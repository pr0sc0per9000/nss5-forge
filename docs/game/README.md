# How New Star Soccer 5 actually works

This directory is **the deliverable**. Everything else in `docs/` is about the binary, the
toolchain, or the process of reconstruction. This is about the game.

The reason it exists as a separate tree: the exact behaviour of this game - how the AI
decides, how injuries and cards happen, how a season unfolds, what the random tables are - 
exists in exactly one place, the 2011 binary. Nobody wrote it down. There is no developer
documentation to find. Everything else we depend on (zip archives, encrypted saves, PNG
loading, audio) is a solved problem with public documentation and can be reimplemented, and
probably reimplemented better. **This knowledge cannot be re-derived from anywhere else, so
it is the thing worth capturing carefully.**

Read `../RULES.md` before adding a file here. The short version: every behavioural claim
carries the function it came from and an honest tag saying whether we proved it or believe
it, and `scripts/check_docs.py` fails the build if a document claims `VERIFIED` for a
function that is not actually byte-matched.

```bash
python scripts/check_docs.py
```

As of this pass, 22 of 24 planned documents are written. Only the save-file format and the
language-tag catalogue remain unwritten (see the Data table below) - everything else that
touches how the game actually *plays* now has a document behind it.

---

## Headline findings

The handful of things worth reading even if you read nothing else here.

* **Goalkeepers cannot be booked or sent off, structurally.** `TPlayer.RedCard()` opens with
  an unconditional `If Self.selectionno = 0 Then Return 0` - selection number 0 is always the
  keeper - so no caller, anywhere, can ever card him. See
  [match/fouls-and-cards.md](match/fouls-and-cards.md).

* **The top half of the power bar does nothing.** Every kick gets a flat **+50** added to its
  power before the result is clamped to 100 (130 during one match state) - so the usable range
  is really 0-50, not 0-100. See [match/ball-physics.md](match/ball-physics.md).

* **The ball has no left/right velocity at all.** `TBall` stores a scalar speed plus a
  direction in degrees, not x/y velocity - so friction and drag only ever slow the ball down,
  never bend its path. Only curl and collisions change its heading. See
  [match/ball-physics.md](match/ball-physics.md).

* **Painkillers are a trap dressed as a cure.** Taking them before an injury forces both the
  worst injury-*frequency* band (same multiplier as being exhausted, ×0.5) and the worst
  injury-*severity* band (a forced 5-7 match roll instead of the normal 1-3) on the very next
  foul - and the in-game purchase dialog says this outright. See
  [match/injuries.md](match/injuries.md).

* **CPU players never get any of the feedback systems.** Rating changes, celebration effects,
  the whole "good pass!" / "bad shot!" boss-shout loop - all of it is gated on
  `Self.newstar`. CPU players run the identical shot/save/goal code but the game never shows
  any of the reward layer to them. See
  [match/shooting-and-scoring.md](match/shooting-and-scoring.md).

* **Formation "width" settings in `Engine.ini` are divisors, not multipliers.** A *bigger*
  `formationwidth` number makes the team's on-pitch shape *narrower* - the opposite of what
  the key name suggests. See [ai/team-shape.md](ai/team-shape.md) and
  [ai/formations.md](ai/formations.md).

* **Two of the 13 shipped formation files are dead content.** `4-1-4-1.tac` and
  `4-2-3-1.tac` are well-formed and sit on disk, but their filenames never appear anywhere in
  the game's strings or code - no menu, no random pick, nothing can ever select them. See
  [data/tactics-format.md](data/tactics-format.md).

* **Horse-racing odds are pure noise.** `THorse.SetRaceOdds` assigns prices from a random
  tie-breaker that gets re-rolled before every race - a horse's actual stats have zero
  influence on its own odds, so the board is disconnected from the race a value-tracking
  player could actually predict. See [economy/stable.md](economy/stable.md).

* **The slot machine pays the player, not the house.** Computed net expected value is
  **+25.6%** of the stake per spin in the player's favour (under a stated uniformity
  assumption) - the opposite of how a real slot machine is built. See
  [economy/casino.md](economy/casino.md).

* **Only 12 of 211 nations have their own name pool.** Every other nationality's randomly
  generated players fall back to the English first/last-name list in `Names.csv`. See
  [data/csv-schemas.md](data/csv-schemas.md).

* **Boots, shin pads and energy drinks are not cosmetic - they change your stats.** A
  `GetBootBonus` lookup table adds real dribbling/passing/shooting points, shin pads add flat
  tackling, and NRG drinks add pace, directly into the live match. Property, vehicles and most
  shop items, by contrast, only ever feed a cosmetic "Lifestyle" score. See
  [economy/money-and-shop.md](economy/money-and-shop.md).

