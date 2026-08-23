# The Steam exclusion, re-examined

**Finding: the exclusion conflates two different things -- a body that cannot SHIP, and a body
that cannot be VERIFIED. They are separable, the oracle already separates them, and on the
evidence none of the four excluded bodies is permanently unverifiable.**

This does not make `STEAM_EXCLUDE` wrong. Its reasoning about the *playable build* is correct
and well-evidenced. What follows is a refinement of the conclusion drawn from it.

---

## 1. What the exclusion currently claims

`scripts/progress.py` drops 4 bodies (1,232 bytes) from both numerator and denominator, on
this reasoning:

> A body that can never be present in a working program can also never report `byte-identical
> vs NSS5.exe` and remain playable -- closing it and shipping it are mutually exclusive,
> permanently, by construction, not because the work is unfinished. Counting its bytes in the
> denominator below therefore does not measure remaining work; it measures a wall nobody is
> meant to climb.

The mechanism is real and documented: a `'!Import ".../libsteamstub.a"` pragma puts
`STEAMSTUB.DLL` in the exe's import table, `src/assembled/` does not carry that DLL, and the
Windows loader kills the process with `STATUS_DLL_NOT_FOUND` before any code runs -- not just
the guarded call inside the body.

---

## 2. Why that does not extend to verification

`STATUS_DLL_NOT_FOUND` is a **loader** failure. It happens when a process is **executed**.

The byte oracle never executes anything. `harness.try_method` (`scripts/harness.py:1205`) and
`harness.try_function` (`:1380`) each:

1. write a probe `.bmx`,
2. build it with `bmk makeapp -r -t console` (`:1223`, `:1422`),
3. **read the resulting `probe.exe`'s bytes** and compare them against `NSS5.exe`
   (`:1270-1271`, `:1471-1472`).

There is no execution step. A missing DLL cannot affect a comparison that only ever reads the
file. `libsteamstub.a` is a static archive present at `extern/steamstub/`, so the probe *links*
fine; the DLL is needed only at run time, and run time never arrives.

**Verified empirically.** `TProfile.CheckAchievement`, one of the four excluded bodies, run
through the oracle under `NSS5_NO_LEARN=1` in an isolated worker tree:

```
CheckAchievement: MISMATCH 148 / 625   first_diff 14
```

Not `BUILD_FAIL`. Not a loader kill. An ordinary verdict on an ordinary unfinished body.

---

## 3. The actual state of all four

| body | bytes | actual state |
|---|---:|---|
| `SteamInit` | 158 | **already byte-identical** -- 158/158, `mode=reloc`, verified under `NSS5_NO_LEARN=1`, stated in its own header |
| `Fn_0058D90B.SyncSteamAchievements` | 124 | **already byte-identical** -- 124/124, `mode=reloc`, stated in its own header |
| `Fn_0058D987.SteamPostPlayerValue` | 325 | near miss, `delta +2`, one fully-characterised defect, verified via `try_function` |
| `TProfile.CheckAchievement` | 625 | `MISMATCH 148/625`, measured fresh (§2) |

**282 of the 1,232 excluded bytes are already proven byte-identical.** The remaining 950 are
ordinary reconstruction work, one of them two bytes from closing.

So the sentence *"it measures a wall nobody is meant to climb"* is not true of these four. Two
have already been climbed. The other two are ordinary slopes.

---

## 4. What is actually mutually exclusive

Precisely this, and only this:

> A body carrying `'!Import ".../libsteamstub.a"` cannot be in `src/assembled/` **and** have
> that build launch.

That is a statement about **one artifact** -- the playable exe. It says nothing about whether
the body's bytes can be shown to equal the original's, which is what the reconstruction claim
is about. `SteamInit` demonstrates the separation directly: its byte-identical original is
verified *and* kept out of the build, deliberately, with the neutralised stub shipped in its
place. That is exactly the both-at-once the exclusion says is impossible -- because the
"impossible" pairing is only impossible for one body in one build, not for a body and a
measurement.

---

## 5. Consequence for the completion claim

There are two honest finish lines, and they are different numbers:

- **"100% of the game's code is byte-for-byte reconstructed"** -- a claim about
  reconstruction. The Steam bodies belong in this denominator, because they are verifiable.
  Reaching it needs the 950 outstanding Steam bytes done like any others.
- **"the reconstruction builds and plays"** -- a claim about `src/assembled/`. Here the Steam
  bodies are legitimately absent, exactly as they are now, and their absence is a deliberate,
  documented substitution rather than a gap.

The current accounting reports the first number while applying the second one's exclusion
rule, which understates what is provable by 282 already-matched bytes and mislabels 950 bytes
of ordinary work as a permanent wall.

