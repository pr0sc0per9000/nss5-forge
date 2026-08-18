# Formations and pitch zones

> **Source:** `TFormation.LoadTactics` @ 0x004d8783 (VERIFIED) · `TFormation.GetCol` @ 0x004d8aa4 (VERIFIED) · `TFormation.GetRow` @ 0x004d8aba (VERIFIED) · `TFormation.GetSelectionNoFromSeg` @ 0x004d8a4f (VERIFIED) · `TFormation.GetRowFromSelectionNo` @ 0x004d8af3 (VERIFIED) · `TFormation.GetColFromSelectionNo` @ 0x004d8b3c (VERIFIED) · `TFormation.GetPosFromSelectionNo` @ 0x004d96d7 (VERIFIED) · `TFormation.GetSideFromSelectionNo` @ 0x004d975c (VERIFIED) · `TFormation.UpdateLabels` @ 0x004d83cc (VERIFIED) · `TFormation.New` @ 0x004d7ef2 (VERIFIED) · `TFormation.Create` @ 0x004d8397 (VERIFIED) · `TFormation.SetUp` @ 0x004d80c2 (VERIFIED) · `TFormation.PickRandomFormation` @ 0x004d9c6f (VERIFIED) · `TFormation.GetStringTacticName` @ 0x004d9856 (VERIFIED) · `TFormation.GetTacticIdByName` @ 0x004d9911 (VERIFIED) · `TFormation.GetPlayerXY` @ 0x004d8b85 (READ) · `TTeam.UpdatePlayerDestinations` @ 0x004de516 (READ) · `TTeam.GetShootingDirection` @ 0x004e1914 (VERIFIED) · `TPitch.SetUp` @ 0x004e4a73 (VERIFIED) · `TPitch.YardsToPixels` @ 0x004e9fdb (VERIFIED)
> **Confidence:** MEDIUM
> **Last checked:** 2026-08-15

The grid mechanics below (how a `.tac` file becomes 35 zones, how a zone becomes a row/column,
how a formation is picked) come from functions that are byte-exact against the shipping
binary - that part is HIGH confidence. The pixel-coordinate formula that turns a zone into an
actual x,y target (`GetPlayerXY`) comes from a near-miss candidate that is **length-exact**
(2,898/2,898 bytes) but not fully byte-matched - three bytes concerning comparison direction
in two clamp checks remain unresolved. Everything attributed to
it below is marked accordingly and should be read as "very likely correct, not proven."

## What happens in the game

A formation is a shape: which of 11 outfield-plus-goalkeeper slots a player fills, and roughly
where he stands. New Star Soccer 5 stores that shape as one of 13 plain-text files under
`EngineMedia/Tactics/*.tac`, each 35 lines of `0` or `1` - a flattened **5 row × 7 column**
grid of pitch zones, with a `1` marking a zone that has a player in it. The goalkeeper is not
part of the grid at all; he is always squad slot 0 and is positioned by separate keeper AI.

When a team's formation loads, the game reads that grid into `TFormation.m_TacPos` and hands
out **selection numbers** 1 through 10 to the marked zones, in the order they appear in the
grid (top row, left to right, then the next row down). Every player on the pitch - outfielder
or opponent - is asked "where should selection number N stand right now?", and the answer
depends on three things: which zone selection N owns in the grid, which end the team is
currently attacking (it flips at half-time), and where the ball is. The formation gives a
player his base slot; the ball then pulls him off that slot by an amount that depends on
whether his team currently has the ball.

## The grid

### Layout

35 zones, indices 0-34. `TFormation.GetCol` and `TFormation.GetRow` split an index into a
column and a row:

* **Column** = `index Mod 7` → 0-6, left to right.
* **Row** = `index \ 7` (as a threshold ladder: `<7`→0, `<14`→1, `<21`→2, `<28`→3, else 4) →
  0-4, own goal to opponent's goal.

`TFormation.UpdateLabels` (byte-exact, 951/951) confirms what each row and column mean by the
labels it assigns and the squad counts (`m_Defenders`, `m_DefensiveMidfielders`, …) it derives
from them:

