# Fouls, bookings and sendings-off

> **Source:** `TPlayer.CheckFoul` @ 0x004f4d5f (READ) · `TPlayer.CheckPlayerContactAll` @ 0x004f458a (READ) · `TPlayer.YellowCard` @ 0x004f5333 (VERIFIED) · `TPlayer.RedCard` @ 0x004f546d (VERIFIED) · `TPlayer.CleanThrough` @ 0x004f5510 (VERIFIED) · `TPlayer.BlockTackle` @ 0x004f889e (VERIFIED) · `TPlayer.SlideBall` @ 0x004f86d6 (VERIFIED) · `AngleDiff` @ 0x00506049 (VERIFIED) · `TStats_Match.CountStat` @ 0x0056d8f6 (VERIFIED) · `TStats_Match.AddStat` @ 0x0056d827 (VERIFIED) · `TEngine.SetUpSetPiece` @ 0x004d2f01 (READ)
> **Confidence:** HIGH
> **Last checked:** 2026-08-15

`CheckFoul` and `CheckPlayerContactAll` had no recovered body anywhere in the tree before this
document. Both were read from Ghidra's decompilation and then
disassembled directly (`capstone`, reading raw bytes out of `binary/NSS5.exe`) to resolve the parts
Ghidra's decompiler gets wrong for x87 float locals - most importantly, which of two angle
calculations actually feeds the from-behind test. Every field offset below was cross-checked against
`extracted/object_model.json`'s `TPlayer` member list, not assumed from the variable names Ghidra
picked.

## What happens, in plain English

A foul is never checked just because two players are close together. The game only asks "was that a
foul?" at the moment two player sprites actually **overlap on screen** while the challenging player is
in a tackling animation - a sliding tackle connecting with an opponent's body, or (separately) a
goalkeeper's dive colliding with an attacker. Plain running into someone, or being near the ball
carrier without your sprite touching theirs, never reaches the foul check at all.

Once a challenge is judged close enough and overlapping to matter, `TPlayer.CheckFoul` decides the
outcome from four things: how far the tackler is from the ball, whether the tackler is a goalkeeper,
whether the ball carrier was clean through on goal, and the angle between the tackler's and the ball
carrier's running directions. That last one stands in for "did this look like a tackle from behind" - 
the engine never checks the two players' relative positions for this, only which way each of them is
currently heading.

Every foul that is actually given - yellow, red, or just a recorded foul with no card - also does two
more things: it awards a free kick to the team that was fouled, at the exact spot of the contact (and
if that spot is inside the fouling team's own penalty box, `TEngine.SetUpSetPiece` silently upgrades it
to a penalty instead); and, only if the player fouled is the human player, it rolls a chance of a
match-ending injury.

## The decision tree

`CheckFoul(tackler, victim)` - read as `tackler.CheckFoul(victim)` - runs these checks in order.
Everything below only applies once the game is in normal live play (match state 1; state 10 is the
penalty shootout, confirmed from `TEngine.SetUpSetPiece`'s own dispatch, and fouls are never checked
during it) and the match isn't a training session.

1. **Is the victim a goalkeeper holding the ball?**
   This is the "sliding into the keeper" case, checked separately from everything below.
   - Only matters if the tackler is mid-slide-tackle animation *and* standing inside the penalty box
     (checked with `TPitch.InsidePenaltyBox`, using `GetShootingDirection()` to pick the right box).
   - If so, and the tackler wasn't the one who last touched the ball, it's a **yellow card** - logged
     internally as `"Foul: Slide on keeper!"`.
   - Otherwise nothing happens at all (logged `"Don't block tackle keeper."`) - no foul, no stat, no
     free kick.
2. **Is the tackler too far from the ball, or did they just win it fairly?**
   - Tackler more than **10 yards** from the ball → `"No Foul: Too far from ball"`, nothing happens.
   - Tackler was the last player to *kick* the ball → `"No Foul: Got ball"`, nothing happens.
   - The ball must currently be controlled by the victim at all - if nobody controls it, or someone
     else controls it, there is no foul regardless of distance.
