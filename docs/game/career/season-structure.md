# Seasons, fixtures and competitions

> **Source:** `TCompetition.SetUpCompetitionsAll` @ 0x0050a77b (VERIFIED) · `TCompetition.SetUpCompetition` @ 0x0050a94d (VERIFIED) · `TCompetition.CreateTeamPool` @ 0x0050aae0 (VERIFIED) · `TCompetition.PopulateTeamPool` @ 0x0050abfb (VERIFIED) · `TCompetition.CreateFixtureListLeague` @ 0x0050b420 (READ) · `TCompetition.CreateFixtureListKO` @ 0x0050ba1a (VERIFIED) · `TCompetition.GetHomeAndAwayTeam` @ 0x0050bdb6 (VERIFIED) · `SelectFixtureTable` @ 0x004c5280 (VERIFIED) · `TCompetition.CheckFixtureClash` @ 0x0050bef9 (VERIFIED) · `TCompetition.VerifyCupDates` @ 0x0050e7c6 (VERIFIED) · `TCompetition.PlayFixtures` @ 0x0050eed4 (VERIFIED) · `TFixture.PlayFixture` @ 0x004c47e1 (READ) · `TFixture.UpdatePoints` @ 0x004c4c0b (VERIFIED) · `TCompetition.DoPromotionPlaces` @ 0x0050f0d0 (VERIFIED) · `TCompetition.PromoteToMe` @ 0x0050f841 (READ) · `TCompetition.IsComplete` @ 0x0050cf11 (VERIFIED) · `TCompetition.GetNoofQualifiers` @ 0x0050cbed (VERIFIED) · `TCompetition.GetNoofTeamsInRound` @ 0x0050cc87 (VERIFIED) · `TCompetition.ValidatePromotionPlaces` @ 0x0050ff5b (VERIFIED) · `TFixture.GetRandomGoal` @ 0x004c4d29 (VERIFIED)
> **Confidence:** MEDIUM
> **Last checked:** 2026-08-15

This document covers the *engine* half of the season: what code walks the competition graph, when
it builds fixture lists, how it decides a result for a match the player doesn't watch, and how
places flow between competitions. The *data* half - the 1,028 competitions and 2,067 promotion
edges that describe every league and cup in the game - is already exhaustively catalogued in
`docs/specs/02-competition-system.md`; this document does not repeat that catalogue, only cross-references
it, and adds what the verified code says about a handful of things that document had marked
**UNCERTAIN**. For how a single match becomes a scoreline (the 0-10 goal table), see
`docs/game/match/simulated-results.md` - `TFixture.PlayFixture` calls that function twice and
this document describes only the machinery *around* it: which fixtures get played, when, and what
happens to the result afterwards.

## What the system does

### The competition graph, briefly

Every league, cup, qualifying round and virtual holding pen in the game is one row of
`GameMedia/Data/Competitions.csv` (1,028 rows). `GameMedia/Data/PromotionPlaces.csv` (2,067 rows)
is a graph of edges `(parentid, place) -> promotiontoid` saying where teams go when a competition
finishes. There is no other structure - no hard-coded league tables or cup brackets anywhere in
the engine. Six `comptype` shapes and two fixture generators (`CreateFixtureListLeague`,
`CreateFixtureListKO`) are all the code there is; everything else is these two files. Full column
reference, every `comptype`/`locale`/`legs`/`place`-code table, and the worked World Cup / Euro /
English pyramid examples are in spec 02 §3-§8 - read that first if you need the *data*, come back
here for the *code*.

### Season boot: `SetUpCompetitionsAll`

Once per season transition, `TCompetition.SetUpCompetitionsAll` walks every competition in the
game (`g_complist`, sorted by `SortListBy(22, 1)` first) and asks a single question per
competition:

```
If c.startyear = gy Or c.IsComplete(0) Then c.SetUpCompetition()
```

