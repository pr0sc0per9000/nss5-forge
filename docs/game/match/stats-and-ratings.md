# Match statistics and player ratings

> **Source:** `TPlayer.RecordPlayerStats` @ 0x004ff67c (READ) · `TBall.CheckForPlayerRatings` @ 0x004cc644 (READ) · `TProfile.GetStat` @ 0x00569329 (READ) · `TProfile.GetCurrentStats` @ 0x00569a31 (READ) · `TProfile.CheckAchievement` @ 0x0056cf70 (READ) · `TProfile.GetStats` @ 0x00569912 (VERIFIED) · `TProfile.GetStringStat` @ 0x0056962d (VERIFIED) · `TProfile.GetLastMatchRating` @ 0x00569c39 (VERIFIED) · `TProfile.GetAverageForm` @ 0x00569b04 (VERIFIED) · `TProfile.CreateNewClubStats` @ 0x005662af (VERIFIED) · `TProfile.CreateNewInternationalStats` @ 0x0056635a (VERIFIED) · `TProfile.ShowRatingChanges` @ 0x0056c628 (VERIFIED) · `TProfile.UpdateMyRatings` @ 0x0056c449 (VERIFIED) · `TProfile.FixturePlayed` @ 0x005667ff (VERIFIED) · `TPlayer.AddPlayerRating` @ 0x005031ae (VERIFIED) · `TPlayer.UpdateMatchRatingAll` @ 0x004ff56d (VERIFIED) · `TEngine.UpdateMatchTime` @ 0x004d4087 (VERIFIED) · `TStats_Match.New` @ 0x0056d4c3 (VERIFIED) · `TStats_Match.AddStat` @ 0x0056d827 (VERIFIED) · `TStats_Match.CountStat` @ 0x0056d8f6 (VERIFIED) · `TStats_Match.GetPlayTime` @ 0x0056e82b (VERIFIED) · `TStats_Match.UpdateRating` @ 0x0056e2de (VERIFIED) · `TStats_Match.Clear` @ 0x0056d7f4 (VERIFIED) · `TStats_Match.Create` @ 0x0056d811 (VERIFIED) · `TStats_Match.SortListBy` @ 0x0056e2af (VERIFIED) · `TStats_Team.Create` @ 0x0056eaf2 (VERIFIED) · `TStats_Team.CreateFromString` @ 0x0056ef96 (VERIFIED) · `TStats_Team.UpdateStats` @ 0x0056eb20 (VERIFIED) · `TStats_Team.WriteData` @ 0x0056ecb7 (VERIFIED) · `TStat.Create` @ 0x0056e8bf (VERIFIED) · `TStat.New` @ 0x0056e869 (VERIFIED) · `TStat.Compare` @ 0x0056e8ff (VERIFIED) · `TEngine.ResetStats` @ 0x004d7ba9 (VERIFIED)
> **Confidence:** MEDIUM
> **Last checked:** 2026-08-15

