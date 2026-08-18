# Goalkeeper behaviour

> **Source:** `TPlayer.DoKeeperDiveAI` @ 0x004f3592 (VERIFIED) · `TPlayer.UpdateKeeperPosition` @ 0x004f2eed (READ) · `TPlayer.CheckKeeperSave` @ 0x004f698f (VERIFIED) · `TPlayer.KeeperDive` @ 0x004f4124 (VERIFIED) · `TPlayer.KeeperCatchLow` @ 0x004f43d2 (VERIFIED) · `TPlayer.KeeperCatchHigh` @ 0x004f4421 (VERIFIED) · `TPlayer.KeeperJump` @ 0x004f4470 (VERIFIED) · `TPlayer.BlockSave` @ 0x004f89ce (VERIFIED) · `TPlayer.GetKeeperHandHeight` @ 0x004fcd01 (VERIFIED) · `TPlayer.KeeperHoldingBall` @ 0x004fcab6 (VERIFIED) · `TPlayer.KeeperDiving` @ 0x004fcbb8 (VERIFIED) · `TPlayer.KeeperJumping` @ 0x004fcc37 (VERIFIED) · `TPlayer.ValidateKeeperAnim` @ 0x004fc5af (VERIFIED) · `TPlayer.GetOppKeeper` @ 0x004fbc98 (VERIFIED) · `TBall.Parry` @ 0x004cb6c5 (VERIFIED) · `TBall.KeeperHolding` @ 0x004cb54e (VERIFIED) · `TBall.KeeperImageHolding` @ 0x004cb58d (VERIFIED) · `TEngine.GetStringMatchState` @ 0x004d7a8e (VERIFIED) · `TEngine.SetPiece` @ 0x004d35fd (VERIFIED)
> **Confidence:** MEDIUM (HIGH for the save/dive/parry decisions - every function behind them is byte-exact; MEDIUM for standing positioning, which rests on one unverified decompile with a couple of unresolved constants)
> **Last checked:** 2026-08-15

Almost the whole goalkeeper - where he stands, when he comes off his line, what a save turns
into - lives in `TPlayer`. He is not a separate class; a `TPlayer` behaves as a keeper when its
`selectionno` and animation tables point at keeper-specific frame ranges. The functions below
are the ones that check "is this player acting as a keeper right now" and decide what he does.

Match state numbers, used throughout, are pinned down by `TEngine.GetStringMatchState`
(a `Select` that returns the exact debug string for each value, byte-matched) and
corroborated by `TEngine.SetPiece`, which shares the identical `Select` skeleton:

| Value | State |
|---:|---|
| 0 | Tunnel |
| 1 | In Play |
| 2 | Centre (kick-off) |
| 3 | Throw-In |
| 4 | Free Kick |
| 5 | Corner |
| 6 | Goal Kick |
| 7 | Penalty |
| 8 | Goal! |
| 9 | Shoot-Out |
| 10 | Shoot-Out Taken |
| 11 | Match Over |

That table matters because the keeper's dive logic is gated on exactly two of these values - 
**1 (In Play)** and **10 (Shoot-Out Taken)** - and his standing position uses **9** and **10**
as a pair. "Shoot-Out Taken" is the state the engine is in for the few seconds after a
penalty-shootout kicker has struck the ball, while it is still live and the keeper needs to
react.

## What the system does

### Standing position - `UpdateKeeperPosition`

Every frame, before anything else happens, the keeper is given a target point (`desx`,
`desy` - the same destination fields every player has; some other, not-yet-documented movement
function walks him toward it). What that point is depends on match state:

* **Any state other than In Play, Shoot-Out, or Shoot-Out Taken** (kick-offs, throw-ins, free
  kicks, corners, goal kicks, after a goal, match over): go straight to the centre of his own
  goal line.
* **Shoot-Out or Shoot-Out Taken (9, 10)**: stand roughly on the goal line, 5 pixels off it,
  centred - unless his own team currently has the ball (`ball.teaminpossession = Self.teamid`),
  in which case he is offset sideways by an amount read from an unnamed Global
  (`g_engine_int103`, address 0x00C5D64C) whose value has not been read yet.
