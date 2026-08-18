# How your player improves

> **Source:** `TProfile.GetSkillRating` @ 0x00569d19 (VERIFIED) · `TProfile.UpdateAbility` @ 0x00569d57 (READ) · `TProfile.SetAbility` @ 0x00569f28 (READ) · `TProfile.GetPaceCap` @ 0x0056c3d8 (VERIFIED) · `TProfile.LoseRandomSkillPoint` @ 0x0056bcfb (VERIFIED) · `TProfile.DoInjury` @ 0x0056bb58 (VERIFIED) · `TProfile.CheckSkillHash` @ 0x0056a0f9 (READ) · `TTraining.Success` @ 0x00581969 (VERIFIED) · `TTraining.Fail` @ 0x005818c7 (VERIFIED) · `TPlayer.AddPlayerRating` @ 0x005031ae (VERIFIED) · `TBall.CheckForPlayerRatings` @ 0x004cc644 (READ) · `TBall.CheckLongShotRating` @ 0x004cd177 (VERIFIED) · `TPlayer.CheckOffside` @ 0x004feec4 (VERIFIED) · `TProfile.UpdateMyRatings` @ 0x0056c449 (VERIFIED) · `TProfile.ShowRatingChanges` @ 0x0056c628 (VERIFIED) · `TStats_Team.UpdateStats` @ 0x0056eb20 (VERIFIED) · `TProfile.GetAverageForm` @ 0x00569b04 (VERIFIED) · `TScreen_SeasonReview.ButtonPlay` @ 0x00560796 (VERIFIED) · `TScreen_Abilities.SetUpScreen` @ 0x0053e86c (VERIFIED) · `TProfile.GetValue` @ 0x0056a366 (VERIFIED) · `TProfile.GetStat` @ 0x00569329 (READ) · `TProfile.GetCurrentStats` @ 0x00569a31 (READ) · `TPlayer.RecordPlayerStats` @ 0x004ff67c (READ) · `TProfile.New` @ 0x0056244b (VERIFIED)
> **Confidence:** HIGH
> **Last checked:** 2026-08-15

Your career player has three separate things that go up and down over a career, and they
are tracked, capped and earned in three completely different ways. There are seven "big"
skills (Pace, Dribbling, Tackling, Passing, Heading, Shooting, Flair) that only move when
you actively play a training minigame or lose a chunk to injury; there are ten quieter
"match attributes" (things like Crossing, Finishing, Aggression) that move automatically,
a little at a time, purely from how you play in matches; and there is Form, a rolling
memory of your last five match ratings that decays back to average the moment you stop
playing well. None of the three feed each other directly, but all three feed back into
the two numbers that actually matter to your career - your overall Skill Rating and your
transfer Value.

## The two skill systems, at a glance

| | The Big Seven | The Ten Match Attributes |
|---|---|---|
| Fields | `pace`, `dribbling`, `tackling`, `passing`, `heading`, `shooting`, `flair` | `freekicks`, `corners`, `crossing`, `positioning`, `shortpassing`, `longpassing`, `aggression`, `longshots`, `finishing`, `penalties` |
| Range | 0-100 | 0-100 |
| Shown on screen as | `value / 10.0`, one decimal place (e.g. `73` → "7.3") | the raw integer, no scaling (e.g. `73` → "73") |
| Goes up via | Training minigames only | Automatically, from match events ("coach shouts") |
| Goes down via | Injury (random loss) and age (pace/dribbling only, from 30 onward) | Automatically, from match events |
| Feeds | `GetSkillRating()` → overall rating, `GetValue()`, `GetStatus()` | Nothing else - purely cosmetic/flavour stats shown on the Abilities screen |
| Protected by | A stored hash (`skillshash`), checked against save tampering | Nothing |

These two field groups sit right next to each other in `TProfile` and both use small
integer indices (1-7 for the Big Seven, 1-10 for the attributes) to select which stat a
function call is talking about - but **they are two unrelated index spaces that happen to
overlap for 1-7**. `UpdateAbility(3, ...)` means Tackling; `AddPlayerRating(3, ...)` means
Crossing. Do not conflate them when reimplementing.

