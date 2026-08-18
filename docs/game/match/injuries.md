# Injuries

> **Source:** `TPlayer.CheckFoul` @ 0x004f4d5f (READ) · `TProfile.DoInjury` @ 0x0056bb58 (VERIFIED) · `TProfile.LoseRandomSkillPoint` @ 0x0056bcfb (VERIFIED) · `TProfile.UpdateHealth` @ 0x0056b98b (VERIFIED) · `TProfile.UpdateSelectedForMatch` @ 0x0056726c (VERIFIED) · `TProfile.FixturePlayed` @ 0x005667ff (VERIFIED) · `TEngine.DoYourSubstitutionOff` @ 0x004d648f (VERIFIED) · `TScreen_MatchPrep.ButtonPainKillers` @ 0x0055eece (VERIFIED) · `TScreen_MatchPrep.SetUpScreen` @ 0x0055d904 (VERIFIED)
> **Confidence:** HIGH
> **Last checked:** 2026-08-15

## Only you can get hurt

New Star Soccer 5 tracks an in-match injury for exactly one player on the pitch: the human
player's own career character (`newstar`, the game's mascot as the title implies). Every
other player, teammate or opponent, can be fouled and carded, but the injury roll that
follows a foul is gated on `param_2.newstar <> 0` and there is no other call site anywhere
in the binary's call graph that reaches `TProfile.DoInjury` - the extracted call graph shows
exactly one caller of it. CPU players do not have a `TProfile` at all, so there is nowhere
for an "injury" to live even if the game wanted to hurt them.

Injuries happen as a side effect of being fouled, not as their own random event. There is no
independent "training ground injury" or "freak accident" roll: `TProfile.RandomIncident`,
the function that fires the game's other career mishaps (drinking too much, gambling
addiction, losing an item, a lost vehicle), has six cases and none of them is an injury.
The single trigger point is `TPlayer.CheckFoul`, called once per contact resolution
(`TPlayer.CheckPlayerContactAll`, unread) and once from inside a sliding tackle
(`TPlayer.SlideBall`, unread) - whenever the match engine decides a foul has actually
happened (distance/angle/possession checks that belong to `fouls-and-cards.md`, not this
document) it hands out a card to the fouler, sets up a free kick, and - only if the fouled
player is the human - rolls for injury.

If that roll comes up hurt: the human player is force-substituted out of the match right
there on the pitch (`TEngine.DoYourSubstitutionOff`), a generic AI-controlled player takes
the shirt for the rest of the game, and `TProfile.DoInjury` decides how bad it is. The
severity becomes a countdown of matches the human is unavailable for afterwards, ticking
down by one every time a fixture involving the player's club or nation is played.

## The numbers

### 1. Chance the foul actually injures you

`TPlayer.CheckFoul` only reaches the injury roll once it already knows a foul happened
*and* the victim is the human player. From there it is one roll: `Rand(N)`, hurt on a 1,
where `N` is the Engine.ini setting `injuryfrequency` (**15**, `EngineMedia`/incbin
`Inc/Engine.ini`, read at startup into a global) scaled down by a multiplier that depends on
the player's `energy` stat (0-100, set on the match-prep screen) and whether the player has
taken pain killers this outing:

| Condition | Multiplier | N = floor(15 × mult) | Chance of injury this foul |
|---|---:|---:|---:|
| `energy` < 30, **or** pain killers taken | ×0.5 | 7 | **14.3%** |
| 30 ≤ `energy` < 40 | ×0.6 | 9 | 11.1% |
| 40 ≤ `energy` < 50 | ×0.7 | 10 | 10.0% |
| 50 ≤ `energy` < 60 | ×0.8 | 12 | 8.3% |
| 60 ≤ `energy` < 70 | ×0.9 | 13 | 7.7% |
| `energy` ≥ 70 | ×1.0 (no reduction) | 15 | 6.7% |

Pain killers override the energy band entirely and always apply the worst multiplier
(×0.5), regardless of how fit the player otherwise is. The field read for the energy check
is `TProfile.energy` at offset `+0x15C`; the pain-killers flag is `TProfile.takenpainkillers`
at `+0x174` - both confirmed against `object_model.json`, and both match the fields
`TScreen_MatchPrep.ButtonPainKillers` writes to.

This is not a guess about intent: the in-game confirmation dialog for buying pain killers
says outright that they "will also increase the chances of suffering a more serious INJURY
in the next match" (`CMESSAGE_BUYPAINKILLERS`, `Languages.csv`), which is exactly what the
code above does.

