# Match flow: kickoff to full time

> **Source:** `TEngine.SetUpMatch` @ 0x004ce7be (VERIFIED) · `TEngine.MatchLoop` @ 0x004cf671 (VERIFIED) ·
> `TEngine.Update` @ 0x004cfa6c (VERIFIED) · `TEngine.UpdateMatchTime` @ 0x004d4087 (VERIFIED) ·
> `TEngine.DoHalfEnds` @ 0x004d4334 (VERIFIED) · `TEngine.MatchOver` @ 0x004d67cc (VERIFIED) ·
> `TEngine.EndMatch` @ 0x004d732f (VERIFIED) · `TEngine.SetPiece` @ 0x004d35fd (VERIFIED) ·
> `TEngine.WaitForSetpiece` @ 0x004d3689 (VERIFIED) · `TEngine.UpdateSetPieceReady` @ 0x004d373c (VERIFIED) ·
> `TEngine.SkipTime` @ 0x004d7541 (VERIFIED) · `TEngine.SkipMatchTime` @ 0x004d6a80 (VERIFIED) ·
> `TEngine.DoShootOut` @ 0x004d7768 (VERIFIED) · `TEngine.CheckShootOutComplete` @ 0x004d780c (VERIFIED) ·
> `TEngine.GetStringMatchState` @ 0x004d7a8e (VERIFIED) · `TEngine.DoYourSubstitutionOn` @ 0x004d60f7 (VERIFIED) ·
> `TEngine.DoYourSubstitutionOff` @ 0x004d648f (VERIFIED) · `TEngine.ForcePositionResetAll` @ 0x004d771c (VERIFIED) ·
> `TEngine.PauseEngine` @ 0x004d7c67 (VERIFIED) · `TEngine.ResetStats` @ 0x004d7ba9 (VERIFIED) ·
> `TEngine.SetUp` @ 0x004cd9c3 (VERIFIED) · `TEngine.SetUpChannels` @ 0x004ce59b (VERIFIED) ·
> `TEngine.StopChannels` @ 0x004ce6c3 (VERIFIED) · `TEngine.CheckInput` @ 0x004d28e4 (READ) ·
> `TEngine.CheckReplayInput` @ 0x004d4a9e (READ) · `TEngine.GoalScored` @ 0x004d39d6 (READ) ·
> `TEngine.SetUpSetPiece` @ 0x004d2f01 (READ) · `TEngine.UpdateOffset` @ 0x004cfb35 (READ)
> **Confidence:** HIGH for the frame loop, the clock, half/extra-time transitions, set-piece
> dispatch and the penalty shoot-out (all byte-exact). MEDIUM for goal handling and the
> skip-ahead simulator, since `GoalScored` and part of the input handling are read from
> Ghidra's decompile only, not byte-matched.
> **Last checked:** 2026-08-15

Nearly every method described here is a `Function` - a static method with no `Self` - on
`TEngine`. There is only ever one match in progress, so its entire state lives in module
globals rather than in an object. This document identifies each global by the name a
recovered file gave it; several of the same address get different names in different
recovered files because each was named independently before anyone cross-checked, and one
genuine unreconciled conflict is called out in "What we do not know yet."

## The two clocks: game state and match state

The engine actually runs **two** separate state machines that are easy to conflate because
both get called "state" in the recovered code.

**Game state** (`g_gamestate`) is the outer loop selector inside `MatchLoop`. It has 4
values that matter: `0` stops the loop entirely (leaving the match), `1` is paused (a
`TScreen_MatchPaused` overlay is up and `TScreen.Update()` runs instead), `2` is a live
match (`TEngine.Update()` runs), `3` is watching a replay (`TEngine.UpdateReplay()` runs,
and the frame budget below is tripled if fast-forward replay is on).

**Match state** (`g_matchstate`, the Int at 0x00C5B1FC) only means anything while
`g_gamestate = 2`. It is a single shared variable that plays two roles at once: it is both
"what is currently happening on the pitch" (ball live, a goal celebration, a penalty
shoot-out, full time) **and** "which dead-ball routine is active right now" - the same
enum value doubles as the set-piece type. `TEngine.SetPiece()` and
`TEngine.WaitForSetpiece()` both switch on this exact global to answer "is a stoppage in
progress" and "should the game hold for players to get in position." The full 12-value
table is confirmed byte-exact by `GetStringMatchState`.

## Kicking a match off