* **There is no bench.** Every substitute that comes on for a CPU team - including for
  injuries - is a brand-new `TPlayer` generated on the spot with a random name and freshly
  rolled stats, not drawn from any existing reserve pool. See
  [ai/manager.md](ai/manager.md).

* **A skipped match's penalty shoot-out score can come back inverted.** When the game
  fast-forwards a match straight to a shoot-out result, the loser is assigned the *higher*
  recorded score - a genuine original bug, preserved byte-exact. See
  [career/season-structure.md](career/season-structure.md) and
  [match/set-pieces.md](match/set-pieces.md).

* **Debut-season transfer valuations are probably a bug.** `TProfile.GetValue`'s age
  multiplier table has no case for age 15 - the age every career starts at - so it silently
  falls back to the same 0.1× floor used for a washed-up 40-year-old. See
  [career/player-progression.md](career/player-progression.md).

---

## Map

### The spine - start here

| Document | Covers | State |
|---|---|---|
| [engine/main-loop.md](engine/main-loop.md) | Launch → first kick: the boot sequence and the main loop | **Written** (HIGH) - **fixed 40 Hz logic tick (25 ms), interpolated rendering**; the first screen is the language picker; the retail game hard-exits if Steam is unavailable |

This is the function everything else hangs off. Read it before any other document here.

### Match engine - what happens on the pitch

| Document | Covers | State |
|---|---|---|
| [match/simulated-results.md](match/simulated-results.md) | Scorelines for fixtures the player does not play | **Written** (HIGH) - a fixed weighted table, 0-3 goals each equally likely (23.82%), completely uncorrelated with team ability |
| [match/ball-physics.md](match/ball-physics.md) | Ball movement, bounce, spin, friction | **Written** (MEDIUM) - polar motion (speed + heading, no vx/vy), 25%-per-tick dribble lerp, flat +50 kick-power boost before the 0-100 clamp |
| [match/fouls-and-cards.md](match/fouls-and-cards.md) | Tackles, fouls, bookings, sendings-off | **Written** (HIGH) - foul checks fire on real sprite overlap during a tackle animation; four-factor yellow/red decision; goalkeepers structurally immune to cards |
| [match/injuries.md](match/injuries.md) | When and how players get hurt | **Written** (HIGH) - injuries only ever happen to the human player's own character, as a side effect of being fouled; 2-8 match layoffs; painkillers make things worse |
| [match/shooting-and-scoring.md](match/shooting-and-scoring.md) | Shots, saves, goals in played matches | **Written** (MEDIUM) - three independent systems (power/direction, on-target test, goal-line test) mean a shot can be logged on-target and still curl wide |
| [match/set-pieces.md](match/set-pieces.md) | Corners, free kicks, penalties, throw-ins | **Written** (HIGH for dispatch/geometry/shootout, MEDIUM for two taker-selection thresholds) - one dispatcher handles every restart; full shootout state machine with an early-decision table |
| [match/match-flow.md](match/match-flow.md) | Kickoff to full time: the match clock and state machine | **Written** (HIGH for the frame loop/clock/shootout, MEDIUM for goal handling) - two overlapping globals drive the whole match; skip-ahead simulator dice odds documented |
| [match/stats-and-ratings.md](match/stats-and-ratings.md) | What the game records, and how the 1-10 match rating is computed | **Written** (MEDIUM) - rating is 1-100 internally shown ÷10, baseline 55; per-event weights and caps; stat type 8 is rated with the tackle weight instead of its own (an original bug) |

### AI - how the computer decides

| Document | Covers | State |
|---|---|---|
| [ai/player-decisions.md](ai/player-decisions.md) | What an individual CPU player chooses to do | **Written** (MEDIUM) - shoot/pass/cross off flat yard thresholds (20/22.5/35/40yd), no skill weighting at all; even the human's own set-piece taker is AI-steered |
| [ai/team-shape.md](ai/team-shape.md) | Where the team moves as a unit | **Written** (MEDIUM) - the 9,170-byte function that positions every non-keeper every tick; formation-width constants are divisors, not multipliers |
| [ai/formations.md](ai/formations.md) | How the 13 `.tac` files become pitch positions | **Written** (MEDIUM) - 35-cell 0/1 grid per file; 2 of 13 shipped files are unreachable dead content; pitch size is derived from background-art pixel dimensions |
| [ai/goalkeeper.md](ai/goalkeeper.md) | Keeper positioning and saves | **Written** (MEDIUM overall; HIGH for save/dive/parry, MEDIUM for standing position) - every decision is geometry or a dice roll; no function reads a keeper skill rating anywhere |
| [ai/manager.md](ai/manager.md) | CPU manager: selection, substitutions, tactics | **Written** (HIGH for formation changes/subs, MEDIUM for squad building) - no strategic AI exists; it's three independent dice rolls at fixed moments, and every substitute is freshly generated, not benched |