| Row | Zone indices | Role label | Counted into |
|---|---|---|---|
| 0 | 0-6 | Defender (`D`) | `m_Defenders` |
| 1 | 7-13 | Defensive Midfielder (`DM`) | `m_DefensiveMidfielders` |
| 2 | 14-20 | Midfielder (`M`) | `m_Midfielders` |
| 3 | 21-27 | Attacking Midfielder (`AM`) | `m_AttackingMidfielders` |
| 4 | 28-34 | Attacker (`F`) | `m_Attackers` |

| Column | Side label | Zones |
|---|---|---|
| 0, 1 | Left (`L`) | left flank |
| 2, 3, 4 | Centre (`C`) | centre - column 3 is dead centre |
| 5, 6 | Right (`R`) | right flank |

`UpdateLabels` concatenates the two to build each zone's on-screen tag: role letters first,
side letter appended - `"D"+"L"="DL"`, `"M"+"C"="MC"`, `"AM"+"R"="AMR"`, and so on. Those are
the same tags shown in the in-game formation editor.

```
                    col0   col1   col2   col3   col4   col5   col6
                    Left   Left   Centre Centre Centre Right  Right
row 0  Defenders     0      1      2      3      4      5      6
row 1  Def.Mid       7      8      9     10     11     12     13
row 2  Midfield     14     15     16     17     18     19     20
row 3  Att.Mid      21     22     23     24     25     26     27
row 4  Attackers    28     29     30     31     32     33     34
```

`TFormation.GetRowFromSelectionNo` / `GetColFromSelectionNo` walk the grid counting `1`s until
the count matches the requested selection number, then return that zone's row/column - 
the inverse of the table above. `TFormation.GetPosFromSelectionNo` does the same walk but
returns a 0-5 position code instead (0 = goalkeeper, hard-coded - selection 0 never reaches the
walk; 1-5 = the five row roles in order). `TFormation.GetSideFromSelectionNo` returns 0/1/2 for
Left/Centre/Right the same way, but has **no** selection-0 special case - see Quirks below.

### The 13 shipped shapes

Every `.tac` file is 35 lines with **exactly 10 ones** (confirmed by reading all 13 files - 
`3-4-3.tac`, `3-5-2 A.tac`, `3-5-2 B.tac`, `4-1-4-1.tac`, `4-2-2-2.tac`, `4-2-3-1.tac`,
`4-2-4.tac`, `4-3-3.tac`, `4-4-1-1.tac`, `4-4-2 A.tac`, `4-4-2 B.tac`, `4-5-1.tac`,
`5-3-2.tac`, all in `EngineMedia/Tactics/`). Ten outfield slots plus the separate goalkeeper
makes eleven - a full side. Row-by-row breakdown (D / DM / M / AM / F), read directly from the
files:

| File | D | DM | M | AM | F | Notes |
|---|---:|---:|---:|---:|---:|---|
| 3-4-3 | 3 | 0 | 4 | 0 | 3 | |
| 3-5-2 A | 3 | 1 | 3 | 1 | 2 | the "5" spread across DM/M/AM |
| 3-5-2 B | 3 | 0 | 5 | 0 | 2 | the "5" bunched in one midfield line |
| 4-1-4-1 | 4 | 1 | 4 | 0 | 1 | |
| 4-2-2-2 | 4 | 0 | 2 | 2 | 2 | two separate central lines |
| 4-2-3-1 | 4 | 2 | 0 | 3 | 1 | |
| 4-2-4 | 4 | 0 | 2 | 0 | 4 | |
| 4-3-3 | 4 | 0 | 3 | 0 | 3 | |
| 4-4-1-1 | 4 | 0 | 4 | 1 | 1 | |
| 4-4-2 A | 4 | 0 | 4 | 0 | 2 | flat banks of 4 - the compiled-in default, see Quirks |
| 4-4-2 B | 4 | 1 | 2 | 1 | 2 | narrower midfield diamond-ish spread |
| 4-5-1 | 4 | 0 | 5 | 0 | 1 | |
| 5-3-2 | 5 | 0 | 3 | 0 | 2 | |

The formation name is literally the row-group sizes (defence-midfield-block-attack), which is
why this table lines up with every file name exactly. 4-4-2 A, laid out:

```
row 0  Defenders    1  .  1  .  1  .  1      back four: columns 0,2,4,6
row 1  Def.Mid      .  .  .  .  .  .  .
row 2  Midfield     1  .  1  .  1  .  1      bank of four: columns 0,2,4,6
row 3  Att.Mid      .  .  .  .  .  .  .
row 4  Attackers    .  .  1  .  1  .  .      strike pair: columns 2,4
```

A back four sits on the even columns (0,2,4,6 - fullbacks out on the touchline columns); a
back three (3-4-3, 3-5-2, 5-3-2's front pairing) sits one column narrower, on the odd columns
(1,3,5), which is the model's only way of expressing "narrower defensive width."

### Picking and naming a formation

`TFormation.GetStringTacticName` maps a numeric tactic ID to its display name, and
`GetTacticIdByName` is its exact inverse:

| ID | Name | ID | Name |
|---:|---|---:|---|
| 1 | 3-4-3 | 8 | 4-4-2 A |
| 2 | 3-5-2 A | 9 | 4-4-2 B |
| 3 | 3-5-2 B | 10 | 4-5-1 |
| 4 | 4-2-2-2 | 11 | 5-3-2 |
| 5 | 4-2-4 | 12 | Custom 1 |
| 6 | 4-3-3 | 13 | Custom 2 |
| 7 | 4-4-1-1 | 14 | Custom 3 |

`TFormation.PickRandomFormation` is `Rand(11)` - BlitzMax's one-argument `Rand`, which is
inclusive 1 to 11. It can only land on IDs 1-11, i.e. only the eleven named shapes above; the
three Custom slots (12-14, player-edited formations) are never chosen at random.
`TBase_Team.CheckManagerChangeFormation` is the caller that decides *when* to reroll: after
every completed fixture it looks at a CPU team's last five results (`res[0..4]`, one point per
win, none for a loss, an explicit `1` for a draw), and if the most recent result was a loss
**and** the five-result total is under 5 **and** a `Rand(3) = 1` (1-in-3) roll hits, the team's
formation is replaced with a fresh random pick and `TTeam.ChangeFormation` rebuilds the
`TFormation` object from it. So a poorly-performing CPU team has roughly a 1-in-3 chance, per
fixture that leaves it still struggling, of a formation reshuffle.

## Zone → pixel coordinate (READ, near-miss - see confidence note above)

`TFormation.GetPlayerXY(selectionNo, ballX, ballY, pitchW, pitchH, dir, hasBall, &outX, &outY,
scale, heightScale)` is what actually turns a selection number into an x,y target each frame.
Every call site found (`TTeam.UpdatePlayerDestinations`, itself a near-miss) passes:

* `pitchW` / `pitchH` = `g_pitchhalfwidth*2` / `g_pitchhalfheight*2` - the full working area.
  `TPitch.SetUp` (byte-exact) sets `g_pitchhalfwidth = ImageWidth(StadiumTop.png) * 0.5` and
  `g_pitchheight = ImageHeight(StadiumTop.png) * 0.5` - the formation coordinate space is
  sized off the **stadium background art's pixel dimensions**, not a configured pitch size. The
  currently shipped `EngineMedia/Match/Pitch/StadiumTop.png` measures 580×772 px, giving a
  580×772 working area (58×77.2 yards at `TPitch.YardsToPixels`'s confirmed 10 px/yard).
* `dir` = `TTeam.GetShootingDirection()` (byte-exact) → always `1` or `-1`; it flips at
  half-time so "row 0 = defenders" always means "nearest this team's own goal" regardless of
  which physical end that is this half.
* `hasBall` = a local the caller calls `chase`, `1` when `ball.teaminpossession = Self.id`
  (this team currently has the ball), `0` otherwise, with a couple of penalty-box exceptions.
* `scale` = normally `1.0`; the caller has at least two paths that push it to `3.0` when the
  ball is more than 45 yards (`TPitch.YardsToPixels(45.0)`) from one goal-line or the other
  (exact condition depends on `chase`), and one that sets it to `2.0` in a separate numbered
  match state - both spread the whole team out further than usual. The full match-state
  dispatch this sits inside is not otherwise covered by this document (see Gaps below).
* `ballX`/`ballY` = the ball's current position (or the human player's position in training
  mode) - this is the "pull toward the ball" input.