## System 1 - The Big Seven

### The overall rating

`TProfile.GetSkillRating()` is the player's headline number, used on the Abilities screen
and by the value/status formulas below:

```
r = pace + dribbling + tackling + passing + heading + shooting + flair
Return r / 7          ' Integer division - the remainder is thrown away, not rounded
```

Every new career player starts all seven at **0** (`TProfile.New`) - there is no starting
ability roll for the human player's own created character; you begin as close to
untrained as the data model allows, and everything is earned.

### How the Big Seven go up: training only

Skills change through exactly one positive path: playing a training minigame to success
(`TTraining.Success`, a `Function` triggered when a minigame completes). It reads a global
"which drill did you just do" mode (0-10) and applies a fixed gain through
`UpdateAbility(index, amount)`:

| Training mode | Skill trained | Ability index | Gain |
|---:|---|---:|---:|
| 0 | *(none)* | - | 0 |
| 1 | Pace | 1 | **+10** |
| 2 | Dribbling | 2 | **+5** |
| 3 | Flair | 7 | **+10** |
| 4 | Tackling (drill A) | 3 | **+5** |
| 5 | Tackling (drill B) | 3 | **+5** |
| 6 | Passing | 4 | **+5** |
| 7 | Heading (drill A) | 5 | **+10** |
| 8 | Heading (drill B) | 5 | **+10** |
| 9 | Shooting (drill A) | 6 | **+5** |
| 10 | Shooting (drill B) | 6 | **+5** |

`UpdateAbility` (and its sibling `SetAbility`, which overwrites rather than adds) both do
the same three things after touching the target field: clamp **all seven** fields to
0-100 with `ClampInt`, rebuild the anti-tamper hash (see below), and return. Failing a
minigame (`TTraining.Fail`) changes nothing - it just plays a sound and shows a message.

Reading the table: Heading is the cheapest skill to max (two available drills, +10 each,
no drill gives less), Tackling and Shooting are mid-cost (two drills, +5 each), and Pace,
Dribbling, Flair and Passing each have exactly one drill. Grinding Heading from 0 to 100
takes 10 successful sessions; grinding Passing takes 20.

The Abilities screen (`TScreen_Abilities.SetUpScreen`) disables a skill's training button
(`alph = 0.5`, greyed out) once that skill is already at its ceiling, or disables **all
seven** buttons if you are currently injured (`injury <> 0`) or your energy is below
**20.0** (out of 100). The ceiling is a flat **100** for five of the seven - but Pace and
Dribbling use the age-based Pace Cap instead (next section), so those two can lock out
training well before reaching 100.

### How the Big Seven go down: injury

`TProfile.DoInjury()` rolls an injury severity, then converts part of that severity
directly into lost skill points via `LoseRandomSkillPoint(n)`:

```
injury = Rand(3)                        ' 1..3, uniform
If Rand(5) = 1 Then injury = Rand(3, 5) ' 20% chance: re-rolled to 3..5, uniform
If takenpainkillers Then injury = Rand(5, 7)  ' overrides everything: 5..7, uniform
```

The **pre-increment** roll (call it the severity `X`) decides how many skill points are
lost, before `injury` itself is bumped by 1 for display/recovery-countdown purposes:

| Severity `X` | Chance (no painkillers) | Skill points lost | Physio report |
|---:|---:|---:|---|
| 1 | 4/15 (26.7%) | 0 | `CREPORT_PHYSIO1` |
| 2 | 4/15 (26.7%) | 1 | `CREPORT_PHYSIO2` |
| 3 | 5/15 (33.3%) | 1 | `CREPORT_PHYSIO2` |
| 4 | 1/15 (6.7%) | 2 | `CREPORT_PHYSIO2` |
| 5 | 1/15 (6.7%) | 2 | `CREPORT_PHYSIO2` |
| 6 | 0% (needs painkillers) | 3 | `CREPORT_PHYSIO2` |
| 7 | 0% (needs painkillers) | 3 | `CREPORT_PHYSIO2` |

