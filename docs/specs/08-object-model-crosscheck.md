# 08 - Object Model Cross-Check (Adversarial Verification Pass)

**Purpose.** Try to *falsify* the recovered object model (`extracted/object_model.json`) by
re-deriving it independently from `NSS5.exe`, and by checking every claim it makes against the
shipped data files and against specs 01-07. Default posture: report the contradiction, do not
explain it away.

**Method.** Independent evidence channels, never one alone:

| Tag | Meaning |
|---|---|
| **[RE-PARSE]** | The BBDebugScope/BBDebugDecl tables were re-decoded from scratch by a parser written for this pass, with no reference to `object_model.json`, then diffed against it. |
| **[DISASM]** | Function bodies disassembled with `tools/blitzmax/BlitzMax/MinGW32x86/bin/objdump.exe -d -M intel --start-address=… --stop-address=…` against the shipped exe. VAs come from `extracted/vtable_map.tsv`. |
| **[FILE]** | Exhaustive scan of the shipped data files under `GameMedia/Data` and `EngineMedia/Tactics`. |
| `UNCERTAIN:` | Not established. Do not build on it. |

Source of truth (read-only): `C:/Program Files (x86)/Steam/steamapps/common/New Star Soccer 5`.

PE mapping used throughout (re-derived via `objdump -h`; matches spec 01 §0):

```
section   VMA         VSize       RawPtr
.text     0x00401000  0x000B8788  0x00000400
code      0x004BA000  0x000FF723  0x000B8C00
.data     0x005BA000  0x0001480C  0x001B8400
data      0x005CF000  0x006E431C  0x001CCE00
.rdata    0x00CB4000  0x00020760  0x008B1200
```

BBString literal layout, used to resolve every string quoted below **[RE-PARSE]**:
`+0 vtable = 0x005C7D60`, `+4 refcount = 0x7FFFFFFF`, `+8 length (UTF-16 units)`, `+12 chars`.

---

## 0. Executive summary - the headline result

**The object model is arithmetically sound but materially incomplete.** Offsets, sizes and
inheritance survived every test thrown at them (0 overlaps, 0 size mismatches, 0 bad inheritance
bases across 231 types with fields). But the extractor that produced `object_model.json`
**silently dropped 18 types**, including **`TPlayer` - the single most important type in the
match engine (97 fields, 134 methods/functions, 4 consts)** - and dropped **all 53 `Const`
declarations** in the binary.

The cause is a decoder bug, and the project brief's own description of the record format encodes
it. The brief states *"kind 3=Field, 6=Method, 7=Function, 2=Global, 4=Const"*. That is wrong.
The real kind for a `Const` declaration is **1**, and there are **no `Global` declarations at all**
in this binary. A parser that treats `1` as an invalid kind aborts the enclosing scope - which is
exactly what happened to `TPlayer`, whose scope record opens with four `Const`s.

| Metric | `object_model.json` | Independent re-parse | Delta |
|---|---|---|---|
| Scopes (types) | 337 | **355** | **+18 missing** |
| Field decls | 2,670 | **2,831** | **+161 missing** |
| Method decls | 1,661 | **1,977** | +316 missing |
| Function decls | 939 | **975** | +36 missing |
| Const decls | 0 | **53** | **+53 missing** |
| Global decls | 0 | **0** | - (kind never occurs) |

Everything `object_model.json` *does* contain was verified byte-identical to the independent
re-parse for 327 of 337 types; the other 10 are prefix-truncated (runtime/driver types only - 
§7.2). **No game type present in the file was found to be wrong. The problem is omission, not
corruption.**

---

## 1. Discrepancy register

Severity: **S1** = will produce a wrong reconstruction; **S2** = will produce an incomplete or
subtly wrong reconstruction; **S3** = documentation/precision defect.

| # | Sev | Area | Discrepancy | Evidence |
|---|---|---|---|---|
| D-01 | **S1** | Object model | `TPlayer` is **entirely absent** from `object_model.json`, yet 19 signatures across the model reference `:TPlayer`. Its scope record exists at VA `0x00C5EA90` with 97 fields (+8…+392), 110 methods, 24 functions, 4 consts. | [RE-PARSE] |
| D-02 | **S1** | Decoder | Declaration kind **1 = Const** is not handled. Any scope whose declaration list contains a Const is aborted and lost. 53 Const decls across 11 types are missing. | [RE-PARSE] |
| D-03 | **S1** | Brief / spec 07 | The documented record format ("kind 2=Global, 4=Const") is **not what the binary contains**. Kind 2 appears only as the *scope header*; kind 4 never appears; Const is kind 1. | [RE-PARSE] |
| D-04 | **S2** | Object model | 17 further types missing besides `TPlayer` (§7.1) - incl. `TMap`, `TTextStream`, `TCStream`, `TD3D7Max2DDriver`, `TZipFileList`, and three `z_blide_bg*` build-metadata scopes. | [RE-PARSE] |
| D-05 | **S2** | Object model | 10 types are **prefix-truncated** - the first N decls are right, the tail is missing (e.g. `TD3D7GraphicsDriver` has 1 of 31). All are BlitzMax runtime/driver types. | [RE-PARSE] |
| D-06 | **S1** | `src/nss5/teams.bmx` | `TBase_Team.labelname` (+28) and `labelshortname` (+32) are **never populated**. They are not CSV columns; `TClub.CreateClub` derives them at load time from a global flag. A reconstruction that leaves them Null will render blank team names. | [DISASM] `0x4BFFD1-0x4C0044` |
| D-07 | **S2** | Reconstruction guidance | Field order ≠ CSV column order. `TBase_Team` and `TCompetition` both interleave runtime-only fields *inside* the file-backed run (`labelname` at +20 in `TCompetition`, `priority` at +84). Index-by-field-ordinal loaders will silently misalign. | [DISASM] |
| D-08 | **S2** | `EngineMedia/Tactics` | 13 `.tac` files ship, but `TFormation.GetStringTacticName` only names **11** built-ins + 3 custom slots. **`4-1-4-1.tac` and `4-2-3-1.tac` are unreachable** - no id maps to them. | [DISASM] `0x4D9856`, [FILE] |
| D-09 | **S2** | Engine fallback | `TFormation.LoadTactics` falls back to the literal path `EngineMedia\Tactics\4-4-2.tac`. **No such file ships** (only `4-4-2 A.tac` / `4-4-2 B.tac`). The fallback is dead. | [DISASM] `0x4D882A`, [FILE] |
| D-10 | **S2** | `.tac` decode | The brief states "exactly 10 ones = the outfield players". The **loader's guard is `< 11`**, not 10: `LoadTactics` accepts up to 11 set cells. All 13 shipped files do contain exactly 10 - but the format permits 11. | [DISASM] `0x4D88CF` |
| D-11 | **S2** | Task premise (item 4) | The premise "which Engine.ini key drives which `TBall` field" is **false**. Not one of the 20 `[Ball]` keys corresponds to a `TBall` *field*. They are module-level globals (§6.2 gives the full key→VA map). `TBall`'s 42 fields are per-ball *state*, not tuning constants. | [DISASM] |
| D-12 | **S2** | `TProfile` vs spec 03 | Spec 03 §17 documents a full horse-racing / Stable system; **`TProfile` has no horse or stable field**. Ownership lives on `THorse.owned` (+80), i.e. the horse roster is global state, not profile state. | [RE-PARSE] |
| D-13 | **S2** | `TProfile` vs spec 03 | Spec 03 §20.3 documents a Difficulty system; **`TProfile` has no difficulty field**, and `TOptions` has **zero fields**. `UNCERTAIN:` where difficulty is persisted. | [RE-PARSE] |
| D-14 | **S3** | Brief | "132 game Types" is not reproducible. The tables hold 355 scopes; excluding the ~200 BlitzMax runtime/Win32/D3D/Zip scopes leaves ~150 game types, and the count depends entirely on where the line is drawn. | [RE-PARSE] |
| D-15 | **S3** | Brief / spec 01 | "kit styles are ASCII tokens e.g. PLAIN, TRIM, STRIPE_RL" understates it. The engine recognises **23** tokens; the shipped data uses **21 distinct raw values** including one lowercase (`plain`), one colour literal in a style column, and empty strings. Spec 01 §5 already has the full 23 - the brief's summary is the lossy one. | [DISASM] `0x4DCE33`, [FILE] |
| D-16 | **S3** | Data hygiene | `Competitions.csv` and `PromotionPlaces.csv` data rows carry a **trailing TAB** → 21 and 4 split-fields for 20- and 3-column files. `Clubs.csv`/`Nations.csv` do **not**. `Achievements.csv` is the only file with a UTF-8 **BOM**. One shared loader must handle all three shapes. | [FILE] |
| D-17 | **S3** | Data hygiene | 15 malformed colour cells ship (13 in `Clubs.csv`, 2 in `Nations.csv`): truncated hex (`#CC`, `#4444`, `#00033`), a bare `#`, and one with a trailing space (`#9933CC `). A strict `#RRGGBB` parser will reject real data. | [FILE] |
| D-18 | **S3** | `TCompetition` | `teampool` is `[]:TTeamPool` and is assigned at +108 in `CreateCompetition` - it is **not** file-backed despite sitting adjacent to file-backed ints. | [DISASM] `0x5092E3` |

