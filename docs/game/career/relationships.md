# Relationships, morale and off-pitch life

> **Source:** `TProfile.UpdateRelationship` @ 0x0056a955 (VERIFIED) · `TProfile.GetHappiness` @ 0x0056add8 (VERIFIED) · `TProfile.RandomIncident` @ 0x00567c79 (VERIFIED) · `TProfile.GetLifestyle` @ 0x0056b5da (VERIFIED) · `TProfile.GetFame` @ 0x0056b64e (VERIFIED) · `TProfile.GetStatus` @ 0x0056a8d0 (VERIFIED) · `TProfile.GotSponsor` @ 0x0056bfae (VERIFIED) · `TProfile.OfferSponsorship` @ 0x0056c158 (VERIFIED) · `TProfile.CheckSponsorExpiry` @ 0x0056bfe2 (VERIFIED) · `TProfile.Play` @ 0x00566397 (VERIFIED) · `TProfile.FixturePlayed` @ 0x005667ff (VERIFIED) · `TScreen_Relationships.ButtonRelationship` @ 0x00540958 (VERIFIED) · `TScreen_Relationships.SetUpScreen` @ 0x00540590 (VERIFIED) · `TScreen_Relationships.ButtonFriendsRacing` @ 0x00540da5 (VERIFIED) · `TScreen_Relationships.ButtonTeamCasino` @ 0x00540d21 (VERIFIED) · `TScreen_Relationships.ButtonGirlEnd` @ 0x00540c58 (VERIFIED) · `TScreen_Dilemma.ButtonRelationship` @ 0x00557bfa (VERIFIED) · `TScreen_Dilemma.SetUpScreen` @ 0x00556e11 (VERIFIED) · `TScreen_Pairs.SetUpScreen` @ 0x00578f5e (VERIFIED) · `TScreen_Pairs.Update` @ 0x00579419 (VERIFIED) · `TScreen_Pairs.Success` @ 0x00579658 (VERIFIED) · `TPair_Icon.SetUp` @ 0x005799e3 (VERIFIED) · `TPair_Icon.CreateAll` @ 0x005798da (VERIFIED) · `SponsorName` @ 0x00508131 (VERIFIED) · `TScreen_MatchPrep.NextFixture` @ 0x0055f262 (VERIFIED) · `docs/specs/03-game-systems-from-language-tags.md` §10 (INFERRED, from `Languages.csv` tags, no VA)
> **Confidence:** HIGH
> **Last checked:** 2026-08-15

Your career player is not just a set of football stats. Six named relationships plus an
overall "fame" score sit on the profile alongside your skills, and they are read and
written by code throughout the career loop: they gate team selection, they get damaged by
skipping matches, drinking and gambling, they get repaired by mini-games and random
requests, and they combine into a single "happiness" number that (per the game's own tip
text) makes you misplace the ball more often when it is low.

## What the game tracks

`TProfile` - the save-game record for your career player - carries seven scalars for your
off-pitch life, all `Int` fields except fame, which is stored as an `Int` but read back
through a `Float`-typed getter:

| Field | Range | What it is |
|---|---|---|
| `relationboss` | 0-100 | Your manager/coach. Debug label `CRELATION_BOSS:` |
| `relationteam` | 0-100 | Your team mates. `CRELATION_TEAM:` |
| `relationfans` | 0-100 | Your supporters. `CRELATION_FANS:` |
| `relationfriends` | 0-100 | Your non-football friends. `CRELATION_FRIENDS:` |
| `relationgirlfriend` | **0 = no girlfriend**, else 1-100 | Romantic relationship. `CRELATION_GIRLFRIEND:` |
| `relationsponsors` | 0-100 | Your commercial sponsors. `CRELATION_SPONSORS:` |
| `relationfame` (read via `GetFame()`) | 0-100 | Overall celebrity, not a "relationship" but tracked and clamped the same way. `CRELATION_FAME:` |

Sponsorship itself is nine separate deals (`sponsor_amount[0..8]` cash value,
`sponsor_expires[0..8]` an in-game day number), one relationship score
(`relationsponsors`) shared across all of them, plus two housekeeping fields:
`girlscandalrating` (0-100, set once when you get a girlfriend) and
`lastspendtimefriends` / `lastspendtimegirlfriend` (the day you last actively spent time
with that group - used to detect neglect).

