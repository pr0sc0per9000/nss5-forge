# Achievements, boss messages, interviews, and the season-end news

> **Source:** `TProfile.CheckAchievement` @ 0x0056cf70 (READ) · `TProfile.CheckPurchaseAchievements` @ 0x0056d1e1 (VERIFIED) · `TProfile.GetAchievements` @ 0x0056cf38 (VERIFIED) · `TAchievement.LoadData` @ 0x0058d1a5 (VERIFIED) · `TAchievement.Compare` @ 0x0058d5da (VERIFIED) · `TScreen_Achievements.SetUpScreen` @ 0x00559566 (VERIFIED) · `TBossMessage.Create` @ 0x00570973 (VERIFIED) · `TBossMessage.DrawAll` @ 0x00570a47 (VERIFIED) · `TBossMessage.Draw` @ 0x00570b40 (READ) · `TPlayer.BossPositive` @ 0x005036fb (VERIFIED) · `TPlayer.UpdateOffside` @ 0x004fe9ba (VERIFIED) · `TScreen_ReportBoss.SetUpScreen` @ 0x00561dff (READ) · `TScreen_ReportBoss.Draw` @ 0x005623f5 (VERIFIED) · `TScreen_Interview.SetUpScreen` @ 0x0057b109 (READ) · `TScreen_Interview.Update` @ 0x0057b9d9 (READ) · `TScreen_Interview.ButtonAddText` @ 0x0057b640 (VERIFIED) · `TScreen_Interview.Success` @ 0x0057bd61 (VERIFIED) · `TScreen_Interview.Fail` @ 0x0057be24 (VERIFIED) · `TScreen_WebPage.GetSocialMessage` @ 0x0056142a (READ) · `TScreen_WebPage.SetUpScreen` @ 0x00561066 (VERIFIED) · `TScreen_WebPage.ButtonTwitter` @ 0x005613ca (VERIFIED) · `TScreen_WebPage.ButtonFacebook` @ 0x005613fa (VERIFIED) · `TScreen_SeasonReview.SetUpScreen` @ 0x0055f8e6 (READ) · `TScreen_SeasonReview.UpdateSeasonStats` @ 0x005601ca (READ) · `TScreen_SeasonReview.UpdateSeasonTournaments` @ 0x005606c9 (VERIFIED) · `TScreen_SeasonReview.ButtonPlay` @ 0x00560796 (VERIFIED) · `TProfile.DoNews` @ 0x00569106 (VERIFIED)
> **Confidence:** HIGH for the mechanics that were read directly (achievement award flow, boss-message tone selection, interview setup, the social-share message builder, the season-review award checks that were traced). MEDIUM/LOW for the unlock conditions of the ~86 achievements whose triggering `CheckAchievement(id)` call site was not located in this pass - those are known only by their description text.
> **Last checked:** 2026-08-15

This is everything that talks to the player between matches: achievements, the boss's running
commentary and post-match report, the word-game interview, and the season-end review and social
share.

## Achievements

### The data file is nearly empty of information

`GameMedia/Data/Achievements.csv` looks like it should hold the unlock conditions. It doesn't - 
it's two columns, `id` and `sortindex`, one row per achievement:

```
id	sortindex
1	1
2	2
...
100	100
```

100 rows, ids 1-100 with no gaps, and **`sortindex` is identical to `id` on every single row** - 
it has never diverged from the identity mapping in the shipped file. (The file also carries a
UTF-8 byte-order mark, unlike `Languages.csv` which doesn't - a small, harmless inconsistency
between the two data formats.) All the real information - the unlock condition and the display
text - lives in code and in `Languages.csv`'s `CACHIEVEMENT_*` tags, not in this file.

`TAchievement.LoadData` (the loader) actually supports a **third column** that isn't used: after
reading `id` and `sortindex` from a row, if there's anything left on the line it reads one more
tab-delimited integer and writes it straight into `g_profile.achievements[id-1]` - i.e. the CSV
*could* pre-seed a player's unlocked-achievement dates directly. The shipped file never has a
third column, so this branch is always false in practice. The loader also recognises a line that
is literally `//` as an early-exit sentinel (with a small backfill for the first 10 achievement
IDs if fewer than 100 were loaded) - the shipped file has no such line either, so that path is
dead too. Worth flagging as an original bug for anyone who does hit it: that early-exit branch
returns without calling `CloseStream`, leaving the file handle open.