---

## 2. Confirmed claims

These survived active attempts to break them.

| # | Claim | Verdict | Evidence |
|---|---|---|---|
| C-01 | `TBase_Team` occupies +8…+92 and ends at +96; `TClub` and `TNation` both start own fields at +96. | **CONFIRMED** | `class_tables.tsv` gives `TBase_Team.instance_size = 96`; `super_type` of both = `TBase_Team`; both first own field = +96. |
| C-02 | Field-offset arithmetic is internally consistent everywhere. | **CONFIRMED** | 231 types with fields: **0 overlaps**, **0** cases of `instance_size ≠ last_offset + sizeof(last)`. Int/Float/String/object/array all 4 bytes; Byte 1; Short 2; Long/Double 8. |
| C-03 | Inheritance offsets are consistent for **every** subclass in the binary. | **CONFIRMED** | 76 declared subclasses; in all 76 the subclass's first own field lands exactly on the superclass's `instance_size` (e.g. seven `TGadget` subclasses at +92; four `TTrainingObject` subclasses at +36). |
| C-04 | `Clubs.csv` → `TClub` and `Nations.csv` → `TNation` column mapping in `src/nss5/teams.bmx`. | **CONFIRMED column-for-column** (with the D-06 gap) | §3.2. |
| C-05 | Kit styles are ASCII tokens and `kitcols*` is `:TKitStrings`. | **CONFIRMED and mutually consistent** | `TKitStrings` = `style`,`shirt1`,`shirt2`,`shorts`,`socks` (all `$`) at +8/+12/+16/+20/+24, size 28 - exactly the (type, 4×colour) shape the CSV's 5-column kit blocks carry. §3.4. |
| C-06 | comptype enum `_League/_KO/_BestPlaced/_Pool/_LeagueCont/_RegionalSort` (spec 02). | **CONFIRMED exactly, ids 0-5** | §4.2. All six values occur in `Competitions.csv`. |
| C-07 | `.tac` = 7 wide × 5 deep, GK implicit. | **CONFIRMED** | `GetCol(seg) = seg Mod 7` (literal `idiv 7`); `GetRow` is a 5-way cascade on 7/14/21/28; `LoadTactics` loops `seg = 0 To 34`. §5.1. |
| C-08 | `TFormation`'s 5 band fields correspond to the 5 grid rows. | **CONFIRMED - direct, not inferred** | `UpdateLabels` labels rows 0-4 `"D","DM","M","AM","F"` and increments the five counters by label. Independently, per-row set-counts of all 13 `.tac` files reproduce their filenames (13/13). §5.2. |
| C-09 | `TProfile`'s ability/rating block matches spec 03 §5.1-§5.2. | **CONFIRMED both directions** | 7 trainable abilities, 10 usage-driven ratings, each rating mirrored by a `temp_*` field. §8.1. |
| C-10 | Spec 03 §10.1's "six relationships + FAME = seven scalars". | **CONFIRMED** | `TProfile` has exactly `relationboss/team/fans/friends/girlfriend/sponsors` + `relationfame` at +260…+284. |
| C-11 | Engine.ini blob provenance (spec 04): offset `0x837C34`, length 2422, MD5 `0FC19A7BE9C6553E74375A2688FD16F6`, 118 keys in 9 groups. | **CONFIRMED, all four** | Re-extracted and re-hashed this pass. |
| C-12 | `PromotionPlaces.csv` graph closure (spec 02). | **CONFIRMED** | 0 dangling `parentid`, 0 dangling `promotiontoid` against the 1,028 competition ids. |
| C-13 | Data files are UTF-8, TAB-separated, with a `//` sentinel (spec 01/02). | **CONFIRMED** | §3.1. |
| C-14 | Row counts 5,436 clubs / 211 nations (spec 01) and 1,028 competitions / 2,067 promotion places (spec 02). | **CONFIRMED, all four** | §3.1. |

**Sections with no discrepancies found:** §7.4 (offset arithmetic) and C-03 (inheritance)
produced **zero** findings across the entire binary. That is a real result - whatever tool
produced the offsets in `object_model.json` got the layout algebra completely right.

---

## 3. `TBase_Team` / `TClub` / `TNation` vs the real CSVs

### 3.1 Physical format (re-measured this pass) **[FILE]**

| File | Delimiter | BOM | Header cols | Data rows | Split-fields per row | Sentinel |
|---|---|---|---|---|---|---|
| `Clubs.csv` | TAB | no | 38 | **5,436** | 38 (clean) | `//` |
| `Nations.csv` | TAB | no | 38 | **211** | 38 (clean) | `//` |
| `Competitions.csv` | TAB | no | 20 | **1,028** | **21** (trailing TAB) | `//` |
| `PromotionPlaces.csv` | TAB | no | 3 | **2,067** | **4** (trailing TAB) | `//` |
| `Continents.csv` | TAB | no | 7 | 6 | 7 (clean) | `//` |
| `Achievements.csv` | TAB | **yes** | 2 | 100 | 2 (clean) | none |

Row counts match spec 01 (5,436 / 211) and spec 02 (1,028 / 2,067) exactly.

### 3.2 Column → field mapping, verified cell by cell

`teams.bmx` indexes `f[0]…f[37]`. Verified against real row 1 of each file and against
`TClub.CreateClub` **[DISASM] `0x4BFEA2`** / `TNation.CreateNation` **[DISASM] `0x4BD649`**,
whose store sequence is `[esi+0x0C, 0x10, 0x14, 0x18, (0x1C, 0x20 derived), 0x24, 0x28, 0x2C,
0x30, 0x34, 0x38, …]`.

