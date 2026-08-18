# The .tac formation file format

> **Source:** `TFormation.LoadTactics` @ 0x004d8783 (VERIFIED) · `TFormation.New` @ 0x004D7EF2 (VERIFIED) · `TFormation.GetRow` @ 0x004d8aba (VERIFIED) · `TFormation.GetCol` @ 0x004d8aa4 (VERIFIED) · `TFormation.UpdateLabels` @ 0x004d83cc (VERIFIED) · `TFormation.GetPosFromSelectionNo` @ 0x004d96d7 (VERIFIED) · `TFormation.GetSideFromSelectionNo` @ 0x004d975c (VERIFIED) · `TFormation.GetSelectionNoFromSeg` @ 0x004d8a4f (VERIFIED) · `TFormation.GetRowFromSelectionNo` @ 0x004d8af3 (VERIFIED) · `TFormation.GetColFromSelectionNo` @ 0x004d8b3c (VERIFIED) · `TFormation.GetStringTacticName` @ 0x004D9856 (VERIFIED) · `TFormation.GetTacticIdByName` @ 0x004D9911 (VERIFIED) · `TFormation.PickRandomFormation` @ 0x004d9c6f (VERIFIED) · `TFormation.Create` @ 0x004d8397 (VERIFIED) · `TFormation.SaveTactics` @ 0x004D8948 (VERIFIED) · `TScreen_Formation.ButtonFormation` @ 0x0054BCA1 (VERIFIED) · `TFormation.GetPlayerXY` @ 0x004D8B85 (READ) · the 13 shipped `.tac` files under `EngineMedia/Tactics/` (OBSERVED)
> **Confidence:** HIGH
> **Last checked:** 2026-08-15

Every formation used in the game - your own team's and every AI team's - is stored on disk as
one of these tiny text files. Thirteen ship in `EngineMedia/Tactics/`, one per named formation
(plus two extra files that, as far as the recovered code shows, the game never actually loads - 
see the callout below). There is no coordinate data in the file at all. It is a flat list of
**35 lines, each a single digit, `0` or `1`**, and everything else - how many defenders, where
the wide players sit, what a button in the tactics screen is labelled - is worked out by the
engine at load time purely by counting and dividing that one array of flags.

## What the format is, in football terms

The 35 flags are a **5-row-by-7-column grid** laid over the outfield half of the team's shape:
5 horizontal "lines" (defence, defensive mid, midfield, attacking mid, attack) of 7 possible
slots each. A `1` means "there is a player standing in this slot"; a `0` means the slot is
empty. `TFormation.LoadTactics` reads the file top to bottom and stores each digit straight into
`m_TacPos[i]` (index `i` = line number − 1, so line 1 of the file is grid cell 0, line 35 is
grid cell 34). Nothing in the file says which physical shirt goes where, what a cell's on-pitch
X/Y position is, or even how many players are supposed to be lit up - the grid is just a
yes/no mask, and every downstream question (position label, side, pitch coordinates) is
answered by a separate `TFormation` method that walks that same 35-element array.

**The goalkeeper is not part of the grid.** Formation "selection number" 0 is always the
keeper, hard-coded as a special case everywhere the game numbers formation slots
(`GetPosFromSelectionNo(0)` returns 0 directly, `GetStringLabelFromSelectionNo(0)` returns the
"Goalkeeper" label directly, neither one touches `m_TacPos`). The grid only ever encodes the
**10 outfield players**; every shipped file has exactly 10 flags set to `1`.

## The numbers

### File shape

| Property | Value |
|---|---|
| Lines | 35, one digit per line |
| Values | `0` or `1` only |
| Line terminator | `\r\n` (CRLF) |
| Size of a well-formed file | 105 bytes exactly (35 × 3: digit + CR + LF), no trailing blank line |
| Ones per shipped file | Exactly 10, in all 13 files on disk |

### Turning a line number into a pitch cell

Cell index `i` runs 0-34 (line 1 of the file → `i=0`, line 35 → `i=34`). Two tiny functions
turn that index into grid coordinates:

- **Row** (`TFormation.GetRow`): `row = i div 7`, computed as a `<7 / <14 / <21 / <28` threshold
  cascade rather than a literal division, but equivalent.
