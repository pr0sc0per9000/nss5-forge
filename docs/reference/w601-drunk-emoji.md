# w601 - "drunk" emoji face on pressing Z (training start)

**Verdict: root cause found. MEASURED against NSS5.exe. No fix applied.**

The defect is NOT in any recovered body. Every body involved is byte-identical.
It is a **two-name swap in `extracted/global_address_map.tsv`** that
`scripts/assemble.py`'s alias map then propagates, turning one harmless statement in
`TTraining.StartChallenge` into `g_matchtime = 0`.

## The one line

`src/recovered/TTraining.StartChallenge.bmx` (VA 0x0057FD35, 95/95 byte-identical):

    g_tr_prevscreen = g_tr_screen

Its own header annotates the addresses **correctly**:

    '   Global g_tr_screen:Int      (0x00C6EFD4)
    '   Global g_tr_prevscreen:Int  (0x00C6CFA0)

and the original agrees (MEASURED, `python scripts/disasm.py 0x0057FD35 30`):

    0x0057FD38  a1d4efc600   mov eax, dword ptr [0xc6efd4]   ; READ  the match clock
    0x0057FD3D  a3a0cfc600   mov dword ptr [0xc6cfa0], eax   ; WRITE the training tick stamp

So the original statement is `g_train_lasttick = g_matchtime` - stamp the per-second
countdown tick at challenge start.

## The swap

`extracted/global_address_map.tsv` attributes the two names to each other's addresses:

    2622: g_tr_prevscreen   0x00C6EFD4   STRONG  Int  1  forced in 1 body
    2623: g_tr_screen       0x00C6CFA0   STRONG  Int  1  forced in 1 body

Both rows are wrong; they are exactly transposed. `extracted/global_alias_unified.tsv:663`
then inherits it:

    0x00C6EFD4   g_tr_prevscreen -> g_matchtime   descriptive, 6 files; alias tier STRONG

`assemble.global_alias_map()` therefore returns `g_tr_prevscreen -> g_matchtime` and leaves
`g_tr_screen` canonical (it "owns" 0x00C6CFA0, which no other file names `g_tr_screen`).

## What gets emitted

`src/assembled/nss5_assembled.bmx:42182`

    Function StartChallenge:Int()
            g_matchtime = g_tr_screen      <-- was: g_train_lasttick = g_matchtime
            g_training_state = 1
            ...

`g_tr_screen` is declared at line 46733 and **never written anywhere in the program**
(grep for `g_tr_screen` returns exactly two hits: this read and the declaration). It is 0.

**The emitted statement is `g_matchtime = 0`.**

The real 0x00C6CFA0 slot - named `g_train_lasttick` by `TTraining.Update.bmx`, a *third*
name for the same address, also unmerged - never receives its stamp.

## Causal chain to the drunk face

1. Z -> `TEngine.SkipTime` -> `Select g_training_state / Case 0 -> TTraining.StartChallenge()`
   (`src/recovered/TEngine.SkipTime.bmx:55`).
2. `g_matchtime = g_tr_screen` executes: **g_matchtime := 0**.
3. `TPlayer.Render` (VA 0x004EE340, byte-identical) runs the `If Self.newstar` status-icon
   chain (`src/assembled/nss5_assembled.bmx:11684`):
   * `g_profile.injury <> 0` - false (healthy)
   * `Self.matchstats.reds <> 0` - false
   * `Self.selectionno > 10` - false (human player)
   * `ElseIf g_matchtime < Self.boozedup + 2500` -> `0 < 0 + 2500` -> **TRUE**
4. `Self.boozedup` is 0: MEASURED in the original's `TPlayer.New` at 0x004EBCB4 -
   `0x004EBD2C  c7433400000000  mov dword ptr [ebx + 0x34], 0`, and `boozedup` is
   `object_model.json`'s reflected name for TPlayer +0x34. Our `Field boozedup:Int`
   (line 11118) also defaults to 0, so this half matches the original exactly - the
   default is NOT the bug.
5. `If g_matchtime Mod 500 < 350` -> `0 Mod 500 = 0 < 350` -> TRUE ->
   `TDrawOb.AddDrawOb(g_img_booze, px, py - 35.0, ...)`.
   `g_img_booze` correctly holds `EngineMedia/Match/Other/BoozeFace.png`
   (`TEngine.SetUp.bmx:143`, assembled line 3480) and the alias map does not disturb it.
   `py - 35` is directly above the player's head. **That is the drunk face.**
6. On the next pass of the frame loop, `g_matchtime = MilliSecs() - g_pausedms`
   (`GameMain` 0x004BCCDB, `TEngine.MatchLoop` 0x004CF671) restores a large value, the
   comparison goes false, and the face disappears.