| CSV col | Clubs header | Nations header | Field | Offset | `teams.bmx` | Verdict |
|---|---|---|---|---|---|---|
| - | - | - | `randno` | +8 | not loaded | runtime-only ✔ |
| 0 | `id` | `id` | `id` | +12 | `f[0]` | ✔ |
| 1 | `name` | `name` | `name` | +16 | `f[1]` | ✔ |
| 2 | `shortname` | `shortname` | `shortname` | +20 | `f[2]` | ✔ |
| 3 | `tla` | `tla` | `tla` | +24 | `f[3]` | ✔ |
| - | - | - | **`labelname`** | **+28** | **missing** | **D-06** |
| - | - | - | **`labelshortname`** | **+32** | **missing** | **D-06** |
| 4 | `strength` | `strength` | `strength` | +36 | `f[4]` | ✔ |
| 5 | `rivalclub1` | `rivalid1` | `rivalid1` | +40 | `f[5]` | ✔ (header name differs) |
| 6 | `rivalclub2` | `rivalid2` | `rivalid2` | +44 | `f[6]` | ✔ |
| 7 | `rivalclub3` | `rivalid3` | `rivalid3` | +48 | `f[7]` | ✔ |
| 8 | `stadiumname` | `stadiumname` | `stadiumname` | +52 | `f[8]` | ✔ |
| 9 | `stadiumcapacity` | `stadiumcapacity` | `stadiumcapacity` | +56 | `f[9]` | ✔ |
| 10 | `stadiumlongitude` | `stadiumlongitude` | `stadiumlongitude` | +60 | `f[10]` | ✔ (Float) |
| 11 | `stadiumlatitude` | `stadiumlatitude` | `stadiumlatitude` | +64 | `f[11]` | ✔ (Float) |
| 12-16 | `homestyle` + 4 | `homekittype` + 4 | `kitcolsHome` | +68 | `TKitStrings.Create(f[12..16])` | ✔ |
| 17-21 | `awaystyle` + 4 | `awaykittype` + 4 | `kitcolsAway` | +72 | `f[17..21]` | ✔ |
| 22-26 | `thirdstyle` + 4 | `thirdkittype` + 4 | `kitcolsThird` | +76 | `f[22..26]` | ✔ |
| 27-31 | `keeperstyle` + 4 | `keeperkittype` + 4 | `kitcolsKeeper` | +80 | `f[27..31]` | ✔ |
| 32 | `formation` | `formation` | `formation` | +84 | `f[32]` | ✔ |
| - | - | - | `imgFlag` | +88 | not loaded | runtime-only ✔ |
| - | - | - | `imgFlagSmall` | +92 | not loaded | runtime-only ✔ |
| 33 | `nickname` | `nationality` | `nickname` / `nationality` | +96 | `f[33]` | ✔ |
| 34 | `nationid` | `continent` | `nationid` / `continent` | +100 | `f[34]` | ✔ |
| 35 | `leagueid` | `climate` | `leagueid` / `climate` | +104 | `f[35]` | ✔ |
| 36 | `continentalcompid` | `primaryskin` | `continentalcompid` / `primaryskin` | +108 | `f[36]` | ✔ |
| 37 | `bteamof` | `secondaryskin` | `bteamofid` / `secondaryskin` | +112 | `f[37]` | ✔ |

**Result: the mapping in `teams.bmx` is correct for all 38 columns of both files.** The one
defect is the omission (D-06), not a misalignment.

Naming notes (harmless, but record them): `Clubs.csv` uses `rivalclub1..3` where the field is
`rivalid1..3`, and `bteamof` where the field is `bteamofid`;
`homestyle/awaystyle/thirdstyle/keeperstyle` in Clubs vs
`homekittype/awaykittype/thirdkittype/keeperkittype` in Nations address the *same*
`TKitStrings.style` slot.

Observed value domains **[FILE]**: `formation` ∈ {4,6,7,8,9,10} in both files;
`Nations.continent` ∈ 1-6 (matches `Continents.csv` ids); `climate`, `primaryskin`,
`secondaryskin` ∈ 0-4; `Clubs.nickname` empty in 3,733 of 5,436 rows; `bteamof` non-zero in 163;
`continentalcompid` non-zero in 442; `leagueid = 0` in 1,349.

### 3.3 What `labelname` / `labelshortname` actually are **[DISASM]**

`TClub.CreateClub` at `0x4BFFD1`:

```
cmp DWORD PTR ds:0xC6EF74, 0        ; a global mode flag
je  .use_tla
    labelname      = name           ; [esi+0x1C] <- [esi+0x10]
    labelshortname = shortname      ; [esi+0x20] <- [esi+0x14]
    jmp .done
.use_tla:
    labelname      = tla            ; [esi+0x1C] <- [esi+0x18]
    labelshortname = tla            ; [esi+0x20] <- [esi+0x18]
.done:
    strength = Int(next column)     ; [esi+0x24]
```

Both label fields are **derived at load time**, selecting between the real name pair and the TLA
under a single global switch. `UNCERTAIN:` the identity of the flag at `0x00C6EF74` - the shape
(real names vs. codes) is the classic unlicensed-names toggle, but its writer was not traced.
A reconstruction must implement the derivation; it must not invent CSV columns for it.

### 3.4 `TKitStrings` - the real structure

| Offset | Field | Sig | Holds |
|---|---|---|---|
| +8 | `style` | `$` | ASCII style token (below) |
| +12 | `shirt1` | `$` | `#RRGGBB` |
| +16 | `shirt2` | `$` | `#RRGGBB` |
| +20 | `shorts` | `$` | `#RRGGBB` |
| +24 | `socks` | `$` | `#RRGGBB` |

`instance_size = 28`. Members: `CreateKitStrings($,$,$,$,$)`, `Copy`, `CheckKitColours`,
`ConvertNSS4ColourIndexToHex(i)$` (an NSS4 save-import path), `GetFileName()$`,
`GetStyleId_Mobile()i`.

**23 recognised style tokens** and their `GetStyleId_Mobile` ids, decoded from the compare chain
at **[DISASM] `0x4DCE33`-`0x4DD109`** (23 `StringCompare` tests, then a jump table of `mov eax,N`):

| Token | id | Token | id | Token | id |
|---|---|---|---|---|---|
| `PLAIN` | 0 | `STRIPE_V` | 6 | `SPLIT` | 12 |
| `TRIM` | 1 | `HOOPS` | 8 | `SPLIT_LR` | 12 |
| `STRIPES` | 2 | `HOOP` | 9 | `DIAGONALSPLIT_LR` | 12 |
| `STRIPE` | 2 | `SINGLEHOOP` | 9 | `DIAGONALSPLIT_RL` | 12 |
| `STRIPE_L` | 2 | `SLEEVES` | 10 | `CHEQUERED` | 13 |
| `STRIPE_R` | 2 | `SLEEVE` | 11 | `SEGMENTS` | 14 |
| `STRIPE_LR` | 3 | `SLEEVE_L` | 11 | *(unrecognised)* | 0 |
| `STRIPE_RL` | 4 | `SLEEVE_R` | 11 | | |
| `STRIPE_C` | 5 | | | | |

Id 7 is unused. This agrees with spec 01 §5 (`STRIPE_RL → 4`). Note it is **lossy** - it is the
mobile-port compression, *not* the desktop renderer, which goes through `GetFileName()` to a
per-style PNG.

Raw values actually present **[FILE]** - 21 distinct across the four style columns of
`Clubs.csv`, and not all clean:

* lowercase variant `plain` (1 cell) - a case-sensitive compare would miss it;
* empty string (2 home, 3 away, 2 third, 2 keeper);
* one `keeperstyle` cell containing `#FFFFFF` - a colour leaked into the style column;
* `Nations.csv` uses `SLEEVE_L` / `SLEEVE_R`, which never appear in `Clubs.csv`.

All still parse, because unrecognised tokens fall through to id 0 (`PLAIN`). **A faithful
reconstruction must reproduce that fall-through, not validate the input.**

---

## 4. `TCompetition`: 27 fields vs 20 columns

### 4.1 File-backed vs runtime-only - settled by disassembly

`TCompetition.CreateCompetition` **[DISASM] `0x5092E3`** stores in this order:
`+8, +12, +16, +20 (×2, derived), +24, +28, +32, +36, +40, +44, +48, +52, +56, +60, +64, +68,
+72, +76, +80, +88, +92`, then `+108`. **`+84` is never written from the file.**

