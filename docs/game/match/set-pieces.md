# Corners, free kicks, penalties and throw-ins

> **Source:** `TEngine.SetUpSetPiece` @ 0x004d2f01 (READ) · `TEngine.SetPiece` @ 0x004d35fd (VERIFIED) ·
> `TEngine.WaitForSetpiece` @ 0x004d3689 (VERIFIED) · `TEngine.UpdateSetPieceReady` @ 0x004d373c (VERIFIED) ·
> `TEngine.GetStringMatchState` @ 0x004d7a8e (VERIFIED) · `TEngine.DoShootOut` @ 0x004d7768 (VERIFIED) ·
> `TEngine.CheckShootOutComplete` @ 0x004d780c (VERIFIED) · `TPlayer.GetShootOutPosition` @ 0x004fa2a3
> (VERIFIED) · `TTeam.GetShootoutPositions` @ 0x004e0954 (VERIFIED) · `TTeam.GetSetPieceTakers` @
> 0x004e0c0c (VERIFIED) · `TTeam.GetWallLocation` @ 0x004e0a62 (VERIFIED) · `TTeam.ResetCornerFormation`
> @ 0x004ddfb2 (VERIFIED) · `TBall.SetUpSetPieceBall` @ 0x004cbb7b (VERIFIED) · `TBall.CheckSideLines` @
> 0x004ca8a4 (VERIFIED) · `TBall.Kick` @ 0x004c91a2 (VERIFIED) · `TPitch.InsidePenaltyBox` @ 0x004e9e5e
> (VERIFIED) · `TPitch.YardsToPixels` @ 0x004e9fdb (VERIFIED) · `TPlayer.CheckOffside` @ 0x004feec4
> (VERIFIED) · `TPlayer.PlayerReady` @ 0x004fabe3 (VERIFIED) · `TDummy.UpdateWallLocations` @ 0x005836d9
> (VERIFIED) · `TTraining.TrainingSetPiece` @ 0x00582ae9 (VERIFIED) · `TEngine.UpdateMatchTime` @
> 0x004d4087 (VERIFIED) · `TEngine.DoHalfEnds` @ 0x004d4334 (VERIFIED) · `TEngine.SkipMatchTime` @
> 0x004d6a80 (VERIFIED)
> **Confidence:** HIGH for the dispatch table, taker-selection weights, wall geometry and the shootout
> rules (all read from byte-identical bodies). MEDIUM for two specific distance thresholds in
> `TTeam.GetSetPieceTakers` (noted inline) where the number is certain but the footballing intent behind
> it is inferred rather than confirmed against play.
> **Last checked:** 2026-08-15

Every dead-ball restart in a played match - kick-off, throw-in, free kick, corner, goal kick, penalty,
and penalty shoot-out - funnels through one function, `TEngine.SetUpSetPiece`. It is the traffic
controller: something else in the engine (the sideline check, an offside call, a foul, a scoreline)
decides that play has stopped and *why*, then hands that reason to `SetUpSetPiece` as a numeric code.
From there the game moves the ball, works out who takes it, and puts up the "Corner" / "Free Kick" /
etc. banner.

`TEngine.SetUpSetPiece` itself is **not byte-matched yet** - the copy in
`src/recovered_unverified/TEngine.SetUpSetPiece.bmx` is 1 byte short of the original (1787 of 1788), with
the gap fully accounted for by register-allocation differences, not missing logic (see that file's header
for the itemised diff). Everything described from it below was read directly off the disassembly, not
guessed from Ghidra's decompile, so it is tagged READ rather than INFERRED - but it has not cleared the
project's byte oracle, and that should be finished before this document's HIGH confidence claims
about its exact branch shapes are trusted at the instruction level. The *behaviour* - which case does
what, in what order, with what numbers - is not in doubt; only the exact register choices are still open.

## What happens, in plain English

### The state machine

