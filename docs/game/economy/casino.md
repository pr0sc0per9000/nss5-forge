# The casino minigames

> **Source:** `TCard.Shuffle` @ 0x00577c36 (VERIFIED) · `TCard.Pull` @ 0x00577cc9 (VERIFIED) · `TCard.CreateCard` @ 0x00577b5e (VERIFIED) · `TBlackJack.CheckPlayerScore` @ 0x00576e46 (VERIFIED) · `TBlackJack.DealersTurn` @ 0x0057704c (VERIFIED) · `TBlackJack.Hit` @ 0x0057726a (VERIFIED) · `TBlackJack.ShowResult` @ 0x00577710 (VERIFIED) · `TScreen_BlackJack.CreateScreen` @ 0x00576333 (READ) · `TRoulette.GetResult` @ 0x00575795 (VERIFIED) · `TRouletteWheel.GetColour` @ 0x00575ca9 (VERIFIED) · `TScreen_Roulette.IncreaseBet` @ 0x00575027 (VERIFIED) · `TSlotMachine.DoPrize` @ 0x005784ef (VERIFIED) · `TSlotStrip.Update` @ 0x005787dd (VERIFIED) · `TScreen_Pairs.Update` @ 0x00579419 (VERIFIED) · `TPair_Icon.SetUp` @ 0x005799e3 (VERIFIED) · `TScreen_Negotiate.SetUpScreen` @ 0x0057a477 (VERIFIED) · `TScreen_Negotiate.Update` @ 0x0057a7e8 (VERIFIED) · `TScreen_Negotiate.Fail` @ 0x0057ab00 (VERIFIED) · `TProfile.Bet` @ 0x0056b780 (VERIFIED) · `TScreen_Casino.SetStake` @ 0x005742b8 (VERIFIED) · `TScreen_Casino.UpdateStakeCurrency` @ 0x0057411d (VERIFIED) · `TProfile.RandomIncident` @ 0x00567c79 (VERIFIED)
> **Confidence:** HIGH
> **Last checked:** 2026-08-15

## The framing this scope arrived with was half right

The task that produced this document was scoped as "Blackjack, roulette, slots,
higher-lower and pairs." That is a real list of five card/number games in New Star
Soccer 5 - but it is not one system, and only three of them live in the Casino.

`TScreen_Casino` (the building the player actually visits, reached from the club/city
menu) has exactly three game buttons in its class table: `ButtonBlackJack`,
`ButtonRoulette`, `ButtonSlots`, plus a `ButtonRelationships` that just leaves. **Those
three - Blackjack, Roulette, Slots - are the real casino: they cost and pay real career
money.** They all deal from the same deck engine (`TCard`) or the same "pick a stake
chip" UI on the Casino screen.

The other two names in the brief turned out to be minigames that only *reuse the same
card-flip presentation* and are launched from completely different parts of the game:

* **"Higher-lower"** is `TScreen_Negotiate` - the five-card guessing game that runs
  **inside contract negotiations**, not the casino. There is no `TScreen_HigherLower`
  or similar Type anywhere in the reflection data; the `GameMedia/Images/Casino/HigherLower/`
  art folder is filed under `Casino/` for asset-organisation reasons only. Winning it
  raises the wage a club is offering; losing it damages your relationship with your boss.
* **"Pairs"** is `TScreen_Pairs` - a 4×4 memory-matching game that costs energy, not
  money, and is launched from relationship interactions (boss, teammates, fans, friends,
  girlfriend, sponsors) to raise that relationship's score. It is never reached from the
  Casino screen either.

Both are documented below because they were named in the brief and because they share
`TCard`-adjacent machinery, but they are not gambling and have no house edge - there is
no bet.

## Blackjack, Roulette and Slots - plain English

**Blackjack.** Standard two-card start for player and dealer, hit-or-hold, bust over 21,
dealer must keep hitting until it has 17 or more. Every "win" - a beaten dealer, a
natural blackjack, or the pub-rules **5-card trick** (see below) - pays exactly **even
money** (you get your stake back plus one more stake), never the 3:2 bonus a real casino
pays for a natural blackjack. A tie just returns your stake.