| Offset | Field | Sig | CSV col | Status |
|---|---|---|---|---|
| +8 | `id` | `i` | 0 `id` | file-backed |
| +12 | `name` | `$` | 1 `name` | file-backed |
| +16 | `tla` | `$` | 2 `tla` | file-backed |
| **+20** | **`labelname`** | `$` | - | **runtime - derived, same pattern as §3.3** |
| +24 | `locale` | `i` | 3 | file-backed |
| +28 | `level` | `i` | 4 | file-backed |
| +32 | `based` | `i` | 5 | file-backed |
| +36 | `comptype` | `i` | 6 | file-backed |
| +40 | `startyear` | `i` | 7 | file-backed |
| +44 | `startweek` | `i` | 8 | file-backed |
| +48 | `duration` | `i` | 9 | file-backed |
| +52 | `recurring` | `i` | 10 | file-backed |
| +56 | `primarymatchday` | `i` | 11 | file-backed |
| +60 | `secondarymatchday` | `i` | 12 | file-backed |
| +64 | `groups` | `i` | 13 | file-backed |
| +68 | `rounds` | `i` | 14 | file-backed |
| +72 | `legs` | `i` | 15 | file-backed |
| +76 | `townregion` | `i` | 16 | file-backed |
| +80 | `compstatus` | `i` | 17 | file-backed |
| **+84** | **`priority`** | `i` | - | **runtime - set by `SetPriority()` (vt `0xB8`)** |
| +88 | `minstrength` | `i` | 18 | file-backed |
| +92 | `maxstrength` | `i` | 19 | file-backed |
| +96 | `lfixturelist` | `:TList` | - | runtime |
| +100 | `lpromotionplaces` | `:TList` | - | runtime (filled by `TPromotionPlace.AddToParentLists`) |
| +104 | `lplacesthatpromotetome` | `:TList` | - | runtime (reverse edge of the same graph) |
| +108 | `teampool` | `[]:TTeamPool` | - | runtime (`CreateTeamPool` / `PopulateTeamPool`) |
| +112 | `tempNoofTeams` | `i` | - | runtime scratch |

**20 file-backed + 7 runtime = 27.** Exact. The trap is that `priority` sits *between*
`compstatus` and `minstrength`, i.e. inside the run of file-backed ints - see D-07.

Default injection observed in the same function (blank cell → default): `duration←1`,
`primarymatchday←6`, `secondarymatchday←3`, `groups←1`, `rounds←1`, `compstatus←1`, plus a
branch forcing `primarymatchday←99`, `secondarymatchday←99`, `startweek←1`, `duration←0`.
`UNCERTAIN:` the exact guard conditions on the 99/0 branch were not traced.

### 4.2 Enum reconciliation with spec 02 **[DISASM]**

All four label functions decoded from `0x50C926`-`0x50CB14`; values are the literal BBStrings.

| `comptype` | Label | Rows in `Competitions.csv` |
|---|---|---|
| 0 | `comptype_League` | 339 |
| 1 | `comptype_KO` | 651 |
| 2 | `comptype_BestPlaced` | 5 |
| 3 | `comptype_Pool` | 2 |
| 4 | `comptype_LeagueCont` | 17 |
| 5 | `comptype_RegionalSort` | 14 |
| else | `None` | - |

**Spec 02's enum is confirmed exactly, in both name and ordinal.** All six values occur in the
shipped data, so none is speculative.

Further enums recovered from the shipped data:

| `locale` | | `level` | | `townregion` | |
|---|---|---|---|---|---|
| 0 | `Nation` | 0 | `Club` | 1 | `North` |
| 1 | `Continent` | 1 | `International` | 2 | `East` |
| 2 | `World` | else | `None` | 3 | `South` |
| else | `None` | | | 4 | `West` |
| | | | | 0 / else | `None` |

Observed domains **[FILE]**: `locale` {0:915, 1:107, 2:6}; `level` {0:988, 1:40};
`townregion` {0:998, 1:13, 2:6, 3:7, 4:4}. Every observed value has a label. No orphans.

---

## 5. `TFormation` vs the `.tac` decode

Array-access note: `m_TacPos` is at object +0x20; element `i` is at `[array_ptr + i*4 + 0x18]`,
i.e. the legacy BlitzMax array header is **24 bytes**. Same for `m_TacLabel` at +0x24.

### 5.1 The exactly-decoded accessors **[DISASM]**

**`GetCol(seg:Int)` - `0x4D8AA4`, 22 bytes.**
```
mov eax,[ebp+0xC] ; mov ecx,7 ; cdq ; idiv ecx ; mov eax,edx      →  Return seg Mod 7
```
Literally `seg Mod 7`. **Proves the grid is 7 wide.** No bounds check.

**`GetRow(seg:Int)` - `0x4D8ABA`, 57 bytes.** A descending cascade, not a division:
```
row = 4
If seg < 28 Then row = 3
If seg < 21 Then row = 2
If seg < 14 Then row = 1
If seg <  7 Then row = 0
Return row
```
**Proves 5 rows of 7 = 35 cells.** Note it is *unclamped above*: any `seg ≥ 28` yields 4,
including out-of-range values. Reproduce the cascade, not `seg / 7`, for bug-compatibility.

**`GetSelectionNoFromSeg(seg:Int, side:Int)` - `0x4D8A4F`, 85 bytes.**
```
n = 0
If side = -1 Then seg = 34 - seg          ' 180 degree rotation of the whole grid
For i = 0 To seg
    If m_TacPos[i] = 1 Then n :+ 1
Next
If m_TacPos[seg] = 1 Then Return n Else Return -1
```
Returns the **1-based rank** of that cell among occupied cells in scan order, or −1 if the cell is
empty. `side = -1` mirrors the board (`34 - seg`) - the away-team view. The literal in the
compare is `0x22 = 34`, again confirming 35 cells.

**`GetRowFromSelectionNo` / `GetColFromSelectionNo` - `0x4D8AF3` / `0x4D8B3C`** are the exact
inverse, byte-identical to each other except for the final vtable slot:
```
count = 0
For seg = 0 To 34
    If m_TacPos[seg] = 1 Then
        count :+ 1
        If count = selno Then Return GetRow(seg)   ' resp. GetCol(seg)
    EndIf
Next
Return -1
```
The dispatch is `call [eax+0x4C]` and `call [eax+0x48]` - slots `0x4C`/`0x48`, which the
reflection table independently records as `GetRow`(76) and `GetCol`(72). **The vtable-slot
decoding in `object_model.json` is thereby confirmed by executable behaviour, not just by table
layout.**

### 5.2 The 5 bands ARE the 5 rows - proved twice, independently

**Proof A - `UpdateLabels` at `0x4D83CC` [DISASM].** It zeroes +0x0C…+0x1C (the five band
counters), then for each `seg` assigns `m_TacLabel[seg]` from a row cascade using *the same*
7/14/21/28 thresholds as `GetRow`, then - for occupied cells only - compares the label against
each row-label global and increments the matching counter:

| Row | Label global | BBString | Counter | Field |
|---|---|---|---|---|
| 0 | `0xC5BBBC` | `"D"` | `[edi+0x0C]` | `m_Defenders` (+12) |
| 1 | `0xC5BBD0` | `"DM"` | `[edi+0x10]` | `m_DefensiveMidfielders` (+16) |
| 2 | `0xC5BBE4` | `"M"` | `[edi+0x14]` | `m_Midfielders` (+20) |
| 3 | `0xC5BBF8` | `"AM"` | `[edi+0x18]` | `m_AttackingMidfielders` (+24) |
| 4 | `0xC5BC0C` | `"F"` | `[edi+0x1C]` | `m_Attackers` (+28) |

**Proof B - all 13 shipped `.tac` files [FILE].** Each file is 105 bytes = 35 lines of `"0␍␊"` or
`"1␍␊"` (CRLF on every line including the last). Reading **row-major** (7 per row, row 0 = the
defensive line), the per-row set-counts reproduce the filename in **13 of 13** cases:

| File | Row counts (D, DM, M, AM, F) | Filename check |
|---|---|---|
| `3-4-3.tac` | 3, 0, 4, 0, 3 | ✔ |
| `3-5-2 A.tac` | 3, 1, 3, 1, 2 | ✔ (1+3+1 = 5) |
| `3-5-2 B.tac` | 3, 0, 5, 0, 2 | ✔ |
| `4-1-4-1.tac` | 4, 1, 4, 0, 1 | ✔ |
| `4-2-2-2.tac` | 4, 0, 2, 2, 2 | ✔ |
| `4-2-3-1.tac` | 4, 2, 0, 3, 1 | ✔ |
| `4-2-4.tac` | 4, 0, 2, 0, 4 | ✔ |
| `4-3-3.tac` | 4, 0, 3, 0, 3 | ✔ |
| `4-4-1-1.tac` | 4, 0, 4, 1, 1 | ✔ |
| `4-4-2 A.tac` | 4, 0, 4, 0, 2 | ✔ |
| `4-4-2 B.tac` | 4, 1, 2, 1, 2 | ✔ (1+2+1 = 4) |
| `4-5-1.tac` | 4, 0, 5, 0, 1 | ✔ |
| `5-3-2.tac` | 5, 0, 3, 0, 2 | ✔ |

