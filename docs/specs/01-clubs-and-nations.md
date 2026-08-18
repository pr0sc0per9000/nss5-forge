# NSS5 Data Spec 01 - Clubs, Nations, Continents

**Scope:** `GameMedia/Data/Clubs.csv`, `GameMedia/Data/Nations.csv`, `GameMedia/Data/Continents.csv`
**Target:** faithful source reconstruction of New Star Soccer 5 (Steam appid 212780) in BlitzMax.
**Status:** every claim below was verified against the shipped files and/or the shipped `NSS5.exe` binary.
Anything not proven is explicitly flagged `UNCERTAIN:`.

Reference install used for verification:
`C:/Program Files (x86)/Steam/steamapps/common/New Star Soccer 5` (read-only).

---

## 0. Evidence key

Two kinds of evidence appear in this document:

| Tag | Meaning |
|---|---|
| **[FILE]** | Derived by exhaustively scanning the shipped CSV bytes. Deterministic. |
| **[CODE]** | Extracted from `NSS5.exe` machine code / `.data` string pool. File offsets given so it can be re-checked. |
| **[INFER]** | Reasoned from data correlation. Strong but not machine-proven. |
| `UNCERTAIN:` | Not established. Do not build on this without further work. |

PE layout used for all file-offset ↔ virtual-address conversions **[CODE]**:

```
ImageBase = 0x00400000
section   VA          VSize       RawPtr      RawSize
.text     0x00001000  0x000B8788  0x00000400  0x000B8800
code      0x000BA000  0x000FF723  0x000B8C00  0x000FF800
.data     0x001BA000  0x0001480C  0x001B8400  0x00014A00
data      0x001CF000  0x006E431C  0x001CCE00  0x006E4400
.rdata    0x008B4000  0x00020760  0x008B1200  0x00020800
.eh_fram  0x008D5000  0x0001E830  0x008D1A00  0x0001EA00
.bss      0x008F4000  0x0000B6CC  --          --
.idata    0x00900000  0x000024C0  0x008F0400  0x00002600
.CRT      0x00903000  0x00000018  0x008F2A00  0x00000200
.tls      0x00904000  0x00000020  0x008F2C00  0x00000200

VA(file_off)  = file_off - 0x1CCE00 + 0x1CF000 + 0x400000     (for the big `data` section)
```

BlitzMax string objects in `data` have the layout:

```
+0x00  dword  vtable pointer = 0x005C7D60   (BBString class)
+0x04  dword  refcount       = 0x7FFFFFFF   (immortal literal)
+0x08  dword  length in UTF-16 code units
+0x0C  ...    UTF-16LE characters
```

This signature is how every string literal below was located.

---

## 1. File format contract

### 1.1 Physical format

| Property | Clubs.csv | Nations.csv | Continents.csv |
|---|---|---|---|
| Size on disk | 1,435,457 bytes | 55,659 bytes | 540 bytes |
| Encoding | UTF-8, **no BOM** | UTF-8, **no BOM** | UTF-8, **no BOM** |
| First 3 bytes | `69 64 09` (`id\t`) | `69 64 09` | `69 64 09` |
| Line terminator | **LF only** (5438 LF, 0 CR) | **CRLF** (213 LF, 213 CR) | **CRLF** (8 LF, 8 CR) |
| Field delimiter | **TAB (0x09)** - *not* comma | TAB | TAB |
| Total lines | 5,438 | 213 | 8 |
| Header lines | 1 | 1 | 1 |
| Data rows | **5,436** | **211** | **6** |
| Terminator line | `//` + 37 trailing tabs | `//` | `//` |
| Columns | 38 | 38 | 7 |
| Quoting | **none** - no quote character is used anywhere | none | none |
| Escaping | **none** - a literal tab or newline inside a field is impossible | none | none |

Line-ending inconsistency is real and must be tolerated: `Clubs.csv` is LF-only while every
other data file in the folder is CRLF **[FILE]**. Verified byte-exactly with `tr -dc '\r' | wc -c`:

```
Clubs.csv              LF=5438  CR=0
Nations.csv            LF=213   CR=213
Continents.csv         LF=8     CR=8
Competitions.csv       LF=1030  CR=1030
PromotionPlaces.csv    LF=2069  CR=2069
Achievements.csv       LF=101   CR=101
```

A reimplementation must strip a trailing `\r` from the last field of every line, or the last
column (`bteamof` / `secondaryskin` / `strength`) will parse as e.g. `"0\r"`.

### 1.2 Loader contract, proven from the binary **[CODE]**

The literal pool belonging to `TNation.LoadData` sits contiguously at file offsets
`0x86DAC0 … 0x86DCA4`, and reading it in source order gives the whole algorithm:

| VA | len | literal |
|---|---|---|
| `0x00C6FCC0` | 1 | `\t` - the field delimiter |
| `0x00C6FCD0` | 9 | `CKITTYPE_` - localisation-key prefix for kit-style names |
| `0x00C6FCF0` | 39 | `GameMedia/Images/Nations/NationIm_0.png` |
| `0x00C6FD4C` | 4 | `.png` |
| `0x00C6FD60` | 34 | `GameMedia/Images/Nations/NationIm_` |
| `0x00C6FDB0` | 26 | `GameMedia/Data/Nations.csv` |
| `0x00C6FDF0` | 6 | `utf8::` - BlitzMax stream protocol prefix ⇒ file is read as UTF-8 |
| `0x00C6FE08` | 41 | `Could not load GameMedia/Data/Nations.csv` |
| `0x00C6FE68` | 16 | `TNation.LoadData` - debug/trace label |
| `0x00C6FE94` | 2 | **`//`** - end-of-data sentinel |
| `0x00C6FEA4` | 8 | `Nations:` - debug print of the loaded row count |

So the loader is:

```
stream = ReadStream("utf8::" + "GameMedia/Data/Nations.csv")
if stream = Null -> Print "Could not load GameMedia/Data/Nations.csv"; return
ReadLine()                       ' discard the header row
Repeat
    line = ReadLine()
    If line.StartsWith("//") Or Eof Then Exit     ' the "//" sentinel
    fields = line.Split("~t")                     ' TAB
    ... assign positionally ...
Forever
Print "Nations:" + count
```

The `//` literal object is **shared** (GCC/BlitzMax literal pooling) - it is referenced from
31 code sites (`0x0BCE9B, 0x0BD450, 0x0BD6AB, 0x0BF6A1, 0x0BFC63, 0x0BFF1E, 0x107825, …`),
i.e. by every CSV loader **and** every CSV writer. The TAB literal is referenced from ~600 sites.

**The `//` convention is confirmed** and it applies to
`Clubs.csv`, `Nations.csv`, `Continents.csv`, `Competitions.csv`, `PromotionPlaces.csv`.
It does **not** apply to `Achievements.csv` or `Names.csv`, which simply end at EOF **[FILE]**.

In `Clubs.csv` the terminator line is `//` followed by 37 tabs (so the sentinel row still has
38 fields); in the other files it is a bare `//`.

### 1.3 Field access is positional, not header-driven

`.data` contains, in exact CSV column order, the field-name strings the built-in Data Editor
writes back out **[CODE]** (string-dump indices 264-299 for Nations, 324-359 for Clubs).
`id` and `tla` are absent from those runs only because identical literals elsewhere in the
binary were pooled - the emitted header is the full 38 names.

The header row is **discarded** by the loader; columns are read by index. Reordering columns
in a modded CSV will silently corrupt the data.

### 1.4 "Save For Mobile" subset **[CODE]**

The Data Editor has a `Save For Mobile` command writing `GameMedia/Data/Mobile/*.txt`
(these files are **not** shipped). The exported column subsets are hard-coded and much smaller:

| Target | Columns exported |
|---|---|
| `Mobile/Nations.txt` | shortname, strength, stadiumlongitude, stadiumlatitude, homekittype, homekitshirtcol1, homekitshirtcol2, homekitshortscol, awaykitshirtcol1, awaykitshortscol, nationality, continent |
| `Mobile/Clubs.txt` | shortname, strength, stadiumlongitude, stadiumlatitude, homestyle, homekitshirtcol1, homekitshirtcol2, homekitshortscol, awaykitshirtcol1, awaykitshortscol, nationid, leagueid, continentalcompid, bteamof |
| `Mobile/Continents.txt` | (path literal present at string index 1392; column list not isolated) |

Useful signal: those are the fields the developers considered *load-bearing*. Everything else
(third kit, keeper kit, nickname, rivals, stadium name/capacity, formation, climate, skins) is
cosmetic or secondary.

---

## 2. Continents.csv

7 columns, 6 data rows, ids 1-6 contiguous. The complete file, verbatim **[FILE]**:

| id | name | tla | continentality | federationname | federationshortname | strength |
|---|---|---|---|---|---|---|
| 1 | Asia | ASI | Asian | Asian Football Confederation | AFC | 60 |
| 2 | Africa | AFR | African | Confédération Africaine de Football | CAF | 70 |
| 3 | North America | NAM | North American | Confederation of North; Central American and Caribbean Association Football | CONCACAF | 50 |
| 4 | South America | SAM | South American | Confederación Sudamericana de Fútbol | CONMEBOL | 80 |
| 5 | Oceania | OCE | Oceanic | Oceania Football Confederation | OFC | 50 |
| 6 | Europe | EUR | European | Union of European Football Associations | UEFA | 90 |

