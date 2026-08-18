# Horse racing

> **Source:** `THorse.Update` @ 0x0058abcc (VERIFIED) · `TScreen_Stable.DoRace` @ 0x00588a89 (VERIFIED) · `TScreen_Stable.Update` @ 0x00588c99 (READ) · `TScreen_Stable.FinishRace` @ 0x0058946f (VERIFIED) · `THorse.SelectRunners` @ 0x0058b226 (VERIFIED) · `THorse.SetRaceOdds` @ 0x0058b40d (VERIFIED) · `THorse.ResetRands` @ 0x0058b4ea (VERIFIED) · `THorse.Compare` @ 0x0058b55b (VERIFIED) · `THorse.PostRaceUpdate` @ 0x0058b0dc (VERIFIED) · `THorse.GetValue` @ 0x0058aa59 (VERIFIED) · `THorse.DoHealthUpdate` @ 0x0058b9da (VERIFIED) · `THorse.Create` @ 0x0058a36b (VERIFIED) · `TScreen_Stable.SetUpNextRace` @ 0x00588574 (VERIFIED) · `TScreen_Stable.ButtonRaceHorse` @ 0x00589eb4 (VERIFIED) · `TScreen_Stable.ButtonHorse` @ 0x005887fe (VERIFIED) · `TScreen_Stable.SetStake` @ 0x00588687 (VERIFIED) · `TScreen_Stable.LoadData` @ 0x00587c3a (VERIFIED) · `TScreen_Stable.SetUpHorsesForSale` @ 0x00588370 (VERIFIED) · `TScreen_Stable.ButtonBuyHorse` @ 0x0058993b (VERIFIED) · `TScreen_Stable.ButtonSellHorse` @ 0x00589c6e (VERIFIED) · `TScreen_Stable.ButtonTreatHorse` @ 0x00589d61 (VERIFIED) · `TProfile.Bet` @ 0x0056b780 (VERIFIED) · `TProfile.GetStableSize` @ 0x0056b974 (VERIFIED) · `TProfile.UpdateHealth` @ 0x0056b98b (VERIFIED)
> **Confidence:** MEDIUM
> **Last checked:** 2026-08-15

Horse racing is the game's side-gambling minigame: buy a horse, keep it fit, enter it in
races, and bet cash on every race whether you own a runner or not. Almost every rule below
comes from byte-exact bodies. The one genuinely load-bearing exception is the function that
actually notices a horse has crossed the finish line and ends the race
(`TScreen_Stable.Update`) - it exists only as an unverified Ghidra decompile, so the
finish-line mechanics are marked accordingly below and the confidence line reflects that.

## What happens, in plain English

