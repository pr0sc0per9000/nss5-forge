# Disposition: the three fontmachine `Draw*Text` bodies are equivalent, not matching

**Status: final disposition. No further sweeps.**

`TPrivateBitmapFont`'s three text-drawing methods are the last three bodies in the corpus
whose reconstruction is finished and correct but whose compiled bytes are not the
original's. This document says plainly what differs, why nothing available to this project
can close it, and what that means for how they are counted and stored.

| body | VA | length | verdict |
|---|---|---:|---|
| `DrawFaceText` | 0x00591383 | 1428 | equivalent, not matching |
| `DrawBorderText` | 0x00591917 | 1195 | equivalent, not matching |
| `DrawShadowText` | 0x00591DC2 | 666 | equivalent, not matching |

The mechanism is established elsewhere and is not repeated here. Read
[`spill-tie-x87-precision.md`](spill-tie-x87-precision.md) for it, and
[`allocator-knob-sweep.md`](allocator-knob-sweep.md) for the six compiler hypotheses it
rules out. This document is about disposition only.

---

## 1. The one-sentence version

Each of the three bodies compiles to the original's instruction stream, instruction for
instruction, with the same calls to the same functions and the same references to the same
data; the only difference is that three local variables that get spilled to the stack land
in a different order within an otherwise identical stack frame, and that order is decided
by a floating-point rounding accident inside `bcc.exe` itself.

## 2. What was measured, independently

Worker 384, `NSS5_NO_LEARN=1`, shipped `bin/bcc.exe`, 2026-08-22. This is a fresh
measurement, not a restatement of the earlier pass, and it deliberately does not use
`localise_diff.py`, whose mask set includes call operands and therefore cannot see a body
that calls the wrong function.

| body | harness verdict | length | first_diff | positional `matched` |
|---|---|---|---:|---|
| `DrawFaceText` | MISMATCH, mode=diff | 1428 = 1428 | +78 | 1270 / 1428 |
| `DrawBorderText` | MISMATCH, mode=diff | 1195 = 1195 | +87 | 1086 / 1195 |
| `DrawShadowText` | MISMATCH, mode=diff | 666 = 666 | +87 | 604 / 666 |

Both images were then disassembled in full and lined up instruction by instruction:

| body | instructions, original / ours | instruction boundaries identical | mnemonic or length differences |
|---|---|---|---|
| `DrawFaceText` | 450 / 450 | yes | **none** |
| `DrawBorderText` | 375 / 375 | yes | **none** |
| `DrawShadowText` | 210 / 210 | yes | **none** |

There is no realignment anywhere, no gap, no substituted instruction and no different
addressing form. Every byte that differs was then classified by which field of its
instruction it falls in, with nothing left over:

| body | total differing bytes | `ebp` displacement | `call`/`jmp` rel32 operand | absolute in-image address | unaccounted |
|---|---:|---:|---:|---:|---:|
| `DrawFaceText` | 158 | **6** | 117 | 35 | **0** |
| `DrawBorderText` | 109 | **4** | 78 | 27 | **0** |
| `DrawShadowText` | 62 | **4** | 31 | 27 | **0** |

The rel32 and absolute-address bytes are the ordinary consequence of a probe executable
being laid out differently from `NSS5.exe`. They are not evidence of anything on their own,
so each one was adjudicated rather than assumed (section 3). What is left after that is the
`ebp` column, and only the `ebp` column.

### The stack frame is the same size

`sub esp, 0x24` in `DrawShadowText`'s prologue, and the equivalent in the other two, is
among the bytes that agree. So this is not a bigger or smaller frame: it is the same frame
with three of its slots handed to different variables. In `DrawShadowText` and
`DrawBorderText` two slots are swapped; in `DrawFaceText` three are rotated.

| body | our slot assignment | the original's |
|---|---|---|
| `DrawShadowText` | hasfx `-0x1c`, origin `-0x18`, limit `-0x14` | limit `-0x1c`, origin `-0x18`, hasfx `-0x14` |
| `DrawBorderText` | limit `-0x54`, hasfx `-0x50`, origin `-0x4c` | hasfx `-0x54`, limit `-0x50`, origin `-0x4c` |
| `DrawFaceText` | limit `-0x64`, hasfx `-0x60`, origin `-0x5c` | hasfx `-0x64`, origin `-0x60`, limit `-0x5c` |

`limit` is the `For` loop's cached `a0.Length` temporary and has no name in the source.

## 3. Every call and every data reference was checked by name

