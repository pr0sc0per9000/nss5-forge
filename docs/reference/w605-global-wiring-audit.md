# w605 -- Whole-program Global and type wiring audit

Worker 605. **Investigation only -- no corpus file was edited.** Every claim below is tagged
MEASURED (read out of `binary/NSS5.exe` or out of the emitted
`src/assembled/nss5_assembled.bmx`) or INFERRED.

Scripts written for this audit (read-only, safe to re-run):
`scripts/workflow/w605_wiring_audit.py`, `scripts/workflow/w605_split_triage.py`.

---

## 0. Headline

The three type conflicts handed to me are **all false alarms** -- every one is already
resolved correctly by `extracted/globals_type_overrides.tsv`, which the parent's
pragma-only scan did not consult. Type conflicts are *not* where the remaining damage is.

The damage is in the **alias tables**, and it takes two shapes the byte oracle cannot see:

| # | Defect | Path | Confidence |
|---|--------|------|-----------|
| **A** | Screen-width slot `0x00C6EFE4` split 4 ways; the writer lands on one name, 11 reads land on three dead ones | rendering | **MEASURED, certain** |
| **B** | `g_tr_x2`/`g_tr_y2` transposed by `global_alias_unified.tsv` -- X and Y swapped | training | **MEASURED, certain** |
| **C** | `g_plr:TPlayer` should be `g_profile:TProfile`; same vtable slot `0x6c`, different method | training / match start | **MEASURED, certain** |

All three are invisible to `harness.try_method` by construction, and all three are live in
the currently emitted program.

---

## 1. The three handed-over conflicts: all already fixed

MEASURED, by grepping `extracted/globals_type_overrides.tsv` and by reading the emitted
declarations in `src/assembled/nss5_assembled.bmx` (mtime 2026-08-22 19:49):

| Conflict as reported | Override row | What is actually emitted |
|---|---|---|
| `g_curscreen` :TScreen x19 vs :Object x1 | line 121, `TScreen` | `nss5_assembled.bmx:45427` -- `Global g_curscreen:TScreen` OK |
| `g_object108` :TGadget x5 vs :Object x2 | line 22, `TGadget` | name is aliased to `g_activegadget`; `:45161` -- `Global g_activegadget:TGadget` OK |
| `g_inpname` :TInputBox vs :TGadget | line 126, `TInputBox` | `:45809` -- `Global g_inpname:TInputBox` OK |

All three are also written at runtime (`g_curscreen` 5 writes, `g_activegadget` 10,
`g_inpname` 1), so none is a split-slot victim either. **Ruled out.**

### Why the crude scan mis-fired, and the real hazard it points at

`assemble.py:1595` resolves an unresolved conflict as `sorted(v)[0]` -- **alphabetical**,
which systematically favours the *base* type (`Object` < `TScreen`, `Object` < `TGadget`,
`TGadget` < `TInputBox`). The override table exists precisely to defeat that, and it has
**224 rows**. The parent read pragmas but not the override table, so it saw the raw
disagreement and not the resolution.

MEASURED: 95 conflicts are still emitted with a live `' !! UNRESOLVED CONFLICT` marker.
Almost all are benign *by luck* -- `TButton` < `TGadget`, `TCombo` < `TGadget`,
`TChannel` < `brl.audio.TChannel`, so alphabetical happens to pick the derived/correct type.
The pairs of *unrelated* types are the ones worth a second look:

* `g_holdframes`, `g_keeperframes`, `g_player_arr01`, `g_player_arr02` -- `Int[] vs TList`.
  **Ruled out**: MEASURED, no body anywhere declares these names `:TList` (the claim
  arrives through an alias), and all four are assigned real Int-array literals in the
  emitted program (`g_keeperframes = [59,60,60,61,...]` at `:11271`). `Int[]` is correct.
* `g_screenname` -- `String vs TBall`. **Ruled out**: written at `:23844` from
  `g_curscreen.name`; `String` is correct.
