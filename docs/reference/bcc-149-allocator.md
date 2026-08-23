# What BlitzMax 1.49's allocator actually does -- read, not guessed

**Status: decisive negative result, established by static analysis of a genuine 1.49 `bcc`.**
`spill()`'s cost formula and its tie-break comparison in the real 1.49 compiler are
**identical** to what ships in our 1.50 source. The "Munged cost" comment in
`_src/codegen/cgallocregs.cpp` does not mark a change introduced between 1.49 and 1.50 -- the
munge, and the strict `<`, both predate 1.49. This confirms, by direct evidence rather than by
inference from corpus behaviour, the conclusion `allocator-knob-sweep.md` §5.1 already drew
from K1/K2's negative results.

## 1. What was read

A genuine BlitzMax 1.49 macOS demo `bcc`:

```
path   scratchpad/bmx149/BlitzMaxDemo/bin/bcc
format Mach-O 32-bit x86 (i386), NOUNDEFS|DYLDLINK|TWOLEVEL|SUBSECTIONS_VIA_SYMBOLS
size   493,356 bytes
sha256 9193d2e7a9bafdd102376a29ce43a2e1c14ad1d71d6f1bbf2fb67f39ef531f57
```

It cannot be executed here (32-bit macOS support is gone, and it is a demo with an expiry
check), and no attempt was made to. It was imported into Ghidra 12.1.2 (`analyzeHeadless`,
default auto-analysis) and read statically. `_src/codegen/cgallocregs.cpp` is
platform-independent in `bcc`'s own source tree, so this Darwin binary carries the same
allocator logic as the Windows `bcc.exe` that (within `NSS5.exe`'s bracketed 1.44-1.49 range)
could have built `NSS5.exe`.

**The binary was not actually stripped of local symbols.** `___i686.get_pc_thunk.bx`,
`___i686.get_pc_thunk.cx`, `allocSpill`, `spillReg`, and `cgAllocRegs` are all present as
named functions, which made locating the target far more direct than the PIC-string-xref
route the task anticipated needing. `spill()` itself has no separate symbol -- it is inlined
into `cgAllocRegs` (0x0001f806, 3,954 bytes), which is unsurprising for a single-call-site
static/local method.

## 2. Confirming this is the right code: string cross-reference

Ghidra's auto-analysis does **not** create xrefs to the two `fail`/warning string literals --
confirming the task brief's warning that this is Darwin PIC code (`call get_pc_thunk.bx` /
`.cx`, then direct `LEA reg,[EBX/ECX + disp]` with **no** intervening `add reg,imm`, unlike the
classic ELF `call thunk; add reg,_GLOBAL_OFFSET_TABLE_` idiom). Absolute-address search finds
nothing because nothing stores the absolute address -- only `(target − return_address)` is
ever encoded, as a small immediate.

Resolved by treating every `call get_pc_thunk.bx/.cx` site's return address as a candidate PIC
base, and scanning each caller's own function body for a scalar operand equal to
`target − candidate_base`:

```
target=0x4cdbc ("Unable to find spill candidate")
  thunkCallAt=0001f812  candidateBase=0x1f817  neededDisp=0x2d5a5
  foundAt=00020234  insn=[LEA EAX,[EBX + 0x2d5a5]]
  inFunction=cgAllocRegs@0001f806
```

Both target strings resolve into `cgAllocRegs`, at the exact addresses the task brief named
(`0x4cdbc` and -- confirmed independently -- `0x4cd9a`, two bytes into a string Ghidra stored as
`": trouble finding spill candidate\n"`). Disassembly around the fail-path (0x00020222-
0x0002023d) shows exactly the two-pass structure `codegen-patterns.md` §22.1 describes: a
warning is printed once per pass (`local_48` 0 then 1), `fail()` is called only after the
second pass finds no candidate, then `selectNode` on whatever *was* found. This is `spill()`,
not a look-alike.

## 3. The cost formula -- decompiled, then confirmed at instruction level

Decompiled (`cgAllocRegs`, DecompInterface, 60s timeout, completed clean):

```c
if (((local_48 != 0) || (*(int *)(piVar6[3] + 8) < *(int *)(unaff_EBX + 0x43d7d))) &&
   (fVar15 = (float)piVar6[8] / ((float)piVar6[7] * (float)piVar6[9]), fVar15 < local_4c))
{
  local_4c = fVar15;
  local_38 = piVar6;
}
```