This is the check that matters, because a call operand sits inside the oracle's mask set:
a body that calls the wrong function entirely still reads clean through a masking diff. So
each `call`/`jmp rel32` site was resolved on both sides and adjudicated individually, using
the same three rules `harness.compare` uses (name agreement, corroborated runtime-symbol
table, or a proof that the two callees are byte-identical).

| body | call sites | proven same target | disagreements | unproven |
|---|---:|---:|---:|---:|
| `DrawFaceText` | 46 | 44 | **0** | 2 |
| `DrawBorderText` | 32 | 32 | **0** | 0 |
| `DrawShadowText` | 14 | 14 | **0** | 0 |

The two unproven sites in `DrawFaceText` are dealt with in section 5; they are correct, and
the reason they cannot be proven automatically is a gap in the tooling, not in the body.

Differing absolute addresses were adjudicated the same way, by resolving what each address
points at rather than accepting it because both sides are in-image:

| body | distinct address pairs | agree | differ |
|---|---:|---:|---:|
| `DrawFaceText` | 7 | 7 | 0 |
| `DrawBorderText` | 3 | 3 | 0 |
| `DrawShadowText` | 3 | 3 | 0 |

They resolve to `bbNullObject`, the `TDrawingPoint` class table, the `TDrawCharAction`
class table, and in `DrawFaceText` four string literals whose text is identical on both
sides (`"  -  "`, `")"`, `", "`, `"("`, the pieces of the leftover debug `Print`).

The result is deterministic: all three were rebuilt into a second work directory back to
back and produced byte-identical output.

One caveat on comparing probe bytes across time. The corpus gained a module Function
mid-pass (another worker moved `Fn_0050874A.DecodeText` into `src/recovered_module`), which
relaid out the probe executable and so changed every relocated address and call
displacement inside our copy of these bodies. The whole analysis above was re-run against a
fresh pair of builds afterwards and is unchanged: same instruction counts, same alignment,
the same 6 / 4 / 4 `ebp` bytes at the same offsets, nothing unaccounted for, no call or
data disagreement. A probe body's raw hash is therefore not a stable identity across corpus
changes; the classified anatomy is.

## 4. Why this is behaviourally identical

Nothing about a spill slot is observable from inside the program. The frame is the same
size, the same three values are spilled, and each is written and read through the same
displacement consistently. Swapping which slot holds which value is a relabelling of
private stack storage. The instructions executed, the functions called, the arguments
passed and the memory read are all the original's, so the sequence of `DrawImage` calls
these methods issue is the original's, and the pixels they produce are the original's.

That is a deduction from the byte evidence above, not a screenshot comparison. It is a
strong one: with zero mnemonic differences, zero unaccounted bytes, zero call-target
disagreements and zero data-reference disagreements, there is no remaining channel through
which behaviour could differ.

## 5. Two tooling gaps sit behind these bodies as well

Neither is a reason the bodies do not match. Both would have to be closed before a
hypothetically perfect allocator could make them certify, and both are worth fixing on
their own account. Neither was changed here: each touches the table every verification in
the project is scored against, and that belongs in its own change with its own corpus
re-verify.

**5.1 `orig_functions()` does not scan `src/recovered_thirdparty/`.** Recorded already as
section 8 of [`spill-tie-x87-precision.md`](spill-tie-x87-precision.md). Fontmachine's four
module-level helpers at 0x00592A13, 0x00592A37, 0x00592B79 and 0x00592B87 are verified
bodies carrying a `VA` header, but the scan never reaches them, so their `E8` operands have
no original-side name. In this pass those four rows were supplied in memory purely to
adjudicate, and every call through them agreed.

**5.2 `bbStringFromDouble` at 0x004A7990 has no row in the corroborated helper table, and
`DrawFaceText` is the only body in the corpus that could ever give it one.** Identified
from the original's own bytes: the function takes an eight-byte argument, formats it with
`"%#.17lg"` (seventeen significant digits, i.e. `double`), and tail-calls
`bbStringFromCString` at 0x004A7960; it sits between that and `bbStringFromFloat` at
0x004A79D0 in the runtime's string-conversion family, and our own
`_bbStringFromDouble` uses the identical format string. `DrawFaceText`'s leftover debug
`Print` concatenates exactly two `Double` values, and there are exactly two calls to
0x004A7990 in the body.

