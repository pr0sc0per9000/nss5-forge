# The allocator knob sweep -- six hypotheses, and what they ruled out

**Status: negative result, and a strong one.** Six single-decision changes to bcc's register
allocator, spanning both axes that could plausibly explain the outstanding bodies, closed
**zero** of them. Every non-control knob broke bodies that currently match. This document
records what was tested, what it cost, and what it rules out, so nobody spends another day
rediscovering it.

Reproduce anything here with `scripts/workflow/knob_sweep.py`.

---

## 1. Why this was worth doing

At the time of the sweep, 28 bodies were outstanding -- 49,928 bytes. A triage of all 28
against their own headers classified them:

| class | bodies | bytes | share |
|---|---:|---:|---:|
| allocator tie-break | 15 | 40,785 | **82%** |
| open source work | 5 | 6,036 | 12% |
| tooling / oracle | 8 | 3,107 | 6% |

So 82% of the remaining bytes were not unreconstructed source. They were bodies whose source
is believed correct and whose emitted code differs because bcc's register allocator resolves
some decision differently from the compiler that built `NSS5.exe`. Several of those headers
say so after direct instrumented-allocator investigation, in terms like *"closing this gap
needs a rule change inside the allocator's tie-break, not a rewrite here."*

That makes the allocator, not the source, the only lever with enough reach to matter -- one
correct change there could have closed 40,785 bytes at once. It also makes it the only lever
that could silently destroy 1,915 existing matches, which is why the harness is built the way
it is (§3).

Two independent reasons to think a compiler difference was real:

1. **We are not using the original compiler.** `docs/archive/research/11-byte-matching-feasibility.md`
   brackets `NSS5.exe` to BlitzMax **1.44-1.49** on PE evidence (linker version 2.21 →
   binutils 2.21.1; a `brl.reflection` constant of 65536 where 1.50's source says 4096;
   `WSOCK32` vs `WS2_32`). We build with **1.50**, the only prebuilt legacy bcc in the public
   archive. A codegen difference across that gap is the expected state of affairs, not an
   exotic theory.

2. **bcc's own source advertises a candidate.** `_src/codegen/cgallocregs.cpp`, in `spill()`:

   ```c
   //          float cost=(float)t->usage/(float)t->degree;

               //***** Munged cost *****//
               float cost=(float)t->usage/((float)t->degree*(float)t->block_count);
   ```

   The original cost formula is still there, commented out, above a replacement its own
   author labelled "Munged cost". If the pre-munge formula was live in the bcc that built
   `NSS5.exe`, that one line would explain the entire allocator class.

Hypothesis 2 was the most attractive idea available. It is now refuted (§4, K1).

---

## 2. Prerequisite: from-source bcc must equal shipped bcc

Every knob experiment rests on one assumption -- that a bcc rebuilt from `_src` generates the
same code as the shipped `bin/bcc.exe`. If it did not, a body that changed after a patch might
have changed because of the patch, or merely because from-source bcc differs from shipped bcc.

Established first, on an **unmodified** tree, by `scripts/workflow/bcc_rebuild_probe.py`:

- rebuild wall-clock: **~14-39 s** (`bmk makeapp -a -r -z -t console -o ../../bin/bcc ../compiler/bcc.cpp`)
- verdicts compared on 8 currently-matched bodies drawn from `progress.py --csv`, largest
  first, up to `TScreen_Stats.UpdateStatTable` at 16,301 bytes
- **bodies whose verdict changed: 0 of 8**

The rebuilt binary is *not* byte-identical to the shipped one, which is expected and
irrelevant -- what matters is that it emits the same code. It does.

