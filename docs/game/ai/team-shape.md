# How the team moves as a unit

> **Source:** `TTeam.UpdatePlayerDestinations` @ 0x004de516 (READ) · `TTeam.Update` @ 0x004de0a2 (VERIFIED) · `TTeam.UpdateLocalPlayer` @ 0x004de0c7 (READ) · `TFormation.GetPlayerXY` @ 0x004d8b85 (READ) · `TFormation.GetCol` @ 0x004d8aa4 (VERIFIED) · `TFormation.GetRow` @ 0x004d8aba (VERIFIED) · `TFormation.GetColFromSelectionNo` @ 0x004d8b3c (VERIFIED) · `TFormation.GetRowFromSelectionNo` @ 0x004d8af3 (VERIFIED) · `TFormation.LoadTactics` @ 0x004d8783 (VERIFIED) · `TFormation.SetUp` @ 0x004d80c2 (VERIFIED) · `TTeam.GetWallLocation` @ 0x004e0a62 (VERIFIED) · `TTeam.GetShootingDirection` @ 0x004e1914 (VERIFIED) · `TTeam.ResetCornerFormation` @ 0x004ddfb2 (VERIFIED) · `TTeam.ChangeFormation` @ 0x004ddf60 (VERIFIED) · `TTeam.GetTunnelPositions` @ 0x004e08e8 (VERIFIED) · `TTeam.GetShootoutPositions` @ 0x004e0954 (VERIFIED) · `TTeam.GetMatchOverPositions` @ 0x004e09db (VERIFIED) · `TTeam.ForcePositionReset` @ 0x004e0b9f (VERIFIED) · `TTeam.GetPlayerNearestToXY` @ 0x004e19d8 (VERIFIED) · `TTeam.GetLosingBy` @ 0x004e1eb2 (VERIFIED) · `TTeam.NewLocalPlayer` @ 0x004de470 (VERIFIED) · `TPlayer.Compare` @ 0x0050379f (VERIFIED) · `TPlayer.ChaseBall` @ 0x004f94b9 (VERIFIED) · `TPlayer.GetCoveringLocation` @ 0x004f96a1 (VERIFIED) · `TPlayer.MoveYardsClear` @ 0x004f9cf5 (VERIFIED) · `TPlayer.UpdateJoyAI` @ 0x004f1d08 (VERIFIED) · `TPitch.YardsToPixels` @ 0x004e9fdb (VERIFIED) · `TPitch.InsidePenaltyBox` @ 0x004e9e5e (VERIFIED) · `TPitch.InsideCrossZone` @ 0x004e9f32 (VERIFIED) · `TPitch.ValidateOnPitch` @ 0x004ea029 (VERIFIED) · `TEngine.GetStringMatchState` @ 0x004d7a8e (VERIFIED)
> **Confidence:** MEDIUM overall - HIGH for every piece built on a byte-matched body (the match-state table, the wall geometry, the corner-crowd randomiser, the defensive sort keys, the pitch scale); MEDIUM for the two length-exact-but-not-byte-exact near-misses this document leans on most (`UpdatePlayerDestinations` itself and `TFormation.GetPlayerXY`), where the overall shape is trustworthy but a handful of individual comparisons are still one `setcc` bit away from proven; LOW for the one self-contradictory guard flagged below, whose real-world effect is not established.
> **Last checked:** 2026-08-15

`TTeam.UpdatePlayerDestinations` is the second-largest function in the game (9,170 bytes) and
it is the single place that decides, for every player on a side except the one a human is
driving, *where on the pitch they currently want to be*. It runs once per team per tick, and
its two Float outputs - each player's `desx`/`desy` (`TPlayer` +0x7c/+0x80) - are exactly the
values `TPlayer.UpdateJoyAI` reads to aim that player's joystick (see
`docs/game/ai/player-decisions.md`). This document is about how those two numbers get chosen.
It is a **near-miss reconstruction**: length-exact against the original (9,174 of our bytes vs
9,170 original - a 4-byte residue from two still-unexplained `fxch` instructions that do not
change any value) with every other byte aligned, so the *logic* below is read directly off
real BlitzMax source, not guessed from a decompile. It is tagged READ rather than VERIFIED
only because the byte oracle hasn't closed the last few bytes - see "What we do not know yet."