3. **Is the tackler a goalkeeper?** (`selectionno = 0` identifies the goalkeeper throughout this
   engine - confirmed independently in `TPlayer.GetOppKeeper`, `TBall.KeeperImageHolding`,
   `TPlayer.CleanThrough` and `TPlayer.BlockTackle`, which all use the same test.)
   - If the keeper is **more than 2.5 yards** from the ball, **and** hasn't already touched it, **and**
     the ball is still travelling from the victim's own last touch (nobody else has kicked it since) - 
     the challenge is judged *not* to be a legitimate save attempt, and is recorded as a **plain foul,
     no card**.
   - In every other case - keeper close to the ball, or already touching it, or someone else has
     kicked it since - it's ruled `"No Foul: Made save"` and produces nothing at all, not even a plain
     foul stat. This is the common case; see the "quirk" note below on how the log line reads.
   - **A goalkeeper can never reach a yellow or red card through this function.** That branch of the
     logic (step 4) is only reached when the tackler is *not* the keeper.
4. **Outfield tackler - the real disciplinary logic.** Two questions decide the card:
   - **Was the victim clean through on goal?** (`TPlayer.CleanThrough`: no opposing outfield player is
     positioned goal-side of the victim, within a 2-yard buffer, between them and the goal they're
     defending. The opposing goalkeeper doesn't count - only having beaten the outfield line matters.)
   - **Was it from behind?** `AngleDiff(tackler.direction, victim.direction, True)` - the absolute
     angle in degrees between the two players' current headings - compared against **60°**. Under 60°
     counts as "from behind" (the tackler was running roughly the same way the victim was facing).

   | Clean through? | From behind (angle < 60°)? | Result |
   |---|---|---|
   | Yes | Yes | **Red card** - `"Red card: Clean through and from behind"` |
   | Yes | No | **Yellow card** - `"Yellow card: Clean through but not from behind"` |
   | No | Yes | **Yellow card** - `"Yellow card: From behind"` |
   | No | No | Accumulation check (below) |

   **Accumulation, when it's neither clean-through nor from behind:** the game compares
   `matchstats.CountStat(11)` (every previous plain foul this player has committed, *plus* every
   yellow and red they've already picked up - `TStats_Match.CountStat` double-counts type 9/10 rows
   when asked for type 11) against `matchstats.yellows + 5`. Every prior yellow the player has cancels
   out of that comparison exactly, which reduces it to: **has this player already committed 5 plain
   fouls (and picked up no red card) this match?** If yes, this foul - the 6th of that kind - is
   automatically a **yellow card** (`"Yellow card: Too many fouls"`). If not, it's just logged as a
   plain foul (stat type 11) with no card.

## The numbers

| Quantity | Value | Where it applies |
|---:|---|---|
| Max distance from ball to be judged at all | 10.0 yards | Any foul check on an outfield tackler |
| "Genuine save" distance for a goalkeeper | 2.5 yards | Goalkeeper-committed-foul branch |
| Sprite-overlap radius for a slide tackle to register as contact | 1.25 yards | `CheckPlayerContactAll`'s first collision test |
| Distance for a "good slide tackle" credit (stat 7) | 3.0 yards | `TPlayer.SlideBall` |
| General player-to-player contact radius | 10 px (`playerradius`, `Engine.ini`) | `CheckPlayerContactAll`'s standing-tackle window |
| "From behind" angle threshold | 60° | Both the clean-through and plain-foul branches |
| Fouls before an automatic yellow | 5 prior plain fouls (6th foul carded) | Accumulation branch |
| Base injury chance for the human player | 1 in 15 (`injuryfrequency=15`, `Engine.ini`) | Every recorded foul on the human player |

### Standing tackles (no slide) - `CheckPlayerContactAll`

Away from slide tackles, the same function also resolves standing challenges: if a defender who is on
their feet gets within `playerradius` (10px) of an opponent who has the ball (and that opponent isn't
the keeper), and the two players aren't facing the same way, the defender automatically wins the ball
-`TPlayer.BlockTackle`, a stat-8 "good tackle", never a foul - when:

```
AngleDiff(defender.direction, opponent.direction, absolute) > 115 - defender.tackling
```

`tackling` is one of the player's five core attributes (alongside `pace`, `dribbling`, `passing`,
`heading`, `shooting`, `flair` - all plain `Float` fields), presumably on the same scale as those. A
higher `tackling` stat lowers the threshold on the right-hand side, so a good tackler wins standing
challenges across a wider range of approach angles; a poor tackler (threshold near 115) essentially
never wins one standing up. This formula was read from disassembly, not cross-checked against a second
oracle, so treat the exact constant `115` as MEDIUM confidence even though the read itself is
unambiguous.