This document leans on two different kinds of evidence. Everything about the stat *fields*
themselves and about the 0-100 in-match rating formula (`TStats_Match.*`, `TStats_Team.*`,
`TStat.*`, `TPlayer.AddPlayerRating`, `TPlayer.UpdateMatchRatingAll`, `TEngine.UpdateMatchTime`,
and most of `TProfile`'s stat-reading methods) comes from source bodies that are **byte-exact**
against the shipped exe - call these HIGH confidence. The two functions that tie it all
together at the top - `TPlayer.RecordPlayerStats` (post-match processing, 15,154 bytes, the
largest function in the game) and `TBall.CheckForPlayerRatings` (the manager's live in-match
shouts) - are **not** byte-exact. Both are "near-miss" candidates, reconstructed
to the *exact same length* as the original with only register-allocation-level
differences left (which registers/stack slots hold which temporary value - a compiler detail,
not a logic difference), but neither has crossed the byte-for-byte line yet. Treat the control
flow and the numbers quoted from those two as MEDIUM confidence - very likely right, not proven.
`TProfile.GetStat`, `TProfile.GetCurrentStats` and `TProfile.CheckAchievement` are the same
situation (near-miss candidates, read but not verified); `CheckAchievement` additionally cannot
even be tested yet (see "What we do not know yet").

## Two different things are both called "rating"

The game tracks a player two different ways, and both use the word "rating" in the recovered
names, which invites confusion:

1. **The match rating** - a number from roughly 1 to 100 (displayed to the player divided by
   10, so "7.4") that scores *this one match's* performance. It is recalculated continuously
   while the match is being played, reset to a fresh value every match, and is what decides Man
   of the Match. This is `TStats_Match.rating`, computed by `TStats_Match.UpdateRating`.
2. **Skill-attribute nudges** - small permanent changes to the player's actual ability numbers
   (Crossing, Free Kicks, Finishing, Aggression, and so on), earned from specific
   praise-or-blame moments both during and after the match. This is what
   `TPlayer.AddPlayerRating` actually does, despite the name - it does not touch the match
   rating at all.

They are covered in that order below, then how a match's stats roll up into season and career
totals, then the manager/fan/sponsor relationship and suspension systems that read them back.

## What a match logs

Every notable thing a player does in a match becomes one `TStat` record, appended to a list on
that player's `TStats_Match` (the "matchstats" object every `TPlayer` carries). A `TStat` is
six fields: a type code, the match minute, an x/y position, a direction, and a "distance" value
whose meaning depends on the type code (see below).

| `stype` | Event | Notes |
|---:|---|---|
| 1 | Ground covered | Logged periodically, not per-instant - see below. `distance` here is the extra ground covered since the last sample. |
| 2 | Shot | |
| 3 | Pass (completed) | |
| 4 | Assist | |
| 5 | Goal | `distance` here is the shot distance from goal, in pixels - used by the long-range-goal achievements (see below). |
| 6 | Header | |
| 7 | Tackle | |
| 8 | *(unnamed - see the tackle/save bug below)* | |
| 9 | Yellow card | |
| 10 | Red card | |
| 11 | Foul | |

`TStats_Match.AddStat(type, minute, x, y, direction, amount)` is the single entry point that
writes these. Type 1 (ground covered) is handled specially: the running total
`Self.distance` is bumped by `amount` on *every* call, but a `TStat` record is only appended to
the list if the match clock has moved more than 250 units past the last time one was logged - 
so the full-resolution movement total is exact, but the event log itself only samples it
occasionally, keeping the list short. *(UNCERTAIN: the unit of that 250 - the match clock this
compares against, `g_matchtime`, was not independently pinned down to milliseconds while
reading this function.)* Every other type appends a `TStat` unconditionally; types 9 and 10
(cards) also bump dedicated `yellows`/`reds` counters on `TStats_Match` at the same time, so a
card is recorded two ways - as a list entry and as a running count.

`TStats_Match.CountStat(n)` counts how many logged events have `stype = n` - with one quirk:
asking for `CountStat(11)` (fouls) **also** counts every type-9 and type-10 entry (cards). Since
every card in this game is itself the result of a foul, that is presumably deliberate - "fouls"
as displayed includes the ones that were bad enough to be booked - but it means a raw count of
type-11 entries alone understates the real foul tally by however many cards were shown.
`TStats_Team.UpdateStats` (the season roll-up, see below) does the equivalent by hand: its
`fouls` field is incremented for every type-11, -9 **and** -10 entry.

### `TStats_Match` fields (one per player, one per match)

| Field | Type | Meaning |
|---|---|---|
| `list` | `TList` of `TStat` | the full event log for this match |
| `yellows` / `reds` | `Int` | cards shown this match |
| `distance` | `Float` | total ground covered this match, in pixels |
| `lastdistancetime` | `Int` | match-clock value the last type-1 sample was taken at |
| `subbedontime` / `subbedofftime` | `Int` | match minute subbed on/off; **default `-1`**, meaning "did not happen" |
| `motm` | `Int` | 1 if this player is this match's Man of the Match, else 0 |
| `rating` | `Int` | the live match rating, 1-100 (see next section) |

## The match rating: 1-100, recomputed continuously

`TStats_Match.UpdateRating` is called from `TPlayer.UpdateMatchRatingAll`, which loops over
every player on the pitch and calls it - and that loop is itself called **on every tick of
match time** that the ball is in active play (`TEngine.UpdateMatchTime`, `g_matchstate = 1`,
skipped while the keeper is holding the ball). So there is no single "final tally" moment: every
player's rating is thrown away and rebuilt from scratch, from the complete stat list gathered so
far, dozens of times a minute throughout the match. `TPlayer.RecordPlayerStats` calls the same
loop once more at the very start of full-time processing, which is really just a last refresh
before everything downstream reads the number.

### Starting point

Four statements run in this exact order (a later one overwrites an earlier one - they are not
cumulative):

| Condition | `rating` set to |
|---|---:|
| always, first | 55 |
| was brought on as a substitute (`subbedontime > -1`) | 60 |
| substitute came on after minute 65 | 65 |
| was substituted off before minute 45 | 65 |

So a player who plays the whole match, or is subbed off after half-time, starts at 55. A normal
substitute starts at 60. A very-late substitute, or someone taken off very early, starts at 65 - 
protecting a short appearance from tanking on a small sample.

### Position: goal difference vs. a flat bonus

The player's on-pitch position (`GetPosFromSelectionNo`, 0 = goalkeeper, 1 = Defender, 2 =
Defensive Midfielder, 3 = Midfielder, 4 = Attacking Midfielder, 5 = Forward - see
`docs/game/ai/formations.md`) decides which of two very different scoring rules applies. Let
`gd` = (player's team goals) − (opponent goals), capped at a maximum of 3 (no cap on the
downside):