## What the system does

### Two jobs, once per team per tick

`TTeam.Update` (VERIFIED, 37 bytes) is the entire per-team tick:

```blitzmax
Method Update:Int()
    UpdatePlayerDestinations()
    UpdateLocalPlayer()
End Method
```

`UpdatePlayerDestinations` decides where all eleven shirts want to run. `UpdateLocalPlayer`
decides, only for a human-controlled team, which one of those eleven the joystick is currently
plugged into. They are covered in that order below.

### `UpdatePlayerDestinations` - the pipeline

Every tick works through the same nine stages. Later stages can overwrite what an earlier
stage wrote; a few short-circuit the rest of the function entirely.

```
A. Find the ball; decide a provisional "chase" flag for this team
B. Switch on the 12-value match state - 4 states return immediately,
   4 more nudge the shared reference point/scale before continuing
C. Fan every outfielder out from that reference point through the
   formation grid; route the keeper, subs and sent-off players elsewhere
D. (Corner only) overwrite with the random corner "crowd"
E. (a training minigame only) overwrite via TTraining
F. if there is no ball at all, stop here
G. (a dead ball is live) position the taker, the taker's buddy, and
   - for a close free kick - build a defensive wall; pull everyone
   else 10 yards from the ball
H. (Goal! state, and the human's created player is on this team)
   overwrite with the celebration swarm, OR:
I. (open play only) possession logic: loose ball / we have it /
   they have it, the last case building a press-cover-mark shape
J. (open play only) clamp every target back onto the pitch
```

Match-state numbers are the 12-value enum pinned down by `TEngine.GetStringMatchState`
(VERIFIED) - the same global, `0x00C5B1FC`, that `docs/game/ai/player-decisions.md` and
`docs/game/ai/goalkeeper.md` call `g_player_int01`; this document calls it `g_matchstate` as
the near-miss candidate itself does.

| Value | State | Stage B does this before the fan-out | Extra layer after the fan-out |
|---:|---|---|---|
| 0 | Tunnel | - | `GetTunnelPositions(0)`, **returns immediately** |
| 1 | In Play | nothing | full possession logic (stage I) |
| 2 | Centre (kick-off) | pulls the reference point 35 yards into this team's *own* half (`desy = -35yd × dir`) | set-piece taker/buddy nudge (stage G) |
| 3 | Throw-In | nothing | stage G |
| 4 | Free Kick | see "the two 45-yard zones" below | stage G, incl. the wall |
| 5 | Corner | `desx = 0`, `scale = 2.0` | corner crowd (stage D), then stage G |
| 6 | Goal Kick | `desx = 0`, `desy = 0`, `chase` dropped | stage G |
| 7 | Penalty | nothing | stage G |
| 8 | Goal! | nothing (still runs the normal fan-out first) | **replaces** stage I with the celebration swarm - only for the team the human's created player belongs to |
| 9 | Shoot-Out | - | `GetShootoutPositions()`, **returns immediately** |
| 10 | Shoot-Out Taken | - | `GetShootoutPositions()`, **returns immediately** |
| 11 | Match Over | - | `GetMatchOverPositions()`, **returns immediately** |

Stage J (`TPitch.ValidateOnPitch`, clamping every outfielder's target back inside the pitch
rectangle) and the whole of stage I only run when the state is exactly 1 (In Play) - states
2-7 get the formation fan-out and (where relevant) the set-piece layer, but never the
possession/marking refinement.

### Stage A - reading the ball