### The spacing constants

Nine floats, read once at startup by `TFormation.SetUp` (byte-exact) from
`incbin::Inc/Engine.ini` (extracted copy: `extracted/incbin/Inc/Engine.ini`) under its own
`' Tactics` section, whose file comment is the single best one-line summary of the whole
system: *"Higher width and height makes formation tighter."* Both constants are **divisors**,
so a bigger number means less space between columns/rows.

| Key | Value | Used for |
|---|---:|---|
| `formationwidth` | 24 | column divisor when the team **has** the ball |
| `withoutballformationwidth` | 26 | column divisor when it does **not** |
| `formationheight` | 10 | row divisor (both states) |
| `formationxshift` | 1.0 | how fully a player snaps sideways to his slot, **with** ball |
| `withoutballformationxshift` | 1.25 | same, **without** ball |
| `formationyshift` | 2.75 | how fully a player snaps forward/back to his slot (both states) |
| `formationdepth` | 1.0 | whole-row depth shift toward/away from goal, by possession |
| `wideplayerpush` | 1.1 | extra depth push for touchline zones in the back three rows |
| `ymarginmultiply` | 2.0 | doubles a row's vertical roam box when `g_player_int01` is set |

Column spacing `wSpacing = pitchW / (formationwidth × scale)`; row spacing
`hSpacing = pitchH / formationheight` (the call sites always pass the height-scale argument as
`1.0`). At the measured 580×772 working area and `scale=1.0`: `wSpacing ≈ 24.2px` with the
ball, `≈22.3px` without; `hSpacing = 77.2px` in both states.

### Column offsets and roam boxes

Each column has a fixed offset (in `wSpacing` units) from the pitch centre-line and a scale
factor (`wScale`) that sets how wide a box the player is allowed to roam sideways from that
point:

| Column | Offset (× wSpacing) | wScale (roam width) |
|---|---:|---:|
| 0 (far left) | 4.5 | 1.5 |
| 1 | 3.5 | 2.0 |
| 2 | 1.5 (mirror: 1.25 - see Quirks) | 3.0 |
| 3 (centre) | 0 | 3.5 |
| 4 | 1.5 (mirror: 1.25 - see Quirks) | 3.0 |
| 5 | 3.5 | 2.0 |
| 6 (far right) | 4.5 | 1.5 |

Wide zones (0,1,5,6) get a narrow side-to-side box; the centre zone gets the widest - wingers
and fullbacks stay pinned near their touchline, central players are freer to drift left-right.

### Row offsets and roam heights

Each row has a base depth offset (× `hSpacing`) and an `hScale` (vertical roam height) that
differs by whether the team has the ball - the whole team stretches out lengthways in
possession and compresses out of possession:

| Row | Depth offset (× hSpacing) | hScale, with ball | hScale, without ball |
|---|---:|---:|---:|
| 0 Defenders | 1.25 | 1.8 | 1.0 |
| 1 Def. Mid | 0.5 | 1.6 | 1.2 |
| 2 Midfield | 0.25 | 1.4 | 1.4 |
| 3 Att. Mid | 1.0 | 1.2 | 1.6 |
| 4 Attackers | 1.75 | 1.0 | 1.8 |

(Defenders and Attackers are exact mirrors of each other's hScale, as are Def. Mid/Att. Mid - 
the shape stretches symmetrically around the midfield line.)

## What it means in play

* **Possession changes the whole team's shape, not just one player.** With the ball, columns
  are ~8% further apart (divisor 24 vs 26) and a player sits exactly on his formation spot
  sideways (`formationxshift=1.0` removes 100% of the gap between his ball-relative starting
  point and his slot). Without the ball, the shape tightens up and a player only closes 80% of
  that gap (`÷1.25`), leaving 20% ball-relative drift - a defending side looks slightly less
  rigidly-drilled than an attacking one, by design.