This was the section the project most wanted filled, because replacing the AI with a real
model requires knowing exactly what the old one read, wrote and decided. It is now the most
complete section in the tree.

### Career and world simulation

| Document | Covers | State |
|---|---|---|
| [career/season-structure.md](career/season-structure.md) | Fixtures, competitions, promotion, relegation | **Written** (MEDIUM) - shared pairing-table generator missing an entry for 27-team pools; resolved the open question on promotion-place codes 101/107 |
| [career/transfers-and-contracts.md](career/transfers-and-contracts.md) | Offers, interest, signing, transfer windows | **Written** (MEDIUM) - exponential wage-vs-club-strength curve (2.25^(strength/6.5)), strength-tiered fees up to ×10; background interest system read from decompile only |
| [career/training.md](career/training.md) | Training minigames and how they change ability | **Written** (HIGH for the reward mechanism, MEDIUM for the Pace drill) - reward × level-count = 100 for every drill, by design |
| [career/player-progression.md](career/player-progression.md) | How ability and stats change over a career | **Written** (HIGH) - two unrelated stat systems (7 trained "Big" skills, 10 match-nudged attributes); the Big Seven are guarded by an anti-tamper SHA-256-shaped hash |
| [career/relationships.md](career/relationships.md) | Girlfriend, pass, boss, teammates, morale | **Written** (HIGH) - six relationships + Fame feed one Happiness score (girlfriend weighted double) that the game's own tips say affects misplaced kicks |
| [career/achievements-and-news.md](career/achievements-and-news.md) | Achievements, boss messages, interviews, season review, social sharing | **Written** (MEDIUM) - all 100 achievements listed, 14 unlock conditions traced; `CACHIEVEMENTMOBILE_*` is a dead second list with no caller |

### Economy and side content

| Document | Covers | State |
|---|---|---|
| [economy/money-and-shop.md](economy/money-and-shop.md) | Wages, bonuses, spending, shop items | **Written** (HIGH) - boots/shin pads/NRG give real stat boosts; everything else (property, vehicles, most items) is purely cosmetic Lifestyle score |
| [economy/casino.md](economy/casino.md) | Blackjack, roulette, slots, higher-lower, pairs | **Written** (HIGH) - roulette's house edge (-5.26%) is realistic, slots pay the player (+25.6% EV); "higher-lower" and "pairs" turned out not to be casino games at all |
| [economy/stable.md](economy/stable.md) | Horse racing | **Written** (MEDIUM) - races are decided by real stat-driven physics; betting odds are pure random noise, disconnected from ability |

### Data and formats

| Document | Covers | State |
|---|---|---|
| [data/csv-schemas.md](data/csv-schemas.md) | All 8 `GameMedia/Data/*.csv` + `.ini` files | **Written** (HIGH) - full column-by-column schema; only 12/211 nations have their own name pool, the rest fall back to English names |
| [data/tactics-format.md](data/tactics-format.md) | The 13 `.tac` files: 35 lines of 0/1 = a pitch-zone grid | **Written** (HIGH) - grid layout and per-file contents confirmed; 2 files are dead content (see Headline findings) |
| _data/save-format.md_ | Encrypted zip, entry `newstarsoccerfivesavefile` | **Gap** - deliberately low priority; a solved problem, public zip/AES documentation covers it |
| [data/languages.md](data/languages.md) | `Languages.csv`, 2,750 tags × 10 languages | **Written** (HIGH) - 87 tag families catalogued, which doubles as a map of every feature the game has; missing tag renders as `"@"+tag`, blank cell falls back to English |

### User interface

| Document | Covers | State |
|---|---|---|
| [ui/screen-flow.md](ui/screen-flow.md) | Every screen, the navigation graph, and what each button does | **Written** (MEDIUM) - ~97 navigation edges extracted mechanically from verified button bodies; clicks route through a raw `fHit` function pointer, not virtual dispatch; a live developer cheat is still in the shipped binary |

### Existing material elsewhere

These predate this directory and contain real behavioural content. They are not being
re-filed; link to them rather than duplicating:

* `docs/specs/01-clubs-and-nations.md`
* `docs/specs/02-competition-system.md`
* `docs/specs/03-game-systems-from-language-tags.md`
* `docs/specs/04-match-engine-physics.md`
* `docs/specs/09-match-engine-implementation-spec.md`

---

## Where the knowledge is thinnest

Every document above has provenance, but "written" is not the same as "settled." Ranked
honestly, worst first.

### Documents at MEDIUM confidence (the primary tag, not just an inline caveat)