`chase` starts at 0. If this team's own player is currently holding/controlling the ball,
`chase = 1` - **unless** it's normal play, the goalkeeper isn't holding it, and the ball sits
inside this team's own penalty box or "cross zone" (`TPitch.InsidePenaltyBox` /
`InsideCrossZone`, both VERIFIED axis-aligned rectangle tests in pixel space - 1 yard = 10
pixels, `TPitch.YardsToPixels`, VERIFIED), in which case `chase` drops back to 0. If the
*other* team has the ball, `chase = 1` only if the ball is in this team's own box during
normal play, or unconditionally if it's in the cross zone. `desx`/`desy` start as the ball's
own position.

### Stage B - the two 45-yard zones (Free Kick, state 4)

```
d1 = distance from the ball to this team's own goal
d2 = distance from the ball to the opponent's goal
If 45 yards < d1:
    chasing?  -> drop the point to (0,0) and stop chasing
    not chasing? -> scale = 3.0
ElseIf 45 yards < d2:
    chasing?  -> scale = 3.0
    not chasing? -> drop the point to (0,0) and stop chasing
```

`scale` feeds straight into the formation grid (stage C) as a width-compression factor:
**1.0 is normal spacing, 2.0 (corners) and 3.0 (the more distant of the two free-kick zones)
squeeze the horizontal spread of the formation.** It is a divisor inside
`TFormation.GetPlayerXY` (`wSpacing = pitchWidth / (formationWidth × scale)`), so a *bigger*
`scale` produces a *narrower* shape - worth remembering, because it reads backwards on a
first pass.

### Stage C - the formation grid

Every outfielder with `selectionno` 1-10 is handed to `formation.GetPlayerXY(selectionno,
desx, desy, pitchWidth, pitchHeight, dir, chase, →desx, →desy, scale, 1.0)`. `selectionno 0`
(the keeper) is routed to `TPlayer.UpdateKeeperPosition` instead (see
`docs/game/ai/goalkeeper.md`); anyone with `selectionno > 10` (an unused squad member) or a
red card is sent to the tunnel (`TPlayer.GetTunnelPosition`). One extra branch:
`g_trainingmode = 9` redirects every outfielder toward the human-controlled player's own
position instead of the formation slot - a practice mode, out of scope here (see
`docs/game/career/training.md`).

`TFormation.GetPlayerXY` is itself a **length-exact near-miss** (2,898/2,898 bytes, 3 known
same-length substitutions remaining, all `setae`/`setbe` swaps that do not change any value it
returns). What it does: the 13 shipped `.tac` files (`EngineMedia/Tactics/*.tac`) are each 35
lines of `0`/`1` - a 7-column × 5-row pitch-zone grid (`TFormation.GetCol` = `i Mod 7`,
`GetRow` buckets `i` into `<7 / <14 / <21 / <28 / else` → rows 0-4, both VERIFIED). Every
shipped file carries **exactly 10 ones** - the outfielders; the keeper isn't part of the grid.
`selectionno` is assigned in file order: the *n*-th `1` found becomes `selectionno n`. As one
concrete example, `4-4-2 A.tac` has its ten ones split 4 in row 0, 4 in row 2, 2 in row 4 - the
back four, midfield four, and strike pair of a 4-4-2, in that reading order.

For a given `selectionno`, `GetPlayerXY` looks up that slot's row/column, then:
* turns column into a lateral offset (`xOff`, scaled by `wSpacing` and a per-column width
  multiplier, widest at the touchline columns and narrowest through the middle);
* turns row into a depth offset (`yOff`), separately tuned for whether the ball is "with" or
  "without" the team (`chase`) and pushed further forward for the wide columns of the front
  three rows when the ball is out wide (`wideplayerpush`);
* blends that pure grid position with the ball-relative point via two more Engine.ini ratios,
  `xshift`/`xshiftnoball` for the lateral axis and a single `yshift` for depth.

All of these come from `EngineMedia/Inc/Engine.ini` (read once, at `TFormation.SetUp`,
VERIFIED):