- **Column** (`TFormation.GetCol`): `col = i Mod 7`.

Row selects the position **line**, read directly off `TFormation.UpdateLabels`' cascade of
overwrites (each `If i < N` fires in order, so the last one to match wins):

| Row | Cell indices | Line |
|---:|---|---|
| 0 | 0-6 | Defender |
| 1 | 7-13 | Defensive midfielder |
| 2 | 14-20 | Midfielder |
| 3 | 21-27 | Attacking midfielder |
| 4 | 28-34 | Forward |

Row 0 is the team's own defensive third; row 4 is furthest up the pitch, nearest the
opponent's goal.

Column selects the **side**, from the same function's `i Mod 7` cascade:

| Column | Side |
|---:|---|
| 0, 1 | Left |
| 2, 3, 4 | Centre |
| 5, 6 | Right |

The width isn't symmetric in a simple "outer/inner" sense: columns **0 and 6** are the widest
touchline slots (used by fullbacks/wingbacks), columns **1 and 5** sit one step infield (used
for narrower wide players - wing-backs in a back three, or wide attacking mids), and columns
**2, 3, 4** are the three central lanes. `TFormation.GetPlayerXY` (see below) confirms this
isn't just a labelling quirk: it gives columns 0/6 the *smallest* horizontal spread and column 3
the *largest*, i.e. the engine really does treat 0/6 as "hug the touchline" and 2-4 as
"central, spread out."

### Worked example: 4-4-2 A.tac really is a 4-4-2

Raw file (13 read from `EngineMedia/Tactics/4-4-2 A.tac`, digit per line, 35 lines):

```
1,0,1,0,1,0,1, 0,0,0,0,0,0,0, 1,0,1,0,1,0,1, 0,0,0,0,0,0,0, 0,0,1,0,1,0,0
```

Laid out as the 5×7 grid (columns labelled by side):

| | col0 L | col1 L | col2 C | col3 C | col4 C | col5 R | col6 R |
|---|---:|---:|---:|---:|---:|---:|---:|
| **row0 - Defender** | 1 | 0 | 1 | 0 | 1 | 0 | 1 |
| **row1 - Def. mid** | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| **row2 - Midfielder** | 1 | 0 | 1 | 0 | 1 | 0 | 1 |
| **row3 - Att. mid** | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| **row4 - Forward** | 0 | 0 | 1 | 0 | 1 | 0 | 0 |

Count the `1`s per line: **4 defenders** (cols 0, 2, 4, 6 - left back, two centre-backs, right
back), **0 defensive mids**, **4 midfielders** (cols 0, 2, 4, 6 - left mid, two central mids,
right mid), **0 attacking mids**, **2 forwards** (cols 2, 4 - both central). That's
4 + 0 + 4 + 0 + 2 = **10 outfield players**, plus the always-implicit goalkeeper = **11** - a
flat-midfield 4-4-2, exactly as the filename says.

For contrast, `4-4-2 B.tac` encodes the *diamond* variant of the same nominal shape: back four
identical to A's, but line 1 (def. mid) has a single `1` at col 3 (a lone holding mid), line 2
(midfield) has `1`s only at cols 0 and 6 (two wide mids, no central pair), and line 3
(att. mid) has a single `1` at col 3 (a central playmaker) - 4+1+2+1+2 = 10 again, same headline
name, genuinely different shape. The grid format is expressive enough to tell "flat" and
"diamond" 4-4-2 apart even though both compress to the same 4-4-2 label.

### The rest of the shipped set