### The injury roll

Every foul that produces a free kick (yellow, red, or an uncarded foul - but *not* the separate
"sliding into the keeper" yellow, which has its own shorter tail and skips this entirely) ends with one
more check, but only if the fouled player is the human ("newstar") player:

```
N = injuryfrequency (15, from Engine.ini) × energy-based multiplier
if Rand(1, Int(N)) = 1:
    force the human player off (TEngine.DoYourSubstitutionOff)
    TProfile.DoInjury()
```

The multiplier comes from the human player's current `energy` (a 0-100 field on their profile):

| Energy | Multiplier | Effective N (truncated) | Injury chance |
|---|---:|---:|---:|
| Under 30, or already on painkillers | ×0.5 | 7 | **1 in 7 (≈14.3%)** |
| 30 - 39 | ×0.6 | 9 | **1 in 9 (≈11.1%)** |
| 40 - 49 | ×0.7 | 10 | **1 in 10 (10%)** |
| 50 - 59 | ×0.8 | 12 | **1 in 12 (≈8.3%)** |
| 60 - 69 | ×0.9 | 13 | **1 in 13 (≈7.7%)** |
| 70 and over | ×1.0 (none) | 15 | **1 in 15 (≈6.7%)** |

So a tired human player is roughly twice as likely to be forced off by a foul as a fresh one. This is
the same "roll 1 in N" idiom documented in `simulated-results.md` - `Rand(1, N)` and check for exactly
`1`.

## What it means in play

- **Goalkeepers cannot be booked or sent off, anywhere in this system.** Not just because
  `CheckFoul`'s carding branch is skipped for a keeper tackler (step 3 above) - `TPlayer.RedCard`
  itself opens with `If Self.selectionno = 0 Then Return 0`, an immediate no-op for any goalkeeper,
  regardless of who calls it or why. Whatever a keeper does on the pitch, the red-card method refuses
  to act on them.
- **A "too many fouls" yellow can be a hidden second yellow.** The accumulation trigger calls the same
  `YellowCard()` as every other yellow. If the player already has one yellow from earlier in the match,
  their 6th plain foul doesn't give them a fresh caution - it triggers `YellowCard()`'s own "second
  yellow" branch and sends them off, exactly as if the 6th foul itself had been a bookable one.
- **A foul in your own box becomes a penalty automatically.** `CheckFoul` always calls
  `SetUpSetPiece(4, ...)` with the exact contact coordinates; `SetUpSetPiece`'s own dispatch checks
  whether that spot is inside the fouling team's penalty box and silently redirects to a penalty
  (set-piece type 7) if so. `CheckFoul` itself has no penalty-box logic at all - the penalty is a side
  effect of always requesting a free kick at the true location of the contact.
  (`TEngine.SetUpSetPiece` is an *unverified* candidate body, so treat this specific mechanism as READ,
  not proven.)
  - Being a goalkeeper protects you from cards, but not from committing fouls that concede penalties - 
    the goalkeeper-branch in step 3 still calls the same `SetUpSetPiece(4, ...)` at the contact point
    whenever it isn't ruled a save.
- **The 10-yard and 2.5-yard checks are hard cutoffs, not sliding odds.** There is no partial credit - 
  a challenge one pixel outside 10 yards from the ball is never even considered a foul.
- **Tiredness makes the game more dangerous for the human player specifically.** No other player on the
  pitch has an `energy` field read here, and CPU players never trigger the injury roll at all (`if
  victim.newstar` gates the whole thing) - this mechanic exists purely as a risk the human player
  manages by not playing exhausted.

## What we do not know yet

- **`TEngine.SetUpSetPiece`** (@ 0x004d2f01) is only a near-miss candidate in
  `src/recovered_unverified/`, one byte short of a match. The penalty-box redirect and the "side"
  argument (which team is awarded the set piece) are read from that candidate, not proven byte-exact.
  Landing this body would upgrade the penalty-redirect claim above to VERIFIED.