* **In Play (1)**, the interesting case, splits three ways:
  1. **He is already holding the ball** (`KeeperHoldingBall()` true) and the match clock is
     still within **750** clock units of `keepercatchtime` (the moment he caught it): stand
     exactly where he is (`desx = Self.x, desy = Self.y`). He does not walk anywhere while he
     is holding the ball and the catch is still fresh.
  2. **Still holding it, catch is more than 750 units old**: start walking back out from the
     goal line. The distance he steps out from a base offset (`g_player_int19`, value not yet
     read) wobbles by a small, cyclic amount rather than a real random roll - see the quirks
     section below; two-thirds of the time he steps forward 1.5 yards extra, one-third of the
     time he steps back 1 yard.
  3. **Not holding the ball**: this is the normal "come off your line" logic. He first picks a
     default spot - an arc **6 yards** out from the point on his goal line nearest the ball
     (**3 yards** if the match is a training session, `g_training_int03 <> 0`), angled to face
     the ball. Then, depending on what the ball is doing, that default can be overridden:
     * **Loose ball nobody controls, inside his own penalty box**: he will break from the arc
       and charge the ball (`InterceptBall`) if it is simply within **6 yards** of him - or, for
       a fast, high ball (velocity > 3.0, height above twice his own max jump height, and within
       **10 yards** of the ball's `jumpx`/`jumpy` target point - a predicted landing spot for
       crosses/high balls, not yet named in the reflection data) if it is heading somewhere
       dangerous. This is the "come and claim the cross" behaviour.
     * **An opponent is running with the ball, not in training mode, and that opponent is
       within 30 yards of goal**: check whether it is a clean run at goal
       (`TPlayer.CleanThrough`, slot 0xe4, on the attacker). If it is, and the predicted ball
       path threatens the goal mouth, or the attacker is already inside 12 yards, the keeper
       abandons his arc and goes to smother it (`InterceptBall`). If it's a clean run but not
       yet dangerous enough, he doesn't commit - he narrows his arc, standing at a radius equal
       to **half the attacker's own distance to goal**, i.e. he edges forward as the attacker
       advances without fully coming out.
     * **Nothing of the above**: he just holds the standard 6/3-yard arc.

### Coming off the line to make a save - `DoKeeperDiveAI`

This is separate from positioning: it decides whether to actually dive/jump/catch. It only
runs in states **In Play (1)** and **Shoot-Out Taken (10)**, and bails out immediately if there
is no ball, the ball is already in the net, the keeper isn't on his feet, he just kicked the
ball himself (within 300 clock units), he's outside his own penalty box, or he's already
holding the ball.

**Shoot-Out Taken (state 10)** - the penalty-shootout reaction:

Triggers once the ball is within **8 yards** of the keeper, still in play, and wasn't last
touched by the keeper himself. He then picks a save at random:

| Roll (`Rand(1,6)`) | Chance | Action |
|---:|---:|---|
| 1 | 1/6 (16.7%) | `KeeperCatchHigh` (stands and catches) |
| 2 | 1/6 (16.7%) | `KeeperJump` |
| 3, 4, 5, 6 | 4/6 (66.7%) | `KeeperDive`, with a further `Rand(0,2)` picking the dive's height/animation variant (so each of the three dive sub-types is 2/6 ≈ 22.2%) |

Dive side/power (`intercept_AB`, consumed by `KeeperDive` below) is `Rnd(0,1)` - a random float
0-1, low = left, high = right, no bias toward either side by default.

If it is the human-controlled captain's shoot-out kick to face, keyboard/joystick input
overrides the dice: **Down forces a catch, Up forces a jump, Right forces a full-power dive
right, Left forces a full-power dive left** - checked in that order, so pressing both Up and
Down picks Up, and pressing both Left and Right picks Left (last write wins; see the codegen
note in `DoKeeperDiveAI.bmx` about the left-binding being checked first for the joystick/keyboard
mode switch too).

**In Play (state 1)** - reacting to a live ball:

The function projects the ball's flight forward frame by frame (applying ball friction and
gravity, and curl if nobody currently controls it) against a 15-yard-wide line drawn through the
keeper, perpendicular to the goal (7.5 yards each side of him). It also tracks two lines just
outside each goalpost; if the ball's projected path crosses either of those first, the function
gives up immediately - the ball is going well wide, no action needed.

Once the projected path crosses the keeper's line, the height at that crossing point classifies
the incoming ball:

| Height at crossing | Type (`dtype`) |
|---|---|
| ≤ half the keeper's max jump height | 0 - low |
| > half, ≤ full max jump height | 1 - medium |
| > full max jump height | 2 - high |

Then, only if the crossing point is inside the penalty box and the keeper is within **3 yards**
of the ball already:

* **Dive**, if the eventual distance to the ball will be **≥ 0.75 yards** and it isn't a
  detected "crossing" ball (`ball.Crossing()`) and the ball is either still moving fast
  (velocity > 1.0) or currently under someone's control.
* Otherwise, if the eventual distance is **< 2.5 yards**, pick a save by the height classified
  above, each gated by its own distance:
  * low (0): `KeeperCatchLow` if within **1.0 yard**
  * medium (1): `KeeperCatchHigh` if within **5.0 yards**
  * high (2): `KeeperJump` if within **6.0 yards**

### The dive/jump/catch animations themselves

`KeeperDive`, `KeeperCatchLow`, `KeeperCatchHigh`, and `KeeperJump` (all VERIFIED, tiny
functions) just pick the animation table and, for dive/jump, set a vertical launch speed:

* `KeeperDive(point, type)`: `type` 0 = no vertical launch (along the ground), 1 = half the
  keeper's jump-speed constant, 2 = full jump-speed constant. It also works out which way to
  face: if the keeper is already moving sideways fast (`xvel` beyond ±1.0) he dives the way
  he's already moving; otherwise, if he's within 5 yards of where the ball was last kicked from,
  the dive side is a fresh coin flip (`Rnd(0,1)`, reusing the same `intercept_AB` field the
  shoot-out roll uses). Horizontal dive speed is `distancetoball / 30.0`.
