# Corpus integrity audit - every body re-verified against NSS5.exe

> **Method:** `harness.try_method` / `harness.try_function`, `NSS5_NO_LEARN=1` on every run
> **Scope:** all 1,973 bodies in all four trees, five complete or partial passes
> **Worker:** 385 (trees `385`, `385b`..`385l`), 2026-08-22, 19:14 to 20:08 local
> **Raw rows:** `scripts/workflow/w385_out/all_{a,b,c,d1,d2}.tsv` (untracked working files)

A header saying `byte-identical vs NSS5.exe` is a claim, and `progress.py` counts it. This
audit re-ran the byte oracle over every body that carries a VA header, so that each of
those claims was checked rather than believed. Nothing was fixed here; the bodies belong to
other passes.

---

## 1. What was run, and why it is not `reverify.py`

`scripts/reverify.py --shard i/n` is the existing guard and it is the right tool, but it
covers **`src/recovered/` only** and sends **every** file through `try_method`. That leaves
two gaps this audit had to close:

| gap | consequence |
|---|---|
| `src/recovered_module/`, `src/recovered_thirdparty/`, `src/recovered_unverified/` are not walked | 264 bodies (115,849 bytes, 13% of the corpus) have never been re-checked by anything |
| a module-level `Function` fed to `try_method` | bogus `ERROR` rows; an earlier sweep reported 16 of them for this reason alone |

So the sweep used the right entry point per body:

* `<Type>.<Method>.bmx` -> `try_method(Type, Method, reverify.body_of(text))`
* `<name>.bmx` with no dot, and `Fn_<VA>.<name>.bmx` -> `try_function(name, sig, body, VA)`

Module Functions were handed **their own declared parameter list** through
`try_function(decl=...)` rather than the reflection-signature lowering. Five of them declare
`String Var` / `Int Var` parameters that the signature grammar cannot express, and the
regenerated `a0..` list then fails to compile - which reads exactly like a broken body.
`LoadImageChecked.bmx` additionally defines a second module Function beside its target, so
siblings are re-emitted at module scope through the `'!Raw` pragma; without that the probe
fails with `Identifier 'MissingArtImage' not found`, again indistinguishable from a defect.

**Every one of the three genuine defects below is in the part of the corpus
`reverify.py` does not walk.** `LoadImageChecked.bmx`'s own header predicted this in
writing: "This file is in src/recovered_module/ and is NOT covered by scripts/reverify.py,
so nothing will flag it."

---

## 2. Result

| pass | when | trees | MATCH | MISMATCH | BUILD_FAIL | ERROR |
|---|---|---|---|---|---|---|
| A | 19:14-19:26 | 385, 385b..385h | 1,930 | 39 | 1 | 3 |
| B | 19:31-19:43 | 385b..385i | 1,915 | 54 | 1 | 3 |
| C | 19:52-20:06 | 385c..385j | 1,961 | 8 | 1 | 3 |
| D1/D2 | 20:03-20:05 | 385 / 385b | (59-body re-check of everything that ever failed) | | | |

The corpus moved underneath the audit; section 5 is about that. The **final** state,
reproduced on at least three separate worker trees per body, is:

* **(a) header claims byte-identical, oracle disagrees: 3 bodies, 778 bytes**
* **(b) BUILD_FAIL: 1 body** (already correctly unmarked by its owner at 19:32)
* **(c) oracle MATCHes, header carries no marker: 1 body, 2,848 bytes**
* two false-alarm classes, 4 bodies, recorded in section 6 so nobody re-reports them

Corrected numerator: 867,506 - 778 + 2,848 = **869,576 of 873,829 bytes (99.51%)**, against
the 99.3% `progress.py` reports.

---

## 3. (a) Headers that claim a byte match the oracle refuses

All three are the same defect: a **deliberate boot-time divergence was added to the body on
2026-08-18 and the match marker was left in the header.** Each file documents its own
divergence in prose; none of them removed the claim. `localise_diff` reports real
length-changing gaps in every case, so these are byte differences, not name divergences.

| body | VA | header claims | oracle (5 runs, 5 trees) | localise_diff |
|---|---|---|---|---|
| `src/recovered_module/LoadImageChecked.bmx` | 0x004bc372 | 251/251 | MISMATCH, ours **253** bytes, first_diff +6 | 3 gaps, +2 bytes; 6 substitutions |
| `src/recovered_module/LoadSoundChecked.bmx` | 0x004bc564 | 256/256 | MISMATCH, ours **253** bytes, first_diff +6 | 4 gaps, -3 bytes; 6 substitutions |
| `src/recovered_module/LoadAnimImageChecked.bmx` | 0x004bc664 | 271/271 | MISMATCH, ours **272** bytes, first_diff +22 | 2 gaps, +1 byte |