Read against our 1.50 source's `spill()`:

* the outer guard -- `local_48 != 0 || t->reg->id < max_spill_id` -- is 1.50's two-pass "pass 0
  skips `t->reg->id >= max_spill_id`" guard, sign-flipped into the decompiler's `<`. Confirmed
  at the raw level too (§4).
* the cost line is **`usage / (degree * block_count)`, with the multiply present** -- the
  *munged* form, not the commented-out `usage/degree` original.
* the update condition is **`fVar15 < local_4c`** -- strict less-than, exactly `if(cost<min)`.

This is not read from the decompiler alone. Confirmed at the instruction level:

```
0001fa xx  (loop over spill candidates, ESI = current node t)
00020131   MOV EAX,[ESI+0xc]          ; t->reg
00020134   MOV EAX,[EAX+0x8]          ; t->reg->id
00020137   CMP EAX,[EBX+0x43d7d]      ; vs max_spill_id
0002013d   JGE 0x20168                ; pass-0 guard: skip if reg->id >= max_spill_id
0002013f   CVTSI2SS XMM0,[ESI+0x1c]   ; int->float convert #1  (degree)
00020144   CVTSI2SS XMM1,[ESI+0x24]   ; int->float convert #2  (block_count)
00020149   MULSS  XMM0,XMM1           ; degree * block_count      <-- THE MULTIPLY
0002014d   MOVSS  XMM1,[ESI+0x20]     ; usage -- already float, NOT converted (0 conversions here)
00020152   DIVSS  XMM1,XMM0           ; cost = usage / (degree*block_count)
00020156   MOVSS  XMM0,[EBP-0x48]     ; XMM0 = running min
0002015b   UCOMISS XMM0,XMM1          ; compare min vs cost
0002015e   JBE    0x20168             ; skip update when min <= cost (i.e. update only if cost < min)
00020160   MOV    [EBP-0x34],ESI      ; candidate = t
00020163   MOVSS  [EBP-0x48],XMM1     ; min = cost
```

This build targets Darwin/SSE, not the x87 the task brief expected (that expectation was
written for the Windows/MinGW-style toolchain; Apple's contemporaneous gcc used scalar SSE for
`float` on i386). The signature the task asked for translates directly: **two** int→float
conversions (`CVTSI2SS`, for `degree` and `block_count`) feed **one** `MULSS` before the
`DIVSS` -- the pre-munge original (`usage/degree`) would show one conversion and no multiply.
Two conversions and a multiply are present. `usage` itself is read straight off the node with a
plain `MOVSS`, i.e. it is already stored as a float field, so it was never a conversion
candidate -- consistent with the source, where only `degree` and `block_count` are cast from
int.

The comparison is unambiguous too. `UCOMISS XMM0(min), XMM1(cost)` followed by
`JBE → skip-update` means the update (`min = cost`, candidate = current node) fires only when
`min > cost`, i.e. **only on a strict `cost < min`**. On an exact tie, `JBE` is taken, the
update is skipped, and the **earlier** candidate already recorded as the running minimum keeps
its slot. That is 1.50's shipped `if(cost<min)`, not the "last-wins" `cost<=min` of knob `K2`.

## 4. Answers to the four questions the task posed

| # | question | answer |
|---|---|---|
| a | located `spill()`? | **Yes.** Inlined into `cgAllocRegs` @ 0x0001f806 (Mach-O VA); confirmed via string xref to both `fail()`/warning literals at their exact stated addresses, plus the two-pass loop structure matching the source. |
| b | block_count multiply present in 1.49? | **Yes.** `CVTSI2SS ×2` (degree, block_count) → `MULSS` → `DIVSS`. Identical to 1.50's "Munged cost" line. The pre-munge, commented-out `usage/degree` form is **not** what 1.49 shipped. |
| c | strict `<` or `<=`? | **Strict `<`.** `UCOMISS` + `JBE`-skips-update means the running minimum only replaces on `cost < min`; an exact tie leaves the earlier candidate selected. Identical to 1.50's `if(cost<min)`. |
| d | knob run, and result | **None run.** No difference from 1.50 was found on either axis the task asked about, so there was nothing new to encode -- `knob_sweep.py`'s existing K1 (drop block_count) and K2 (tie→`<=`) already tested exactly these two hypotheses and both were refuted (K1: 0 closed / 8 broken; K2: 0 closed / 1 broken, per `allocator-knob-sweep.md` §4). This binary now shows *why* they failed: the thing they were trying to un-munge back to 1.4x behaviour was never munged relative to 1.4x in the first place. |