Column-major decoding reproduces **none** of the filenames. **Row-major, row 0 = defenders, is
settled.** GK-implicit is confirmed: every file has exactly 10 ones and no cell is reserved.

### 5.3 `LoadTactics` - the 11 cap **[DISASM] `0x4D8783`**

```
For seg = 0 To 34
    If Not Eof(f) And noofplayers < 11 Then     ' <-- cmp edi,0xB ; setl
        m_TacPos[seg] = Int(ReadLine(f))
        If m_TacPos[seg] = 1 Then noofplayers :+ 1 Else m_TacPos[seg] = 0
    EndIf
Next
CloseFile f
UpdateLabels()                                   ' call [eax+0x38]
```

Any value other than exactly `1` is normalised to `0`. The guard is `< 11`, not `< 10` (D-10).
The dead fallback path `EngineMedia\Tactics\4-4-2.tac` lives at `0x4D882A` (D-09).

### 5.4 `GetPlayerXY` - what is established and what is not

Signature `(i,f,f,f,f,i,i,*f,*f,f,f)f`, vt slot `0x58`, body `0x4D8B85`-`0x4D96D6` (2,898 bytes).
Stack slots confirmed by use:

| Slot | Arg | Confirmed role |
|---|---|---|
| `[ebp+0x08]` | `Self` | receiver |
| `[ebp+0x0C]` | arg1 `i` | **selection number** - fed straight to `GetColFromSelectionNo` (`call [eax+0x54]`) and `GetRowFromSelectionNo` (`call [eax+0x50]`) |
| `[ebp+0x10]`, `[ebp+0x14]` | arg2, arg3 `f` | working X and Y (arg3 is negated on entry: `fld; fchs; fstp`) |
| `[ebp+0x18]`, `[ebp+0x1C]` | arg4, arg5 `f` | pitch width and height extents |
| `[ebp+0x20]` | arg6 `i` | compared `= 1` at three points - a side/direction flag |
| `[ebp+0x24]` | arg7 `i` | **has-ball flag** - selects `formationwidth` vs `withoutballformationwidth` |
| `[ebp+0x28]`, `[ebp+0x2C]` | arg8, arg9 `*f` | out-parameters (the returned X, Y) |
| `[ebp+0x30]`, `[ebp+0x34]` | arg10, arg11 `f` | horizontal / vertical scale divisors |

Established cell geometry (globals resolved in §6.2):
```
cellH = arg5 / (formationheight * arg11)                                 ' 0xC5BB38
If arg7 <> 0 Then cellW = arg4 / (formationwidth * arg10)                ' 0xC5BB3C
              Else cellW = arg4 / (withoutballformationwidth * arg10)    ' 0xC5BB40
```
followed by clamping of X into `[3*cellW, arg4 - 3*cellW]` and Y into `[1*cellH, arg5 - 1*cellH]`,
then a **5-way switch on the row** (`GetRowFromSelectionNo`) where each band applies its own depth
multiplier (`1.25`, `0.5`, `0.25`, …) and its own has-ball / no-ball constant pair, with
`formationdepth` (`0xC5BB44`) applied to Y.

`UNCERTAIN:` **the complete formula.** This is a 2.9 KB x87 function with roughly 14 branches, and
it was not decompiled to a level worth staking a reconstruction on. Safe to build on: the argument
roles above, the two cell-size expressions, the fact that it dispatches on `(row, col)` derived
from the selection number, and the four ini globals it consumes. Anything beyond that must be
re-derived.

### 5.5 Formation ids and the orphan `.tac` files **[DISASM] `0x4D9856`**

`TFormation.Create(id)` = `LoadTactics(GetStringTacticName(id))` (`0x4D8397`; indirect call to
`GetStringTacticName` via `ds:0xC5C020`, then vt slot `0x3C` = `LoadTactics`). The tactic name
**is** the file basename.

| id | Name | `.tac` file present? |
|---|---|---|
| 1 | `3-4-3` | ✔ |
| 2 | `3-5-2 A` | ✔ |
| 3 | `3-5-2 B` | ✔ |
| 4 | `4-2-2-2` | ✔ |
| 5 | `4-2-4` | ✔ |
| 6 | `4-3-3` | ✔ |
| 7 | `4-4-1-1` | ✔ |
| 8 | `4-4-2 A` | ✔ |
| 9 | `4-4-2 B` | ✔ |
| 10 | `4-5-1` | ✔ |
| 11 | `5-3-2` | ✔ |
| 12-14 | `Custom 1` / `Custom 2` / `Custom 3` | user-saved |
| 0 / >14 | falls back to `4-4-2 A` | ✔ |
| - | **`4-1-4-1`** | **file ships, no id → unreachable (D-08)** |
| - | **`4-2-3-1`** | **file ships, no id → unreachable (D-08)** |

`formation` column values in `Clubs.csv`/`Nations.csv` are `{4,6,7,8,9,10}` **[FILE]** - all inside
1-11, consistent with spec 01's "1-based index into the formation list". Confirmed.

---

## 6. `TBall` (42 fields) vs the `[Ball]` ini group (20 keys)

### 6.1 The premise does not hold

There is **no field-to-key correspondence** (D-11). `TBall`'s 42 fields are per-instance
simulation *state*: position (`x,y,z` / `oldx,oldy,oldz`), meta/jump/dive targets, set-piece
coordinates, `velocity` / `zvelocity` / `direction`, six `:TPlayer` role references
(`controlledby`, `lastkickedby`, `lasttouchedby`, `assistedby`, `setpiecetaker`, `setpiecebuddy`),
flags, and rendering/replay members. The ini keys are **module-level globals** - which is why they
appear nowhere in the reflection tables (there are no `Global` declarations in this binary at all,
§7.3).

The only defensible field↔key *relationships* are indirect:

| `TBall` field | Offset | Related ini key(s) | Relationship |
|---|---|---|---|
| `curlamount` | +152 | `curlinc` (0.05), `curlmax` (0.7) | accumulator: stepped by `curlinc`, clamped at `curlmax` (`CheckAfterTouch`) |
| `kicktime` | +100 | `aftertouchtime` (750) | timestamp compared against the after-touch window |
| `velocity`, `zvelocity` | +84, +88 | `kickpow_*`, `kickheight_*`, `gravity`, `bounce`, `fricAir`, `fricGrass` | integrated in `UpdateMovement` |
| `disttoreciever` | +148 | `kickdistratio_*` | scales pass/shot power by distance |
| `posthit` | +144 | `goalpost`, `postwidth`, `crossbar` (`[Pitch]`) | `HitPost` |
| `frame`, `lastframetime` | +160, +164 | `framelength` (`[Animation]`) | animation clock |

`UNCERTAIN:` **every row above.** Each is a *plausible* wiring inferred from names plus the
existence of the matching method (`UpdateMovement`, `CheckAfterTouch`, `HitPost`); the arithmetic
was not traced. Do not treat this table as a specification.

### 6.2 What can be given exactly: every ini key → its backing global

Derived mechanically **[DISASM]**: each key is read through a helper at `0x4BBFC1` taking
`(section:$, key:$, default:i, max:f)`, and the result is immediately committed with
`fstp DWORD PTR ds:0x…` (float) or `mov ds:0x…,eax` (int). **80 of 118 keys resolved**; the
remainder are read in code regions not disassembled this pass.

