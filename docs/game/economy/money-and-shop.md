# Money, wages and spending

> **Source:** `TProfile.UpdateFinances` @ 0x0056b7e3 (VERIFIED) · `TProfile.UpdateBank` @ 0x0056b669 (VERIFIED) · `TProfile.GetSponsorshipAmount` @ 0x0056ae46 (VERIFIED) · `TProfile.OfferSponsorship` @ 0x0056c158 (VERIFIED) · `TProfile.CheckSponsorExpiry` @ 0x0056bfe2 (VERIFIED) · `TProfile.GetPropertyCosts` @ 0x0056aec2 (VERIFIED) · `TProfile.GetVehicleCosts` @ 0x0056af98 (VERIFIED) · `TProfile.GetRentCosts` @ 0x0056ae99 (VERIFIED) · `TProfile.GetLifestyle` @ 0x0056b5da (VERIFIED) · `TProfile.SellItemByName` @ 0x0056b1de (VERIFIED) · `TProfile.BuyBoots` @ 0x0056c367 (VERIFIED) · `TProfile.WearBoots` @ 0x0056a310 (VERIFIED) · `TProfile.GetStableSize` @ 0x0056b974 (VERIFIED) · `TScreen_Shop.ButtonBuy` @ 0x005424de (VERIFIED) · `TScreen_BootShop.ButtonBuy` @ 0x00543cdc (VERIFIED) · `TScreen_BootShop.SetUpScreen` @ 0x00543978 (VERIFIED) · `TScreen_MatchPrep.SetUpScreen` @ 0x0055d904 (VERIFIED) · `TPlayer.CreatePlayerSimple` @ 0x004ed58d (VERIFIED) · `GetBootBonus` @ 0x00507ddd (VERIFIED) · `SponsorAmount` @ 0x00507d1a (VERIFIED) · `TierA` @ 0x00507b79 (VERIFIED) · `TierB` @ 0x00507c04 (VERIFIED) · `TierC` @ 0x00507c8f (VERIFIED)
> **Confidence:** HIGH
> **Last checked:** 2026-08-15

Every function cited above is a byte-exact recovered body (`src/recovered/` or
`src/recovered_module/`), so the numbers below are read directly out of the game's own code,
not reverse-engineered from observed behaviour.

## The weekly wage packet

Once a career is running, `TProfile.UpdateFinances` settles the player's finances once per
game-week. It is one function that both pays you and bills you:

**Income:**
- **Wage** - `contractwage`. If the contract has expired (`date.sdate > contractexpires`)
  the wage is **halved** - the club keeps paying you, just less, until you re-sign.
- **Sponsorship** - the sum of up to 9 active sponsor deals, each paid out as `deal amount /
  52` per week (see below).
- **Bonuses** - `thisweeksgoalbonus + thisweeksassistbonus + thisweekscleanbonus`, accumulated
  during the week's matches from the contract's per-goal/per-assist/clean-sheet bonus terms,
  then zeroed for the next week.
- **Shirt sales** - see the box below; a noisy number driven by fan relationship and fame.

**Outgoings**, all billed every week regardless of whether anything changed:
- **Rent** - a flat **$250/week**, but only if you own **no** property at all.
- **Property upkeep** - 0.5% of the total tier-value of every property you own, every week.
- **Vehicle upkeep** - 0.5% of the total tier-value of every vehicle you own, every week.

The net total (`wage + sponsor + bonus + shirt − rent − property − vehicle`) is handed to
`UpdateBank`, which is also the single choke point for every deposit and withdrawal in the
game (shop purchases, sponsor offers, betting, transfers) - it refuses the transaction and
pops "CMESSAGE_NOTENOUGHCASH" if a withdrawal would take the bank negative, and fires three
achievements at $1m / $10m / $25m in the bank.

**Shirt sales, in detail.** Two functions cooperate:
1. `UpdateFinances` rolls a raw shirt-sales *count*: `relationfans * GetFame() / 50`, plus
   `Rand(relationfans / 4, 1)` random noise, **zeroed outright if `relationfans < 20`** (an
   unpopular player sells no shirts, full stop). Selling over 100 in a week fires
   achievement 84.
2. `GetLastWeeksShirtSales` converts that count into cash: it takes the club's `strength`
   stat, multiplies by 0.7, and clamps the result to **20-70**. That clamped number, as a
   percent, is what each shirt actually nets - `Int(pct * 0.01 * shirtcount)`. A big club
   sells the same shirt count for up to 3.5× the cash of a weak one (70% vs 20% cut).

## What things cost