`gy` is `g_profile.date.GetYear()` - the player's current game year. This is a **simpler rule
than it looks**: spec 02's checklist (§11) guessed the gate was a modulo test - 
`gameYear MOD recurring == startyear MOD recurring` - because that is the only reading consistent
with the *data* (World Cup `startyear=4, recurring=4` firing in years 4, 8, 12, 16...). The
verified code shows it isn't a modulo at all. `TCompetition.SetUpCompetition` ends with:

```
If Self.startyear > 0 Then Self.startyear :+ Self.recurring
```

So after a competition is set up, its own `startyear` field is advanced by `recurring` right
there - a World Cup that just ran with `startyear=4` becomes `startyear=8` for its next edition.
The gate `c.startyear = gy` naturally recreates the modulo behaviour spec 02 inferred from the data,
without ever computing one: the field *is* "the next year this fires", updated in place, not "the
phase within the cycle" re-derived every season. The `Or c.IsComplete(0)` half is a safety net - 
any competition left in a finished state gets rebuilt even if its year counter didn't line up,
which stops a competition from ever getting stuck complete-and-unplayed forever.

`SetUpCompetition` then dispatches purely on `comptype`/`level`/`locale` (nine `Select` arms) to
decide, for each due competition: build the team pool (`CreateTeamPool`, which either clears an
existing pool or allocates one `TTeamPool` per `groups`), fill it (`PopulateTeamPool`), then
generate the fixture list (`CreateFixtureListLeague` for `comptype` 0/4, `CreateFixtureListKO` for
`comptype` 1). Virtual types (`comptype` 2/3/5 - BestPlaced, Pool, RegionalSort) never reach either
generator; they play no matches (confirmed by the `Select` simply having no case for them here,
matching spec 02 §7.3's data-side observation).

At the very end of `SetUpCompetitionsAll`, every club's `continentalcompid` is reset to 0 for the
whole game world, and (year 1 only) `Test_UpdateNoofTeamsInLeagues` snapshots each league's team
count into `tempNoofTeams`; every other year `Test_CheckNoofTeamsInLeagues` compares the current
count against that snapshot and logs `"WARNING! Number of teams changed in: "` if it drifted - 
a self-check the game runs on itself every season, not something the player ever sees directly.

### Filling a team pool - two complementary halves

`PopulateTeamPool` is the "pull" half of getting teams into a competition; `DoPromotionPlaces` /
`PromoteToMe` (below) are the "push" half. Reading `PopulateTeamPool`'s own `Select pp.place`
answers a question spec 02 §5.6/§12 left **UNCERTAIN** - see the numbers section below.

For an ordinary domestic league (`comptype=0, level=0, locale=0`) the pool is just
`TClub.SelectListByLeagueId(id)` - whoever `Clubs.csv.leagueid` currently says belongs to this
league, in file order, one to a `TTeamPool` slot. For a continental club competition
(`locale=1`) it instead pulls every club in `g_clubs` whose `continentalcompid` equals this
competition's id, sorts by `TClub.Compare` sort-key **11** (strength), and round-robins them
across the `groups` team pools (`teampool[i]`, `i` wrapping at `groups`). For an
international competition with no inbound promotion edges (`level=1, locale=1`, e.g. the nine
World Cup / Euro / ACN qualifying-stage-1 rows spec 02 §6 lists) the pool is built straight from
`TNation.SelectListByContinent(based)`, each nation given a random sort key (`Rand(9999)`) and
sorted by `TNation.Compare` key **15** before being distributed the same way - i.e. the seeding
for these groups is **pure random shuffle**, not a strength-based draw, despite `Nations.csv`
carrying a `strength` column that would support one. (Spec 02 §6 flagged the seeding rule as
open; this settles at least these nine entry points: random.)

### The two fixture generators

**`CreateFixtureListLeague` (`comptype` 0 and 4).** For each of the competition's `groups` team
pools it needs `rounds` complete round-robins. Rather than compute a schedule, it asks a module
Function (ours to name - no reflection record; `SelectFixtureTable`, VERIFIED byte-exact,
`src/recovered_module/SelectFixtureTable.bmx`) for a **precomputed pairing table** keyed by team
count, then walks that table pulling one `(home, away)` pair at a time via `GetHomeAndAwayTeam`,
advancing the fixture date and checking `CheckFixtureClash` before each match is actually created.
`CreateFixtureListLeague` itself is still only READ - a near-byte-exact candidate (1548/1530
bytes, structure and control flow believed complete; the residual is register-allocation, not
logic - see `src/recovered_unverified/TCompetition.CreateFixtureListLeague.bmx`'s own header) is
banked but not yet certified. See the round-robin table domain below - the precomputed-table
design is also the source of a real gap (see Quirks).

**`CreateFixtureListKO` (`comptype` 1).** For each `leg` (1 or 2, from the competition's `legs`
field) it walks the pool in id order pairing `local_8` with `local_8+1` - i.e. **team 1 vs team 2,
team 3 vs team 4, ...** in whatever order `PopulateTeamPool` left them - *except* when the round
has exactly 4, 8, 16 or 32 teams, in which case pairs are instead read from one of four hard-coded
bracket tables (see below). `matchtype` (which decides how `TFixture.PlayFixture` will resolve a
draw) is set from `legs` at fixture-creation time - see the table below.

Both generators finish by calling `Self.SortFixtureList()`, which sets a shared sort-key global to
**17** and calls `TList.Sort()` on `lfixturelist` - every fixture list in the game is sorted by the
same key.

### Calendar clashes

`CheckFixtureClash(date)` is consulted while both generators are placing fixtures, and again
independently by `VerifyCupDates`. Two rules, both hard numbers:

* **International-window guard.** If `Self.level = 1` (a national-team competition) and the
  candidate date's week is `> 47` or `< 7`, it's an automatic clash - international competitions
  are simply not allowed to schedule outside **weeks 7-47** of the 52-week season, full stop, no
  further checking needed.
* **Same-slot guard.** Otherwise it walks every other live competition (`g_competitions`) and
  flags a clash if another fixture already occupies that exact date, under four rules: any other
  `level=1, locale=2` (world) competition always clashes; a domestic competition clashes with a
  continental competition based on its own continent; a domestic league clashes with a
  continental competition in a same-locale sibling nation-league; and two domestic leagues in the
  same locale/nation clash with each other **unless both are ordinary league or league-continuation
  play** (`comptype` 0 or 4 on both sides - cup fixtures are allowed to share a date with league
  fixtures of the same nation, everything else is not).

`VerifyCupDates` (a `Function`, run over every KO competition) additionally pushes a cup round's
date forward if its own feeder round hasn't finished with at least a **6-day gap**: it builds each
feeding competition's date, adds 6 days, and if that's later than the current round's date it
adopts the later date and then walks forward one day at a time until it lands back on the right
day-of-week (`primarymatchday`).

### Playing the world's other matches

`TCompetition.PlayFixtures` (a `Function`, presumably called once per week tick) is the only place
`TFixture.PlayFixture` gets called for matches the player doesn't play. For every competition with
a non-empty fixture list, it walks every fixture whose date (`f.sdate`) is not later than the
current game date: a fixture with `result = -1` is marked played (`result = 1`) **without ever
calling `PlayFixture`** - this is the bye path (§ Quirks); a fixture with `result = 0` gets
`PlayFixture()` called on it. Once anything in the competition was played this tick, the fixture
list is re-sorted and, if every fixture is now played, `DoPromotionPlaces()` fires. `PlayFixtures`
also decides whether the just-played round is interesting enough to report to the player (returns
true for any international competition, or for the player's own nation's leagues/cups, or if
`TScreen_TestFixtures.CheckShowFixtures` says so for the rest of the world) - that's a UI concern,
not a football one, and is out of scope here.

`TFixture.PlayFixture` itself (structure confirmed, exact codegen not yet byte-matched - see
Quirks) does more than roll `GetRandomGoal()` twice. It looks up both sides' `TTableData` (their
current league-table row, carrying `teamstrength`); if either side can't be found (a stub/bye
entry) it fabricates a 0-1 or 1-0 placeholder score instead of rolling. Otherwise it rolls two goal
counts, and if the two sides' `teamstrength` differs by less than **20**, clamps the *gap* between
the two rolls to at most 4 (whichever side rolled higher is capped to `other + 4`) - a strength
band exists, and outside it the raw `GetRandomGoal()` numbers from `docs/game/match/simulated-results.md`
apply unmodified; inside it, blowout scores between evenly-matched sides are suppressed. A further
tie-break (drawn or close scores get nudged toward the stronger side using `Rand(5,1)`, i.e. a
1-in-5 factor) then decides the winner when the two goal counts are close. The exact shape of this
tie-break is the one part of `PlayFixture` **not yet nailed down byte-for-byte** - see the source
file's own recovery notes for the specific ambiguity - but the strength-band clamp, the two
`GetRandomGoal()` rolls, and the format dispatch below are all structurally confirmed.