All six relationships plus fame are edited through one function, `TProfile.UpdateRelationship(kind, amount)`,
where `kind` is 1=Boss, 2=Team, 3=Fans, 4=Friends, 5=Girlfriend, 6=Sponsors, 7=Fame. Every
other system in the game - the mini-games, the random events, the news stories, match
celebrations - calls into this one gate, so its rules apply everywhere:

* Boss/Team/Fans/Friends/Sponsors clamp to **0-100**.
* Girlfriend clamps to **1-100** once you have one, but a **positive** change that would
  land below 10 instead **ends the relationship outright** (sets it to 0, shows a dump
  message, and - if your fame is over 50 - publishes a break-up news story instead of a
  simple pop-up). A *negative* change is never blocked this way; only a positive nudge that
  can't clear 10 triggers the dump. Trying to raise the relationship with no girlfriend at
  all (`relationgirlfriend = 0`) is silently ignored.
* Sponsors changes are ignored (and the score forced to 0) if you currently hold zero
  sponsor deals (`GotSponsor()` returns false) - you cannot have a "sponsor relationship"
  with nobody.
* Fame is special-cased on the way *up*: a **positive** fame gain is capped by your club's
  strength. The cap is `Clamp(myclub.strength * 0.1, 1.0, 10.0)`, so a single incident can
  raise fame by at most 10 (big, famous club) or as little as 1 (small club) regardless of
  how large the nominal gain was. Fame *losses* are not capped this way.
* After every change, the function checks each of the six relationship scores (and
  happiness, and fame) against 100 and unlocks the matching "reach 100%" achievement the
  instant it is crossed (see the table below) - so these are edge-triggered unlocks, not
  polled.

## Happiness, status and lifestyle - the derived numbers

**Happiness** (`GetHappiness()`) is the one number the game actually calls "morale" in its
help text. It is a straight average of the six relationships plus fame, with the
girlfriend counted twice:

```
Happiness = Int( boss + team + fans + friends + 2*girlfriend + sponsors + fame ) / 8
```

Eight "shares" - six relationships, one extra share for the girlfriend, one for fame - so a
maxed-out profile with a maxed-out girlfriend lands at exactly 100. A player with no
girlfriend simply has 0 contributed for both girlfriend terms, which quietly caps their
achievable happiness below what a player who's found one can reach for a given set of
other scores.

**Lifestyle** (`GetLifestyle()`) is not a relationship, but it feeds sponsorship pricing and
gates the girlfriend event, so it belongs in this system: count how many of your ten item
slots, ten vehicle slots and ten property slots (30 total) are non-zero, divide by 30,
multiply by 100.

**Status** (`GetStatus()`), an overall "how are you doing" figure, averages five things - 
unlocked-achievement *count* (not a percentage - this is a raw integer, so it behaves
differently in scale from the other four terms), skill rating, lifestyle, fame and
happiness - divided by 5.

## Spending time: three ways to raise a relationship

| Method | Screen / function | Energy cost | Relationship gain | Notes |
|---|---|---:|---:|---|
| **Meet them** (Pairs mini-game) | `TScreen_Relationships.ButtonRelationship` → `TScreen_Pairs` | **20** (paid up front, win or lose) | **+10** on success, **0** on failure | See mini-game detail below |
| **Casino with team mates** | `TScreen_Relationships.ButtonTeamCasino` | 20 | +5 flat, Team only | No mini-game, guaranteed |
| **Racing with friends** | `TScreen_Relationships.ButtonFriendsRacing` | 20 | +5 flat, Friends only | No mini-game, guaranteed |
| **End it** (girlfriend only) | `TScreen_Relationships.ButtonGirlEnd` | 0 | sets girlfriend to 0 | Publishes a break-up news story |

All three spending routes require **energy ≥ 20** - below that the buttons visibly dim
(`SetUpScreen` sets their alpha to 0.5) and clicking them returns a "too tired" message
instead of acting. The "meet" buttons for Boss/Team/Fans/Friends are always available once
energy allows it; Girlfriend and Sponsors only light up if you actually have one
(`relationgirlfriend > 0`, `GotSponsor()`).