### How an achievement gets checked and awarded

Every achievement unlock goes through one method, `TProfile.CheckAchievement(id)`, called from
scattered sites all over the codebase (match events, purchases, season review, etc. - see below
for the ones located in this pass). Each call is a self-contained "did the player just do this?"
check; nothing polls for achievements, they're pushed at the moment they happen.

1. `LogLine("CheckAchievement:" + id)`.
2. The first time it's ever called, it loads `Star.png` (the little icon that overlays the
   pop-up alert).
3. **Four IDs (1, 73, 74, 75) are "Bugged Achievements"** and get special handling: if Steam
   integration is enabled, the game asks Steam directly (`GetSteamAchievement`) whether the
   player already has it, and skips the rest of the function if so. Every other achievement is
   deduplicated purely from local save data.
4. For all other IDs: if `g_profile.achievements[id-1]` is already non-zero (already unlocked),
   return immediately - an achievement can only be awarded once.
5. Otherwise, record **the current in-game date** into `g_profile.achievements[id-1]` - this
   array doubles as both the "have I got this" flag and "when did I get it", which is exactly
   what `TScreen_Achievements.SetUpScreen` displays (see below).
6. Unless the ID is **80** (`"Upgrade to a Premium account"` - a purchase event, not something
   worth interrupting play for), show an on-screen popup via `TScreenMessage.CreateAlert` with
   the `CACHIEVEMENT_<id>` text, the achievement icon, a 2.5-second display time, and a sound
   effect.
7. If Steam is enabled, tell Steam the achievement was unlocked (`SetSteamAchievement`).

### The achievements screen

`TScreen_Achievements.SetUpScreen` builds the list the player actually sees: every loaded
`TAchievement` **except id 80** (skipped from the list entirely - it's a purchase flag, not a
badge), sorted by unlock date (most recent first among the unlocked; locked ones show a `-` and a
padlock icon, unlocked ones show the date as `YYY-WWW` - in-game year and week - and a checkmark
icon). The most recently unlocked achievement is auto-selected. A progress bar at the top shows
`TProfile.GetAchievements()` - simply a count of how many of the 100 entries have a non-zero date.

### The full list

Every `CACHIEVEMENT_<id>` description, in ID order. The **Trigger** column names the exact
condition only for the IDs whose `CheckAchievement` call site was traced in this pass - for
everything else, only the description text is known.