After a score is decided, `matchtype` selects how the tie is finally resolved (table below), and
`UpdatePoints` always runs last, updating both sides' `TTableData`: **win = 3 points, draw = 1,
loss = 0** - and a penalty-shootout win also counts as `won`/3 points, not a draw, for table
purposes. `played`, `goalsf`, `goalsa` are updated unconditionally; `won`/`drawn`/`lost` from the
final score (and `penscore1`/`penscore2` when regulation was level).

### Promotion: the push half

Once a competition has every fixture played, `DoPromotionPlaces` fires. It first re-sorts every
team pool by a comptype/townregion-selected key (`SortTableBy` - points-based for League, a
different key for `RegionalSort`'s four `townregion` values), then walks every
`(teampool, promotionplace)` pair and dispatches on `place`. Only five of the nine special codes do
anything **here**: `103` (winner of each tie, via `GetWinningTeamTableId`), `104` (loser), `105`
(winner - the one-off Jamaican-league case), `106` (cup winner → continental, same as 103's
lookup), `108` (runner-up - the one-off MLS Cup case), and literal positions 1..N (walk the sorted
table to position `place`). Codes `100`, `101`, `102` and `107` are **empty `Case`s here** - see
below, they are not dead code, they are handled by the other half.

Whichever team is found is handed to `nextComp.PromoteToMe(team, sourceComp)`, whose behaviour
depends on the **destination's** `comptype`: a domestic league (`comptype=0`) either slots the team
into the one team pool it has, or - if there's more than one pool (a competition with `groups>1`
receiving from a single-source promotion, e.g. a knockout final feeding a group stage) - finds the
pool with the fewest members so far and adds there; `comptype=1` (KO) adds the team and, if the
target has fewer than 2 groups, immediately reshuffles pool order (`ShuffleIds`); `comptype=2/3`
(BestPlaced/Pool) accumulate via `AddTableDataItem` and, the moment the pool reaches
`GetNoofQualifiers()` teams, immediately call `DoPromotionPlaces` **on themselves** - a virtual
competition resolves itself the instant it's full, it doesn't wait for a scheduling tick;
`comptype=4` (LeagueCont) uses `AddItemLeagueContinuation` instead of a plain add - the one place in
the code that distinguishes "carrying a team's history forward" from "adding a fresh team", which
is the strongest evidence yet for spec 02 §3.4's guess that LeagueCont fully carries points over
(still not proven - see Gaps). There's also a continental-competition special case for domestic
leagues (`level=0, locale=1`): if the destination club doesn't yet hold a continental slot it's
simply granted one; if it already holds a *worse* one (lower `compstatus`, or same `compstatus` but
later `startweek`), the old slot is bumped down to the previous best-ranked domestic club not yet
in continental football and the new, better slot takes over - i.e., a club that qualifies for two
continental competitions in one push keeps the more prestigious one and the vacated slot cascades
down to the next-best team.