* **Vertically, nobody ever fully holds their line.** `formationyshift=2.75` applies in both
  possession states and only removes about 36% (`1/2.75`) of the gap between a player's
  ball-relative position and his row's target depth - every player tracks the ball forward and
  back far more than he holds a fixed depth, which is what gives the team shape its
  concertina/elastic look as the ball moves end to end.
* **Centre-backs are kept honest near the halfway line.** Only for row 0 (Defenders) *and*
  only the three centre columns (2, 3, 4 - fullbacks in columns 0/1/5/6 are exempt), the
  computed depth target is additionally clamped to within `pitchH/12` of the pitch's vertical
  mid-point - about 6.4 yards at the shipped stadium art size - pushing back in only the
  direction that would otherwise let a centre-back step too far into the attacking half. It
  reads as a basic offside-trap/"hold the line" rule: your wide defenders can drop deep to
  cover a flank, but your central pairing is not allowed to wander far from the halfway mark.
* **Touchline zones in the back three lines get an extra depth kick.** Rows 0-2 only
  (Defenders/Def.Mid/Midfield - not the two attacking rows), columns 0 or 6 only: with the
  ball, that zone's player is pushed a further full `wideplayerpush` (1.1) `hSpacing` units;
  without the ball, he only gets pushed if the ball itself is over on his side, and only by
  half as much, scaled down further the closer the ball sits to the centre. In practice this
  reads as cover for the flank the ball is actually in - a winger/full-back zone leans into
  covering that side rather than holding a rigid depth regardless of where play is.
* **The 13 formation names describe the grid exactly.** As the row-breakdown table above shows,
  every formation's D-block/mid-block/attack-block name is a literal count of marked rows - 
  "3-5-2 A" spreads its five midfielders across DM/M/AM, "3-5-2 B" bunches all five into the
  single M row. There is no hidden weighting or player-quality factor in any of this: the shape
  is purely geometric, read straight off the `.tac` file.

## What we do not know yet

* **`TFormation.GetPlayerXY` itself is unverified.** It is length-exact (2,898/2,898 bytes),
  and every constant and branch quoted above has been independently re-confirmed, but three bytes remain wrong: the comparison
  direction (`setbe` vs `setae`) on two of the early ball-position clamps and one clamp inside
  the centre-back depth check. The root cause is understood (a BlitzMax-compiler FPU
  stack-ordering quirk in `cgfixfp_x86.cpp`, documented at length in the candidate file itself,
  `src/recovered_unverified/TFormation.GetPlayerXY.bmx`) but not yet fixed without breaking the
  function's total length elsewhere. None of the open bytes affect the numbers or branch shapes
  reported in this document - they are pure comparison-direction encoding, not different
  thresholds - but the function cannot be tagged VERIFIED until closed.
* **`TTeam.UpdatePlayerDestinations` is also unverified.** This document only read the slice
  around its `GetPlayerXY` calls to establish what the arguments mean; the rest of that
  9,170-byte function (training-mode positioning, the match-state `Select` block, corner-kick
  positions, shootout positions) is out of this document's scope. A future pass on that
  function would sharpen exactly what `chase`/`scale` mean in every match state.
* **`g_player_int01`**, the flag that doubles a row's `hScale` via `ymarginmultiply` when set,
  is read inside `GetPlayerXY` but no function that *writes* it has been identified yet. What
  triggers the wider vertical roam box is unknown.
* **`TFormation.GetSelectionNoFromSeg`'s real caller is unknown.** The `a1=-1` branch mirrors a
  zone index (`34 - index`) before doing the zone→selection-number lookup, which is clearly a
  "same zone from the other end" operation, but no confirmed direct caller exists in the
  recovered corpus - only ambiguous virtual-dispatch candidates that share its vtable slot
  (0x44) with unrelated Types. Which system actually calls this, and why it needs the mirrored
  form, is open.
* **The in-game formation *editor's* screen-pixel layout** (as opposed to the match engine's
  world coordinates) was not investigated here - `TScreen_Formation.*` (recovered, verified)
  reuses `GetPosFromSelectionNo`/`GetSideFromSelectionNo` for its labels but has its own,
  separate screen-coordinate placement logic that this document does not cover.

