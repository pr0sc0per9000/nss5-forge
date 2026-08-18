# The game database

> **Source:** `TCompetition.LoadData` @ 0x00509c2d (VERIFIED) · `TCompetition.CreateCompetition` @ 0x005092e3 (VERIFIED) · `TPromotionPlace.LoadData` @ 0x00525f17 (VERIFIED) · `TAchievement.LoadData` @ 0x0058d1a5 (VERIFIED) · `TNames.SetUp` @ 0x004c71dc (VERIFIED) · `TScreen_Stable.LoadData` @ 0x00587c3a (VERIFIED) · `THorse.Create` @ 0x0058a36b (VERIFIED) · `TClub.LoadData` @ 0x004c09f9 (VERIFIED) · `TNation.LoadData` @ 0x004be1f3 (VERIFIED) · `TContinent.LoadData` @ 0x00508b7d (VERIFIED)
> **Confidence:** HIGH
> **Last checked:** 2026-08-15

Every "quirk" and enum-decode claim below cites its own function inline; the confidence line
above describes the file formats and loader mechanics, which are proven by byte-exact code.
A handful of narrower claims (what `compstatus`'s general default means, exactly how the
0-14 `nat_column` search behaves for edge inputs) are individually marked `UNCERTAIN:`.

This is the map to every loose data file the game reads at startup - the thing to open before
touching any of it in a hex editor or a spreadsheet. `Clubs.csv`, `Nations.csv` and
`Continents.csv` already have an excellent, exhaustive treatment in
[`docs/specs/01-clubs-and-nations.md`](../../specs/01-clubs-and-nations.md) (column-by-column,
every data defect catalogued, the kit-style enum fully decoded) - this document does not repeat
that, only summarises it and points there. The five files that had **no** documentation at all - 
`Competitions.csv`, `PromotionPlaces.csv`, `Achievements.csv`, `Names.csv` and `Horse.ini` - get
full treatment here, straight from the byte-exact loader bodies in `src/recovered/`.

---

## 1. The shared file format

All eight files live in `GameMedia/Data/`. Six of them share one convention almost exactly:
TAB-separated, a discarded header row, and a sentinel line reading exactly `//` that means
"stop reading, ignore anything after this." Two files (`Achievements.csv`, `Names.csv`) skip
the sentinel and just read to end-of-file. `Horse.ini` isn't a CSV at all - see §7.

| File | Size | Data rows | Columns | Terminator | Loader |
|---|---:|---:|---:|---|---|
| `Clubs.csv` | 1.4 MB | 5,436 | 38 | `//` + 37 tabs | `TClub.LoadData` @ 0x004c09f9 |
| `Nations.csv` | 55.7 KB | 211 | 38 | `//` | `TNation.LoadData` @ 0x004be1f3 |
| `Continents.csv` | 540 B | 6 | 7 | `//` | `TContinent.LoadData` @ 0x00508b7d |
| `Competitions.csv` | 76.6 KB | 1,028 | 20 | `//` | `TCompetition.LoadData` @ 0x00509c2d |
| `PromotionPlaces.csv` | 30.4 KB | 2,067 | 3 | `//` | `TPromotionPlace.LoadData` @ 0x00525f17 |
| `Achievements.csv` | 701 B | 100 | 2 | *(none - ends at EOF)* | `TAchievement.LoadData` @ 0x0058d1a5 |
| `Names.csv` | 239.9 KB | 2,900 | 26 (13 nation pairs) | *(none - ends at EOF)* | `TNames.SetUp` @ 0x004c71dc |
| `Horse.ini` | 3.6 KB | 250 lines | 1 (just a name) | *(none - ends at EOF)* | `TScreen_Stable.LoadData` @ 0x00587c3a |

Every one of these loaders has the identical opening shape, confirmed byte-for-byte in five of
them (`TClub`, `TNation`, `TContinent`, `TCompetition`, `TPromotionPlace` all compile to the
same 285/360/219-byte pattern):

```
If <list> <> Null Then <list>.Clear()          ' wipe whatever was loaded before
If Not a0 Then a0 = ReadFile("utf8::" + g_datapath + "GameMedia/Data/<file>.csv")
If Not a0
    Notify("Could not load GameMedia/Data/<file>.csv", 0)   ' or TScreen.DoMessage for Nations/Competitions
    End                                          ' the game exits outright - a missing data
EndIf                                            ' file is not something it tries to survive
ReadLine(a0)                                     ' discard header row, never inspected
While Not Eof(a0)
    Local l:String = ReadLine(a0)
    If l = "//" Then <log count>; Return 0       ' sentinel - everything after is ignored
    Create<Thing>(l)                             ' one row -> one object, parsed positionally
Wend
CloseStream(a0)  ' or CloseFile(a0) -- both are used, no functional difference observed
```

**A missing or unreadable data file is fatal.** Every loader above calls BlitzMax's `End`
(process exit) if `ReadFile` fails - there is no fallback content, no empty-league behaviour.
Delete `Competitions.csv` and the game does not start.

**Columns are read positionally, by call order, never by the header row's text.** The header
row is read once and discarded unconditionally. Reordering columns in a modded file silently
corrupts every field after the swap; renaming a header cell does nothing at all.

**Load order**, confirmed by the cross-references between loaders (`TPromotionPlace.AddToParentLists`
resolves both `parentid` and `promotiontoid` against `TCompetition.SelectById` immediately, so
every competition must already exist):