> **Machine-level gotcha.** This route was blocked for part of a day by Windows **Smart App
> Control**, which had auto-promoted itself to enforced. The build succeeded and the resulting
> `bcc.exe` could not execute at all (`"An Application Control policy has blocked this file"`),
> surfacing through the harness as `BUILD_FAIL` on every body -- which reads exactly like a
> catastrophic codegen regression and is nothing of the kind. Diagnostic: binaries built on an
> earlier date still ran from their original paths, while a **byte-identical copy** of one placed
> elsewhere was also blocked. If instrumented-compiler work ever mysteriously stops working,
> check `HKLM:\SYSTEM\CurrentControlSet\Control\CI\Policy\VerifiedAndReputablePolicyState`
> (`0` = off, `1` = enforced) before suspecting the compiler.

---

## 3. How a knob is judged

Every knob is scored on **both halves at once**:

- does it **close** bodies that are currently unmatched? *(numerator)*
- does it **hold** every body that currently matches? *(denominator)*

A knob that closes 5 and breaks 200 is not a partial success -- it is a refutation, because it
means the shipped allocator is *closer* to the original than the knob is. A knob that closes
several and breaks nothing would be very strong evidence, precisely because ~1,900 independent
bodies each had every opportunity to disagree with it.

Nothing in the harness lets a knob be called "right" because it fixes a body we wanted fixed.

**Control runs are mandatory.** `K0` applies no patch at all and must report zero closed and
zero broken. Its first run did not -- and that caught a bug in the sweep itself, not in bcc
(§5.2). A sweep without a control is a sweep that cannot tell a discovery from a defect in its
own plumbing.

---

## 4. Results

Screen stage = all 28 unmatched bodies + a 59-body control sample of currently-matched bodies
spread across the size range (sampling the largest would let a knob that only perturbs small
low-pressure bodies pass unnoticed). ~14 s rebuild + ~20 s verification per knob, 16-way
parallel across worker trees.

Counts below are **relative to the K0 control**, so accounting artifacts are subtracted out.

| knob | axis | new closed | new broken | change |
|---|---|---:|---:|---|
| **K0** | -- | 0 | 0 | control: no patch |
| **K1** | spill victim | **0** | 8 | `cost = usage/degree` -- the pre-"Munged cost" formula |
| **K2** | spill victim | **0** | 1 | `cost<min` → `cost<=min` (last-wins on an exact tie) |
| **K3** | spill victim | **0** | 9 | K1 + K2 together |
| **K4** | spill victim | **0** | 7 | `usage/(degree+block_count)` |
| **K5** | spill victim | **0** | 4 | spill-candidate scan reversed (`succ` → `pred`) |
| **K6** | spill **slot** | **0** | 9 | slot-assignment walk reversed (`cgallocregs.cpp:585`) |

**Not one of the 15 allocator-blocked bodies closed under any knob.**

### Why K6 is on a different axis, and why it had to be run

K1-K5 all change *which value gets spilled*. K6 changes only *what slot a spilled value
receives*, by reversing the loop at `cgallocregs.cpp:585` that walks the spilled list calling
`spillReg` → `allocSpill` → `allocLocal` -- and `allocLocal` is a bare `local_sz += n` counter,
so slot depth **is** that loop's iteration order.

This mattered because the best-diagnosed body in the whole set, `TBall.CheckForPlayerRatings`,
is a pure slot-**order** defect: the same values spill in both builds, and the original places
them at `-0x18/-0x1c/-0x14` where we produce `-0x14/-0x18/-0x1c`. **K1-K5 could not have fixed
it even in principle.** A sweep that stopped at K5 would have been reported as "the allocator
is not the answer" while never having tested the mechanism the evidence actually pointed at.

K6 was run as a *reachability probe*, with its failure predicted in advance: the original order
is a **rotation** of ours, and reversing a 3-element sequence yields `-0x1c/-0x18/-0x14`, not
`-0x18/-0x1c/-0x14`. The result is informative either way -- and it moved 9 other bodies, which
proves the slot axis is genuinely reachable from this loop while none of the targets respond to
it.

---

## 5. What this establishes

### 5.1 The shipped 1.50 allocator is at a local optimum for this corpus

