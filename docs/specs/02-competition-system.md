# NSS5 Reconstruction - Spec 02: The Competition / Calendar System

**Scope:** `GameMedia/Data/Competitions.csv`, `GameMedia/Data/PromotionPlaces.csv`,
`GameMedia/Data/venuesWC.txt`, `venuesEuros.txt`, `venuesCopa.txt`, `venuesACoN.txt`.

**Status:** derived by direct measurement against the shipped data files and cross-checked against
UTF-16 string evidence extracted from `NSS5.exe`. Every numeric claim in this document was computed
from the real files; every bracket size quoted was verified to close exactly. Items that could not be
proven are marked **UNCERTAIN**.

**Source of truth (read-only):**
`C:/Program Files (x86)/Steam/steamapps/common/New Star Soccer 5/GameMedia/Data/`

---

## 0. Executive summary

The whole football world of NSS5 - every league, every cup, every qualifying round, promotion,
relegation, play-off and international tournament - is expressed as **two tables and one graph**:

* `Competitions.csv` (1,028 competitions) declares *what* each competition is and *when* it runs.
* `PromotionPlaces.csv` (2,067 edges) declares *where teams go afterwards*: `(parentid, place) -> promotiontoid`.

There is no hard-coded structure in the engine beyond six competition *shapes* (`comptype`) and two
fixture generators (`CreateFixtureListLeague:` / `CreateFixtureListKO:`). Everything else is data.
The graph is **closed** (verified: zero dangling `parentid`, zero dangling `promotiontoid`) and
**arithmetically exact** - e.g. the World Cup Pool receives precisely 32 teams, the FA Cup collapses
80 → 40 → … → 2, the Champions League group stage receives precisely 32 and the Europa League
precisely 48.

---

## 1. Physical file format

Both CSVs share the same conventions.

| Property | Value |
|---|---|
| Delimiter | **TAB** (`0x09`) - *not* comma |
| Encoding | **UTF-8, no BOM** (verified: `C3 B3` = `ó`, `C3 AB` = `ë`, `C3 AD` = `í`) |
| Line terminator | **CRLF** (`0D 0A`) on **every** line, including the last (verified 1030/1030 and 2069/2069) |
| Header row | present, field names lower-case, **no trailing tab** |
| Data rows | **have a trailing tab** → `awk -F'\t'` reports 21 fields for a 20-column file |
| End-of-file sentinel | a final line containing exactly `//` |
| Sorting | `Competitions.csv` is sorted ascending by `id` (verified) |

**Parser requirement:** split on TAB, ignore a trailing empty field, stop at a line whose first field
is `//`. The same `//` sentinel appears in `Continents.csv`, so it is a house convention of the loader
(`TCompetition.LoadData`, `TPromotionPlace.LoadData`).

Row counts:

| File | Physical lines | Header | Sentinel | **Real records** |
|---|---|---|---|---|
| `Competitions.csv` | 1030 | 1 | 1 | **1028** |
| `PromotionPlaces.csv` | 2069 | 1 | 1 | **2067** |

**Faithfulness note:** the data contains genuine typos that must be preserved byte-for-byte, e.g.
competition 1424 is `Campeonato Brasileiro 3ã Divisão Regional Sort` - the `ã` (`C3 A3`) is a mis-typed
ordinal `ª`. Likewise `Europa League 3d Qualifying Round` (missing `r`) and
`Liga II Seria II (No longer used)`.

### 1.1 Mobile variants

The binary also references `GameMedia/Data/Mobile/Competitions.txt` and
`GameMedia/Data/Mobile/PromotionPlaces.txt`. Neither ships with the PC build. The loader supports both
paths; the PC build always takes the `.csv` route.

---

## 2. Engine-side identifiers recovered from `NSS5.exe`

These are literal strings in the executable and are the strongest evidence available for the field
semantics. They should be reused verbatim as identifier names in the reconstruction.

**Loader / column names** (in file order, confirming the header):
`name locale level based comptype startyear startweek duration recurring primarymatchday
secondarymatchday groups rounds legs townregion compstatus minstrength maxstrength`

**comptype enum names** (found as a contiguous block):

```
comptype_League          comptype_Pool
comptype_KO              comptype_LeagueCont
comptype_BestPlaced      comptype_RegionalSort
```

`GameMedia/Languages/Languages.csv` gives their display strings:

| Tag | English label |
|---|---|
| `comptype_League` | League |
| `comptype_KO` | KO |
| `comptype_BestPlaced` | Best Placed |
| `comptype_Pool` | Pool |
| `comptype_LeagueCont` | League Continuation |
| `comptype_RegionalSort` | Regional Sort |

**Adjacent UI label blocks** (unlabelled in the binary, matched to columns by value domain):

| Block | Strings | Maps to |
|---|---|---|
| Tie format | `ET/P`, `R/ET/P`, `2L/ET/P` | `legs` = 0, 1, 2 |
| Region | `None`, `North`, `East`, `South`, `West`, `Combn` | `townregion` = 0..5 |
| Locale | `Nation`, `Continent`, `World` | `locale` = 0, 1, 2 |
| Level | `Club`, `International` | `level` = 0, 1 |
| Recurring combo | `Every Year`, `Year`, `Years` | `recurring` |

**Runtime function labels** (these are real function names - use them):

```
SetUpCompetitionsAll      CreateTeamPool:          DoPromotionPlaces:
SetUpCompetition:         PopulateTeamPool:         PromotionToId:
Creating Fixtures         CreateFixtureListLeague:  Place:
GetNoofTeamsInRound:      CreateFixtureListKO:      Promoting to:
IsComplete:               CreateReplayFixture:      ValidatePromotionPlacesAll
IsCupFinal:               fixture_Bye               Test_UpdateNoofTeamsInLeagues
PlayFixtures              gameyear:                 Test_CheckNoofTeamsInLeagues
```

**Error/warning strings** (these tell us what the engine validates):

```
Could not promote to competition! Comp:
WARNING! Promotion place errors in competition(s):
WARNING! Promotion place exceeds number of teams in competition:
WARNING! Number of teams changed in:
```

The last two are decisive: `place` is validated against the number of teams in the *parent*
competition - which is why the special codes live at 100+ (out of range of any real finishing
position, so the check must special-case them).

**Venue files** are referenced as four literal paths:
`GameMedia/Data/venuesACoN.txt`, `venuesCopa.txt`, `venuesEuros.txt`, `venuesWC.txt`.

---

## 3. `Competitions.csv` - column reference

Header, verbatim:

```
id	name	tla	locale	level	based	comptype	startyear	startweek	duration	recurring	primarymatchday	secondarymatchday	groups	rounds	legs	townregion	compstatus	minstrength	maxstrength
```

| # | Column | Type | Domain observed | Meaning |
|---|---|---|---|---|
| 1 | `id` | int | 10 … 10412 | Primary key. Unique. |
| 2 | `name` | UTF-8 string | 3-46 chars | Display name. 23 names are duplicated across nations. |
| 3 | `tla` | UTF-8 string | 2-14 chars | Short display abbreviation ("TLA" is a misnomer). 15 duplicated. |
| 4 | `locale` | enum | 0, 1, 2 | 0=`Nation`, 1=`Continent`, 2=`World`. **Selects how `based` is interpreted.** |
| 5 | `level` | enum | 0, 1 | 0=`Club`, 1=`International` (national teams). |
| 6 | `based` | int | 0 … 211 | **Polymorphic** - see §3.3. |
| 7 | `comptype` | enum | 0 … 5 | Competition shape. See §3.4. |
| 8 | `startyear` | int | 0 … 4 | Phase within the `recurring` cycle. See §3.5. |
| 9 | `startweek` | int | 0 … 52 | Season week the competition begins. |
| 10 | `duration` | int | 0 … 104 | Span in **weeks**. See §3.6. |
| 11 | `recurring` | int | 1, 2, 4 | Period in years. 1 = every season. |
| 12 | `primarymatchday` | int | 1-7, 99 | Preferred day of week (1=Mon … 7=Sun). 99 = no fixtures. |
| 13 | `secondarymatchday` | int | 1-7, 99 | Second slot in the week. 99 = none. |
| 14 | `groups` | int | 1,2,3,4,6,8,10,12,20 | Number of parallel groups (League only). |
| 15 | `rounds` | int | 0 … 4 | Times each pair meets (League); always 1 for KO. |
| 16 | `legs` | enum | 0, 1, 2 | Tie format (KO only). See §3.9. |
| 17 | `townregion` | enum | 0 … 4 | Geographic tag / sort axis. See §3.10. |
| 18 | `compstatus` | int | 0-6, 70 | Pyramid tier / prestige tier. See §3.11. |
| 19 | `minstrength` | int | 0 … 99 | Strength band low. See §3.12. |
| 20 | `maxstrength` | int | 0 … 99 | Strength band high. See §3.12. |

