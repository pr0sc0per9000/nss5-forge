# The text and language system

> **Source:** `TLocale.SetUp` @ 0x004c558f (READ) · `TLocale.SetCurrentLanguage` @ 0x004c584d (READ) · `TLocale.GetLocaleText` @ 0x004c58fc (READ) · `TLocale.SetUpKeyStrings` @ 0x004c5966 (READ) · `GetText` @ 0x004c5549 (VERIFIED) · `TAchievement.LoadData` @ 0x0058d1a5 (VERIFIED) · `TProfile.DoNews` @ 0x00569106 (VERIFIED) · `TPlayer.UpdateOffside` @ 0x004fe9ba (VERIFIED) · `TScreen_Interview.SetUpScreen` @ 0x0057b109 (READ) · `TScreen_ReportBoss.SetUpScreen` @ 0x00561dff (READ)
> **Confidence:** HIGH for the file format and the tag-to-text lookup mechanism (all four `TLocale` functions were read from Ghidra's decompile with every string literal resolved); MEDIUM for what some of the smaller tag families are used for, since that is inferred from the tag's own name and its text rather than from reading every function that calls `GetText` with it.
> **Last checked:** 2026-08-15

Almost nothing New Star Soccer 5 shows on screen is a literal string in the code. A screen label,
a button caption, a boss's shout, a newspaper headline - all of it is a short key (a "tag", e.g.
`CMESSAGE_BOOTSWORNOUT`) that gets looked up in one file at the moment it is drawn. That file is
`GameMedia/Languages/Languages.csv`, and this document is about how that lookup works and what the
2,750 tags in it actually cover.

## The file itself

`Languages.csv` is 1.4 MB, tab-separated, plain UTF-8 with no byte-order mark. It has 2,751 lines:
one header row naming the columns, then 2,750 tag rows.

```
Tag	en	br	pt	de	es	fr	it	pl	tr	nl
```

The header's first column is always `Tag`; the other ten are language codes - English, Brazilian
Portuguese, European Portuguese, German, Spanish, French, Italian, Polish, Turkish, Dutch. Every
data row is one tag followed by up to ten pieces of translated text, tab-separated, in that same
column order.

Three rows are metadata about the file rather than in-game text (see "Language selection" below):
`Tag_Language`, `Tag_NationId`, `Tag_Translator`.

## How a tag becomes on-screen text

The lookup is a thin, two-function pipe. Almost every caller in the game (1,831 call sites, per
the disassembly's call graph) writes `GetText("SomeTag")`, a 22-byte module-level function that
does nothing but forward to `TLocale.GetLocaleText`:

```blitzmax
Function GetText:String(a0:String)
    Return TLocale.GetLocaleText(a0)
End Function
```

`TLocale.GetLocaleText`, in turn, does a two-level dictionary lookup: first find the dictionary for
the *current language*, then find the tag inside it.

**Loading (`TLocale.SetUp`, called once at startup):**

1. Opens `GameMedia/Languages/Languages.csv` as UTF-8. If it can't be opened, the game shows
   `Notify("Error TMyLocale: Unable to load language file!")` and exits immediately - the whole
   game is unplayable without this file. (The message says "TMyLocale", not "TLocale" - the class
   was evidently renamed at some point during development and this one debug string was never
   updated. Harmless, but a nice fossil.)
2. Reads the header line, splits it on tabs, and throws away the first field (`Tag`). The other
   ten fields (`en`, `br`, `pt`, …) become the set of known language codes; one empty dictionary
   (a `TMap`) is created for each.
3. Reads every remaining line. Column 0 of each row is the tag; the game then walks the row
   left-to-right and inserts `(tag → text)` into each language's dictionary in turn.
4. **The fallback rule for a blank cell:** while walking a row, the game remembers the last
   non-blank piece of text it has seen so far in that row. If a language's cell is empty, that
   remembered text is used instead. Because `en` (English) is always the first language column
   and is essentially never blank, this means **a missing translation silently falls back to the
   English text** for that tag, not to a blank string. A translator who leaves a cell empty is
   choosing "use English here", whether they meant to or not.

**Looking a tag up (`TLocale.GetLocaleText`, every time `GetText(...)` is called):**

1. Find the current language's dictionary (see below).
2. Look the tag up in it.
3. If the tag isn't in the dictionary at all (not even the English fallback - this can only
   happen if a tag used somewhere in the code was simply never added to the CSV), the function
   falls back to an empty string.
