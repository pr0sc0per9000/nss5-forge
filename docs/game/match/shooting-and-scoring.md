# Shooting, saves and goals

> **Source:** `TBall.Kick` @ 0x004c91a2 (VERIFIED) · `TBall.CheckGoals` @ 0x004ca0cc (READ) · `TEngine.GoalScored` @ 0x004d39d6 (READ) · `TPlayer.CheckKeeperSave` @ 0x004f698f (VERIFIED) · `TPlayer.DoKeeperDiveAI` @ 0x004f3592 (VERIFIED) · `TPlayer.BlockSave` @ 0x004f89ce (VERIFIED) · `TBall.Parry` @ 0x004cb6c5 (VERIFIED) · `TBall.Deflect` @ 0x004cb5ec (VERIFIED) · `TBall.HitPost` @ 0x004cac9b (VERIFIED) · `TPlayer.ShootAI` @ 0x004f28a1 (VERIFIED) · `TPlayer.TapKick` @ 0x004f7528 (VERIFIED) · `TPlayer.HoldKick` @ 0x004f8159 (VERIFIED) · `TPlayer.HoldKickAdvanced` @ 0x004f8487 (VERIFIED) · `TPlayer.HeadBall` @ 0x004f8a6a (VERIFIED) · `TPlayer.HeadBallAdvanced` @ 0x004f8f5d (VERIFIED) · `TPlayer.DiveHeadBall` @ 0x004f9156 (VERIFIED) · `TPlayer.CheckKick` @ 0x004f6c2b (READ) · `TPlayer.TapKickAdvanced` @ 0x004f7c89 (READ) · `TBall.CheckLongShotRating` @ 0x004cd177 (VERIFIED) · `TPlayer.AddStat` @ 0x004ff16a (VERIFIED) · `TPlayer.AddPlayerRating` @ 0x005031ae (VERIFIED) · `TBall.GetStringKickType` @ 0x004cc5e2 (VERIFIED)
> **Confidence:** MEDIUM
> **Last checked:** 2026-08-15

Confidence is MEDIUM, not HIGH, because two of the load-bearing functions are not fully
nailed down: `TBall.CheckGoals` is a near-miss (+8 bytes, two gaps confined to one
`If`-test near the very end - see "What we do not know yet") and `TEngine.GoalScored` /
`TPlayer.TapKickAdvanced` are read from Ghidra's decompilation only, never byte-matched.
Everything else cited above is byte-exact.

## What happens, in plain English

A shot is not one event, it is three separate systems that happen to run in sequence:
**something decides how hard and in which direction to kick** (different code for a
human holding the shoot button, an AI teammate, and a header), **`TBall.Kick` turns that
into a flying ball** and decides, at the instant of the kick, whether the shot counts as
"on target" for stats purposes, and then **every single frame afterwards**,
`TBall.CheckGoals` asks "did the ball's flight path just cross the goal line, hit a
post, or hit the net" - completely independently of what kicked it. A goal is a
*trajectory* event, not a *kick* event: nothing about the kick itself "is" a goal until
the ball's predicted straight-line path for that frame crosses the mouth of the net.

Between the kick and the goal line stands the goalkeeper, who runs a separate predictive
AI (`TPlayer.DoKeeperDiveAI`) that simulates the ball's own physics forward, frame by
frame, to decide whether to commit to a dive before the ball arrives.

### 1. Deciding power and direction

