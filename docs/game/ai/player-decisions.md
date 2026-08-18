# What a CPU player decides to do

> **Source:** `TPlayer.UpdateJoyAI` @ 0x004f1d08 (VERIFIED) · `TPlayer.DoKickingAI` @ 0x004f22d6 (READ) · `TPlayer.ForceControlCPU` @ 0x004f1491 (READ) · `TPlayer.ShootAI` @ 0x004f28a1 (VERIFIED) · `TPlayer.PassAI` @ 0x004f2c2b (VERIFIED) · `TPlayer.UpdateMovement` @ 0x004f0468 (VERIFIED) · `TPlayer.UpdatePassPotential` @ 0x004efb83 (VERIFIED) · `TPlayer.UpdateTeamMateId` @ 0x004ef516 (VERIFIED) · `TPlayer.UpdateTeamMateId_CPU` @ 0x004ef8f8 (VERIFIED) · `TPlayer.BackPass` @ 0x004f44c8 (VERIFIED) · `TPlayer.CleanThrough` @ 0x004f5510 (VERIFIED) · `TPlayer.KeeperHoldingBall` @ 0x004fcab6 (VERIFIED) · `TPlayer.GetShootingDirection` @ 0x004fadcb (VERIFIED) · `TPlayer.GetDistanceToByLine` @ 0x004fb1c0 (VERIFIED) · `TPlayer.DoTacklingAI` @ 0x004f2ca9 (VERIFIED) · `TPlayer.DoHeadingAI` @ 0x004f20e2 (VERIFIED) · `TPlayer.DoKeeperDiveAI` @ 0x004f3592 (VERIFIED) · `TPlayer.PlayerDiving` @ 0x004fca47 (VERIFIED) · `TJoy.Clear` @ 0x004da665 (VERIFIED) · `TTeam.GetSetPieceTakers` @ 0x004e0c0c (VERIFIED) · `TEngine.SetUpSetPiece` @ 0x004d2f01 (READ)
> **Confidence:** MEDIUM
> **Last checked:** 2026-08-15

This is the contract a replacement AI has to satisfy. It covers every non-human player on
the pitch, every tick: what it looks at, what it writes, and in what order it decides.

## The one fact that matters most