* `g_diffname` -- `String vs TBall`. `String` is correct, **but see section 6** -- this Global is dead.

---

## 2. Root cause A -- the screen-width slot is split four ways (RENDERING)

### The measurement

`0x00C6EFE4` is the backbuffer/screen **width**; `0x00C6EFE8` is the **height**.

MEASURED, `scripts/disasm.py 0x00510DFC` (TScreen.Draw, byte-identical, 618/618):

```
0x00510ED6  ff35e8efc600   push dword ptr [0xc6efe8]
0x00510EDC  ff35e4efc600   push dword ptr [0xc6efe4]
0x00510EE6  e884cf0900     call 0x5ade6f          ; _brl_max2d_SetViewport
```

MEASURED, by scanning `NSS5.exe` for every write instruction targeting those two
addresses: **exactly one writer function**, `SetUpGraphics`, and it writes both --

```
0x00506AF3  8b4308               mov eax, dword ptr [ebx + 8]      ; mode.w
0x00506AF6  a3e4efc600           mov dword ptr [0xc6efe4], eax
0x00506AFB  8b430c               mov eax, dword ptr [ebx + 0xc]    ; mode.h
0x00506AFE  a3e8efc600           mov dword ptr [0xc6efe8], eax
...
0x00506B3A  c705e4efc60020030000 mov dword ptr [0xc6efe4], 0x320   ; 800
0x00506B44  c705e8efc60058020000 mov dword ptr [0xc6efe8], 0x258   ; 600
```

`src/recovered_module/SetUpGraphics.bmx:102-107` reproduces this exactly, and declares the
pair **symmetrically**: `'!Global g_engine_int162:Int` / `'!Global g_engine_int163:Int`.

### The defect

MEASURED, by calling `assemble.py`'s own `global_alias_map()`:

```
g_engine_int162  -> (canonical / unmapped)      <-- the WRITER's name for WIDTH
g_engine_int163  -> g_engine_gfxh               <-- the WRITER's name for HEIGHT, remapped
g_engine_screenw -> g_engine_gfxw
g_scr_w          -> g_engine_gfxw
g_scrw           -> g_engine_gfxw
g_snow_count     -> g_engine_gfxw
g_snow_wid       -> g_engine_gfxw
g_gfxw           -> (canonical / unmapped)
g_gfx_width      -> (canonical / unmapped)
```

`extracted/global_alias_unified.tsv` lines 667-671 elect **`g_engine_gfxw`** as canonical
for `0x00C6EFE4` and rewrite five reader spellings onto it -- **but there is no row
`g_engine_int162 -> g_engine_gfxw`.** The equivalent row for the height slot *does* exist
(line 672, `g_engine_int163 -> g_engine_gfxh`). **One missing row, and it is the writer's
own spelling.**

`assemble.py` emits one `Global` per surviving distinct name, so the width slot fragments
into **four independent variables**. MEASURED over the emitted program:

| Emitted Global | reads | writes | value at runtime |
|---|---:|---:|---|
| `g_engine_int162` | 103 | 2 (`= mode.w`, `= 800`) | correct width |
| `g_engine_gfxw` | 9 | **0** | **always 0** |
| `g_gfxw` | 1 | **0** | **always 0** |
| `g_gfx_width` | 1 | **0** | **always 0** |

The height slot is healthy by comparison (`g_engine_gfxh` 104 reads / 2 writes); only
`g_gfxh` and `g_gfx_height` (1 read each) are dead. **The asymmetry is the whole bug**: a
body that reads the pair `g_engine_gfxw, g_engine_gfxh` gets **0 for X and the correct 600
for Y**. That is precisely the signature "a sprite drawn at the wrong offset" -- wrong in
one axis only.

### Named victims (MEASURED -- every read site of a dead width name)

