# Ball physics

> **Source:** `TBall.Update` @ 0x004c81b6 (VERIFIED) · `TBall.UpdateMovement` @ 0x004c871f (READ) ·
> `TBall.UpdateMetaBall` @ 0x004c8dce (VERIFIED) · `TBall.Kick` @ 0x004c91a2 (VERIFIED) ·
> `TBall.CheckAfterTouch` @ 0x004c9c35 (READ) · `TBall.CheckGoals` @ 0x004ca0cc (READ) ·
> `TBall.CheckSideLines` @ 0x004ca8a4 (VERIFIED) · `TBall.CheckAdHoardings` @ 0x004caa8f (VERIFIED) ·
> `TBall.HitPost` @ 0x004cac9b (VERIFIED) · `TBall.HitNet` @ 0x004cae6e (VERIFIED) ·
> `TBall.Deflect` @ 0x004cb5ec (VERIFIED) · `TBall.Parry` @ 0x004cb6c5 (VERIFIED) ·
> `TBall.KeeperHolding` @ 0x004cb54e (VERIFIED) · `TBall.ResetPosition` @ 0x004cbc81 (VERIFIED) ·
> `TBall.Crossing` @ 0x004cbda9 (VERIFIED) · `TBall.GetHeightScale` @ 0x004cc466 (VERIFIED) ·
> `TBall.SetUp` @ 0x004c78c0 (VERIFIED) · `TBall.CreateBall` @ 0x004c7cf2 (VERIFIED) ·
> `TBall.New` @ 0x004c74e1 (VERIFIED) · `TPlayer.CheckBallContact` @ 0x004f55f2 (VERIFIED) ·
> `TPlayer.SetUp` @ 0x004ec179 (VERIFIED)
> **Confidence:** MEDIUM
> **Last checked:** 2026-08-15

Confidence is mixed on purpose. Everything about collisions (posts, crossbar, net, hoardings,
throw-ins, keeper saves, the free/dribbled kick launch) comes from functions that are
byte-exact matches against the shipped exe - that part is HIGH confidence. The tick-by-tick
motion integrator (`UpdateMovement`) and the curl/aftertouch and goal-line-crossing logic
(`CheckAfterTouch`, `CheckGoals`) are still draft reconstructions - read from the disassembly,
shape believed correct, but not yet byte-for-byte proven (the closest, `UpdateMovement`, is
one byte off out of 1,711; the furthest, `CheckAfterTouch`, is 14 bytes off out of 1,175).
Anywhere this document relies on one of those three, it says so.

---

## 1. What the system does

### The ball is not a physics-engine rigid body - it is one number for speed and one for direction

Every tutorial on 2D ball physics reaches for `(vx, vy)`. New Star Soccer 5 does not. Reading
`TBall`'s own field list (`extracted/object_model.json`) shows the ball stores a **scalar
speed** (`velocity`) and a **heading in degrees** (`direction`), plus a separate **vertical
speed** (`zvelocity`) and **height** (`z`). Every tick the horizontal move is computed as
`Cos(direction) * velocity` and `Sin(direction) * velocity` - polar, not Cartesian. This
matters for anyone reimplementing it: friction and drag only ever shrink the speed number:
they never touch the heading. Only two things change the heading of a moving ball - hitting
something (a post, the net, a hoarding, a player) and curl (§1.4). Gravity and air/grass drag
never bend the ball's path sideways; they only slow it down or bring it down.

### Two completely different motion models, chosen by whether anyone controls the ball

`TBall.UpdateMovement` - the per-tick motion routine - is a single `If Self.controlledby <>
Null` branch away from being two unrelated pieces of code:

- **Controlled (dribbled or held):** the ball is not simulated as a projectile at all. It is
  eased 25% of the way, every tick, toward a point computed from the controlling player's
  position, facing and speed. It is a leash, not a physics body.
- **Loose (in flight, rolling, or just released):** this is the projectile you'd expect - 
  gravity, air drag while airborne, rolling friction on the ground, a bounce coefficient on
  landing, and a heading that only curl or a collision can change.