### Column reference

| # | Name | Type | Range / values | Meaning |
|---|---|---|---|---|
| 1 | `id` | Int | 1-6 | Primary key. Referenced by `Nations.continent`. |
| 2 | `name` | String | 4-13 chars | Display name of the confederation region. |
| 3 | `tla` | String | exactly 3 chars, uppercase | Short code used in compact tables. |
| 4 | `continentality` | String | 5-14 chars | **Adjectival** form of the name, used to build phrases like "the African champions". Distinct field from `name` precisely because "North America" → "North American". |
| 5 | `federationname` | String | 33-75 chars, may contain accents and a `;` | Full confederation name. Note row 3 uses `;` where the real name has a comma - because comma has no special meaning here, this is a stylistic choice, not an escape. |
| 6 | `federationshortname` | String | 3-8 chars | AFC / CAF / CONCACAF / CONMEBOL / OFC / UEFA. |
| 7 | `strength` | Int | 50-90 (Asia 60, Africa 70, N.America 50, S.America 80, Oceania 50, Europe 90) | Confederation quality rating. Same 0-100 scale as `Nations.strength` and `Clubs.strength`. Drives continental-competition seeding and the relative value of continental honours. `UNCERTAIN:` the exact consumption formula is not established in this document. |

Loader field-name list found in `.data` **[CODE]** (string-dump 1386-1390):
`name`, `continentality`, `federationname`, `federationshortname`, `strength`
(with `id` and `tla` pooled elsewhere) - 7 columns total, matching the file.

Club distribution across continents, resolved through `Clubs.nationid → Nations.continent` **[FILE]**:

| Continent | Nations | Clubs |
|---|---|---|
| 1 Asia | 46 | 551 |
| 2 Africa | 53 | 568 |
| 3 North America | 36 | 424 |
| 4 South America | 10 | 418 |
| 5 Oceania | 11 | 13 |
| 6 Europe | 55 | 3,459 |
| (unresolved - `nationid = 0`) | - | 3 |

---

## 3. Nations.csv

**211 data rows. `id` runs 1-211 with no gaps** (distinct = 211, min = 1, max = 211) **[FILE]**.
38 columns; every data row has exactly 38 fields.

### 3.1 Column reference

| # | Name | Type | Distinct | Min / Max | Empty | Meaning |
|---|---|---|---|---|---|---|
| 1 | `id` | Int | 211 | 1 / 211 | 0 | Primary key. Contiguous, ascending. Referenced by `Clubs.nationid`, `Nations.rivalid1..3`. |
| 2 | `name` | String | 211 | maxlen 26 | 0 | Full nation name, e.g. `Republic of Ireland`, `Bosnia Herzegovina`. Unique. |
| 3 | `shortname` | String | 211 | maxlen 23 | 0 | Table/UI abbreviation. **Equals `name` for 199 of 211 rows**; only 12 differ (long names). |
| 4 | `tla` | String | 211 | 3-8 chars | 0 | Uppercase code. Despite the name it is **not** three letters: lengths 3(×4), 4(×11), 5(×33), 6(×57), 7(×104), 8(×2). E.g. `AFGHAN`, `ENGLAND`, `KOSOVO`. |
| 5 | `strength` | Int | 76 | 10 / 96 | 0 | National-team quality, 0-100 scale. Mean 47.67. Top: Spain 96, Germany 95, Uruguay 93, England 93, Portugal 90, Italy 89, Argentina 86, Netherlands 85. Floor 10 (Anguilla, Bhutan, British Virgin Islands, Brunei, Macau…). |
| 6 | `rivalid1` | Int | 40 | 0 / 202 | 0 | FK → `Nations.id`; `0` = none. 50 rows non-zero. |
| 7 | `rivalid2` | Int | 25 | 0 / 200 | 0 | FK → `Nations.id`; `0` = none. 30 rows non-zero. |
| 8 | `rivalid3` | Int | 11 | 0 / 194 | 0 | FK → `Nations.id`; `0` = none. 12 rows non-zero. |
| 9 | `stadiumname` | String | 209 | maxlen 37 | 0 | National stadium, e.g. `Wembley`, `Maracanã`, `Ghazi Stadium`. Two names repeat (shared venues). |
| 10 | `stadiumcapacity` | Int | 100 | 1,000 / 120,000 | 0 | Mean 35,936. No zeros. |
| 11 | `stadiumlongitude` | Float | 210 | −175.21 / +178.45 | 0 | Decimal degrees **east-positive**. Verified: England `−0.28`, Brazil `−43.23`. |
| 12 | `stadiumlatitude` | Float | 208 | −64.77 / +89.64 | 0 | Decimal degrees **north-positive**. Verified: England `+51.56`, Brazil `−22.91`. Two rows are swapped - see §7. |
| 13 | `homekittype` | Enum(str) | 14 | - | 0 | Kit pattern. See §5. |
| 14 | `homekitshirtcol1` | Colour | 32 | - | 0 | Primary shirt colour, `#RRGGBB`. |
| 15 | `homekitshirtcol2` | Colour | 25 | - | 0 | Secondary shirt colour (the pattern colour). |
| 16 | `homekitshortscol` | Colour | 31 | - | 0 | Shorts colour. |
| 17 | `homekitsockscol` | Colour | 28 | - | 0 | Socks colour. |
| 18 | `awaykittype` | Enum(str) | 12 | - | 0 | See §5. |
| 19-22 | `awaykitshirtcol1/2`, `awaykitshortscol`, `awaykitsockscol` | Colour | 27 / 21 / 30 / 24 | - | 0 | As above, away kit. |
| 23 | `thirdkittype` | Enum(str) | 11 | - | 0 | See §5. |
| 24-27 | `thirdkitshirtcol1/2`, `thirdkitshortscol`, `thirdkitsockscol` | Colour | 22 / 18 / 21 / 22 | - | 0 | As above, third kit. |
| 28 | `keeperkittype` | Enum(str) | 6 (`PLAIN`,`TRIM`,`SLEEVES`,`SPLIT`,`SINGLEHOOP`,`SLEEVE`) | - | 0 | Goalkeeper kit pattern. |
| 29-32 | `keeperkitshirtcol1/2`, `keeperkitshortscol`, `keeperkitsockscol` | Colour | 34 / 17 / 23 / 25 | - | 0 | Goalkeeper kit colours. |
| 33 | `formation` | Enum(int) | 6 | 4 / 10 | 0 | Default tactic. **1-based** index into the formation list. See §6. |
| 34 | `nationality` | String | 209 | maxlen 23 | 0 | Demonym used for player nationality text: `English`, `Brazilian`, `Kosovar`, `Afghan`. Two collisions: `Guinean` ×2, `Dominican` ×2. |
| 35 | `continent` | Enum(int) | 6 | 1 / 6 | 0 | FK → `Continents.id`. Distribution: 1→46, 2→53, 3→36, 4→10, 5→11, 6→55. |
| 36 | `climate` | Enum(int) | 5 | 0 / 4 | 0 | Weather profile. See §8. |
| 37 | `primaryskin` | Enum(int) | 5 | 0 / 4 | 0 | Dominant skin tone for generated players. See §9. |
| 38 | `secondaryskin` | Enum(int) | 5 | 0 / 4 | 0 | Secondary skin tone for generated players. See §9. |

### 3.2 Real example rows

```
28 | Brazil | Brazil | BRAZIL | 83 | 9 | 0 | 0 | Maracanã | 95000 | -43.2299995 | -22.9099998
   | TRIM       | #FFFF00 | #339933 | #0033FF | #FFFFFF
   | PLAIN      | #0033FF | #0000FF | #FFFFFF | #0033FF
   | PLAIN      | #0000FF | #0000FF | #FFFFFF | #0000FF
   | SINGLEHOOP | #E0E0E0 | #444444 | #E0E0E0 | #E0E0E0
   | 7 | Brazilian | 4 | 2 | 2 | 0

62 | England | England | ENGLAND | 93 | 75 | 164 | 71 | Wembley | 90000 | -0.280000001 | 51.5600014
   | PLAIN | #FFFFFF | #FFFFFF | #003399 | #FFFFFF
   | PLAIN | #444444 | #FF0000 | #00CCFF | #444444
   | PLAIN | #FF0000 | #FF0000 | #FFFFFF | #FF0000
   | PLAIN | #000066 | #000080 | #000066 | #000066
   | 6 | English | 6 | 0 | 0 | 2
```

Reading Brazil: formation 7 = `4-4-1-1`, continent 4 = South America, climate 2 = Warm,
primaryskin 2 = Dark, secondaryskin 0 = White.

### 3.3 Referential integrity **[FILE]**

| Reference | Resolved | Dangling | Zero (= none) |
|---|---|---|---|
| `rivalid1 → Nations.id` | 50 | 0 | 161 |
| `rivalid2 → Nations.id` | 30 | 0 | 181 |
| `rivalid3 → Nations.id` | 12 | 0 | 199 |
| `continent → Continents.id` | 211 | 0 | 0 |

Rivalries are **directed and only partly reciprocal**: 92 directed links, 54 of which have a
reverse link (58.7%). A reimplementation must not assume symmetry; store the arcs as given.