### 3.1 Composition of the file

| `comptype` | Name | Count | Plays matches? |
|---|---|---|---|
| 0 | League | 339 | yes |
| 1 | KO | 651 | yes |
| 2 | BestPlaced | 5 | no (virtual) |
| 3 | Pool | 2 | no (virtual) |
| 4 | LeagueCont | 17 | yes |
| 5 | RegionalSort | 14 | no (virtual) |

### 3.2 `locale` × `level` - only four combinations exist

| `locale` | `level` | Count | Meaning | Example |
|---|---|---|---|---|
| 0 | 0 | 915 | Domestic club competition | 2270 Premiership |
| 1 | 0 | 73 | Continental club competition | 350 Champions League Group Stage |
| 1 | 1 | 34 | Continental national-team competition | 280 European Championship Group Stage |
| 2 | 1 | 6 | World national-team competition | 20 World Cup Stage 1 |

`(locale=0, level=1)` and `(locale=2, level=0)` never occur. A reconstruction may assert this.

### 3.3 `based` - polymorphic foreign key

`based` **must** be resolved through `locale`:

| `locale` | `based` refers to | Range in data |
|---|---|---|
| 0 (Nation) | `Nations.csv.id` | 2 … 211 (plus two dead rows with 0) |
| 1 (Continent) | `Continents.csv.id` | 1 … 6 (plus one row with 0) |
| 2 (World) | **UNCERTAIN** - see below | 0 or 169 |

The collision is real and dangerous: competition **9300 “Angolan Girabola”** has `based=6` meaning
*Angola* (nation 6), while competition **350 “Champions League Group Stage”** has `based=6` meaning
*Europe* (continent 6). Only `locale` disambiguates them.

Continent ids (from `Continents.csv`):

| id | Continent | Federation | Nations in `Nations.csv` |
|---|---|---|---|
| 1 | Asia | AFC | 46 |
| 2 | Africa | CAF | 53 |
| 3 | North America | CONCACAF | 36 |
| 4 | South America | CONMEBOL | 10 |
| 5 | Oceania | OFC | 11 |
| 6 | Europe | UEFA | 55 |

**UNCERTAIN - `based` for `locale=2`:** the five World Cup finals stages (ids 20,30,40,50,60) all carry
`based=169`. Nation 169 is *Singapore*, which is not a World Cup host in any of the venue files and is
not otherwise referenced. World Cup Pool (id 10) carries `based=0`. The most likely readings are
(a) a stale/fallback host-nation id that is overwritten from `venuesWC.txt`, or (b) an ignored field
for `locale=2`. Reproduce the literal value `169`; do not attach meaning to it without further
disassembly.

**`locale=1, based=0`:** exactly one row - 70 `CBL/OFC WCQ Play-Off`. Its sibling 80
`CONCACAF/AFC WCQ Play-Off` carries `based=5` (Oceania), which is also wrong for a
CONCACAF/AFC tie. Both are inter-confederation play-offs whose entrants come purely from
`PromotionPlaces`, so `based` is cosmetic there. Treat both values as data noise.

### 3.4 `comptype` - the six competition shapes

#### `comptype = 0` - League (`comptype_League`)

Round-robin. Entrants are split into `groups` groups; every pair inside a group meets `rounds` times.
Produces a standings table. Used for domestic leagues, tournament group stages and qualifying groups.

* `groups` > 1 occurs **only** for this type.
* `rounds = 0` (100 rows) means the "league" never plays - these are the `Non-League XXX` holding pens
  and disabled divisions. They still hold clubs and still feed cups via `place=100`.

Matchday count (verified against every seeded league):

```
teamsPerGroup = floor(teams / groups)
matchdays = rounds * (teamsPerGroup - 1)          if teamsPerGroup is even
matchdays = rounds * teamsPerGroup                 if teamsPerGroup is odd   (one bye per matchday)
```

Worked: Premiership 20 teams, `rounds=2` → 38 matchdays. Championship 24 teams, `rounds=2` → 46.
Scottish Premier League 12 teams, `rounds=3` → 33. Austrian Bundesliga (id 950) 12 teams,
`rounds=4` → 44.

#### `comptype = 1` - KO (`comptype_KO`)

**One competition record = one knockout round.** Always `groups=1`, always `rounds=1`. Teams are
paired; `legs` decides the tie format. Winners leave via place code 103, losers via 104.
An odd entrant count produces a bye (`fixture_Bye` exists in the binary and is *required* - see §7.4).

#### `comptype = 2` - BestPlaced (`comptype_BestPlaced`)

A **virtual ranking competition**. Plays no matches (`duration=0`, `rounds=0`,
`primarymatchday=secondarymatchday=99`, `groups=1`). It collects teams fed in from a multi-group
League (typically all the runners-up or all the third-placed teams), ranks them against each other,
and then re-emits the best N via ordinary `place=1..N` edges.

All five instances:

| id | Name | Fed by | Emits |
|---|---|---|---|
| 95 | AFC World Cup Qualifiers Best Runners-Up | 90 place 2 (×8 groups) | places 1-4 → 100 |
| 140 | CAF WCQ Best Runners-Up | *(no inbound edges - dead)* | none |
| 285 | European Championship Best 3rd Place | 280 place 3 (×6 groups) | places 1-4 → 295 |
| 330 | UEFA WCQ Best Placed Runner Up | 290 place 2 (×8 groups) | places 1-6 → 10 |
| 10411 | Copa Libertadores Best Placed | 4 domestic league places | places 1-2 → 9520 |

**UNCERTAIN:** the exact tie-break used to rank teams that played in different groups
(points, then goal difference, then goals - and whether results against the bottom team of an
uneven group are discarded, as in real UEFA rules). The data cannot tell us.

#### `comptype = 3` - Pool (`comptype_Pool`)

A **virtual holding container**, also playing no matches. It accumulates teams across a whole
qualifying cycle and then re-emits them via `place=1..N` so a draw can be made. Exactly two instances:

| id | Name | Capacity | Emits to |
|---|---|---|---|
| 10 | World Cup Pool | 32 | places 1-32 → 20 World Cup Stage 1 |
| 340 | European Championship Pool | 24 | places 1-24 → 280 Euro Group Stage |

Both have `startyear=1, recurring=4` - i.e. they are created at the *start* of the 4-year cycle and
filled during it, whereas the finals they feed have `startyear=4` (WC) / `startyear=2` (Euro).

**UNCERTAIN:** whether the Pool's own `startweek`/`duration`/`startyear` are used at all, or whether
Pool/BestPlaced/RegionalSort competitions are simply resolved on demand when a `DoPromotionPlaces`
edge fires. The scheduling fields of these types are mutually inconsistent across the file
(e.g. 330 has `startyear=1` while the competition feeding it has `startyear=3`), which strongly
suggests they are dead for virtual types.

#### `comptype = 4` - LeagueCont (“League Continuation”)

A **split phase**: the parent league stops mid-season and its table is cut into a championship group
and one or more relegation groups, which then play further round-robin matches. The name
("League Continuation") and the calendar layout imply the parent standings are **carried over**.

Verified example - Scottish Premier League: parent 6180 = 12 teams, `rounds=3`, weeks 4-33 (33 matchdays);
split at week 33 into 6230 (places 1-6) and 6240 (places 7-12), each 6 teams `rounds=1`, weeks 33-40
(5 matchdays). 33 + 5 = **38**, the real SPL season length.

All 17 instances:

| id | Name | Teams | `rounds` | `sw` | `dur` | Fed from (places) |
|---|---|---|---|---|---|---|
| 800 | Play off per al títol (AND) | 4 | 2 | 20 | 7 | 730 (1,2,3,4) |
| 810 | Play off pel descens (AND) | 4 | 2 | 20 | 7 | 730 (5,6,7,8) |
| 1315 | Premijer Liga Championship | 6 | 1 | 33 | 8 | 1310 (1-6) |
| 1316 | Premijer Liga Relegation | 6 | 1 | 33 | 8 | 1310 (7-12) |
| 1505 | A PFG Championship Group | 6 | 1 | 35 | 8 | 1500 (1-6) |
| 1506 | A PFG Relegation Group | 8 | 1 | 35 | 8 | 1500 (7-14) |
| 2065 | Danish Superliga Championship | 6 | 2 | 30 | 8 | 2060 (1-6) |
| 2066 | Danish Superliga Relegation Group A | 4 | 2 | 30 | 8 | 2060 (7,10,11,14) |
| 2067 | Danish Superliga Relegation Group B | 4 | 2 | 30 | 8 | 2060 (8,9,12,13) |
| 4750 | Maltese Championship Playoff | 0 | 0 | 1 | 0 | **dead - no inbound edges** |
| 4760 | Maltese Relegation Playoff | 0 | 0 | 1 | 0 | **dead - no inbound edges** |
| 5855 | Liga I Championship Round | 6 | 1 | 33 | 8 | 5850 (1-6) |
| 5856 | Liga I Relegation Round | 8 | 1 | 33 | 8 | 5850 (7-14) |
| 6230 | Scottish Premier League 1 | 6 | 1 | 33 | 8 | 6180 (1-6) |
| 6240 | Scottish Premier League 2 | 6 | 1 | 33 | 8 | 6180 (7-12) |
| 10091 | A Kategoria Championship Phase | 6 | 1 | 33 | 8 | 1900 (1-6) |
| 10092 | A Kategoria Relegation Phase | 6 | 1 | 33 | 8 | 1900 (7-12) |

Note the Danish snake-split (7,10,11,14 / 8,9,12,13) - the two relegation groups are seeded
alternately rather than by contiguous block.

**UNCERTAIN:** whether points carry over in full, are halved, or reset. `comptype_LeagueCont` and the
fact that these groups never emit a champion-only edge (every single place emits an edge back to the
parent league for next season, see §5.4) argue strongly for **full carry-over**.

#### `comptype = 5` - RegionalSort (`comptype_RegionalSort`)

A **virtual geographic sorter**. Plays no matches. It receives teams, **sorts them geographically**
along the axis given by `townregion` (using club stadium latitude/longitude, which
`Clubs.csv` provides as `stadiumlatitude` / `stadiumlongitude`), and re-emits them by rank via
`place=1..N`. This is how the game distributes relegated clubs into regionalised third/fourth tiers.

Proof by wiring (see §8.5): `2340 National Pool North/South` (`townregion=1`) takes the bottom four of
the English Conference and emits `place 1,2 → National North` and `place 3,4 → National South`.

### 3.5 `startyear` and `recurring` - the multi-year cycle

`recurring` is the period in **years**:

| `recurring` | Count | Meaning |
|---|---|---|
| 1 | 987 | every season |
| 2 | 5 | every 2 seasons (Africa Cup of Nations + its qualifier) |
| 4 | 35 | every 4 seasons (World Cup, Euros, Copa América and all their qualifiers) |

`startyear` is the **phase** within the cycle. The competition is active when
`gameYear MOD recurring == startyear MOD recurring`.

Verified against the venue files: World Cup finals `startyear=4, recurring=4` → active in game years
4, 8, 12, 16, 20 - *exactly* the five years listed in `venuesWC.txt`. Euro finals
`startyear=2, recurring=4` → 2, 6, 10, 14, 18 - *exactly* `venuesEuros.txt`. This pins the semantics.

The full `startyear × recurring` distribution:

| | `rec=1` | `rec=2` | `rec=4` |
|---|---|---|---|
| `sy=0` | 1 | - | - |
| `sy=1` | 987 | 5 | 6 |
| `sy=2` | - | - | 12 |
| `sy=3` | - | - | 7 |
| `sy=4` | - | - | 10 |

`sy=0` occurs once (10411 Copa Libertadores Best Placed, `recurring=1`) and is equivalent to `sy=1`
under a mod-1 test. Every annual competition has `sy=1`.

The phases inside the 4-year World Cup cycle are meaningful:

| Phase | What runs |
|---|---|
| `sy=1` | World Cup Pool created; Euro qualifiers begin (270, weeks 7-93); Euro Pool created |
| `sy=2` | Euro finals; AFC WCQ Stage 1; CAF WCQ 1; CONCACAF WCQ 1&2; CSF WCQ begins |
| `sy=3` | Copa América; AFC WCQ Stage 2; CONCACAF WCQ 3; UEFA WCQ begins (weeks 9-95) |
| `sy=4` | **World Cup finals**; CAF WCQ 2 + 3rd round; both inter-confederation play-offs |

### 3.6 `startweek` and `duration` - the season calendar

The season is **52 weeks**. `startweek` is 1-based; `startweek = 0` appears in 8 rows and marks
unscheduled/disabled competitions.

`duration` is the span in **weeks**, not matchdays. Proof:

* Championship (2280): 24 teams, `rounds=2` → 46 matchdays, but `duration=39`. 46 matchdays cannot be
  39 matchdays; they fit 39 weeks only if 7 weeks carry a midweek round - which is exactly what
  `secondarymatchday=3` (Wednesday) provides. This is the real Championship schedule.
* CSF World Cup Qualifiers (220): 10 nations, `rounds=2` → 18 matchdays, `duration=104` = **two years**.
  The CONMEBOL group genuinely spans two calendar years.
* UEFA WCQ (290) and Euro qualifiers (270): `duration=86` weeks ≈ 1.65 seasons.
* KO rounds: `duration=1` = a single week.

A competition occupies weeks `startweek … startweek + duration - 1`.
Only 9 competitions have `startweek + duration > 52` (all the multi-year international ones, plus one
data quirk: 5210 Primera División `sw=8 dur=46` → week 54).

Week-of-year mapping (inferred from `startweek` distribution and real-world schedules): **week 1 ≈ early
August**, week 52 ≈ late July. World Cup finals sit at weeks 48-52; European league seasons start at
weeks 4-7; European finals at weeks 42-46.

**UNCERTAIN:** whether `duration` is inclusive as stated (`sw … sw+dur-1`) or exclusive
(`sw … sw+dur`). The KO case (`dur=1`, one week) supports inclusive.

### 3.7 `primarymatchday` / `secondarymatchday`

Day-of-week slots, `1 = Monday … 7 = Sunday`, `99 = none`.

| Rule | Evidence |
|---|---|
| `primarymatchday = 99` ⟺ the competition plays no fixtures | exactly 21 rows, and exactly the 21 rows with `comptype ∈ {2,3,5}` (5+2+14) |
| `secondarymatchday = 99` and `primary ≠ 99` ⟹ one fixture slot per week | 13 rows, all international tournament stages (WC/Euro/ACN/OFC) |
| `secondarymatchday = primarymatchday` ⟹ effectively one slot per week | 667 rows (222 × `3/3`, 189 × `6/6`, 175 × `1/1`, …) |
| `secondarymatchday ≠ primarymatchday`, neither 99 ⟹ two slots per week | 327 rows; most notably `6/3` (Sat + Wed), 166 rows |

Most common pairs: `3/3` (222), `6/6` (189), `1/1` (175), `6/3` (166), `3/6` (57), `4/4` (37).

**Slot budget check.** With `slots = duration × (2 if md2 ∉ {md1, 99} else 1)`, only **10 of 356**
league-type competitions require more matchdays than slots. Of those, 4 are `duration=0` dead rows,
and the rest are tournament group stages that pack 3 matchdays into a 2-week window (World Cup Stage 1,
ACN Group Stage, Euro Group Stage, OFC WCQ Stage 2). The engine therefore must be able to **compress**
matchdays into a week beyond the two nominal slots for short tournaments. Note also that the World Cup
Semi Final and Final both carry `startweek=52` - multiple rounds in one week is legal.

### 3.8 `groups` and `rounds`

`groups` > 1 only occurs with `comptype=0`. Distribution:

| `groups` | 1 | 2 | 3 | 4 | 6 | 8 | 10 | 12 | 20 |
|---|---|---|---|---|---|---|---|---|---|
| Count | 1006 | 3 | 1 | 5 | 1 | 8 | 1 | 2 | 1 |

**Critical rule (validated by every bracket in the file):** a promotion edge `place = P` from a
competition with `groups = G` yields **G teams** - the P-th placed team of *each* group.