- **The exact scale of the `tackling` attribute** (and its siblings `pace`, `passing`, `heading`,
  `shooting`, `flair`) is not established anywhere in this pass - no CSV in `GameMedia/Data/` carries
  player attributes, so they must be generated in code. `115 - tackling` only makes sense as a
  football mechanic if we know `tackling`'s real range; right now that's an assumption, not a
  reading.
- **`TPlayer.KeeperHoldingBall`** (@ 0x004fcab6, slot 0x1c0) and **`TBall.KeeperHolding`** (@
  0x004cb54e, slot 0x88) are both called by the functions this document covers but neither has been
  read. We know only that the former asks "is this specific player a keeper holding the ball" and the
  latter asks "is the ball currently held by any keeper" - the distinction matters for `SlideBall`'s
  keeper-foul check but the exact logic (e.g. does either count diving-but-not-yet-gathered
  possession?) is unread.
- **What match states 2-9 mean precisely, and whether any of them also suppress `CheckFoul`.** Only
  state 1 (normal play) and state 10 (penalty shootout, confirmed via `SetUpSetPiece`) are pinned
  down. `CheckFoul`'s own guard only tests `state = 1`, so if any other state is also "the ball is
  live" (kickoff countdown, VAR-style stoppage, whatever states 2-9 turn out to be), fouls would be
  silently skipped there too - this hasn't been checked.
- **Message display durations** for the second-yellow and red-card banners (`g_secondYellowTime`,
  `g_msgtime` in `TPlayer.YellowCard`/`RedCard`) were not traced back to a source; only the first
  yellow's 2500ms was confirmed from the AddStat/TScreenMessage call itself.

## Quirks worth preserving exactly

- **`AngleTo` is called and its result is thrown away.** Immediately after computing
  `AngleDiff(tackler.direction, victim.direction, True)` (which *is* used for the from-behind test),
  `CheckFoul` also calls `AngleTo(tackler.x, tackler.y, victim.x, victim.y)` - the bearing between the
  two players' positions - and does nothing with the answer. Confirmed at the instruction level: the
  call is immediately followed by `fstp st(0)`, x86's "pop the FPU stack and discard" idiom, not a
  store to any variable. Ghidra's decompiler doesn't show this at all (it just silently drops the
  statement), which is exactly why it's worth recording here: a from-scratch reimplementation reading
  only the decompile would never know this dead call was ever in the source. The practical effect is
  real, though: **the from-behind test only ever looks at which way the two players are facing, never
  at where they actually are relative to each other.** A tackler running parallel to the victim from
  10 yards to the side reads identically to one bearing down from directly behind, as long as their
  heading matches.
- **The disciplinary branch has a dead conditional.** Right before the energy-tier calculation, the
  code tests the human player's `shinpads` field (`TProfile + 0x178`) against zero - and then does
  nothing with the result either way; the "then" branch is empty (`cmp ...; jne <next instruction>`,
  i.e. the branch target *is* the fall-through). Whatever shin pads originally did to injury risk in
  this build, the effect has been deleted while the `If` that used to guard it was left behind.
- **The keeper-vs-outfield "made a save" wording is inverted from what it sounds like.** The log line
  `"No Foul: Made save"` fires whenever the keeper is judged to have made a fair play for the ball - 
  which is the *common* case, not a special one. Only when the keeper was clearly not near the ball,
  hadn't touched it, and the victim's kick was still live does the game fall through to record a plain
  foul. Reading the branch the other way round (treating "Made save" as the rare success path) would
  invert the whole keeper-foul mechanic.
- **`CleanThrough` ignores the opposing goalkeeper entirely.** Its loop explicitly skips any player
  with `selectionno = 0`, so a lone covering keeper never disqualifies "clean through" - by this
  engine's definition, beating the last outfield defender is enough, whether or not the keeper is
  still between the attacker and the goal.
- **The accumulation math only works because a yellow always logs stat 9, and only stat 9.**
  `TStats_Match.CountStat(11)`'s special "also count 9 and 10" rule and the comparison against
  `matchstats.yellows + 5` were written by the original team to cancel out exactly (see the derivation
  above). If a reimplementation ever changes how yellows are logged - e.g. logs a plain foul stat
  alongside a card, or double-books a second yellow differently from a first - this cancellation
  breaks silently and the "6th foul" threshold drifts.