Both branches always run the vertical (`z`/`zvelocity`) update afterward, so height and
bouncing behave the same whether or not someone has the ball at their feet - with one
exception (a keeper's held ball has its vertical speed frozen, §1.3).

### 1.1 The free ball: gravity, drag and bounce (`TBall.UpdateMovement`, READ - shape solid, 1 byte off)

```
each tick, when Self.controlledby = Null:
    direction ← direction + curlamount              ' curl bends the heading (§1.4)
    velocity  ← velocity × fricAir      (0.99)       if z > 0   (airborne)
    velocity  ← velocity × fricGrass    (0.985)      if z = 0   (rolling)
    x ← x + Cos(direction) × velocity
    y ← y + Sin(direction) × velocity

every tick, regardless of control:
    zvelocity ← zvelocity − gravity     (0.14)
    z ← z + zvelocity
    if z ≤ 0:
        z ← 0
        zvelocity ← −zvelocity × bounce (0.6)
        if zvelocity > 1.0: play the bounce sound
```

`gravity`, `bounce`, `fricAir` and `fricGrass` are read straight out of `Engine.ini` by
`TBall.SetUp` (VERIFIED, byte-exact) into four module Globals, and `UpdateMovement`'s use of
them matches the values in the file exactly: **gravity 0.14, bounce 0.6, fricAir 0.99,
fricGrass 0.985.** These are the same numbers `docs/specs/04-match-engine-physics.md` derived
from the `Engine.ini` blob alone; having them confirmed inside the actual motion code (even in
a not-yet-byte-matched draft) is a second, independent check on that spec.

One thing the spec could only guess at is now settled by reading the code directly: **`fricAir`
is never applied to `zvelocity`.** Only the horizontal speed decays in the air; the vertical
motion is pure `gravity`, undamped. That resolves open question 2 in the spec.

### 1.2 Gravity is applied *twice* while a player is juggling the ball in the air

This is a genuine original quirk, not a reconstruction artefact - see §6. When the ball is
both airborne (`z > 0`) **and** currently controlled by a player who is not the goalkeeper
holding it, `UpdateMovement` subtracts `gravity` from `zvelocity` a second time in the same
tick, and additionally clamps the ball's height to a cap (`playerheight`, see below) so it
cannot balloon above what a dribble/flick should reach. A loose ball in the air only ever gets
gravity applied once. Practically: a flick-up or keepy-uppy falls noticeably faster than a
identical-looking loose lob.

### 1.3 The keeper's held ball

`TBall.KeeperHolding` (VERIFIED) is one line: the ball is "held" exactly when it has a
controller and that controller's own `KeeperHoldingBall()` flag is set. While held, its
vertical speed is pinned to `0.0` every tick (it does not fall out of the keeper's hands), and
its height is snapped down to whatever `GetKeeperHandHeight()` reports for that player if the
ball's current height is above that (i.e. the ball rides the keeper's hands, not the other way
round).

### 1.4 Curl / aftertouch - resolved: it is a heading rotation, not a sideways force

Section 5.7/13#4 of the physics spec flagged this as the single biggest open question about
ball flight: is `curlamount` a lateral velocity, or a rotation of the ball's own heading? The
recovered `UpdateMovement` code answers it outright - the *only* thing `curlamount` ever does
to a loose ball is:

```
direction ← direction + curlamount     ' every tick, only while the ball is loose
```

`curlamount` is a **degrees-per-tick heading drift**, added straight onto `direction` (which is
itself in degrees - `ATan2` in this codebase returns degrees, confirmed by
`src/recovered_module/`'s recovered `ATan2` matching `atan2(y,x) * RAD_TO_DEG` from the legacy
BlitzMax math runtime). A curling shot is not "pushed sideways" - its whole heading slowly
rotates while it flies, which produces the same visual bend but is a different (and simpler)
computation than a lateral force would be.

How `curlamount` itself gets set is in `TBall.CheckAfterTouch` (READ, not yet byte-matched,
14 bytes off out of 1,175 - believed right in shape). Every tick, while the ball is loose and
within its aftertouch window, the game compares the direction the kicking player's joystick is
currently pointing against the ball's own direction of travel, and buckets the angle between
them into five bands:

| Angle between stick input and ball heading | Effect |
|---:|---|
| within 45° of "same direction" (315°-360° or 0°-45°) | dips the ball: `zvelocity -= curlinc × 2` |
| within 45° of "opposite direction" (135°-225°) | lifts **and** speeds up the ball: `zvelocity += curlinc × 2`, `velocity += curlinc` |
| 10°-170° (roughly "stick held left of travel") | `curlamount += curlinc`, capped at `+curlmax` |
| 190°-350° (roughly "stick held right of travel") | `curlamount -= curlinc`, capped at `−curlmax` |
| the two 10° gaps in between | no change that tick |

`curlinc = 0.05`°/tick and `curlmax = 0.7`° are the raw `Engine.ini` values, but the draft code
scales *both* by the kicking player's `flair` stat divided by 10 before use - a player with
`flair = 10` gets exactly the book value, a player with higher flair curls the ball faster and
further, a player with low flair barely curls it at all. This scaling is UNVERIFIED (draft
code) but the shape (curl gated on a player attribute) is a plausible and specific enough claim
that it is worth testing in game before relying on it.

There is also a 50-millisecond dead zone at the start of every kick: input is ignored for the
first 50 ms after the kick (`kicktime + 50 < now`), and the whole aftertouch window closes at
`kicktime + aftertouchtime` (750 ms). Both times are real milliseconds, not ticks - confirmed
because the clock they are compared against, `g_player_int50`, is independently documented as
"the millisecond clock" in the verified `TPlayer.CheckBallContact` (VA 0x004f55f2). That
settles another of the spec's open questions (§13#1 context): the aftertouch window really is
750 ms of wall-clock time, not 750 ticks.

### 1.5 Dribbling: the ball on a leash

While a player controls the ball (open play, not a set piece - see §1.6), `UpdateMovement`
computes a target point out in front of the player and eases the ball 25% of the way to it
every tick:

```
mv = 6.0 + controlledby.speed × 3.0        ' how far ahead of the player the ball sits
if keeper is holding it:            mv ×= 1.5
if celebrating (match state 8):     mv ×= 0.8, and ×= 0.6 more if speed < 1.0; direction += 10°

targetX = controlledby.x + Cos(direction) × (mv × 1.25)
targetY = controlledby.y + Sin(direction) × mv

x ← x + (targetX − x) × 0.25
y ← y + (targetY − y) × 0.25
velocity ← controlledby.speed          ' recorded, not used to move the ball here
```

The x-component gets an extra ×1.25 that the y-component does not - the lead point is
stretched further out in the direction the player is facing than sideways from it, which
matches the visual of the ball sitting slightly ahead of a sprinting player's feet rather than
glued to them. The distance out in front grows with the player's own speed (a standing player
holds the ball 6 units from their feet; a player at full speed pushes it further out), which is
exactly the "the faster you run, the less close control you have" trade-off a New Star Soccer
player would recognise.