Six single-decision perturbations across two independent axes: every one is strictly worse.
Nothing gained anywhere, something lost every time.

That is a meaningful result about the **1.44-1.49 vs 1.50 question**. If the original compiler
had used the pre-munge cost formula -- the single most plausible point-release difference, and
one bcc's own source hands you -- some of the 15 blocked bodies should have closed under K1.
None did, and 8 working bodies regressed. **The munge predates the compiler that built
`NSS5.exe`.**

### 5.2 What the control run caught

`K0`'s first run reported 1 body broken with no patch applied. That was a bug in `knob_sweep.py`,
not in bcc: `corpus()` resolved each body by a bare recursive glob over `src/`, and two corpus
names (`TKit.GetPaintedFan`, `TKit.GetPaintedPlayer`) *also* have a functional placeholder under
`src/placeholder/`. "placeholder" sorts before "recovered_unverified", so the sweep verified the
placeholder against the real function's bytes and reported a regression that did not exist.
Fixed by resolving inside the tree `progress.py --csv` names. `progress.py` was correct
throughout; the sweep was not.

### 5.3 A real body-count correction, found by the control

`K0` also reported two bodies *closing* with no patch applied --
`TBitmapFontLoadException.GetFontObject` and `.ToString`. This one was not a bug. Both headers
said *"code-identical vs NSS5.exe (NOT byte-identical: the E8 rel32 displacement is
layout-dependent)"*, and so never stated the phrase `progress.py` counts.

The reasoning was sound and the conclusion drawn from it was wrong. A call's rel32 displacement
*is* layout-dependent -- but that is true of nearly every body in the corpus, and the oracle
already handles it by resolving the call target's symbol on both sides and masking the operand
when the names agree. Under `NSS5_NO_LEARN=1` both report `MATCH, 21/21, first_diff=None`.

Headers corrected. `src/recovered_thirdparty` went 108/110 → **110/110 (100.0%)**.

---

## 6. What is NOT ruled out

This sweep tested **single-decision changes inside the allocator**. It says nothing about:

- **Front-end ordering.** Register ids are minted in AST visit order (`LocalDeclStm::eval`,
  `IfStm::eval`'s unconditional Then-before-Else walk). That order feeds every downstream tie.
  A 1.4x-vs-1.50 difference *there* would be invisible to all six knobs -- and it is consistent
  with `TBall.CheckForPlayerRatings`, where the six spill candidates are an exact tie on every
  cost metric and the tie-break follows register id order. **This is the strongest remaining
  allocator-side hypothesis.**
- **Combinations.** Only K3 combined knobs. The space was not searched.
- **`createGraph`'s inputs** -- how `usage` and `block_count` are *computed*, as opposed to how
  they are combined into a cost.
- **Coalescing.** Untouched.
- **The source itself.** "Diagnosed to the allocator" is a claim made per body by its own
  header. Those claims are well-evidenced, but this sweep did not re-audit them, and a
  liveness-shaped source difference (§18.4 of `codegen-patterns.md`) would present exactly the
  same way.

The cheapest next experiment is **not another knob**. It is to take one body whose allocator
diagnosis is strongest, dump the instrumented trace under both a matching and a non-matching
build, and find the first point where the two register-id sequences diverge. If they diverge
before the allocator runs, the answer was never in `cgallocregs.cpp`.

---

## 7. Cost, for planning

| step | wall-clock |
|---|---|
| bcc rebuild from patched `_src` | ~14 s |
| screen stage (87 bodies, 16-way) | ~20 s |
| **one hypothesis, end to end** | **~40 s** |
| full corpus stage (1,943 bodies, 16-way) | a few minutes |

Allocator hypotheses are **cheap**. The expensive part of this work was never the compute -- it
was not knowing which axis to test. Which is the argument for keeping `knob_sweep.py` around:
the next idea costs under a minute to falsify.