| File | D | DM | M | AM | F | Shape notes |
|---|---:|---:|---:|---:|---:|---|
| 3-4-3.tac | 3 (cols1,3,5) | 0 | 4 (0,2,4,6) | 0 | 3 (1,3,5) | back three |
| 3-5-2 A.tac | 3 (1,3,5) | 1 (3) | 3 (0,3,6) | 0 | 2 (2,4) | back three, holding mid |
| 3-5-2 B.tac | 3 (1,3,5) | 0 | 5 (0,2,3,4,6) | 0 | 2 (2,4) | back three, flat five |
| 4-1-4-1.tac | 4 (0,2,4,6) | 1 (3) | 4 (0,2,4,6) | 0 | 1 (3) | not reachable - see callout |
| 4-2-2-2.tac | 4 (0,2,4,6) | 0 | 2 (2,4) | 2 (0,6) | 2 (2,4) | narrow midfield pair, wide AMs |
| 4-2-3-1.tac | 4 (0,2,4,6) | 2 (2,4) | 0 | 3 (1,3,5) | 1 (3) | not reachable - see callout |
| 4-2-4.tac | 4 (0,2,4,6) | 0 | 2 (2,4) | 0 | 4 (0,2,4,6) | wide forwards |
| 4-3-3.tac | 4 (0,2,4,6) | 0 | 3 (1,3,5) | 0 | 3 (1,3,5) | narrow mid three |
| 4-4-1-1.tac | 4 (0,2,4,6) | 0 | 4 (0,2,4,6) | 1 (3) | 1 (3) | withdrawn striker |
| 4-4-2 A.tac | 4 (0,2,4,6) | 0 | 4 (0,2,4,6) | 0 | 2 (2,4) | flat |
| 4-4-2 B.tac | 4 (0,2,4,6) | 1 (3) | 2 (0,6) | 1 (3) | 2 (2,4) | diamond |
| 4-5-1.tac | 4 (0,2,4,6) | 0 | 5 (0,2,3,4,6) | 0 | 1 (3) | flat five |
| 5-3-2.tac | 5 (0,2,3,4,6) | 0 | 3 (1,3,5) | 0 | 2 (2,4) | back five |

(Column numbers in parentheses are the `1` positions within that line, read left to right.)
Every one of the 11 *named, reachable* formations totals exactly 10 flags, confirming the grid
convention above across the whole corpus, not just the one worked example.

### Formation IDs

`TFormation.Create(id)` - called from `TTeam.ChangeFormation` - turns a small integer into a
filename via `GetStringTacticName(id)`, then hands that name to `LoadTactics`, which appends
`.tac` and looks it up:

| ID | Name | Shipped file? |
|---:|---|---|
| 1 | 3-4-3 | yes |
| 2 | 3-5-2 A | yes |
| 3 | 3-5-2 B | yes |
| 4 | 4-2-2-2 | yes |
| 5 | 4-2-4 | yes |
| 6 | 4-3-3 | yes |
| 7 | 4-4-1-1 | yes |
| 8 | 4-4-2 A | yes |
| 9 | 4-4-2 B | yes |
| 10 | 4-5-1 | yes |
| 11 | 5-3-2 | yes |
| 12 | Custom 1 | no - player-saved only (see below) |
| 13 | Custom 2 | no - player-saved only |
| 14 | Custom 3 | no - player-saved only |
| - (no ID) | 4-1-4-1, 4-2-3-1 | yes, but unreachable - see callout |

`GetTacticIdByName` is the exact mirror (string → ID, `0` for no match), and
`GetStringTacticName`'s `Select` has no `Default` case - any ID it doesn't recognise (0, or 15+)
falls through to the trailing `Return "4-4-2 A"`, so **"4-4-2 A" is the format's universal
fallback name**, not just LoadTactics' file-not-found fallback (see quirks below).