Purchases (property, vehicles, luxury items, sponsor-priced boots) are drawn from four
independent 1-10 price tables, each a plain `Select`/`Case` lookup with no formula behind
it - just ten hand-picked numbers per category:

| Tier | Property (`TierA`) | Vehicle (`TierB`) | Item (`TierC`) | Example (property / vehicle / item) |
|---:|---:|---:|---:|---|
| 1 | $100,000 | $5,000 | $250 | Apartment / Bicycle / Phone |
| 2 | $250,000 | $10,000 | $500 | House / Scooter / Games Console |
| 3 | $500,000 | $25,000 | $750 | Town House / Small Car / Music Player |
| 4 | $750,000 | $50,000 | $1,000 | Cottage / Motorbike / Tablet |
| 5 | $1,000,000 | $100,000 | $2,500 | Stable / SUV / TV |
| 6 | $2,500,000 | $250,000 | $5,000 | Holiday Villa / Sailing Boat / Designer Suit |
| 7 | $5,000,000 | $500,000 | $7,500 | Ski Chalet / Sports Car / Silver Chain |
| 8 | $10,000,000 | $1,000,000 | $10,000 | Mansion / Helicopter / Gold Ring |
| 9 | $50,000,000 | $5,000,000 | $25,000 | Castle / Yacht / Earrings |
| 10 | $100,000,000 | $10,000,000 | $50,000 | Private Island / Private Jet / Watch |

The tier names come from the localisation keys (`property_*`, `vehicle_*`, `item_*` in
`GameMedia/Languages/Languages.csv`), read by the recovered `PropertyName`/`VehicleName`/
`ItemName` functions. Property and vehicles can be bought in **multiple copies of the same
tier** - the game does not stop you owning three TVs - but the "own everything" achievements
(60/61/62) only need one of each of the ten tiers, and so does the Lifestyle score below.

Boots use a **separate, unrelated** price table, `SponsorAmount` (the project's own name for
the function - not a recovered original name, and it has nothing to do with sponsorship deals
despite the name overlap; it is purely the boot shop's per-design price list):

| Boot design | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | 10 |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| Price | $500 | $1,000 | $1,500 | $2,000 | $2,500 | $3,000 | $4,000 | $6,000 | $8,000 | $10,000 |

Two more purchases are flat prices, both bought from the match-prep screen, not the shop:
**shin pads cost a flat $500**, and an **NRG energy drink costs a flat $250**.

## Buying, selling, and what buying actually gets you

The shop screen (`TScreen_Shop.ButtonBuy`) requires **10.0 energy** to enter a purchase at
all ("CMESSAGE_NOSHOPPINGTIRED" if you're too tired to shop), then checks the bank against
the tier price, confirms with a dialog, and increments the relevant `items[]`/`vehicles[]`/
`property[]` slot by one.

Selling (`TProfile.SellItemByName`) always pays back **exactly 50% of the tier price** - 
`TierA/B/C(tier) * 0.5` - for property, vehicles or items alike, after a confirmation dialog.

**Property, vehicles and most items are cosmetic status symbols with one real feed-back
loop.** Owning any of the 30 tier-slots (10 property + 10 vehicle + 10 item) only feeds a
single derived number, `GetLifestyle()`:

```
Lifestyle = (distinct tiers owned across all three categories / 30) * 100
```

Lifestyle isn't just a stat screen - it directly inflates future sponsorship offers (see
below), and hitting 100% fires achievement 63.

**But three purchases are not cosmetic - they unlock real functionality or real match
stats:**

- **Item 1 (Phone).** Not owning one triggers a recurring negative incident
  (`RandomIncident`: "CMESSAGE_NEEDAPHONE", a relationship penalty with team or friends).
  Owning one also gates a notification sound when a contract offer is accepted
  (`TScreen_ContractOffer.SetUpScreen`).
- **Items 2-4 (Games Console, Music Player, Tablet).** Each unlocks one travel-time activity
  on the world map screen (`TScreen_WorldMap.UpdateTravelTime`) - you can't play games,
  listen to music, or watch a film while travelling to an away match without owning the
  matching gadget.
- **Property 5 (Stable).** `GetStableSize` returns `property[4] * 2` - every Stable you own
  doubles your horse-stable capacity for the horse-racing minigame (see the stable gap doc).

**Boots and shin pads are the real gear-with-stats system**, and they behave completely
differently from the cosmetic shop: they are *consumable*, not permanent.

- `BuyBoots` wipes all ten boot slots to 0 and sets the newly bought design's durability to
  **5** - you can only ever own one pair of boots at a time; buying a new pair discards
  whatever you had.
- `WearBoots` - called once per match played - knocks 1 off the current boots' durability
  and 1 off `shinpads`' durability (shin pads share the same 5-use counter, no per-design
  slot). At 0, the gear is worn out.