### Promotion: the pull half - resolving spec 02's open question

`PopulateTeamPool`'s `comptype=1` (KO) branch walks the destination's *own* inbound
`lplacesthatpromotetome` list and, for codes `100`, `101` and `107` specifically, pulls teams
**directly from `Clubs.csv`** rather than waiting for anything to be pushed:

```
Case 100   ' every club with leagueid = parent
Case 101   ' clubs with leagueid = parent AND continentalcompid = 0
Case 107   ' clubs with leagueid = parent AND continentalcompid > 0
```

This is a direct, code-level answer to spec 02 §5.6/§12's open question about codes `101`/`107`:
**101 = "not currently in a continental competition", 107 = "currently in one"**, tested by the
literal `continentalcompid` field, computed fresh every time the destination competition is built
 - not a fixed split like "13 clubs / 7 clubs". The apparent 13/7 English League-Cup split spec 02
found by arithmetic is simply whatever that boolean partition happens to total in a given season,
not a designed constant. Codes `102, 103, 104, 105, 106, 108` are **no-ops in this pull pass** - 
those five are exactly the ones that depend on match results (a winner, a loser, a ranked
position) and so can only be resolved by the push half once the source competition's fixtures are
actually played. Code `102` is a no-op on *both* sides of the code and unused in the data - it is
simply dead.