```
Continents.csv -> Nations.csv -> Clubs.csv -> Competitions.csv -> PromotionPlaces.csv
```

`Achievements.csv` is loaded separately when a career profile is created/loaded (it fills in
`TProfile.achievements`, not a standalone world list). `Names.csv` is **not** loaded once at
startup at all - see §6, it is re-read from disk every time a name is needed. `Horse.ini` is
read only when the Stable screen opens with no existing save data - see §7.

---

## 2. Clubs.csv / Nations.csv / Continents.csv - quick reference

Full column-by-column detail, every data defect, and the kit-style/formation/climate/skin enum
decodes all live in **`docs/specs/01-clubs-and-nations.md`** - that document is exhaustive and
this one does not repeat it. Condensed for orientation:

| File | Rows | Key | Notable columns |
|---|---:|---|---|
| `Continents.csv` | 6 | `id` 1-6 | `name`, `tla`, `federationname`, `strength` 50-90 |
| `Nations.csv` | 211 | `id` 1-211 | `strength` 10-96, `rivalid1-3`, kit×4, `formation` 1-based, `climate` 0-4, `primaryskin`/`secondaryskin` 0-4 |
| `Clubs.csv` | 5,436 (409 gaps) | `id` 1-5,845 | `strength` 6-99, `nationid`, `leagueid` → `Competitions.id`, `continentalcompid` → `Competitions.id`, `bteamof` |

The two facts from that spec worth repeating here because they matter to every file below too:
**`0` always means "no reference"** for every foreign-key column across every file in this
database (never a valid id - ids start at 1 everywhere), and **kit-style columns hold ASCII
tokens (`PLAIN`, `TRIM`, `STRIPES`…), not integers** - the only place an integer style code
exists is inside the engine's own runtime object.

`Clubs.leagueid` and `Clubs.continentalcompid` are the join to the file covered next - 
every club's domestic league and continental-competition entry point is a row in
`Competitions.csv`.

---

## 3. Competitions.csv - the tournament calendar

### What it is

One row is one competition **instance** - not "the Premier League" as a concept, but "the
Premier League, this specific 38-game round-robin." A domestic pyramid is many rows (one per
division), a cup is one row per round (Quarter Final, Semi Final, Final are three separate
competition rows, chained together - see §3.4), and international tournaments are built from
several rows too: a virtual seeding "Pool", then a real Group Stage, then knockout rounds.
1,028 rows cover the entire world's football calendar - domestic leagues and cups for every
nation with clubs, all continental club competitions, and the full World Cup / continental
international tournament ladders.

### 3.1 Column reference

Confirmed field-for-field against `TCompetition.CreateCompetition` @ 0x005092e3 (VERIFIED),
which reads the 20 header columns in this exact order into the 20 matching `TCompetition`
fields (`object_model.json` offsets `+0x08`…`+0x5C`):

| # | Column | Type | Meaning |
|---|---|---|---|
| 1 | `id` | Int | Primary key. Referenced by `Clubs.leagueid`/`continentalcompid`, `PromotionPlaces.parentid`/`promotiontoid`. Row rejected (`Return 0`, no object created) if `id < 1`. |
| 2 | `name` | String | Full name, e.g. `Premiership`, `World Cup Pool`. |
| 3 | `tla` | String | Short code, e.g. `ENG PREM`. Also used as a literal match list - 8 exact TLA strings (`EURO1`, `UEFA WCQ`, `EUROQF`, `EUROSF`, `EUROF`, `EURO QF`, `EURO SF`, `EURO FNL`) force `compstatus = 1` regardless of the CSV's own `compstatus` column - see §3.3. |
| 4 | `locale` | Enum(int) | `0`=Nation, `1`=Continent, `2`=World. Decoded by `TCompetition.GetStringLocale` @ 0x0050c926 (VERIFIED). |
| 5 | `level` | Enum(int) | `0`=Club, `1`=International. Decoded by `TCompetition.GetStringLevel` @ 0x0050c97d (VERIFIED). |
| 6 | `based` | Int | FK, meaning depends on `locale`: `locale=0` → `Nations.id`, `locale=1` → `Continents.id`, `locale=2` → unused (World). Decoded (as text) by `TCompetition.GetStringBased` @ 0x0050c9c0 (VERIFIED). |
| 7 | `comptype` | Enum(int) | `0`=League, `1`=KO (knockout), `2`=BestPlaced, `3`=Pool, `4`=LeagueCont, `5`=RegionalSort. Decoded by `TCompetition.GetStringCompType` @ 0x0050ca1a (VERIFIED). See §3.2 for what each does to the other columns. |
| 8 | `startyear` | Int | 0-4. Which save-game year this row activates in; compared against the profile's current year in `TCompetition.SetUpCompetitionsAll`. |
| 9 | `startweek` | Int | 1-52 (raw), the in-season week the competition begins. Silently reduced by repeated `-50/-40/-30/-20/-10` for pure domestic leagues - see §3.3. |
| 10 | `duration` | Int | 0-104. Number of match-days, e.g. 38 for a 20-team double round-robin. Forced to ≤1 for `comptype=1` (KO). |
| 11 | `recurring` | Int | `1` (988 rows) = every year, `2` (5 rows), `4` (35 rows, e.g. the World Cup and the Euros). `INFERRED` from the data pattern - no consuming function was traced, so treat the "every N years" reading as likely but unproven. |
| 12 | `primarymatchday` | Int | 1-7, or `99` = not applicable. Clamped to 1-7 for club leagues; set to a fixed day for long international rounds - §3.3. |
| 13 | `secondarymatchday` | Int | Same domain as above - the secondary fixture day of the week (e.g. Wednesday alongside a Saturday primary). |
| 14 | `groups` | Int | Number of parallel groups. Clamped to a minimum of 1 on load (a `0` in the file becomes `1`). |
| 15 | `rounds` | Int | Round-robin legs (1 or 2 = single/double). **Forced to exactly `1` whenever `comptype = 1`** (KO), overwriting whatever value the CSV row carries. |
| 16 | `legs` | Int | 0/1/2 - home-and-away leg count for a single KO tie. |
| 17 | `townregion` | Enum(int) | `0` (998 rows) = none, `1`=North, `2`=East, `3`=South, `4`=West. Decoded by `TCompetition.GetStringRegion` @ 0x0050caad (VERIFIED). Used for splitting a country into regional lower-division groups. |
| 18 | `compstatus` | Int | Observed range 0-6 in shipped data, plus 2 rows at `70` (see §3.5). For pure domestic leagues this value is **recomputed at every load** by `TCompetition.ResetCompStatusAll` @ 0x0050e2bf (VERIFIED) into the division tier (1 = top flight, 2 = second tier, …) - the CSV value is only ever the initial seed. `UNCERTAIN:` what a nonzero `compstatus` means for the many rows `ResetCompStatusAll` never touches (cups, continental comps, internationals). |
| 19 | `minstrength` | Int | 0-99. Club/entry strength gate - sometimes a floor of a range (Premiership: 75), sometimes a fixed exact cutoff paired with an equal `maxstrength` (Copa Libertadores Group Stage: 45/45). |
| 20 | `maxstrength` | Int | 0-99. Paired with `minstrength`. |