### 2. How bad it is, once you're hurt (`TProfile.DoInjury`)

```
injury = Rand(3)                      ' 1-3, uniform
If Rand(5) = 1                        ' 20% chance
    injury = Rand(3, 5)               ' re-roll 3-5, uniform
EndIf
If takenpainkillers
    injury = Rand(5, 7)               ' overrides the above, uniform
EndIf
' ... skill loss decided from this value, see below ...
injury = injury + 1                   ' this is the value actually stored
```

`injury` is a small integer field on the career profile - it is simultaneously "how many
matches you're out for" and (before the final `+1`) the number that decides how much ability
is lost. Skill loss is `TProfile.LoseRandomSkillPoint(n)`, called with `n` = 1, 2 or 3 draws
depending on the roll:

**Normal case (no pain killers taken):**

| Roll | Chance | Skill-loss draws | Matches missed (roll+1) |
|---:|---:|---:|---:|
| 1 | 26.7% | 0 | 2 |
| 2 | 26.7% | 1 | 3 |
| 3 | 33.3%* | 1 | 4 |
| 4 | 6.7% | 2 | 5 |
| 5 | 6.7% | 2 | 6 |

*3 is reached two ways - as the top of the base 1-3 roll (26.7%) and as the bottom of the
20%-chance 3-5 re-roll (6.7%) - the two paths sum to 33.3%.

**After pain killers (this outing):**

| Roll | Chance | Skill-loss draws | Matches missed (roll+1) |
|---:|---:|---:|---:|
| 5 | 33.3% | 2 | 6 |
| 6 | 33.3% | 3 | 7 |
| 7 | 33.3% | 3 | 8 |

So a fresh match injury always sidelines the player for **2 to 8 matches** - never less than
two, never the full 10-match clamp the field is capped at (see below). Averaged out: about
3.4 matches missed normally (weighting the table above), jumping to 7.0 matches if the
injury happens on the back of a pain-killers match.

### 3. Skill loss (`TProfile.LoseRandomSkillPoint`)

Each of the 1-3 draws picks one of seven abilities uniformly at random (`Rand(7)`) and, only
if that ability is currently above a floor, cuts it:

| Roll | Ability | Floor to qualify | Points lost |
|---:|---|---:|---:|
| 1 | Pace | > 10 | −10 |
| 2 | Dribbling | > 5 | −5 |
| 3 | Tackling | > 5 | −5 |
| 4 | Flair | > 10 | −10 |
| 5 | Passing | > 5 | −5 |
| 6 | Heading | > 10 | −10 |
| 7 | Shooting | > 5 | −5 |