### The Pairs mini-game

Meeting someone launches `TScreen_Pairs`, a memory/matching game (help text:
*"Try to find two matching pictures to ensure that you have a good time"*). The verified
numbers:

* The board is a **4×4 grid - 16 face-down tiles** (`TPair_Icon.CreateAll` creates exactly
  16 icons, `NewButtonPositions` lays out a 4-row-by-4-column grid).
* Each relationship type has exactly **4 distinct face images** (`Boss_1..4.png`,
  `Team_1..4.png`, etc., loaded by `TPair_Icon.SetUp`), and each image is assigned to
  **4 of the 16 tiles**, not 2 - so despite the "Pairs" name, any given picture appears
  four times on the board, not twice. Tile order is shuffled by sorting on a per-tile
  random number 0-99 (`TPair_Icon.Compare`), redrawn fresh every time you meet someone.
* You get **two attempts** to flip a matching pair (`TScreen_Pairs.Update` tracks
  `g_pairs_tries`; it calls `Fail()` once `tries = 2` without a match). Flip two tiles: if
  their `imgId` matches, you win immediately, even on the first attempt; if not, and it was
  your second attempt, you fail; otherwise the tiles flip back and you get one more go.
* Win: plays a sound, calls `UpdateRelationship(kind, +10)`, and shows one of four
  flavour-text lines per relationship (`CDILEMMA_BOSS1..4`, `CDILEMMA_TEAM1..4`, etc. - the
  same 24-line pool the Dilemma screen uses, see below). Lose: shows a plain "Fail!"
  toast, no relationship change at all - you still paid the 20 energy for nothing.

## The Dilemma screen - forced trade-offs

Independent of anything you click, the game can present a **Dilemma**: *"Two people want to
meet you at the same time - choose which relationship you want to increase."*
`TScreen_Dilemma.SetUpScreen` picks two *different* relationship kinds at random from the
same 1-6 set (Girlfriend only eligible if you have one, Sponsors only if you have one),
shows both relationships' current bars and a portrait for each (see the image-selection
table below), and waits for you to click one. Picking a side calls:

```
UpdateRelationship(chosen,   +10)
UpdateRelationship(rejected, -10)
```

 - a genuine zero-sum trade, no energy cost. If you pick Friends or Girlfriend, that also
resets the neglect timer (`lastspendtimefriends` / `lastspendtimegirlfriend`) for that side,
exactly as if you had spent time with them directly.

The portrait shown for each side is picked at random from a small venue pool, which doubles
as the asset list under `GameMedia/Images/Relationships/`:

| Relationship | Possible venue image |
|---|---|
| Boss | `boss.png` or `training_ground.png` (50/50) |
| Team | `bowling.png`, `golf_course.png` or `training_ground.png` (1-in-3 each) |
| Fans | `fans.png` (always) |
| Friends | `bowling.png`, `cinema.png`, `golf_course.png`, `pub.png` or `shopping.png` (1-in-5 each) |
| Girlfriend | `cinema.png`, `pub.png`, `restaurant.png` or `shopping.png` (1-in-4 each) |
| Sponsors | `sponsors.png` (always) |

## Random incidents - the weekly event roll

`TProfile.RandomIncident()` is a single large dispatcher: it rolls `r = Rand(6,1)` (1-6),
and if that number is the same as the *previous* roll it does nothing that turn (a simple
de-dupe against repeating the same incident category twice running), otherwise it runs the
branch for `r`. Below `r` are the six top-level categories it can pick; several branches
have an inner condition that can also produce nothing, so not every roll is guaranteed to
show an event:

| Roll | Category | Condition | Effect |
|---:|---|---|---|
| 1 | **Booze scandal** | `booze > 90` | One of five relationships is damaged **−20**: Boss, Girlfriend, Friends (only if not currently injured), Sponsors (only if you have one), or Team - chosen by a second `Rand(5,1)` |
| 2 | **Gambling addiction** | `gambling > 90` and `contractwage > 5000` | **All five** of Sponsors/Girlfriend/Friends/Fans/Boss take **−20 simultaneously**, plus a published news story |
| 2 | **Gambling problem** | else if `gambling > 60` | One relationship takes **−20**: Sponsors, Girlfriend, Friends or Boss, chosen by `Rand(5,1)` (some rolls do nothing) |
| 3 | **Sponsor offer** | An empty sponsor slot exists and `Fame > slotIndex*10 + 15` | Offers that sponsorship (see table below) |
| 4 | **Girlfriend event** | No girlfriend and `date.sdate > 70` (day 71+ of the career) | Gated by Friends and Lifestyle rolls (below), then a chance to start dating |
| 4 | **Girlfriend event** | Has girlfriend | Scandal check, then a 28-day neglect check |
| 5 | **Friends neglect** | `date.sdate > lastspendtimefriends + 42` | **−10** Friends, warning message |
| 6 | **Lost item/vehicle** | `date.sdate > 180`, 1-in-4 sub-roll | Lose an owned item, or an owned vehicle (cheap ones just vanish; ones worth ≥100,000 offer a pay-half-to-keep choice) |

After that block (whether or not it fired), three more independent checks run every call:

* If you have no phone (`items[0] = 0`): a "need a phone" message and **−2** to Team or
  Friends (50/50).
* Otherwise, **1 in 10**: a random rival club in your league gets **±3 strength** and a news
  story (`CNEWS_RANDOMCLUBBOOST*` / `CNEWS_RANDOMCLUBCRISIS*`).
* Otherwise, **1 in 10** *and* `energy < 90`: a free energy top-up of `min(50, 100-energy)`
  from Girlfriend (if you have one), Physio, Friends or Team (`Rand(4,1)` chooses which,
  Girlfriend re-rolled away if absent).
* Otherwise, **1 in 5** *and* `energy ≥ 15`: someone **requests** your time - Boss, Team,
  Fans, Friends, Girlfriend or Sponsors (Girlfriend/Sponsors skipped if you don't have them)
  - accepting costs **15 energy** for **+5** to that relationship (+5 Fame too, if it was a
  Sponsor request); declining costs you **−5** to that relationship instead, for free.
* If none of the above fired, the Dilemma screen (above) is shown instead.

### Girlfriend event detail

If you don't have a girlfriend yet (and it's day 71+): first your **Friends** score must
beat `Rand(40,1)+40` (a threshold of 41-80), then your **Lifestyle** score must beat
`Rand(30,1)+20` (a threshold of 21-50) - either failure just shows a "haven't met anyone"
or "not impressed" message and ends the incident. Clear both gates and you're offered a new
girlfriend with a random "scandal rating" `Rand(100,1)` shown up front; accepting sets
`relationgirlfriend = 50`, stores the scandal rating permanently, resets the neglect timer
to today, and unlocks the "Get a girlfriend" achievement (45).

If you already have one, every incident roll of 4 first checks
`girlscandalrating > Rand(100,1)` - a scandal roll that becomes more likely the higher that
girlfriend's fixed scandal rating is. On a scandal:

| Scandal rating | Boss penalty | Fame gain |
|---:|---:|---:|
| > 75 | −20 | +7 |
| 51-75 | −15 or −10 (50/50) | +5 or +3 |
| ≤ 50 | −5 | +2 |

Otherwise, if it's been more than 28 days since you last actively spent time with her
(`lastspendtimegirlfriend`), you get a "long time no see" warning and **−10** Girlfriend.

## Sponsorship

Nine sponsor slots exist, filled one at a time by `RandomIncident`'s category-3 roll: slot
`i` (0-8) can only be offered once your fame passes `i*10 + 15`, so the game effectively
gates sponsor categories by fame in order:

| Slot | Category (`SponsorName`) | Fame required |
|---:|---|---:|
| 1 | Boots | > 15 |
| 2 | Sports drink | > 25 |
| 3 | Sports clothing | > 35 |
| 4 | Casual clothing | > 45 |
| 5 | Food | > 55 |
| 6 | Cosmetics | > 65 |
| 7 | Watch | > 75 |
| 8 | Electronics | > 85 |
| 9 | Jewelry | > 95 |

Each accepted deal pays a lump sum and runs for exactly **364 days** (not 365):