Two fields are **not** in the CSV at all, despite existing on `TCompetition`: `labelname`
(derived - full `name` or `tla` depending on a module-wide display-mode flag, the same flag
`TClub.CreateClub` uses) and `priority` (never read from the row; computed after loading - see
§3.3).

### 3.2 What `comptype` actually does to a row

Each value changes how the other 19 columns are treated, not just what gets printed in a combo
box:

| `comptype` | Meaning | Effect on load |
|---|---|---|
| 0 | League | Normal round-robin scheduling. |
| 1 | KO (knockout) | `duration` clamped to ≤1; `rounds` **forced to 1** no matter what the CSV says. |
| 2 | BestPlaced | `startweek=1`, `duration=0`, both matchdays `=99` - this row is never itself played, it only selects the best-ranked losers from elsewhere. |
| 3 | Pool | Same forced reset as BestPlaced - a virtual seeding bucket (e.g. `World Cup Pool`, id 10) with no fixtures of its own. |
| 4 | LeagueCont | A continental group-style competition that isn't nation-based. |
| 5 | RegionalSort | Same forced reset as BestPlaced/Pool. |

### 3.3 The load-time adjustments - priority, startweek, compstatus, the TLA override

* **`priority` is computed, never loaded.** `TCompetition.SetPriority` @ 0x0050d498 (VERIFIED)
  runs immediately after every row parses:

  | `level` | `locale` | `comptype` | → `priority` |
  |---|---|---|---:|
  | 1 (International) | - | - | 1 |
  | 0 (Club) | 1 (Continent) or 2 (World) | - | 2 |
  | 0 (Club) | 0 (Nation) | 0 (League) | 4 |
  | 0 (Club) | 0 (Nation) | 1 (KO) | 3 |
  | 0 (Club) | 0 (Nation) | 2, 3 or 5 | 5 |
  | 0 (Club) | 0 (Nation) | 4 | 4 |

  International football always outranks (lowest number = highest priority) everything else;
  domestic cups outrank domestic leagues; the virtual seeding rows rank lowest.

* **`startweek` is silently rewritten** for the common case (`comptype=0`, `locale=0`,
  `level=0` - an ordinary domestic league): five independent checks subtract 50, then 40, then
  30, then 20, then 10 if the (already-reduced) value still exceeds that threshold. A raw value
  of 56 becomes 6; a raw value of 24 becomes 4. This is not one `Mod 10` - it is five
  sequential `If > N Then :- N` statements, confirmed against the disassembly.

* **`compstatus` is recomputed for domestic leagues.** `ResetCompStatusAll` walks every nation,
  then every one of that nation's `level=0, locale=0, based=<nation>` rows **in file order**,
  and assigns `compstatus = 1, 2, 3, …` - literally "the division number", counting only
  `comptype=0` rows and skipping the counter increment (but not the assignment) for
  `townregion` 1 or 2. `comptype=4` rows always get `compstatus=1`; anything else gets `0`.
  Real example: England's `Premiership` (id 2270) carries `compstatus=1` in the shipped file,
  which matches - it is nation 62's first `comptype=0` row in file order.

* **Eight exact TLA strings force `compstatus=1`** regardless of the loaded value:
  `EURO1`, `UEFA WCQ`, `EUROQF`, `EUROSF`, `EUROF`, `EURO QF`, `EURO SF`, `EURO FNL`. This is a
  simple string-equality chain in `CreateCompetition`, not a lookup table - renaming one of
  those TLAs in a modded file would silently drop this override.

### 3.4 Real rows, decoded