**The horse pool.** The game ships a fixed list of 250 named horses
(`GameMedia/Data/Horse.ini`, one name per line - "Simon Says", "Nancy Boy", "Bunch Of
Fives" twice, and so on). The very first time the stable screen loads with no save data,
`TScreen_Stable.LoadData` walks that file and calls `THorse.Create` once per line, rolling
fresh stats for every horse. From then on, a horse's stats, ownership and past form are
whatever was written into the save file - the 250-name list is only ever consulted at
world creation.

**Who can be bought.** Each newly-created horse gets one shot at being "for sale"
(`TScreen_Stable.SetUpHorsesForSale`, a 1-in-5 roll) or otherwise sitting in an unowned
"reserve" pool that never appears in the shop. **This only happens once**, at the same
moment the 250 horses are generated - nothing in the recovered code re-rolls it later, so
whichever horses missed the 20% roll at the start of the career are for-sale forever, and
whichever horses hit it are the only ones you will ever be offered.

**Races.** Every "meet" is up to 6 races, tracked by a counter that refuses to go past 6
(`TScreen_Stable.SetUpNextRace`). Setting up a race draws 6 runners at random from the
reserve pool (horses nobody owns and nobody is selling) that haven't already run today,
using a race-day reshuffle of a random tie-breaker field (`randno`) that every horse in the
game gets re-rolled on every single time a race is set up. You can swap your own horse into
the lineup in place of the runner drawn last (`TScreen_Stable.ButtonRaceHorse`), provided no
other runner is already yours and your horse is healthy (health ≥ 70) and not exhausted
(energy ≥ 10).

**Betting.** Before the race you can bet on any of the 6 runners at a stake between 50 and
5,000 (`TScreen_Stable.SetStake`) against odds assigned by `THorse.SetRaceOdds`. The odds
have **nothing to do with the horses' ability** - see "What it means in play" below.

**The race itself.** `TScreen_Stable.DoRace` starts all 6 horses at slightly different
x-positions (faster starting horses are placed slightly further back, so nobody gets a free
head start) and from then on `THorse.Update` runs every horse forward one simulation step at
a time: a small chance of losing energy, a small chance of nudging speed up or down, and a
speed ceiling that depends on how close to the finish line the horse currently is. A horse's
final placing (1st through 6th) is decided purely by which x-position it has reached - no
dice roll is thrown at the finish, the race is just watched until someone crosses the line.

**After the race.** `TScreen_Stable.FinishRace` pays out: prize money to every horse by
finishing position, a real cash payout to you if you bet on the winner, and a form/fitness
update to every horse via `THorse.PostRaceUpdate`. A separate daily-ish tick,
`THorse.DoHealthUpdate` (called from `TProfile.UpdateHealth`, the same function that resets
your own player's booze/gambling/injury counters - so this most likely runs on the game's
regular match-to-match cadence, not a horse-specific timer), drifts every horse's energy and
health, and can make an owned horse ill if you neglect it.

## The numbers

### Race physics - `THorse.Update`, one call per simulation step, per horse

| Step | Rule |
|---|---|
| Energy decay | `If Rand(100) < strength Then energy -= 0.1`. `Rand(100)` returns 1-100, so the chance is `(strength-1)/100` per step. A strength-100 horse loses 0.1 energy on **99%** of steps; a strength-30 horse loses it on 29%. |
| Energy floor | `If energy < 1.0 Then energy = 1.0` (no explicit ceiling is applied here - energy only ever falls during a race). |
| Speed nudge, energised (`energy > 1.0`) | `Select Rand(50)`: **1/50 (2%)** chance of `xvel += strength/500`, **1/50 (2%)** chance of `xvel -= strength/500`, **96%** no change. |
| Speed nudge, exhausted (`energy <= 1.0`) | `Select Rand(100)`: **1/100 (1%)** chance of `xvel -= strength/200`, **99%** no change - an exhausted horse can only ever get slower, never faster, for the rest of the race. |
| Speed ceiling by track position | see table below |
| Move | `x = x + xvel` |

The speed ceiling narrows the pack early in the race and lets it fan out near the line - 
this is what manufactures a photo finish instead of the field just spreading out linearly
the whole way round:

| Segment (distance to finish line, x = 11552.0*) | `ClampFloat(xvel, min, max)` |
|---|---|
| 0-73 units from the line (`x > 11479`) | 9.0 - 15.0 |
| 73-1993 units (`x > 9559`) | 9.0 - 14.5 |
| 1,993-3,913 units (`x > 7639`) | 9.5 - 14.0 |
| 3,913-5,833 units (`x > 5719`) | 10.0 - 13.5 |
| 5,833-7,753 units (`x > 3799`) | 10.5 - 13.0 |
| more than 7,753 units out (everything else) | 11.0 - 12.5 |

*The finish line's x-value (11552.0) is read from the unverified `TScreen_Stable.Update`
decompile (READ, not byte-matched) - treat it as trustworthy but not proven. The seven
segment thresholds above it (11479 down to −41) ARE byte-exact, from `THorse.Update`, and
sit consistently just inside that finish line, which cross-checks the reading.

**Start position** (`TScreen_Stable.DoRace`, VERIFIED): every horse's starting speed is
`xvel = strength * energy * 0.0015`, and its starting x is `5500.0 - xvel * 30.0` - so a
horse that would start faster is placed further back at the gate, a built-in stagger rather
than a flying start advantage.

### Finish-line detection and race end - `TScreen_Stable.Update` (READ only)

Every step, the 6 runners are re-sorted by current x (leader first) and walked in that
order. A horse is assigned its finishing position (1st, 2nd, 3rd…) the moment its x passes
11552.0 **and** it doesn't have a position yet - so positions are handed out in strict
x-order, first horse to cross gets 1st, and so on. The race only actually ends
(`TScreen_Stable.FinishRace` is called) once **every** runner has crossed the line - the
camera keeps rolling to show the also-rans finish even after 1st place is decided. The
frame the winner is first detected, the game grabs a "photo finish" screenshot, plays a
sound, and shows a win/lose message for about **2.5 seconds** (2,500 ms, timed off the
game's millisecond clock) before the display resumes.

### Odds - `THorse.SetRaceOdds`

```
price = 2
For each of the 6 runners, in the SAME randno order SelectRunners just picked them in:
    horse.betprice = price
    price += Rand(1, 3)      ' 1, 2 or 3, uniformly
```

So odds run 2/1, then +1-3, then +1-3 again, etc. - a plausible-looking ascending odds
ladder. **The order the runners are stepped through is `randno`, a value re-rolled from
scratch for every horse before every race** (`THorse.ResetRands`, `Rand(1, 1000)`) with no
connection to any racing stat. The favourite (2/1) is exactly as likely to be assigned to
the weakest horse in the field as the strongest.

### `THorse.GetValue` - a horse's price, both to buy and to sell

```
v = 250000
v += Int(strength) * 10000
For each of the 5 slots in the horse's form history:
    1 -> v += 100000   4 -> v += 40000
    2 -> v +=  80000   5 -> v += 20000
    3 -> v +=  60000   6 -> v += 10000
    (anything else -> no bonus)
v += prize                    ' lifetime prize money won
v = Clamp(v, 250000, 3000000)
```

This is the exact price `TScreen_Stable.ButtonBuyHorse` charges you and
`TScreen_Stable.ButtonSellHorse` pays you - there is no markup or spread, buying and
reselling immediately loses nothing but the horse's chance to win something in between.

### `THorse.DoHealthUpdate` - the periodic drift (all values Clamp'd to energy/health
[1,100], strength [30,100] afterwards)

| Ownership | Energy | Health | Other |
|---|---|---|---|
| For sale (`owned = -1`) | `+ Rnd(-5.0, 5.0)` | `+ Rnd(-0.5, 0.5)` | - |
| Owned by you (`owned = 1`) | `+ Rand(50, 75)` | `- Rand(1, 5)` | If health drops below 70: strength `-= 2.5`; if health was above 50 the moment before, shows "your horse is becoming ill" |
| Reserve pool (`owned = 0`) | `+ Rand(50, 80)` | `+ 0.5` | - |

Owning a horse is the only state where health can *fall* under this tick - an owned horse
you never race still needs attention, or its strength erodes 2.5 at a time every time
health dips under 70.

### `THorse.PostRaceUpdate` - after every race, for every runner

Form history shifts left and the new finishing position is appended (`form[0..3] =
form[1..4]`, `form[4] = <finishing position>`). If you own the horse: `strength += Rnd(0.5,
2.5)` regardless of result, and if the horse finished the race with energy under 20.0 it
loses `Rnd(25.0, 50.0)` health and shows an "exhausted" message.

### Race payouts - `TScreen_Stable.FinishRace`

| Finishing position | Prize added to horse | If you bet on this horse and it won | If you own this horse |
|---|---|---|---|
| 1st | +50,000 | stake × betprice, credited to your bank | +50,000 cash, achievement 83 |
| 2nd | +25,000 | - | +25,000 cash |
| 3rd | +10,000 | - | +10,000 cash |
| 4th-6th | +0 | - | +0 |

### Economy odds and ends

| Value | Formula / source |
|---|---|
| Stable capacity | `TProfile.GetStableSize`: `property[4] * 2` - property count directly buys stable slots |
| Buy / sell price | `THorse.GetValue()`, both directions, no spread |
| Treat/heal cost | `TScreen_Stable.ButtonTreatHorse`: `Int((100.0 - health) * 1000.0)`; blocked if health already ≥ 99.5, restores health to exactly 100.0 |
| Stake sizes | 50 / 100 / 250 / 500 / 1,000 / 2,500 / 5,000 (`TScreen_Stable.SetStake`) |
| Bet placement | `TProfile.Bet`: refused outright if `bank < stake`; otherwise `bank -= stake` and `gambling += 2` (capped at 100) |
| Fresh horse stats | `TScreen_Stable.LoadData`: energy `Rand(80,100)`, health `Rand(80,100)`, strength `Rand(40,100)`, 5 form slots each `Rand(1,6)`, starting prize = sum of 50,000/25,000/10,000 for any form slot that rolled 1/2/3 |
| For-sale odds | `TScreen_Stable.SetUpHorsesForSale`: `Rand(1,5) = 1` → for sale, else reserve pool. One-time only (see above). |
| Race eligibility (AI runners) | `THorse.SelectRunners`: `owned = 0` (reserve pool only) and `lastran <> today` |

## What it means in play

**The betting odds are decorative.** Odds are handed out in an order that is re-randomised
before every single race and has no connection to strength, health, form, or the value
figure the game itself shows you in the stable screens. A player who has been tracking a
horse's `GetStringForm()` history or its displayed value has genuinely useful information - 
and the game's own odds board does not use any of it. Betting on the highest-value horse
regardless of its posted odds is a real, quietly profitable strategy, and it works because
of a design accident rather than a deliberate long-shot mechanic.

**Race outcomes are not decorative - ability matters, but noisily.** Unlike the flat
scoring table documented in `match/simulated-results.md`, a horse's `strength` stat really
does drive its top speed (bigger `strength/500` upward nudges, smaller
`strength/200` penalty when exhausted) and its starting energy affects how long it stays
above the "energised" threshold before losing its chance at ever speeding up again. But the
per-step nudges are small and infrequent (2% chance either way, 1% chance once exhausted),
so a talented horse can absolutely still lose to a random walk that didn't go its way - 
especially since the track's speed ceiling deliberately keeps the whole field within about
a 1.5-unit band for most of the race and only opens up to a 6-unit band in the final
stretch, which is exactly where a small stat edge has the most room to actually show up as
a winning margin.

**The reserve pool is a closed system.** Because `SetUpHorsesForSale` only runs once, no
new horses ever enter the shop over the course of a career - the initial 1-in-5 sale roll
at world creation is the entire supply you will ever see, forever. If you buy every horse
that was ever offered for sale, the shop stays permanently empty of new stock (barring
anything a later, unread function might do - see below).

**Owning a horse is a maintenance commitment, not a passive investment.** An owned horse's
health only trends downward under the periodic tick (`Rand(1,5)` loss with no matching
gain, versus the reserve pool's flat `+0.5`), and once health drops under 70 its strength
starts eroding too. A horse bought and never visited will get slower and eventually sick;
the `ButtonTreatHorse` cost (`(100 - health) * 1000`) is the escape hatch, and it scales
linearly, so waiting to treat a badly neglected horse literally costs more, not less.

## What we do not know yet

- **`TScreen_Stable.Update` @ 0x00588c99 is not byte-matched.** Everything about *how the
  finish line is detected and how the race actually ends* - the 11552.0 finish x, the
  x-descending sort that hands out finishing positions, the photo-finish freeze, the 2.5
  second pause - comes from an unverified Ghidra decompile, not a proven body. It reads
  cleanly and cross-checks against the verified segment thresholds in `THorse.Update`, but
  it has not been reconstructed and byte-matched into `src/nss5`. This is the single
  biggest gap in this document; verifying it would upgrade nearly every claim in the "Race
  physics" and "Finish-line detection" sections from READ to VERIFIED.
- **`TScreen_Stable.Draw` @ 0x005890c9** is also unread (a near-miss sits in
  `src/recovered_unverified/TScreen_Stable.Draw.bmx`, not yet proven). It almost certainly
  only concerns rendering - the jockey sprites, track background, camera scroll - and is
  unlikely to change any of the numbers above, but that is an assumption, not a finding.
  A rebalance-minded reader who wants the actual on-screen visual pacing (camera speed,
  track distance in pixels, animation frame rate) needs this function.
  `TScreen_Stable.Update`'s decompile does show a camera-follow float
  (`g_screen_stable_float02`) tracking the leading horse's x, and a channel volume fade tied
  to the same state - neither is included above because neither changes race outcomes.
- **`THorse.GetStringracenum`'s "Win"/"Place" text makes no sense against the `racenum`
  field as used elsewhere.** `THorse.SelectRunners` numbers the 6 runners 1 through 6 in
  `racenum`, but `GetStringracenum` only returns text for `racenum = 0` ("Win") or
  `racenum = 1` ("Place"), falling through to an empty string for every other value - 
  meaning in practice only the very first-selected runner could ever show "Place", and no
  horse can ever show "Win" through this specific method. Either this method is dead code,
  or `racenum` is deliberately repurposed to hold a bet-type flag (0=win bet, 1=place bet)
  in some caller we have not identified, overwriting the runner-slot meaning temporarily.
  We could not find that caller. **Do not "fix" this if reimplementing** - reproduce the
  mismatch exactly; it is either intentionally unreachable or the game rebinds the field's
  meaning somewhere we have not found yet.
- **`DoHealthUpdate`'s exact cadence is inferred, not proven.** It is only ever called from
  `TProfile.UpdateHealth`, which also resets the player's own weekly/match-cycle counters
  (booze, gambling, injury, drugs, "matchskipped" energy). That strongly suggests the horse
  tick runs on the same once-per-match cadence as the rest of the career simulation, but we
  did not trace `UpdateHealth`'s own caller to confirm the cadence itself.
- **The save-file row format for a horse** (the 9-field comma-separated line
  `TScreen_Stable.LoadData` parses back with `THorse.Create`) is not documented here on
  purpose - the encrypted save format is a solved problem elsewhere in this project and
  deliberately low priority (see `docs/game/README.md`).

## Preserve exactly when reimplementing

- **`Rand(100) < strength` uses BlitzMax's inclusive 1-100 range**, so the decay chance is
  `(strength-1)/100`, not `strength/100`. At the strength cap of 100 that is 99%, not 100%
  - a max-strength horse can, rarely, go an entire step without losing energy. Writing the
  probability as a clean `strength/100.0` roll changes behaviour at every strength value.
- **The exhausted-horse speed rule has no upward case.** Energised horses roll a 2-way
  Select (up 2%, down 2%); exhausted horses roll a 1-way Select (down 1% only) - collapsing
  both into one symmetric "maybe adjust speed" roll silently gives exhausted horses a
  chance to speed up that the original never grants them.
- **The odds and race-order are driven by the same `randno` field, re-rolled game-wide on
  every single race setup**, not per-runner and not once per horse's lifetime. Re-rolling
  only the 6 selected runners' `randno` instead of the whole 250-horse pool has no visible
  effect on the odds (only the runners' values are ever read that race) but does change the
  reserve pool's tie-break order for whichever race gets set up next, and the original
  clearly re-rolls unconditionally.
- **`SetUpHorsesForSale`'s one-time nature is easy to "fix" by accident.** It is written as
  an ordinary function with no guard against being called twice - nothing stops a future
  caller from re-rolling the for-sale pool. But in the recovered call graph it has exactly
  one caller (`LoadData`'s fresh-game branch), so as shipped it only ever runs once per
  career. Adding a periodic call is a legitimate rebalance idea, not a bug fix - the
  original genuinely never refreshes stock.
- **Buying and selling both use `GetValue()` with zero spread or fee.** This is unusual for
  a shop and is worth keeping deliberately: it means the stable can never be used as a
  simple arbitrage loop (buy low, sell high) since the "low" and "high" prices are the same
  number at every moment.