4. If the result is still empty at that point, the game builds the literal string `"@" + tag` - 
   e.g. asking for a tag that was never entered in the CSV returns `@SomeMissingTag` rather than
   nothing. Ghidra's decompiler doesn't show an explicit `Return` for this branch (a limitation
   noted throughout this project - it drops final-value assignments it can't prove are used by
   the caller), so the exact mechanics of the "@"-prefixing are read with medium confidence, but
   the literal string `"@"` sitting right where a not-found fallback would go is strong evidence:
   **a genuinely absent tag renders as its own name with an "@" stuck on the front, right there
   in the middle of a sentence**, which is a classic "make the hole in the localisation visible in
   QA" trick.

So there are two different kinds of "missing": a blank cell in a row that exists (falls back to
English, invisibly) and a tag that was never entered at all (renders visibly as `@TagName`).

## Language selection

`Tag_NationId` maps each of the ten language columns to a nation ID from `Nations.csv`:

| Column | Language | Nation ID | Nation (from `Nations.csv`) |
|---|---|---:|---|
| en | English | 0 | *(no nation with ID 0 - see below)* |
| br | Brazilian Portuguese | 28 | Brazil |
| pt | Portuguese | 151 | Portugal |
| de | German | 75 | Germany |
| es | Spanish | 175 | Spain |
| fr | French | 71 | France |
| it | Italian | 95 | Italy |
| pl | Polish | 150 | Poland |
| tr | Turkish | 193 | Turkey |
| nl | Dutch | 133 | Netherlands |

Nine of the ten resolve cleanly to a real nation in `Nations.csv`. English's ID is `0`, which is
not any nation in that file (England itself is nation 62) - `0` reads as a sentinel meaning
"default language, no specific nation", not "the nation whose ID happens to be zero". *(INFERRED
from the data; the code that actually reads `Tag_NationId` to drive nation→language defaulting - 
e.g. for a new save file - was not located in this pass.)*

`TLocale.SetCurrentLanguage(code)` is what changes the active dictionary:

1. Look `code` up in the outer map. **If it isn't one of the ten known codes, the game silently
   falls back to `"en"`** rather than erroring - there's no way to end up with no language
   selected.
2. Store the (validated) code as the current language.
3. Call `TLocale.SetUpKeyStrings()` (see below) to rebuild the cached keyboard-key name strings
   for the new language.
4. `LogLine("Language set to: " + code)`.

`TLocale.SetUpKeyStrings` calls `GetLocaleText` roughly 85 times in a fixed sequence - mechanically
repeated blocks, one per tag, each storing its result into a fixed slot of a small on-disk-shaped
struct (`PTR_PTR_00c5a324`, offsets `0x1c` through `0x314`). This is clearly a pre-fetch cache for
the 113 `key_*` tags (`key_A`, `key_F1`, `key_Enter`, …) used by the controls/key-rebinding screen,
so the game doesn't call `GetText` fresh every frame while that screen is open. *(READ, MEDIUM - 
the general shape and its caller are confirmed, but the 85 individual tag names inside it were not
read one by one, so it isn't confirmed that all 85 are `key_*` and no others.)*

## Variable substitution - the `$token` system

A lot of `CMESSAGE_*`/`CNEWS_*`/`CREPORT_*` text contains placeholders like `$playername` or
`$clubname`. These are **not** handled inside `GetText`/`GetLocaleText` - the raw text comes back
with the literal `$token` still in it, and the caller runs it through `TProfile.DoNews(text, home,
away, years, num)`, which does a fixed sequence of `.Replace()` calls:

| Token | Replaced with |
|---|---|
| `$clubname` | home club's short name |
| `$clubstadium` | home club's stadium name (or short name again, if the club has no stadium name) |
| `$opposingclubname` / `$offerclubname` | away club's short name |
| `$opposingclubstadium` / `$offerclubstadium` | away club's stadium name |
| `$playername` | the player's own display name |
| `$years` | the `years` argument, as text |
| `$num` | the `num` argument, as text |
| `$injurylength` | the player's current injury length |
| `$value` | the player's transfer value, formatted as money (rounded down to the nearest 10,000 above 10,000) |
| `$wage` | the player's current wage, formatted as money |