| Position | Formula |
|---|---|
| Midfielder, Attacking Midfielder, Forward (3, 4, 5) | `rating += gd × 2.5`, truncated to a whole number |
| Goalkeeper, Defender, Defensive Midfielder (0, 1, 2) | `rating += 5` always, **then**: if the opponent has 0 goals so far, `rating += (match minute so far) ÷ 3` (integer division) - a clean-sheet bonus that grows through the match; otherwise `rating -= (opponent goals) × 5` |

So the three most advanced positions are scored off the scoreline directly (up to +7.5 for a
3-goal lead, unboundedly negative for a heavy loss), while the three deepest positions get a
flat participation bonus plus a separate, time-weighted clean-sheet incentive or a
per-goal-conceded penalty.

### Team-strength adjustment

`m = (opponent team rating) − (own team rating)`, clamped to the range **−15 to 0** (so this
term can only ever help, never hurt, and the biggest possible help is capped at 15). It only
applies at all when the player's own team is rated stronger than the opponent
(`own team rating > opponent team rating`):

| Scoreline right now | Adjustment |
|---|---|
| Level | `rating -= m × 0.5` (0 to +7.5) |
| Losing | `rating -= m` (0 to +15) |
| Winning | `rating -= m × 0.25` (0 to +3.75) |