- `TPlayer.CreatePlayerSimple`, which builds the player-controlled player's in-match stats
  from the profile, adds a **real stat bonus** from whichever boots are currently owned, via
  the `GetBootBonus(tier, stat)` lookup table (0-2 points, added at ×10 before the 0.2 scaling
  every raw stat goes through):

| Boot tier | Dribbling boost | Passing boost | Shooting boost |
|---:|---:|---:|---:|
| 1 | +1 | +0 | +0 |
| 2 | +0 | +1 | +0 |
| 3 | +0 | +0 | +1 |
| 4 | +1 | +1 | +0 |
| 5 | +1 | +0 | +1 |
| 6 | +0 | +1 | +1 |
| 7 | +1 | +1 | +1 |
| 8 | +2 | +1 | +1 |
| 9 | +2 | +2 | +1 |
| 10 | +2 | +2 | +2 |

  Shin pads add a flat **+10 tackling** (pre-scaling) whenever `shinpads > 0` - no tiers,
  it's on or off. An **NRG drink** adds pace instead: **+10 if `NRG > 0`, +20 total if
  `NRG > 50`** (each drink adds 50 to the `NRG` stock, so one drink alone already crosses the
  first threshold). Unlike boots and shin pads, NRG is a single-match consumable - the profile's
  health-tick resets `NRG` to 0 unconditionally.

## Sponsorship: a second income stream that also waives prices

Sponsorship deals are a parallel system to the shop, and the game only ever tracks **9**
active deals at once (`sponsor_amount`/`sponsor_expires`, indices 0-8), even though the
sponsor-name table (`SponsorName`) lists 10 categories - see the quirk below. Each of the 9
slots corresponds to a sponsor type 1-9:

| # | Sponsor type | Effect on the shop |
|---:|---|---|
| 1 | Boots | Boots become **free** (cost 0) while active |
| 2 | Sports Drink | NRG drinks become **free** |
| 3 | Sports Clothing | Shin pads become **free** |
| 4 | Casual Clothing | - |
| 5 | Food | - |
| 6 | Cosmetics | - |
| 7 | Watch | - |
| 8 | Electronics | - |
| 9 | Jewelry | - |
| 10 | Car | never offered - no array slot exists for it |

Offers come from `RandomIncident` (case 3): it scans the 9 slots for the first empty one
where `GetFame() > slot_index * 10 + 15`, and offers exactly that one - sponsors are
approached in a fixed order, cheapest fame requirement first, never randomly picked.

`OfferSponsorship`'s cash formula for accepting deal `a0` (1-9):

```
cash = a0 * 15000 + relationsponsors * 2500 + Lifestyle * 1500 + Fame * 1500
```

So a flashier Lifestyle score and a better sponsor relationship both directly inflate the
deal size - buying shop items pays for itself a little via bigger future sponsor cheques. A
deal lasts **364 days** (not 365 - see the quirk below), and paid weekly as `amount / 52`
inside `UpdateSponsorshipAmount`/`UpdateFinances`. Accepting your first ever sponsor jumps
`relationsponsors` straight to 50 if it was still 0.

`CheckSponsorExpiry` runs the housekeeping: any deal whose date has passed is cancelled and
announced ("CMESSAGE_SPONSOREXPIRED"). Separately, if `relationsponsors < 20`, **one random
active deal is cancelled outright** ("CMESSAGE_SPONSORCANCEL") - neglecting the sponsor
relationship can cost you a deal even before its natural expiry.

## What it means in play

- **Being unpopular with fans is a hard income floor, not a soft one.** Below 20 fan
  relationship, shirt income isn't reduced, it's exactly zero, every week, no matter how
  famous or skilled the player is otherwise.
- **A weak, low-strength club sells your shirts for a third of the cash** a top club would,
  for the identical shirt count - the 20-70% band on `GetLastWeeksShirtSales` means club
  quality is worth more to your shirt income than anything you personally do.
- **An expired contract quietly halves your wage** every week until renewed - there's no
  warning dialog for this beyond the wage number itself dropping.
- **Property and vehicles are a standing tax, not a one-off purchase.** Every property or
  vehicle you own costs 0.5% of its price *every single week* forever; a $100,000,000
  private island costs $500,000/week just to keep. Luxury items, by contrast, are one-off - 
  no recurring item-upkeep function exists at all, so once bought (or received free from a
  sponsor) an item never costs you anything again.