`TFormation.PickRandomFormation` is `Return Rand(11)`. BlitzMax's one-argument `Rand(n)` is
shorthand for `Rand(1, n)`, so this returns a whole number **from 1 to 11 inclusive** - every
named formation with equal (1/11 ≈ 9.1%) probability, and it can never land on 0 or on the three
Custom slots (12-14). Anywhere the game auto-picks a formation (e.g.
`TBase_Team.CheckManagerChangeFormation`'s AI-manager formation swap), it can only choose one of
the 11 shipped shapes - never a custom one, and never the two orphaned files.

### Selection numbers (how the UI and the AI address one grid cell)

Cell indices 0-34 are an internal detail; the rest of the game (buttons, position matching,
player-swap logic) addresses grid slots by **selection number**, 1-10, assigned by walking the
35-cell array in order and counting the `1`s as they're found. `GetPosFromSelectionNo(n)` and
`GetSideFromSelectionNo(n)` both do this same walk (`c = c + 1` each time a `1` is found,
returning once `c = n`), converting selection number → line label / side. `GetSelectionNoFromSeg`
goes the other way (cell index → selection number) and can also mirror the whole grid first
(`If a1 = -1 Then a0 = 34 - a0`) - flipping cell `i` to `34 - i`, i.e. reflecting the grid
top-to-bottom, row-for-row and column-for-column, which is how the same 35-cell layout serves as
both "our shape, attacking up the pitch" and "their shape, attacking down it" without a second
copy of the data. Selection 0 is always the keeper and is never produced or consumed by this
walk.

### From grid cell to an actual pitch position (READ, not byte-verified)

`TFormation.GetPlayerXY` turns a selection's row/column into real X/Y coordinates for that
match. It is not yet byte-matched (three `setbe`/`setae` byte substitutions remain open - see
`src/recovered_unverified/TFormation.GetPlayerXY.bmx` for the full trail), but the body is
length-exact and the arithmetic mirrors the row/column tables above closely enough to trust the
constants. Per-row vertical push (`yOff`, scaled by formation-width settings from
`Engine.ini`) is largest for defenders and forwards (pushed furthest back/forward) and smallest
near the centre of the pitch; per-column horizontal spread (`wScale`) is:

| Column | 0 | 1 | 2 | 3 | 4 | 5 | 6 |
|---|---:|---:|---:|---:|---:|---:|---:|
| wScale | 1.5 | 2.0 | 3.0 | 3.5 | 3.0 | 2.0 | 1.5 |

confirming columns 0/6 hug the touchline tightly (smallest spread multiplier) while column 3
(the true centre) gets the most lateral room. `hScale` per row additionally depends on whether
the team has the ball (`a5`), pulling the back/front lines up or back between roughly 1.0 and
1.8×. None of this is stored in the `.tac` file - it all lives in code plus the nine
`formation*` settings in `EngineMedia/Inc/Engine.ini`, read once at start-up by `TFormation.SetUp`.

## What it means in play

**Editing a `.tac` file is the whole modding surface.** Flip a `0` to a `1` (respecting the
10-ones convention) and you've moved a player to a new line/side; nothing else about the format
needs updating, because every consumer (labels, selection numbers, AI position-matching, pitch
coordinates) derives itself from the flags. A hand-edited file that keeps exactly 10 ones and
respects CRLF line endings should load exactly as if it shipped with the game.

**The player's own tactics screen only ever offers the same 11 names as the ID table** - 
`TScreen_Formation.ButtonFormation` maps its formation-diagram buttons through the identical
11-name `Select` block used by `GetTacticIdByName`, calling `TTeam.ChangeFormation(1..11, 0)`.
Custom slots exist as save destinations (`TFormation.SaveTactics` writes to
`<userpath>\Tactics\<name>.tac`) but nothing among the recovered code reads them back in by ID - 
the mapping from "Custom 1/2/3" to a loadable formation, if any exists at all in the shipped
game, is one of the gaps below.

**AI-controlled teams' automatic formation changes are limited to the same 11 shapes.**
`TBase_Team.CheckManagerChangeFormation` (a team's mid-season formation-tinkering logic, run
after a poor run of form) calls `TFormation.PickRandomFormation`, which - per the numbers above
 - can only land on IDs 1-11. A club never randomly drifts into a Custom formation or into one
of the two orphaned files.

### The two files nothing loads

`4-1-4-1.tac` and `4-2-3-1.tac` sit in `EngineMedia/Tactics/` alongside the eleven named files,
each a perfectly well-formed 35-line/10-ones grid (rows above), but **neither filename appears
anywhere in the game's string data** (checked against `extracted/ghidra/strings_with_xrefs.tsv`
 - no hit for either string), and the only code path that calls `LoadTactics` at all
(`TFormation.Create`, via `GetStringTacticName`) can only ever produce one of the 11 names in
the ID table above. There is no directory-scan of `Tactics/` anywhere in the recovered code
either (compare `TScreen_MainMenu.UpdateLoadTable`, which *does* `ReadDir` the save folder - the
Tactics folder gets no equivalent). As far as the code recovered so far shows, these two files
are dead weight: content for two more formations (a 4-1-4-1 and a 4-2-3-1) that never made it
into the ID table or the tactics-screen buttons, left on disk from wherever they came from.
**INFERRED** - this is an absence-of-evidence finding (no string reference, no caller), not a
function that says "these are unused"; a caller could still exist among the ~992 unattributed
`code` functions not yet named.