`LoadImageChecked` states the divergence outright:

```
' # BOOT SHIM -- DELIBERATE DIVERGENCE. Both failure paths now return a       #
' # visible placeholder image instead of Null (and the DebugStop is gone).    #
' # Delete MissingArtImage() and restore `Return Null` / `DebugStop` to get   #
' # the original behaviour back.
```

and its line 3 still reads `byte-identical vs NSS5.exe (251/251, ...)`. The other two carry
`' BOOT SHIM: DebugStop removed` inline. The measured cost of the shims is exactly the
length delta: `LoadSoundChecked` drops two `call 0x005B9660` (DebugStop) sites, -3 bytes;
`LoadImageChecked` drops them and gains a `MissingArtImage()` call, +2.

The shim also perturbs register allocation, which is why the diff starts at +6 rather than
at the shim: the original opens `mov esi,[ebp+8] / mov ebx,[ebp+0xc]` and ours emits the
two the other way round, then substitutes `push ebx` for `push esi` at +16, +40, +69, +92
and +107. That is downstream of the source change, not an independent defect.

Two siblings of the same family, `LoadPixmapChecked` (247/247) and `LoadFontChecked`
(257/257), keep their `DebugStop` and **MATCH**, which is the control: the family is not
inherently unverifiable, only the three that were shimmed.

**Not fixed here.** Restoring the original bodies re-breaks the boot for a missing asset,
which is why the shims exist; the honest minimum is to drop the marker from those three
headers until the Global-aliasing defect the shim works around is closed.

---

## 4. (b) BUILD_FAIL, and (c) a match nobody is counting

**(b)** `src/recovered_unverified/ZipFile.getFileInfoByName.bmx` (0x0058dda7, 28 bytes) -
`BUILD_FAIL` in all five passes:

```
Compile Error: Identifier 'getEntryByName' not found
```

`m_zipFileList`'s type `TZipFileList` has no row in `object_model.json` or
`class_tables.tsv`, so the placeholder-type generator emits an empty stub and the
forwarding call cannot resolve. The header carried `byte-identical vs NSS5.exe` on one line
while line 1 said `BUILD_FAIL, oracle-confirmed`; **that marker was removed at 19:32 during
this audit**, so the body is now correctly counted as unmatched. `check_docs.py` already has
a `SELF_DECLARED_BUILD_FAIL` check for exactly this shape and it now passes.

**(c)** `src/recovered_unverified/Fn_0058BC02.Md5.bmx` (0x0058bc02, **2,848 bytes**) -
**MATCH 2848/2848, mode=reloc**, reproduced on four trees (pass C shard tree, 385, 385b,
385c) under `NSS5_NO_LEARN=1`. Its header opens `UNVERIFIED, and deliberately so`, written
when the body could not certify because `runtime_helpers.tsv` had the case-conversion rows
the wrong way round. That table was corrected at 19:17 and the body's own last line was
switched to `.ToLower()` at 19:45; the header's opening verdict was not updated. This is the
largest single body `progress.py` reports as outstanding and it has been matching since.

No other body in the corpus matches without carrying the marker. `TScreen.CreateScreen`
(0x005103c3, 381 bytes) was in this state at 19:14 and its owner added the marker at 19:22.

---

## 5. The corpus is a live tree, and the audit measured that too

Between pass A and pass C a concurrent pass corrected
`extracted/runtime_helpers.tsv` and then rewrote 47 body files. The audit caught the whole
sequence, which is worth recording because it is the single largest false-MATCH episode
this corpus has had, and because a sweep run an hour earlier or later would have reported
completely different numbers.

**The mechanism.** `runtime_helpers.tsv` named `0x004A7410` `_brl_retro_Lower` and
`0x004A74E0` `_brl_retro_Upper`. Both were wrong. Read off the original's own instruction
bytes:

```
0x004A7410   lea eax,[edi-0x61]  ; 'a'
             cmp eax,0x19        ; ..'z'
             and edi,0xFFFFFFDF  ; clear bit 5  -> UPPERCASES   = _bbStringToUpper
0x004A74E0   lea eax,[edi-0x41]  ; 'A'
             cmp eax,0x19        ; ..'Z'
             or  edi,0x20        ; set bit 5    -> lowercases   = _bbStringToLower
```

Both are ~190-byte functions with a binary-searched Unicode table, so neither can be one of
the 21-byte `brl.retro` wrappers (`0x0059C8FD` Lower, `0x0059C912` Upper), which **call**
these two. Masking keys on the name, so the wrong rows masked `Lower(` against the
upper-caser and blessed **30 bodies whose case conversion runs backwards** - the identical
failure shape as the `_bbStringStartsWith` / `_bbStringContains` episode in
codegen-patterns 15.5, at three times the blast radius.