Secondary observables from the same line, worth using to confirm:
* `shown = 1` forces `g_arrowalpha = 0`, so the energy arrow above the player is
  suppressed on the same frames.
* `g_train_lasttick` is never stamped, so the training countdown's
  `If g_matchtime > g_train_lasttick + 1000` fires on a stale/zero stamp - the countdown
  should misbehave on the first tick of every challenge.
* Any other `g_matchtime`-relative timer sampled on that frame (screen messages, set-piece
  power, replay) sees a clock that jumped to 0 and back.

## Honest gap

The mechanism above produces the face on **at least the frame in which StartChallenge ran**.
I did not measure how many rendered frames actually see `g_matchtime = 0`; the reported
~0.5 s implies more than one. Both loops recompute the clock at the top of every iteration,
so on my reading it should be a short flash. Either the estimate is a human eyeball figure,
or something in the training-entry path (`TEngine.SetUpSetPiece(0,1,0,0)` is called on the
very next line) renders several passes before the clock is re-derived. This does not change
the root cause - nothing else can make `g_matchtime < 2500` at that moment - but the exact
frame count is INFERRED, not MEASURED.

## Second, independent defect found on the way (same address family, NOT the drunk face)

0x00C6EFD8 is split the same way:

    0x00c6efd8   g_pausedms(refs=14,writes=1)   g_screen_int20(refs=3,writes=1)

The original initialises it once at module init (0x004BA034), MEASURED:

    0x004BB926  call 0x4a4860              ; MilliSecs()
    0x004BB92B  mov  dword ptr [0xc6efd8], eax
    0x004BB930  or   dword ptr [0xc6e2ac], 0x80   ; bcc per-Global "initialised" bit
    0x004BB93A  push dword ptr [0xc6efd8]
    0x004BB940  call 0x59f0f4              ; SeedRnd

Our module tail emits it under `globals_final.tsv`'s name for that address
(`src/assembled/nss5_assembled.bmx:48707`):

    g_screen_int20 = MilliSecs()
    SeedRnd(g_screen_int20)

`g_screen_int20` never merges with `g_pausedms`, so the epoch lands in a dead global and
`g_pausedms` stays 0. Every `g_matchtime = MilliSecs() - g_pausedms` therefore yields raw
`timeGetTime()` (ms since Windows boot) instead of ms since program start. Mostly benign
because almost every consumer takes a difference - but it makes `g_matchtime` negative on a
machine with more than ~24.85 days of uptime, at which point the drunk/sick/sad/tired chain
in `TPlayer.Render` fires *permanently*. Report it, do not conflate it with the Z-press bug.

Same sweep also shows the debug-overlay question left open in `GameMain.bmx` is answered:
0x00C6EF50 (`g_engine_int161`) is initialised at module init from
`ReadSettingFloat(..., "debug", 0.0, 2.0)`.

## Tooling written for this (read-only, no corpus edits)

* `scripts/workflow/w601_initsweep.py` - every store to a game Global inside the original's
  module-init function 0x004BA034..0x004BCCDB (100 distinct Globals with initialisers).
* `scripts/workflow/w601_initdiff.py`  - those vs. what the assembled build declares.
* `scripts/workflow/w601_split.py`     - **the general detector.** One address in NSS5.exe,
  several names in the corpus, not collapsed by `assemble.global_alias_map()`. 106 hits.
  This is the family the drunk-face bug belongs to and it is worth sweeping properly.
* `scripts/workflow/w601_deadinit.py`  - Globals written but never read in the assembled
  build (78 hits) - the downstream signature of the same defect.

## Proposed fix (NOT applied)

Transpose the two addresses in `extracted/global_address_map.tsv`:

    g_tr_prevscreen   0x00C6CFA0
    g_tr_screen       0x00C6EFD4

and drop/repoint the derived row `extracted/global_alias_unified.tsv:663`
(`0x00C6EFD4  g_tr_prevscreen -> g_matchtime`) so that instead
`g_tr_screen -> g_matchtime` and `g_tr_prevscreen` merges with `g_train_lasttick`
(0x00C6CFA0, `TTraining.Update.bmx:14`). `TTraining.StartChallenge` then assembles as
`g_train_lasttick = g_matchtime`, which is what the original's two instructions do.
Rerun `scripts/build_alias_map.py` / `scripts/emit_unified_aliases.py` after the edit.

`extracted/global_address_map.tsv` is shared and other workers are mid-sweep, so this edit
was deliberately NOT made.