## Quirks worth preserving exactly

* **`New()` pre-seeds the grid with the 4-4-2 A pattern**, not zeros:
  `m_TacPos = [1,0,1,0,1,0,1,0,0,0,0,0,0,0,1,0,1,0,1,0,1,0,0,0,0,0,0,0,0,0,1,0,1,0,0]` is a
  field initialiser, not something `LoadTactics` writes. `LoadTactics`'s read loop
  (`If Not Eof(s) And cnt < 11`) only overwrites a zone while the file still has lines *and*
  fewer than 11 marked positions have been seen so far. Every shipped file is a full 35 lines
  with only 10 ones, so this never shows up in practice - but a shorter or malformed custom
  `.tac` file would leave its unread tail zones silently holding the **compiled-in 4-4-2 A
  default**, not empty zones. This must be reproduced by seeding the array the same way, not by
  zero-filling it.
* **The final fallback filename in `LoadTactics` does not exist.** If a named tactics file is
  missing from both the install path and the user path, the code falls back to
  `EngineMedia\Tactics\4-4-2.tac` - but the 13 shipped files are named `4-4-2 A.tac` and
  `4-4-2 B.tac`; there is no plain `4-4-2.tac`. That fallback `FileType` check always fails too,
  so the function logs `"Cannot find tactics: <name>.tac"` and returns 0 having loaded nothing - 
  it only "works" because the `New()` default (above) already happens to be the 4-4-2 A shape.
  Reproduce the fallback path exactly, including the fact that it is dead code that happens to
  be harmless, not a working fallback.
* **`PickRandomFormation` can only choose IDs 1-11.** Custom 1/2/3 (12-14) are unreachable by
  any random roll - preserve `Rand(11)`, not `Rand(14)` or `Rand(1,14)`.
* **Two shipped `.tac` files have no tactic ID.** `4-1-4-1.tac` and `4-2-3-1.tac` exist in
  `EngineMedia/Tactics/` and load fine by filename, but `GetTacticIdByName` has no case for
  either name (returns 0) and `GetStringTacticName` has no case for ID 0 (falls through to its
  default, `"4-4-2 A"`). Anything that round-trips one of these two formations through its
  numeric ID rather than its filename will silently relabel it "4-4-2 A". Preserve this
  mismatch rather than "fixing" the ID tables to cover all 13 files - the original never did.
* **`GetSideFromSelectionNo` has no selection-0 case.** Its loop only matches counts produced
  by walking marked (`=1`) zones, and selection 0 (the goalkeeper) never increments the counter
  to 0 inside the loop, so the function always falls through to its generic not-found
  `Return 1` (Centre). The goalkeeper's "side" is Centre only because that happens to be the
  fallback value, not because of a deliberate rule - worth keeping as-is rather than adding an
  explicit `If a0 = 0 Then Return 1` that would look intentional.
* **`GetPlayerXY`'s Float return value is dead.** It always returns `g_form_posnoise`, a module
  global that `TFormation.SetUp` never assigns and that reads as BlitzMax's default `0.0` every
  time it has been checked directly. The real x/y output goes through the two pointer
  parameters; every known caller ignores the return value. Looks like an abandoned "positional
  noise" feature - reproduce the always-0.0 return rather than wiring it up to do something.
* **The column-2/column-4 widen offsets are asymmetric between the two attacking-direction
  mirrors** - 1.5× `wSpacing` in one mirror, 1.25× in the other, while every other column
  (0,1,3,5,6) uses identical magnitudes in both mirrors. This has been checked directly against
  the two literal float constants in the binary, not merely inferred from decompiler output;
  it is very likely simply how the original was written rather than a bug that matters, and
  should be kept exactly as measured rather than symmetrised.

*Jargon notes: a "selection number" is the game's 1-based index for a formation slot (0 is
always the goalkeeper, 11+ are substitutes who are not part of the grid at all).
`ReadSettingFloat`/`incbin::` mean the value is compiled straight into the executable from
`EngineMedia/Inc/Engine.ini` at build time - there is no loose `Engine.ini` file to edit on
disk; changing these numbers means rebuilding the game.*