### 1.6 Set pieces reposition the ball directly, bypassing all of the above

At the top of `UpdateMovement`, if the engine is currently in a set-piece state
(`TEngine.SetPiece()`), the whole projectile/dribble model is skipped. The ball is snapped via
`TBall.ResetPosition` (VERIFIED - `x=a0; y=a1; z=a2; oldx/oldy/oldz mirror; velocity=0;
zvelocity=0`) to a spot near the taker (offset ±2 units in x, −1 in y, and a height derived from
`playerheight − 5`) if the taker's current running animation matches the "about to take it"
animation set, or to the stored `setpiecex`/`setpiecey` otherwise. Either way, velocity and
vertical speed are both hard-zeroed - a set piece never inherits leftover momentum from before
the stoppage.

### 1.7 Kicking - how a touch turns into velocity (`TBall.Kick`, VERIFIED, 2,707/2,707 bytes)

`Kick(kicker, direction, power, kickType, passTargetId)` is what every pass, shot, lob, cross
and header routes through. Two things happen before the kick type is even looked at:

**A flat +50 power boost, then a hard cap.** The incoming `power` value (from the on-screen
power meter, `0..100`) always has 50 added to it before anything else, then is clamped to
`100` in normal play or `130` during one particular match state (`g_player_int01 = 5` - 
UNCERTAIN which set-piece phase this is; the cap is higher there, consistent with a free kick
or penalty being allowed more oomph than an open-play shot). The practical consequence: **the
top half of the power meter does nothing.** Any power reading of 50 or above produces an
identical, maximum-strength kick; only the bottom half of the bar (0-50) has any effect on how
hard the ball actually goes, because it is the only range that survives the +50/clamp-to-100
squeeze without saturating.