`TEngine.SetUpMatch(fixture, team1, team2, onDoneCallback)` is called once per match. It:

* forces a garbage-collect and logs memory used (a developer diagnostic, present in the
  shipped build);
* resets the replay-frame list;
* stashes the fixture and both teams in module globals, and fetches the first leg's score
  for two-legged ties (`TFixture.GetFirstLegScore`);
* sets the crowd zoom level for match-speed 2+ (see the Numbers section);
* zeroes a 99-element working array and works out which of the 4 playing periods the match
  should resume in, from whatever `g_engine_int20` (elapsed minutes) already holds - this
  looks like a save/resume path, not a fresh-match path (see "What we do not know yet");
* sets up radar colours, weather, resumes sound channels;
* sets the stadium capacity: 60,000 by default, the home club's own capacity for a normal
  club fixture, and forced back to 60,000 (with the "big crowd" flag set) for a cup final
  or a top-flight international/continental fixture;
* builds crest images, kit-coloured name labels, and the "Cup Match / Leg 1 / Aggregate a b"
  corner label for cup ties;
* paints the fan crowd (skipped in training mode);
* and finally calls `TEngine.MatchLoop()`, which does not return until the match ends.

`SetUpMatch` never itself sets `g_matchstate` to the pre-kickoff "Tunnel" value or fires the
opening kickoff - that must happen in whatever screen calls `SetUpMatch` (the kit-selection
screen, going by a field comment in the recovered file), which is outside `TEngine` and not
covered here.

## The frame loop

`TEngine.MatchLoop()` is a fixed-step accumulator:

```
matchclock = MilliSecs() - pausedms
Repeat
    accumulate elapsed real time into g_frameaccum
    spd = g_matchspeed                       ' ms budget per simulation tick
    If replaying AND fast-forwarding Then spd = spd * 3.0
    While g_frameaccum >= spd
        dispatch on g_gamestate (paused UI / live match Update / replay Update)
        g_frameaccum -= spd
    Wend
    RenderGameEngine(g_frameaccum / spd)     ' one render per real frame, with interpolation
    If AppTerminate() Then End
Until g_gamestate = 0
```

Before the loop starts, if a training minigame is active it resets player positions, forces
camera sub-mode 12 and starts training music (track 3 for an unpaid new player, otherwise a
coin-flip between tracks 3 and 4); a real match instead starts track 0.

Each live-match tick, `TEngine.Update()` runs, in this exact order:

1. `UpdateSounds()`
2. `UpdateOffset(0.1)` - smooths the camera toward the ball/focus point (see Numbers)
3. advance the replay-frame counter and record a replay frame for players and ball
4. `UpdateSetPieceReady()` - checks whether play can resume from a dead ball
5. `TTraining.Update()`
6. each team's own `Update()`
7. every player's `UpdateAll()`, then the ball's `UpdateAll()`, then the pitch's `Update()`
8. `UpdateMatchTime()` - the match clock (below)
9. `TWeather.Update()`
10. particle effects (`TParticle.UpdateParticlesAll()`)
11. `CheckInput()` - reads the human player's controls last

## The match clock

`TEngine.UpdateMatchTime()` runs every tick and is the only place the in-game minute
counter (`g_minutes`) advances. It bails out immediately during a training session. Then,
depending on match state:

* **Match state 8 (Goal!)** - the celebration screen holds for up to 6000 ms (8000 ms if the
  player being tracked for the goal is the profile's own custom pro), or ends the moment the
  ball settles within 30 pixels of the centre spot, whichever comes first; either way it
  calls `SkipTime()` to restart play and returns.
* **Match state 10 (Shoot-Out Taken)** - waits 2500 ms after the previous kick, then calls
  `DoShootOut()` to line up the next one.
* **Any other state except 1 (In Play)** - nothing happens; the clock only runs while the
  ball is genuinely live.
* **Match state 1, and the ball is not being held by the keeper** - records match ratings,
  credits 0.01 possession-time to whichever side currently has the ball, and every so often
  advances `g_minutes` by one. How often is computed as
  `tick = (g_halflength * 60 * g_matchspeed) / 90` engine-time units per in-game minute
  (both `g_halflength` and `g_matchspeed` are option/config values whose own source this
  document does not trace).
* Each time a minute ticks over, the engine checks whether it's a good moment to blow for
  half/full time: the ball must be within `TPitch.YardsToPixels(30.0)` of the halfway line
  on the Y axis, **and** either the last kick happened while the ball was already in open
  play, or it's been at least 1500 ms since the last kick. Even then, if the player currently
  holding the ball is clean through on goal (`TPlayer.CleanThrough()`), the whistle is
  withheld and the function returns without checking anything else - **the engine will not
  end a half while someone has a clear run at goal.**
* Only past that gate does it check `g_minutes` against 45 / 90 / 105 / 120 (by which of the
  4 playing periods, `g_half`, is current) and call `DoHalfEnds()`.

## Half time, full time, extra time

`TEngine.DoHalfEnds()` is a 4-case state machine keyed on `g_half` (1 = first half, 2 =
second half, 3 = first extra-time period, 4 = second extra-time period). Each case bumps
`g_half` to the next period **before** doing anything else, so by the time `MatchOver()` is
consulted in cases 2 and 4, `g_half` already reads 3 or 5 respectively.

| `g_half` going in | Next threshold set | Message shown | Player energy | What happens next |
|---:|---:|---|---:|---|
| 1 | 45 | "Half Time" | +10.0 | pause for the interval (match state → 0) |
| 2 | 90 | "Full Time" | +5.0 (only if not over) | `MatchOver()`: over → match state 11; not over → resume, into extra time |
| 3 | 105 | "Half Time" | +5.0 | pause for the interval |
| 4 | 120 | "Full Time" | - | `MatchOver()`: over → match state 11; not over → `DoShootOut()` |

`MatchOver()` applies the fixture's own decision rule, keyed on `TFixture.matchtype` (the
mapping from this numeric code to real competition formats - league, single cup leg, two-leg
tie, and so on - is not established by this function and is a gap; see below). What is
byte-exact is the mechanics:

| `matchtype` | At full time (90/120 min) | At the second check (extra-time full time) |
|---:|---|---|
| 1 | Always over; `resulttype` = 1 | - |
| 2 | Always over; `resulttype` = 1. If scores are level, also schedules a replay fixture | - |
| 3 | Scores differ → over, `resulttype` 1. Level → go to extra time | Scores differ → over, `resulttype` 2. Level → `resulttype` 3, shoot-out |
| 4 | Always over; `resulttype` = 1 | - |
| 5 (aggregate, two legs) | Away-goals-adjusted aggregate comparison decides `resulttype` 5 (won outright) or 4 (won on away goals); otherwise extra time | Same comparison again → `resulttype` 2 (won in extra time) or 3 (shoot-out) |

## Set pieces

Every dead ball - kickoff, throw-in, free kick, corner, goal kick, penalty, or a shoot-out
kick - goes through the one entry point, `TEngine.SetUpSetPiece(type, side, x, y)` (READ,
not yet byte-matched). It sets `g_matchstate` to the requested type, plays the previous
whistle if one was mid-stoppage, logs `"SetUpSetPiece: <type> <state name>"`, clears the
ball's controller, spawns a fresh ball at the given (or computed) spot, resets every
player's kick and offside flags, and - in training mode only - clears messages and force-
resets positions immediately instead of waiting for players to walk back.

| Type | Banner text | Notes |
|---:|---|---|
| 2 | *(none here - see below)* | Kickoff / centre restart |
| 3 | "Throw In" | Ball placed on the touchline at the ball's last X sign |
| 4 | "Free Kick" | If the spot falls inside the defending team's own penalty box, the routine calls itself again as type 7 (penalty) instead |
| 5 | "Corner" | Ball placed near the nearer corner flag |
| 6 | "Goal Kick" | Ball placed near the six-yard box, with a footstep sound if it lands close to the edge |
| 7 | "Penalty!" | Ball on the penalty spot |
| 9 | "Penalties" | Banner only shown on the very first shoot-out kick (`g_engine_int25 = 1`) |

Exact pixel-placement formulas for each type are not reproduced here - see the "gap"
`match/set-pieces.md`; this document only covers where set pieces sit in the overall flow.

Play does not resume from a dead ball the instant it's set up. `TEngine.UpdateSetPieceReady()`
runs every tick and holds `g_setpiecepower` at 0 (and the game effectively paused mid-restart)
until: `TPlayer.AllPlayersReady()` says every AI player has reached position (for the set
piece types `WaitForSetpiece()` says should wait - corners, penalties, shoot-out kicks, and
free kicks with a "buddy" assigned), the human player is ready if they're outfield, and no
opposing player is within `TPitch.YardsToPixels(8.0)` of the ball while it's a defended dead
ball. The instant it flips from not-ready to ready, the whistle sound plays, and - only for
a kickoff (match state 2) - a "Kick Off" banner appears at that moment, not when the set
piece was first set up.

