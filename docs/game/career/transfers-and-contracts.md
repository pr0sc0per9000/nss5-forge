# Transfers, contracts and club interest

> **Source:** `TContractOffer.New` @0x00570eed (VERIFIED) · `TContractOffer.Delete` @0x00570f9b (VERIFIED) · `TContractOffer.LoadData` @0x00570fbd (VERIFIED) · `TContractOffer.WriteData` @0x00571030 (VERIFIED) · `TContractOffer.CreateContract` @0x00571214 (VERIFIED) · `TContractOffer.GetOffer` @0x00571431 (VERIFIED) · `TContractOffer.DoNegotiation` @0x00571c1b (VERIFIED) · `TContractOffer.IncreaseOffer` @0x00571d0a (VERIFIED) · `TContractOffer.GetStringLength` @0x00571d8b (VERIFIED) · `TContractOffer.EraseInterestedClubs` @0x00571dc9 (VERIFIED) · `TContractOffer.TransferWindowOpen` @0x00571df9 (VERIFIED) · `TContractOffer.CheckTransferWindow` @0x00571e91 (READ) · `TContractOffer.GetInitialClub` @0x00572500 (VERIFIED) · `TContractOffer.UpdateInterestedClubs` @0x00572643 (READ) · `TContractOffer.GetClubsInterestedInLoan` @0x00572a53 (VERIFIED) · `TContractOffer.GetPlayerValueStatus` @0x00572c50 (VERIFIED) · `TContractOffer.CheckClubCanAffordPlayer` @0x00572e4d (VERIFIED) · `TContractOffer.SignForNewClub` @0x00572f47 (READ) · `TContractOffer.CheckPromoteFromBTeam` @0x005734f4 (VERIFIED) · `TContractOffer.DoTransferRumour` @0x005736dc (VERIFIED) · `TScreen_ContractOffer.ButtonAccept` @0x00554297 (VERIFIED) · `TScreen_ContractOffer.ButtonReject` @0x00554219 (VERIFIED) · `TScreen_ContractOffer.ButtonNegotiate` @0x00554270 (VERIFIED) · `TScreen_MyContract.ButtonRequestTransfer` @0x0055587a (VERIFIED) · `TScreen_MyContract.UpdateTransferStatus` @0x00555195 (VERIFIED)
> **Confidence:** MEDIUM
> **Last checked:** 2026-08-15

Seventeen of the twenty `TContractOffer` methods below are byte-matched against the
original - the money formulas, the negotiation gate, the afford/loan eligibility checks and
the save format are as certain as anything in this project gets. The three that are not
(`CheckTransferWindow`, `SignForNewClub`, `UpdateInterestedClubs`) are read from Ghidra's
decompile only. They are the functions that decide *when* interest and offers happen at all,
so this document leans on them a lot; every number pulled from them is flagged READ and the
prose says where the uncertainty is.

## What the system does

### The offer object

A `TContractOffer` is one club's current offer to the player: a wage, a contract length, three
performance bonuses, a signing fee, and how the *new* boss feels about the player
(`newbossrel`). Every offer that currently exists lives in one global list. Offers are created
lazily - the first time the game needs to know "what would club X offer me", it either finds an
existing offer for that club in the list or invents one from scratch and adds it.

### Getting an offer - the money formula

`TContractOffer.GetOffer(club)` is the function that invents an offer. There is one hard-coded
special case: **the very first contract of a new career** (no wage on file yet, and it is year
1) is always wage 1000, 3-year length, 50/50/50 bonuses, 1000 signing fee - a fixed starter deal,
not computed from anything about the club.

For every other offer:

- **Wage** starts as `2.25 ^ (clubStrength / 6.5)`, i.e. it grows exponentially with the target
  club's strength rating, not linearly.
  - If the offer is from the player's **current** club, the wage is then multiplied by
    `max(relationboss / 75, 0.7)` - a poor relationship with the boss (below 52.5) cannot push
    the multiplier below 0.7, so an unhappy boss still can't offer less than 70% of the raw
    figure.
  - If the offer is from a **different** club and the player's current contract has already
    expired, the wage is multiplied by 1.25 instead (a 25% bump for negotiating as a free pass).
  - The wage from the player's *current* club can never drop below what they are already
    earning, as long as they are under 31: if the new offer would pay less than
    `contractwage` and `GetAge() < 31`, the game just keeps the old wage.