### 3.4 Kit-pattern vocabulary actually used in Nations.csv **[FILE]**

| Column | Value counts |
|---|---|
| `homekittype` | PLAIN 109, TRIM 60, SLEEVES 16, STRIPES 10, SINGLEHOOP 5, STRIPE_LR 2, STRIPE_C 2, STRIPE_RL 1, STRIPE_L 1, SPLIT 1, SLEEVE_R 1, SLEEVE_L 1, SEGMENTS 1, CHEQUERED 1 |
| `awaykittype` | PLAIN 129, TRIM 54, SLEEVES 9, STRIPE_LR 4, SINGLEHOOP 4, STRIPES 3, STRIPE_C 2, HOOPS 2, STRIPE_RL 1, STRIPE_L 1, SLEEVE_R 1, SLEEVE_L 1 |
| `thirdkittype` | PLAIN 119, TRIM 71, SLEEVES 10, STRIPE_LR 2, STRIPES 2, SINGLEHOOP 2, STRIPE_RL 1, STRIPE_L 1, STRIPE_C 1, SLEEVE_R 1, SLEEVE_L 1 |
| `keeperkittype` | PLAIN 163, TRIM 34, SLEEVES 6, SPLIT 4, SINGLEHOOP 3, SLEEVE 1 |

No empty values, no malformed values. Nations data is clean where Clubs data is not.

---

## 4. Clubs.csv

**5,436 data rows. `id` runs 1 - 5845, strictly ascending, with 409 missing ids across 23 gap
runs** (deleted clubs) **[FILE]**. 38 columns; every data row has exactly 38 fields.

First gaps: after 89→91, 545→547, 1502→1504, 1511→1513, 1513→1516, 2005→**2025** (19 missing),
2212→2214, 3536→3538.

### 4.1 Column reference

| # | Name | Type | Distinct | Min / Max | Empty | Meaning |
|---|---|---|---|---|---|---|
| 1 | `id` | Int | 5,436 | 1 / 5,845 | 0 | Primary key. Sparse (409 unused ids), strictly ascending. Referenced by `rivalclub1..3`, `bteamof`, and by save games. |
| 2 | `name` | String | 5,422 | maxlen 43 | 0 | Full club name. **14 names are duplicated** across different countries: `Wellington Phoenix`, `Turgutluspor`, `Police United`, `Police FC`, `Orlando Pirates`, `Harimau Muda B`, `Fostiras FC`, `Club Nacional`, `CD Guadalajara`, `CA River Plate`, `Botswana Railways Highlanders`, `Blackburn Rovers`, … Name is **not** a key. |
| 3 | `shortname` | String | 5,328 | maxlen 29 | 0 | Table/commentary name (`Man United`, `Barcelona`). Equal to `name` for 1,236 rows. |
| 4 | `tla` | String | 5,424 | 2-11 chars | 0 | Compact code. Lengths: 2(×10) 3(×141) 4(×292) 5(×746) **6(×3,625)** 7(×556) 8(×57) 9(×8) 11(×1). Not restricted to ASCII: `BARÇA`, `BESËLI`, `SÉTIF `, `SAÏDA `, `TËRBUNI  ` (note embedded trailing spaces). Duplicates exist (`ÇORUM`, `TURGUT`, `SOCHI`, `SLAVOJ`, `SHORTA`, `SABANA`, `S PACAS`, `ELAZIG` each ×2). |
| 5 | `strength` | Int | 91 | 6 / 99 | 0 | Club quality, 0-100. Mean 37.22. Top: Real Madrid 99, FC Barcelona 99, Manchester City 98, Bayern München 97. Distribution below. |
| 6 | `rivalclub1` | Int | 610 | 0 / 4,365 | 0 | FK → `Clubs.id`; `0` = none. 817 non-zero. |
| 7 | `rivalclub2` | Int | 297 | 0 / 5,383 | 0 | FK → `Clubs.id`; `0` = none. 428 non-zero. |
| 8 | `rivalclub3` | Int | 144 | 0 / 3,446 | 0 | FK → `Clubs.id`; `0` = none. 198 non-zero. |
| 9 | `stadiumname` | String | 4,718 | maxlen 49 | **4** | Ground name. Shared grounds repeat (`Salt Lake Stadium`, `Cairo International`, `Azadi`). Empty for ids 4505, 5537, 5561, 5562. |
| 10 | `stadiumcapacity` | Int | 1,128 | 0 / **525,000** | 0 | Mean 12,323. Quantiles: p25 = 3,000; median = 7,000; p75 = 16,000; p95 = 41,000. **11 rows are 0.** The 525,000 max is a data error (see §7). |
| 11 | `stadiumlongitude` | Float | 4,019 | −123.349 / +176.920 | 0 | Decimal degrees east-positive. Extremes are legitimate: Victoria United (Canada) −123.349, Hawke's Bay United (NZ) +176.920. |
| 12 | `stadiumlatitude` | Float | 3,803 | **−722.317** / +116.030 | 0 | Decimal degrees north-positive. Out-of-range values are data errors (see §7). |
| 13 | `homestyle` | Enum(str) | 21 raw = 19 valid tokens + `plain` (lowercase) + empty | - | **2** | Home kit pattern. §5. |
| 14 | `homekitshirtcol1` | Colour | 180 | - | 0 | Primary shirt colour. |
| 15 | `homekitshirtcol2` | Colour | 148 | - | 0 | Secondary/pattern shirt colour. |
| 16 | `homekitshortscol` | Colour | 149 | - | 0 | Shorts colour. |
| 17 | `homekitsockscol` | Colour | 157 | - | 0 | Socks colour. |
| 18 | `awaystyle` | Enum(str) | 19 raw = 18 valid + empty | - | **3** | Away kit pattern. §5. |
| 19-22 | `awaykitshirtcol1/2`, `awaykitshortscol`, `awaykitsockscol` | Colour | 162 / 160 / 156 / 155 | - | 0 | Away kit colours. |
| 23 | `thirdstyle` | Enum(str) | 18 raw = 17 valid + empty | - | **2** | Third kit pattern. §5. |
| 24-27 | `thirdkitshirtcol1/2`, `thirdkitshortscol`, `thirdkitsockscol` | Colour | 111 / 113 / 103 / 112 | - | 0 | Third kit colours. |
| 28 | `keeperstyle` | Enum(str) | 18 raw = 16 valid + empty + 1 corrupt (`#FFFFFF`) | - | **2** | Goalkeeper kit pattern. §5. |
| 29-32 | `keeperkitshirtcol1/2`, `keeperkitshortscol`, `keeperkitsockscol` | Colour | 87 / 52 / 53 / 56 | - | 0 | Goalkeeper kit colours. |
| 33 | `formation` | Enum(int) | 6 | 4 / 10 | 0 | Default tactic, **1-based**. §6. |
| 34 | `nickname` | String | 1,387 | maxlen 31 | **3,733** | Optional fan nickname used in commentary/press. 1,703 clubs have one: `The Red Devils`, `Los Merengues`, `Cules`, `The Black Eagles`, `The Canaries`, `The Crabs`. |
| 35 | `nationid` | Int | 124 | 0 / 211 | 0 | FK → `Nations.id`; `0` = unassigned (3 rows). Only **124 of 211** nations have any clubs. |
| 36 | `leagueid` | Int | 299 | 0 / 10,412 | 0 | FK → `Competitions.id` - the club's domestic league. `0` = not in any league (1,349 rows, i.e. reserve/non-league filler). 298 distinct leagues used. |
| 37 | `continentalcompid` | Int | 31 | 0 / 9,500 | 0 | FK → `Competitions.id` - the continental competition (and the exact round) the club **enters at** in season 1. `0` = does not qualify (4,994 rows). 442 clubs qualify across 30 entry points. |
| 38 | `bteamof` | Int | 153 | 0 / 4,088 | 0 | FK → `Clubs.id` - this club is the **reserve / B / academy team of** that club. `0` = it is a first team (5,273 rows). 163 B-teams. |

### 4.2 Strength distribution **[FILE]**

| Band | Clubs |
|---|---|
| 0-9 | 7 |
| 10-19 | 565 |
| 20-29 | 1,483 |
| 30-39 | 1,404 |
| 40-49 | 816 |
| 50-59 | 515 |
| 60-69 | 359 |
| 70-79 | 202 |
| 80-89 | 67 |
| 90-99 | 18 |

Right-skewed with a mode at 20-29. Only 18 clubs sit at 90+, and exactly 4 at 97+
(Real Madrid 99, FC Barcelona 99, Manchester City 98, Bayern München 97).

### 4.3 Real example rows