**Recommended (owner's call, not made here):** keep the four out of `src/assembled/` exactly as
they are, and move them from `STEAM_EXCLUDE` into the ordinary corpus with a distinct
`VERIFIED_NOT_SHIPPED` marker -- so the reconstruction percentage counts what has actually been
proven, while the build keeps doing the right thing. That preserves every genuine fact the
current exclusion protects and drops the one inference that does not hold.

Whatever is chosen, it should be chosen explicitly: an exclusion that silently converts
"cannot ship" into "cannot count" is the kind of quiet denominator drift `progress.py`'s own
header warns about at length.

---

## 6. Outcome, and two corrections to the analysis above

**Acted on 2026-08-22 (worker 322).** `STEAM_EXCLUDE` is gone from `scripts/progress.py`,
replaced by `VERIFIED_NOT_SHIPPED`. The four bodies are ordinary corpus members again --
numerator and denominator both -- and the report gained a `NOT IN THE SHIPPED BUILD`
section that prints each one's bytes, VA, live MATCHED state and the mechanism that keeps
it out of `src/assembled/`. Every per-body fact the old comment block carried is preserved,
including the reasoning for keeping `TProfile.SaveGame` and `TProfile.LoadSavedGame` off the
list. The word VERIFIED in the new name qualifies NOT_SHIPPED and nothing else: each
`OMITTED` entry is now cross-checked against the skip set that actually omits it, and the
check reports loudly in the report when it cannot be performed.

Measured on one tree, immediately before and after the change:

| | bodies | matched | done | total | pct |
|---|---:|---:|---:|---:|---:|
| before (exclusion applied) | 1,946 | 1,941 | 862,087 | 867,404 | 99.39% |
| after (nothing excluded) | 1,950 | 1,943 | 862,536 | 868,636 | 99.30% |

Denominator +1,232, numerator +449, headline **-0.09 points**. Falling is the correct
direction.

### Correction 1: it was 124 already-matched bytes, not 282

Section 3 counts `SteamInit` as already matched. `progress.py` does not, and did not:
`MATCHED` is the literal phrase `byte-identical vs NSS5.exe`, searched in the first 40 lines
of a body. `SteamInit.bmx` spells it `byte-identical to NSS5.exe` (to, not vs) on line 47.
So at the moment of the change only 124 of the 1,232 bytes were in the numerator, and 449
by the time it landed, because worker 320 closed `SteamPostPlayerValue` (325/325) in
parallel.

That is not a typo to fix in passing. `SteamInit.bmx` compiles a 4-line neutralised stub;
its byte-identical original is a comment beside it. The file therefore does not carry the
marker, and it is recorded in `VERIFIED_NOT_SHIPPED` as `SUBSTITUTED` rather than `OMITTED`.
Whether a substituted body may carry the MATCHED marker is an owner's call, deliberately not
made here; until it is, 158 bytes of proven work sit in the denominator only, which
understates rather than overstates.

### Correction 2: the oracle currently cannot reach these bodies at all

Section 2's central claim -- that the oracle builds and reads, never executes, so
`STATUS_DLL_NOT_FOUND` is irrelevant to it -- is correct, and both byte-identical claims
were re-verified fresh under `NSS5_NO_LEARN=1` on two worker trees:

```
SteamInit              MATCH 158/158  mode=reloc  reloc_masked=18
SyncSteamAchievements  MATCH 124/124  mode=reloc  reloc_masked=8
```

But that took a workaround. On the ordinary path both return `BUILD_FAIL`, reproduced on
both trees:

```
Compile Error: Syntax error in extern block - expecting Const, Global,
Function or Type declaration
```

Root cause, confirmed by dumping `harness.merge_globals()` directly, and independently
reported earlier by worker 278: `merge_globals` de-duplicates `'!Raw` pragma payloads by
bare lowercased text with no awareness of which `Extern` block a line belongs to. A probe
body carrying its own `Extern` block emits `End Extern` first and wins the dedup slot, so
the `End Extern` belonging to `src/recovered_module/Fn_0058D81A.GetClipboardText.bmx`'s
unrelated `Extern "Win32"` block is dropped as a duplicate. That block is left open and
every module Global emitted afterwards lands inside it. It affects every body with its own
`Extern` block, which is all four of these.

Adding `Fn_0058D81A.GetClipboardText.bmx` to `harness.MODULE_SKIP` (the precedent already
set for `SyncSteamAchievements`), or making `merge_globals` dedup per block rather than by
bare text, fixes it. Neither was done here: `harness.py` is shared and several workers build
against it concurrently. The verification above used an in-process, untracked override that
dropped only that one bystander from the probe, touching no compare path and no tracked file.