- **Length** is `Rand(3, 5)` years, then capped by age: over 30 it can't exceed 3 years, over 32
  not more than 2, over 33 not more than 1. A 34-year-old is never offered more than a one-year
  deal by this formula.
- **Bonuses** (goal / assist / clean-sheet, paid presumably per occurrence during a season) come
  from a `Select` on the player's position code (0-5) and both club strengths:

  | Position | Goal bonus | Assist bonus | Clean-sheet bonus |
  |---|---|---|---|
  | 0 | 0 | 0 | `strength·myStrength/5 + 50` |
  | 1 | 0 | 0 | `strength·myStrength/5 + 50` |
  | 2 | 0 | `strength·myStrength/20 + 50` | `strength·myStrength/10 + 50` |
  | 3 | `strength·myStrength/15 + 50` | `strength·myStrength/15 + 50` | 0 |
  | 4 | `strength·myStrength/20 + 50` | `strength·myStrength/10 + 50` | 0 |
  | 5 | `strength·myStrength/10 + 50` | `strength·myStrength/20` (no +50) | 0 |

  Positions 0-1 (defensive-looking, clean-sheet only) and 5 (goal-heavy, no clean-sheet bonus)
  bookend the table; the exact position-name mapping is not confirmed in this pass, so codes
  are given as-is rather than guessed names.
- **Signing fee** starts as `clubStrength²`, then both fee and bonuses are scaled by a strength
  tier for the *target* club:

  | Target club strength | Signing fee | Bonus multiplier |
  |---:|---:|---:|
  | ≥ 90 | ×10 | ×3.0 |
  | 86-89 | ×6 | ×2.0 |
  | 83-85 | ×4 | ×1.5 |
  | 80-82 | ×2 | ×1.25 |
  | 75-79 | ×1.5 | ×1 (unchanged) |
  | < 75 | ×1 (unchanged) | ×0.5 |

  On top of that, if the player's current contract has already expired *and* the target club
  isn't the current one, the signing fee is further multiplied by 4 - a lapsed contract makes a
  player a much more expensive prize once someone actually wants to sign them, not a discount.
- **Rounding.** Every final figure is deliberately rounded down to a clean number: wage and all
  three bonuses to the nearest 100, the signing fee to the nearest 1000. Minimums apply after
  rounding: wage floors at 500, signing fee floors at 500.

### Negotiating

`TContractOffer.DoNegotiation` gates whether the player is even allowed to push back on an
offer:

- If the offer already has `negotiationsuccess` set (a previous bump succeeded), any further
  attempt is refused with a "not negotiating" message.