## The actual numbers

### Round-robin pairing tables - team-count domain

`SelectFixtureTable(teamCount, mode)` (VERIFIED, `src/recovered_module/SelectFixtureTable.bmx`,
713/713 byte-exact) doesn't compute a schedule; each `Case` is a plain `RestoreData <label>` - 
the classic BlitzMax `Data`/`Read`/`Restore` mechanism (legacy keywords `DefData`/`ReadData`/
`RestoreData`) - pointing the shared module data-read cursor (`g_competition_int01`,
`0x00C58F88`) at one of a bank of already-built static `DefData` blocks.

| `mode` | Used by | Supported team counts |
|---|---|---|
| 0 | `CreateFixtureListLeague` (round-robin) | 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, **28** |
| 1 | `CreateFixtureListKO` (bracket seeding) | 2, 4, 8, 16, 32 |

Every count from 2 to 26 has a table for league mode - **except 27**, which is skipped entirely.
This is `Select a0` in real `Case`s (all compares emitted back-to-back before any body, per the
project's Select-vs-If/ElseIf codegen tell), not an `If/ElseIf` cascade - confirmed directly from
the disassembly (`cmp eax,0x1a / je ... / cmp eax,0x1c / je ...`, no `cmp eax,0x1b` anywhere in
the function's 713 bytes) while writing the verified body, not merely inferred from the data side
as spec 02 originally was. See Quirks for what the gap means in practice.

### KO pairing - table lookup only fires for four sizes

Inside `CreateFixtureListKO`'s pairing loop, the precomputed table (loaded by mode-1
`SelectFixtureTable`) is only actually *read* when the round's team count is exactly **4, 8, 16 or 32**.
For every other size - including 2, and every odd count a bye chain produces (17, 9, 5, 3, ... - 
see spec 02 §7.4) - pairing is simple sequential adjacency: team-pool position 1 vs 2, 3 vs 4, 5 vs
6, and so on. The mode-1 table for team count 2 is loaded by `SelectFixtureTable` but its entry is
never consulted (the size check never includes `== 2`) - harmless, but dead work every time a
2-team knockout final is scheduled.

### `matchtype` - how a tie format becomes a decision rule

Set once, at fixture-creation time, from the competition's `legs` field (Competitions.csv column
16) and the leg number:

| `legs` | Tie format label | `matchtype` (leg 1) | `matchtype` (leg 2) | `PlayFixture` behaviour |
|---:|---|---:|---:|---|
| 0 | ET/P | 3 | - | Single match. Level scores → +0..2 random each side → if still level, penalties `Rand(2,7)` each, re-rolled on a tie via a coin flip (`Rand(2,1)`) that adds one goal to the winner. |
| 1 | R/ET/P | 2 | - | Single match. A drawn scoreline (`score1 = score2`) creates a replay fixture (`CreateReplayFixture`) instead of deciding anything here. |
| 2 | 2L/ET/P | 4 | 5 | Leg 1 (`matchtype=4`) just records a score, nothing is decided. Leg 2 (`matchtype=5`) compares the two-leg aggregate (via `GetFirstLegScore`); level on aggregate → +0..2 random each side → still level → away-goals-rule check (`fl2+score1*2 = fl1+score2*2`... i.e. away goals double-counted) → still level → penalties, same coin-flip rule as above. |
| League fixtures (n/a - `legs` doesn't apply) | - | 1 | - | League/LeagueCont fixtures from `CreateFixtureListLeague` are always created with `matchtype=1`. `PlayFixture`'s `Select` treats `matchtype` 0 and 1 identically (`resulttype = 1`, drawn scores stand) - `matchtype=0` is never assigned by either generator; see Gaps. |

`CreateReplayFixture` schedules the rematch for the day after the original (`sdate + 1`), then
walks forward day-by-day through `CheckFixtureClash` until it lands on a clear date, with roles
reversed (original away team now hosts).

### Table points and the `TFixture` record

| Outcome | Points | Counted as |
|---|---:|---|
| Win in regulation, or win via penalties | 3 | `won` |
| Draw stands (league fixture, or a KO tie explicitly allowed to end level) | 1 | `drawn` |
| Loss | 0 | `lost` |

Every fixture is one `TFixture` object with these fields (offsets from `object_model.json`, all
`Int`): `sdate` +8, `matchtype` +12, `round` +16, `groupno` +20, `leg` +24, `hometeam` +28,
`awaytime` - sorry, `awayteam` +32, `result` +36, `resulttype` +40, `score1` +44, `score2` +48,
`penscore1` +52, `penscore2` +56, `level` +60, `compid` +64. `result` is a tri-state, not a
boolean: `0` = not yet played, `1` = played, `-1` = a bye/placeholder that `PlayFixtures` marks
played **without simulating it at all**.

### Season gate and calendar constants, collected

| Constant | Value | Where |
|---|---|---|
| International scheduling window | weeks **7-47** of 52 | `CheckFixtureClash`, corroborated inside `CreateFixtureListLeague`'s own week-counting loop |
| Minimum gap enforced between a cup round and its feeder | **6 days** | `VerifyCupDates` |
| Fixture-list sort key | **17** | `SortFixtureList` |
| Promotion-place sort key | **18** | `SortPromotionPlaces` |
| Club sort key used to seed continental pools | **11** (strength) | `PopulateTeamPool` |
| Nation sort key used to seed international groups | **15** (fuzzy strength) - but the nations are given a *random* key first | `PopulateTeamPool` |
| KO table-lookup sizes | 4, 8, 16, 32 | `CreateFixtureListKO` |
| League table-lookup sizes | 2-26, 28 (27 missing) | `SelectFixtureTable` |
| Extra-time random goal padding (both formats) | `Rand(0, 2)` per side | `PlayFixture` |
| Penalty shootout score range | `Rand(2, 7)` per side | `PlayFixture` |
| Strength gap below which blowouts are clamped | teamstrength difference `< 20` | `PlayFixture` |
| Blowout clamp (within that band) | losing side's roll capped to `winning roll − 4` | `PlayFixture` |
| Close-match tie-break factor | `Rand(5, 1)`, i.e. roughly 1 in 5 | `PlayFixture` (exact formula not yet byte-matched) |

## What it means in play

**The world outside the player's club runs on exactly the same fixture-and-table machinery the
player's own league uses**, just without the visual match. Every rival's league position, every
cup shock, every relegation battle the player reads about in a news ticker was produced by
`PlayFixtures` → `PlayFixture` → `GetRandomGoal` (twice) → `UpdatePoints`, using the flat
goals-table from `docs/game/match/simulated-results.md`, softened only by the ±20-strength blowout
clamp described above. If a division looks statistically flat over a long career (see that
document's own conclusion), this is why - the clamp helps *within* one strength band, but it does
nothing across bands, and nothing at all affects which of two evenly-matched teams wins beyond the
1-in-5 nudge.

**Promotion and relegation are computed twice a season from the player's point of view but only
once from the engine's**: `DoPromotionPlaces` fires the moment a competition's own fixture list
empties out, immediately cascading into every competition it feeds - a completed Premiership
instantly pushes clubs into the Champions League pool, the FA Cup, the Championship, and so on, all
in one call chain, not on a later "start of season" pass. A `comptype=2/3` virtual competition (a
Pool or BestPlaced holding pen) resolves itself the *instant* it fills up, which means these can
fire mid-season, out of step with any calendar week, purely because the last team a promotion edge
was waiting on happened to arrive.

**A knockout round's bracket is not random beyond the group stage.** Only rounds that land on
exactly 4, 8, 16 or 32 surviving teams draw from the hand-built pairing tables (their contents are
not yet read - see Gaps, but their existence at all, rather than a runtime shuffle, strongly
suggests they encode a real seeding rule, e.g. keeping group-stage group-mates apart in the
Champions League Round of 16). Every other bracket size - which, per spec 02 §7.4, includes some
real "Final" rounds with three surviving teams - pairs strictly by team-pool order: whoever sits
first and second in the pool meet, third and fourth meet, and so on. There is no shuffle at all for
those sizes; `PopulateTeamPool`'s own ordering (round-robin distribution, `Clubs.csv` file order,
or `ShuffleIds` from a *previous* `PromoteToMe` call) is the only source of pairing variety.

## What we do not know yet

* **`SelectFixtureTable`'s table contents.** The function itself is now VERIFIED byte-exact (its
  own code is nothing but `RestoreData` dispatch - see above), but the ~27 league-mode `DefData`
  blocks and 4 (or 5) KO-mode ones it points into are static data nobody has read yet. Knowing the
  actual bytes at e.g. `0x00C58D94` (2-team KO) through `0x00C4C7C4` (23-team league) would let us
  state the exact round-robin schedule and, more importantly, the exact seeding rule the
  4/8/16/32 KO tables encode, rather than just "some fixed table exists". Each record is a
  `(type-tag, value)` `Data` pair (see the resolved `'d'`-tag entry below), so reading a table
  means walking that format, not raw integers.