**Human-controlled outfield player.** `TPlayer.CheckKick` watches the shoot button every
frame. While the button is held, `kickpower` climbs by a fixed per-frame amount (a Float
global the reconstruction has not pinned a value for yet - see "What we do not know
yet"). The moment the button state resolves - either it was tapped and released, or
`kickpower` hits **50.0**, or the match is in kickoff state (`g_player_int01 = 2`), which
forces an immediate release - the game picks one of two finishing methods:

> `If Self.kickpower < 15.0 And matchstate <> 7 And matchstate <> 9 Then TapKick() Else HoldKick()`

Under 15.0 power is a **tap** (`TapKick`); 15.0 or over, or during a free-kick/corner
restart (states 7 and 9), is a **hold** (`HoldKick`). `HoldKick` adds random spread to
the kick direction, scaled by the player's `shooting` attribute - a wider `Rand` range
means a *worse* shooter wobbles the shot more. Better `shooting` narrows the cone. When
the player is a "newstar" (the user's created pro) under CPU auto-play, both functions
hand off immediately to an `*Advanced` sibling (`TapKickAdvanced` / `HoldKickAdvanced`)
with slightly different power/direction math, keyed off which of the three joystick
buttons (shoot/pass/lob) is active.

A quick tap does not automatically mean a shot - `TapKick` first has to decide whether
this is even an attempt on goal. It is a Shot only when there is no valid pass target
(no teammate selected, or the AI has decided against a pass) *and* the player is not
standing in the opponent's crossing zone; if both hold, `kickpower` is a flat **30.0**,
bumped to **40.0** with kick type forced to Shoot (`2`) once the player is within 30
yards of goal, or dropped to `distancetogoal_opp * 0.1` with kick type forced to Lob
(`3`) if this player is the designated set-piece taker standing near the ball. Outside
30 yards with no closer trigger, the "Shot" log line fires but the kick actually goes
out as a type-1 **Pass** at that same flat power - the shot logging and the shot
*result* can diverge, which is worth knowing if a reimplementation tries to key
statistics off the log message instead of the resulting kick type.

**AI-controlled player.** `TPlayer.ShootAI` sets `kickpower` and `joy.direction`
directly, with no player-held charge at all:

| Situation | Direction | Power |
|---|---|---|
| Free kick / restart (state 7 or 9) | toward goal ± `Rnd(-28,28)` | `Rand(15,35)` |
| Penalty-style restart (state 5) | at goal, offset by shooting-direction sign, ± `Rnd(-5,5)` | `Rand(55,70)` |
| In the opponent's cross zone | toward goal, offset by shooting-direction sign | `Rand(45,50)` |
| Wide position, near the byline (open play) | angled toward the near post | unchanged |
| Not wide, inside 16 yards of goal (open play) | unchanged | `Rand(15,40)` |
| Not wide, inside 6 yards of goal (open play) | straight at goal | unchanged by this test (may already be `Rand(15,40)` from the 16-yard test above - both are separate `If`s, not `ElseIf`, so a shot inside 6 yards is also inside 16 and gets both) |
| Default (open play) | toward goal ± `Rnd(-15,15)` | `distancetogoal_opp / 5.0` |

**Headers.** `TPlayer.HeadBall` sets a base `kickpower` of `distancetoteammate * 0.06`
and, for the human/CPU-selected player, escalates depending on field position: inside 30
yards of the player's own goal or 18 of the opponent's, power jumps to a flat **50.0**
aimed at goal with `Rand(-20,20)` spread (tighter, `Rand(-10,10)`, inside 8 or 18 yards - 
these are the header-shot cases). `HeadBallAdvanced` (the newstar/auto-play path) instead
reads which of the three joystick buttons is held: **Shoot** sets power to a flat 50.0,
**Pass** to `distancetoteammate * 0.07`, **Lob** to `distancetoteammate * 0.08` - then
both subtract `Rand(0, heading)` from power and jitter direction by
`Rand(-heading, heading)`, so a higher `heading` stat again means a *tighter*, more
reliable header. `TPlayer.DiveHeadBall` is the diving-header special case: fixed power
20.0, direction is the player's own facing plus the angle to the joystick direction,
clamped to **±30°**.

**Goalkeeper clearances.** `TPlayer.BlockSave` (a smothered shot) and the low/high
catches below are not really "shots" but they call the same `TBall.Kick` - a block-save
clearance is a weak `kickpower = 2.0` punt back into play.

### 2. `TBall.Kick` - turning the decision into a flying ball, and grading it

Every kick in the game - pass, shot, lob, or header - funnels through one function,
`TBall.Kick(kicker, direction, power, kicktype, targetPlayerId)`. Kick type is an
integer (`TBall.GetStringKickType` gives the debug names): **1 Pass, 2 Shoot, 3 Lob,
4 Head Pass, 5 Head Shoot, 6 Head Lob.**

Before anything else, a **tired/unhappy mishit check** can override the kick entirely
for a newstar in open play attempting a Shoot or Lob (1-in-5 chance, `Rand(5) = 1`, gated
further by match state and not being in training): if the player's `energy` is under
30.0 and a `Rand(0,40)` roll beats it, the kick becomes a weak sideways stumble (power
halved, direction randomly skewed 20-40°, forced to a Pass, a "tired" screen message);
otherwise if `happiness` loses a `Rand(70)` roll, the same thing happens at a smaller
penalty (power ×0.75, skew 10-30°, "unhappy" message).

**Power is then always bumped by +50.0**, and capped: **100.0** normally, **130.0**
during match state 5 (the penalty-style restart). Per kick type, velocity and
z-velocity (loft) are scaled by module-global multipliers; Shoot type additionally
gets extra lift capped near the box (height clamped to 30% of the keeper's max reach
when within 16 yards) and Lob gets +10% power in the cross zone, +20%/+40% during a
corner (state 6), and half the vertical loft once training mode is off and the kicker
is within 12 yards of goal.

**"On target" is decided at the moment of the kick**, not later: the code only runs
this check outside of set-piece states (8, 11, 9, 10, 0 are excluded via a `Select`).
It measures the angle between the ball's actual flight direction and the straight line
to the opponent's goal (`AngleDiff`), and requires:

* the angle is under **25.0°**, and
* the kicker is within **50 yards** of the opponent's goal.

If both hold, it constructs the goal-mouth line and asks whether the flight path (as a
straight line, at kick-time trajectory, not simulated forward with gravity) intersects
it. If it does: `AddStat(2, direction, distancetogoal_opp, 0, 0)` - stat type 2, "shot
on target" - is logged, `ihadashot` is set on the kicker (used later by
`CheckLongShotRating`), and one of two global on-target counters is bumped
(`g_engine_int29` home / `g_engine_int30` away). This all happens **regardless of
whether a keeper is in the way** - it is a geometry check against the empty goal
frame, so a shot that is later saved still counts as "on target" here.

### 3. Every frame: does the ball cross the line? (`TBall.CheckGoals`)

Independently of who kicked it or why, every active ball runs `CheckGoals` once per
frame. It is a pure geometry function: it takes the ball's position last frame
(`oldx/oldy/oldz`) and this frame (`x/y/z`) and asks `GetInterceptPoint` whether that
one-frame line segment crosses any of several fixed planes:

* **Posts** (both goals, only when the game is in normal play, `g_player_int01` is 1 or
  10): four narrow zones right around each post when the ball is low
  (`z < pitch-goal-height − 2×crossbar-thickness`), two wide zones spanning the whole
  goal mouth when the ball is at mid-height. A hit calls `TBall.HitPost`.
* **Net** (only the goal at the correct end, and only for a ball not already controlled):
  a ball crossing behind the goal line but below crossbar height triggers `TBall.HitNet`,
  with the net panel chosen by which third of the goal width it entered.
* **The goal line itself**, only when `g_player_int01` is 1 or 10 (open play or shootout)
  and only below crossbar height: crossing it calls `TEngine.GoalScored(ball)` and sets
  `ball.ingoal = 1` so the same crossing cannot re-fire next frame.

This is why a shot that is heading in but gets touched, blocked, or the keeper punches
it away is a non-event here - the ball's trajectory simply never crosses the line
segment, so `GoalScored` never fires, no matter what `TBall.Kick`'s on-target check
said at the moment of the kick.

### 4. What happens when a goal is scored (`TEngine.GoalScored`)

* If the game is in training mode, this delegates entirely to `TTraining.GoalScored`
  instead (a separate, undocumented path - out of scope here).
* If the match is in a penalty shootout (state 10): plays the shootout-goal sound,
  works out which team is taking this kick from the kick index's parity, increments
  that team's shootout tally, marks the current round as scored, and hands off to
  `TEngine.DoShootOut()` to continue the sequence.
* Otherwise, in open play: shows the "Goal!" banner, plays the goal sound, and sets
  `g_player_int01 = 8` (the goal-celebration match state - kicks are disabled while this
  state holds, per `TBall.Kick`'s own `Select` on match state). Which team is credited
  is read from **which half of the pitch the ball crossed into** (`ball.y >= 0` or
  `< 0`) combined with a kickoff-side flag (`g_engine_int18`) that tracks which way
  around the two teams are currently facing - the same swap that happens at half time.
* **Stats and credit.** The last player to *touch* the ball (which may differ from the
  last player to *kick* it - a deflection off a defender still counts as a touch) is
  tracked; if the toucher isn't the human-selected player, credit shifts to whoever
  last kicked it instead. If that credited scorer's team actually matches the team
  just awarded the goal (own goals are filtered out of personal credit this way), the
  scorer gets `AddStat(5, direction, distancetogoal, x, y)` - stat type 5, a Goal - and,
  if there's a distinct `assistedby` on the same team, that player gets
  `AddStat(4, angle, distance, kickx, kicky)` - stat type 4, an Assist. Either one
  triggers a green ("Goal!") or purple ("Assist") star-shower particle effect at the
  scorer's/passer's position, but **only if that player is a newstar** (a
  user-controlled career pro) - CPU players never get the celebration effect.

## Goalkeeper saves

There are two entirely separate keeper systems: a **reactive** one for a keeper already
touching the ball, and a **predictive** AI that decides whether to commit to a dive
*before* the ball arrives.

### Reactive: `TPlayer.CheckKeeperSave`

Runs once contact happens. If the ball is already `controlledby` someone else, this is a
smothered shot and just calls `BlockSave` (a weak `kickpower = 2.0` clearance kick, after
knocking any current controller down with a fall animation). Otherwise:

* if the keeper's current animation matches the "catch" animation table, it's a clean
  catch (`NewController` - keeper simply takes the ball);
* else if ball velocity exceeds a threshold Float global, it's parried away
  (`TBall.Parry`);
* else if the ball was struck from close to where the last kicker actually made contact
  (`Dist2D` to `posxwhenkicked/posywhenkicked` under a Yards-scaled threshold) and moving
  at more than half that velocity threshold, it's also parried;
* otherwise, another clean catch.

A crowd "ooh" sound plays separately whenever the keeper is within 18 yards of goal and
the ball is fast or already loose, as long as the shot didn't come from the keeper's own
team.

### Predictive: `TPlayer.DoKeeperDiveAI`

Runs every frame for both AI and (partly) human keepers. It bails out immediately - 
does nothing this frame - if there is no ball, the ball is already in the net, the
keeper isn't on their feet, the keeper kicked the ball themselves less than 300ms ago,
the ball is outside the keeper's own penalty box, the keeper is already holding it, or
the match isn't in open play or a shootout.

**During a shootout (state 10):** this is the actual penalty save minigame. Once the
ball is within 8 yards and hasn't already been touched by this keeper, it rolls a random
dive type (`Rand(1,6)`) and power (`Rnd(0,1)`) - but if the keeper belongs to the
human-controlled team and is the captain, directional input overrides the random pick:
**down → catch high, up → jump, right → dive with `power=1.0`, left → dive with
`power=0.0`.** Type 1 calls `KeeperCatchHigh`, type 2 calls `KeeperJump`, anything else
(3-6) is a dive at the chosen power via `KeeperDive`.

**In open play (state 1):** the function simulates the ball's *own* physics forward,
frame by frame (`velocity *= friction`, position += velocity, `zvelocity -= gravity`),
tracing where it will be, and tests each simulated step against a **7.5-yard-wide
reaction line** centered on the keeper (offset 10 pixels toward the near/far post
depending on facing) *and* against the actual goal line. If the simulated path reaches
the goal line before it ever crosses the keeper's reaction line, the function gives up
immediately - the shot is already past the keeper, nothing to react to.

If the reaction line is hit first, the predicted impact height decides which kind of
save is even attempted: below **half** the keeper's max dive height it stays a low
save, between half and full height it's a half-height save, above full height it's a
full stretch. Then, only if the keeper is *currently* within 3 real yards of the ball
and inside the box:

* if the *predicted* landing point is 0.75 yards or more from the keeper, and the ball
  isn't a low cross and is moving fast or already controlled, it's a **dive**
  (`KeeperDive`);
* otherwise, if the predicted point is within 2.5 yards, it's a **catch**, gated by
  actual current distance and predicted height: low catch requires being within 1 yard,
  a high catch within 5 yards, a jump-catch (loose high ball) within 6 yards.

### What a save actually does to the ball - `TBall.Parry` / `Deflect`

A save is rarely a clean stop; `Parry` decides where the ball goes next:

| Case | Ball speed after | Direction |
|---|---|---|
| Keeper was diving (`KeeperDiving()`), ball moving left relative to keeper | ×`Rnd(0.3, 0.4)` | keeper's dive direction ± `Rand(-25,25)` |
| Keeper was diving, ball moving right | ×`Rnd(0.3, 0.4)` | keeper's dive direction ± `Rand(-25,25)` |
| Ball above keeper reach × 0.8, close-range "punch" animation active and near the last kicker | (turned to face away, `zvelocity = Rnd(2.5,3.5)`) | roughly back the way it came |
| Ball above keeper reach × 0.8, otherwise | ×0.7 | current direction ± `Rand(-15,15)`, `zvelocity = Rnd(2.5,3.5)` |
| Ball below keeper reach × 0.8 ("tip over") | ×`Rnd(0.45, 0.65)` | toward the side, based on the keeper's own horizontal velocity |

So a diving save barely slows the ball at all (still 30-65% of its original speed) and
sends it out at a fairly wide random angle - parries routinely produce rebounds and
corners rather than dead stops. `TBall.Deflect` (used when an outfield player tries to
head a ball that's too low, `z < keeper-reach × 0.6`) is the crudest version: speed cut
to 25% and a fully random new direction (`Rand(360)`), with an offside check on the
player who caused it.

### Hitting the post - `TBall.HitPost`

The ball's position resets to last frame's, velocity is damped by a module-global
factor, and the rebound direction is picked from **five bands** based on where along
the goal-mouth line the shot crossed (a fraction 0.0-1.0 fed in as the parameter):

| Fraction along goal line | Direction shift |
|---:|---:|
| < 0.2 | +60° |
| 0.2 - 0.4 | +30° |
| 0.4 - 0.6 | +0° (straight back) |
| 0.6 - 0.8 | −30° |
| ≥ 0.8 | −60° |

...plus `Rnd(-10, 10)` random scatter on top. A post hit in a real match (not training)
also plays a crowd "ooh" and calls `CheckLongShotRating` - a near miss still earns rating
credit exactly like an on-target shot does.

## What it means in play

**Shot accuracy is a stat-scaled dice roll, not a skill check on the player.** Whether a
human or AI takes the shot, the direction is the intended angle plus a `Rand`/`Rnd`
window whose width is driven by the shooter's `shooting` (or `heading`, for headers, or
`passing`, for the AI's own-pass fallback) attribute - a low-rated player's shots wander
much further off target than a high-rated one's, even with identical joystick input.

**"On target" is a promise made before the keeper gets involved.** The 25°/50-yard check
in `TBall.Kick` happens once, at the moment of the kick, against an empty goal frame. A
shot that a great keeper then saves comfortably was still logged as "on target" and
still bumps the on-target counter - the stat measures shot placement, not whether it
went in.

**A goal genuinely requires the ball to physically cross the line in a simulated frame.**
There is no "shot resolution roll" separate from the trajectory - `CheckGoals` runs the
same line-intersection test on every ball, every frame, whether it was just kicked or is
a stray back-pass. This means anything that changes the ball's position or velocity
before that frame - a deflection, a block, a keeper's `Parry` nudging it wide - genuinely
prevents the goal, because there is nothing left to override.

**The keeper AI commits to a dive before the shot is close**, by literally forward-
simulating the ball's own physics. A fast, well-placed shot can still be un-saveable
simply because the simulated trajectory crosses the goal line before it ever crosses the
keeper's 7.5-yard reaction line in the loop - the keeper's code gives up and returns
without attempting anything the instant that happens.

**Newstar players get an in-match feedback loop invisible to CPU players.** Every shot
attempt nudges the created pro's `finishing` or `longshots` temp rating (via
`CheckLongShotRating`, ±1, clamped to ±10 for the match) with a boss shout
("BADFINISHING" from inside the box, "GOODEFFORT" from outside), and a scored goal
triggers a further, larger rating bump through `AddStat`'s case 5 (+7 to +10 depending on
whether it came from a shot, free kick, or corner) - but only newstars see any of this;
`AddPlayerRating` returns immediately for every non-newstar player.

## What we do not know yet

* **The per-frame power-charge rate for a held human shot** (`g_player_float13` in
  `TPlayer.CheckKick`) has no confirmed value - `CheckKick` itself is only a near-miss
  (`recovered_unverified/TPlayer.CheckKick.bmx`, +132 bytes / 33 gaps against the
  original, all localised to one register-allocation cascade the reconstruction has not
  yet solved) and no other verified body reads that global. Reconstructing `CheckKick`
  to a byte match, or finding another verified caller of the same global, would pin it
  down.
* **`TapKickAdvanced`** (`TPlayer.TapKickAdvanced` @ 0x004f7c89) has never been written
  as a `.bmx` body at all - this document's description of it comes from reading
  `extracted/decomp_annotated/TPlayer.TapKickAdvanced@004f7c89.c` directly (Ghidra
  decompilation, MEDIUM confidence per its own header), not from a verified or even
  attempted reconstruction. The shoot-case numbers quoted (power = `distancetogoal_opp *
  0.5` minus `Rand(shooting)`, direction jitter `± Rand(shooting)`) come from that read
  and are not byte-proven.
* **`TBall.CheckGoals`'s exact sense on the very last height test** is still an open +8
  byte / 2-gap defect confined to one `If self.z < f4` comparison near the end of the
  function (the crossbar-height check gating the goal-line intercept itself) - see the
  notes in the header of `src/recovered_unverified/TBall.CheckGoals.bmx`. The geometry
  described above (post/net/line, in that order) is confirmed correct for the whole rest
  of the function; only the sense of that one comparison (which way the `<` points) is
  still unresolved.
* **The exact meaning of `g_engine_int31` / `g_engine_int32`**, the two counters bumped
  both by `TBall.Parry` (keyed off the saving goalkeeper's team) and by
  `TEngine.GoalScored` (keyed off the scoring player's team), is INFERRED, not read from
  any comment or debug label - this document guesses they are a combined "shots faced
  and resolved" tally per team, but that is not confirmed against any UI or save-file
  field that displays them.
* **What `TTraining.GoalScored` does** for a goal scored in a training minigame is
  completely unread; `TEngine.GoalScored` just hands off to it and stops.
* **`KeeperDive`, `KeeperCatchHigh`'s and `KeeperCatchLow`'s own save-success logic** - 
  this document covers *when* the keeper decides to attempt a dive/catch and what the
  rebound looks like once contact happens (`Parry`), but not whether `KeeperDive` itself
  can fail to actually reach the ball once committed (i.e. whether there's a further
  ability check inside the dive animation, or whether reaching the decision to dive
  guarantees contact). `TPlayer.KeeperDive` itself has not been read for this document.

## Implementation detail worth preserving

**"On target" and "goal" are computed by two unrelated geometry checks that can
disagree, and that is not a bug worth fixing.** `TBall.Kick`'s on-target test uses the
ball's flight *direction* at the instant of the kick against a 25° cone; `CheckGoals`'s
goal test uses the ball's actual simulated *position* crossing a line, frame by frame,
after friction, gravity, spin and any collisions have been applied. A shot can be logged
on-target and then curl wide, or be logged off-target by the 25° cone yet still swing in
via curl. Unifying these into one calculation would be a plausible-sounding
"cleanup" that changes real shot statistics - keep them separate.

**The tired/unhappy mishit substitution happens inside `TBall.Kick`, after the shooting
function has already committed to a kick type and power.** A newstar's `ShootAI`/
`TapKick`/`HoldKick` call can ask for a full-power Shoot and have `TBall.Kick` silently
turn it into a stumbling Pass at half power with a randomised direction. Any
reimplementation that resolves power/direction and kick-type in one step, rather than
letting `Kick` itself veto the type afterward, will lose this substitution.

**`ResetKick`'s `-1.0` sentinel for `kickdirection` is a genuine "no direction chosen
yet" flag, read elsewhere.** `TPlayer.CheckKick` explicitly checks
`If Self.kickdirection = -1.0 Then Self.kickdirection = Self.direction` while charging a
held shot - the sentinel is not just a reset value, it is load-bearing logic that a
freshly-reset player who starts charging without moving the stick inherits their current
facing as the shot direction.

**Only newstars can be credited with a goal celebration or a rating change; CPU players
running through the identical code paths get neither.** `AddPlayerRating` opens with
`If Self.newstar = 0 Then Return 0`, and `GoalScored`'s particle effect is gated the same
way. This means the "GOODEFFORT"/"BADFINISHING" boss-shout system, the whole visible
feedback loop of the game's career mode, literally does not run for any player except
the one the save file belongs to - worth remembering if AI-vs-AI simulated matches are
ever expected to produce the same commentary as a played match.
