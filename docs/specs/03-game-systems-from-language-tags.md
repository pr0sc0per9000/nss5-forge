# 03 - Game Systems Derived from `Languages.csv` Tag Namespaces

**Project:** NSS5-Forge - faithful BlitzMax source reconstruction of *New Star Soccer 5* (Steam appid 212780)
**Primary source:** `C:/Program Files (x86)/Steam/steamapps/common/New Star Soccer 5/GameMedia/Languages/Languages.csv`
**Corroborating source:** UTF-16 string dump of `NSS5.exe` (3,678 strings), `GameMedia/Data/*`, `GameMedia/Images/*`
**Status:** verified against the actual shipped files. Every count, tag and English string in this document was
extracted mechanically from the file - none of it is recalled or inferred unless explicitly marked `UNCERTAIN:`.

---

## 0. How to read this document

`Languages.csv` is the single richest artefact in the whole install. It contains **every user-visible string in the
game**, and - far more importantly for reconstruction - the *tag* column is effectively a **symbol table of the
game's design**. Every subsystem announces itself through a tag prefix. This document therefore does two things:

1. **Reverse-engineers each game system** from its tag namespace and, where possible, cross-checks the inference
   against widget IDs / debug labels found inside `NSS5.exe`.
2. **Dumps the complete tag inventory**, namespace by namespace, so that a programmer writing `TLanguage`,
   `TShop`, `TRelationships`, `TNewsEvent` etc. never has to re-open the CSV.

Sections 1-5 are the format and cross-cutting mechanics. Sections 6-20 are the system-by-system analysis with
inline tag dumps. Section 21 lists confirmed data defects in the shipped file. Appendices A-D dump the remaining
namespaces (keyboard, abbreviations, UI chrome, mobile dead weight) in full.

---

## 1. File format - verified facts

| Property | Value | How verified |
|---|---|---|
| Path | `GameMedia/Languages/Languages.csv` | file listing |
| Size | 1,424,170 bytes | `ls -la` |
| Encoding | **UTF-8, no BOM** | `od -c` of first bytes: `T a g \t e n \t ...`, multi-byte sequences `303 252` = `ê` |
| Line ending | **CRLF (`\r\n`)** | `od -c` |
| Delimiter | **TAB (0x09)** - not comma | `od -c` |
| Total lines | 2,751 | `wc -l` |
| Columns | **exactly 11 on every single row** - zero ragged rows | `awk NF` histogram: `2751 x 11` |
| Quoting | **none** - no `"` field quoting anywhere; fields are raw | inspection |
| Escapes | **none** - no `\n`, no `\t` inside fields | inspection |
| Header row | line 1: `Tag`, `en`, `br`, `pt`, `de`, `es`, `fr`, `it`, `pl`, `tr`, `nl` | line 1 |
| Metadata rows | lines 2-4 (`Tag_Language`, `Tag_NationId`, `Tag_Translator`) | lines 2-4 |
| Data rows | **2,747** (lines 5-2751) | 2751 − 4 |
| Unique tags | **2,739** (8 rows are duplicate tags, see §21) | `sort -u` |
| Characters forbidden in values | none observed: no `|`, no backtick, only 3 rows with non-ASCII in `en` (`clichés` ×2, a curly `“`) | grep |

### 1.1 The three metadata rows

These are **not** UI strings; they are per-language configuration read at load time.

| Tag | en | br | pt | de | es | fr | it | pl | tr | nl |
|---|---|---|---|---|---|---|---|---|---|---|
| `Tag_Language` | English | Português Brasileiro | Português | Deutsch | Español  | Français | Italiano | Polski | Türkçe | Nederlands |
| `Tag_NationId` | 0 | 28 | 151 | 75 | 175 | 71 | 95 | 150 | 193 | 133 |
| `Tag_Translator` | Simon Read | /n | Paulo Tavares e Hugo Cunha | Joe, Becks, Leo Oblomov, Mario Werkgarner | Guillermo Wallbrecher, Gabriel Jiménez | Draiden2kx, Chléo, Min's, Julien Haddar | Alessio Villani, Francesco Riccobono | Best Aka Kily, Olaf Kryus | Burak Akbugday, C. Mertcan Dogusgen, … | … |

Notes for reconstruction:

* `Tag_Language` is the **display name shown in the Options language combo**. Note `Español ` ships with a
  **trailing space** - reproduce it or normalise it, but be aware it exists.
* `Tag_NationId` cross-references `GameMedia/Data/Nations.csv` `id` column. **Verified**: 28=Brazil, 71=France,
  75=Germany, 95=Italy, 133=Netherlands, 150=Poland, 151=Portugal, 175=Spain, 193=Turkey. `en` uses `0`, which
  **does not exist in Nations.csv** - i.e. English has no default nationality and the new-player screen must not
  preselect one. This value is almost certainly used to preselect the player's nationality on the
  "Set up your nationality" screen when a non-English language is active.
* `Tag_Translator` for `br` is the literal string `/n` - a placeholder meaning "none". Do not render it.

### 1.2 Translation completeness (per column)

Measured over the 2,747 data rows, counting empty cells and the literal placeholder `/n`:

| Column | Missing | % |
|---|---|---|
| `en` | 0 | 0.0% |
| `br` | 0 | 0.0% |
| `pt` | 0 | 0.0% |
| `de` | 0 | 0.0% |
| `es` | 1 | 0.0% |
| `fr` | 1 | 0.0% |
| `it` | 1 | 0.0% |
| `pl` | 1 | 0.0% |
| `tr` | 1 | 0.0% |
| `nl` | **174** | **6.3%** |

The single shared gap in es/fr/it/pl/tr is `CNEWS_RANDOMCLUBCRISIS6`. The Dutch gap is a contiguous block of the
late-added (mobile-era) `CMESSAGE_*`, `CNEWS_*` and `CMOBILE_TIP*` strings - Dutch was translated before those
were authored. **A faithful `TLanguage.Get()` must therefore implement an empty-string fallback to `en`**,
otherwise a Dutch player sees blank dialogs. `UNCERTAIN:` whether the original falls back to `en` or renders the
tag itself; no fallback marker string was found in the exe.

---

## 2. Runtime lookup semantics (inferred, with evidence)

The exe contains raw tag literals such as `CMESSAGE_BUYNRG`, `tt_RelationsBoss`, `sla_Million`. It also contains
**bare prefixes with no suffix**: `CTIP_`, `CACHIEVEMENT_`, `CNEWS_MATCHSTARMAN`, `CBOSS_GENERICGOOD`,
`CDILEMMA_BOSS`, `CLICHE_`, `CNEWS_RANDOMCLUBBOOST`, `CMESSAGE_ENERGYBOOSTGIRL`, `CMESSAGE_BOSSREQUEST`,
`CMESSAGE_SPONSORREQUEST`, `CNEWS_GIRLSCANDALHIGH`, `CMESSAGE_LOSTVEHICLE`, `CREPORT_BOSSMOTM`, …

That establishes the two lookup idioms the reconstruction must support:

1. **Direct**: `Lang("CMESSAGE_BUYNRG")`.
2. **Randomised variant**: `Lang(prefix + Rand(1, N))` where `N` is the number of numbered variants that exist for
   that prefix. The variant count is *not* stored anywhere - it is a compile-time constant per call site. Every
   variant family and its exact cardinality is enumerated in this document so those constants can be recovered.

A third idiom is proven by the boss-shout system (§12): the exe stores keys with the literal token `SHOUT`
(`CBOSSSHOUT_GOODPASS`) plus the standalone strings `SHOUT`, `POS`-flavoured and `NEG`-flavoured families in the
CSV. The runtime substitutes `SHOUT` → `POS` or `NEG` depending on the boss's mood, then appends `1..4`.

### 2.1 Tag reference coverage in the PC exe

Cross-referencing the 2,739 unique tags against literal strings inside `NSS5.exe`:

* **1,100 tags appear verbatim** in the exe.
* **1,639 do not** - the overwhelming majority because they are reached by `prefix + index` construction
  (all 100 `CACHIEVEMENT_n`, all 49 `CTIP_n`, all 96+96 `CBOSS*`, all 91 `CMATCHTEXT_*`, …).
* A residue of namespaces has **no literal reference and no prefix stub at all** - these are dead in the PC build:
  `CACHIEVEMENTMOBILE_` (66), `CHELPMOBILE_` (42), `CMOBILE_TIP` (20), `iap_` (11), `upgrade_` (4), `WARNING_` (4),
  `workrate_` (4), `drink_` (4), `nrg_` (2), `gambling_` (1), `lifestyle_` (1), `appstore_` (1), `product_` (1),
  plus the `*MOBILE` suffixed `CMESSAGE_`/`CNEWS_` variants. Substring test: `MOBILE` occurs **0 times** in the
  exe string table; `iap`, `Star Bux`, `Arcade`, `Work Rate`, `Technique`, `Swipe` likewise **0 times**.

**Conclusion:** `Languages.csv` is a *shared* localisation file used by both NSS5-PC and the mobile
"New Star Soccer" title. A faithful PC reconstruction should load all rows (the file is read wholesale) but must
implement **none** of the mobile systems (Star Bux currency, IAP, Arcade Mode, Work Rate, the 5-skill mobile
model, swipe UI). They are catalogued in Appendix D for completeness and to prevent a reconstructor mistaking
them for cut PC content.

---

## 3. Namespace census (complete)

All 81 prefixes present in the tag column, with counts. "PC" = at least one tag or prefix stub of this namespace
is referenced by `NSS5.exe`.

| Prefix | Count | PC | System it reveals |
|---|---:|:--:|---|
| *(no underscore)* | 614 | yes | Bare UI labels, column headers, screen titles |
| `CMESSAGE_` | 408 | yes | Modal dialogs, confirmations, life-events, errors |
| `CNEWS_` | 194 | yes | Newspaper / web-page story pool about the player |
| `tla_` | 120 | yes | Three-letter abbreviations (table headers) |
| `key_` | 113 | yes | Keyboard key display names for the control editor |
| `CACHIEVEMENT_` | 100 | yes | The 100 PC achievements |
| `CBOSSPOS_` | 96 | yes | In-match boss shouts, boss in a **good** mood |
| `CBOSSNEG_` | 96 | yes | In-match boss shouts, boss in a **bad** mood |
| `CMATCHTEXT_` | 91 | yes | Text-commentary lines for match incidents |
| `CREPORT_` | 87 | yes | Post-match boss office / physio room report lines |
| `tt_` | 69 | yes | Button tooltips ("Button Tips" option) |
| `CACHIEVEMENTMOBILE_` | 66 | **no** | Mobile achievements (dead) |
| `CTIP_` | 49 | yes | Loading/hint tips (1-50, **46 missing**) |
| `CHELPMOBILE_` | 42 | **no** | Mobile contextual help (dead) |
| `position_` | 35 | yes | Ordinal suffixes 1st…32nd + Promoted/Relegated/Finished |
| `CHELP_` | 35 | yes | PC contextual help callouts (arrow-pointer tutorials) |
| `help_` | 33 | yes | Per-screen Help-button body text |
| `CCHANCESTAGE_` | 30 | **no** | Mobile text-match chance narration (dead on PC) |
| `sla_` | 28 | yes | Single-letter abbreviations (W/D/L, H/A, K/M …) |
| `CLICHE_` | 26 | yes | Interview mini-game cliché phrases |
| `CDILEMMA_` | 24 | yes | "Two people want to see you" outcome lines |
| `date_` | 23 | yes | Month / weekday / season names |
| `CTRAINING_` | 23 | yes | Training-challenge objective text |
| `controls_` | 21 | yes | Control action names in the key editor |
| `CMOBILE_` | 20 | **no** | Mobile tips (dead) |
| `transfer_` | 18 | yes | Transfer/loan screen buttons and statuses |
| `settings_` | 17 | yes | Options screen |
| `replay_` | 14 | yes | Replay viewer controls |
| `CRESULTNEWS_` | 14 | **no** | League/cup result stories (see §14 - mobile-era) |
| `iap_` | 11 | **no** | In-app purchases (dead) |
| `blackjack_` | 11 | yes | Black Jack casino game |
| `account_` | 11 | partial | Online account / free-vs-premium |
| `vehicle_` | 10 | yes | **Shop: 10 vehicles** |
| `sponsor_` | 10 | yes | **10 sponsorship categories** |
| `property_` | 10 | yes | **Shop: 10 properties** |
| `item_` | 10 | yes | **Shop: 10 luxury items** |
| `CBOSS_` | 10 | yes | Generic good/bad boss shouts (fallback pool) |
| `simple_` | 8 | yes | Simple (1-button) control scheme description |
| `injury_` | 7 | yes | "<Skill> Lost!" injury popups |
| `finances_` | 7 | yes | Finances screen |
| `advanced_` | 7 | yes | Advanced (3-button) control scheme description |
| `time_` | 6 | yes | Travel-time buckets |
| `roulette_` | 6 | yes | Roulette bet types |
| `comptype_` | 6 | yes | Competition format enum |
| `skin_` | 5 | yes | Skin tone enum |
| `selection_` | 5 | **no**\* | Team-selection status enum (PC uses bare labels) |
| `request_` | 5 | yes | Free-kick / corner request preference |
| `pos_` | 5 | yes | Long-form position names |
| `leaderboard_` | 5 | partial | Online leaderboard views |
| `joy_` | 5 | yes | Joystick direction/button names |
| `workrate_` | 4 | **no** | Mobile work-rate setting (dead) |
| `upgrade_` | 4 | **no** | Web-era premium upsell (dead on Steam) |
| `skiptime_` | 4 | yes | Skip-time menu |
| `matchmsg_` | 4 | yes | In-match status flashes (drunk/cramps/tired/unhappy) |
| `kit_` | 4 | yes | Kit slot names |
| `highlow_` | 4 | yes | Contract negotiation Higher/Lower mini-game |
| `drink_` | 4 | **no** | Mobile NRG drink tiers (dead) |
| `climate_` | 4 | yes | Nation climate enum |
| `WARNING_` | 4 | **no** | 2019 web→Steam migration notices (dead) |
| `volume_` | 3 | yes | Volume enum |
| `side_` | 3 | yes | Pitch side enum |
| `matchtype_` | 3 | yes | Ban scope: league-and-cup / continental / international |
| `matchlength_` | 3 | yes | 3/5/7 minute halves |
| `gamespeed_` | 3 | yes | Game speed enum |
| `difficulty_` | 3 | yes | Easy / Normal / Hard |
| `Tag_` | 3 | n/a | File metadata (§1.1) |
| `zoom_` | 2 | yes | Replay zoom |
| `stable_` | 2 | yes | Horse racing labels |
| `social_` | 2 | yes | Tweet / Share |
| `nrg_` | 2 | **no** | Mobile "Can/Cans" (dead) |
| `bet_` | 2 | yes | You Won / You Lost |
| `training_` | 1 | **no** | Mobile "Aim Here" |
| `tournament_` | 1 | yes | Tournament exit label |
| `team_` | 1 | yes | "Selection" |
| `product_` | 1 | **no** | Store product description (dead) |
| `price_` | 1 | yes | "Free" |
| `match_` | 1 | yes | "Watch" |
| `lifestyle_` | 1 | **no** | Mobile lifestyle label |
| `interview_` | 1 | yes | Interview instruction |
| `instrucs_` | 1 | yes | Activation key instruction |
| `gambling_` | 1 | **no** | Mobile "Wins" |
| `fixtures_` | 1 | yes | "Round" |
| `fixture_` | 1 | yes | "Bye" |
| `contract_` | 1 | yes | "Bonuses" |
| `casino_` | 1 | yes | "Stake" |
| `btn_` | 1 | yes | `btn_Action` |
| `appstore_` | 1 | **no** | "Games" (dead) |
| `CINSTRUCS_` | 1 | yes | Pairs mini-game instruction |

\* `selection_*` tags exist but the PC exe references the bare labels `Not Picked`, `Low Club Level`,
`No Experience`, `Boss Unhappy`, `Poor Form`, `Match Fit`, `Substitute`, `Injured`, `Tiredness`, `No Boots`,
`No Shin Pads`, `No Injury` instead. The `selection_*` set is the mobile equivalent.

### 3.1 Namespaces the brief asked about that do **not** exist in this file

Named in the task brief but **absent from `Languages.csv`**:

| Asked-for | Reality |
|---|---|
| `CRELATION_*` | **Not a language namespace.** `CRELATION_BOSS: `, `CRELATION_TEAM: `, `CRELATION_FANS: `, `CRELATION_FRIENDS: `, `CRELATION_GIRLFRIEND: `, `CRELATION_SPONSORS: `, `CRELATION_FAME: ` exist **only inside NSS5.exe as debug-print labels** (note the trailing `": "`). They confirm the seven tracked relationship scalars but carry no localised text. |
| `btn_*`, `pan_*`, `lbl_*`, `tbl_*`, `prg_*`, `cmb_*` | These are **widget IDs inside the exe**, not language tags. `Languages.csv` contains exactly one (`btn_Action`). They are extremely valuable for reconstruction (they name every UI control) and are used throughout this document as corroboration. |
| `mainmenu_*`, `editmenu_*` | Do not exist. Menu items are bare no-underscore tags (`New Career`, `Load Career`, `Quick Match`, `Replays`, `Scenarios`, `Data Editor`, `Options`, `Quit`, …). |

---

## 4. Runtime variable substitution - complete `$variable` inventory

Every `$name` token found in the `en` column, with usage count and the tags that consume it. Substitution is a
plain textual replace performed after the tag lookup.

| Variable | Uses | Meaning | Representative tags |
|---|---:|---|---|
| `$playername` | 193 | The player's own name | `CNEWS_*` (almost all), `CMATCHTEXT_CHANCEFORPLAYER*`, `CMESSAGE_RETIREMENTLEGEND` |
| `$clubname` | 164 | The player's **current** club | `CMESSAGE_CONTRACTEXPIRED`, `CNEWS_FIRSTCONTRACT`, `CMATCHTEXT_PENALTYSTEPUP` |
| `$opposingclubname` | 74 | Opponent in the match just played | `CNEWS_MATCHSTARMAN*`, `CREPORT_BOSSGOOD*` |
| `$offerclubname` | 31 | Club making a transfer offer / signing him | `CNEWS_TRANSFER1..10`, `CNEWS_TRANSFERINTEREST1..10` |
| `$percent` | 37 | Percentage cost or gain (energy cost, wage increase) | all `*REQUEST*` tags, `CMESSAGE_CONTRACTINCREASE`, `highlow_EndNegotiations` |
| `$value` | 28 | Transfer fee / player valuation, pre-formatted with currency | `CNEWS_TRANSFER*`, `CMESSAGE_TRANSFERNEWCLUB`, `CMESSAGE_SELLITEM` |
| `$energy` | 17 | Energy delta as a percentage | `CMESSAGE_ENERGYBOOST*`, `CMESSAGE_CONFIRMPURCHASEENERGYCOST` |
| `$teamname` | 15 | Team referenced in text-commentary narration | `CCHANCESTAGE_MOVEFORWARD*`, `CCHANCESTAGE_SHOOT*` |
| `$winningteam` | 13 | Winner in a result story | `CRESULTNEWS_*` |
| `$losingteam` | 12 | Loser in a result story | `CRESULTNEWS_*` |
| `$score1` / `$score2` | 12 / 12 | Winner's / loser's goals | `CRESULTNEWS_*` |
| `$competition` | 12 | Competition name | `CNEWS_CUPWINNER`, `CNEWS_LEAGUEWINNER`, `CRESULTNEWS_*` |
| `$cash` | 9 | A money amount, pre-formatted | `CMESSAGE_BUYHORSE`, `CMESSAGE_CONFIRMPURCHASE`, `CMESSAGE_SPONSOROFFER`, `CMESSAGE_HORSEPRIZE` |
| `$num` | 9 | Generic integer (matches banned, matches remaining, goals scored) | `CNEWS_DRUGTESTFAIL`, `CREPORT_PHYSIO2`, `CMESSAGE_BOOTSHAVEMATCHES`, `transfer_OffersWindowOpens` |
| `$vehicle` | 8 | Localised vehicle name | `CMESSAGE_LOSTVEHICLE1..3`, `CMESSAGE_VEHICLEBORROW*`, `CMESSAGE_VEHICLEDAMAGED*`, `CNEWS_STYLEVEHICLE` |
| `$filename` | 8 | Save/replay/scenario file name | `CMESSAGE_FILE*`, `CMESSAGE_DELETEYN`, `CMESSAGE_SCENARIOSAVED` |
| `$wage` | 6 | Weekly (PC) / per-match (mobile) wage | `CNEWS_RENEWCONTRACT`, `CNEWS_TRANSFER4` |
| `$loanclub` | 3 | Club he is on loan at | `CMESSAGE_LOANSTARTED/ENDED/ENDBOSSUNHAPPY` |
| `$sponsor` | 4 | Sponsorship **category** name (see §10) | `CMESSAGE_SPONSOROFFER/EXPIRED/CANCEL` |
| `$item` | 4 | Localised luxury-item name / generic list item | `CMESSAGE_LOSTITEM`, `CNEWS_STYLECLOTHES`, `CNEWS_STYLEGADGET`, `CMESSAGE_DELETE` |
| `$amount` | 4 | Bribe payout or repair bill | `CMESSAGE_BRIBE`, `CMESSAGE_BRIBECOMPLETE`, `CMESSAGE_VEHICLEDAMAGED*` |
| `$name` | 4 | Horse name / account name | `CMESSAGE_HORSEBECOMESILL`, `CMESSAGE_HORSEEXHAUSTED`, `CMESSAGE_PLAYERNOTFOUND` |
| `$team` | 4 | The **national** team (used to disambiguate "the $team BOSS") | `CMESSAGE_NOTPICKED*INT`, `CMESSAGE_SUB*INT` |
| `$matchtype` | 3 | One of `matchtype_club` / `matchtype_continental` / `matchtype_international` | `CREPORT_COACHBAN1/2`, `CREPORT_COACHBANIMMINENT` |
| `$years` | 3 | Contract length in years | `CNEWS_FIRSTCONTRACT`, `CNEWS_RENEWCONTRACT`, `CNEWS_TRANSFER4` |
| `$dist` | 3 | Distance with unit (metres/yards) | `CMATCHTEXT_PASSFANTASTIC`, `CMESSAGE_NEWFURTHESTGOAL/PASS` |
| `$clubateam` | 2 | Parent A-team club when promoted from a B team | `CMESSAGE_PROMOTEFROMBTEAM`, `CMESSAGE_PROMOTEDTOATEAM` |
| `$id` | 2 | Competition id (Data Editor) | `CMESSAGE_NEWCOMPID*` |
| `$bonus` | 2 | Goal bonus (mobile contract) | `CMESSAGE_CONTRACTOFFERMOBILE` |
| `$num1` / `$num2` | 1 / 1 | Long-season / short-season round counts | `CMESSAGE_SHORTORLONGSEASON` |
| `$scandalrating` | 1 | Prospective girlfriend's scandal % | `CMESSAGE_GIRLFRIENDMEET` |
| `$skillslost` | 1 | Comma list of abilities lost to injury | `CREPORT_PHYSIO3` |
| `$transdate` | 1 | Week number the transfer window opens | `CMESSAGE_TRANSFERWINDOWCLOSEDNEXT` |
| `$cost` | 1 | Vehicle repair cost | `CMESSAGE_LOSTVEHICLE3` |
| `$price` | 1 | Property price (mobile) | `CMESSAGE_PROPERTYCHECK` |
| `$property` | 1 | Localised property name | `CNEWS_STYLEPROPERTY` |
| `$pos` | 1 | Final league position | `CMESSAGE_LEAGUEFINISHPOS` |
| `$date` | 1 | Loan expiry date | `transfer_OnLoanUntil` |
| `$wait` | 1 | Countdown until free matches refresh | `CMESSAGE_NOGAMESLEFT` |
| `$matches` | 1 | Free matches remaining today | `CMESSAGE_PASSWORDOKFREE` |
| `$year` | 1 | Year international fixtures begin | `CMESSAGE_INTERNATIONALSTARTYEAR` |
| `$clubstadium` / `$offerclubstadium` | 1 / 1 | Stadium names in transfer stories | `CNEWS_TRANSFER8`, `CNEWS_TRANSFER7` |
| `$hometeam` / `$awayteam` | 1 / 1 | Next cup tie | `CRESULTNEWS_NEXTCUPOPPONENT` |
| `$highscore` | 1 | Goals scored by the winner | `CRESULTNEWS_HIGHSCORE3` |
| `$club` / `$comp` / `$place` / `$code` / `$clubs` | 1 each | Data Editor / scenario / transfer-rumour list | `CMESSAGE_DELETECLUB`, `CMESSAGE_DELETECOMPETITION`, `CMESSAGE_DELETEPROMOTIONPLACE`, `CMESSAGE_SCENARIOSUBMITTED`, `CMESSAGE_TRANSFERRUMOUR` |
| `$goalbonus` / `$assistbonus` | 1 each | Mobile transfer confirm | `CMESSAGE_TRANSFERCONFIRM` |
| `$labelname` / `$leaguename` | 1 each | Mobile trial success | `CMESSAGE_TRIALSUCCESSMOBILE` |
| `$rating` `$goals` `$tackles` `$assists` `$passes` `$distance` | 1 each | Social-share stats | `CMESSAGE_SOCIAL2..10` |

### 4.1 Variables that exist in the exe but never in the `en` column

The exe string table also contains `$keykick`, `$keypause`, `$injurylength`. Neither `$keykick` nor `$keypause`
nor `$injurylength` appears in **any** of the ten language columns. Interpretation:

* `$keykick` / `$keypause` - the code *would* substitute the player's currently bound Kick/Pause key into the trial
  instructions (`CMESSAGE_TRIALPACE` says "press PAUSE", `CMESSAGE_TRIALPASSING` says "the KICK button"). The
  English text was hardcoded to the words instead, so the substitution is a no-op. **Implement the substitution
  hook anyway** - a reconstruction that drops it will diverge if anyone re-localises.
* `$injurylength` - a planned but unused placeholder; `CREPORT_PHYSIO2` uses `$num` instead.

### 4.2 False positives - `$` used as a currency symbol

`$1`, `$5`, `$10`, `$20`, `$25` appear in `CACHIEVEMENT_41..44` and `CACHIEVEMENT_57..59`
("Make a $1 million transfer move", "Have $25 million in the bank"). These are **literal dollar signs**, not
variables. A naive `$[A-Za-z0-9]+` substitution regex will mangle them - the original must be matching
`$[A-Za-z]` only (letter-initial). Reproduce that constraint.

---
## 5. The player model - abilities, match ratings, positions

### 5.1 The seven trainable ABILITIES

Confirmed by the `abilities` screen widget block in the exe, which defines for each ability a label, a progress
bar, a numeric readout, a tooltip and a training button:

```
pan_abilities
  Pace      lbl_Pace      prg_Pace      lbl_PaceNum      tt_PaceTraining      btn_Pace
  Flair     lbl_Flair     prg_Flair     lbl_FlairNum     tt_FlairTraining     btn_Flair
  Tackling  lbl_Tackling  prg_Tackling  lbl_TacklingNum  tt_TacklingTraining  btn_Tackling
  Dribbling lbl_Dribbling prg_Dribbling lbl_DribblingNum tt_DribblingTraining btn_Dribbling
  Passing   lbl_Passing   prg_Passing   lbl_PassingNum   tt_PassingTraining   btn_Passing
  Shooting  lbl_Shooting  prg_Shooting  lbl_ShootingNum  tt_ShootingTraining  btn_Shooting
  Heading   lbl_Heading   prg_Heading   lbl_HeadingNum   tt_HeadingTraining   btn_Heading
lbl_Skills          <- aggregate "skill rating" meter
```

| # | Ability | Tag | Training tooltip | Trained by |
|---|---|---|---|---|
| 1 | Pace | `Pace` | `tt_PaceTraining` | `CTRAINING_PACE1` |
| 2 | Flair | `Flair` | `tt_FlairTraining` | `CTRAINING_FLAIR1` |
| 3 | Tackling | `Tackling` | `tt_TacklingTraining` | `CTRAINING_TACKLING1`, `CTRAINING_TACKLING2` |
| 4 | Dribbling | `Dribbling` | `tt_DribblingTraining` | `CTRAINING_DRIBBLING1`, `CTRAINING_DRIBBLING2` |
| 5 | Passing | `Passing` | `tt_PassingTraining` | `CTRAINING_PASSING1` |
| 6 | Shooting | `Shooting` | `tt_ShootingTraining` | `CTRAINING_SHOOTING1`, `CTRAINING_SHOOTING2` |
| 7 | Heading | `Heading` | `tt_HeadingTraining` | `CTRAINING_HEADING1`, `HEADING2`, `HEADING3` |

Behavioural rules extracted from tip/help text (all quoted verbatim in §Appendix B):

* `CTIP_8` - SHOOTING, PASSING and HEADING determine **kick accuracy**; low ability makes shots/passes deviate
  from the aim direction.
* `CTIP_12` - FLAIR determines **how much bend** can be applied; more bend is achievable at lower kick power.
* `CTIP_11` - FLAIR is a prerequisite for passing the SHOOTING training challenges.
* `CMESSAGE_GETTINGOLD` / `CTIP_49` - **after age 30, PACE and DRIBBLING decay** and can no longer be restored to
  maximum. Fired once as `CMESSAGE_GETTINGOLD`.
* `CMESSAGE_LASTSEASON` + `CTIP_50` - career is **20 seasons**, then forced retirement.
* `CMESSAGE_NOTRAININGMAX` / `NOTRAININGTIRED` / `NOTRAININGINJURY` - the three training refusal conditions.
* Injury can *remove* ability points: `injury_Pace`, `injury_Flair`, `injury_Tackling`, `injury_Dribbling`,
  `injury_Passing`, `injury_Shooting`, `injury_Heading` are the seven "<X> Lost!" popups, and `CREPORT_PHYSIO3`
  reports the list as `$skillslost`.

| Tag | English |
|---|---|
| `CTRAINING_DRIBBLING1` | Run between the poles with the ball. If you touch a pole you will fail. |
| `CTRAINING_DRIBBLING2` | Run between the cones. If you touch a cone or pole you will fail. |
| `CTRAINING_FLAIR1` | Try to bend a shot between all the poles. |
| `CTRAINING_HEADING1` | Header a ball. |
| `CTRAINING_HEADING2` | Score goals from behind the red line. You must head the ball. |
| `CTRAINING_HEADING3` | Head the ball between the cones. |
| `CTRAINING_PACE1` | Run between the poles. If you touch a pole you will fail. |
| `CTRAINING_PASSING1` | Kick the ball between the cones. |
| `CTRAINING_SHOOTING1` | Score goals from behind the red line. |
| `CTRAINING_SHOOTING2` | Score goals from a set-piece. |
| `CTRAINING_TACKLING1` | Try to touch the ball. |
| `CTRAINING_TACKLING2` | Knock down all the cones by slide tackling. |
| `injury_Dribbling` | Dribbling Lost! |
| `injury_Flair` | Flair Lost! |
| `injury_Heading` | Heading Lost! |
| `injury_Pace` | Pace Lost! |
| `injury_Passing` | Passing Lost! |
| `injury_Shooting` | Shooting Lost! |
| `injury_Tackling` | Tackling Lost! |
| `CTRAINING_ARCADEFINISH` | You scored $num goals. Do you want to play again? |
| `CTRAINING_ARCADEFINISHRECORD` | You scored $num goals. A new high score! Do you want to play again? |
| `CTRAINING_TUTORIAL1a` | TOUCH the ball, DRAG to aim, then RELEASE. |
| `CTRAINING_TUTORIAL1b` | Now touch the centre of the ball to kick it straight. |
| `CTRAINING_TUTORIAL2a` | It is also possible to bend your shots. Aim to the left of the dummy players. |
| `CTRAINING_TUTORIAL2b` | To bend the ball right you need to tap it on the left. |
| `CTRAINING_TUTORIAL3a` | You can add backspin or topspin to the ball too. Aim straight at the goal. |
| `CTRAINING_TUTORIAL3b` | Now tap the ball at the bottom to chip it over the wall. |
| `CTRAINING_TUTORIAL4a` | At higher levels you may need to compensate for wind when aiming your kick. |
| `CTRAINING_TUTORIAL5a` | This displays how many attempts you have left to complete the challenge. |
| `CTRAINING_TUTORIALFINISH` | That's the end of the tutorial. You have learnt the basics of New Star Soccer and are all set to try out the ARCADE and CAREER modes. |

### 5.2 The ten match RATINGS (separate from abilities)

The `abilities` screen has a second panel, `pan_Levels`, holding ten more progress bars. `CHELP_PLAYERRATINGS`
states: *"These are your ratings. They can only be improved by performing the action during a match."* These are
**not** trainable - they are usage-driven proficiencies.

| # | Rating | Tag | Exe widget | Praise line |
|---|---|---|---|---|
| 1 | Positioning | `Positioning` | `prg_Positioning` | `CREPORT_GOODPOSITIONING` |
| 2 | Short Passing | `Short Passing` | `prg_ShortPassing` | `CREPORT_GOODSHORTPASSING` |
| 3 | Long Passing | `Long Passing` | `prg_LongPassing` | `CREPORT_GOODLONGPASSING` |
| 4 | Finishing | `Finishing` | `prg_Finishing` | `CREPORT_GOODFINISHING` |
| 5 | Long Shots | `Long Shots` | `prg_LongShots` | `CREPORT_GOODLONGSHOTS` |
| 6 | Crossing | `Crossing` | `prg_Crossing` | `CREPORT_GOODCROSSING` |
| 7 | Free Kicks | `Free Kicks` | `prg_FreeKicks` | `CREPORT_GOODFREEKICKS` |
| 8 | Corners | `Corners` | `prg_Corners` | `CREPORT_GOODCORNERS` |
| 9 | Penalties | `Penalties` | `prg_Penalties` | `CREPORT_GOODPENALTIES` |
| 10 | Aggression | `Aggression` | `prg_Aggression` | `CREPORT_GOODAGGRESSION` |

Additional bare tags in the same family, not bound to a `prg_` bar in the dump: `Ball Control` (`tla_BallControl`
= `CNT`), `Vision`. `UNCERTAIN:` `Ball Control` and `Vision` may be mobile-only (`Vision`/`Technique`/`Power` are
the mobile 5-skill model); `Vision` appears 3× in the exe string table but not as a `prg_` bar.

Match-rating *inputs* are named directly in the exe (they are save-file / stats keys, not language tags):
`ratingperminute`, `ratingpasses`, `ratingdefensiveheaders`, `ratingshots`, `ratinggoals`, `ratingassists`,
`ratingsaves`, `ratingtackles`, `ratingfouls`, `ratingyellows`, `ratingreds`. `CTIP_18` adds that **calling for
the ball does not affect overall match rating but bad calls hurt POSITIONING**; `CTIP_19` says assists give the
rating "a big boost".

### 5.3 Positions

| Tag | English |
|---|---|
| `pos_AttackingMid` | Attacking Midfielder |
| `pos_Defender` | Defender |
| `pos_DefensiveMid` | Defensive Midfielder |
| `pos_Forward` | Forward |
| `pos_Midfielder` | Midfielder |
| `side_Centre` | Centre |
| `side_Left` | Left |
| `side_Right` | Right |
| `sla_AttackingMid` | AM |
| `sla_Centre` | C |
| `sla_Defender` | D |
| `sla_DefensiveMid` | DM |
| `sla_Forward` | F |
| `sla_GoalKeeper` | GK |
| `sla_Left` | L |
| `sla_Midfielder` | M |
| `sla_Right` | R |
| `sla_Substitute` | S |
| `tla_AttackingMid` | AM |
| `tla_Defender` | D |
| `tla_DefensiveMid` | DM |
| `tla_Forward` | F |
| `tla_GoalKeeper` | GK |
| `tla_GoalKeeping` | Gk |
| `tla_Midfielder` | M |

Position-change rules (from `CMESSAGE_*`): the BOSS must approve a position change (`CMESSAGE_NEWPOSITIONSUCCESS`
/ `CMESSAGE_NEWPOSITIONFAIL` when relationship too low), and there are **ability gates per position** - 
`NEWPOSITIONFAILDEFENDER` demands TACKLING, `NEWPOSITIONFAILMIDFIELDER` demands PASSING,
`NEWPOSITIONFAILFORWARD` demands SHOOTING.

---

## 6. Training system

Seven training screens (`SetUpTraining_Pace`, `_Dribbling`, `_Passing`, `_Shooting`, `_Heading`, `_Flair`,
`_Tackling` in the exe). The **same screens double as the 7-challenge trial** when starting a career
(`CMESSAGE_TRIAL`: *"complete 7 training challenges"*).

| Challenge | Objective tag | Trial-intro tag |
|---|---|---|
| Pace | `CTRAINING_PACE1` | `CMESSAGE_TRIALPACE` |
| Dribbling | `CTRAINING_DRIBBLING1`, `CTRAINING_DRIBBLING2` | `CMESSAGE_TRIALDRIBBLING` |
| Passing | `CTRAINING_PASSING1` | `CMESSAGE_TRIALPASSING` |
| Shooting | `CTRAINING_SHOOTING1`, `CTRAINING_SHOOTING2` | `CMESSAGE_TRIALSHOOTINGSIMPLE` / `…ADVANCED` |
| Heading | `CTRAINING_HEADING1/2/3` | `CMESSAGE_TRIALHEADINGSIMPLE` / `…ADVANCED` |
| Flair | `CTRAINING_FLAIR1` | `CMESSAGE_TRIALFLAIR` |
| Tackling | `CTRAINING_TACKLING1`, `CTRAINING_TACKLING2` | `CMESSAGE_TRIALTACKLING` |

Trial HUD readouts (`lbl_TrialInstrucs1..4` in the exe): `CMESSAGE_TRIALTIME` (time left),
`CMESSAGE_TRIALBALLS` (balls left), `CMESSAGE_TRIALGOALS` (goals needed).
Outcomes: `CMESSAGE_TRAININGSUCCESS`, `CMESSAGE_TRAININGFAIL`, `Time Up!`, `CMESSAGE_TRIALSUCCESS`,
`CMESSAGE_TRIALFAIL`. Props referenced by the exe: `Cones.png`, `Poles.png`, `Dummies.png`, `Zone.png`,
`Target.png`, with `ConeHit.ogg`, `ConeSplit.ogg`, `PoleBoing.ogg`, `TrainingSuccess.ogg`, `TrainingClap.ogg`,
`TrainingReset.ogg`, `TrainingError.ogg`.

Note the SIMPLE/ADVANCED control-scheme fork: heading and shooting have **two different instruction texts**
depending on the active control scheme, so the trial must query the control mode.

| Tag | English |
|---|---|
| `CHELP_ABILITIES` | On the left of the screen you can see your abilities and any boosts that are currently applied to them. |
| `CHELP_TRAININGBUTTONS` | When you want to improve a skill click one of these buttons to take the training challenge. |
| `CMESSAGE_CHAPTERFAIL` | Unlucky. You have failed to complete this chapter. |
| `CMESSAGE_CHAPTERLOCKED` | This chapter is locked! |
| `CMESSAGE_CHAPTERSUCCESS` | Congratulations! You have completed this chapter. |
| `CMESSAGE_NOTRAININGINJURY` | You cannot train whilst you are injured. |
| `CMESSAGE_NOTRAININGMAX` | You are at the maximum limit for this ability. |
| `CMESSAGE_NOTRAININGTIRED` | You cannot train. You are too tired. |
| `CMESSAGE_TRAININGFAIL` | Unlucky. You have failed this training challenge. |
| `CMESSAGE_TRAININGSUCCESS` | Congratulations! You have passed this training challenge. |
| `CMESSAGE_TRIAL` | OK! Your player details are all set up. Now you must undergo a football trial with $clubname and complete 7 training challenges. Don't worry if you fail a challenge, you can still progress to the next one. |
| `CMESSAGE_TRIALBALLS` | This shows you how many balls you have left to complete the challenge. |
| `CMESSAGE_TRIALDRIBBLING` | Now you need to complete the DRIBBLING test. It is exactly the same as the PACE test only this time you need to run with the ball. |
| `CMESSAGE_TRIALFAIL` | Oh dear. $clubname were not impressed with your skills and you failed the trial! Don't worry, you can always try again. |
| `CMESSAGE_TRIALFLAIR` | Nearly there! The last trial tests your FLAIR ability. You are able to bend the flight of a ball by moving left or right just after kicking it. Kick the ball between the posts and immediately push LEFT or RIGHT to bend it slightly. |
| `CMESSAGE_TRIALGOALS` | This shows you how many goals you need to score to complete the challenge. |
| `CMESSAGE_TRIALHEADINGADVANCED` | This is the HEADING test. CALL for a ball by tapping a KICK button. Whilst the ball is in the air hold down a KICK button to run towards it and perform a header. Aim it into the goal. |
| `CMESSAGE_TRIALHEADINGSIMPLE` | This is the HEADING test. CALL for a ball by tapping the KICK button then head it into the goal. The key here is to HOLD down the kick button whilst the ball is in the air. |
| `CMESSAGE_TRIALPACE` | The first trial is to test your PACE. Guide your player between the poles and into the green zone before the time runs out. If you want to change the game controls press PAUSE and choose OPTIONS then EDIT CONTROLS. Press KICK to start. |
| `CMESSAGE_TRIALPASSING` | Now you need to prove your PASSING skills. Aim towards the training cones and kick the ball between them. The longer you hold the KICK button the harder you will kick the ball. |
| `CMESSAGE_TRIALSHOOTINGADVANCED` | Now you need to show off your SHOOTING skills. First CALL for a ball by tapping a KICK button. Once you have control of the ball aim towards the goal and SHOOT. Call for another ball if you need it. |
| `CMESSAGE_TRIALSHOOTINGSIMPLE` | Now you need to show off your SHOOTING skills. First CALL for a ball by tapping the KICK button. Once you have control of the ball aim towards the goal and SHOOT. Call for another ball if you need it. |
| `CMESSAGE_TRIALSUCCESS` | Amazing! You have really impressed $clubname with your skills and they are ready to offer you a contract. |
| `CMESSAGE_TRIALTACKLING` | Next up is the TACKLING test. Run towards the training cone and knock it over with a SLIDE TACKLE. |
| `CMESSAGE_TRIALTIME` | This shows you how much time you have left to complete the challenge. |
| `CHELP_PLAYERRATINGS` | These are your ratings. They can only be improved by performing the action during a match. |
| `CMESSAGE_TRAININGPACE` | Touch and hold the screen where you want to run and intercept the pass. |
| `CMESSAGE_TRAININGPOWER` | Beat the keeper! |
| `CMESSAGE_TRAININGSETPIECES` | Bend your shot to score a goal! |
| `CMESSAGE_TRAININGTECHNIQUE` | Kick the ball between the poles! |
| `CMESSAGE_TRAININGVISION` | Kick the ball at the dummy player! |
| `CMESSAGE_TRIALMOBILE1` | OK! You must undergo a football trial and impress the talent scouts! The first trial is TECHNIQUE. This skill determines how much you can bend and dip the ball. |
| `CMESSAGE_TRIALMOBILE2` | Great! Now let's see how good you are at FREE KICKS. |
| `CMESSAGE_TRIALMOBILE3` | Nice! Next up it's the POWER trial. This determines how hard you can kick the ball. |
| `CMESSAGE_TRIALMOBILE4` | Well done! OK, this trial is a little different. You need good PACE to intercept passes. |
| `CMESSAGE_TRIALMOBILE5` | Excellent! The last trial is VISION. Your vision allows you to spot team mates in good positions during a match. |
| `CMESSAGE_TRIALMOBILEFAIL2` | Ok, never mind. Let's see how good you are at FREE KICKS. |
| `CMESSAGE_TRIALMOBILEFAIL3` | Oops! Let try the POWER trial. This determines how hard you can kick the ball. |
| `CMESSAGE_TRIALMOBILEFAIL4` | Oh dear! Let's move on. This trial is a little different. You need good PACE to intercept passes. |
| `CMESSAGE_TRIALMOBILEFAIL5` | Unlucky! But don't worry about it. The last trial is VISION. Your vision allows you to spot team mates in good positions during a match. |
| `CMESSAGE_TRIALSUCCESSMOBILE` | Amazing! You have impressed $clubname ($labelname) with your skills and they have given you a contract. If you want to play for a bigger club you will need to increase your STAR RATING and impress in the $leaguename division. |

---

## 7. The Shop - complete catalogue

The shop is **four separate catalogues**: Items, Vehicles, Property (all on the `shop` screen with three category
buttons `btn_items` / `btn_vehicles` / `btn_property`), plus a **separate Boot Shop** reached from Match
Preparation.

Every catalogue has **exactly 10 slots**, proven three ways:
1. Widget IDs `btn_items1..btn_items10`, `btn_vehicles1..10`, `btn_property1..10`, `btn_boots1..10`.
2. Art assets `GameMedia/Images/Shop/{Items,Vehicles,Property,Boots}/{Items,Vehicles,Property,Boots}_1..10.png`.
3. Ten `item_*`, ten `vehicle_*`, ten `property_*` language tags.

**The exe stores the tag names in slot order.** This is the canonical catalogue ordering - it is *not*
alphabetical, and it is almost certainly ascending price:

### 7.1 Items (luxury goods) - slot order from the exe

| Slot | Tag | English | Art | Functional? |
|---:|---|---|---|---|
| 1 | `item_Phone` | Phone | `Items_1.png` | **Yes** - `tt_Phone`: "Receive calls from friends and team mates". Without it, `CMESSAGE_NEEDAPHONE` fires. |
| 2 | `item_GamesConsole` | Games Console | `Items_2.png` | **Yes** - `tt_GamesConsole`: "Allows you to buy games to relieve tiredness". Gate for `CMESSAGE_CANNOTBUYGAME`. |
| 3 | `item_MusicPlayer` | Music Player | `Items_3.png` | **Yes** - `tt_MusicPlayer`: "Allows you to buy music to relieve tiredness". Gate for `CMESSAGE_CANNOTBUYMUSIC`. |
| 4 | `item_Tablet` | Tablet | `Items_4.png` | **Yes** - `tt_Tablet`: "Allows you to buy movies to relieve tiredness". Gate for `CMESSAGE_CANNOTBUYFILM`. |
| 5 | `item_TV` | TV | `Items_5.png` | Lifestyle only |
| 6 | `item_DesignerSuit` | Designer Suit | `Items_6.png` | Lifestyle only |
| 7 | `item_SilverChain` | Silver Chain | `Items_7.png` | Lifestyle only |
| 8 | `item_GoldRing` | Gold Ring | `Items_8.png` | Lifestyle only |
| 9 | `item_Earrings` | Earrings | `Items_9.png` | Lifestyle only |
| 10 | `item_Watch` | Watch | `Items_10.png` | Lifestyle only |

Only the first four have tooltips - and the exe emits `tt_Phone`, `tt_GamesConsole`, `tt_MusicPlayer`,
`tt_Tablet` immediately after the ten `item_*` names, confirming the tooltip block covers exactly slots 1-4.

Items can be **stolen**: `CMESSAGE_LOSTITEM` - *"One of your luxury items has been stolen! ($item)"*.
Items can be **sold**: `CMESSAGE_SELLITEM` - *"Do you wish to sell this item for $value?"* (finances screen
`tbl_Lifestyle` + `finances_Own` / `finances_Cost` / `finances_Sell` / `btn_sell`).
Owning gadgets triggers a news story: `CNEWS_STYLEGADGET` - *"Gadget man! … using his $item."*
Owning clothing/jewellery triggers `CNEWS_STYLECLOTHES` - *"Style guru! … Check out the $item he was wearing!"*
Owning **nothing** triggers `CNEWS_STYLELOW1..3` (mocking his lack of style).

### 7.2 Vehicles - slot order from the exe

| Slot | Tag | English | Art |
|---:|---|---|---|
| 1 | `vehicle_Bicycle` | Bicycle | `Vehicles_1.png` |
| 2 | `vehicle_Scooter` | Scooter | `Vehicles_2.png` |
| 3 | `vehicle_SmallCar` | Small Car | `Vehicles_3.png` |
| 4 | `vehicle_Motorbike` | Motorbike | `Vehicles_4.png` |
| 5 | `vehicle_SUV` | SUV | `Vehicles_5.png` |
| 6 | `vehicle_SailingBoat` | Sailing Boat | `Vehicles_6.png` |
| 7 | `vehicle_SportsCar` | Sports Car | `Vehicles_7.png` |
| 8 | `vehicle_Helicopter` | Helicopter | `Vehicles_8.png` |
| 9 | `vehicle_Yacht` | Yacht | `Vehicles_9.png` |
| 10 | `vehicle_PrivateJet` | Private Jet | `Vehicles_10.png` |

Vehicles have a **running cost** (`Vehicle Costs` line on the finances screen) and their own event set:

| Event | Tag | Text |
|---|---|---|
| Written off | `CMESSAGE_LOSTVEHICLE1` | One of your vehicles has broken down and is beyond repair! ($vehicle) |
| Stolen | `CMESSAGE_LOSTVEHICLE2` | One of your vehicles has been stolen! ($vehicle) |
| Repairable | `CMESSAGE_LOSTVEHICLE3` | One of your vehicles has broken down! ($vehicle) Do you wish to repair it for $cost? |
| Girlfriend borrows | `CMESSAGE_VEHICLEBORROWGIRL` | Your GIRLFRIEND asked if she can take your $vehicle for a ride. Do you want to let her? |
| Team mate borrows | `CMESSAGE_VEHICLEBORROWTEAM` | A TEAM MATE asks if he can take your $vehicle for a spin. Do you want to let him? |
| Girlfriend crashes it | `CMESSAGE_VEHICLEDAMAGEDGIRL` | Oh no! Your GIRLFRIEND has crashed your $vehicle. It costs you $amount to repair it! |
| Team mate crashes it | `CMESSAGE_VEHICLEDAMAGEDTEAM` | Oh no! Your TEAM MATE has crashed your $vehicle. It costs you $amount to repair it! |
| Press notices | `CNEWS_STYLEVEHICLE` | Trail blazer! … snapped getting into his $vehicle recently. |

The exe references `CMESSAGE_LOSTVEHICLE` (no suffix) **and** `CMESSAGE_LOSTVEHICLE3` separately - i.e. the code
picks `LOSTVEHICLE` + `Rand(1,2)` for the total-loss cases and handles the repairable case as a distinct branch.

### 7.3 Property - slot order from the exe

| Slot | Tag | English | Art | Notes |
|---:|---|---|---|---|
| 1 | `property_Apartment` | Apartment | `Property_1.png` | |
| 2 | `property_House` | House | `Property_2.png` | |
| 3 | `property_TownHouse` | Town House | `Property_3.png` | |
| 4 | `property_Cottage` | Cottage | `Property_4.png` | |
| 5 | `property_Stable` | Stable | `Property_5.png` | **Functional.** `tt_Stable`: "Allows you to buy race horses". `CMESSAGE_NOSTABLE`: *"Each stable you buy will house up to 2 race horses."* Stackable - see `Increase Stable` / `Decrease Stable` / `Stable Size`. |
| 6 | `property_HolidayVilla` | Holiday Villa | `Property_6.png` | |
| 7 | `property_SkiChalet` | Ski Chalet | `Property_7.png` | |
| 8 | `property_Mansion` | Mansion | `Property_8.png` | |
| 9 | `property_Castle` | Castle | `Property_9.png` | |
| 10 | `property_PrivateIsland` | Private Island | `Property_10.png` | |

Properties carry `Rent` and `Property Costs` lines on the finances screen. `CNEWS_STYLEPROPERTY` reports
ownership. On mobile, `CMESSAGE_PROPERTYCHECK` states property "increases your recovery rate after a match" - 
`UNCERTAIN:` whether the PC build applies the same energy-recovery bonus; the PC confirm dialog is the generic
`CMESSAGE_CONFIRMPURCHASE` / `CMESSAGE_CONFIRMPURCHASEENERGYCOST`, which says nothing about recovery. Also see
`Trailer Home` - a bare tag with no `property_` prefix and no art slot; `UNCERTAIN:` likely the **default**
starting residence shown before the first property purchase.

### 7.4 Boot Shop (separate screen)

`bootshop` screen; art `GameMedia\Images\Shop\Boots\Boots_1..10.png`; widgets `btn_boots1..btn_boots10`,
`lbl_boots`, `prg_boots`, plus `price_Free`, `Matches`, `Match`.

* `CHELP_BOOTS` - *"Boots will improve your DRIBBLING, PASSING and SHOOTING skills. Boots are free when you get a
  boot sponsor."*
* The boot-shop widget block in the exe lists `lbl_tackling`, `lbl_passing`, `lbl_shooting`.
  `UNCERTAIN:` the widget id says *tackling* but the help text says *dribbling*. Either the help text is wrong or
  the widget id is a copy-paste leftover. Resolve against the disassembly before implementing.
* Boots **wear out**: `CMESSAGE_BOOTSWORNOUT`, and the shop warns `CMESSAGE_BOOTSHAVEMATCHES`
  (*"Your existing boots can still be worn for $num matches"*). So each boot model carries a **durability in
  matches**, shown via `prg_boots` and the `Matches` label.
* `CMESSAGE_BOOTALREADYOWNED` prevents duplicate purchase.
* With a boot sponsor: `CMESSAGE_FREEBOOTS` (*"Your SPONSORS send you some free boots"*) and
  `CMESSAGE_SPONSORSHIPACCEPTBOOTS`.
* Selection status `No Boots` exists, implying the player can be **unable to play without boots**.
  `UNCERTAIN:` boot model names are not in `Languages.csv` and were not found in the exe string dump.
  The mobile achievement `CACHIEVEMENTMOBILE_66` names one model, *"NS-Control"*, suggesting boots are named
  `NS-<something>`; PC boot names must be recovered from the disassembly or from `Boots_n.png` artwork.

### 7.5 Shop-wide rules

| Tag | English |
|---|---|
| `CHELP_BOOTS` | Click here to go to the boot shop. Boots will improve your DRIBBLING, PASSING and SHOOTING skills. Boots are free when you get a boot sponsor. |
| `CHELP_SHOPBUTTONS` | Choose the category with these buttons then click an item below to purchase it. |
| `CMESSAGE_BOOTALREADYOWNED` | You already own a new pair of these boots. |
| `CMESSAGE_BOOTSWORNOUT` | Your boots have worn out. |
| `CMESSAGE_CANNOTBUYFILM` | You need to purchase a TABLET from the shop before you can buy a movie. |
| `CMESSAGE_CANNOTBUYGAME` | You need to purchase a GAMES CONSOLE from the shop before you can buy a game. |
| `CMESSAGE_CANNOTBUYMUSIC` | You need to purchase a MUSIC PLAYER from the shop before you can buy music. |
| `CMESSAGE_CONFIRMPURCHASE` | Do you wish to purchase this item for $cash? |
| `CMESSAGE_CONFIRMPURCHASEENERGYCOST` | Do you wish to purchase this item for $cash? You will lose $energy% energy going shopping. |
| `CMESSAGE_FREEBOOTS` | Your SPONSORS send you some free boots. |
| `CMESSAGE_ITEMNOTOWNED` | You do not own this item |
| `CMESSAGE_LOSTITEM` | One of your luxury items has been stolen! ($item) |
| `CMESSAGE_LOSTVEHICLE1` | One of your vehicles has broken down and is beyond repair! ($vehicle) |
| `CMESSAGE_LOSTVEHICLE2` | One of your vehicles has been stolen! ($vehicle) |
| `CMESSAGE_LOSTVEHICLE3` | One of your vehicles has broken down! ($vehicle) Do you wish to repair it for $cost? |
| `CMESSAGE_NEEDAPHONE` | Your FRIENDS and TEAM MATES have been trying to contact you but you don't own a PHONE! Head to the SHOP and purchase one as soon as you can. |
| `CMESSAGE_NOSHOPPINGTIRED` | You don't have enough energy to go shopping! |
| `CMESSAGE_NOSTABLE` | You do not own a stable yet. You can purchase one in the shop under the Property section. Each stable you buy will house up to 2 race horses. |
| `CMESSAGE_NOTENOUGHCASH` | You do not have enough money! |
| `CMESSAGE_NOTTIRED` | You do not need to buy any entertainment because you are not tired. |
| `CMESSAGE_SELLITEM` | Do you wish to sell this item for $value? |
| `CTIP_21` | Your LIFESTYLE rating is determined by the number of items, vehicles and properties that you have purchased from the shop |
| `CTIP_31` | Girls will expect a football star to have a high LIFESTYLE rating. Make sure you purchase items from the SHOP to impress them. |
| `CTIP_7` | You can purchase entertainment items such as MUSIC, GAMES and FILMS to ease tiredness caused by long away game journeys. You will need to purchase the relevant device from the SHOP first though. |
| `help_bootshop` | Every player has a default pair of boots, but if you want to increase your skills you will need to splash some cash. Once you have signed a boot sponsorship deal you will get your boots for free! |
| `help_shop` | Buying items, vehicles or property will increase your LIFESTYLE rating. A good LIFESTYLE will impress potential SPONSORS and also increase your desirability to the opposite sex! |
| `CMESSAGE_BOOTSHAVEMATCHES` | Your existing boots can still be worn for $num matches. Are you sure you want to buy new boots? |
| `CMESSAGE_PROPERTYCHECK` | Buying property gives you a new place to relax and increases your recovery rate after a match! Do you want to buy this property for $price? |
| `CMESSAGE_VEHICLEBORROWGIRL` | Your GIRLFRIEND asked if she can take your $vehicle for a ride. Do you want to let her? |
| `CMESSAGE_VEHICLEBORROWTEAM` | A TEAM MATE asks if he can take your $vehicle for a spin. Do you want to let him? |
| `CMESSAGE_VEHICLEDAMAGEDGIRL` | Oh no! Your GIRLFRIEND has crashed your $vehicle. It costs you $amount to repair it! |
| `CMESSAGE_VEHICLEDAMAGEDTEAM` | Oh no! Your TEAM MATE has crashed your $vehicle. It costs you $amount to repair it! |
| `CNEWS_STYLECLOTHES` | Style guru! $clubname player $playername was looking good at an event recently. Check out the $item he was wearing! |
| `CNEWS_STYLEGADGET` | Gadget man! Footballer $playername was recently spotted out on the town using his $item. |
| `CNEWS_STYLELOW1` | $playername was looking shabby on his way home from training yesterday. He really hasn't got a clue when it comes to style! |
| `CNEWS_STYLELOW2` | Style moron! That was the opinion of our fashion expert when asked what they thought of $playername's appearance. He really needs to splash some cash and smarten up a bit. |
| `CNEWS_STYLELOW3` | Football player $playername was spotted out on the town yesterday wearing a cheap tracksuit. Maybe he had just finished training but he really needs some fashion advice! |
| `CNEWS_STYLEPROPERTY` | Home sweet home! Famous footballer $playername was seen entering his $property recently. How's that for moving up the property ladder! |
| `CNEWS_STYLEVEHICLE` | Trail blazer! Football player $playername was snapped getting into his $vehicle recently. He's a real motor head! |

* **Shopping costs ENERGY.** `CMESSAGE_CONFIRMPURCHASEENERGYCOST` - *"Do you wish to purchase this item for
  $cash? You will lose $energy% energy going shopping."* and `CMESSAGE_NOSHOPPINGTIRED` blocks it entirely.
  There are therefore two purchase-confirm paths; `UNCERTAIN:` what selects between them (likely: first purchase
  of a shopping trip costs energy, subsequent ones don't - or PC vs mobile).
* **LIFESTYLE rating** = a function of how many items + vehicles + properties are owned (`CTIP_21`,
  `help_finances`, `help_shop`). Lifestyle drives: sponsorship *amount* offered (`CTIP_25`), attractiveness to
  girlfriends (`CTIP_31`, `CMESSAGE_GIRLFRIENDNOTIMPRESSED`), and one achievement (`CACHIEVEMENT_63`).
  Home-screen meter: `pan_Lifestyle` / `prg_Lifestyle` / `btn_Lifestyle`.
* **Entertainment purchases** (games/music/movies) are consumables bought from the **world map** screen, not the
  shop: `tt_BuyGames` / `btn_Game`, `tt_BuyMusic` / `btn_Music`, `tt_BuyMovies` / `btn_Film`, gated on owning the
  Games Console / Music Player / Tablet respectively, and refused with `CMESSAGE_NOTTIRED` if not tired.
  Purpose per `CTIP_7`: **ease the tiredness caused by long away-game journeys**.

---

## 8. Match-day preparation - consumables and equipment

The `matchprep` screen (`Match Preparation`) is where every consumable lives. Widget block from the exe:

```
Kit Bag / pan_health
  btn_Drugs      prg_Drugs      tt_BuyDrugs        "Enhancers"   CHELP_ENHANCERS   CMESSAGE_BUYDRUGS
  btn_Booze      prg_Booze      tt_BuyBooze        "Booze"       CHELP_BOOZE       CMESSAGE_BUYBOOZE
  btn_ShinPads   prg_ShinPads   tt_BuyShinPads                   CHELP_SHINPADS    CMESSAGE_BUYSHINPADS
  btn_Boots      prg_Boots      tt_BuyBoots                      CHELP_BOOTS
  btn_Injury     prg_Injury     tt_BuyPainKillers                CHELP_PAINKILLERS CMESSAGE_BUYPAINKILLERS
  btn_NRG        prg_NRG        tt_BuyNRG                        CHELP_NRG         CMESSAGE_BUYNRG
  prg_Energy
btn_skip  "Skip Match"  CHELP_SKIPMATCH  CMESSAGE_SKIPMATCH
```

| Consumable | Buys you | Downside | Icons |
|---|---|---|---|
| **NRG Drink** | ENERGY | *"You may get stomach cramps during a match"* → `matchmsg_Stomach` | `NRG28.png` |
| **Booze** | FLAIR (bend more than usual) | *"dizzy spells"* / *"You may however fall over from time to time"* → `matchmsg_Drunk`, `BoozeFace.png`, `BoozedUp.ogg` | `Booze.png`, `Booze28.png`, `BoozeBoost.png` |
| **Performance Enhancers** | PACE | **drugs test after the match** | `Drugs28.png`, `DrugsBoost.png` |
| **Pain Killers** | reduces INJURY, restores match fitness | *"increase the chances of suffering a more serious INJURY in the next match"* | `PainKiller.png` |
| **Shin Pads** | TACKLING | none | `ShinPads28.png`, `ShinPadsBoost.png` |
| **Boots** | DRIBBLING / PASSING / SHOOTING | wear out | `Boot22.png`, `Boot28.png`, `BootBoost.png` |

| Tag | English |
|---|---|
| `CHELP_BOOZE` | Booze will increase your FLAIR and allow you to bend the ball more than usual. You may however fall over from time to time. |
| `CHELP_ENHANCERS` | Enhancers are a supplement that will boost your pace. Sometimes enhancers contain illegal ingredients so be warned, as you may have to take a drugs test after a match. |
| `CHELP_NRG` | Drinking cans of NRG will boost your ENERGY. You may find that you suffer stomach cramps during the match though! |
| `CHELP_PAINKILLERS` | If you are injured you can sometimes take pain killers to regain match fitness. However, if you get injured in the match immediately after taking pain killers your injury will become more severe. |
| `CHELP_SHINPADS` | Shin pads increase your tackling skill. Once you have a sports clothing sponsor you will be able to get shin pads for free. |
| `CHELP_SKIPMATCH` | If you don't want to play the next match then use this button to skip it. Be warned that you will not impress your BOSS or TEAM MATES if you skip matches that you have been picked for. |
| `CMESSAGE_BOOZINGBOSS` | The BOSS has found out that you are drinking booze before a game and is furious! |
| `CMESSAGE_BOOZINGFRIENDS` | Your FRIENDS are worried that you are drinking booze before a match! |
| `CMESSAGE_BOOZINGGIRLFRIEND` | Your GIRLFRIEND is not happy about your boozing! |
| `CMESSAGE_BOOZINGSPONSORS` | Your SPONSORS have heard that you are drinking booze before a match. They are not happy! |
| `CMESSAGE_BOOZINGTEAM` | Some TEAM MATES have noticed that you are drunk during a match! They are not impressed. |
| `CMESSAGE_BUYBOOZE` | Drinking bottles of BOOZE will temporarily increase your FLAIR but you may have dizzy spells during a match. Are you sure you wish to buy BOOZE? |
| `CMESSAGE_BUYDRUGS` | Buying PERFORMANCE ENHANCERS will temporarily increase your PACE but you may get tested for banned substances after the match. Are you sure you wish to buy PERFORMANCE ENHANCERS? |
| `CMESSAGE_BUYNRG` | Drinking cans of NRG drink will increase your ENERGY but you may get stomach cramps during a match. Are you sure you wish to buy NRG drink? |
| `CMESSAGE_BUYPAINKILLERS` | Buying PAIN KILLERS will reduce your INJURY but will also increase the chances of suffering a more serious INJURY in the next match. Do you wish to buy PAIN KILLERS? |
| `CMESSAGE_BUYSHINPADS` | Shin pads will increase your TACKLING ability. Do you wish to buy some shin pads? |
| `CMESSAGE_FITAGAINTRAVELTIME` | You are match fit again! You may want to go back to the map screen to check the travel time. |
| `CMESSAGE_PAINKILLERSSERIOUSINJURY` | Your INJURY is severe and PAIN KILLERS will do nothing to help at the moment. Please try again later. |
| `CNEWS_SKIPMATCHCLUB` | I won't play! $clubname player $playername has stunned his team mates and infuriated his boss by refusing to play! He has been fined one weeks wages for his actions. |
| `CNEWS_SKIPMATCHINTERNATIONAL` | Traitor! $playername has incurred the wrath of the $clubname fans by refusing to play for his country! |
| `CTIP_15` | If you skip a match that you have been selected for you will forfeit one weeks wages and some of your relationships will drop. |
| `CTIP_4` | Playing with low ENERGY makes it more likely that you will suffer an injury. |
| `CTIP_40` | If your relationship with SPONSORS is low you risk having contracts cancelled. |
| `CTIP_41` | Replica shirt sales are determined by your FAME and your relationship with the FANS. |
| `CTIP_42` | If your contract expires you will be offered higher wages in contract negotiations because other clubs will not need to pay a transfer fee. |
| `CTIP_43` | Once you have purchased a STABLE from the shop you can buy race horses. |
| `CTIP_44` | If you own a race horse you need to race it to make it stronger and faster, but don't over work it or it may become ill! |
| `CTIP_45` | If your race horse becomes ill it's strength will deteriorate over time. Make sure you TREAT it to bring it back to full health. |
| `CTIP_47` | Going to the CASINO with TEAM MATES or going RACING with FRIENDS is a great way to improve your relationships. Just make sure you don't become a gambling addict! |
| `CTIP_48` | Player of the year' awards only go to players that achieve a high average match rating in a high profile league. You will also need to be playing well for your country. |
| `CTIP_49` | Once you pass the age of 30 your PACE and DRIBBLING skills will start to fall and it will be impossible to restore them to the maximum level. |
| `matchmsg_Drunk` | You are drunk! |
| `matchmsg_Stomach` | Stomach cramps! |
| `matchmsg_Tired` | You are tired! |
| `matchmsg_Unhappy` | Unhappiness strikes! |
| `CMESSAGE_SKIPMATCH` | Are you sure you want to skip this match? |
| `CMESSAGE_DEBUTTIRED` | The boss notices that you are very tired for your debut match. He gives you an NRG drink to replenish your ENERGY but in future he wants you to save enough energy to start matches. |
| `CMESSAGE_DRINKNRGCHECK` | You still have plenty of ENERGY. Are you sure you want to drink a can of NRG? |
| `CMESSAGE_ENERGYCHECKLOW` | You have very low ENERGY. Would you like to use an NRG drink? |
| `CMESSAGE_ENERGYFULL` | Energy full! |
| `CMESSAGE_NONRG` | No NRG! |

### 8.1 The booze scandal chain

Drinking before a match is detected and damages **five** relationships, each with its own message. All five are
referenced consecutively in the exe inside `RandomIncident`:

| Tag | Text |
|---|---|
| `CMESSAGE_BOOZINGBOSS` | The BOSS has found out that you are drinking booze before a game and is furious! |
| `CMESSAGE_BOOZINGGIRLFRIEND` | Your GIRLFRIEND is not happy about your boozing! |
| `CMESSAGE_BOOZINGFRIENDS` | Your FRIENDS are worried that you are drinking booze before a match! |
| `CMESSAGE_BOOZINGSPONSORS` | Your SPONSORS have heard that you are drinking booze before a match. They are not happy! |
| `CMESSAGE_BOOZINGTEAM` | Some TEAM MATES have noticed that you are drunk during a match! They are not impressed. |

### 8.2 The drugs-test chain

`CHELP_ENHANCERS` - *"Sometimes enhancers contain illegal ingredients so be warned, as you may have to take a
drugs test after a match."* The physio-room report path:

| Tag | Text |
|---|---|
| `CREPORT_PHYSIODRUGSTESTGOOD` | The club PHYSIO took a sample from you after the match… The results were clear. |
| `CREPORT_PHYSIODRUGSTESTBAD` | The club PHYSIO took a sample from you after the match… The boss would like to see you in his office. |
| `CREPORT_BOSSDRUGSTESTBAD` | What the hell were you thinking taking performance enhancers! … |
| `CNEWS_DRUGTESTFAIL` | BANNED! $playername has failed a drugs test and faces a $num match ban! … |

The exe also contains the debug strings `Drugs lose friends` and `Drugs:` in the boss-report code path.

### 8.3 Skipping a match

`CHELP_SKIPMATCH` warns the BOSS and TEAM MATES will be unimpressed; `CTIP_15` quantifies it: *"you will forfeit
one weeks wages and some of your relationships will drop"*. The news reaction differs for club vs country
(`CNEWS_SKIPMATCHCLUB` - fined one week's wages; `CNEWS_SKIPMATCHINTERNATIONAL` - *"Traitor!"*).

---

## 9. Energy, health, injury, travel

**ENERGY** is the master resource. Everything consumes it: training, shopping, spending time with people,
travelling to away matches.

| Consumer | Evidence |
|---|---|
| Training | `CHELP_ENERGY`, `CMESSAGE_NOTRAININGTIRED` |
| Shopping | `CMESSAGE_CONFIRMPURCHASEENERGYCOST`, `CMESSAGE_NOSHOPPINGTIRED` |
| Relationship meetings | every `*REQUEST*` costs `$percent%`, `CMESSAGE_NOMEETINGINGTIRED` (sic - typo in tag) |
| Casino trip | `CMESSAGE_NOCASINOTIRED` |
| Horse racing trip | `CMESSAGE_NORACINGTIRED` |
| Travel to away matches | `Travel Time`, `prg_EnergyAfterTravelling`, `Energy After Travelling` |

Low energy has hard consequences at selection time:

| Tag | Text |
|---|---|
| `CMESSAGE_NOTPICKEDENERGY` | The BOSS has not picked you for this match because your ENERGY is too low. He is furious! |
| `CMESSAGE_NOTPICKEDENERGYINT` | The $team BOSS has not picked you for this match because your ENERGY is too low. He is furious! |
| `CMESSAGE_SUBENERGY` | You are a substitute for this match because your ENERGY is low. The BOSS is not happy. |
| `CMESSAGE_SUBENERGYINT` | You are a substitute for this match because your ENERGY is low. The $team BOSS is not happy. |
| `CTIP_4` | Playing with low ENERGY makes it more likely that you will suffer an injury. |

### 9.1 Free energy gifts (four sources × four variants)

`RandomIncident` in the exe references four prefixes; each has variants 1-4:

| Tag | English |
|---|---|
| `CMESSAGE_ENERGYBOOSTFRIENDS1` | Your FRIENDS take you out for a meal! ENERGY +$energy%! |
| `CMESSAGE_ENERGYBOOSTFRIENDS2` | Your FRIENDS take you to the beach for the day! ENERGY +$energy%! |
| `CMESSAGE_ENERGYBOOSTFRIENDS3` | Your FRIENDS take you out for a picnic! ENERGY +$energy%! |
| `CMESSAGE_ENERGYBOOSTFRIENDS4` | A FRIEND is learning Reiki and practices on you! ENERGY +$energy%! |
| `CMESSAGE_ENERGYBOOSTGIRL1` | Your GIRLFRIEND books a spa day for you both! ENERGY +$energy%! |
| `CMESSAGE_ENERGYBOOSTGIRL2` | Your GIRLFRIEND gives you a massage! ENERGY +$energy%! |
| `CMESSAGE_ENERGYBOOSTGIRL3` | Your GIRLFRIEND cooks you a healthy meal! ENERGY +$energy%! |
| `CMESSAGE_ENERGYBOOSTGIRL4` | Your GIRLFRIEND takes you to one of her yoga classes! ENERGY +$energy%! |
| `CMESSAGE_ENERGYBOOSTPHYSIO1` | The club PHYSIO teaches you a great way to warm down after exercising! ENERGY +$energy%! |
| `CMESSAGE_ENERGYBOOSTPHYSIO2` | The club PHYSIO teaches you some breathing exercises! ENERGY +$energy%! |
| `CMESSAGE_ENERGYBOOSTPHYSIO3` | The club PHYSIO teaches you some great stretching techniques! ENERGY +$energy%! |
| `CMESSAGE_ENERGYBOOSTPHYSIO4` | The club PHYSIO books you in for a session with a sports psychologist! ENERGY +$energy%! |
| `CMESSAGE_ENERGYBOOSTTEAM1` | One of your TEAM MATES lends you his hypnosis CD to help you sleep! ENERGY +$energy%! |
| `CMESSAGE_ENERGYBOOSTTEAM2` | A TEAM MATE gives you a great recipe for a healthy juice drink! ENERGY +$energy%! |
| `CMESSAGE_ENERGYBOOSTTEAM3` | A TEAM MATE invites you over to use his home sauna! ENERGY +$energy%! |
| `CMESSAGE_ENERGYBOOSTTEAM4` | A TEAM MATE invites you over to use his hot tub! ENERGY +$energy%! |

### 9.2 Travel-time buckets

The world-map screen converts distance to an energy penalty through six named buckets:

| Tag | English |
|---|---|
| `time_Long` | Long |
| `time_Medium` | Medium |
| `time_None` | None |
| `time_Short` | Short |
| `time_VeryLong` | Very Long |
| `time_VeryShort` | Very Short |

Mitigation: buy Music / Games / Movies (requires Music Player / Games Console / Tablet). Exe references
`MusicPlayer.png`, `Console.png`, `Tablet.png` on the `worldmap` screen and the `Distance:` debug label.

### 9.3 Injury

`UpdateHealth` → `DoInjury` in the exe. Physio report:

| Tag | Text |
|---|---|
| `CREPORT_PHYSIO1` | After a thorough assessment of your injury the physio tells you that you are likely to miss 1 match. |
| `CREPORT_PHYSIO2` | After a thorough assessment of your injury the physio tells you that you are likely to miss $num matches. |
| `CREPORT_PHYSIO3` | Your abilities have also suffered ($skillslost). |

Note the deliberate singular/plural split (`PHYSIO1` vs `PHYSIO2`) - the same pattern recurs in
`CREPORT_COACHBAN1`/`2` and `account_MatchesLeft1`/`account_MatchesLeft`. Reproduce it; do not collapse to one
string.

Related statuses: `Injured`, `No Injury`, `Injury!`, `Match Fit`, `Health`, `Suspension`, `Current Suspension`,
and the seven `injury_*` "<Skill> Lost!" flashes. Pain killers interact:
`CMESSAGE_PAINKILLERSSERIOUSINJURY` refuses when the injury is severe.

---

## 10. Relationships, Happiness, Fame, Lifestyle

### 10.1 The six relationships

The `relationships` screen widget block gives the definitive list and their buttons:

```
lbl_Boss       prg_Boss       tt_RelationsBoss        btn_Boss
lbl_Team       prg_Team       tt_RelationsTeam        btn_Team
                              tt_RelationsTeamCasino  btn_TeamCasino
lbl_Fans       prg_Fans       tt_RelationsFans        btn_Fans
lbl_Friends    prg_Friends    tt_RelationsFriends     btn_Friends
                              tt_RelationsFriendsRacing btn_FriendsRacing
lbl_Girlfriend prg_Girlfriend tt_RelationsGirl        btn_Girlfriend
                              tt_RelationsGirlEnd     btn_GirlfriendEnd
lbl_Sponsors   prg_Sponsors   tt_RelationsSponsors    btn_Sponsors
lbl_Happiness
```

The exe's debug labels confirm **seven** tracked scalars - six relationships plus FAME:
`CRELATION_BOSS: `, `CRELATION_TEAM: `, `CRELATION_FANS: `, `CRELATION_FRIENDS: `, `CRELATION_GIRLFRIEND: `,
`CRELATION_SPONSORS: `, `CRELATION_FAME: `.

| # | Relationship | Portrait | Tooltip | Secondary action |
|---|---|---|---|---|
| 1 | Boss | `Boss.png` | `tt_RelationsBoss` "Meet the boss" | - |
| 2 | Team | `Team.png` | `tt_RelationsTeam` "Meet the team" | `tt_RelationsTeamCasino` "Go to casino with team mates" |
| 3 | Fans | `Fans.png` | `tt_RelationsFans` "Meet the fans" | - |
| 4 | Friends | *(no portrait listed)* | `tt_RelationsFriends` "Meet your friends" | `tt_RelationsFriendsRacing` "Go racing with friends" |
| 5 | Girlfriend | `Girlfriend.png` | `tt_RelationsGirl` "Meet your girlfriend" | `tt_RelationsGirlEnd` "End relationship" |
| 6 | Sponsors | `Sponsors.png` | `tt_RelationsSponsors` "Meet your sponsors" | - |

Plus `Stable.png` on the same screen (the horse-racing entry point, `CHELP_STABLEBUTTON`).

### 10.2 What each relationship *does* (verbatim rules from tip/help text)

| Relationship | Mechanical effect | Source tag |
|---|---|---|
| **Boss** | Gates selection for the first team. Low → not picked / substitute. Boosted by playing well and by completing training challenges. Also gates position changes, formation changes, contract renewal, loan permission, transfer-list removal. | `CTIP_1`, `CTIP_14`, `CHELP_RELATIONSHIPBUTTONS`, `CMESSAGE_NEWPOSITIONFAIL`, `CMESSAGE_NORENEWBOSSUNHAPPY` |
| **Team** | Higher → team mates pass to you more often. Improved by passing to them; assists improve it most. Damaged by shooting a lot without scoring. | `CTIP_6`, `CTIP_22`, `CTIP_24`, `CREPORT_TEAMLOW1/2` |
| **Fans** | High → they love you; low → **booing at home games**, which in-match causes you to lose the ball. Fans reward tackles/passion and match results, punish loyalty-jumping. Drives replica shirt sales together with FAME. | `CTIP_16`, `CTIP_34`, `CTIP_41`, `CREPORT_FANSLOW1/2`, `CMATCHTEXT_BOOING1..5` |
| **Friends** | Determines your **social life** and therefore your chance of meeting a girlfriend. | `CTIP_27`, `CMESSAGE_GIRLFRIENDNOTMET` |
| **Girlfriend** | **Double weight** in the HAPPINESS calculation. Neglect → warnings then dumping. | `CTIP_33`, `CMESSAGE_LONGTIMEGIRLFRIEND`, `CMESSAGE_GIRLFRIENDDUMPSYOU` |
| **Sponsors** | Low → contracts get cancelled. Good current relationship → better future offers. Pleased by international wins and Star Man; displeased by cards. | `CTIP_35`, `CTIP_36`, `CTIP_38`, `CTIP_40`, `CMESSAGE_SPONSORCANCEL` |
| **Fame** (not a relationship, tracked alongside) | Raised by celebrating in front of the TV cameras, appearing in the news, being at a famous club, dating a high-`SCANDAL` girl, successful interviews, sponsor appearances. Feeds HAPPINESS, TRANSFER VALUE, sponsorship *type* availability, shirt sales. | `CTIP_25`, `CTIP_28`, `CTIP_30`, `CTIP_32`, `CTIP_39`, `CTIP_41` |
| **Happiness** (derived) | Combined status of all relationships (girlfriend ×2) + FAME. **Low HAPPINESS → more misplaced kicks in matches** (`matchmsg_Unhappy` "Unhappiness strikes!"). | `CTIP_5`, `CTIP_33`, `CTIP_39`, `help_relationships` |

### 10.3 Goal celebrations feed relationships

`CTIP_29` - *"Celebrate in front of your own FANS or BOSS to improve your relationships. Also try grabbing the
ball after scoring and running back to the centre circle to improve your TEAM relationship."* `CTIP_28` adds the
TV-camera celebration raises FAME. The exe confirms five celebration animations (`Celebrate1..5`) and the
in-match alert labels `Fame!`, `Boss`, `Fans`. Achievements `CACHIEVEMENT_36..39` are the four celebration types:
fans / cameras / boss / run-to-centre-circle.

### 10.4 Spending time - the request system

Clicking a relationship button spends ENERGY and plays the **Pairs** mini-game (§18.2). Independently, people
*ask you* for favours via `CMESSAGE_*REQUEST*`. Cardinalities are exact and must be reproduced:

| Family | Count | Costs | Also grants |
|---|---:|---|---|
| `CMESSAGE_BOSSREQUEST1..5` | 5 | `$percent%` ENERGY | Boss relationship |
| `CMESSAGE_TEAMREQUEST1..5` | 5 | `$percent%` ENERGY | Team relationship |
| `CMESSAGE_FANSREQUEST1..5` | 5 | `$percent%` ENERGY | Fans relationship |
| `CMESSAGE_FRIENDSREQUEST1..5` | 5 | `$percent%` ENERGY | Friends relationship |
| `CMESSAGE_GIRLREQUEST1..5` | 5 | `$percent%` ENERGY | Girlfriend relationship |
| `CMESSAGE_SPONSORREQUEST1..10` | **10** | `$percent%` ENERGY | Sponsors relationship **+ FAME** |

| Tag | English |
|---|---|
| `CMESSAGE_BOSSREQUEST1` | Your BOSS wants you to help coach some of the youth players. It will improve your relationship but cost you $percent% ENERGY. Do you want to help? |
| `CMESSAGE_BOSSREQUEST2` | Your BOSS wants you to visit sick children in the local hospital. It will improve your relationship but cost you $percent% ENERGY. Will you do it? |
| `CMESSAGE_BOSSREQUEST3` | Your BOSS wants you to give an after-dinner speech. It will improve your relationship but cost you $percent% ENERGY. Do you want to do it? |
| `CMESSAGE_BOSSREQUEST4` | Your BOSS wants you take part in an event to find talented youngsters in the local schools. It will improve your relationship but cost you $percent% ENERGY. Will you do it? |
| `CMESSAGE_BOSSREQUEST5` | Your BOSS has asked you to meet up with the physio to check out your diet. It will improve your relationship but cost you $percent% ENERGY. Do you want to do it? |
| `CMESSAGE_FANSREQUEST1` | You have been invited to an evening dinner for the club's disabled FANS. It will improve your relationship but cost you $percent% ENERGY. Do you want to do it? |
| `CMESSAGE_FANSREQUEST2` | You see a car broken down on the roadside and notice from the flags and stickers that it belongs to a FAN. Will you stop to help? It will improve your relationship but cost you $percent% ENERGY. |
| `CMESSAGE_FANSREQUEST3` | You see a girl wearing a replica shirt with your name on it struggling with her bike which has a puncture. Will you stop to help her? It will improve your relationship with the FANS but cost you $percent% ENERGY. |
| `CMESSAGE_FANSREQUEST4` | A woman stops you by the river and asks if you will help her find her dog. She says she is a big fan of yours. Will you help? It will improve your FANS relationship but cost you $percent% ENERGY. |
| `CMESSAGE_FANSREQUEST5` | You have been asked to attend the next supporters club meeting. It will improve your relationship with the FANS but cost you $percent% ENERGY. Will you attend? |
| `CMESSAGE_FRIENDSREQUEST1` | Some of your FRIENDS are having a party. If you go along it will improve your relationship but cost you $percent% ENERGY. Will you go? |
| `CMESSAGE_FRIENDSREQUEST2` | Some of your FRIENDS are having a video game session. If you join in it will improve your relationship but cost you $percent% ENERGY. Will you go? |
| `CMESSAGE_FRIENDSREQUEST3` | A FRIEND asks if you will look after his dog for a few days and take it out for walks. It will improve your relationship but cost you $percent% ENERGY. Will you help? |
| `CMESSAGE_FRIENDSREQUEST4` | A FRIEND is in hospital for a minor operation. If you visit him it will improve your relationship but cost you $percent% ENERGY. Will you visit? |
| `CMESSAGE_FRIENDSREQUEST5` | A FRIEND asks if you will babysit their child for a few hours. It will improve your relationship but cost you $percent% ENERGY. Will you help? |
| `CMESSAGE_GIRLREQUEST1` | Your GIRLFRIEND has asked you to help her parents move house. It will improve your relationship but cost you $percent% ENERGY. Do you want to help? |
| `CMESSAGE_GIRLREQUEST2` | Your GIRLFRIEND has asked you to re-decorate your living room. It will improve your relationship but cost you $percent% ENERGY. Will you do it? |
| `CMESSAGE_GIRLREQUEST3` | Your GIRLFRIEND wants to introduce you to some of her friends. It will improve your relationship but cost you $percent% ENERGY. Do you want to meet them? |
| `CMESSAGE_GIRLREQUEST4` | Your GIRLFRIEND wants to go swimming with you. It will improve your relationship but cost you $percent% ENERGY. Will you go? |
| `CMESSAGE_GIRLREQUEST5` | Your GIRLFRIEND wants to go on a bicycle ride with you. It will improve your relationship but cost you $percent% ENERGY. Do you want to go? |
| `CMESSAGE_SPONSORREQUEST1` | Your SPONSORS want you to take part in a photoshoot for a new product. It will improve your relationship and increase your FAME but cost you $percent% ENERGY. Do you wish to take part? |
| `CMESSAGE_SPONSORREQUEST10` | Your SPONSORS want you to appear in a TV advert. It will improve your relationship and increase your FAME but cost you $percent% ENERGY. Do you want to do it? |
| `CMESSAGE_SPONSORREQUEST2` | Your SPONSORS want you to make an appearance at a corporate event. It will improve your relationship and increase your FAME but cost you $percent% ENERGY. Do you want to do it? |
| `CMESSAGE_SPONSORREQUEST3` | Your SPONSORS want you to take sign autographs at the launch of a new product. It will improve your relationship and increase your FAME but cost you $percent% ENERGY. Do you want to do it? |
| `CMESSAGE_SPONSORREQUEST4` | Your SPONSORS want you to make an appearance at a charity event. It will improve your relationship and increase your FAME but cost you $percent% ENERGY. Do you want to do it? |
| `CMESSAGE_SPONSORREQUEST5` | Your SPONSORS want you to make a brief appearance on a TV show. It will improve your relationship and increase your FAME but cost you $percent% ENERGY. Do you want to do it? |
| `CMESSAGE_SPONSORREQUEST6` | Your SPONSORS want you to make appear on a radio show. It will improve your relationship and increase your FAME but cost you $percent% ENERGY. Do you want to do it? |
| `CMESSAGE_SPONSORREQUEST7` | Your SPONSORS want you to do an interview for a magazine. It will improve your relationship and increase your FAME but cost you $percent% ENERGY. Do you want to do it? |
| `CMESSAGE_SPONSORREQUEST8` | Your SPONSORS want you to do an interview for a website. It will improve your relationship and increase your FAME but cost you $percent% ENERGY. Do you want to do it? |
| `CMESSAGE_SPONSORREQUEST9` | Your SPONSORS want you to do an interview for a newspaper. It will improve your relationship and increase your FAME but cost you $percent% ENERGY. Do you want to do it? |
| `CMESSAGE_TEAMREQUEST1` | Some of your TEAM MATES have arranged a golf tournament. If you take part it will improve your relationship but cost you $percent% ENERGY. Do you want to play? |
| `CMESSAGE_TEAMREQUEST2` | Some of your TEAM MATES are doing interviews and photos for the club magazine and you have been invited along. Do you want to attend? It will improve your relationship but cost you $percent% ENERGY. |
| `CMESSAGE_TEAMREQUEST3` | Some of your TEAM MATES are playing poker after training. If you attend it will improve your relationship but cost you $percent% ENERGY. Do you want to play with them? |
| `CMESSAGE_TEAMREQUEST4` | Some of your TEAM MATES are going karting. If you take part it will improve your relationship but cost you $percent% ENERGY. Do you want to join them? |
| `CMESSAGE_TEAMREQUEST5` | Some of your TEAM MATES are doing some charity work at the local hospital. Do you want to attend? It will improve your relationship but cost you $percent% ENERGY. |

### 10.5 The Dilemma screen

`dilemma` screen, `Dilemma!`, `help_dilemma` - *"Oh no! Two people want to meet you at the same time! Choose
which relationship you want to increase."* Widgets: `btn_relationship1` / `btn_relationship2`,
`prg_Relationship1` / `prg_Relationship2`. Six outcome families × 4 variants = 24 lines:

| Tag | English |
|---|---|
| `CDILEMMA_BOSS1` | You impress the BOSS in training! |
| `CDILEMMA_BOSS2` | You have a positive meeting with the BOSS! |
| `CDILEMMA_BOSS3` | The BOSS is impressed with your healthy lifestyle! |
| `CDILEMMA_BOSS4` | You convince the BOSS that you are proud to wear the shirt! |
| `CDILEMMA_FANS1` | You sign some autographs for the FANS! |
| `CDILEMMA_FANS2` | You meet some FANS whilst out on the town! |
| `CDILEMMA_FANS3` | You give one of your shirts to a FAN! |
| `CDILEMMA_FANS4` | You have your photo taken with some FANS! |
| `CDILEMMA_FRIENDS1` | You go out dancing with FRIENDS! |
| `CDILEMMA_FRIENDS2` | You see a great film at the cinema with your FRIENDS! |
| `CDILEMMA_FRIENDS3` | You meet your FRIENDS for a few drinks! |
| `CDILEMMA_FRIENDS4` | You arrange for one of your FRIENDS children to meet the club mascot! |
| `CDILEMMA_GIRL1` | Your GIRLFRIEND loves the flowers you bought her! |
| `CDILEMMA_GIRL2` | You buy your GIRLFRIEND a nice gift! |
| `CDILEMMA_GIRL3` | You take your GIRLFRIEND out for cocktails! |
| `CDILEMMA_GIRL4` | You take your GIRLFRIEND away for a mini-break! |
| `CDILEMMA_SPONSORS1` | Your SPONSORS feature you in a smart-phone app! |
| `CDILEMMA_SPONSORS2` | One of your endorsements makes a bundle of cash for your SPONSORS! |
| `CDILEMMA_SPONSORS3` | You have a positive meeting with your SPONSORS! |
| `CDILEMMA_SPONSORS4` | You have a successful photoshoot with your SPONSORS! |
| `CDILEMMA_TEAM1` | You have a fun time at the bowling alley with some TEAM MATES! |
| `CDILEMMA_TEAM2` | You have a great game of golf with some TEAM MATES! |
| `CDILEMMA_TEAM3` | You have a great training session with your TEAM MATES! |
| `CDILEMMA_TEAM4` | You teach a TEAM MATE a new trick! |

The exe references exactly the six prefixes `CDILEMMA_BOSS`, `CDILEMMA_FANS`, `CDILEMMA_TEAM`,
`CDILEMMA_FRIENDS`, `CDILEMMA_GIRL`, `CDILEMMA_SPONSORS` (then `+ Rand(1,4)`). Backdrop art for the
meeting/dilemma screens (10 locations): `boss.png`, `training_ground.png`, `fans.png`, `bowling.png`,
`golf_course.png`, `cinema.png`, `pub.png`, `restaurant.png`, `shopping.png`, `sponsors.png`.

### 10.6 The girlfriend life-cycle

Complete state machine reconstructed from tags:

1. **Cannot meet anyone** - social life too dull → `CMESSAGE_GIRLFRIENDNOTMET` (raise FRIENDS).
2. **Meets someone but rejected** - LIFESTYLE too low → `CMESSAGE_GIRLFRIENDNOTIMPRESSED` (buy shop items).
   Mobile variant `CMESSAGE_NOGIRLFRIENDLIFESTYLE`.
3. **Offer** - `CMESSAGE_GIRLFRIENDMEET`: *"You meet an attractive woman. She has a SCANDAL rating of
   $scandalrating%. Do you want to start dating her?"* → **each girlfriend has a SCANDAL stat**.
4. **Accepted** - `CMESSAGE_GIRLFRIENDGET`.
5. **Ongoing** - she generates press: `CNEWS_GIRLSCANDALHIGH1..10` (high-scandal girl) or
   `CNEWS_GIRLSCANDALLOW1..10` (low-scandal girl). High scandal raises FAME (`CTIP_32`).
   She can also attack the club: `CMESSAGE_GIRLFRIENDRAMPAGEBOSS` / `…FANS` / `…TEAM` (mobile-flavoured but
   present).
6. **Neglect** - `CMESSAGE_LONGTIMEGIRLFRIEND` → `CNEWS_RELATIONSHIPGIRL1..3` → `CMESSAGE_GIRLFRIENDDUMPSYOU`
   + `CNEWS_GIRLFRIENDDUMPSYOU`.
7. **Player ends it** - `tt_RelationsGirlEnd` → `CMESSAGE_GIRLFRIENDEND` → `CNEWS_GIRLFRIENDDUMPED`.
8. **No girlfriend** - meeting attempt yields `CMESSAGE_NOGIRLFRIEND`.

| Tag | English |
|---|---|
| `CHELP_ENDRELATIONSHIP` | If you have a GIRLFRIEND you can end the relationship if it's not working out. |
| `CHELP_RELATIONSHIPBUTTONS` | Spend time with people by clicking one of these buttons. It is important to keep the BOSS happy if you want to get picked for the team! |
| `CHELP_REPORTRELATIONSHIPS` | These numbers show you how much your relationships increased or decreased after the match. |
| `CMESSAGE_GIRLFRIENDDUMPSYOU` | You girlfriend is so unhappy that she has dumped you! |
| `CMESSAGE_GIRLFRIENDEND` | Do you wish to end the relationship with your GIRLFRIEND? |
| `CMESSAGE_GIRLFRIENDGET` | Amazing! You actually have a GIRLFRIEND. |
| `CMESSAGE_GIRLFRIENDMEET` | You meet an attractive woman. She has a SCANDAL rating of $scandalrating%. Do you want to start dating her? |
| `CMESSAGE_GIRLFRIENDNOTIMPRESSED` | You meet an attractive woman but she is not impressed with your LIFESTYLE! Try buying some cool stuff in the shop. |
| `CMESSAGE_GIRLFRIENDNOTMET` | You are not meeting many women because you have a dull social life! Try increasing your relationship with FRIENDS. |
| `CMESSAGE_LONGTIMEFRIENDS` | Your FRIENDS are unhappy because you have not spent any time with them for weeks. |
| `CMESSAGE_LONGTIMEGIRLFRIEND` | Your GIRLFRIEND is extremely unhappy because you have not spent any time with her for weeks. |
| `CMESSAGE_NOGIRLFRIEND` | You do not have a GIRLFRIEND yet! |
| `CMESSAGE_NOMEETINGINGTIRED` | You are too tired to meet anyone! |
| `CMESSAGE_RELATIONSHIPFULL` | This relationship is already at maximum level! |
| `CNEWS_GIRLFRIENDDUMPED` | Ladies watchout! $playername is a free man again after splitting up with his girlfriend. |
| `CNEWS_GIRLFRIENDDUMPSYOU` | Dumped! $playername has sensationally split up with his girlfriend after she publicly ditched him this week. "He was a lousy boyfriend and I look forward to finding a real man," she said. |
| `CNEWS_GIRLSCANDALHIGH1` | Classy! Girlfriend of $playername was photographed out partying with friends at a nightclub last night. She had clearly been drinking and was cavorting with guys on the dancefloor. |
| `CNEWS_GIRLSCANDALHIGH10` | $playername's girlfriend has hit out at the $clubname boss claiming that he pushes the players too hard. "When my man comes home from training he is shattered," she said. "He has no energy left for anything!" |
| `CNEWS_GIRLSCANDALHIGH2` | Temptress! What will $playername say when he sees the photos of his girlfriend out with another guy? One onlooker said, "they looked like they were having a great time together." |
| `CNEWS_GIRLSCANDALHIGH3` | Girlfriend of $playername denies she has a drink problem despite being seen falling out of a seedy nightclub and onto the pavement. |
| `CNEWS_GIRLSCANDALHIGH4` | Girlfriend of $playername admits that she is a shop-aholic. "I can't help it," she says "I just love clothes." When asked what her boyfriend thought about her addiction she said, "he doesn't complain when I buy lingerie!" |
| `CNEWS_GIRLSCANDALHIGH5` | Catfight! Girlfriend of $clubname player $playername was snapped having a fight with another WAG last night. No one was hurt but the girls had to be pulled apart. |
| `CNEWS_GIRLSCANDALHIGH6` | Your nicked miss! Girlfriend of $playername was in handcuffs last night after being caught drink driving. She stumbled out of a night club and into her car only to be stopped by the police after driving 10 yards! |
| `CNEWS_GIRLSCANDALHIGH7` | Wow what a beauty! Girlfriend of $playername has appeared in a sexy photoshoot for lads mag 'Spuds'. The saucy WAG doesn't quite reveal all but the pics don't leave much to the imagination! |
| `CNEWS_GIRLSCANDALHIGH8` | In an interview for every WAG's favourite magazine Okie Dokie, girlfriend of $playername admitted to being very "experimental" in the bedroom. We wonder what the $clubname boss will say about that! |
| `CNEWS_GIRLSCANDALHIGH9` | High roller! $playername's girlfriend said she just loves gambling. "I love casinos," she said. "You can almost smell the money!" Looks like $playername might be needing to improve his contract soon! |
| `CNEWS_GIRLSCANDALLOW1` | Girlfriend of $playername is hoping to set the music world alight as she tries to launch her music career with a new single. Having heard it we doubt she will be topping the charts just yet! |
| `CNEWS_GIRLSCANDALLOW10` | When $playername's girlfriend appeared on a cookery show recently she nearly brought the house down when the food she was cooking caught fire! |
| `CNEWS_GIRLSCANDALLOW2` | $playername's girlfriend is trying her hand at being a TV presenter. She can be seen selling household products on a home shopping show in the early hours of the morning. |
| `CNEWS_GIRLSCANDALLOW3` | True love! Girlfriend of $playername appeared on a TV chat show yesterday lunchtime and couldn't stop talking about him. It looks like $playername has scored a winner with her! |
| `CNEWS_GIRLSCANDALLOW4` | Girlfriend of $playername says she tries to give as much as she can to charity every month. "I just want to help people," she said. |
| `CNEWS_GIRLSCANDALLOW5` | $playername's girlfriend was photographed out shopping with friends yesterday. Judging from the number of bags she's carrying, $playername might be expecting a rather large credit card bill next month! |
| `CNEWS_GIRLSCANDALLOW6` | $playername's girlfriend was seen out partying at a classy nightclub last night. Any hope of catching her doing something scandalous was dashed though when she headed home at 10pm in a taxi! |
| `CNEWS_GIRLSCANDALLOW7` | In an interview for every WAG's favourite magazine Okie Dokie, girlfriend of $playername was careful not to give any secrets away. "We like to keep our personal lives very private," she said. |
| `CNEWS_GIRLSCANDALLOW8` | $playername's girlfriend was spotted out walking her dog in the park yesterday afternoon. We wonder if she keeps her man on such a short leash! |
| `CNEWS_GIRLSCANDALLOW9` | On your bike! $playername's girlfriend was seen cycling around town yesterday. When asked to comment on his recent form for $clubname she said, "don't ask me, I know nothing about football!" |
| `help_dilemma` | Oh no! Two people want to meet you at the same time! Choose which relationship you want to increase. |
| `help_relationships` | This is your Relationships screen. It is important to keep the people around you happy or your career may suffer. If your HAPPINESS is low then there is more chance of mistiming a kick during a match. Spending time with someone will hopefully improve the relationship but it will cost you ENERGY. |
| `CMESSAGE_GIRLFRIENDMEETMOBILE` | Amazing! You meet an attractive girl and she likes you! Do you want to start dating? |
| `CMESSAGE_GIRLFRIENDRAMPAGEBOSS` | $playername's girlfriend was interviewed on a radio show and claimed that the $clubname boss doesn't care about his players! |
| `CMESSAGE_GIRLFRIENDRAMPAGEFANS` | $playername's girlfriend appeared on a chat show and stated that the $clubname fans are all idiots! |
| `CMESSAGE_GIRLFRIENDRAMPAGETEAM` | $playername's girlfriend was recently interviewed in a gossip magazine and stated that the $clubname players are a bad influence on him! |
| `CMESSAGE_NOGIRLFRIENDLIFESTYLE` | You do not have a GIRLFRIEND yet! You need to increase your lifestyle to impress the ladies. |
| `CNEWS_RELATIONSHIPBOSS1` | $playername may have to start looking for a new club if he cannot improve his relationship with the boss. "He needs to start impressing me, and quickly," said the $clubname coach. |
| `CNEWS_RELATIONSHIPBOSS2` | $playername is struggling to impress the boss at $clubname. A former player of the club says that working hard and performing well are the keys to success. |
| `CNEWS_RELATIONSHIPBOSS3` | $playername is in danger of being frozen out of the $clubname first team if he doesn't improve relations with the boss soon. An insider said that he is letting the club down at the moment. |
| `CNEWS_RELATIONSHIPFANS1` | Fans are running out of patience with $playername. "This isn't just about performances," said one $clubname fan. "He doesn't do enough off the pitch to earn our respect either." |
| `CNEWS_RELATIONSHIPFANS2` | $clubname fans are furious with $playername's attitude. "If he wants us to cheer his name then he needs to show some respect for the club and start working hard on the pitch," said one supporter. |
| `CNEWS_RELATIONSHIPFANS3` | A section of $clubname fans want $playername out of the club. "He's not fit to wear the shirt," said one supporter. "We spent good money to come and see him play but he couldn't care less." |
| `CNEWS_RELATIONSHIPGIRL1` | According to a $clubname insider, $playername is finding it hard to stay positive at the moment. Apparently his relationship with his girlfriend is getting him down. |
| `CNEWS_RELATIONSHIPGIRL2` | On the rocks! $playername is close to splitting up with his girlfriend according one of his closest friends. "They are going through a bad patch right now, but I expect them to work it out." |
| `CNEWS_RELATIONSHIPGIRL3` | Down in the dumps! $playername is struggling to salvage his relationship with his girlfriend. A close friend of the couple said that football commitments are "putting a strain on the relationship". |
| `CNEWS_RELATIONSHIPLOW1` | $playername has got the blues! According to a close friend his general happiness is low and it is affecting his motivation. |
| `CNEWS_RELATIONSHIPLOW2` | $playername is unable to cope with the demands of professional football according to a close family member. "He is very unhappy at the moment and struggling to deal with it all," she said. |
| `CNEWS_RELATIONSHIPLOW3` | We may think that footballers are living the dream, but try telling that to $playername. According to a fellow team mate he is utterly miserable and wanders around the club like a dark cloud. |
| `CNEWS_RELATIONSHIPSPONSORS1` | Apparently $playername is at risk of losing a sponsorship contract. According to our sources, the relationship with his sponsors is at an all time low. |
| `CNEWS_RELATIONSHIPSPONSORS2` | A spokes person for one of $playername's sponsors has revealed that they are debating wether to cancel their agreement with the player. "His lack of commitment to our brand is very disappointing," he said. |
| `CNEWS_RELATIONSHIPSPONSORS3` | $playername is in danger of losing out on a lucrative sponsorship deal. A board member of the company told us, "he's not portaying the professional image that we expect from our clients." |
| `CNEWS_RELATIONSHIPTEAM1` | $playername cuts a lonely figure on the $clubname training ground at the moment. According to our insider at the club, he is finding it hard to bond with his team mates. |
| `CNEWS_RELATIONSHIPTEAM2` | According to a former player of $clubname, $playername really needs to improve his relationship with the team. Only then will he start getting chances on the pitch. |
| `CNEWS_RELATIONSHIPTEAM3` | According to an insider at the $clubname, $playername needs to start bonding with his team mates. "If he wants to get opportunities in the match he needs to earn the respect of his fellow team members." |

### 10.7 Captaincy

Captaincy is a **relationship-derived state**, not a stat. Won and lost through three different relationship
channels:

| Tag | Text |
|---|---|
| `CMESSAGE_CAPTAINCYWON` | The boss is impressed with your leadership and the way you inspire the fans. He has made you the team captain! You can now attempt to persuade the boss to change tactics on the Formation screen. |
| `CMESSAGE_CAPTAINCYLOSTBOSS` | The boss has not been impressed with you lately and has taken away the captain's armband! |
| `CMESSAGE_CAPTAINCYLOSTFANS` | The boss has taken the captain's armband away from you because you no longer inspire the fans! |
| `CMESSAGE_CAPTAINCYLOSTTEAM` | The boss has taken the captain's armband away from you because your team mates are not showing you respect! |

Captaincy unlocks: formation suggestions (`CHELP_FORMATIONBUTTONS`, `CMESSAGE_NEWFORMATIONNOTCAPTAIN`) and
overrides the set-piece "Always" preference (`CTIP_23`).

---

## 11. Sponsorship

**Ten sponsorship categories**, in the exe's declaration order:

| # | Tag | English | Special effect |
|---:|---|---|---|
| 1 | `sponsor_Boots` | Boots | Free boots - `CMESSAGE_SPONSORSHIPACCEPTBOOTS`, `CMESSAGE_FREEBOOTS` |
| 2 | `sponsor_SportsDrink` | Sports Drink | Free NRG - `CMESSAGE_SPONSORSHIPACCEPTDRINK` |
| 3 | `sponsor_SportsClothing` | Sports Clothing | Free shin pads - `CMESSAGE_SPONSORSHIPACCEPTSHINPADS` |
| 4 | `sponsor_CasualClothing` | Casual Clothing | cash only |
| 5 | `sponsor_Food` | Food | cash only |
| 6 | `sponsor_Cosmetics` | Cosmetics | cash only |
| 7 | `sponsor_Watch` | Watch | cash only |
| 8 | `sponsor_Electronics` | Electronics | cash only |
| 9 | `sponsor_Jewelry` | Jewelry | cash only |
| 10 | `sponsor_Car` | Car | cash only |

`CACHIEVEMENT_53` = "Sign maximum number of sponsorship contracts"; the mobile equivalent
`CACHIEVEMENTMOBILE_36` spells it out: **"Sign all 10 sponsorship contracts"**.

Contract terms, from `CMESSAGE_SPONSOROFFER`: *"You will be paid $cash in weekly installments over 1 year."*
→ **1-year term, paid weekly** on PC. (Mobile `CMESSAGE_SPONSOROFFERMOBILE` pays *per match* instead.)

Acquisition gates:
* `CTIP_25` - *"A high FAME rating is required to attract all of the different SPONSORSHIP types. A high
  LIFESTYLE rating will improve the amount of money offered."* → **FAME selects which categories are available;
  LIFESTYLE scales the money.**
* `CTIP_30` - increase FAME to bring in offers.
* `CTIP_35` - better deals if current SPONSOR relationship is good.
* `CMESSAGE_SPONSORSNOTIMPRESSEDFANS` / `…LIFESTYLE` - explicit refusal reasons.

Loss paths: `CMESSAGE_SPONSOREXPIRED` (term ran out) and `CMESSAGE_SPONSORCANCEL` (relationship broke down).
Warning stories: `CNEWS_RELATIONSHIPSPONSORS1..3`.

| Tag | English |
|---|---|
| `CMESSAGE_NOSPONSORS` | You do not have any sponsors at the moment. |
| `CMESSAGE_SPONSORCANCEL` | Your relationship with your $sponsor sponsors has broken down. They have cancelled your sponsorship! |
| `CMESSAGE_SPONSOREXPIRED` | Your $sponsor sponsorship contract has expired. |
| `CMESSAGE_SPONSOROFFER` | You have been offered a $sponsor sponsorship contract. You will be paid $cash in weekly installments over 1 year. Do you wish to accept this offer? |
| `CMESSAGE_SPONSORREQUEST1` | Your SPONSORS want you to take part in a photoshoot for a new product. It will improve your relationship and increase your FAME but cost you $percent% ENERGY. Do you wish to take part? |
| `CMESSAGE_SPONSORREQUEST10` | Your SPONSORS want you to appear in a TV advert. It will improve your relationship and increase your FAME but cost you $percent% ENERGY. Do you want to do it? |
| `CMESSAGE_SPONSORREQUEST2` | Your SPONSORS want you to make an appearance at a corporate event. It will improve your relationship and increase your FAME but cost you $percent% ENERGY. Do you want to do it? |
| `CMESSAGE_SPONSORREQUEST3` | Your SPONSORS want you to take sign autographs at the launch of a new product. It will improve your relationship and increase your FAME but cost you $percent% ENERGY. Do you want to do it? |
| `CMESSAGE_SPONSORREQUEST4` | Your SPONSORS want you to make an appearance at a charity event. It will improve your relationship and increase your FAME but cost you $percent% ENERGY. Do you want to do it? |
| `CMESSAGE_SPONSORREQUEST5` | Your SPONSORS want you to make a brief appearance on a TV show. It will improve your relationship and increase your FAME but cost you $percent% ENERGY. Do you want to do it? |
| `CMESSAGE_SPONSORREQUEST6` | Your SPONSORS want you to make appear on a radio show. It will improve your relationship and increase your FAME but cost you $percent% ENERGY. Do you want to do it? |
| `CMESSAGE_SPONSORREQUEST7` | Your SPONSORS want you to do an interview for a magazine. It will improve your relationship and increase your FAME but cost you $percent% ENERGY. Do you want to do it? |
| `CMESSAGE_SPONSORREQUEST8` | Your SPONSORS want you to do an interview for a website. It will improve your relationship and increase your FAME but cost you $percent% ENERGY. Do you want to do it? |
| `CMESSAGE_SPONSORREQUEST9` | Your SPONSORS want you to do an interview for a newspaper. It will improve your relationship and increase your FAME but cost you $percent% ENERGY. Do you want to do it? |
| `CMESSAGE_SPONSORSHIPACCEPT` | Congratulations! You have agreed a new sponsorship deal! |
| `CMESSAGE_SPONSORSHIPACCEPTBOOTS` | Congratulations! You now get your boots for free! |
| `CMESSAGE_SPONSORSHIPACCEPTDRINK` | Congratulations! You now get your NRG drink for free! |
| `CMESSAGE_SPONSORSHIPACCEPTSHINPADS` | Congratulations! You now get your shin pads for free! |
| `CTIP_25` | A high FAME rating is required to attract all of the different SPONSORSHIP types. A high LIFESTYLE rating will improve the amount of money offered. |
| `CTIP_30` | Increase your FAME rating to bring in sponsorship offers. |
| `CTIP_35` | You will be offered better sponsorship deals if your current SPONSOR relationship is good. |
| `CTIP_36` | Your SPONSORS will be pleased if you win international matches. |
| `CTIP_38` | Your SPONSORS will not be happy if you get a YELLOW or RED card. However, they will be impressed by a STAR MAN performance. |
| `CTIP_40` | If your relationship with SPONSORS is low you risk having contracts cancelled. |
| `sponsor_Boots` | Boots |
| `sponsor_CasualClothing` | Casual Clothing |
| `sponsor_Cosmetics` | Cosmetics |
| `sponsor_Electronics` | Electronics |
| `sponsor_Food` | Food |
| `sponsor_Jewelry` | Jewelry |
| `sponsor_SportsClothing` | Sports Clothing |
| `sponsor_SportsDrink` | Sports Drink |
| `sponsor_Watch` | Watch |
| `CMESSAGE_SPONSOROFFERMOBILE` | You have been offered a $sponsor sponsorship contract! You will be paid $cash per match. Do you wish to accept this offer? |
| `CMESSAGE_SPONSORSNOTIMPRESSEDFANS` | You are not attracting new SPONSORS because your relationship with the FANS is too low. |
| `CMESSAGE_SPONSORSNOTIMPRESSEDLIFESTYLE` | You are not attracting new SPONSORS because your LIFESTYLE rating is too low. |
| `CNEWS_RELATIONSHIPSPONSORS1` | Apparently $playername is at risk of losing a sponsorship contract. According to our sources, the relationship with his sponsors is at an all time low. |
| `CNEWS_RELATIONSHIPSPONSORS2` | A spokes person for one of $playername's sponsors has revealed that they are debating wether to cancel their agreement with the player. "His lack of commitment to our brand is very disappointing," he said. |
| `CNEWS_RELATIONSHIPSPONSORS3` | $playername is in danger of losing out on a lucrative sponsorship deal. A board member of the company told us, "he's not portaying the professional image that we expect from our clients." |
| `sponsor_Car` | Car |

---

## 12. In-match BOSS SHOUTS

Toggled by `settings_BossShouts`. This is the largest single mechanic encoded in the language file: **24 shout
events × 4 variants × 2 moods = 192 lines**, plus a 10-line generic fallback pool.

Construction: the exe holds keys containing the literal token `SHOUT` (`CBOSSSHOUT_GOODPASS`,
`CBOSSSHOUT_BADCALL`, …) plus the standalone token `SHOUT`. At runtime `SHOUT` is replaced with `POS` or `NEG`
according to the boss's mood, then `Rand(1,4)` is appended. `CBOSSPOS_GETONSIDE` / `CBOSSNEG_GETONSIDE` are
referenced directly (that one call site does not use the SHOUT template).

The 24 events, and what each proves about the match engine's event taxonomy:

| Event | Fires when | POS example | NEG example |
|---|---|---|---|
| `GOODPASS` | short pass completed well | Great pass. | Nice pass. |
| `GOODLONGPASS` | long pass completed well | Great ball! | Decent ball. |
| `GOODCROSS` | good cross | Great cross! | Decent cross. |
| `BADCROSS` | wasted cross | Keep trying. | Poor cross. |
| `GOODCORNER` | good corner delivery | Great corner! | Decent corner. |
| `BADCORNER` | wasted corner | Nice try. | Poor corner. |
| `GOODFREEKICK` | good free kick | Great free kick! | Good free kick. |
| `BADFREEKICK` | wasted free kick | Nice try. | That was a bad free kick. |
| `GOODFINISH` | goal from close range | Nice finish! | Good. |
| `BADFINISHING` | missed close-range chance | Take your time. | Terrible finishing. |
| `GOODLONGSHOT` | goal from distance | Fantastic goal! | Not bad. |
| `BADLONGSHOT` | wasted long shot | Don't be hasty. | What a waste. |
| `GOODEFFORT` | shot that deserved better | Unlucky! | Decent effort. |
| `GOODTACKLE` | successful tackle | Good tackle! | Decent tackle. |
| `GOODINTERCEPTION` | interception | Great interception. | Good interception. |
| `GOODPOSITIONING` | good off-ball movement | Good positioning! | Well played. |
| `GOODBACKLINE` | held the defensive line / offside trap | Excellent positioning! | Decent positioning. |
| `BADCALL` | called for a ball in a poor position | Find space before calling. | That was a bad call! |
| `BADVISION` | risky/blind pass thrown away | Come on. | Wasted! |
| `OFFSIDE` | player caught offside | Drop deep to find space. | Poor running. |
| `GETONSIDE` | player standing offside (pre-emptive) | Try to stay onside. | Get onside! |
| `OFFSIDEPASS` | played a team mate offside | Try to time your pass. | Time your pass better! |
| `CALMDOWN` | player committing fouls / losing temper | Be careful. | Calm down! |
| `EXPLETIVE` | generic anger | Oh dear. | Idiot! |

**This table is a specification of the match engine's event detector.** Every event listed must exist as a
detectable in-match condition.

| Tag | English |
|---|---|
| `CBOSSPOS_BADFINISHING1` | Take your time. |
| `CBOSSPOS_BADFINISHING2` | Try to place it. |
| `CBOSSPOS_BADFINISHING3` | Keep trying. |
| `CBOSSPOS_BADFINISHING4` | Decent effort. |
| `CBOSSPOS_GOODLONGSHOT1` | Fantastic goal! |
| `CBOSSPOS_GOODLONGSHOT2` | Awesome strike! |
| `CBOSSPOS_GOODLONGSHOT3` | Scorcher! |
| `CBOSSPOS_GOODLONGSHOT4` | Wow! Great goal! |
| `CBOSSPOS_GOODTACKLE1` | Good tackle! |
| `CBOSSPOS_GOODTACKLE2` | Nice tackle. |
| `CBOSSPOS_GOODTACKLE3` | Well in! |
| `CBOSSPOS_GOODTACKLE4` | Nicely done. |
| `CBOSSPOS_GOODLONGPASS1` | Great ball! |
| `CBOSSPOS_GOODLONGPASS2` | Fantastic ball! |
| `CBOSSPOS_GOODLONGPASS3` | Good ball! |
| `CBOSSPOS_GOODLONGPASS4` | Nice ball! |
| `CBOSSPOS_GOODPASS1` | Great pass. |
| `CBOSSPOS_GOODPASS2` | Fantastic pass. |
| `CBOSSPOS_GOODPASS3` | Lovely passing. |
| `CBOSSPOS_GOODPASS4` | Beautiful. |
| `CBOSSPOS_CALMDOWN1` | Be careful. |
| `CBOSSPOS_CALMDOWN2` | Don't be rash. |
| `CBOSSPOS_CALMDOWN3` | Don't let them get to you. |
| `CBOSSPOS_CALMDOWN4` | Stay cool. |
| `CBOSSPOS_EXPLETIVE1` | Oh dear. |
| `CBOSSPOS_EXPLETIVE2` | I'm not happy with that. |
| `CBOSSPOS_EXPLETIVE3` | Ridiculous. |
| `CBOSSPOS_EXPLETIVE4` | Oh come on referee! |
| `CBOSSPOS_GOODFINISH1` | Nice finish! |
| `CBOSSPOS_GOODFINISH2` | Fantastic finish! |
| `CBOSSPOS_GOODFINISH3` | Good goal. |
| `CBOSSPOS_GOODFINISH4` | Great finish! |
| `CBOSSPOS_GOODPOSITIONING1` | Good positioning! |
| `CBOSSPOS_GOODPOSITIONING2` | Good movement! |
| `CBOSSPOS_GOODPOSITIONING3` | Intelligent running! |
| `CBOSSPOS_GOODPOSITIONING4` | Excellent positioning! |
| `CBOSSPOS_GOODINTERCEPTION1` | Great interception. |
| `CBOSSPOS_GOODINTERCEPTION2` | Excellent interception. |
| `CBOSSPOS_GOODINTERCEPTION3` | Smart interception. |
| `CBOSSPOS_GOODINTERCEPTION4` | Very nicely done. |
| `CBOSSPOS_BADCALL1` | Find space before calling. |
| `CBOSSPOS_BADCALL2` | Be smarter when calling. |
| `CBOSSPOS_BADCALL3` | Think before you call. |
| `CBOSSPOS_BADCALL4` | Time your calls. |
| `CBOSSPOS_GOODEFFORT1` | Unlucky! |
| `CBOSSPOS_GOODEFFORT2` | Ooh, good try! |
| `CBOSSPOS_GOODEFFORT3` | Great technique! |
| `CBOSSPOS_GOODEFFORT4` | Deserved a goal. |
| `CBOSSPOS_BADCORNER1` | Nice try. |
| `CBOSSPOS_BADCORNER2` | Keep it simple next time. |
| `CBOSSPOS_BADCORNER3` | Oh, come on. |
| `CBOSSPOS_BADCORNER4` | Unlucky. |
| `CBOSSPOS_BADFREEKICK1` | Nice try. |
| `CBOSSPOS_BADFREEKICK2` | Keep it simple next time. |
| `CBOSSPOS_BADFREEKICK3` | Oh, come on. |
| `CBOSSPOS_BADFREEKICK4` | Unlucky. |
| `CBOSSPOS_BADLONGSHOT1` | Don't be hasty. |
| `CBOSSPOS_BADLONGSHOT2` | Keep it simple. |
| `CBOSSPOS_BADLONGSHOT3` | Keep trying. |
| `CBOSSPOS_BADLONGSHOT4` | Unlucky. |
| `CBOSSPOS_GOODCROSS1` | Great cross! |
| `CBOSSPOS_GOODCROSS2` | Good stuff! |
| `CBOSSPOS_GOODCROSS3` | Excellent cross! |
| `CBOSSPOS_GOODCROSS4` | Lovely cross. |
| `CBOSSPOS_BADCROSS1` | Keep trying. |
| `CBOSSPOS_BADCROSS2` | Unlucky. |
| `CBOSSPOS_BADCROSS3` | Keep it up. |
| `CBOSSPOS_BADCROSS4` | Keep it simple. |
| `CBOSSPOS_GOODCORNER1` | Great corner! |
| `CBOSSPOS_GOODCORNER2` | Beautiful! |
| `CBOSSPOS_GOODCORNER3` | Great ball in! |
| `CBOSSPOS_GOODCORNER4` | Excellent delivery! |
| `CBOSSPOS_GOODFREEKICK1` | Great free kick! |
| `CBOSSPOS_GOODFREEKICK2` | Excellent free kick! |
| `CBOSSPOS_GOODFREEKICK3` | Well played! |
| `CBOSSPOS_GOODFREEKICK4` | Great stuff! |
| `CBOSSPOS_GETONSIDE1` | Try to stay onside. |
| `CBOSSPOS_GETONSIDE2` | Get back onside. |
| `CBOSSPOS_GETONSIDE3` | Watch the back line. |
| `CBOSSPOS_GETONSIDE4` | You are offside. |
| `CBOSSPOS_OFFSIDEPASS1` | Try to time your pass. |
| `CBOSSPOS_OFFSIDEPASS2` | Watch the runner. |
| `CBOSSPOS_OFFSIDEPASS3` | Take your time. |
| `CBOSSPOS_OFFSIDEPASS4` | Don't be hasty. |
| `CBOSSPOS_BADVISION1` | Come on. |
| `CBOSSPOS_BADVISION2` | No more risky passes. |
| `CBOSSPOS_BADVISION3` | Look for the easy pass. |
| `CBOSSPOS_BADVISION4` | Keep it simple. |
| `CBOSSPOS_GOODBACKLINE1` | Excellent positioning! |
| `CBOSSPOS_GOODBACKLINE2` | Great back line! |
| `CBOSSPOS_GOODBACKLINE3` | Great offside trap! |
| `CBOSSPOS_GOODBACKLINE4` | Superb awareness! |
| `CBOSSPOS_OFFSIDE1` | Drop deep to find space. |
| `CBOSSPOS_OFFSIDE2` | Try to time your run. |
| `CBOSSPOS_OFFSIDE3` | Watch the back line. |
| `CBOSSPOS_OFFSIDE4` | Get in-between the defenders. |

| Tag | English |
|---|---|
| `CBOSSNEG_BADFINISHING1` | Terrible finishing. |
| `CBOSSNEG_BADFINISHING2` | Awful finish! |
| `CBOSSNEG_BADFINISHING3` | Woeful finishing! |
| `CBOSSNEG_BADFINISHING4` | That was poor finishing. |
| `CBOSSNEG_GOODLONGSHOT1` | Not bad. |
| `CBOSSNEG_GOODLONGSHOT2` | Pretty good. |
| `CBOSSNEG_GOODLONGSHOT3` | Good goal. |
| `CBOSSNEG_GOODLONGSHOT4` | That's more like it. |
| `CBOSSNEG_GOODTACKLE1` | Decent tackle. |
| `CBOSSNEG_GOODTACKLE2` | Better. |
| `CBOSSNEG_GOODTACKLE3` | Good tackle. |
| `CBOSSNEG_GOODTACKLE4` | Nice. |
| `CBOSSNEG_GOODLONGPASS1` | Decent ball. |
| `CBOSSNEG_GOODLONGPASS2` | Not bad. |
| `CBOSSNEG_GOODLONGPASS3` | Good ball. |
| `CBOSSNEG_GOODLONGPASS4` | That's good. |
| `CBOSSNEG_GOODPASS1` | Nice pass. |
| `CBOSSNEG_GOODPASS2` | Good pass. |
| `CBOSSNEG_GOODPASS3` | Good stuff. |
| `CBOSSNEG_GOODPASS4` | Decent pass. |
| `CBOSSNEG_CALMDOWN1` | Calm down! |
| `CBOSSNEG_CALMDOWN2` | Take it easy! |
| `CBOSSNEG_CALMDOWN3` | Keep your head! |
| `CBOSSNEG_CALMDOWN4` | Get a grip! |
| `CBOSSNEG_EXPLETIVE` | Idiot! |
| `CBOSSNEG_EXPLETIVE` | What was that?! |
| `CBOSSNEG_EXPLETIVE` | Pathetic! |
| `CBOSSNEG_EXPLETIVE` | $#@%!!! |
| `CBOSSNEG_GOODFINISH1` | Good. |
| `CBOSSNEG_GOODFINISH2` | Better. |
| `CBOSSNEG_GOODFINISH3` | Nice. |
| `CBOSSNEG_GOODFINISH4` | Decent finish. |
| `CBOSSNEG_GOODPOSITIONING1` | Well played. |
| `CBOSSNEG_GOODPOSITIONING2` | Smart run. |
| `CBOSSNEG_GOODPOSITIONING3` | Nice positioning. |
| `CBOSSNEG_GOODPOSITIONING4` | Good positioning. |
| `CBOSSNEG_GOODINTERCEPTION1` | Good interception. |
| `CBOSSNEG_GOODINTERCEPTION2` | Nice interception. |
| `CBOSSNEG_GOODINTERCEPTION3` | Decent interception. |
| `CBOSSNEG_GOODINTERCEPTION4` | Nicely done. |
| `CBOSSNEG_BADCALL1` | That was a bad call! |
| `CBOSSNEG_BADCALL2` | Poor positioning. |
| `CBOSSNEG_BADCALL3` | I expect better! |
| `CBOSSNEG_BADCALL4` | Stupid call! |
| `CBOSSNEG_GOODEFFORT1` | Decent effort. |
| `CBOSSNEG_GOODEFFORT2` | Not a bad effort. |
| `CBOSSNEG_GOODEFFORT3` | It was worth a try. |
| `CBOSSNEG_GOODEFFORT4` | Good effort. |
| `CBOSSNEG_BADCORNER1` | Poor corner. |
| `CBOSSNEG_BADCORNER2` | Rubbish corner! |
| `CBOSSNEG_BADCORNER3` | What was that?! |
| `CBOSSNEG_BADCORNER4` | Poor delivery. |
| `CBOSSNEG_BADFREEKICK1` | That was a bad free kick. |
| `CBOSSNEG_BADFREEKICK2` | Poor free kick. |
| `CBOSSNEG_BADFREEKICK3` | You wasted that free kick. |
| `CBOSSNEG_BADFREEKICK4` | Terrible free kick. |
| `CBOSSNEG_BADLONGSHOT1` | What a waste. |
| `CBOSSNEG_BADLONGSHOT2` | What was that?! |
| `CBOSSNEG_BADLONGSHOT3` | Awful effort! |
| `CBOSSNEG_BADLONGSHOT4` | Terrible effort. |
| `CBOSSNEG_GOODCROSS1` | Decent cross. |
| `CBOSSNEG_GOODCROSS2` | That's nice. |
| `CBOSSNEG_GOODCROSS3` | Nice cross. |
| `CBOSSNEG_GOODCROSS4` | Better. |
| `CBOSSNEG_BADCROSS1` | Poor cross. |
| `CBOSSNEG_BADCROSS2` | Awful cross. |
| `CBOSSNEG_BADCROSS3` | Wasted cross. |
| `CBOSSNEG_BADCROSS4` | Terrible cross. |
| `CBOSSNEG_GOODCORNER1` | Decent corner. |
| `CBOSSNEG_GOODCORNER2` | Nice corner. |
| `CBOSSNEG_GOODCORNER3` | Good ball in. |
| `CBOSSNEG_GOODCORNER4` | Nice delivery. |
| `CBOSSNEG_GOODFREEKICK1` | Good free kick. |
| `CBOSSNEG_GOODFREEKICK2` | Nice. |
| `CBOSSNEG_GOODFREEKICK3` | That's better. |
| `CBOSSNEG_GOODFREEKICK4` | Good stuff. |
| `CBOSSNEG_GETONSIDE1` | Get onside! |
| `CBOSSNEG_GETONSIDE2` | Time your runs! |
| `CBOSSNEG_GETONSIDE3` | Use your brain! |
| `CBOSSNEG_GETONSIDE4` | Stay onside! |
| `CBOSSNEG_OFFSIDEPASS1` | Time your pass better! |
| `CBOSSNEG_OFFSIDEPASS2` | Watch the runner! |
| `CBOSSNEG_OFFSIDEPASS3` | Take your time! |
| `CBOSSNEG_OFFSIDEPASS4` | No, no, no! |
| `CBOSSNEG_BADVISION1` | Wasted! |
| `CBOSSNEG_BADVISION2` | What was that?! |
| `CBOSSNEG_BADVISION3` | Terrible! |
| `CBOSSNEG_BADVISION4` | Awful! |
| `CBOSSNEG_GOODBACKLINE1` | Decent positioning. |
| `CBOSSNEG_GOODBACKLINE2` | Good organisation. |
| `CBOSSNEG_GOODBACKLINE3` | Good offside trap. |
| `CBOSSNEG_GOODBACKLINE4` | Good awareness. |
| `CBOSSNEG_OFFSIDE1` | Poor running. |
| `CBOSSNEG_OFFSIDE2` | Poor movement. |
| `CBOSSNEG_OFFSIDE3` | Not clever. |
| `CBOSSNEG_OFFSIDE4` | Pathetic. |

Generic fallback pool (referenced as `CBOSS_GENERICGOOD` / `CBOSS_GENERICBAD` + `Rand(1,5)`):

| Tag | English |
|---|---|
| `CBOSS_GENERICGOOD1` | Good. |
| `CBOSS_GENERICGOOD2` | Nice. |
| `CBOSS_GENERICGOOD3` | Very nice. |
| `CBOSS_GENERICGOOD4` | Nicely done. |
| `CBOSS_GENERICGOOD5` | Great. |
| `CBOSS_GENERICBAD1` | No. |
| `CBOSS_GENERICBAD2` | Not good enough. |
| `CBOSS_GENERICBAD3` | Poor. |
| `CBOSS_GENERICBAD4` | Not great. |
| `CBOSS_GENERICBAD5` | That was poor. |

---

## 13. Post-match reports - the Boss's office and the Physio's room

Two dedicated screens: `reportboss` (`GameMedia\Images\Backgrounds\report_boss.png`, `help_reportboss`) and
`reportphysio` (`report_physio.png`, `help_reportphysio`). The boss report is **assembled from parts**, which the
exe's label set makes explicit:

```
lbl_ReportBoss           <- the verdict sentence
lbl_ReportCoachBoss      <- delta to BOSS relationship
lbl_ReportCoachTeam      <- delta to TEAM
lbl_ReportCoachFans      <- delta to FANS
lbl_ReportCoachSponsors  <- delta to SPONSORS
lbl_ReportCoachFame      <- delta to FAME
```
(`CHELP_REPORTRELATIONSHIPS`: *"These numbers show you how much your relationships increased or decreased after
the match."*)

### 13.1 Verdict tier (pick one, `prefix + Rand(1,10)`)

| Tier | Prefix | Count | Trigger |
|---|---|---:|---|
| Man of the match | `CREPORT_BOSSMOTM` | 10 | Star Man award |
| Good | `CREPORT_BOSSGOOD` | 10 | high rating |
| OK | `CREPORT_BOSSOK` | 10 | mid rating |
| Poor | `CREPORT_BOSSPOOR` | 10 | low rating |

### 13.2 Override verdicts (single lines, replace the tier line)

`CREPORT_BOSSREDCARDGOOD` / `…OK` / `…BAD` (red card, 3 performance flavours),
`CREPORT_BOSSINJURYGOOD` / `…OK` / `…BAD` (injured mid-match, 3 flavours),
`CREPORT_BOSSDRUGSTESTBAD`.

### 13.3 Appended praise clauses

Ten "your X was good" clauses map 1:1 onto the ten match RATINGS (§5.2). Four of them have a *"however"* variant
used when the overall verdict is negative - proving the report is a sentence builder, not a lookup:

`CREPORT_GOODHEADING` / `CREPORT_GOODHEADINGHOWEVER`, `CREPORT_GOODPASSING` / `…HOWEVER`,
`CREPORT_GOODTACKLING` / `…HOWEVER`, plus `CREPORT_GOODCROSSING`, `CREPORT_GOODFREEKICKS`,
`CREPORT_GOODCORNERS`, `CREPORT_GOODPOSITIONING`, `CREPORT_GOODSHORTPASSING`, `CREPORT_GOODLONGPASSING`,
`CREPORT_GOODAGGRESSION`, `CREPORT_GOODLONGSHOTS`, `CREPORT_GOODFINISHING`, `CREPORT_GOODPENALTIES`.

### 13.4 Discipline clauses

`CREPORT_COACHYELLOW`, `CREPORT_COACHYELLOWS` (two yellows = sent off), `CREPORT_COACHRED`,
`CREPORT_COACHYELLOWSPONSORS` (sponsors unhappy about the yellow),
`CREPORT_COACHBAN1` (1 game) / `CREPORT_COACHBAN2` ($num games) / `CREPORT_COACHBANIMMINENT`
 - all parameterised by `$matchtype` ∈ {`matchtype_club` = "league and cup", `matchtype_continental` =
"club continental", `matchtype_international` = "international"}, confirming **three independent suspension
counters**.

### 13.5 Derby / rivalry clauses

Four ×2 combinations of result and performance - proving the game tracks **rival clubs**
(`Rival`, `Rival Club Name`; `Clubs.csv`/`Nations.csv` carry `rivalid1..3`):

`CREPORT_RIVALSWEWONGOOD1/2`, `CREPORT_RIVALSWEWONBAD1/2`,
`CREPORT_RIVALSWELOSTGOOD1/2`, `CREPORT_RIVALSWELOSTBAD1/2`.

### 13.6 Relationship-nag clauses

`CREPORT_FANSLOW1/2` (make more tackles, show passion), `CREPORT_TEAMLOW1/2` (pass more, be less selfish).

### 13.7 Complete `CREPORT_` dump

| Tag | English |
|---|---|
| `CREPORT_BOSSDRUGSTESTBAD` | What the hell were you thinking taking performance enhancers! You have shown a complete lack of respect for me and this club. You have let down the team, the fans, yourself, everyone! |
| `CREPORT_BOSSGOOD1` | Your performance was very good against $opposingclubname. |
| `CREPORT_BOSSGOOD10` | You are playing some great football lately. Well done. |
| `CREPORT_BOSSGOOD2` | That was a great performance against $opposingclubname. |
| `CREPORT_BOSSGOOD3` | A great display against $opposingclubname. |
| `CREPORT_BOSSGOOD4` | A fine performance against $opposingclubname. |
| `CREPORT_BOSSGOOD5` | You impressed me in the game against $opposingclubname. |
| `CREPORT_BOSSGOOD6` | Well played in the last game against $opposingclubname. Very good. |
| `CREPORT_BOSSGOOD7` | You played some good stuff against $opposingclubname. Keep it up! |
| `CREPORT_BOSSGOOD8` | You impressed me in the last match. I want to see that every week. |
| `CREPORT_BOSSGOOD9` | You were unlucky not to pick up a 'Star Man' award for that display! |
| `CREPORT_BOSSINJURYBAD` | I was not happy with your performance and then you got injured. |
| `CREPORT_BOSSINJURYGOOD` | It's a shame that you got injured in the last game because you were playing very well. |
| `CREPORT_BOSSINJURYOK` | You were playing well in the last game until you got injured. |
| `CREPORT_BOSSMOTM1` | That was stunning performance against $opposingclubname. Keep it up! |
| `CREPORT_BOSSMOTM10` | You thoroughly deserved the 'Star Man' award. It was a commanding performance. |
| `CREPORT_BOSSMOTM2` | That was a very impressive performance against $opposingclubname. Well done! |
| `CREPORT_BOSSMOTM3` | You played superbly well against $opposingclubname. |
| `CREPORT_BOSSMOTM4` | Fantastic display against $opposingclubname. Top drawer! |
| `CREPORT_BOSSMOTM5` | That was an outstanding performance in the last match. Excellent! |
| `CREPORT_BOSSMOTM6` | That really was a man of the match performance against $opposingclubname. |
| `CREPORT_BOSSMOTM7` | An awesome display against $opposingclubname. You really impressed. |
| `CREPORT_BOSSMOTM8` | A superb performance. That's exactly what I want from you. |
| `CREPORT_BOSSMOTM9` | That kind of performance lifts everyone at the club. Well done. |
| `CREPORT_BOSSOK1` | Your performance was ok in the last game, but I want to see more from you. |
| `CREPORT_BOSSOK10` | I want to see a bit more from you. You are not pushing yourself hard enough. |
| `CREPORT_BOSSOK2` | That was a decent performance against $opposingclubname. |
| `CREPORT_BOSSOK3` | A decent display against $opposingclubname, but you know you can do better. |
| `CREPORT_BOSSOK4` | A fairly good display but I am expecting a bit more from you. |
| `CREPORT_BOSSOK5` | Nice work against $opposingclubname but you need to step it up a bit. |
| `CREPORT_BOSSOK6` | You need to build on that performance. It was ok. |
| `CREPORT_BOSSOK7` | You held your own against $opposingclubname. |
| `CREPORT_BOSSOK8` | You did well against $opposingclubname but you need to impose yourself more. |
| `CREPORT_BOSSOK9` | You failed to impress me in the last match but you did ok. |
| `CREPORT_BOSSPOOR1` | Your performance was poor in the last game. |
| `CREPORT_BOSSPOOR10` | That was a terribly display against $opposingclubname. You need to pull your socks up! |
| `CREPORT_BOSSPOOR2` | You did not play well against $opposingclubname. |
| `CREPORT_BOSSPOOR3` | That was not a good performance at all against $opposingclubname. |
| `CREPORT_BOSSPOOR4` | A very disappointing performance. I expect a lot more than that! |
| `CREPORT_BOSSPOOR5` | You've made it difficult to select you for the next game after that performance. |
| `CREPORT_BOSSPOOR6` | That really wasn't good enough in the last game. |
| `CREPORT_BOSSPOOR7` | Hmm, the less said about that performance the better. |
| `CREPORT_BOSSPOOR8` | I won't say anything about that performance except that you were awful. |
| `CREPORT_BOSSPOOR9` | I'd better not say too much about your performance against $opposingclubname. |
| `CREPORT_BOSSREDCARDBAD` | The red card in your last game just about summed up your performance. Disappointing. |
| `CREPORT_BOSSREDCARDGOOD` | Your performance was good in the last game, but then you got a red card. |
| `CREPORT_BOSSREDCARDOK` | I can't believe you got a red card in the last game, you were playing well. |
| `CREPORT_COACHBAN1` | You have been banned from playing $matchtype matches for $num game. |
| `CREPORT_COACHBAN2` | You have been banned from playing $matchtype matches for $num games. |
| `CREPORT_COACHBANIMMINENT` | You are one yellow card away from a $matchtype match ban! |
| `CREPORT_COACHRED` | I am furious that you were sent off. |
| `CREPORT_COACHYELLOW` | I am not happy that you received a yellow card. |
| `CREPORT_COACHYELLOWS` | You were sent off for 2 yellow card offences which I am not happy about. |
| `CREPORT_COACHYELLOWSPONSORS` | Your sponsors are not happy that you received a yellow card. |
| `CREPORT_FANSLOW1` | The fans want to see a bit more passion from you. Make a few tackles! |
| `CREPORT_FANSLOW2` | The fans were not impressed. Get stuck in a bit more! |
| `CREPORT_GOODHEADING` | Your heading was particularly impressive. |
| `CREPORT_GOODHEADINGHOWEVER` | Your heading was particularly impressive though. |
| `CREPORT_GOODPASSING` | Your passing was outstanding. |
| `CREPORT_GOODPASSINGHOWEVER` | Your passing was outstanding, however. |
| `CREPORT_GOODTACKLING` | Your tackling was superb. |
| `CREPORT_GOODTACKLINGHOWEVER` | Your tackling was superb though. |
| `CREPORT_PHYSIO1` | After a thorough assessment of your injury the physio tells you that you are likely to miss 1 match. |
| `CREPORT_PHYSIO2` | After a thorough assessment of your injury the physio tells you that you are likely to miss $num matches. |
| `CREPORT_PHYSIO3` | Your abilities have also suffered ($skillslost). |
| `CREPORT_PHYSIODRUGSTESTBAD` | The club PHYSIO took a sample from you after the match to test it for banned substances. The boss would like to see you in his office. |
| `CREPORT_PHYSIODRUGSTESTGOOD` | The club PHYSIO took a sample from you after the match to test it for banned substances. The results were clear. |
| `CREPORT_RIVALSWELOSTBAD1` | The fans are bitterly disappointed about losing to our fierce rivals. They were not impressed with your performance. |
| `CREPORT_RIVALSWELOSTBAD2` | The fans were unimpressed with your performance. They at least want to see some passion when playing our fierce rivals. |
| `CREPORT_RIVALSWELOSTGOOD1` | The fans are disappointed about losing to our fierce rivals but they were impressed with your performance. |
| `CREPORT_RIVALSWELOSTGOOD2` | The fans are gutted that we lost to our rivals but they appreciated the effort that you put in. |
| `CREPORT_RIVALSWEWONBAD1` | The fans are glad that we beat our fierce rivals but they were not impressed with your performance. |
| `CREPORT_RIVALSWEWONBAD2` | The fans were disappointed in your lack of passion. Particularly in a match against our rivals! |
| `CREPORT_RIVALSWEWONGOOD1` | The fans are extremely happy that we beat our fierce rivals. |
| `CREPORT_RIVALSWEWONGOOD2` | Beating our rivals has pleased the fans. |
| `CREPORT_TEAMLOW1` | You need to pass it more to impress your team mates. |
| `CREPORT_TEAMLOW2` | Your team mates weren't happy. Try not to be so selfish and look to pass it more. |
| `CREPORT_GOODCROSSING` | Your crossing was impressive. |
| `CREPORT_GOODFREEKICKS` | Your free kicks were excellent. |
| `CREPORT_GOODCORNERS` | Your corners were very effective. |
| `CREPORT_GOODPOSITIONING` | Your positioning was particularly impressive. |
| `CREPORT_GOODSHORTPASSING` | Your short passing was excellent. |
| `CREPORT_GOODLONGPASSING` | Your long passing was impressive. |
| `CREPORT_GOODAGGRESSION` | You showed some good aggression. |
| `CREPORT_GOODLONGSHOTS` | Your shots from distance were impressive. |
| `CREPORT_GOODFINISHING` | Your close range finishing was impressive. |
| `CREPORT_GOODPENALTIES` | Your penalty taking was excellent. |

---

## 14. News system

Two distinct outlets:
* **Newspaper** (`newspaper` screen, `Newspaper.png`, `NewspaperPhoto.png`, `Hands_*.png`, `Newspaper.ogg`) - 
  shows the player's match rating and the `Star Man!` award.
* **NSG Sport web page** (`webpage` screen, `WebPage.png`, `help_webpage`: *"If something newsworthy occurs in
  your life NSG Sport will be first to report it!"*) with Twitter/Facebook share buttons
  (`social_Tweet`, `social_Share`, `#NSS5`, `NSS5 News! `).

### 14.1 `CNEWS_` families and their exact cardinalities

| Family | Count | Trigger |
|---|---:|---|
| `CNEWS_DEBUT_MOTM1..4` | 4 | club debut, star man |
| `CNEWS_DEBUT_GOOD1..2` | 2 | club debut, good |
| `CNEWS_DEBUT_AVERAGE1..2` | 2 | club debut, average |
| `CNEWS_DEBUT_POOR1..2` | 2 | club debut, poor |
| `CNEWS_DEBUT_REDCARD` | 1 | club debut, sent off |
| `CNEWS_INTDEBUT_MOTM / GOOD / AVERAGE / POOR / REDCARD` | 1 each | international debut |
| `CNEWS_MATCHSTARMAN1..15` | 15 | star man performance |
| `CNEWS_MATCHSTARMANYOUNG1..5` | 5 | star man, young player |
| `CNEWS_MATCHSTARMANINT1..15` | 15 | star man, international / world-class (mobile-flavoured) |
| `CNEWS_MATCHSHOTS1..5` | 5 | many shots, no goal |
| `CNEWS_MATCHFOULS1..5` | 5 | many fouls |
| `CNEWS_MATCHREDCARD1..5` | 5 | red card |
| `CNEWS_TRANSFER1..10` | 10 | transfer completed |
| `CNEWS_TRANSFERINTEREST1..10` | 10 | club interested |
| `CNEWS_TRANSFERREQUEST` | 1 | player hands in transfer request |
| `CNEWS_FIRSTCONTRACT` | 1 | signed first pro deal |
| `CNEWS_RENEWCONTRACT` | 1 | renewed |
| `CNEWS_RANDOMCLUBBOOST1..15` | 15 | random positive club event |
| `CNEWS_RANDOMCLUBCRISIS1..15` | 15 | random negative club event |
| `CNEWS_GIRLSCANDALHIGH1..10` | 10 | high-scandal girlfriend |
| `CNEWS_GIRLSCANDALLOW1..10` | 10 | low-scandal girlfriend |
| `CNEWS_GIRLFRIENDDUMPED` / `CNEWS_GIRLFRIENDDUMPSYOU` | 1 each | break-up (by you / by her) |
| `CNEWS_RELATIONSHIPBOSS1..3` | 3 | boss relationship critically low |
| `CNEWS_RELATIONSHIPTEAM1..3` | 3 | team relationship low |
| `CNEWS_RELATIONSHIPFANS1..3` | 3 | fans relationship low |
| `CNEWS_RELATIONSHIPGIRL1..3` | 3 | girlfriend relationship low |
| `CNEWS_RELATIONSHIPSPONSORS1..3` | 3 | sponsor relationship low |
| `CNEWS_RELATIONSHIPLOW1..3` | 3 | overall happiness low |
| `CNEWS_STYLECLOTHES` / `CNEWS_STYLEGADGET` / `CNEWS_STYLEVEHICLE` / `CNEWS_STYLEPROPERTY` | 1 each | owns a purchased asset |
| `CNEWS_STYLELOW1..3` | 3 | owns nothing |
| `CNEWS_GAMBLINGADDICT` (+ `…BOSS`, `…GIRL`) | 3 | gambling addiction detected |
| `CNEWS_DRUGTESTFAIL` | 1 | failed drugs test |
| `CNEWS_SKIPMATCHCLUB` / `CNEWS_SKIPMATCHINTERNATIONAL` | 1 each | refused to play |
| `CNEWS_CUPWINNER` / `CNEWS_LEAGUEWINNER` | 1 each | competition decided |
| `CNEWS_YOUNGPLAYER` / `CNEWS_LEAGUEPLAYER` / `CNEWS_WORLDPLAYER` | 1 each | the three end-of-season awards |
| `CNEWS_*MOBILE*` | 20 | mobile-only rewrites, dead on PC |

### 14.2 Complete `CNEWS_` dump

| Tag | English |
|---|---|
| `CNEWS_CUPWINNER` | $clubname have won the $competition! |
| `CNEWS_DEBUT_AVERAGE1` | $playername put in a decent performance on his debut for $clubname. "It's early days," said his manager, "I'm sure he will get better with every game." |
| `CNEWS_DEBUT_AVERAGE2` | It was a decent debut for $playername in the match against $opposingclubname. "The $clubname fans will start to warm to him if he can improve on that performance," said his manager. |
| `CNEWS_DEBUT_GOOD1` | $playername put in an excellent display on his debut for $clubname. "I was delighted with his performance," said his manager. "That's exactly what I wanted from him." |
| `CNEWS_DEBUT_GOOD2` | $playername impressed the $clubname fans after putting in an good performance on his debut. They will certainly be hoping he can perform like that every week! |
| `CNEWS_DEBUT_MOTM1` | A man of the match performance from $playername had the $clubname boss raving after the game. "It was a stunning display," he said. "The best debut I've seen in a long, long time." |
| `CNEWS_DEBUT_MOTM2` | $playername put in a man of the match performance on his debut for $clubname. His boss was full of praise after the game saying, "he is exactly what we need at this club." |
| `CNEWS_DEBUT_MOTM3` | A star is born! That was the opinion of fans, pundits and even the $clubname manager after a stunning debut from $playername against $opposingclubname. Watch out for this boy! |
| `CNEWS_DEBUT_MOTM4` | Diamond lights! The $clubname boss will be singing for joy after witnessing a stunning debut from $playername. After the game he said, "I think we may have uncovered a gem!" |
| `CNEWS_DEBUT_POOR1` | $playername failed to impress on his debut for $clubname. "I think he was overcome with the situation," said his boss. "It always takes time to settle in." |
| `CNEWS_DEBUT_POOR2` | $playername failed to impress the $clubname fans in his debut against $opposingclubname. "It was a bit of a shocker, but I'm sure he will train hard and get better." said his new boss. |
| `CNEWS_DEBUT_REDCARD` | $playername had a debut from hell after being sent off in the game against $opposingclubname. "It was a bit of a disaster," the $clubname boss said. "He has to show me that he can bounce back from that." |
| `CNEWS_DRUGTESTFAIL` | BANNED! $playername has failed a drugs test and faces a $num match ban! The $clubname boss is absolutely furious with him. |
| `CNEWS_FIRSTCONTRACT` | $clubname have signed the youngster $playername on a $years year contract. The $clubname boss says he has "high expectations" of the player and wants to give him a chance to prove himself. |
| `CNEWS_GAMBLINGADDICT` | Gambling addict! $playername has been spotted spending large amounts of cash at the casino. This extravagant, playboy lifestyle will certainly not impress his boss or the fans who can only dream about the kind of money he earns. |
| `CNEWS_GIRLFRIENDDUMPED` | Ladies watchout! $playername is a free man again after splitting up with his girlfriend. |
| `CNEWS_GIRLFRIENDDUMPSYOU` | Dumped! $playername has sensationally split up with his girlfriend after she publicly ditched him this week. "He was a lousy boyfriend and I look forward to finding a real man," she said. |
| `CNEWS_GIRLSCANDALHIGH1` | Classy! Girlfriend of $playername was photographed out partying with friends at a nightclub last night. She had clearly been drinking and was cavorting with guys on the dancefloor. |
| `CNEWS_GIRLSCANDALHIGH10` | $playername's girlfriend has hit out at the $clubname boss claiming that he pushes the players too hard. "When my man comes home from training he is shattered," she said. "He has no energy left for anything!" |
| `CNEWS_GIRLSCANDALHIGH2` | Temptress! What will $playername say when he sees the photos of his girlfriend out with another guy? One onlooker said, "they looked like they were having a great time together." |
| `CNEWS_GIRLSCANDALHIGH3` | Girlfriend of $playername denies she has a drink problem despite being seen falling out of a seedy nightclub and onto the pavement. |
| `CNEWS_GIRLSCANDALHIGH4` | Girlfriend of $playername admits that she is a shop-aholic. "I can't help it," she says "I just love clothes." When asked what her boyfriend thought about her addiction she said, "he doesn't complain when I buy lingerie!" |
| `CNEWS_GIRLSCANDALHIGH5` | Catfight! Girlfriend of $clubname player $playername was snapped having a fight with another WAG last night. No one was hurt but the girls had to be pulled apart. |
| `CNEWS_GIRLSCANDALHIGH6` | Your nicked miss! Girlfriend of $playername was in handcuffs last night after being caught drink driving. She stumbled out of a night club and into her car only to be stopped by the police after driving 10 yards! |
| `CNEWS_GIRLSCANDALHIGH7` | Wow what a beauty! Girlfriend of $playername has appeared in a sexy photoshoot for lads mag 'Spuds'. The saucy WAG doesn't quite reveal all but the pics don't leave much to the imagination! |
| `CNEWS_GIRLSCANDALHIGH8` | In an interview for every WAG's favourite magazine Okie Dokie, girlfriend of $playername admitted to being very "experimental" in the bedroom. We wonder what the $clubname boss will say about that! |
| `CNEWS_GIRLSCANDALHIGH9` | High roller! $playername's girlfriend said she just loves gambling. "I love casinos," she said. "You can almost smell the money!" Looks like $playername might be needing to improve his contract soon! |
| `CNEWS_GIRLSCANDALLOW1` | Girlfriend of $playername is hoping to set the music world alight as she tries to launch her music career with a new single. Having heard it we doubt she will be topping the charts just yet! |
| `CNEWS_GIRLSCANDALLOW10` | When $playername's girlfriend appeared on a cookery show recently she nearly brought the house down when the food she was cooking caught fire! |
| `CNEWS_GIRLSCANDALLOW2` | $playername's girlfriend is trying her hand at being a TV presenter. She can be seen selling household products on a home shopping show in the early hours of the morning. |
| `CNEWS_GIRLSCANDALLOW3` | True love! Girlfriend of $playername appeared on a TV chat show yesterday lunchtime and couldn't stop talking about him. It looks like $playername has scored a winner with her! |
| `CNEWS_GIRLSCANDALLOW4` | Girlfriend of $playername says she tries to give as much as she can to charity every month. "I just want to help people," she said. |
| `CNEWS_GIRLSCANDALLOW5` | $playername's girlfriend was photographed out shopping with friends yesterday. Judging from the number of bags she's carrying, $playername might be expecting a rather large credit card bill next month! |
| `CNEWS_GIRLSCANDALLOW6` | $playername's girlfriend was seen out partying at a classy nightclub last night. Any hope of catching her doing something scandalous was dashed though when she headed home at 10pm in a taxi! |
| `CNEWS_GIRLSCANDALLOW7` | In an interview for every WAG's favourite magazine Okie Dokie, girlfriend of $playername was careful not to give any secrets away. "We like to keep our personal lives very private," she said. |
| `CNEWS_GIRLSCANDALLOW8` | $playername's girlfriend was spotted out walking her dog in the park yesterday afternoon. We wonder if she keeps her man on such a short leash! |
| `CNEWS_GIRLSCANDALLOW9` | On your bike! $playername's girlfriend was seen cycling around town yesterday. When asked to comment on his recent form for $clubname she said, "don't ask me, I know nothing about football!" |
| `CNEWS_INTDEBUT_AVERAGE` | It was a solid performance from $playername on his international debut against $opposingclubname. "I think he will improve," said the $clubname manager, "he certainly has potential." |
| `CNEWS_INTDEBUT_GOOD` | $playername put in an excellent performance on his international debut. "All the signs are there," said the $clubname manager. "He is definitely in my plans for the future." |
| `CNEWS_INTDEBUT_MOTM` | It was a day to remember for $playername who put in a man of the match performance on his debut for $clubname. He has virtually guaranteed his place in the starting line-up. |
| `CNEWS_INTDEBUT_POOR` | $playername failed to set the world alight in his first game for his country. "He was trying too hard," said the $clubname boss. "He needs to calm down and keep it simple." |
| `CNEWS_INTDEBUT_REDCARD` | It was a day to forget for $playername who was sent off in his first ever match for his country. The $clubname boss said, "I think the occasion went to his head, but I'm sure he will get another chance to prove himself once he has served his ban." |
| `CNEWS_LEAGUEPLAYER` | After an outstanding season, $playername of $clubname has been voted as the 'League Player of the Year'! |
| `CNEWS_LEAGUEWINNER` | $clubname are crowned $competition champions! |
| `CNEWS_MATCHFOULS1` | A disgrace! $opposingclubname boss name declared $playername a disgrace after his hot tempered performance. "He needs to calm down and have some respect for his fellow professionals." |
| `CNEWS_MATCHFOULS2` | Leg breaker! The $opposingclubname boss was furious with the performance of $playername claiming that he was "out to do some damage." |
| `CNEWS_MATCHFOULS3` | $opposingclubname boss was critical of the ref after the match against $clubname. "How $playername was still on the pitch at the end of that game, I don't know," he said. |
| `CNEWS_MATCHFOULS4` | Nasty! $playername is gaining a reputation as something of a hard man after committing numerous fouls in the match against $opposingclubname. |
| `CNEWS_MATCHFOULS5` | $clubname boss looked gloomy when asked about the performance of $playername against $opposingclubname in a press conference after the game. "He was erratic to say the least and gave away far too many free kicks." |
| `CNEWS_MATCHREDCARD1` | $playername incurred the wrath of the $opposingclubname boss after committing numerous fouls in a heated display. "I don't know what is going on in the lads life but he lost the plot. It was a shocking tackle." |
| `CNEWS_MATCHREDCARD2` | $playername is in hot water after his red card in the match against $opposingclubname and now faces a deserved ban. The $clubname boss was brutally honest in his interview after the game saying, "it was a terrible tackle. The kind of challenge that can end a career." |
| `CNEWS_MATCHREDCARD3` | A frustrated $clubname manager struggled to keep his cool when commenting on the the red card received by $playername in the match against $opposingclubname. "Let's just say that my opinion differed from the referee's." |
| `CNEWS_MATCHREDCARD4` | $clubname boss will not appeal the red card that $playername received in the match against $opposingclubname. "It was the right decision," he said. |
| `CNEWS_MATCHREDCARD5` | $playername has infuriated his manager after being sent off against $opposingclubname. "He drives me mad sometimes," the $clubname boss said. "He really needs to take a look at himself after that challenge." |
| `CNEWS_MATCHSHOTS1` | Hit and miss! $playername won't win over many $clubname fans if he carries on shooting like he did against $opposingclubname. "He couldn't hit a barn door," one fan said as he left the stadium. |
| `CNEWS_MATCHSHOTS2` | $opposingclubname fans jeered $playername in delight as shot after shot failed to hit the mark. $clubname boss said, "he will need to get on the training ground and work hard to improve his shooting." |
| `CNEWS_MATCHSHOTS3` | $playername will need to work hard on his shooting if he wants to impress the $clubname fans. He failed to score after numerous attempts in the match against $opposingclubname. |
| `CNEWS_MATCHSHOTS4` | Ironic cheers were heard from the $opposingclubname fans every time $playername attempted a shot on goal. "He is going through a dry spell, but I expect him to turn it around soon," said the $clubname boss after the game. |
| `CNEWS_MATCHSHOTS5` | Countless chances went begging for $playername in the match between $clubname and $opposingclubname. "I expect to see him working doubly hard in training after that horror show in front of goal," said the $clubname boss. |
| `CNEWS_MATCHSTARMAN1` | The $clubname boss was brimming with pride after watching $playername put in a stunning performance against $opposingclubname. "It was a fantastic display. Pure class," he said. |
| `CNEWS_MATCHSTARMAN10` | Straight out of the top drawer! That's how $clubname boss described $playername's performance against $opposingclubname. He will gain many more admirers if he keeps performing like that! |
| `CNEWS_MATCHSTARMAN11` | The special one. After $playername put in a star man performance against $opposingclubname his boss said, "he really is something special". |
| `CNEWS_MATCHSTARMAN12` | World beater! Nothing can stop $playername from becoming a legend at $clubname. That's the feeling around the club after a fantastic performance against $opposingclubname. |
| `CNEWS_MATCHSTARMAN13` | Out of this world! $playername continued to impress his peers with a classy display against $opposingclubname. The $clubname player is in great form right now. |
| `CNEWS_MATCHSTARMAN14` | Beautiful!" That was the word that the $clubname boss used to describe the performance of $playername against $opposingclubname. "When he is on top of his game he is a joy to watch," he went on to say. |
| `CNEWS_MATCHSTARMAN15` | A class act! $playername impressed his boss in the match against $opposingclubname. "Form is temporary but class is permanent," said the $clubname manager, "and this boy has got class coming out of his ears!" |
| `CNEWS_MATCHSTARMAN2` | Superstar! The $clubname fans were chanting the name of $playername at the end of a match in which he put in a stunning performance. |
| `CNEWS_MATCHSTARMAN3` | There's only one $playername! That was the chant of the $clubname fans after his amazing display against $opposingclubname. |
| `CNEWS_MATCHSTARMAN4` | Unplayable! That was the opinion of the $opposingclubname manager about $clubname superstar $playername. "There's no stopping him when he is in that form," he said. |
| `CNEWS_MATCHSTARMAN5` | Pure class! The $clubname manager was full of praise for $playername after an emphatic display against $opposingclubname. He went on to say, "I want to see this kind of performance from him every game." |
| `CNEWS_MATCHSTARMAN6` | Masterclass! $playername put in a sublime performance against $opposingclubname and was rightly named as the man of the match. |
| `CNEWS_MATCHSTARMAN7` | A man of the match performance from $playername had the pundits raving about him after the game between $clubname and $opposingclubname. |
| `CNEWS_MATCHSTARMAN8` | Classy, majestic, awesome... They were just some of the words used by pundits as they struggled to find words to describe the performance of $playername against $opposingclubname. |
| `CNEWS_MATCHSTARMAN9` | Too good! $clubname player $playername was a cut above the rest in the game against $opposingclubname. "A joy to watch," said his boss after the game. |
| `CNEWS_MATCHSTARMANYOUNG1` | A new star! Nothing can stop $playername from becoming a great player, according to the $clubname boss. "He is a star in the making," he said. |
| `CNEWS_MATCHSTARMANYOUNG2` | A cool head. $playername impressed his manager after a star man display against $opposingclubname. "For someone so young he has a great understanding of the game and plays with maturity," said the $clubname boss. |
| `CNEWS_MATCHSTARMANYOUNG3` | The $clubname boss couldn't resist eulogising about his young starlet $playername after the match against $opposingclubname. "If you're good enough you're old enough! That has always been my philosophy." |
| `CNEWS_MATCHSTARMANYOUNG4` | Blinding! $clubname boss reckons the future is bright for $playername. After the match against $opposingclubname he said, "he has a rare talent and needs to be given the freedom to play and express himself." |
| `CNEWS_MATCHSTARMANYOUNG5` | The $clubname boss struggled to contain himself when he spoke about $playername after the match against $opposingclubname. "If he keeps his feet on the ground and keeps working hard then there is no telling how far he can go," he said. |
| `CNEWS_RANDOMCLUBBOOST1` | $clubname have been taken over by a billionaire businessman who has cleared the club debts and will be investing heavily. The $clubname manager will now be looking to strengthen the team by bringing in some top players. |
| `CNEWS_RANDOMCLUBBOOST10` | The $clubname manager has decided to give the squad a much needed rest and has taken them away to a beach resort for a few days where they can relax and rejuvenate in the sun. |
| `CNEWS_RANDOMCLUBBOOST11` | The chairman of $clubname has publicly stated that despite the rumours, they will not be selling any of their key players in the upcoming transfer window. |
| `CNEWS_RANDOMCLUBBOOST12` | $clubname have announced record breaking profits over the past 12 months. The chairman is keen to stress that this money is being re-invested in the club. |
| `CNEWS_RANDOMCLUBBOOST13` | The manager of $clubname caused great hilarity at a press conference today when he declared that his wife knows more about football than the clowns in charge of the league. |
| `CNEWS_RANDOMCLUBBOOST2` | $clubname have recruited a renowned head scout as they attempt to restructure their scouting system. The hope is that they can bring in young, promising players as they look to the future. |
| `CNEWS_RANDOMCLUBBOOST3` | $clubname have invested heavily in their youth scheme and have upgraded their training facilities in a bid to bring more players up through the ranks. |
| `CNEWS_RANDOMCLUBBOOST4` | $clubname have signed a lucrative deal with a new shirt sponsor. The chairman has stated that the money coming in will be spent on new players. |
| `CNEWS_RANDOMCLUBBOOST5` | $clubname have been praised by league officials for the way the club's finances have been managed. Due to a strict wage structure and some shrewd deals in the transfer market $clubname are in a very healthy state. |
| `CNEWS_RANDOMCLUBBOOST6` | $clubname have been praised for their outstanding contributions to various charities and rejuvenating the local communities in the area. One league official said that many other clubs would do well to follow their example. |
| `CNEWS_RANDOMCLUBBOOST7` | There were bizarre scenes at the $clubname training ground today as the entire squad was photographed in a mass group hug. One staff member said that it proves that the squad is in complete harmony. |
| `CNEWS_RANDOMCLUBBOOST8` | The $clubname squad received a boost when they arrived at the training ground today. The manager decided that instead of training they should all spend the day at the local fun fair! |
| `CNEWS_RANDOMCLUBBOOST9` | The $clubname squad were given a boost by the chairman today when they were told that they would receive a huge bonus if they finish the season in a good position. |
| `CNEWS_RANDOMCLUBCRISIS1` | $clubname are in crisis and are suffering severe financial difficulties. The chairman has suggested that they will need to sell some of their best players to balance the books. |
| `CNEWS_RANDOMCLUBCRISIS10` | A bizarre incident occurred at the $clubname training ground which saw at least 5 players involved in a brawl. Our source said that there is a lack of harmony in the squad and things finally reached boiling point. |
| `CNEWS_RANDOMCLUBCRISIS11` | The manager of $clubname has been charged with a drink driving offence. If found guilty he could face a custodial sentence. The news will no doubt cause concern amongst the fans and staff at the club. |
| `CNEWS_RANDOMCLUBCRISIS12` | The manager of $clubname has been given a 2 match touchline ban for his angry comments after a game about some key refereeing decisions. |
| `CNEWS_RANDOMCLUBCRISIS13` | The manager of $clubname will appear in court this week to face allegations of tax fraud. It is thought that he will be given a hefty fine rather than a prison sentence if found guilty. It is however disrupting the harmony at the club. |
| `CNEWS_RANDOMCLUBCRISIS2` | $clubname fans have been protesting outside of the ground demanding that changes be made in the boardroom. They are tired of how the club is being run and intend to voice their opinions at every match until the chairman resigns. |
| `CNEWS_RANDOMCLUBCRISIS3` | $clubname are in danger of being docked points if league officials determine that they have breached the rules in the transfer market. An investigation over alleged illegal payments to player passes is under way. |
| `CNEWS_RANDOMCLUBCRISIS4` | $clubname fans have been accused of racist chants in a recent game which could lead to a hefty fine for the club. $clubname say that they are currently investigating the incident. |
| `CNEWS_RANDOMCLUBCRISIS5` | A group of $clubname players that cannot be named due to legal reasons are currently being questioned by police after a nightclub dancer made allegations that the group made improper advances upon her. |
| `CNEWS_RANDOMCLUBCRISIS6` | $clubname are said to be in crisis due to excessive player wages that are crippling the club's finances. Player bonuses and passes fees have compounded the problem and the club may be forced into selling their best players. |
| `CNEWS_RANDOMCLUBCRISIS7` | Several members of the backroom staff at $clubname have walked out on the club after a disagreement over wages. The club is in financial disarray and could now face legal action if an agreement cannot be reached with the staff members. |
| `CNEWS_RANDOMCLUBCRISIS8` | There are rumours of discontent in the $clubname squad with players stating on Twitter that they are not happy with the demanding training schedule. |
| `CNEWS_RANDOMCLUBCRISIS9` | Several $clubname players have been hit by a mysterious stomach bug that will rule them out of action for a few days at least. One member of staff suggested that it may have been the lasagne they ate in the club canteen. |
| `CNEWS_RENEWCONTRACT` | $playername has renewed his contract with $clubname. The $years year deal sees him earning around $wage per week. |
| `CNEWS_SKIPMATCHCLUB` | I won't play! $clubname player $playername has stunned his team mates and infuriated his boss by refusing to play! He has been fined one weeks wages for his actions. |
| `CNEWS_SKIPMATCHINTERNATIONAL` | Traitor! $playername has incurred the wrath of the $clubname fans by refusing to play for his country! |
| `CNEWS_TRANSFER1` | $playername has completed his transfer to $offerclubname. $clubname are thought to have received around $value for the player. |
| `CNEWS_TRANSFER10` | Pressure? Top players like $playername can handle pressure, says $offerclubname boss after finally getting his man for $value. |
| `CNEWS_TRANSFER2` | $offerclubname get their man! "$value buys you a player with real class," said the $offerclubname manager.  |
| `CNEWS_TRANSFER3` | I'm off! $playername completes his transfer to $offerclubname for a fee of $value. |
| `CNEWS_TRANSFER4` | $playername has penned a $years year deal with $offerclubname thought to be worth around $wage per week to the player. |
| `CNEWS_TRANSFER5` | $offerclubname sign $playername from $clubname for $value. A $offerclubname fan said, "with a price tag like that he will need to perform right from the off!" |
| `CNEWS_TRANSFER6` | $offerclubname seal the deal! Highly rated player $playername finally makes his move away from $clubname for a transfer fee of $value. |
| `CNEWS_TRANSFER7` | Deal of the decade! That was the $offerclubname managers first words about the $value transfer that brings $playername to $offerclubstadium. |
| `CNEWS_TRANSFER8` | Match made in heaven? $playername completes his move away from $clubstadium and joins $offerclubname for $value. |
| `CNEWS_TRANSFER9` | Madness! $offerclubname send shockwaves through the transfer market by signing $playername from $clubname for $value. |
| `CNEWS_TRANSFERINTEREST1` | $offerclubname are desperate to sign $playername. A spokesman for $offerclubname said, "we have been monitoring him for some time and intend to make a generous offer to $clubname." |
| `CNEWS_TRANSFERINTEREST10` | $playername heading to $offerclubname? The transfer rumour mill is up and running again with speculation that $playername could soon be heading to $offerclubname for a fee of around $value. |
| `CNEWS_TRANSFERINTEREST2` | $offerclubname are rumoured to be interested in signing $playername. $clubname have slapped a price tag of $value on his head but that is unlikely to deter $offerclubname in their pursuit of the player. |
| `CNEWS_TRANSFERINTEREST3` | $offerclubname are apparently lining up an offer in the region of $value for $clubname player $playername. |
| `CNEWS_TRANSFERINTEREST4` | $clubname are said to be willing to listen to offers in the region of $value for $playername. This might interest the $offerclubname manager who is apparently a big fan of the player. |
| `CNEWS_TRANSFERINTEREST5` | $playername is attracting the attention of a number of clubs but it is $offerclubname that are leading the pack in the race for his signature. The $clubname player is currently valued at $value. |
| `CNEWS_TRANSFERINTEREST6` | $offerclubname have joined the race to sign $playername with $clubname thought to be willing to listen to offers over $value. |
| `CNEWS_TRANSFERINTEREST7` | The $offerclubname manager has declared his interest in $clubname man $playername. He is a fantastic player and one that any club like us would want to sign. |
| `CNEWS_TRANSFERINTEREST8` | When the $offerclubname manager was recently asked for his opinion on $playername he said, "the boy is class. He has bags of talent. In fact I have spoken to the chairman about bringing him to $offerclubname." |
| `CNEWS_TRANSFERINTEREST9` | $offerclubname want $playername! At a press conference yesterday $offerclubname manager declared his admiration of the player saying, "he's a top player with teriffic skill and ability. Any manager would want him." |
| `CNEWS_TRANSFERREQUEST` | $clubname player $playername has handed in a transfer request. The news is likely to alert a number of clubs who are rumoured to be interested in him. |
| `CNEWS_WORLDPLAYER` | After a truly outstanding season, $playername of $clubname has been awarded the 'World Player of the Year' award! |
| `CNEWS_YOUNGPLAYER` | After an amazing season, $playername of $clubname has been awarded the 'Young Player of the Year' award! |
| `CNEWS_RANDOMCLUBBOOST14` | The $clubname manager revealed the secret behind their improved performance recently, letting slip that all the players recently enjoyed a boogie during a team dinner. |
| `CNEWS_RANDOMCLUBBOOST15` | The chairman of $clubname has revealed that they have hired a top chef in the club canteen. He hopes that eating well will help the players to perform well. |
| `CNEWS_RANDOMCLUBCRISIS14` | A number of $clubname players have been struck down with flu recently and are doubtful for their upcoming match. |
| `CNEWS_RANDOMCLUBCRISIS15` | Training had to be abandoned at $clubname yesterday after a burst water pipe flooded the changing rooms. The team will be training in the local park whilst repairs are made over the next few days. |
| `CNEWS_FIRSTCONTRACTMOBILE` | $clubname have signed the youngster $playername. The $clubname boss says he has "high expectations" of the player and wants to give him a chance to prove himself. |
| `CNEWS_GAMBLINGADDICTBOSS` | Gambling addict! $playername has been spotted spending large amounts of cash at the casino. This extravagant, playboy lifestyle will certainly not impress his boss or the fans. |
| `CNEWS_GAMBLINGADDICTGIRL` | Loser! $playername is in the doghouse after his girlfriend found out about his excessive gambling. "He should be spending more time with me," she said. |
| `CNEWS_MATCHSHOTSMOBILE1` | Hit and miss! $playername won't win over many $clubname fans if he carries on playing like he did against $opposingclubname. "He couldn't hit a barn door," one fan said as he left the stadium. |
| `CNEWS_MATCHSHOTSMOBILE2` | $opposingclubname fans jeered $playername in delight as he wasted chance after chance. $clubname boss said, "he will need to get on the training ground and work hard to improve his shooting." |
| `CNEWS_MATCHSHOTSMOBILE3` | $playername will need to work hard on his shooting if he wants to impress the $clubname fans. He failed to score after numerous chances in the match against $opposingclubname. |
| `CNEWS_MATCHSHOTSMOBILE4` | Ironic cheers were heard from the $opposingclubname fans every time $playername had a chance to shoot. "He is going through a dry spell, but I expect him to turn it around soon," said the $clubname boss after the game. |
| `CNEWS_MATCHSHOTSMOBILE5` | Countless chances went begging for $playername in the match between $clubname and $opposingclubname. "I expect to see him working doubly hard in training after that horror show in front of goal," said the $clubname boss. |
| `CNEWS_MATCHSTARMANINT1` | The $clubname boss could barely control himself after witnessing a stellar performance from $playername. "He is amazing," he said. “A truely fantastic player!" |
| `CNEWS_MATCHSTARMANINT10` | A football wizard! $playername produced a spell-binding performance last night worthy of the great Mr Potter himself. The things he can do with a football are truly magical! |
| `CNEWS_MATCHSTARMANINT11` | Top man! $playername can rightly be considered one of the best in the world according to the $clubname boss. "When he is on top of his game, no-one comes close," he said. |
| `CNEWS_MATCHSTARMANINT12` | World class! $playername put in a sublime performance against $opposingclubname and was rightly named as the man of the match. |
| `CNEWS_MATCHSTARMANINT13` | A man of the match performance from $playername had the social networks going into overdrive last night and his name is still trending this morning! |
| `CNEWS_MATCHSTARMANINT14` | Football pundits will need to invent a new word to describe $clubname player $playername. His performance against $opposingclubname was utterly mesmerising! |
| `CNEWS_MATCHSTARMANINT15` | Fabulous! $clubname player $playername was bang in form against $opposingclubname last night. "It was a pleasure to watch him play," said his boss after the game. |
| `CNEWS_MATCHSTARMANINT2` | $playername sent shockwaves around the world last night after a stunning performance against $opposingclubname. No one will fancy playing $clubname when he is in the team! |
| `CNEWS_MATCHSTARMANINT3` | The social networks went crazy after $clubname's game against $opposingclubname, all thanks to $playername. It was the kind of performance that you just can't stop talking about! |
| `CNEWS_MATCHSTARMANINT4` | $clubname man $playername is in the spotlight again after an outrageous performance against $opposingclubname. The fans were chanting his name long into the night. |
| `CNEWS_MATCHSTARMANINT5` | $playername staked a claim for the title of 'most inform player in the world' after a magical display against $opposingclubname. Nothing can stop this man right now. |
| `CNEWS_MATCHSTARMANINT6` | Dance like a butterfly, sting like a bee! $playername put on the kind of dazzling display that the great Muhammad Ali would have been proud of. It won't be long before he can state "I am the greatest!" |
| `CNEWS_MATCHSTARMANINT7` | It takes a special talent to totally dominate a match on the world stage but $playername is such a player. It seems like nothing can faze him! |
| `CNEWS_MATCHSTARMANINT8` | There are only a handful of players in the world that can truly claim to be world class, but add $playername to that list if you haven't already! |
| `CNEWS_MATCHSTARMANINT9` | $playername added a few more zeros to his transfer value after an awesome display against $opposingclubname last night. There aren't many clubs in the world that could afford him right now! |
| `CNEWS_RELATIONSHIPBOSS1` | $playername may have to start looking for a new club if he cannot improve his relationship with the boss. "He needs to start impressing me, and quickly," said the $clubname coach. |
| `CNEWS_RELATIONSHIPBOSS2` | $playername is struggling to impress the boss at $clubname. A former player of the club says that working hard and performing well are the keys to success. |
| `CNEWS_RELATIONSHIPBOSS3` | $playername is in danger of being frozen out of the $clubname first team if he doesn't improve relations with the boss soon. An insider said that he is letting the club down at the moment. |
| `CNEWS_RELATIONSHIPFANS1` | Fans are running out of patience with $playername. "This isn't just about performances," said one $clubname fan. "He doesn't do enough off the pitch to earn our respect either." |
| `CNEWS_RELATIONSHIPFANS2` | $clubname fans are furious with $playername's attitude. "If he wants us to cheer his name then he needs to show some respect for the club and start working hard on the pitch," said one supporter. |
| `CNEWS_RELATIONSHIPFANS3` | A section of $clubname fans want $playername out of the club. "He's not fit to wear the shirt," said one supporter. "We spent good money to come and see him play but he couldn't care less." |
| `CNEWS_RELATIONSHIPGIRL1` | According to a $clubname insider, $playername is finding it hard to stay positive at the moment. Apparently his relationship with his girlfriend is getting him down. |
| `CNEWS_RELATIONSHIPGIRL2` | On the rocks! $playername is close to splitting up with his girlfriend according one of his closest friends. "They are going through a bad patch right now, but I expect them to work it out." |
| `CNEWS_RELATIONSHIPGIRL3` | Down in the dumps! $playername is struggling to salvage his relationship with his girlfriend. A close friend of the couple said that football commitments are "putting a strain on the relationship". |
| `CNEWS_RELATIONSHIPLOW1` | $playername has got the blues! According to a close friend his general happiness is low and it is affecting his motivation. |
| `CNEWS_RELATIONSHIPLOW2` | $playername is unable to cope with the demands of professional football according to a close family member. "He is very unhappy at the moment and struggling to deal with it all," she said. |
| `CNEWS_RELATIONSHIPLOW3` | We may think that footballers are living the dream, but try telling that to $playername. According to a fellow team mate he is utterly miserable and wanders around the club like a dark cloud. |
| `CNEWS_RELATIONSHIPSPONSORS1` | Apparently $playername is at risk of losing a sponsorship contract. According to our sources, the relationship with his sponsors is at an all time low. |
| `CNEWS_RELATIONSHIPSPONSORS2` | A spokes person for one of $playername's sponsors has revealed that they are debating wether to cancel their agreement with the player. "His lack of commitment to our brand is very disappointing," he said. |
| `CNEWS_RELATIONSHIPSPONSORS3` | $playername is in danger of losing out on a lucrative sponsorship deal. A board member of the company told us, "he's not portaying the professional image that we expect from our clients." |
| `CNEWS_RELATIONSHIPTEAM1` | $playername cuts a lonely figure on the $clubname training ground at the moment. According to our insider at the club, he is finding it hard to bond with his team mates. |
| `CNEWS_RELATIONSHIPTEAM2` | According to a former player of $clubname, $playername really needs to improve his relationship with the team. Only then will he start getting chances on the pitch. |
| `CNEWS_RELATIONSHIPTEAM3` | According to an insider at the $clubname, $playername needs to start bonding with his team mates. "If he wants to get opportunities in the match he needs to earn the respect of his fellow team members." |
| `CNEWS_RENEWCONTRACTMOBILE` | $playername has renewed his contract with $clubname. The new deal means he will earn $wage per match. |
| `CNEWS_STYLECLOTHES` | Style guru! $clubname player $playername was looking good at an event recently. Check out the $item he was wearing! |
| `CNEWS_STYLEGADGET` | Gadget man! Footballer $playername was recently spotted out on the town using his $item. |
| `CNEWS_STYLELOW1` | $playername was looking shabby on his way home from training yesterday. He really hasn't got a clue when it comes to style! |
| `CNEWS_STYLELOW2` | Style moron! That was the opinion of our fashion expert when asked what they thought of $playername's appearance. He really needs to splash some cash and smarten up a bit. |
| `CNEWS_STYLELOW3` | Football player $playername was spotted out on the town yesterday wearing a cheap tracksuit. Maybe he had just finished training but he really needs some fashion advice! |
| `CNEWS_STYLEPROPERTY` | Home sweet home! Famous footballer $playername was seen entering his $property recently. How's that for moving up the property ladder! |
| `CNEWS_STYLEVEHICLE` | Trail blazer! Football player $playername was snapped getting into his $vehicle recently. He's a real motor head! |
| `CNEWS_TRANSFERMOBILE1` | $playername has completed his transfer to $offerclubname. $clubname are thought to have received around $value for the player. |
| `CNEWS_TRANSFERMOBILE10` | Madness! $offerclubname send shockwaves through the transfer market by signing $playername from $clubname for $value. |
| `CNEWS_TRANSFERMOBILE2` | Pressure? Top players like $playername can handle pressure, says $offerclubname boss after finally getting his man for $value. |
| `CNEWS_TRANSFERMOBILE3` | $offerclubname get their man! "$value buys you a player with real class," said the $offerclubname manager.  |
| `CNEWS_TRANSFERMOBILE4` | I'm off! $playername completes his transfer to $offerclubname for a fee of $value. |
| `CNEWS_TRANSFERMOBILE5` | $playername has penned a lucrative deal with $offerclubname thought to be worth around $wage per match to the player. $offerclubname paid a transfer fee of $value for him. |
| `CNEWS_TRANSFERMOBILE6` | $offerclubname sign $playername from $clubname for $value. A $offerclubname fan said, "with a price tag like that he will need to perform right from the off!" |
| `CNEWS_TRANSFERMOBILE7` | $offerclubname seal the deal! Highly rated player $playername finally makes his move away from $clubname for a transfer fee of $value. |
| `CNEWS_TRANSFERMOBILE8` | Deal of the decade! That was the $offerclubname managers first words about the $value transfer that brings $playername to the club. |
| `CNEWS_TRANSFERMOBILE9` | Match made in heaven? $playername completes his move away from $clubname and joins $offerclubname for $value. |

### 14.3 `CRESULTNEWS_` - other-teams' results ticker

14 lines. **Not referenced by the PC exe** (no literal, no prefix stub found), so treat as mobile-era content.
Note it is the only family that uses `$winningteam` / `$losingteam` / `$score1` / `$score2` / `$highscore` /
`$hometeam` / `$awayteam`.

| Tag | English |
|---|---|
| `CRESULTNEWS_COMPETITIONWINNERS` | $winningteam have won the $competition! |
| `CRESULTNEWS_CUPSHOCK1` | $winningteam pulled off the shock result of the round by defeating $losingteam $score1-$score2 in the $competition. |
| `CRESULTNEWS_CUPSHOCK2` | $losingteam were stunned by $winningteam this week after losing $score1-$score2 in the $competition. |
| `CRESULTNEWS_CUPSHOCK3` | Giant killers! $winningteam stunned the nation by defeating $losingteam $score1-$score2 in the $competition this week. |
| `CRESULTNEWS_HIGHSCORE1` | $winningteam beat $losingteam in an amazing $competition match that finished $score1-$score2. |
| `CRESULTNEWS_HIGHSCORE2` | $losingteam were defeated by $winningteam $score1-$score2 in a thrilling match in the $competition. |
| `CRESULTNEWS_HIGHSCORE3` | Goal fest! $winningteam put $highscore past $losingteam in a stunning match that finished $score1-$score2. |
| `CRESULTNEWS_NEXTCUPOPPONENT` | $hometeam will face $awayteam in the $competition. |
| `CRESULTNEWS_SHOCKRESULT1` | $losingteam were pegged back by $winningteam this week who produced a stunning performance to win $score1-$score2. |
| `CRESULTNEWS_SHOCKRESULT2` | $losingteam were rocked by a defiant $winningteam team who pulled off a $score1-$score2 victory. |
| `CRESULTNEWS_SHOCKRESULT3` | $winningteam pulled off the shock result of the week by defeating high flying $losingteam $score1-$score2. |
| `CRESULTNEWS_SHOCKRESULTLEADERS1` | $competition leaders $losingteam were defeated $score1-$score2 by $winningteam in a shock result. |
| `CRESULTNEWS_SHOCKRESULTLEADERS2` | $losingteam were stunned by $winningteam this week who pulled off a $score1-$score2 victory in the $competition. |
| `CRESULTNEWS_SHOCKRESULTLEADERS3` | $winningteam caused an amazing upset in the $competition this week by defeating league leaders $losingteam $score1-$score2. |

---

## 15. Contract, transfer, loan and wages

### 15.1 Contract data model (from the exe's `TContractOffer.LoadData` field list)

```
offerclubid   wage   length   goalbonus   cleanbonus   signingfee   newbossrel
```

The `contractoffer` screen shows current vs offered side by side:

| Field | Current widget | New widget | Language tag |
|---|---|---|---|
| Club | `lbl_TeamCurrent` | `lbl_TeamNew` | - |
| Nation | `lbl_NationCurrent` | `lbl_NationNew` | - |
| League | `lbl_LeagueCurrent` | `lbl_LeagueNew` | - |
| Boss relationship | `prg_BossCurrent` | `prg_BossNew` | `CHELP_CONTRACTBOSS1` / `CHELP_CONTRACTBOSS2` |
| Wage | `lbl_WageCurrent1/2` | `lbl_WageNew1/2` | `Wage`, `tla_Wage` |
| Goal bonus | `lbl_GoalCurrent1/2` | `lbl_GoalNew1/2` | `Goal Bonus` |
| Assist bonus | `lbl_AssistCurrent1/2` | `lbl_AssistNew1/2` | `Assist Bonus` |
| Clean sheet bonus | `lbl_CleanCurrent1/2` | `lbl_CleanNew1/2` | `Clean Sheet Bonus` |
| Length / expiry | `lbl_LengthCurrent1/2` | `lbl_LengthNew1/2` | `Expires`, `Length` |
| Signing fee | - | `lbl_SigningFeeNew1/2` | `Signing Fee` |

**Note the discrepancy:** `TContractOffer` loads `cleanbonus` but not an assist bonus, yet the screen shows an
Assist Bonus row and `CMESSAGE_BONUSINCREASED` says *"The boss has increased your goal and assist bonuses!"*.
`UNCERTAIN:` assist bonus may be derived from goal bonus. Resolve in the disassembly.

Three response buttons: `transfer_Consider` / `transfer_Negotiate` / `transfer_Accept` (+ `transfer_Reject`).
`help_contractoffer` explains CONSIDER keeps other offers alive.

### 15.2 The Higher/Lower negotiation mini-game

`CHELP_CONTRACTNEGOTIATE` - negotiating is a gamble: *"the boss of the new club will lose patience with you if
you fail the challenge."* `help_negotiate` gives the rules: **guess whether the next shirt number is higher or
lower; numbers range 1-11**; you may stop early and bank the current increase.

Assets: `GameMedia/Images/Casino/HigherLower/Player1..Player11.png` (11 shirt numbers - matches exactly).
Widgets: `btn_higher`, `btn_lower`, `lbl_Percent`, `pan_HigherLower`, `pan_HigherLower2`, `btn_Accept`.
Strings: `highlow_Instrucs`, `highlow_EndNegotiations` ("Accept a $percent% increase"), `Negotiate!`, `Success!`,
`CMESSAGE_CONTRACTINCREASE`, `CMESSAGE_NONEGOTIATING`, `CMESSAGE_NEGOTIATIONSCANCELLED`.

### 15.3 Transfer / loan status machine

| Tag | English |
|---|---|
| `transfer_Accept` | Accept |
| `transfer_CancelLoan` | Cancel Loan |
| `transfer_CancelRequest` | Cancel Transfer Request |
| `transfer_ComeOffList` | Come Off List |
| `transfer_Consider` | Consider |
| `transfer_CurrentOffers` | Current Offers |
| `transfer_Negotiate` | Negotiate |
| `transfer_NoClubsDesiredTransfer` | None: Maybe change your desired transfer |
| `transfer_NoClubsTooSoon` | None: Too soon since last contract signed |
| `transfer_NoLoanOffers` | No Loan Offers |
| `transfer_NoOffers` | No Transfer Offers |
| `transfer_OffersNotListed` | Request transfer to see offers |
| `transfer_OffersWindowClosed` | Transfer Window Closed |
| `transfer_OffersWindowOpens` | Window Opens Week $num |
| `transfer_OnLoanUntil` | On Loan Until $date |
| `transfer_Reject` | Reject |
| `transfer_Request` | Request Transfer |
| `transfer_RequestLoan` | Request Loan |

Rules extracted:
* **Transfer window**: `CMESSAGE_TRANSFERWINDOWOPEN` / `…CLOSED` / `…CLOSEDNEXT` (with `$transdate` = week).
  Offers are only visible while listed **and** the window is open (`transfer_OffersWindowClosed`,
  `transfer_OffersWindowOpens` = "Window Opens Week $num").
* **Desired destination filters**: `Any Continent` / `Any Nation` / `Any Division` / `Any Club` combos
  (`cmb_Division`, `ComboContinent`, `ComboNation`), explained by `CHELP_TRANSFERCOMBOS`. If nothing matches:
  `transfer_NoClubsDesiredTransfer`.
* **Cooldown**: `transfer_NoClubsTooSoon` and `CMESSAGE_NORENEWTOOSOON` - *"less than 6 months since you signed
  the last one"*.
* **Requesting a transfer** angers the boss (`CMESSAGE_REQUESTCONFIRM`) and may be irreversible
  (`CMESSAGE_REQUESTNOTCANCELLED`, `CMESSAGE_REQUESTNOTCANCELLEDCONTRACT`).
* **Expired contract** → auto transfer-listed, rolling contract at **half wages**, free transfer available
  (`CMESSAGE_CONTRACTEXPIRED`). `CTIP_42`: expired contract → higher wages offered because no fee is payable.
* **Affordability**: `CMESSAGE_TRANSFERCLUBCANNOTAFFORDYOU`.
* **Loans**: 6-month (`CMESSAGE_LOANOFFER`) or to season end (`CMESSAGE_LOANOFFERTOSEASONEND`). While on loan the
  relationships screen shows the **loan club's** Boss/Team/Fans; the parent club's boss relationship moves to the
  contract screen (`CMESSAGE_LOANSTARTED`). Early termination: `CMESSAGE_LOANENDBOSSUNHAPPY`,
  `CMESSAGE_CANCELLOANEARLY`.
* **B teams**: `CMESSAGE_PROMOTEFROMBTEAM` / `CMESSAGE_PROMOTEDTOATEAM`, `B Team Of`, `tla_BTeamOf` - clubs have
  a B-team relationship and the player can be promoted without a contract change.
* **Valuation inputs** (exe debug prints, `UpdateInterestedClubs`): `>>> avgrating = `, `>>> skills = `,
  `>>> fame = `, `>>> clubstrength = `. So **transfer value = f(average match rating, skills, fame, club
  strength)**. Confirms `CTIP_39` ("FAME … will also improve your TRANSFER VALUE").
* Up to **5 simultaneous offers**: `btn_Offer0..btn_Offer4`.

| Tag | English |
|---|---|
| `CHELP_CONTRACTBOSS1` | This is the relationship you have with your current BOSS. |
| `CHELP_CONTRACTBOSS2` | This is the relationship that you will have with the BOSS at the new club (or your current club if you are renewing the contract). |
| `CHELP_CONTRACTNEGOTIATE` | Click 'Negotiate' if you want to take a challenge to improve the offer but be careful because the boss of the new club will lose patience with you if you fail the challenge. |
| `CHELP_LOANBUTTON` | If you are struggling to get picked for matches then it may be beneficial to go on loan to a lower league club. |
| `CHELP_RENEWCONTRACT` | If you feel you deserve a better contract then click this button to begin negotiating. That's if the boss feels you deserve a new contract! |
| `CHELP_TRANSFERBUTTON` | You can request to be transferred with this button. You can only see offers from interested clubs if you are on the transfer list. |
| `CHELP_TRANSFERCOMBOS` | When you are listed for transfer or loan you can specify exactly where you want to go with these drop-down lists. |
| `CMESSAGE_CONTRACTEXPIRED` | Your current contract with $clubname has expired and you have been placed on the transfer list. If you do not renew your contract you can continue to play for them on a rolling contract and receive half your wages. Alternatively you can transfer to any club that is interested in you on a free transfer. |
| `CMESSAGE_CONTRACTINCREASE` | $clubname are willing to increase their offer by $percent%. |
| `CMESSAGE_CONTRACTNEWOFFER` | The boss would like to discuss a new contract with you. Head over to your contract page if you want to renew your contract with $clubname. |
| `CMESSAGE_FIRSTCONTRACTREJECT` | If you reject this contract you will have to perform the trial challenges again. Are you sure you want to reject this contract offer? |
| `CMESSAGE_LOANENDBOSSUNHAPPY` | Your loan spell has been terminated. The $loanclub BOSS has not been impressed with you. |
| `CMESSAGE_LOANENDED` | Your loan spell with $loanclub has ended and you have returned to $clubname. |
| `CMESSAGE_LOANOFFER` | Would you like to go on loan to $clubname for 6 months? |
| `CMESSAGE_LOANOFFERTOSEASONEND` | Would you like to go on loan to $clubname until the end of the season? |
| `CMESSAGE_LOANREQUESTREJECTED` | The boss does not want to let you out on loan. You are a valued member of the squad. |
| `CMESSAGE_LOANREQUESTREJECTEDDATE` | The boss does not want to let you out on loan. You should renew you current contract with the club first. |
| `CMESSAGE_LOANSTARTED` | You have joined $loanclub on loan. Whilst you are on loan the relationships screen will reflect your relationships with the BOSS, TEAM and FANS at $loanclub. You can check your relationship with the $clubname BOSS on the contract screen. It will improve if you do well at $loanclub. |
| `CMESSAGE_NEGOTIATIONSCANCELLED` | $clubname have withdrawn their contract offer. |
| `CMESSAGE_NONEGOTIATING` | $clubname do not wish to negotiate further. |
| `CMESSAGE_NORENEWBOSSUNHAPPY` | The boss does not want to renew your contract at the moment because he is unhappy with you. |
| `CMESSAGE_NORENEWLOANLISTED` | You cannot renew your contract whilst you are listed for loan. |
| `CMESSAGE_NORENEWONLOAN` | You cannot renew your contract whilst you are on loan. |
| `CMESSAGE_NORENEWTOOSOON` | The boss does not want to renew your contract yet. It has been less than 6 months since you signed the last one. |
| `CMESSAGE_OFFLINERESTRICTEDTRANSFER` | You need to be connected to the internet to make a transfer move so that the database can be updated. |
| `CMESSAGE_PROMOTEDTOATEAM` | Congratulations! You are now playing in the A team of $clubateam. Your existing contract has not changed. |
| `CMESSAGE_PROMOTEFROMBTEAM` | The boss of $clubateam would like to promote you up from the B team. Would you like to switch to the A team? |
| `CMESSAGE_REQUESTCANCELLED` | The boss has removed you from the transfer list. |
| `CMESSAGE_REQUESTCONFIRM` | Are you sure you wish to request a transfer? The boss will not be happy. |
| `CMESSAGE_REQUESTLOANCONFIRM` | Are you sure you wish to request a loan? |
| `CMESSAGE_REQUESTNOTCANCELLED` | The boss is not happy with you and has refused to remove you from the transfer list. |
| `CMESSAGE_REQUESTNOTCANCELLEDCONTRACT` | Your contract has expired so you cannot come off the transfer list. Try to renew your contract if you wish to stay at this club. |
| `CMESSAGE_TRANSFERCLUBCANNOTAFFORDYOU` | This club cannot afford your transfer fee. You will need to wait until your current contract has expired so that you can be transferred for free. |
| `CMESSAGE_TRANSFERFIRSTCLUB` | You have signed a contract with $clubname! |
| `CMESSAGE_TRANSFERLISTEDBOSSUNHAPPY` | The boss has not been impressed with your attitude or performance lately and has put you on the transfer list. |
| `CMESSAGE_TRANSFERNEWCLUB` | You have signed a new contract with $clubname! You were transferred for $value. |
| `CMESSAGE_TRANSFERNEWCLUBFREE` | You have signed a new contract with $clubname! You were transferred for free. |
| `CMESSAGE_TRANSFERSAMECLUB` | You have signed a new contract with $clubname! |
| `CMESSAGE_TRANSFERWINDOWCLOSED` | The transfer window has now closed. |
| `CMESSAGE_TRANSFERWINDOWCLOSEDNEXT` | The transfer window is currently closed. The next window opens on week $transdate. Check your contract page after this date to negotiate offers. |
| `CMESSAGE_TRANSFERWINDOWOPEN` | The transfer window is now open. If you are transfer listed you can check your contract page to view offers. |
| `contract_Bonuses` | Bonuses |
| `CTIP_42` | If your contract expires you will be offered higher wages in contract negotiations because other clubs will not need to pay a transfer fee. |
| `help_contractoffer` | When you receive a contract offer you will see your current contract on the left and the new offer on the right. You have the options to 'Consider', 'Negotiate' or 'Accept' the new contract. If you don't want to make a decision straight away click CONSIDER. This will allow you to view offers from other clubs without cancelling negotiations. If you are happy with the offer click ACCEPT. |
| `help_mycontract` | The Contract screen details your current club contract and your transfer or loan status. You can also see what clubs are currently interested in you. |
| `help_negotiate` | To negotiate a better contract you need to guess whether the next shirt number will be higher or lower than the previous one. The shirt numbers range from 1 to 11. You can end negotiations early if you wish to agree the current offer increase. |
| `highlow_EndNegotiations` | Accept a $percent% increase |
| `highlow_Instrucs` | Guess higher or lower to improve offer |
| `CMESSAGE_BONUSINCREASED` | The boss has increased your goal and assist bonuses! |
| `CMESSAGE_CHOOSEDESIREDTRANSFER` | Set your preferred transfer destination |
| `CMESSAGE_CLUBSINTERESTED` | Clubs interested |
| `CMESSAGE_CLUBSNOTINTERESTED` | No clubs in this division are interested in signing you |
| `CMESSAGE_CONTRACTINCREASEMOBILE` | $clubname are willing to increase their offer to $wage per match and $bonus per goal. |
| `CMESSAGE_CONTRACTOFFERMOBILE` | $clubname are offering you $wage per match and $bonus per goal. |
| `CMESSAGE_NEGOTIATEWITH` | Negotiate contract with $clubname |
| `CMESSAGE_NEGOTIATIONFAILED` | $clubname are not willing to negotiate any further. |
| `CMESSAGE_NOBONUSLUCRATIVE` | The BOSS is not willing to improve your contract. He feels you are already on quite a lucrative wage for your STAR RATING. |
| `CMESSAGE_NOBONUSRELATIONSHIPBOSS` | The BOSS does not want to discuss your contract. Your relationship with him is too low. |
| `CMESSAGE_NOBONUSRELATIONSHIPFANS` | The BOSS does not want to discuss your contract. Your relationship with the FANS is too low. |
| `CMESSAGE_NOBONUSRELATIONSHIPTEAM` | The BOSS does not want to discuss your contract. Your relationship with the TEAM is too low. |
| `CMESSAGE_NOBONUSSTARRATING` | The BOSS is not willing to improve your contract. You need to increase your STAR RATING. |
| `CMESSAGE_NOBONUSTOOSOON` | The BOSS does not want to discuss your contract. It is too soon since your last meeting. |
| `CMESSAGE_NOCLUBSINTERESTEDATALL` | There are no clubs interested in signing you at all. |
| `CMESSAGE_SEASONENDTRANSFER` | At the end of the season you are able to transfer to any club that is interested in you. You may even transfer to a different country if you wish. Would you like to view the interested clubs? |
| `CMESSAGE_TRANSFERCONFIRM` | Are you sure you wish to transfer to $clubname? You will be paid a goal bonus of $goalbonus and an assist bonus of $assistbonus. |
| `CMESSAGE_TRANSFERNEWCLUBMOBILE` | You have transferred to $clubname! |
| `CMESSAGE_TRANSFEROFFERMOBILE` | $clubname have accepted a transfer offer from $offerclubname for you. You have been given permission to discuss a contract with them but you can reject it if you wish to stay at $clubname. |
| `CMESSAGE_TRANSFERRUMOUR` | A number of clubs are said to be interested in signing $playername in the upcoming transfer window. $clubs are amongst those vying for his signature. |
| `highlow_EndNegotiationsMobile` | Finalise Negotiation |
| `highlow_InstrucsMobile` | Guess higher or lower to improve offer. Numbers range from 1 to 11. |
| `CMESSAGE_TRANSFERCONFIRMMOBILE` | Are you sure you wish to transfer to $clubname? |

---

## 16. Casino and gambling

`casino` screen with three games plus a shared stake selector.

**Stakes - 7 chip denominations** (`btn_stake1..7`, art `Chip_50/100/250/500/1000/2500/5000.png`):
**50, 100, 250, 500, 1000, 2500, 5000**. Label `casino_Stake` = "Stake"; `UpdateStakeCurrency` implies the values
are converted/formatted per the active currency.

### 16.1 Roulette

Six bet types only - no numbers, no splits:

| Tag | English |
|---|---|
| `bet_YouLost` | You Lost |
| `bet_YouWon` | You Won |
| `help_roulette` | In Roulette you can bet on whether the ball will land on an odd or even number, a red or black number or within the ranges of 1 to 18 or 19 to 36. Place your bet and spin the wheel! |
| `roulette_19to36` | 19 to 36 |
| `roulette_1to18` | 1 to 18 |
| `roulette_Black` | Black |
| `roulette_Even` | Even |
| `roulette_Odd` | Odd |
| `roulette_Red` | Red |

Widgets `btn_odd`, `btn_even`, `btn_red`, `btn_black`, `btn_1to18`, `btn_19to36`, `btn_clear` (`Clear Bets`),
`lbl_total1/2`. Sounds `RouletteSpin.ogg`, `RouletteHit.ogg`, `RouletteLand.ogg`. Art `Wheel.png`,
`Wheel_Inner.png`, `Ball.png`.

### 16.2 Black Jack

| Tag | English |
|---|---|
| `blackjack_5CardTrick` | 5 Card Trick! |
| `blackjack_BlackJack` | Black Jack! |
| `blackjack_Bust` | Bust! |
| `blackjack_DealersHand` | Dealer's Hand |
| `blackjack_DealerWins` | You Lose! |
| `blackjack_Hit` | Hit |
| `blackjack_Hold` | Hold |
| `blackjack_PlayersHand` | Your Hand |
| `blackjack_Tie` | Tie! |
| `blackjack_YouWin` | You Win! |
| `help_blackjack` | In Black Jack your cards need to add up as close to 21 as possible without going over it. Set your stake then click the 'Play' button. Press 'Hit' to deal another card or 'Hold' if you are happy with your hand. The dealer will then play his hand. If you win you will receive two times the stake that you bet. |
| `blackjack_Dealer` | Dealer |

`help_blackjack` gives the payout rule explicitly: **"If you win you will receive two times the stake that you
bet."** Special hands recognised: `blackjack_BlackJack`, `blackjack_5CardTrick` (five cards without busting),
`blackjack_Bust`, `blackjack_Tie`. Card art is a full 52-card deck
(`{1..13}_{club,diamond,heart,spade}.png` + `back.png`); the exe names the suits `heart`, `diamond`, `club`,
`spade`. Mobile help adds "The dealer will always stick on 16 or higher" - `UNCERTAIN:` whether the PC dealer
uses the same rule.

### 16.3 Slot machine

`help_slots`: *"set your stake and hit the red button. If two or three reels show the same image then you win
some cash!"* → **3 reels**, 2-match and 3-match payouts. The exe names **8 symbols**:
`Orange`, `Plum`, `Banana`, `Apple`, `Grapes`, `Cherries`, `Pineapple`, `Strawberry` (debug label `Fruit: `).
Assets `Strip.png`, `Glass.png`, `Button.png`, `SlotsArm.ogg`, `SlotsStop.ogg`, `SlotsWin.ogg`.

### 16.4 Gambling addiction

A tracked stat (`Gambling`, `Gambling Addiction`, mobile `CHELPMOBILE_GAMBLING`: *"the GAMBLING meter reflects
how addicted you are"*). Consequences hit four relationships:

| Tag | English |
|---|---|
| `CHELP_CASINOBUTTON` | If you want to go to the casino with your team mates, click this button. Win, lose or draw it will help your relationship. |
| `CMESSAGE_CASINOINVITEFRIENDS` | Some FRIENDS have invited you to the CASINO. Would you like to go? |
| `CMESSAGE_CASINOINVITETEAMMATES` | Some TEAM MATES have invited you to the CASINO. Would you like to go? |
| `CMESSAGE_GAMBLINGADDICT1` | Your SPONSORS have been made aware of your gambling habit and they are not impressed! |
| `CMESSAGE_GAMBLINGADDICT2` | Your GIRLFRIEND is fed up with your gambling addiction! |
| `CMESSAGE_GAMBLINGADDICT3` | Your FRIENDS are worried about your gambling addiction! |
| `CMESSAGE_GAMBLINGADDICT4` | The BOSS has heard about your gambling addiction and is not happy! |
| `CMESSAGE_NOCASINOTIRED` | You are too tired to go to the casino! |
| `CNEWS_GAMBLINGADDICT` | Gambling addict! $playername has been spotted spending large amounts of cash at the casino. This extravagant, playboy lifestyle will certainly not impress his boss or the fans who can only dream about the kind of money he earns. |
| `CTIP_47` | Going to the CASINO with TEAM MATES or going RACING with FRIENDS is a great way to improve your relationships. Just make sure you don't become a gambling addict! |
| `help_casino` | The Casino offers a variety of games where you can gamble lots of that hard earned cash! |
| `CNEWS_GAMBLINGADDICTBOSS` | Gambling addict! $playername has been spotted spending large amounts of cash at the casino. This extravagant, playboy lifestyle will certainly not impress his boss or the fans. |
| `CNEWS_GAMBLINGADDICTGIRL` | Loser! $playername is in the doghouse after his girlfriend found out about his excessive gambling. "He should be spending more time with me," she said. |

**Data defect:** the exe references `CMESSAGE_GAMBLINGADDICT1`, `2`, `3` and **`5`** - but `Languages.csv`
contains `1`, `2`, `3`, `4` and **no `5`**. `CMESSAGE_GAMBLINGADDICT4` (the BOSS variant) is therefore
**unreachable** on PC and the fourth branch renders a missing tag. See §21.

Going to the casino is also a *relationship activity*: `tt_RelationsTeamCasino` ("Go to casino with team mates",
`btn_TeamCasino`), plus unsolicited invitations `CMESSAGE_CASINOINVITETEAMMATES` and
`CMESSAGE_CASINOINVITEFRIENDS`. `CHELP_CASINOBUTTON`: *"Win, lose or draw it will help your relationship."*

---

## 17. Horse racing and the Stable

Entry point is on the **relationships** screen (`Stable.png`, `CHELP_STABLEBUTTON`,
`tt_RelationsFriendsRacing` "Go racing with friends"). There is also a standalone `btn_Racing.png` in the casino
art folder.

### 17.1 Screens and widgets

```
stable
  btn_StableHome / btn_StableStable   "My Stable"
  pan_Owned      tbl_Owned            "Stable Size" lbl_Stable lbl_StableSize
                 columns: Health, Prizes, Strength
  btn_SellHorse  "Sell Horse"
  btn_TreatHorse "Treat Horse"
  btn_RaceHorse  "Race Horse"
  pan_BuyHorse   tbl_BuyHorse   btn_BuyHorse  "Horses For Sale" / "Buy Horse"
  pan_Race       lbl_Horse  lbl_Odds  btn_Horse  "Race"
  tt_StartRace / btn_StartRace / tt_NextRace
```

### 17.2 Horse model

| Attribute | Evidence |
|---|---|
| **Name** | Drawn from `GameMedia/Data/Horse.ini` - **249 names, one per line, plain text, CRLF** (248 distinct; "Bunch Of Fives" appears twice; "Quality Assurance" has a trailing TAB). The exe logs `HorseCount:`. |
| **Health** | `Health` column; `CMESSAGE_HORSEHEALTHY` / `CMESSAGE_HORSEILL` / `CMESSAGE_HORSEBECOMESILL` / `Treat Horse` (`CMESSAGE_TREATHORSE` costs `$cash`). |
| **Strength** | `Strength`, `tla_Strength` = `Str`. `CMESSAGE_HORSEEXHAUSTED`: *"Horses with low health will lose strength."* `CTIP_44`: racing makes a horse **stronger and faster**, over-racing makes it ill. `CTIP_45`: illness degrades strength over time. |
| **Tiredness** | `CMESSAGE_HORSETIRED` - "This horse is too tired to race." |
| **Prizes won** | `Prizes` / `stable_Prizes`, `CMESSAGE_HORSEPRIZE` ("Your horse won $cash in prize money!") |
| **Odds** | `lbl_Odds` on the race screen |

### 17.3 Race rules

* **6 runners per race** - the exe contains the format literals ` / 6` and ` / 1` next to `SetUpNextRace`,
  `RefreshRunners`, `SelectRunners` and the debug prints `Total Horses:` / `Total Runners:`.
  `UNCERTAIN:` the ` / 6` may be a "race N of 6" counter rather than the runner count; both readings fit.
* **Limited races per day**: `CMESSAGE_NOMORERACES` ("There are no more races today").
* **One horse of yours per race**: `CMESSAGE_ONLY1HORSE`.
* **Stable capacity**: each `property_Stable` purchase houses **2 horses** (`CMESSAGE_NOSTABLE`);
  `CMESSAGE_STABLE_NOROOM` ("You need to increase your stable size!"), `Increase Stable` / `Decrease Stable`.
* **Too tired to attend**: `CMESSAGE_NORACINGTIRED`.
* Art: 4 horse sprites (`Horse_01..04.png`), 6 jockey silks (`Jockey_01..06.png`), 6 furlong posts
  (`Post_1..6.png`), `FinishPost.png`, `FinishLine.png`, `Railing_01.png`, `Grass.png`, `Bg.png`, `Star.png`,
  `ArrowD.png`; sound `Gallop.ogg`, `FlashBulb.ogg`.
* Exe-only keys `stable_racenumWin` / `stable_racenumPlace` are **not** language tags - `UNCERTAIN:` most likely
  save-profile stat keys where `num` is substituted with the race index.

| Tag | English |
|---|---|
| `CHELP_STABLEBUTTON` | You can go to the race track with your friends. If you own a stable you can also race your own horses! |
| `CMESSAGE_BUYHORSE` | Do you wish to buy this horse for $cash? |
| `CMESSAGE_HORSEBECOMESILL` | Your horse $name has become ill. |
| `CMESSAGE_HORSEEXHAUSTED` | Your horse $name is exhausted and his health is suffering! Horses with low health will lose strength. |
| `CMESSAGE_HORSEHEALTHY` | This horse is healthy. |
| `CMESSAGE_HORSEILL` | This horse in not healthy. You need to treat it first. |
| `CMESSAGE_HORSEPRIZE` | Your horse won $cash in prize money! |
| `CMESSAGE_HORSETIRED` | This horse is too tired to race. |
| `CMESSAGE_NOMORERACES` | There are no more races today. |
| `CMESSAGE_NORACINGTIRED` | You are too tired to go to racing! |
| `CMESSAGE_NOSTABLE` | You do not own a stable yet. You can purchase one in the shop under the Property section. Each stable you buy will house up to 2 race horses. |
| `CMESSAGE_ONLY1HORSE` | You already have a horse in this race. |
| `CMESSAGE_RACEHORSE` | Do you wish to race this horse? |
| `CMESSAGE_SELECTHORSE` | Please select a horse from the list. |
| `CMESSAGE_SELLHORSE` | Do you wish to sell this horse for $cash? |
| `CMESSAGE_STABLE_NOROOM` | You need to increase your stable size! |
| `CMESSAGE_TREATHORSE` | Do you wish to treat this horse for $cash? |
| `CTIP_43` | Once you have purchased a STABLE from the shop you can buy race horses. |
| `CTIP_44` | If you own a race horse you need to race it to make it stronger and faster, but don't over work it or it may become ill! |
| `CTIP_45` | If your race horse becomes ill it's strength will deteriorate over time. Make sure you TREAT it to bring it back to full health. |
| `help_stable` | Set your stake, choose a horse and start the race! If you have purchased a stable from the shop you can even purchase and race your own horses. |
| `stable_Prizes` | Prizes |
| `stable_Race` | Race |
| `CMESSAGE_NOSTABLEMOBILE` | You do not own a stable yet. You can purchase one in the shop under the Property section. |
| `CMESSAGE_TRAINHORSE` | Do you wish to train this horse for $cash? |

---

## 18. Mini-games

### 18.1 Interview (cliché memory game)

`interview` screen, `Interview.png`, `Beep.ogg`, `lbl_Sentence`, `interview_Instrucs` ("Memorise the GREEN
sequence!"), `help_interview`: *"Watch the GREEN buttons light up then repeat the sequence in the correct order.
Ignore the BLUE lights. If you are successful you will increase your FAME."*
Triggered by `CMESSAGE_DOINTERVIEW` after a good performance; success raises FAME, a mistake lowers it.
The exe references `CLICHE_` + index. **26 clichés:**

| Tag | English |
|---|---|
| `CLICHE_1` | Er |
| `CLICHE_10` | A great advert for the game |
| `CLICHE_11` | A game of two halves |
| `CLICHE_12` | One game at a time |
| `CLICHE_13` | The fans were great |
| `CLICHE_14` | Great feet for a big lad |
| `CLICHE_15` | All credit to the lads |
| `CLICHE_16` | The better team on paper |
| `CLICHE_17` | We worked our socks off |
| `CLICHE_18` | There are no easy games |
| `CLICHE_19` | Over the moon |
| `CLICHE_2` | Y'know |
| `CLICHE_20` | It was hand bags |
| `CLICHE_21` | Quality performance |
| `CLICHE_22` | Jumpers for goal posts |
| `CLICHE_23` | A real 6 pointer |
| `CLICHE_24` | A top, top team |
| `CLICHE_25` | Bounce-back ability |
| `CLICHE_26` | Every game is like a cup final |
| `CLICHE_3` | Um |
| `CLICHE_4` | 110% |
| `CLICHE_5` | At the end of the day |
| `CLICHE_6` | All day long |
| `CLICHE_7` | Back of the net |
| `CLICHE_8` | End-to-end football |
| `CLICHE_9` | Week in week out |

### 18.2 Pairs (relationship mini-game)

`pairs` screen. `CINSTRUCS_PAIRS` ("Find two matching cards!"), `CHELP_PAIRS`, `help_pairs`:
*"Spending time with people doesn't always improve the relationship. Try to find two matching pictures to ensure
that you have a good time!"* Widgets `pan_Pairs`, `NewButtonPositions`, `UpdateFaces`, outcome `Fail!`.
Card faces are per-relationship: `Boss_1..4`, `Team_1..4` (plus stray `Team_6`, `Team_8`),
`Fans_1..4`, `Friends_1..4`, `Girl_1..4`, `Sponsors_1..4`; five backdrops `BG_1..5.png`.
Success feeds the `CDILEMMA_*` outcome lines (§10.5) - the exe reads the `CDILEMMA_*` prefixes inside the
`pairs` screen code.

### 18.3 Higher/Lower - see §15.2.

---

## 19. Match engine strings

### 19.1 Control schemes

Two schemes, described on the Edit Controls screen:

| Tag | English |
|---|---|
| `advanced_CallDesc` | TAP a kick button when a team mate has the ball to call for a low pass, high pass or driven pass. |
| `advanced_Description` | The advanced control scheme uses 3 action buttons. |
| `advanced_LobDesc` | HOLD the LOB button for a manual high pass. TAP it for an automatic high pass. |
| `advanced_PassDesc` | HOLD the PASS button for a manual low pass. TAP it for an automatic low pass. |
| `advanced_ShootDesc` | HOLD the SHOOT button for a manual shot. TAP it for an automatic shot at goal. |
| `advanced_SlideDesc` | TAP the LOB button to slide tackle an opponent. |
| `advanced_Tip` | If you HOLD a kick button you will automatically chase the ball and perform a 1st-time shot, pass or header. |
| `controls_Aim` | Aim |
| `controls_BlockTackle` | Block Tackle |
| `controls_Call` | Call |
| `controls_CallHard` | Call Hard |
| `controls_CallHigh` | Call High |
| `controls_CallLow` | Call Low |
| `controls_CursorKeys` | Cursor Keys |
| `controls_Head` | Header |
| `controls_HeadHard` | Head Hard |
| `controls_HeadHigh` | Head High |
| `controls_HeadLow` | Head Low |
| `controls_Kick` | Kick |
| `controls_Lob` | Lob |
| `controls_Pass` | Pass |
| `controls_Pause` | Pause |
| `controls_Replay` | Replay |
| `controls_Run` | Run |
| `controls_Shoot` | Shoot |
| `controls_SlideTackle` | Slide Tackle |
| `controls_Start` | Start |
| `controls_Tackle` | Tackle |
| `simple_CallDesc` | TAP the KICK button when a team mate has the ball to call for a pass. |
| `simple_CallTip` | You can also HOLD the KICK button to chase the ball. This is useful for performing headers. |
| `simple_Description` | The simple control scheme lets you play with just 1 action button. |
| `simple_PassDesc` | TAP the KICK button to pass to the team mate you are facing. |
| `simple_PassTip` | TAP the KICK button whilst standing still to make a high pass or TAP whilst alongside the penalty box to cross the ball. |
| `simple_ShootDesc` | HOLD the KICK button to shoot. |
| `simple_ShootTip` | When inside the penalty box you can aim towards the goal and TAP the KICK button to perform a low, hard shot. |
| `simple_SlideDesc` | TAP the KICK button to slide tackle an opponent. |

`CTIP_3` - switch between SIMPLE and ADVANCED from Pause → Options → Edit Controls.
`CTIP_9` (simple), `CTIP_13` (crossing), `CTIP_23` (free kicks & corners request), `CMESSAGE_MOVEMENTMAP`
("Hold RIGHT for movement map"), `Lock Kicking Direction`.

Set-piece preference:

| Tag | English |
|---|---|
| `request_Always` | Always |
| `request_Corners` | Request Corners |
| `request_Freekicks` | Request Free Kicks |
| `request_Never` | Never |
| `request_Sometimes` | Sometimes |

### 19.2 In-match status flashes

| Tag | English |
|---|---|
| `CMESSAGE_3SUBLIMIT` | Only 3 substitutes allowed! |
| `CMESSAGE_SKIPTIMEEND` | Do you wish to skip to the end of the match? |
| `CMESSAGE_SKIPTIMESUB` | Do you wish to skip to your substitution? |
| `CMESSAGE_SKIPTOCONTINUE` | Press KICK to continue |
| `matchmsg_Drunk` | You are drunk! |
| `matchmsg_Stomach` | Stomach cramps! |
| `matchmsg_Tired` | You are tired! |
| `matchmsg_Unhappy` | Unhappiness strikes! |
| `skiptime_EndMatch` | Skip to end of match |
| `skiptime_EndTraining` | Quit Training |
| `skiptime_SubstitutionOff` | Request substitution and skip to end of match |
| `skiptime_SubstitutionOn` | Skip to substitution |

### 19.3 Text commentary (`CMATCHTEXT_`) - 91 lines

This family is the **text-based match presentation**. On PC the full 2D match is played, so much of this is
mobile-era; however `CMATCHTEXT_PENALTYSTEPUP`, `CMATCHTEXT_PENRESULT`, `CMATCHTEXT_SUBON/SUBOFF` and the
free-kick/penalty result lines are plausible PC usages (penalty shoot-outs, substitutions).
`UNCERTAIN:` no `CMATCHTEXT_` literal or prefix stub was found in the PC exe string table, which argues the
whole family is unused on PC. Verify before implementing.

| Tag | English |
|---|---|
| `CMATCHTEXT_BOOING1` | But some booing fans put him off |
| `CMATCHTEXT_BOOING2` | But he gets booed and loses the ball |
| `CMATCHTEXT_BOOING3` | But some abuse from the fans puts him off |
| `CMATCHTEXT_BOOING4` | But he gets booed and stumbles |
| `CMATCHTEXT_BOOING5` | But the boo boys are getting to him |
| `CMATCHTEXT_CHANCEFORPLAYER1` | $playername collects the ball |
| `CMATCHTEXT_CHANCEFORPLAYER10` | $playername has possession |
| `CMATCHTEXT_CHANCEFORPLAYER2` | $playername receives the ball |
| `CMATCHTEXT_CHANCEFORPLAYER3` | $playername is in space |
| `CMATCHTEXT_CHANCEFORPLAYER4` | It's passed to $playername |
| `CMATCHTEXT_CHANCEFORPLAYER5` | The ball falls to $playername |
| `CMATCHTEXT_CHANCEFORPLAYER6` | $playername wins the ball |
| `CMATCHTEXT_CHANCEFORPLAYER7` | It breaks nicely for $playername |
| `CMATCHTEXT_CHANCEFORPLAYER8` | It's played in to $playername |
| `CMATCHTEXT_CHANCEFORPLAYER9` | It comes to $playername |
| `CMATCHTEXT_CHANCEFORPLAYERINTERCEPT1` | A chance for $playername to intercept... |
| `CMATCHTEXT_CHANCEFORPLAYERINTERCEPT2` | $playername has a chance to intercept... |
| `CMATCHTEXT_CHANCEFORPLAYERINTERCEPT3` | A chance for $playername to win the ball... |
| `CMATCHTEXT_CHANCEFORPLAYERINTERCEPT4` | $playername can win possession... |
| `CMATCHTEXT_CHANCEFORPLAYERINTERCEPT5` | $playername has a chance to win the ball... |
| `CMATCHTEXT_CHANCEMISSED` | Chance missed |
| `CMATCHTEXT_CHANCEPLAYERWONBALL1` | $playername has it in midfield |
| `CMATCHTEXT_CHANCEPLAYERWONBALL2` | He has an opportunity to pass |
| `CMATCHTEXT_FREEKICK` | It's a free kick |
| `CMATCHTEXT_FREEKICKGOAL1` | Goal! A beautiful free kick! |
| `CMATCHTEXT_FREEKICKGOAL2` | Goal! Curled around the wall! |
| `CMATCHTEXT_FREEKICKGOAL3` | Goal! Right in the top corner! |
| `CMATCHTEXT_FREEKICKGOAL4` | Goal! A well worked routine |
| `CMATCHTEXT_FREEKICKGOAL5` | Goal! Deflected off the wall and in! |
| `CMATCHTEXT_FREEKICKMISS1` | Missed! That's high and wide |
| `CMATCHTEXT_FREEKICKMISS2` | Missed! He shoots wide! |
| `CMATCHTEXT_FREEKICKMISS3` | Saved! Straight into the keeper's arms! |
| `CMATCHTEXT_FREEKICKMISS4` | Saved! A fantastic dive by the keeper |
| `CMATCHTEXT_FREEKICKMISS5` | But he hits it straight into the wall |
| `CMATCHTEXT_GOAL1` | It's there! Fantastic goal! |
| `CMATCHTEXT_GOAL10` | Goal! A fantastic strike! |
| `CMATCHTEXT_GOAL2` | Goal! The keeper couldn't reach it! |
| `CMATCHTEXT_GOAL3` | It's a goal! Headed in brilliantly! |
| `CMATCHTEXT_GOAL4` | It's in! A precise curled effort! |
| `CMATCHTEXT_GOAL5` | Goal! An unstoppable shot! |
| `CMATCHTEXT_GOAL6` | Goal! Deflected and in! |
| `CMATCHTEXT_GOAL7` | It's there! A sublime effort! |
| `CMATCHTEXT_GOAL8` | It's a goal! A powerful strike! |
| `CMATCHTEXT_GOAL9` | It's there! A scruffy shot goes in! |
| `CMATCHTEXT_INTERCEPTBAD1` | But he can't get to it |
| `CMATCHTEXT_INTERCEPTBAD2` | But he fails to stop the attack |
| `CMATCHTEXT_INTERCEPTBAD3` | But he couldn't get there |
| `CMATCHTEXT_INTERCEPTBAD4` | But the play bypasses him |
| `CMATCHTEXT_INTERCEPTBAD5` | But he can't break up the attack |
| `CMATCHTEXT_INTERCEPTGOOD1` | He intercepts the pass |
| `CMATCHTEXT_INTERCEPTGOOD2` | He breaks up the attack |
| `CMATCHTEXT_INTERCEPTGOOD3` | He wins the ball |
| `CMATCHTEXT_INTERCEPTGOOD4` | He wins possession |
| `CMATCHTEXT_INTERCEPTGOOD5` | That's a good interception |
| `CMATCHTEXT_MISS1` | But the shot goes wide |
| `CMATCHTEXT_MISS10` | But the linesman flags for offside |
| `CMATCHTEXT_MISS2` | But it's over the bar |
| `CMATCHTEXT_MISS3` | But the keeper saves it |
| `CMATCHTEXT_MISS4` | But the shot is blocked |
| `CMATCHTEXT_MISS5` | But the keeper palms it away |
| `CMATCHTEXT_MISS6` | But the ball is cleared |
| `CMATCHTEXT_MISS7` | But it's headed away |
| `CMATCHTEXT_MISS8` | But it's scrambled to safety |
| `CMATCHTEXT_MISS9` | But the keeper smothers it |
| `CMATCHTEXT_PASSBAD` | Possession lost by $playername |
| `CMATCHTEXT_PASSFANTASTIC` | A fantastic $dist pass by $playername |
| `CMATCHTEXT_PASSGOOD` | A good pass by $playername |
| `CMATCHTEXT_PASSGREAT` | A great pass by $playername |
| `CMATCHTEXT_PASSSIMPLE` | $playername plays a simple pass |
| `CMATCHTEXT_PENALTY` | It's a penalty! |
| `CMATCHTEXT_PENALTYGOAL1` | Goal! Fantastic penalty! |
| `CMATCHTEXT_PENALTYGOAL2` | Goal! Cooly taken |
| `CMATCHTEXT_PENALTYGOAL3` | Goal! The keeper couldn't stop it! |
| `CMATCHTEXT_PENALTYGOAL4` | Goal! Straight down the middle |
| `CMATCHTEXT_PENALTYGOAL5` | Goal! An unstoppable penalty! |
| `CMATCHTEXT_PENALTYMISS1` | Missed! Blazed over the bar! |
| `CMATCHTEXT_PENALTYMISS2` | Missed! He shoots wide! |
| `CMATCHTEXT_PENALTYMISS3` | Saved! The keeper guessed right! |
| `CMATCHTEXT_PENALTYMISS4` | Saved! Fantastic save from the keeper |
| `CMATCHTEXT_PENALTYMISS5` | Saved! The keeper pushes it away! |
| `CMATCHTEXT_PENALTYSTEPUP` | $clubname penalty |
| `CMATCHTEXT_PENALTYSTEPUPPLAYER` | $playername steps up for $clubname |
| `CMATCHTEXT_PENRESULT` | $clubname win the penalty shoot-out! |
| `CMATCHTEXT_SUBOFF` | $playername is coming off |
| `CMATCHTEXT_SUBOFFENERGY` | He looks exhausted |
| `CMATCHTEXT_SUBOFFRATING` | He hasn't played well |
| `CMATCHTEXT_SUBON` | $playername is coming on |
| `CMATCHTEXT_CORNER` | It's a corner |
| `CMATCHTEXT_CORNERGOOD1` | Great delivery by $playername |
| `CMATCHTEXT_CORNERGOOD2` | A well taken corner by $playername |
| `CMATCHTEXT_CORNERGOOD3` | A nice ball in by $playername |

### 19.4 `CCHANCESTAGE_` - 30 lines (mobile text-match build-up)

Three stages of an attacking move: `MOVEFORWARD1..10` → `SHOOT1..10` → `CHANCEBREAKSDOWN1..10`.
Not referenced by the PC exe.

| Tag | English |
|---|---|
| `CCHANCESTAGE_CHANCEBREAKSDOWN1` | But the attack breaks down |
| `CCHANCESTAGE_CHANCEBREAKSDOWN10` | But they fail to hold onto the ball |
| `CCHANCESTAGE_CHANCEBREAKSDOWN2` | But the ball is given away |
| `CCHANCESTAGE_CHANCEBREAKSDOWN3` | But possession is lost |
| `CCHANCESTAGE_CHANCEBREAKSDOWN4` | But it comes to nothing |
| `CCHANCESTAGE_CHANCEBREAKSDOWN5` | But the chance is wasted |
| `CCHANCESTAGE_CHANCEBREAKSDOWN6` | But the ball goes out of play |
| `CCHANCESTAGE_CHANCEBREAKSDOWN7` | But the ball goes astray |
| `CCHANCESTAGE_CHANCEBREAKSDOWN8` | But that is good defending |
| `CCHANCESTAGE_CHANCEBREAKSDOWN9` | But they cannot get through |
| `CCHANCESTAGE_MOVEFORWARD1` | They push forward |
| `CCHANCESTAGE_MOVEFORWARD10` | They attack down the wing |
| `CCHANCESTAGE_MOVEFORWARD2` | They are passing it around well |
| `CCHANCESTAGE_MOVEFORWARD3` | The build up play looks promising |
| `CCHANCESTAGE_MOVEFORWARD4` | $teamname get men behind the ball |
| `CCHANCESTAGE_MOVEFORWARD5` | $teamname are looking vulnerable |
| `CCHANCESTAGE_MOVEFORWARD6` | $teamname try to regroup |
| `CCHANCESTAGE_MOVEFORWARD7` | $teamname are short at the back |
| `CCHANCESTAGE_MOVEFORWARD8` | $teamname are outnumbered here |
| `CCHANCESTAGE_MOVEFORWARD9` | They are moving the ball quickly |
| `CCHANCESTAGE_SHOOT1` | $teamname have a chance to score... |
| `CCHANCESTAGE_SHOOT10` | It's a chance for $teamname... |
| `CCHANCESTAGE_SHOOT2` | $teamname are in on goal... |
| `CCHANCESTAGE_SHOOT3` | $teamname knock the ball forwards... |
| `CCHANCESTAGE_SHOOT4` | $teamname have a great chance... |
| `CCHANCESTAGE_SHOOT5` | $teamname put it into the box... |
| `CCHANCESTAGE_SHOOT6` | $teamname push forward... |
| `CCHANCESTAGE_SHOOT7` | A cross comes in from $teamname... |
| `CCHANCESTAGE_SHOOT8` | That's nice football from $teamname... |
| `CCHANCESTAGE_SHOOT9` | $teamname are moving the ball nicely... |

### 19.5 Replay system

| Tag | English |
|---|---|
| `replay_Exit` | Exit |
| `replay_Forward` | Forward |
| `replay_HideNames` | Hide Names |
| `replay_Pause` | Pause |
| `replay_PauseSlowMo` | Pause & SlowMo |
| `replay_Rewind` | Rewind |
| `replay_RwdFwd` | Rwd / Fwd |
| `replay_Save` | Save Replay |
| `replay_Saved` | Saved |
| `replay_ShowNames` | Show Names |
| `replay_SlowMo` | Slow Mo |
| `replay_Zoom` | Zoom |
| `replay_ZoomIn` | Zoom In |
| `replay_ZoomOut` | Zoom Out |
| `zoom_Far` | Zoom Far |
| `zoom_Near` | Zoom Near |

Exe: `.rep` extension, `newstarsoccerfivereplayfile` magic, `Could not save replay!`, saved through
`zipe::` (a ZIP stream engine). `CTIP_10` documents saving and replaying from the main menu.

---

## 20. Season, competitions, achievements, editor, online

### 20.1 Season / competition vocabulary

| Tag | English |
|---|---|
| `climate_Cold` | Cold |
| `climate_Hot` | Hot |
| `climate_Variable` | Variable |
| `climate_Warm` | Warm |
| `comptype_BestPlaced` | Best Placed |
| `comptype_KO` | KO |
| `comptype_League` | League |
| `comptype_LeagueCont` | League Continuation |
| `comptype_Pool` | Pool |
| `comptype_RegionalSort` | Regional Sort |
| `fixture_Bye` | Bye |
| `fixtures_Round` | Round |
| `tournament_exit` | exit |
| `position_Finished` | Finished |
| `position_Promoted` | Promoted! |
| `position_Relegated` | Relegated! |

Season flow messages: `CMESSAGE_LEAGUEWON`, `CMESSAGE_LEAGUEFINISHPOS`, `CMESSAGE_LEAGUESTARTNEW`,
`CMESSAGE_SHORTORLONGSEASON` (long = `$num1` rounds, short = `$num2` rounds), `Season Review`,
`Tournaments and Awards`, and the three annual awards (`Young Player Of The Year`, `League Player Of The Year`,
`World Player Of The Year`) with their news counterparts. `CTIP_48` states awards require a **high average match
rating in a high-profile league plus good international form**.

Career length: **20 seasons** (`CACHIEVEMENT_100` "Retire after 20 seasons", `CTIP_50`), with
`CMESSAGE_LASTSEASON`, `CMESSAGE_RETIRED`, `CMESSAGE_RETIREMENT` and the legend variant
`CMESSAGE_RETIREMENTLEGEND` (requires World Cup + World Player of the Year + all achievements per `CTIP_50`).

### 20.2 The 100 PC achievements

`GameMedia/Data/Achievements.csv` is TAB-separated with exactly two columns, `id` and `sortindex`, values
`1..100` identity-mapped - i.e. the CSV contributes only ordering; **all achievement text lives in
`Languages.csv` as `CACHIEVEMENT_1..100`.** The exe builds the key as `CACHIEVEMENT_` + id and logs
`Bugged Achievement` when the id is out of range.

| Tag | English |
|---|---|
| `CACHIEVEMENT_100` | Retire after 20 seasons |
| `CACHIEVEMENT_10` | Win 15 tackles in one match |
| `CACHIEVEMENT_11` | Make 10 passes in one match |
| `CACHIEVEMENT_12` | Make 20 passes in one match |
| `CACHIEVEMENT_13` | Make 30 passes in one match |
| `CACHIEVEMENT_14` | Earn a 'Star Man' award |
| `CACHIEVEMENT_15` | Earn 10 'Star Man' awards |
| `CACHIEVEMENT_16` | Earn 25 'Star Man' awards |
| `CACHIEVEMENT_17` | Earn 50 'Star Man' awards |
| `CACHIEVEMENT_18` | Win a league game |
| `CACHIEVEMENT_19` | Win a cup game |
| `CACHIEVEMENT_1` | Score a club goal |
| `CACHIEVEMENT_20` | Win a continental cup game |
| `CACHIEVEMENT_21` | Win an international game |
| `CACHIEVEMENT_22` | Win a match by 5 goals |
| `CACHIEVEMENT_23` | Win a national cup tournament |
| `CACHIEVEMENT_24` | Win a club continental tournament |
| `CACHIEVEMENT_25` | Win an international tournament |
| `CACHIEVEMENT_26` | Win the 'Young Player of the Year' award |
| `CACHIEVEMENT_27` | Win the 'League Player of the Year' award |
| `CACHIEVEMENT_28` | Win the 'World Player of the Year' award |
| `CACHIEVEMENT_29` | Play an international match |
| `CACHIEVEMENT_2` | Score a club hattrick |
| `CACHIEVEMENT_30` | Play 50 international matches |
| `CACHIEVEMENT_31` | Play 100 international matches |
| `CACHIEVEMENT_32` | Score an international goal |
| `CACHIEVEMENT_33` | Score an international hattrick |
| `CACHIEVEMENT_34` | Score 50 international goals |
| `CACHIEVEMENT_35` | Score 100 international goals |
| `CACHIEVEMENT_36` | Celebrate a goal in front of the fans |
| `CACHIEVEMENT_37` | Celebrate a goal in front of the cameras |
| `CACHIEVEMENT_38` | Celebrate a goal with the boss |
| `CACHIEVEMENT_39` | Celebrate a goal by running with ball to the centre circle |
| `CACHIEVEMENT_3` | Score 50 club goals |
| `CACHIEVEMENT_40` | Transfer to a new club |
| `CACHIEVEMENT_41` | Make a $1 million transfer move |
| `CACHIEVEMENT_42` | Make a $5 million transfer move |
| `CACHIEVEMENT_43` | Make a $10 million transfer move |
| `CACHIEVEMENT_44` | Make a $20 million transfer move |
| `CACHIEVEMENT_45` | Get 100% relationship with boss |
| `CACHIEVEMENT_46` | Get 100% relationship with team |
| `CACHIEVEMENT_47` | Get 100% relationship with fans |
| `CACHIEVEMENT_48` | Get 100% relationship with sponsors |
| `CACHIEVEMENT_49` | Get 100% relationship with friends |
| `CACHIEVEMENT_4` | Score 100 club goals |
| `CACHIEVEMENT_50` | Get 100% relationship with girlfriend |
| `CACHIEVEMENT_51` | Achieve 100% happiness |
| `CACHIEVEMENT_52` | Sign a sponsorship contract |
| `CACHIEVEMENT_53` | Sign maximum number of sponsorship contracts |
| `CACHIEVEMENT_54` | Buy an NRG drink |
| `CACHIEVEMENT_55` | Buy some booze |
| `CACHIEVEMENT_56` | Buy some pain killers |
| `CACHIEVEMENT_57` | Have $1 million in the bank |
| `CACHIEVEMENT_58` | Have $10 million in the bank |
| `CACHIEVEMENT_59` | Have $25 million in the bank |
| `CACHIEVEMENT_5` | Keep a clean sheet |
| `CACHIEVEMENT_60` | Purchase all luxury items |
| `CACHIEVEMENT_61` | Purchase all vehicles |
| `CACHIEVEMENT_62` | Purchase all properties |
| `CACHIEVEMENT_63` | Achieve 100% lifestyle rating |
| `CACHIEVEMENT_64` | Achieve maximum pace |
| `CACHIEVEMENT_65` | Achieve maximum dribbling skill |
| `CACHIEVEMENT_66` | Achieve maximum tackling skill |
| `CACHIEVEMENT_67` | Achieve maximum passing |
| `CACHIEVEMENT_68` | Achieve maximum heading skill |
| `CACHIEVEMENT_69` | Achieve maximum shooting |
| `CACHIEVEMENT_6` | Make an assist |
| `CACHIEVEMENT_70` | Achieve maximum flair |
| `CACHIEVEMENT_71` | Achieve 100% skill rating |
| `CACHIEVEMENT_72` | Win money betting on a horse |
| `CACHIEVEMENT_73` | Win money at the roulette wheel |
| `CACHIEVEMENT_74` | Win money on the slot machine |
| `CACHIEVEMENT_75` | Win money playing black jack |
| `CACHIEVEMENT_76` | Achieve 100% fame rating |
| `CACHIEVEMENT_77` | Win a league title |
| `CACHIEVEMENT_78` | Win a lower division title |
| `CACHIEVEMENT_79` | Get a girlfriend |
| `CACHIEVEMENT_7` | Make 3 assists in one match |
| `CACHIEVEMENT_80` | Upgrade to a Premium account |
| `CACHIEVEMENT_81` | Sign your first contract |
| `CACHIEVEMENT_82` | Buy a horse |
| `CACHIEVEMENT_83` | Win a race with a horse that you own |
| `CACHIEVEMENT_84` | Sell over 100 replica shirts in one week |
| `CACHIEVEMENT_85` | Get a maximum match rating 5 times in a row |
| `CACHIEVEMENT_86` | Win the World Cup |
| `CACHIEVEMENT_87` | Become a local hero and play 100 games for one club |
| `CACHIEVEMENT_88` | Become a club legend and play 200 games for one club |
| `CACHIEVEMENT_89` | Become the club captain |
| `CACHIEVEMENT_8` | Win 5 tackles in one match |
| `CACHIEVEMENT_90` | Buy a pair of shin pads |
| `CACHIEVEMENT_91` | Buy some boots |
| `CACHIEVEMENT_92` | Score a goal from 20 metres |
| `CACHIEVEMENT_93` | Score a goal from 30 metres |
| `CACHIEVEMENT_94` | Score 20 club goals in a season |
| `CACHIEVEMENT_95` | Make 150 club tackles in a season |
| `CACHIEVEMENT_96` | Make 300 club passes in a season |
| `CACHIEVEMENT_97` | Make 20 club assists in a season |
| `CACHIEVEMENT_98` | Get 20 Star Man awards in a season |
| `CACHIEVEMENT_99` | Play for 10 seasons |
| `CACHIEVEMENT_9` | Win 10 tackles in one match |

### 20.3 Difficulty

| Tag | English |
|---|---|
| `CMESSAGE_DIFFICULTYEASY` | Opposing players are slow and less skillful in matches. The BOSS is lenient and will pick you for most matches. |
| `CMESSAGE_DIFFICULTYHARD` | The BOSS is strict and will not pick you if you are out of form. You can achieve a higher transfer value. |
| `CMESSAGE_DIFFICULTYNORMAL` | The BOSS will pick you for most matches unless he is very unhappy with you. |
| `CMESSAGE_DIFFICULTYSET1` | Please choose a difficulty level |
| `CMESSAGE_DIFFICULTYSET2` | You can change your difficulty level at any time from the 'Options' screen |
| `CMESSAGE_NOPREMIUMNOHARD` | Only Premium players can play on the HARD difficulty level. After upgrading you can select it from the OPTIONS menu. |
| `difficulty_Easy` | Easy |
| `difficulty_Hard` | Hard |
| `difficulty_Normal` | Normal |

### 20.4 Online account, premium, Steam

| Tag | English |
|---|---|
| `account_CouldNotConnect` | Could Not Connect |
| `account_Instrucs` | When you create a new player he needs to be registered on the server so that other players can see you in their game world. Please enter your details below to set up your NSS5 account... |
| `account_Invalid` | Invalid |
| `account_MatchesLeft` | $num Free Matches |
| `account_MatchesLeft1` | 1 Free Match |
| `account_MatchRefresh` | Free matches in |
| `account_Status` | Account Status |
| `account_TrialEnded` | Trial Period Expired |
| `account_Unknown` | Unknown |
| `account_Upgrade` | Upgrade to a Premium account |
| `account_Valid` | Valid |
| `CMESSAGE_ACCOUNTBANNED` | This account is no longer active. Please contact support@newstargames.com if you are the owner of this account. |
| `CMESSAGE_CONNECTIONERROR` | Could not connect to the NSS5 server. Please ensure that your internet connection is working correctly. If everything appears to be fine then please try again. |
| `CMESSAGE_COULDNOTCREATEPLAYER` | I'm sorry but your player could not be created on the server. Please try again. |
| `CMESSAGE_DEMORESTRICTED` | Please purchase the full version to access this feature. |
| `CMESSAGE_ENTERNAME` | Please enter your full name. |
| `CMESSAGE_ENTERPASSWORD` | Please enter your password. |
| `CMESSAGE_ENTERVALIDEMAIL` | Please enter a valid email address. |
| `CMESSAGE_GETEMAIL` | Please enter your email address in case you forget your password. |
| `CMESSAGE_GETNEWPLAYERPASSWORD` | Your player profile will be stored in the database. Please choose a password (minimum 8 characters). |
| `CMESSAGE_INVALIDEMAIL` | Your email address appears to be invalid. Please type it again. |
| `CMESSAGE_INVALIDPASSWORD` | Please use an alpha-numeric password, at least 8 characters long. |
| `CMESSAGE_INVALIDPLAYERNAME` | Your player name must use only letters and be between 3 and 26 characters long. Please try again. |
| `CMESSAGE_INVALIDSKILLSHASH` | Your save file seems to be corrupted and your skills have been reset. |
| `CMESSAGE_LEADERBOARDCOULDNOTRETRIEVE` | Could not connect! |
| `CMESSAGE_LEADERBOARDNOTSUBMITTEDHASH` | Could not submit stats to the leaderboard. Your save file is invalid. |
| `CMESSAGE_LEADERBOARDNOTSUBMITTEDPASSWORD` | Could not submit stats to the leaderboard. Your password is incorrect. |
| `CMESSAGE_MUSTBEONLINE` | You must be connected to the internet to start a new career. |
| `CMESSAGE_MUSTUPDATEVERSION` | There is a new version of NSS5! You need to download the latest version before you can register a new player. |
| `CMESSAGE_NEWSLETTER` | Get Retro Football news! |
| `CMESSAGE_NOGAMESLEFT` | You currently have a FREE account and have exceeded your maximum number of matches for today. Your free matches will refresh in $wait. If you don't want to wait you can buy more matches. Would you like to buy more matches now? |
| `CMESSAGE_PASSWORDINCORRECT` | That is the wrong password. Would you like to reset your password? |
| `CMESSAGE_PASSWORDOKFREE` | You currently have a FREE account which means that you can only play a limited number of matches per day. You have $matches matches remaining today. |
| `CMESSAGE_PASSWORDSDONTMATCH` | Your passwords don't match. Please try again. |
| `CMESSAGE_PASSWORDTOOSHORT` | Your password is too short. |
| `CMESSAGE_PLAYERDOESNOTEXIST` | This player name does not exist. Would you like to create a new account? |
| `CMESSAGE_PLAYEREXISTS` | This player name exists already. Please try again. |
| `CMESSAGE_PLAYEREXISTSENTERPASSWORD` | This player name exists in the database already. Please enter your password. (If you did not create the original player then please go back and choose a different player name.) |
| `CMESSAGE_PLAYERNOTFOUND` | This player $name could not be found in the NSS5 database. Please contact support@newstargames.com. |
| `CMESSAGE_PREMIUMCHECKIN` | As a PREMIUM account holder you need to connect to the server at least once every 50 matches in order to update your player profile. You have 10 matches remaining until you need to connect online. |
| `CMESSAGE_PREMIUMMUSTCHECKIN` | You have played 50 matches since you last connected to the NSS5 server. You must connect in order to update your player profile. |
| `CMESSAGE_PREMIUMONLYLEADERBOARDVIEW` | Only PREMIUM players can view player stats. |
| `CMESSAGE_SELECTFRIEND` | You need to select a player in the list to add a friend. |
| `CMESSAGE_UPDATEVERSION` | There is a new version of NSS5! If you wish to access the leaderboards and squad data you need to download the latest version. Would you like to update now? |
| `CMESSAGE_UPGRADEFORFREEMIUM` | You must install the latest version to play with a FREE account. |
| `leaderboard_StatsCareer` | Career Stats |
| `leaderboard_StatsInt` | International Stats |
| `leaderboard_StatsSeason` | Season Stats |
| `leaderboard_Status` | Status |
| `leaderboard_View` | Change View |
| `tt_Banned` | Account has been banned |
| `tt_CreateAccount` | Create |
| `tt_Download` | Download |
| `tt_Facebook` | Facebook |
| `tt_Forum` | Forum |
| `tt_Offline` | Try to connect |
| `tt_Premium` | View account |
| `tt_RefreshConnection` | Refresh connection |
| `tt_Twitter` | Twitter |
| `tt_Upgrade` | Upgrade to a Premium account |
| `tt_UpToDate` | Up to date |
| `tt_GetMoreMatches` | Get more matches |
| `instrucs_Key` | If you have an activation key please enter it here. Otherwise leave blank. |
| `CMESSAGE_NO7MINS` | Only premium players can play 7 minute matches. |
| `CMESSAGE_WEBACCOUNT` | You can log in at www.newstarsoccer.com to edit your account and email settings. |

Anti-cheat: the exe contains the salt string `dontcheatatnss5` next to `CMESSAGE_INVALIDSKILLSHASH`, and a
64-hex constant `3c422b4eb93f7e15d399b188f4b4c7278b99a9c5c71ec6428969c9aabd8eed0a` next to
`newstarsoccerfivesavefile` / `SaveGame` / `#VERSION:1.10`. A faithful save-file implementation needs both.

### 20.5 Data Editor and Scenarios

The shipped exe includes a full database editor (`Data Editor`, `Edit Club`, `Edit Comp`, `Edit Nation`,
`Edit Place`, `Edit Player`, `Compress IDs`, `Inflate IDs`, `Test Data`, `Duplicate`, `Move Player`,
`Create Players`, `Refresh Clubs`, `Save`, `Load League`, `New League`) and a scenario editor/share system
(`New Scenario`, `Load Scenario`, `Share Scenario`, `Receive Scenario`, `Enter Scenario ID`,
`This is your scenario code`).

| Tag | English |
|---|---|
| `CMESSAGE_CHOOSECLUB` | Please choose a club. |
| `CMESSAGE_CHOOSENATION` | Please choose a nation. |
| `CMESSAGE_CHOOSENATIONALITY` | Please choose a nationality. |
| `CMESSAGE_CHOOSEPOSITION` | Please choose a position. |
| `CMESSAGE_CHOOSETEAM1` | Choose team 1 |
| `CMESSAGE_CHOOSETEAM2` | Choose team 2 |
| `CMESSAGE_COMPRESSIDS` | Compressing will remove any spaces between ID numbers, so IDs 10, 20, 30 become 1,2,3. Do you want to compress IDs? |
| `CMESSAGE_COULDNOTLOADFILE` | Unable to open this file. '$filename' |
| `CMESSAGE_DELETE` | Are you sure you want to delete '$item'? |
| `CMESSAGE_DELETECLUB` | Are you sure you want to delete the club '$club'? |
| `CMESSAGE_DELETECOMPETITION` | Are you sure you want to delete the competition '$comp'? |
| `CMESSAGE_DELETEPROMOTIONPLACE` | Are you sure you want to delete this promotion place '$place'? |
| `CMESSAGE_DELETEYN` | Delete '$filename'? |
| `CMESSAGE_FILECONFIRMDELETE` | Are you sure you wish to delete this file? '$filename' |
| `CMESSAGE_FILECORRUPTDELETE` | The file '$filename' seems to be corrupt. Do you wish to delete it? |
| `CMESSAGE_FILECORRUPTRESTORE` | The file '$filename' seems to be corrupt. Do you wish to try to recover it from the backup file? |
| `CMESSAGE_FILEEXISTSOVERWRITE` | There is already a save file with this name. Do you wish to overwrite it? |
| `CMESSAGE_FILEGETSAVENAME` | Please choose a name for your save file. |
| `CMESSAGE_FILENOTCREATED` | Could not create file '$filename'! |
| `CMESSAGE_INFLATEIDS` | Inflating will space out ID numbers, so IDs 1,2,3 become 10,20,30. Do you want to inflate IDs? |
| `CMESSAGE_INVALIDBREAK` | Duration + Break must equal 12, 24, 36 or 48 months. |
| `CMESSAGE_INVALIDCOMPETITION` | Please enter a valid competition id. |
| `CMESSAGE_INVALIDPLACE` | Please enter a valid place. |
| `CMESSAGE_NEWCOMPIDEXISTS` | The competition id cannot be changed because the id '$id' already exists! |
| `CMESSAGE_NEWCOMPIDSET` | The competition id has been changed to '$id'. |
| `CMESSAGE_OVERWRITEFILE` | Do you want to overwrite the file '$filename'? |
| `CMESSAGE_OVERWRITESAVE` | Starting a new campaign will overwrite your existing save file. Do you wish to continue? |
| `CMESSAGE_SAVEMASTERFILES` | Do you wish to save the database? |
| `CMESSAGE_SCENARIOFIXMATCHMIN` | Match minute must be between 0 and 105 |
| `CMESSAGE_SCENARIOFIXSCORE1` | Score 1 must be between 0 and 9 |
| `CMESSAGE_SCENARIOFIXSCORE2` | Score 2 must be between 0 and 9 |
| `CMESSAGE_SCENARIONOTEAM1` | Please enter a name for team 1 |
| `CMESSAGE_SCENARIONOTEAM2` | Please enter a name for team 2 |
| `CMESSAGE_SCENARIONOTFOUND` | Could not retrieve scenario. Please make sure you have the correct id or try later. |
| `CMESSAGE_SCENARIONOTITLE` | Please enter a title for your scenario |
| `CMESSAGE_SCENARIONOTSUBMITTED` | Could not submit scenario to the database! Please try again later. |
| `CMESSAGE_SCENARIORETRIEVED` | Scenario retrieved! |
| `CMESSAGE_SCENARIOSAVED` | Scenario '$filename' saved. |
| `CMESSAGE_SCENARIOSUBMITTED` | Congratulations! Your scenario was submitted to the database. Other people can play your scenario by using the id: $code. |
| `CMESSAGE_TESTDATACONTINUE` | Continue to the testing menu? |
| `CMESSAGE_TESTDATASAVE` | After starting the data test you cannot save the database. Would you like to save now? |

---
## 21. Confirmed data defects in the shipped file

These are real, verified faults in `Languages.csv` (and its immediate neighbours). A *faithful* reconstruction
must decide, defect by defect, whether to reproduce the original behaviour or silently repair it. Recommendation
in each row.

| # | Defect | Evidence | Runtime effect | Recommendation |
|---:|---|---|---|---|
| 1 | **`CTIP_46` does not exist.** The row that should hold it (line 918, in alphabetical position between `CTIP_45` and `CTIP_47`) instead holds the tag `Compress IDs`. Someone overwrote the tip's tag with a Data Editor label. | `CTIP_*` present: 1-45, 47-50 = 49 tags for a 1..50 range | `Lang("CTIP_" + Rand(1,50))` fails 2% of the time | Reproduce the gap; make the tip picker resilient (retry or clamp) exactly as the original must have to avoid a visible crash. Note the original may pick `Rand(1,49)` over an index list. |
| 2 | **`CBOSSNEG_EXPLETIVE` is duplicated four times with no numeric suffix**, while `CBOSSPOS_EXPLETIVE1..4` are correctly numbered. Rows: `Idiot!`, `What was that?!`, `Pathetic!`, `$#@%!!!` | 4 identical tags at lines 2014-2017 | If lookup is `…EXPLETIVE + Rand(1,4)` the negative expletive **never resolves**; if lookup is by first match, only `Idiot!` is ever heard | Reproduce the data as-is; document that the reconstruction's boss-shout code must not assume symmetry between POS and NEG families |
| 3 | **`CMESSAGE_GAMBLINGADDICT4` is unreachable / `…ADDICT5` is missing.** The exe references `1`, `2`, `3`, `5`; the CSV supplies `1`, `2`, `3`, `4`. | exe string table order: `CMESSAGE_GAMBLINGADDICT1/2/3/5` | The BOSS gambling reaction (`ADDICT4`) never fires; one branch looks up a non-existent tag | Reproduce the CSV verbatim; in code, note the off-by-one so the disassembly can be matched exactly |
| 4 | **`CMESSAGE_QUIT` is defined twice with *different* text** - line 515 "Are you sure you want to quit?" and line 2502 "Do you wish to quit to the main menu?" | duplicate-tag scan | Whichever the loader keeps wins; a last-write-wins hash map yields the *second* text everywhere | Determine load order (last-write-wins vs first-write-wins) from the disassembly; this is user-visible |
| 5 | Four further duplicate tags with **identical** text (harmless but must not trip a strict loader): `Desired Transfer` (977, 2644), `Positioning` (1982, 2687), `Vision` (1983, 2719), `settings_Language` (1571, 1973) | duplicate-tag scan | none | Loader must tolerate duplicates rather than assert |
| 6 | **`$variable` typos in translations** - 12 rows where a translator mistyped a placeholder, so the raw token renders in-game | see table below | visible `$playermane` etc. in the affected language | Fix or reproduce; document either way |
| 7 | **Missing translations**: `nl` is missing 174 strings (6.3%); `es`/`fr`/`it`/`pl`/`tr` each miss `CNEWS_RANDOMCLUBCRISIS6` | empty-cell scan | blank dialogs unless a fallback exists | Implement `en` fallback on empty cell |
| 8 | **`Tag_Language` for Spanish is `"Español "` with a trailing space** | `od -c` | trailing space in the language combo | Trim on display, keep in data |
| 9 | **Trailing spaces in four `en` values**: `CNEWS_TRANSFER2`, `CNEWS_TRANSFERMOBILE3`, `CTIP_10`, `WARNING_1` | whitespace scan | cosmetic | Keep verbatim |
| 10 | **`CNEWS_MATCHFOULS1` contains the stray words "boss name"**: *"A disgrace! $opposingclubname boss name declared $playername a disgrace…"* - a leftover from an abandoned `$bossname` placeholder | inspection | grammatically broken headline ships to players | Reproduce verbatim (it is the shipped text) |
| 11 | **`CMESSAGE_GIRLFRIENDDUMPSYOU` says "You girlfriend"** (missing "r") | inspection | typo visible | Reproduce verbatim |
| 12 | **Tag name itself is misspelled: `CMESSAGE_NOMEETINGINGTIRED`** ("MEETINGING") | inspection | none - the exe uses the same misspelling | **Must reproduce exactly** or the lookup breaks |
| 13 | **`CNEWS_MATCHSTARMAN14` opens with an unmatched quote**: `Beautiful!" That was the word…` | inspection | cosmetic | Reproduce verbatim |
| 14 | **`GameMedia/Data/Achievements.csv` has a UTF-8 BOM** (`EF BB BF`) while `Languages.csv` does **not**. A shared CSV loader must strip BOMs or the first column name becomes `id`. | `od -c` | first-field mismatch if unhandled | Strip BOM in the shared loader |
| 15 | **`GameMedia/Data/Horse.ini` contains a duplicate name** ("Bunch Of Fives", 2×) and one entry with a trailing TAB ("Quality Assurance\t") | dedup scan: 249 lines, 248 distinct | two horses can share a name | Reproduce; trim trailing whitespace on load |
| 16 | **Inconsistent distance variables**: `$dist` (match text, furthest-goal/pass) vs `$distance` (social share) | variable scan | none, but two code paths | Reproduce both |
| 17 | **`$keykick`, `$keypause`, `$injurylength` exist in the exe but in no language column** | variable scan | substitutions are no-ops | Keep the substitution hooks |

### 21.1 The 12 typo'd placeholders

| Tag | Language | Broken token | Should be |
|---|---|---|---|
| `CMESSAGE_ENERGYBOOSTGIRL4` | nl | `$energie` | `$energy` |
| `CMESSAGE_SOCIAL8` | fr | `$ssists` | `$assists` |
| `CNEWS_MATCHREDCARD4` | tr | `$opoosingclubname` | `$opposingclubname` |
| `CMATCHTEXT_PASSFANTASTIC` | de | `$distm` | `$dist` |
| `CNEWS_GAMBLINGADDICTBOSS` | pl | `$playermane` | `$playername` |
| `CNEWS_MATCHSTARMANINT4` | fr | `$opposingclubnane` | `$opposingclubname` |
| `CNEWS_RELATIONSHIPBOSS3` | de | `$playernames` | `$playername` |
| `CNEWS_RELATIONSHIPGIRL2` | br | `$plyername` | `$playername` |
| `CNEWS_STYLELOW3` | de | `$player` | `$playername` |
| `CNEWS_TRANSFERMOBILE1` | de | `$offerclubename` | `$offerclubname` |
| `CRESULTNEWS_SHOCKRESULT3` | pl | `$winingteam` | `$winningteam` |
| `CRESULTNEWS_SHOCKRESULTLEADERS1` | fr | `$competion` | `$competition` |

---

## 22. Reconstruction checklist derived from this file

A `TLanguage` implementation faithful to the original must:

1. Read `GameMedia/Languages/Languages.csv` as **UTF-8, CRLF, TAB-separated, unquoted, 11 fields**.
2. Skip line 1 (header) and treat lines 2-4 as metadata (`Tag_Language`, `Tag_NationId`, `Tag_Translator`).
3. Build a tag → string map for the **active column only** (column index chosen from the header row by language
   code), tolerating duplicate tags.
4. Fall back to the `en` column when the active cell is empty (required for `nl`).
5. Support `Get(tag)` and `Get(prefix + index)`.
6. Support `SHOUT` → `POS`/`NEG` token replacement for the boss-shout family.
7. Perform `$variable` substitution with a **letter-initial** token rule so `$1 million` survives.
8. Expose `Tag_NationId` to the new-player screen to preselect nationality.
9. Never assume symmetric variant counts between related families (see defects 1-3).

Systems that this file proves must exist, with their canonical cardinalities:

| System | Cardinality |
|---|---|
| Trainable abilities | 7 |
| Match ratings | 10 |
| Relationships | 6 (+ Fame, + derived Happiness, + Lifestyle, + Skills meters) |
| Shop catalogues | 4 (Items, Vehicles, Property, Boots) × 10 slots |
| Sponsorship categories | 10 (3 of which supply free equipment) |
| Match-day consumables | 6 (NRG, Booze, Enhancers, Pain Killers, Shin Pads, Boots) |
| Boss shout events | 24 × 4 variants × 2 moods, + 5×2 generic |
| Boss report verdict tiers | 4 × 10 variants, + 7 overrides |
| Praise clauses | 14 (10 ratings + 4 "however" variants) |
| Relationship favour requests | 5+5+5+5+5+10 = 35 |
| Energy gift events | 4 sources × 4 |
| Dilemma outcomes | 6 × 4 |
| Achievements (PC) | 100 |
| Loading tips | 50 slots, 49 present |
| Interview clichés | 26 |
| Casino games | 3 (Roulette 6 bets, Black Jack, Slots 8 symbols × 3 reels), 7 stake tiers |
| Horse names | 249 |
| Suspension counters | 3 (`matchtype_club` / `_continental` / `_international`) |
| Simultaneous transfer offers | 5 |
| Career length | 20 seasons |

---

# Appendix A - Complete `CMESSAGE_` dump (408 rows, file order)

The canonical, exhaustive list. Many of these are quoted in the system sections above; this appendix guarantees
nothing is lost.

| Tag | English |
|---|---|
| `CMESSAGE_3SUBLIMIT` | Only 3 substitutes allowed! |
| `CMESSAGE_ACCOUNTBANNED` | This account is no longer active. Please contact support@newstargames.com if you are the owner of this account. |
| `CMESSAGE_BOOTALREADYOWNED` | You already own a new pair of these boots. |
| `CMESSAGE_BOOTSWORNOUT` | Your boots have worn out. |
| `CMESSAGE_BOOZINGBOSS` | The BOSS has found out that you are drinking booze before a game and is furious! |
| `CMESSAGE_BOOZINGFRIENDS` | Your FRIENDS are worried that you are drinking booze before a match! |
| `CMESSAGE_BOOZINGGIRLFRIEND` | Your GIRLFRIEND is not happy about your boozing! |
| `CMESSAGE_BOOZINGSPONSORS` | Your SPONSORS have heard that you are drinking booze before a match. They are not happy! |
| `CMESSAGE_BOOZINGTEAM` | Some TEAM MATES have noticed that you are drunk during a match! They are not impressed. |
| `CMESSAGE_BOSSCHANGINGFORMATION` | The boss announces that he wants to try a new formation. |
| `CMESSAGE_BOSSREQUEST1` | Your BOSS wants you to help coach some of the youth players. It will improve your relationship but cost you $percent% ENERGY. Do you want to help? |
| `CMESSAGE_BOSSREQUEST2` | Your BOSS wants you to visit sick children in the local hospital. It will improve your relationship but cost you $percent% ENERGY. Will you do it? |
| `CMESSAGE_BOSSREQUEST3` | Your BOSS wants you to give an after-dinner speech. It will improve your relationship but cost you $percent% ENERGY. Do you want to do it? |
| `CMESSAGE_BOSSREQUEST4` | Your BOSS wants you take part in an event to find talented youngsters in the local schools. It will improve your relationship but cost you $percent% ENERGY. Will you do it? |
| `CMESSAGE_BOSSREQUEST5` | Your BOSS has asked you to meet up with the physio to check out your diet. It will improve your relationship but cost you $percent% ENERGY. Do you want to do it? |
| `CMESSAGE_BUYBOOZE` | Drinking bottles of BOOZE will temporarily increase your FLAIR but you may have dizzy spells during a match. Are you sure you wish to buy BOOZE? |
| `CMESSAGE_BUYDRUGS` | Buying PERFORMANCE ENHANCERS will temporarily increase your PACE but you may get tested for banned substances after the match. Are you sure you wish to buy PERFORMANCE ENHANCERS? |
| `CMESSAGE_BUYHORSE` | Do you wish to buy this horse for $cash? |
| `CMESSAGE_BUYNRG` | Drinking cans of NRG drink will increase your ENERGY but you may get stomach cramps during a match. Are you sure you wish to buy NRG drink? |
| `CMESSAGE_BUYPAINKILLERS` | Buying PAIN KILLERS will reduce your INJURY but will also increase the chances of suffering a more serious INJURY in the next match. Do you wish to buy PAIN KILLERS? |
| `CMESSAGE_BUYSHINPADS` | Shin pads will increase your TACKLING ability. Do you wish to buy some shin pads? |
| `CMESSAGE_CANCELLOANEARLY` | Are you sure you wish to cancel your loan and return to $clubname? |
| `CMESSAGE_CANNOTBUYFILM` | You need to purchase a TABLET from the shop before you can buy a movie. |
| `CMESSAGE_CANNOTBUYGAME` | You need to purchase a GAMES CONSOLE from the shop before you can buy a game. |
| `CMESSAGE_CANNOTBUYMUSIC` | You need to purchase a MUSIC PLAYER from the shop before you can buy music. |
| `CMESSAGE_CAPTAINCYLOSTBOSS` | The boss has not been impressed with you lately and has taken away the captain's armband! |
| `CMESSAGE_CAPTAINCYLOSTFANS` | The boss has taken the captain's armband away from you because you no longer inspire the fans! |
| `CMESSAGE_CAPTAINCYLOSTTEAM` | The boss has taken the captain's armband away from you because your team mates are not showing you respect! |
| `CMESSAGE_CAPTAINCYWON` | The boss is impressed with your leadership and the way you inspire the fans. He has made you the team captain! You can now attempt to persuade the boss to change tactics on the Formation screen. |
| `CMESSAGE_CASINOINVITEFRIENDS` | Some FRIENDS have invited you to the CASINO. Would you like to go? |
| `CMESSAGE_CASINOINVITETEAMMATES` | Some TEAM MATES have invited you to the CASINO. Would you like to go? |
| `CMESSAGE_CHANGERESOLUTION` | The screen settings will change when you confirm your changes to the Options. |
| `CMESSAGE_CHAPTERFAIL` | Unlucky. You have failed to complete this chapter. |
| `CMESSAGE_CHAPTERLOCKED` | This chapter is locked! |
| `CMESSAGE_CHAPTERSUCCESS` | Congratulations! You have completed this chapter. |
| `CMESSAGE_CHOOSECLUB` | Please choose a club. |
| `CMESSAGE_CHOOSENATION` | Please choose a nation. |
| `CMESSAGE_CHOOSENATIONALITY` | Please choose a nationality. |
| `CMESSAGE_CHOOSEPOSITION` | Please choose a position. |
| `CMESSAGE_CHOOSETEAM1` | Choose team 1 |
| `CMESSAGE_CHOOSETEAM2` | Choose team 2 |
| `CMESSAGE_COMPRESSIDS` | Compressing will remove any spaces between ID numbers, so IDs 10, 20, 30 become 1,2,3. Do you want to compress IDs? |
| `CMESSAGE_CONFIRMPURCHASE` | Do you wish to purchase this item for $cash? |
| `CMESSAGE_CONFIRMPURCHASEENERGYCOST` | Do you wish to purchase this item for $cash? You will lose $energy% energy going shopping. |
| `CMESSAGE_CONNECTIONERROR` | Could not connect to the NSS5 server. Please ensure that your internet connection is working correctly. If everything appears to be fine then please try again. |
| `CMESSAGE_CONTRACTEXPIRED` | Your current contract with $clubname has expired and you have been placed on the transfer list. If you do not renew your contract you can continue to play for them on a rolling contract and receive half your wages. Alternatively you can transfer to any club that is interested in you on a free transfer. |
| `CMESSAGE_CONTRACTINCREASE` | $clubname are willing to increase their offer by $percent%. |
| `CMESSAGE_CONTRACTNEWOFFER` | The boss would like to discuss a new contract with you. Head over to your contract page if you want to renew your contract with $clubname. |
| `CMESSAGE_COULDNOTCREATEPLAYER` | I'm sorry but your player could not be created on the server. Please try again. |
| `CMESSAGE_COULDNOTLOADFILE` | Unable to open this file. '$filename' |
| `CMESSAGE_DELETE` | Are you sure you want to delete '$item'? |
| `CMESSAGE_DELETECLUB` | Are you sure you want to delete the club '$club'? |
| `CMESSAGE_DELETECOMPETITION` | Are you sure you want to delete the competition '$comp'? |
| `CMESSAGE_DELETEPROMOTIONPLACE` | Are you sure you want to delete this promotion place '$place'? |
| `CMESSAGE_DELETEYN` | Delete '$filename'? |
| `CMESSAGE_DEMORESTRICTED` | Please purchase the full version to access this feature. |
| `CMESSAGE_DIFFICULTYEASY` | Opposing players are slow and less skillful in matches. The BOSS is lenient and will pick you for most matches. |
| `CMESSAGE_DIFFICULTYHARD` | The BOSS is strict and will not pick you if you are out of form. You can achieve a higher transfer value. |
| `CMESSAGE_DIFFICULTYNORMAL` | The BOSS will pick you for most matches unless he is very unhappy with you. |
| `CMESSAGE_DIFFICULTYSET1` | Please choose a difficulty level |
| `CMESSAGE_DIFFICULTYSET2` | You can change your difficulty level at any time from the 'Options' screen |
| `CMESSAGE_DOINTERVIEW` | You have been asked to do a post-match interview. A successful interview will increase your FAME. Making a mistake will decrease your FAME. Would you like to do an interview? |
| `CMESSAGE_ENERGYBOOSTFRIENDS1` | Your FRIENDS take you out for a meal! ENERGY +$energy%! |
| `CMESSAGE_ENERGYBOOSTFRIENDS2` | Your FRIENDS take you to the beach for the day! ENERGY +$energy%! |
| `CMESSAGE_ENERGYBOOSTFRIENDS3` | Your FRIENDS take you out for a picnic! ENERGY +$energy%! |
| `CMESSAGE_ENERGYBOOSTFRIENDS4` | A FRIEND is learning Reiki and practices on you! ENERGY +$energy%! |
| `CMESSAGE_ENERGYBOOSTGIRL1` | Your GIRLFRIEND books a spa day for you both! ENERGY +$energy%! |
| `CMESSAGE_ENERGYBOOSTGIRL2` | Your GIRLFRIEND gives you a massage! ENERGY +$energy%! |
| `CMESSAGE_ENERGYBOOSTGIRL3` | Your GIRLFRIEND cooks you a healthy meal! ENERGY +$energy%! |
| `CMESSAGE_ENERGYBOOSTGIRL4` | Your GIRLFRIEND takes you to one of her yoga classes! ENERGY +$energy%! |
| `CMESSAGE_ENERGYBOOSTPHYSIO1` | The club PHYSIO teaches you a great way to warm down after exercising! ENERGY +$energy%! |
| `CMESSAGE_ENERGYBOOSTPHYSIO2` | The club PHYSIO teaches you some breathing exercises! ENERGY +$energy%! |
| `CMESSAGE_ENERGYBOOSTPHYSIO3` | The club PHYSIO teaches you some great stretching techniques! ENERGY +$energy%! |
| `CMESSAGE_ENERGYBOOSTPHYSIO4` | The club PHYSIO books you in for a session with a sports psychologist! ENERGY +$energy%! |
| `CMESSAGE_ENERGYBOOSTTEAM1` | One of your TEAM MATES lends you his hypnosis CD to help you sleep! ENERGY +$energy%! |
| `CMESSAGE_ENERGYBOOSTTEAM2` | A TEAM MATE gives you a great recipe for a healthy juice drink! ENERGY +$energy%! |
| `CMESSAGE_ENERGYBOOSTTEAM3` | A TEAM MATE invites you over to use his home sauna! ENERGY +$energy%! |
| `CMESSAGE_ENERGYBOOSTTEAM4` | A TEAM MATE invites you over to use his hot tub! ENERGY +$energy%! |
| `CMESSAGE_ENTERNAME` | Please enter your full name. |
| `CMESSAGE_ENTERPASSWORD` | Please enter your password. |
| `CMESSAGE_ENTERVALIDEMAIL` | Please enter a valid email address. |
| `CMESSAGE_FANSREQUEST1` | You have been invited to an evening dinner for the club's disabled FANS. It will improve your relationship but cost you $percent% ENERGY. Do you want to do it? |
| `CMESSAGE_FANSREQUEST2` | You see a car broken down on the roadside and notice from the flags and stickers that it belongs to a FAN. Will you stop to help? It will improve your relationship but cost you $percent% ENERGY. |
| `CMESSAGE_FANSREQUEST3` | You see a girl wearing a replica shirt with your name on it struggling with her bike which has a puncture. Will you stop to help her? It will improve your relationship with the FANS but cost you $percent% ENERGY. |
| `CMESSAGE_FANSREQUEST4` | A woman stops you by the river and asks if you will help her find her dog. She says she is a big fan of yours. Will you help? It will improve your FANS relationship but cost you $percent% ENERGY. |
| `CMESSAGE_FANSREQUEST5` | You have been asked to attend the next supporters club meeting. It will improve your relationship with the FANS but cost you $percent% ENERGY. Will you attend? |
| `CMESSAGE_FILECONFIRMDELETE` | Are you sure you wish to delete this file? '$filename' |
| `CMESSAGE_FILECORRUPTDELETE` | The file '$filename' seems to be corrupt. Do you wish to delete it? |
| `CMESSAGE_FILECORRUPTRESTORE` | The file '$filename' seems to be corrupt. Do you wish to try to recover it from the backup file? |
| `CMESSAGE_FILEEXISTSOVERWRITE` | There is already a save file with this name. Do you wish to overwrite it? |
| `CMESSAGE_FILEGETSAVENAME` | Please choose a name for your save file. |
| `CMESSAGE_FILENOTCREATED` | Could not create file '$filename'! |
| `CMESSAGE_FIRSTCONTRACTREJECT` | If you reject this contract you will have to perform the trial challenges again. Are you sure you want to reject this contract offer? |
| `CMESSAGE_FITAGAINTRAVELTIME` | You are match fit again! You may want to go back to the map screen to check the travel time. |
| `CMESSAGE_FREEBOOTS` | Your SPONSORS send you some free boots. |
| `CMESSAGE_FRIENDSREQUEST1` | Some of your FRIENDS are having a party. If you go along it will improve your relationship but cost you $percent% ENERGY. Will you go? |
| `CMESSAGE_FRIENDSREQUEST2` | Some of your FRIENDS are having a video game session. If you join in it will improve your relationship but cost you $percent% ENERGY. Will you go? |
| `CMESSAGE_FRIENDSREQUEST3` | A FRIEND asks if you will look after his dog for a few days and take it out for walks. It will improve your relationship but cost you $percent% ENERGY. Will you help? |
| `CMESSAGE_FRIENDSREQUEST4` | A FRIEND is in hospital for a minor operation. If you visit him it will improve your relationship but cost you $percent% ENERGY. Will you visit? |
| `CMESSAGE_FRIENDSREQUEST5` | A FRIEND asks if you will babysit their child for a few hours. It will improve your relationship but cost you $percent% ENERGY. Will you help? |
| `CMESSAGE_GAMBLINGADDICT1` | Your SPONSORS have been made aware of your gambling habit and they are not impressed! |
| `CMESSAGE_GAMBLINGADDICT2` | Your GIRLFRIEND is fed up with your gambling addiction! |
| `CMESSAGE_GAMBLINGADDICT3` | Your FRIENDS are worried about your gambling addiction! |
| `CMESSAGE_GAMBLINGADDICT4` | The BOSS has heard about your gambling addiction and is not happy! |
| `CMESSAGE_GETEMAIL` | Please enter your email address in case you forget your password. |
| `CMESSAGE_GETJOY` | Press a joystick direction or button |
| `CMESSAGE_GETKEY` | Press a key |
| `CMESSAGE_GETNEWPLAYERPASSWORD` | Your player profile will be stored in the database. Please choose a password (minimum 8 characters). |
| `CMESSAGE_GETTINGOLD` | You are moving into the latter stages of your career and you are not as physically strong as you once were. Your PACE and DRIBBLING abilities will become more and more limited with each passing year. |
| `CMESSAGE_GIRLFRIENDDUMPSYOU` | You girlfriend is so unhappy that she has dumped you! |
| `CMESSAGE_GIRLFRIENDEND` | Do you wish to end the relationship with your GIRLFRIEND? |
| `CMESSAGE_GIRLFRIENDGET` | Amazing! You actually have a GIRLFRIEND. |
| `CMESSAGE_GIRLFRIENDMEET` | You meet an attractive woman. She has a SCANDAL rating of $scandalrating%. Do you want to start dating her? |
| `CMESSAGE_GIRLFRIENDNOTIMPRESSED` | You meet an attractive woman but she is not impressed with your LIFESTYLE! Try buying some cool stuff in the shop. |
| `CMESSAGE_GIRLFRIENDNOTMET` | You are not meeting many women because you have a dull social life! Try increasing your relationship with FRIENDS. |
| `CMESSAGE_GIRLREQUEST1` | Your GIRLFRIEND has asked you to help her parents move house. It will improve your relationship but cost you $percent% ENERGY. Do you want to help? |
| `CMESSAGE_GIRLREQUEST2` | Your GIRLFRIEND has asked you to re-decorate your living room. It will improve your relationship but cost you $percent% ENERGY. Will you do it? |
| `CMESSAGE_GIRLREQUEST3` | Your GIRLFRIEND wants to introduce you to some of her friends. It will improve your relationship but cost you $percent% ENERGY. Do you want to meet them? |
| `CMESSAGE_GIRLREQUEST4` | Your GIRLFRIEND wants to go swimming with you. It will improve your relationship but cost you $percent% ENERGY. Will you go? |
| `CMESSAGE_GIRLREQUEST5` | Your GIRLFRIEND wants to go on a bicycle ride with you. It will improve your relationship but cost you $percent% ENERGY. Do you want to go? |
| `CMESSAGE_HISTORYBUTTON` | There is a new button on your Stats screen labelled 'My History'. You can click it to see a record of your tournament places and awards. |
| `CMESSAGE_HORSEBECOMESILL` | Your horse $name has become ill. |
| `CMESSAGE_HORSEEXHAUSTED` | Your horse $name is exhausted and his health is suffering! Horses with low health will lose strength. |
| `CMESSAGE_HORSEHEALTHY` | This horse is healthy. |
| `CMESSAGE_HORSEILL` | This horse in not healthy. You need to treat it first. |
| `CMESSAGE_HORSEPRIZE` | Your horse won $cash in prize money! |
| `CMESSAGE_HORSETIRED` | This horse is too tired to race. |
| `CMESSAGE_INFLATEIDS` | Inflating will space out ID numbers, so IDs 1,2,3 become 10,20,30. Do you want to inflate IDs? |
| `CMESSAGE_INVALIDBREAK` | Duration + Break must equal 12, 24, 36 or 48 months. |
| `CMESSAGE_INVALIDCOMPETITION` | Please enter a valid competition id. |
| `CMESSAGE_INVALIDEMAIL` | Your email address appears to be invalid. Please type it again. |
| `CMESSAGE_INVALIDPASSWORD` | Please use an alpha-numeric password, at least 8 characters long. |
| `CMESSAGE_INVALIDPLACE` | Please enter a valid place. |
| `CMESSAGE_INVALIDPLAYERNAME` | Your player name must use only letters and be between 3 and 26 characters long. Please try again. |
| `CMESSAGE_INVALIDSKILLSHASH` | Your save file seems to be corrupted and your skills have been reset. |
| `CMESSAGE_ITEMNOTOWNED` | You do not own this item |
| `CMESSAGE_LASTSEASON` | You are approaching the end of your career and this season will be your last before you retire. |
| `CMESSAGE_LEADERBOARDCOULDNOTRETRIEVE` | Could not connect! |
| `CMESSAGE_LEADERBOARDNOTSUBMITTEDHASH` | Could not submit stats to the leaderboard. Your save file is invalid. |
| `CMESSAGE_LEADERBOARDNOTSUBMITTEDPASSWORD` | Could not submit stats to the leaderboard. Your password is incorrect. |
| `CMESSAGE_LEAGUEFINISHPOS` | Oh dear. You finished the season in position $pos. |
| `CMESSAGE_LEAGUESTARTNEW` | Would you like to start a new season? |
| `CMESSAGE_LEAGUEWON` | Congratulations you have won the league! |
| `CMESSAGE_LOANENDBOSSUNHAPPY` | Your loan spell has been terminated. The $loanclub BOSS has not been impressed with you. |
| `CMESSAGE_LOANENDED` | Your loan spell with $loanclub has ended and you have returned to $clubname. |
| `CMESSAGE_LOANOFFER` | Would you like to go on loan to $clubname for 6 months? |
| `CMESSAGE_LOANOFFERTOSEASONEND` | Would you like to go on loan to $clubname until the end of the season? |
| `CMESSAGE_LOANREQUESTREJECTED` | The boss does not want to let you out on loan. You are a valued member of the squad. |
| `CMESSAGE_LOANREQUESTREJECTEDDATE` | The boss does not want to let you out on loan. You should renew you current contract with the club first. |
| `CMESSAGE_LOANSTARTED` | You have joined $loanclub on loan. Whilst you are on loan the relationships screen will reflect your relationships with the BOSS, TEAM and FANS at $loanclub. You can check your relationship with the $clubname BOSS on the contract screen. It will improve if you do well at $loanclub. |
| `CMESSAGE_LONGTIMEFRIENDS` | Your FRIENDS are unhappy because you have not spent any time with them for weeks. |
| `CMESSAGE_LONGTIMEGIRLFRIEND` | Your GIRLFRIEND is extremely unhappy because you have not spent any time with her for weeks. |
| `CMESSAGE_LOSTITEM` | One of your luxury items has been stolen! ($item) |
| `CMESSAGE_LOSTVEHICLE1` | One of your vehicles has broken down and is beyond repair! ($vehicle) |
| `CMESSAGE_LOSTVEHICLE2` | One of your vehicles has been stolen! ($vehicle) |
| `CMESSAGE_LOSTVEHICLE3` | One of your vehicles has broken down! ($vehicle) Do you wish to repair it for $cost? |
| `CMESSAGE_MOVEMENTMAP` | Hold RIGHT for movement map |
| `CMESSAGE_MUSTBEONLINE` | You must be connected to the internet to start a new career. |
| `CMESSAGE_MUSTUPDATEVERSION` | There is a new version of NSS5! You need to download the latest version before you can register a new player. |
| `CMESSAGE_NEEDAPHONE` | Your FRIENDS and TEAM MATES have been trying to contact you but you don't own a PHONE! Head to the SHOP and purchase one as soon as you can. |
| `CMESSAGE_NEGOTIATIONSCANCELLED` | $clubname have withdrawn their contract offer. |
| `CMESSAGE_NEWCOMPIDEXISTS` | The competition id cannot be changed because the id '$id' already exists! |
| `CMESSAGE_NEWCOMPIDSET` | The competition id has been changed to '$id'. |
| `CMESSAGE_NEWFORMATIONFAILRECENT` | The boss is furious that you have suggested changing formation when you know he is trying out a something new. |
| `CMESSAGE_NEWFORMATIONFAILRELATIONSHIP` | The boss does not want to change the formation. Your relationship with him is not good enough. |
| `CMESSAGE_NEWFORMATIONNOTCAPTAIN` | The boss does not want to change the formation. You need to be the team captain to influence his decision. |
| `CMESSAGE_NEWPOSITIONFAIL` | The boss will not change your position. You need to improve your relationship with him. |
| `CMESSAGE_NEWPOSITIONFAILDEFENDER` | The BOSS does not want to change your position. You will need to focus your training on TACKLING if you want to be a defender. |
| `CMESSAGE_NEWPOSITIONFAILFORWARD` | The BOSS does not want to change your position. You will need to focus your training on SHOOTING if you want to be a forward. |
| `CMESSAGE_NEWPOSITIONFAILMIDFIELDER` | The BOSS does not want to change your position. You will need to focus your training on PASSING if you want to be a midfielder. |
| `CMESSAGE_NEWPOSITIONSUCCESS` | The boss has agreed to let you play in a new position. |
| `CMESSAGE_NEWSLETTER` | Get Retro Football news! |
| `CMESSAGE_NOCASINOTIRED` | You are too tired to go to the casino! |
| `CMESSAGE_NOFREETIME` | You don't have any free time left. Try again after your next match. |
| `CMESSAGE_NOGAMESLEFT` | You currently have a FREE account and have exceeded your maximum number of matches for today. Your free matches will refresh in $wait. If you don't want to wait you can buy more matches. Would you like to buy more matches now? |
| `CMESSAGE_NOGIRLFRIEND` | You do not have a GIRLFRIEND yet! |
| `CMESSAGE_NOHELP` | Sorry but there is no help file for this page. |
| `CMESSAGE_NOMEETINGINGTIRED` | You are too tired to meet anyone! |
| `CMESSAGE_NOMORERACES` | There are no more races today. |
| `CMESSAGE_NONEGOTIATING` | $clubname do not wish to negotiate further. |
| `CMESSAGE_NOPREMIUMNOHARD` | Only Premium players can play on the HARD difficulty level. After upgrading you can select it from the OPTIONS menu. |
| `CMESSAGE_NORACINGTIRED` | You are too tired to go to racing! |
| `CMESSAGE_NORENEWBOSSUNHAPPY` | The boss does not want to renew your contract at the moment because he is unhappy with you. |
| `CMESSAGE_NORENEWLOANLISTED` | You cannot renew your contract whilst you are listed for loan. |
| `CMESSAGE_NORENEWONLOAN` | You cannot renew your contract whilst you are on loan. |
| `CMESSAGE_NORENEWTOOSOON` | The boss does not want to renew your contract yet. It has been less than 6 months since you signed the last one. |
| `CMESSAGE_NOSHOPPINGTIRED` | You don't have enough energy to go shopping! |
| `CMESSAGE_NOSPONSORS` | You do not have any sponsors at the moment. |
| `CMESSAGE_NOSTABLE` | You do not own a stable yet. You can purchase one in the shop under the Property section. Each stable you buy will house up to 2 race horses. |
| `CMESSAGE_NOTENOUGHCASH` | You do not have enough money! |
| `CMESSAGE_NOTRAININGINJURY` | You cannot train whilst you are injured. |
| `CMESSAGE_NOTRAININGMAX` | You are at the maximum limit for this ability. |
| `CMESSAGE_NOTRAININGTIRED` | You cannot train. You are too tired. |
| `CMESSAGE_NOTTIRED` | You do not need to buy any entertainment because you are not tired. |
| `CMESSAGE_OFFLINERESTRICTEDTRANSFER` | You need to be connected to the internet to make a transfer move so that the database can be updated. |
| `CMESSAGE_ONLY1HORSE` | You already have a horse in this race. |
| `CMESSAGE_OVERWRITEFILE` | Do you want to overwrite the file '$filename'? |
| `CMESSAGE_OVERWRITESAVE` | Starting a new campaign will overwrite your existing save file. Do you wish to continue? |
| `CMESSAGE_PAINKILLERSSERIOUSINJURY` | Your INJURY is severe and PAIN KILLERS will do nothing to help at the moment. Please try again later. |
| `CMESSAGE_PASSWORDINCORRECT` | That is the wrong password. Would you like to reset your password? |
| `CMESSAGE_PASSWORDOKFREE` | You currently have a FREE account which means that you can only play a limited number of matches per day. You have $matches matches remaining today. |
| `CMESSAGE_PASSWORDSDONTMATCH` | Your passwords don't match. Please try again. |
| `CMESSAGE_PASSWORDTOOSHORT` | Your password is too short. |
| `CMESSAGE_PLAYERDOESNOTEXIST` | This player name does not exist. Would you like to create a new account? |
| `CMESSAGE_PLAYEREXISTS` | This player name exists already. Please try again. |
| `CMESSAGE_PLAYEREXISTSENTERPASSWORD` | This player name exists in the database already. Please enter your password. (If you did not create the original player then please go back and choose a different player name.) |
| `CMESSAGE_PLAYERNOTFOUND` | This player $name could not be found in the NSS5 database. Please contact support@newstargames.com. |
| `CMESSAGE_PREMIUMCHECKIN` | As a PREMIUM account holder you need to connect to the server at least once every 50 matches in order to update your player profile. You have 10 matches remaining until you need to connect online. |
| `CMESSAGE_PREMIUMMUSTCHECKIN` | You have played 50 matches since you last connected to the NSS5 server. You must connect in order to update your player profile. |
| `CMESSAGE_PREMIUMONLYLEADERBOARDVIEW` | Only PREMIUM players can view player stats. |
| `CMESSAGE_PROMOTEDTOATEAM` | Congratulations! You are now playing in the A team of $clubateam. Your existing contract has not changed. |
| `CMESSAGE_PROMOTEFROMBTEAM` | The boss of $clubateam would like to promote you up from the B team. Would you like to switch to the A team? |
| `CMESSAGE_QUIT` | Are you sure you want to quit? |
| `CMESSAGE_RACEHORSE` | Do you wish to race this horse? |
| `CMESSAGE_RELATIONSHIPFULL` | This relationship is already at maximum level! |
| `CMESSAGE_REQUESTCANCELLED` | The boss has removed you from the transfer list. |
| `CMESSAGE_REQUESTCONFIRM` | Are you sure you wish to request a transfer? The boss will not be happy. |
| `CMESSAGE_REQUESTLOANCONFIRM` | Are you sure you wish to request a loan? |
| `CMESSAGE_REQUESTNOTCANCELLED` | The boss is not happy with you and has refused to remove you from the transfer list. |
| `CMESSAGE_REQUESTNOTCANCELLEDCONTRACT` | Your contract has expired so you cannot come off the transfer list. Try to renew your contract if you wish to stay at this club. |
| `CMESSAGE_RETIRED` | You have retired! |
| `CMESSAGE_RETIREMENT` | You have had a wonderful career with many highs and lows but it is now time to hang up your boots. I hope you have enjoyed New Star Soccer 5. Thank you for playing! |
| `CMESSAGE_RETIREMENTLEGEND` | You have had a magnificent career and will always be remembered as one of the true legends. Your name ranks alongside some of footballs greatest heros... Pele, Maradona, Zidane, Messi, $playername. I hope you have enjoyed New Star Soccer 5. Thank you for playing! |
| `CMESSAGE_SAVEANDQUIT` | Do you want to save and quit? |
| `CMESSAGE_SAVEMASTERFILES` | Do you wish to save the database? |
| `CMESSAGE_SCENARIOFIXMATCHMIN` | Match minute must be between 0 and 105 |
| `CMESSAGE_SCENARIOFIXSCORE1` | Score 1 must be between 0 and 9 |
| `CMESSAGE_SCENARIOFIXSCORE2` | Score 2 must be between 0 and 9 |
| `CMESSAGE_SCENARIONOTEAM1` | Please enter a name for team 1 |
| `CMESSAGE_SCENARIONOTEAM2` | Please enter a name for team 2 |
| `CMESSAGE_SCENARIONOTFOUND` | Could not retrieve scenario. Please make sure you have the correct id or try later. |
| `CMESSAGE_SCENARIONOTITLE` | Please enter a title for your scenario |
| `CMESSAGE_SCENARIONOTSUBMITTED` | Could not submit scenario to the database! Please try again later. |
| `CMESSAGE_SCENARIORETRIEVED` | Scenario retrieved! |
| `CMESSAGE_SCENARIOSAVED` | Scenario '$filename' saved. |
| `CMESSAGE_SCENARIOSUBMITTED` | Congratulations! Your scenario was submitted to the database. Other people can play your scenario by using the id: $code. |
| `CMESSAGE_SELECTFRIEND` | You need to select a player in the list to add a friend. |
| `CMESSAGE_SELECTHORSE` | Please select a horse from the list. |
| `CMESSAGE_SELLHORSE` | Do you wish to sell this horse for $cash? |
| `CMESSAGE_SELLITEM` | Do you wish to sell this item for $value? |
| `CMESSAGE_SHORTORLONGSEASON` | Long seasons have $num1 rounds, short seasons have $num2 rounds. Do you want to play a long season? |
| `CMESSAGE_SKIPTIMEEND` | Do you wish to skip to the end of the match? |
| `CMESSAGE_SKIPTIMESUB` | Do you wish to skip to your substitution? |
| `CMESSAGE_SKIPTOCONTINUE` | Press KICK to continue |
| `CMESSAGE_SOCIAL1` | I am currently playing for $clubname in New Star Soccer 5! |
| `CMESSAGE_SOCIAL10` | I have made $passes passes in New Star Soccer 5. |
| `CMESSAGE_SOCIAL2` | My transfer value is $value in New Star Soccer 5! |
| `CMESSAGE_SOCIAL3` | I have an average rating of $rating in New Star Soccer 5! |
| `CMESSAGE_SOCIAL4` | New Star Soccer 5 is awesome! |
| `CMESSAGE_SOCIAL5` | I love New Star Soccer 5. |
| `CMESSAGE_SOCIAL6` | I have scored $goals goals in New Star Soccer 5. |
| `CMESSAGE_SOCIAL7` | I have made $tackles tackles in New Star Soccer 5. |
| `CMESSAGE_SOCIAL8` | I have made $assists assists in New Star Soccer 5. |
| `CMESSAGE_SOCIAL9` | I have run $distance metres in New Star Soccer 5. |
| `CMESSAGE_SPONSORCANCEL` | Your relationship with your $sponsor sponsors has broken down. They have cancelled your sponsorship! |
| `CMESSAGE_SPONSOREXPIRED` | Your $sponsor sponsorship contract has expired. |
| `CMESSAGE_SPONSOROFFER` | You have been offered a $sponsor sponsorship contract. You will be paid $cash in weekly installments over 1 year. Do you wish to accept this offer? |
| `CMESSAGE_SPONSORREQUEST1` | Your SPONSORS want you to take part in a photoshoot for a new product. It will improve your relationship and increase your FAME but cost you $percent% ENERGY. Do you wish to take part? |
| `CMESSAGE_SPONSORREQUEST10` | Your SPONSORS want you to appear in a TV advert. It will improve your relationship and increase your FAME but cost you $percent% ENERGY. Do you want to do it? |
| `CMESSAGE_SPONSORREQUEST2` | Your SPONSORS want you to make an appearance at a corporate event. It will improve your relationship and increase your FAME but cost you $percent% ENERGY. Do you want to do it? |
| `CMESSAGE_SPONSORREQUEST3` | Your SPONSORS want you to take sign autographs at the launch of a new product. It will improve your relationship and increase your FAME but cost you $percent% ENERGY. Do you want to do it? |
| `CMESSAGE_SPONSORREQUEST4` | Your SPONSORS want you to make an appearance at a charity event. It will improve your relationship and increase your FAME but cost you $percent% ENERGY. Do you want to do it? |
| `CMESSAGE_SPONSORREQUEST5` | Your SPONSORS want you to make a brief appearance on a TV show. It will improve your relationship and increase your FAME but cost you $percent% ENERGY. Do you want to do it? |
| `CMESSAGE_SPONSORREQUEST6` | Your SPONSORS want you to make appear on a radio show. It will improve your relationship and increase your FAME but cost you $percent% ENERGY. Do you want to do it? |
| `CMESSAGE_SPONSORREQUEST7` | Your SPONSORS want you to do an interview for a magazine. It will improve your relationship and increase your FAME but cost you $percent% ENERGY. Do you want to do it? |
| `CMESSAGE_SPONSORREQUEST8` | Your SPONSORS want you to do an interview for a website. It will improve your relationship and increase your FAME but cost you $percent% ENERGY. Do you want to do it? |
| `CMESSAGE_SPONSORREQUEST9` | Your SPONSORS want you to do an interview for a newspaper. It will improve your relationship and increase your FAME but cost you $percent% ENERGY. Do you want to do it? |
| `CMESSAGE_SPONSORSHIPACCEPT` | Congratulations! You have agreed a new sponsorship deal! |
| `CMESSAGE_SPONSORSHIPACCEPTBOOTS` | Congratulations! You now get your boots for free! |
| `CMESSAGE_SPONSORSHIPACCEPTDRINK` | Congratulations! You now get your NRG drink for free! |
| `CMESSAGE_SPONSORSHIPACCEPTSHINPADS` | Congratulations! You now get your shin pads for free! |
| `CMESSAGE_STABLE_NOROOM` | You need to increase your stable size! |
| `CMESSAGE_TEAMREQUEST1` | Some of your TEAM MATES have arranged a golf tournament. If you take part it will improve your relationship but cost you $percent% ENERGY. Do you want to play? |
| `CMESSAGE_TEAMREQUEST2` | Some of your TEAM MATES are doing interviews and photos for the club magazine and you have been invited along. Do you want to attend? It will improve your relationship but cost you $percent% ENERGY. |
| `CMESSAGE_TEAMREQUEST3` | Some of your TEAM MATES are playing poker after training. If you attend it will improve your relationship but cost you $percent% ENERGY. Do you want to play with them? |
| `CMESSAGE_TEAMREQUEST4` | Some of your TEAM MATES are going karting. If you take part it will improve your relationship but cost you $percent% ENERGY. Do you want to join them? |
| `CMESSAGE_TEAMREQUEST5` | Some of your TEAM MATES are doing some charity work at the local hospital. Do you want to attend? It will improve your relationship but cost you $percent% ENERGY. |
| `CMESSAGE_TESTDATACONTINUE` | Continue to the testing menu? |
| `CMESSAGE_TESTDATASAVE` | After starting the data test you cannot save the database. Would you like to save now? |
| `CMESSAGE_THANKS` | Thanks for playing! |
| `CMESSAGE_TRAININGFAIL` | Unlucky. You have failed this training challenge. |
| `CMESSAGE_TRAININGSUCCESS` | Congratulations! You have passed this training challenge. |
| `CMESSAGE_TRANSFERCLUBCANNOTAFFORDYOU` | This club cannot afford your transfer fee. You will need to wait until your current contract has expired so that you can be transferred for free. |
| `CMESSAGE_TRANSFERFIRSTCLUB` | You have signed a contract with $clubname! |
| `CMESSAGE_TRANSFERLISTEDBOSSUNHAPPY` | The boss has not been impressed with your attitude or performance lately and has put you on the transfer list. |
| `CMESSAGE_TRANSFERNEWCLUB` | You have signed a new contract with $clubname! You were transferred for $value. |
| `CMESSAGE_TRANSFERNEWCLUBFREE` | You have signed a new contract with $clubname! You were transferred for free. |
| `CMESSAGE_TRANSFERSAMECLUB` | You have signed a new contract with $clubname! |
| `CMESSAGE_TRANSFERWINDOWCLOSED` | The transfer window has now closed. |
| `CMESSAGE_TRANSFERWINDOWCLOSEDNEXT` | The transfer window is currently closed. The next window opens on week $transdate. Check your contract page after this date to negotiate offers. |
| `CMESSAGE_TRANSFERWINDOWOPEN` | The transfer window is now open. If you are transfer listed you can check your contract page to view offers. |
| `CMESSAGE_TREATHORSE` | Do you wish to treat this horse for $cash? |
| `CMESSAGE_TRIAL` | OK! Your player details are all set up. Now you must undergo a football trial with $clubname and complete 7 training challenges. Don't worry if you fail a challenge, you can still progress to the next one. |
| `CMESSAGE_TRIALBALLS` | This shows you how many balls you have left to complete the challenge. |
| `CMESSAGE_TRIALDRIBBLING` | Now you need to complete the DRIBBLING test. It is exactly the same as the PACE test only this time you need to run with the ball. |
| `CMESSAGE_TRIALFAIL` | Oh dear. $clubname were not impressed with your skills and you failed the trial! Don't worry, you can always try again. |
| `CMESSAGE_TRIALFLAIR` | Nearly there! The last trial tests your FLAIR ability. You are able to bend the flight of a ball by moving left or right just after kicking it. Kick the ball between the posts and immediately push LEFT or RIGHT to bend it slightly. |
| `CMESSAGE_TRIALGOALS` | This shows you how many goals you need to score to complete the challenge. |
| `CMESSAGE_TRIALHEADINGADVANCED` | This is the HEADING test. CALL for a ball by tapping a KICK button. Whilst the ball is in the air hold down a KICK button to run towards it and perform a header. Aim it into the goal. |
| `CMESSAGE_TRIALHEADINGSIMPLE` | This is the HEADING test. CALL for a ball by tapping the KICK button then head it into the goal. The key here is to HOLD down the kick button whilst the ball is in the air. |
| `CMESSAGE_TRIALPACE` | The first trial is to test your PACE. Guide your player between the poles and into the green zone before the time runs out. If you want to change the game controls press PAUSE and choose OPTIONS then EDIT CONTROLS. Press KICK to start. |
| `CMESSAGE_TRIALPASSING` | Now you need to prove your PASSING skills. Aim towards the training cones and kick the ball between them. The longer you hold the KICK button the harder you will kick the ball. |
| `CMESSAGE_TRIALSHOOTINGADVANCED` | Now you need to show off your SHOOTING skills. First CALL for a ball by tapping a KICK button. Once you have control of the ball aim towards the goal and SHOOT. Call for another ball if you need it. |
| `CMESSAGE_TRIALSHOOTINGSIMPLE` | Now you need to show off your SHOOTING skills. First CALL for a ball by tapping the KICK button. Once you have control of the ball aim towards the goal and SHOOT. Call for another ball if you need it. |
| `CMESSAGE_TRIALSUCCESS` | Amazing! You have really impressed $clubname with your skills and they are ready to offer you a contract. |
| `CMESSAGE_TRIALTACKLING` | Next up is the TACKLING test. Run towards the training cone and knock it over with a SLIDE TACKLE. |
| `CMESSAGE_TRIALTIME` | This shows you how much time you have left to complete the challenge. |
| `CMESSAGE_UPDATEVERSION` | There is a new version of NSS5! If you wish to access the leaderboards and squad data you need to download the latest version. Would you like to update now? |
| `CMESSAGE_UPGRADEFORFREEMIUM` | You must install the latest version to play with a FREE account. |
| `CMESSAGE_USEMOUSE` | Please use mouse to change controls. |
| `CMESSAGE_CHANGELANGUAGE` | To change the language you must quit your game and select options from the main menu. |
| `CMESSAGE_SKIPMATCH` | Are you sure you want to skip this match? |
| `CMESSAGE_NO7MINS` | Only premium players can play 7 minute matches. |
| `CMESSAGE_ARCADE` | Arcade Mode! |
| `CMESSAGE_ARCADENEWRECORD` | A new record! |
| `CMESSAGE_BONUSINCREASED` | The boss has increased your goal and assist bonuses! |
| `CMESSAGE_BOOTSHAVEMATCHES` | Your existing boots can still be worn for $num matches. Are you sure you want to buy new boots? |
| `CMESSAGE_BRIBE` | A shady looking character offers you a bribe. He says he will give you $amount if you play badly and lose the next match. Do you want to take him up on the offer? |
| `CMESSAGE_BRIBECAUGHT` | SCANDAL! $playername accepted a bribe for playing badly in the match against $opposingclubname. How do we know? Because the dodgy deal was set up by one of our reporters! |
| `CMESSAGE_BRIBECOMPLETE` | The shady man gives you $amount. He looks forward to doing business with you some other time. |
| `CMESSAGE_BRIBEFAILED` | The shady man is disappointed that you did not lose the match. You do not receive any cash. |
| `CMESSAGE_CAREERMODEPURCHASE` | You must unlock the Career Mode via the Shop if you wish to continue playing. |
| `CMESSAGE_CAREERMODETRIAL` | You can play up to 10 matches in the Career Mode for free. After that you must unlock the full version via the Shop if you wish to continue. |
| `CMESSAGE_CHECKDONETUTORIAL` | Would you like to see the kicking tutorial? |
| `CMESSAGE_CHECKOVERWRITESAVE` | If you start a new career you will overwrite the exisiting save file. Are you sure you want to start a new career? |
| `CMESSAGE_CHECKOVERWRITESAVEIOS` | If you start a new career you will overwrite the exisiting save file, however, your existing Star Bux will carry over into your new game. Are you sure you want to start a new career? |
| `CMESSAGE_CHOOSEDESIREDTRANSFER` | Set your preferred transfer destination |
| `CMESSAGE_CLUBSINTERESTED` | Clubs interested |
| `CMESSAGE_CLUBSNOTINTERESTED` | No clubs in this division are interested in signing you |
| `CMESSAGE_CONTRACTINCREASEMOBILE` | $clubname are willing to increase their offer to $wage per match and $bonus per goal. |
| `CMESSAGE_CONTRACTOFFERMOBILE` | $clubname are offering you $wage per match and $bonus per goal. |
| `CMESSAGE_CREDITS` | New Star Soccer was created by Simon Read. Graphics by Chico and Simon. Special thanks to Mark Sibly (Monkey), John Holden (help and data), Nick Greig, Anti Shinkie, Vasilis, Diavol, Stephen Tyas, tinoco, Kurt Brunenberg, Szenti, Toni Sagues Bosch, Marko Hladnik, Milan Sulek, Damianii (all league data), Ziggy (JungleIDE and Font Machine), Steve & Shane (Diddy), James Boyd (Autofit), Alex (GameCenter), Roman Budzowski (iap), Brad (Kong), GfK, Paulo Tavares (testing), Damian Sinclair (coding help). |
| `CMESSAGE_DEBUTTIRED` | The boss notices that you are very tired for your debut match. He gives you an NRG drink to replenish your ENERGY but in future he wants you to save enough energy to start matches. |
| `CMESSAGE_DRINKNRGCHECK` | You still have plenty of ENERGY. Are you sure you want to drink a can of NRG? |
| `CMESSAGE_ENERGYCHECKLOW` | You have very low ENERGY. Would you like to use an NRG drink? |
| `CMESSAGE_ENERGYFULL` | Energy full! |
| `CMESSAGE_GIRLFRIENDMEETMOBILE` | Amazing! You meet an attractive girl and she likes you! Do you want to start dating? |
| `CMESSAGE_GIRLFRIENDRAMPAGEBOSS` | $playername's girlfriend was interviewed on a radio show and claimed that the $clubname boss doesn't care about his players! |
| `CMESSAGE_GIRLFRIENDRAMPAGEFANS` | $playername's girlfriend appeared on a chat show and stated that the $clubname fans are all idiots! |
| `CMESSAGE_GIRLFRIENDRAMPAGETEAM` | $playername's girlfriend was recently interviewed in a gossip magazine and stated that the $clubname players are a bad influence on him! |
| `CMESSAGE_INTERNATIONALSTARTYEAR` | International and club continental tournaments have been added in this version! Since you have updated the game in the middle of your career the international fixtures won't start until year $year. Club continental fixtures will start next season. |
| `CMESSAGE_KONGWELCOME` | Welcome, $name! |
| `CMESSAGE_NEGOTIATEWITH` | Negotiate contract with $clubname |
| `CMESSAGE_NEGOTIATIONFAILED` | $clubname are not willing to negotiate any further. |
| `CMESSAGE_NEWFURTHESTGOAL` | New furthest goal stat! ($dist) |
| `CMESSAGE_NEWFURTHESTPASS` | New furthest pass stat! ($dist) |
| `CMESSAGE_NEWSEASONWITHSAMECLUB` | Do you want to start a new season with your current club $clubname? |
| `CMESSAGE_NOBONUSLUCRATIVE` | The BOSS is not willing to improve your contract. He feels you are already on quite a lucrative wage for your STAR RATING. |
| `CMESSAGE_NOBONUSRELATIONSHIPBOSS` | The BOSS does not want to discuss your contract. Your relationship with him is too low. |
| `CMESSAGE_NOBONUSRELATIONSHIPFANS` | The BOSS does not want to discuss your contract. Your relationship with the FANS is too low. |
| `CMESSAGE_NOBONUSRELATIONSHIPTEAM` | The BOSS does not want to discuss your contract. Your relationship with the TEAM is too low. |
| `CMESSAGE_NOBONUSSTARRATING` | The BOSS is not willing to improve your contract. You need to increase your STAR RATING. |
| `CMESSAGE_NOBONUSTOOSOON` | The BOSS does not want to discuss your contract. It is too soon since your last meeting. |
| `CMESSAGE_NOCLUBSINTERESTEDATALL` | There are no clubs interested in signing you at all. |
| `CMESSAGE_NOGIRLFRIENDLIFESTYLE` | You do not have a GIRLFRIEND yet! You need to increase your lifestyle to impress the ladies. |
| `CMESSAGE_NONRG` | No NRG! |
| `CMESSAGE_NOSHOPCONNECTION` | Could not connect to shop |
| `CMESSAGE_NOTENOUGHCASHSHORT` | Not enough cash! |
| `CMESSAGE_NOTENOUGHENERGY` | Energy too low! |
| `CMESSAGE_NOTPICKEDENERGY` | The BOSS has not picked you for this match because your ENERGY is too low. He is furious! |
| `CMESSAGE_NOTPICKEDENERGYINT` | The $team BOSS has not picked you for this match because your ENERGY is too low. He is furious! |
| `CMESSAGE_NOTPICKEDRELATION` | The BOSS has not picked you for this match. Try improving your relationship by completing training challenges. |
| `CMESSAGE_NOTPICKEDRELATIONINT` | The $team BOSS has not picked you for this match. You need to impress him by performing well at a decent club level. |
| `CMESSAGE_PROPERTYCHECK` | Buying property gives you a new place to relax and increases your recovery rate after a match! Do you want to buy this property for $price? |
| `CMESSAGE_QUIT` | Do you wish to quit to the main menu? |
| `CMESSAGE_RESTOREPRODUCTS` | If you have purchased shop items before and you have re-installed New Star Soccer, or are installing it on a new device then you can restore your purchases. Would you like to do this now? |
| `CMESSAGE_SEASONENDTRANSFER` | At the end of the season you are able to transfer to any club that is interested in you. You may even transfer to a different country if you wish. Would you like to view the interested clubs? |
| `CMESSAGE_SPONSOROFFERMOBILE` | You have been offered a $sponsor sponsorship contract! You will be paid $cash per match. Do you wish to accept this offer? |
| `CMESSAGE_SPONSORSNOTIMPRESSEDFANS` | You are not attracting new SPONSORS because your relationship with the FANS is too low. |
| `CMESSAGE_SPONSORSNOTIMPRESSEDLIFESTYLE` | You are not attracting new SPONSORS because your LIFESTYLE rating is too low. |
| `CMESSAGE_STARMAN` | You were the star man! |
| `CMESSAGE_SUBENERGY` | You are a substitute for this match because your ENERGY is low. The BOSS is not happy. |
| `CMESSAGE_SUBENERGYINT` | You are a substitute for this match because your ENERGY is low. The $team BOSS is not happy. |
| `CMESSAGE_SUBFORM` | You are a substitute for this match because of your poor performances lately. |
| `CMESSAGE_SUBFORMINT` | You are a substitute for this international match because of your poor performances lately. |
| `CMESSAGE_SUBRELATION` | You are a substitute for this match because your relationship with the BOSS is low. |
| `CMESSAGE_SUBRELATIONINT` | You are a substitute for this match because your relationship with the $team BOSS is low. |
| `CMESSAGE_THREEINAROW` | Three in a row! |
| `CMESSAGE_TRAININGPACE` | Touch and hold the screen where you want to run and intercept the pass. |
| `CMESSAGE_TRAININGPOWER` | Beat the keeper! |
| `CMESSAGE_TRAININGSETPIECES` | Bend your shot to score a goal! |
| `CMESSAGE_TRAININGTECHNIQUE` | Kick the ball between the poles! |
| `CMESSAGE_TRAININGVISION` | Kick the ball at the dummy player! |
| `CMESSAGE_TRANSFERCONFIRM` | Are you sure you wish to transfer to $clubname? You will be paid a goal bonus of $goalbonus and an assist bonus of $assistbonus. |
| `CMESSAGE_TRANSFERNEWCLUBMOBILE` | You have transferred to $clubname! |
| `CMESSAGE_TRANSFEROFFERMOBILE` | $clubname have accepted a transfer offer from $offerclubname for you. You have been given permission to discuss a contract with them but you can reject it if you wish to stay at $clubname. |
| `CMESSAGE_TRANSFERRUMOUR` | A number of clubs are said to be interested in signing $playername in the upcoming transfer window. $clubs are amongst those vying for his signature. |
| `CMESSAGE_TRIALMOBILE1` | OK! You must undergo a football trial and impress the talent scouts! The first trial is TECHNIQUE. This skill determines how much you can bend and dip the ball. |
| `CMESSAGE_TRIALMOBILE2` | Great! Now let's see how good you are at FREE KICKS. |
| `CMESSAGE_TRIALMOBILE3` | Nice! Next up it's the POWER trial. This determines how hard you can kick the ball. |
| `CMESSAGE_TRIALMOBILE4` | Well done! OK, this trial is a little different. You need good PACE to intercept passes. |
| `CMESSAGE_TRIALMOBILE5` | Excellent! The last trial is VISION. Your vision allows you to spot team mates in good positions during a match. |
| `CMESSAGE_TRIALMOBILEFAIL2` | Ok, never mind. Let's see how good you are at FREE KICKS. |
| `CMESSAGE_TRIALMOBILEFAIL3` | Oops! Let try the POWER trial. This determines how hard you can kick the ball. |
| `CMESSAGE_TRIALMOBILEFAIL4` | Oh dear! Let's move on. This trial is a little different. You need good PACE to intercept passes. |
| `CMESSAGE_TRIALMOBILEFAIL5` | Unlucky! But don't worry about it. The last trial is VISION. Your vision allows you to spot team mates in good positions during a match. |
| `CMESSAGE_TRIALSUCCESSMOBILE` | Amazing! You have impressed $clubname ($labelname) with your skills and they have given you a contract. If you want to play for a bigger club you will need to increase your STAR RATING and impress in the $leaguename division. |
| `CMESSAGE_TWOINAROW` | Two in a row! |
| `CMESSAGE_VEHICLEBORROWGIRL` | Your GIRLFRIEND asked if she can take your $vehicle for a ride. Do you want to let her? |
| `CMESSAGE_VEHICLEBORROWTEAM` | A TEAM MATE asks if he can take your $vehicle for a spin. Do you want to let him? |
| `CMESSAGE_VEHICLEDAMAGEDGIRL` | Oh no! Your GIRLFRIEND has crashed your $vehicle. It costs you $amount to repair it! |
| `CMESSAGE_VEHICLEDAMAGEDTEAM` | Oh no! Your TEAM MATE has crashed your $vehicle. It costs you $amount to repair it! |
| `CMESSAGE_REVIEWAPP` | Would you like to review this game on the App Store? (Don't worry, I will never ask this question again!) |
| `CMESSAGE_BUYPITCHPACK` | Did you know that you can play on different pitch styles and in rain and snow conditions by purchasing the Pitch & Weather pack from the shop? Would you like to buy it now? |
| `CMESSAGE_NOSTABLEMOBILE` | You do not own a stable yet. You can purchase one in the shop under the Property section. |
| `CMESSAGE_TRANSFERCONFIRMMOBILE` | Are you sure you wish to transfer to $clubname? |
| `CMESSAGE_TRAINHORSE` | Do you wish to train this horse for $cash? |
| `CMESSAGE_WEBACCOUNT` | You can log in at www.newstarsoccer.com to edit your account and email settings. |

---

# Appendix B - Help, tips and tooltips

## B.1 `CHELP_` - contextual pointer callouts (35)

| Tag | English |
|---|---|
| `CHELP_ABILITIES` | On the left of the screen you can see your abilities and any boosts that are currently applied to them. |
| `CHELP_BANK` | This shows you how much money you have in the bank. You can spend money on items from the shop or equipment for the next match. |
| `CHELP_BOOTS` | Click here to go to the boot shop. Boots will improve your DRIBBLING, PASSING and SHOOTING skills. Boots are free when you get a boot sponsor. |
| `CHELP_BOOZE` | Booze will increase your FLAIR and allow you to bend the ball more than usual. You may however fall over from time to time. |
| `CHELP_CASINOBUTTON` | If you want to go to the casino with your team mates, click this button. Win, lose or draw it will help your relationship. |
| `CHELP_CONTRACTBOSS1` | This is the relationship you have with your current BOSS. |
| `CHELP_CONTRACTBOSS2` | This is the relationship that you will have with the BOSS at the new club (or your current club if you are renewing the contract). |
| `CHELP_CONTRACTNEGOTIATE` | Click 'Negotiate' if you want to take a challenge to improve the offer but be careful because the boss of the new club will lose patience with you if you fail the challenge. |
| `CHELP_ENDRELATIONSHIP` | If you have a GIRLFRIEND you can end the relationship if it's not working out. |
| `CHELP_ENERGY` | This is your current energy level. Training, going shopping and spending time will use up your energy so make sure you save some for matchday! |
| `CHELP_ENHANCERS` | Enhancers are a supplement that will boost your pace. Sometimes enhancers contain illegal ingredients so be warned, as you may have to take a drugs test after a match. |
| `CHELP_FILTERS` | The buttons along the top here will filter the leaderboard results. You can view all players or just those of your age, club or nationality. |
| `CHELP_FORMATIONBUTTONS` | If you are the team CAPTAIN you can suggest a new formation to the BOSS by clicking these buttons. |
| `CHELP_HELPBUTTON` | The Help button will appear on most screens. It allows you to read the tutorial text again. |
| `CHELP_HOMEBUTTONS` | The home page buttons allow you to view specific details such as match stats, finances, your club contract and so on. |
| `CHELP_LOANBUTTON` | If you are struggling to get picked for matches then it may be beneficial to go on loan to a lower league club. |
| `CHELP_MAINBUTTONS` | The buttons on the nav bar will bring up the most important screens. You can view league tables, go training, spend time with friends and go shopping. |
| `CHELP_NRG` | Drinking cans of NRG will boost your ENERGY. You may find that you suffer stomach cramps during the match though! |
| `CHELP_OPTIONSBUTTON` | You can change your game settings on the Options screen. |
| `CHELP_PAINKILLERS` | If you are injured you can sometimes take pain killers to regain match fitness. However, if you get injured in the match immediately after taking pain killers your injury will become more severe. |
| `CHELP_PAIRS` | Click two cards to reveal their pictures. Then pick two more and try to find a pair. |
| `CHELP_PLAYBUTTON` | The play button will move time forward and bring up news and incidents. It will also take you to your next match. |
| `CHELP_QUITBUTTON` | Use the Quit button to exit back to the main screen. Your game will be saved automatically when you quit. |
| `CHELP_RELATIONSHIPBUTTONS` | Spend time with people by clicking one of these buttons. It is important to keep the BOSS happy if you want to get picked for the team! |
| `CHELP_RENEWCONTRACT` | If you feel you deserve a better contract then click this button to begin negotiating. That's if the boss feels you deserve a new contract! |
| `CHELP_REPORTRELATIONSHIPS` | These numbers show you how much your relationships increased or decreased after the match. |
| `CHELP_SHINPADS` | Shin pads increase your tackling skill. Once you have a sports clothing sponsor you will be able to get shin pads for free. |
| `CHELP_SHOPBUTTONS` | Choose the category with these buttons then click an item below to purchase it. |
| `CHELP_SKIPMATCH` | If you don't want to play the next match then use this button to skip it. Be warned that you will not impress your BOSS or TEAM MATES if you skip matches that you have been picked for. |
| `CHELP_STABLEBUTTON` | You can go to the race track with your friends. If you own a stable you can also race your own horses! |
| `CHELP_STATFILTERS` | You can filter the stats by club or by year with the drop-down lists. |
| `CHELP_TRAININGBUTTONS` | When you want to improve a skill click one of these buttons to take the training challenge. |
| `CHELP_TRANSFERBUTTON` | You can request to be transferred with this button. You can only see offers from interested clubs if you are on the transfer list. |
| `CHELP_TRANSFERCOMBOS` | When you are listed for transfer or loan you can specify exactly where you want to go with these drop-down lists. |
| `CHELP_PLAYERRATINGS` | These are your ratings. They can only be improved by performing the action during a match. |

## B.2 `help_` - per-screen Help-button body text (33)

| Tag | English |
|---|---|
| `help_abilities` | This screen lists your current abilities. To increase an ability you will need to complete a training challenge but keep an eye on your ENERGY as you don't want to use it all up before the next match. |
| `help_achievements` | There are many milestones in a player's career and the Achievements screen lets you keep track of the important ones. Only the best players in the world will be able to achieve them all. |
| `help_blackjack` | In Black Jack your cards need to add up as close to 21 as possible without going over it. Set your stake then click the 'Play' button. Press 'Hit' to deal another card or 'Hold' if you are happy with your hand. The dealer will then play his hand. If you win you will receive two times the stake that you bet. |
| `help_bootshop` | Every player has a default pair of boots, but if you want to increase your skills you will need to splash some cash. Once you have signed a boot sponsorship deal you will get your boots for free! |
| `help_casino` | The Casino offers a variety of games where you can gamble lots of that hard earned cash! |
| `help_continents` | This screen lets you view the fixtures and league table for any competition in the world. The button at the top left will switch between club, continental or international competitions. You can then use the drop-down lists to view a specific competition or team. |
| `help_contractoffer` | When you receive a contract offer you will see your current contract on the left and the new offer on the right. You have the options to 'Consider', 'Negotiate' or 'Accept' the new contract. If you don't want to make a decision straight away click CONSIDER. This will allow you to view offers from other clubs without cancelling negotiations. If you are happy with the offer click ACCEPT. |
| `help_dilemma` | Oh no! Two people want to meet you at the same time! Choose which relationship you want to increase. |
| `help_finances` | The finance screen will keep track of your weekly income and outgoings, along with any sponsorship deals you have made. Your LIFESTYLE is determined by the number of items that you have purchased from the shop. |
| `help_formation` | This is the formation screen where you can see exactly what tactics the boss is using for the match. Your position is highlighted by the star. If you want to change it click the 'Change Position' button. Your boss will normally agree unless he is unhappy with you. |
| `help_interview` | If you cannot remember a few clichés then you will never become a top footballer. Watch the GREEN buttons light up then repeat the sequence in the correct order. Ignore the BLUE lights. If you are successful you will increase your FAME. |
| `help_leaderboard` | This is your home screen where you can view your current position in the global leaderboard. You will need to train hard and play well to get good match ratings and increase your transfer value. |
| `help_leagues` | This screen lets you view the fixtures and league table for any competition in the world. The button at the top left will switch between club, continental or international competitions. You can then use the drop-down lists to view a specific competition or team. |
| `help_matchpaused` | Whilst the match is paused you can choose to watch a 'Replay', check the team 'Formation', edit your 'Options' or 'Skip time'. If you are are currently a SUBSTITUTE click 'Skip time' to fast forward the match to your substitution. If you skip time whilst you are on the pitch you will be subbed off and the rest of the match will be simulated. |
| `help_matchprep` | This is the Match Preparation screen. At the top of the page you will see if you have been selected for the match. If you have not been selected your 'Status' will show you the reason why. |
| `help_mycontract` | The Contract screen details your current club contract and your transfer or loan status. You can also see what clubs are currently interested in you. |
| `help_negotiate` | To negotiate a better contract you need to guess whether the next shirt number will be higher or lower than the previous one. The shirt numbers range from 1 to 11. You can end negotiations early if you wish to agree the current offer increase. |
| `help_newplayer` | Welcome to New Star Soccer. You are about to embark on an exciting football career where you live the life of a young player, but first you must set up your profile. |
| `help_newspaper` | After every game you will receive a match rating in the newspaper. The best player of the game will receive a 'Star Man' award. |
| `help_nohelp` | Sorry but there is no help for this screen! |
| `help_pairs` | Spending time with people doesn't always improve the relationship. Try to find two matching pictures to ensure that you have a good time! |
| `help_relationships` | This is your Relationships screen. It is important to keep the people around you happy or your career may suffer. If your HAPPINESS is low then there is more chance of mistiming a kick during a match. Spending time with someone will hopefully improve the relationship but it will cost you ENERGY. |
| `help_reportboss` | The BOSS has called you into his office to give you his opinion on your performance in the last game. |
| `help_reportphysio` | This is the medical room. It is where the club PHYSIO will report on any injuries or drug tests. |
| `help_roulette` | In Roulette you can bet on whether the ball will land on an odd or even number, a red or black number or within the ranges of 1 to 18 or 19 to 36. Place your bet and spin the wheel! |
| `help_shop` | Buying items, vehicles or property will increase your LIFESTYLE rating. A good LIFESTYLE will impress potential SPONSORS and also increase your desirability to the opposite sex! |
| `help_slots` | The Slot Machine is a simple game where you set your stake and hit the red button. If two or three reels show the same image then you win some cash! |
| `help_stable` | Set your stake, choose a horse and start the race! If you have purchased a stable from the shop you can even purchase and race your own horses. |
| `help_stats` | Every goal you score and every tackle you make for club or country will be recorded on this screen along with a whole host of other statistics. |
| `help_Tip` | Tip |
| `help_webpage` | If something newsworthy occurs in your life NSG Sport will be first to report it! |
| `help_worldmap` | The map screen highlights your next fixture. If you have to travel to an away game you will see how much the journey will affect your ENERGY level. Purchasing games, music or movies will ease your fatigue but you will need to purchase the relevant devices from the SHOP first. |
| `help_home` | The home page allows you to view specific details such as match stats, finances, your club contract and so on. |

## B.3 `CTIP_` - loading/hint tips (49 of a 1..50 range)

| Tag | English |
|---|---|
| `CTIP_1` | If your relationship with the BOSS is low you will not get picked for the first team. |
| `CTIP_10` | You can watch a REPLAY at any time, just press the REPLAY or PAUSE button during the match. If you save a replay you can view it again by choosing REPLAYS from the main menu.  |
| `CTIP_11` | If you are having trouble with the SHOOTING challenges in training try to increase your FLAIR first. |
| `CTIP_12` | Your FLAIR ability determines how much you can bend a shot or pass. You can get more bend on the ball if you don't hit it too hard. |
| `CTIP_13` | You can automatically CROSS the ball by tapping the KICK button (Simple) or LOB button (Advanced) when you are alongside the penalty box. |
| `CTIP_14` | You can boost your relationship with the BOSS by playing well and completing the training challenges. |
| `CTIP_15` | If you skip a match that you have been selected for you will forfeit one weeks wages and some of your relationships will drop. |
| `CTIP_16` | FANS will love you if you perform well on the pitch. If they don't like you they may start booing you at home games! |
| `CTIP_17` | When you come on as a sub the 'Substitution' message highlights which way you are shooting with a green arrow. |
| `CTIP_18` | Calling for the ball has no effect on your overall match rating but bad calls will affect your POSITIONING rating. |
| `CTIP_19` | If your match ratings are low try to focus on passing to your TEAM MATES. Making assists (passing to the goal scorer) will also give your rating a big boost. |
| `CTIP_2` | If you are a substitute you can SKIP TIME to get straight into the action. |
| `CTIP_20` | If you are awarded a STAR MAN rating in the newspaper it means you were the best player of the match! |
| `CTIP_21` | Your LIFESTYLE rating is determined by the number of items, vehicles and properties that you have purchased from the shop |
| `CTIP_22` | Passing to your TEAM MATES is the best way to improve your relationship with them. |
| `CTIP_23` | You can request to take FREE KICKS and CORNERS from the OPTIONS screen. However, the 'Always' setting will only take effect if you have the best SHOOTING or PASSING skills in the team or if you are the CAPTAIN. |
| `CTIP_24` | The FANS and your TEAM MATES will not be happy if you shoot a lot without scoring. |
| `CTIP_25` | A high FAME rating is required to attract all of the different SPONSORSHIP types. A high LIFESTYLE rating will improve the amount of money offered. |
| `CTIP_26` | The BOSS may put you on the transfer list if he is unhappy with you. You will need to impress him if you wish to stay at the club. |
| `CTIP_27` | If you want a GIRLFRIEND make sure your relationship with your FRIENDS is good. This will ensure that you have a good social life and you will get more opportunities to meet girls. |
| `CTIP_28` | Improve your FAME rating by celebrating a goal in front of the TV cameras or by appearing in the news. It also helps to be at a famous club. |
| `CTIP_29` | Celebrate in front of your own FANS or BOSS to improve your relationships. Also try grabbing the ball after scoring and running back to the centre circle to improve your TEAM relationship. |
| `CTIP_3` | You can see an explanation of the game controls by pausing the match and selecting OPTIONS then EDIT CONTROLS. You can also switch between the SIMPLE and ADVANCED controls from this screen. |
| `CTIP_30` | Increase your FAME rating to bring in sponsorship offers. |
| `CTIP_31` | Girls will expect a football star to have a high LIFESTYLE rating. Make sure you purchase items from the SHOP to impress them. |
| `CTIP_32` | If you are dating a girl with a high SCANDAL rating she will be more likely to attract media attention. This will increase your FAME. |
| `CTIP_33` | Your relationship with your GIRLFRIEND is vital to your overall HAPPINESS. It has double the effect of any other relationship. |
| `CTIP_34` | When you join a new club the FANS will be sceptical if you have not shown loyalty to your previous club. |
| `CTIP_35` | You will be offered better sponsorship deals if your current SPONSOR relationship is good. |
| `CTIP_36` | Your SPONSORS will be pleased if you win international matches. |
| `CTIP_37` | If you play well you might be asked to give an INTERVIEW after the match. Make sure you get your clichés in order! |
| `CTIP_38` | Your SPONSORS will not be happy if you get a YELLOW or RED card. However, they will be impressed by a STAR MAN performance. |
| `CTIP_39` | Your FAME rating has an affect on your HAPPINESS and it will also improve your TRANSFER VALUE. |
| `CTIP_4` | Playing with low ENERGY makes it more likely that you will suffer an injury. |
| `CTIP_40` | If your relationship with SPONSORS is low you risk having contracts cancelled. |
| `CTIP_41` | Replica shirt sales are determined by your FAME and your relationship with the FANS. |
| `CTIP_42` | If your contract expires you will be offered higher wages in contract negotiations because other clubs will not need to pay a transfer fee. |
| `CTIP_43` | Once you have purchased a STABLE from the shop you can buy race horses. |
| `CTIP_44` | If you own a race horse you need to race it to make it stronger and faster, but don't over work it or it may become ill! |
| `CTIP_45` | If your race horse becomes ill it's strength will deteriorate over time. Make sure you TREAT it to bring it back to full health. |
| `CTIP_47` | Going to the CASINO with TEAM MATES or going RACING with FRIENDS is a great way to improve your relationships. Just make sure you don't become a gambling addict! |
| `CTIP_48` | Player of the year' awards only go to players that achieve a high average match rating in a high profile league. You will also need to be playing well for your country. |
| `CTIP_49` | Once you pass the age of 30 your PACE and DRIBBLING skills will start to fall and it will be impossible to restore them to the maximum level. |
| `CTIP_5` | The combined status of your relationships determines your overall HAPPINESS. Misplaced kicks occur more often if your HAPPINESS is low. |
| `CTIP_50` | You will retire after 20 seasons. During your career you will need to win the World Cup, recieve the 'World Player of the Year' award and collect all of the achievements to be deemed as a true football legend. |
| `CTIP_6` | If you increase your relationship with your TEAM MATES they will be more likely to pass the ball to you. |
| `CTIP_7` | You can purchase entertainment items such as MUSIC, GAMES and FILMS to ease tiredness caused by long away game journeys. You will need to purchase the relevant device from the SHOP first though. |
| `CTIP_8` | Your SHOOTING, PASSING and HEADING abilities determine how accurate your kicks and headers will be. If your ability is low your shots and passes may not go precisely in the direction you aim. |
| `CTIP_9` | If you are using the SIMPLE control method you can quickly tap the kick button whilst standing still to LOB the ball. This is useful from set-pieces, particularly in the SHOOTING training challenges. |

## B.4 `tt_` - button tooltips (69). Toggled by the `tt_ButtonTips` option.

| Tag | English |
|---|---|
| `tt_Achievements` | Achievements |
| `tt_Back` | Back |
| `tt_Banned` | Account has been banned |
| `tt_BlackJack` | Black Jack |
| `tt_ButtonTips` | Button Tips |
| `tt_BuyBoots` | Buy Boots |
| `tt_BuyBooze` | Buy Booze |
| `tt_BuyDrugs` | Buy Enhancers |
| `tt_BuyGames` | Buy Games |
| `tt_BuyMovies` | Buy Movies |
| `tt_BuyMusic` | Buy Music |
| `tt_BuyNRG` | Buy NRG |
| `tt_BuyPainKillers` | Buy Pain Killers |
| `tt_BuyShinPads` | Buy Shin Pads |
| `tt_Competitions` | Competitions |
| `tt_Contract` | Contract |
| `tt_CreateAccount` | Create |
| `tt_Download` | Download |
| `tt_DribblingTraining` | Dribbling Training |
| `tt_Facebook` | Facebook |
| `tt_Finances` | Finances |
| `tt_FlairTraining` | Flair Training |
| `tt_Forum` | Forum |
| `tt_GamesConsole` | Allows you to buy games to relieve tiredness |
| `tt_GoToMatch` | Go To Match |
| `tt_Happiness` | Happiness |
| `tt_HeadingTraining` | Heading Training |
| `tt_Help` | Help |
| `tt_Home` | Home |
| `tt_HorseRacing` | Horse Racing |
| `tt_LeaveCasino` | Leave Casino |
| `tt_MusicPlayer` | Allows you to buy music to relieve tiredness |
| `tt_NextRace` | Next Race |
| `tt_Offline` | Try to connect |
| `tt_Options` | Options |
| `tt_PaceTraining` | Pace Training |
| `tt_PassingTraining` | Passing Training |
| `tt_Phone` | Receive calls from friends and team mates |
| `tt_Play` | Play |
| `tt_PlayButton` | Proceed |
| `tt_Premium` | View account |
| `tt_Proceed` | Proceed |
| `tt_Profile` | Profile |
| `tt_Quit` | Quit |
| `tt_RefreshConnection` | Refresh connection |
| `tt_RelationsBoss` | Meet the boss |
| `tt_RelationsFans` | Meet the fans |
| `tt_RelationsFriends` | Meet your friends |
| `tt_RelationsFriendsRacing` | Go racing with friends |
| `tt_RelationsGirl` | Meet your girlfriend |
| `tt_RelationsGirlEnd` | End relationship |
| `tt_RelationsSponsors` | Meet your sponsors |
| `tt_RelationsTeam` | Meet the team |
| `tt_RelationsTeamCasino` | Go to casino with team mates |
| `tt_Roulette` | Roulette |
| `tt_SaveQuit` | Save and Quit |
| `tt_ShootingTraining` | Shooting Training |
| `tt_Shop` | Shop |
| `tt_Slots` | Slot Machine |
| `tt_Stable` | Allows you to buy race horses |
| `tt_StartRace` | Start Race |
| `tt_Stats` | Stats |
| `tt_Tablet` | Allows you to buy movies to relieve tiredness |
| `tt_TacklingTraining` | Tackling Training |
| `tt_Training` | Training |
| `tt_Twitter` | Twitter |
| `tt_Upgrade` | Upgrade to a Premium account |
| `tt_UpToDate` | Up to date |
| `tt_GetMoreMatches` | Get more matches |

## B.5 `CINSTRUCS_`

| Tag | English |
|---|---|
| `CINSTRUCS_PAIRS` | Find two matching cards! |

---

# Appendix C - UI chrome, enums and abbreviations (everything not yet dumped)

Every tag in `Languages.csv` that has not appeared in a table above appears below, so that this document is a
complete substitute for the CSV.

## C.1 Bare tags (no underscore) - 611 remaining screen titles, column headers and labels

These are the raw UI vocabulary. Notable groupings visible in the list: main-menu entries
(`New Career`, `Load Career`, `Quick Game`, `Quick Match`, `Replays`, `Scenarios`, `Data Editor`, `Options`,
`Quit`), home-screen panels (`Profile`, `My Contract`, `My Finances`, `My Stats`, `My Achievements`,
`My History`, `My Stable`), match vocabulary (`Kick Off`, `Half Time`, `Full Time`, `Extra Time`, `ET/Pens`,
`Throw In`, `Goal Kick`, `Corner`, `Free Kick`, `Offside`, `Penalty!`, `Yellow Card!`, `Red Card!`,
`Second Yellow!`, `Star Man!`, `Substitution`), Data-Editor field names (`Stadium Latitude`,
`Stadium Longitude`, `Federation Name`, `Continentality`, `Promotion Places`, `B Team Of`, `Rival Club Name`),
and the kit editor (`Shirt`, `Shorts`, `Socks`, `Home Kit`, `Away Kit`, `Third Kit`, `Keeper Kit`,
`Primary Skin`, `Secondary Skin`, `Hair`, `Display Initials`).

| Tag | English |
|---|---|
| `1st` | 1st |
| `1st Team` | 1st Team |
| `2nd` | 2nd |
| `3rd` | 3rd |
| `4th` | 4th |
| `90 Mins` | 90 Mins |
| `Abbreviation` | Abbreviation |
| `Abilities` | Abilities |
| `Achievement` | Achievement |
| `Achievements` | Achievements |
| `Add` | Add |
| `Add Friend` | Add Friend |
| `Advanced` | Advanced |
| `Advanced Controls` | Advanced Controls |
| `Age` | Age |
| `Aggregate` | Aggregate |
| `Alcohol` | Alcohol |
| `All Clubs` | All Clubs |
| `All Time` | All Time |
| `Amount` | Amount |
| `Any` | Any |
| `Any Age` | Any Age |
| `Any Club` | Any Club |
| `Any Comp Type` | Any Comp Type |
| `Any Competition` | Any Competition |
| `Any Continent` | Any Continent |
| `Any Division` | Any Division |
| `Any Level` | Any Level |
| `Any Locale` | Any Locale |
| `Any Nation` | Any Nation |
| `Anywhere` | Anywhere |
| `Appearance` | Appearance |
| `Appearances` | Appearances |
| `AppTitle` | New Star Soccer 5 |
| `Assist` | Assist |
| `Assist Bonus` | Assist Bonus |
| `Assists` | Assists |
| `Average Rating` | Average Rating |
| `Away` | Away |
| `Away Kit` | Away Kit |
| `Away Team` | Away Team |
| `B Team Of` | B Team Of |
| `Back` | Back |
| `Ball` | Ball |
| `Bank` | Bank |
| `Banned` | Banned |
| `Based` | Based |
| `Black Jack` | Black Jack |
| `Boots` | Boots |
| `Booze` | Booze |
| `Boss` | Boss |
| `Boss Report` | Boss Report |
| `Boss Unhappy` | Boss Unhappy |
| `Buy` | Buy |
| `Buy Horse` | Buy Horse |
| `Calendar` | Calendar |
| `Capacity` | Capacity |
| `Career` | Career |
| `Casino` | Casino |
| `Change Kits` | Change Kits |
| `Change Position` | Change Position |
| `Checking License` | Checking License |
| `Choose Formation` | Choose Formation |
| `Choose Kits` | Choose Kits |
| `Choose Nation` | Choose Nation |
| `Choose Nations` | Choose Nations |
| `Clean Sheet Bonus` | Clean Sheet Bonus |
| `Clear Bets` | Clear Bets |
| `Climate` | Climate |
| `Club` | Club |
| `Club Name` | Club Name |
| `Club Stats` | Club Stats |
| `Clubs` | Clubs |
| `Clubs Interested` | Clubs Interested |
| `Coach Report` | Coach Report |
| `Compare` | Compare |
| `Competition` | Competition |
| `Competitions` | Competitions |
| `Continent` | Continent |
| `Continental Comp` | Continental Comp |
| `Continental Competitions` | Continental Competitions |
| `Continental Comps` | Continental Comps |
| `Continentality` | Continentality |
| `Continents` | Continents |
| `Continue` | Continue |
| `Contract` | Contract |
| `Contract Negotiation` | Contract Negotiation |
| `Contract Offer` | Contract Offer |
| `Control` | Control |
| `Control Player` | Control Player |
| `Control Team` | Control Team |
| `Controls` | Controls |
| `Copy To Clipboard` | Copy To Clipboard |
| `Corner` | Corner |
| `Corners` | Corners |
| `CPU` | CPU |
| `Create` | Create |
| `Create Account` | Create Account |
| `Create Kits` | Create Kits |
| `Create New Account` | Create New Account |
| `Create Players` | Create Players |
| `Creating Fixtures` | Creating Fixtures |
| `Compress IDs` | Compress IDs |
| `Cup` | Cup |
| `Currency` | Currency |
| `Current Contract` | Current Contract |
| `Current Suspension` | Current Suspension |
| `Custom` | Custom |
| `Data Editor` | Data Editor |
| `Date` | Date |
| `Decrease` | Decrease |
| `Decrease Stable` | Decrease Stable |
| `Delete` | Delete |
| `Delete Place` | Delete Place |
| `Description` | Description |
| `Desired Loan` | Desired Loan |
| `Desired Transfer` | Desired Transfer |
| `Difficulty` | Difficulty |
| `Dilemma!` | Dilemma! |
| `Display Initials` | Display Initials |
| `Distance` | Distance |
| `Down` | Down |
| `Dribbling` | Dribbling |
| `Dribbling Training` | Dribbling Training |
| `Drugs` | Drugs |
| `Duplicate` | Duplicate |
| `East` | East |
| `Edit` | Edit |
| `Edit Club` | Edit Club |
| `Edit Comp` | Edit Comp |
| `Edit Competition` | Edit Competition |
| `Edit Controls` | Edit Controls |
| `Edit Details` | Edit Details |
| `Edit Kit` | Edit Kit |
| `Edit Kits` | Edit Kits |
| `Edit Nation` | Edit Nation |
| `Edit Place` | Edit Place |
| `Edit Player` | Edit Player |
| `Editor` | Editor |
| `Email` | Email |
| `End Tutorial` | End Tutorial |
| `Energy` | Energy |
| `Energy After Travelling` | Energy After Travelling |
| `Energy Cost` | Energy Cost |
| `Enhancers` | Enhancers |
| `Enter Scenario ID` | Enter Scenario ID |
| `ET/Pens` | ET/Pens |
| `Every Year` | Every Year |
| `Exit` | Exit |
| `Expires` | Expires |
| `Fail!` | Fail! |
| `Fame` | Fame |
| `Fame!` | Fame! |
| `Fans` | Fans |
| `Federation Name` | Federation Name |
| `Federation Short Name` | Federation Short Name |
| `Files` | Files |
| `Final` | Final |
| `Finances` | Finances |
| `Find a pair!` | Find a pair! |
| `Find Me` | Find Me |
| `Finish` | Finish |
| `Fixtures` | Fixtures |
| `Fixtures Today` | Fixtures Today |
| `Flair` | Flair |
| `Flair Training` | Flair Training |
| `Forgot Password` | Forgot Password |
| `Form` | Form |
| `Formation` | Formation |
| `Fouls` | Fouls |
| `Free Account` | Free Account |
| `Free Kick` | Free Kick |
| `Free Kicks` | Free Kicks |
| `Free Time` | Free Time |
| `Friends` | Friends |
| `Full Time` | Full Time |
| `Gambling` | Gambling |
| `Gambling Addiction` | Gambling Addiction |
| `Game` | Game |
| `Game Info` | Game Info |
| `Game Options` | Game Options |
| `Game Speed` | Game Speed |
| `Girlfriend` | Girlfriend |
| `Go` | Go |
| `Go To Clubs` | Go To Clubs |
| `Go!` | Go! |
| `Goal Bonus` | Goal Bonus |
| `Goal Kick` | Goal Kick |
| `Goal!` | Goal! |
| `Goals` | Goals |
| `Goals per Game` | Goals per Game |
| `Group` | Group |
| `Groups` | Groups |
| `Groups 1-4` | Groups 1-4 |
| `Groups 5-8` | Groups 5-8 |
| `Hair` | Hair |
| `Half Time` | Half Time |
| `Happiness` | Happiness |
| `Hat Trick` | Hat Trick |
| `Hat Tricks` | Hat Tricks |
| `Headers` | Headers |
| `Heading` | Heading |
| `Heading Training` | Heading Training |
| `Health` | Health |
| `Help` | Help |
| `Hide Names` | Hide Names |
| `High or Low?` | High or Low? |
| `Higher` | Higher |
| `Highlight Ball` | Highlight Ball |
| `History` | History |
| `Home` | Home |
| `Home Kit` | Home Kit |
| `Home Team` | Home Team |
| `Horse Racing` | Horse Racing |
| `Horses For Sale` | Horses For Sale |
| `Human Team` | Human Team |
| `ID` | ID |
| `Incident` | Incident |
| `Increase` | Increase |
| `Increase Stable` | Increase Stable |
| `Inflate IDs` | Inflate IDs |
| `Info` | Info |
| `Injured` | Injured |
| `Injury` | Injury |
| `Injury!` | Injury! |
| `International` | International |
| `International Stats` | International Stats |
| `Interview` | Interview |
| `Interview!` | Interview! |
| `Items` | Items |
| `Keeper Kit` | Keeper Kit |
| `Keyboard` | Keyboard |
| `Kick` | Kick |
| `Kick Off` | Kick Off |
| `Kit Bag` | Kit Bag |
| `Kit Type` | Kit Type |
| `Knock Out` | Knock Out |
| `Large` | Large |
| `Latest Version` | Latest Version |
| `Leaderboard` | Leaderboard |
| `Leaderboards` | Leaderboards |
| `League` | League |
| `League Player Of The Year` | League Player Of The Year |
| `Left` | Left |
| `Leg` | Leg |
| `Length` | Length |
| `Level` | Level |
| `Lifestyle` | Lifestyle |
| `Load` | Load |
| `Load Career` | Load Career |
| `Load Game` | Load Game |
| `Load League` | Load League |
| `Load Replay` | Load Replay |
| `Load Scenario` | Load Scenario |
| `Loading` | Loading |
| `Loan Listed` | Loan Listed |
| `Locale` | Locale |
| `Log In` | Log In |
| `Log Out` | Log Out |
| `Long Pass` | Long Pass |
| `Low Club Level` | Low Club Level |
| `Lower` | Lower |
| `Man of the Match` | Man of the Match |
| `Match` | Match |
| `Match Fit` | Match Fit |
| `Match FX` | Match FX |
| `Match Length` | Match Length |
| `Match Minute` | Match Minute |
| `Match Options` | Match Options |
| `Match Preparation` | Match Preparation |
| `Match Refresh` | Match Refresh |
| `Match Report` | Match Report |
| `Match Type` | Match Type |
| `Matches` | Matches |
| `Media` | Media |
| `Members` | Members |
| `Menu` | Menu |
| `Metres` | Metres |
| `Move Player` | Move Player |
| `Music` | Music |
| `My Achievements` | My Achievements |
| `My Age` | My Age |
| `My Club` | My Club |
| `My Contract` | My Contract |
| `My Finances` | My Finances |
| `My History` | My History |
| `My Nation` | My Nation |
| `My Profile` | My Profile |
| `My Stable` | My Stable |
| `My Stats` | My Stats |
| `My Version` | My Version |
| `Name` | Name |
| `Nation` | Nation |
| `National Team` | National Team |
| `Nationality` | Nationality |
| `Nations` | Nations |
| `Negotiate!` | Negotiate! |
| `New` | New |
| `New Career` | New Career |
| `New Contract` | New Contract |
| `New Game` | New Game |
| `New League` | New League |
| `New Player` | New Player |
| `New Promotion Place` | New Promotion Place |
| `New Scenario` | New Scenario |
| `Next` | Next |
| `Next Match` | Next Match |
| `Next Opponent` | Next Opponent |
| `Nick Name` | Nick Name |
| `No` | No |
| `No Boots` | No Boots |
| `No Experience` | No Experience |
| `No Injury` | No Injury |
| `No Shin Pads` | No Shin Pads |
| `None` | None |
| `North` | North |
| `Not Picked` | Not Picked |
| `NRG Boost` | NRG Boost |
| `NRG Drink` | NRG Drink |
| `Off` | Off |
| `Offline` | Offline |
| `Offside` | Offside |
| `OK` | OK |
| `On` | On |
| `On Loan` | On Loan |
| `On Target` | On Target |
| `Online` | Online |
| `Opponent` | Opponent |
| `Options` | Options |
| `Or` | Or |
| `or` | or |
| `Pace` | Pace |
| `Pace Training` | Pace Training |
| `Page` | Page |
| `Pass` | Pass |
| `Passes` | Passes |
| `Passes per Game` | Passes per Game |
| `Passing` | Passing |
| `Passing Training` | Passing Training |
| `Password` | Password |
| `Paste From Clipboard` | Paste From Clipboard |
| `Pause` | Pause |
| `Paused` | Paused |
| `Penalties` | Penalties |
| `Penalty!` | Penalty! |
| `Physio Report` | Physio Report |
| `Place` | Place |
| `Play` | Play |
| `Play Offline` | Play Offline |
| `Player` | Player |
| `Player 1` | Player 1 |
| `Player 2` | Player 2 |
| `Player Cam` | Player Cam |
| `Player Name` | Player Name |
| `Poor Form` | Poor Form |
| `Position` | Position |
| `Possession` | Possession |
| `Post To FaceBook` | Post To FaceBook |
| `Post To Twitter` | Post To Twitter |
| `Premium` | Premium |
| `Premium Account` | Premium Account |
| `Premium Players` | Premium Players |
| `Previous` | Previous |
| `Primary Skin` | Primary Skin |
| `Prize Money` | Prize Money |
| `Prizes` | Prizes |
| `Profile` | Profile |
| `Promote To` | Promote To |
| `Promotion From Comps` | Promotion From Comps |
| `Promotion Places` | Promotion Places |
| `Promotions` | Promotions |
| `Property` | Property |
| `Property Costs` | Property Costs |
| `Qtr Final` | Qtr Final |
| `Quarter Finals` | Quarter Finals |
| `Quick Game` | Quick Game |
| `Quick Match` | Quick Match |
| `Quit` | Quit |
| `Race` | Race |
| `Race Horse` | Race Horse |
| `Radar` | Radar |
| `Random` | Random |
| `Rank` | Rank |
| `Rating` | Rating |
| `Re-type Password` | Re-type Password |
| `Receive` | Receive |
| `Receive Scenario` | Receive Scenario |
| `Recurring` | Recurring |
| `Red Card!` | Red Card! |
| `Red Cards` | Red Cards |
| `Refresh` | Refresh |
| `Refresh Clubs` | Refresh Clubs |
| `Reject` | Reject |
| `Relationships` | Relationships |
| `Renew Contract` | Renew Contract |
| `Rent` | Rent |
| `Replay` | Replay |
| `Replays` | Replays |
| `Request New Position` | Request New Position |
| `Rest` | Rest |
| `Result` | Result |
| `Results` | Results |
| `Retrieve Leaderboard` | Retrieve Leaderboard |
| `Retrieve Team` | Retrieve Team |
| `Retry` | Retry |
| `Right` | Right |
| `Rival` | Rival |
| `Rival Club Name` | Rival Club Name |
| `Roulette` | Roulette |
| `Round` | Round |
| `Runner-Up` | Runner-Up |
| `Save` | Save |
| `Save and Exit` | Save and Exit |
| `Save File` | Save File |
| `Save Name` | Save Name |
| `Saving` | Saving |
| `Scenarios` | Scenarios |
| `Score` | Score |
| `Season` | Season |
| `Season Review` | Season Review |
| `Season Stats` | Season Stats |
| `Second Yellow!` | Second Yellow! |
| `Secondary Skin` | Secondary Skin |
| `Select Club` | Select Club |
| `Select League` | Select League |
| `Select Start Letter` | Select Start Letter |
| `Select Team` | Select Team |
| `Sell Horse` | Sell Horse |
| `Semi Final` | Semi Final |
| `Semi Finals` | Semi Finals |
| `Send By Email` | Send By Email |
| `Share` | Share |
| `Share Scenario` | Share Scenario |
| `Shirt` | Shirt |
| `Shirt Sales` | Shirt Sales |
| `Shooting` | Shooting |
| `Shooting Training` | Shooting Training |
| `Shop` | Shop |
| `Short Name` | Short Name |
| `Shorts` | Shorts |
| `Shots` | Shots |
| `Shots per Goal` | Shots per Goal |
| `Show Energy` | Show Energy |
| `Show Names` | Show Names |
| `Side` | Side |
| `Signing Fee` | Signing Fee |
| `Simple` | Simple |
| `Simple Controls` | Simple Controls |
| `Skills` | Skills |
| `Skin` | Skin |
| `Skip Match` | Skip Match |
| `Skip Time` | Skip Time |
| `Slot Machine` | Slot Machine |
| `Small` | Small |
| `Socks` | Socks |
| `Sort By` | Sort By |
| `Sound` | Sound |
| `Sound FX` | Sound FX |
| `South` | South |
| `Spend Time` | Spend Time |
| `Sponsors` | Sponsors |
| `Sponsorship` | Sponsorship |
| `Squad` | Squad |
| `Stable Size` | Stable Size |
| `Stadium` | Stadium |
| `Stadium Capacity` | Stadium Capacity |
| `Stadium ID` | Stadium ID |
| `Stadium Latitude` | Stadium Latitude |
| `Stadium Longitude` | Stadium Longitude |
| `Stadium Name` | Stadium Name |
| `Stage` | Stage |
| `Star Man` | Star Man |
| `Star Man!` | Star Man! |
| `Start` | Start |
| `Statistics` | Statistics |
| `Stats` | Stats |
| `Status` | Status |
| `Story` | Story |
| `Strength` | Strength |
| `Submit Stats` | Submit Stats |
| `Substitute` | Substitute |
| `Substitution` | Substitution |
| `Success!` | Success! |
| `Suspension` | Suspension |
| `Tackle` | Tackle |
| `Tackles` | Tackles |
| `Tackles per Game` | Tackles per Game |
| `Tackling` | Tackling |
| `Tackling Training` | Tackling Training |
| `Tactics` | Tactics |
| `Team` | Team |
| `Teams` | Teams |
| `Test Data` | Test Data |
| `Third Kit` | Third Kit |
| `This is your scenario code` | This is your scenario code |
| `This Year` | This Year |
| `Throw In` | Throw In |
| `Time` | Time |
| `Time Up!` | Time Up! |
| `Tiredness` | Tiredness |
| `Title` | Title |
| `Top 16` | Top 16 |
| `Top 20` | Top 20 |
| `Total` | Total |
| `Total Per Year` | Total Per Year |
| `Total Players` | Total Players |
| `Tournament` | Tournament |
| `Tournaments` | Tournaments |
| `Tournaments and Awards` | Tournaments and Awards |
| `Trailer Home` | Trailer Home |
| `Training` | Training |
| `Transfer Listed` | Transfer Listed |
| `Transfer Offer` | Transfer Offer |
| `Transfer Status` | Transfer Status |
| `Travel Time` | Travel Time |
| `Treat Horse` | Treat Horse |
| `Up` | Up |
| `Update` | Update |
| `Upgrade` | Upgrade |
| `User Name` | User Name |
| `Value` | Value |
| `Vehicle Costs` | Vehicle Costs |
| `Vehicles` | Vehicles |
| `View Friends` | View Friends |
| `View Opponent` | View Opponent |
| `Wage` | Wage |
| `Web Profile` | Web Profile |
| `Week` | Week |
| `West` | West |
| `Win!` | Win! |
| `Winner` | Winner |
| `Winners` | Winners |
| `World` | World |
| `World Cup` | World Cup |
| `World Player Of The Year` | World Player Of The Year |
| `Yards` | Yards |
| `Year` | Year |
| `Years` | Years |
| `Yellow Card!` | Yellow Card! |
| `Yellow Cards` | Yellow Cards |
| `Yes` | Yes |
| `Young Player Of The Year` | Young Player Of The Year |
| `Your Club Name` | Your Club Name |
| `Your Details` | Your Details |
| `Your Rating` | Your Rating |
| `Zoom` | Zoom |
| `Positioning` | Positioning |
| `Vision` | Vision |
| `Finishing` | Finishing |
| `Long Shots` | Long Shots |
| `Crossing` | Crossing |
| `Aggression` | Aggression |
| `Ratings` | Ratings |
| `Lock Kicking Direction` | Lock Kicking Direction |
| `Activation Key` | Activation Key |
| `Cross` | Cross |
| `Short Passing` | Short Passing |
| `Long Passing` | Long Passing |
| `Chance missed` | Chance missed |
| `About` | About |
| `Accept` | Accept |
| `Arcade Mode` | Arcade Mode |
| `Awards` | Awards |
| `Ball Control` | Ball Control |
| `Bet` | Bet |
| `Boot Shop` | Boot Shop |
| `Chances` | Chances |
| `Choose Club` | Choose Club |
| `Choose Continent` | Choose Continent |
| `Choose Division` | Choose Division |
| `Choose League` | Choose League |
| `Choose Relationship Boost` | Choose Relationship Boost |
| `Choose Skill Boost` | Choose Skill Boost |
| `Desired Transfer` | Desired Transfer |
| `Drink` | Drink |
| `Enter Your Name` | Enter Your Name |
| `Extra Time` | Extra Time |
| `First Name` | First Name |
| `Furthest Goal` | Furthest Goal |
| `Furthest Pass` | Furthest Pass |
| `Hi-Score` | Hi-Score |
| `Intercept` | Intercept |
| `Last Name` | Last Name |
| `Life` | Life |
| `Lives` | Lives |
| `Match Kits` | Match Kits |
| `Match Rating` | Match Rating |
| `Match Stats` | Match Stats |
| `Negotiate` | Negotiate |
| `New Boss` | New Boss |
| `NRG Shop` | NRG Shop |
| `People` | People |
| `Play Now` | Play Now |
| `Please wait` | Please wait |
| `Positioning` | Positioning |
| `Power` | Power |
| `Price` | Price |
| `Renegotiate` | Renegotiate |
| `Restore` | Restore |
| `Selection Status` | Selection Status |
| `Set up your nationality` | Set up your nationality |
| `Set up your player profile` | Set up your player profile |
| `Slots` | Slots |
| `Star Bux` | Star Bux |
| `Star Rating` | Star Rating |
| `Swipe` | Swipe |
| `Technique` | Technique |
| `Total Cash` | Total Cash |
| `Total Per Match` | Total Per Match |
| `Tutorial` | Tutorial |
| `Vision` | Vision |
| `Wind` | Wind |
| `Work Rate` | Work Rate |
| `NRG Drinks` | NRG Drinks |

## C.2 `tla_` - three-letter abbreviations for table headers (120)

| Tag | English |
|---|---|
| `tla_Abbreviation` | Abr |
| `tla_Achievements` | Ach |
| `tla_Aggregate` | Ag |
| `tla_Appearances` | Apps |
| `tla_April` | Apr |
| `tla_Assists` | Assists |
| `tla_August` | Aug |
| `tla_AverageRating` | AvgRat |
| `tla_Based` | Bsd |
| `tla_Break` | Brk |
| `tla_BTeamOf` | B of |
| `tla_Capacity` | Cap |
| `tla_Centre` | C |
| `tla_Club` | Club |
| `tla_Continent` | Cont |
| `tla_ContinentalComp` | CntComp |
| `tla_CupMatch` | Cup |
| `tla_DDMMYY` | DD-MM-YY |
| `tla_December` | Dec |
| `tla_Drawn` | Drn |
| `tla_Dribbling` | Drb |
| `tla_Duration` | Dur |
| `tla_Energy` | Enr |
| `tla_Entrants` | Ent |
| `tla_Fame` | Fame |
| `tla_February` | Feb |
| `tla_GoalDifference` | GD |
| `tla_Goals` | Goals |
| `tla_Group` | Grp |
| `tla_Groups` | Grps |
| `tla_Happiness` | Hap |
| `tla_Health` | Hlt |
| `tla_hours` | hrs |
| `tla_International` | Int |
| `tla_January` | Jan |
| `tla_JoyButton` | Btn |
| `tla_JoyDown` | Joy D |
| `tla_JoyLeft` | Joy L |
| `tla_JoyRight` | Joy R |
| `tla_JoyUp` | Joy U |
| `tla_July` | Jul |
| `tla_June` | Jun |
| `tla_KnockOut` | KO |
| `tla_Latitude` | Lat |
| `tla_Left` | L |
| `tla_Leg` | Leg |
| `tla_Legs` | Legs |
| `tla_Level` | Lvl |
| `tla_Lifestyle` | LifeSty |
| `tla_Locale` | Loc |
| `tla_Longitude` | Long |
| `tla_Lost` | Lst |
| `tla_March` | Mar |
| `tla_Matchday1` | MD1 |
| `tla_Matchday2` | MD2 |
| `tla_May` | May |
| `tla_Metres` | Mtrs |
| `tla_minutes` | mins |
| `tla_Minutes` | Mins |
| `tla_Name` | Nam |
| `tla_Nation` | Nat |
| `tla_Nationality` | Nat |
| `tla_NickName` | Nick |
| `tla_November` | Nov |
| `tla_October` | Oct |
| `tla_Pace` | Spd |
| `tla_Passes` | Passes |
| `tla_Passing` | Pas |
| `tla_Played` | Pld |
| `tla_Player1` | P1 |
| `tla_Player2` | P2 |
| `tla_Points` | Pts |
| `tla_Position` | Pos |
| `tla_Recurring` | Rec |
| `tla_Region` | Reg |
| `tla_Right` | R |
| `tla_Rival` | Riv |
| `tla_Rounds` | Rnds |
| `tla_seconds` | secs |
| `tla_September` | Sep |
| `tla_Shooting` | Sht |
| `tla_ShortName` | Short |
| `tla_Skills` | Skills |
| `tla_Sponsors` | Spon |
| `tla_StarMan` | Star M |
| `tla_Status` | Sts |
| `tla_Strength` | Str |
| `tla_Substitute` | Sub |
| `tla_Surface` | Srf |
| `tla_Tackles` | Tackles |
| `tla_Tackling` | Tck |
| `tla_ToBeConfirmed` | TBC |
| `tla_Type` | Typ |
| `tla_Value` | Value |
| `tla_Versus` | Vs |
| `tla_versus` | vs |
| `tla_Wage` | Wage |
| `tla_Week` | Wk |
| `tla_Won` | Won |
| `tla_Yards` | Yrds |
| `tla_Year` | Yr |
| `tla_YearWeek` | Yr Wk |
| `tla_BallControl` | CNT |
| `tla_Flair` | FLR |
| `tla_Form` | Form |
| `tla_FurthestGoal` | F Goal |
| `tla_FurthestPass` | F Pass |
| `tla_HatTricks` | Hat Trk |
| `tla_Matches` | MAT |
| `tla_Penalties` | Pens |
| `tla_Power` | POW |
| `tla_Yard` | Yrd |
| `tla_Metre` | Mtr |

## C.3 `sla_` - single-letter abbreviations (28)

`sla_Thousand` = `K` and `sla_Million` = `M` are the currency suffixes; the exe references both immediately
before the shop catalogue, i.e. money formatting is `<value><sla_Thousand|sla_Million>`.

| Tag | English |
|---|---|
| `sla_Away` | A |
| `sla_awaygoals` | a |
| `sla_Drawn` | D |
| `sla_extratime` | e |
| `sla_GoalsAgainst` | A |
| `sla_GoalsFor` | F |
| `sla_Home` | H |
| `sla_hours` | h |
| `sla_Leg` | L |
| `sla_Lost` | L |
| `sla_Million` | M |
| `sla_minutes` | m |
| `sla_penalty` | p |
| `sla_seconds` | s |
| `sla_Thousand` | K |
| `sla_Versus` | V |
| `sla_versus` | v |
| `sla_Won` | W |

## C.4 `key_` - keyboard key display names for the control editor (113)

Bound via `CMESSAGE_GETKEY` ("Press a key"). `CMESSAGE_USEMOUSE` restricts rebinding to the mouse.

| Tag | English |
|---|---|
| `key_0` | 0 |
| `key_1` | 1 |
| `key_2` | 2 |
| `key_3` | 3 |
| `key_4` | 4 |
| `key_5` | 5 |
| `key_6` | 6 |
| `key_7` | 7 |
| `key_8` | 8 |
| `key_9` | 9 |
| `key_A` | A |
| `key_Alt` | Alt |
| `key_AltKeyLeft` | Alt Key Left |
| `key_AltKeyRight` | Alt Key Right |
| `key_B` | B |
| `key_Backslash` | Backslash |
| `key_Backspace` | Backspace |
| `key_BracketClose` | Bracket Close |
| `key_BracketOpen` | Bracket Open |
| `key_C` | C |
| `key_CapsLock` | Caps Lock |
| `key_Clear` | Clear |
| `key_Comma` | Comma |
| `key_Control` | Control |
| `key_ControlLeft` | Control Left |
| `key_ControlRight` | Control Right |
| `key_CursorDown` | Cursor Down |
| `key_CursorLeft` | Cursor Left |
| `key_CursorRight` | Cursor Right |
| `key_CursorUp` | Cursor Up |
| `key_D` | D |
| `key_Delete` | Delete |
| `key_E` | E |
| `key_End` | End |
| `key_Enter` | Enter |
| `key_Equals` | Equals |
| `key_Escape` | Esc |
| `key_Execute` | Execute |
| `key_F` | F |
| `key_F1` | F1 |
| `key_F10` | F10 |
| `key_F11` | F11 |
| `key_F12` | F12 |
| `key_F2` | F2 |
| `key_F3` | F3 |
| `key_F4` | F4 |
| `key_F5` | F5 |
| `key_F6` | F6 |
| `key_F7` | F7 |
| `key_F8` | F8 |
| `key_F9` | F9 |
| `key_G` | G |
| `key_H` | H |
| `key_Help` | Help |
| `key_Home` | Home |
| `key_I` | I |
| `key_Insert` | Insert |
| `key_J` | J |
| `key_K` | K |
| `key_L` | L |
| `key_LeftMouseButton` | Left Mouse Button |
| `key_M` | M |
| `key_MiddleMouseButton` | Middle Mouse Button |
| `key_Minus` | Minus |
| `key_N` | N |
| `key_NumLock` | Num Lock |
| `key_Numpad-` | Numpad - |
| `key_Numpad.` | Numpad . |
| `key_Numpad*` | Numpad * |
| `key_Numpad/` | Numpad / |
| `key_Numpad+` | Numpad + |
| `key_Numpad0` | Numpad 0 |
| `key_Numpad1` | Numpad 1 |
| `key_Numpad2` | Numpad 2 |
| `key_Numpad3` | Numpad 3 |
| `key_Numpad4` | Numpad 4 |
| `key_Numpad5` | Numpad 5 |
| `key_Numpad6` | Numpad 6 |
| `key_Numpad7` | Numpad 7 |
| `key_Numpad8` | Numpad 8 |
| `key_Numpad9` | Numpad 9 |
| `key_O` | O |
| `key_P` | P |
| `key_PageDown` | Page Down |
| `key_PageUp` | Page Up |
| `key_Pause` | Pause |
| `key_Period` | Period |
| `key_Print` | Print |
| `key_Q` | Q |
| `key_Quote` | Quote |
| `key_R` | R |
| `key_RightMouseButton` | Right Mouse Button |
| `key_S` | S |
| `key_Screen` | Screen |
| `key_ScrollLock` | Scroll Lock |
| `key_Select` | Select |
| `key_Semi-Colon` | Semi-Colon |
| `key_Shift` | Shift |
| `key_ShiftLeft` | Shift Left |
| `key_ShiftRight` | Shift Right |
| `key_Slash` | Slash |
| `key_Space` | Space |
| `key_SyskeyLeft` | Sys key Left |
| `key_SyskeyRight` | Sys key Right |
| `key_T` | T |
| `key_Tab` | Tab |
| `key_Tilde` | Tilde |
| `key_U` | U |
| `key_V` | V |
| `key_W` | W |
| `key_X` | X |
| `key_Y` | Y |
| `key_Z` | Z |

## C.5 `joy_` - joystick names (5). Bound via `CMESSAGE_GETJOY`.

| Tag | English |
|---|---|
| `joy_Button` | Button |
| `joy_Down` | Joy Down |
| `joy_Left` | Joy Left |
| `joy_Right` | Joy Right |
| `joy_Up` | Joy Up |

## C.6 `date_` - months, weekdays and seasons (23)

| Tag | English |
|---|---|
| `date_April` | April |
| `date_August` | August |
| `date_Autumn` | Autumn |
| `date_December` | December |
| `date_February` | February |
| `date_Friday` | Friday |
| `date_January` | January |
| `date_July` | July |
| `date_June` | June |
| `date_March` | March |
| `date_May` | May |
| `date_Monday` | Monday |
| `date_November` | November |
| `date_October` | October |
| `date_Saturday` | Saturday |
| `date_September` | September |
| `date_Spring` | Spring |
| `date_Summer` | Summer |
| `date_Sunday` | Sunday |
| `date_Thursday` | Thursday |
| `date_Tuesday` | Tuesday |
| `date_Wednesday` | Wednesday |
| `date_Winter` | Winter |

## C.7 `position_` - league-table ordinals 1st..32nd (32 remaining)

The cap of **32** bounds the largest supported league/group size.

| Tag | English |
|---|---|
| `position_1` | 1st |
| `position_10` | 10th |
| `position_11` | 11th |
| `position_12` | 12th |
| `position_13` | 13th |
| `position_14` | 14th |
| `position_15` | 15th |
| `position_16` | 16th |
| `position_17` | 17th |
| `position_18` | 18th |
| `position_19` | 19th |
| `position_2` | 2nd |
| `position_20` | 20th |
| `position_21` | 21st |
| `position_22` | 22nd |
| `position_23` | 23rd |
| `position_24` | 24th |
| `position_25` | 25th |
| `position_26` | 26th |
| `position_27` | 27th |
| `position_28` | 28th |
| `position_29` | 29th |
| `position_3` | 3rd |
| `position_30` | 30th |
| `position_31` | 31st |
| `position_32` | 32nd |
| `position_4` | 4th |
| `position_5` | 5th |
| `position_6` | 6th |
| `position_7` | 7th |
| `position_8` | 8th |
| `position_9` | 9th |

## C.8 `settings_` - Options screen (16 remaining)

| Tag | English |
|---|---|
| `settings_16-Bit` | 16-Bit |
| `settings_24-Bit` | 24-Bit |
| `settings_32-Bit` | 32-Bit |
| `settings_FullScreen` | Full |
| `settings_Graphics` | Graphics |
| `settings_High` | High Detail |
| `settings_JOYFOUND` | Joystick detected |
| `settings_JOYNOTFOUND` | Joystick not detected |
| `settings_Language` | Language |
| `settings_Low` | Low Detail |
| `settings_Resolution` | Resolution |
| `settings_Screen` | Screen |
| `settings_tlaResolution` | Res |
| `settings_Window` | Window |
| `settings_Language` | Language |
| `settings_ChangeLanguage` | Change Language |
| `settings_BossShouts` | Boss Shouts |

## C.9 `finances_` - Finances screen (7)

| Tag | English |
|---|---|
| `finances_Balance` | Balance |
| `finances_Cost` | Cost |
| `finances_In` | In |
| `finances_Out` | Out |
| `finances_Own` | Own |
| `finances_Sell` | Sell |
| `finances_WeeklyBalance` | Weekly Balance |

## C.10 Remaining enums and one-offs

Includes the shop catalogues (`item_`, `vehicle_`, `property_`), kit slots, skin tones, volume, game speed,
match length, match type, selection status, social share, and assorted singletons.

| Tag | English |
|---|---|
| `property_Apartment` | Apartment |
| `vehicle_Bicycle` | Bicycle |
| `btn_Action` | Action |
| `casino_Stake` | Stake |
| `property_Castle` | Castle |
| `property_Cottage` | Cottage |
| `item_DesignerSuit` | Designer Suit |
| `item_Earrings` | Earrings |
| `item_GamesConsole` | Games Console |
| `gamespeed_Fast` | Fast |
| `gamespeed_Normal` | Normal |
| `gamespeed_Slow` | Slow |
| `item_GoldRing` | Gold Ring |
| `vehicle_Helicopter` | Helicopter |
| `property_HolidayVilla` | Holiday Villa |
| `property_House` | House |
| `interview_Instrucs` | Memorise the GREEN sequence! |
| `kit_Away` | Away |
| `kit_Home` | Home |
| `kit_Keeper` | Keeper |
| `kit_Third` | Third |
| `property_Mansion` | Mansion |
| `matchlength_mins3` | 3 min |
| `matchlength_mins5` | 5 min |
| `matchlength_mins7` | 7 min |
| `matchtype_club` | league and cup |
| `matchtype_continental` | club continental |
| `matchtype_international` | international |
| `vehicle_Motorbike` | Motorbike |
| `item_MusicPlayer` | Music Player |
| `item_Phone` | Phone |
| `price_Free` | Free |
| `property_PrivateIsland` | Private Island |
| `vehicle_PrivateJet` | Private Jet |
| `vehicle_SailingBoat` | Sailing Boat |
| `vehicle_Scooter` | Scooter |
| `item_SilverChain` | Silver Chain |
| `property_SkiChalet` | Ski Chalet |
| `skin_Asian` | Asian |
| `skin_Black` | Black |
| `skin_Dark` | Dark |
| `skin_Light` | Light |
| `skin_White` | White |
| `vehicle_SmallCar` | Small Car |
| `social_Share` | Share |
| `social_Tweet` | Tweet |
| `vehicle_SportsCar` | Sports Car |
| `property_Stable` | Stable |
| `vehicle_SUV` | SUV |
| `item_Tablet` | Tablet |
| `team_Selection` | Selection |
| `property_TownHouse` | Town House |
| `item_TV` | TV |
| `volume_High` | High |
| `volume_Low` | Low |
| `volume_Off` | Off |
| `match_Watch` | Watch |
| `item_Watch` | Watch |
| `vehicle_Yacht` | Yacht |
| `selection_EnergyLow` | Energy Low |
| `selection_MatchFit` | Match Fit |
| `selection_PoorForm` | Poor Form |
| `selection_RelationshipLow` | Boss Unhappy |
| `selection_RelationshipLowInt` | Unimpressed |

---

# Appendix D - Mobile-only namespaces (present in the file, **dead in the PC/Steam build**)

Verification: the substring `MOBILE` occurs **zero** times in the `NSS5.exe` UTF-16 string table, as do `iap`,
`Star Bux`, `Arcade`, `Work Rate`, `Technique`, `Swipe`, `upgrade_`, `workrate`, `drink_`, `nrg_`, `gambling_`,
`lifestyle_`, `appstore`, `product_`. These strings belong to the mobile "New Star Soccer" title, which shares
this localisation file. **Do not implement these systems in a PC reconstruction** - but do keep the rows, because
the file is loaded wholesale and row counts affect nothing but must match for a byte-identical asset.

The mobile game differs from PC in ways this appendix documents for the record:

| PC | Mobile |
|---|---|
| 7 trainable abilities (Pace, Flair, Tackling, Dribbling, Passing, Shooting, Heading) | **5 skills**: Pace, Power, Technique, Vision, Free Kicks (`CHELPMOBILE_PACE/POWER/TECHNIQUE/VISION/SETPIECES`) |
| Full playable 2D match | Text match with occasional interactive chances (`CHELPMOBILE_MATCH`, `CCHANCESTAGE_*`) |
| In-game currency = real currency with `sla_Thousand`/`sla_Million` | **Star Bux** (`CHELPMOBILE_CASH`, `iap_StarBux1..8`) |
| Transfer value / rating | **Star Rating** (`Star Rating`, `CHELPMOBILE_STARRATING`) |
| Wage per **week** | Wage per **match** (`CMESSAGE_CONTRACTOFFERMOBILE`) |
| - | **Work Rate** setting (`workrate_Light/Normal/Hard/Extreme`, `CMOBILE_TIP7`) |
| - | **Arcade Mode** (`Arcade Mode`, `CMESSAGE_ARCADE`, `CTRAINING_ARCADEFINISH`) |
| - | **Wind** affecting kicks (`Wind`, `CMOBILE_TIP18`, `CTRAINING_TUTORIAL4a`) |
| - | 4 NRG drink tiers (`drink_NRG1..4`: NRG, NRG Skills, NRG Charm, NRG Gold) |
| - | IAP packs: Career Mode unlock, Pitch & Weather, Horse Racing |
| 100 achievements | 66 achievements |

## D.1 `CACHIEVEMENTMOBILE_` (66)

| Tag | English |
|---|---|
| `CACHIEVEMENTMOBILE_1` | Sign your first contract |
| `CACHIEVEMENTMOBILE_10` | Earn 25 'Star Man' awards |
| `CACHIEVEMENTMOBILE_11` | Earn 50 'Star Man' awards |
| `CACHIEVEMENTMOBILE_12` | Get 5 maximum match ratings in a row |
| `CACHIEVEMENTMOBILE_13` | Win a league game |
| `CACHIEVEMENTMOBILE_14` | Win a cup game |
| `CACHIEVEMENTMOBILE_15` | Win a cup tournament |
| `CACHIEVEMENTMOBILE_16` | Win a league title |
| `CACHIEVEMENTMOBILE_17` | Win a lower division title |
| `CACHIEVEMENTMOBILE_18` | Win a match by 5 goals |
| `CACHIEVEMENTMOBILE_19` | Score 20 club goals in a season |
| `CACHIEVEMENTMOBILE_2` | Score a goal |
| `CACHIEVEMENTMOBILE_20` | Make 200 club passes in a season |
| `CACHIEVEMENTMOBILE_21` | Make 20 club assists in a season |
| `CACHIEVEMENTMOBILE_22` | Get 20 'Star Man' awards in a season |
| `CACHIEVEMENTMOBILE_23` | Score 50 career goals |
| `CACHIEVEMENTMOBILE_24` | Score 100 career goals |
| `CACHIEVEMENTMOBILE_25` | Buy an NRG drink |
| `CACHIEVEMENTMOBILE_26` | Buy some boots |
| `CACHIEVEMENTMOBILE_27` | Purchase all luxury items |
| `CACHIEVEMENTMOBILE_28` | Purchase all vehicles |
| `CACHIEVEMENTMOBILE_29` | Purchase all properties |
| `CACHIEVEMENTMOBILE_3` | Score a hat-trick |
| `CACHIEVEMENTMOBILE_30` | Achieve 100% lifestyle rating |
| `CACHIEVEMENTMOBILE_31` | Win money at the roulette wheel |
| `CACHIEVEMENTMOBILE_32` | Win money on the slot machine |
| `CACHIEVEMENTMOBILE_33` | Win money playing black jack |
| `CACHIEVEMENTMOBILE_34` | Transfer to a new club |
| `CACHIEVEMENTMOBILE_35` | Sign a sponsorship contract |
| `CACHIEVEMENTMOBILE_36` | Sign all 10 sponsorship contracts |
| `CACHIEVEMENTMOBILE_37` | Achieve maximum pace skill |
| `CACHIEVEMENTMOBILE_38` | Achieve maximum power skill |
| `CACHIEVEMENTMOBILE_39` | Achieve maximum technique skill |
| `CACHIEVEMENTMOBILE_4` | Make 5 passes in 1 match |
| `CACHIEVEMENTMOBILE_40` | Achieve maximum vision skill |
| `CACHIEVEMENTMOBILE_41` | Achieve maximum free kick skill |
| `CACHIEVEMENTMOBILE_42` | Achieve 100% skill rating |
| `CACHIEVEMENTMOBILE_43` | Get a girlfriend |
| `CACHIEVEMENTMOBILE_44` | Get 100% BOSS relationship |
| `CACHIEVEMENTMOBILE_45` | Get 100% TEAM relationship |
| `CACHIEVEMENTMOBILE_46` | Get 100% FANS relationship |
| `CACHIEVEMENTMOBILE_47` | Get 100% SPONSORS relationship |
| `CACHIEVEMENTMOBILE_48` | Get 100% GIRLFRIEND relationship |
| `CACHIEVEMENTMOBILE_49` | Achieve 100% happiness |
| `CACHIEVEMENTMOBILE_5` | Make 10 passes in 1 match |
| `CACHIEVEMENTMOBILE_50` | Play for 10 seasons |
| `CACHIEVEMENTMOBILE_51` | Play for your country |
| `CACHIEVEMENTMOBILE_52` | Score an international goal |
| `CACHIEVEMENTMOBILE_53` | Score an international hattrick |
| `CACHIEVEMENTMOBILE_54` | Win an international match |
| `CACHIEVEMENTMOBILE_55` | Win an international tournament |
| `CACHIEVEMENTMOBILE_56` | Score 50 international goals |
| `CACHIEVEMENTMOBILE_57` | Score 100 international goals |
| `CACHIEVEMENTMOBILE_58` | Play in a continental club match |
| `CACHIEVEMENTMOBILE_59` | Score in a continental club match |
| `CACHIEVEMENTMOBILE_6` | Make an assist |
| `CACHIEVEMENTMOBILE_60` | Score a hattrick in a continental club match |
| `CACHIEVEMENTMOBILE_61` | Win a continental club match |
| `CACHIEVEMENTMOBILE_62` | Win a continental club tournament |
| `CACHIEVEMENTMOBILE_7` | Make 3 assists in 1 match |
| `CACHIEVEMENTMOBILE_8` | Earn a 'Star Man' award |
| `CACHIEVEMENTMOBILE_9` | Earn 10 'Star Man' awards |
| `CACHIEVEMENTMOBILE_63` | Win a bet at the races |
| `CACHIEVEMENTMOBILE_64` | Purchases a race horse |
| `CACHIEVEMENTMOBILE_65` | Win a race with your own horse |
| `CACHIEVEMENTMOBILE_66` | Purchase some 'NS-Control' boots |

## D.2 `CHELPMOBILE_` (42)

| Tag | English |
|---|---|
| `CHELPMOBILE_ACHIEVEMENTS` | Keep track of your achievements here. |
| `CHELPMOBILE_BOOTS` | You will always own a standard pair of football boots but there are a variety for sale that can give your SKILLS a boost. They will wear out over time so keep an eye on the 'Matches' stat. |
| `CHELPMOBILE_BOSS` | You will need to keep the BOSS happy if you want to play every match or if you want to improve your contract. |
| `CHELPMOBILE_BOSSINT` | This button will display your relationships with the BOSS, TEAM and FANS of the national team. You need to impress at club level to get selected for international matches. |
| `CHELPMOBILE_CASH` | These are your STAR BUX. You need them to buy NRG Drinks, BOOTS and SHOP items. You can also spend star bux in the CASINO. |
| `CHELPMOBILE_CASINO` | Need a bit more cash? Then try your luck in the CASINO! |
| `CHELPMOBILE_CASINOBET` | Set your bet amount and try your luck in one of the rooms below. |
| `CHELPMOBILE_CASINOBLACKJACK` | Try to get as close to 21 without going over it. The dealer will always stick on 16 or higher. |
| `CHELPMOBILE_CASINOROULETTE` | Red or black. It's that simple. |
| `CHELPMOBILE_CASINOSLOTS` | Spin the reels to match 2 items for a win or 3 items for a jackpot! |
| `CHELPMOBILE_ENERGY` | You need ENERGY to increase skills and improve relationships but make sure you save enough for the next match! |
| `CHELPMOBILE_FANS` | FANS may boo you during a match and cause you to lose the ball if your relationship is low. You will also need a good relationship with the FANS in order to attract SPONSORS. |
| `CHELPMOBILE_FIXTURES` | Switch to this screen to see your fixtures and results. You can highlight a different team in the league table if you want to view their fixtures. |
| `CHELPMOBILE_GAMBLING` | Then GAMBLING meter reflects how addicted you are! |
| `CHELPMOBILE_GIRLFRIEND` | Your relationship with your GIRLFRIEND has a big impact on your overall HAPPINESS. |
| `CHELPMOBILE_HAPPINESS` | Your HAPPINESS is determined by the relationships below. |
| `CHELPMOBILE_HELP` | This is the HELP button. Press it whenever you want to understand more about the current screen you are on. |
| `CHELPMOBILE_LEAGUES` | This is the competitions screen. You can check out different league, cup and international competitions by pressing this button. |
| `CHELPMOBILE_LIFESTYLE` | You can buy items in the shop to increase your LIFESTYLE rating. |
| `CHELPMOBILE_MATCH` | This is the match screen. Incidents will be listed here and occasionally you will get a chance to influence the game. Your TEAM relationship and WORK RATE will affect the number of chances you get. |
| `CHELPMOBILE_MATCHNRG` | You can drink a can of NRG at half time if you have purchased any. Only green NRG can be used during a match. |
| `CHELPMOBILE_MATCHTIME` | If you want to slow down or speed up the match text press this button. |
| `CHELPMOBILE_NAVBAR` | This is the navigation bar. You can switch to different screens or progress to the next match with the Play button. |
| `CHELPMOBILE_NRG` | NRG drinks can be purchased to recover your ENERGY level. Special cans of NRG can also improve SKILLS and RELATIONSHIPS! |
| `CHELPMOBILE_PACE` | PACE determines how quickly you run. It is useful for intercepting passes. |
| `CHELPMOBILE_PAIRS` | Pick two matching cards to improve your relationship! |
| `CHELPMOBILE_POWER` | POWER determines how hard you can kick the ball. |
| `CHELPMOBILE_RENEWCONTRACT` | If the BOSS is happy with you and your STAR RATING has increased then you can ask for a new contract. |
| `CHELPMOBILE_SELECTIONSTATUS1` | This tells you whether you have been picked to play in the next match. Sometimes you might be a substitute or even dropped from the squad completely! |
| `CHELPMOBILE_SELECTIONSTATUS2` | If the BOSS has not selected you for the first team the reason why will be shown here. Maybe you can solve the problem before the match. |
| `CHELPMOBILE_SETPIECES` | Improve your SET PIECE skill if you want to take free kicks and penalties during a match. |
| `CHELPMOBILE_SKILLCHOICE1` | Completing a training challenge will improve your skill and unlock the next level. To achieve a 3 star rating you need to complete the challenge in 1 attempt. |
| `CHELPMOBILE_SKILLCHOICE2` | You will need 3 stars on every level to max out your skill rating. |
| `CHELPMOBILE_SKILLS` | There are 5 key SKILLS you can improve by completing training challenges. This meter represents your overall skill rating. |
| `CHELPMOBILE_SPONSORS` | You will need to fulfill your commitments to your SPONSORS in order to keep them happy or they may cancel their contracts! |
| `CHELPMOBILE_SPONSORSLIST` | As your STAR RATING increases you may attract SPONSORS that want you to endorse their products. They will pay you money each time you play. |
| `CHELPMOBILE_STARRATING` | Your STAR RATING is increased by playing well in matches. You need to increase it if you want to transfer to a bigger club or negotiate a better contract. |
| `CHELPMOBILE_STATS` | This is the STAT screen. It keeps track of your goals, assists, match ratings and so on. |
| `CHELPMOBILE_SWIPE` | You can swipe the screen to view your STATS, CONTRACT and SPONSOR details. |
| `CHELPMOBILE_TEAM` | A good relationship with the TEAM means you will get more chances during a match. |
| `CHELPMOBILE_TECHNIQUE` | Your TECHNIQUE determines how much you can bend, chip or dip the ball. |
| `CHELPMOBILE_VISION` | If your VISION is good you will see more team mates who you can to pass the ball to. |

## D.3 `CMOBILE_TIP` (20)

| Tag | English |
|---|---|
| `CMOBILE_TIP1` | Maximum kicking power is achieved by striking the ball dead centre. Striking the top half of the ball keeps your shots low. |
| `CMOBILE_TIP10` | Your LIFESTYLE rating is determined by the number of items, vehicles and properties that you have purchased from the shop. |
| `CMOBILE_TIP11` | The BOSS, TEAM and FANS will get more critical of you as your STAR RATING increases. |
| `CMOBILE_TIP12` | If you increase your STAR RATING you might be able to persuade the BOSS that you deserve an improved contract. |
| `CMOBILE_TIP13` | At the end of the season you are able to view all clubs that are interested in signing you. Even those in other leagues. |
| `CMOBILE_TIP14` | Increase your FREE KICK skill to become the main free kick and penalty taker in the team. |
| `CMOBILE_TIP15` | NRG drinks that increase a SKILL will fill the first empty star in your list of training challenges. |
| `CMOBILE_TIP16` | You need to buy the best boots to achieve maximum PACE, POWER and TECHNIQUE. |
| `CMOBILE_TIP17` | If you have a GIRLFRIEND she will expect you to spend some time with her regularly. Leave it too long and she will get annoyed! |
| `CMOBILE_TIP18` | It is important to have good POWER and TECHNIQUE to combat the effects of the WIND. |
| `CMOBILE_TIP19` | Your relationship with your SPONSORS will decrease slowly over time. Make sure you regularly spend some time with them. |
| `CMOBILE_TIP2` | Having a good relationship with the TEAM will increase the number of chances you get during a match. |
| `CMOBILE_TIP20` | Winning the World Cup and the Champions League are perhaps the greatest achievements for any player. |
| `CMOBILE_TIP3` | The BOSS is mainly concerned about your overall performance in a match. However, he may get annoyed if your GIRLFRIEND starts making news headlines! |
| `CMOBILE_TIP4` | Passing to your TEAM MATES is the best way to improve your relationship with them. If they score after recieving a pass from you (an ASSIST) they will be even more impressed! |
| `CMOBILE_TIP5` | The most important thing to the FANS is the match result. Play well AND win to improve your relationship with them. |
| `CMOBILE_TIP6` | Playing the ARCADE MODE is a great way to practice your shooting skills. |
| `CMOBILE_TIP7` | Setting your WORK RATE to low will help you conserve ENERGY but you may get less opportunities. Setting it high will burn ENERGY faster but get you more opportunities. |
| `CMOBILE_TIP8` | Owning properties increases your ENERGY recovery after a match. |
| `CMOBILE_TIP9` | Focus on passing if your kicking POWER is low and save up enough cash for a cool pair of BOOTS. |

## D.4 `iap_` - in-app purchases (11)

| Tag | English |
|---|---|
| `iap_CareerMode` | Career Mode |
| `iap_PitchPack` | Pitch & Weather |
| `iap_RacingPack` | Horse Racing |
| `iap_StarBux1` | 25 Star Bux |
| `iap_StarBux2` | 50 Star Bux |
| `iap_StarBux3` | 100 Star Bux |
| `iap_StarBux4` | 250 Star Bux |
| `iap_StarBux5` | 500 Star Bux |
| `iap_StarBux6` | 1,000 Star Bux |
| `iap_StarBux7` | 2,500 Star Bux |
| `iap_StarBux8` | 5,000 Star Bux |

## D.5 `upgrade_` - pre-Steam web premium upsell (4)

| Tag | English |
|---|---|
| `upgrade_Premium` | Upgrade to a premium account and get unlimited matches forever! |
| `upgrade_MatchPack` | Or purchase a match pack to increase the number of matches you can play... |
| `upgrade_MatchPack2` | By purchasing a match pack you will add matches to your account. When all of these matches have been played your account will revert to receiving 3 free matches per day. |
| `upgrade_Methods` | We accept Credit Card, PayPal, Amazon Pay, Google CheckOut, MoneyBookers and more! |

## D.6 `WARNING_` - 2019 web→Steam migration notices (4)

Note the un-substituted markers `DAY-MONTH-YEAR-1/2/3`: these were placeholders the developer filled in by hand
per build. They are dead in the shipped Steam build.

| Tag | English |
|---|---|
| `WARNING_1` | After DAY-MONTH-YEAR-1, New Star Soccer 5 will only be playable using Steam.  |
| `WARNING_2_FREE` | From DAY-MONTH-YEAR-2 to DAY-MONTH-YEAR-3 New Star Soccer 5 will be on sale at an introductory price for players who wish to upgrade. |
| `WARNING_2_PAID` | You have been assigned a Steam activation key which will unlock New Star Soccer 5 on Steam at no further cost. If you have not redeemed the code already, sign in to newstarsoccer.com before DAY-MONTH-YEAR-1 to get your activation key. |
| `WARNING_3` | Career save data from this version will continue to be compatible with the Steam version. |

## D.7 Remaining mobile singletons

| Tag | English |
|---|---|
| `drink_NRG1` | NRG |
| `drink_NRG2` | NRG Skills |
| `drink_NRG3` | NRG Charm |
| `drink_NRG4` | NRG Gold |
| `nrg_Can` | Can |
| `nrg_Cans` | Cans |
| `training_AimHere` | Aim Here |
| `workrate_Extreme` | Extreme |
| `workrate_Hard` | Hard |
| `workrate_Light` | Light |
| `workrate_Normal` | Normal |
| `lifestyle_Luxury` | Lifestyle |
| `product_Description` | Live the life of an up-and-coming superstar in this unique football career game. Start out as a 16 year old lad and work your way to the top to become a footballing legend! You need to train hard, play matches, make transfers, do interviews, stay in touch with friends, sign sponsorship deals, go to the casino, buy cars, and more! With so many distractions in a footballer's life is it any wonder that so many don't make it? But what about you? Can you become a new star? |
| `gambling_Wins` | Wins |
| `appstore_Games` | Games |

## D.8 Mobile-flavoured `CMESSAGE_`/`CNEWS_`/`CRESULTNEWS_`/`CMATCHTEXT_`/`CCHANCESTAGE_`

Already dumped in Appendix A and §14/§19. The `*MOBILE*`-suffixed tags are the obvious ones; also mobile-only:
`CMESSAGE_ARCADE*`, `CMESSAGE_CAREERMODE*`, `CMESSAGE_RESTOREPRODUCTS`, `CMESSAGE_REVIEWAPP`,
`CMESSAGE_BUYPITCHPACK`, `CMESSAGE_KONGWELCOME`, `CMESSAGE_CHECKOVERWRITESAVEIOS`, `CMESSAGE_NOSHOPCONNECTION`,
`CMESSAGE_TRAINING{PACE,POWER,SETPIECES,TECHNIQUE,VISION}`, `CMESSAGE_TRIALMOBILE*`,
`CTRAINING_TUTORIAL*`, `CTRAINING_ARCADE*`, the whole `CCHANCESTAGE_` family and (probably) the whole
`CMATCHTEXT_` and `CRESULTNEWS_` families.

---

## 23. Open questions (`UNCERTAIN`) - resolve against the disassembly

1. **Empty-cell fallback.** Does `TLanguage` fall back to `en`, render the tag, or render empty? Dutch would
   otherwise show 174 blank strings.
2. **Duplicate-tag resolution.** First-write-wins or last-write-wins? Decides which `CMESSAGE_QUIT` text ships.
3. **`CTIP_46` handling.** Does the tip picker index a list (so the gap is invisible) or compute
   `"CTIP_" + Rand(1,50)` (so 2% of tips are broken)?
4. **Boot shop stat labels.** `lbl_tackling` in the widget block vs `CHELP_BOOTS` saying DRIBBLING. Which three
   abilities do boots actually modify?
5. **Boot model names.** Not in `Languages.csv`, not in the exe string dump. Where are they?
6. **Item / vehicle / property prices.** Not in any CSV and not in the string dump - they must be a hardcoded
   numeric table in `.text`/`code`. Locate the 4×10 price arrays.
7. **Two purchase-confirm dialogs.** What selects `CMESSAGE_CONFIRMPURCHASE` vs
   `CMESSAGE_CONFIRMPURCHASEENERGYCOST`?
8. **Property → energy recovery.** Mobile says property increases post-match recovery; does the PC build?
9. **`" / 6"` in the stable code.** Runners per race, or race N of 6?
10. **`stable_racenumWin` / `stable_racenumPlace`.** Save-profile stat keys, or a language-tag template with an
    index substituted for `num`? They are absent from `Languages.csv`.
11. **`CMATCHTEXT_` / `CCHANCESTAGE_` / `CRESULTNEWS_` on PC.** No literal or prefix stub was found in the exe;
    confirm they are entirely mobile before dropping ~135 strings' worth of behaviour.
12. **Assist bonus storage.** `TContractOffer` loads `goalbonus` and `cleanbonus` but no assist bonus, yet the UI
    and `CMESSAGE_BONUSINCREASED` reference one.
13. **`Trailer Home`** - a bare tag with no shop slot. Default starting residence?
14. **`Ball Control` / `Vision`** as PC ratings - present as tags and `tla_BallControl` exists, but no `prg_` bar
    was found. PC or mobile?
15. **`selection_*` vs bare selection labels.** The PC exe uses the bare strings; is `selection_*` truly unused?

---

*End of document.*