If the roll lands on an ability already at or under its floor, that draw does nothing - 
still "used", but silently. The physio report text (`CREPORT_PHYSIO3`, "Your abilities have
also suffered (...)") only lists the abilities that were actually reduced.

### 4. Recovery and being ruled out

`TProfile.UpdateHealth` runs once per fixture the player's club or nation plays
(`TProfile.FixturePlayed` calls it every time, whether or not the human actually took the
pitch), and does three things relevant to injury:

* `injury = injury - 1`, clamped back into `0..10`
* `takenpainkillers = 0` (the pain-killers penalty is one match only)
* the on-screen injury bar is set to `injury * 10` percent

While `injury > 0`, `TProfile.UpdateSelectedForMatch` short-circuits everything else and
sets `selectedformatch = -5` ("Not Picked - Injured"). This check is the very first thing
the method does, ahead of form, ban status, or club level - an injured player cannot even be
picked as a substitute, unlike a player who is merely out of form (which can still yield a
substitute slot).

### 5. Paying to skip it - pain killers

`TScreen_MatchPrep.ButtonPainKillers` lets the player buy the injury away outright:

* Blocked entirely if `injury > 4` - the game calls this "severe" and refuses
  (`CMESSAGE_PAINKILLERSSERIOUSINJURY`); the player must wait it out.
* Otherwise costs `injury * 5000` in-game currency (deducted via `UpdateBank`), needs a
  confirmation click, and on confirmation sets `injury = 0` and `takenpainkillers = 1`
  immediately.
* If the world-map travel time changes as a result of suddenly being fit, the game pops an
  extra message telling the player to go re-check it (`CMESSAGE_FITAGAINTRAVELTIME`).

Because `takenpainkillers` stays set until the *next* `UpdateHealth` call, a player who buys
their way fit and then gets fouled in that very match is rolling from the worst injury band
in both tables above - worse odds of getting hurt again (Table 1, ×0.5) **and** a worse
outcome if it happens (Table 2, 6-8 matches instead of 2-6). The game is not bluffing in its
own warning text.

## What it means in play

* **Getting fouled is only dangerous to you.** A crunching tackle on a teammate or an
  opponent has zero injury consequence in the reconstructed code - the entire mechanic
  exists for the player's own career character.
* **Fitness going into a match matters more than it looks.** The `energy` stat set on the
  match-prep screen roughly doubles injury risk end-to-end: 14.3% per foul when tired
  (under 30 energy) versus 6.7% when fully fit (70+). Since a foul against you is already a
  fairly rare event per match, this mostly matters as a background lean rather than
  something the player will feel foul-by-foul.
* **There is no "knock" tier.** Every injury that actually triggers costs at least 2
  matches and a real chance of permanent ability loss - there is no code path that produces
  a 0- or 1-match knock from a fresh injury roll. The minimum outcome (roll 1, 26.7% of
  injuries) is 2 matches out with no skill loss at all.
* **Any injury, however minor, benches you completely** - there is no partial availability.
  `selectedformatch = -5` is checked before anything else in team selection, so a 2-match
  knock keeps the player out of the squad entirely, the same as an 8-match one.
* **Pain killers are a trap dressed as a shortcut.** They convert a known, capped injury
  into instant availability, but the price is real: guaranteed worst-case severity bands on
  the very next foul while the flag is still set. The game explains this to the player in
  the purchase dialog, so it is a deliberate risk/reward decision, not a hidden trick.
* **Recovery is automatic and match-paced, not day-paced.** The countdown only moves when a
  fixture involving the player's team is actually played (`FixturePlayed`), so injuries are
  measured and communicated in "matches missed", matching the UI text exactly
  ("1 Match" / "N Matches" on the injury bar and in the physio report).

## What we do not know yet

* **What actually counts as a foul.** This document only covers the tail of
  `TPlayer.CheckFoul` (the injury roll and its inputs). The geometry that decides whether a
  slide tackle *is* a foul in the first place - distance, angle, "clean through" status,
  yellow vs red - belongs to `fouls-and-cards.md` (still a gap) and needs the front half of
  the same function plus its two call sites, `TPlayer.CheckPlayerContactAll` @ 0x004f458a
  and `TPlayer.SlideBall` @ 0x004f86d6, neither of which has been read yet.
* **`g_player_int01`.** `CheckFoul` only runs at all when this global equals 1 (it also
  requires `g_training_int03 = 0`, which clearly means "not a training-ground session").
  What flips `g_player_int01` is not yet established - it reads like a top-level "is a real
  match in progress" gate, but that is inference, not a read function.
  *UNCERTAIN: purpose of `g_player_int01`.*
* **`TProfile.UpdateAbility`** (slot `0xA8`, VA not yet resolved) is the method that
  actually applies the stat cut requested by `LoseRandomSkillPoint`. It has not been read,
  so it is not confirmed whether it clamps abilities at some floor beyond the `>10`/`>5`
  gating that already exists one level up.
* **Whether any other system can set `TProfile.injury`.** Everywhere this document found
  `injury` being *set* to a fresh (non-decrementing) value was inside `DoInjury`, and
  `DoInjury` has exactly one caller in the extracted call graph. That is strong evidence
  injuries are foul-only, but it is evidence from a generated call graph, not an exhaustive
  proof - a hand-search of `src/recovered/` and `src/recovered_unverified/` for the word
  "injur" (19 files) turned up nothing else that writes to the field.

## Implementation detail worth preserving

The skill-loss loop in `LoseRandomSkillPoint` has a quirk that is easy to lose in a
rewrite: the ability-reduction `Select` runs on **every** iteration regardless of what the
previous iteration rolled, but the description text that ends up in the physio report is
only appended when the roll **differs from the previous one** (`If r <> last`). Two
consecutive identical rolls (e.g. Tackling, then Tackling again) apply the stat cut twice
but the report only ever mentions "tackling" once. A clean rewrite that de-duplicates the
loop into "distinct skills only" will under-punish the player relative to the original - 
the loss is real even when the text doesn't say it happened twice.

Also worth keeping exactly as found: the severity roll is computed, then used for both the
physio-report wording *and* the skill-loss band, and **only after both of those consult it**
does the code add 1 to get the stored value. Reading `TProfile.injury` mid-function (e.g. for
a UI preview) between the roll and the final increment would see a value one lower than what
ends up on the profile - there is no intermediate save point, but a reimplementation that
splits `DoInjury` into "roll severity" and "apply it" as two separate steps needs to make
sure nothing observes the pre-increment number.