Taking painkillers before this roll forces `X` into {5, 6, 7} uniformly (a straight 1-in-3
each) - so the game's actual design is: painkillers only ever make an injury's *effect on
your skills worse* (guaranteeing a 2- or 3-point loss) in exchange for letting you play
through it; they never reduce the severity.

Each lost point comes from `LoseRandomSkillPoint(n)`, called once per point to lose. Each
call is an **independent** `Rand(7, 1)` roll picking which of the seven skills takes the
hit, with a floor that can no-op the roll entirely:

| Roll | Skill | Ability index | Requires (to apply) | Loss |
|---:|---|---:|---|---:|
| 1 | Pace | 1 | `pace > 10` | **−10** |
| 2 | Dribbling | 2 | `dribbling > 5` | **−5** |
| 3 | Tackling | 3 | `tackling > 5` | **−5** |
| 4 | Flair | 7 | `flair > 10` | **−10** |
| 5 | Passing | 4 | `passing > 5` | **−5** |
| 6 | Heading | 5 | `heading > 10` | **−10** |
| 7 | Shooting | 6 | `shooting > 5` | **−5** |

Because each of the (up to 3) rolls is independent and can miss (land on a skill already
at or below its floor and do nothing), a bad injury is not a guaranteed 30-point swing - 
it is up to three separate dice rolls, each of which might do nothing at all. A player
with several skills already near zero is naturally more injury-resistant on this specific
mechanic, simply because more rolls come up empty.

### How the Big Seven go down: aging (Pace and Dribbling only)

`GetPaceCap()` returns a ceiling that only matters from age 30 onward:

| Age | Cap |
|---:|---:|
| < 30 | 100 (no cap) |
| 30 | 90 |
| 31 | 80 |
| 32 | 70 |
| 33 | 60 |
| 34 | 50 |
| 35 | 30 |
| ≥ 36 | 10 |

`GetAge()` is `date.GetYear() + 15` - the career clock's "year" field doubles as an age
offset, so year 0 is age 15 and year 20 is age 35.

At the start of every new season, `TScreen_SeasonReview.ButtonPlay` runs the actual
enforcement: if you are 30 or older and your current Pace or Dribbling exceeds that
season's cap, it is force-set (`SetAbility`, an overwrite, not a clamp-in-place) straight
down to the cap value. **Only Pace and Dribbling are touched.** Tackling, Passing,
Heading, Shooting and Flair never decline with age by any mechanism this document found - 
a 38-year-old can still carry a 100 Shooting rating built at 22. The same season-rollover
function also fully heals injuries (`injury = 0`), tops energy back up to 100, and clears
the current-season yellow-card counters. If your career year is already past 20 (i.e. you
would be starting your age-36 season), the player retires instead of continuing.

### The anti-tamper hash

Every write to any of the seven skills (through `UpdateAbility` or `SetAbility`) ends by
recomputing `skillshash`, a hash of the literal string `"dontcheatatnss5"` concatenated
with all seven current values, and storing it. `CheckSkillHash()` recomputes the same hash
and compares it against the stored one; on a mismatch it shows a
`CMESSAGE_INVALIDSKILLSHASH` warning and **resets all seven skills to 1**. This exists
purely to punish direct save-file editing of the skill fields. The mechanism is noted
but not chased further - see "What we do not know yet" for why the hash
function itself resists full recovery.

## System 2 - The Ten Match Attributes

Unlike the Big Seven, none of Crossing, Free Kicks, Corners, Positioning, Short Passing,
Long Passing, Aggression, Long Shots, Finishing and Penalties are trained deliberately.
They move automatically, in small amounts, as a side effect of how a match plays out, and
the player only sees the result as a batch of pop-up alerts at full time.

### Where the deltas come from: the "coach shout" system