At 19:14 all 30 reported MISMATCH against the corrected table. Every one was
`localise_diff` **CLEAN**, i.e. a NAME divergence at a single call operand and nothing else:

| body | first_diff | original call target | localise_diff |
|---|---|---|---|
| `TKit.SetUp` | +28 | 0x004a7410 | CLEAN |
| `TPlayer.BlockTackle` | +239 | 0x004a7410 | CLEAN |
| `TPlayer.CheckOffside` | +66 | 0x004a7410 | CLEAN |
| `TPlayer.DoAnimCelebrate` | +576 | 0x004a7410 | CLEAN |
| `TPlayer.RecordPlayerStats` | +1199 | 0x004a7410 | CLEAN |
| `TPlayer.RedCard` | +120 | 0x004a7410 | CLEAN |
| `TPlayer.SlideBall` | +277 | 0x004a7410 | CLEAN |
| `TPlayer.UpdateMovement` | +3835 | 0x004a7410 | CLEAN |
| `TPlayer.YellowCard` | +152 | 0x004a7410 | CLEAN |
| `TProfile.CheckSponsorExpiry` | +118 | 0x004a7410 | CLEAN |
| `TProfile.LoseRandomSkillPoint` | +167 | 0x004a7410 | CLEAN |
| `TProfile.OfferSponsorship` | +145 | 0x004a7410 | CLEAN |
| `TScreen.DoProgressBar` | +96 | 0x004a7410 | CLEAN |
| `TScreen.SetActive` | +94 | 0x004a74e0 | CLEAN |
| `TScreen.SetActiveGadget` | +87 | 0x004a74e0 | CLEAN |
| `TScreen_Controls.CreateScreen` | +3190 | 0x004a7410 | CLEAN |
| `TScreen_EditKits.UpdateKitInp` | +42 | 0x004a7410 | CLEAN |
| `TScreen_Finances.CreateScreen` | +1683 | 0x004a7410 | CLEAN |
| `TScreen_Interview.ButtonAddText` | +315 | 0x004a74e0 | CLEAN |
| `TScreen_Newspaper.Draw` | +275 | 0x004a7410 | CLEAN |
| `TScreen_Pairs.CreateScreen` | +150 | 0x004a7410 | CLEAN |
| `TScreen_WebPage.SetUpScreen` | +209 | 0x004a7410 | CLEAN |
| `TTraining.Fail` | +70 | 0x004a7410 | CLEAN |
| `TTraining.Success` | +90 | 0x004a7410 | CLEAN |
| `TTraining.TimeUp` | +39 | 0x004a7410 | CLEAN |
| `TBall.NewController` | +910 | 0x004a7410 | CLEAN |
| `TScreen_GameMenu.UpdateNavPanel` | +486 | 0x004a7410 | CLEAN |
| `TScreen_ReportBoss.SetUpScreen` | +793 | 0x004a7410 | CLEAN |
| `TTeam.CheckComManagement` | +733 | 0x004a7410 | CLEAN |
| `TTraining.SetUpTraining_Pace` | +458 | 0x004a7410 | CLEAN |

The direction was checked independently rather than assumed, because a rename that makes
the oracle green can break the game. `TPlayer.RedCard`, four variants of one body, one tree,
`NSS5_NO_LEARN=1`:

```
as on disk  Lower(GetText("Red Card!"))     MISMATCH  128/163  first_diff=120
            Upper(GetText("Red Card!"))     MISMATCH  128/163  first_diff=120
            GetText("Red Card!").ToUpper()  MATCH     163/163  mode=reloc
            GetText("Red Card!").ToLower()  MISMATCH  129/163  first_diff=120
```

Only the String **method** form emits a direct call to the C-runtime function; the
`brl.retro` `Lower()`/`Upper()` Functions emit a call to the 21-byte wrapper, which is a
different symbol. The discrimination is real in both directions - `.ToLower()` fails - so
this is not a case where any spelling would pass.

**The 15 bodies that were right all along.** 17 bodies call the genuine `brl.retro`
wrappers and legitimately spell it `Lower(` / `Upper(`. Pass B caught 15 of them mid-edit,
MISMATCHing at 19:31; by pass C all 15 were MATCHing again. They are listed here so that a
future sweep that flags them does not "fix" them a second time:
`TBlackJack.CheckPlayerScore`, `TBlackJack.DealersTurn`, `TBlackJack.ShowResult`,
`TClub.CreateClub`, `TCombo.SelectItemByLetter`, `TCompetition.IsCupFinal`,
`TEngine.DoHalfEnds`, `TEngine.DoYourSubstitutionOff`, `TEngine.GoalScored`,
`TEngine.RenderReplayGUI`, `TEngine.RenderScoreboard`, `TEngine.SaveReplay`,
`TEngine.SetUpSetPiece`, `TEngine.SkipMatchTime`, `TEngine.UpdateSetPieceReady`.