| ID | Description | Trigger (where confirmed) |
|---:|---|---|
| 1 | Score a club goal | - |
| 2 | Score a club hattrick | - |
| 3 | Score 50 club goals | - |
| 4 | Score 100 club goals | - |
| 5 | Keep a clean sheet | - |
| 6 | Make an assist | - |
| 7 | Make 3 assists in one match | - |
| 8 | Win 5 tackles in one match | - |
| 9 | Win 10 tackles in one match | - |
| 10 | Win 15 tackles in one match | - |
| 11 | Make 10 passes in one match | - |
| 12 | Make 20 passes in one match | - |
| 13 | Make 30 passes in one match | - |
| 14 | Earn a 'Star Man' award | - |
| 15 | Earn 10 'Star Man' awards | - |
| 16 | Earn 25 'Star Man' awards | - |
| 17 | Earn 50 'Star Man' awards | - |
| 18 | Win a league game | - |
| 19 | Win a cup game | - |
| 20 | Win a continental cup game | - |
| 21 | Win an international game | - |
| 22 | Win a match by 5 goals | - |
| 23 | Win a national cup tournament | - |
| 24 | Win a club continental tournament | - |
| 25 | Win an international tournament | - |
| 26 | Win the 'Young Player of the Year' award | `TScreen_SeasonReview.SetUpScreen`: your competition has no promotion path to a domestic top-flight league (i.e. you're already in one), your age is under 22, season average rating (`GetStat` code 18) > 8.0, season goals (code 12) > 15 |
| 27 | Win the 'League Player of the Year' award | Same as 26, plus you finished the season in 1st place |
| 28 | Win the 'World Player of the Year' award | Season average rating > 8.5, and this season's `history` contains a title win matching one of three continental/domestic patterns, each additionally gated on a rating threshold around 7.0 |
| 29 | Play an international match | - |
| 30 | Play 50 international matches | - |
| 31 | Play 100 international matches | - |
| 32 | Score an international goal | - |
| 33 | Score an international hattrick | - |
| 34 | Score 50 international goals | - |
| 35 | Score 100 international goals | - |
| 36 | Celebrate a goal in front of the fans | - |
| 37 | Celebrate a goal in front of the cameras | - |
| 38 | Celebrate a goal with the boss | - |
| 39 | Celebrate a goal by running with ball to the centre circle | - |
| 40 | Transfer to a new club | - |
| 41 | Make a $1 million transfer move | - |
| 42 | Make a $5 million transfer move | - |
| 43 | Make a $10 million transfer move | - |
| 44 | Make a $20 million transfer move | - |
| 45 | Get 100% relationship with boss | - |
| 46 | Get 100% relationship with team | - |
| 47 | Get 100% relationship with fans | - |
| 48 | Get 100% relationship with sponsors | - |
| 49 | Get 100% relationship with friends | - |
| 50 | Get 100% relationship with girlfriend | - |
| 51 | Achieve 100% happiness | - |
| 52 | Sign a sponsorship contract | - |
| 53 | Sign maximum number of sponsorship contracts | - |
| 54 | Buy an NRG drink | - |
| 55 | Buy some booze | - |
| 56 | Buy some pain killers | - |
| 57 | Have $1 million in the bank | - |
| 58 | Have $10 million in the bank | - |
| 59 | Have $25 million in the bank | - |
| 60 | Purchase all luxury items | `TProfile.CheckPurchaseAchievements`: all 10 `items` slots owned |
| 61 | Purchase all vehicles | `TProfile.CheckPurchaseAchievements`: all 10 `vehicles` slots owned |
| 62 | Purchase all properties | `TProfile.CheckPurchaseAchievements`: all 10 `property` slots owned |
| 63 | Achieve 100% lifestyle rating | `TProfile.CheckPurchaseAchievements`: `GetLifestyle() >= 100` |
| 64 | Achieve maximum pace | - |
| 65 | Achieve maximum dribbling skill | - |
| 66 | Achieve maximum tackling skill | - |
| 67 | Achieve maximum passing | - |
| 68 | Achieve maximum heading skill | - |
| 69 | Achieve maximum shooting | - |
| 70 | Achieve maximum flair | - |
| 71 | Achieve 100% skill rating | - |
| 72 | Win money betting on a horse | - |
| 73 | Win money at the roulette wheel | "Bugged Achievement" (see above) - Steam-synced specially |
| 74 | Win money on the slot machine | "Bugged Achievement" |
| 75 | Win money playing black jack | "Bugged Achievement" |
| 76 | Achieve 100% fame rating | - |
| 77 | Win a league title | `TScreen_SeasonReview.SetUpScreen`: finished 1st, and your competition has **no** promotion path to a domestic top-flight league (i.e. you're already there) |
| 78 | Win a lower division title | `TScreen_SeasonReview.SetUpScreen`: finished 1st, and your competition **does** have such a promotion path (i.e. you're not yet top flight) |
| 79 | Get a girlfriend | - |
| 80 | Upgrade to a Premium account | Purchase event; excluded from the achievements list and from the unlock popup (see above) |
| 81 | Sign your first contract | - |
| 82 | Buy a horse | - |
| 83 | Win a race with a horse that you own | - |
| 84 | Sell over 100 replica shirts in one week | - |
| 85 | Get a maximum match rating 5 times in a row | - |
| 86 | Win the World Cup | - |
| 87 | Become a local hero and play 100 games for one club | - |
| 88 | Become a club legend and play 200 games for one club | - |
| 89 | Become the club captain | - |
| 90 | Buy a pair of shin pads | - |
| 91 | Buy some boots | - |
| 92 | Score a goal from 20 metres | - |
| 93 | Score a goal from 30 metres | - |
| 94 | Score 20 club goals in a season | `TScreen_SeasonReview.SetUpScreen`: `GetStat(5, 3, 0, year) > 20.0` |
| 95 | Make 150 club tackles in a season | `TScreen_SeasonReview.SetUpScreen`: `GetStat(17, 3, 0, year) > 150.0` |
| 96 | Make 300 club passes in a season | `TScreen_SeasonReview.SetUpScreen`: `GetStat(3, 3, 0, year) > 300.0` |
| 97 | Make 20 club assists in a season | `TScreen_SeasonReview.SetUpScreen`: `GetStat(4, 3, 0, year) > 20.0` |
| 98 | Get 20 Star Man awards in a season | `TScreen_SeasonReview.SetUpScreen`: `GetStat(15, 3, 0, year) > 20.0` |
| 99 | Play for 10 seasons | `TScreen_SeasonReview.SetUpScreen`: `(current year - 1) = 10` |
| 100 | Retire after 20 seasons | `TScreen_SeasonReview.SetUpScreen`: `(current year - 1) = 20` |

The stat codes for 94-98 line up exactly with the ones `TScreen_SeasonReview.UpdateSeasonStats`
uses to build the season stats table (5=Goals, 4=Assists, 3=Passes, 17=Tackles, 15=Star Man) - 
good cross-confirmation that both functions agree on what each numeric stat ID means.

A separate, second list exists in the data - `CACHIEVEMENTMOBILE_*` in `Languages.csv`, IDs 1-66
with completely different text (e.g. mobile #1 is "Sign your first contract" where desktop #1 is
"Score a club goal"). No code path was found anywhere in the recovered source or the string
cross-reference tables that reads a `CACHIEVEMENTMOBILE_*` tag - see `data/languages.md` for the
detail. It looks like leftover data from a mobile build, not something this Steam build ever
shows.

## Boss messages and interviews

### In-match boss commentary (`TBossMessage`)

During a match, the boss can pop up a short floating speech-bubble line reacting to something
that just happened. `TBossMessage.Create(homeboss, text, colour)` queues one: it picks a screen
position based on which side's boss is talking (`homeboss` = is this about a player on the home
team), gives it a 1,750ms display window, and starts it fully opaque. `TBossMessage.DrawAll`
walks the active list every frame, fading each message in over its first ~25% and out over its
last ~25% of its window (`TBossMessage.Draw`, READ - the exact vertical-centring arithmetic in
this function is still an open near-miss, but the fade timing and screen-flip logic are read
correctly), and staggers overlapping messages 500ms apart so they don't collide on screen.

**What triggers one, and what decides its tone.** The one confirmed trigger, `TPlayer.UpdateOffside`,
shows the pattern every other trigger almost certainly follows: it only ever fires for **the
player's own character** (`Self.newstar`), only when no other boss message is currently showing,
and only in a fixed 500ms window (2,500-3,000ms after the triggering state began - e.g. staying
offside). It then calls `GetText("CBOSSPOS_GETONSIDE" + Rand(1,4))` or
`GetText("CBOSSNEG_GETONSIDE" + Rand(1,4))` depending on **`TPlayer.BossPositive()`** - a small,
fully verified scoring method:

```
n = 0
n += 1  if this is your first season
n += 1  if your season goal tally is under 5
n -= 1  if your relationship with the boss is below 50%
n -= 1  if your current match rating is below 50
return  n > 0
```

So the boss's tone in the moment is **not** about whether the specific event was good or bad - 
`CBOSSPOS_GETONSIDE` and `CBOSSNEG_GETONSIDE` are both reactions to the *same* neutral "you keep
getting caught offside" nag, just phrased more gently or more harshly. It's about how forgiving
the boss is feeling: a new signing in his first season, or a striker who hasn't scored much yet
(so there's less to be annoyed about), gets the gentler phrasing; a bad relationship with the boss
or a poor match so far gets the harsher one. `Languages.csv` has 24 of these event categories
(`BADCALL`, `BADCORNER`, `BADCROSS`, `BADFINISHING`, `BADFREEKICK`, `BADLONGSHOT`, `BADVISION`,
`CALMDOWN`, `EXPLETIVE`, `GETONSIDE`, `GOODBACKLINE`, `GOODCORNER`, `GOODCROSS`, `GOODEFFORT`,
`GOODFINISH`, `GOODFREEKICK`, `GOODINTERCEPTION`, `GOODLONGPASS`, `GOODLONGSHOT`, `GOODPASS`,
`GOODPOSITIONING`, `GOODTACKLE`, `OFFSIDE`, `OFFSIDEPASS`), each with 4 phrasing variants under
both `CBOSSPOS_` and `CBOSSNEG_` - 192 lines total. Only `GETONSIDE`'s trigger was actually read;
the other 23 categories' trigger sites were not located in this pass, but by analogy they're
almost certainly other `TPlayer` in-match event checks calling `BossPositive()` the same way.

### The post-match boss report (`TScreen_ReportBoss`)

After a match, if the boss has something queued to say (a text field on the profile is
non-empty), the report screen shows it and up to five relationship-change lines - Boss, Team,
Fans, Sponsors, Fame - each rendered as `"boss +5%"` / `"team -3%"` (the stat name lower-cased,
sign-prefixed delta, percent sign), then reset to zero once shown (each is a one-shot delta, not
a running display). There's also an **automatic passive Fame adjustment**: if nothing else set a
Fame delta this round, the game computes one from your club's level - roughly `(55 - level/2) *
0.1`, clamped to the range 1.0-5.0 and applied as a *penalty* - meaning fame quietly erodes over
time purely from which division your club plays in, on every visit to this screen, unless
something more specific (a match event, an interview, …) already touched it.

**Failing a drugs test hits hard.** A special sentinel value (99) on one of the profile's fields
triggers six simultaneous relationship penalties in one go - three of them heavy (-50, -30, -30
on the first three relationship types) and three lighter (-10, -10, -50 on the rest) - alongside
the `CREPORT_BOSSDRUGSTESTBAD` report text ("What the hell were you thinking taking performance
enhancers..."). This is by far the single largest relationship hit found anywhere in this pass.

The screen also carries a first-time tutorial popup and a help tooltip
(`CHELP_REPORTRELATIONSHIPS`) attached to the relationships panel.

### The interview minigame (`TScreen_Interview`)

A word-by-word sentence-building minigame: the player taps numbered buttons in the right order to
build up an answer, one word per correct tap. Setup difficulty scales with the player's
`interviewskill` stat (floored at a minimum of 3):

| `interviewskill` | Buttons available | 
|---|---|
| < 6 | 9 |
| 6-8 | 12 |
| ≥ 9 | 15 |

Buttons 1-3 always show the same three `CLICHE_1`/`CLICHE_2`/`CLICHE_3` lines; buttons 4 and up
each get a random, non-repeating `CLICHE_4`-`CLICHE_25` (22 possible values for up to 12 slots;
`CLICHE_26` exists in the data but is never rolled). Among the active buttons, a random subset is
secretly marked as **wrong answers** - a 1-in-3 chance per button, capped by a budget equal to how
far above the skill floor of 3 the player's real `interviewskill` is (so a higher-skilled player's
longer interview also has more traps planted in it, not fewer). About 2.5 seconds after setup, the
correct next button starts flashing/beeping to prompt the player.

Each tap (`ButtonAddText`) is checked against the expected next answer: correct taps turn the
button green, play a positive sound, and append the word to the growing sentence label (the last
correct tap capitalises and full-stops it); a wrong tap turns the button red, plays a failure
sound, and ends the round immediately by calling `Fail()`. Completing all the required correct
answers calls `Success()`.

- **`Success()`**: plays a success sound, shows a "Success!" pop-up, sets the interview button's
  icon to a tick, and calls `UpdateRelationship(7, +5)` - relationship type 7, the same type
  `TScreen_ReportBoss` uses for the automatic Fame adjustment above, so a good interview raises
  your public profile rather than your boss/team/fan relationships specifically. `interviewskill`
  is also incremented by 1.
- **`Fail()`**: plays a failure sound, shows a "Fail!" pop-up, sets the icon to a cross, and calls
  `UpdateRelationship(7, -5)`. `interviewskill` is not changed on a fail.

*(UNCERTAIN: which numeric type code maps to which relationship in general - `TProfile.UpdateRelationship`
itself, the function that would answer that definitively, was not read in this pass. The Fame
identification for type 7 rests on the field-offset cross-match between `TScreen_ReportBoss` and
these two functions, not on reading `UpdateRelationship`'s body directly.)*

## News, social sharing, and the "web page" screen

`TScreen_WebPage` is the end-of-season screen that shows the league table alongside a headline and
Twitter/Facebook share buttons; it isn't a rolling "newspaper" (that's a separate, unread
`TScreen_Newspaper`). Its headline text comes from `TProfile.DoNews`, which is the general
`$token`-substitution engine used across `CNEWS_*`/`CMESSAGE_*`/`CREPORT_*` text (see
`data/languages.md`) - for example, `TScreen_SeasonReview.SetUpScreen` builds a "Young Player of
the Year" or "World Player of the Year" news story this way and hands it straight to
`TScreen_WebPage.SetUpScreen(screenName, story)` to display and make shareable.

**`TScreen_WebPage.GetSocialMessage(mode)`** builds the actual text that gets shared - this was
fully read and every string literal resolved:

1. Take the current webpage headline and strip any `"` characters from it.
2. **Facebook (`mode = 0`)**: `"NSS5 News! " + headline + " http://bit.ly/jokTnJ"`.
3. **Twitter (`mode = 1`)**: find the first `.` in the headline; if it's before character 113,
   cut the headline there (keeping the full first sentence), otherwise hard-cut at 113
   characters. Then build `"#NSS5 " + headline + " http://bit.ly/jokTnJ"`. 113 + `"#NSS5 "` (6) +
   `" http://bit.ly/jokTnJ"` (21) = 140 characters exactly - the classic tweet limit at the time
   this game shipped.
4. The finished string is passed through one more function (`0x005084a8`) before being returned.
   That function wasn't read directly, but its own callees (character-code lookups, string finds,
   repeated concatenation) are exactly the shape of a URL-encoder, and the result is immediately
   used inside a query string by the caller - so it's almost certainly `EncodeURL`. *(INFERRED
   from call shape, not confirmed by reading the function.)*

`TScreen_WebPage.ButtonTwitter`/`ButtonFacebook` just call `OpenURL()` with
`GetSocialMessage`'s result appended to a fixed `twitter.com`/`facebook.com` share-dialog URL.
**Neither the game nor `GetSocialMessage` makes any network request of its own** - `OpenURL`
hands off to the OS's default browser and returns immediately, so sharing cannot hang or time out
the game itself, regardless of the `nettimeout=5` setting in `Settings/Settings.txt`.

That setting almost certainly belongs to a *different*, unread subsystem: the binary also contains
a cluster of URLs at `http://www.newstarsoccer.com/{gamephp,download,login,upgrade,profile,
forgottenpassword}.php` (see `docs/specs/06-binary-string-subsystem-map.md` §9.5), which is the
game's own online-account system (`TScreen_CreateAccount` and friends) - that one plausibly does
make real HTTP requests from inside the game, and would be where a 5-second timeout matters, and
by 2026 `newstarsoccer.com` is very likely long dead. **This subsystem was not read in this pass**;
flagging it here so nobody assumes the sharing feature is the risky one.

A related loose end: `Languages.csv` has ten `CMESSAGE_SOCIAL1`-`CMESSAGE_SOCIAL10` tags that read
exactly like alternative share templates ("I have scored $goals goals in New Star Soccer 5.", "I
have an average rating of $rating...", etc.). `GetSocialMessage` doesn't use them - no `GetText`
call for any `CMESSAGE_SOCIAL*` tag appears in the function that was fully read. Whatever reads
them (if anything still does) was not located.

## Season review and awards

`TScreen_SeasonReview.SetUpScreen` runs once at the end of each season and is the hub for most of
the achievement checks in this document (see the table above for 26-28, 77, 78, 94-100). Beyond
the achievement checks, it:

- Records a `THistory` entry for the season's league finish, and one more for each individual
  award (Young/League/World Player of the Year) - this is the data
  `TScreen_SeasonReview.UpdateSeasonTournaments` later displays as a scrollable list of "what you
  won this season", filtered to the current year.
- Refreshes the league table and paints which clubs got promoted.
- Builds the news story text for whichever individual award (if any) was won, via `TProfile.DoNews`,
  and forwards it to the web-page/share screen (see above).

`TScreen_SeasonReview.UpdateSeasonStats` (READ - a near-miss, semantics fully mapped but not yet
byte-matched) builds the season totals table: Appearances (with substitute-appearances shown
alongside), Goals, Assists, Passes, Tackles, Star Man awards, and Average Rating, each row showing
two numbers side by side from `GetStat`/`GetStringStat` with period codes 3 and 4 (*UNCERTAIN*:
read elsewhere in this pass as "home half vs away half of the season", not independently
confirmed here).

`TScreen_SeasonReview.ButtonPlay` (the button that leaves this screen) is also where actual
retirement happens: past year 20, it checks whether **every one of the 100 achievement slots is
non-zero** and shows a special "you're a legend" retirement message if so, or the ordinary
retirement message otherwise, then sets `retired = 1` and saves. This is flavour text only - it
doesn't grant achievement 100 itself (that's the year-20 check in `SetUpScreen`, above), it just
reacts to how many you've already collected by the time you hang up your boots.

## What we do not know yet

- **Unlock conditions for ~86 of the 100 achievements.** Only the ones reachable from
  `TProfile.CheckPurchaseAchievements` and `TScreen_SeasonReview.SetUpScreen` were traced. The
  rest (goal counts, tackle counts, transfer values, relationship percentages, casino wins, and
  so on) are scattered across dozens of other functions - training, matches, transfers, the shop,
  the casino minigames - none of which were searched for `CheckAchievement(` call sites in this
  pass. `scripts/build_dependency_graph.py` against `TProfile.CheckAchievement`'s callers would
  find them.
- **`TProfile.UpdateRelationship`'s type-code mapping.** This document infers "type 7 = Fame" from
  matching field offsets across three different functions, and lists "types 1-6 are probably Boss/
  Team/Fans/Sponsors/Friends/Girlfriend, in some order" without pinning the order down. Reading
  `UpdateRelationship` itself would settle both.
- **Which function decides tone for the other 23 `CBOSSPOS_`/`CBOSSNEG_` event categories.** Only
  `GETONSIDE` (via `TPlayer.UpdateOffside`) was actually traced back to `BossPositive()`.
- **What `TScreen_Interview.SetUpScreen`'s trailing `EnableAllButtons()` immediately followed by
  `DisableAllButtons()` is for.** Both calls appear back to back with no branch between them in
  the decompile; the net effect is the buttons end up disabled when the function returns. Possibly
  leftover from a refactor; not chased further.
- **`TScreen_CreateAccount` and the `newstarsoccer.com` online-account subsystem.** Not read at
  all in this pass - this, not the social-share feature, is the more likely home for any
  `nettimeout=5`-related hang.
- **Who (if anyone) still reads `CACHIEVEMENTMOBILE_*` or `CMESSAGE_SOCIAL*`.** See above - both
  look like live features with no call site found.
- **`TBossMessage.Draw`'s exact vertical-centring math** near the `flipit` branch - a near-miss,
  length-correct but 2 bytes still mismatched (see the file's own header in
  `src/recovered_unverified/`).