Example: `350 Champions League Group Stage` has `groups=8` and emits `place 1 → 470` and
`place 2 → 470`. That is 2 × 8 = 16 teams, exactly filling the Round of 16.

`rounds` distribution by type:

| | `rounds=0` | `1` | `2` | `3` | `4` |
|---|---|---|---|---|---|
| League (0) | 100 | 9 | 170 | 32 | 28 |
| KO (1) | - | 651 | - | - | - |
| BestPlaced/Pool/RegionalSort | 21 | - | - | - | - |
| LeagueCont (4) | 2 | 10 | 5 | - | - |

`rounds = 3` and `4` are real: small European leagues that play each opponent three or four times
(Scottish Premier League `rounds=3`, Scottish First/Second/Third Division `rounds=4`,
Austrian Bundesliga `rounds=4`).

### 3.9 `legs` - tie format (KO only)

Occurs non-zero **only** for `comptype=1`. Maps to the binary's tie-format labels:

| `legs` | Label | Count | Meaning |
|---|---|---|---|
| 0 | `ET/P` | 432 (KO) | Single match; if drawn → extra time → penalties |
| 1 | `R/ET/P` | 18 | Single match; if drawn → **replay**; if replay drawn → ET → penalties |
| 2 | `2L/ET/P` | 201 | Two legs on aggregate; if level → ET → penalties |

`legs = 1` is used by **exactly 18 competitions, and only in England and Scotland** - the FA Cup
rounds 3Q, 4Q, 1, 2, 3, 4, 5 and QF; the FA Trophy 3Q, 1, 2, 3 and QF; and Scottish Cup rounds 1-4
and QF. This is precisely where replays exist in real football, and it is why the binary contains
`CreateReplayFixture:`. Note the FA Cup **Semifinal and Final** use `legs=0` (no replay), which is
also correct.

`legs = 0` on 339 League rows is simply "not applicable".

### 3.10 `townregion`

| Value | Label (from exe) | Count |
|---|---|---|
| 0 | None | 998 |
| 1 | North | 13 |
| 2 | East | 6 |
| 3 | South | 7 |
| 4 | West | 4 |
| 5 | Combn (Combined) | 0 - declared but unused |

Two distinct uses:

1. **On a League (`comptype=0`)** it tags which region that division covers. They come in pairs:
   `Svenska Division 1 North`(1) / `South`(3); `National North`(1) / `National South`(3);
   `Serie C Group A`(1) / `Group B`(3); `2. Division East`(2) / `West`(4);
   `Liga II`(2) / `Liga II Seria II`(4); `Cymru Alliance`(1) / `First Division`(3);
   `Prva liga Federacije BiH`(1) / `Prva liga Republike Srpske`(3).
   So **1↔3 is the North/South axis and 2↔4 the East/West axis.**

2. **On a RegionalSort (`comptype=5`)** it selects the **sort axis**: values 1/3 → sort by latitude
   (north → south), values 2/4 → sort by longitude. The one exception is 1530 `B PFG Pool East/West`
   which carries `townregion=0` despite its name - a data bug (it is also completely unwired).

### 3.11 `compstatus` - pyramid tier

| Value | Count | Meaning |
|---|---|---|
| 0 | 601 | No tier - cups, qualifiers, play-offs, pools, sorts |
| 1 | 216 | Tier 1 (top domestic division; also the premier international/continental tournaments) |
| 2 | 100 | Tier 2 |
| 3 | 84 | Tier 3 |
| 4 | 19 | Tier 4 |
| 5 | 4 | Tier 5 |
| 6 | 2 | Tier 6 |
| 70 | 2 | **Data bug** - see below |

The English pyramid proves it exactly:

| id | Name | `compstatus` |
|---|---|---|
| 2270 | Premiership | 1 |
| 2280 | Championship | 2 |
| 2290 | League One | 3 |
| 2300 | League Two | 4 |
| 2310 | National National | 5 |
| 2320 / 2330 | National North / National South | 6 / 6 |

It doubles as a prestige tier for non-domestic competitions: Champions League rounds carry
`compstatus=1`, Europa League rounds `compstatus=3`, Copa Sudamericana `compstatus=2`.
World Cup / Euro / ACN / Copa América **finals** stages carry `compstatus=1` while their
**qualifiers** carry `compstatus=0`.

`compstatus = 70` appears on exactly two rows - `7450 Ukraine Cup Quarter Final` and
`9590 Nigerian FA Cup Quarterfinals`. Both are cup quarter-finals, whose siblings all carry 0.
Treat as a typo for `0` but **reproduce the literal value 70** for byte-fidelity.

### 3.12 `minstrength` / `maxstrength`

Two different uses depending on shape, both on a 0-99 scale that matches `Clubs.csv.strength`.

**A. League / LeagueCont → a band.** 208 of 212 non-zero League rows have `min < max`. The band
describes the expected club-strength range of that division and forms a descending ladder per nation:

| id | England | `min` | `max` |
|---|---|---|---|
| 2270 | Premiership | 75 | 99 |
| 2280 | Championship | 55 | 80 |
| 2290 | League One | 40 | 60 |
| 2300 | League Two | 30 | 45 |
| 2310 | National National | 20 | 35 |
| 2320/2330 | National North / South | 16 | 24 |

Bands overlap deliberately. Italy: Serie A 75-97, Serie B 54-78, Serie C 30-55.
Spain: La Liga 75-99, Segunda 56-80, Segunda B 30-64.

The declared band is **not** a hard filter on the shipped clubs - only 24 of 201 seeded leagues have
every member inside the declared band (e.g. Serie A declares 75-97 but ships clubs from 30 to 81).
It is therefore a *target* band, not a constraint.

**UNCERTAIN:** the precise runtime use. The most likely purposes are (i) drifting a club's strength
toward its division's band after promotion/relegation, (ii) generating filler clubs when
`Test_UpdateNoofTeamsInLeagues` finds a league short, and (iii) rating the division for the player's
career progression. The data alone cannot separate these.

**B. KO / continental → a single prestige value.** 125 of 138 non-zero KO rows have `min == max`,
and the value **escalates monotonically with round depth**:

| FA Cup round | value | | Champions League round | value |
|---|---|---|---|---|
| 1Q-1R | 0 | | Prelim / 1st Q | 0 |
| 2nd Round | 15 | | 2nd Qualifying | 40 |
| 3rd Round | 30 | | 3rd Qualifying | 50 |
| 4th Round | 45 | | Play-off Round | 60 |
| 5th Round | 60 | | Group Stage | 70 |
| Quarterfinal | 70 | | Round of 16 | 75 |
| Semifinal | 75 | | Quarterfinal | 80-82 |
| **Final** | **90** | | Semifinal | 85 |
| League Cup Final | 80 | | **Final** | **95** |

Europa League mirrors it one step lower (Group 45, R32 50, R16 60, QF 65, SF 70, Final 85).

**UNCERTAIN:** whether this drives player reputation gain, news importance, crowd size, or opponent
quality. It is clearly a "how big is this match" scalar.

---

## 4. `PromotionPlaces.csv` - format

Header, verbatim:

```
parentid	place	promotiontoid
```

| Column | Meaning |
|---|---|
| `parentid` | competition the team is coming **from** (`Competitions.csv.id`) |
| `place` | which team(s), by finishing position or special code |
| `promotiontoid` | competition the team goes **to** (`Competitions.csv.id`) |

Facts:

* 2,067 edges, 938 distinct sources, 819 distinct targets.
* **Zero dangling references** in either direction - the graph is closed.
* Rows are grouped by `parentid` in ascending id order and by `place` ascending within a group.
* A `(parentid, place)` pair **may repeat** - one finishing position can be routed to several
  competitions (see §5.3). Example: `2280 Championship` has `place 100` twice, to the League Cup and
  to the FA Cup.

Verbatim sample (English Premiership, id 2270) - this single block exercises almost every feature:

```
2270	1	350
2270	2	350
2270	3	350
2270	4	350
2270	5	360
2270	18	2280
2270	19	2280
2270	20	2280
2270	100	2450
2270	101	2370
2270	107	2390
```

Reading: places 1-4 → Champions League group stage; place 5 → Europa League group stage;
places 18-20 → relegated to the Championship; **all** 20 clubs → FA Cup 3rd Round;
code 101 → League Cup 2nd Round; code 107 → League Cup 3rd Round.

---

## 5. The `place` field - full semantics