```
920  | Manchester United | Man United | MAN U | 93 | 919 | 915 | 810 | Old Trafford | 76312 | -2.27900004 | 53.4500008
     | TRIM       | #FF0000 | #444444 | #444444 | #444444
     | TRIM       | #C0C0C0 | #444444 | #444444 | #C0C0C0
     | PLAIN      | #FFFFFF | #0000FF | #444444 | #FFFFFF
     | PLAIN      | #FFFF00 | #FFFF00 | #444444 | #FFFF00
     | 8 | The Red Devils | 62 | 2270 | 360 | 0

2880 | FC Barcelona | Barcelona | BARÇA | 99 | 2921 | 2909 | 2834 | Camp Nou | 99354 | 2.11800003 | 41.3800011
     | STRIPES    | #BF0000 | #0000BF | #0000BF | #0000BF
     | TRIM       | #00FFFF | #00FFFF | #00FFFF | #00FFFF
     | SINGLEHOOP | #78E7CB | #0000BF | #000040 | #78E7CB
     | PLAIN      | #3C773C | #008000 | #444444 | #444444
     | 8 | Cules | 175 | 6790 | 350 | 0

1    | Hakim Sanayi Kabul FC | Hakim Sanayi | HAKIMS | 14 | 0 | 0 | 0 | Kabul Stadium | 25000 | 69.1900024 | 34.5200005
     | PLAIN | #FFFFFF | #FFFFFF | #FFFFFF | #FFFFFF
     | PLAIN | #444444 | #444444 | #444444 | #444444
     | PLAIN | #444444 | #444444 | #444444 | #444444
     | PLAIN | #00EB00 | #00EB00 | #008000 | #008000
     | 8 | (none) | 1 | 560 | 0 | 0
```

Man United: leagueid 2270 = `Premiership` (England), continentalcompid 360 =
`Europa League Group Stage`. Barcelona: leagueid 6790 (Spain), continentalcompid 350 =
`Champions League Group Stage`.

### 4.4 Referential integrity **[FILE]**

| Reference | Resolved | Dangling | Zero (= none) |
|---|---|---|---|
| `nationid → Nations.id` | 5,433 | 0 | **3** (ids 4238 `ASC Jeanne d'Arc`, 4327 `MŠK Žilina II`, 5737 `Triomphe FC de Liancourt`) |
| `leagueid → Competitions.id` | 4,087 | 0 | 1,349 |
| `continentalcompid → Competitions.id` | 442 | 0 | 4,994 |
| `bteamof → Clubs.id` | 163 | 0 | 5,273 |
| `rivalclub1 → Clubs.id` | 816 | **1** | 4,619 |
| `rivalclub2 → Clubs.id` | 427 | **1** | 5,008 |
| `rivalclub3 → Clubs.id` | 198 | 0 | 5,238 |

The only dangling reference in the entire file is club id **1514**, which does not exist
(it falls in the 1513→1516 gap) but is still cited by `Dempo SC` (`rivalclub1`) and
`Churchill Brothers` (`rivalclub2`). The loader must tolerate this - presumably by resolving
rivals lazily and dropping unresolved ones.

Rivalries: 1,443 directed links, 958 reciprocated (66.4%). Again **not symmetric**.

### 4.5 `continentalcompid` - the 30 entry points in use **[FILE]**

Resolved against `Competitions.csv`:

| id | Competition | Clubs |
|---|---|---|
| 350 | Champions League Group Stage | 26 |
| 360 | Europa League Group Stage | 17 |
| 365 | Champions League Preliminary Round 1 | 4 |
| 370 | Champions League 1st Qualifying Round | 31 |
| 375 | Europa League Preliminary Round | 14 |
| 380 | Europa League 1st Qualifying Round | 87 |
| 390 | Champions League 2nd Qualifying Round | 4 |
| 391 | Champions League 2nd Qualifying Round (NC) | 4 |
| 400 | Europa League 2nd Qualifying Round (NC) | 27 |
| 410 | Champions League 3rd Qualifying Round (C) | 2 |
| 420 | Champions League 3rd Qualifying Round (NC) | 6 |
| 430 | Champions League Play-off Round (C) | 2 |
| 450 | Europa League 3d Qualifying Round (NC) | 13 |
| 6820 | Segunda División B Group 3 | 1 |
| 7800 | Copa Libertadores Qualifying Stage 1 | 6 |
| 7801 | Copa Libertadores Qualifying Stage 2 | 13 |
| 7810 | Copa Libertadores Group Stage | 28 |
| 7910 | CONCACAF Champions League Round of 16 | 15 |
| 7950 | CONCACAF League Round of 16 | 13 |
| 8000 | CFU Club Cup | 11 |
| 8100 | AFC Champions League West Preliminary Round 2 | 4 |
| 8101 | AFC Champions League Qualifying Round East 1 | 2 |
| 8105 | AFC Champions League Qualifying Round East 2 | 7 |
| 8110 | AFC Champions League West Playoff | 6 |
| 8111 | AFC Champions League East Playoff | 4 |
| 8120 | AFC Champions League Group West | 12 |
| 8121 | AFC Champions League Group East | 12 |
| 8320 | CAF Champions League Second Round | 22 |
| 8330 | CAF Champions League Group | 5 |
| 9500 | Copa Sudamericana First Stage | 44 |

`(C)` = champions path, `(NC)` = non-champions path - these mirror the real UEFA bracket split.
Entry **6820 `Segunda División B Group 3`** with 1 club is almost certainly a data-entry mistake:
a domestic league id pasted into the continental slot.

### 4.6 `bteamof` semantics **[FILE]**

163 clubs are reserve teams. The pattern of naming is consistent - `II`, `-2`, ` B`, `Castilla`,
`Academy`:

| B-team | `bteamof` | Parent | Its own `leagueid` |
|---|---|---|---|
| CE Principat B | 82 | CE Principat | 0 |
| Lusitanos la Posa B | 91 | Lusitanos la Posa | 740 |
| UE Santa Coloma B | 96 | UE Santa Coloma | 740 |
| Ararat Yerevan-2 | 145 | Ararat Yerevan | 880 |
| FC Liefering | 189 | FC Red Bull Salzburg | 960 |
| FK Austria Wien II | 193 | FK Austria Vienna | 960 |
| FC Minsk-2 | 254 | FC Minsk | 1,130 |
| Toronto FC Academy | 3327 | Toronto FC | 0 |
| Bayern München II | 1215 | Bayern München | 3,170 |
| Real Madrid Castilla | 2921 | Real Madrid | 6,810 |
| FC Barcelona B | 2880 | FC Barcelona | 6,820 |

A B-team is a full club row in its own right (own id, own kit, own strength, often its own
league). `bteamof` exists so the engine can forbid promotion into the parent's division, block
the two meeting in cup draws, and route loan/youth moves.

### 4.7 Kit-pattern vocabulary actually used in Clubs.csv **[FILE]**

| Value | homestyle | awaystyle | thirdstyle | keeperstyle |
|---|---|---|---|---|
| `PLAIN` | 2,208 | 3,152 | 3,761 | 4,503 |
| `TRIM` | 1,042 | 1,181 | 865 | 606 |
| `STRIPES` | 1,086 | 229 | 201 | 4 |
| `SLEEVES` | 357 | 332 | 234 | 130 |
| `HOOPS` | 150 | 65 | 41 | 14 |
| `SPLIT` | 118 | 29 | 42 | 123 |
| `HOOP` | 86 | 76 | 52 | 14 |
| `STRIPE_C` | 69 | 54 | 31 | 2 |
| `SLEEVE` | 68 | 65 | 44 | 7 |
| `STRIPE` | 52 | 62 | 39 | 4 |
| `STRIPE_V` | 51 | 40 | 27 | 13 |
| `SINGLEHOOP` | 45 | 51 | 29 | 1 |
| `STRIPE_LR` | 43 | 46 | 29 | 1 |
| `STRIPE_RL` | 27 | 30 | 25 | 3 |
| `CHEQUERED` | 12 | 10 | 4 | 5 |
| `SEGMENTS` | 11 | 3 | 6 | 3 |
| `SPLIT_LR` | 6 | 5 | 4 | 0 |
| `STRIPE_L` | 1 | 3 | 0 | 0 |
| `DIAGONALSPLIT_RL` | 1 | 0 | 0 | 0 |
| `plain` (lowercase) | 1 | 0 | 0 | 0 |
| `#FFFFFF` (corrupt) | 0 | 0 | 0 | 1 |
| *(empty)* | 2 | 3 | 2 | 2 |

Note `Clubs.csv` prefers the **direction-agnostic** tokens (`STRIPE`, `SLEEVE`) whereas
`Nations.csv` prefers the **directional** ones (`STRIPE_L`, `SLEEVE_R`) - consistent with the
two editor screens offering different lists (see §5.4).

---

## 5. The kit-pattern enum

Columns covered: `Clubs.homestyle` / `awaystyle` / `thirdstyle` / `keeperstyle` and
`Nations.homekittype` / `awaykittype` / `thirdkittype` / `keeperkittype`. Different column
names, identical value domain and identical handling.

**These columns hold ASCII tokens, not integers.** This is the single most important correction
to the original task brief. The integer enum exists only inside the engine.

### 5.1 The complete token list **[CODE]**

23 tokens live contiguously in `.data`, in declaration order:

| # | Token | obj file offset | VA |
|---|---|---|---|
| 1 | `PLAIN` | 0x873470 | 0x00C75670 |
| 2 | `TRIM` | 0x873498 | 0x00C75698 |
| 3 | `STRIPES` | 0x8734AC | 0x00C756AC |
| 4 | `STRIPE` | 0x8734C8 | 0x00C756C8 |
| 5 | `STRIPE_L` | 0x8734E0 | 0x00C756E0 |
| 6 | `STRIPE_R` | 0x8734FC | 0x00C756FC |
| 7 | `STRIPE_LR` | 0x873518 | 0x00C75718 |
| 8 | `STRIPE_RL` | 0x873538 | 0x00C75738 |
| 9 | `STRIPE_C` | 0x873558 | 0x00C75758 |
| 10 | `STRIPE_V` | 0x873574 | 0x00C75774 |
| 11 | `SLEEVES` | 0x873590 | 0x00C75790 |
| 12 | `SLEEVE` | 0x8735AC | 0x00C757AC |
| 13 | `SLEEVE_L` | 0x8735C4 | 0x00C757C4 |
| 14 | `SLEEVE_R` | 0x8735E0 | 0x00C757E0 |
| 15 | `HOOPS` | 0x8735FC | 0x00C757FC |
| 16 | `HOOP` | 0x873614 | 0x00C75814 |
| 17 | `SINGLEHOOP` | 0x873628 | 0x00C75828 |
| 18 | `SPLIT` | 0x873648 | 0x00C75848 |
| 19 | `SPLIT_LR` | 0x873660 | 0x00C75860 |
| 20 | `DIAGONALSPLIT_LR` | 0x87367C | 0x00C7587C |
| 21 | `DIAGONALSPLIT_RL` | 0x8736A8 | 0x00C758A8 |
| 22 | `SEGMENTS` | 0x8736D4 | 0x00C758D4 |
| 23 | `CHEQUERED` | 0x8736F0 | 0x00C758F0 |

Immediately after them, in matching order, sit the 15 sprite-sheet filenames
(0x873710 - 0x8739A4). `DIAGONALSPLIT_LR` never appears in either CSV, but the engine supports it.

### 5.2 Token → sprite sheet - **fully decoded from the dispatch function at `0x0DB750`** **[CODE]**

The function takes a style string and returns a filename. Each row below was recovered by
following the `je` displacement of the corresponding `bbStringCompare` test to its
`mov eax, <VA>` target.

| CSV token | Sprite sheet returned | Compare site | Case site |
|---|---|---|---|
| `PLAIN` | `Player_Plain.png` | 0x0DB766 | 0x0DB981 |
| `TRIM` | `Player_Trim.png` | 0x0DB77D | 0x0DB98B |
| `STRIPES` | `Player_Stripes.png` | 0x0DB794 | 0x0DB995 |
| `STRIPE` | `Player_StripeR.png` | 0x0DB7AB | 0x0DB99F |
| `STRIPE_L` | `Player_StripeR.png` | 0x0DB7C2 | 0x0DB9A9 |
| `STRIPE_R` | `Player_StripeR.png` | 0x0DB7D9 | 0x0DB9B0 |
| `STRIPE_LR` | `Player_StripeLR.png` | 0x0DB7F0 | 0x0DB9B7 |
| `STRIPE_RL` | `Player_StripeLR.png` | 0x0DB807 | 0x0DB9BE |
| `STRIPE_C` | `Player_StripeC.png` | 0x0DB81E | 0x0DB9C5 |
| `STRIPE_V` | `Player_V.png` | 0x0DB835 | 0x0DB9CC |
| `SLEEVES` | `Player_Sleeves.png` | 0x0DB84C | 0x0DB9D3 |
| `SLEEVE` | `Player_SleeveR.png` | 0x0DB863 | 0x0DB9DA |
| `SLEEVE_L` | `Player_SleeveR.png` | 0x0DB87A | 0x0DB9E1 |
| `SLEEVE_R` | `Player_SleeveR.png` | 0x0DB891 | 0x0DB9E8 |
| `HOOPS` | `Player_Hoops.png` | 0x0DB8A8 | 0x0DB9EF |
| `HOOP` | `Player_Hoop.png` | 0x0DB8BF | 0x0DB9F6 |
| `SINGLEHOOP` | `Player_Hoop.png` | 0x0DB8D6 | 0x0DB9FD |
| `SPLIT` | `Player_Split.png` | 0x0DB8ED | 0x0DBA04 |
| `SPLIT_LR` | `Player_DiagonalSplit.png` | 0x0DB904 | 0x0DBA0B |
| `DIAGONALSPLIT_LR` | `Player_DiagonalSplit.png` | 0x0DB91B | 0x0DBA12 |
| `DIAGONALSPLIT_RL` | `Player_DiagonalSplit.png` | 0x0DB932 | 0x0DBA19 |
| `SEGMENTS` | `Player_Segments.png` | 0x0DB949 | 0x0DBA20 |
| `CHEQUERED` | `Player_Chequered.png` | 0x0DB960 | 0x0DBA27 |
| **anything else** (incl. `""`, `plain`, `#FFFFFF`) | **`Player_Plain.png`** | fall-through | 0x0DB977 |

Two consequences worth writing down:

* The comparison is **case-sensitive** (`bbStringCompare` on raw UTF-16). The single lowercase
  `plain` in the data therefore renders as the *default*, which happens to also be Plain - the
  bug is invisible in game.
* Empty style ⇒ Plain. That silently rescues the 9 empty style cells.

**Sprite-sheet inventory check** (`EngineMedia/Match/Player/`): 16 `Player_*.png` files ship,
15 are referenced by the code above. **`Player_Hoopsb.png` (65,661 bytes) is never referenced
anywhere in the executable** - a dead asset. Do not wire it up.

### 5.3 Token → internal integer id - second dispatch at `0x0DBA33` **[CODE]**

A separate function maps the style token to a small integer (returned in `eax`). This is the
value stored in the runtime kit object; it is **not** written to the CSV.

| Token | Internal id |
|---|---|
| `PLAIN` | 0 |
| `TRIM` | 1 |
| `STRIPES`, `STRIPE`, `STRIPE_L`, `STRIPE_R` | 2 |
| `STRIPE_LR` | 3 |
| `STRIPE_RL` | 4 |
| `STRIPE_C` | 5 |
| `STRIPE_V` | 6 |
| *(7 - unused / no token maps to it)* | 7 |
| `HOOPS` | 8 |
| `HOOP`, `SINGLEHOOP` | 9 |
| `SLEEVES` | 10 |
| `SLEEVE`, `SLEEVE_L`, `SLEEVE_R` | 11 |
| `SPLIT`, `SPLIT_LR`, `DIAGONALSPLIT_LR`, `DIAGONALSPLIT_RL` | 12 |
| `CHEQUERED` | 13 |
| `SEGMENTS` | 14 |

`UNCERTAIN:` what consumes this integer. It is *not* the sprite index (STRIPES and STRIPE share
id 2 but use different sheets). Most likely it is the index into a 15-entry table used by the
non-match 2D kit renderer (menus / kit editor preview), or the suffix index for the `CKITTYPE_`
localisation key (`CKITTYPE_` literal lives at VA 0x00C6FCD0 in the same loader pool). Value 7
is reserved and unreachable from data.

### 5.4 What the Data Editor offers **[CODE]**

Two different pick-lists are built in the kit editor (`AddItem` call order at 0x134100-0x134C00):

**Full list (19 items)** - directional variants exposed:
`PLAIN, STRIPES, SLEEVES, SLEEVE_L, SLEEVE_R, HOOPS, SINGLEHOOP, SPLIT, DIAGONALSPLIT_LR,
DIAGONALSPLIT_RL, SEGMENTS, STRIPE_LR, STRIPE_RL, STRIPE_L, STRIPE_R, STRIPE_C, STRIPE_V,
CHEQUERED, TRIM`

**Reduced list (14 items)** - direction-agnostic:
`PLAIN, STRIPES, SLEEVES, SLEEVE, HOOPS, SINGLEHOOP, SPLIT, SEGMENTS, STRIPE_LR, STRIPE,
STRIPE_C, STRIPE_V, CHEQUERED, TRIM`

`UNCERTAIN:` which screen gets which list. The data strongly suggests the full list belongs to
the Nations editor and the reduced one to the Clubs editor, since `Nations.csv` uses
`SLEEVE_L`/`SLEEVE_R`/`STRIPE_L` while `Clubs.csv` uses `SLEEVE`/`STRIPE`. Note that `HOOP`
and `SPLIT_LR` appear in neither list yet occur in `Clubs.csv` (86 and 6 times) - legacy values
that predate the current editor.

### 5.5 Kit colour slot semantics

Each kit is `<style>` + 4 colours, always in this order:

| Slot | Column suffix | Applies to |
|---|---|---|
| 1 | `shirtcol1` | Shirt **base** colour |
| 2 | `shirtcol2` | Shirt **pattern** colour - the stripes / hoops / trim / sleeves ink |
| 3 | `shortscol` | Shorts |
| 4 | `sockscol` | Socks |

For `PLAIN`, `shirtcol2` is normally set equal to `shirtcol1` (2,208 home rows use PLAIN and
the overwhelming majority repeat the colour). Verified example, club id 1:
`PLAIN #FFFFFF #FFFFFF #FFFFFF #FFFFFF`.

The player sprite sheets are greyscale/palette masks recoloured at runtime; the palette-slot
names are in `.data` **[CODE]**:
`basemask, baseshirt1..6, baseshorts1..3, basesocks1..2, baseboots1..3, basehair1..3,
baseskin1..6, basegloves1..2` - sourced from the incbin'd `Inc/Player.png`.

---

## 6. `formation` - **1-based**, proven both directions