| Site | Code | Consequence |
|---|---|---|
| **`TScreen.Draw`** | `SetViewport(0, 0, g_gfxw, g_gfxh)` | **`SetViewport(0,0,0,0)`** -- a zero-area clip rectangle on the main screen draw. Most severe site in the list. |
| `TEngine.RenderReplayGUI` | `DrawMyText(..., g_engine_gfxw-20, 0, ...)` | text drawn at **x = -20**, off-screen left |
| `TEngine.RenderReplayGUI` | `TPanel_Controls.RenderReplay(g_engine_gfxw-154, g_engine_gfxh-214)` | **x = -154**, y = 386 (correct) -- wrong in X only |
| `TPanel_Controls.RenderKickToContinue` | `Int(g_engine_gfxw/2 - (kick[0].w + kick[1].w)/2.0)` | prompt centred on **x = 0**, i.e. half off the left edge |
| `TScreenMessage.Create` | `a0 = g_engine_gfxw / 2` | **every** screen message centred at x = 0 |
| `TScreen_Interview.SetUpScreen` / `.Fail` | `TScreenMessage.Create(g_engine_gfxw/2, g_engine_gfxh/2, ...)` | x = 0, y = 300 -- wrong in X only |
| `TScreen_Dilemma.SetUpScreen` | `TScreenMessage.Create(g_gfx_width/2, g_gfx_height/2, ...)` | x = 0, y = 0 |
| `TSnowFlake.SetUp` | `For i = 0 To g_engine_gfxw / 6` | loop runs `0 To 0` -- **1 snowflake instead of ~133** |
| `TSnowFlake.Create` / `.ResetAll` | `s.x = Rand(0, g_engine_gfxw)` | every snowflake pinned to **x = 0** |

INFERRED (not executed): `TScreenMessage.Create` is shared by the interview, dilemma,
negotiation and pairs screens, so the "message appears at the wrong place / off the left
edge" symptom should be visible on all of them, and `TScreen.Draw`'s zero viewport should
suppress drawing for the remainder of that method.

### Why the byte oracle is blind to it

`SetUpGraphics` and `TScreen.Draw` are both byte-identical. In a single-body probe the
Global's *name* is not load-bearing at all -- `harness.merge_globals` folds the file's own
`'!Global` pragma in verbatim, so the probe declares whatever the body spells and the
codegen emits the same `mov`/`push` against a slot either way. The split only exists once
**two different files** are compiled into **one** program.

---

## 3. Root cause B -- the training set-piece X/Y are transposed by the alias map (TRAINING)

### The measurement

MEASURED, `NSS5.exe` at the set-piece call site:

```
0x005809FD  ff35dccfc600   push dword ptr [0xc6cfdc]
0x00580A03  ff35d8cfc600   push dword ptr [0xc6cfd8]
0x00580A09  6a01           push 1
0x00580A0B  6a04           push 4
0x00580A0D  ff15a0bac500   call dword ptr [0xc5baa0]     ; TEngine.SetUpSetPiece
```

cdecl, pushed right-to-left, so the argument list is
`(4, 1, [0xC6CFD8], [0xC6CFDC])` -- matching our
`TEngine.SetUpSetPiece(4, 1, <x>, <y>)`. Therefore **`0x00C6CFD8` = X, `0x00C6CFDC` = Y.**

Corroborated by the initialiser at `0x0057DEBA`, which sets `[0xC6CFD8] = 0` and then
converts the float `0xC1200000` (= -10.0) to int and stores it in `[0xC6CFDC]`. A set piece
at (x=0, y=-10) -- centred, just in front of goal -- is coherent; (x=-10, y=0) is not.

### The defect

`src/recovered/TTraining.GetMatchState.bmx` declares the pair **correctly**, with its own
address comments:

```
'!Global g_tr_x2:Int       ' 0x00C6CFD8      <-- correct, CFD8 is X
'!Global g_tr_y2:Int       ' 0x00C6CFDC      <-- correct, CFDC is Y
...
a1[0] = g_tr_x2
a2[0] = g_tr_y2
TDummy.UpdateWallLocations(g_tr_x2, g_tr_y2)
```

MEASURED, the two alias tables **contradict each other**:

```
global_alias_map.tsv:215   0x00C6CFD8  g_tr_x2 -> g_training_setpiecex     (correct)
global_alias_map.tsv:216   0x00C6CFDC  g_tr_y2 -> g_training_setpiecey     (correct)

global_alias_unified.tsv:584  0x00C6CFD8  g_tr_x2 -> g_training_setpiecey  <-- SWAPPED
global_alias_unified.tsv:585  0x00C6CFDC  g_tr_y2 -> g_training_setpiecex  <-- SWAPPED
```

`assemble.py`'s `global_alias_map()` loads the five tables in the order
`MAP, UNIFIED, WRITERS, ADJUDICATED, OVERRIDES` and does a plain `out[a] = c`, so **later
wins** -- the transposed `UNIFIED` rows beat the correct `MAP` rows.

MEASURED, the resulting emitted code (`nss5_assembled.bmx:42957-42959`) -- the arguments
have been swapped relative to the source:

```
a1[0] = g_training_setpiecey
a2[0] = g_training_setpiecex
TDummy.UpdateWallLocations(g_training_setpiecey, g_training_setpiecex)
```

`extracted/global_address_map.tsv` agrees with the transposed reading
(`g_training_setpiecex -> 0x00C6CFDC`, `g_training_setpiecey -> 0x00C6CFD8`), so the solver
and `UNIFIED` share one error and only `global_alias_map.tsv` and the recovered body's own
comment are right. The binary settles it: **`MAP` is correct, `UNIFIED` is wrong.**

### Compounding: both names are also dead

MEASURED: `g_training_setpiecex` and `g_training_setpiecey` are each read 4x in the emitted
program and **written 0 times** -- no recovered body assigns either spelling. So today both
are 0, the wall/set-piece is placed at (0, 0) rather than (0, -10), and the transposition is
currently masked by the deadness. Fixing the deadness *without* fixing the transposition
would turn a wrong-but-symmetric (0,0) into a genuinely swapped (-10, 0).

Victims (MEASURED): `TTraining.GetMatchState`, `TDummy.UpdateWallLocations`, and the two
`TEngine.SetUpSetPiece(4, 1, ...)` calls at `:42467` and `:42534` (`UpdatePassing`).

---

## 4. Root cause C -- `g_plr:TPlayer` is `g_profile:TProfile`; slot 0x6c differs (TRAINING / MATCH START)

### The measurement

`src/recovered/TScreen_ReportBoss.ButtonPlay.bmx` (VA `0x005623D3`, byte-identical 34/34):

```
Function ButtonPlay:Int()
    '!Global g_plr:TPlayer
    TScreen_GameMenu.SetUpScreen()
    g_plr.UpdateTeamMateId_Human()
End Function
```

MEASURED, the original:

```
0x005623DC  a128f0c600     mov eax, dword ptr [0xc6f028]
0x005623E1  50             push eax
0x005623E2  8b00           mov eax, dword ptr [eax]
0x005623E4  ff506c         call dword ptr [eax + 0x6c]
```

So the Global is `0x00C6F028` and the dispatch is through **vtable slot `0x6c`**.

MEASURED, `extracted/global_address_map.tsv` -- ten corpus names resolve to `0x00C6F028`, and
the consensus is overwhelming:

```
g_profile                0x00C6F028  STRONG   TProfile  158 bodies  (112/113 bodies agree)
g_contractoffer_tplayer  0x00C6F028  CERTAIN  TProfile   22 bodies  (forced in 19, unanimous)
g_plr                    0x00C6F028  STRONG   TPlayer     1 body    (forced in 1 body)
... 7 more, all TProfile
```

`extracted/globals_final.tsv` types `0x00c6f028` as **`TProfile`**, `verified`/`high`.
In the emitted program `g_profile` has 1,984 reads and 3 writes (`g_profile = New TProfile`).

MEASURED, `extracted/vtable_map.tsv` -- slot `0x6c` is a **different method on each type**:

```
TPlayer   Method  UpdateTeamMateId_Human  ()i  0x6c  0x004ef619
TProfile  Method  NextPlayButton          ()i  0x6c  0x005679a0
```

### The mechanical chain

1. `0x00C6F028` holds a `TProfile` (158-body consensus + `globals_final` verified). MEASURED.
2. `ButtonPlay` dispatches slot `0x6c` on it, so the original calls **`TProfile.NextPlayButton()`**. MEASURED.
3. Our body declares the slot `g_plr:TPlayer`, so `.UpdateTeamMateId_Human()` -- which *is*
   `TPlayer` slot `0x6c` -- emits the identical `call [eax+0x6c]`. **The body byte-matches.** MEASURED.
4. `g_plr` is not in the alias map, so `assemble.py` emits it as its **own** `Global`
   (`nss5_assembled.bmx:46286`) alongside `g_profile`. MEASURED.
5. `g_plr` is **written 0 times** anywhere in the program -- it is on the CRITICAL dead list. MEASURED.
6. Therefore `g_plr` is always `Null`, and `g_plr.UpdateTeamMateId_Human()` at `:34685` is a
   null dispatch: silently nothing in a release build, `Attempt to access field or method of
   Null object` in `-d`. INFERRED from the language semantics (blitzmax-language-guide 18.26),
   not executed.
7. Even with the deadness repaired, the *intent* is wrong: `TProfile.NextPlayButton` advances
   the career to the next fixture. `TPlayer.UpdateTeamMateId_Human` does not.

**Symptom this predicts**: pressing *Play* on the boss-report screen sets up the game menu
but never advances the career -- i.e. a career that will not reach its next match/training --
or an access violation on that click in a `-d` build. INFERRED.

This is the same failure class as commit `bb1b094`, one address with two names, except the
second name also carries a wrong *type*, which is what makes the vtable slot resolve to a
different function.

---

## 5. The complete many-to-many map

Built by `scripts/workflow/w605_wiring_audit.py` over
`src/{recovered,recovered_module,recovered_unverified,recovered_thirdparty,module_body,behaviour}`
joined to `extracted/global_address_map.tsv`, with names canonicalised through
`assemble.py`'s own `global_alias_map()`.

### address -> {names}

MEASURED: **50 addresses** carry more than one *distinct emitted* name after
canonicalisation. That number is an upper bound and **most of it is solver noise, not real
splits** -- `global_address_map.tsv` is an alignment product, and low-body-count rows land on
whatever slot the aligner had spare. Two reliable tells for noise:

* **Type incoherence.** `0x00C5B218 -> {g_hometeam:TTeam, g_radarcol_home:String}` and
  `0x00C6E950 -> {g_calendar_screen:TScreen, g_mediaprefix:String, g_pair_fronts:TImage[5],
  g_screen_competitions:TScreen, g_slotglass:TImage, ...}` (8 names). One dword cannot be all
  of those. Treat any group whose members disagree about object-vs-scalar as noise until the
  binary says otherwise.