Scattered through the match engine's per-event handlers (ball-out-of-play, offside calls,
long-range efforts, and the general `TBall.CheckForPlayerRatings` reaction to every kick),
the game calls `TPlayer.AddPlayerRating(index, delta, shoutKey)` - `index` selects which of
the ten attributes, `delta` is the point change (typically −5 to +5, always clamped to
±10 for that match), and `shoutKey` (when non-empty) triggers a boss pop-up message. A
representative sample, read directly from the match-engine callers:

| Event | Attribute | Delta |
|---|---|---:|
| Good defensive positioning / good interception | Positioning | +2 |
| Called for the ball incorrectly | Positioning | −1 |
| Caught offside yourself | Positioning | −2 |
| Defender plays a good offside trap (human is that defender) | Positioning | +2 |
| Long pass that put a teammate offside (>15 yards) | Long Passing | −2 |
| Short pass that put a teammate offside (≤15 yards) | Short Passing | −3 |
| Good long pass found a teammate closer to goal (>15 yards) | Long Passing | +3 |
| Good short pass (≤15 yards, or not closer to goal) | Short Passing | +3 |
| Misplaced pass lost to an opponent, long | Long Passing | −2 |
| Misplaced pass lost to an opponent, short | Short Passing | −3 |
| Good cross found a teammate (>20 yards, crossing situation) | Crossing | +3 |
| Cross went to the opposition | Crossing | −1 (silent, no boss message) |
| Good corner (delivery reaches a teammate) | Corners | +5 |
| Bad corner | Corners | −1 |
| Good free kick delivery | Free Kicks | +3 |
| Bad free kick | Free Kicks | −1 |
| Good long-range effort (shot from outside the box) | Long Shots | +1 |
| Bad long shot (off target, well outside the box) | Long Shots | −3 to −5 |
| Poor finish inside the box | Finishing | −1 to −2 |
| Wild finish inside the box in an already-hot situation | *(Penalties slot, "Expletive")* | −5 |

This list is representative, not exhaustive - `TBall.CheckForPlayerRatings` alone contains
well over twenty distinct branches. The full event catalogue belongs properly to the
match-engine behaviour docs (`match/fouls-and-cards.md`, `match/shooting-and-scoring.md`,
`match/set-pieces.md` - all still gaps); this document only establishes that the mechanism
exists and gives its shape and typical magnitudes.

Aggression is handled differently: at full time, `TPlayer.RecordPlayerStats` looks at how
many combined fouls-plus-tackles you registered that match (both counted from your match
stats, not from `AddPlayerRating` shout events) and applies a flat penalty if it is low - 
**−5** if you recorded zero of either, **−2** if you made tackles but committed no fouls
at all, **−1** if the combined total was 1-3. Four or more combined fouls and tackles
avoids the penalty entirely. There is no code path in this function that *rewards*
Aggression - it is a pure "you weren't physical enough" deduction on top of whatever the
in-match shout events already did to the same buffer.

### How a match's changes get applied

Every `AddPlayerRating` call during a match writes into a `temp_*` buffer (`temp_crossing`,
`temp_freekicks`, etc.), not the real stat, and every write is immediately clamped to
**[−10, +10]** - not per event, but as a running total for the whole match. A match with
one big spike in one direction saturates at 10; a match with several offsetting events
(a great cross followed by a bad one) can net out to almost nothing.

At full time, for the human player's own profile, two calls run back-to-back
(`TPlayer.RecordPlayerStats`, its final two lines):

1. **`ShowRatingChanges()`** - for each of the ten `temp_*` buffers that is non-zero, pops
   up a `"<Attribute> +N"` or `"<Attribute> -N"` alert (green up-arrow icon for a gain, red
   down-arrow for a loss), in a fixed order: Positioning, Short Passing, Long Passing,
   Finishing, Long Shots, Crossing, Free Kicks, Corners, Penalties, Aggression.
2. **`UpdateMyRatings()`** - adds each `temp_*` delta onto the matching permanent stat,
   clamps every permanent stat to 0-100, then zeroes all ten buffers for next match.

So what the player sees on the pop-up ("+3 Positioning") is exactly what gets added to the
permanent stat a moment later - the alert is not cosmetic, it is a live read of the actual
pending change.

