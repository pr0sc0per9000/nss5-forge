# Training

> **Source:** `TTraining.Success` @ 0x00581969 (VERIFIED) · `TTraining.Update` @ 0x0057fd94 (VERIFIED) · `TTraining.Call` @ 0x00581ea1 (VERIFIED) · `TTraining.ResetTraining` @ 0x005826b1 (VERIFIED) · `TTraining.ClearUpTraining` @ 0x00581cc9 (VERIFIED) · `TTraining.SetUpTraining_Dribbling` @ 0x0057cd1f (VERIFIED) · `TTraining.SetUpTraining_Passing` @ 0x0057d94e (VERIFIED) · `TTraining.SetUpTraining_Shooting` @ 0x0057e0c5 (VERIFIED) · `TTraining.SetUpTraining_Heading` @ 0x0057eac1 (VERIFIED) · `TTraining.SetUpTraining_Flair` @ 0x0057f1c8 (VERIFIED) · `TTraining.SetUpTraining_Tackling` @ 0x0057f595 (VERIFIED) · `TTraining.UpdatePace` @ 0x005800c9 (VERIFIED) · `TTraining.UpdateDribbling` @ 0x005803c7 (VERIFIED) · `TTraining.UpdatePassing` @ 0x00580c44 (VERIFIED) · `TTraining.UpdateShooting1` @ 0x00580f4e (VERIFIED) · `TTraining.UpdateShooting2` @ 0x00580f6b (VERIFIED) · `TTraining.UpdateHeading1` @ 0x00580e6d (VERIFIED) · `TTraining.UpdateHeading2` @ 0x00580e8a (VERIFIED) · `TTraining.UpdateTackling1` @ 0x00580ae3 (VERIFIED) · `TTraining.UpdateTackling2` @ 0x00580bcf (VERIFIED) · `TTraining.GoalScored` @ 0x005823d6 (VERIFIED) · `TProfile.GetSkillRating` @ 0x00569d19 (VERIFIED) · `TProfile.UpdateAbility` @ 0x00569d57 (READ) · `TTraining.SetUpTraining` @ 0x0057bf1f (READ) · `TTraining.SetUpTraining_Pace` @ 0x0057c6d2 (READ) · `TTraining.UpdateFlair` @ 0x00580761 (READ)
>
> **Confidence:** HIGH for the reward mechanism (which stat goes up, by how much, and when)
> and for six of the seven difficulty tables. MEDIUM for the Pace drill's numbers, which come
> from an unread/unverified decompile rather than byte-matched source.
> **Last checked:** 2026-08-15

Training is the game's only way to raise a player's seven core ratings - pace, dribbling,
tackling, passing, heading, shooting, flair - outside of the small automatic nudges match
performance gives. There are seven training minigames, one per rating, reached from the
player's own menu. Three of them (tackling, heading, shooting) actually contain **two**
different mini-games apiece that the difficulty curve switches between automatically, so in
practice there are ten distinct playable drills sharing one scoring engine.

## How a session works

Every drill goes through the same shape, all driven off one shared state machine
(`TTraining.Update`, called once per frame):

1. **Difficulty is picked automatically from the player's current rating**, not chosen by the
   player. `TTraining.SetUpTraining(mode)` reads the relevant stat off the human player's
   `TProfile` and computes a level in the same call that builds the course. The player never
   sees a level-select screen - the course just gets harder as the underlying stat improves.
2. **The player plays the minigame** - dribble through cones, pass through gates, shoot at
   goal, win a tackle, and so on. Each drill's `TTraining.UpdateX` function polls once a frame
   for two outcomes: all the course's markers/lines cleared (win) or a rule broken, in which
   case it calls `TTraining.Fail()` immediately.
3. **A clock is always running.** `TTraining.Update` decrements a countdown once a second
   (with beeping under 6 seconds left, from `g_snd_beep2`) and calls `TTraining.TimeUp()` - a
   fail - the instant it hits zero.
4. **On success**, `TTraining.Success()` fires once: it plays two success sounds, clears the
   HUD, puts up the "Success!" screen, raises the boss relationship, and grants a fixed amount
   of exactly one rating (see below). On fail/time-up, `TTraining.Fail()`/`TTraining.TimeUp()`
   fire instead - sound effect, "Fail!"/"Time Up!" screen, no rating change at all.
