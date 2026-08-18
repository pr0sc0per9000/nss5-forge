# 06 - Binary String Subsystem Map

**Master index for the NSS5.exe reverse-engineering effort.**

Source artefact: `<temp>
(3,955 lines, UTF-16 string pool of `NSS5.exe`, in binary order.)

Cross-checked against the read-only install at
`C:/Program Files (x86)/Steam/steamapps/common/New Star Soccer 5`.

---

## 1. Why order matters

BlitzMax (BMK/`bmk makeapp`) emits each source module's string constants into the
`.data`/`.rodata` section **in the order the compiler walked the module**, and modules are
walked in `Import`/`Include` order. The consequence is that the string pool is effectively a
**table of contents of the original source tree**. Consecutive runs of thematically-related
strings are almost always one original `.bmx` file (or one `Type` inside it).

Three structural signatures make the seams easy to spot:

| Signature | Meaning |
|---|---|
| `<path>.csv` → `Could not load <path>.csv` → `TXxx.LoadData` → run of lowercase field names → shorter run of the *same* field names → `GameMedia/Data/Mobile/Xxx.txt` | A data-table `Type` with a CSV loader and a reduced-column "Save For Mobile" exporter |
| `<screenid>` → `<Caption>` → `<widgetid>` → `<Caption>` → `<widgetid>` … | One GUI screen `Type`; captions and widget IDs alternate because the constructor signature is `New<Widget>(id$, caption$, …)` |
| Run of bare lowercase words with no punctuation, immediately after an `incbin::Inc/Engine.ini` or a `.png` block | `Engine.ini` key names being read by `TIni.GetFloat("key")` |

**Verified example of the mobile-export signature** - `Nations.csv` real header is
`id name shortname tla strength rivalid1 … secondaryskin` (38 cols). Dump lines 264-299 list
exactly those 36 (minus `id`/`tla`, handled positionally). Lines 300-311 then list a
12-column subset, immediately followed by line 312 `GameMedia/Data/Mobile/Nations.txt`.
That is the reduced mobile export, not a duplicate.

### 1.1 Reading the dump - extraction artefacts

The extractor scanned for runs of UTF-16 code units and over-ran into adjacent object headers.
Several strings therefore carry **1-4 trailing junk characters**. Confirmed by ground truth:

| Dump line | Dump text | Real value | Proof |
|---|---|---|---|
| 3559 | `GameMedia\Data\Horse.inii` | `GameMedia\Data\Horse.ini` | File on disk is `Horse.ini` |
| 253 | `666666i` | `666666` | 6-hex colour |
| 392 | `sla_Losti` | `sla_Lost` | Sibling keys `sla_Won`, `sla_Drawn` |
| 780 | `444444$$$` | `444444` | 6-hex colour |
| 1332 | `008000$` | `008000` | 6-hex colour |
| 3803 | `utf16lebb` | `utf16le` | Sibling `utf16be` at 3802 |

Observed padding characters: `$ i b s h j f`. **Rule: strip trailing `[$ibshjf]+` from any
string whose semantic length is otherwise obvious.**

Lines **1-157** are not strings at all - repeated `jjjj` / `\jjj` / `jjjh` / `jjjjj`
(0x006A006A… / 0x005C006A…). This is a pointer or GC-descriptor table misread as UTF-16.
Ignore. The real string pool starts at line **158**.

---

## 2. Master segmentation map

`Confidence`: **H** = seam is unambiguous (loader signature, screen ID, ini block);
**M** = strong thematic run; **L** = inferred, see §9.

| Lines | Inferred original module | What it does | Conf |
|---|---|---|---|
| 1-157 | *(none - binary noise)* | Pointer/descriptor table, not strings | H |
| 158-170 | `NSS5.bmx` (main, `Incbin` header) | The 10 `Incbin` directives: Credits, Player.png, 2 TTFs, 6 OGGs, Engine.ini | H |
| 171-205 | `NSS5.bmx` / `TApp.bmx` - bootstrap | App identity (`New Star Soccer 5`, `5.1.0`, `Win32`), `Settings/Settings.txt` + its 7 keys, save/replay dir layout, 10 outbound URLs, audio-driver names | H |
| 206-250 | `TMedia.bmx` - asset manager | Generic Load/Warn/Error trace family for image / pixmap / sound / anim-image / font; icon dir; message-box chrome; the 6 `incbin::Inc/Music/*.ogg` handles | H |
| 251-254 | `TIni.bmx` (tail) + stray | `Value=`, `000000`, `666666`, `: changing formation` | L |
| 255-319 | `TNation.bmx` | Nations.csv load/save, 36 columns, mobile export, flag images, kit-type enum prefix `CKITTYPE_`, `ReorderNations` | H |
| 320-378 | `TClub.bmx` | Clubs.csv load/save, 36 columns, mobile export, `ReorderClubsByName`, stadium upgrade | H |
| 379-393 | `TFixture.bmx` | Fixture display: date format `YY-WW-DDD`, versus/ET/pens/away-goals/aggregate keys, `Bye`, H/A/D/W/L, `CreateReplayFixture:` | H |
| 394-397 | `TMyLocale.bmx` | `GameMedia/Languages/Languages.csv`, `SetCurrentLanguage:` | H |
| 398-510 | `TKeys.bmx` / input names | 113 `key_*` display names, mouse → F12 → punctuation, exact order of BlitzMax `KEY_*` constants | H |
| 511-516 | `TNames.bmx` | Names.csv, per-nation first/last name columns | H |
| 517-586 | **`TBall.bmx` - match engine, ball** | Ball sprites, `ballradius`, `incbin::Inc/Engine.ini` (first read), 16 physics keys, bounce/kick/post sounds, `CreateBall:`, `Kick:`, `NewController:`, keeper parry/dive decisions, kick-type enum, 16 `CBOSSSHOUT_*` keys | H |
| 587-631 | `TMatch.bmx` (part 1 - presentation) | Match fonts, `replaylength`/`gamesecond`/scroll-limit keys, 16 `Other/*.png` HUD icons, crowd/whistle audio, radar, scoreboard labels + greys | H |
| 632-710 | `TMatch.bmx` (part 2 - loop & state) | `SetUpMatch`, `MatchLoop`, memory trace, weather setup, on-screen debug (`FPS:`/`Mem:`), full stats-panel label + colour set, set-piece names, goal/HT/FT, substitution flow, shoot-out, 9 match-state names, `Unpause:` | H |
| 711-751 | `TTactics.bmx` / `TFormation.bmx` | 9 formation-geometry ini keys, side + position name keys, `.tac` file I/O under `EngineMedia\Tactics\`, default `4-4-2.tac`, 11 preset + 3 custom formation names | H |
| 752-850 | `TKit.bmx` / player recolour | 27 `base*` palette keys from Engine.ini, `Player.png`, `BOOTCOL:`, 19 hard-coded hair/skin/boot hexes, `CHAIR_*` (7) + `CSKIN_*` (5) enums, 22 kit-style tokens, 15 `Player_<Style>.png` templates | H |
| 851-856 | `TTeam.bmx` | `CreateSquad:`, `Create Players`, `ForcePositionReset`, `GetSetPieceTakers`, `CheckComManagement` | H |
| 857-1021 | `TOptions.bmx` | `Settings/Options.ini`: default-writer literals (`k_Up=38` …), then 45 `key=` save prefixes, then 45 bare load keys; joystick/key capture UI | H |
| 1022-1091 | `TPitch.bmx` | 20 pitch/goal/ad sprites, 11 pitch-geometry ini keys, 22 stadium tile sprites, crowd tint colours, dugout/boss/photographer, 4 cameraman ini keys | H |
| 1092-1235 | **`TPlayer.bmx` - match player** | 10 sprite ini keys, overlay sprites, 24 player-physics ini keys, player sounds, `CreatePlayerSimple:` + 8-field skill dump, keeper AI (`KeeperDive:`, catch/jump), foul & card decision traces, 16 kick/tackle action names, 30 animation-state names, `CBOSS*` shout keys | H |
| 1236-1314 | `TReport.bmx` / `TNews.bmx` | `RecordPlayerStats`, 8 `CREPORT_COACH*`, 15 `CNEWS_*` match/debut items, 26 `CREPORT_BOSS*`/`CREPORT_GOOD*`/`CREPORT_RIVALS*`, drug-test outcomes, 7 rating-category display names | H |
| 1315-1320 | `TReplay.bmx` | `.rep`, magic `newstarsoccerfivereplayfile`, `zipe::` (zip-stream URL scheme) | H |
| 1321-1325 | `TWeather.bmx` | Rain/Snow sprites + rain loop, `SetWeatherTimes s=` | H |
| 1326-1332 | Graphics/app boot (tail) | `SetVirtualResolution(800, 600)`, `New Star Games 2019`, 5 brand colours | H |
| 1333-1379 | `TLifestyle.bmx` / shop catalogue | `sla_Thousand`/`Million`, 10 `property_*`, 10 `vehicle_*`, 10 `item_*`, 10 `sponsor_*` | H |
| 1380-1381 | net/stream helpers | `STREAM ERROR`, URL reserved-character set | M |
| 1382-1400 | `TContinent.bmx` | Continents.csv (5 cols) + mobile export; then 8 hard-coded Euro/WCQ competition abbreviations | H |
| 1401-1500 | **`TCompetition.bmx` - the season engine** | Competitions.csv (18 cols) + mobile export, `SetUpCompetitionsAll`, `CreateFixtureListLeague:`, `CreateFixtureListKO:`, locale/based/comptype/legs enum tables, ID inflate/compress, 4 international `venues*.txt`, `PlayFixtures`, `DoPromotionPlaces:`, 4 promotion-integrity warnings | H |
| 1501-1552 | `TScreen.bmx` - GUI framework base | Global BGs, cursor, click/select SFX, both TTFs + `incbin::Inc/`, `Create Screen:`, help system, `msgscreen` + 7 widgets, loading bar, tip panel, list/combo art, `SelectItem:`, `btn_`/`lbl_` ID prefixes, `CreateScreensAll:` | H |
| 1553-1557 | Screen: language select | `Tag_NationId`, `Tag_Language` (real Languages.csv row keys) | H |
| 1558-1613 | Screen: `mainmenu` | 10 icons, New/Load Career, Replays, Options, Quit, load-game & load-replay tables, social panel, `incbin::Inc/Credits.txt` | H |
| 1614-1623 | `TSaveGame.bmx` (file layer) | `.sav`, `::newstarsoccerfivesavefile::<sha256>`, `#VERSION:`, `.bak`, corrupt/restore/delete messages | H |
| 1624-1758 | Screen: `options` | Full options UI: language, resolution, difficulty, music, SFX, tooltips, distance units, currency, save name, match length/speed, radar, cam, FX, boss shouts, highlight ball, show energy, lock kicking, request FK/corners | H |
| 1759-1839 | Screen: `controls` (+ simple/advanced) | Joystick/key art, 10 binding rows, scheme toggle, 12+12 tutorial slots | H |
| 1840-1883 | Screen: `newplayer` | Name/nationality/league/position/side/skin/hair/kit, trial messages | H |
| 1884-1906 | Screen: `createaccount` | Email/password/activation-key form (online account, legacy) | H |
| 1907-1922 | Screen: difficulty select | Easy/Normal/Hard panels | H |
| 1923-1949 | `TPromotionPlace.bmx` + `TLeagueTable.bmx` | PromotionPlaces.csv (3 cols) + mobile export, 9 special promotion-rule IDs `100:`-`108:`, 9 league-table columns | H |
| 1950-1956 | `TStadium.bmx` | Stadiums.csv (5 cols). **File is absent from the shipped install → editor-only / dev-only** | H |
| 1957-1985 | Screen: `editmenu` - **data editor root** | `Data Editor`, `New Star Games 2010`, 6 section buttons, Test Data, Save, Save For Mobile | H |
| 1986-2005 | Screen: `editcontinents` | Continent fields + member list | H |
| 2006-2051 | Screen: `nations` (edit) | Nation fields, rivals, climate, skins, stadium, 4 kit slots, `Interface/s` prefix for small kit previews | H |
| 2052-2090 | Screens: `clubs` + `editclubs` | Club table, locale/based/competition filters, new/delete, name toggle | H |
| 2091-2186 | Screens: `continentalcomps`/`competitions` + `editcompetition` | Competition grid (14 `tla_*` columns), filters, duplicate/inflate/compress, full competition edit form, promotion-place sub-editor | H |
| 2187-2193 | Screen: `promotions` | Two-comp promote/relegate transfer UI | H |
| 2194-2212 | Screen: Continental Competitions | Continent → comp → qualifier club management | H |
| 2213-2234 | Screen: `editkits` | 4 kit slots, kit-type combo, shirt1/shirt2/shorts/socks colour pickers | H |
| 2235-2262 | Screen: `calendar` | Week grid, 7 day keys, 12 month keys, `YYYY`/`WWWW`/`DDDD` format tokens | H |
| 2263-2302 | Screens: `testmenu`, `tournaments`, `fixtures` | Dev harness: simulate fixtures/tournaments, league table + fixture tables, group/round steppers | H |
| 2303-2355 | Screen: `gamemenu` - career shell | Persistent top/bottom chrome: bank, cash, energy, achievements bar, year/week, 5 nav buttons, next-opponent, play button; `SeasonReview`, `SeasonStart:` | H |
| 2356-2402 | Screen: `home` | Career hub: profile, rating, value, fame, contract, finances, stats, happiness/skills/lifestyle bars, 7 `CHELP_*` | H |
| 2403-2466 | Screen: `abilities` (training) | 7 trainable attributes × (label, bar, number, tooltip, button); 10 derived ratings bars; no-training messages | H |
| 2467-2521 | Screen: `relationships` | Boss/Team/Fans/Friends/Girlfriend/Sponsors rows + casino/racing/end-relationship side buttons | H |
| 2522-2576 | Screen: `shop` | Items/Vehicles/Property tabs, 3×10 buy buttons, cash/energy messages | H |
| 2577-2604 | Screen: `bootshop` | Match-prep boot shop, 10 boot buttons, stat deltas, durability | H |
| 2605-2631 | Screen: competitions/fixtures browser | World/Country/Club levels, round & group steppers, club + league fixture tables, standings | H |
| 2632-2646 | Screen: `kits` | Pre-match kit clash resolution, 2 controllers | H |
| 2647-2664 | Screens: `matchpaused`, `skiptime` | Pause menu (continue/replay/formation/tactics/skip), 4 skip-time end conditions | H |
| 2665-2696 | Screen: `formation` | Tactics pitch, position change, ask-boss flow, captaincy gain/loss messages | H |
| 2697-2729 | Screen: `stats` | Club + international stat tables, history, filters, 11 derived stat rows | H |
| 2730-2786 | Screen: `contractoffer` | Current vs new contract side-by-side (wage, goal/assist/clean-sheet bonus, expiry, signing fee) | H |
| 2787-2859 | Screen: `mycontract` (transfers) | Offers list, transfer/loan request, desired-transfer filters, interested clubs, window logic, 5 offer slots | H |
| 2860-2875 | Screen: `dilemma` | Two-choice relationship dilemma + 10 venue backdrops | H |
| 2876-2899 | Screen: `finances` | In/Out ledger, sponsors table, lifestyle table with sell, weekly balance | H |
| 2900-2907 | Screen: `newspaper` | Newspaper background, photo, 5 `Hands_*` variants, star rating | H |
| 2908-2914 | Screen: `achievements` | Achievement list table | H |
| 2915-2954 | Screen: `worldmap` | World map JPGs, blob markers, fixture info, stadium capacity, travel time (6 bands), buy games/music/movies | H |
| 2955-3026 | Screen: `matchprep` | Kit bag: enhancers, booze, shin pads, boots, painkillers, NRG; selection status reasons (12); skip match | H |
| 3027-3050 | Screen: `seasonreview` | Season stats + tournaments/awards tables, 3 player-of-the-year awards, retirement/aging messages | H |
| 3051-3065 | Screen: `webpage` | In-game web page, headline, league table, Twitter/Facebook share URLs, `#NSS5` hashtag | H |
| 3066-3082 | Screens: `reportphysio`, `reportboss` | Physio + boss/coach match report panels | H |
| 3083-3097 | `TProfile.bmx` + `TSaveGame.bmx` | Online profile hash, `LoadGame`/`SaveGame`, `#VERSION:1.10`, GC/bank capacity trace, save-file magic | H |
| 3098-3118 | `TGame.bmx` - fixture flow | `GetNextFixture`, `PlayNextFixture:`, `FixturePlayed:`, cup/league winner news, interview trigger, selection form fields, `NextPlayButton`/`SetPlayButtonIcon` | H |
| 3119-3158 | `TGame.bmx` - `RandomIncident` | Booze consequences ×5, gambling addiction ×4, girlfriend events, lost item/vehicle, club boost/crisis, 4 energy boosts, 6 relationship requests | H |
| 3159-3171 | `TGame.bmx` - token table | `CTIP_`, 13 `$…` substitution tokens, `YYYY-WWW`, anti-cheat salt `dontcheatatnss5` + `CMESSAGE_INVALIDSKILLSHASH` | H |
| 3172-3202 | `TGame.bmx` - relationships/health | 7 `CRELATION_*: ` deltas, `UpdateEnergy:`, `UpdateHealth`, `DoInjury`, 3 physio reports, sponsor lifecycle, loan lifecycle | H |
| 3203-3206 | `TAchievements` check | `CheckAchievement:`, `Bugged Achievement`, `ACHIEVEMENT_`/`CACHIEVEMENT_` prefixes | H |
| 3207-3222 | `TStats.bmx` | Stats pitch + heatmap art, 11 `rating*` Engine.ini keys, `TStats_Team.WriteData`, `THistory.WriteData` | H |
| 3223-3229 | `TScreenMessage.bmx` / alerts | In-match star/skill FX, `ClearAll`, `ClearAlerts`, `CreateAlert:`, speech bubble | H |
| 3230-3269 | `TContractOffer.bmx` + transfer logic | 7 offer fields, negotiation, transfer-window checks, valuation trace (`>>> avgrating =` …), first/same/new club outcomes, B-team promotion | H |
| 3270-3300 | Screen: `casino` | 7 chip denominations, 3 game buttons, 7 stake buttons | H |
| 3301-3335 | Screen: `roulette` | Odd/Even/Red/Black/1-18/19-36 bets, wheel art, 3 SFX | H |
| 3336-3360 | Screen: `blackjack` | Dealer/player hands, hit/hold, bust/blackjack/5-card-trick/tie, card art `<rank>_<suit>.png` | H |
| 3361-3382 | Screens: `slots`, `pairs` | Reel strip, 8 fruit symbols, pairs instructions | H |
| 3383-3394 | `pairs` minigame logic | `NewButtonPositions`, `UpdateFaces`, 6 `CDILEMMA_*`, `Fail!`, 5 BG variants | H |
| 3395-3410 | Higher/Lower negotiation minigame | Player cards, higher/lower buttons, `CMESSAGE_CONTRACTINCREASE` | H |
| 3411-3419 | Screen: `interview` | Interview background, beep, `CLICHE_` prefix | H |
| 3420-3489 | **`TTraining.bmx`** | Stopwatch/bird/clap SFX, trial instructions, 7 `SetUpTraining_<Skill>` routines with per-skill `CTRAINING_*` + `CMESSAGE_TRIAL*`, cones/dummies/poles/zone/target props | H |
| 3490-3513 | Replay + in-match control overlay | `(F4)`, replay panel, kick-to-continue, 12 `controls_*` keys, 7 `replay_*` keys | H |
| 3514-3603 | **`TStable.bmx` - horse racing** | Track art, 6 posts, 4 horses × 6 jockeys, stable UI, `GameMedia\Data\Horse.ini` name list, buy/sell/treat/race, 17 stable messages | H |
| 3604-3608 | `TAchievement.bmx` | Achievements.csv (`id`, `sortindex`), `date` | H |
| 3609-3619 | Steam integration | `Steam must be running to play this game.`, `OpenSteam() failed.`, online/offline states, leaderboard find/upload (`Player Value`) | H |
| 3620-3629 | `brl.*` / `ZipEngine` module | Month table `JANFEB…`, TZipReader errors, `zipe` URL scheme | H |
| 3630-3637 | Stream driver strings | `Experimental Code Called`, read/write/tell/seek/close | H |
| 3638-3656 | **`Font Machine 1.5.1`** third-party module | Bitmap-font `.fmf` loader: SHADOW/BORDER/FACE layers, PNG errors | H |
| 3657-3669 | BlitzMax reflection (`brl.reflection`) | Byte/Short/Long/Float/Double/Object/String type names, meta-data errors | H |
| 3670-3784 | OpenAL binding (`pub.openal`) | Error enums, buffer/source logging, 115 `alc*`/`al*` entry points | H |
| 3785-3795 | FreeAudio driver | DirectSound / Multimedia backends | H |
| 3796-3803 | PNG loader + text encodings | `1.2.12`, `PNG ERROR`, latin1/utf8/utf16be/utf16le | H |
| 3804-3811 | HTTP/socket + endian + incbin | `GET `, `Host: `, `HTTP/1.0`, bigendian/littleendian | H |
| 3812-3872 | Max2D drivers | DirectX9, DirectX7, OpenGL - surface/texture/clipplane errors, `d3d9`/`ddraw`/`dsound` DLL + entry-point names | H |
| 3873-3888 | `brl.blitzfont`, `brl.stream` | `blitzfont.bin`, date formats, stream read/write errors | H |
| 3889-3931 | BlitzMax event names | 37 `AppSuspend`…`UserEvent` event ID names + formatting fragments | H |
| 3932-3936 | BlitzMax runtime exceptions | Null object, abstract method, uninitialised function pointer, array bounds, EOF | H |
| 3937-3955 | JPEG tables / charsets / noise | Huffman symbol tables, ASCII ranges, `BlitzMax GLGraphics` | H |

---

## 3. Complete list - strings ending in `:` (trace / debug labels)

The task brief cites **85** debug labels. The dump actually contains **168** colon-terminated
strings, **163** of them in the game region (before line 3609). **UNCERTAIN:** the "85" figure
probably counted only the strict `Identifier:` form with no trailing space and no spaces inside
(102 by that filter, of which 97 are in the game region). All 168 are listed below so nothing
is lost. `Kind` legend: **FN** = a real function/method name; **FLD** = a field-value dump
prefix; **MSG** = an error/status prefix; **ETC** = enum/URL/other.

| # | Line | String | Kind | Owning module (§2) |
|---|---|---|---|---|
| 1 | 222 | `Could not open file: ` | MSG | TMedia |
| 2 | 223 | `Could not load variable: ` | MSG | TMedia |
| 3 | 224 | `Load variable: ` | MSG | TMedia |
| 4 | 225 | `Loading image: ` | MSG | TMedia |
| 5 | 226 | `WARNING! >>>>>>>>>>>> Cannot see image: ` | MSG | TMedia |
| 6 | 228 | `ERROR! >>>>>>>>>>>>>> Image could not be loaded: ` | MSG | TMedia |
| 7 | 229 | `Loading pixmap: ` | MSG | TMedia |
| 8 | 230 | `WARNING! >>>>>>>>>>>> Cannot see pixmap: ` | MSG | TMedia |
| 9 | 232 | `ERROR! >>>>>>>>>>>>>> Pixmap could not be loaded: ` | MSG | TMedia |
| 10 | 233 | `Loading sound: ` | MSG | TMedia |
| 11 | 234 | `WARNING! >>>>>>>>>>>> Cannot see sound: ` | MSG | TMedia |
| 12 | 236 | `ERROR! >>>>>>>>>>>>>> Sound could not be loaded: ` | MSG | TMedia |
| 13 | 237 | `Loading anim image: ` | MSG | TMedia |
| 14 | 238 | `WARNING! >>>>>>>>>>>> Cannot see anim image: ` | MSG | TMedia |
| 15 | 240 | `ERROR! >>>>>>>>>>>>>> Anim Image could not be loaded: ` | MSG | TMedia |
| 16 | 241 | `Loading font: ` | MSG | TMedia |
| 17 | 242 | `WARNING! >>>>>>>>>>>> Cannot see font: ` | MSG | TMedia |
| 18 | 244 | `ERROR! >>>>>>>>>>>>>> Font could not be loaded: ` | MSG | TMedia |
| 19 | 260 | `utf8::` | ETC | TNation (stream URL scheme) |
| 20 | 263 | `Nations:` | FLD | TNation.LoadData |
| 21 | 323 | `Clubs:` | FLD | TClub.LoadData |
| 22 | 377 | `Club stadium upgrade:` | FLD | TClub |
| 23 | 393 | `CreateReplayFixture: ` | **FN** | TFixture |
| 24 | 396 | `SetCurrentLanguage:` | **FN** | TMyLocale |
| 25 | 397 | `Language set to: ` | FLD | TMyLocale |
| 26 | 511 | `TNames.SetUp: ` | **FN** | TNames |
| 27 | 542 | `CreateBall:` | **FN** | TBall |
| 28 | 546 | `Kick:` | **FN** | TBall |
| 29 | 551 | `NewController:` | **FN** | TBall |
| 30 | 556 | `Parry: v=` | FLD | TBall (keeper) |
| 31 | 557 | `Dive: Tip left` | FLD | TBall (keeper) |
| 32 | 558 | `Dive: Tip right` | FLD | TBall (keeper) |
| 33 | 559 | `Parry: Punch` | FLD | TBall (keeper) |
| 34 | 560 | `Parry: Tip over` | FLD | TBall (keeper) |
| 35 | 562 | `   Team:` | FLD | TBall |
| 36 | 563 | `SetUpSetPieceBall:` | **FN** | TBall |
| 37 | 634 | `FixtureType:` | FLD | TMatch |
| 38 | 643 | `Rating: ` | FLD | TMatch (debug HUD) |
| 39 | 644 | `FPS: ` | FLD | TMatch (debug HUD) |
| 40 | 645 | `Time: ` | FLD | TMatch (debug HUD) |
| 41 | 646 | `Mem: ` | FLD | TMatch (debug HUD) |
| 42 | 673 | `SetUpSetPiece: ` | **FN** | TMatch |
| 43 | 689 | `MySquad:` | FLD | TMatch |
| 44 | 690 | `List:` | FLD | TMatch |
| 45 | 696 | ` att:` | FLD | TMatch |
| 46 | 697 | `CheckShootOutComplete:` | **FN** | TMatch |
| 47 | 698 | `fixture.penscore1:` | FLD | TMatch |
| 48 | 699 | `fixture.penscore2:` | FLD | TMatch |
| 49 | 709 | `Unpause:` | **FN** | TMatch |
| 50 | 731 | `Loading Tactics:` | **FN** | TTactics |
| 51 | 735 | `Cannot find tactics: ` | MSG | TTactics |
| 52 | 736 | `Saving Tactics:` | **FN** | TTactics |
| 53 | 737 | `Cannot save tactics: ` | MSG | TTactics |
| 54 | 779 | `BOOTCOL:` | FLD | TKit |
| 55 | 806 | `CHAIR_UNKNOWN:` | ETC | TKit (enum fallback) |
| 56 | 812 | `CSKIN_UNKNOWN:` | ETC | TKit (enum fallback) |
| 57 | 852 | `CreateSquad:` | **FN** | TTeam |
| 58 | 859 | `Error OPTIONS: Unable to create an options file:` | MSG | TOptions |
| 59 | 1102 | `Adding:` | FLD | TPlayer |
| 60 | 1136 | `CreatePlayerSimple:` | **FN** | TPlayer |
| 61 | 1137 | ` Name:` | FLD | TPlayer |
| 62 | 1138 | ` Sel:` | FLD | TPlayer |
| 63 | 1139 | `Player:` | FLD | TPlayer |
| 64 | 1140 | `mypace:` | FLD | TPlayer |
| 65 | 1141 | `mydribbling:` | FLD | TPlayer |
| 66 | 1142 | `mytackling:` | FLD | TPlayer |
| 67 | 1143 | `mypassing:` | FLD | TPlayer |
| 68 | 1144 | `myheading:` | FLD | TPlayer |
| 69 | 1145 | `myshooting:` | FLD | TPlayer |
| 70 | 1146 | `myflair:` | FLD | TPlayer |
| 71 | 1147 | `mygoalkeeping:` | FLD | TPlayer |
| 72 | 1148 | ` Im:` | FLD | TPlayer |
| 73 | 1155 | `KeeperDive:` | **FN** | TPlayer |
| 74 | 1168 | `Yellows:` | FLD | TPlayer |
| 75 | 1187 | `CBUTTON_SHOOT dir:` | FLD | TPlayer |
| 76 | 1188 | `CBUTTON_PASS dir:` | FLD | TPlayer |
| 77 | 1189 | `CBUTTON_LOB dir:` | FLD | TPlayer |
| 78 | 1213 | `Commiserate1:ScratchHead` | ETC | TPlayer (anim name) |
| 79 | 1214 | `Commiserate1:FallOnFace` | ETC | TPlayer (anim name) |
| 80 | 1215 | `Commiserate1:FallOnKnees` | ETC | TPlayer (anim name) |
| 81 | 1216 | `Commiserate1:HoldHead` | ETC | TPlayer (anim name) |
| 82 | 1237 | `Player Found: ` | FLD | TReport |
| 83 | 1248 | `No stats:` | MSG | TReport |
| 84 | 1266 | `WinningTeam:` | FLD | TReport |
| 85 | 1267 | `MyTeam:` | FLD | TReport |
| 86 | 1318 | `::newstarsoccerfivereplayfile` | ETC | TReplay (magic) |
| 87 | 1319 | `zipe::` | ETC | TReplay (stream URL) |
| 88 | 1320 | `Could not load:` | MSG | TReplay |
| 89 | 1324 | `  f=` *(not colon - listed for context)* | FLD | TWeather |
| 90 | 1325 | `SetWeatherTimes s=` *(context)* | **FN** | TWeather |
| 91 | 1385 | `Continents:` | FLD | TContinent.LoadData |
| 92 | 1404 | `Competitions:` | FLD | TCompetition.LoadData |
| 93 | 1440 | `gameyear: ` | FLD | TCompetition |
| 94 | 1442 | `SetUpCompetition: ` | **FN** | TCompetition |
| 95 | 1443 | `CreateTeamPool: ` | **FN** | TCompetition |
| 96 | 1444 | `PopulateTeamPool:` | **FN** | TCompetition |
| 97 | 1445 | `CreateFixtureListLeague:` | **FN** | TCompetition |
| 98 | 1446 | `CreateFixtureListKO:` | **FN** | TCompetition |
| 99 | 1448 | `Clash: $` | MSG | TCompetition |
| 100 | 1472 | `GetNoofTeamsInRound: ` | **FN** | TCompetition |
| 101 | 1473 | ` TeamCount: ` | FLD | TCompetition |
| 102 | 1474 | `IsComplete: ` | **FN** | TCompetition |
| 103 | 1485 | `IsCupFinal:` | **FN** | TCompetition |
| 104 | 1488 | `DoPromotionPlaces:` | **FN** | TCompetition |
| 105 | 1489 | ` PromotionToId:` | FLD | TCompetition |
| 106 | 1490 | ` Place: ` | FLD | TCompetition |
| 107 | 1491 | `Could not promote to competition! Comp: ` | MSG | TCompetition |
| 108 | 1492 | `Promoting to:` | FLD | TCompetition |
| 109 | 1497 | `WARNING! Number of teams changed in: ` | MSG | TCompetition |
| 110 | 1499 | `WARNING! Promotion place errors in competition(s): ` | MSG | TCompetition |
| 111 | 1500 | `WARNING! Promotion place exceeds number of teams in competition: ` | MSG | TCompetition |
| 112 | 1508 | `Create Screen:` | **FN** | TScreen |
| 113 | 1512 | `offsetX:` | FLD | TScreen |
| 114 | 1513 | `offsetY:` | FLD | TScreen |
| 115 | 1517 | `SetActive:` | **FN** | TScreen |
| 116 | 1539 | `SelectItem:` | **FN** | TScreen (list widget) |
| 117 | 1551 | `CreateScreensAll:` | **FN** | TScreen |
| 118 | 1552 | `ScreensAllCreated:` | **FN** | TScreen |
| 119 | 1557 | `ButtonLanguage:` | **FN** | Screen: language select |
| 120 | 1616 | `#VERSION:` | ETC | TSaveGame |
| 121 | 1948 | `Could not find id:` | MSG | TLeagueTable |
| 122 | 2209 | `ButtonEditPlaceComp:` | **FN** | Editor: continental comps |
| 123 | 2210 | `ButtonEditClub:` | **FN** | Editor: continental comps |
| 124 | 2212 | `ComboClub:` | **FN** | Editor: continental comps |
| 125 | 2301 | `continentid:` | FLD | Screen: fixtures (test) |
| 126 | 2302 | `nationid:` | FLD | Screen: fixtures (test) |
| 127 | 2351 | `week:` | FLD | Screen: gamemenu |
| 128 | 2354 | `SeasonStart:` | **FN** | Screen: gamemenu |
| 129 | 2355 | `compfixdate:` | FLD | Screen: gamemenu |
| 130 | 2684 | `CheckPosition:` | **FN** | Screen: formation |
| 131 | 2685 | `PosOK:` | FLD | Screen: formation |
| 132 | 2686 | `newstarselno:` | FLD | Screen: formation |
| 133 | 2914 | `Achievements:` | FLD | Screen: achievements |
| 134 | 2940 | `Team1:` | FLD | Screen: worldmap |
| 135 | 2941 | `Team2:` | FLD | Screen: worldmap |
| 136 | 2947 | `Distance:` | FLD | Screen: worldmap |
| 137 | 3036 | `SetUpScreen:` | **FN** | Screen: seasonreview |
| 138 | 3044 | `My Age:` | FLD | Screen: seasonreview |
| 139 | 3045 | `Year:` | FLD | Screen: seasonreview |
| 140 | 3059 | `Temp headline: ` | FLD | Screen: webpage |
| 141 | 3060 | `Player webheadline: ` | FLD | Screen: webpage |
| 142 | 3080 | `Drugs:` | FLD | Screen: reportboss |
| 143 | 3086 | `Saving play button type: ` | FLD | TProfile/TSaveGame |
| 144 | 3098 | `Play:` | FLD | TGame |
| 145 | 3099 | `Date:` | FLD | TGame |
| 146 | 3101 | ` Date:` | FLD | TGame |
| 147 | 3102 | `PlayNextFixture:` | **FN** | TGame |
| 148 | 3103 | `FixturePlayed:` | **FN** | TGame |
| 149 | 3111 | `clubform:` | FLD | TGame |
| 150 | 3112 | `intform:` | FLD | TGame |
| 151 | 3113 | `lastmatch:` | FLD | TGame |
| 152 | 3114 | `rating:` | FLD | TGame |
| 153 | 3115 | `avgform:` | FLD | TGame |
| 154 | 3116 | `relationship:` | FLD | TGame |
| 155 | 3172 | `CRELATION_BOSS: ` | FLD | TGame |
| 156 | 3173 | `CRELATION_TEAM: ` | FLD | TGame |
| 157 | 3174 | `CRELATION_FANS: ` | FLD | TGame |
| 158 | 3175 | `CRELATION_FRIENDS: ` | FLD | TGame |
| 159 | 3176 | `CRELATION_GIRLFRIEND: ` | FLD | TGame |
| 160 | 3179 | `CRELATION_SPONSORS: ` | FLD | TGame |
| 161 | 3180 | `CRELATION_FAME: ` | FLD | TGame |
| 162 | 3184 | `UpdateEnergy:` | **FN** | TGame |
| 163 | 3203 | `CheckAchievement:` | **FN** | TAchievements |
| 164 | 3227 | `CreateAlert:` | **FN** | TScreenMessage |
| 165 | 3249 | `mystatus:` | FLD | TContractOffer |
| 166 | 3255 | `Value:` | FLD | TContractOffer |
| 167 | 3256 | `Status:` | FLD | TContractOffer |
| 168 | 3257 | `ClubStrength:` | FLD | TContractOffer |
| 169 | 3377 | `Fruit: ` | FLD | Screen: slots |
| 170 | 3481 | `kicktype:` | FLD | TTraining |
| 171 | 3560 | `HorseCount:` | FLD | TStable |
| 172 | 3601 | `Total Horses:` | FLD | TStable |
| 173 | 3602 | `Total Runners:` | FLD | TStable |
| 174 | 3619 | `Post end: ` | FLD | Steam/leaderboard |
| - | 3621 | `TZipReader.getFileInfo(): Invalid index ` | MSG | *(BlitzMax runtime)* |
| - | 3649 | `…The exception source is: ` | MSG | *(Font Machine)* |
| - | 3677 | `OpenAL Error: ` | MSG | *(pub.openal)* |
| - | 3807 | `Host: ` | MSG | *(brl.httpstream)* |
| - | 3842 | `UNKNOWN:` | ETC | *(DirectX7 driver)* |
| - | 3853 | `CreateSurface failed:` | MSG | *(DirectX7 driver)* |
| - | 3877-3879 | `http:` `file:` `https:` | ETC | *(brl.stream schemes)* |

### 3.1 Non-colon function names in the same trace family

These are `DebugLog`/`Print` argument constants that are unmistakably function names but
lack a colon. Include them in the function-name index:

`ReorderNations` (317) · `GetFixtureList:Nation` (319) · `ReorderClubsByName` (376) ·
`HitPost` (549) · `HitNet` (550) · `SetUpMatch` (632) · `SetUpWeatherConditions` (640) ·
`MatchLoop` (642) · `GoalScored` (680) · `PauseSounds` (686) · `ResumeSounds` (687) ·
`DoYourSubstitutionOn` (688) · `DoYourSubstitutionOff` (691) · `SkipTime` (695) ·
`Create Players` (853) · `ForcePositionReset` (854) · `GetSetPieceTakers` (855) ·
`CheckComManagement` (856) · `WaitForJoyRelease` (869) · `WriteNewOptionsIni` (870) ·
`SaveOptions` (921) · `LoadOptions` (971) · `NewButtonKick` (1022) · `CheckKeeperSave` (1172) ·
`SetTunnelPositionAll` (1191) · `DoAnimJump/Dive/Slide/Fall/Kick` (1218-1222) ·
`ResetAnimationsAll` (1226) · `RecordPlayerStats` (1236) · `SetWeatherTimes` (1325) ·
`SetUpCompetitionsAll` (1439) · `Creating Fixtures` (1441) ·
`Test_UpdateNoofTeamsInLeagues` (1493) · `Test_CheckNoofTeamsInLeagues` (1494) ·
`ValidatePromotionPlacesAll` (1498) · `PlayFixtures` (1487) · `UpdateOffset` (1511) ·
`ResetScreens` (1516) · `DoHelp` (1532) · `ButtonHelpOk` (1535) · `SelectItemByLetter` (1540) ·
`LoadCredits` (1608) · `CreditsLoaded` (1611) · `UpdateReplayTable` (1622) · `ResetScreen` (1758) ·
`ComboLocale` (2080) · `ComboBased` (2081) · `ComboLevel` (2295) · `ComboCompetition` (2296) ·
`ComboClub` (2621) · `RefreshClubCombo` (2211) · `SetUpFixturesTable` (2630) ·
`UpdateTitlePanel` (2346) · `SeasonReview` (2353) ·
`TScreen_Formation.SetUpScreen` (2679) · `UpdateStakeCurrency` (3299) ·
`Updated Details/Transfer Status/Label/Buttons` (2813-2816) ·
`UpdateClubsInterestedLabel` (2817) · `UpdateDesiredCombos` (2826) · `CombosDone` (2827) ·
`ComboContinent` (2838) · `ComboNation` (2839) · `UpdateOfferButtons` (2845) ·
`TScreen_SeasonReview.ButtonPlay` (3043) · `LoadGame` (3087) · `SaveGame` (3089) ·
`Saving` (3092) · `SaveFile` (3096) · `GetNextFixture` (3100) ·
`UpdateSelectedForMatch` (3110) · `NextPlayButton` (3117) · `SetPlayButtonIcon` (3118) ·
`RandomIncident` (3119) · `UpdateHealth` (3185) · `DoInjury` (3186) ·
`TStats_Team.WriteData` (3221) · `THistory.WriteData` (3222) ·
`TScreenMessage.ClearAll` (3225) · `TScreenMessage.ClearAlerts` (3226) ·
`TContractOffer.LoadData` (3230) · `CheckTransferWindow` (3241) ·
`Clear contract offer list` (3246) · `UpdateInterestedClubs` (3248) ·
`GetClubsInterestedInLoan` (3250) · `CheckPromoteFromBTeam` (3265) ·
`ButtonQuit` (3348) · `NewButtonPositions` (3383) · `UpdateFaces` (3384) ·
`SetUpTraining_Pace/Dribbling/Passing/Shooting/Heading/Flair/Tackling`
(3436, 3445, 3450, 3455, 3462, 3468, 3472) · `ClearUpTraining` (3480) ·
`LoadHorseData` (3558) · `SetUpHorsesForSale` (3561) · `SetUpNextRace` (3563) ·
`RefreshRunners` (3567) · `DoRace` (3569) · `SelectRunners` (3599) ·
`TNation.LoadData` (262) · `TClub.LoadData` (322) · `TContinent.LoadData` (1384) ·
`TCompetition.LoadData` (1403) · `TPromotionPlace.LoadData` (1925) ·
`TAchievement.LoadData` (3606) · `TProfile.LoadData` (3085)

---

## 4. Complete media path index

### 4.1 `Inc/` - compiled-in (`Incbin`) resources

| Line | Path | Notes |
|---|---|---|
| 158 | `Inc/Credits.txt` | Loaded via `incbin::Inc/Credits.txt` (1609) |
| 159 | `Inc/Player.png` | Master player sprite sheet, 128×128 × 192 frames |
| 162 | `Inc/TCCEB.TTF` | Latin UI font |
| 163 | `Inc/RUSSIAN.TTF` | Cyrillic UI font |
| 164 | `Inc/Music/Intro.ogg` | |
| 165 | `Inc/Music/Main.ogg` | |
| 166 | `Inc/Music/Training_Loop1.ogg` | |
| 167 | `Inc/Music/Training_Loop2.ogg` | |
| 168 | `Inc/Music/Shopping_Loop1.ogg` | |
| 169 | `Inc/Music/Casino_Loop1.ogg` | |
| 170 | `Inc/Engine.ini` | 2,422 bytes at file offset `0x837C34` |

### 4.2 `incbin::` URL strings (the runtime handles)

| Line | String |
|---|---|
| 221 | `incbin` (scheme registration) |
| 245 | `incbin::Inc/Music/Main.ogg` |
| 246 | `incbin::Inc/Music/Training_Loop1.ogg` |
| 247 | `incbin::Inc/Music/Training_Loop2.ogg` |
| 248 | `incbin::Inc/Music/Shopping_Loop1.ogg` |
| 249 | `incbin::Inc/Music/Casino_Loop1.ogg` |
| 250 | `incbin::Inc/Music/Intro.ogg` |
| 522 | `incbin::Inc/Engine.ini` |
| 1507 | `incbin::Inc/` (prefix - concatenated with `TCCEB.TTF` / `RUSSIAN.TTF` at 1505-1506) |
| 1609 | `incbin::Inc/Credits.txt` |
| 3811 | `incbin` (brl.stream driver registration) |

**Note:** `Inc/Player.png` (159) has **no** `incbin::` URL of its own. It is opened as
`Player.png` (778) - the `TKit` recolour code prefixes it. **UNCERTAIN:** whether the prefix
used is `incbin::Inc/` (1507) or a filesystem path.

### 4.3 `EngineMedia/` - match-engine assets (110 paths)

All verified present on disk unless noted.

**Ball** (517-520): `Match/Ball/Ball.png`, `Shadow.png`, `Marker.png`, `TenYards.png`

**Fonts** (587-588): `Fonts/MatchFontM.fmf`, `Fonts/MatchFontL.fmf` *(Font Machine 1.5.1 format)*

**Match/Other** (594-609, 622, 3223, 3229, 3429-3431):
`Trophy.png`, `YellowCard.png`, `SecondYellowCard.png`, `RedCard.png`, `Injury.png`,
`Substitution.png`, `SubOnUp.png`, `SubOnDown.png`, `SubOff.png`, `BoozeFace.png`,
`SadFace.png`, `SickFace.png`, `TiredFace.png`, `EnergyBack.png`, `EnergyBackRed.png`,
`Energy.png`, `RadarPlayer.png`, `Star.png`, `Speech.png`, `BallIcon.png`, `GoalIcon.png`,
`StopWatch.png`

**Match/Player** (637-638, 1083, 1103-1107):
`Player.png`, `Keeper.png`, `ArrowGreen.png`, `ArrowYellow.png`, `Highlight.png`,
`OffsideFlag.png`, `Speech.png` - note line 1083 is the backslash form
`EngineMedia\Match\Player\Player.png`

**Match/Pitch** (1023-1041, 1053-1075, 1080, 1084-1085, 1090-1091, 1321, 1323, 3482-3489):
`Pitch1.png`, `Pitch2.png`, `Pitch1b.png`, `Pitch2b.png`, `Pitch3.png`, `Pitch4.png`,
`NSG.png`, `Dugout.png`, `Grass.png`, `Mows.png`, `Mow0.png`, `Mow1.png`, `Goal1.png`,
`Goal1_Net.png`, `Goal1_Shadow.png`, `Goal2.png`, `Goal2_Shadow.png`, `Flag.png`,
`Ads/AdBoard_` *(prefix → `AdBoard_1..N.png`, verified)*,
`StadiumTop.png`, `StadiumBottom.png`, `StadiumSide.png`, `StadiumTunnel.png`,
`StadiumCornerTop.png`, `StadiumCornerBottom.png`, `StadiumRoofTop.png`,
`StadiumRoofBottom.png`, `StadiumTunnelBarrier.png`, `StadiumCornerTopGrass.png`,
`StadiumCornerBottomGrass.png`, `StadiumTopGrass.png`, `StadiumBottomGrass.png`,
`StadiumCornerTopGrass2.png`, `StadiumSideGrass.png`, `StadiumCornerBottomGrass2.png`,
`StadiumTopG.png`, `StadiumBottomG.png`, `StadiumSideG.png`, `StadiumTunnelG.png`,
`StadiumCornerTopG.png`, `StadiumCornerBottomG.png`, `Fans.png`, `Boss.png`, `Patch.png`,
`Photographer.png`, `CameraMan.png`, `Camera.png`, `Rain.png`, `Snow.png`,
`Cones.png`, `Dummies.png`, `Poles.png`, `Zone.png`, `Target.png`

**Match/Sounds** (539-541, 612-621, 1132-1135, 1322, 3224, 3420-3428, 3483, 3486, 3488):
`Bounce.ogg`, `Kick.ogg`, `Post.ogg`, `Whistle.ogg`, `WhistleFinal.ogg`,
`CrowdAmbience.ogg`, `CrowdChant` *(prefix + index + `.ogg`)*, `CrowdGoal.ogg`,
`CrowdOh.ogg`, `CrowdBoo.ogg`, `CrowdBooShort.ogg`, `CrowdCheer.ogg`, `Slide.ogg`,
`Oof.ogg`, `BoozedUp.ogg`, `TrainingError.ogg`, `Rain.ogg`, `Skill.ogg`, `StopWatch.ogg`,
`StopWatchBeep.ogg`, `Bird1.ogg`-`Bird4.ogg`, `TrainingSuccess.ogg`, `TrainingClap.ogg`,
`TrainingReset.ogg`, `ConeHit.ogg`, `PoleBoing.ogg`, `ConeSplit.ogg`

**Tactics** (732-734): `EngineMedia\Tactics\` (dir prefix), `Tactics\` (user dir),
`EngineMedia\Tactics\4-4-2.tac` (default)

### 4.4 `GameMedia/` - game data & UI assets

**Data** (all TAB-separated despite `.csv`):

| Line | Path | On disk? |
|---|---|---|
| 259 | `GameMedia/Data/Nations.csv` | yes |
| 320 | `GameMedia/Data/Clubs.csv` | yes |
| 512 | `GameMedia/Data/Names.csv` | yes |
| 1382 | `GameMedia/Data/Continents.csv` | yes |
| 1401 | `GameMedia/Data/Competitions.csv` | yes |
| 1923 | `GameMedia/Data/PromotionPlaces.csv` | yes |
| 1950 | `GameMedia/Data/Stadiums.csv` | **NO - editor/dev only** |
| 3604 | `GameMedia/Data/Achievements.csv` | yes (UTF-8 BOM) |
| 1481-1484 | `venuesACoN.txt`, `venuesCopa.txt`, `venuesEuros.txt`, `venuesWC.txt` | yes (`nationid,clubid` pairs) |
| 3559 | `GameMedia\Data\Horse.ini` | yes (flat list of horse names) |
| 1391 | `GameMedia/Data/Mobile` (dir) | **NO - created by editor** |
| 312 / 374 / 1392 / 1438 / 1929 | `Mobile/Nations.txt`, `Mobile/Clubs.txt`, `Mobile/Continents.txt`, `Mobile/Competitions.txt`, `Mobile/PromotionPlaces.txt` | **NO - editor export targets** |

**Languages** (394): `GameMedia/Languages/Languages.csv` - TAB-separated, 2,751 tag rows,
columns `Tag en br pt de es fr it pl tr nl` (10 languages). Special rows: `Tag_Language`,
`Tag_NationId`, `Tag_Translator`.

**Sounds** (206-207, 1503-1504, 2731, 2905, 3238, 3412, 3328-3330, 3349, 3365-3367,
3514-3515): `Sounds/Cash.ogg`, `Achievement.ogg`, `Click.ogg`, `Select.ogg`, `Phone.ogg`,
`Newspaper.ogg`, `Signature.ogg`, `Beep.ogg`, `Casino/RouletteLand.ogg`,
`Casino/RouletteHit.ogg`, `Casino/RouletteSpin.ogg`, `Casino/CardFlip.ogg`,
`Casino/SlotsWin.ogg`, `Casino/SlotsArm.ogg`, `Casino/SlotsStop.ogg`,
`Casino/FlashBulb.ogg`, `Casino/Gallop.ogg`
*(Also on disk but not referenced by any dump string: `BDay.ogg`, `Bus.ogg`, `Mobile.ogg`,
`Plane.ogg` - **UNCERTAIN:** probably loaded via a runtime-built path.)*

**Images/Backgrounds** (1501, 1514-1515, 1528, 1985, 2901-2903, 2938-2939, 3051,
3069, 3078, 3411): `MyBg2.png`, `StadiumBG2.jpg`, `StadiumBG.jpg`, `MyBg.png`, `Grass.png`,
`Newspaper.png`, `NewspaperPhoto.png`, `Hands_` (prefix, `_1..5`), `WorldMap2.jpg`,
`WorldMap4.jpg`, `WebPage.png`, `report_physio.png`, `report_boss.png`, `Interview.png`

**Images/Interface** (219-220, 1502, 1536-1538, 1542, 1759-1761, 1876, 2051, 2361,
2665-2667, 2904, 2916, 3207-3208, 860-861): `MessageBg.png`, `MessageLine.png`,
`Cursor.png`, `ListUp.png`, `ListDown.png`, `Combo.png`, `Pointer.png`, `Joystick.png`,
`Joystick2.png`, `Keys.png`, `Player.png`, `s` *(prefix → `sPlayer_*.png`, verified)*,
`Star52.png`, `Star52Grey.png`, `TacticsPitch.png`, `Arrow.png`, `Star128.png`, `Blob.png`,
`StatsPitch.png`, `Heatmap.png`, `Buttons/btn` (prefix), `Buttons/stick.png`

**Images/Icons** (208 prefix + bare names at 209-218, 610-611, 1559-1568, 2304-2317,
2357-2360, 2404, 2468-2473, 2605-2607, 2698-2699, 2909-2910, 2917-2919, 2956-2963, 3516):
`ArrowL.png`, `ArrowR.png`, `ArrowU.png`, `ArrowD.png`, `ArrowD_Red.png`, `Refresh.png`,
`Cross.png`, `Tick.png`, `CrossSmall.png`, `TickSmall.png`, `Help.png`, `Booze28.png`,
`NRG28.png`, `Star.png`, `Replays.png`, `Boot22.png`, `Boot28.png`, `Options.png`,
`Offline.png`, `Home.png`, `Home20.png`, `Facebook.png`, `Twitter.png`, `Mobile.png`,
`Relationships.png`, `Money.png`, `Casino.png`, `Trophy.png`, `Trophy14.png`, `PlayBall.png`,
`PlayRelations.png`, `PlayNewspaper.png`, `PlayCup.png`, `PlayWeb.png`, `PlayPhysio.png`,
`PlayBoss.png`, `PlayCoach.png`, `PlayRace.png`, `World.png`, `World14.png`, `Country.png`,
`Club.png`, `Shirt.png`, `Shirt14.png`, `Finances.png`, `Contract.png`, `Training.png`,
`Boss.png`, `Team.png`, `Fans.png`, `Girlfriend.png`, `Sponsors.png`, `Stable.png`,
`Star28.png`, `StarGrey28.png`, `MusicPlayer.png`, `Console.png`, `Tablet.png`,
`Drugs28.png`, `DrugsBoost.png`, `BoozeBoost.png`, `ShinPadsBoost.png`, `ShinPads28.png`,
`BootBoost.png`, `PainKiller.png`, `Eye.png`

**Images/Nations** (256, 258, 318): `Nations/NationIm_0.png`, prefix `Nations/NationIm_`,
prefix `GameMedia/Images/ButtonNationIm_`. Also `.png` suffix constant at 257.

**Images/Shop** (2523-2525, 2578, backslash form):
`Shop\Items\Items_`, `Shop\Vehicles\Vehicles_`, `Shop\Property\Property_`,
`Shop\Boots\Boots_` - each 10 numbered PNGs (verified).

**Images/Relationships** (2866-2875, backslash form): `boss.png`, `training_ground.png`,
`fans.png`, `bowling.png`, `golf_course.png`, `cinema.png`, `pub.png`, `restaurant.png`,
`shopping.png`, `sponsors.png`

**Images/Casino** (3271-3280, 3301, 3333-3336, 3355, 3360-3368, 3392, 3394-3395):
`Chip_50/100/250/500/1000/2500/5000.png`, `btn_BlackJack.png`, `btn_Roulette.png`,
`btn_Slots.png`, `Roulette/bg.png`, `Roulette/Wheel.png`, `Roulette/Wheel_Inner.png`,
`Roulette/Ball.png`, `BlackJack/bg.png`, `BlackJack/back.png`, `BlackJack/` (prefix →
`<rank>_<suit>.png`), `Slots/bg.png`, `Slots/Button.png`, `Slots/Glass.png`,
`Slots/Strip.png`, `Pairs/BG_` (prefix), `Pairs/` (prefix), `HigherLower/Player` (prefix)
*(Note: on-disk `btn_slots.png` is lowercase-s and `btn_Racing.png` exists but is unreferenced.)*

**Images/Stable** (3517-3527, 3582-3594): `Bg.png`, `Grass.png`, `FinishPost.png`,
`Post_1..6.png`, `Railing_01.png`, `FinishLine.png`, `Horse/Shadow.png`,
`Horse/Horse_01..04.png`, `Jockey/Jockey_01..06.png`, `ArrowD.png`, `Star.png`

### 4.5 Non-media file paths

| Line | Path | Purpose |
|---|---|---|
| 181 | `Settings/Settings.txt` | Boot config (7 keys, verified on disk) |
| 183 | `Settings/` | Settings dir prefix |
| 184 | `Save/` | Save dir prefix |
| 185 | `Replays/` | Replay dir prefix |
| 182 | `/New Star Soccer 5/` | User-documents subdir (used when `saveloc=1`) |
| 201 | `log.txt` | Debug log target |
| 857 | `Settings/Options.ini` | Player options |
| 730 | `.tac` | Tactics file extension |
| 1315 | `.rep` | Replay file extension |
| 1614 | `.sav` | Save file extension |
| 1618 | `.bak` | Save backup extension |
| 615 | `.ogg` / 257 `.png` | Extension constants for built paths |

---

## 5. Complete `$variable` placeholder index

These are substituted into localised strings from `Languages.csv` at display time
(`Replace(text, "$x", value)`).

| Line | Token | Used by |
|---|---|---|
| 313 | `$filename` | TNation/TClub save (`CMESSAGE_OVERWRITEFILE`) |
| 1242 | `$num` | `CREPORT_COACHYELLOWS` (yellow-card count) |
| 1244 | `$matchtype` | `CREPORT_COACHBAN*` (international/continental/club) |
| 1448 | `$` in `Clash: $` | competition-clash trace |
| 1880 | `$clubname` | trial / first-club messages |
| 2082 | `$club` | editor delete-club confirm |
| 2127 | `$comp` | editor delete-competition confirm |
| 2575 | `$cash` | shop purchase confirm |
| 2576 | `$energy` | shop purchase energy cost |
| 2834 | `$transdate` | transfer-window-closed message |
| 2846 | `$date` | generic date substitution |
| 3046 | `$playername` | retirement/legend messages |
| 3106 | `$competition` | cup/league winner news |
| 3132 | `$scandalrating` | girlfriend scandal news |
| 3139 | `$item` | lost item incident |
| 3141 | `$vehicle` | lost vehicle incident |
| 3144 | `$cost` | repair/replacement cost |
| 3158 | `$percent` | relationship request percentage |
| 3160 | `$clubstadium` | fixture/travel text |
| 3161 | `$opposingclubname` | fixture text |
| 3162 | `$opposingclubstadium` | fixture text |
| 3163 | `$offerclubname` | contract offer text |
| 3164 | `$offerclubstadium` | contract offer text |
| 3165 | `$years` | contract length |
| 3166 | `$injurylength` | physio report |
| 3167 | `$value` | player valuation |
| 3168 | `$wage` | contract wage |
| 3189 | `$skillslost` | `CREPORT_PHYSIO3` |
| 3191 | `$sponsor` | sponsor lifecycle messages |
| 3199 | `$loanclub` | loan messages |
| 3266 | `$clubateam` | B-team promotion |
| 3441 | `$keypause` | training instructions (bound key name) |
| 3443 | `$keykick` | training instructions (bound key name) |
| 3597 | `$name` | horse messages |

Also `$ USD` (1675) is a **currency prefix literal**, not a token.
`!*'();:@&=+$,/?%#[]` (1381) is the URL reserved-character set.
Trailing `$` on lines 375, 378, 386, 710, 780, 1332, 2718, 3793, 3881 and the `$$$$` runs
are **padding artefacts** (§1.1), not tokens.

---

## 6. Complete hex colour constant index (60 occurrences, 58 distinct)

Strip padding per §1.1. BlitzMax stores these as 6-hex strings and converts with
`SetColor(Hex(...))` - there is no `#` prefix in the exe (the CSVs *do* use `#RRGGBB`).

### 6.1 UI / chrome greys and accents

| Line | Hex | Context (nearest preceding string) |
|---|---|---|
| 176 | `FFFFFF` | app boot default colour |
| 178 | `00FF00` | app boot (version-OK green) |
| 252 | `000000` | ini `Value=` region |
| 253 | `666666` | ini region |
| 624 | `c0c0c0` | `lbl_Scores0` (scoreboard) - **lowercase in binary** |
| 629 | `888888` | `lbl_Time` |
| 639 | `555555` | match player/keeper sprites |
| 1543 | `AAAAAA` | `Pointer.png` / list widget |
| 1584 | `EEEEEE` | `tbl_LoadGame` header |
| 1586 | `DDDDDD` | `tbl_LoadGame` row |
| 1598 | `707070` | `btn_DeleteReplay` / social panel |
| 1642 | `BBBBBB` | `cmb_resolution` |
| 2094 | `CCCCCC` | editor `tbl_comps` |
| 2617 | `333333` | fixtures table |

### 6.2 Match HUD / stats panel

| Line | Hex | Nearest label |
|---|---|---|
| 543 | `FF9900` | ball marker / power |
| 544 | `FFFF00` | ball marker |
| 545 | `FF0000` | ball marker |
| 552 | `0000FF` | `NewController:` |
| 648 | `99FF99` | `Shots` stat row |
| 660 | `990099` | `Passes` stat row |
| 662 | `9999FF` | `Assists` stat row |
| 664 | `FF0099` | `Headers` stat row |
| 1151 | `FF00FF` | `matchmsg_Stomach` |

### 6.3 Crowd / stadium tints (TPitch)

| Line | Hex |
|---|---|
| 1076 | `0000C0` |
| 1077 | `808000` |
| 1078 | `8080FF` |
| 1079 | `C00000` |
| 1081 | `000080` (near `Boss.png`) |
| 1082 | `800000` |

### 6.4 Brand palette (near `New Star Games 2019`)

| Line | Hex |
|---|---|
| 1328 | `800080` |
| 1329 | `FF6600` |
| 1330 | `970045` |
| 1331 | `FCDB00` |
| 1332 | `008000` |
| 1480 | `6666FF` (competition editor) |

### 6.5 Character palette (TKit, lines 780-798) - **19 colours, ordered**

The 19 hexes sit between `BOOTCOL:` (779) and the `CHAIR_*` enum (799). The counts line up
exactly with the enums that follow, giving a high-confidence mapping:

| Line | Hex | Inferred slot |
|---|---|---|
| 780 | `444444` | boot default (black) / `BOOTCOL` index 0 |
| 781 | `404040` | `CHAIR_BLACK` |
| 782 | `5B2603` | `CHAIR_BROWN` |
| 783 | `E5E60E` | `CHAIR_BLOND` |
| 784 | `EA3C00` | `CHAIR_RED` |
| 785 | `999999` | `CHAIR_GREY` |
| 786 | `AC541A` | `CHAIR_LBROWN` |
| 787 | `D7A303` | `CHAIR_DBLOND` |
| 788 | `FFC28E` | `CSKIN_LIGHT` |
| 789 | `C47840` | `CSKIN_MEDIUM` |
| 790 | `B75E23` | `CSKIN_DARK` |
| 791 | `7C3400` | `CSKIN_BLACK` |
| 792 | `C6A754` | `CSKIN_ASIAN` |
| 793 | `4BD998` | boot colour |
| 794 | `9900DE` | boot colour |
| 795 | `FF9933` | boot colour |
| 796 | `00FFFF` | boot colour |
| 797 | `2D00EA` | boot colour |
| 798 | `EA0005` | boot colour |

7 hair colours ↔ 7 `CHAIR_*` values; 5 skin colours ↔ 5 `CSKIN_*` values. **The hair and skin
mappings are effectively certain.** **UNCERTAIN:** the boot grouping - there are 7 candidate
boot colours (`444444` + lines 793-798) but 10 shop boots, so the shop boot index is not a
1:1 map onto this palette.

### 6.6 Editor / misc

| Line | Hex | Context |
|---|---|---|
| 1973 | `FF8800` | editor `Test Data` |
| 2016 | `FFFF99` | edit-nations table |
| 2076 | `99FFFF` | `btn_MemberCount` |
| 2115 | `FF99FF` | competitions filter |
| 2206 | `FF9999` | `btn_RemoveClub` |
| 2976 | `38FF24` | matchprep `Enhancers` bar |

---

## 7. Complete ini / settings key index

### 7.1 `Settings/Settings.txt` - 7 keys (verified against the shipped file)

| Line | Key | Shipped value |
|---|---|---|
| 180 | `saveloc` | `0` |
| 196 | `debug` | `0` |
| 203 | `opengl` | `0` |
| 197 | `fullnames` | `0` |
| 198 | `nettimeout` | `5` |
| 199 | `port` | `0` |
| 200 | `proxy` | `0` |

Related: `Debug=` (202) is the write-back prefix; `log.txt` (201) is the log target;
`OpenAL` (204) / `FreeAudio` (205) are audio-driver selections.

### 7.2 `Settings/Options.ini` - 45 keys, three parallel string runs

Run A (**lines 871-920**) = the literal default-writing block in `WriteNewOptionsIni`.
Run B (**lines 922-970**) = `SaveOptions` write prefixes (`key=`).
Run C (**lines 972-1021**) = `LoadOptions` lookup keys (bare).

Run C has 50 entries vs Run B's 49 because `screen` (1002) is loaded but not saved in the
same loop (it also appears alone at line 901 as `screen=`).

| Key | Default (line 871-920) |
|---|---|
| `j_Control` | 0 |
| `j_Scheme` | 0 |
| `k_Up` | 38 (VK_UP) |
| `k_Down` | 40 |
| `k_Left` | 37 |
| `k_Right` | 39 |
| `k_Button` | 90 (`Z`) |
| `k_Button2` | 88 (`X`) |
| `k_Button3` | 67 (`C`) |
| `k_Button4` | 32 (Space) |
| `k_Pause` | 27 (Esc) |
| `k_Replay` | 112 (F1) |
| `j_Up` | -3 |
| `j_Down` | -4 |
| `j_Left` | -1 |
| `j_Right` | -2 |
| `j_Button` | 2 |
| `j_Button2` | 0 |
| `j_Button3` | 1 |
| `j_Button4` | 3 |
| `j_Pause` | 7 |
| `j_Replay` | 6 |
| `soundfx` | 100 |
| `music` | 100 |
| `difficulty` | 2 |
| `radar` | 0 |
| `matchlength` | 5 |
| `matchscale` | 2 |
| `replayscale` | 2 |
| `displayinitials` | 1 |
| `screen` | *(written bare as `screen=`, line 901)* |
| `window` | 1 |
| `playercam` | 2 |
| `matchfx` | 1 |
| `distance` | 0 |
| `leaderboardfindme` | 1 |
| `leaderboardmyage` | 0 |
| `leaderboardmyclub` | 0 |
| `leaderboardmynation` | 0 |
| `matchspeed` | 2 |
| `tooltips` | 1 |
| `highlightball` | 1 |
| `showenergy` | 0 |
| `currency` | 1 |
| `requestfreekicks` | 0 |
| `requestcorners` | 0 |
| `leaderboardview` | 1 |
| `language` | 0 |
| `fixkick` | 1 |
| `bossoff` | 0 |

### 7.3 `Inc/Engine.ini` - verified against the extracted 2,422-byte blob

The dump's key runs map **exactly** onto the ini's comment-delimited sections. Values below
are the real shipped values.

| Dump lines | Ini section | Keys = values |
|---|---|---|
| 589-593 | `' Match` | `replaylength=12000`, `gamesecond=1000`, `limitscrollx=50`, `limitscrolly1=44`, `limitscrolly2=26` |
| 1042-1052 | `' Pitch` | `pitchscale=10`, `sideline=450`, `goalline=600`, `goalpost=55`, `postwidth=3`, `crossbar=36`, `netline=16`, `penboxside=235`, `penboxd=421`, `penspoty=480`, `sixyardside=115` |
| 521, 523-538, 1128-1131 | `' Ball` | `ballradius=2`, `fricAir=0.99`, `fricGrass=0.985`, `gravity=0.14`, `bounce=0.6`, `kickpow_pass=0.07`, `kickheight_pass=0.0`, `kickpow_shoot=0.1`, `kickheight_shoot=2.85`, `kickpow_lob=0.08`, `kickheight_lob=3.65`, `kickpow_head=0.08`, `kickheight_head=1.5`, `kickdistratio_shoot=0.15`, `kickdistratio_lob=0.15`, `kickdistratio_pass=0.275`, `kickdistratio_cross=0.3`, `aftertouchtime=750`, `curlinc=0.05`, `curlmax=0.7` |
| 527, 1108-1127 | `' Player` | `acceleration=0.55`, `keeperaccel=0.75`, `walkingspeed=0.75`, `joggingspeed=0.85`, `playerfriction=0.85`, `slidevelocity=2.25`, `slidefriction=0.92`, `touchdist_ball=8.0`, `jumpspotradius=10.0`, `playerheight=22`, `playerradius=10`, `passcheckradius=5`, `turningcircle=0.75`, `powerbarspeed=3.5`, `highlightpass=0`, `fixkick=0`, `jumpvelocity=2.0`, `shotpowerparry=6.5`, `shotdistanceparry=7.5`, `injuryfrequency=15`, `energydrain=0.00225` |
| 1116 | `' Animation` | `framelength=80` |
| 1092-1101 | `' Player sprite` | `spritename_player=Player.png`, `spritewidth_player=128`, `spriteheight_player=128`, `spritecount_player=192`, `handlex_player=63`, `handley_player=110`, `spritescale=0.25`, `jumpframes=18,19,12`, `fallframes=8,9,10,13,14,15,30,60,61,62,63`, `holdballframes=50,51,52,53,54,58,63` |
| 752-778 | *(same section)* | `basemask=08846B`, `baseshirt1=EF1818`, `baseshirt2=CE0808`, `baseshirt3=B50000`, `baseshirt4=FFF700`, `baseshirt5=E7DE00`, `baseshirt6=BDB500`, `baseshorts1=39B500`, `baseshorts2=299400`, `baseshorts3=216B00`, `basesocks1=FF9400`, `basesocks2=BD7300`, `baseboots1=2929FF`, `baseboots2=1010CE`, `baseboots3=00008C`, `basehair1=F78463`, `basehair2=B54218`, `basehair3=630800`, `baseskin1=FFE7D6`, `baseskin2=FFDEB5`, `baseskin3=FFC68C`, `baseskin4=F78C63`, `baseskin5=CE734A`, `baseskin6=9C5A39`, `basegloves1=00FFFF`, `basegloves2=00B5B5` |
| 711-719 | `' Tactics` | `formationheight=10`, `formationwidth=24`, `withoutballformationwidth=26`, `wideplayerpush=1.1`, `formationxshift=1.0`, `withoutballformationxshift=1.25`, `formationyshift=2.75`, `formationdepth=1.0`, `ymarginmultiply=2.0` |
| 1086-1089 | `' Match Cameramen` | `camerax1=565`, `cameray1=300`, `camerax2=250`, `cameray2=660` |
| 3209-3219 | `' Match rating` | `ratingperminute=-0.25`, `ratingpasses=3`, `ratingdefensiveheaders=3`, `ratingshots=1`, `ratinggoals=17`, `ratingassists=10`, `ratingsaves=5`, `ratingtackles=5`, `ratingfouls=-3`, `ratingyellows=-5`, `ratingreds=-20` |

**Key insight for reconstruction:** the *ordering of the key strings in the binary* is the
order the code reads them, which is **not** the ini's file order. `basemask`/`base*` are read
inside `TKit` (line 752, i.e. before the pitch), while `spritename_player` etc. are read in
`TPlayer` (1092). `passcheckradius` is read in `TBall` (527) even though the ini places it in
the Player block. `fixkick` exists in **both** Options.ini and Engine.ini.

### 7.4 `GameMedia\Data\Horse.ini`

Despite the `.ini` extension this is **not** a key/value file - it is a flat newline-delimited
list of horse names (`Simon Says`, `Nancy Boy`, `Jolly Bristols`, …). Read at line 3558
(`LoadHorseData`), counted into `HorseCount:` (3560).

---

## 8. Complete error / warning / assert message index

### 8.1 Game-code messages (lines < 3609)

| Line | Message | Module |
|---|---|---|
| 222 | `Could not open file: ` | TMedia |
| 223 | `Could not load variable: ` | TMedia |
| 226/230/234/238/242 | `WARNING! >>>>>>>>>>>> Cannot see {image,pixmap,sound,anim image,font}: ` | TMedia |
| 228/232/236/240/244 | `ERROR! >>>>>>>>>>>>>> {Image,Pixmap,Sound,Anim Image,Font} could not be loaded: ` | TMedia |
| 261 | `Could not load GameMedia/Data/Nations.csv` | TNation |
| 316 | `No nation found!` | TNation |
| 321 | `Could not load GameMedia/Data/Clubs.csv` | TClub |
| 375 | `No club found!` | TClub |
| 395 | `Error TMyLocale: Unable to load language file!` | TMyLocale |
| 513 | `Error TNames: Unable to load file!` | TNames |
| 586 | `Player kicked ball out of play` | TBall (trace, not error) |
| 708 | `Error` | TMatch (state name) |
| 735 | `Cannot find tactics: ` | TTactics |
| 737 | `Cannot save tactics: ` | TTactics |
| 858 | `Options.ini doesn't exist. Writing new one...` | TOptions |
| 859 | `Error OPTIONS: Unable to create an options file:` | TOptions |
| 1159 | `Foul: Slide on keeper!` | TPlayer |
| 1160 | `Don't block tackle keeper.` | TPlayer |
| 1161-1163 | `No Foul: Too far from ball` / `No Foul: Got ball` / `No Foul: Made save` | TPlayer |
| 1164 | `Red card: Clean through and from behind` | TPlayer |
| 1165 | `Yellow card: Clean through but not from behind` | TPlayer |
| 1166 | `Yellow card: From behind` | TPlayer |
| 1167 | `Yellow card: Too many fouls` | TPlayer |
| 1217 | `No Anim!` | TPlayer |
| 1316 | `Could not save replay!` | TReplay |
| 1320 | `Could not load:` | TReplay |
| 1380 | `STREAM ERROR` | stream helper |
| 1383 | `Could not load GameMedia/Data/Continents.csv` | TContinent |
| 1477 | `ERROR INFLATING IDS!` | TCompetition (editor) |
| 1478 | `ERROR COMPRESSING IDS!` | TCompetition (editor) |
| 1491 | `Could not promote to competition! Comp: ` | TCompetition |
| 1497 | `WARNING! Number of teams changed in: ` | TCompetition |
| 1499 | `WARNING! Promotion place errors in competition(s): ` | TCompetition |
| 1500 | `WARNING! Promotion place exceeds number of teams in competition: ` | TCompetition |
| 1541 | `Letter not in list` | TScreen (list widget) |
| 1610 | `Could not open file: Credits.txt` | mainmenu |
| 1924 | `Could not load GameMedia/Data/PromotionPlaces.csv` | TPromotionPlace |
| 1948 | `Could not find id:` | TLeagueTable |
| 1951 | `Could not load GameMedia/Data/Stadiums.csv` | TStadium |
| 3084 | `Could not load profile!` | TProfile |
| 3204 | `Bugged Achievement` | TAchievements |
| 3391 | `Fail!` | pairs minigame |
| 3477 | `Time Up!` | TTraining |
| 3605 | `Could not load GameMedia/Data/Achievements.csv` | TAchievement |

Localised (user-facing) failure messages live in `Languages.csv`, not the exe. In the dump
they appear only as tags: `CMESSAGE_FILENOTCREATED` (315), `CMESSAGE_FILECORRUPTRESTORE`
(1619), `CMESSAGE_FILECORRUPTDELETE` (1620), `CMESSAGE_COULDNOTLOADFILE` (1623),
`CMESSAGE_INVALIDPLACE` (2182), `CMESSAGE_INVALIDCOMPETITION` (2183),
`CMESSAGE_INVALIDSKILLSHASH` (3171), `CMESSAGE_NEWCOMPIDEXISTS` (1479).

### 8.2 Steam layer

| Line | Message |
|---|---|
| 3609 | `Steam must be running to play this game.` |
| 3610 | `OpenSteam() failed.` |
| 3611 | `steamstate=` |
| 3612 | `Steam is online` |
| 3613 | `Steam is offline` |
| 3614 | `Steamstate offline!` |

### 8.3 BlitzMax runtime / module messages (lines ≥ 3620) - reference only

`TZipReader.getFileInfo(): Invalid index ` (3621) · `Invalid ZIP file!` (3622) ·
`unable to locate central directory!` (3623) · `<bad_dir>` (3624) ·
`WARNING: ZipEngine streams are read-only` (3626) ·
`Invalid syntax for URL (ex. zipe::zipfilename::file_in_zip::password)` (3627) ·
`unable to open zip ` (3628) · `Unable to find file` (3629) ·
`Experimental Code Called` (3630) · `Unable to Locate Open File` (3634) ·
`Unable to load the bitmapfont due to corrupted or unsuported file format` (3646) ·
`ERROR LOADING PNG` (3647) · `Can't draw text becouse the bitmapfont is null.` (3648) ·
`There was an unhandled exception inside this drawtext operation. The exception source is: ` (3649) ·
`The requested action could not be completed.` (3651) · `Malformed meta data` (3667) ·
`Unable to create new object` (3668) · `TypeID is not an array type` (3669) ·
`OpenAL Error: ` (3677) · `Failed to generate OpenAL source` (3687) ·
`Stream is not seekable` (3794) · `Unimplemented sample format conversion` (3795) ·
`PNG ERROR` (3797) · `Malformed line terminator` (3799) · `Internal socket error` (3810) ·
`Unable to create texture` (3813) · `_texture.GetSurfaceLevel failed` (3814) ·
`dstsurf.LockRect failed` (3815) · `GetRenderTarget failed` (3817) · `GetDesc failed` (3818) ·
`Unable to lock render target surface` (3819) · `CreateOffscreenPlainSurface failed` (3820) ·
`srcsurf.GetDC failed` (3821) · `dstsurf.GetDC failed` (3822) ·
`device does not support clipplanes` (3824) ·
`D3D7Max2D Create System Surface Failed` (3825) · `Create DX7 surface Failed` (3826) ·
`DD3D7ImageFrame Lock failed` (3827) · `BuildMipMaps: lock failed` (3828) ·
`Unable to calculate tex size` (3829, 3832) · `_d3dDev.Reset failed` (3834) ·
`Size invalidated` (3852) · `CreateSurface failed:` (3853) · `DDERR_WRONGMODE` (3856) ·
`List index out of range` (3874) · `Error reading from stream` (3882) ·
`Error writing to stream` (3883) · `Stream is not readable` (3884) ·
`Stream is not writeable` (3885) · `Unable to read object` (3886) ·
`Unable to write object` (3887) · `Too many hook ids` (3931) ·
`Attempt to access field or method of Null object` (3932) ·
`Attempt to call abstract method` (3933) ·
`Attempt to call uninitialized function pointer` (3934) ·
`Attempt to index array element beyond array length` (3935) ·
`Attempt to read beyond end of data` (3936)

---

## 9. Additional constant tables worth indexing

### 9.1 Save/replay file magics and hashes

| Line | Value | Meaning |
|---|---|---|
| 1615 | `::newstarsoccerfivesavefile::3c422b4eb93f7e15d399b188f4b4c7278b99a9c5c71ec6428969c9aabd8eed0a` | Full save-file header (magic + 64-hex SHA-256-shaped key) |
| 3093 | `3c422b4eb93f7e15d399b188f4b4c7278b99a9c5c71ec6428969c9aabd8eed0a` | The key alone |
| 3094 | `newstarsoccerfivesavefile` | The magic alone |
| 1317 | `newstarsoccerfivereplayfile` | Replay magic |
| 1318 | `::newstarsoccerfivereplayfile` | Replay magic with separator |
| 3083 | `47a5bc5742ca47828de0374c8ce31bde` (+`a` padding) | 32-hex online-profile key. **UNCERTAIN:** MD5-shaped |
| 3170 | `dontcheatatnss5` | Anti-cheat salt for the skills hash (`CMESSAGE_INVALIDSKILLSHASH`, 3171) |
| 1616 / 3088 | `#VERSION:` / `#VERSION:1.10` | Save-format version marker |

### 9.2 Date/time format tokens

`YY-WW-DDD` (379) · `YY-WW` (2631) · `YYY-WWW` (1617) · `YYYY-WWW` (3169) ·
`YYYY-WWWW` (3181) · `YYYY` (2258) · `WWWW` (2259) · `DDDD` (2260) ·
`%d %b %Y` (3875, BlitzMax) · `%H:%M:%S` (3876, BlitzMax) ·
`JANFEBMARAPRMAYJUNJULAUGSEPOCTNOVDEC` (3620, BlitzMax)

### 9.3 Enumeration tables (exact order preserved in the binary)

| Lines | Enum | Values |
|---|---|---|
| 564-569 | Kick type | `PASS`, `SHOOT`, `HEAD PASS`, `HEAD SHOOT`, `HEAD LOB`, `NONE` |
| 700-708 | Match state | `Tunnel`, `In Play`, `Centre`, `Throw-In`, `Penalty`, `Shoot-Out`, `Shoot-Out Taken`, `Match Over`, `Error` |
| 720-729 | Position/side | `sla_Left`, `sla_Centre`, `sla_Right`, `sla_GoalKeeper`, `sla_Defender`, `sla_DefensiveMid`, `sla_Midfielder`, `sla_AttackingMid`, `sla_Forward`, `sla_Substitute` |
| 738-751 | Formations | `3-4-3`, `3-5-2 A`, `3-5-2 B`, `4-2-2-2`, `4-2-4`, `4-3-3`, `4-4-1-1`, `4-4-2 A`, `4-4-2 B`, `4-5-1`, `5-3-2`, `Custom 1`, `Custom 2`, `Custom 3` |
| 799-805 | `CHAIR_*` | `BLACK`, `BROWN`, `BLOND`, `RED`, `GREY`, `LBROWN`, `DBLOND` |
| 807-811 | `CSKIN_*` | `LIGHT`, `MEDIUM`, `DARK`, `BLACK`, `ASIAN` |
| 813-835 | Kit style tokens | `PLAIN`, `TRIM`, `STRIPES`, `STRIPE`, `STRIPE_L`, `STRIPE_R`, `STRIPE_LR`, `STRIPE_RL`, `STRIPE_C`, `STRIPE_V`, `SLEEVES`, `SLEEVE`, `SLEEVE_L`, `SLEEVE_R`, `HOOPS`, `HOOP`, `SINGLEHOOP`, `SPLIT`, `SPLIT_LR`, `DIAGONALSPLIT_LR`, `DIAGONALSPLIT_RL`, `SEGMENTS`, `CHEQUERED` |
| 836-850 | Kit style sprite files | `Player_Plain/Trim/Stripes/StripeR/StripeLR/StripeC/V/Sleeves/SleeveR/Hoops/Hoop/Split/DiagonalSplit/Segments/Chequered.png` |
| 1173-1190 | Kick/tackle actions | `TapKick`, `Shot`, `Requested pass`, `AI pass`, `TapKickAdvanced`, `Knock`, `HoldKick`, `HoldKickAdvanced`, `SlideBall`, `Tackle`, `BlockTackle`, `BlockSave`, `HeadBall`, `HeadBallAdvanced`, `DiveHeadBall` |
| 1192-1216 | Animation states | `Stand`, `Kick`, `Header`, `Slide`, `Fall`, `StandGK`, `StandWithBallGK`, `WalkWithBallGK`, `DiveGK`, `DiveFallGK`, `JumpGK`, `JumpWithBallGK`, `CatchGK`, `CatchWithBallGK`, `CatchLowGK`, `CatchLowWithBallGK`, `Celebrate1`-`Celebrate5`, `Commiserate1:ScratchHead/FallOnFace/FallOnKnees/HoldHead` |
| 1449-1465 | Competition locale/based | `Club`, `Pool`, `LgCn`, `RgSr`, `ET/P`, `R/ET/P`, `2L/ET/P`, `None`, `North`, `East`, `South`, `West`, `Combn`, `Nation`, `Continent`, `World`, `International` |
| 1466-1471 | `comptype_*` | `League`, `KO`, `BestPlaced`, `Pool`, `LeagueCont`, `RegionalSort` |
| 1930-1938 | Special promotion rules | `100:AllTeams`, `101:TeamsNotInCnt`, `102:HighestNotInCnt`, `103:AllWinningTeams`, `104:AllLosingTeams`, `105:WinTeamElseLosing`, `106:WinTeamElseLeague`, `107:TeamsInContinental`, `108:LoseTeamElseLeague` |
| 3005-3016 | Selection status reasons | `Not Picked`, `Low Club Level`, `No Experience`, `Boss Unhappy`, `Poor Form`, `Match Fit`, `Substitute`, `Injured`, `Tiredness`, `No Boots`, `No Shin Pads`, `No Injury` |
| 3356-3359 | Card suits | `heart`, `diamond`, `club`, `spade` |
| 3369-3376 | Slot symbols | `Orange`, `Plum`, `Banana`, `Apple`, `Grapes`, `Cherries`, `Pineapple`, `Strawberry` |

### 9.4 Localisation key prefixes seen in the dump

Confirmed against the 2,751-row `Tag` column of `Languages.csv`:

| Prefix | Rows in CSV | Meaning |
|---|---|---|
| `CMESSAGE_` | 408 | Modal message-box body text |
| `CNEWS_` | 194 | Newspaper / news-feed items |
| `tla_` | 120 | Three-letter / table-header abbreviations |
| `key_` | 113 | Keyboard key display names |
| `CACHIEVEMENT_` | 100 | Achievement text |
| `CBOSSPOS_` / `CBOSSNEG_` | 96 / 96 | Boss positive / negative in-match shouts |
| `CMATCHTEXT_` | 91 | In-match commentary |
| `CREPORT_` | 87 | Post-match report lines |
| `tt_` | 69 | Button tooltips |
| `CACHIEVEMENTMOBILE_` | 66 | Mobile-only achievement text |
| `CTIP_` | 49 | Loading/idle tips |
| `CHELPMOBILE_` / `CHELP_` | 42 / 35 | Contextual help |
| `position_` | 35 | Position names |
| `help_` | 33 | Help panel bodies |
| `CCHANCESTAGE_` | 30 | Chance-build-up commentary |
| `sla_` | 28 | Short-label abbreviations |
| `CLICHE_` | 26 | Interview clichés |
| `CDILEMMA_` | 24 | Dilemma prompts |
| `date_` | 23 | Day/month names |
| `CTRAINING_` | 23 | Training instructions |
| `controls_` | 21 | Control action names |
| `CMOBILE_` | 20 | Mobile-only strings |
| `transfer_` | 18 | Transfer UI |
| `settings_` | 17 | Options labels |
| `replay_` / `CRESULTNEWS_` | 14 / 14 | Replay controls / result news |
| `iap_`, `blackjack_`, `account_` | 11 each | IAP, blackjack, online account |
| `vehicle_`, `sponsor_`, `property_`, `item_`, `CBOSS_` | 10 each | Shop catalogues, generic boss lines |
| `simple_`, `injury_`, `finances_`, `advanced_` | 7-8 | Control tutorials, finance rows |
| `time_`, `roulette_`, `comptype_` | 6 each | Travel bands, roulette bets, comp types |
| `skin_`, `selection_`, `request_`, `pos_`, `leaderboard_`, `joy_` | 5 each | Misc |

**Widget IDs are NOT language keys.** Of `btn_*`, `pan_*`, `lbl_*`, `tbl_*`, `prg_*`, `cmb_*`,
`inp_*` only **one** appears in the Tag column: `btn_Action`. Everything else with those
prefixes is a runtime element name. Screen-scoped IDs use `<screenid>_<widget>` instead
(e.g. `mainmenu_newgame`, `options_difficultyeasy`, `editmenu_clubs`).

Plain-English strings in the dump (`Abilities`, `Achievements`, `Star Man`, …) serve **both**
as the fallback English text **and** as the lookup key - the `Tag` column literally contains
`Abilities`, `1st Team`, `AppTitle`, etc.

### 9.5 Outbound URLs (lines 186-195, 3061-3064)

| Line | URL |
|---|---|
| 186 | `http://www.newstargames.com/` |
| 187 | `http://www.newstargames.com/en/text/releases/Releases/item/200/Releases-New-Star-Soccer` |
| 188 | `http://www.facebook.com/pages/New-Star-Soccer/173805879330444` |
| 189 | `http://twitter.com/newstargames` |
| 190 | `http://www.newstarsoccer.com/gamephp/` |
| 191 | `http://www.newstarsoccer.com/download.php` |
| 192 | `http://www.newstarsoccer.com/login.php` |
| 193 | `http://www.newstarsoccer.com/upgrade.php` |
| 194 | `http://www.newstarsoccer.com/profile.php` |
| 195 | `http://www.newstarsoccer.com/forgottenpassword.php?msg=Enter your player name and click reset to change your password...` |
| 3061 | `http://twitter.com/?status=` |
| 3062 | `http://www.facebook.com/dialog/feed?app_id=176264549093321&redirect_uri=http://www.facebook.com/&message=` |
| 3063 | ` http://bit.ly/jokTnJ` |
| 3064 / 3065 | `#NSS5 ` / `NSS5 News! ` |

---

## 10. Proposed original source-file list

Derived directly from §2. This is the reconstruction target for `src/`.

**Framework / third-party (do not rewrite - reimplement as thin shims):**
`Font Machine 1.5.1` (`.fmf` bitmap fonts), `ZipEngine` (`zipe::`), BlitzMax `brl.*`/`pub.*`.

**Engine layer (`EngineMedia`-driven, shared with the mobile port):**
`TBall.bmx`, `TPlayer.bmx`, `TMatch.bmx`, `TPitch.bmx`, `TKit.bmx`, `TTeam.bmx`,
`TTactics.bmx`, `TWeather.bmx`, `TReplay.bmx`, `TTraining.bmx`, `TScreenMessage.bmx`

**Data layer (`GameMedia/Data`-driven):**
`TContinent.bmx`, `TNation.bmx`, `TClub.bmx`, `TCompetition.bmx`, `TPromotionPlace.bmx`,
`TStadium.bmx` *(editor-only)*, `TFixture.bmx`, `TLeagueTable.bmx`, `TNames.bmx`,
`TAchievement.bmx`, `TContractOffer.bmx`, `TStats.bmx`, `THistory.bmx`

**Systems:**
`TMedia.bmx`, `TIni.bmx`, `TMyLocale.bmx`, `TOptions.bmx`, `TKeys.bmx`, `TProfile.bmx`,
`TSaveGame.bmx`, `TGame.bmx`, `TReport.bmx`/`TNews.bmx`, `TSteam.bmx`

**GUI:** `TScreen.bmx` (framework) + ~46 `TScreen_<Name>.bmx` screen types, one per block in
§2 rows 1553-3419. Naming is confirmed by lines 2679 (`TScreen_Formation.SetUpScreen`) and
3043 (`TScreen_SeasonReview.ButtonPlay`).

**Editor (shipped but only reachable via a hidden path):** `editmenu`, `editcontinents`,
`nations`, `clubs`, `editclubs`, `competitions`, `editcompetition`, `continentalcomps`,
`promotions`, `editkits`, `calendar`, `testmenu`, `tournaments`, `fixtures`.

---

## 11. Open questions / UNCERTAIN

1. **The "85 debug labels" figure.** The dump contains 168 colon-terminated strings (163 in
   game code). No filter I tried yields exactly 85. The strict `Identifier:` filter yields
   102 (97 in game code). §3 lists everything so nothing is lost, but the 85 figure should be
   re-derived before it is quoted again.
2. **`Inc/Player.png` load path.** No `incbin::Inc/Player.png` string exists. Only
   `Player.png` (778) and the prefix `incbin::Inc/` (1507). Needs a disassembly check of the
   call site near line 778's xref.
3. **Boot colour palette** (lines 793-798 + 780). 7 colours vs 10 shop boots. Mapping unknown.
4. **Tactics preset mismatch.** The exe hard-codes 11 preset formation names (738-748) but
   `EngineMedia/Tactics/` ships **13** `.tac` files - `4-1-4-1.tac` and `4-2-3-1.tac` are on
   disk with no matching string. Either the list is enumerated from the directory at runtime
   and 738-748 is a fallback, or those two files are dead assets.
5. **Unreferenced shipped assets:** `GameMedia/Sounds/{BDay,Bus,Mobile,Plane}.ogg`,
   `GameMedia/Images/Casino/btn_Racing.png`, `GameMedia/Images/Interface/Block.png`, and
   ~20 `Icons/*.png` (`Forum.png`, `Spanner.png`, `Media.png`, `Friend*.png`, `NRGBoost.png`,
   `PlayFreeTime.png`, `PlayIncident.png`, `*120.png`, `*20.png`, `Star14.png`,
   `StarGrey.png`, `ArrowRs.png`, `Cherry.png`, `Ball.png`, `Contract14/20.png`) have no
   literal string. They are almost certainly loaded via runtime-concatenated names - e.g.
   `"Play" + buttontype + ".png"` (cf. `Saving play button type: `, line 3086) and
   `<Icon><size>.png`. Confirm before treating any as dead.
6. **Line 253-254 orphans** (`666666`, `: changing formation`). `: changing formation` is
   clearly team-AI trace but sits 600 lines before `TTeam`. Possibly a `Global` const in a
   shared header.
7. **`GameMedia/Data/Mobile/` and `Stadiums.csv`** are referenced but absent from the retail
   install. They belong to the shipped-but-hidden data editor. If a full reconstruction is the
   goal, `Stadiums.csv` must be recreated (5 columns: `name`, `nation`, `capacity`,
   `longitude`, `latitude`).
8. **Copyright year split:** main game says `New Star Games 2019` (1327); the editor footer
   says `New Star Games 2010` (1959). The editor was not re-dated across the 9-year
   maintenance window - useful evidence that editor code is frozen and can be reconstructed
   from an earlier baseline.