```
id=2270  Premiership          locale=0(Nation) level=0(Club) based=62(England)
         comptype=0(League)   startweek=6  duration=38  recurring=1
         groups=1  rounds=2   compstatus=1   minstrength=75  maxstrength=99

id=7810  Copa Libertadores Group Stage   locale=1(Continent) level=0(Club) based=4(S.America)
         comptype=0  groups=8  rounds=2  compstatus=1  minstrength=45  maxstrength=45

id=10    World Cup Pool       locale=2(World) level=1(International) based=0
         comptype=3(Pool)     startweek=1  duration=0  primarymatchday=99  secondarymatchday=99

id=9500  Copa Sudamericana First Stage   comptype=1(KO)  rounds=1  legs=2  compstatus=2
```

`duration=38` for the Premiership is the real 38-match Premier League season length reproduced
exactly. Strength gates can be a genuine range (Premiership clubs 75-99) or a single fixed cutoff
written as an equal min/max pair (Libertadores/Europa League group stages both use 45/45).

### 3.5 What we do not know yet

* `UNCERTAIN:` the general-purpose meaning of `compstatus` for the majority of rows that
  `ResetCompStatusAll` never touches (cups, continental comps, `level=1` internationals). Two
  rows carry `compstatus=70`, well outside every other observed value (0-6) - not explained by
  any function read so far.
* `UNCERTAIN:` exactly which function consumes `recurring` to decide whether a competition
  actually runs in a given save year. The 4-year pattern lining up with the World Cup and Euros
  is `INFERRED` from the data, not proven by reading a scheduler.
* `UNCERTAIN:` what actually consumes `minstrength`/`maxstrength` at runtime (club selection
  for continental entry? promotion eligibility?). The debug strings `>>> clubstrength = ` and
  `ClubStrength:` (noted in `docs/specs/01-clubs-and-nations.md` §12) are the likely entry point
  and were not traced here.
* The gap: no function that actually **schedules** a full season's fixture calendar from these
  columns (beyond `CreateFixtureListLeague`/`CreateFixtureListKO`, which exist in
  `src/recovered/` but were not read for this document) has been turned into prose yet.

---

## 4. PromotionPlaces.csv - how one competition feeds another

### What it is

This file is the wiring between competition rows: "the team that finishes in **this** place in
competition A goes into competition B." Three columns, 2,067 rows, one row per promotion/
qualification link. It is what turns 1,028 isolated competition rows into a connected pyramid - 
relegation from the Premiership into the Championship, a cup round's winner advancing to the
next round, a nation's Cup winner qualifying for next year's continental competition.

### 4.1 Column reference

Confirmed against `TPromotionPlace.CreatePromotionPlace` @ 0x00525e1b (VERIFIED) - three fields,
read in this order, no validation beyond `NextFieldInt`:

| # | Column | Type | Meaning |
|---|---|---|---|
| 1 | `parentid` | Int | FK → `Competitions.id`. The competition a team is moving *from*. |
| 2 | `place` | Enum(int) | Either a literal finishing position (1-32, observed) **or** one of nine special codes 100-108 - see §4.2. |
| 3 | `promotiontoid` | Int | FK → `Competitions.id`. The competition a team is moving *to*. |

Immediately after construction, `TPromotionPlace.AddToParentLists` @ 0x00526273 (VERIFIED)
resolves both ids via `TCompetition.SelectById` and links the object into **both**
competitions' lists (`lpromotionplaces` on the source, `lplacesthatpromotetome` on the
destination). **If either id fails to resolve to a real competition, the row is silently
dropped** (`Else Return 0`) - no error, no log line.

### 4.2 The `place` code table

Decoded from `TPromotionPlace.GetStringPlace` @ 0x005262eb (VERIFIED):

| `place` | Meaning | Rows in shipped data |
|---:|---|---:|
| 1-32 | Literal finishing position in the parent competition | 1,153 |
| 100 | All teams (whole division feeds forward) | 248 |
| 101 | Teams not in a continental competition | 1 |
| 102 | Highest-ranked team not in a continental competition | 1 |
| 103 | All winning teams (KO round winners advance) | 536 |
| 104 | All losing teams (KO round losers, e.g. into a consolation bracket) | 60 |
| 105 | Winning team, else the losing team | 1 |
| 106 | Winning team, else back into the league | 66 |
| 107 | Teams already in a continental competition | 1 |
| 108 | Losing team, else back into the league | 1 |

`place=103`/`104` are how a cup bracket is actually threaded round-to-round: confirmed by
`TCompetition.GetNoofTeamsInRound` @ 0x0050cc87 (VERIFIED), which for a `place=103` or `104`
promotion source computes the **feeding round's team count divided by two** - exactly what a
straight single-elimination bracket needs (half the entrants become winners, half become
losers, each half seeds the next stage).

### 4.3 What it means in play

The literal-position codes (1-32) carry the overwhelming majority of rows and are what makes
promotion and relegation work - a `place=1..N` row from a lower division's competition id into
a higher division's competition id, and vice versa for relegation. The special codes are what
let three-team-per-round cups, group-into-knockout transitions, and "loser's second chance"
brackets exist without a literal position number, since a cup round doesn't have a fixed
"7th place."

### 4.4 What we do not know yet

* `UNCERTAIN:` the exact runtime meaning of codes 101, 102, 105, 107, 108 - each appears in
  only a single row of the shipped data, so no pattern could be cross-checked the way 100/103/
  104/106 could. `TCompetition.DoPromotionPlaces` (present in `src/recovered/` but not read for
  this document) is the function that would confirm them.