## Substitutions

`TEngine.DoYourSubstitutionOn()` and `TEngine.DoYourSubstitutionOff()` are mirror-image
routines that swap the human profile's controlled squad member. Both:

* create the new `TPlayer` (`TPlayer.CreatePlayerSimple`) and add it to the squad list;
* set the outgoing player's `selectionno` to 99 (off the pitch) - Off does this to the human's
  current player, On does it to whichever squad member currently occupies the profile's
  "new star" selection slot;
* place the new player at `x = -g_player_int16` (the standard off-pitch sideline X), except
  the outgoing-player version (`Off`) places its incoming substitute 50 pixels further back
  still (`x = -g_player_int16 - 50`) - a small deliberate offset so the two "waiting to sub"
  spots don't overlap;
* and - the part that matters for continuity - walk through the ball's 6 loose references
  (`controlledby`, `lastkickedby`, `lasttouchedby`, `assistedby`, `setpiecetaker`,
  `setpiecebuddy`) and repoint any that pointed at the outgoing player onto the new one, so a
  substitution mid-passage-of-play doesn't lose track of who's on the ball.

`DoYourSubstitutionOff` also shows an on-screen message - "Substitution", or "Injury!" with
the injury icon instead of the substitution icon if it was called with a nonzero argument.

## Skipping ahead

Two different routines fast-forward the clock, and they are not the same mechanism.

**`TEngine.SkipTime()`** handles the *short* waits the player can button through: the goal
celebration and shoot-out-taken pauses described above, the pre-kickoff pause after half
time (which also re-sorts the human's match-stat list and, depending on which side is
kicking off, sets up the restart), and - in training mode - either starts the training
challenge, does nothing (mode 1), or ends the match outright (mode 2).

**`TEngine.SkipMatchTime()`** is the *long* fast-forward: it pauses the engine, and then, in
training mode, ends the match immediately (flagging a new-player screen if the profile is
unpaid). In a real match it runs a `Repeat...Until g_matchstate = 11` loop that advances the
clock one simulated minute at a time - with no ball physics at all - until the match ends
or a scheduled substitution minute (`g_engine_int22`) is reached, then performs that
substitution and returns. The dice it rolls every simulated minute:

| Roll | Chance | Effect |
|---|---:|---|
| `Rand(4,1) = 1`, per eligible outfield player (selection 1-10) | 25% each | that player logs a generic match-stat event (a 1-in-4 further split decides which stat code: 6, 7, 8, or - twice as often as any single one of those - 3) |
| possession coin (`Rand(5,1) > 2`) | 60% | the better-rated team keeps possession that tick (the coin only flips the outcome for the worse-rated side 40% of the time) |
| given possession, `Rand(4,1) = 1` | 25% | a shot: a random attacker is credited a shot stat |
| given a shot, `Rand(3,1) = 1` | 33% | the shot is on target |
| given on target, `Rand(3,1) = 1` | 33% | **goal** - score +1, scorer credited, and a different random teammate credited an assist |
| `Rand(30,1) = 1` / `= 2` | 3.3% each | a rare away-side / home-side event; a random non-keeper player is credited stat 11 |
| `Rand(45,1) = 1` / `= 2` (two independent rolls) | 2.2% each | a rare event counter increments, with no player attached in this function |

Combined, a team in possession scores in roughly 1 in 36 simulated minutes (25% × 33% ×
33%), on top of the 40-60% chance of holding possession that minute at all.

## Penalty shoot-outs

`TEngine.DoShootOut()` alternates kicks one at a time: after each kick it checks
`CheckShootOutComplete()`; if the shoot-out isn't over it increments the kick counter and
sets up the next kick, alternating sides by parity (odd kick count → side 1, even → side 2).
If it *is* over, it plays the whistle, snapshots the match-rating leader into a display
global, sets match state to 11, and records final player stats.

`CheckShootOutComplete()` implements a standard best-of-5-then-sudden-death shoot-out with
early stopping the moment the outcome is mathematically settled:

| Kicks taken so far | Stops the shoot-out when |
|---:|---|
| 6 | either side's lead exceeds 2 |
| 7 | the side on its 4th kick leads by more than 2, or the side on its 3rd kick leads by more than 1 |
| 8 | either side's lead exceeds 1 |
| 9 | the side on its 5th kick leads by more than 1, or the side on its 4th leads at all |
| 10 | the scores are not level (both sides have had 5 kicks - this is the last "regulation" check) |
| 11+ | after each completed pair of sudden-death kicks, if the scores differ |

## Ending the match

`TEngine.EndMatch()` tears everything down: flushes input, resets game/match state and
elapsed minutes, saves options, stops the 5 audio channels, and - outside training mode - 
marks the fixture's result invalid (`result = -1`) and calls `TFixture.UpdatePoints(Null, Null)`
before releasing it. It clears every team, player, ball, on-screen message, pitch mark,
photographer, camera-man, draw-object and particle list, plays a post-match track if the
profile has a contract, garbage-collects, logs the before/after memory totals as a developer
diagnostic, and finally invokes the `Int()` function-pointer callback that was passed into
`SetUpMatch` - this is how control returns to whichever screen started the match.

## The numbers

| Constant | Value | Where |
|---|---:|---|
| Goal-celebration hold | 6000 ms (8000 ms if the tracked scorer is the profile's own pro) | `UpdateMatchTime` |
| Goal-celebration early exit | ball within 30 px of centre | `UpdateMatchTime` |
| Shoot-out inter-kick pause | 2500 ms | `UpdateMatchTime` |
| Half/full/extra-time thresholds | 45 / 90 / 105 / 120 minutes | `UpdateMatchTime`, `DoHalfEnds` |
| Half-time energy refund | +10.0 (normal) / +5.0 (extra time, or continuing past normal full time) | `DoHalfEnds` |
| Whistle-withheld window | ball within 30 yards of halfway line **and** (last kick was live play, or ≥1500 ms since the last kick) **and** no player clean through | `UpdateMatchTime` |
| Possession accrual | +0.01 per live tick to whichever side has the ball | `UpdateMatchTime` |
| Minute-tick length | `(halflength × 60 × matchspeed) / 90` engine-time units | `UpdateMatchTime` |
| Replay fast-forward multiplier | ×3.0 frame budget | `MatchLoop` |
| Sub off-pitch stand-by X | `-g_player_int16` (incoming sub), `-g_player_int16 - 50` (outgoing player's replacement) | `DoYourSubstitutionOn/Off` |
| Camera zoom at kickoff (match speed > 1) | 1-in-5: wide (`Rand(10,65)`); 4-in-5: tight (`Rand(55,65)`) | `SetUpMatch` |
| Set-piece "no encroachment" radius | 8 yards | `UpdateSetPieceReady` |

## What this means in play

The whole match - halves, extra time, shoot-outs, substitutions, the skip button - is driven
by one shared Int (`g_matchstate`) doing double duty as both "what's happening" and "which
dead ball is live," and a second Int (`g_half`) tracking which of up to 5 periods (4 playing
periods plus shoot-out) is current. Nothing about the match length is hard-coded beyond the
90/105/120-minute checkpoints - how fast real time turns into match minutes is entirely a
function of `g_matchspeed` and `g_halflength`, both of which live outside `TEngine`.

The clean-through veto on ending a half is a real, deliberate piece of football feel: NSS5
will not cut off a golden chance just because the whistle-eligible minute happened to tick
over. Conversely, the whistle is *also* gated on the ball being near the halfway line and
not mid-pass, so a half can run visibly over its nominal length while the engine waits for a
tidy moment to blow it dead.

The fast-forward simulator (`SkipMatchTime`) is a genuinely separate, much simpler model
from what happens when the player is actively watching: no positions, no ball, just a
possession coin biased toward the better-rated side and three chained dice rolls (shot →
on target → goal) per minute of simulated possession. It is close in spirit to, but
structurally unrelated to, the flat weighted-goals table `TFixture.GetRandomGoal` uses for
matches the player never opens at all (see `match/simulated-results.md`) - two different
"nobody's watching" scoring models exist in the same game for two different situations
(fixture the player skips entirely, versus a match the player starts and then fast-forwards).

## What we do not know yet

* **`TFixture.matchtype`'s real-world meaning.** `MatchOver` and `DoHalfEnds` treat it as a
  5-way code that decides whether draws stand, whether extra time and shoot-outs apply, and
  whether a cup replay gets scheduled - but which competition format maps to which of the 5
  numbers is not established here. `TFixture`/`TCompetition` fields would answer it.
* **Where the per-match counters get reset.** `TEngine.SetUp` (the one-time asset loader) and
  `TEngine.ResetStats` (the post-match stat-counter reset) both leave `g_half`, `g_matchstate`
  and the shoot-out kick counter (`g_engine_int25`/`g_shootoutkicks`) untouched. Something
  must initialize `g_matchstate` to the pre-kickoff "Tunnel" value and `g_half` to 1 for a
  fresh match, and it is not in any function this document draws on - likely the screen that
  calls `SetUpMatch` (a comment in the recovered file points at the kit-selection screen).
* **`CheckInput`'s key/state dispatch is READ only, not byte-matched.** It reads raw scan
  codes (e.g. `0x78`, `0x79`, `0x74`, `0x46`, `0x43`) rather than named actions, and branches
  on `g_matchstate` values `0`, `2`, `5`, `11`, and an unlabelled `12` that `GetStringMatchState`
  has no case for. What state 12 represents, and what the exact key bindings are, needs a
  verified reconstruction of `TEngine.CheckInput` @ 0x004d28e4 plus the options/key-binding
  data it reads out of `g_options_arr*`.
* **`GoalScored` is READ only too.** What it does to the score, stats and camera FX belongs
  to a future `match/shooting-and-scoring.md` and needs its own byte-exact pass; this
  document only relies on the two facts also visible from `UpdateMatchTime`'s and
  `DoShootOut`'s callers: it sets `g_matchstate = 8` and starts the celebration timer
  described above, and it distinguishes a shoot-out goal (state 10) from an open-play goal
  with separate stat bookkeeping.
* **`TFixture.GetFirstLegScore`'s output order.** `SetUpMatch` reads it into two locals used
  later by `MatchOver`'s aggregate-score maths, but which of the two is the home leg score
  and which is the away leg score is not confirmed from this function alone.
* **One address, two claimed meanings.** 0x00C5B210 is documented as `g_minutes` (the
  elapsed-minute counter) in `UpdateMatchTime`, as `g_engine_clock` in `SkipMatchTime` and
  `DoYourSubstitutionOn` (consistent with `g_minutes`), but as a plain 0/1 `g_engine_flag20`
  in `SkipTime`. The first two agree; `SkipTime`'s use may just be testing "has any time
  elapsed yet" as a stand-in boolean, but this has not been reconciled against the byte
  evidence and should be checked before relying on it.

## Implementation details worth preserving exactly

* **`DoHalfEnds` compares `g_fixture.score1` against `g_fixture.score1`** - the same field
  twice, in both the normal-full-time and extra-time-full-time branches - guarding a crowd
  sound effect (`PlaySound(g_snd_crowd, ...)`). Since a value is always equal to itself, that
  sound can never play. This reads like a copy-paste of `score1` where `score2` was meant;
  reproduce it exactly rather than "fixing" the sound.
* **`SkipMatchTime`'s away-goal assist always looks at the home squad.** When the away side
  scores during the fast-forward simulator, the assist is picked with
  `g_hometeam.SelectRandomPlayer(...)`, not `g_awayteam` - verified twice against the raw
  bytes. Away goals in a skipped-ahead match can end up crediting an assist to a player on
  the wrong team.
* **A free kick silently becomes a penalty.** `SetUpSetPiece` doesn't just award a penalty
  when the game logic decides one is warranted elsewhere - a type-4 (free kick) call that
  lands inside the defending team's own box re-dispatches itself as type 7 on the spot, with
  no separate "was this a foul in the box" decision visible in this function.
* **The kickoff whistle plays when players finish walking back, not when the kickoff is
  set up.** `SetUpSetPiece(2, ...)` shows no banner; `UpdateSetPieceReady` is what plays the
  whistle and shows "Kick Off," and only at the instant readiness flips from false to true.
  A reimplementation that plays the whistle at set-piece creation time will fire it too early
  and, for a slow-walking squad, well before anyone can actually take the kick.
* **`g_half` is incremented before the "is it actually over" check, not after.** `DoHalfEnds`
  bumps the period counter first and then asks `MatchOver()`, so any reconstruction that
  reorders those two statements will have `MatchOver()` (and anything else that reads
  `g_half`/`g_engine_state` concurrently) looking at the wrong period.
