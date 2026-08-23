# The spill tie-break is decided by x87 excess precision, not by the program

> **The three bodies this document is about are now dispositioned.** See
> [`fontmachine-drawtext-disposition.md`](fontmachine-drawtext-disposition.md), which
> re-measures the residual independently, adjudicates every call and data operand in all
> three bodies by name, and settles how they are to be counted and stored. This document
> remains the record of the mechanism. Do not open another variant sweep against it.

**Status: documented limit, with a proven mechanism and a refuted alternative.**
`TPrivateBitmapFont`'s three `Draw*Text` bodies sit on a genuine three-way EXACT tie in
`cgallocregs.cpp`'s spill cost. Which of the three tied values gets spilled first is
decided, in the `bcc.exe` this project ships, by the direction in which the cost quotient
rounds to `float` - because the comparison puts an x87 **extended-precision** `cost`
against a **32-bit** `min`. That is a property of how `bcc.exe` itself was compiled. It is
not reachable from BlitzMax source, it is not one of the six knobs in
[`allocator-knob-sweep.md`](allocator-knob-sweep.md), and it is not the 1.44-1.49 vs 1.50
question [`bcc-149-allocator.md`](bcc-149-allocator.md) closed.

Two earlier claims are corrected here. The "`std::set<Node*>` iterates in pointer order so
the heap layout decides it" hypothesis, carried in these three headers and in
`scripts/workflow/walloc_report.py`'s docstring, is **refuted** (section 6). And the
`WALLOC_TRACE=1` "deciding experiment" those headers rest on turns out to have been
measuring exactly this rounding, by accident (section 5).

---

## 1. The residual, measured

Worker 276, shipped `bcc.exe`, `NSS5_NO_LEARN=1`:

| body | VA | length | verdict | first_diff | differing bytes |
|---|---|---:|---|---:|---|
| `DrawFaceText` | 0x00591383 | 1428 = 1428 | MISMATCH | +78 | 6, all `ebp` displacements, at +76 +108 +124 +384 +401 +1402 |
| `DrawBorderText` | 0x00591917 | 1195 = 1195 | MISMATCH | +87 | 4, at +85 +101 +384 +1169 |
| `DrawShadowText` | 0x00591DC2 | 666 = 666 | MISMATCH | +87 | 4, at +85 +101 +378 +640 |

The offsets in the last column are **instruction start** offsets. The byte that actually
differs is the `disp8`, two bytes later, which is why `first_diff` is +87 where the row
says +85. Both readings are right and they are not the same number; the disposition
document gives both.

Every other byte is the original's. Three values land in a different spill ORDER, and
`allocLocal` hands out `-4` first while `selectRegs` pops `_selected` from `pred`, so
**the deepest slot belongs to the value spilled first**:

| body | our order (deep to shallow) | the original's order |
|---|---|---|
| `DrawShadowText` | hasfx `-0x1c`, origin `-0x18`, limit `-0x14` | limit `-0x1c`, origin `-0x18`, hasfx `-0x14` |
| `DrawBorderText` | limit `-0x54`, hasfx `-0x50`, origin `-0x4c` | hasfx `-0x54`, limit `-0x50`, origin `-0x4c` |
| `DrawFaceText` | limit `-0x64`, hasfx `-0x60`, origin `-0x5c` | hasfx `-0x64`, origin `-0x60`, limit `-0x5c` |

`limit` is the `For` loop's cached `a0.Length` temp; it has no source name, so the trace
reports it by register id.

## 2. The tie is exact, and it is exact AT THE DECISION POINT

Read from the compiler's own `WALLOC_SPILLCAND` lines, which print `usage`, `degree` and
`block_count` as the candidate presented them to `spill()` - `degree` there is live and
already mutated by `decDegree`, unlike the `WALLOC_NODE` dump taken at graph build:

| body | tied values | usage | degree | block_count | cost |
|---|---|---:|---:|---:|---|
| `DrawFaceText` | limit, origin, hasfx | 11 | 90 | 31 | 11/2790 |
| `DrawBorderText` | limit, origin, hasfx | 11 | 73 | 29 | 11/2117 |
| `DrawShadowText` | limit, origin, hasfx | 11 | 43 | 26 | 11/1118 |