* `UNCERTAIN:` whether `place` values above 32 but below 100 are reachable/meaningful - none
  appear in the shipped file, so the boundary between "highest real finishing position" and
  "lowest special code" was never exercised by real data.

---

## 5. Achievements.csv - the achievement list

### What it is

This is not the achievement *text* - that lives in `Languages.csv` as 100 `CACHIEVEMENT_1`
through `CACHIEVEMENT_100` tags (confirmed present, all 100, in
`GameMedia/Languages/Languages.csv`). `Achievements.csv` is purely a **display-order table**:
which achievement id shows in which position in the achievements list UI.

### 5.1 Column reference

Two columns, 100 rows, `id` and `sortindex` both running 1-100 and (in the shipped file)
identical to each other on every row. Confirmed by `TAchievement.LoadData` @ 0x0058d1a5
(VERIFIED), which reads exactly `id` then `sortindex` per row via `NextFieldInt`.

| # | Column | Type | Meaning |
|---|---|---|---|
| 1 | `id` | Int | Achievement id. Also the numeric suffix of its localisation key, `CACHIEVEMENT_<id>`. A row with `id=0` is discarded immediately (`g_achievements.Remove(a)` on the object that was just added - the object is created, then instantly removed). |
| 2 | `sortindex` | Int | Display position. Written into `g_profile.achievements[id - 1]` - i.e. it is actually stored **per save profile**, not just used for sorting a static list. |

### 5.2 The backfill quirk - real, but effectively dead code

If the file (or a stream-based save load) produces **fewer than 100** distinct achievement
rows, the loader runs a repair pass - but it only checks **ids 1 through 10**, not all 100:

```
If n < 100
    For Local i:Int = 1 To 10          ' NOT "1 To 100" -- confirmed against the disassembly
        <find achievement with id = i in the list; if absent, create a stub for it>
    Next
EndIf
```

This never fires against the shipped `Achievements.csv` (all 100 ids are present, no gaps).
It matters for modding: **deleting or renumbering any row from id 11 onward, with fewer than
100 total rows remaining, will not be repaired** - only a missing id in 1-10 gets a stub
object created (with `txt` filled from `GetText("CACHIEVEMENT_" + id)` but no other fields
set). This is reproduced faithfully as a load-bearing detail of the original, not "fixed" - 
see rule 3 of the reconstruction method.

**Also worth preserving:** the `"//"` sentinel check exists in this loader's code (`If ln =
"//" Then ...`), but the shipped `Achievements.csv` has no `//` line - it simply ends at EOF
after row 100, confirmed byte-for-byte (`od -c` shows the file ending `100\t100\r\n` with
nothing after). The sentinel branch, when it *does* fire (e.g. on a modded file with an
appended `//` line), **never calls `CloseStream`** - every code path through it returns before
reaching the `CloseStream` at the bottom of the function. `ORIGINAL BUG` (or deliberate
shortcut), reproduced as written.

### 5.3 What we do not know yet

* `UNCERTAIN:` how `sortindex` is actually consumed for display ordering - no rendering
  function was read for this document, only the loader.
* `UNCERTAIN:` under what real gameplay circumstance the file would ever legitimately be
  missing an id 1-10 (a fresh install always ships the complete 1-100 file) - this path may
  only matter for corrupted/hand-edited saves or mods.

---

## 6. Names.csv - the player-name generator's word list

### What it is

This is the pool of first and last names the game draws from when it generates a player. It is
organised as **one pair of columns per nation**, not one row per name - reading it is
column-major, not row-major. Twelve nations get a dedicated first-name/last-name pool each;
every other nation in the game (199 of the 211 in `Nations.csv`) has **no pool of its own at
all** and silently falls back to England's.

### 6.1 File shape

The header row is 26 cells: 13 nation labels, each followed by one blank cell - 
`9_Argentina␠␠20_Belgium␠␠28_Brazil␠␠…␠␠156_RussiaB␠␠` (the blank cell is the *label* for the
paired last-name column, which the loader never reads text from - it only reads the label of
the even-indexed cell). The label format is `<NationId>_<Name>`, and the number is what
`TNames.SetUp` @ 0x004c71dc (VERIFIED) searches for: it walks the header, computes
`Int(cell[..cell.Find("_")])` for each cell, and stops at the first one equal to the requested
nation id. That column becomes the first-name pool; the very next column (always the pool's
odd-indexed neighbour) becomes the last-name pool.

| Header label | Nation id | Cross-checked against `Nations.id` |
|---|---:|---|
| `9_Argentina` | 9 | Argentina ✓ |
| `20_Belgium` | 20 | Belgium ✓ |
| `28_Brazil` | 28 | Brazil ✓ |
| `62_England` | 62 | England ✓ |
| `75_Germany` | 75 | Germany ✓ |
| `71_France` | 71 | France ✓ |
| `95_Italy` | 95 | Italy ✓ |
| `151_Portugal` | 151 | Portugal ✓ |
| `156_Russia` | 156 | Russia ✓ |
| `164_Scotland` | 164 | Scotland ✓ |
| `175_Spain` | 175 | Spain ✓ |
| `193_Turkey` | 193 | Turkey ✓ |
| `156_RussiaB` | 156 | Russia again - a **second, Cyrillic-script** name pool under the same nation id (`INFERRED` from content: this column pair holds Cyrillic text, e.g. `Аарон`/`Абакумов`, where the plain `Russia` columns hold Latin transliterations, e.g. `Abagor`/`Abakumov`). |

