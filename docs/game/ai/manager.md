# The CPU manager

> **Source:** `TBase_Team.CheckManagerChangeFormation` @ 0x004bd2a6 (VERIFIED) · `TTeam.CheckComManagement` @ 0x004e1b6c (READ) · `TTeam.CreateTeamSimple` @ 0x004dd418 (READ) · `TTeam.CreateSquadSimple` @ 0x004dd954 (VERIFIED) · `TTeam.SelectRandomPlayer` @ 0x004e1f20 (VERIFIED) · `TTeam.GetSetPieceTakers` @ 0x004e0c0c (VERIFIED) · `TTeam.GetLosingBy` @ 0x004e1eb2 (VERIFIED) · `TEngine.DoYourSubstitutionOn` @ 0x004d60f7 (VERIFIED) · `TEngine.DoYourSubstitutionOff` @ 0x004d648f (VERIFIED) · `TFormation.PickRandomFormation` @ 0x004d9c6f (VERIFIED) · `TScreen_Kits.ButtonPlay` @ 0x0054a4c0 (VERIFIED)
> **Confidence:** HIGH for formation changes and mid-match substitution triggers (byte-verified); MEDIUM for squad building and set-piece-taker weighting (decompiled and cross-checked against verified callees, not yet byte-matched)
> **Last checked:** 2026-08-15

There is no strategic AI in New Star Soccer 5's "CPU manager." No club ever evaluates a
matchup, studies an opponent, or picks a system to counter one. What looks like management
is a short list of independent dice rolls that fire at fixed moments - one right before
kickoff, a couple of others repeatedly during the match - each checking a handful of
numbers and, sometimes, calling `Rand`. This document covers three of those moments: how a
club's starting eleven gets built before a match, how a club occasionally changes formation
based on recent results, and how the game decides whether to pull the human player's own
on-pitch character (called the "newstar" throughout the code) off - or on - during a match.

## 1. Building the matchday squad

Every match the player is involved in is launched from the "choose your kit" screen's Play
button, `TScreen_Kits.ButtonPlay`. That single function decides, for both clubs in the
fixture: whether either club's manager has just changed formation
(`CheckManagerChangeFormation`, see §2), then builds both full matchday squads by calling
`TTeam.CreateTeamSimple` once per side.

`CreateTeamSimple` does the following, in order:
1. Seeds the random number generator with the club's own ID (`SeedRnd(id)`).
2. Copies over name, three-letter code, overall rating, kit, and formation.
3. Decides who "controls" this team (a flag set by the caller, not computed here) and, if
   the human player has no valid squad slot at all for this match (`sel = -1`, e.g. an
   international fixture the newstar isn't part of), forces that flag off.
4. Works out skin tone from the club's or nation's data (`Nations.csv`/`Clubs.csv`,
   accessed via `TClub.SelectById`/`TNation.SelectById`), builds the `TFormation` and an
   empty corner-formation list, then calls `CreateSquadSimple()` to actually populate the
   squad (see below), `PaintSquad()` to render kit sprites onto each player, and loads the
   nation's name lists (`TNames.SetUp`) for the random-naming pass that follows.
5. Walks the freshly built squad and gives every player **except the newstar** a random
   forename/surname pair drawn from that nation's name-list arrays.
6. Re-seeds the RNG a second time, now from a different global
   (`SeedRnd(g_player_int50)`), before returning - so none of the match's own randomness
   (kicks, tackles, fouls) is correlated with the deterministic per-club seed used to build
   the squad.

`CreateSquadSimple` (the part that actually decides who is *in* the squad) is simpler than
it sounds:

* If the newstar has no valid slot this match (`newstarselno = -1`), it just fills all 11
  outfield/keeper positions (0-10) - subject to `TTraining.IsPlayerNeededForTraining`, which
  outside training mode always says yes, so in a normal match this fills every position.
* If the newstar does have a slot, the newstar's own position is always filled by them;
  every *other* position is filled only if the training filter allows it. Outside training
  mode the filter still says yes to everything, so this only matters during a training
  minigame, where it can produce squads with fewer than 11 players so the drill only
  involves the positions being trained.
* A separate difficulty-style flag, `g_modeFlag`, bumps a CPU-only team's (no newstar
  involved) rating by **+5** (clamped to 30-100) when it equals 3. *UNCERTAIN: which game
  mode `g_modeFlag = 3` corresponds to has not been confirmed - see §5.*