All three values, all three inputs, identical. The `_spill` list order is limit, origin,
hasfx in every one of the three bodies.

**This corrects the number these headers have carried since they were written.** They said
`origin` was NOT tied and carried "exactly three more interference edges". That is true of
`createGraph`'s starting graph and false by the time `spill()` runs: `decDegree` has
equalised all three. The published `origin 11 / 93 / 31` figure is a starting-graph
reading of a decision that is taken later.

## 3. What the shipped `bcc.exe` actually executes

`spill()` is inlined into `cgAllocRegs`. In `bin/bcc.exe` (1,270,272 bytes) the cost loop
is at VA 0x0041eddb:

```
0041eddb   fild   dword ptr [edi + 0x1c]     ; degree        -> st(0), extended
0041edde   fild   dword ptr [edi + 0x24]     ; block_count   -> st(0), extended
0041ede1   fmulp  st(1)                      ; degree * block_count
0041ede3   fdivr  dword ptr [edi + 0x20]     ; cost = usage / that  -- stays in st(0)
0041ede6   fcom   dword ptr [esp + 0x14]     ; compare against min, a 4-BYTE FLOAT SLOT
0041edea   fnstsw ax
0041edec   test   ah, 1
0041edef   je     0x41edf9                   ; not less -> keep the incumbent
0041edf1   fstp   dword ptr [esp + 0x14]     ; min = (float)cost  -- ROUNDS HERE
0041edf5   mov    ebx, edi                   ; node = t
```

`cost` is never rounded. `min` always is. So for two candidates whose costs are
mathematically equal, the comparison is `q` (extended) against `float32(q)`:

* `float32(q) > q` (rounds **UP**): `cost < min` is TRUE, the incumbent is replaced, and
  the **LAST** tied candidate wins.
* `float32(q) < q` or exact (rounds **DOWN**): FALSE, and the **FIRST** tied candidate
  wins.

An SSE build has no such asymmetry: `bcc-149-allocator.md` records the genuine 1.49 `bcc`
doing `CVTSI2SS` / `MULSS` / `DIVSS` / `MOVSS min` / `UCOMISS` / `JBE`, which is 32-bit on
both sides, so its ties always go to the first candidate.

## 4. The rule predicts our slot map, 9 of 9

| body | cost | rounds | predicted pick order | measured (ours) |
|---|---|---|---|---|
| `DrawShadowText` | 11/1118 then 11/1092 | UP, UP | hasfx, origin, limit | hasfx `-0x1c`, origin `-0x18`, limit `-0x14` |
| `DrawBorderText` | 11/2117 then 11/2088 | DOWN, UP | limit, hasfx, origin | limit `-0x54`, hasfx `-0x50`, origin `-0x4c` |
| `DrawFaceText` | 11/2790 then 11/2759 | DOWN, UP | limit, hasfx, origin | limit `-0x64`, hasfx `-0x60`, origin `-0x5c` |

Every one of the nine slot assignments falls out of the rounding direction alone. Nothing
else in the three bodies distinguishes `DrawShadowText` from its two siblings, and the
rounding direction does: that is why the original resolves this tie one way in
`DrawShadowText` and the other way in the other two, and so do we, but in opposite
directions.

## 5. The controlled experiment: one line, no I/O

`WALLOC_FP32` was added to a private copy of `cgallocregs.cpp`, gated off by default, and
does exactly one thing:

```c
float cost=(float)t->usage/((float)t->degree*(float)t->block_count);
if( fp32On() ){ volatile float _r32=cost; cost=_r32; }   // force the float32 round
```

Same `bcc.exe`, same sources, back to back, one environment variable apart. Differing
`ebp` displacements against `NSS5.exe`:

| body | gate OFF | gate ON |
|---|---:|---:|
| `DrawShadowText` | 4 | **0** |
| `DrawBorderText` | 4 | 34 |
| `DrawFaceText` | 6 | 12 |