## What we do not know yet

- **How selection numbers get bound to actual squad members.** This document covers turning a
  selection number into a *slot* (line, side, pitch coordinates); it does not cover which
  `TPlayer` in the squad is assigned to which selection number, or in what order, when a
  formation is first chosen or when the user drags a player between slots. `TScreen_Formation`
  has other methods (`ChangePosition`, `UpdatePosition`) that were not read for this document
  and are the likely place to look.
- **Whether "Custom 1/2/3" are ever loaded back in.** `SaveTactics` writes a custom shape to the
  user folder using the team's *current* in-memory name (`Self.name`), but no recovered code
  path calls `LoadTactics("Custom 1")`/`(2)`/`(3)` or otherwise turns ID 12-14 into a load. It's
  possible the save simply isn't reloaded anywhere in the retail build, or that the loader lives
  in one of the unattributed functions. Worth another look at any function that calls
  `TFormation.LoadTactics` besides `TFormation.Create` once more of the object model is named.
- **The exact three-byte codegen mismatch in `GetPlayerXY`.** The function is *length*-exact
  (2898/2898 bytes) and only 3 bytes differ in the actual output (a `setbe` vs `setae` compare
  direction at three sites, tracked in detail in
  `src/recovered_unverified/TFormation.GetPlayerXY.bmx`), so the constants and formulas quoted
  above are trustworthy, but the file cannot be promoted to VERIFIED until that closes.

## Worth preserving exactly when reimplementing

- **The `1` grid cap is 11, not 10, and the extra slot is a real (if unused-in-practice) bug
  surface.** `LoadTactics`'s read loop is `If Not Eof(s) And cnt < 11` - it keeps reading and
  assigning lines only until it has seen 11 flags equal to `1`. Every shipped file has exactly
  10, so this cap is never hit by any file on disk today, but a hand-edited or modded file with
  11+ ones would trigger it: once the 11th `1` is read, the loop's `If` body stops firing
  entirely - `ReadLine` is not called again - so **any remaining cells keep whatever value they
  already had**, which is the field initialiser's built-in default grid (see next point), not
  zero. A reimplementation that "cleans this up" into a straightforward "read all 35 lines"
  loop will silently behave differently on any file with 11 or more ones.
- **Any line that isn't the literal string `"1"` is forced to `0`,** even if it's a garbled or
  out-of-range digit - `Int(ReadLine(s))` is assigned first, then immediately overwritten to `0`
  in the `Else` branch unless the parsed value was exactly `1`. A file containing `"2"` or blank
  lines behaves identically to one containing `"0"` there.
- **`TFormation.New`'s field initialiser hard-codes a default grid, and that default is
  byte-identical to `4-4-2 A.tac`'s actual grid**
  (`[1,0,1,0,1,0,1,0,0,0,0,0,0,0,1,0,1,0,1,0,1,0,0,0,0,0,0,0,0,0,1,0,1,0,0]`, confirmed
  digit-for-digit above). This matters because of a second bug: `LoadTactics`'s final fallback
  path, when neither the requested file nor a user override exists, tries to open
  `g_datapath + "EngineMedia\Tactics\4-4-2.tac"` - a filename that **does not exist anywhere in
  the shipped game** (the real files are `4-4-2 A.tac` and `4-4-2 B.tac`; there's no bare
  `4-4-2.tac`). That fallback read fails too, `LoadTactics` logs "Cannot find tactics:" and
  returns 0 *without ever touching `Self.name` or `m_TacPos`* - so the object is simply left
  exactly as `New` created it. The two independent fallbacks (the dead file-path fallback, and
  the constructor's baked-in array) happen to converge on the *same* formation, 4-4-2 A, but
  only one of them actually works; the other is unreachable dead code that looks like a working
  safety net and isn't. Reproduce both faithfully - including the broken filename - rather than
  "fixing" the second fallback to a name that would actually resolve.
- **CRLF matters for line counting**, and the format only ever appears as `\r\n`-terminated in
  every shipped file - `ReadLine` handles either terminator, so this isn't a parsing hazard, but
  a byte-for-byte reproduction of a `.tac` file should keep CRLF to match the originals exactly.