| `[Ball]` key | Global VA | | `[Ball]` key | Global VA |
|---|---|---|---|---|
| `ballradius` | `0xC5A4C8` | | `kickheight_shoot` | `0xC5A4EC` |
| `fricGrass` | `0xC5A4CC` | | `kickpow_lob` | `0xC5A4F0` |
| `fricAir` | `0xC5A4D0` | | `kickheight_lob` | `0xC5A4F4` |
| `gravity` | `0xC5A4D4` | | `kickpow_head` | `0xC5A4F8` |
| `bounce` | `0xC5A4D8` | | `kickheight_head` | `0xC5A4FC` |
| `kickpow_pass` | `0xC5A4E0` | | `aftertouchtime` | `0xC5A500` |
| `kickheight_pass` | `0xC5A4E4` | | `curlinc` | `0xC5A504` |
| `kickpow_shoot` | `0xC5A4E8` | | `curlmax` | `0xC5A508` |
| `kickdistratio_shoot` | `0xC5DE94` | | `kickdistratio_pass` | `0xC5DE9C` |
| `kickdistratio_lob` | `0xC5DE98` | | `kickdistratio_cross` | `0xC5DEA0` |

Note `passcheckradius` (a `[Player]` key) lands at `0xC5A4DC`, **inside the ball block** - the
groups are not contiguous in memory. The `[Ball]` globals otherwise form one dense run
`0xC5A4C8`…`0xC5A508`; the four `kickdistratio_*` live with the player block.

`[Tactics]` globals, needed for §5.4:

| Key | Global VA | | Key | Global VA |
|---|---|---|---|---|
| `formationheight` | `0xC5BB38` | | `formationxshift` | `0xC5BB4C` |
| `formationwidth` | `0xC5BB3C` | | `withoutballformationxshift` | `0xC5BB50` |
| `withoutballformationwidth` | `0xC5BB40` | | `formationyshift` | `0xC5BB54` |
| `formationdepth` | `0xC5BB44` | | `ymarginmultiply` | `0xC5BB58` |
| `wideplayerpush` | `0xC5BB48` | | | |

All read as `0` in the on-disk image (they are `data`-section slots initialised at runtime), which
independently confirms they are ini-loaded rather than compile-time constants.

Also resolved: `[Match]` `0xC5B1EC`-`0xC5B2B4`; `[Pitch]` `0xC5D628`-`0xC5D65C`;
`[Player]` `0xC5DE48`-`0xC5DE90`; `[Animation] framelength` `0xC5DEA8`;
`[Match Cameramen]` `0xC5DB2C`-`0xC5DB38`; `[Match rating]` `0xC6A630`-`0xC6A654`
(`ratingperminute` unresolved).

---

## 7. The object model itself

### 7.1 The 18 missing types

Re-parse found 355 scopes; `object_model.json` has 337. Missing:

| Type | Scope VA | Fields | Methods | Functions | Consts | Impact |
|---|---|---|---|---|---|---|
| **`TPlayer`** | `0x00C5EA90` | **97** | **110** | **24** | 4 | **S1 - the match-engine player type** |
| `TMap` | `0x00C9B668` | 1 | 20 | - | 2 | runtime container |
| `TTextStream` | `0x00C9D5F4` | 2 | 27 | 1 | 4 | runtime |
| `TCStream` | `0x00CB1FFC` | 4 | 9 | 2 | 2 | runtime |
| `TD3D7Max2DDriver` | `0x00C9F6CC` | 16 | 31 | - | - | renderer |
| `TD3D9ImageFrame` | `0x00C9EA90` | 9 | 4 | - | - | renderer |
| `TZipFileList` | `0x00C94ED8` | 4 | 8 | 1 | - | archive |
| `TWinVolume` | `0x00C9AD7C` | 1 | 13 | 1 | 1 | platform |
| `EDITSTREAM` | `0x00CAD078` | 3 | 2 | - | - | Win32 struct |
| `TMip` | `0x00C9FF08` | 2 | 6 | - | - | renderer |
| `TD3D7Surface` | `0x00CA1624` | 1 | 2 | - | - | renderer |
| `TD3D9AutoRelease` | `0x00CA1074` | 1 | 2 | - | - | renderer |
| `D3DDEVTYPE` | `0x00CA3608` | - | 2 | - | 5 | enum scope |
| `EConstBlend` | `0x00C96BE8` | - | 2 | 1 | 5 | enum scope |
| `eDrawCharStatus` | `0x00C97370` | - | 2 | - | 3 | enum scope |
| `z_blide_bg…be3d` | `0x00C59194` | - | 2 | - | 9 | **build metadata** |
| `z_blide_bg…1c02b` | `0x00C97AC8` | - | 2 | - | 9 | build metadata |
| `z_blide_bg…f638b5` | `0x00C96174` | - | 2 | - | 9 | build metadata |

**`TPlayer` - complete recovered field layout** (`instance_size` = 396; consts `CLEFT=0`,
`CRIGHT=1`, `CUP=2`, `CDOWN=3`):

| Offset | Field | Sig |
|---|---|---|
| +8 | `newstar` | `i` |
| +12 | `imgPlayer` | `:TImage` |
| +16 | `id` | `i` |
| +20 | `teamid` | `i` |
| +24 | `controller` | `i` |
| +28 | `name` | `$` |
| +32 | `initials` | `$` |
| +36 | `age` | `i` |
| +40 | `value` | `$` |
| +44 | `preferredposition` | `$` |
| +48 | `happiness` | `i` |
| +52 | `boozedup` | `i` |
| +56 | `nrgsickness` | `i` |
| +60 | `unhappiness` | `i` |
| +64 | `tiredness` | `i` |
| +68 | `boozecount` | `i` |
| +72 | `nrgcount` | `i` |
| +76 | `x` | `f` |
| +80 | `y` | `f` |
| +84 | `z` | `f` |
| +88 | `oldx` | `f` |
| +92 | `oldy` | `f` |
| +96 | `oldz` | `f` |
| +100 | `xvel` | `f` |
| +104 | `yvel` | `f` |
| +108 | `zvel` | `f` |
| +112 | `runtime` | `i` |
| +116 | `speed` | `f` |
| +120 | `direction` | `f` |
| +124 | `desx` | `f` |
| +128 | `desy` | `f` |
| +132 | `metax` | `f` |
| +136 | `metay` | `f` |
| +140 | `goalside` | `i` |
| +144 | `keepercatchtime` | `i` |
| +148 | `kickx` | `i` |
| +152 | `kicky` | `i` |
| +156 | `receivex` | `i` |
| +160 | `receivey` | `i` |
| +164 | `posxwhenkicked` | `i` |
| +168 | `posywhenkicked` | `i` |
| +172 | `offside` | `i` |
| +176 | `offsidewhenkicked` | `i` |
| +180 | `offsidealpha` | `f` |
| +184 | `offsidetime` | `i` |
| +188 | `selectionno` | `i` |
| +192 | `kickpower` | `f` |
| +196 | `kickdirection` | `f` |
| +200 | `lastkickdirection` | `f` |
| +204 | `directiontoball` | `i` |
| +208 | `distancetoball` | `f` |
| +212 | `directiontometaball` | `i` |
| +216 | `distancetometaball` | `f` |
| +220 | `jumpspotgood` | `i` |
| +224 | `directiontogoal_opp` | `i` |
| +228 | `directiontogoal_own` | `i` |
| +232 | `distancetogoal_opp` | `i` |
| +236 | `distancetogoal_own` | `i` |
| +240 | `teammateid` | `i` |
| +244 | `lastchangedteammateid` | `i` |
| +248 | `directiontoteammate` | `i` |
| +252 | `distancetoteammate` | `f` |
| +256 | `opponentid` | `i` |
| +260 | `directiontoopponent` | `i` |
| +264 | `distancetoopponent` | `f` |
| +268 | `passpotential` | `i` |
| +272 | `passison` | `i` |
| +276 | `calling` | `i` |
| +280 | `calltype` | `i` |
| +284 | `bonus` | `i` |
| +288 | `icalledforball` | `i` |
| +292 | `ihadashot` | `i` |
| +296 | `facing` | `i` |
| +300 | `spriterotation` | `f` |
| +304 | `currentanim` | `[]i` |
| +308 | `frame` | `i` |
| +312 | `lastframetime` | `i` |
| +316 | `imageframenumber` | `i` |
| +320 | `skincol` | `i` |
| +324 | `haircol` | `i` |
| +328 | `bootcolint` | `i` |
| +332 | `glovecolint` | `i` |
| +336 | `bootcol` | `$` |
| +340 | `glovecol` | `$` |
| +344 | `joy` | `:TJoy` |
| +348 | `obtext` | `$` |
| +352 | `replayframes` | `:TList` |
| +356 | `pace` | `f` |
| +360 | `dribbling` | `f` |
| +364 | `tackling` | `f` |
| +368 | `passing` | `f` |
| +372 | `heading` | `f` |
| +376 | `shooting` | `f` |
| +380 | `flair` | `f` |
| +384 | `slide_start` | `i` |
| +388 | `slide_delay` | `i` |
| +392 | `matchstats` | `:TStats_Match` |