Gate OFF reproduces the shipped compiler exactly, byte for byte and offset for offset, so
the patched binary is its own control. Gate ON makes `DrawShadowText`'s frame layout
exactly the original's and makes the other two worse - which is precisely the pattern the
old `WALLOC_TRACE=1` "deciding experiment" reported.

**So that experiment was never about heap layout or about I/O.** `cerr << cost` forces
`cost` through a 32-bit float slot before the comparison, which is the same edit as
`WALLOC_FP32` with a print attached. Both give float32-exact semantics, both make the
first tied candidate win, and both close `DrawShadowText`'s allocator outcome and only
that one.

## 6. What is refuted

**The heap-layout hypothesis.** Three body headers and `walloc_report.py`'s docstring say
`cgallocregs.cpp` keeps each node's edges and moves in `std::set<Node*>`, "a container
ordered by raw POINTER VALUE, not by anything about the program being compiled", and that
the OS heap therefore decides near-ties. The container is right; the inference is not.
`cgallocregs.cpp` line 110 declares

```c
static vector<Node> nodes;
```

and every pointer ever inserted into a `NodeSet` is `&nodes[k]`. All `Node` objects
therefore live in one contiguous buffer, so `set<Node*>` iterates in **index order, which
is register-id order**, on every run and on every machine. There is no heap-order
dependence in the allocator to find. The docstring's own caveat - "hold it as a
well-motivated hypothesis, not a proven mechanism" - was the right instinct, and this is
the measurement it was waiting for.

**The float32-exact fix.** Making the comparison 32-bit on both sides is the obvious
"restore the 1.49 SSE semantics" move, and it is a refutation by
`allocator-knob-sweep.md`'s own scoring rule. A control sample run serially in one worker
tree:

| control set | gate OFF | gate ON |
|---|---|---|
| 12 matched bodies, 14 to 1,321 bytes, spread across the range | 12/12 MATCH | 12/12 MATCH |
| the 16 largest matched bodies, 5,081 to 16,301 bytes | 16/16 MATCH | **10/16 MATCH** |

Broken under the gate: `TScreen_Stats.UpdateStatTable`, `TPlayer.RecordPlayerStats`,
`TTeam.UpdatePlayerDestinations`, `TEngine.RenderScoreboard`,
`TScreen_Controls.CreateScreen`, `TPitch.SetUp`. It closes at most one body and breaks six
of the sixteen that matter most. The shipped x87 build is **closer** to the original than
a float32-exact build is, which is a real result in its own right: whatever compiled the
`bcc.exe` that built `NSS5.exe` was also an x87 build carrying excess precision through
this comparison. It simply gave `cost` and `min` the opposite treatment - on the first
contested pick in all three bodies our build and the original's are exact mirror images,
which is the signature of `cost` rounded and `min` kept in a register rather than the
other way round. The second pick fits that reading in two bodies of three, so the
original's exact register assignment inside `spill()` is bracketed, not pinned, and
pinning it would need that `bcc.exe`, which we do not have.

## 7. Why no source change can reach it

`usage`, `degree` and `block_count` are all fixed by the emitted CG stream, and that
stream is already the original's - the two images differ only in six, four and four
`ebp` displacement bytes. So a source edit can only move the tie by changing the emitted
code, which is already right. Measured on `DrawShadowText`, statement placement and
liveness included (this is the axis previous passes had argued about rather than tested):

| variant | length | first_diff | effect on the tie |
|---|---:|---:|---|
| as committed | 666 = 666 | +87 | 3-way exact tie, `u=11 d=43 b=26` |
| `origin` computed immediately before the `For` | 666 = 666 | +39 (worse) | tie unchanged |
| limit hoisted to `Local n` + `While i <= n` | 666 = 666 | +87 (identical) | tie unchanged; `block_count` 26 to 25 **for all three at once** |
| `hasfx` defined inside the loop body | 664 (-2) | +5 | tie broken, code no longer the original's |
| `hasfx` read at the loop top via a copy | 668 (+2) | +55 | tie broken, code no longer the original's |
| `origin` read at the loop top via a copy | 667 (+1) | +55 | tie broken, code no longer the original's |