### 6.1 The list **[CODE]**

14 contiguous string objects at file offsets 0x872B14 - 0x872C6C:

| VA | Name |
|---|---|
| 0x00C74D14 | `3-4-3` |
| 0x00C74D2C | `3-5-2 A` |
| 0x00C74D48 | `3-5-2 B` |
| 0x00C74D64 | `4-2-2-2` |
| 0x00C74D80 | `4-2-4` |
| 0x00C74D98 | `4-3-3` |
| 0x00C74DB0 | `4-4-1-1` |
| 0x00C74DCC | `4-4-2 A` |
| 0x00C74DE8 | `4-4-2 B` |
| 0x00C74E04 | `4-5-1` |
| 0x00C74E1C | `5-3-2` |
| 0x00C74E34 | `Custom 1` |
| 0x00C74E50 | `Custom 2` |
| 0x00C74E6C | `Custom 3` |

### 6.2 Proof of 1-basing

**Direction A - index → name.** The dispatch at `0x0DB840`-ish is a literal `cmp eax, N / je`
ladder. Disassembled bytes:

```
0D845C  83 f8 01      cmp  eax, 1
0D845F  74 43         je   0D84A4   ->  b8 14 4d c7 00   mov eax, "3-4-3"
0D8462  83 f8 02      cmp  eax, 2
0D8465  74 45         je   0D84AB   ->  mov eax, "3-5-2 A"
...
0D847F  83 f8 08      cmp  eax, 8
0D8482  74 51         je   0D84D5   ->  b8 cc 4d c7 00   mov eax, "4-4-2 A"
0D8484  83 f8 09      cmp  eax, 9
0D8487  74 53         je   0D84DC   ->  b8 e8 4d c7 00   mov eax, "4-4-2 B"
0D8489  83 f8 0a      cmp  eax, 0Ah
0D848C  74 55         je   0D84E3   ->  mov eax, "4-5-1"
0D848E  83 f8 0b      cmp  eax, 0Bh
0D8491  74 57         je   0D84EA   ->  mov eax, "5-3-2"
0D8493  83 f8 0c      cmp  eax, 0Ch -> "Custom 1"
0D8498  83 f8 0d      cmp  eax, 0Dh -> "Custom 2"
0D849D  83 f8 0e      cmp  eax, 0Eh -> "Custom 3"
0D84A2  eb 62         jmp  0D8506   ->  b8 cc 4d c7 00   mov eax, "4-4-2 A"   ; DEFAULT
```

**Direction B - name → index.** The inverse function starts at `0x0D8511`:

```
0D8511  55 89 e5 53               push ebp; mov ebp,esp; push ebx
0D8515  8b 5d 08                  mov  ebx,[ebp+8]
0D8518  68 14 4d c7 00            push "3-4-3"
0D851D  53                        push ebx
0D851E  e8 0d d1 fc ff            call bbStringCompare
0D8526  83 f8 00                  cmp  eax,0
0D8529  75 0a                     jne  ...
0D852B  b8 01 00 00 00            mov  eax,1          ; "3-4-3"  -> 1
...
0D8535  68 2c 4d c7 00            push "3-5-2 A"
0D8543  b8 02 00 00 00            mov  eax,2          ; "3-5-2 A" -> 2
```

Both directions agree. **The mapping is:**

| `formation` value | Tactic | `.tac` file | Clubs | Nations |
|---|---|---|---|---|
| 1 | 3-4-3 | `3-4-3.tac` | 0 | 0 |
| 2 | 3-5-2 A | `3-5-2 A.tac` | 0 | 0 |
| 3 | 3-5-2 B | `3-5-2 B.tac` | 0 | 0 |
| **4** | **4-2-2-2** | `4-2-2-2.tac` | 252 | 18 |
| 5 | 4-2-4 | `4-2-4.tac` | 0 | 0 |
| **6** | **4-3-3** | `4-3-3.tac` | 239 | 6 |
| **7** | **4-4-1-1** | `4-4-1-1.tac` | 217 | 12 |
| **8** | **4-4-2 A** (flat) | `4-4-2 A.tac` | **3,316** | **108** |
| **9** | **4-4-2 B** (diamond) | `4-4-2 B.tac` | 1,193 | 59 |
| **10** | **4-5-1** | `4-5-1.tac` | 219 | 8 |
| 11 | 5-3-2 | `5-3-2.tac` | 0 | 0 |
| 12 | Custom 1 | `Custom 1.tac` | 0 | 0 |
| 13 | Custom 2 | `Custom 2.tac` | 0 | 0 |
| 14 | Custom 3 | `Custom 3.tac` | 0 | 0 |
| 0 or anything else | → **4-4-2 A** (default) | - | 0 | 0 |

Only 6 of the 14 slots are ever used in the shipped data. `8` is the bulk default - every
stub/incomplete club row (ids 4505, 5737) carries `formation = 8`, i.e. a plain 4-4-2.

### 6.3 `.tac` file format **[FILE]**

`EngineMedia/Tactics/*.tac`, 105 bytes each: **35 lines of `0` or `1`, CRLF-terminated**
(`"0\r\n"` × 35). The 35 slots are a **7-column × 5-row grid, row-major**, row 0 = own defensive
third, row 4 = attacking third. Exactly 10 slots are `1` in every file (the goalkeeper is not
represented). Decoded:

```
3-4-3      3-5-2 A    3-5-2 B    4-1-4-1*   4-2-2-2    4-2-3-1*   4-2-4
.X.X.X.    .X.X.X.    .X.X.X.    X.X.X.X    X.X.X.X    X.X.X.X    X.X.X.X
.......    ...X...    .......    ...X...    .......    ..X.X..    .......
X.X.X.X    X..X..X    X.XXX.X    X.X.X.X    ..X.X..    .......    ..X.X..
.......    ...X...    .......    .......    X.....X    .X.X.X.    .......
.X.X.X.    ..X.X..    ..X.X..    ...X...    ..X.X..    ...X...    X.X.X.X
3-0-4-0-3  3-1-3-1-2  3-0-5-0-2  4-1-4-0-1  4-0-2-2-2  4-2-0-3-1  4-0-2-0-4

4-3-3      4-4-1-1    4-4-2 A    4-4-2 B    4-5-1      5-3-2
X.X.X.X    X.X.X.X    X.X.X.X    X.X.X.X    X.X.X.X    X.XXX.X
.......    .......    .......    ...X...    .......    .......
.X.X.X.    X.X.X.X    X.X.X.X    X.....X    X.XXX.X    .X.X.X.
.......    ...X...    .......    ...X...    .......    .......
.X.X.X.    ...X...    ..X.X..    ..X.X..    ...X...    ..X.X..
4-0-3-0-3  4-0-4-1-1  4-0-4-0-2  4-1-2-1-2  4-0-5-0-1  5-0-3-0-2
```

`4-4-2 A` is the flat 4-4-2; `4-4-2 B` is the diamond (4-1-2-1-2). `3-5-2 A` has a holding
midfielder and an attacking midfielder; `3-5-2 B` is a flat five.

**\* Dead files.** `4-1-4-1.tac` and `4-2-3-1.tac` ship on disk but **neither string appears
anywhere in `NSS5.exe`** - verified by exhaustive byte search of the whole image in both
UTF-16LE and ASCII (0 hits each), while `3-4-3`, `4-4-2 A`, `5-3-2` and `Custom 1` all hit at
0x8858400, 0x8858584, 0x8858664, 0x8858688. They are unreachable. Do not add them to the
formation list in a faithful port.