`TPlayer`'s 134 methods/functions include the whole AI stack (`UpdateJoyAI`, `DoKickingAI`,
`ShootAI`, `PassAI`, `DoTacklingAI`, `DoHeadingAI`, `DoKeeperDiveAI`), collision
(`CheckPlayerContactAll`, `DoCollision`, `CheckFoul`), offside (`UpdateOffside`, `CheckOffside`,
`UpdatePositionWhenKickedAll`), the animation predicates, and the rating hooks (`AddStat`,
`UpdateMatchRatingAll`, `AddPlayerRating`). **Any attempt to reconstruct the match engine without
this type would have had to rediscover all of it.**

### 7.2 The 10 prefix-truncated types

Same root cause. In each case the decls present are correct and in order; the tail is missing.
All are BlitzMax runtime/driver types - **no game type is truncated.**

| Type | Decls in file | Decls in binary | First dropped |
|---|---|---|---|
| `TD3D7GraphicsDriver` | 1 | 31 | `_dd7` |
| `TD3D7ImageFrame` | 2 | 20 | `surface` |
| `TD3D7Graphics` | 6 | 20 | `_clipper` |
| `TBitmapFont` | 21 | 36 | `GetFaceImage` |
| `TVolume` | 9 | 18 | `ListVolumes` |
| `TBitMapChar` | 5 | 9 | `Image` |
| `ZipReader` | 4 | 7 | `ExtractFile` |
| `ZipRamStream` | 3 | 4 | `ZCreate` |
| `TZipEngineStreamFactory` | 2 | 3 | `CreateStream` |
| `zip_fileinfo` | 6 | 7 | `getBank` |

### 7.3 Corrected record-format specification

```
BBDebugScope : [u32 kind = 2] [char* scopeName] [BBDebugDecl ...] [u32 0]
BBDebugDecl  : [u32 kind] [char* name] [char* signature] [u32 payload]     ' 16 bytes
```

| kind | Meaning | `payload` |
|---|---|---|
| 0 | end-of-scope terminator | - |
| **1** | **Const** | **pointer to a BBString holding the value's *text*** |
| 3 | Field | byte offset in the object |
| 6 | Method | vtable slot |
| 7 | Function | vtable slot (static) |
| 2 | *scope header only* - never a declaration | - |
| 4, 5 | **do not occur** | - |

Const values are stored as text BBStrings even for `Int` consts - e.g. `TMap.RED` → `"-1"`,
`TTextStream.UTF8` → `"2"`, `D3DDEVTYPE_FORCE_DWORD` → `"2147483647"`.

**Build metadata recovered from the `z_blide_bg*` scopes** (BLIde project descriptors) - new this
pass, and it corroborates spec 07's "legacy BlitzMax, not NG" conclusion:

| Scope | `Name` | `VersionString` | `Platform` | `Architecture` | `DebugOn` |
|---|---|---|---|---|---|
| `…be3d` | **`New Star Soccer 5`** | **`5.1.0`** | `Win32` | `x86` | `0` |
| `…f638b5` | `Font Machine` | `1.5.1` | `Win32` | `x86` | `0` |
| `…1c02b` | `Untitled` | `0.0.1` | `Win32` | `x86` | `0` |

The shipped binary is **New Star Soccer 5 v5.1.0, Win32/x86, non-debug**, built with BLIde and
statically linking Font Machine 1.5.1.

### 7.4 Offset arithmetic - full sweep, zero findings

231 types with at least one field. Sizes used: `b`=1, `s`=2, `i`/`f`/`$`/`:T…`/`[]…`/`*…`/`(…)…`=4,
`l`/`d`=8.

* **Overlaps: 0.**
* **`instance_size` ≠ `last_field_offset + sizeof(last_field)`: 0** (all 231).
* Apparent "gaps": 28, and **all 28 are explained** - none is a hole in the model:
  * 24 are **inheritance** - the subclass's first own field starting at the superclass's
    `instance_size` (e.g. `TClub`/`TNation` 8→96 over `TBase_Team`; seven `TGadget` subclasses
    8→92; four `TTrainingObject` subclasses 8→36).
  * 4 are **real alignment padding after a sub-4-byte field**, all internally consistent:
    `TSnowFlake` (`t:b` @+32, `w:i` @+36 → 3 bytes pad, `instance_size` 56 ✔),
    `SZIPCentralFileHeader` (2 bytes after a `s`), `zip_fileinfo`, `TMyStream`.
* 11 fields carry a `?IUnknown`-style COM signature (`?IDirect3DDevice7` etc.); all are pointers
  and all size to 4 without breaking any `instance_size`.

Spot-checked sizes, all exact: `TBase_Team` 96, `TClub` 116, `TNation` 116, `TKitStrings` 28,
`TCompetition` 116, `TFormation` 40, `TBall` 176, `TProfile` 544, `TPlayer` 396, `TContinent` 36,
`TPromotionPlace` 20, `TTeam` 64, `TFixture` 68, `TGadget` 92, `TTrainingObject` 36.

**This section produced no discrepancies. The layout algebra in `object_model.json` is correct.**

---

## 8. `TProfile` (134 fields) vs the career systems of spec 03

### 8.1 Systems present in both - confirmed

| Spec 03 system | `TProfile` fields | Offsets | Verdict |
|---|---|---|---|
| §5.1 seven trainable abilities | `pace`, `shooting`, `passing`, `tackling`, `heading`, `dribbling`, `flair` | +164…+188 | ✔ exactly 7 |
| §5.2 ten match ratings | `crossing`, `freekicks`, `corners`, `positioning`, `shortpassing`, `longpassing`, `aggression`, `longshots`, `finishing`, `penalties` | +196…+232 | ✔ exactly 10 |
| §5.2 (implied) | `temp_*` mirror of all ten | +500…+536 | ✔ per-match deltas |
| §7.1 Items | `items:[]i` | +240 | ✔ |
| §7.2 Vehicles | `vehicles:[]i` | +244 | ✔ |
| §7.3 Property | `property:[]i` | +248 | ✔ |
| §7.4 Boot Shop | `boots:[]i` | +236 | ✔ |
| §8 match-prep consumables | `takenpainkillers`, `shinpads`, `boughtmusic`, `boughtgame`, `boughtfilm`, `drugs`, `NRG`, `booze` | +352…+392 | ✔ |
| §8.3 skipping a match | `matchskipped` | +476 | ✔ |
| §9 energy / injury | `energy:f`, `injury`, `freetime` | +348, +364, +368 | ✔ |
| §10.1 six relationships **+ fame** | `relationboss/team/fans/friends/girlfriend/sponsors`, `relationfame` | +260…+284 | ✔ exactly 7, matching spec 03's "seven tracked scalars" |
| §10.4 spending time | `lastspendtimefriends`, `lastspendtimegirlfriend` | +296, +300 | ✔ |
| §10.6 girlfriend life-cycle | `girlscandalrating` | +292 | ✔ |
| §10.7 captaincy | `captain` | +288 | ✔ |
| §11 sponsorship | `sponsor_amount:[]i`, `sponsor_expires:[]i` | +252, +256 | ✔ |
| §13 boss / physio reports | `bossreport`, `physioreport`, `coachreport`, `coachrep_boss/team/fans/sponsors/fame` | +84…+112 | ✔ |
| §14 news | `newsheadline`, `newsrating`, `newsmotm`, `webheadline` | +68…+80 | ✔ |
| §15 contract | `contractexpires/wage/goalbonus/assistbonus/cleanbonus`, `last/thisweeks*bonus`, `lastweeksshirtsales` | +116…+160 | ✔ |
| §15.3 transfer / loan | `transferlisted`, `desiredcontinentid/nationid/leagueid/clubid`, `onloanfrom`, `loanexpires`, `interestedclubs:[]i`, `lasttransferdate` | +308…+332, +420, +424 | ✔ |
| §16.4 gambling addiction | `gambling` | +360 | ✔ |
| §18.1 interview mini-game | `interviewskill`, `interviewchance` | +192, +480 | ✔ |
| §19 discipline | `currentyellowsclub/continent/international`, `banclub/bancontinent/baninternational` | +396…+416 | ✔ |
| §20.2 achievements | `achievements:[]i` | +444 | ✔ |
| §20.4 online / premium | `gNetStatus`, `skillshash`, `passhash`, `premiumhash`, `lastconnecthash` | +8, +428…+440 | ✔ |
| career history | `history:TList` (of `THistory`), `careerstats:TList` (of `TStats_Team`) | +448, +64 | ✔ |
| tips / help | `tipcount`, `helppages:[]i` | +452, +456 | ✔ |