Below the header, each of the 2,900 data rows is one "row" of the table, but the columns are
**ragged** - every nation's name list is a different length, and TAB-separated CSV forces every
row to the same column count, so shorter lists are padded with empty cells for the rest of the
file. The table's row count (2,900) is set by whichever single column has the most names - 
here, Germany's last-name list, which is non-empty on all but a handful of rows.

### 6.2 Pool sizes

Counted directly from the file (non-empty cells per column):

| Nation | First names | Last names |
|---|---:|---:|
| Argentina (9) | 135 | 157 |
| Belgium (20) | 168 | 150 |
| Brazil (28) | 1,795 | 1,722 |
| England (62) | 319 | 924 |
| Germany (75) | 232 | 2,900 |
| France (71) | 337 | 703 |
| Italy (95) | 258 | 2,416 |
| Portugal (151) | 171 | 493 |
| Russia (156) | 223 | 1,991 |
| Scotland (164) | 93 | 772 |
| Spain (175) | 160 | 536 |
| Turkey (193) | 560 | 727 |
| Russia (156), Cyrillic pool | 141 | 1,985 |

Brazil's pools are the two largest first-name lists by a wide margin (1,795), and Germany's
last-name list is the single largest pool in the file at 2,900 - big enough on its own to set
the row count of the entire CSV.

### 6.3 The England fallback

If the header search reaches the end of the row without finding the requested nation id
(`nat_column` stays `-1`), `TNames.SetUp` does not fail or return an empty pool - it **calls
itself again with the England id, `62` (`$3E` in the disassembly)**:

```
If nat_column < 0
    SetUp($3e)          ' recurse with a0 = 62 (England) -- hardcoded, not the caller's choice
    Return 0
Else
    ...
```

**Only 12 of the 211 nations in `Nations.csv` (5.7%) have a dedicated name pool.** Every other
nation's generated players - Afghanistan, China, Nigeria, the United States, all of it - draw
their names from the **English** pool, dressed up in every other respect (kit, strength,
stadium) as that nation's own club or country. This is the single most consequential fact in
this file for how the generated football world actually looks and sounds.

**The function that reads `g_team_arr01`/`g_team_arr02` (the arrays `SetUp` fills) to actually
draw a random name for a specific player has not been located** - see §6.4. `TNames.SetUp`
only populates the pool; picking one first name and one last name out of it happens elsewhere.

### 6.4 What we do not know yet

* The consumer of `g_team_arr01`/`g_team_arr02` - the function that picks one random name from
  each array to actually name a generated player - was not found. `TPlayer` is currently absent
  from `extracted/vtable_map.tsv` entirely (see the reconstruction skill's known-gaps note,
  §9), which blocks tracing this the direct way; it may live on `TPlayer` or on a Function this
  document did not search for.
* **Performance/behaviour note, not yet confirmed against a caller:** `TNames.SetUp` re-opens
  and re-reads the *entire* `Names.csv` file from disk every time it runs - there is no
  cache. If it is genuinely called once per generated player (rather than once per nation, with
  the pool reused for every player of that nation), that is several thousand full-file reads
  over the course of building a new career's world. `UNCERTAIN:` call frequency - the caller
  was not located.
* `UNCERTAIN:` whether the `156_RussiaB` pool is actually used for anything distinct from
  `156_Russia` at runtime (e.g. picked for a specific in-game context) or whether it is simply
  unreachable - nothing in `TNames.SetUp` itself distinguishes the two; both are just "the
  first header cell whose number equals 156," and the *first* one wins, so `156_RussiaB`
  (the later, second occurrence) can never be reached by `SetUp(156)` at all. Only a caller
  that searches specifically for the `RussiaB` label by name - if one exists - could ever use
  it, and no such caller was found.

---

## 7. Horse.ini - the stable minigame's horse names

### What it is

Despite the `.ini` extension this is not a key/value file - it is 250 CRLF-terminated lines,
each one just a horse name (`Simon Says`, `Nancy Boy`, `Jolly Bristols`, …). Confirmed by
`TScreen_Stable.LoadData` @ 0x00587c3a (VERIFIED), which has two completely different modes
depending on whether it's called with an existing save stream:

* **No stream (`a0` is `Null`, e.g. starting a fresh career):** read `Horse.ini` line by line,
  and for **every single line**, generate a brand-new horse with fully randomised stats. The
  file supplies only the *name* - every other attribute of every horse is randomised at load
  time and never comes from disk.
* **With a stream (loading a save):** parse a different, comma-separated per-line format (not
  the `.ini` file at all) carrying all ten `THorse.Create` parameters explicitly, including
  ownership and last-run date.

### 7.1 Fresh-generation stat formula

For each line of `Horse.ini`, `TScreen_Stable.LoadData` builds a horse as:

```
st = [Rand(6), Rand(6), Rand(6), Rand(6), Rand(6)]      ' five stats, each 1-6 inclusive
price = 0
For each of the 5 values in st:
    value 1 -> price += 50,000
    value 2 -> price += 25,000
    value 3 -> price += 10,000
    value 4, 5 or 6 -> price += 0
THorse.Create(n, <line from Horse.ini>, Rand(80,100), Rand(80,100), Rand(40,100),
               st, price, owned=0, lastran=0, Rand(1,4))
```