**Roulette.** A 38-pocket wheel (American-style, with both a 0 and a "00" - see the
numbers table). The player can only bet the six outside/even-money bets - odd, even,
red, black, 1-18, 19-36 - never a single number. Each is a coin flip against roughly
half the wheel; the ball never lands on the true 50%, which is exactly what a casino's
edge is built from.

**Slots.** Three independently spinning fruit-machine reels, 8 fruits each (Orange,
Plum, Banana, Apple, Grapes, Cherries, Pineapple, Strawberry). Three matching fruits
pays big; any two matching pays a small amount; no match loses the stake. Unusually for
a casino minigame, the numbers below work out **in the player's favour** - see "What it
means in play."

All three games share the same seven-rung stake ladder, chosen once on the Casino
screen before entering a game (Blackjack and Slots both read the same "current stake"
global; Roulette instead accumulates its six bet piles independently, chip click by
chip click).

### The stake ladder

`TScreen_Casino.SetStake` / `TScreen_Roulette.IncreaseBet` - the same seven amounts
appear in both, in both directions (tapping a stake button cycles it up the ladder; it
wraps to 0 if the bank can't afford the next rung):

| Rung | Amount |
|---:|---:|
| 1 | 50 |
| 2 | 100 |
| 3 | 250 |
| 4 | 500 |
| 5 | 1,000 |
| 6 | 2,500 |
| 7 | 5,000 |

`TProfile.Bet` is the single gate all three games call before anything else happens: if
`bank < stake` it shows "You do not have enough money!" and refuses the bet; otherwise it
deducts the stake immediately (win or lose is settled afterwards) **and adds 2 to a
`gambling` stat on the player's profile, capped at 100.** That stat is not cosmetic - see
"What it means in play."

### Blackjack - the numbers

Scoring (`TBlackJack.GetPlayerScore` / `GetDealerScore`): every card counts face value,
face cards (11/12/13) count as 10, and an Ace counts as 1 unless counting it as 11 stays
at or under 21, in which case both totals are tracked (`lo`/`hi`) and the higher legal
one is used.

| Situation | Function / condition | Result |
|---|---|---|
| Player total > 21 | `CheckPlayerScore`, `lo > 21` | Bust, dealer wins |
| Exactly 21 on the first two cards | `hi = 21 And Count() = 2` | Natural Blackjack, instant win |
| 5 cards drawn without busting | `Count() = 5` | **5-Card Trick** - instant win regardless of total |
| Dealer total ≤ 16 | `DealersTurn`, `lo <= 16 And hi <= 16` | Dealer must hit again |
| Dealer total ≥ 17 (and not bust) | `lo > 16 Or hi > 16` | Dealer stands |
| Any win | `ShowResult` → `TScreen_BlackJack.Win` | Bank credited stake × 2 (even money) |
| Tie | `ShowResult` → `Tie` | Bank credited stake × 1 (stake returned, no profit) |
| Loss | `ShowResult` → `Lose` | Stake stays lost, no credit |

`TBlackJack.Hit` - the game reshuffles the full 52-card deck (`TCard.Shuffle`) at the
start of *every* new deal (`Deal` calls `Reset` calls `Shuffle`), so there is no
practical card-counting across hands. Achievement 75 ("Win money playing black jack")
fires on any win.

### Roulette - the numbers

`TRouletteWheel.GetColour` (a plain 38-way `Select`, exact case list read from the
byte-matched body) gives the colour of every pocket:

| Pocket(s) | Colour |
|---|---|
| 0 | Green |
| 37 (the wheel's "00") | Green |
| 1,3,5,7,9,12,14,16,18,19,21,23,25,27,30,32,34,36 (18 numbers) | Red |
| every other number 1-36 (18 numbers) | Black |

`TRoulette.GetResult` - the six bets, each an outside/even-money bet, each paying stake
× 2 (i.e. your stake back plus one more stake) if it hits:

| Bet | Wins on | Chance | Payout |
|---|---|---:|---:|
| Odd | odd number, not 0/00 | 18/38 = 47.4% | 2× stake |
| Even | even number, not 0/00 | 18/38 = 47.4% | 2× stake |
| Red | any red pocket | 18/38 = 47.4% | 2× stake |
| Black | any black pocket | 18/38 = 47.4% | 2× stake |
| 1-18 | low half | 18/38 = 47.4% | 2× stake |
| 19-36 | high half | 18/38 = 47.4% | 2× stake |

**House edge = (18 − 20) / 38 = −5.26%** for every bet type. This is the textbook
American double-zero roulette edge, and it falls straight out of the 38-pocket wheel:
there is no bet that covers 0 or 37, so the two green pockets are pure house profit.

A win also checks `CheckAchievement(73)` ("Win money at the roulette wheel").

### Slots - the numbers

`TSlotMachine.DoPrize` compares the three reels' `.fruit` values (each 0-7):

| Outcome | Prize credited | Net profit (prize − lost stake) |
|---|---:|---:|
| All three reels match | 30 × stake | +29 × stake |
| Exactly two of three match | 2.4 × stake | +1.4 × stake |
| No match | 0 | −1 × stake (stake lost) |

**Odds** are not drawn from a literal weight table the way roulette's colours are - each
reel stops wherever its continuously-decelerating physical position happens to be when
its randomised spin timer runs out (`TSlotStrip.Update`), not from a single `Rand()`
pick of a symbol. *Assuming* that process lands on each of the 8 fruits with equal
likelihood and independently per reel (INFERRED - see "What we do not know yet"), the
probabilities are a simple combinatorial count over 8³ = 512 equally likely reel triples:

| Outcome | Ways / 512 | Probability |
|---|---:|---:|
| Three match | 8 | 1.56% |
| Exactly a pair | 168 | 32.81% |
| No match | 336 | 65.63% |

Under that assumption, expected profit per spin works out to
`(8/512)×29 + (168/512)×1.4 + (336/512)×(−1) = +0.256`, i.e. **the machine pays out
about 25.6% more than it takes in, on average** - a positive expected value for the
player. That is the opposite of how a real slot machine is tuned, and it is the single
most notable number in this document if anyone plans to rebalance the economy.

Achievement 74 ("Win money on the slot machine") fires on any prize.

## Higher-or-Lower (in contract negotiations) - the numbers

`TScreen_Negotiate.SetUpScreen(a0:TContractOffer)` deals **5 distinct numbers, each
drawn from 1-11** (`Rand(11)`, rejection-sampled so no two of the five repeat - the
in-game instructions literally say "Numbers range from 1 to 11" per the
`highlow_InstrucsMobile` text tag). Card 1 is revealed face-up; the player then guesses,
one card at a time, whether each next card is **Higher** or **Lower** than the one just
revealed (`TScreen_Negotiate.ButtonHigher` / `ButtonLower`). Guessing right advances to
the next card and raises the wage increase on offer; guessing wrong ends the round.

| Correct guesses so far | Wage increase offered |
|---:|---:|
| 0 | 0% |
| 1 | 10% |
| 2 | 20% |
| 3 | 30% |
| 4 (all 5 cards revealed correctly) | 40% |

The player can stop and bank the current percentage at any point (`ButtonAccept`, which
calls `TContractOffer.IncreaseOffer(v)` and returns to the contract screen) or keep
pushing for a bigger increase. A wrong guess (`TScreen_Negotiate.Fail`) ends the whole
negotiation attempt **and costs the player 10-20 relationship points with the club's
boss** (`newbossrel -= Rand(10, 20)`) - pushing your luck on the wage negotiation and
losing has a real, separate cost beyond just missing out on the raise.

*Quirk worth knowing if you're playing, not just rebuilding it:* because the pool is
only the numbers 1-11, whenever the currently revealed card shows **1**, "Higher" is a
guaranteed correct guess, and whenever it shows **11**, "Lower" is guaranteed. There is
no equivalent guaranteed play for any of the other nine values.

## Pairs (relationship minigame) - the numbers

`TScreen_Pairs.SetUpScreen(a0)` costs **20 energy** to play (`g_profile.UpdateEnergy(-20.0)`)
and lays out **16 tiles in a 4×4 grid**. `TPair_Icon.SetUp` loads only **4 distinct
face images** for the chosen category and assigns them round-robin across the 16 tiles
 - so each of the 4 images appears on **4 different tiles**, not 2. Any two tiles sharing
an image count as a match; you do not need the *same two* tiles seen before.

The category (`a0`, 1-6) decides both the artwork and which relationship benefits from a
win:

| `a0` | Category | Text tag |
|---:|---|---|
| 1 | Boss | `CDILEMMA_BOSS` |
| 2 | Team | `CDILEMMA_TEAM` |
| 3 | Fans | `CDILEMMA_FANS` |
| 4 | Friends | `CDILEMMA_FRIENDS` |
| 5 | Girlfriend | `CDILEMMA_GIRL` |
| 6 | Sponsors | `CDILEMMA_SPONSORS` |

The player gets **exactly two attempts** to flip a matching pair (`TScreen_Pairs.Update`
counts attempts in `g_pairs_tries`; a second wrong attempt calls `Fail()` outright). A
match on either attempt calls `Success()`, which plays a sound, raises that relationship
by **+10**, and shows a category-flavoured dilemma message. A double miss just shows
"Fail!" with no further penalty coded into `Fail()` itself.

With 16 tiles split into 4 groups of 4 identical images, a single **blind** random pick
of two tiles matches `C(4,2)×4 / C(16,2) = 24/120 = 20%` of the time; across two blind
attempts that is `1 − 0.8² = 36%`. A player who remembers what the first failed attempt
revealed does much better than that, which is presumably the point - it is a genuine
memory game, not a coin flip, unlike the three real casino games above.

## What it means in play

**The three real casino games are not tuned the same way.** Roulette carries a
believable house edge (5.26%, identical to a real American wheel). Blackjack is nudged
toward the house by paying natural blackjacks at even money instead of the usual 3:2 and
by never letting a drawn card be a second Ace in the same hand (see quirks below) - both
push the odds a little further from a real casino's blackjack table, though this
document does not attempt a full basic-strategy simulation to turn that into one number.
**Slots, on the assumption used above, pays out more than it takes in.** If the game
world ever needs an obvious "free money" strategy patched out, this is it - three lines
in `TSlotMachine.DoPrize` (30× and 2.4×) are the whole story.

**Gambling has a stat, and the stat has consequences.** Every bet placed through
`TProfile.Bet` - win or lose - adds 2 to the player's `gambling` stat, capped at 100 (and
it decays by 5 a day via `TProfile.UpdateHealth`). `TProfile.RandomIncident` reads that
stat directly: above 60 there is a chance of a bad news story or a relationship hit tied
to gambling; above 90 (combined with `contractwage > 5000`) it can trigger a full
"gambling addict" news story that costs −20 to five relationships (boss, team, fans,
friends, girlfriend) simultaneously. So repeated casino visits are not free even when you
win - the `gambling` number just keeps climbing regardless of outcome, and eventually the
game punishes it on its own schedule, independent of the table results.

**Higher-or-Lower makes wage negotiation a real gamble, not a formality.** A player who
never risks the guessing game gets the club's opening offer; one who plays and wins big
can walk away with 40% more, but a bad guess costs boss relationship on top of the
missed raise - so the minigame is doing double duty as both a wage lever and a
relationship risk, wired into the career layer rather than the casino.

## Worth preserving exactly when reimplementing

* **`TCard.Pull` never actually removes a card.** It re-sorts the deck, takes the front
  card, and reassigns *that card's own* `randno` field to be one more than the current
  back card's `randno` - which just moves it behind the back of the list rather than
  taking it out of play. This is only safe because `TBlackJack.Deal` calls
  `TCard.Shuffle()` (which re-sorts by fresh random numbers) at the start of every hand.
  A reimplementation that "cleans up" `Pull` into a real dequeue-and-discard will not
  change any observable behaviour today, but changes the deck's internal object
  identity/order - worth a note if anything ever inspects deck state directly.
* **`TBlackJack.Hit` will not deal a second Ace onto a hand that already has one.** The
  draw loop is `Repeat card = TCard.Pull() Until Not ace Or card.num > 1` - if the hand
  being hit already contains an Ace, any Ace the deck offers up is discarded (moved to
  the bottom via `Pull`'s recycling behaviour above) and redrawn until a non-Ace shows.
  This is not standard blackjack and should be copied deliberately, not "fixed" to allow
  two Aces.
* **Blackjack payout is flat even money for every kind of win** - natural 21, ordinary
  win, and the 5-Card Trick all pay `stake × 2` via the exact same code path in
  `ShowResult`. There is no 3:2 bonus anywhere in this function.
* **A live cosmetic bug on the Casino screen's stake buttons.** `UpdateStakeCurrency`
  sets the sixth stake button's label with `FormatMoney(250, 0)` - the same literal the
  *third* button uses - instead of `FormatMoney(2500, 0)`. The button still sets the
  correct stake (2,500) when clicked (that logic lives in `SetStake` and reads correctly),
  it just visibly displays "250" on a button that spends 2,500. Confirmed byte-identical,
  not a decompiler artifact - reproduce the wrong label faithfully.
* **`TSlotStrip`'s narrower 6-fruit reel mode is dead code today.** `SetUp(a0, a1)` sets
  `fruitCount = 6` when `a1` is non-zero, and `Update` has a whole branch for it
  (`fruit Mod 3`). `TSlotMachine.SetUp` constructs all three strips with `a1 = 0`, so
  every observed reel uses the 8-fruit table; the 6-fruit path is unreachable from any
  code path this project has found. Keep the branch if reimplementing faithfully - just
  don't expect to ever see it trigger.

## What we do not know yet

* **`TScreen_BlackJack.CreateScreen` (0x00576333) is READ, not byte-matched.** It has
  been decompiled and is described above (background image, dealer/player panels and
  score labels, Hold/Hit/Play/Back buttons - Hold coloured red, Hit coloured green), but
  nobody has driven it through the byte-exact oracle yet. It is pure UI construction, not
  game rules, so nothing in this document depends on it being wrong - but it should be
  reconstructed and re-tagged VERIFIED before `src/nss5/` claims to have this screen.
* **The roulette wheel's physical pocket order was not found.** `TRoulette.GetResult`
  reads a pocket's *number* out of a Global array (`g_roulette_pockets`, 0x00C6BCBC) that
  is initialised somewhere outside every `TRoulette.*` body this project has recovered - 
  `extracted/module_globals_decoded.tsv` flags it as "a real init expression, not a bare
  array," i.e. some module-level setup code builds it, and that code has not been
  located. It only matters for exactly which number the ball visually lands on for a
  given wheel angle, not for the odds or payouts above, which come from `GetColour`'s
  byte-matched case list instead.
* **Whether a slot reel's stopping fruit is actually uniform across its 8 positions is
  assumed, not measured.** `TSlotStrip.Update` snaps to whichever symbol band the reel's
  continuously-integrated position happens to be in when its randomised spin timer
  expires - there is no single `Rand(0,7)` pick of a symbol to point to. The odds table
  above (and the "+25.6%" house-favours-the-player number that follows from it) assumes
  this physical process behaves like a fair 8-sided die per reel. Confirming that would
  need an Oracle-C differential sweep of `TSlotStrip.Spin` + `Update` across many
  randomised velocities/durations, tallying which fruit each run lands on.
* **No basic-strategy house edge is computed for Blackjack.** The rule set here is
  non-standard enough (flat even-money payout on every win type, the no-second-Ace hit
  rule, a full reshuffle every hand) that a real number would need a rules-accurate
  simulation across many hands of optimal player strategy, not a closed-form
  calculation. `TBlackJack.CheckPlayerScore`, `DealersTurn`, `Hit` and `ShowResult`
  (all VERIFIED, all cited above) are the complete rule set needed to build that
  simulation.