A scan of both code sections of `NSS5.exe` finds six call sites to 0x004A7990 in the entire
program: two in `DrawFaceText`, and four in `TField.SetDouble`, `TTextStream.WriteDouble`
and two unreconstructed BRL functions. None of those four is a body this project
reconstructs. So the only body that could ever teach the table this name is the body that
needs the name, and the table has stayed empty for exactly that reason. Compare
`bbStringFromInt` at 0x004A7AC0, which has 1,015 call sites and 1,606 witnesses.

## 6. Corrections to numbers published earlier

**Offset convention.** The differing-byte offsets quoted in the earlier write-up and in the
three body headers are **instruction start offsets**, not the offsets of the byte that
differs. The byte is the `disp8`, two bytes later:

| body | instruction starts (as published) | the byte that actually differs |
|---|---|---|
| `DrawFaceText` | +76 +108 +124 +384 +401 +1402 | +78 +110 +126 +386 +403 +1404 |
| `DrawBorderText` | +85 +101 +384 +1169 | +87 +103 +386 +1171 |
| `DrawShadowText` | +85 +101 +378 +640 | +87 +103 +380 +642 |

Both are correct readings; they are simply not the same number. `first_diff` is on the byte
convention, which is why the published list for `DrawShadowText` starts at +85 while its
own `first_diff` is +87. The headers now give both.

**"662 of 666 bytes identical".** That figure, and its siblings for the other two bodies,
is the count after relocations and calls are masked. `harness.try_method`'s own positional
`matched` is 604/666, 1086/1195 and 1270/1428, because it counts raw byte equality and
every relocated address and call displacement counts against it. Both numbers are honest
and they measure different things. The headers now state which is which.

**The three-way tie itself.** Confirmed as published: `usage=11`, and all three candidates
tied on every cost input at the decision point. Nothing in this pass contradicts
[`spill-tie-x87-precision.md`](spill-tie-x87-precision.md); the slot maps in section 1 of
that document reproduce exactly.

## 7. What to do with them

**They stay in `src/recovered_unverified/`, uncounted.** No `byte-identical` marker has
been added to any of the three and none should be. The oracle says MISMATCH, and the rule
that only the oracle can promote a body is the reason the rest of the corpus can be
trusted.

**If they ever certify they belong in `src/recovered_thirdparty/fontmachine/`,** never in
`src/recovered/`. Folding a third-party module's Types into the main module corrupts the
declaration order the class tables follow.

**A "non-matching" category is worth considering, and the decision is the owner's.** Other
decompilation projects that reach this point keep an explicit `NON_MATCHING` category for
code that is proven equivalent but not byte-identical, so that the headline percentage
stops being dragged down by work that is actually finished, without anyone being tempted to
mark it matched. The case for one here is that these three bodies are 3,289 bytes, just
under half of everything still unmatched, they are demonstrably complete, and their headers
already say so in prose that no tool reads. The case against is that this project's whole
discipline is that a body
either passes the oracle or it does not, and every category that is not "the oracle said
yes" is a place for a wrong body to hide. `progress.py` was **not** changed in this pass and
no new category was invented; this is a recommendation, not a change.

If such a category is added, it should be earned the same way a match is: by a checker that
verifies the equivalence claim mechanically (equal length, one-to-one instruction
alignment, zero mnemonic differences, and zero unadjudicated bytes) rather than by a phrase
in a comment. A category granted by prose is a category that will eventually be granted to
something that does not deserve it.

## 8. Reproducing

Scratch scripts for this pass are under `scripts/workflow/w384/` (untracked):

* `run3.py` builds all three through `harness.try_method` under `NSS5_NO_LEARN=1` and
  records the verdicts. Feed the file through `reverify.body_of` first; the files are
  wrapped, and handing the wrapper to `try_method` fails to build.
* `anatomy.py` disassembles both streams, checks the instruction alignment, and classifies
  every differing byte by instruction field.
* `adjudicate.py` puts every `call`/`jmp rel32` site through the oracle's own three rules
  one site at a time, so nothing is masked by default.
* `dataops.py` resolves every differing absolute address to its pointee on both sides.
* `callers.py` counts call sites to a runtime helper across both code sections. Scan
  **both** `.text` and `code`: the runtime lives in the first, the game in the second, and
  scanning only `.text` finds zero callers for everything and looks like a working answer.
* `recheck.py` rebuilds each body twice, back to back, into fresh work directories to
  confirm determinism.

`anatomy.py`, `adjudicate.py` and `dataops.py` take a `WD_PREFIX` environment variable so
they can be pointed at any of the build directories.