5. **Leaving costs energy regardless of the result.** `TTraining.ClearUpTraining` always calls
   `g_trainingprofile.UpdateEnergy(-20.0)` on the way out - training is not free, win or lose.

## The actual numbers

### Which stat, and how much

`TTraining.Success` reads a single shared mode number (0-10) and awards ability through
`TProfile.UpdateAbility(id, amount)`. The ability-id mapping comes from `UpdateAbility`
itself (READ - an unverified but high-confidence Ghidra decompile, `if/elseif` chain on the
first argument, each branch adding to one named field then clamping every stat to `[0,100]`):

| Ability id | Stat field |
|---:|---|
| 1 | `pace` |
| 2 | `dribbling` |
| 3 | `tackling` |
| 4 | `passing` |
| 5 | `heading` |
| 6 | `shooting` |
| 7 | `flair` |

`TTraining.Success`'s `Select` on the mode number (`Case 0` is present and **empty** - no
`Default`):

| Mode | Drill (from `TTraining.Update`'s own dispatch) | `UpdateAbility` call | Net effect |
|---:|---|---|---|
| 0 | *(unused entry point - see quirks)* | - | nothing happens |
| 1 | Pace | `UpdateAbility(1, 10)` | pace **+10** |
| 2 | Dribbling | `UpdateAbility(2, 5)` | dribbling **+5** |
| 3 | Flair | `UpdateAbility(7, 10)` | flair **+10** |
| 4 | Tackling, mode A | `UpdateAbility(3, 5)` | tackling **+5** |
| 5 | Tackling, mode B | `UpdateAbility(3, 5)` | tackling **+5** |
| 6 | Passing | `UpdateAbility(4, 5)` | passing **+5** |
| 7 | Heading, mode A | `UpdateAbility(5, 10)` | heading **+10** |
| 8 | Heading, mode B | `UpdateAbility(5, 10)` | heading **+10** |
| 9 | Shooting, mode A | `UpdateAbility(6, 5)` | shooting **+5** |
| 10 | Shooting, mode B | `UpdateAbility(6, 5)` | shooting **+5** |

Every drill only ever raises the stat it is named after - there is no cross-training. The
mode number that picks the reward is the exact same integer (module global at `0x00C6CF90`)
that `TTraining.Update` uses to decide which `UpdateX` function to poll every frame, so the
two tables above are really one and the same dispatch read twice.

**The reward size is not arbitrary: reward × level-count = 100 for every drill.** Pace,
heading and flair use a 10-level difficulty scale and pay out **+10** per win; dribbling,
tackling, passing and shooting use a 20-level scale and pay out **+5** per win. Clearing
every level of any drill exactly once, back to back, therefore walks a 0-rated player to
almost exactly 100 - the level count and the per-success reward were tuned as a matched
pair.

### How the level is chosen

Two formulas cover all seven drills, both computed fresh every time the drill is entered
(`Int` division truncates):

| Scale | Formula | Levels | Used by |
|---|---|---|---|
| Fine (20 levels) | `level = Clamp((stat*2 + 10) / 10, 1, 20)` | 1-20 | Dribbling, Passing, Shooting, Tackling |
| Coarse (10 levels) | `level = Clamp(stat/10 + 1, 1, 10)` | 1-10 | Heading, Flair, Pace *(READ only, see below)* |

Both formulas hit their maximum level a little **before** the stat reaches 100 (the 20-level
scale caps out at stat ≥ 95, the 10-level scale at stat ≥ 90), so the last handful of points
on any stat are earned by repeatedly clearing the single hardest level, not by a steadily
rising one.

A level-1 trial message (`CMESSAGE_TRIAL...`) is shown only when the computed level is 1
**and** `g_profile.contractwage = 0` - i.e. only to a player who is not yet under a
professional contract, treating level 1 of every drill as the free trial/tutorial run.

### Dribbling - `TTraining.SetUpTraining_Dribbling` (VERIFIED)

Odd levels (1,3,5,…,19) are a **straight line of poles with sideways wobble**; even levels
(2,4,…,20) are a **cone slalom** (a cone plus an angled paired cone, joined by a line the
player must run without touching). The minigame does not just get harder level to level - 
it alternates *shape* the whole way up:

| Level | Shape | Obstacles | Gap (yd) | Time (s) | Wobble (yd) |
|---:|---|---:|---:|---:|---:|
| 1 | straight | 3 poles | 8 | 60 | 0 |
| 2 | cones | 2 cones | 10 | 20 | - |
| 3 | straight | 4 poles | 7 | 20 | 1 |
| 4 | cones | 3 cones | 10 | 20 | - |
| 5 | straight | 5 poles | 6 | 20 | 2 |
| 6 | cones | 4 cones | 10 | 20 | - |
| 7 | straight | 6 poles | 5 | 20 | 2 |
| 8 | cones | 5 cones | 9 | 20 | - |
| 9 | straight | 7 poles | 4 | 20 | 2 |
| 10 | cones | 5 cones | 8 | 20 | - |
| 11 | straight | 8 poles | 4 | 18 | 2 |
| 12 | cones | 6 cones | 7 | 18 | - |
| 13 | straight | 9 poles | 4 | 16 | 2 |
| 14 | cones | 7 cones | 7 | 16 | - |
| 15 | straight | 10 poles | 4 | 14 | 2 |
| 16 | cones | 8 cones | 7 | 14 | - |
| 17 | straight | 10 poles | 4 | 12 | 2 |
| 18 | cones | 9 cones | 7 | 12 | - |
| 19 | straight | 10 poles | 4 | 10 | 2 |
| 20 | cones | 10 cones | 7 | 12 | - |

Note the clock does **not** shrink smoothly: it drops from a generous 60s trial at level 1 to
a flat 20s for levels 2-10, then only starts tightening from level 11 on, bottoming out
around 10-12s. Fail conditions checked every frame (`TTraining.UpdateDribbling`): any pole
turns from yellow (untouched) once knocked, any cone falls, or the ball is not under the
player's control when the finish line is crossed.

### Passing - `TTraining.SetUpTraining_Passing` (VERIFIED)

20 levels, always a fan of cone-pairs the player must pass a ball between. The number of
gates rises from 1 to 10 while the angular spread between each gate's two cones narrows from
25° to 6° - more gates, and each one tighter to thread:

| Level | Gates | Radius (yd) | Spread (deg) | Level | Gates | Radius (yd) | Spread (deg) |
|---:|---:|---:|---:|---:|---:|---:|---:|
| 1 | 1 | 10 | 25.0 | 11 | 6 | 11 | 15.0 |
| 2 | 2 | 10 | 24.0 | 12 | 7 | 11 | 14.0 |
| 3 | 2 | 10 | 23.0 | 13 | 7 | 11 | 13.0 |
| 4 | 3 | 10 | 22.0 | 14 | 8 | 11 | 12.0 |
| 5 | 3 | 10 | 21.0 | 15 | 8 | 11 | 11.0 |
| 6 | 4 | 10 | 20.0 | 16 | 9 | 12 | 10.0 |
| 7 | 4 | 10 | 19.0 | 17 | 9 | 12 | 9.0 |
| 8 | 5 | 10 | 18.0 | 18 | 10 | 12 | 8.0 |
| 9 | 5 | 10 | 17.0 | 19 | 10 | 12 | 7.0 |
| 10 | 6 | 10 | 16.0 | 20 | 10 | 12 | 6.0 |

Pass all the gates (`TTraining.UpdatePassing` sees every training line cleared) to succeed;
letting the ball roll dead, drift more than 20 yards past the farthest cone, or cross the
halfway line resets the ball to a set piece instead of failing outright.

### Shooting - `TTraining.SetUpTraining_Shooting` (VERIFIED)

The 20-way `Select` is written in the *odd-then-even* source order, not numeric order, and
that split is meaningful: odd levels (1,3,…,19) are **shoot at an open goal from range**;
even levels (2,4,…,20) are **shoot past a wall of dummies**, i.e. a free-kick drill.

Odd levels - distance from goal climbs, the clock does not fall smoothly:

| Level | Time (s) | Distance (yd) |
|---:|---:|---:|
| 1 | 60 | 6 |
| 3 | 55 | 8 |
| 5 | 50 | 10 |
| 7 | 45 | 12 |
| 9 | 50 | 14 |
| 11 | 60 | 16 |
| 13 | 55 | 18 |
| 15 | 50 | 20 |
| 17 | 45 | 22 |
| 19 | 40 | 24 |

Even levels - a wall of dummies that grows from 1 to 5, standing further and further back:

| Level | Dummies | Wall gap (yd) | Distance (yd) |
|---:|---:|---:|---:|
| 2 | 1 | 10 | 20 |
| 4 | 2 | 15 | 22 |
| 6 | 3 | 20 | 24 |
| 8 | 3 | 25 | 26 |
| 10 | 4 | 30 | 28 |
| 12 | 4 | 35 | 30 |
| 14 | 4 | 40 | 32 |
| 16 | 5 | 45 | 34 |
| 18 | 5 | 50 | 36 |
| 20 | 5 | 50 | 38 |

`TTraining.GoalScored` (VERIFIED) is the referee: on odd levels the shot must be a kick type
≥ 4 (a proper shot, not a stray touch); on even levels it must be < 4. Every goal must also
clear the target line at a minimum height computed from `TPitch.YardsToPixels`. A miss just
plays a miss sound and leaves the goal counter alone; there is no separate "attempts" fail
path visible in this function - running out of the clock is what actually ends a bad run.

### Heading - `TTraining.SetUpTraining_Heading` (VERIFIED)

10 levels. Levels 1,2,4,6,8,10 are **"head the ball at the target"**; the four odd levels
3,5,7,9 are a **cone-course header drill** where the player must head the ball between
paired cones placed at a shrinking spacing:

| Level | Mode | Time (s) | Distance (yd) | Level | Mode | Cones | Cone gap (yd) |
|---:|---|---:|---:|---:|---|---:|---:|
| 1 | target | 60 | 6 | 3 | cones | 2 | 6.5 |
| 2 | target | 50 | 12 | 5 | cones | 3 | 6.0 |
| 4 | target | 40 | 18 | 7 | cones | 4 | 5.5 |
| 6 | target | 50 | 6 | 9 | cones | 5 | 5.0 |
| 8 | target | 40 | 6 | | | | |
| 10 | target | 30 | 10 | | | | |

The cone-course cones are placed by `Rand(180,1) + 180` - an angle in **[181°, 360°]**, never
normalised down to [0°,180°]. This is written straight into the original and is preserved as
written (see Quirks below), not "fixed" to a symmetric spread.

### Flair - `TTraining.SetUpTraining_Flair` (VERIFIED)

10 levels, one mode. The exact in-play meaning of two of its four per-level numbers is not
confirmed (see Gaps) - they are given here as read directly from the level table:

| Level | Attempts (int22) | Bias float | Count (int20) | Scale float |
|---:|---:|---:|---:|---:|
| 1 | 20 | +0.45 | 4 | 1.75 |
| 2 | 18 | −0.45 | 4 | 1.70 |
| 3 | 16 | +0.50 | 5 | 1.65 |
| 4 | 14 | −0.50 | 5 | 1.60 |
| 5 | 12 | +0.55 | 6 | 1.55 |
| 6 | 10 | −0.55 | 6 | 1.50 |
| 7 | 10 | +0.60 | 6 | 1.50 |
| 8 | 8 | −0.60 | 6 | 1.50 |
| 9 | 6 | +0.75 | 7 | 1.50 |
| 10 | 4 | −0.75 | 7 | 1.50 |

The "attempts" column is the same module global (`g_training_int22`) that `TTraining.Call`
documents as a "calls-remaining counter, decremented at the end" of each kick - it clearly
tightens (20 down to 4) as level rises, i.e. higher-flair sessions give fewer attempts before
some as-yet-unread fail condition kicks in.

### Tackling - `TTraining.SetUpTraining_Tackling` (VERIFIED)

20 levels, split into two groups by which sub-drill they use - group A is
{1,2,3,5,7,9,11,13,15,17,19}, group B is the rest - not an odd/even split like shooting.

Group A - "win the ball off an AI opponent" (`TTraining.UpdateTackling1`, which succeeds the
instant the human either controls or last-touched the ball):

| Level | 1 | 2 | 3 | 5 | 7 | 9 | 11 | 13 | 15 | 17 | 19 |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| Time (s) | 60 | 50 | 40 | 30 | 28 | 26 | 24 | 22 | 20 | 18 | 16 |

Group B - a marker/cone drill (`TTraining.UpdateTackling2`, succeeds when every cone is
knocked down):

| Level | 4 | 6 | 8 | 10 | 12 | 14 | 16 | 18 | 20 |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| Time (s) | 60 | 60 | 60 | 55 | 50 | 45 | 40 | 35 | 30 |

Group B's markers are scattered by `TCone.Create` in a ring whose radius grows
`10.0 + i*1.5` yards with each of the `i` cones placed - the course physically gets wider as
the level number climbs, on top of the shrinking clock.

### Pace - `TTraining.SetUpTraining_Pace` (READ, unverified decompile - treat as provisional)

This function has not been byte-matched; the numbers below are read directly out of Ghidra's
decompile (`extracted/decomp_annotated/TTraining.SetUpTraining_Pace@0057c6d2.c`), which the
project's own automated annotator marked `CONFIDENCE=NONE`, so treat every value here as
believed, not proven. It is the same 10-level scale and the same straight-line-of-poles shape
as dribbling's odd levels, with a "wobble" term active only on levels 3,5,7,9:

| Level | Poles | Time (s) | Wobble (yd) |
|---:|---:|---:|---:|
| 1 | 3 | 60 | 0 |
| 2 | 4 | 20 | 0 |
| 3 | 5 | 18 | 1 |
| 4 | 6 | 16 | 0 |
| 5 | 7 | 14 | 2 |
| 6 | 8 | 12 | 0 |
| 7 | 9 | 10 | 3 |
| 8 | 10 | 10 | 0 |
| 9 | 11 | 10 | 4 |
| 10 | 12 | 10 | 0 |

## What it means in play

**Every stat improves at the same underlying pace once you account for the level count.**
Because reward × levels = 100 for all seven drills, there's no faster or slower stat to grind
in principle - a player who plays every level of any drill exactly once, back to back, ends
that stat close to maxed. What actually differs between drills is difficulty of *play*, not
the arithmetic of reward.

**Training auto-scales to the player's current rating, so there's no way to farm cheap wins.**
The level is recomputed from the live stat every time the drill is entered - improve pace by
10, and pace training immediately jumps to whatever level that new value maps to. There is no
way to sit at level 1 repeatedly clearing the free trial for a full-price reward.

**Boss relationship gets an outsized boost from training while it's still bad.** On every
success, `g_profile.UpdateRelationship(1, 2)` fires unconditionally, then a *second*
`UpdateRelationship(1, 3)` fires only `If g_profile.relationboss < 20`. A player who is in the
manager's bad books recovers relationship roughly 2.5× faster per training win than one who
is already in good standing - and that bonus disappears entirely once `relationboss` clears
20, all inside the same function.

**Training always costs energy, independent of the result.** `TTraining.ClearUpTraining`
takes 20.0 energy off the player on the way out of *every* session, success, fail, or time-up
alike - there's a real resource cost to attempting a drill you might not win.

**Three drills quietly retrain the difficulty curve into a different minigame, not just a
harder one.** Dribbling alternates straight-line/cone-slalom every level; shooting alternates
open-goal/free-kick-wall every level; heading is target-practice for six levels and a cone
course for the other four. A player grinding any of these three experiences a genuinely
different game shape from one session to the next, not a smooth ramp.

## What we do not know yet

* **`TTraining.SetUpTraining` (dispatcher, VA 0x0057bf1f)** and **`TTraining.SetUpTraining_Pace`
  (VA 0x0057c6d2)** are both unread beyond an unverified Ghidra decompile - no byte-matched
  BlitzMax source exists for either yet. The dispatcher does confirm (from the decompile) that
  the seven menu entry points pass mode values 1 (Pace), 2 (Dribbling), 3 (Flair), 4
  (Tackling), 6 (Passing), 7 (Heading), 9 (Shooting) - modes 5, 8 and 10 are never chosen from
  the menu, only reached internally once a drill's own setup function reassigns the shared
  mode global mid-course. Whoever verifies these two functions should re-check every Pace
  number in this document against the byte-matched result.
* **`TProfile.UpdateAbility` (VA 0x00569d57)** has no recovered BlitzMax source, only a
  high-confidence annotated decompile. The ability-id table above (1=pace … 7=flair) and the
  `[0,100]` clamp both come from that decompile, not from verified source.
* **`TTraining.UpdateFlair` (VA 0x00580761)** is a near-miss sitting in
  `src/recovered_unverified/` - 896 of 898 bytes matched, with the remaining 2-byte gap fully
  localised (not a semantic uncertainty, per its own header notes) to a spill-slot ordering
  question. The pass/fail logic quoted in this document (distance-from-poles/lines checks,
  ball-possession checks, a red "target still armed" pole) is very likely correct but not
  proven byte-exact.
* **The consumer of `g_training_float03`/`g_training_float04`** (Flair's per-level bias and
  scale numbers) has not been identified. `TTraining.UpdateFlair`, the function that would be
  the obvious place to read them during play, does not reference either global - so whatever
  function actually uses them to shape the flair minigame (most likely something in the ball
  physics/trick-move code, outside `TTraining`) is still unread.
* **What "attempts exhausted" actually does** for the drills that carry a counter
  (`g_training_int21` for shooting/heading single-target mode, `g_training_int22` for flair
  and the calls counter `TTraining.Call` decrements) is only confirmed for the trivial
  `If counter = 0 Then Success()` case in `UpdateShooting1`/`UpdateHeading1`. Whether running a
  counter down to a *negative* value, or exhausting it without succeeding, triggers a Fail
  anywhere has not been traced.
* **`TTraining.GetFocus`, `GetMatchState`, `GetPiggyInTheMiddlePosition`, `TrainingSetPiece`,
  `UpdateSounds`** are all VERIFIED in `src/recovered/` but are camera/AI/set-piece plumbing
  rather than "what changes a rating," and are out of this document's scope.

## Quirks worth preserving exactly

* **`TTraining.Success`'s mode dispatch has a genuinely empty `Case 0`.** If the shared mode
  global is ever 0 when `Success()` fires, the function still plays sounds, shows "Success!",
  and pays the relationship bonus - but grants **no** ability points at all. This is a real
  branch in the original `Select`, not a gap in the reconstruction; reproduce the empty case,
  don't add a fallback.
* **Two different level-count scales share one game.** Pace/Heading/Flair use
  `Clamp(stat/10+1, 1, 10)`; Dribbling/Passing/Shooting/Tackling use
  `Clamp((stat*2+10)/10, 1, 20)`. Don't unify them - the reward sizes (+10 vs +5) are tuned
  specifically to each scale's level count.
* **Dribbling's clock is not monotonic.** It drops from 60s (level 1, the free trial) straight
  to a flat 20s for levels 2 through 10, and only starts shrinking again from level 11. A
  "smoothed" curve would misrepresent the original.
* **Heading's cone-course angle is never normalised.** `Rand(180,1) + 180` yields an angle in
  [181°,360°] every time - an apparent asymmetry (the cone pair is always swept through the
  same half of the circle) that is exactly what the shipped game does. Do not "fix" it to
  [0°,360°] or [0°,180°].
* **Flair's bias float alternates sign every single level**: +0.45, −0.45, +0.5, −0.5, +0.55,
  −0.55, +0.6, −0.6, +0.75, −0.75. This is a deliberate per-level flip in the source data, not
  noise - reproduce the literal signs.
* **One module global, five different local names.** The shared "which drill/sub-mode is
  active" Int at module address `0x00C6CF90` was independently recovered under five different
  names across files that were never true to each other: `g_trainingmode` (in `Success`),
  `g_trainingstate` (in `ClearUpTraining`, `SetUpTraining_Shooting`, `SetUpTraining_Tackling`),
  `g_training_int03` (in `SetUpTraining_Heading`, `IsPlayerNeededForTraining`), `g_train_mode`
  (in `Update`, `GoalScored`), and `g_training_mode` (in `CanCallForBall`). It is one variable.
  Anyone consolidating globals across `src/recovered/` should merge these five names, not treat
  them as five different fields that happen to share an address.
* **`TTraining.Call`'s six identical `Case` bodies (modes 1-6, each `a0.calling = 0 : Return 0`)
  are written out six separate times in the original**, not collapsed into
  `Case 1,2,3,4,5,6`. Reproduce the duplication - the original genuinely emits the three-line
  body six times.