### 8.2 In spec 03 but **absent** from `TProfile`

| Spec 03 system | Expected field | Reality | Assessment |
|---|---|---|---|
| §17 Horse racing / Stable | horse ownership, stable state | **none** | **D-12.** State lives on `THorse` (27 fields incl. `owned` +80, `betamount` +100, `betprice` +104, `betwinnings` +108, `form:[]i` +72). The horse roster is global, not per-profile. |
| §20.3 Difficulty | `difficulty` | **none**, and `TOptions` has **zero fields** | **D-13.** `UNCERTAIN:` persistence location. |
| §6 Training | training-session state | **none** | Expected - `TTraining` also has 0 fields; training is transient screen state. **Not** a discrepancy. |
| §10.5 Dilemma | dilemma state | **none** | Expected - resolved within the screen. **Not** a discrepancy. |
| §12 in-match boss shouts | - | `TBossMessage` (11 fields) | Expected - match-scoped. **Not** a discrepancy. |
| §16.1-16.3 casino games | chip balance | **none** | Expected - `TRoulette`/`TBlackJack`/`TSlotMachine` carry their own state; money is `bank` (+40). **Not** a discrepancy. |

### 8.3 In `TProfile` but **not** covered by spec 03

The reverse direction, as required. None is a contradiction - they are gaps in spec 03's coverage,
which is language-tag-derived and therefore blind to anything without a UI string.

| Field | Offset | Note |
|---|---|---|
| `saveversion` | +12 | `$` - save-file schema version. **Load-bearing for save compatibility; spec 03 never mentions it.** |
| `dbName` | +24 | `$` - database/profile name, distinct from `name` (+20). |
| `playbuttontype` | +304 | UI mode selector for the play button. |
| `newstarselno` | +44 | the player's own selection number in the formation grid - ties `TProfile` to `TFormation` (§5.1). |
| `side` | +52 | side/footedness; `position` (+48) is separate. |
| `internationalselno` | +56 | separate selection number for national-team duty. |
| `prematchsaved` | +540 | autosave-before-match flag. |
| `timecheck` | +496 | `UNCERTAIN:` semantics; shape suggests a clock-tamper check. |
| `matchesleft`, `matcheswait` | +488, +492 | match-scheduling counters. |
| `formationchanged`, `selectedformatch` | +484, +472 | per-fixture selection state. |
| `oldbossrel`, `oldteamrel`, `oldfansrel` | +336…+344 | previous-week relationship snapshot (drives the report deltas in §13). |
| `playercols:TPlayerColours` | +36 | `skin:i`, `hair:i`, `boots:$`. |
| `mynation`, `myclub`, `mylastfixture` | +460…+468 | resolved object references (runtime caches of `nationid` / `clubid`). |
| `retired`, `bank`, `date`, `nationid`, `clubid` | +60, +40, +16, +28, +32 | core career scalars. |

**Neither direction produced a contradiction of spec 03's *content*.** The two asymmetries (D-12,
D-13) are about *where state lives*, and both are resolvable.

---

## 9. What a reconstruction must change

1. **Re-run the reflection extractor with kind 1 = Const handled**, then regenerate
   `extracted/object_model.json`, `docs/specs/07-object-model.md` and
   `src/generated/types_skeleton.bmx`. Until then the model is missing `TPlayer` and 17 others.
2. **Correct spec 07's record-format table** (kind 1 = Const with a text-BBString payload; kinds
   2/4/5 are not declaration kinds; there are no Globals).
3. **`src/nss5/teams.bmx`**: add the `labelname` / `labelshortname` derivation from §3.3.
4. **Make loaders column-name-driven, not field-ordinal-driven** - `labelname` (both types) and
   `TCompetition.priority` sit inside the file-backed offset run.
5. **The shared TSV loader must tolerate** a trailing TAB (Competitions, PromotionPlaces), a BOM
   (Achievements), the `//` sentinel, and malformed colour cells.
6. **Reproduce `GetRow`'s cascade and the `< 11` tactics cap literally**, not "corrected"
   versions - both are observable behaviour.
7. **Ship `4-1-4-1.tac` and `4-2-3-1.tac` anyway** (byte-faithful asset set) but do not wire ids to
   them; and reproduce the dead `4-4-2.tac` fallback path.
8. **Do not model Engine.ini values as object fields.** They are module globals; §6.2 gives the
   authoritative key list and addresses for cross-checking.

---

## 10. Reproduction

```sh
PY="<home>/AppData/Local/Programs/Python/Python313/python.exe"
OBJ="<repo>/tools/blitzmax/BlitzMax/MinGW32x86/bin/objdump.exe"
EXE="C:/Program Files (x86)/Steam/steamapps/common/New Star Soccer 5/NSS5.exe"

# section table
"$OBJ" -h "$EXE"

# any function, given a VA from extracted/vtable_map.tsv
"$OBJ" -d -M intel --start-address=0x4d8aa4 --stop-address=0x4d8aba "$EXE"   # GetCol
"$OBJ" -d -M intel --start-address=0x4d8aba --stop-address=0x4d8af3 "$EXE"   # GetRow
"$OBJ" -d -M intel --start-address=0x4d8a4f --stop-address=0x4d8aa4 "$EXE"   # GetSelectionNoFromSeg
"$OBJ" -d -M intel --start-address=0x4d83cc --stop-address=0x4d8783 "$EXE"   # UpdateLabels
"$OBJ" -d -M intel --start-address=0x4d8783 --stop-address=0x4d8948 "$EXE"   # LoadTactics
"$OBJ" -d -M intel --start-address=0x4dce33 --stop-address=0x4dd10a "$EXE"   # GetStyleId_Mobile
"$OBJ" -d -M intel --start-address=0x4bfea2 --stop-address=0x4c09f9 "$EXE"   # CreateClub
"$OBJ" -d -M intel --start-address=0x5092e3 --stop-address=0x509acd "$EXE"   # CreateCompetition
"$OBJ" -d -M intel --start-address=0x50c926 --stop-address=0x50cb14 "$EXE"   # GetString* enums
```

`VA → file offset`: `off = va - 0x5CF000 + 0x1CCE00` for the `data` section;
`off = va - 0x4BA000 + 0xB8C00` for `code`.

The independent scope re-parser: scan `data` for `u32 == 2` whose following pointer resolves to an
ASCII identifier, then consume 16-byte declarations while `kind ∈ {1,3,6,7}` until a `kind == 0`
terminator. **Accepting kind 1 is the whole fix.**