| Engine.ini key | Value | Used for |
|---|---:|---|
| `formationheight` | 10 | row-to-row vertical spacing divisor |
| `formationwidth` | 24 | column spacing divisor, **with** the ball |
| `withoutballformationwidth` | 26 | column spacing divisor, **without** the ball |
| `wideplayerpush` | 1.1 | extra forward push for wide-column players when the ball is wide |
| `formationdepth` | 1.0 | whole-line depth shift toward the ball |
| `formationxshift` | 1.0 | lateral blend factor, **with** the ball (1.0 = snap fully to the grid slot) |
| `withoutballformationxshift` | 1.25 | lateral blend factor, **without** the ball (80% grid / 20% ball-relative) |
| `formationyshift` | 2.75 | depth blend factor (≈36% grid / 64% ball-relative, always) |
| `ymarginmultiply` | 2.0 | doubles the row-0 vertical margin during In Play specifically |

Two things worth noting even at MEDIUM confidence (the formula, not just the constants, is
read from the near-miss body): because `formationwidth` (24) is *smaller* than
`withoutballformationwidth` (26) and both are divisors, the team actually spreads **wider**
while engaged with the ball and pulls slightly tighter once settled - the opposite of what the
key names alone would suggest. And depth (`yshift = 2.75`, a single constant for both cases)
tracks the ball far more loosely than width does (`xshift = 1.0` when chasing pins the x-axis
exactly to the grid slot) - sideways shape is closer to rigid, forward/back shape is fluid.
Deriving the full row/column offset table (every `xOff`/`yOff`/scale value for all 35 cells)
belongs to a dedicated formations document, not here.

### Stage D - the corner "crowd"

Only when `g_matchstate = 5`. `TTeam.ResetCornerFormation` (VERIFIED) builds a fresh random
set of 4 or 5 points (`Rand(4,5)`) whenever a corner starts: each point sits ±12 yards
laterally (`Rand(-12,12)`) and 8-18 yards in front of the goal line (`YardsToPixels(Rand(8,18))`,
measured from the goal line inward, then mirrored by `GetShootingDirection`) - the classic
crowd of runners piling into the six-yard box. `UpdatePlayerDestinations` then walks that list
against the squad: if this team is taking the corner, `selectionno (11 - n)` for the *n*-th
point gets sent there; if defending, `selectionno (n + 3)` gets the same X but a mirrored Y.

### Stage G - dead balls: taker, buddy, wall

Gated on `TEngine.SetPiece()` being true and a taker already assigned (taker/buddy selection
itself - who gets picked - is `TTeam.GetSetPieceTakers`, VERIFIED, and belongs to a set-pieces
document, not this one). Given a taker:

* **Kick-off (state 2):** taker stands 0.5 yards from the ball; buddy stands 3 yards back.
* **Throw-in (state 3):** the buddy's standoff cycles through three distances as
  `g_matchtimer Mod 4500` advances - 12×8 yards for the first 1,500 ticks of the cycle, 16×12
  yards for the next 1,500, then 8×4 yards for the remainder - a small "make a run" wobble
  rather than a fixed spot.
* **Everything else (default):** taker stands 0.5 yards behind the ball along their own facing
  direction; buddy stands a fixed 10×5 yards away.
* **Kick-off only, one more nudge:** the buddy's Y is forced to at least 10 (not 10 *yards* - 
  the literal is bare `10.0`/`-10.0`, one yard) on the attacking side of the line, so the
  buddy never straddles the wrong half at kick-off. Everywhere else in this function a
  distance like this is wrapped in `YardsToPixels(...)`; this one pair is not - worth
  preserving exactly, not "fixing" to ten yards.

**The wall** only forms defending a free kick (`g_matchstate = 4`, opponent has the ball), and
only grows one player at a time as the kick gets closer to this team's own goal:

| Distance from ball to own goal | Wall gets |
|---|---|
| < 60 yards | `selectionno 10` |
| < 50 yards | + `selectionno 8` |
| < 40 yards | + `selectionno 7` |
| < 35 yards | + `selectionno 6` |
| < 30 yards | + `selectionno 5` |

`TTeam.GetWallLocation` (VERIFIED) places each of those five slots along an arc 10.2 yards
from the ball, fanned out from a reference bearing at 0°, +5°, −5°, +10°, −10° (slots 5,4,3,2,1
respectively) - a wall that starts as one covering defender at long range and fills in toward
five players shoulder to shoulder inside 30 yards.

Finally, unconditionally whenever a dead ball is live: every outfielder who isn't the taker or
buddy gets `TPlayer.MoveYardsClear(10.0, ball.x, ball.y)` (VERIFIED) - the game reproduces
football's actual ten-yard law directly, as a distance check, not a rule enforced by a
referee. For goal kicks, penalties and shoot-outs specifically, everyone's Y is additionally
clamped to a goal-mouth band so nobody drifts to the wrong side of the goal while the ball is
dead.

### Stage H - the Goal! celebration (state 8)

Only runs for the team the human's created player ("the newstar," `g_newstar`, `TPlayer`
@ `0x00C5B248`) belongs to; the opposing team gets no special treatment here at all. Within
that team's squad, every player *except* one specific match is sent to swarm the newstar:

```blitzmax
ang = AngleTo(p.x, p.y, newstar.x, newstar.y)
p.desx = newstar.x + Cos(ang + 180 + selectionno*5) * 2 yards
p.desy = newstar.y + Sin(ang + 180 + selectionno*5) * 2 yards
```

 - every teammate within 40 yards converges to within 2 yards of the newstar, fanned out by
`selectionno × 5°` apiece so they don't all stack on the same spot. The one excluded match
(`p = newstar And p.newstar = 0`, see "quirks" below) is meant to give the newstar himself
something to do: chase the loose ball if the team is losing by more than a goal (or losing at
all and 70 ticks have passed), otherwise cycle every few ticks through three fixed patrol
spots (`g_enginetick Mod 3`) roughly a half-pitch-width out to either side.

### Stage I - open play: press, cover, and mark (state 1 only)

Three mutually exclusive cases, checked in order:

1. **Loose ball, nobody in control:** the player the ball was last passed toward tries to
   intercept it (`TPlayer.InterceptBall`); failing that, whichever of this team's players is
   physically nearest the ball's effective position does, provided they aren't already the
   goalkeeper standing off their line.
2. **This team has the ball:** the ball carrier dribbles (`TPlayer.DoDribbling`); any teammate
   within 15 yards of the carrier's own target point is re-run through the formation grid
   pushed 15 yards further forward, so support doesn't bunch directly on top of the carrier;
   separately, anyone within 30 yards of the ball who currently isn't a viable pass option
   (`passison = 0`) is nudged away from their assigned marker via `TPlayer.DoRepulsion` (not
   examined for this document), with a push strength of `2.5 × pitchscale` (≈2.5 yards).
3. **The other team has the ball**, and this team is either fully CPU-controlled (`controller
   = 0`) or a human is only puppeting the newstar (`newstarselno > 0`) - i.e. this block is
   skipped for a fully human-switched team, since the human is assumed to be doing the
   marking themself. When it runs:
   * The squad is sorted by `TPlayer.Compare`'s **key 13** (VERIFIED): rank by distance to the
     ball, but double the effective distance of anyone not already goal-side of the ball
     (`goalside = 0`). The closest-ranked eligible player presses the ball
     (`TPlayer.ChaseBall`); the next covers behind them (`TPlayer.GetCoveringLocation`).
   * If neither of those two happened to already be goal-side, the squad is re-sorted on
     **key 10** (pure distance to ball, no goal-side weighting) and the closest remaining
     goal-side-eligible player is added as a third body via `ChaseBall` as well.
   * Every opponent within 45 yards of *their own* attacking goal is treated as a threat; each
     one is greedily assigned the nearest still-unassigned teammate (excluding the three
     players just picked), who is sent to that opponent's predicted position (`metax`/`metay`)
     rather than their exact current spot - man-marking the dangerous end of the pitch.