The whole match runs on one number, `g_matchstate` (called `g_player_int01` in some of the recovered
files - same global, address `0x00C5B1FC`, spelled differently in different files). `SetUpSetPiece`'s
first argument, `what`, is the new value it writes into that global. `TEngine.GetStringMatchState`
reads the same twelve values back out as debug text, which gives every state a name for free:

| Value | Name (debug string) | Meaning |
|---:|---|---|
| 0 | Tunnel | Not on the pitch yet / between-play holding state |
| 1 | In Play | Ball live, normal play |
| 2 | Centre | Kick-off |
| 3 | Throw-In | |
| 4 | Free Kick | |
| 5 | Corner | |
| 6 | Goal Kick | |
| 7 | Penalty | Penalty awarded in normal play |
| 8 | Goal! | |
| 9 | Shoot-Out | A shoot-out kick is being set up |
| 10 | Shoot-Out Taken | The shoot-out kick has been struck, waiting on the result |
| 11 | Match Over | |

**Quirk worth preserving:** every dispatch in this subsystem (`SetPiece`, `WaitForSetpiece`,
`GetStringMatchState`, and `SetUpSetPiece` itself) tests these twelve values in the same non-numeric
order: `1, 2, 3, 4, 5, 6, 7, 9, 10, 8, 0, 11`. Value 8 ("Goal!") is always tested *after* 9 and 10, out
of numeric sequence. That is not an artefact of decompilation - it is the literal order the source wrote
the `Case` statements in, reproduced identically four separate times, which strongly suggests "Goal!" was
added to the underlying enum after the shoot-out states already existed and was given a numerically
earlier value without the case order being tidied up. Reproduce the case order exactly if
reimplementing a `Select` here; a `Select` evaluates every `Case` compare back-to-back before any body
runs (confirmed from the raw compare chains, not inferred), so getting the order right only matters for
matching the bytes, not the behaviour - but it is a fact about the original worth keeping on record.

### Setting up a restart

`SetUpSetPiece(what, side, x, y)` runs (roughly) as follows:

1. **Training-mode override.** In training (`g_training_int03 <> 0`), the side is forced to 1 (the
   human) and the actual restart type/position come from `TTraining.GetMatchState` instead of the
   caller's arguments. If that says "state 1" (normal play), the function just sets `g_matchstate = 1`
   and returns - no restart is staged.