Also note the hard-coded fallback path `EngineMedia\Tactics\4-4-2.tac` (string index 734) - 
that file **does not exist** on disk (only `4-4-2 A.tac` / `4-4-2 B.tac`). It is dead legacy.
Loader helper strings: `.tac` (730), `Loading Tactics:` (731), `EngineMedia\Tactics\` (732),
`Tactics\` (733), `Cannot find tactics: ` (735), `Saving Tactics:` (736), `Cannot save tactics: `
(737). The `Custom 1..3.tac` files are created by the player, not shipped.

---

## 7. `climate` (Nations only)

Integer, 0-4, no empties. Localisation keys in `.data` **[CODE]** - only **four** exist:

| VA | key |
|---|---|
| 0x00C82E74 | `climate_Variable` |
| 0x00C82EA0 | `climate_Cold` |
| 0x00C82EC4 | `climate_Warm` |
| 0x00C82EE8 | `climate_Hot` |

`GameMedia/Languages/Languages.csv` also contains exactly these four keys and no others
matching `climate_*` **[FILE]**.

The editor builds the combo by four sequential `AddItem` calls at `0x12898B`, `0x1289B3`,
`0x1289DB`, `0x128A0F`, in the order Variable → Cold → Warm → Hot, and each key is referenced
exactly once in the whole binary (no int→key dispatch exists). The stored value is therefore
the raw 0-based combo index. **[CODE] + [INFER]**

Corroborated decisively by the data **[FILE]** - mean absolute latitude per value:

| Value | Meaning | Nations | Mean \|latitude\| | Sample |
|---|---|---|---|---|
| 0 | **Variable** | 112 | 32.3° | Afghanistan, Argentina, Armenia, Austria, Azerbaijan, Belarus, Belgium, Bhutan, England, Germany, France, China, Japan |
| 1 | **Cold** | 6 | **50.2°** | Albania, Andorra, Iceland, Russia, Switzerland, Ukraine |
| 2 | **Warm** | 52 | 21.2° | Angola, Australia, Bahamas, Bangladesh, Brazil, Egypt |
| 3 | **Hot** | 36 | **14.2°** | Bahrain, Benin, Botswana, Brunei, Burkina Faso, Burundi, Chad |
| 4 | *(out of range)* | **5** | 21.7° | Algeria, Ghana, Greece, Grenada, Guadeloupe |

The monotonic latitude gradient 1 (50.2°) → 2 (21.2°) → 3 (14.2°) confirms Cold/Warm/Hot, and
0 being the mixed-latitude bulk confirms Variable.

**Value 4 is a data defect, not a fifth climate.** Only 5 nations carry it and they are
alphabetically adjacent (`Algeria`, `Ghana`, `Greece`, `Grenada`, `Guadeloupe`) - a classic
fill-down accident during editing. There is no `climate_` string for index 4; a faithful loader
must decide what the engine does with an out-of-range value.
`UNCERTAIN:` the exact out-of-range behaviour. The likely candidates are (a) an array read past
the end of a 4-element table, or (b) a `Select`-with-default that falls back to Variable. This
was not traced. The engine-side consumer is `SetUpWeatherConditions` (string index 640) with
`weatherchance=` (641), `SetWeatherTimes s=` (1325), and assets
`EngineMedia/Match/Pitch/Rain.png`, `Snow.png`, `EngineMedia/Match/Sounds/Rain.ogg`.

---

## 8. `primaryskin` / `secondaryskin` (Nations only)

Integer, 0-4, no empties, **0-based**. Two parallel name sets exist in `.data` **[CODE]**:

| Index | Editor combo key (0x00C82F0C…) | Engine constant (string dump 807-811) |
|---|---|---|
| 0 | `skin_White` | `CSKIN_LIGHT` |
| 1 | `skin_Light` | `CSKIN_MEDIUM` |
| 2 | `skin_Dark` | `CSKIN_DARK` |
| 3 | `skin_Black` | `CSKIN_BLACK` |
| 4 | `skin_Asian` | `CSKIN_ASIAN` |

(`CSKIN_UNKNOWN:` at index 812 is the diagnostic printed for an unmapped value.)

Two combo boxes are built - Primary Skin at `0x128A97…0x128B47` and Secondary Skin at
`0x128BCF…0x128C7F` - each adding the five keys in the order above.

**Confirmed by data [FILE]** - the mapping is unambiguous:

| Value | Meaning | Nations with `primaryskin = v` | Nations with `secondaryskin = v` | Evidence |
|---|---|---|---|---|
| 0 | White | 72 | 67 | Sweden 0/0, Norway 0/0, Iceland 0/0, Argentina 0/1 |
| 1 | Light | 31 | 35 | Algeria 1/1 |
| 2 | Dark | 35 | 58 | Brazil 2/0, India 4/2 |
| 3 | Black | 38 | 20 | Nigeria 3/3, Cameroon 3/3, Senegal 3/2, Jamaica 3/2 |
| 4 | Asian | 35 | 31 | China 4/4, Japan 4/4, Korea Republic 4/4, Mongolia 4/4, Thailand 4/4 |

Most common `(primary, secondary)` pairs: `(0,0)` ×52, `(3,2)` ×36, `(4,4)` ×18, `(2,3)` ×15,
`(0,1)` ×14, `(1,0)` ×10, `(2,1)` ×9, `(4,2)` ×8, `(4,1)` ×8, `(1,4)` ×8.

Reading: when the engine generates a player of nationality *N*, it draws a skin tone from
`primaryskin` most of the time and `secondaryskin` as the minority variant.
`UNCERTAIN:` the exact split ratio (e.g. 70/30) was not traced.

Note the value `4` is applied loosely - Egypt, Saudi Arabia, India and Ghana all carry
`primaryskin = 4`. For AFC members that reads as "Asian confederation"; Ghana (a CAF member with
`secondaryskin = 3`) looks like the same fill-down error region that produced its `climate = 4`.

**Related enum (for completeness) - hair colours [CODE]**, string dump 799-806:
`CHAIR_BLACK, CHAIR_BROWN, CHAIR_BLOND, CHAIR_RED, CHAIR_GREY, CHAIR_LBROWN, CHAIR_DBLOND`
plus `CHAIR_UNKNOWN:`. These are not stored in Clubs/Nations; they are per-player.
Adjacent literal `BOOTCOL:` (779) precedes a run of raw hex colour constants
`444444, 404040, 5B2603, E5E60E, EA3C00, 999999, AC541A, D7A303, FFC28E, C47840, B75E23,
7C3400, C6A754, 4BD998, 9900DE, FF9933, 00FFFF, 2D00EA, EA0005` - note these are **bare hex,
no `#`**, unlike the CSV colour columns.

---

## 9. Colour columns - format confirmed

**Confirmed: colours are `#` + 6 uppercase hexadecimal digits = 24-bit RGB.** **[FILE]**

Validated across all 16 colour columns in both files: **90,335 of 90,352 cells** match
`^#[0-9A-Fa-f]{6}$`. **Zero cells use lowercase hex.** No alpha channel, no 3-digit shorthand,
no named colours, no `0x` prefix.

Most frequent colours in `Clubs.csv` (all 16 colour columns pooled):

| Count | Value | Reading |
|---|---|---|
| 31,485 | `#FFFFFF` | white - the overwhelming default |
| 7,372 | `#FF0000` | red |
| 6,940 | `#0000FF` | blue |
| 6,441 | `#444444` | the game's "black" (a dark grey, so it reads on a dark pitch) |
| 5,450 | `#05CD32` | the stock goalkeeper green |
| 5,235 | `#000000` | true black |
| 4,910 | `#008000` | green |
| 3,714 | `#FFFF00` | yellow |
| 2,303 | `#000080` | navy |
| 1,871 | `#00FF00` | bright green |
| 1,094 | `#00FFFF` | cyan |
| 942 | `#8080FF` | light blue |
| 824 | `#00EB00` | alt keeper green |
| 812 | `#C00000` | dark red |
| 637 | `#FF5A00` | orange |

`#444444` rather than `#000000` for "black" kits is a deliberate rendering choice and appears
6,441 times - reproduce it literally, do not "fix" it.

The default stock goalkeeper kit, seen on thousands of rows, is
`PLAIN #05CD32 #05CD32 #008000 #FFFFFF`.

---

## 10. Data defect register

Everything below is a genuine defect in the shipped data. A faithful reconstruction should
**reproduce the files byte-for-byte** and make the loader tolerant, rather than clean the data.

### 10.1 The 17 malformed colour cells **[FILE]**

| File | id | Club / Nation | Column | Raw value | Problem |
|---|---|---|---|---|---|
| Clubs | 100 | Arsenal de Sarandí | 17 `homekitsockscol` | `#OOBFFF` | letter **O** instead of digit 0 (×2) |
| Clubs | 177 | Perth Glory | 25 `thirdkitshirtcol2` | `#9933CC ` | **trailing space** |
| Clubs | 562 | Hohhot Dongjin FC (disbanded) | 17 `homekitsockscol` | `#CC` | truncated |
| Clubs | 2208 | ŁKS Łódź | 22 `awaykitsockscol` | `#4444` | truncated |
| Clubs | 2211 | Świt Nowy Dwór Mazowiecki | 24 `thirdkitshirtcol1` | `#` | empty after `#` |
| Clubs | 2227 | ROW 1964 Rybnik | 15, 16, 17 | `#` | empty ×3 |
| Clubs | 2242 | Jarota Jarocin | 30 `keeperkitshirtcol2` | `#` | empty |
| Clubs | 2251 | Korona Kielce | 31, 32 | `#` | empty ×2 |
| Clubs | 2278 | Podbeskidzie Bielsko-Biała | 25 `thirdkitshirtcol2` | `#` | empty |
| Clubs | 2935 | SD Amorebieta | 16 `homekitshortscol` | `#OO47AB` | letter **O** ×2 |
| Clubs | 4348 | CRO FC | 21, 22 | `#00000` | **5** digits |
| Nations | 150 | Poland | 27 `thirdkitsockscol` | `#00033` | 5 digits |
| Nations | 154 | Republic of Ireland | 25 `thirdkitshirtcol2` | `#00800` | 5 digits |

`UNCERTAIN:` how the engine's colour parser handles these. Any faithful loader must not crash;
the plausible BlitzMax idiom (`Int("$" + col[1..])`) yields 0 (black) for `#`, `#OO…`,
and yields a shifted value for the 5-digit cases (`#00033` → 0x00033 = `#000033`).

### 10.2 Structurally broken row - club id 337 **[FILE]**

```
337  Club Blooming  Blooming  BLOOM  48  343  0  0  Estadio Tahuichi Aguilera  38000
     -63.1660004  -17.7980003
     TRIM  #0000FF #FFFFFF #444444 #FFFFFF
     TRIM  #FF6600 #FFFFFF #444444 #FFFFFF
     TRIM  #FF6600 #FFFFFF #444444 #FFFFFF
     #FFFFFF  #FFFFFF #05CD32 #05CD32 #008000        <-- keeperstyle slot holds a COLOUR
     8  8  25  1300  0  0                            <-- nickname = "8"
```