* `KeeperJump`: sets vertical speed to the full jump-speed constant (`g_player_float08`,
  address 0x00C5DE5C - value not yet read out of the binary, but confirmed to be the *same*
  Global `KeeperDive`'s "full power" case uses).
* `KeeperCatchLow` / `KeeperCatchHigh`: no vertical speed at all - pure animation swap.

`KeeperDiving`, `KeeperJumping`, and `KeeperHoldingBall` are the read side: pure animation-frame
lookups (no game logic) used elsewhere to ask "is this player currently diving / jumping /
holding the ball". Each checks the player's current frame number against a short list of frame
indices, tried three times (frame, frame+64, frame+128) - the sprite sheet apparently repeats
the same pose at three 64-frame offsets, presumably per-direction or per-kit variant.

### What happens when the ball actually reaches him - `CheckKeeperSave`, `TBall.Parry`, `BlockSave`

`CheckKeeperSave` is the entry point once contact is made. First, if he's close enough to his
own goal (within 18 yards) and the ball is moving fast or controlled, it plays a crowd/keeper
sound. Then:

1. **Ball already controlled by someone** (a defender in the way, a rebound already claimed):
   `BlockSave()` instead - punch it away with kick power **2.0** in his own facing direction,
   unless his current animation is already the "dive" table (then he does nothing further this
   frame; the game lets the dive animation finish).
2. **His current animation is a specific keeper-catch table**: clean catch - 
   `ball.NewController(Self)`.
3. **Ball velocity exceeds a threshold** (`g_player_float14`, value not yet read): too hot to
   hold - `ball.Parry(Self)`.
4. **Otherwise**, if the ball was last kicked from close range (`g_player_float15` yards,
   value not yet read) and is still moving faster than half that same velocity threshold:
   also a `Parry`. Anything slower/further than that: a clean catch (`NewController`).

`TBall.Parry` is where a save that isn't a clean catch is actually resolved into a deflection - 
byte-exact and unusually detailed:

* **If the keeper is mid-dive** (`KeeperDiving()` true) and already moving sideways
  (`xvel` non-zero): the ball is tipped, not caught - "Tip left"/"Tip right". Its speed drops to
  **30-40%** of what it was (`Rnd(0.3,0.4)`), and its new direction is the keeper's own facing
  plus a random **±25°** scatter.
* **Otherwise, if the ball is well above the keeper's reach**
  (`ball.z > keeper.z + 0.8 × g_keeper_maxheight`):
  * If the keeper's current animation is the specific "high claim" table *and* he is within 1
    yard of whoever last kicked it: a **Punch** - the ball pops up with `zvelocity = Rnd(2.5,3.5)`
    and is redirected via `ATan2` using a heavily damped forward component (`cos(direction) *
    0.1`), i.e. mostly straight up and slightly forward.
  * Otherwise, a plain **Parry**: ball speed drops to **70%**, it pops up
    (`zvelocity = Rnd(2.5,3.5)`), direction is the keeper's own facing plus **±15°** scatter,
    and the keeper's own animation is forced into the "parry" pose.
* **Otherwise ("Tip over")** - the ball is at a height the keeper can control: speed drops to
  **45-65%** (`Rnd(0.45,0.65)`), and direction comes from `ATan2` using the keeper's own current
  sideways speed (`xvel × 2.0`) - i.e. the parry tends to squirt away in whichever direction the
  keeper was already moving. Keeper's animation is again forced to the "parry" pose.

Every branch of `Parry` also calls `CheckLongShotRating()` on the ball (feeding whoever shot it
a rating contribution) and plays a save sound, and bumps one of two per-team counters
(`g_engine_int31`/`g_engine_int32`, purpose beyond "count of parries conceded" not confirmed).

### Reach and possession bookkeeping

* `GetKeeperHandHeight` answers "how high up can this keeper's hands reach right now", read from
  his current animation frame. If he is the **human-controlled** player (`selectionno > 0`) it
  doesn't even look at the animation - it unconditionally returns **100.0**, always at full
  reach. For the CPU keeper, the answer depends on which of three specific frames he's
  currently showing: **40 × the draw scale, plus his current height**, or **50 × scale + height**,
  or just his current height (ground level) for the third, and **0.0** for any other frame (not
  a reaching pose at all).
* `KeeperHoldingBall` is the general "is he holding it" test used all over (by `CheckKeeperSave`,
  positioning, etc.): true whenever his selection index is the AI default (`selectionno <= 0`)
  and his current animation is one of seven specific tables - some unconditionally count as
  holding, two of them (the dive-catch tables) only count if the ball object confirms
  `controlledby = Self`.
* `ValidateKeeperAnim` re-tags a keeper's animation between an "attacking-side" and a
  "defending-side" table pair (six such pairs) depending on whether the global ball is currently
  controlled by this player with no backpass flag set - this is what keeps the correct mirrored
  animation set active as possession changes hands.
* `GetOppKeeper` finds the opposing team's keeper by scanning its squad for the player whose
  `selectionno` is 0 (the AI-controlled slot) - used by other systems (e.g. shooting logic) that
  need to know who the keeper actually is without a dedicated "is keeper" flag.
* `TBall.KeeperHolding` / `TBall.KeeperImageHolding` are the ball-side mirror: "does whoever
  controls me count as a keeper holding the ball", checked either by animation table
  (`KeeperHoldingBall`) or, for `KeeperImageHolding`, directly by current image/frame
  (`ImageHoldingBall`, not covered here).

## What it means in play

The keeper's positioning is genuinely reactive, not scripted: every frame he re-derives a target
point from the ball's live position, so he visibly slides along his 6-yard arc as play moves
side to side, and noticeably steps forward when an attacker with a clean run gets inside 12
yards. He will not fully commit to closing an attacker down until either the ball's predicted
path threatens the goal, or the attacker is already close - outside that he edges out, he
doesn't charge.

Once a shot is genuinely goal-bound, the keeper's actual save (dive vs jump vs catch) is decided
by a **height classification of where the ball crosses his line**, not by shot power or by any
notion of a "save skill" stat - the functions read here never touch a goalkeeping attribute.
Whether a save is held clean or spilled turns almost entirely on **ball speed and, for aerial
balls, how far above the keeper's reach it is** - a fast, low shot from close range is very
likely to be parried rather than caught (`CheckKeeperSave`'s velocity threshold), and a keeper
already diving sideways will only ever tip the ball, never hold it (`Parry`'s dive branch always
tips, never catches).

The human-controlled keeper is measurably different from the CPU one in two concrete ways: full
reach at all times (`GetKeeperHandHeight` returns 100.0 unconditionally, skipping the frame
check entirely), and full manual override of the shoot-out dive roll (dive direction and type
become a direct key/stick press rather than a 1-in-6 random pick). Outside a shoot-out, though,
there is no player-input branch in `DoKeeperDiveAI`'s in-play dive logic at all - during normal
play the human "goalkeeper" is being played by the same AI as everyone else's keeper, and the
player only really takes over once the ball is already at the keeper's feet or a shoot-out kick
is being faced.

## What we do not know yet

* **The exact values of several thresholds.** `g_player_float14` and `g_player_float15`
  (`CheckKeeperSave`'s "too fast to hold" velocity and "how close the last kick has to be"
  distance), `g_keeper_maxheight`'s actual number, `g_engine_int103` (the shoot-out sideways
  offset), and `g_player_int19` (the base "walk back out" distance) are all named Globals whose
  *use* is proven byte-exact but whose literal *value* has not been read out of the binary yet.
  `scripts/check_floats.py`, which already found several placeholder constants elsewhere in this
  subsystem (see the quirks below), would resolve these the same way.
* **`UpdateKeeperPosition` is unverified.** It's a READ-tag decompile, not a byte-matched body - 
  the overall shape (three states, three sub-cases of In Play) is clear, but nobody has byte-
  matched it against the original yet, so treat the exact arithmetic (especially the
  `CleanThrough` / narrowing-arc branch) as a solid *lead*, not a proven fact. Reconstructing and
  verifying `TPlayer.UpdateKeeperPosition` @ 0x004f2eed properly is the single highest-value next
  step for this document.
* **What actually moves the keeper toward `desx`/`desy`.** Every positioning function here only
  sets a destination; some other, undocumented movement function (likely something in the same
  family as `TTeam.UpdatePlayerDestinations`, itself a listed gap in `docs/game/README.md`)
  presumably walks him there over subsequent frames, at some player-specific speed. That
  function has not been identified.
* **What `ball.jumpx`/`jumpy` actually get set to.** The object model confirms the field names
  (`TBall.jumpx`/`jumpy` at +0x38/+0x3c) and `UpdateKeeperPosition` reads them as a target point
  for coming for a high ball, but no function that *writes* them has been identified yet, so we
  don't know exactly what event computes that target (a specific cross? any high pass?).
* **`g_engine_int31`/`g_engine_int32`**, bumped once per `Parry` by team - plausibly a save
  counter feeding match stats, not confirmed against any UI or stats screen.
* **Goalkeeper attributes.** Nothing read here ever touches a rating/skill field on the keeper - 
  every decision is geometric (distance, height, angle) or a flat random roll. Whether keeper
  ability affects saves anywhere else in the game (e.g. a modifier applied before
  `CheckKeeperSave` is even called, or in whatever decides `ball.velocity` on the shot itself) is
  outside the functions covered here and remains open.

## Quirks worth preserving exactly

* **The "walk back out" wobble is not random - it's a modulo-3 cycle, and one of its three
  branches is dead code.** `UpdateKeeperPosition`'s post-catch repositioning reads a counter
  (`g_engine_int20`) and does `Select g_engine_int20 Mod 3`: for remainder 0 or 1 it steps
  forward 1.5 yards, for remainder 2 it steps back 1 yard - a 2:1 forward bias, not a coin flip.
  But the decompiled shape is actually a *nested* pair of `< 2` / `< 3` checks, and because the
  outer `< 2` test already guarantees the inner `< 3` test, the inner test's `else` branch
  (subtract 2.5 yards) can never execute. It is dead in the original binary. Reproduce the
  observable behaviour (2/3 forward-1.5, 1/3 back-1) rather than "cleaning up" the nesting into
  something that would make the dead branch reachable - that would change the game's behaviour,
  not just its style.
* **`TBall.Parry`'s "Tip over" branch computes `Cos(Self.direction)` and throws the result
  away.** That's confirmed from the disassembly (`fstp st(0)`, no store) - a genuine original
  bug/dead calculation, not a transcription error. Keep the call, drop the assignment, exactly
  as the recovered body does.
* **Two float constants in this subsystem were originally miscopied during reconstruction and
  had to be corrected against the exe's actual bytes**, because the byte-oracle used in this
  project masks `.rdata` *addresses*, so any float of the right width matches equally well until
  checked by value: `BlockSave`'s kick power is **2.0**, not 12.0; `GetKeeperHandHeight`'s two
  reach constants are **40.0** and **50.0**, not the `12.0`/`8.0`-scale placeholders first
  written. If you're pulling numbers from other not-yet-value-checked functions in this
  subsystem, treat any float literal as provisional until `scripts/check_floats.py` (or
  equivalent) has confirmed it.
* **Shoot-out input priority is last-write-wins, not first-match.** Pressing Up and Down
  together in a shoot-out picks Up; pressing Left and Right together picks Left. This falls out
  of the four `If` statements being independent and unconditional (not an `ElseIf` chain) with
  Up checked after Down, and Left checked after Right - reproduce the same statement order, not
  a priority list.
* **The joystick/keyboard split for shoot-out diving is decided once, by the LEFT binding
  only** (`g_opt_ctrlleft[1] = -1` selects analog-stick mode for *all four* directions, not just
  left). That asymmetry is in the original and both `DoKeeperDiveAI`'s provenance notes and this
  document flag it as deliberate to preserve, not simplify into "check each direction's own
  binding independently".