## What it means in play

The team's shape is not a fixed formation glued to the pitch - it is a formation **recentred
on a moving point every tick**, and that point itself moves depending on the match state and
whether the team currently reads as chasing the ball. In open play that point is simply the
ball; at a kick-off it snaps 35 yards into the team's own half; near a free kick it can
collapse to the centre spot or squeeze to a third of its normal width depending on which zone
the ball is in. This is why the on-pitch shape visibly "breathes" around the ball rather than
holding a rigid grid, and why teams look tighter and more urgent the closer play gets to their
own goal.

The defending trio (presser/coverer/third man) plus the 45-yard opponent-marking sweep is the
entire man-marking model in the game - there is no zonal defence beyond the formation grid
itself, and no marking assignment persists between ticks; it is recomputed from scratch every
tick from whoever is currently closest. A striker who loses their marker for one tick and
regains separation the next is not "losing" a defender in any lasting sense - the defensive
assignment has no memory.

Career mode only drives one player directly. Every other player on your own team, including
your strike partner and your own back four, is running exactly the same AI described here - 
`Self.controller = 0 Or Self.newstarselno > 0` is true for a human-controlled career-mode team
precisely because only the newstar is under direct control. The marking/pressing block above
runs for your teammates exactly as it does for the CPU side.

The ten-yard free-kick clearance, the growing defensive wall, and the throw-in "wobble" are
all small, deliberate pieces of real football etiquette reproduced as literal distance
checks - nobody enforces them; they are simply where the AI is told to stand.

## What we do not know yet

* **The exact bytes of `UpdatePlayerDestinations` and `GetPlayerXY`.** Both are length-exact
  near-misses; every remaining difference from the original is a same-length `setcc`
  substitution (a comparison direction, not a value), and none has been shown to change any
  number this document quotes - but neither function can be tagged VERIFIED until those close.
  See the header of `src/recovered_unverified/TFormation.GetPlayerXY.bmx` (the grid math)
  for exactly what is left.
* **Whether the "chase the ball if losing" newstar behaviour in stage H ever actually runs.**
  The guard is `p = g_newstar And p.newstar = 0` - the same object compared for identity
  *and* required to have its own `newstar` flag read false. That comparison is confirmed
  correct at the byte level (`sete`, not `setne`), so it is not a transcription error, but it is hard to see how an object can equal
  `g_newstar` while its own `.newstar` field disagrees. Whatever sets/clears `TPlayer.newstar`
  (not examined here - likely wherever `TProfile`/`TTeam.CreateSquadSimple` build the human's
  character) would resolve whether this branch is live gameplay or dead code.