## Form

Form is a third, independent thread: a short memory of recent match performance, not a
skill at all.

Every match a player appears in, `TStats_Team.UpdateStats` appends that match's rating
(the 0-100 match-rating scale used throughout the stats system) onto
`form:Int[]` - the array only ever grows, once per appearance, for the player's entire
career; nothing ever trims it.

`GetAverageForm()` only looks at the **last five** entries (shifted into a small 5-slot
window, oldest dropped): if a slot was never filled (early in a career, or a
just-created stats record) it is treated as **60** (i.e. "6.0"), not zero - so a rookie's
form reads as a neutral 6.0 out of 10 rather than 0.0 until five real matches exist. The
final number is:

```
Return ((f[0]+f[1]+f[2]+f[3]+f[4]) / 5) / 10.0
```

Note the division order: the five ratings are summed and divided by 5 as an **integer**
first (rounding down), and only that integer result is then divided by 10.0 to produce the
displayed decimal. This is not the same as averaging the five 0.0-10.0 decimal ratings
directly - the intermediate rounding can shave off up to 0.09 versus a "true" float
average, and a faithful reimplementation must reproduce the integer step, not skip it.

## What it all feeds

`GetSkillRating()` (the Big Seven's average) is one ingredient of two much larger
formulas documented elsewhere in the codebase:

* **`GetStatus()`** averages Skill Rating together with unlocked-achievement count,
  Lifestyle, Fame and Happiness - see `docs/game/career/relationships.md` for the other
  four terms.
* **`GetValue()`**, the transfer-market valuation, squares Skill Rating, multiplies by
  achievements, fame and a career-average match-rating score, then multiplies again by
  the cube of your club's strength rating, before applying an age multiplier:

  | Age | Multiplier | Age | Multiplier |
  |---:|---:|---:|---:|
  | 16-26 | 1.00 | 33 | 0.65 |
  | 27 | 0.95 | 34 | 0.60 |
  | 28 | 0.90 | 35 | 0.55 |
  | 29 | 0.85 | 36 | 0.50 |
  | 30 | 0.80 | 37 | 0.40 |
  | 31 | 0.75 | 38 | 0.30 |
  | 32 | 0.70 | 39 | 0.20 |
  | ≥ 40 | 0.10 | | |

  The result is floored at a minimum value of **100**, and otherwise rounded down into
  increasingly coarse brackets as it grows (nearest 10 under 1,000; nearest 100 up to
  10,000; nearest 500 up to 50,000; nearest 1,000 up to 100,000; nearest 10,000 up to
  1,000,000; nearest 100,000 above that).

  The `Select` only has explicit cases for ages 16-39; there is no `Case 15`. A
  freshly-created career player is age 15 (year 0), so their very first valuation falls
  through to the same `Default` arm as a 40-year-old - **0.1×**, the lowest multiplier in
  the table, not the highest. Confirmed against the byte-exact body, not a guess.

The practical read: training the Big Seven and playing well enough to grow the Ten
Attributes and Form both compound into the same handful of numbers that decide a player's
market value and "career status" - but they do so in fixed, additive, uncapped-by-form
ways. There is no synergy bonus for maxing everything at once; the formulas just multiply
whatever each ingredient currently is.

## What we do not know yet

* **The hash function itself.** `CheckSkillHash`'s logic (build the string, hash it,
  compare, reset-to-1 on mismatch) is fully readable in the decompilation, but the hash
  primitive it calls (`FUN_0058C960`, roughly 1,776 bytes, showing the unmistakable round
  constants and working-variable rotation of a SHA-256 implementation) is not itself a
  `Type` method and has not been separately reconstructed - it is a large, self-contained
  module function nobody has named or verified yet. Until it exists, `CheckSkillHash`
  cannot be compiled or byte-verified even though its behaviour is understood. This is
  intentionally not chased further; whoever does should start from
  `FUN_0058C960` directly.