Each squad member is created by `TPlayer.CreatePlayerSimple`, which rolls seven raw stats
as `rating + Rand(10)` each (pace, dribbling, tackling, passing, heading, shooting, flair),
then rescales and clamps them; the newstar instead gets their stats read straight from the
player's own profile (with boot and training bonuses applied). The exact stat formulas are
player-progression material, not manager material, and are only summarised here for context.

## 2. Formation changes based on recent form

`TBase_Team.CheckManagerChangeFormation` runs once per club, for both clubs, immediately
before a human-played match (called from `TScreen_Kits.ButtonPlay`, the only caller found so
far - see §5 for what that scoping does and doesn't cover). It looks at the club's last five
fixtures and decides whether to reshuffle.

| Step | Rule |
|---|---|
| Enough history? | Needs at least 5 fixtures on record; otherwise no check happens at all |
| Score each of the last 5 | **Win = 3**, **Draw = 1**, **Loss = 0** - standard football points |
| Most recent result | Must be a **loss** (0 points) for anything to happen |
| Recent form | Sum of the last 5 match-points must be **< 5** |
| Dice roll | `Rand(3) = 1` - a **1-in-3 (33.3%)** chance |
| If all four hold | Formation is reassigned: `formation = PickRandomFormation()` |

All four conditions are required together: the club must have just lost, must be on a poor
run (fewer than 5 points from the last 5 games - roughly "a win and two draws" or worse),
and must pass the coin-in-three roll. `PickRandomFormation()` is `Rand(11)`, uniform across
11 outcomes, and the "manager" doesn't even check whether it changed anything - it re-rolls
into the same pool every time, so about **1-in-11 (9.1%)** of "formation changes" silently
pick the exact same formation the club already had, and the function's caller only reports a
change when the new value actually differs from the old one.

The 11 values `Rand(11)` can land on (1-11) map to specific formations via
`TFormation.GetStringTacticName`:

| Index | Formation | Index | Formation |
|---:|---|---:|---|
| 1 | 3-4-3 | 7 | 4-4-1-1 |
| 2 | 3-5-2 A | 8 | 4-4-2 A |
| 3 | 3-5-2 B | 9 | 4-4-2 B |
| 4 | 4-2-2-2 | 10 | 4-5-1 |
| 5 | 4-2-4 | 11 | 5-3-2 |
| 6 | 4-3-3 | | |

Indices 12-14 exist too ("Custom 1/2/3") but are never reachable from
`PickRandomFormation` - they're only for player-set custom tactics. Index 0 has no `Case` at
all in `GetStringTacticName` and falls through to the function's own default, "4-4-2 A".

`ButtonPlay` calls this check for **both** clubs in the upcoming fixture, but only raises
the on-screen "formation changed" notice (`g_profile.formationchanged = 1`) when the club
that actually changed is the player's **own** club in a club-level fixture - an opponent
that reshuffles does so silently, with no warning shown before kickoff.

## 3. Deciding what happens to the human player mid-match

`TTeam.CheckComManagement` is the function that decides, during the match itself, whether
to substitute the human player's on-pitch character off - or bring them on if they haven't
started. It is skipped entirely during training mode (`g_training_int03 <> 0` returns
immediately) and, once it has recorded a substitution event for this player in this match
(`subbedontime` or `subbedofftime` already set), it never re-evaluates them again for the
rest of the match.

**If the newstar is currently on the pitch** (found in the squad, not sent off, playing in
shirt-number slot 0-10), the checks run in this order and the first one that is true forces
a substitution off:

| # | Condition | Effect |
|---|---|---|
| 0 | Match clock hasn't reached **55** yet | No decision is made at all this call |
| 1 | Booked (1 yellow) **and** has committed more than 4 fouls this match (`CountStat(11) > 4`) | Subbed off - protecting a foul-prone booked player from a second card |
| 2 | `TProfile.energy < 6.0` | Subbed off - exhausted |
| 3 | Match rating below the **boss-relationship threshold** (table below) | Subbed off |
| 4 | Team currently behind in the tie (`GetLosingBy() > 0`, see caveat below) **and** rating below threshold **+10** | Subbed off |

If none of those fire, the player stays on. Every one of these paths calls
`TEngine.DoYourSubstitutionOff(0)` - the `0` means "ordinary substitution," never "injury":
this function is not how injury substitutions happen, even though the same underlying
`DoYourSubstitutionOff` also knows how to show an "Injury!" banner for `a0 = 1`. That path
must be triggered from somewhere else in the injury system, not from here.

### The boss relationship sets the bar

The rating threshold in step 3/4 is not fixed - it depends on `TProfile.relationboss`, the
player's standing with the club's manager. Lower relationship, harsher grading:

| `relationboss` | Rating threshold (must stay above this to avoid being subbed) |
|---|---:|
| ≥ 90 | **45** |
| 60-89 | **50** |
| 30-59 | **55** |
| < 30 | **60** |

These are cascading `If` checks, each able to raise the threshold again, so a relationship
below 30 ends up at the harshest bar (60) having passed through all three raises. When the
team is behind in the tie, the bar becomes **10 points stricter still** (threshold + 10) - 
so a bad relationship with the boss combined with losing is the single fastest way to get
hauled off, regardless of how the match is actually going for the rest of the team.

*Caveat on "behind in the tie":* `GetLosingBy()` returns `mine − theirs` computed from
`TFixture.score1/score2` plus the two legs' first-leg scores, with which side is "mine"
depending on whether `Self` is `g_hometeam`. The verified body is reproduced faithfully
above, and the function's own name strongly implies positive = losing, but the exact
score1/score2-to-home/away mapping has not been independently confirmed (LOW confidence on
sign only - see §5).

### Bringing the newstar on

**If the newstar is not currently found on the pitch** (not yet subbed on, or sent off), a
different, much simpler check runs: if a scheduled clock target (`g_engine_int22`) is set
(`> 0`) and the match clock has reached or passed it, the newstar is substituted on
(`DoYourSubstitutionOn`), every player's position is force-reset, any on-screen match
message is cleared, and a "Substitution" banner is shown - using one of two side-specific
icon images depending on which flank `TPlayer.GetShootingDirection()` reports for the human
player. Nothing in this function *sets* `g_engine_int22`; that scheduling decision is made
elsewhere (see §5).

### What a substitution actually does to the pitch

Both `DoYourSubstitutionOn` and `DoYourSubstitutionOff` create a **brand-new** `TPlayer` via
`CreatePlayerSimple` for whoever is coming on, rather than drawing from any existing bench - 
see the quirk in §6. The player going off has their `selectionno` set to **99** (out of
play); the incoming player inherits whichever ball-reference fields (who's controlling it,
who last touched/kicked/assisted, who's the free-kick taker/buddy) pointed at the outgoing
player, so the ball doesn't silently lose track of who's involved in the passage of play
that was happening the instant the sub occurred.

## 4. Picking who takes a free kick, corner, or penalty

`TTeam.GetSetPieceTakers` (a large 3,336-byte, fully verified function) assigns the taker
for every restart type. Its full restart-by-restart taxonomy belongs in the set-pieces gap
document, not here - but three of its cases are squarely about how the CPU treats the human
player, and use the same boss-relationship idea as §3.

For **free kicks** (outside the defensive-box special case, which just hands it to the
keeper) and **corners**, the normal pick is simply the outfield player with the best
shooting stat (free kicks) or passing stat (corners), subject to a game option
(`g_options_int15` for free kicks, `g_options_int16` for corners) that can ban the newstar
from ever being considered (`-1`) or give them only even odds of being considered at all
(`0`, a 50% skip via `Rand(2,1) = 1`). Separately from that pick, if the human player is on
the pitch and wasn't already chosen, the boss can still hand them the ball:

| Restart | Option value | Chance / condition to hand it to the human player |
|---|---|---|
| Free kick | `1` (player wants it) | `Rand(4,1) = 1` (25%) **or** player is captain **or** `freekicks` stat > club's `strength` |
| Free kick | `0` (auto) | `Rand(5,1) = 1` - flat **20%** |
| Corner | `1` | `Rand(4,1) = 1` (25%) **or** captain **or** `corners` stat > club `strength` |
| Corner | `0` | `Rand(5,1) = 1` - flat **20%** |
| Penalty | (no option gate) | Only if `penalties` stat > club `strength` - no captaincy or random override |

Penalties are the strictest case: being captain doesn't matter, and there's no random
chance at all - the human player only gets a penalty if their penalty-taking stat is
genuinely better than the club's own overall strength rating.

## 5. What we do not know yet

* **`CreateTeamSimple` is READ, not VERIFIED.** It has been decompiled and cross-checked
  against fields and calls that are independently confirmed elsewhere, but nobody has run
  the byte oracle against it yet. In particular, the second pass over the squad - a loop
  gated by the count of a list at `TProfile+0x10` that re-rolls names for roughly 1-in-3
  players (`Rand(6,1) < 2`) with an "X is replacing Y" log line - is not understood. It
  reads like flavour-text churn for a squad list the player can browse, but that is a guess.
  Re-run the oracle and re-derive that loop before trusting it.
* **`CheckComManagement` is one byte off a verified match** (837/838; the detail is recorded in the
  header of `src/recovered_unverified/TTeam.CheckComManagement.bmx`). The
  semantics in §3 are believed solid - the remaining gaps are codegen-shape issues, not
  logic questions - but the file should not be promoted to VERIFIED without finishing that
  work. Do not re-derive what's already logged there.
* **Where `g_engine_int22` (the scheduled newstar sub-on time) gets set is unknown.** No
  function that writes it has been identified yet. Finding that function would explain how
  the game decides *when* to bring the star player on in the first place.
* **The scale of `TProfile.energy`** (compared against the literal `6.0` in §3) has not been
  pinned down - is it 0-10, a percentage, or something else? Whatever function initialises
  or displays it (likely in the training or match-day systems) would answer this.
  `g_modeFlag`'s meaning (what mode value `3` represents, used in §1's rating boost) is
  similarly unconfirmed.
* **The non-boss-relationship restart cases in `GetSetPieceTakers`** (its numeric `Select`
  cases 0, 1, 2, 3, 6, 9 - kickoffs, throw-ins, goal kicks, and whatever case 9's
  repeat-forever queue-position pick is for) are deliberately not analysed here; that
  taxonomy belongs in the still-unwritten `match/set-pieces.md`, and its caller,
  `TEngine.SetUpSetPiece` (itself a near-miss in `src/recovered_unverified/`), is the place
  to start.
* **`CheckManagerChangeFormation` has exactly one known caller** in the recovered corpus so
  far (`TScreen_Kits.ButtonPlay`), meaning the evidence only covers matches the human player
  is about to play. Whether background, unplayed league fixtures ever trigger a formation
  change at all - or whether that's exclusive to the two clubs involved in the player's next
  match - has not been confirmed either way.

## 6. Quirks worth preserving exactly

* **There is no bench.** `CreateSquadSimple` only ever populates shirt numbers 0-10 (the
  starting eleven). It never creates a 12th player. When a substitution happens, the
  incoming player is a **freshly generated stranger** - `CreatePlayerSimple` called on the
  spot, with a name drawn at random and stats rolled from the team's rating just like every
  other filler player - not a reserve pulled from an existing squad list. A reimplementation
  that pre-builds a realistic bench of reserves would look more sensible but would diverge
  from what the original game actually does, and would change which names show up as subs.
* **The threshold cascade in §3 is written as sequential `If`s, not `ElseIf`.** Each
  `relationboss` check can re-raise `thresh` even though the ranges are already mutually
  exclusive by construction - reproduce it as written rather than collapsing it into a
  single `Select`, in case a future patch to the thresholds breaks the mutual exclusivity
  assumption.
* **`PickRandomFormation` never checks whether it picked something new.** About 1 time in
  11 the "manager changes formation" event fires, rolls the dice, and silently keeps the
  same formation. The 33%/33%/9% chain of rolls in §2 describes the chance of the *event*
  firing, not the chance of the formation *visibly* changing.
* **Two `.tac` formation files on disk are apparently dead content for CPU selection.**
  `EngineMedia/Tactics/4-1-4-1.tac` and `4-2-3-1.tac` exist alongside the 11 formations
  in the table in §2, but neither name appears anywhere in `GetStringTacticName`'s `Select`,
  which is the only confirmed path from a formation index to a `.tac` filename. *INFERRED*
  from the data directory listing plus the one verified name-lookup function - it's possible
  another, not-yet-recovered function loads them by literal filename, so treat "dead" as a
  working hypothesis, not a proven fact.
* **A management-triggered substitution is never an injury.** `CheckComManagement` always
  calls `DoYourSubstitutionOff(0)`. If a reimplementation ever wires this function's outcome
  to the "Injury!" message/icon path, that is a bug - that path is `a0 = 1`, and nothing
  shown here ever passes it.