(`Rand(6)` in legacy BlitzMax is `Rand(min=6, max=1)`, which the standard library's swap rule
turns into a uniform 1-6 inclusive roll - see `random.bmx` in the legacy runtime source.)

| Parameter | Range | Meaning |
|---|---|---|
| `id` | 0, 1, 2, … | Sequential, one per line read (see §7.2 for the exact count). |
| `name` | - | The `Horse.ini` line, read verbatim including any stray trailing whitespace. |
| `energy` | 80-100 | `THorse.energy` |
| `health` | 80-100 | `THorse.health` |
| `strength` | 40-100 | `THorse.strength` - the widest random range of the three stat floats. |
| `form` (`st[]`) | five values, each 1-6 | Recent-form indicators; also drives `prize`. |
| `prize` | 0-250,000 | Sum of the five form-value payouts above. Maximum only if all five form values roll `1` - probability (1/6)⁵ ≈ 0.013%. |
| `owned` | always 0 | No horse starts owned by the player. |
| `lastran` | always 0 | No horse has raced yet. |
| `colour` | 1-4 | Selects one of 4 pre-loaded horse sprite images (`Horse_01.png`…`Horse_04.png`); `colour=0` (unreachable from this generator, since `Rand(1,4)` never rolls it) would leave `THorse.image` unset - see `THorse.Create`'s `Select`, which has no `Default` case. |

`THorse.SelectRunners` @ 0x0058b226 (VERIFIED) confirms `form` (called `st`/stats here) feeds
into race participation: only horses not already run today (`lastran <> currentdate`) and not
currently owned are eligible, and the field is capped by a module Global fixed at `5` runners
per race at the moment `SelectRunners` sets it.

### 7.2 The trailing-blank-horse quirk