* **Contradicted by the body's own address comment.** `0x00C6EFE4 -> {g_engine_gfxw,
  g_train_scrollx}` is noise: `TTraining.Update.bmx:20` states `0x00C6CFB0 g_train_scrollx`,
  and `TTraining.SetUpTraining.bmx:206` explains the confusion -- it does
  `g_train_scrollx = Float(g_screen_w)`, so the aligner conflated the source with the
  destination. **Ruled out.** Discarding it is what exposed the real `0x00C6EFE4` family.

Filtering to groups where **one member is never written** (section 6) is the discriminator
that survives both tells, because deadness is measured on the emitted program rather than
inferred by alignment.

### name -> {addresses}

The map is **legitimately** many-to-many, as `TScreen.CreateScreen.bmx` cautions, so a name
on two addresses is not by itself a defect. MEASURED: **no name in the corpus is emitted at
two addresses** -- `assemble.py` emits exactly one `Global` per canonical name by
construction, so this direction cannot produce a split. What it *can* produce, and does, is
the deliberate-reuse case being mistaken for an alias and merged. I found no instance of that
having happened.

What the reverse direction *does* surface is names the solver could not pin at all
(tier `AMBIGUOUS`/`UNGROUNDED`) yet the corpus still uses. Two of the confirmed root causes
sit in that population (`g_gfxw`, `g_gfx_width`, `g_eng_hasjoystick`, `g_pitchmargin` are all
unpinned singletons with no alias row), which makes **"unpinned + never written"** the single
highest-yield query in this audit.

---

## 6. Split-slot victims: read but never written

`scripts/find_dead_globals.py` against the current assembly: **1,697 Globals declared, 171
never written** (CRITICAL 16, HIGH 17, MEDIUM 7, LOW 131). Cross-referencing those against
the address map gives **7 slots where one name is written and a co-resident name is not** --
the exact shape of the `g_currentscreen`/`g_curscreen` bug:

| Address | Live (written) name | Dead name | Verdict |
|---|---|---|---|
| `0x00C6EFE4` | `g_engine_int162` | `g_engine_gfxw` (+ unpinned `g_gfxw`, `g_gfx_width`) | **REAL -- root cause A** |
| `0x00C6F028` | `g_profile` | `g_plr` | **REAL -- root cause C** |
| `0x00C5D638` | `g_goalline` | `g_pitch_int17` (5 reads) | **Likely real.** Both `Int`, both pitch geometry, tiers CERTAIN/STRONG -- type-coherent, so the noise tells do not fire. Not yet confirmed against the binary. |
| `0x00C6E294` | `g_allhorses:TList` | `g_stable_tbl01:TGadget` | Type-incoherent, probably noise; low priority (stable screen, not one of the four bugs). |
| `0x00C6E298` | `g_horselist2`/`g_runners:TList` | `g_stable_tbl02:TGadget` | as above |
| `0x00C6EFD4` | `g_matchtime` | `g_player_int36` (1 read) | Low blast radius. |
| `0x00C6F0D4` | `g_object860:TSound` | `g_sound:TSound` (2 reads) | Type-coherent; plausible real split, audio path. |

### Dead Globals on the four bug paths, not yet tied to a split

MEASURED as never written; each is a candidate for a *different* alias-table gap:

* **Input** -- `g_eng_hasjoystick` (4 reads, all in `TJoy.Update`). Unpinned, no alias row.
  Because it is 0, `TJoy.Update:7054/7094/7121` `If g_eng_hasjoystick <> 0` never fires and
  `:7145` `If g_eng_hasjoystick = 0 Or (...)` short-circuits true. INFERRED: joystick/gamepad
  input is dead. **This does not by itself explain arrow keys** -- I found no `KEY_LEFT`/
  `KEY_RIGHT`/`KeyDown` arrow handling anywhere in the emitted program (MEASURED, grep
  returned only two locale-string hits), which is itself a finding: the arrow-key path may
  simply be unrecovered rather than mis-wired.
* **Training** -- `g_training_setpiecex`, `g_training_setpiecey` (root cause B).
* **Rendering** -- `g_pitch_int05` (26 reads, `Select` scrutinee in `TPitch.DrawFans` -- a
  dead selector means always the same branch), `g_pitchmargin` (4 reads, the cull margin in
  `CheckSideLines`: with 0 the sideline test loses its tolerance band), `g_pitch_int17`,
  `g_cam_offx/offy/targetx/targety`, `g_campan_rate*`.
* **`g_screen_top`** -- flagged in the report itself as *"alias of `g_screen_float01`
  @ 0x00C61724, merge REFUSED"*. A known-but-declined merge that is producing a dead read.
* `g_diffname` (MEDIUM, 3 reads) -- `TScreen.SetActive(g_diffname, "")` after choosing a
  difficulty navigates to `""`.

---

## 7. Shortest remaining path

I did **not** reach a root cause for the arrow-key or quit-crash symptoms. Honest status:

* **Arrow keys** -- narrowed, not solved. Ruled out: it is not a type conflict, and it is not
  a split on any gadget/input Global I could find (`g_activegadget`, `g_inpname`,
  `g_inputtext` are all live and correctly typed). The strongest lead is that **no arrow-key
  read exists in the emitted program at all**. Deciding experiment: find the original's
  `KeyDown`/`KeyHit` call sites (scan `NSS5.exe` for calls to the `brl.polledinput` thunks
  listed in `extracted/runtime_helpers.tsv` -- **do not edit that file**, a fix is in flight)
  and check each against `extracted/decomp_todo.txt`. If they are unrecovered, this is a
  coverage gap, not a wiring bug, and belongs to a different worker.
* **Quit AV** -- not investigated to a conclusion. Nothing in the dead-Global or split-slot
  population is on a shutdown path (the only `quit` names are three buttons, all live and all
  benignly conflicted `TButton vs TGadget` with `TButton` correctly winning). INFERRED: a quit
  crash is more likely a `Delete`/refcount or an ordering problem than a wiring one. Deciding
  experiment: `debugger_attach` to the **original** `NSS5.exe`, breakpoint the shutdown path,
  and compare the teardown order against `extracted/module_emission_order.tsv`.
* **Emote sprite** -- ruled out on the animation-array hypothesis (section 1: the
  `Int[] vs TList` conflicts are phantoms and all four arrays are correctly written). Root
  cause A predicts briefly-misplaced sprites via `TScreenMessage.Create`, which may account
  for the symptom if what was observed was a *misplaced* rather than a *wrong* sprite. Not
  confirmed.

### Recommended fixes (for whoever owns the tables -- I edited nothing)

1. Add `0x00C6EFE4  g_engine_int162  g_engine_gfxw` to `extracted/global_alias_overrides.tsv`,
   plus rows folding the unpinned `g_gfxw` and `g_gfx_width` onto the same canonical. Evidence:
   `TScreen.Draw@0x00510DFC` pushes `[0xc6efe4]` into `SetViewport`; `SetUpGraphics@0x00506AF6`
   is the only writer.
2. **Correct the transposed rows** `global_alias_unified.tsv:584-585` (or override them),
   restoring `g_tr_x2 -> ...setpiecex` / `g_tr_y2 -> ...setpiecey`. Evidence:
   `0x00580A0D` argument order and the `[CFD8]=0` / `[CFDC]=-10.0` initialiser.
   Also fix `global_address_map.tsv`, which shares the error. Note this pair is *also* dead --
   fix the transposition **before** reviving the writes, or a masked bug becomes a live one.
3. Add `0x00C6F028  g_plr  g_profile` to the alias overrides **and** file a correction against
   `TScreen_ReportBoss.ButtonPlay.bmx` -- the call must become
   `g_profile.NextPlayButton()`. Note this changes the *source* but not the *bytes*; the body
   will still verify 34/34.
4. Consider making `assemble.py` fail loudly when two alias tables map the same address to
   *different* canonicals (root cause B would have been caught at build time by that check),
   and when a table maps a pair of adjacent addresses to a pair of canonicals in swapped
   order.

---

## 8. Scope and honesty notes

* No file under `src/recovered*`, no `extracted/runtime_helpers.tsv`, no
  `extracted/brl_functions.tsv`, and no shared assembly was written. `assemble.py` was
  **imported** to call `global_alias_map()` and `global_overrides()`; it was never run.
* Read/write counts come from the emitted `src/assembled/nss5_assembled.bmx` as it stood at
  mtime 2026-08-22 19:49, reusing `find_dead_globals.py`'s own regex battery rather than a
  reimplementation. Other workers are mid-sweep, so those counts are a snapshot.
* **Nothing here was executed.** Every runtime consequence is INFERRED from BlitzMax
  semantics; every address, instruction, vtable slot and emitted declaration is MEASURED.
  The live debugger was not needed for A, B or C -- the static evidence is decisive -- but it
  is the right tool for the quit-crash question left open in section 7.