**Every player except the single one a human is puppeting is 100% run by this code, every
tick, with no exceptions.** `TPlayer.ForceControlCPU` is a `Boolean`-returning method
(`1`/`0`) called once per player per movement update; for any player whose `controller`
field (`TPlayer` +0x18) is not `1`, it returns `1` unconditionally in its very first
branch. There is no difficulty setting, no "assist level", no partial hand-off - a CPU
player's movement is always computed by this AI. The only player who ever runs on live
input is the one the save file marks `controller = 1` (set once, in `TTeam.NewLocalPlayer`
@ 0x004de470, when the human's created character joins the squad), and even that player is
frequently and deliberately overridden - see below.

## The pipeline, once per player per tick

```
UpdateMovement()                  <- physics tick, runs for every player
  |
  +-- ForceControlCPU()  -----------> TRUE: steer toward (desx,desy) instead of the
  |                                          real joystick (movement only)
  |
UpdateJoyAI()                     <- separate call; the actual "AI brain" for one tick
  |
  +-- aim the virtual joystick (direction, force, axis_x/axis_y)
  |
  +-- pick AT MOST ONE sub-behaviour, in priority order:
        1. DoCelebrations()   -- goal scored / shootout win-and-ball-dead
        2. (if goalkeeper) DoKickingAI() if in possession, else DoKeeperDiveAI()
        3. DoHeadingAI()      -- loose ball, good jump spot
        4. DoKickingAI()      -- in possession (outfield)
        5. DoTacklingAI()     -- opponent has the ball
             |
             +-- DoKickingAI() ends in exactly one of:
                   ShootAI()  -- writes kick direction/power, arms the kick button
                   PassAI()   -- may be a complete no-op, see below
```

`desx`/`desy` (`TPlayer` +0x7c/+0x80, the player's target position this tick) are **read**
by `UpdateJoyAI`/`ForceControlCPU`/`UpdateMovement`, not computed by them. Something else - 
almost certainly `TTeam.UpdatePlayerDestinations`, itself an open gap (`docs/game/ai/`
team-shape) - decides *where* a player wants to be. This document is entirely about what a
player does once it already knows where it wants to be and whether it has the ball.

---

## `TPlayer.UpdateJoyAI` - the per-tick dispatcher

VERIFIED, 986 bytes, called once per non-human-steered player per tick (vtable slot 0x90).

**Inputs read:** `TEngine.SetPiece()` (is a dead ball live right now); the global
`g_player_int01` (`Int` @ 0x00C5B1FC, the match/situation code - see the table below);
`Self.x`/`y`, `Self.desx`/`desy`; `Self.directiontogoal_opp`; `Self.PlayerDiving()` /
`Self.PlayerSliding()`; `Self.selectionno` (this player's shirt-number slot - `0` is
**verified** to mean goalkeeper, since `TPlayer.KeeperHoldingBall` refuses outright unless
`selectionno <= 0`; `< 11` means "in the current XI", `>= 11` means substituted off or
never selected); `Self.jumpspotgood`; `Self.teamid`; the ball global `g_match_ball` (its
`active` flag and `controlledby:TPlayer`); a second ball-typed global `g_engine_tball`
(only its `active` flag is read, in one place - not proven to be the same instance as
`g_match_ball`); the pitch constant `g_player_int17` (half the pitch's goal-to-goal
length, in the engine's internal units) multiplied by `GetShootingDirection()`; and
`TPitch.YardsToPixels(1.0)`.

**Outputs written:** `Self.joy.direction`, `Self.joy.force` (always exactly `0.0` or
`1.0` - this AI never throttles, it is full-speed-or-stationary), `Self.joy.axis_x` =
`Cos(direction)*force`, `Self.joy.axis_y` = `Sin(direction)*force`; `Self.desx`/`desy` are
overwritten (not just read) when the player is mid-dive or mid-slide-tackle; and a call
into **at most one** of the five sub-behaviours below.

**Decision order** (first match wins; `TJoy.Clear()` runs first and zeroes `axis_x`,
`axis_y`, `force`, `kickbuttondown` and `kickbuttonhits` - so an idle tick really is idle,
nothing carries over from the previous frame):

1. **Aim the stick.** If `TEngine.SetPiece()` is true, direction comes from a `Select` on
   `g_player_int01` (situation codes `2`/`3` face the player's own goal-line;
   `4`/`5`/`6`/`7`/`9` face `directiontogoal_opp`) and `force = 1.0`. Codes outside that
   list leave direction at whatever `Clear()` left it. Otherwise (open play): if diving or
   sliding, `desy` is snapped to the byline in the player's attacking direction first;
   then `direction = AngleTo(x, y, desx, desy)`, and `force = 1.0` only if the distance to
   `(desx,desy)` exceeds one yard (`TPitch.YardsToPixels(1.0)`) - inside that one-yard
   radius the player simply stops.
2. **Gate check.** The rest only runs if `g_match_ball <> Null` AND not diving AND not
   sliding AND `selectionno < 11`.
3. **Celebration.** `g_player_int01 = 8`, or (`= 11` AND the ball is not active) →
   `DoCelebrations()`. Stop.
4. **Goalkeeper branch** (only reached when `selectionno = 0`): if `g_match_ball.controlledby
   = Self` → `DoKickingAI()`, stop. Else if `Self.BackPass() = 0` → `DoKeeperDiveAI()`, stop.
5. **Loose ball, good jump.** `g_match_ball.controlledby = Null` AND `Self.jumpspotgood` →
   `DoHeadingAI()`. Stop.
6. **In possession (outfield).** `g_match_ball.controlledby = Self` → `DoKickingAI()`. Stop.
7. **Opponent in possession.** `g_match_ball.controlledby <> Null` and that player's
   `teamid <> Self.teamid` → `DoTacklingAI()`. Stop.
8. Otherwise: nothing. The aim vector from step 1 is the only effect this tick.

The `g_player_int01` situation code is the single most important piece of shared state in
this whole system - it is read by all three named functions plus `ShootAI`,
`UpdatePassPotential` and `TTeam.GetSetPieceTakers`. Its exact enum is the domain of the
set-pieces gap (`TEngine.SetUpSetPiece` @ 0x004d2f01, READ at CONFIDENCE=NONE - genuinely
not resolved well enough to cite specific numbers from). What is corroborated across
several verified bodies: `0` = normal open play, `10` = penalty shootout in progress
(`TEngine.SetUpMatch`/`DoShootOut`), and the values `2`-`9` are set-piece situation codes
(corner, free kick, throw-in, goal kick, penalty) whose individual mapping is not yet
pinned down - do not guess which number is which restart.

---

## `TPlayer.ForceControlCPU` - who is actually driving right now

READ (Ghidra decompile, symbol/global resolution CONFIDENCE=HIGH, 15/15 calls resolved, 0
rejected - well understood, just not byte-matched). Called from `TPlayer.UpdateMovement`
(VERIFIED) as `If Self.ForceControlCPU() Then ...`. **Its return value only replaces the
steering inputs `dir`/`force` for that tick's physics update - it has no effect on
kicking.** Whether a player shoots, passes or tackles is decided entirely by
`DoKickingAI`/`DoTacklingAI`/`DoHeadingAI` regardless of this function's answer. This
matters for a replacement model: "forced CPU control" here means *the game is walking you
around*, not *the game is playing for you* - the human keeps the kick button live even
while their feet are being steered by the AI.

When `UpdateMovement` sees `ForceControlCPU() = True`, it overwrites the tick's direction
and force with: `dir = AngleTo(x, y, desx, desy)`, `force = 1.0 - 3.0/Dist2D(x, y, desx,
desy)` (so force rises toward `1.0` the farther the player is from its target and can go
negative up close - the caller clamps effective movement to `force > 0.2` later, so this
silently produces a dead zone near the destination rather than reverse movement).

**Inputs:** `Self.controller`; `Self.matchstats.reds` (red cards); `Self.selectionno`;
`TEngine.SetPiece()`; the ball global and its `setpiecetaker` (`TBall` +0x80),
`teaminpossession` (+0x60), `controlledby` (+0x70), `lastkickedby` (+0x74), `passtoid`
(+0x9c), `kicktime` (+0x64), `jumpx`/`jumpy` (+0x38/+0x3c), `x`/`y` (+0x18/+0x1c);
`g_player_int01`; a 500ms-window pair of globals (`g_player_int50` = the running match
clock in milliseconds, `g_player_int51` = the timestamp CPU control was last forced);
`Self.PlayerOnFeet()`; `Self.distanceto­ball`; `Self.joy.kickbuttondown` /
`kickbuttonhits`; `Self.GetMyTeam()`.

**Output:** a single `Int`, `1` (force CPU steering) or `0` (leave the real input alone).
As a side effect on two paths it also calls `Self.Call(x, y, receiver)` (`TPlayer.Call` @
0x004f74c4, VERIFIED but not detailed here - it is the "shout for the ball" action) and
updates `g_player_int51`.

### Every CPU player, always

`Self.controller <> 1` → return `1`. No further checks. This is the entire function for
every player except the one human.

### The human-controlled player

Checked in this order (first `return 1` wins):

| Situation | Condition | Forces CPU? |
|---|---|---|
| Sent off / not selected | `matchstats.reds > 0` OR `selectionno > 10` | Always |
| Match state `0` | `g_player_int01 = 0` | Always |
| Taking this set piece | `SetPiece()` AND `ball.setpiecetaker = Self` | **Always** - see note below |
| Situation `2` | (not the taker) | Always |
| Situation `4` | the set-piece taker (whoever it is) is the goalkeeper (`selectionno = 0`) | If true |
| Situation `5` | an opponent has general possession (`teaminpossession <> teamid`) AND is within an unresolved short distance of `Self` | If true |
| Situation `6` | `Abs(y)` exceeds a pitch-geometry constant (`g_pitch_int11`, value not confirmed) minus 50 raw units, OR less than 500ms since CPU was last forced | If either |
| Situation `7` | - | Always |
| Situation `8` | `Self` is not the global "featured player" (`g_player_tplayer01` - role not confirmed, plausibly the camera's focus during a celebration) | If true |
| Situation `9`, `10`, `11` | - | Always |
| Not on feet | `PlayerOnFeet() = 0` | **Never** (returns 0 - the human keeps input even while falling/getting up, for whatever that's worth) |
| Opponent has the ball nearby | ball controlled by someone else, and (in training, the human without the ball is explicitly exempt) `distancetoball` under an unresolved threshold, OR within 500ms of the last force | If true |
| Ball was passed to you | `ball.passtoid = Self.id` AND `GetMyTeam().newstarselno = 0` | If true |
| Holding the kick button without the ball | `joy.kickbuttondown <> 0` AND not in possession AND `g_player_int01 = 1` AND held over 100ms | Always - also fires `Self.Call()` (shout for the ball) at the ball's position (or its predicted landing spot if airborne) |
| Goalkeeper just cleared it | `selectionno = 0` AND `ball.passtoid = 0` AND `ball.lastkickedby = Self` AND still inside a short recovery window (`g_ball_float14`, value not confirmed) | If true |
| None of the above | - | Never - real input stands |

Two genuine 500ms "sticky" windows appear (situation `6`, and the nearby-opponent-ball
case): once forced, control stays forced for at least half a second even if the triggering
condition stops being true a frame later. A reimplementation that re-evaluates every frame
independently will make control flicker where the original does not.

---

## `TPlayer.DoKickingAI` - what to do with the ball

READ (CONFIDENCE=HIGH annotation, 47/47 calls resolved, 0 rejected). Only ever reached
with `g_match_ball.controlledby = Self` (both call sites in `UpdateJoyAI` gate on that).
Resets `Self.kickpower = 0` unconditionally on entry, so an untriggered tick is a real
no-op, not a stale value.

There are **two entirely separate decision trees**, selected by `g_training_int03` - a
plain match and a training minigame do not share logic at all.

### Match mode (`g_training_int03 = 0`)

**If this player is the designated set-piece taker** (`TEngine.SetPiece()` AND
`ball.setpiecetaker = Self`), the choice is a straight lookup on `g_player_int01`:

| Situation code | Decision |
|---:|---|
| 2 | Always pass |
| 3 | 1-in-10 chance to shoot, otherwise pass |
| 4, distance to opponent goal 35-60 yd | 1-in-10 chance to shoot, otherwise pass |
| 4, distance outside 35-60 yd | 50/50 shoot or pass |
| 5 | 50/50 shoot or pass |
| 6, 7, 9 | Always shoot |

**Otherwise (open play).** First, if the goalkeeper is holding the ball and less than 2500ms
(`0x9c4`) have passed since the catch, nothing happens - the keeper is still holding.  Past
that window, in order:

| # | Condition | Result |
|---|---|---|
| 1 | Distance to own goal < 20 yd | Shoot (clear it) |
| 2 | Distance to own goal 20-35 yd AND nearest opponent within 10 yd | Shoot (panic clearance) |
| 3 | Inside the cross zone (`TPitch.InsideCrossZone`) AND (within 4 yd of the touchline, OR within 3 yd of the byline (`GetDistanceToByLine(1)`), OR an opponent within 10 yd) | Shoot - this **is** the cross; it logs `"ComCross"` but calls the same `ShootAI()` as an actual shot. There is no separate crossing method. |
| 4 | `CleanThrough()` (no defender goal-side of this player by more than 2 yd) AND distance to opponent goal < 18 yd | Shoot |
| 5 | Distance to opponent goal < 22.5 yd | Shoot |
| 6 | Distance to opponent goal 22.5-40 yd AND the opposing keeper is more than 8 yd off his own goal line | Shoot |
| 7 | Distance to opponent goal 22.5-40 yd, keeper close to his line | Pass |
| 8 | Distance to opponent goal ≥ 40 yd, **unless** distance < 35 yd AND the current match minute is an exact multiple of 4 | Pass |
| 8b | Distance to opponent goal < 35 yd AND match minute is a multiple of 4 | Shoot |

Row 8/8b is a genuine, verified-elsewhere oddity: `g_engine_int20` is the **match minute**
(confirmed by `TEngine.DoHalfEnds`, which sets it to 45/90/105/120 at period boundaries,
and by `TPlayer.AddStat`'s comment that it is "the match minute stamped into every stat
row"). This branch is gated on `minute mod 4 = 0`, i.e. only on minutes 0, 4, 8, 12, ...
Three minutes out of four, a player 22.5-35 yards out defers to the keeper-position check
(row 6/7); on the fourth minute, the same distance band shoots regardless of where the
keeper is standing. This is not a tick counter or a random roll - it is literally the
game clock's minute value used as a modulus gate.

### Training mode (`g_training_int03 <> 0`)

A much smaller tree, keyed on `selectionno` and the specific training exercise:

* `selectionno < 1` (goalkeeper): if holding the ball and at least 500ms have passed since
  the catch, release it (arm the kick button, no direction/power decision here).
* Exercise `9` (shooting practice): always `ShootAI()`.
* Anything else: always `PassAI()`.

---

## The terminal actions

### `TPlayer.ShootAI` (VERIFIED, 906 bytes)

Always sets `joy.direction`, `kickpower`, then copies direction into `kickdirection` and
arms the kick (`kickbuttonhits = 1`, `kickbuttondown = 0`). Baseline (open play, no special
case below applies): `direction = directiontogoal_opp + Rnd(-15°, 15°)`, `kickpower =
distancetogoal_opp / 5.0`. Overridden by, in order:

| Situation | Direction | Power |
|---|---|---|
| `g_player_int01 = 7` or `9` | `directiontogoal_opp + Rnd(-28°, 28°)` | `Rand(15, 35)` |
| `g_player_int01 = 5` | aimed at the goal centre (adjusted by `g_player_int19`) `+ Rnd(-5°, 5°)` | `Rand(55, 70)` |
| Inside the cross zone | aimed at the goal centre | `Rand(45, 50)` |
| `g_player_int01 = 1` AND near the corner (`Abs(x) > pitch-half-width+35` AND `GetDistanceToByLine(1) < 45`) | aimed across goal (`(pitchHalfLength - 65) * shootingDirection`) | unchanged |
| `g_player_int01 = 1`, not in that corner, distance to goal < 16 yd | baseline direction | `Rand(15, 40)` |
| `g_player_int01 = 1`, not in that corner, distance to goal < 6 yd | aimed straight at `directiontogoal_opp` | as above |

### `TPlayer.PassAI` (VERIFIED, 126 bytes)

Looks up the teammate id already chosen elsewhere (`Self.teammateid`, set every tick by
`TPlayer.UpdateTeamMateId` → `UpdateTeamMateId_CPU` for a CPU player: the teammate on the
same side, selected and on the pitch, with the **highest `passpotential`**). The pass is
only actually made **if that teammate's `passpotential` is strictly greater than this
player's own `passpotential`** - otherwise `PassAI()` writes nothing at all and the tick
passes with the ball still glued to `Self` (see Quirks).

`passpotential` (`TPlayer.UpdatePassPotential`, VERIFIED, 2277 bytes, recomputed every
tick for every player) starts at `1` and is nudged by roughly two dozen situational
`+1`/`-1`/`+2`/`-2`/`-3` adjustments: further from goal is worth less (`+3` inside 20 yd,
`+2` inside 40 yd, `+1` inside 60 yd, `0` beyond); a clean run at goal is `+1`; being
offside zeroes it outright (unless it is kick-off); not being in a passing lane
(`passison = 0`) is `-1`; pinned against the touchline (`Abs(x) > halfwidth-15`) is `-1`,
and pinned in the far corner is a further `-2`; a human "New Star" player being actively
called for by a high-relationship teammate adds `+1`/`+2`. It is the whole targeting layer
behind "who does the CPU pass to" and deserves its own document if that decision needs
tuning in isolation.

---

## Supporting inputs, briefly

* **`TPlayer.BackPass`** (VERIFIED) has an inverted return convention worth flagging on its
  own: it returns `1` (skip goalkeeper-dive handling) both when a teammate has genuinely
  played the ball back to the keeper, *and* when the "keeper" isn't currently in their own
  penalty box; it returns `0` - meaning "yes, run real keeper AI" - only in the narrow
  remaining case.
* **`TPlayer.CleanThrough`** (VERIFIED) scans every player in the match (not just this
  team) for an opposing outfield player goal-side of this one by more than 2 yards; finding
  none means a clean run at goal.
* **`TPlayer.KeeperHoldingBall`** (VERIFIED) is the function that proves `selectionno = 0`
  is the goalkeeper slot: it refuses immediately for any `selectionno > 0`.
* **`TPlayer.GetShootingDirection`** (VERIFIED) returns `+1`/`-1` for which end of the
  pitch a team is attacking, looked up from home/away identity crossed with the current
  match period (`g_engine_int18`, 1-4) - it flips at half-time and again in extra time.
* **`TPlayer.DoTacklingAI`** (VERIFIED, 302 bytes), **`DoHeadingAI`** (VERIFIED, 500
  bytes) and **`DoKeeperDiveAI`** (VERIFIED, 2962 bytes) are the other three sub-behaviours
  `UpdateJoyAI` can call. All three are read in full for this document's call-graph but not
  exhaustively documented here - full tackle/foul consequences belong to the
  fouls-and-cards gap and full save/dive geometry belongs to the goalkeeper gap. The one-line
  version of each: tackling arms the kick button (a "go for it" trigger, not the foul
  outcome itself) when within 2.5 yd of the ball-carrier and the angle between the
  carrier's direction and this player's is more than 115° (155° inside the defending
  penalty box) and this player's speed exceeds 1.0; heading backs off when the ball is
  already headed toward the player's own goal at a shallow angle, and otherwise arms the
  header when close to an opponent, close to either goal, or the ball is high and close;
  keeper-diving predicts the ball's flight against the goal mouth and picks catch-low /
  catch-high / jump / full dive from where the predicted path crosses a line drawn between
  the keeper's shoulders, with a separate, input-driven branch for penalty shoot-outs.

---

## What it means in play

A CPU-controlled outfield player in possession inside 22.5 yards of goal **always** shoots
 - there is no pass consideration at all once inside that radius, regardless of teammates in
better positions. Between about 22.5 and 40 yards it becomes conditional on the *opposing*
keeper's positioning (shoot if he is caught off his line by more than 8 yards), except on
one match-minute in four where it shoots anyway. Beyond 40 yards it passes. A cross is
mechanically identical to a long-range shot on goal - same method, same "arm the kick
button" side effect - the only visible difference is which zone triggered it and a debug
log line. A pass only actually happens if the AI's own idea of a better-placed teammate
exists; if nobody currently scores higher on `passpotential` than the player on the ball,
"decided to pass" quietly does nothing and the player keeps carrying (typically resolved a
tick or two later by `DoDribbling`, a distinct method not covered here).

For the human's own player, "control" is much more conditional than it looks: taking your
own corner or free kick still walks your feet under AI control (only the kick button is
truly yours), a player getting called for a pass gets auto-steered toward the return ball,
and even ordinary open play can hand movement to the AI for a sticky half-second window
around a nearby loose ball. A replacement model aimed at *only* the CPU opponents can
mostly ignore `ForceControlCPU`; a replacement aimed at making the human's assist feel
right cannot.

---

## What we do not know yet

* **The full `g_player_int01` enum.** Which integer is a corner vs. a free kick vs. a
  throw-in vs. a goal kick vs. kick-off is not pinned down. `TEngine.SetUpSetPiece` @
  0x004d2f01 is the function that would answer it, but its current decompile annotation is
  CONFIDENCE=NONE (unresolved symbols throughout) - it needs a proper annotation pass, or
  byte-verification, before its numbers can be trusted. This blocks a precise reading of
  several `DoKickingAI`/`ForceControlCPU`/`ShootAI` branches keyed on that code.
* **Two numeric literals in `ForceControlCPU`** (the distance threshold in the "situation 5,
  opponent nearby" check, and the one in the "opponent has the ball, how close is close"
  check) are float immediates that Ghidra's decompile does not surface as visible operands.
  The call-site log confirms each is a single-float-argument call to `TPitch.YardsToPixels`,
  but not which yardage. Re-reading the raw disassembly at those two call sites (0x004f1672
  and the second, unlabelled `YardsToPixels()` call later in the body) would resolve them.
* **`g_pitch_int11`** and **`g_ball_float14`**, both referenced in `ForceControlCPU`'s
  timing/geometry checks, are only usage-typed (one write elsewhere each) - their concrete
  values are unconfirmed.
* **`g_player_tplayer01`**, tested in `ForceControlCPU`'s situation-8 branch, is typed
  `TPlayer` from vtable evidence but its role (candidate: "the player the camera follows
  during a celebration") is a guess, not established.
* **Where `desx`/`desy` come from.** Both functions in this document consume a player's
  target position; nothing here computes it. That is `TTeam.UpdatePlayerDestinations`, a
  separate, larger, currently-unrecovered function (see the team-shape gap).
* **What decides `Self.teammateid` for the *human* player** (`TPlayer.UpdateTeamMateId_Human`,
  not read for this document) - only the CPU path (`UpdateTeamMateId_CPU`) was traced here.
* **`TPlayer.Call`** (0x004f74c4, VERIFIED but not opened for this document) is the "shout
  for the ball" action triggered from `ForceControlCPU`; its own targeting/animation
  behaviour is out of scope here.

## Quirks worth preserving exactly

* **`PassAI` can be a complete no-op.** If no teammate's `passpotential` beats the passer's
  own, nothing is written - no kick, no direction change, nothing. A naive reimplementation
  that assumes "decided to pass" always produces a pass will diverge from the original the
  moment there's no better-placed teammate.
* **Crossing is not a separate action.** `ShootAI()` is the method both for shots and for
  crosses; the only distinguishing signal in the original is which guard clause let the
  call happen and a `LogLine("ComCross")` breadcrumb. Do not build a separate `CrossAI` and
  expect it to line up with the original's branch structure.
* **`BackPass()`'s return value is inverted from what its name suggests** - `1` means "skip
  keeper AI", which happens both for genuine back-passes and for a "keeper" who has wandered
  out of the box. Get this backwards and the goalkeeper stops diving for real shots.
* **The `g_engine_int20 Mod 4 = 0` shoot gate uses the real match-clock minute**, not a
  frame or tick counter - confirmed by cross-referencing `TEngine.DoHalfEnds` (which stamps
  this same global to 45/90/105/120) and `TPlayer.AddStat` (which stores it as the match
  minute on every stat row). Reproducing this with a per-frame counter instead of the
  actual minute will change the cadence entirely.
* **Taking your own set piece still surrenders movement to the AI.** It is tempting to
  assume the designated human taker gets free rein to walk into position; the code forces
  `ForceControlCPU() = True` for that exact case. Only the kick button stays live.
  Reimplementing this "the natural way" (skip forcing for the taker) changes the feel of
  every human-taken set piece.
* **Two independent 500ms stickiness windows** exist in `ForceControlCPU` (situation `6`,
  and the nearby-opponent-possession case), each remembered in `g_player_int51`. Evaluate
  the trigger condition fresh every frame without the stored timestamp and control will
  flicker on and off where the original stays locked for half a second.
* **Training mode is a genuinely different decision tree**, not a parameterisation of the
  match tree - `DoKickingAI` branches on `g_training_int03` before anything else. A port
  that tries to reuse the match thresholds (yardage bands, keeper-distance checks) for
  training minigames will misbehave; training only cares about `selectionno` and the
  specific exercise number.