```
cash = category_index * 15000
     + relationsponsors * 2500
     + Lifestyle() * 1500
     + Fame() * 1500
```

Accepting a sponsor for the first time (when `relationsponsors = 0`) sets that score to 50.
Filling all nine slots at once unlocks achievement 53. Every time a fixture is played
(`FixturePlayed` → `UpdateHealth` → `CheckSponsorExpiry`), two things happen: any deal past
its `sponsor_expires` day is dropped with a message, and - independently - **if your
sponsor relationship is below 20**, one currently-held sponsor is picked at random
(`Rand(0,8)`) and cancelled early regardless of its expiry date. If that leaves you with
zero sponsors, `relationsponsors` is reset to 0.

## What playing football does to relationships

Not everything above happens from menus. The match/career loop itself pushes relationships
around:

* **Skipping a fixture** (`TScreen_MatchPrep.NextFixture`) is punished immediately: skipping
  a selected club match costs a week's wages (docked straight from `bank`) plus **Boss −15,
  Team −10, Fans −10, Fame −5**; skipping an international costs **Fans −15, Fame −5**. If
  you didn't even pick a match to play that week at all (`selectedformatch = -7`), all four
  of Boss/Team/Fans/Fame drop by **5**, or by **10** if you'd already skipped once before.
* **Being far more famous than your club deserves** is a slow drain: every single day that
  passes in `TProfile.Play`, if `Fame > myclub.strength + 10`, Fame quietly loses **1**
  point. A superstar stuck at a small club bleeds fame every day until the mismatch closes
  (by your fame falling, or by moving to a bigger club).

`docs/specs/03-game-systems-from-language-tags.md` §10.2 (INFERRED from help/tip text, not
from reading the match-engine code directly - no VA available for these specific claims)
adds a set of in-match effects that this document has not independently verified against
code: the Boss score is said to also gate being picked for the first team and to gate
things like formation changes and contract renewal; the Team score is said to change how
often team mates pass to you; low Fans is said to cause booing that costs you ball control;
low Happiness is said to increase misplaced kicks in matches (`matchmsg_Unhappy`,
*"Unhappiness strikes!"*); and goal celebrations (`Celebrate1..5`) and being interviewed
after a match are both said to raise Fame and the relevant relationship. These are plausible
and consistent with everything verified above, but they live in match-engine functions that have
not been opened - treat them as strong leads, not confirmed numbers.

## Achievements unlocked by this system

Checked live inside `UpdateRelationship` every time a score changes, plus a few checked
elsewhere:

| # | Achievement | Trigger |
|---:|---|---|
| 45 | 100% relationship with Boss | `relationboss >= 100` |
| 46 | 100% relationship with Team | `relationteam >= 100` |
| 47 | 100% relationship with Fans | `relationfans >= 100` |
| 48 | 100% relationship with Sponsors | `relationsponsors >= 100` |
| 49 | 100% relationship with Friends | `relationfriends >= 100` |
| 50 | 100% relationship with Girlfriend | `relationgirlfriend >= 100` |
| 51 | 100% Happiness | `GetHappiness() >= 100` |
| 76 | 100% Fame | `GetFame() >= 100.0` |
| 52 | Sign a sponsorship contract | inside `OfferSponsorship`, on first acceptance |
| 53 | Sign the maximum number of sponsorship contracts | inside `OfferSponsorship`, when all 9 slots are filled |
| 79 | Get a girlfriend | inside `RandomIncident`, when you accept a new girlfriend |

## What we do not know yet

* **Who calls `RandomIncident`.** The function has been read completely, but its caller is
  not anywhere in the recovered corpus or in the direct-call table
  (`extracted/call_sites.tsv`), which suggests it is reached through an unresolved virtual
  dispatch - plausibly a "check your phone" button on the home screen, since the tail of the
  function explicitly checks `items[0] = 0` ("need a phone"). Until that call site is found
  we cannot say exactly *when* in the weekly loop this roll happens (once per day? once per
  fixture? on opening a specific screen?).
* **`TProfile.CheckAchievement`** itself (the generic unlock/notify routine called by all the
  achievement numbers above) has not been read - we know *when* it fires for
  relationships but not what it does when fired (toast text, save-flag format, Steam/mobile
  overlay hookup).