**What this costs a sweep.** `helper_map.load_table()` re-reads `runtime_helpers.tsv` on
every single comparison, so a mid-run edit changes verdicts inside one pass. Any corpus
sweep should therefore record the checksum of `extracted/runtime_helpers.tsv` and
`extracted/brl_functions.tsv` at start and end, and re-run anything that ran across a
change. The audit script now also records each body's mtime after its probe and writes
`FILE CHANGED DURING PROBE` into the row when it moved; pass C reported zero.

---

## 6. False alarms - measured, and not defects

Recorded here because both look exactly like category (a) in a TSV and both cost a build to
disprove.

**6.1 Three fontmachine root Types cannot go through `try_method` at all.**

| body | VA | `try_method` | `try_function` VA route |
|---|---|---|---|
| `EConstBlend.Delete` | 0x00592273 | ERROR `unpack_from requires a buffer of at least 14839019 bytes` | **MATCH 14/14 exact** |
| `EConstBlend.GetCurrent` | 0x00592281 | ERROR (same shape) | **MATCH 14/14 reloc, masked=1** |
| `eDrawCharStatus.Delete` | 0x00592688 | ERROR (same shape) | **MATCH 14/14 exact** |

`EConstBlend` and `eDrawCharStatus` are Const-only Types with no `class_tables.tsv` row, so
`object_model.json`'s method offsets for them are **raw VAs, not vtable slots**, and
`bytematch.find_method` reads past the end of the image trying to treat one as a slot. Each
file's header already says so and records that it was verified through `try_function`.
Confirmed MATCH on two trees (385, 385d). **Any corpus tool must special-case these three
or it will report three errors forever.**

**6.2 `TPitch.DrawFans` is toolchain-nondeterministic, and its header is honest.**
From byte-identical probe source, `bcc` emits several outputs of this 4,664-byte body. 24
builds, two trees, `NSS5_NO_LEARN=1`:

| result | 385j (14 builds) | 385k (10 builds) |
|---|---|---|
| MATCH 4664/4664 mode=reloc | 8 | 5 |
| MISMATCH 4004/4664 first_diff=3052 | 4 | 0 |
| MISMATCH 4046/4664 first_diff=3161 | 1 | 2 |
| MISMATCH 4110/4664 first_diff=3052 | 1 | 2 |
| MISMATCH 2583/4664 mode=len | 0 | 1 |

13 of 24 MATCH (54%), and every mismatch signature is one its own header already tabulates
from a 60-build measurement. A single MISMATCH row for this body is not evidence against
it; re-run until it matches. It should be excluded from any pass/fail corpus gate, or given
a retry budget.

---

## 7. What would have caught these

1. **Walk all four trees in `reverify.py`, and dispatch on the filename.** The three real
   defects, the one BUILD_FAIL and the 2,848-byte undercount are all outside
   `src/recovered/`. This is the single highest-value change.
2. **A body that declares a deliberate divergence must not carry the match marker.**
   `check_docs.py` already refuses `BUILD_FAIL` beside the marker; the same check for
   `BOOT SHIM`, `DELIBERATE DIVERGENCE` and `SUBSTITUTED` would have caught all three
   category (a) bodies without a single build.
3. **Checksum the shared name tables around any sweep.** A row in `runtime_helpers.tsv`
   changes 30 verdicts, and the two tables are re-read per comparison.
4. **Keep a named retry list for nondeterministic bodies.** Today that list is
   `TPitch.DrawFans` and nothing else.

---

## 8. Reproducing this

The drivers are untracked working files under `scripts/workflow/` (`w385_audit.py`,
`w385_launch.py`, `w385_classify.py`), per the repo convention for one-off analysis. The
method needs no private tooling:

```bash
# every body, right entry point per body, learning off, sharded across worker trees
NSS5_WORKER=<yours> NSS5_NO_LEARN=1 python scripts/workflow/w385_audit.py --shard 0/8 --out shard0.tsv

# classify one failure: NAME divergence at a call operand, or a real byte difference
NSS5_WORKER=<yours> NSS5_NO_LEARN=1 python scripts/workflow/w385_classify.py src/recovered/<Type>.<Method>.bmx
```

A full pass is about 13 minutes on eight trees, roughly 3 seconds per body. Copying a worker
tree is 200 MB and 30 to 60 seconds, once per tree.