The row still has exactly 38 fields, so it parses, but fields 28-34 are shifted: `keeperstyle`
receives `#FFFFFF` (falls back to `Player_Plain.png`) and `nickname` receives the string `"8"`.
Fields 35-38 (`nationid=25` Bolivia, `leagueid=1300`) are correct, so the corruption is
self-contained. It is the sole source of `keeperstyle` distinct value `#FFFFFF` and the sole
numeric `nickname`.
`UNCERTAIN:` the intended original values. The keeper block was probably meant to be
`PLAIN #05CD32 #05CD32 #008000 #FFFFFF` (the stock kit) with an empty nickname, but a simple
one-field shift does not reproduce the observed bytes.

### 10.3 Geographic errors **[FILE]**

| File | id | Name | Stored lon | Stored lat | Diagnosis |
|---|---|---|---|---|---|
| Clubs | 4431 | PSM Makassar | 122.622696 | **−722.317383** | decimal point misplaced; intended ≈ −7.22317383 (Surabaya) |
| Clubs | 5069 | Jiangxi Liansheng FC | 28.6389999 | **116.029999** | **lon/lat swapped** (Nanchang is 28.64 N, 116.03 E) |
| Clubs | 5413 | MISC-MIFA | 2.81699991 | **101.800003** | **lon/lat swapped** (USIM is 2.82 N, 101.80 E) |
| Nations | 23 | Bermuda | 32.2999992 | **−64.7699966** | **lon/lat swapped** (32.30 N, −64.77 W) |
| Nations | 24 | Bhutan | 27.4699993 | **89.6399994** | **lon/lat swapped** (27.47 N, 89.64 E) |

Additionally **7 club rows have `longitude = 0` and `latitude = 0`** (unplaced stubs), and
**4 club rows have an empty `stadiumname`** (ids 4505 `ASK Ebreichsdorf`, 5537 `CF Peralada`,
5561 `Mouloudia Dakhla`, 5562 `Eleven Wonders`). `Nations.csv` has no 0/0 coordinates.

Coordinate precision in `Clubs.csv` is inconsistent - decimal places range 0 to 10, with the
bulk at 7 (3,183 rows) and 8 (1,094 rows), consistent with 32-bit float round-tripping:

| Decimals | Rows |
|---|---|
| 0 | 287 |
| 1 | 65 |
| 2 | 147 |
| 3 | 117 |
| 4 | 20 |
| 5 | 6 |
| 6 | 388 |
| 7 | 3,183 |
| 8 | 1,094 |
| 9 | 111 |
| 10 | 18 |

Store these as **`Float` (32-bit), not `Double`** - the values `69.1900024`, `34.5200005`,
`-0.280000001` are exactly what you get printing a BlitzMax `Float`.

### 10.4 Other anomalies **[FILE]**

* `stadiumcapacity = 525000` for **Minnesota United FC** (TCF Bank Stadium, real capacity
  52,500) - an extra trailing zero. Second-largest is 120,000 (Salt Lake Stadium ×2), which is
  correct.
* **11 clubs** have `stadiumcapacity = 0`.
* **9 style cells are empty**: `homestyle` ×2, `awaystyle` ×3, `thirdstyle` ×2, `keeperstyle` ×2.
  Concentrated in three stub rows (4505 `ASK Ebreichsdorf` - all four empty; 5737
  `Triomphe FC de Liancourt` - all four empty; 4552 `FC Mynai` - `awaystyle` only).
* Club 5748 `FC Codru Lozova` has `homestyle = plain` (lowercase) - falls through to the
  Plain default, no visible effect.
* **3 clubs have `nationid = 0`**: 4238 `ASC Jeanne d'Arc`, 4327 `MŠK Žilina II`,
  5737 `Triomphe FC de Liancourt`.
* **1 dangling club id**: 1514 (referenced by `Dempo SC.rivalclub1` and
  `Churchill Brothers.rivalclub2`; the id itself is in the 1513→1516 gap).
* `Clubs.tla` values with embedded trailing spaces: `LAÇI `, `SAÏDA `, `SKËNDE `, `SÉTIF `,
  `TËRBUNI  ` (two spaces). The loader does **not** appear to trim; reproduce verbatim.
* **59 club `name` values end in a space** and **29 club `tla` values end in a space**; no field
  in either file has a *leading* space, and `Nations.csv` has none at all. The affected rows are
  almost all accented names - e.g. ids 31 `KS Gramozi Ersekë `, 33 `KS Luftëtari Gjirokastër `,
  38 `KF Skënderbeu Korçë `, 43 `KS Tërbuni Pukë `, 62 `MC Saïda `, 63 `MO Béjaïa `,
  74 `USM Bel-Abbès `, 77 `USM Sétif `, 1215 `Bayern München `. **Do not trim on load** - the
  original renders them with the space.

---

## 11. Reimplementation notes

### 11.1 Suggested BlitzMax types

```blitzmax
Type TKit
    Field style:String          ' raw CSV token, kept verbatim
    Field shirtcol1:Int         ' 0xRRGGBB
    Field shirtcol2:Int
    Field shortscol:Int
    Field sockscol:Int
End Type

Type TContinent
    Field id:Int
    Field name:String
    Field tla:String
    Field continentality:String
    Field federationname:String
    Field federationshortname:String
    Field strength:Int
End Type

Type TNation
    Field id:Int
    Field name:String
    Field shortname:String
    Field tla:String
    Field strength:Int
    Field rivalid:Int[3]
    Field stadiumname:String
    Field stadiumcapacity:Int
    Field stadiumlongitude:Float
    Field stadiumlatitude:Float
    Field kit:TKit[4]           ' 0=home 1=away 2=third 3=keeper
    Field formation:Int         ' 1-based, default 8
    Field nationality:String
    Field continent:Int         ' 1..6
    Field climate:Int           ' 0..3 (4 occurs in data)
    Field primaryskin:Int       ' 0..4
    Field secondaryskin:Int     ' 0..4
End Type

Type TClub
    Field id:Int
    Field name:String
    Field shortname:String
    Field tla:String
    Field strength:Int
    Field rivalclub:Int[3]
    Field stadiumname:String
    Field stadiumcapacity:Int
    Field stadiumlongitude:Float
    Field stadiumlatitude:Float
    Field kit:TKit[4]           ' 0=home 1=away 2=third 3=keeper
    Field formation:Int         ' 1-based, default 8
    Field nickname:String       ' may be empty
    Field nationid:Int          ' 0 = none
    Field leagueid:Int          ' 0 = none
    Field continentalcompid:Int ' 0 = none
    Field bteamof:Int           ' 0 = is a first team
End Type
```

### 11.2 Load order

`Continents.csv` → `Nations.csv` → `Clubs.csv` → `Competitions.csv` → `PromotionPlaces.csv`.
Cross-references (`nationid`, `leagueid`, `continentalcompid`, `bteamof`, rivals) must be
resolved **after** all files are read, because `Clubs.rivalclub*` and `bteamof` point forward
as well as backward (e.g. `Toronto FC Academy` → 3327, and `rivalclub2` values up to 5383).
Dangling ids must resolve to Null, not abort.

### 11.3 Pitfall checklist

1. TAB delimiter - never comma.
2. `Clubs.csv` is LF; the rest are CRLF. Strip `\r` defensively.
3. UTF-8, no BOM. Club/nation names carry `í ç ë ş ł ő ã ü ñ`.
4. Skip line 1 (header). Stop at a line beginning `//`.
5. Kit styles are **strings**, matched case-sensitively; unknown ⇒ `Player_Plain.png`.
6. `formation` is **1-based**; out-of-range ⇒ `4-4-2 A`.
7. `climate`, `primaryskin`, `secondaryskin`, `continent` are **integers**; `continent` is
   1-based, the other three are 0-based.
8. Coordinates are **Float**, not Double.
9. `0` means "none" for every FK field (`rivalclub*`, `rivalid*`, `nationid`, `leagueid`,
   `continentalcompid`, `bteamof`) - and `Continents.id`/`Nations.id` legitimately start at 1,
   so `0` can never collide with a real key.
10. Do not add `4-1-4-1` or `4-2-3-1` to the formation list, and do not reference
    `Player_Hoopsb.png` - both are dead assets.

---

## 12. Open questions

* `UNCERTAIN:` what consumes the 0-14 internal kit-type integer from §5.3, and what index 7 was
  reserved for.
* `UNCERTAIN:` which editor screen gets the 19-item vs the 14-item kit-style pick-list.
* `UNCERTAIN:` engine behaviour for `climate = 4` (5 nations affected).
* `UNCERTAIN:` the primary/secondary skin selection ratio.
* `UNCERTAIN:` how `Continents.strength`, `Nations.strength` and `Clubs.strength` are consumed
  numerically (seeding, match-engine weighting, transfer valuation). Debug strings
  `>>> clubstrength = ` and `ClubStrength:` (string-dump 3254, 3257) are the entry point for
  that trace.
* `UNCERTAIN:` the exact colour parser (`#` → Int) and its behaviour on the 17 malformed cells.
* `UNCERTAIN:` the intended pre-corruption values of club id 337.