2. **Shoot-out short-circuit.** If the match is already in a shoot-out (`g_matchstate = 10`, "Shoot-Out
   Taken"), the whistle/goal-net sound plays and the function hands off entirely to `TEngine.DoShootOut`
   (see below) - none of the normal restart logic below runs.
3. **Whistle.** Otherwise, if this isn't the very first restart of the match and it isn't training mode,
   the referee's whistle sound plays.
4. **Team lookup.** `side` (1 = home, 2 = away) picks `g_hometeam` or `g_awayteam` as the acting team.
5. **Per-restart-type work** (see the table below) - this decides the ball's placement (`px`, `py`), puts
   up the on-screen banner text, and for some types runs extra logic (auto-converting a boxed free kick
   into a penalty, resetting the corner-run formation, bumping per-restart counters).
6. **Common tail.** A new ball is created at `(px, py)`, `TBall.SetUpSetPieceBall` clamps it inside the
   pitch and resets its controller, `TTeam.GetSetPieceTakers` picks who takes it, every player's kick and
   offside state is reset, and - in training only - the message queue is cleared and every player is
   snapped straight back to position.

### The restart types

| `what` | Banner shown | Ball placement | Extra behaviour |
|---:|---|---|---|
| 3 Throw-In | "Throw In" | `x = ±halfwidth` (whichever side the ball went out), `y = ball's own y` (exact spot) | `team.CheckComManagement()` runs first |
| 4 Free Kick | "Free Kick" (suppressed if a message is already showing) | Exactly the `(x, y)` the caller supplied - the only restart type that keeps the caller's coordinates unchanged | **Auto-converts to a penalty** if the spot is inside the box (see below); increments a per-side free-kick counter |
| 5 Corner | "Corner", shown **1.5×** as long as other banners | `x = ±(halfwidth + 6)` (corner flag side), `y = (halfheight − 3) × shooting direction` (near-post-side corner) | Resets **both** teams' corner-run formation; increments a per-side corner counter; plays no extra sound |
| 6 Goal Kick | "Goal Kick" | `x = ±g_engine_int103` (an inferred pitch-edge constant), `y` = 5.5 yards in front of the goal line on the defending side | If the ball was already central-ish (`|x| < 0.75 × g_engine_int103`) the goal-kick whistle sound plays |
| 7 Penalty (open play) | "Penalty!" | `x = 0` (dead centre), `y = g_player_int19 × direction` (the penalty spot) | Increments a per-side penalty counter |
| 9 Shoot-Out kick | "Penalties" (shown only on the very first kick of the shoot-out) | Same spot as a normal penalty | See the shoot-out section |
| 1, 2, 8, 0, 10, 11 | - | - | Empty `Case` - `SetUpSetPiece` does nothing extra for these; the state change and common tail still run |

*Note on 6's position formula: it is written as two separate statements
(`py = halfheight × −direction` then `py = Int(py + YardsToPixels(5.5) × direction)`), not folded into
one expression. The two forms are mathematically identical; the split is a register-allocation artefact
of the original compiler, not a behavioural difference - but it is exactly what the original bytes do,
so a reimplementation aiming for the same object code should keep it split.*

**The free-kick-in-the-box rule.** After a free kick's position is set, `TPitch.InsidePenaltyBox(px, py,
team.GetShootingDirection())` is checked. If the spot is inside the box the awarded team is attacking
into, `SetUpSetPiece` immediately calls itself again with `what = 7` (Penalty) at the *same* side and
returns - the "Free Kick" banner never appears, only "Penalty!" does. **This check is skipped entirely
in training mode** (`If g_training_int03 = 0 Then inbox = ...`), so free kicks awarded inside the box
during training stay free kicks.

`TPitch.InsidePenaltyBox(x, y, direction)` itself (the box test): `x` must be within
`±g_engine_int103` of the centre, `y` must be within `±g_player_int17`, and `y` must be outside
`±g_pitch_int11` (i.e. not still in the middle third of the pitch) - that's the box as a rectangle
built from three engine constants (their exact yard values were not re-derived in this pass; see
`docs/specs/04-match-engine-physics.md` for the general pitch-dimension table). Then a `direction`
argument of `-1` requires `y < 0`, `+1` requires `y > 0`, and `0` accepts either side.

### Where a restart actually comes from

`SetUpSetPiece` is only ever told *what* to set up; the *why* lives elsewhere. Two concrete examples
recovered in full:

* **Ball out of play** - `TBall.CheckSideLines` runs every tick the ball is live. Crossing a touchline
  (`|x| > halfwidth + margin`) calls `SetUpSetPiece(3, ...)` (throw-in) at the team **not** last touching
  the ball. Crossing a goal-line (`|y| > halfheight + margin`) calls either `SetUpSetPiece(6, ...)`
  (goal kick) or `SetUpSetPiece(5, ...)` (corner), chosen by comparing which end the *defending* team is
  shooting toward against which end the ball went out at.
* **Offside** - `TPlayer.CheckOffside` calls `SetUpSetPiece(4, n, Self.posxwhenkicked,
  Self.posywhenkicked)`, where `n` is the *other* side from the flagged player, and the coordinates are
  where **the offside player himself** was standing at the moment the ball was kicked toward him (not
  where the passer was, and not where the ball currently is).

Fouls (`TPlayer.CheckFoul`) and shots that miss and go out (goal-line events routed through goal-scoring
logic) presumably call the same function with the same shape, but those callers were out of this
document's scope and are unread - see "what we do not know yet" below.

### Who takes it

`TTeam.GetSetPieceTakers(what, ball)` assigns `ball.setpiecetaker` (and sometimes a `setpiecebuddy`, the
second free-kick/corner option for a short pass). It dispatches on the same restart-type code:

| `what` | Taker chosen |
|---:|---|
| 3 Throw-In | Nearest squad player to the ball (`GetPlayerNearestToXY`); buddy = second-nearest |
| 4 Free Kick | See "the free-kick decision" below |
| 5 Corner | Best passing stat among eligible outfielders, subject to the corners option; possible human override |
| 6 Goal Kick | The team's designated `selectionno = 0` player (the goalkeeper) |
| 7 Penalty (open play) | Best shooting stat among eligible outfielders; human override if the human's `penalties` rating exceeds the club's own penalty-taker strength |
| 9 Shoot-Out | A fixed rotation through the squad's `selectionno` order - see the shoot-out section |
| 0, 1, 2 | Empty - no taker assignment for these codes |

"Eligible" throughout means: not sent off (`matchstats.reds = 0`) and either on the pitch or a valid
substitute slot (`selectionno` between 1 and 10 inclusive; `selectionno = 0` is the goalkeeper and is
excluded from outfield taker scans, `> 10` is the bench).

**The free-kick decision (case 4)** is the most elaborate of the six:

1. If the free kick is inside the *defending* team's own box from the taking team's perspective
   (`InsidePenaltyBox(x, y, -direction)`), the goalkeeper (`selectionno = 0`) takes it immediately - a
   defensive free kick deep in your own box goes straight to the keeper.
2. Otherwise: if the kick is far from goal (`Dist2D(x, y, 0, g_player_int17 × direction) > 45.0` world
   units - **MEDIUM confidence**: the number is exact, 45 world units = 4.5 yards at the confirmed 10
   units/yard scale, but whether this specific comparison point represents "far from goal" or something
   else was not independently confirmed against actual play) **or** a coin flip (`Rand(2,1) = 1`, 50%),
   the nearest player to the ball takes it - a quick, no-fuss restart.
3. Otherwise the game scans the squad for the best `passing` stat, applying the free-kick-taker option
   (see the option table below) to optionally exclude or de-weight the newstar (human) player from that
   scan, then gives the human player an independent chance to grab the kick anyway if he isn't already
   the pick (option-dependent probability, see below).
4. On a `g_engine_int20 Mod 2 = 1` tick parity, a buddy (short-pass option) is also assigned.

**The corner decision (case 5)** is the same shape as step 3 above but scores on `passing` and uses the
corners option instead of the free-kick option; a buddy is assigned on `g_engine_int20 Mod 4 = 1` (a
quarter of the time, half as often as free kicks).

**The taker-preference options** (`Engine → free kicks` and `Engine → corners` in the in-game menu,
`TScreen_Options.ButtonCorners` for the corner one) store `-1` / `0` / `1` for Never / Sometimes /
Always wanting the human to take these restarts:

| Option value | Meaning | Effect in the best-stat scan | Effect in the human-override roll |
|---:|---|---|---|
| −1 (Never) | Human excluded from consideration | Skipped outright | No override roll at all |
| 0 (Sometimes) | 50/50 whether the human is even considered for the scan | `Rand(2,1)=1` → skipped from the scan | 20% chance (`Rand(5,1)=1`) the human takes it anyway |
| 1 (Always) | Human always eligible for the scan | Never skipped | 25% chance (`Rand(4,1)=1`), **or automatically** if the human is club captain, **or automatically** if the human's relevant stat (`freekicks`/`corners`) exceeds his club's own designated taker's overall `strength` |

*`Rand(a, b)` returns a whole number between `a` and `b` inclusive; the game writes it with the larger
number first (`Rand(4,1)` not `Rand(1,4)`) but the result is the same 1-in-4 chance either way.*

**Penalties (case 7)** use the same best-`shooting`-stat scan with no coin-flip skip step, and the human
override is unconditional on `penalties > myclub.strength` - no random roll, no captain clause. If the
human out-rates the club's own penalty taker, he takes every penalty.

### The wall

`TTeam.GetWallLocation(slot, ballX, ballY, outX, outY)` places up to five defending players in a fan
in front of the ball, standing **10.2 yards** away (`TPitch.YardsToPixels(10.2)`), at angles offset from
the direct ball-to-goal line by `0°, +5°, −5°, +10°, −10°` degrees for wall slots 5 down to 1
respectively (so the fifth player added stands dead centre, and the wall grows outward two at a time).
Training mode has its own, near-identical function for the practice-ground mannequins
(`TDummy.UpdateWallLocations`) using the same five-slot fan pattern but standing **10.5 yards** back
instead of 10.2.

### Corner run formation

`TTeam.ResetCornerFormation` runs for **both** teams whenever a corner is set up. It clears the previous
run pattern and generates a fresh one: `Rand(4, 5)` runners (i.e. 4 or 5, chosen at random each corner),
each placed at a random point `TPitch.YardsToPixels(Rand(-12, 12))` sideways and
`(goal-line-y − TPitch.YardsToPixels(Rand(8, 18))) × shooting direction` upfield - i.e. a scatter of
attacking runs anywhere from 8 to 18 yards out and up to 12 yards either side of the goalmouth, freshly
randomised on every single corner (not reused from the previous one).

### Waiting for the restart to actually happen

Three small functions gate the on-screen "power meter" that has to fill before a restart is actually
taken (`TEngine.UpdateSetPieceReady`, called every tick):

* `TEngine.SetPiece()` - true if `g_matchstate` is any dead-ball code (2, 3, 4, 5, 6, 7, 9); false for
  In Play, Tunnel, Goal!, Shoot-Out Taken, Match Over.
* `TEngine.WaitForSetpiece()` - true (meaning "hold the power meter, don't let the kick happen yet") for
  kick-off (2), corners (5), penalties (7), and shoot-out kicks (9) **always**; for free kicks (4) only
  if a `setpiecebuddy` has actually been assigned to the ball; **false** - no formal wait at all - for
  throw-ins (3) and goal kicks (6).
* `TEngine.UpdateSetPieceReady()` itself: if not currently a set piece, or in training, the meter is
  simply forced full (instant). Otherwise, if `WaitForSetpiece()` said to wait, the meter stays at zero
  until `TPlayer.AllPlayersReady()` (every selected player has reached their assigned position) is true.
  If it's a non-waiting restart, the meter still stalls at zero if: the human (when not a starting
  player) hasn't confirmed ready via `TPlayer.PlayerReady`; the ball isn't yet controlled by the assigned
  taker; or - **except at throw-ins** - any opposing player is within **8 yards**
  (`TPitch.YardsToPixels(8.0)`) of the ball. That 8-yard rule is the game's version of "defenders must
  retreat before the restart can be taken." The moment the meter first reaches ready, kick-off, free
  kick and penalty restarts (2, 4, 7) additionally play the whistle again, and kick-off alone re-shows
  the "Kick Off" banner.

`TPlayer.PlayerReady` (the human's own readiness, used only when he isn't one of the starting eleven,
`selectionno > 10`): ready immediately if he's stood off the left edge of the pitch
(`x < -g_player_int16`); if the CPU has taken control of him (`ForceControlCPU`), ready unless it's a
corner or free kick and the ball isn't yet in his own team's possession and he's still more than 10
yards from the restart spot; otherwise ready once he is within **2.5 yards**
(`TPitch.YardsToPixels(2.5)`) of his assigned position.

## Penalty shoot-outs

A shoot-out is triggered from `TEngine.DoHalfEnds` - if extra time (period 4) ends still level,
`DoHalfEnds` calls `TEngine.DoShootOut()` instead of ending the match. From then on, `DoShootOut` drives
the whole thing, called once at kickoff of the shoot-out and then again after every kick.

### The kick cycle

`DoShootOut()` each time it runs:

1. Calls `TEngine.CheckShootOutComplete()` first. If the shoot-out is already decided (table below),
   plays the final whistle, records the outcome, sets `g_matchstate = 11` (Match Over), and stops.
2. Otherwise increments the shared kick counter (one Int, address `0x00C5B238` - used both as "kicks
   taken so far" in the completion check and, halved, as "whose turn in the rotation" in
   `GetSetPieceTakers`), picks the side by parity (`counter Mod 2`: even → away, odd → home - since the
   counter is incremented *before* the check, **home always takes kick 1**), sets
   `g_matchstate = 9`, and calls `SetUpSetPiece(9, side, 0, 0)` to stage the next kick exactly like an
   open-play penalty (same spot, same "Penalties" banner logic).

Once the kick is actually struck, `TBall.Kick` (the general kicking function, for any kick type) has a
special case: if the match state at the moment of the kick was 9 (Shoot-Out), it flips the state to 10
(Shoot-Out Taken) and stashes the current "who's up" marker. `TEngine.UpdateMatchTime` then watches for
that: while `g_matchstate = 10`, once **2,500 ticks** (2.5 game-seconds at normal speed) have passed
since the state changed, it calls `DoShootOut()` again to check the result and set up the next kick - 
this is the pause after each spot-kick before the game moves on.

### When it ends

`CheckShootOutComplete` checks the counter of **completed kicks** (not yet counting the one about to be
taken) against `TFixture.penscore1` / `penscore2`:

| Kicks completed | Ends the shoot-out when... |
|---:|---|
| 0 - 5 | Never (still inside the guaranteed part of round 1-3) |
| 6 (3 each) | Either side's `penscore` lead is **greater than 2** (i.e. 3-0) |
| 7 (home 4, away 3) | Home leads by more than 2, **or** away already leads by more than 1 |
| 8 (4 each) | Either side's lead is **greater than 1** (i.e. 2 or more) |
| 9 (home 5, away 4) | Home leads by more than 1, **or** away leads by more than 0 (any lead at all) |
| 10 (5 each - the end of the "normal" 5 rounds) | Scores are **not equal** |
| 11+ (sudden death, one extra kick each) | Only re-checked once **both** sides have taken their extra kick that round (odd counts are skipped); ends the moment the scores differ |

This is the standard "the outcome is already certain, stop early" rule real shoot-outs use - the
asymmetric checks at 7 and 9 kicks account for the fact that the two sides don't finish each round at
the same instant (home always kicks first), so the check has to allow for however many replies the
trailing side still has left before declaring it over.

### Positioning during a shoot-out

`TTeam.GetShootoutPositions` walks every eligible squad player (not sent off, `selectionno <= 10`) and
calls `TPlayer.GetShootOutPosition` on each. That function:

* Sends anyone not in the starting XI (`selectionno > 10`) to the tunnel/bench spot.
* Sends the goalkeeper (`selectionno = 0`) to `UpdateKeeperPosition` (normal keeper behaviour).
* If this player is the ball's current `setpiecetaker`, walks him up to a run-up spot just behind the
  ball: `ball.setpiecex/y` plus a **0.5-yard** offset (`YardsToPixels(0.5)`) along his own facing
  direction, adjusted by a fixed 180° angle constant on each axis (i.e. the away side's run-up direction
  is mirrored to face back toward their own goal, since the shoot-out always fires at one fixed net).
* Everyone else in the outfield forms a queue at the centre circle: `x = 5 + selectionno` yards from
  centre, `y = 10` yards back, mirrored to the opposite side of the circle for whichever team does **not**
  own the shoot-out spot (`teamid = g_shootout_team.id` flips the sign).

### Skipped (unplayed) matches: a different, cheaper resolution

If the *player is not watching* the match at all - `TEngine.SkipMatchTime`, the "simulate forward"
function used for matches the human fast-forwards through - reaching a shoot-out does **not** run any of
the above. Instead the result is decided by a single random roll: the winning side's `penscore` is set to
`Rand(2, 5)` (2 to 5, chosen once) and the losing side's `penscore` is set to exactly **one more** than
the winner's - which is backwards (a losing side cannot legitimately have scored *more* penalties), but
that is what the code does. Two separate code paths in `SkipMatchTime` do this (one for a fully
simulated match reaching extra-time-over-still-level, one for a match the player was fast-forwarding
live through that then hits the same state) - both assign the "winner" via
`g_hometeam.controller = 1` in the first path, or a plain coin flip (`Rand(2,1)`) in the second, and both
have the same score-inversion. This function is a different topic (`TEngine.SkipMatchTime` belongs more
to the season-simulation side of the game than to a played match's set pieces) and is flagged here only
because it is the *other* path by which a shoot-out gets decided - worth knowing so nobody is surprised
that penalty scores in an unplayed fixture don't match the shoot-out rules above.

## What it means in play

* **Where the ball goes is fully mechanical, except for free kicks.** Throw-ins snap to the exact
  sideline spot, corners always go to the flag on whichever side the ball left, goal kicks always sit
  5.5 yards out, and penalties are always dead centre on the spot - none of those read the caller's
  supplied coordinates at all. A free kick is the only restart placed at the exact spot of the
  infringement, which is also the reason offside is enforced at the *receiving* player's own position:
  `CheckOffside` hands `SetUpSetPiece` that player's coordinates directly.
* **Any free kick that lands in the box becomes a penalty automatically**, in every mode except training.
  There is no separate "is this a direct free kick that beat the wall in" resolution needed for a
  boxed foul - the conversion happens the instant the restart is staged, before the ball even moves.
* **The human can talk his way onto set pieces**, but the odds are stacked by role: penalties are the
  easiest to seize (any stat edge over the club taker, no dice roll at all), free kicks and corners
  require passing a coin flip or a captaincy/stat check even on "Always," and setting the option to
  "Never" removes him from consideration entirely rather than merely lowering the odds.
* **Corners are never choreographed the same way twice.** With a fresh `Rand(4,5)` run count and fully
  randomised run positions on every single corner, the same team's corner routine looks visibly different
  kick to kick - there is no fixed "corner routine A/B/C" the AI reuses.
* **A shoot-out can end well before ten kicks are taken**, exactly like a real one - a 3-0 lead after
  three rounds each ends it immediately, and the standard reasoning is applied consistently through the
  five-round mark and into sudden death.
* **Watching a shoot-out live and skipping through one are not the same event statistically.** A live
  shoot-out is a sequence of individually resolved kicks with real early-decision logic; a skipped one
  is a single random roll that, by construction, always gives the *loser* the higher `penscore1`/`2`
  value than the winner recorded elsewhere - an inversion nobody watching would ever see, because nobody
  is watching.

## What we do not know yet

* **`TPlayer.CheckFoul`** (unread, per `docs/game/README.md`) is presumably the other major caller of
  `SetUpSetPiece(4, ...)` for ordinary fouls (as opposed to offside). Until it's read, this document
  can't say how a foul's exact free-kick location is chosen, whether advantage is ever played, or whether
  fouls inside the box route through the same `InsidePenaltyBox` conversion this document describes or
  award the penalty directly.
* **The goal-scoring path to `SetUpSetPiece(2, ...)`** (kick-off after a goal) and to state 8 ("Goal!")
  itself were not traced in this pass - `TTeam.GoalScored`/equivalent is listed as a gap in
  `docs/game/README.md` for the shooting-and-scoring document.
* **`TEngine.SetUpSetPiece` is not yet byte-verified.** The candidate in
  `src/recovered_unverified/TEngine.SetUpSetPiece.bmx` is 1 byte short of the original 1,788-byte body,
  with the shortfall attributed to register-allocation choices, not missing statements - but "attributed"
  is not "proven." Finishing that byte match is the single highest-value next step for this document,
  since every numeric claim in the restart-type table ultimately traces back to that one function.
* **`g_engine_int103`, `g_player_int17`, `g_pitch_int11`, `g_player_int19`, `g_wallDist`, and
  `g_engine_int104`** are all Int globals used as pitch-geometry constants throughout this document
  (box half-width, box half-depth, centre-circle-ish exclusion radius, penalty-spot distance, wall
  reference offset, goal-kick x-position) whose exact stored values were not read out of the assembled
  binary's data section in this pass - only their *usage* (comparison direction, which formula they feed)
  is confirmed. Reading their initial values the way `g_engine_int17 = 1750` was established
  for `TEngine.DoHalfEnds` would let this document state the penalty spot, box, and wall distances in
  actual yards rather than only in named constants.
* **The 45.0-world-unit free-kick-taker distance check** (`TTeam.GetSetPieceTakers`, case 4) is read
  correctly off the bytes, but which reference point it measures against and what footballing rule it's
  encoding was not independently confirmed by cross-checking against `g_player_int17`'s actual value - 
  flagged MEDIUM confidence above.
* **Whether `SetUpSetPiece`'s `what = 1` code (the empty case, alongside `0`, `2` non-kickoff, `8`, `10`,
  `11`) is ever actually reached from outside training mode** was not traced; the training-mode branch is
  the only confirmed caller of code 1.

## Implementation details worth preserving exactly

* **The `Select` dispatch order (`1,2,3,4,5,6,7,9,10,8,0,11`) is load-bearing for byte matching** across
  four different functions in this subsystem, and is presumably a fossil of the original enum's
  declaration order (see the state-machine section above) rather than an intentional design choice. Keep
  it if aiming for byte-exact reconstruction; it makes no behavioural difference either way.
* **The free-kick-auto-becomes-penalty recursion is a genuine self-call**, not a shared helper:
  `SetUpSetPiece` calls itself with `what = 7` and returns immediately, so the "Free Kick" banner is
  created and then never actually shown (the function returns before the common tail that would display
  it) - reproducing this as an early return rather than, say, skipping the free-kick message creation in
  the first place, matters if something later in the frame expects that message object to have briefly
  existed.
* **Case 6's Y-offset is written as two statements, not one expression** (see the goal-kick row of the
  restart-type table) - purely a codegen/register-liveness artefact of the original compiler, safe to
  fold into one expression in a from-scratch reimplementation that isn't targeting byte parity.
  Preserve the split only if byte-matching this function is the goal.
* **The skipped-match shoot-out score inversion is an original bug, not a documentation error.** Both
  code paths in `TEngine.SkipMatchTime` assign the *winning* side's `penscore` first via `Rand(2,5)` and
  then set the *losing* side's `penscore` to exactly one **higher** - the losing side ends up with the
  bigger recorded penalty count. Reproduce it faithfully rather than "fixing" the assignment order; any
  code elsewhere that reads `penscore1`/`penscore2` to decide the shoot-out winner for a skipped match
  must already be comparing them the same backwards way, or league results from skipped fixtures would be
  visibly wrong, and they are not reported as such.
* **The kick-counter global (`0x00C5B238`) is shared between three different-sounding roles** - "kicks
  taken" in `DoShootOut`, "attempt counter" in `CheckShootOutComplete`, and "squad-size counter" in
  `GetSetPieceTakers` - three different spellings across recovered-file headers
  for what is the same address and the same running value. Keep it as one Int if reimplementing; splitting
  it into three separate counters would desync the taker rotation from the completion check.