The general fact, and it is a theorem rather than an observation: **a value defined before
a loop and read inside it is live-in and live-out of every block of that loop**, because
the back edge reaches the read again from anywhere in the body. Its `block_count` is the
loop's block count no matter where inside the loop the read sits, and it is the same
number for every value in that position - which is why the `While` rewrite moved
`block_count` from 26 to 25 for all three tied values simultaneously and left the tie
exactly as it was. `codegen-patterns.md` section 22.3 offers `block_count` as "the untried
lever ... a statement-placement question". For a value in this position there is no such
lever.

## 8. A SECOND blocker, invisible until the first one is removed

Even with the allocator producing the original's frame layout, `DrawShadowText` still
reports MISMATCH at +369 under `NSS5_NO_LEARN=1`. Its remaining differing bytes are 21
absolute-data-address bytes and 29 `call rel32` bytes, and nothing else.

`helper_map.orig_functions()` builds the original-side name table by scanning
`src/recovered_module/` for `' VA 0x...` headers. It never scans
`src/recovered_thirdparty/`. Fontmachine's four module-level helpers -

```
0x00592A13  Fn_00592A13      0x00592A37  Fn_00592A37
0x00592B79  Fn_00592B79      0x00592B87  Fn_00592B87
```

- are verified bodies carrying that header line, and every glyph the game draws goes
through the first two. With no row for them the `E8` operand has no original-side name, so
it cannot mask, and learning it is exactly what `NSS5_NO_LEARN=1` exists to prevent.

Measured, as a diagnostic and not as a verification: with those four rows added **in
memory** from the files' own headers, and the allocator gate on, `DrawShadowText` reports
`MATCH, mode=reloc, 666/666` under `NSS5_NO_LEARN=1`. With the rows absent and everything
else identical it reports `MISMATCH, first_diff=369`.

This is the same defect class the repo has already been bitten by twice - `assemble.py`
silently skipping `src/recovered_thirdparty/`, and the wrong `runtime_helpers.tsv` row
that blessed ten wrong bodies. Nothing was changed here: extending the scan touches every
verification in the project and belongs in its own change with its own corpus re-verify.
But it should be done, and it should be done before anyone attacks the allocator side
again, because otherwise a correct allocator outcome still reports MISMATCH at +369 and
reads like a source error.

## 9. Verdict

These three bodies are **not reachable from source with any toolchain available to this
project**. The tie is exact on all three cost inputs at the decision point, those inputs
are fixed by an instruction stream that is already byte-for-byte the original's, and the
tie-break is settled inside `bcc.exe` by floating-point rounding that no BlitzMax source
and no edit to `bcc`'s own source can address. Closing them needs the actual `bcc.exe` that
built `NSS5.exe`, or a rebuild of `bcc` whose C++ compiler happens to assign `cost` and
`min` to the same places that one did - and the one such rebuild that can be specified
today, float32 on both sides, is measurably worse for the corpus.

Leave them in `src/recovered_unverified/`. If they ever do certify they belong in
`src/recovered_thirdparty/fontmachine/`, never in `src/recovered/`.

## 10. Reproducing

Scratch scripts for this pass are under `scripts/workflow/w276/` (untracked). The pieces:

* raw allocator trace, instrumented `bcc`, one body:
  `trace276.py TPrivateBitmapFont DrawShadowText <body>` then read the
  `WALLOC_SPILLCAND` block immediately before each `WALLOC_SPILLPICK`.
* the tie groups and the rounding direction: `analyse.py <trace.txt> DrawShadowText`.
* the shipped compiler's own cost loop: `bcc_spill_fp.py <bcc.exe>` finds
  `"Unable to find spill candidate"`, then disassemble `.text` and look for the only
  `fild` / `fild` / `fmulp` / `fdivr` / `fcom` sequence in the binary.
* the causal gate: apply `cgallocregs.fp32probe.cpp` to a **private** worker tree, rebuild
  with `bmk makeapp -a -r -z -t console -o ../../bin/bcc ../compiler/bcc.cpp` from
  `_src/win32_x86`, and run with and without `WALLOC_FP32=1`. Restore the tree afterwards:
  a worker tree left holding a patched compiler makes every later verification silently
  wrong.