* **The exact register-level match for `GetStat` and `GetCurrentStats`.** Both are proven
  correct in *structure* (their bodies in `src/recovered_unverified/` are the right length
  and every field/call is confirmed against `object_model.json`), but each has an
  unresolved register-allocation mismatch - a handful of bytes choose a different spill
  register than the original for the same value, not a different value. `GetStat` in
  particular is the generic accessor behind several of the numbers quoted in "What it all
  feeds" above (career goal/appearance/rating totals) - its answers are trusted here, its
  bytes are not yet proven.
* **The full `TBall.CheckForPlayerRatings` and `TPlayer.RecordPlayerStats` event
  catalogues.** Both are READ, not VERIFIED (each is a near-miss, believed complete and
  correct, with a handful of same-length register-allocation differences still open). This
  document quotes representative entries from both; the complete, exhaustive list of every
  in-match event that moves one of the Ten Attributes is not reproduced here and should
  live in the match-engine docs once those gaps are filled.
* **Why training mode 0 exists.** `TTraining.Success`'s dispatch has a real, empty `Case 0`
  - some code path completes a "training" session that grants no ability at all. No caller
  setting `g_trainingmode = 0` has been identified; it may be a
  practice/warm-up mode with no separate `TTraining.SetUpTraining_*` file, or a debug/dev
  path. Unknown.

## Quirks worth preserving exactly

* **Two index spaces share the numbers 1-7.** `UpdateAbility`/`SetAbility`/
  `LoseRandomSkillPoint`'s index (1=Pace…7=Flair) and `AddPlayerRating`'s index
  (1=Free Kicks…10=Penalties) are unrelated. A reimplementation that merges them into one
  enum will silently corrupt one system or the other.
* **Display-scale inconsistency is original, not a bug to fix.** The Big Seven display as
  `value/10.0` (a 0.0-10.0 decimal); the Ten Attributes display as the bare 0-100 integer.
  Both read from the same `TScreen_Abilities.SetUpScreen`, so this is a deliberate (or at
  least shipped) inconsistency in the original UI - reproduce it as-is.
* **Consecutive identical injury rolls under-report in the physio note, but not in the
  actual loss.** `LoseRandomSkillPoint`'s loop applies the ability change on *every*
  iteration a threshold passes, but only appends that skill's name to the returned
  description string when the roll differs from the *previous* roll (`If r <> last`). Roll
  the same skill twice in a row and it is genuinely reduced twice (e.g. Pace −20), while
  the physio report the player reads only says "pace" once.
* **Painkillers make injuries worse, not better, for skills.** Taking them before a match
  does not reduce the chance of the random severity landing in the high tier - it
  overrides the roll entirely into the guaranteed-high tier (severity 5-7, a 2- or
  3-point skill loss). There is no injury-avoidance benefit modelled here at all.
* **`UpdateMyRatings` writes through a module Global, not `Self`**, even though it is a
  `Method` on `TProfile`: the ten `ClampInt` calls at the end address `g_profile.<field>`
  explicitly rather than the implicit receiver. In the shipped game there is only ever one
  active `TProfile`, so this is invisible in play, but it means the method is not safe to
  call on a second, non-global profile instance without also redirecting those ten clamps.
* **Form never shrinks.** The `form:Int[]` array is appended to forever (one entry per
  career appearance) even though only the most recent five are ever read. A long career
  accumulates a large, permanently-retained, effectively-write-only array.
* **The per-match ±10 clamp on the Ten Attributes is a net, not a ceiling per event.** A
  match packed with alternating good and bad events for the same attribute can still end
  up near zero net change; a match with one dominant sequence of same-direction events
  saturates at exactly 10 (or −10) regardless of how many events contributed to it.
* **A brand-new 15-year-old prospect gets the worst age multiplier in `GetValue`, not the
  best.** The age `Select` only lists cases 16-39; age 15 (everyone's starting age) has no
  matching `Case` and falls to `Default` - the same 0.1× applied to a washed-up
  40-year-old. Reproduce the missing `Case 15` faithfully; "fixing" it changes valuations
  for every player in their debut season.