### 5.1 Literal places (1 … 32)

`place ∈ [1, 32]` means "the team finishing in position `place`". The engine validates this against
the parent's team count (`WARNING! Promotion place exceeds number of teams in competition:`).

Frequency: place 1 (266), 2 (226), 3 (159), 4 (91), 5 (61), 6 (49), 7 (33), 8 (28), 9 (22), 10 (26),
11 (19), 12 (22), 13 (9), 14 (11), 15 (16), 16 (26), 17 (14), 18 (20), 19 (10), 20 (10), 21 (6),
22 (7), 23 (7), 24 (7), 25-32 (1 each - the World Cup Pool tail).

**Multiplied by `groups`.** If the parent has `groups = G`, one literal-place edge yields G teams.

Literal places only ever appear with parent `comptype ∈ {0, 2, 3, 4, 5}` - never with a KO parent
(verified cross-tab: 961 from League, 78 from LeagueCont, 56 from Pool, 42 from RegionalSort,
16 from BestPlaced, **0** from KO).

### 5.2 Special codes (≥ 100)

Codes 100 and above are out-of-range sentinels. The cross-tab of code against parent shape is
perfectly clean:

| Code | Count | Only ever with parent `comptype` | Reading |
|---|---|---|---|
| **100** | 248 | 0 (League) ×245, 4 (LeagueCont) ×3 | **ALL teams** in the competition |
| **101** | 1 | 0 (League) | *see §5.6* - ≈13 of the 20 Premiership clubs |
| **103** | 536 | 1 (KO) | **Winner** of each tie |
| **104** | 60 | 1 (KO) | **Loser** of each tie |
| **105** | 1 | 1 (KO) | winner of a league final → continental (single use) |
| **106** | 66 | 1 (KO) | **Cup winner → continental qualification** |
| **107** | 1 | 0 (League) | *see §5.6* - ≈7 of the 20 Premiership clubs |
| **108** | 1 | 1 (KO) | runner-up → continental (single use, paired with 106) |

Note `102` is **never used**.

### 5.3 Code 100 = ALL TEAMS - proved by arithmetic

The FA Cup closes exactly only under this reading:

| Round | Entrants | Source |
|---|---|---|
| FA Cup Qualifying Round 3 (2380) | **80** | National North 22 + National South 22 + Non-League ENG 36, all via `place 100` |
| FA Cup Qualifying Round 4 (2400) | **64** | 40 winners + National National 24 (`place 100`) |
| FA Cup 1st Round (2420) | **80** | 32 winners + League One 24 + League Two 24 (`place 100`) |
| FA Cup 2nd Round (2430) | **40** | 40 winners |
| FA Cup 3rd Round (2450) | **64** | 20 winners + Premiership 20 + Championship 24 (`place 100`) |
| FA Cup 4th Round (2470) | **32** | |
| FA Cup 5th Round (2480) | **16** | |
| Quarterfinal (2500) | **8** | |
| Semifinal (2510) | **4** | |
| **Final (2560)** | **2** | |

Every single round is a clean power-of-two-compatible number. The FA Trophy chain
(80 → 64 → 32 → 16 → 8 → 4 → 2) closes identically.

### 5.4 Codes 103 / 104 = winner / loser

Universal for KO progression. Both the domestic and the continental chains close exactly under
`winners = ceil(n/2)`, `losers = floor(n/2)`:

Champions League / Europa League (all verified):

| Competition | Entrants |
|---|---|
| CL Preliminary R1 / R2 | 4 / 2 |
| CL 1st Q / 2nd Q / 2nd Q (NC) | 32 / 20 / 4 |
| CL 3rd Q (C) / (NC) | 12 / 8 |
| CL Play-off (C) / (NC) | 8 / 4 |
| **CL Group Stage** | **32** (8 groups × 4) |
| CL R16 / QF / SF / Final | 16 / 8 / 4 / 2 |
| EL Preliminary / 1st Q | 14 / 94 |
| EL 2nd Q (NC) / (C) | 74 / 18 |
| EL 3rd Q (NC) / (C) | 52 / 20 |
| EL Play-off (NC) / (C) | 26 / 16 |
| **EL Group Stage** | **48** (12 groups × 4) |
| EL R32 / R16 / QF / SF / Final | 32 / 16 / 8 / 4 / 2 |

Every one of those is even. The `(C)` / `(NC)` suffixes mean **Champions route** / **Non-Champions
route** - UEFA's real split path, modelled as separate competition records.

`104` covers two situations that look different but are the same operation - put the loser into
competition X:

* Same-season side-step: `420 CL 3rd Qualifying Round (NC)` loser `→ 360 Europa League Group Stage`.
* Next-season drop: `2520 Championship Play-Off Semi-Final` loser `→ 2280 Championship`.

The engine therefore does **not** encode timing in the code; it simply adds the team to the target's
team pool, and the target runs at its next scheduled occurrence. (Confirmed: 60 of 536 `103` edges also
point "backwards" in the calendar, e.g. `2570 Championship Play-Off Final (week 46) → 2270 Premiership
(week 6)`.)

### 5.5 Code 106 (and 105 / 108) - continental qualification

All 66 `106` edges share three properties, without exception:

* the parent is a **KO Final**;
* the target has `locale = 1` (continental);
* the target's `startweek` is **earlier** than the parent's (i.e. it wraps to next season).

Examples: `2560 FA Cup Final → 360 Europa League Group Stage`;
`2490 League Cup Final → 400 Europa League 2nd Qualifying Round (NC)`;
`1490 Copa do Brasil Final → 7810 Copa Libertadores Group Stage`;
`945 A-League Grand Final → 8121 AFC Champions League Group East`.

No competition ever carries both a `103` and a `106` edge.

**Why a separate code from 103?** The San Marino block is the best evidence:

```
6110 Coppa Titano Final        place 106 -> 375 Europa League Preliminary Round   (cup winner)
10156 San Marino Championship  place 103 -> 365 Champions League Preliminary R1   (league champion)
10156 San Marino Championship  place 104 -> 375 Europa League Preliminary Round   (league runner-up)
```

The **league** title path uses 103/104; the **cup** path uses 106. **UNCERTAIN:** the most plausible
engine difference is that `106` implements the real-football rule *"if the cup winner has already
qualified via league position, the place passes to the next eligible team"*, whereas `103` does not.
This cannot be confirmed from data alone, but a reconstruction that ignores it will occasionally
double-enter a club.

`105` (one use): `4090 Jamaican Premier League Final place 105 → 8000 CFU Club Cup`. Contributes one
team; behaves as a winner edge.

`108` (one use): `7580 MLS Cup` emits **both** `106 → 7910 CONCACAF Champions League Round of 16` **and**
`108 → 7910`. Since two different codes feed the same target from a two-team final, they must be
winner and runner-up. Given `106` = winner, **`108` = runner-up**. (Verified: CONCACAF CL Round of 16
totals exactly 16 with `106`+`108` contributing 2.)

### 5.6 Codes 101 and 107 - the English League Cup pair

These two codes appear **once each, both on competition 2270 (Premiership)**, and they are
structurally load-bearing. The League Cup chain:

| Round | Entrants | Composition |
|---|---|---|
| 2360 League Cup 1st Round | **72** | Championship 24 + League One 24 + League Two 24, via `place 100` |
| 2370 League Cup 2nd Round | **36 + [101]** | 36 R1 winners + Premiership code 101 |
| 2390 League Cup 3rd Round | **ceil(2370/2) + [107]** | R2 winners + Premiership code 107 |
| 2410 League Cup 4th Round | 16 | |
| 2440 Quarterfinal | 8 | |
| 2460 Semi-Final | 4 (`legs=2`) | |
| 2490 Final | 2 | |