* **`TFixture.PlayFixture`'s exact tie-break codegen.** The overall shape (strength clamp, then a
  `diff < 3 And r < 2`-style closeness test feeding into who wins) is confirmed structurally by two
  independent decompile passes, but the precise boolean decomposition is not yet byte-matched - the
  worker's own notes in `src/recovered_unverified/TFixture.PlayFixture.bmx` suggest the original
  computes the two branches (home-favoured vs away-favoured) as fully independent code rather than
  sharing one boolean, which would change exactly which edge cases favour which side.
* ~~`TCompetition.GetHomeAndAwayTeam`'s pairing-table entry format~~ **RESOLVED.** Both
  `GetHomeAndAwayTeam` and `CreateFixtureListKO` are now byte-verified
  (`src/recovered/TCompetition.GetHomeAndAwayTeam.bmx`,
  `src/recovered/TCompetition.CreateFixtureListKO.bmx`). The `'d'`-tagged entries are not a
  game-specific record format at all - they are classic BlitzMax `DefData`/`ReadData`
  records, where each Data item is a `(type-tag, value)` pair and the tag `'d'` means the
  value is a Double (8 bytes) rather than the default 4, which is why the cursor advances an
  extra word for those entries. This is the compiler's own generic Data mechanism, not
  something the game's own code decodes by hand.