`Horse.ini` is 250 CRLF-terminated lines, but only the first 249 contain an actual name - line
250 is empty (the file's last two bytes are a second, immediately-following `\r\n`). Because
the loop condition is `While Not Eof(a0)` (checked *before* each read, not after), and the
stream still has 2 bytes left (that final empty line's own terminator) once "Lemon Pie" (the
249th and last real name) has been consumed, **the loop runs one more time and generates a
250th horse whose name is the empty string `""`.** This was confirmed directly against the raw
bytes of the shipped file (`od -c` shows `…e\r\n\r\n` at EOF - two consecutive line
terminators). A faithful reimplementation must reproduce this: **the game ships with exactly
250 horses, and the last one is nameless**, not 249 as a naive "one name per line, ignore blank
lines" reading would produce.

Two more literal-text quirks in the name list, reproduced verbatim by the same "no trimming"
loader behaviour documented for `Clubs.csv`/`Nations.csv` string fields: line 11, `Quality
Assurance`, carries a trailing tab character in the file; line 66, `Uncle Brian`, carries a
trailing space. `ReadLine` strips only the `\r\n` terminator, not incidental whitespace, so
both render with the stray character intact. Separately, `Bunch Of Fives` (lines 40 and 51) is
the one duplicated name in the list.

### 7.3 What we do not know yet

* `UNCERTAIN:` the exact comma-separated save-file schema parsed in the "with stream" branch - 
  ten fields were identified positionally (`v1`…`v9` plus a 5-element `st2[]` block) but none
  were named beyond what the `THorse.Create` parameter order implies.
* `UNCERTAIN:` what determines whether `TScreen_Stable.LoadData` is called with or without a
  stream at any given point in a real playthrough (presumably "does the save already contain
  stable data", but the caller was not read for this document).
* The gap: `THorse.SetRaceOdds`, `THorse.PostRaceUpdate` and the betting flow exist as
  byte-exact bodies in `src/recovered/` but were not read for this document - how a race is
  actually resolved and paid out is still unwritten.

---

## 8. What it means in play, across all five

Pulling the individually-noted consequences together, in order of how much they'd surprise a
player who assumed the CSVs were closer to their real-world subject matter:

1. **94% of nations share one name pool.** Only Argentina, Belgium, Brazil, England, France,
   Germany, Italy, Portugal, Russia (×2 - Latin and Cyrillic), Scotland, Spain and Turkey have
   their own first/last name lists. Every other nation's generated players are named as if they
   were English. This is invisible until you notice a Bangladeshi wonderkid named "Adam
   Abercrombie."
2. **A domestic league's `compstatus` - its division tier - is not stored data, it's a live
   computation** re-run at every load from file order. Reordering `Competitions.csv` rows for
   one nation changes which division is "the top flight" without touching a single number.
3. **A cup bracket halves itself automatically.** `place=103`/`104` promotion rows don't carry
   a team count - `GetNoofTeamsInRound` derives "how many teams enter this round" by literally
   dividing the previous round's team count by two, recursively, all the way back up the chain
   of `PromotionPlaces.csv` rows.
4. **The stable minigame throws away almost all of its own data file.** `Horse.ini` supplies
   only 250 (effectively 249) horse names; every stat, every price, every horse's colour is
   randomised fresh at load time, with no persistence back to the `.ini` file itself - the
   "data" file is really just a name pool, structurally identical in spirit to §6's naming
   pools.
5. **Achievement id 11 onward has no safety net.** The completeness backfill in
   `TAchievement.LoadData` only ever checks ids 1-10; anything beyond that, once broken, stays
   broken.

---

## 9. Reimplementation notes

### 9.1 Suggested BlitzMax types (fields not already covered in spec 01's `TClub`/`TNation`)

```blitzmax
Type TCompetition
    Field id:Int
    Field name:String
    Field tla:String
    Field labelname:String       ' derived, not loaded: = name or tla per display-mode flag
    Field locale:Int             ' 0 Nation / 1 Continent / 2 World
    Field level:Int              ' 0 Club / 1 International
    Field based:Int              ' FK: Nations.id or Continents.id, per locale
    Field comptype:Int           ' 0 League / 1 KO / 2 BestPlaced / 3 Pool / 4 LeagueCont / 5 RegionalSort
    Field startyear:Int
    Field startweek:Int          ' rewritten on load for pure domestic leagues, see 3.3
    Field duration:Int
    Field recurring:Int
    Field primarymatchday:Int    ' 1-7, or 99 = n/a
    Field secondarymatchday:Int
    Field groups:Int             ' clamped to >= 1 on load
    Field rounds:Int             ' forced to 1 when comptype = 1 (KO)
    Field legs:Int
    Field townregion:Int         ' 0 none / 1 North / 2 East / 3 South / 4 West
    Field compstatus:Int         ' recomputed for domestic leagues -- see 3.3
    Field priority:Int           ' NEVER loaded from CSV -- computed by SetPriority(), see 3.3
    Field minstrength:Int
    Field maxstrength:Int
    Field lfixturelist:TList
    Field lpromotionplaces:TList        ' places that promote FROM here
    Field lplacesthatpromotetome:TList  ' places that promote TO here
    Field teampool:TTeamPool[]
End Type

Type TPromotionPlace
    Field parentid:Int        ' FK -> Competitions.id, the source
    Field place:Int           ' 1-32 literal position, or 100-108 special code (4.2)
    Field promotiontoid:Int   ' FK -> Competitions.id, the destination
End Type

Type TAchievement
    Field id:Int
    Field index:Int           ' = sortindex column
    Field txt:String          ' = GetText("CACHIEVEMENT_" + id), not stored in the CSV
End Type

Type THorse
    Field id:Int
    Field name:String
    Field energy:Float        ' 80-100 fresh, else loaded
    Field health:Float        ' 80-100 fresh, else loaded
    Field strength:Float      ' 40-100 fresh, else loaded
    Field form:Int[5]         ' each 1-6 fresh; drives prize
    Field prize:Int           ' 0-250,000 fresh
    Field owned:Int
    Field lastran:Int
    Field colour:Int          ' 1-4, selects sprite image
End Type
```

### 9.2 Pitfall checklist (in addition to spec 01's, for the five files new to this document)

1. `Competitions.csv` rows have a genuine **trailing tab** - splitting on `\t` yields 21 raw
   fields for a 20-column row, the last always empty. `Clubs.csv`/`Nations.csv` do not have
   this artifact (their rows split to exactly the column count). Strip or ignore the trailing
   empty field; do not treat it as data.
2. Do not compute `compstatus`, `priority`, or the domestic-league `startweek` reduction as
   "just what's in the file" - all three are transformed or entirely overwritten at load time.
   Reproduce the transforms (3.3), not the raw CSV values, if the goal is matching runtime
   behaviour.
3. `rounds` in `Competitions.csv` is meaningless for `comptype=1` rows - the loader always
   overwrites it to `1`. Don't "fix" CSV rows that already show `rounds=1` for a KO competition
   assuming it's redundant - it's redundant on purpose, matching what the loader would force
   anyway.
4. `Achievements.csv` and `Names.csv` do **not** use the `//` sentinel - they read to EOF.
   Adding a `//` line to `Achievements.csv` changes behaviour (triggers the backfill-and-leak
   path in §5.2); adding one to `Names.csv` does nothing, since `TNames.SetUp` never checks for
   it at all.
5. `Names.csv` must be read column-major (nation-id pairs), not row-major. The header's blank
   cells are not empty data - they are the (never-read) label position for each pool's
   last-name column.
6. When generating fresh stable horses, replicate the **249-real-plus-1-blank** horse count
   exactly (7.2) - a "skip empty lines" reading of `Horse.ini` under-generates by one horse
   relative to the original.

---

## 10. Open questions (collected)

* `UNCERTAIN:` general-purpose meaning of `Competitions.compstatus` outside the domestic-league
  case, and the two `compstatus=70` outlier rows (§3.5).
* `UNCERTAIN:` what consumes `Competitions.recurring`, and whether it truly means "every N
  years" (§3.1, §3.5).
* `UNCERTAIN:` what consumes `Competitions.minstrength`/`maxstrength` numerically (§3.5, and
  see spec 01 §12 for the same open question on `Clubs.strength`/`Nations.strength`).
* `UNCERTAIN:` the runtime meaning of `PromotionPlaces.place` codes 101, 102, 105, 107, 108 - 
  each a single-row occurrence in the shipped data (§4.4).
* The function that actually draws a random name from `TNames.SetUp`'s pools for a specific
  generated player is not located; `TPlayer` is currently missing from `vtable_map.tsv`
  entirely, which blocks this (§6.4).
* `UNCERTAIN:` call frequency of `TNames.SetUp` - whether the full-file re-read happens once
  per nation (cached per pool) or once per generated player (§6.4).
* `UNCERTAIN:` the comma-separated horse save-file schema beyond positional field order (§7.3).