1. **[ai/formations.md](ai/formations.md)** and **[ai/team-shape.md](ai/team-shape.md)** - 
   both lean on the same two near-miss functions, `TTeam.UpdatePlayerDestinations`
   (9,170 bytes, 2 remaining `fxch` gaps) and `TFormation.GetPlayerXY` (length-exact at
   2,898 bytes, 3 remaining same-length `setae`/`setbe` substitutions). The overall shape is
   trustworthy - the byte counts already match - but individual comparison directions are not
   proven, and `team-shape.md` flags one genuinely self-contradictory guard
   (`p = g_newstar And p.newstar = 0`) whose real-world reachability is unresolved and marked
   LOW confidence inline.
2. **[match/ball-physics.md](match/ball-physics.md)** - three of its supporting bodies
   (`TBall.UpdateMovement`, `TBall.CheckAfterTouch`, `TBall.CheckGoals`) are near-misses
   (1, 14, and 8 bytes off respectively). The curl/flair scaling and the exact goal-line test
   both sit downstream of these.
3. **[match/shooting-and-scoring.md](match/shooting-and-scoring.md)** - the human charge-shot
   power-fill rate is unconfirmed (its only reader, `TPlayer.CheckKick`, is an unread
   near-miss), and `TPlayer.TapKickAdvanced` has no `.bmx` reconstruction at all, only a
   Ghidra decompile.
4. **[ai/player-decisions.md](ai/player-decisions.md)** - solid on the shoot/pass/cross
   thresholds, but the restart-type enum it depends on (`g_player_int01`, read from
   `TEngine.SetUpSetPiece`) is CONFIDENCE=NONE in the decompile annotation, and two float
   distance thresholds inside `ForceControlCPU` were not recovered from disassembly.
5. **[ai/goalkeeper.md](ai/goalkeeper.md)** - save/dive/parry are HIGH (fully byte-exact);
   standing position is MEDIUM because `TPlayer.UpdateKeeperPosition` has never been
   byte-verified, only decompiled.
6. **[career/season-structure.md](career/season-structure.md)** - the actual contents of the
   fixture-pairing tables (`Fn_004C5280`) were never read, only their existence and call
   pattern; the 27-team gap in that table is confirmed but unexplained.
7. **[career/transfers-and-contracts.md](career/transfers-and-contracts.md)** - the
   background system that decides *when* a club shows interest
   (`CheckTransferWindow`/`UpdateInterestedClubs`/`SignForNewClub`) is decompile-only; only
   the contract-offer math itself is byte-verified.
8. **[economy/stable.md](economy/stable.md)** - the race-physics and payout tables are all
   VERIFIED; the MEDIUM tag is carried entirely by `TScreen_Stable.Update` (unread), which
   holds the finish-line value and the sort that decides finishing order.

### The single functions most worth reading next

Ranked by how many documents each one would upgrade if it were byte-matched:

1. **`TEngine.SetUpSetPiece` @ 0x004d2f01** (near-miss, 1 byte short) - touched by
   set-pieces.md, fouls-and-cards.md, player-decisions.md and manager.md. This is the
   restart-type dispatcher; closing it would resolve the `g_player_int01` enum that four
   separate documents currently either leave unmapped or infer from context.
2. **`TTeam.UpdatePlayerDestinations` @ 0x004de516** and **`TFormation.GetPlayerXY`
   @ 0x004d8b85** - both near-misses underpinning all of `ai/team-shape.md` and
   `ai/formations.md`.
3. **`FUN_0058C960`** (the 1,776-byte SHA-256-shaped hash primitive) - blocks
   `TProfile.CheckSkillHash`, `UpdateAbility` and `SetAbility` from ever reaching VERIFIED,
   which caps `career/player-progression.md` and `career/training.md`'s Pace section.
4. **`TPlayer.UpdateKeeperPosition` @ 0x004f2eed** - the last unverified piece of
   `ai/goalkeeper.md`.
5. **`TBall.UpdateMovement` / `CheckAfterTouch` / `CheckGoals`** - three small near-misses
   that together would move `match/ball-physics.md` from MEDIUM to HIGH.

### Not written at all

`data/save-format.md` and `data/languages.md` remain gaps. Neither is expected to be
difficult - the save format is a solved problem elsewhere (deliberately deprioritized) and
the language catalogue is a large but straightforward CSV. Both are lower priority than
anything above because neither touches how the game *plays*.

---

## How to fill a gap

1. Find the functions. `scripts/outstanding_game.py` shows what is unread;
   `src/recovered/` holds 1,800+ byte-exact bodies, most of which nobody has yet turned into
   prose. **Most remaining gaps can be closed from code we already have** - the
   reconstruction has consistently run ahead of the documentation.
2. Read the body and its callers (`scripts/build_dependency_graph.py`).
3. Write the football, not the assembly. Give the actual numbers.
4. Tag every source honestly. `VERIFIED` only if byte-matched.
5. Add the file to the table above, then run `python scripts/check_docs.py`.