## 5. What this settles, and what it does not

**Settles:** the single most attractive allocator hypothesis in the project -- that
`NSS5.exe`'s compiler (bracketed 1.44-1.49) predates the "Munged cost" commit and would
therefore use the simpler pre-munge formula or a last-wins tie-break -- is now refuted by
direct binary evidence from the oldest publicly available point in that bracket, not merely by
six knob experiments failing to help. `allocator-knob-sweep.md` §5.1's conclusion ("the munge
predates the compiler that built `NSS5.exe`") now has a primary source. K1/K2 (and by
extension K3, which combines them) should be treated as closed, not merely unpromising.

**Does not settle:** this binary is a Mach-O/Darwin build, and only one 1.49 sample. It says
nothing about:

* whether `createGraph`'s inputs -- how `usage`, `degree`, and `block_count` are *computed* --
  differ between 1.4x and 1.50 (§6 of `allocator-knob-sweep.md`, still open);
* front-end register-id minting order (`allocator-knob-sweep.md`'s strongest remaining
  hypothesis, also still open);
* coalescing behaviour, or the slot-assignment walk direction (K6's axis) -- not re-examined
  here since the task's two named questions were only about the cost formula and the
  comparison operator.

The cheapest next experiment remains what `allocator-knob-sweep.md` §6 already recommended:
instrument-trace one strongly-diagnosed body (e.g. `TBall.CheckForPlayerRatings`, a pure
slot-order tie) under both a matching and non-matching build and find the first point the
register-id sequences diverge -- now with one fewer plausible cause (the cost formula itself)
left to explain that divergence.

## 6. Reproducing this

```
JAVA_HOME=tools/jdk/jdk-21.0.12+8
GHIDRA=tools/ghidra_12.1.2_PUBLIC

# one-time import + auto-analysis
"$GHIDRA/support/analyzeHeadless.bat" <proj-dir> bcc149 -import <path-to-1.49-bcc>

# locate spill() via PIC-resolved string xref
"$GHIDRA/support/analyzeHeadless.bat" <proj-dir> bcc149 -process bcc -noanalysis \
  -scriptPath scripts/ghidra_scripts -postScript NSS5FindSpillPIC.java

# decompile / disassemble what it finds
"$GHIDRA/support/analyzeHeadless.bat" <proj-dir> bcc149 -process bcc -noanalysis \
  -scriptPath scripts/ghidra_scripts -postScript NSS5Decompile.java 0x1f806
"$GHIDRA/support/analyzeHeadless.bat" <proj-dir> bcc149 -process bcc -noanalysis \
  -scriptPath scripts/ghidra_scripts -postScript NSS5FindFPU.java 0x1f806
"$GHIDRA/support/analyzeHeadless.bat" <proj-dir> bcc149 -process bcc -noanalysis \
  -scriptPath scripts/ghidra_scripts -postScript NSS5DumpRange.java 0x20100 0x20190
```

New scripts added for this investigation, all under `scripts/ghidra_scripts/`:

* `NSS5FindSpill.java` -- locates a string literal by substring; reports direct xrefs (finds
  none on this PIC binary, which is itself the diagnostic that motivated the next script).
* `NSS5FindSpillPIC.java` -- the PIC resolver described in §2: finds `get_pc_thunk`-shaped
  functions by instruction pattern, walks their callers, computes each call site's PIC base
  from the **return address alone** (this target uses Darwin's no-`add`-needed idiom, not
  ELF's `call thunk; add reg,GOT`), and matches scalar displacements against target addresses.
* `NSS5FindFPU.java` -- lists every floating-point-ish instruction (`F*`, `*SS`, `CVT*`,
  `MUL*`, `DIV*`) inside one function, which is how the SSE-not-x87 codegen was discovered.
* `NSS5DumpRange.java` -- a minimal linear disassembly dump for an address range, used to read
  the exact `CVTSI2SS`/`MULSS`/`DIVSS`/`UCOMISS`/`JBE` sequence at instruction granularity.
* `NSS5ListFuncs.java` -- lists functions by name substring; how `cgAllocRegs`, `allocSpill`,
  and `spillReg` were confirmed present (this binary is not fully stripped of local symbols).