Read literally: the bigger the gap between your team's strength and the opponent's, the larger
the bonus applied here - and it is largest when the stronger side is *losing*, smallest when the
stronger side is winning as expected. *(UNCERTAIN: no explanation for this direction was found
in the surrounding code - it reads as compensating individual players when their favoured team
underperforms, but that is inference, not something the function states. Reproduced exactly as
computed, per the project's "do not improve the original" rule.)*

### Time on the pitch

`playTime` comes from `TStats_Match.GetPlayTime`, which derives actual minutes played from
`subbedontime`/`subbedofftime` against the current match minute. That is multiplied by a
per-minute rate and added to `rating` (truncated). The base rate is the `ratingperminute`
Engine.ini value, but it is rescaled by the match-length option (`matchlength_` is 3, 5 or 7
"minutes per half" - the compressed match-time settings; see
`docs/specs/03-game-systems-from-language-tags.md`):

| Match length setting | Per-minute rate used |
|---|---|
| 3 | `ratingperminute ÷ 5 × 3` |
| 5 | `ratingperminute` unchanged |
| 7 | `ratingperminute ÷ 5 × 7` |

This normalises the total time-based contribution to be roughly the same regardless of which
match-length option the player chose.

### Per-event bonuses and penalties

The whole event list is then walked once, and each entry adds a fixed amount depending on its
type - several with a cap on how many times they count:

| `stype` | Event | Adds | Counted at most |
|---:|---|---:|---|
| 5 | Goal | `ratinggoals` | first 3 goals only |
| 2 | Shot | `ratingshots` | first 10 shots only |
| 3 | Pass | `ratingpasses` | first 10 passes only |
| 4 | Assist | `ratingassists` | first 3 assists only |
| 6 | Header | `ratingdefensiveheaders` | first 10 headers only, **and** only if the player is in position 1 or 2 (Defender/DefensiveMid) **or** the header happened more than 30 yards from the player's own goal |
| 7 | Tackle | `ratingtackles` | first 10 of tackles+type-8 combined |
| 8 | *(see bug below)* | `ratingtackles` | shares the same first-10 counter as tackles |
| 11 | Foul | `ratingfouls` | uncapped, every foul |
| 9 | Yellow card | `ratingyellows` | uncapped, every card |
| 10 | Red card | `ratingreds` | uncapped |

**ORIGINAL BUG (VA 0x0056E763):** stat type 8 is weighted using `ratingtackles`, the *same*
Engine.ini value and the *same* first-10 counter as an actual tackle (type 7). There is a
separate `ratingsaves` value read from Engine.ini and stored in its own global for exactly this
purpose, but `UpdateRating` never reads it - it is dead code. Whatever type 8 represents (the
name pattern across the rest of this file strongly suggests goalkeeper saves, since 7 and 9-11
account for tackle/yellow/red/foul and there is no other save-like code anywhere in this
function), it is rated as a tackle, not a save, and shares a tackle's per-match cap with actual
tackles. This is reproduced faithfully, not fixed - see the header of
`src/recovered/TStats_Match.UpdateRating.bmx` for the full trace.

**Values used** - the constants baked into the compiled body (per the recovered source's own
header) and the values actually shipped in `Inc/Engine.ini` **disagree on three of eleven**:

| Key | Shipped `Inc/Engine.ini` | Value in the recovered body's annotation |
|---|---:|---:|
| `ratingperminute` | −0.25 | −0.25 |
| `ratingpasses` | 3 | 3.0 |
| `ratingdefensiveheaders` | 3 | 3.0 |
| `ratingshots` | 1 | 1.0 |
| `ratinggoals` | 17 | 17.0 |
| `ratingassists` | 10 | 10.0 |
| `ratingsaves` (unused, see bug above) | 5 | 5.0 |
| `ratingtackles` | 5 | 5.0 |
| `ratingfouls` | **−3** | **−5.0** |
| `ratingyellows` | **−5** | **−8.0** |
| `ratingreds` | **−20** | **−22.0** |

This is an open discrepancy (see "What we do not know yet") - the table above uses the shipped
data file's numbers for the first eight, which agree either way, but the three disagreeing rows
are flagged rather than silently picked.

### Final clamp

`rating` is clamped to **1-100**. Then, if the player was on the pitch for fewer than 10
minutes, it is re-clamped to a much narrower **50-60** - a short cameo can neither be rated a
disaster nor a triumph.

### Displayed vs. internal scale

Every place the game *shows* a rating to the player, it divides the stored 1-100 integer by 10
first - `TProfile.GetLastMatchRating`, `TProfile.GetAverageForm`, `TProfile.GetStringStat`
(stat code 16, the recent-form strip), and `TProfile.GetStat`'s stat code 18 all do this. So the
number the game actually shows is the familiar football convention of a rating out of 10 (e.g.
"7.4"), even though every calculation above works in whole numbers from 1 to 100.

## Man of the Match

`TPlayer.RecordPlayerStats` picks Man of the Match by scanning **every player from both teams**
(the whole match-day player list, not just the human side) and keeping the one with the highest
`rating`. Ties are broken, in order:

1. Whoever scored more goals this match (`CountStat(5)`).
2. Whoever covered more ground (`matchstats.distance`).

The winner's `matchstats.motm` is set to 1. That is the whole selection - it happens
unconditionally, for every match.

Separately, if the human-controlled player happens to be that winner, four more checks decide
whether the game actually **celebrates** it (news headline, "well done" report, relationship
boost) or quietly clears the flag back to 0 first:

* Match rating must be at least 80 (i.e. 8.0 displayed) - a technical MOTM award below that is
  suppressed.
* If the player's own team is rated more than 15 points below the opponent's **and the match was
  a draw**, the award is suppressed.
* If the player's own team is rated more than 5 points below the opponent's **and the match was
  lost**, the award is suppressed.

Only after surviving all three does the human player's MOTM actually trigger the celebratory
news/report text and the manager relationship bonus described below.

## In-match "boss shouts": skill nudges, not the match rating

`TBall.CheckForPlayerRatings` runs every time the ball changes hands or goes out of play and
decides whether the manager should shout praise or criticism at the human player, purely for
what just happened with the ball. It only fires for controlled/human-team situations
(`g_player_int01 = 1` and no message currently queued), and every branch ends in a call to
`TPlayer.AddPlayerRating(skill, delta, message-key)`.

Despite the name, `AddPlayerRating` does **not** touch `matchstats.rating`. It adds `delta`
(clamped to **±10 per call**) to one of ten "temp" skill-delta fields on the profile - the same
skill categories shown in the training screens - and, if the message key is non-empty, may also
pop a `TBossMessage` on screen (skipped outright if the player already has a red card cause; also
skipped for a "bad" shout if `matchstats.rating` is already above 95, and there is a further 1-in-4
chance of the boss actually commenting at all when a shout key is given).

| Skill code | Field nudged |
|---:|---|
| 1 | Free Kicks |
| 2 | Corners |
| 3 | Crossing |
| 4 | Positioning |
| 5 | Short Passing |
| 6 | Long Passing |
| 7 | Aggression |
| 8 | Long Shots |
| 9 | Finishing |
| 10 | Penalties |

Every shout `CheckForPlayerRatings` can trigger, and its exact skill/delta:

| Shout (message key) | Skill | Delta |
|---|---|---:|
| GOODPOSITIONING | Positioning | +2 |
| GOODINTERCEPTION | Positioning | +2 |
| GENERICBAD | Positioning | 0 (message only, no skill change) |
| BADCALL | Positioning | −1 |
| GOODCORNER / BADCORNER | Corners | +5 / −1 |
| GOODFREEKICK / BADFREEKICK | Free Kicks | +3 / −1 |
| GOODCROSS / (silent bad cross) | Crossing | +3 / −1 |
| GOODLONGPASS | Long Passing | +3 |
| GOODPASS | Short Passing | +3 |
| BADVISION (long attempt) / BADVISION (short attempt) | Long Passing / Short Passing | −2 / −3 |
| BADLONGSHOT (main) / BADLONGSHOT (ball out, credited to the last kicker - an original quirk) | Long Shots | −3 / −5 |
| BADFINISHING (×3 sites) | Finishing | −1 / −1 / −2 |
| EXPLETIVE | Penalties | −5 |
| GOODEFFORT | Long Shots | +1 |

These per-call deltas are clamped to ±10 individually, but the ten temp fields themselves are
**also** clamped to ±10 each after every `AddPlayerRating` call, so several small nudges in one
match cannot compound past ±10 before the match ends.

At the end of a match, `TProfile.ShowRatingChanges` pops up one alert per skill that changed
("Positioning +3", red/green arrow), then `TProfile.UpdateMyRatings` folds every temp delta
permanently into the real skill field and clamps each real skill to **0-100**, then zeroes all
ten temp fields ready for the next match.

## Post-match effects on relationships, news and money

`RecordPlayerStats` (READ, not byte-verified - treat the following as very likely but unproven)
turns the match's stats into changes across several other systems, gated on there being a
human-controlled player in the match at all:

* **Boss relationship** (`coachrep_boss`): `local_8 = (rating ÷ 10) − 6`, clamped to −5..5. A
  perfect match (rating 100 → 10 ÷10 −6 = +4) pleases the boss; a poor one (e.g. rating 40 → 4−6
  = −2) annoys him.
* **Fan relationship** (`coachrep_fans`): starts the same way, then adjusted by combined
  tackles+assists, whether the match was won or lost (further penalised if that loss was at
  home), and whether the team is playing a declared rival - an extra bonus for beating a rival,
  an extra penalty for losing to one.
* **Team relationship** (`coachrep_team`): from combined assists, goals and passes, floored at
  −5..5.
* **Sponsor relationship / weekly bonuses**: contract goal and assist bonuses are paid per goal
  and per assist scored (`thisweeksgoalbonus`/`thisweeksassistbonus`, scaled by the player's
  contract rates), and a clean-sheet bonus is paid if the team kept a clean sheet.
* **Bad-game penalty (Aggression)**: if combined tackles+fouls this match is 0, Aggression is
  docked −5 via `AddPlayerRating`; if fouls alone is 0 (but some tackles happened), −2; if
  combined tackles+fouls is under 4, −1. There is no corresponding bonus branch for a
  hard-tackling game in this cascade.
* **News and manager reports**: dozens of `GetText(...)` calls build the "coach report" and
  "boss report" strings shown after the match - praise/criticism keyed off cards shown, rating
  thresholds (65 and 85), whether the player is the top performer for a specific skill this
  match (best of Positioning/Short Passing/Long Passing/Aggression/Long Shots/Finishing/
  Crossing/Free Kicks/Corners/Penalties, minimum 6 to mention it at all), and whether a drug
  test was failed (see below).
* **Drug test**: if `drugs > 0` there is a 1-in-50 chance each match of a test; failing sets
  `drugs = 99`, applies a heavy one-time penalty to boss/team/fan/sponsor relationships
  (−50/−30/−30/−50) and adds a 5-game ban (see the next section) to whichever competition level
  the match was played at.

## Card suspensions: three independent counters

The game tracks bookings separately for club, continental and international football - three
counters that never interact (`docs/specs/03-game-systems-from-language-tags.md` independently
confirms three suspension message categories, `matchtype_club` / `_continental` /
`_international`). All three follow the same two-stage shape, but with different thresholds:

| Competition level | Instant ban on 2 yellows-in-a-match or any red | Accumulated-yellows ban | "One yellow from a ban" warning fires at accumulated count |
|---|---|---|---|
| Club | +3 games | `> 4` accumulated → +2 games | 4 |
| Continental | +3 games | `> 2` accumulated → +2 games | 1 |
| International | +3 games | `> 4` accumulated → +2 games | 1 |

The accumulated-yellows counter resets to 0 every time either ban is triggered. The club
warning threshold (4) does not match the continental/international one (1) - reproduced exactly
as coded, not corrected. The ban text itself ("You have been banned from playing $matchtype
matches for $num games") and the imminent-ban warning are pulled via `GetText`, confirmed
against `docs/specs/03-game-systems-from-language-tags.md`.

## Season and career aggregation

Every completed match folds into a `TStats_Team` record - one record per (competition level,
team, year). `TStats_Team.UpdateStats(matchstats)` adds the match's counts into the season
totals:

| Field | What it accumulates |
|---|---|
| `appearances` | +1 every match |
| `subs` | +1 if `subbedontime > -1` |
| `goals` | count of `stype=5` this match |
| `hattricks` | `goals ÷ 3` (integer division) |
| `shots`, `passes`, `assists`, `headers` | direct counts of the matching `stype` |
| `tackles` | count of `stype=7` **and** `stype=8` combined |
| `fouls` | count of `stype=11`, plus every `stype=9` and `stype=10` (see the `CountStat(11)` note above) |
| `yellowcards`, `redcards` | direct counts |
| `distance` | running total, converted from the match's pixels to yards and added |
| `manofthematch` | +1 if `matchstats.motm` was set |
| `form` | the match's final `rating` appended to a growing array - the full match-by-match history for that season |

### The five statlevel buckets

`statlevel` on a `TStats_Team` record is one of five values, and `RecordPlayerStats` updates
**two** records for every non-international match - the one matching the competition, and
bucket 3 (the season's "all competitions" total):

| `statlevel` | Meaning | Matches `TCompetition` |
|---:|---|---|
| 0 | Domestic league | `locale=0, level=0` |
| 1 | Domestic cup | `locale=0, level=0`, `comptype=1` (KO) |
| 2 | Continental (club or international) | `locale=1` |
| 3 | Overall / all competitions this season | - (synthetic bucket) |
| 4 | International | `level=1` |

(`locale`/`level`/`comptype` values per `docs/specs/02-competition-system.md`.) At the start of
a career or a new season, `CreateNewClubStats(clubid)` creates four fresh records - buckets 0,
1, 2 and 3 - and `CreateNewInternationalStats()` separately creates bucket 4 keyed to the
player's nation, each stamped with the current year.

### Reading stats back

* `TProfile.GetStats(statlevel, teamId, year)` collects every matching `TStats_Team` record
  (0 for `teamId`/`year` means "any").
* `TProfile.GetStat(statCode, statlevel, teamId, year)` sums one field across those records.
  Its dispatch codes do **not** match `TStat`'s per-event codes above - this is a separate,
  career-level numbering:

  | Code | Field | Code | Field |
  |---:|---|---:|---|
  | 1 | distance | 10 | redcards |
  | 2 | shots | 11 | fouls |
  | 3 | passes | 12 | appearances |
  | 4 | assists | 13 | subs |
  | 5 | goals | 14 | hattricks |
  | 6 | headers | 15 | manofthematch |
  | 9 | yellowcards | 17 | tackles |
  | 18 | average match rating (see below) | | |

  **ORIGINAL BUG:** code 16 is a dispatch entry that does nothing - asking for stat 16 silently
  returns the running total unchanged (VA 0x0056957E).
* Code 18 (average rating) is a genuine average-of-averages: for each qualifying
  `TStats_Team` record, it averages that season's own `form` entries (÷10, all matches in that
  season, not just recent ones), then averages those season-averages together across however
  many seasons matched the filter. A season with 3 games played counts exactly as much as one
  with 30.
* `TProfile.GetAverageForm(statlevel, teamId)` is different again: it takes the single most
  recent `TStats_Team` record, builds a 5-slot sliding window of its last five `form` entries
  (shifting the array left each time, so slot 4 is always the most recent match), **substitutes
  a rating of 60 for any empty slot** (protecting a player with fewer than 5 games from an
  artificially low recent-form average), sums, divides by 5 (integer division - the division
  happens before the ÷10 display scaling, so this loses a little precision on the way, faithfully
  reproduced), then ÷10.0. If there is no history at all it returns a flat 5.0.
* `TProfile.GetLastMatchRating(statlevel)` returns just the single most recent match's rating
  (skipping back one further match if the very latest record has no games logged yet), ÷10,
  or 5 if there is nothing to show.
* `TProfile.GetStringStat` is what the stats-screen UI actually calls: for every stat code
  except 16 it formats `GetStat`'s result (grouped digits, or decimal-formatted if asked); for
  code 16 specifically it builds the "recent form" strip as a 5-entry dash-separated string
  (e.g. `7.2-6.8-8.1`), reusing the same last-5 sliding-window trick as `GetAverageForm`, with
  empty leading slots trimmed rather than defaulted to 60.

## Achievements checked directly from match stats

`RecordPlayerStats` calls `TProfile.CheckAchievement(id)` directly off match numbers computed
above. This is not the full achievement catalogue (that is out of scope for this document - see
"What we do not know yet") but every trigger this function itself contains:

| ID(s) | Trigger |
|---:|---|
| 1 / 2 | Scored (≥1) / scored a hat-trick (≥3) this match |
| 3 / 4 | Career club goals (bucket 3) over 49 / over 99 |
| 5 | Clean sheet this match |
| 6 / 7 | Assisted (≥1) / 3+ assists this match |
| 8 / 9 / 10 | Combined tackles this match over 4 / 9 / 14 |
| 11 / 12 / 13 | Passes this match over 9 / 19 / 29 |
| 18 / 19 / 20 / 21 | Won a match at league / cup / continental / international level |
| 22 | Won by 5 or more goals |
| 23 | Won a domestic cup final |
| 24 | Won a continental club cup final |
| 25 | Won a continental **or** world international final |
| 86 | Won a *world*-level international final specifically (stacks with 25) |
| 29 | Played any international match |
| 30 / 31 | International caps over 49 / 99 |
| 32 / 33 | Scored (≥1) / hat-trick (≥3) in an international match |
| 34 / 35 | Career international goals over 49 / 99 |
| 85 | Recent average form (`GetAverageForm`) ≥ 10.0 (displayed 10.0/10.0), checked for both club and international |
| 87 / 88 | Career club appearances over 99 / 199 |
| 92 / 93 | Scored a goal from more than 20 / 30 metres out |

Cup-final achievement IDs 23-25/86 depend on the competition's `locale`/`level`
(`docs/specs/02-competition-system.md`); note the goal-distance achievements (92/93) use
**metres**, while every distance comparison in `TBall.CheckForPlayerRatings` and
`TStats_Match.UpdateRating` uses **yards** - the same underlying pixel unit, converted from two
different real-world units depending on which part of the game is doing the converting.

## What we do not know yet

* **`TPlayer.RecordPlayerStats` is not byte-verified.** It reaches the exact original length (15,154 bytes) with 188 same-length substitutions left
  unresolved - every one investigated so far has turned out to be a register/stack-slot choice,
  not a different statement, but that has not been checked for all 188 individually. Treat the
  control flow and numbers in the "Man of the Match", "Post-match effects" and "Achievements"
  sections as very likely correct, not proven.
* **`TBall.CheckForPlayerRatings` is not byte-verified** either, though it is closer: 2,867 of
  2,867 bytes match, with 6 same-length substitutions left, all traced to one family of
  register-allocation choices (spill order) with no semantic ambiguity found. The shout/skill/
  delta table above is high-confidence despite the READ tag.
* **`TProfile.GetStat` and `TProfile.GetCurrentStats`** are the same situation: same length as
  the original, a handful of register-choice-only gaps, semantics not in doubt.
* **`TProfile.CheckAchievement` cannot be tested at all yet.** It calls two real DLL imports
  (`GetSteamAchievement`/`SetSteamAchievement`) that the current verification harness has no way
  to link against, so this function has never been compared byte-for-byte, only read by hand.
  The achievement-unlock logic (icon load, Steam call, alert popup, `achievements[id-1] =
  today's date`) is not used anywhere in this document beyond confirming that
  `CheckAchievement(id)` marks achievement `id` unlocked - the details of that function itself
  belong in an achievements-specific document, not here.
* **The Engine.ini vs. compiled-constant discrepancy for `ratingfouls`/`ratingyellows`/
  `ratingreds`** (−3/−5/−20 in the shipped ini vs. −5.0/−8.0/−22.0 annotated in the recovered
  source) is unresolved. Both `Inc/Engine.ini` copies in this repo agree with each other, so it
  is not a simple duplicate-file mixup; which number the shipped game actually applies was not
  independently confirmed here.
* **The unit and exact meaning of the 250-tick distance-sampling threshold** in `AddStat`, and
  of `g_matchtime` generally, were not pinned down.
* **The starting values of `g_profile_float02`/`03`/`04`** - the accumulators `GetStat` returns
  on an empty list, or starts summing from - were not read directly; they are presumed to be
  0.0 by context but this was not confirmed against the data section.
* **Position codes 0-5** are taken from `docs/game/ai/formations.md` (itself MEDIUM confidence
  overall, though the specific `GetPosFromSelectionNo` mapping used here is from a VERIFIED
  function). This document trusts that mapping rather than re-deriving it.
* **Why the team-strength adjustment in `UpdateRating` rewards the stronger side** for a
  disappointing scoreline instead of penalising it is not explained anywhere in the function - 
  flagged, not resolved.
* **The full achievement catalogue** (all IDs beyond the ~30 referenced directly from
  `RecordPlayerStats`) is out of scope here and remains a gap - `TProfile.CheckAchievement`'s own
  body would need to be cross-referenced against every caller across the whole game to complete
  it.
* **`GameMedia/Languages/Languages.csv`**, mentioned as a source for UI stat labels, does not
  exist in this checkout (searched the full repository tree; not present under any path). Label
  text used above (e.g. "Free Kicks", "Positioning") comes instead from string literals read
  directly out of the binary by the byte-verified recovered source files themselves.