* **The exact geometry of the penalty box and cross-zone globals** feeding
  `TPitch.InsidePenaltyBox`/`InsideCrossZone` - the functions themselves are byte-matched, but
  which Engine.ini key backs each of their three globals (`g_engine_int103`, `g_pitch_int11`,
  `g_crosszone_x/y` in the recovered bodies' own naming) hasn't been cross-checked against
  `TPitch.SetUp`'s declarations the way the formation-spacing constants above were.
* **What computes `TPlayer.metax`/`metay`** (the "predicted" position used as the marking
  target in stage I, and as the ball's effective position for interception) - used constantly
  in this function and its neighbours, never itself examined.
* **The rest of the formation grid** - the full 5-row × 7-column table of offsets and scale
  multipliers `GetPlayerXY` produces belongs in a dedicated formations document; this one only
  covers the constants that matter for team shape as a whole.
* **`TTeam.GetSetPieceTakers`** (who gets chosen to take a kick - shooting/passing stats,
  captaincy, human-override odds) and **`TTeam.CheckComManagement`** (substitutions) are both
  VERIFIED-adjacent near-misses this document deliberately did not expand on; they belong to
  set-pieces and manager documents respectively.
* **The exact enumeration of `TTeam.controller`.** Confirmed nonzero means "a human has an
  input device assigned to this team" and `1` specifically gates `NewLocalPlayer`'s
  ball-follow switching - whether other nonzero values exist (e.g. a second local pad) has not
  been checked.

## Implementation details worth preserving exactly

* **`scale` is a divisor, not a multiplier of spread.** A *larger* `formationwidth` setting or
  a *larger* `scale` argument produces a *narrower* shape on the pitch. Do not "fix" this to a
  multiplication when reimplementing - the corner (`scale=2.0`) and deep-free-kick
  (`scale=3.0`) cases are deliberately named for what they trigger, not for what the number
  intuitively suggests.
* **`p = g_newstar And p.newstar = 0`** (stage H) must be reproduced literally, including the
  apparent self-contradiction - see "what we do not know yet" above. Rewriting it to
  `p.newstar <> 0` "because that's obviously what was meant" would silently change which
  branch of the celebration logic ever fires.
* **The kick-off buddy's ±10 nudge is one yard, not ten** - the one bare numeric literal in a
  function that otherwise wraps every distance in `TPitch.YardsToPixels(...)`.
* **`TFormation.LoadTactics` stops reading a `.tac` file the instant it has found 11 `1`s**,
  leaving any further lines at their default (0). Every one of the 13 shipped files has
  exactly 10 ones, so this cap never binds in practice - but a hand-edited or modded 14th
  `.tac` file with more than 11 flagged cells would silently lose whichever ones sort past the
  11th line-order match, not the ones a human editor would expect (e.g. duplicates or
  out-of-range values).
* **The wall and taker/buddy code re-reads `ball.setpiecex`/`setpiecey` fresh at every one of
  the five `GetWallLocation` call sites** rather than caching it once - reproduced as five
  separate reads because that is what the original does, not because it is necessary.

## `TTeam.UpdateLocalPlayer` - who the joystick is pointed at

READ (decompiled, not byte-matched; not yet attempted as a near-miss). Runs only when
`Self.controller <> 0`. Two entirely different behaviours depending on `newstarselno`:

**`newstarselno > 0`** (the "always control my created player" setting is on): every tick,
every one of this team's players has `controller` forced to `1` if it *is* the newstar, is not
sent off, and is in the starting eleven, and `0` otherwise. This is a hard reset, not a
one-time assignment - it runs every tick, so nothing else can ever hand control to a different
player while this setting is active.

**`newstarselno <= 0`** (automatic ball-following control, e.g. exhibition/manager play):
looked at in priority order, using a handful of globals cross-confirmed against other verified
functions that share their addresses (`g_newstar` = `TPlayer` @ `0x00C5B248`, the same as
stage H above; `g_time` = `Int` @ `0x00C6EFD4`, the same match clock `TTeam.NewLocalPlayer`
reads):

1. If the match is in the Goal! state and the newstar plays for this team, control snaps to
   the newstar immediately.
2. Otherwise, if the ball isn't controlled by this team but was **just** kicked
   (`g_time < ball.kicktime + <a tolerance read from the exe, not yet named>`) toward a
   teammate who now holds it, control follows the ball to that receiving player.
3. Otherwise, if nobody is currently mid-pass to a teammate, and at least 500 ticks
   (`g_time`) have passed since control was last switched, and the human-controlled player
   (if any) isn't already close enough to the ball
   (`distancetoball < YardsToPixels(<value>)`) to be left alone, control switches to whichever
   of this team's players is currently nearest the ball's effective position - biased toward
   the ball's last kicker if that kick is recent and on-side.

The 500-tick cooldown is the load-bearing number here: it stops the automatic camera/control
target from flicking between players every single frame as the ball bounces around a contested
area, and is the same kind of "don't thrash" guard the 70-tick threshold in stage H uses for a
different decision.