- If `newbossrel < 40` (the new boss doesn't rate the player enough to bargain):
  - at the player's **current** club, same "not negotiating" message;
  - at **any other** club, negotiations are outright **cancelled** - `newbossrel` is reset to 0
    and the offer is effectively dead.
- Otherwise the negotiation screen opens.

`TContractOffer.IncreaseOffer(percent)` is what a successful negotiation calls: it marks
`negotiationsuccess = 1` (locking further negotiation) and bumps wage and all three bonuses and
the signing fee by `field + (field/100)*percent` - a straight percentage increase on each figure
independently, using integer division so small fields barely move.

### Signing

`TScreen_ContractOffer.ButtonAccept` calls `TContractOffer.SignForNewClub()` on the offer being
viewed. It behaves differently depending on the situation (READ tier - the field reads below are
confirmed against `object_model.json`, but the function itself is not byte-matched):

1. **First contract ever** (`contractwage == 0`): unlocks achievement 81 ("first contract"),
   posts a `CNEWS_FIRSTCONTRACT` news headline, sets the club as `myclub`, and calls
   `TProfile.CreateNewClubStats` to start a fresh stats row.
2. **Renewing at the current club** (offer's club id == `clubid`): posts a
   `CNEWS_RENEWCONTRACT` headline and sets `relationboss = offer.newbossrel`. Nothing else about
   the relationship changes.
3. **A genuine move to a different club**: clears the old club's report strings
   (`bossreport`/`physioreport`/`coachreport`/`webheadline`), resets the play-button icon,
   computes a **carried-over reputation** value - half of the player's total appearance count at
   the old club (`GetStat(12,3,clubid,0) / 2`), clamped to 20-80 - and checks four escalating
   achievement thresholds against the player's overall value (`GetValue()`, *not* the actual
   signing fee): over $1,000,000, $5,000,000, $10,000,000 and $19,999,999+ each unlock a further
   achievement. `relationboss` is set from `offer.newbossrel`, `relationteam` is reset to 50,
   the captaincy flag is cleared, and if the player was on loan (`transferlisted == 4`) the loan
   is cancelled first. The popup shown differs: `CMESSAGE_TRANSFERNEWCLUB` (with the fee-derived
   text) if the old contract hadn't expired yet, `CMESSAGE_TRANSFERNEWCLUBFREE` if it had - i.e.
   the game visibly distinguishes a **paid transfer** from a **free transfer**.

Regardless of which of the three cases fired, the shared tail of the function then:

- sets `contractexpires` to today plus the offer's `length` in years;
- copies wage, goal/assist/clean bonuses onto the live profile contract fields, and pays the
  signing fee into the bank via `UpdateBank`;
- resets `transferlisted` to 0 and `lasttransferdate` to today (this restarts the anniversary
  clock described below);
- refreshes the game-menu title/nav panels, plays the signature sound
  (`GameMedia/Sounds/Signature.ogg`), shows the popup message, and **clears the entire pending
  offers list** - every other club's outstanding offer is discarded the moment one is accepted.

`TScreen_ContractOffer.ButtonReject`: rejecting the player's very first-ever offer
(`myclub` still unset) asks for confirmation via `CMESSAGE_FIRSTCONTRACTREJECT` before letting
the reject go through; rejecting any later offer needs no confirmation.

### Transfer windows

`TContractOffer.TransferWindowOpen()` is a simple calendar check on the in-game week number:

| Weeks | Window |
|---|---|
| 1-10 | **Open** |
| 11-25 | Closed |
| 26-32 | **Open** |
| 33-52(ish) | Closed |

### The background interest system (READ tier)

`TContractOffer.CheckTransferWindow` is the function that appears to drive the whole system
over time - string evidence (`GetText` keys read directly out of the .exe) makes the intent
clear even though the function itself is unverified:

- **Once a week** (gated on it being day 1 of the in-game week), once the week is past 10:
  - at **week 26**, it shows `CMESSAGE_TRANSFERWINDOWOPEN`, and if the player is not already
    listed and `relationboss < 30`, it transfer-lists the player itself
    (`transferlisted = 2`) with the message `CMESSAGE_TRANSFERLISTEDBOSSUNHAPPY` - an unhappy
    boss puts the player up for sale without being asked.
  - otherwise, once the week passes 32, at week 33 it shows `CMESSAGE_TRANSFERWINDOWCLOSED` and
    clears the interested-clubs list.
- **Every week, independent of the window**, it checks the calendar against the player's
  contract:
  - if today falls in the **7 days right after** `contractexpires`, it shows
    `CMESSAGE_CONTRACTEXPIRED` (cancelling a loan first if the player was on one) and sets
    `transferlisted = 2`.
  - otherwise, if `relationboss > 50`, it checks six 8-day windows: the 1st, 2nd, 3rd and 4th
    anniversary of `lasttransferdate` (the day the player joined), and two countdown windows
    roughly 6 months and roughly 11 weeks before `contractexpires`. Landing in any of them clears
    any pending offer for the **current** club and shows `CMESSAGE_CONTRACTNEWOFFER` - a good
    relationship with the boss makes the club pre-emptively dangle a new deal.
- **Every 14 days**, once the in-game clock is past day 27, and **only while the transfer window
  is closed**: if the player has been at the current club for more than 84 days
  (`lasttransferdate + 84 < today`), it calls `UpdateInterestedClubs()`, then compares career
  total appearances (`GetStat(12,3,0,0)`) against `GetSkillRating()/3` - if appearances are the
  bigger number, it calls `DoTransferRumour()`.

`TContractOffer.UpdateInterestedClubs` (READ tier) rebuilds the 5-slot `interestedclubs` array
from scratch every time it runs. A candidate club qualifies if, in order:

1. it is not the player's current club (or loan-parent club, if on loan);
2. `club.strength <= status` - `status` is `GetPlayerValueStatus()`, described below;
3. its competition exists and has `duration >= 10`;
4. if `status < 50`, the club must be in the **same nation** as the player's current club;
5. if `status < 60`, the club's nation must be in the **same continent** as the player's;
6. if the player has set transfer preferences (continent/nation/league/club, via the "Desired
   Transfer" screen), the candidate must match all of them, most-specific last;
7. it is skipped if a "dead" offer already exists for it (an on-file `TContractOffer` for that
   club with `newbossrel == 0` - i.e. a negotiation that was previously cancelled).

Clubs are pre-sorted before scanning (`TClub.SortListBy(35, 0)`); the sort key's exact meaning
was not read. The first 5 qualifying clubs are kept.

`TContractOffer.DoTransferRumour` (VERIFIED) then walks the 5 `interestedclubs` slots; for each
populated slot there is a 1-in-3 chance (`Rand(3) = 1`) to stop scanning and use that club,
otherwise it keeps looking. If a club was landed on, it posts one of 11 templated headlines - 
`GetText("CNEWS_TRANSFERINTEREST" + Rand(10))`, and `Rand(10)` in BlitzMax is inclusive of both
ends, so there are keys `CNEWS_TRANSFERINTEREST0` through `…INTEREST10`.

### How a player's transfer "value" is judged

`TContractOffer.GetPlayerValueStatus()` (VERIFIED) computes the single number, capped at 90,
that both club-interest and club-affordability checks are built on:

```
rating = 0.5                                            if year = 1 and week <= 10
       = GetStat(18, 3, clubid, year-1)                  if week <= 10 (else)
       = GetStat(18, 3, 0, year)                          if week > 10   (career-wide, this year)
clubStrength = loanClub.strength   if on loan
             = myClub.strength     otherwise
status = min(90, (rating*5 + SkillRating() + Fame() + clubStrength) / 2)
```

`TContractOffer.CheckClubCanAffordPlayer(club)` (VERIFIED) then gates whether a specific club is
allowed to approach at all:

- if the player's current contract has **already expired**, any club can approach - return true
  unconditionally;
- otherwise, the approaching club must have `strength >= clamp(status, 10, 90) - 15` - clubs more
  than 15 strength points below the player's status simply cannot make an offer.

`TContractOffer.GetClubsInterestedInLoan()` (VERIFIED) is the loan-market equivalent: it looks
for clubs with `strength <= myClub.strength` **and** `strength <= status - 5`, in an active
competition, matching the same desired-transfer filters as above, with `CountFixturesRemaining()
> 4` (no point sending a player on loan to a club whose season is almost over). Capped at 5
clubs, from a list pre-sorted by `SortListBy(11, 0)`.

`TContractOffer.CheckPromoteFromBTeam()` (VERIFIED) is the other way a player changes club
without a transfer market at all: if the player is at a club with a B-team
(`myclub.bteamofid > 0`) and not already transfer-listed, and this season's rating at the club
is above 7.5 with appearances above 8 **and appearances is an exact multiple of 8**, the game
offers a promotion to the first team, resetting both relationship stats to 50 on acceptance.

`TContractOffer.GetInitialClub(nationId)` (VERIFIED) picks the club a new career starts at: it
sorts all clubs, then for clubs in the requested nation with an active competition
(`duration >= 10`) it gives each one a 1-in-6 chance (`Rand(6) > 1` skips, i.e. `Rand(6) = 1`
keeps) of being chosen outright; if none is picked that way, it falls back to the very first
eligible club in sort order.

## What it means in play

- **Moving up the football pyramid pays disproportionately.** Because both the signing fee and
  the bonus multiplier scale with the target club's strength tier, jumping to a 90+ club is not
  a 20% better deal than a sub-75 club - it's roughly a 20x better signing fee (10x from the
  tier times the squared strength) and 6x the bonuses (3.0 vs 0.5).
- **A lapsed contract is a double-edged sword.** It removes the 15-point strength gate on which
  clubs can approach, and it makes an outside offer pay a 25% wage premium and a 4x signing-fee
  premium - but the player's own club can respond by listing them (`transferlisted = 2`) within
  7 days of expiry regardless.
- **Veterans get short deals whether they like it or not.** The age-based length cap (3/2/1
  years past 30/32/33) means a 34-year-old career player literally cannot be offered a multi-year
  contract by this formula - every deal from that point on is a "prove it again next year" deal.
- **You will not see transfer gossip about yourself for your first ~12 weeks at a new club.**
  `UpdateInterestedClubs`/`DoTransferRumour` are both gated behind the 84-day
  (`lasttransferdate + 84`) grace period, and both only run while the transfer window is
  actually shut.
- **A good relationship with the boss gets you a contract offer, not just goodwill.** The
  anniversary/pre-expiry windows in `CheckTransferWindow` actively clear a stale pending offer
  and prompt a new one when `relationboss > 50`; a poor relationship (`< 30`) at the week-26
  checkpoint gets the player listed by the club, unprompted.
- **Negotiating too hard with an outside club can burn the relationship for good.** A rejected
  negotiation with `newbossrel < 40` doesn't just fail - it zeroes `newbossrel`, and a zeroed
  offer is explicitly excluded from being reconsidered for future interest
  (`UpdateInterestedClubs`'s "dead offer" check), so that club stops appearing as an option until
  something clears the stale offer.

## Implementation detail worth preserving

- **Rounding is a real rule, not a no-op.** `goalbonus = (goalbonus/100)*100` on `Int` fields is
  integer division - it truncates to the nearest 100 below, it does not round to the nearest
  100. The same applies to wage (nearest 100) and signing fee (nearest 1000). Any reimplementation
  that "simplifies" this away by keeping the un-rounded float will produce different offer
  numbers than the original.
- **Position 5's assist bonus has no flat `+50`.** Every other bonus in the position table adds a
  flat 50 on top of the strength-product term; position 5's assist bonus is the strength product
  alone. Confirmed directly in the disassembly (no `add`/`50` before the store) per the source
  file's own note - not an artifact of the decompile.
- **`CheckTransferWindow`'s week==1 and week==11 checks are unreachable.** The code nests
  `week = 1 Or week = 26` inside a guard that already requires `week > 10`, and `week = 11 Or
  week = 33` inside a guard requiring `week > 32`. Both `= 1` and `= 11` branches can never fire.
  Only week 26 (open) and week 33 (closed) ever actually trigger. This is READ tier, so it is
  possible the decompile has an operator reversed somewhere in that nest - but the shape appears
  twice with the same pattern, which argues against it being a one-off misread.
- **The marquee-transfer achievement thresholds check the player's overall value, not the actual
  fee.** `SignForNewClub` calls `TProfile.GetValue()` once before the club switch and compares
  *that* against $1m/$5m/$10m/$20m for achievements 40-43 - the `TContractOffer.signingfee` field
  that was actually negotiated is not part of that comparison.
- **A renewal at the current club never touches `relationteam`.** Only a genuine move to a
  different club resets `relationteam` to 50 and recomputes the carried-over reputation value;
  simply re-signing where the player already is leaves those fields untouched.
- **`GetPlayerValueStatus` is heavily logged.** It writes `>>> avgrating =`, `>>> skills =`,
  `>>> fame =` and `>>> clubstrength =` lines (plus the sound-lazy-load overhead in `GetOffer`
  running on every call including the "found an existing offer" early-return path) - useful if
  someone wants to watch these values live from the game's own log rather than instrumenting
  code.

## What we do not know yet

- **Who calls `CheckTransferWindow` and how often** was not traced in this pass (no caller graph
  walk was done). The internal date checks strongly imply a weekly-or-more-often tick, but
  whether it's driven once per in-game day or once per fixture wasn't confirmed. Answering it
  needs `scripts/build_dependency_graph.py` run against `CheckTransferWindow @ 0x00571e91`.
- **The `SortListBy` sort keys (11, 23/0x17, 35/0x23) used across this file are unread.** We know
  clubs get sorted before every scan that builds a shortlist, but not by what field or which
  direction. `TClub.SortListBy` itself (`0x00c59e40`) would answer this.
- **`FUN_0059f089` in `SignForNewClub`** (the helper that picks a `CNEWS_TRANSFER` headline
  variant) is confirmed to be `_brl_random_Rand`, but Ghidra's decompile shows it being called
  with more arguments than `Rand` takes - almost certainly a decompiler artifact from the calling
  convention, but this means the exact roll range for the transfer-headline variant (how many
  `CNEWS_TRANSFER<N>` keys exist) is inferred by analogy to `DoTransferRumour`'s
  `Rand(10)`, not confirmed directly.
- **`GetStat`'s numeric type codes are inferred from repeated usage, not from reading
  `TProfile.GetStat` (`0x00569329`) itself.** Type 12 is assumed to be "appearances" and type 18
  "average match rating" because both `CheckPromoteFromBTeam` and `SignForNewClub` use them that
  way consistently, but the stat-type table itself hasn't been read.
- **What sets `transferlisted = 3`** (loan-listed, per `UpdateTransferStatus`'s Case 3) was not
  found in this pass - the request-transfer button was read, but no "request loan" button body
  was.
- **`CheckTransferWindow`, `SignForNewClub` and `UpdateInterestedClubs` are READ, not
  VERIFIED.** Every number and branch direction pulled from them in this document is Ghidra's
  reading of the disassembly, not a byte-exact match. Running these three through the reverify
  harness would upgrade this whole section from MEDIUM to HIGH confidence.