**The kick-type dispatch**, using the constants `TBall.SetUp` reads from `Engine.ini`
(`kickpow_*`/`kickheight_*`, matching the spec's §5.3 table exactly):

| `kickType` | Name | `velocity` set to | `zvelocity` set to | Notable modifiers |
|---:|---|---|---|---|
| 1 | Pass | `power × kickpow_pass (0.07)` | `kickheight_pass (0.0)` | stays on the ground |
| 2 | Shoot | `power × kickpow_shoot (0.1)` | `kickheight_shoot (2.85)` | see shot special-cases below |
| 3 | Lob | `power × kickpow_lob (0.08)` | `kickheight_lob (3.65)` | ×0.85 velocity if match state 3; ×1.2 velocity / ×1.4 height if state 6; ×1.1 velocity for a cross inside the cross zone; ×0.5 zvelocity if inside 12 yards of goal and not training |
| 4 | Head Pass | `power × kickpow_head (0.08)` | `kickheight_head (1.5) × 0.2` | |
| 5 | Head Shoot | `power × kickpow_head (0.08)` | `kickheight_head (1.5) × 0.75` | |
| 6 | Head Lob | `power × kickpow_head (0.08)` | `kickheight_head (1.5) × 1.0` | |

The Shoot case (2) has its own extra logic: if the ball is inside 16 yards of goal, its height
is clamped to at most 30% of `playerheight` and, if it's below 10 units already, the
vertical speed is forced flat to `kickheight_shoot` (2.85) rather than the usual half-decay - 
a close-range shot is kept low and driven rather than allowed to loop up, which matches how a
"first-time finish" should look. States 7/9 replace the whole `zvelocity` formula with a
power-proportional ramp (`kickheight_shoot × 1.4/50 × (power − 50)`) instead of the fixed
constant - almost certainly the different physics of a **penalty kick**, where height should
scale continuously with how hard the player strikes it rather than jumping straight to a fixed
loft.

**Tired and unhappy players sabotage their own kicks.** Before any of the above, if the kicker
is a "New Star" (the player-controlled career player), the match is live, not in training, the
kick is a Shoot or Lob, and a `1-in-5` dice roll (`Rand(5) = 1`) comes up, the game checks the
player's `energy` and `happiness` (from their `TProfile`). If energy is below 30 and a
`0..40` roll beats the energy value, the kick is downgraded to a half-power Pass and the
direction is randomly thrown off by 20-40°, an on-screen "tired" message appears, and the
player animation-falls over. If not tired but `happiness < Rand(70)`, the same thing happens at
25% off power and a 10-30° miss-direction, with an "unhappy" message instead. **This is a real,
verified mechanic**: fatigue and morale can visibly wreck a shot, roughly once every five
attempts on average when either stat is poor, and it only ever applies to the human career
player, never to AI players.

**Shots also drive the shot counter and rating.** Outside of a handful of neutral match states
(kickoff-adjacent states 8/9/10/0/11), every kick checks whether it is heading close enough to
the opponent's goal (`AngleDiff` under 25° of dead-on, within 50 yards) and, if the resulting
flight path intercepts the goal-mouth line, credits the kicker's `AddStat` (shot-on-target), the
team's on-target counter, and (if it's the New Star) their "I had a shot" flag for the news
system. This is the on-target check that decides whether a shot registers as "on target" for
the match stats, independent of whether it is later saved, parried, or actually scores.

### 1.8 Collisions with posts, crossbar, net and hoardings

- **Post (`TBall.HitPost`, VERIFIED):** the ball is snapped back to its previous position
  (`oldx`/`oldy`), speed is scaled by the `bounce` coefficient (0.6, the same constant used for
  ground bounces), and the heading is reflected using the intersection point along the post
  (`ip.intercept_CD`, a 0..1 fraction along the collision segment). That fraction is bucketed
  into five 0.2-wide bands, each nudging the rebound angle by 0°, ±30° or ±60° depending on how
  central the hit was, then a final `±10°` of random scatter (`Rnd(-10,10)`) is added so no two
  post hits deflect identically. A crowd "ooh" sound plays and `CheckLongShotRating` fires
  (§1.9) if this happened in a live match, not training.