- **Buying property specifically to stop paying rent is a real, intentional strategy** - the
  $250/week rent switches off entirely the moment you own a single property of any tier, even
  the cheapest Apartment.
- **The shop is mostly vanity, but not entirely** - a player chasing achievements or lifestyle
  score can ignore Phone/Games Console/Music Player/Tablet/Stable, but a player who wants the
  travel-time minigames, the horse stable, or to dodge a random "you need a phone"
  relationship penalty needs those five specific purchases and no others.
- **Boots and shin pads reward staying current, not stockpiling.** Because `BuyBoots` erases
  every other pair the moment you buy a new one, there is no way to "bank" boots for later - 
  only the single most recently bought design ever matters, and it wears out after 5
  matches regardless of tier.
- **A Boots or Sports Clothing sponsor is worth more to a boot/shin-pad habit than the cash
  value suggests** - it doesn't just save money, it removes the confirmation dialog gate
  entirely (`Local confirmed:Int = (cost = 0)` skips the "are you sure" prompt whenever a
  sponsor makes the item free).

## What we do not know yet

- **Where `WearBoots` is actually called from.** No recovered body in `src/recovered/` calls
  it yet, so "once per match" is inferred from the function's shape and its 5-use durability
  matching the boot-shop progress bars, not confirmed from a caller. The likely candidates
  are `TProfile.Play` or `TProfile.PlayNextFixture` (both listed in `vtable_map.tsv`, neither
  yet reconstructed).
- **Where `UpdateFinances` is called from**, and therefore exactly what "once per week" means
  in game time (per fixture played? per real-world date rollover?). Not yet traced to a
  caller.
- **What the general shop's per-item weekly upkeep would be if it existed.** We confirmed
  there is no such function for `items[]` by searching the corpus, but that is an absence
  argument, not a positive read of a "no-op" body - worth re-checking once `TProfile`'s few
  remaining unrecovered methods are done.
- **The exact meaning of `booze`/`drugs`/`gambling` stat interactions with match-prep
  purchases** (`TScreen_MatchPrep.ButtonBooze`, `ButtonDrugs`) - read but out of this
  document's scope; they are per-match consumables like NRG, not shop goods, and belong in a
  future `career/relationships.md` or a dedicated vices document.
- **Whether sponsor type 10 ("Car") is unreachable in every build**, or whether some other,
  not-yet-found function offers it through a different code path. All evidence so far
  (`RandomIncident`'s loop, the 9-element `sponsor_amount` array) says it is dead content, but
  no exhaustive search of all `OfferSponsorship` call sites has been done.

## Quirks worth preserving exactly

- **Only 9 of the 10 sponsor categories are reachable.** `sponsor_amount`/`sponsor_expires`
  are both fixed at 9 elements and every offering path indexes them 0-8, but `SponsorName`
  happily formats a 10th category ("Car") that can never be assigned. A "clean" reimplementation
  that bumps the array to 10 slots "to match the name table" would silently make Car sponsors
  offerable - a change in behaviour, not a bug fix.
- **The sponsorship term is 364 days, not 365** (`Self.date.sdate + 364` in
  `OfferSponsorship`). Reproduce the exact number; a "fixed" 365 changes exactly when deals
  lapse relative to `CheckSponsorExpiry`'s weekly sweep.
- **`BuyBoots` always zeroes all ten slots before setting the new one**, even though
  `TScreen_BootShop.ButtonBuy` *also* zeroes them all itself immediately beforehand. The
  zeroing is genuinely redundant in the recovered code - both the caller and the callee do
  it - and should be reproduced exactly as duplicated, not "cleaned up" to a single site.
- **Two different, unrelated systems are both named "sponsor" in the recovered code.** The
  module `Function SponsorAmount(i)` is the *boot shop's price table* (constants 500..10000)
  and has nothing to do with `TProfile.sponsor_amount` (the array of active sponsorship deal
  values) or `TProfile.GetSponsorshipAmount()` (this week's sponsorship income). The name
  collision is the reconstruction project's own naming choice (marked "NAME IS OURS" in the
  source), not evidence of a relationship in the original game - don't let the similar names
  imply a connection that isn't there.
- **`GetLastWeeksShirtSales` reads `myclub.strength * 0.7` clamped to [20, 70] and calls the
  result a percentage** - it is applied as `pct * 0.01`, i.e. divided by 100 a second time
  after the 0.7 multiply already shrank it. This two-step scaling (× 0.7, then clamp, then ×
  0.01) is exactly how the original computes it; collapsing it to a single "clamp strength to
  [28.6, 100] and multiply by 0.007" produces the same numeric range but is not how the code
  is shaped, and float rounding at the `Int()` truncation points would differ.