60 distinct `$tokens` appear across the CSV in total (`$score`, `$percent`, `$energy`,
`$teamname`, `$competition`, `$cash`, and many more, each used by only one or a handful of
messages) - `DoNews` only handles the ten above, so most of the others must be substituted by
other call sites the way `DoNews` does it (each message's caller supplying its own values). Which
function substitutes which of the other 50 tokens was not traced in this pass.

## Tag naming conventions - the family inventory

This is the most useful part of the file: the tag prefixes are a map of what systems the game
has. 2,136 of the 2,750 tags carry an underscore-delimited prefix; the other 614 have no prefix at
all (see below). Splitting on the first underscore gives 87 distinct prefix families; the ones
with five or more members cover 2,052 of those 2,136 rows (96%). Sorted by size:

| Prefix | Rows | What it is |
|---|---:|---|
| `CMESSAGE_` | 408 | Pop-up dialog and confirmation-box text ("Only 3 substitutes allowed!", "Are you sure you wish to...") |
| `CNEWS_` | 194 | In-career newspaper/story templates (transfers, debuts, cup wins) - read via `TProfile.DoNews` |
| `tla_` | 120 | Three-letter (ish) abbreviations for stat names, e.g. `tla_Achievements`→"Ach", `tla_Assists`→"As" |
| `key_` | 113 | Display names for every keyboard key, for the controls-remapping screen (see `SetUpKeyStrings` above) |
| `CACHIEVEMENT_` | 100 | The 100 desktop/Steam achievement descriptions - see `achievements-and-news.md` |
| `CBOSSNEG_` / `CBOSSPOS_` | 96 + 96 | In-match boss commentary: 24 event categories × 4 phrasing variants × {gentler, harsher} tone - see `achievements-and-news.md` |
| `CMATCHTEXT_` | 91 | Short match-commentary fragments ("But he gets booed and loses the ball") |
| `CREPORT_` | 87 | The boss's written post-match report text |
| `tt_` | 69 | Tooltips (`tt_Achievements`, `tt_BuyBoots`, …) |
| `CACHIEVEMENTMOBILE_` | 66 | A **second, entirely different** achievement list (ids 1-66, different unlock text from `CACHIEVEMENT_`). No code path calling `GetText` with this prefix was found anywhere in the recovered source or the string cross-reference table - it appears to be dead data left over from a mobile build. |
| `CTIP_` | 49 | Loading-screen tips |
| `CHELPMOBILE_` | 42 | Mobile-flavoured help text (usage not traced this pass) |
| `CHELP_` | 35 | Sidebar help-panel text for the desktop UI - confirmed in use, e.g. `CHELP_REPORTRELATIONSHIPS` is attached to the boss-report screen's relationship panel via `THelpBox.Create` |
| `position_` | 35 | Ordinal league-position labels (`position_1`→"1st") |
| `help_` | 33 | Full-screen tutorial pop-up text (`help_achievements`, `help_blackjack`, …) - a separate, lower-case family from `CHELP_` |
| `CCHANCESTAGE_` | 30 | Build-up-play commentary shown before a shot ("But the attack breaks down") |
| `sla_` | 28 | Single/double-letter short labels (`sla_Centre`→"C", `sla_AttackingMid`→"AM") |
| `CLICHE_` | 26 | The interview minigame's answer-button text - confirmed: `TScreen_Interview.SetUpScreen` fills buttons 1-3 with `CLICHE_1..3` and buttons 4-15 with a random, non-repeating draw from `CLICHE_4..25` (`CLICHE_26` is defined but never rolled) |
| `CDILEMMA_` | 24 | Random career "dilemma" event text |
| `CTRAINING_` | 23 | Training-minigame instructions |
| `date_` | 23 | Month and season names |
| `controls_` | 21 | Control-scheme action names (Aim, Call, Block Tackle, …) |
| `CMOBILE_` | 20 | Mobile-only gameplay tips |
| `transfer_` | 18 | Transfer-market UI labels |
| `settings_` | 17 | Options-menu labels |
| `replay_` / `CRESULTNEWS_` | 14 / 14 | Replay-controls captions / results-page news blurbs |
| `account_`, `blackjack_`, `iap_` | 11 each | Online-account UI, Black Jack minigame, in-app-purchase catalogue |
| `vehicle_`, `sponsor_`, `property_`, `item_`, `CBOSS_` | 10 each | Shop catalogues (vehicles/sponsors/properties/luxury items) and ten generic short boss acknowledgements ("Good.", "Nice.", "Very nice.") |
| `simple_`, `advanced_` | 4 + 3 | The two control-scheme tutorials |
| `finances_`, `injury_` | 7 each | Finance-screen row labels / injury-loss messages |
| `comptype_`, `roulette_`, `time_` | 6 each | Competition-type names, roulette bet names, travel-time bands |
| `skin_`, `selection_`, `request_`, `pos_`, `leaderboard_`, `joy_` | 5 each | Player-creation skin tones, squad-selection warnings, corner/free-kick request options, position names, leaderboard categories, joypad button names |
| `climate_`, `highlow_`, `kit_`, `matchmsg_`, `skiptime_`, `upgrade_`, `drink_`, `workrate_`, `WARNING_` | 4 each | Climate bands; the Higher-or-Lower negotiation minigame; kit slots; in-match status messages ("You are tired!"); skip-time button captions; IAP upsell text; NRG drink flavours; work-rate settings; and four Steam-transition legal notices |
| ~38 more families | 2-3 each | `Tag_` (the three metadata rows), `difficulty_`, `gamespeed_`, `matchlength_`, `matchtype_`, `side_`, `volume_`, `bet_`, `social_`, `stable_`, `zoom_`, `nrg_`, and others - mostly small option-menu enumerations |

**The other 614 tags have no prefix at all - the tag *is* the English text.** `1st`, `Achievements`,
`Any Club`, `Away Kit`, `Star Man`, and 609 more are stored with the tag column and the `en`
column holding the identical string. 613 of the 614 are exact matches; the sole exception is
`AppTitle`, whose tag is the literal word `AppTitle` but whose text is `"New Star Soccer 5"` in
every language. This is a deliberate convention, not an accident: for short, simple, one-off UI
words, the developers just used the English word itself as the lookup key instead of inventing a
`some_prefix_Something` name.

One family named in the task brief that turned out **not to exist**: no tag anywhere in the file
starts with `inp_`, `pan_`, or `editmenu_`. (A separate document in this repo,
`docs/specs/06-binary-string-subsystem-map.md` §9.4, independently found the same thing from the
binary's string table: widget-name prefixes like `btn_`, `pan_`, `lbl_`, `inp_` are **not** language
keys - with one single exception, `btn_Action` - they're just internal gadget names built directly
from data, such as `"btn_" + String(n)` in the interview screen.)

## Text that is hardcoded in the binary, not in the CSV

A handful of user-visible strings bypass the CSV lookup entirely and are plain literals in the
`.exe`, found while reading the four `TLocale` functions and their neighbours:

- `"Error TMyLocale: Unable to load language file!"` - the fatal startup error if the CSV can't be opened.
- `"SetCurrentLanguage:"` and `"Language set to: "` - debug log lines (`LogLine`), never shown to the player.
- `"@"` - the missing-tag placeholder prefix described above.
- `"btn_"` and every other `<screenid>_<widget>` gadget name (see the `docs/specs/06` cross-reference above) - these identify UI elements, not translatable text, and never go through `GetText`.
- The outbound URLs used by the account and social-share systems (`http://www.newstarsoccer.com/…`, `http://twitter.com/…`, `http://www.facebook.com/…`, the `bit.ly` share link) - covered in `career/achievements-and-news.md`.

## What we do not know yet

- **Which function substitutes the other ~50 `$tokens`.** `TProfile.DoNews` only handles ten of
  the 60 tokens found in the CSV (`$score`, `$percent`, `$energy`, `$teamname`, … are not among
  them). Each must be substituted at its own call site; none of those call sites were traced in
  this pass.
- **Who reads `CACHIEVEMENTMOBILE_*`.** No caller was found. If one exists, it wasn't in the
  recovered source, the string cross-reference table, or the callgraph searched here.
- **`CHELPMOBILE_*` usage.** Unlike `CHELP_*` (confirmed in `TScreen_ReportBoss.SetUpScreen`), no
  consuming function was located for the mobile-flavoured help text.
- **The exact `Replace()` call in `TLocale.SetUp`'s row-reading loop.** Every data row gets run
  through a string-replace before its fields are split; Ghidra's decompiler hid two of that call's
  three arguments (a well-documented limitation in this project - see `TLocale.SetUp` @ 0x004c558f's
  own reading notes), so what exactly gets replaced is unconfirmed. It runs on every row
  unconditionally, so it's likely a defensive cleanup (a stray control character, a smart quote)
  rather than something tag-specific.
- **Exactly how many, and which, of `SetUpKeyStrings`'s ~85 calls are `key_*` tags.** The general
  shape (repeat `GetLocaleText` → store into next struct slot) is confirmed; the 85 individual tag
  names were not read one by one.
- **What drives the nation→language default at first run** (i.e. what actually reads
  `Tag_NationId`). Not located in this pass.