* **`matchtype = 0`.** Never assigned by either fixture generator, but explicitly handled
  (identically to `matchtype = 1`) inside `TFixture.PlayFixture`'s `Select`. Something else in the
  engine - plausibly whatever creates a fixture for the *player's own* match - must set it, but
  that code hasn't been located. `TEngine.GoalScored` (docs/game/README.md gap list) is the likely
  next function to check.
* **Whether LeagueCont carries points over in full.** `PromoteToMe`'s use of a distinct
  `AddItemLeagueContinuation` call (rather than the plain `AddItem`/`AddTableDataItem` every other
  `comptype` uses) is new evidence toward spec 02 §3.4's "full carry-over" guess, but
  `TTeamPool.AddItemLeagueContinuation` itself hasn't been read yet to confirm what it actually
  copies.
* **Whether 27 teams is a real, reachable state.** Nobody has cross-checked every shipped league's
  actual entrant count against this specific gap (see Quirks) to know whether it's a live landmine
  or dead theoretical.

## Quirks worth preserving exactly

* **The missing 27-team round-robin table.** `SelectFixtureTable`'s mode-0 dispatch has a case for
  every team count from 2 to 26 and then jumps straight to 28 - there is no case for 27 (confirmed
  directly from the verified function's own disassembly, not only from the data side). If a league or
  group ever has exactly 27 teams in one pool, the global table pointer (`g_competition_int01`) is
  left pointing at whatever it held from the previous call (a stale table for a different team
  count, or uninitialised on the very first call of the game). `GetHomeAndAwayTeam` would then read
  pairs meant for a different-sized field. A faithful reimplementation must reproduce this exact
  gap - not "fix" it by adding a 27-team table - because any save file that happens to reach 27
  teams in a group depends on whatever the original actually did with stale data, and that has to
  be measured, not guessed.
* **KO pairing degrades to plain adjacency outside {4, 8, 16, 32}.** This is not a fallback path
  reserved for error cases - it is the *normal* path for the very common 2-team final, and for
  every odd-numbered round a bye produces. A reimplementation that "helpfully" always consults a
  seeded bracket table would change which teams meet in every final and every bye round.
* **`result = -1` skips simulation entirely**, it doesn't just skip the RNG calls - `PlayFixtures`
  never calls `PlayFixture` for it, so `score1`/`score2`/`resulttype` are left exactly as they were
  before the fixture was marked played. Whatever process sets `result = -1` (not yet located) must
  also set a valid score directly.
* **`IsComplete(a0=1)`'s "nothing played yet" case.** When `a0 <> 0`, completeness is judged as
  "not the case that some fixtures are played and some are not" - but if *none* are played
  (`anyplayed = 0`), that condition is false, and the competition is reported complete anyway. An
  entirely unstarted feeder competition therefore reads as "complete" under this mode, which is
  presumably intentional (a season-1 competition that simply hasn't been created yet shouldn't
  block whatever depends on it) but reads exactly like a bug if you didn't know to expect it.
  Reproduce it as written; do not tighten the condition to "all fixtures played or the list is
  empty".
* **`comptype = 2` (BestPlaced) and `3` (Pool) resolve themselves recursively.** `PromoteToMe`
  calls `DoPromotionPlaces` on the *same* competition it just added a team to, the moment the pool
  hits `GetNoofQualifiers()`. If two promotion edges both feed the last slot of such a pool in the
  same pass, the second `PromoteToMe` call reenters `DoPromotionPlaces` while the first is
  logically still "in flight" one call frame up. Preserve the direct recursive call - do not
  flatten it into a deferred/queued trigger, which would change the order teams are promoted onward
  in.
* **The FA Cup / League Cup "all teams" and "not-in-Europe" pulls happen when the *destination* is
  built, not when the source finishes.** A league doesn't need to have played a single match this
  season for its clubs to already be sitting in the FA Cup's first qualifying round pool - codes
  100/101/107 are read straight from `Clubs.csv.leagueid`/`continentalcompid` at
  `PopulateTeamPool` time. Only codes 103/104/105/106/108 wait for the source to finish.