- **Net (`TBall.HitNet`, VERIFIED):** simpler - snap back to the previous position, scale speed
  by a random `Rnd(0.03, 0.07)` (the net kills almost all the ball's speed, unlike a post), and
  mirror either the x or y component of the heading depending on which side of the net was hit.
- **Advertising hoardings (`TBall.CheckAdHoardings`, VERIFIED):** tests whether the ball's last
  step crossed either endline hoarding *and* is still low (`z ≤ 12.0`) - if so, it rebounds off
  the hoarding exactly like a post/net hit (snap back, scale by `bounce`, reflect heading), and
  a bounce sound plays. Independently, if the ball strays more than 200 units past either pitch
  boundary (touchline or goal line) for any reason, it fades out at `0.05` alpha per tick,
  regardless of height - the visual fade that covers a ball that's gone flying well out of the
  playable frame before the game resets it for a throw-in or goal kick.
- **Keeper saves - deflect vs. parry.** `TBall.Deflect` (VERIFIED) is a knockdown: possession
  passes to the deflecting player, speed drops to 25% of what it was, direction gets a random
  ±180° kick (`Rand(360)` added, then wrapped), and it immediately re-checks the new holder for
  offside. `TBall.Parry` (VERIFIED, 1,206 bytes) is the keeper-specific version and has four
  distinct outcomes depending on how the keeper is diving and where the ball is relative to
  them:
  - Diving keeper, ball arriving to their weaker side (`xvel` sign test): a weak **tip** - 
    speed scaled by `Rnd(0.3, 0.4)`, direction randomised ±25° off the keeper's own facing.
  - Standing/close-range and the shot came from the same player who last kicked it within 1
    yard (i.e. point-blank): a **punch** - clean, `zvelocity` set to `Rnd(2.5, 3.5)`, aimed
    mostly straight back (`Cos × 0.1`, so almost no forward drift, just up).
  - Standing/close-range otherwise: a plain **parry** - 70% speed, `Rnd(2.5,3.5)` zvelocity,
    ±15° scatter, and it explicitly forces the goalkeeper's animation to a "diving" frame set.
  - Ball above the keeper's stretch (`z > a0.z + playerheight × 0.8`) but not caught by the
    dive-tip cases: a **tip over the bar** - 45-65% speed retained (`Rnd(0.45,0.65)`), deflected
    hard sideways off the keeper's own horizontal speed (`xvel × 2.0`). This branch contains an
    **original bug**: it calls `Cos(direction)` and throws the result away without using it - 
    see §6.

### 1.9 Going out of play

- **Side lines / goal lines (`TBall.CheckSideLines`, VERIFIED):** only checked while the match
  is live (state 1 or 10). If the ball's `x` passes `pitchhalfwidth + margin`, a throw-in is set
  up (`TEngine.SetUpSetPiece(3, team, 0, 0)`) for whichever team didn't touch it last. If `y`
  passes `pitchhalfheight + margin`, the game asks the last player which direction they were
  shooting (`GetShootingDirection`) to decide whether it's a corner (type 6) or a goal kick
  (type 5) - it is a corner if the ball went out on the attacking end from that player's
  perspective, a goal kick otherwise.
- **A goal (`TBall.CheckGoals`, READ, 8 bytes off out of 2,008 - the divergence is confined to
  one comparison at the very end, everything else byte-identical):** independent of the
  post/net collision tests, the function separately checks - only in states 1/10 and only while
  the ball is below crossbar height - whether the ball's last step crossed either goal-mouth
  line segment. If it did, `TEngine.GoalScored(Self)` fires and an `ingoal` flag latches to 1,
  which both suppresses a second goal credit for the same ball and lets the earlier "did we
  cross a goal line at all" test at the top of the function auto-clear the flag once the ball
  has clearly left the goal area (`Abs(y) < pitchhalfheight`) - i.e. **the flag exists purely
  to stop one goal-line crossing from being counted twice**, not to gate anything else. The
  same function also separately re-implements a ball-vs-net-boundary bounce (very similar to
  §1.8's hoarding bounce, but keyed to the goal frame rather than the pitch edge) with a floor
  of `velocity ≥ 1.0` after the bounce - a ball trickling into the net can never come to a
  literal dead stop against it.

### 1.10 The predictive "meta-ball" - how the game knows where the ball is *going to be*

`TBall.UpdateMetaBall` (VERIFIED, 610/610 bytes) is not part of the ball's actual motion - it
runs a full **forward simulation of the ball's future flight**, every single tick, using a copy
of the current speed/height/direction, and throws the copy away once it is done. This is how
AI defenders and the goalkeeper know where to run *before* the ball gets there:

```
metax, metay ← x, y                 ' start of the imaginary flight
if ball is currently controlled:
    metax, metay ← controlled player's own predicted position (metax/metay)
    stop here
else, repeat (airborne branch, using fricAir 0.99):
    lv ← lv × fricAir
    metax += Cos(direction) × lv ;  metay += Sin(direction) × lv
    lz ← lz + (lzv -= gravity)
    if not controlled: heading drifts by curlamount, same as the real ball
    while falling (lzv < 0):
        if lz > playerheight × 1.1: jumpx, jumpy ← metax, metay   ' "jump for this" marker
        if lz > playerheight × 0.6: divex, divey ← metax, metay   ' "dive for this" marker
    until lz ≤ 0 or lv ≤ 0
or, repeat (rolling branch, using fricGrass 0.985):
    lv ← lv × fricGrass ; advance metax/metay the same way
    until lv ≤ 3.0
```

`metax`/`metay` end up being the ball's predicted resting spot (or, if it's being dribbled, just
the dribbler's own predicted spot). `jumpx`/`jumpy` and `divex`/`divey` are waypoints recorded
partway through the simulated arc - the first point in the flight where the simulated height is
still above `1.1×playerheight` (24.2 units) while falling, and the first point above
`0.6×playerheight` (13.2 units) while falling. These read exactly like markers for "where should
a player jump to head this" and "where should the keeper start a dive for this" respectively - 
the game literally fast-forwards the physics to find out.

---

## 2. The numbers

### 2.1 Core constants (`Engine.ini`, loaded by `TBall.SetUp`, VERIFIED)

| Key | Value | Meaning |
|---|---:|---|
| `ballradius` | 2 | collision radius, world units |
| `gravity` | 0.14 | downward accel on `zvelocity`, units/tick² |
| `bounce` | 0.6 | speed multiplier on any ground/post/net/hoarding rebound |
| `fricAir` | 0.99 | horizontal speed multiplier per tick while `z > 0` |
| `fricGrass` | 0.985 | horizontal speed multiplier per tick while `z = 0` |
| `passcheckradius` | 5 | half-width of the pass-lane occlusion test (`CanSeePlayer`) |
| `kickpow_pass` / `kickheight_pass` | 0.07 / 0.0 | ground pass |
| `kickpow_shoot` / `kickheight_shoot` | 0.10 / 2.85 | shot |
| `kickpow_lob` / `kickheight_lob` | 0.08 / 3.65 | lob/chip |
| `kickpow_head` / `kickheight_head` | 0.08 / 1.5 | header (all three header sub-types share this pair, scaled - see §1.7) |
| `aftertouchtime` | 750 ms | real-time window after a kick during which stick input still curls the ball |
| `curlinc` | 0.05°/tick | heading-drift ramp rate, scaled by `flair/10` in the draft `CheckAfterTouch` |
| `curlmax` | 0.7° | heading-drift cap, same scaling |

### 2.2 Values only visible by reading the code, not in `Engine.ini`

| Constant | Value | Where |
|---|---:|---|
| Kick power boost | `+50`, then capped at `100` (or `130` in match state 5) | `TBall.Kick` |
| Dribble lead distance | `6.0 + controlledby.speed × 3.0` units, ×1.25 on the x-axis only | `TBall.UpdateMovement` |
| Dribble easing rate | 25% of the remaining gap closed per tick | `TBall.UpdateMovement` |
| Set-piece reposition offset | `±2` units x, `−1` unit y, height `playerheight − 5` | `TBall.UpdateMovement` |
| `playerheight` (`g_player_int33`) | 22 world units | confirmed the same Global as `Engine.ini`'s `playerheight` via `TPlayer.SetUp`'s header comment for address `0x00C5DE70` |
| Airborne-dribble height cap | `playerheight` (22) | `TBall.UpdateMovement` |
| Meta-ball "jump for it" threshold | `playerheight × 1.1` = 24.2 units | `TBall.UpdateMetaBall` |
| Meta-ball "dive for it" threshold | `playerheight × 0.6` = 13.2 units | `TBall.UpdateMetaBall` |
| Rolling-prediction stop speed | `3.0` units/tick | `TBall.UpdateMetaBall` |
| Post rebound angle bands | 0°, ±30°, ±60° by hit position, +`Rnd(-10,10)` scatter | `TBall.HitPost` |
| Net rebound speed | `× Rnd(0.03, 0.07)` (kills 93-97% of speed) | `TBall.HitNet` |
| Hoarding low-bounce height gate | `z ≤ 12.0` | `TBall.CheckAdHoardings` |
| Off-pitch fade rate | `alph −= 0.05`/tick once 200+ units past a boundary | `TBall.CheckAdHoardings` |
| Aftertouch dead zone | first 50 ms after the kick | `TBall.CheckAfterTouch` (READ) |
| Keeper dive-tip speed retained | `Rnd(0.3, 0.4)` (30-40%) | `TBall.Parry` |
| Keeper punch/parry zvelocity | `Rnd(2.5, 3.5)` | `TBall.Parry` |
| Keeper "tip over" speed retained | `Rnd(0.45, 0.65)` (45-65%) | `TBall.Parry` |
| Keeper close-range punch/tip cutoff height | `a0.z + playerheight × 0.8` | `TBall.Parry` |
| Tired-kick trigger | `New Star`, live match, not training, Shoot/Lob, `Rand(5)=1`, then `energy < 30` and `Rand(0,40) > energy` | `TBall.Kick` |
| Tired-kick penalty | half power, forced to a Pass, ±20-40° miss | `TBall.Kick` |
| Unhappy-kick trigger | same gate, then `happiness < Rand(70)` | `TBall.Kick` |
| Unhappy-kick penalty | 75% power, forced to a Pass, ±10-30° miss | `TBall.Kick` |
| Shot on-target angle gate | within 25° of dead-on, within 50 yards of goal | `TBall.Kick` (uses `g_ball_double01`, confirmed 25.0 from `.rdata`) |

---

## 3. What it means in play

- **Curling a shot really is rotating it, tick by tick, in flight** - there is no lateral push
  to reason about, just a slow heading drift that a well-timed stick input can ramp up to
  ±0.7°/tick (more, proportionally, for a high-flair player) within the first ~467 ms of the
  ball's flight and then hold until the 750 ms aftertouch window closes.
- **Only the bottom half of the power bar matters.** Because every kick gets +50 power before
  the 0-100 clamp, charging the meter past the halfway point produces no harder a shot than
  stopping exactly at half. The skill in timing a shot is entirely in the bottom half of the
  bar (and in aim/type), not in "holding it as long as possible."
- **A juggled or flicked ball falls unnaturally fast.** Doubled gravity while dribbling in the
  air is not a bug worth "fixing" in a reimplementation - it is why keepy-uppies and flick-ons
  look snappy rather than floaty compared to a genuinely loose lob.
- **Tiredness and unhappiness are not just numbers on a stats screen - they can visibly
  sabotage a shot** for the human-controlled career player, roughly one time in five whenever
  either stat is poor, complete with an on-screen warning and the player stumbling.
- **AI positioning is not guesswork** - `UpdateMetaBall` genuinely fast-forwards the real
  physics every tick to find out where the ball will be, and specifically flags the point in
  a falling ball's arc where it first drops below 24.2 units (jump for it) and 13.2 units
  (dive for it). Any reimplementation that has defenders/keepers reading the *current* ball
  state instead of this rolled-forward prediction will look noticeably less prepared than the
  original.
- **A shot that beats the keeper's positioning still has to clear the net-frame boundary
  check**, and a ball that trickles in against the net is guaranteed at least `1.0` units/tick
  of creep rather than a literal stop - nothing in this game's ball physics ever produces a
  hard zero velocity against the net.

---

## 4. What we do not know yet

- **`TBall.UpdateMovement` itself is not byte-verified.** It is 1 byte off out of 1,711 and the
  remaining gap is fully accounted for by two known register-allocation quirks in this
  project's toolchain (not a missing statement) - see the file's own header in
  `src/recovered_unverified/TBall.UpdateMovement.bmx` for the exact diagnosis. Closing this to
  a byte-exact match is the single highest-value next step for this document; everything in
  §1.1, §1.2, §1.5 and §1.6 rests on this file.
- **`TBall.CheckAfterTouch` is 14 bytes off out of 1,175**, and unlike `UpdateMovement` the
  cause is not fully diagnosed - there is a suspected extra clause (a third interval test on
  `curlamount`) that this draft may be missing entirely, not just a codegen mismatch. The
  `flair`-scaling of `curlinc`/`curlmax` described in §1.4 should be treated as a strong lead,
  not a settled fact, until this closes.
- **`TBall.CheckGoals` is 8 bytes off out of 2,008**, isolated to a single sense-flip on one
  `Self.z < f4` comparison near the very end of the function (which of two `If` branches the
  goal-mouth interception check falls into). The function's own header documents the exact
  investigation trail; whoever picks it up next should start there rather than re-deriving it.
- **What match state 5 (the `130` power cap in `TBall.Kick`) actually is** is not confirmed - 
  free kick and penalty are the two footballing-sensible guesses, but no function has been read
  yet that names the numeric match-state codes. `TPlayer.CheckBallContact`'s comment
  ("8 = celebration, 1/10 = live") is the only match-state documentation found so far.
  `TEngine`'s state-transition code would answer this.
- **The exact geometry constants inside `TBall.CheckGoals`** (four Int Globals used for post
  half-width, post thickness, crossbar height and net depth in the goal-collision tests) were
  not independently traced back to specific `Engine.ini` keys the way `TBall.SetUp`'s ball
  constants were - the draft file names them generically (`g_pitch_intNN`). Confirming which
  is `goalpost`, `postwidth`, `crossbar` and `netline` needs either `TPitch.SetUp` or a
  byte-exact `CheckGoals`.
- **What `g_ball_int05` (stamped by both `TBall.Kick` and the tail of `TBall.UpdateMovement`)
  actually drives** is unclear - it looks like it marks the moment of a kickoff-type restart,
  but nothing in the ball-physics functions reads it back. `TEngine`'s match-state machine
  would be the place to look.
- **Whether `shotdistanceparry`/`shotpowerparry` (the two Engine.ini keeper-parry-gate keys
  from the physics spec) are actually read anywhere in `TBall.Parry`** - they are not; `Parry`'s
  branching is driven entirely by height (`z` vs. `playerheight`-scaled thresholds) and the
  keeper's own dive/xvel state, not by the ball's incoming speed or the shot's origin distance.
  Either those two keys are consumed somewhere in `TPlayer`'s save-decision code (most likely
  `CheckKeeperSave`, called repeatedly from `TPlayer.CheckBallContact` in §1's evidence) rather
  than in `TBall`, or they gate whether `Parry` gets called at all rather than what it does - 
  `TPlayer.CheckKeeperSave` is the function that would answer this.

---

## 5. Worth preserving exactly

- **The polar `(velocity, direction)` representation, not `(vx, vy)`.** A reimplementation that
  "cleans this up" into a velocity vector will, quietly, get friction wrong: this game's drag
  multiplies a *speed*, not two independent axis components, so a ball moving diagonally does
  not decay differently on its x- and y-components the way a naive vector-friction port would
  produce if someone were tempted to add per-axis drag. Keep speed and heading as separate
  scalars.
- **Gravity applied twice while dribbling/flicking in the air, once otherwise.** Confirmed in
  `TBall.UpdateMovement` (§1.2) - this is not a bug to fix, it is why the game's short flicks
  and keepy-uppies read as snappy. Losing it would make dribbling the ball in the air feel
  floatier than the original.
- **The kick power `+50`-then-clamp squeeze (§1.7, §3).** Reimplementing the power bar as a
  clean linear `0..100 → 0..100` mapping changes the actual skill curve of shooting - the
  original only ever differentiates shots in the bottom half of the meter.
- **`TBall.Parry`'s "tip over the bar" branch discards a `Cos()` call it computes** (see §1.8,
  4th bullet). This is the *original's own* dead code - the disassembly shows the result loaded
  onto the x87 stack and immediately popped with no store. It costs nothing to keep and nothing
  is achieved by "fixing" it; per this project's law 3, dead code the original shipped with
  stays.
- **The five-band post-rebound angle system and its final ±10° random scatter (`TBall.HitPost`,
  §1.8).** Two consecutive post hits from an identical approach angle will not deflect
  identically - that randomness is deliberate and load-bearing for how unpredictable a post hit
  feels.
- **The `ingoal` latch existing purely to prevent double-counting one goal-line crossing**
  (§1.9) - it is not a broader "is a goal currently being celebrated" flag, even though it might
  look like one at a glance; do not repurpose it for anything else when porting `TEngine`'s
  celebration/restart logic.
- **The Y-clamp on a keeper's held ball only applies outside match state 8** (celebration) - 
  `UpdateMovement` explicitly early-returns before reaching that clamp when celebrating, so a
  keeper carrying the ball during a celebration animation is deliberately allowed to drift
  outside the normal pitch-y bounds that would otherwise pin them.