For the bracket to close at 32 in Round 3 and `[101] + [107] = 20` (the Premiership's size), only two
solutions exist:

* `[101] = 13`, `[107] = 7` → R2 = 49 → 25 through (24 ties + **one bye**) → +7 = **32** ✔
* `[101] = 12`, `[107] = 8` → R2 = 48 → 24 through → +8 = **32** ✔

The real English League Cup of the era had exactly **13** Premier League clubs entering at Round 2 and
**7** (those in European competition) entering at Round 3, with a 50-team Round 2. The 13/7 split is
therefore almost certainly intended.

**UNCERTAIN - best reading:** `101` = *all teams of this competition that are NOT entered in a
continental competition*; `107` = *all teams of this competition that ARE entered in a continental
competition*. They form a complementary partition of the league. A reconstruction must implement
something equivalent; a literal hard-coded 13/7 split would reproduce the shipped data but break if
the number of English European places changes.

### 5.7 Multiple edges per place

A single `(parentid, place)` may fire several times. Scottish Premier League 1 (the post-split
championship group) is the clearest case:

```
6230	1	6180      <- 1st place plays in the SPL again next season
6230	1	370       <- 1st place also enters CL 1st Qualifying Round
6230	2	6180
6230	2	380       <- 2nd place also enters EL 1st Qualifying Round
6230	3	6180
6230	3	380
6230	4	6180
6230	5	6180
6230	6	6180
```

Note that **every** place in a LeagueCont group emits an edge back to the parent league. That is how
the engine knows the composition of next season's league: the split groups, not the parent, hold the
final standings.

---

## 6. How a competition is populated

Three mutually exclusive sources, in order of evidence:

1. **`Clubs.csv.leagueid`** - the initial season's league membership. 299 distinct values; 5,436 clubs.
   These counts are the *steady-state* size of each league (promotion and relegation are balanced).
2. **`Clubs.csv.continentalcompid`** - the initial season's continental entrants, so the first season
   does not need a season of qualifying to have happened. Non-zero for 30 competitions, e.g.
   350 (26 clubs), 380 (87), 400 (27), 9500 (44), 7810 (28).
   Also relevant: `Clubs.csv.bteamof` (163 clubs) marks reserve/B teams.
3. **`PromotionPlaces` inbound edges** - everything else.

**International (national-team) competitions have neither seeds nor inbound edges.** Exactly ten
`level=1` competitions have no inbound edge; one of them (140 CAF WCQ Best Runners-Up, `comptype=2`)
is dead data, leaving these nine League-type entry points that must be filled from `Nations.csv`:

| id | Competition | `based` | `groups` | Nations available |
|---|---|---|---|---|
| 90 | AFC World Cup Qualifiers Stage 1 | 1 (Asia) | 8 | 46 |
| 120 | CAF World Cup Qualifiers 1 | 2 (Africa) | 20 | 53 |
| 190 | CONCACAF World Cup Qualifier Stage 1 | 3 | 12 | 36 |
| 220 | CSF World Cup Qualifiers | 4 | 1 | 10 |
| 230 | Copa America Group Stage | 4 | 2 | 10 |
| 250 | OFC World Cup Qualifier Stage 1 | 5 | 2 | 11 |
| 270 | UEFA European Championship Qualifiers | 6 | 8 | 55 |
| 290 | UEFA World Cup Qualifiers | 6 | 8 | 55 |
| 10158 | African Cup of Nations Qualifier | 2 | 8 | 53 |

These are populated from `Nations.csv` filtered by `continent == based` (all of them carry
`minstrength = maxstrength = 0`, i.e. no strength filter) and distributed across `groups` groups.
`CreateTeamPool:` / `PopulateTeamPool:` are the relevant runtime labels.

**UNCERTAIN:** the seeding rule for the draw. `Nations.csv` provides a `strength` column and
`Continents.csv` a per-federation `strength`, so a pot-based seeding by nation strength is the
obvious implementation, but nothing in the data proves it.

---

## 7. Fixture generation

Two generators exist in the binary.

### 7.1 `CreateFixtureListLeague:` - `comptype` 0 and 4

Round-robin over `teamsPerGroup` teams, repeated `rounds` times, for each of `groups` groups.
Matchdays laid out across weeks `startweek … startweek+duration-1` using `primarymatchday` and, when
needed, `secondarymatchday`.

### 7.2 `CreateFixtureListKO:` - `comptype` 1

Pairs entrants into ties. `legs` decides the format (§3.9). Everything is scheduled within the
`duration` window (almost always 1 week).

### 7.3 Virtual types - no fixtures

`comptype` 2, 3 and 5 generate nothing. All 21 such rows carry
`duration=0, rounds=0, groups=1, primarymatchday=99, secondarymatchday=99`.

### 7.4 Byes are mandatory

The data contains knockout rounds with odd entrant counts that propagate all the way to a "Final"
with three teams. These are not bugs the reconstruction can ignore - they are reachable states:

| Competition chain | Entrants |
|---|---|
| 890 Independence Cup 1st Round → 900 QF → 910 SF → 920 Final | 17 → 9 → 5 → **3** |
| 935 Australian FFA Cup R1 → 936 QF → 937 SF → 938 Final | 17 → 9 → 5 → **3** |
| 4620 Malaysia Cup R1 → 4630 → 4640 → 4650 → 4660 Final | 33 → 17 → 9 → 5 → **3** |
| 862 Copa Argentina R4 → 863 R32 → 864 R16 | 57 → 29 → 15 |
| 2370 League Cup 2nd Round | 49 (one bye → 25 through) |

`fixture_Bye` exists in the binary for exactly this reason. 23 competitions have an odd entrant count
greater than 1.

---

## 8. Worked examples

### 8.1 The World Cup chain - 32 slots, exactly

`10 (Pool) → 20 (Stage 1) → 30 (Stage 2) → 40 (QF) → 50 (SF) → 60 (Final)`

**Feeding the pool.** Competition 10 (`comptype=3`, Pool) has capacity 32 and emits `place 1..32 → 20`.
Its inbound edges:

| Source | Edge | Teams | Note |
|---|---|---|---|
| 100 AFC WCQ Stage 2 | places 1, 2 | 2 × 2 groups = **4** | Asia |
| 135 CAF WCQ Third Round | place 103 (winner) | **5** | 10 entrants → 5 two-legged ties |
| 210 CONCACAF WCQ Stage 3 | places 1, 2, 3 | **3** | 1 group of 6 |
| 220 CSF WCQ | places 1, 2, 3, 4 | **4** | 1 group of 10 |
| 290 UEFA WCQ | place 1 | 1 × 8 groups = **8** | Europe |
| 330 UEFA WCQ Best Placed Runner Up | places 1-6 | **6** | ranks the 8 group runners-up |
| 70 CBL/OFC WCQ Play-Off | place 103 | **1** | CONMEBOL 5th v OFC winner |
| 80 CONCACAF/AFC WCQ Play-Off | place 103 | **1** | CONCACAF 4th v AFC 3rd-place-game winner |
| | | **32** | ✔ |

The host nation is **not** auto-qualified in this model - all 32 slots are consumed by qualification.

**Per-confederation detail:**

* **AFC:** 90 Stage 1 (8 groups, `rounds=2`, weeks 28-74 of year 2) → place 1 ×8 = 8 to Stage 2;
  place 2 ×8 = 8 to 95 BestPlaced, which emits places 1-4 = 4 to Stage 2. Stage 2 = **12** teams in
  **2 groups of 6** (`rounds=2`, year 3, weeks 31-64). Places 1,2 ×2 = 4 → Pool; place 3 ×2 = 2 →
  110 Third Place Game (`legs=2`) → winner → 80.
* **CAF:** 120 WCQ 1 (**20 groups**, `rounds=1`, year 2 weeks 7-21) → places 1,2 ×20 = 40 to
  130 WCQ 2 (**10 groups of 4**, `rounds=2`, year 4 weeks 7-40) → place 1 ×10 = 10 to
  135 Third Round (`legs=2`) → **5 winners** → Pool.
* **CONCACAF:** 190 Stage 1 (12 groups) → place 1 ×12 = 12 → 200 Stage 2 (3 groups of 4) →
  places 1,2 ×3 = 6 → 210 Stage 3 (1 group of 6, `rounds=2`) → places 1,2,3 → Pool, place 4 → 80.
* **CONMEBOL:** 220 (1 group of 10, `rounds=2`, `duration=104` weeks) → places 1-4 → Pool,
  place 5 → 70.
* **OFC:** 250 Stage 1 (2 groups) → places 1,2 ×2 = 4 → 260 Stage 2 (1 group of 4, `rounds=2`) →
  place 1 → 70.
* **UEFA:** 290 (8 groups, `rounds=2`, `duration=86` weeks starting year 3 week 9) → place 1 ×8 = 8 →
  Pool; place 2 ×8 = 8 → 330 BestPlaced → best 6 → Pool.

**Finals.** 20 Stage 1: 32 teams, `groups=8` (4 per group), `rounds=1` → 3 matchdays,
weeks 48-49, `md1=6` (Saturday), `md2=99`. Places 1,2 ×8 = **16** → 30 Stage 2 (Round of 16, `legs=0`,
week 50) → 8 → 40 QF (week 51) → 4 → 50 SF (week 52) → 2 → 60 Final (week 52).

All six finals rows carry `startyear=4, recurring=4, compstatus=1, based=169`.

### 8.2 The European Championship chain

`270 (Qualifiers) → 340 (Pool) → 280 (Group Stage) → 285 (Best 3rd) → 295 (R16) → 300 → 310 → 320`

* 270 EUROQ: 8 groups, `rounds=2`, `startyear=1`, weeks 7-92 (`duration=86`).
  Emits places 1, 2, 3 → 24 teams into 340 Euro Pool.
* 340 Pool: emits places 1-24 → 280.
* 280 Group Stage: **24** teams, `groups=6` (4 each), `rounds=1`, `startyear=2`, weeks 47-48.
  Emits places 1,2 ×6 = 12 → 295 R16; place 3 ×6 = 6 → 285 BestPlaced.
* 285 Best 3rd Place: emits places 1-4 = 4 → 295.
* 295 Round of 16 = 12 + 4 = **16** ✔ → 300 QF (8) → 310 SF (4) → 320 Final (2).

This is the 24-team Euro 2016 format, shipped in a 2012 game.

### 8.3 The English pyramid - a complete domestic system

Divisions (all `comptype=0`, `rounds=2`, `md1=6` Sat / `md2=3` Wed):

| id | Name | Tier | Teams | `sw` | `dur` | Matchdays |
|---|---|---|---|---|---|---|
| 2270 | Premiership | 1 | 20 | 6 | 38 | 38 |
| 2280 | Championship | 2 | 24 | 5 | 39 | 46 |
| 2290 | League One | 3 | 24 | 5 | 39 | 46 |
| 2300 | League Two | 4 | 24 | 5 | 39 | 46 |
| 2310 | National National | 5 | 24 | 5 | 39 | 46 |
| 2320 | National North | 6 | 22 | 5 | 39 | 42 |
| 2330 | National South | 6 | 22 | 5 | 39 | 42 |
| 2350 | Non-League ENG | - | 36 | 5 | 0 | 0 (holding pen) |

Promotion / relegation:

* Premiership 18,19,20 ↓ Championship. Championship 1,2 ↑ Premiership; 3,4,5,6 → 2520 Play-Off
  Semi-Final (`legs=2`) → 2570 Final (`legs=0`, week 46) → winner ↑ Premiership, loser stays.
  Championship 22,23,24 ↓ League One.
* League One 1,2 ↑; 3-6 → play-offs; 21-24 ↓ League Two.
* League Two 1,2,3 ↑; 4-7 → play-offs; 23,24 ↓ National National.
* National National 1 ↑; 2,3 → SF; 4-7 → 2549 Qualifiers; 21-24 → **2340 National Pool
  North/South** (a RegionalSort).
* 2340 sorts those four north-to-south and emits `place 1,2 → National North`,
  `place 3,4 → National South`.
* National North / South each: 1 ↑ National National; 2,3 → Semifinal; 4-7 → Qualifying;
  winners of 2601/2602 ↑ National National.

Cups: see §5.3 (FA Cup, FA Trophy) and §5.6 (League Cup).

European qualification out of England: Premiership 1-4 → 350 CL Group Stage; 5 → 360 EL Group Stage;
2560 FA Cup Final `place 106` → 360; 2490 League Cup Final `place 106` → 400 EL 2nd Qualifying (NC).

### 8.4 A League Continuation split - Scotland and Denmark

**Scotland.** 6180 Scottish Premier League: 12 clubs, `rounds=3`, weeks 4-33 → 33 matchdays.
At week 33 it emits places 1-6 → 6230 and places 7-12 → 6240 (both `comptype=4`, 6 teams,
`rounds=1`, weeks 33-40 → 5 matchdays). Season total 38.
6230 then emits **two edges per place**: every place → 6180 (next season) plus place 1 → 370
(CL 1st Qualifying) and places 2,3 → 380 (EL 1st Qualifying).
6240 emits places 1-4 → 6180, place 5 → 10096 Premiership Relegation Playoff, place 6 → 6190
(relegated to the First Division).

**Denmark.** 2060 Danish Superliga: 14 clubs, `rounds=2`, weeks 4-29 → 26 matchdays. Splits three
ways at week 30: places 1-6 → 2065 Championship (`rounds=2`, 10 matchdays); places 7,10,11,14 →
2066 Relegation Group A; places 8,9,12,13 → 2067 Relegation Group B (both 4 teams, `rounds=2`).
The relegation groups feed a four-stage play-off (2068 Semis → 2069 Final → 2071 Relegation Match →
2072/2073 Promotion Playoffs) that decides the last Superliga places against 2070 1. Division.

Note the deliberate **snake seeding** of the two Danish relegation groups (7,10,11,14 vs 8,9,12,13).

### 8.5 RegionalSort in practice

| Sorter | Axis (`townregion`) | In | Out |
|---|---|---|---|
| 7790 Welsh Pool North/South | 1 (N/S) | League of Wales 11, 12 | p1 → Cymru Alliance (North), p2 → First Division (South) |
| 7010 Svenska D1 Pool N/S | 1 (N/S) | Superettan 15, 16 | p1 → Division 1 North, p2 → Division 1 South |
| 2340 National Pool N/S | 1 (N/S) | National National 21-24 | p1,p2 → National North; p3,p4 → National South |
| 1424 Brasileiro 3ª Divisão Regional Sort | 1 | Série B 17-20 | p1,p2 → Grupo A; p3,p4 → Grupo B |
| 10370 3. Lig Relegation Pool (TUR) | 1 | 2. Lig Red 16-18, 2. Lig White 16-18 | p1→G1, p2→G2, p3→G3, p4→G3, p5→G2, p6→G1 (**snake**) |
| 7289 2. Lig Relegation Pool (TUR) | 1 | 1. Lig 16-18 + 2. Lig Promotion Final loser + three 3. Lig champions + three 3. Lig promotion-final winners | p1..p10 alternating Red/White |
| 6851 Segunda B Sort (ESP) | 1 (N/S) | Segunda 19-22 | p1 → Segunda B Group 4; p2,p3,p4 → **6852** (chained) |
| 6852 Segunda B Sort (ESP) | 4 (E/W) | 6851 places 2,3,4 | p1 → Group 3, p2 → Group 2, p3 → Group 1 |

The Spanish case is a **two-stage sort**: latitude first, then longitude on the remainder.

Four RegionalSort rows are completely unwired dead data: 1530 (Bulgaria), 2100 (Denmark),
2715 (North Macedonia), 5500 (Poland). 3930 (Lega Pro Pool N/S) has outbound edges but no inbound.

---

## 9. `venuesWC.txt` / `venuesEuros.txt` / `venuesCopa.txt` / `venuesACoN.txt`

Tiny lookup tables that assign a **host nation** to each edition of the four national-team
tournaments. Referenced by literal path from the exe.

**Format:** `<gameYear>,<nationId>` per line, **comma-separated** (unlike everything else in `Data/`),
CRLF terminated. `nationId` indexes `Nations.csv`. No header, no sentinel.

**Trailing-newline quirk (byte-exact):** `venuesWC.txt` has **no** trailing CRLF (34 bytes, last line
`20,193`); the other three **do** (`venuesEuros.txt` 35, `venuesCopa.txt` 6, `venuesACoN.txt` 27 bytes).
A faithful writer must reproduce this.

### Decoded contents

**`venuesWC.txt`** (34 bytes)

| Game year | Nation id | Nation | Real-world edition |
|---|---|---|---|
| 4 | 28 | Brazil | 2014 ✔ |
| 8 | 156 | Russia | 2018 ✔ |
| 12 | 153 | Qatar | 2022 ✔ |
| 16 | 62 | England | 2026 (pre-decision guess) |
| 20 | 193 | Turkey | 2030 (guess) |

**`venuesEuros.txt`** (35 bytes)

| Game year | Nation id | Nation | Real-world edition |
|---|---|---|---|
| 2 | 150 | Poland | 2012 ✔ (co-hosted with Ukraine) |
| 6 | 71 | France | 2016 ✔ |
| 10 | 95 | Italy | 2020 (guess; actual was pan-European) |
| 14 | 133 | Netherlands | 2024 (guess; actual Germany) |
| 18 | 31 | Bulgaria | 2028 (guess) |

**`venuesCopa.txt`** (6 bytes) - a single line

| Game year | Nation id | Nation |
|---|---|---|
| 6 | 28 | Brazil |

**`venuesACoN.txt`** (27 bytes)

| Game year | Nation id | Nation | Real-world edition |
|---|---|---|---|
| 2 | 72 | Gabon | 2012 ✔ (co-hosted with Equatorial Guinea) |
| 4 | 139 | Nigeria | - |
| 6 | 128 | Morocco | - |
| 8 | 174 | South Africa | - |

### The lookup rule

Cross-referencing against `Competitions.csv`:

| Tournament | `startyear` | `recurring` | Active game years | Venue file years |
|---|---|---|---|---|
| World Cup (20-60) | 4 | 4 | 4, 8, 12, 16, 20 | **4, 8, 12, 16, 20** ✔ exact |
| Euros (280-320) | 2 | 4 | 2, 6, 10, 14, 18 | **2, 6, 10, 14, 18** ✔ exact |
| Copa América (230-241) | 3 | 4 | 3, 7, 11, 15, 19 | 6 ✘ |
| ACN (150-180) | 1 | 2 | 1, 3, 5, 7, 9 … | 2, 4, 6, 8 ✘ |

Two files match exactly, two are systematically offset (ACN by +1, Copa by +3).

**UNCERTAIN - leading hypothesis:** the lookup selects **the first entry whose year is ≥ the current
game year**, falling back to something else when the list is exhausted. This is the only simple rule
consistent with all four files:

* WC year 4 → entry 4 ✔, year 8 → entry 8 ✔ …
* Euro year 2 → entry 2 ✔, year 6 → entry 6 ✔ …
* ACN year 1 → entry 2 (Gabon), year 3 → entry 4, year 5 → entry 6, year 7 → entry 8 - and 2012 in
  Gabon lands correctly for the first playthrough.
* Copa year 3 → entry 6 (Brazil).

Exact-year matching would leave ACN and Copa hostless in every edition, which is unlikely to be the
shipped behaviour. Alternative readings that also fit: the list is consumed **in order** for the
1st, 2nd, 3rd … occurrence, ignoring the year field.

**Fallback:** once the list runs out (ACN from year 11, Copa from year 7, everything from year 21),
the host must be chosen some other way - presumably a random nation of the relevant continent
weighted by strength, or a fixed nation. **UNCERTAIN.**

**What the host is used for:** the tournament stages carry `compstatus = 1` and the venue determines
the stadium(s), climate and crowd for what are otherwise neutral-venue matches. `Nations.csv`
supplies `stadiumname`, `stadiumcapacity`, `stadiumlongitude`, `stadiumlatitude` and `climate` for
each nation - everything a neutral venue needs.

---

## 10. Data anomalies to reproduce verbatim

A faithful reconstruction must reproduce these rather than "fix" them.

| Kind | Detail |
|---|---|
| Dead competitions | **63** competitions resolve to 0 teams, including `1520 (Old) B PFG West`, `1530 B PFG Pool East/West`, `2080 2. Division East`, `2090 2. Division West`, `5870 Liga II Seria II (No longer used)`, `4750/4760 Maltese Championship/Relegation Playoff` |
| Unwired RegionalSorts | 1530, 2100, 2715, 5500 have neither inbound nor outbound edges |
| Half-wired | 3930 Lega Pro Pool N/S has outbound edges but nothing feeds it; 2090 has a `place 100` edge into the Danish Cup but zero teams |
| `compstatus = 70` | 7450 Ukraine Cup Quarter Final, 9590 Nigerian FA Cup Quarterfinals |
| `townregion` mismatch | 1530 named "East/West" but tagged `townregion=0` |
| `based` noise | 20-60 (World Cup) `based=169` = Singapore; 80 (CONCACAF/AFC play-off) `based=5` = Oceania; 1520/1530 `based=0` with `locale=0` |
| Calendar overflow | 5210 Primera División `startweek=8 duration=46` → week 54 in a 52-week season |
| Odd brackets | 23 KO competitions have an odd entrant count > 1; three "Final" rounds resolve to **3** teams (920, 938, 4660) |
| Text typos | `3ã Divisão` (should be `3ª`), `Europa League 3d Qualifying Round`, `Play off per al títol` |
| Duplicates | 23 duplicated `name` values, 15 duplicated `tla` values |
| Id scheme | ids are multiples of 10 with 5-step and unit-step insertions (95, 135, 241, 391, 2065, 6851); 71 ids are ≥ 10000 (later additions). The editor exposes `Inflate IDs` / `Compress IDs` to renumber, hence the gaps. |

---

## 11. Reconstruction checklist

```
LoadCompetitions()
  parse TAB, UTF-8, CRLF, stop at "//", drop trailing empty field
  keep the raw integers; do not normalise 70 -> 0 or 169 -> 0

LoadPromotionPlaces()
  parse (parentid, place, promotiontoid); duplicates on (parentid, place) are legal

ValidatePromotionPlacesAll()
  for each edge with place < 100: assert place <= NoofTeamsInRound(parent)
  emit "WARNING! Promotion place exceeds number of teams in competition: " on failure

SetUpCompetitionsAll(gameYear)
  for each competition C:
    if (gameYear MOD C.recurring) != (C.startyear MOD C.recurring): skip this year
    CreateTeamPool(C)
    PopulateTeamPool(C):
      level==1 and no inbound edges -> all Nations where continent == C.based
      else                          -> Clubs.leagueid / Clubs.continentalcompid seeds (season 1)
                                       plus everything DoPromotionPlaces has deposited
    switch C.comptype:
      0 League        -> CreateFixtureListLeague(C)   groups x rounds round-robin
      1 KO            -> CreateFixtureListKO(C)       legs = ET/P | R/ET/P | 2L/ET/P
      2 BestPlaced    -> no fixtures; rank cross-group, re-emit by place
      3 Pool          -> no fixtures; hold, re-emit by place (draw)
      4 LeagueCont    -> CreateFixtureListLeague(C), carrying the parent's table (UNCERTAIN)
      5 RegionalSort  -> no fixtures; sort by lat (reg 1|3) or lon (reg 2|4), re-emit by place

Scheduling
  weeks C.startweek .. C.startweek + C.duration - 1
  day slots: primarymatchday, then secondarymatchday when != primary and != 99
  compress extra matchdays into a week when matchdays > slots (tournament group stages)

IsComplete(C) -> DoPromotionPlaces(C)
  for each edge (C, place, target):
    place  1..32 -> the place-th team of EACH of C.groups groups
    place    100 -> every team in C
    place    101 -> teams of C not entered in a continental competition   (UNCERTAIN)
    place    103 -> winner of each tie
    place    104 -> loser of each tie
    place    105 -> winner (single use)                                    (UNCERTAIN)
    place    106 -> cup winner -> continental, with already-qualified fallback (UNCERTAIN)
    place    107 -> teams of C entered in a continental competition        (UNCERTAIN)
    place    108 -> runner-up (single use)                                 (UNCERTAIN)
    append to target's team pool; the target runs at its next scheduled slot
    on failure emit "Could not promote to competition! Comp: "
```

---

## 12. Open questions (all marked UNCERTAIN above, collected)

1. Exact semantics of place codes **101 / 107** (the 13/7 vs 12/8 English League Cup split).
2. Exact semantics of **105** and **108** (one use each).
3. What distinguishes **106** from **103** in the engine (the "already qualified" fallback hypothesis).
4. Whether **LeagueCont** carries points over in full, halved, or not at all.
5. The tie-break used by **BestPlaced** to rank teams from different groups.
6. Whether `startweek` / `duration` / `startyear` / `recurring` are read at all for the virtual types
   (2, 3, 5).
7. The venue-file lookup rule (`year >= current` vs ordinal consumption) and the fallback host once
   a list is exhausted.
8. The meaning of `based = 169` on the World Cup finals rows.
9. Whether `duration` is inclusive (`sw … sw+dur-1`) or exclusive.
10. The seeding / pot rule for international draws and for group-stage draws generally.
11. The precise runtime role of `minstrength` / `maxstrength` (club-strength drift, filler-club
    generation, match-importance scalar - or all three).
12. How the engine compresses matchdays when a group stage has more matchdays than week slots.
