# Bytes that depend on the whole program, not on the body

Some bodies used to be uncertifiable by the per-function oracle no matter how right they
were, because a byte inside them is decided by something `bcc` counted across the entire
compilation unit. The probe compiles one body alone, so the count starts at zero and the
byte comes out different. The body is not wrong. The measurement is out of context.

There is exactly one such counter known today, and this note is about it. **It is now
carried by a pragma, `'!GlobalInit <n>`, and the two bodies it blocked are both closed** -
see "The pragma" below. What remains permanently true is the rest of this note: how the
counter works, how to read the original's order out of the exe, and how to recognise the
next body that hits it.

## The counter

`tools/blitzmax-legacy-src/_src/compiler/stm.cpp:182`, `GlobalDeclStm::eval`, sends any

```blitzmax
Global x:SomeType = <expression>
```

whose initialiser is not a bare literal to `Block::initGlobalRef`
(`tools/blitzmax-legacy-src/_src/compiler/block.cpp:142`). "Bare literal" is
`Val::constant()` in `val.cpp:63`: a `CGLit` or a `CGSym`. `Global n:Int = 5` is constant
and costs nothing. `Global l:TList = CreateList()` is not. Neither is `Global a:Int[10]` --
the parser turns the dimension into an `ArrayExp`, which is a `bbArrayNew1D` call
(`parser.cpp`, `parseInitDecl`).

`initGlobalRef` implements the once-only initialisation guard:

```cpp
static int init_bit;
static CGExp *init_var;
init_bit<<=1;
if( !init_bit ){ init_bit=1; CGDat *d=dat(); d->push_back(lit0); init_var=mem(CG_INT32,d); }
CGLit *init_lit=lit(init_bit);
emit( bcc(CG_NE,bop(CG_AND,init_var,init_lit),lit0,t) );   // and / cmp / jne skip
emit( mov(lhs->cg_exp,rhs->cg_exp) );                      // bare store, no release
emit( mov(init_var,bop(CG_ORL,init_var,init_lit)) );       // flags |= bit
emit( lab(t) );
```

`init_bit` and `init_var` are C++ **function-local statics**. They are not reset per file,
per Type or per Global; they live as long as the `bcc` process. So every such declaration
anywhere in the unit takes the next bit of one shared flags dword, and a fresh dword is
allocated once 32 bits are gone.

The bit value reaches the instruction stream twice, as immediates:

| bit | AND | OR |
|---|---|---|
| `1` .. `0x40` | `83 E0 ib` (3 bytes) | `83 0D disp32 ib` (7 bytes) |
| `0x80` and up | `25 id` (5 bytes) | `81 0D disp32 id` (10 bytes) |

So a body's **length** changes with its position in the whole program's declaration order.

## Order

`bcc.cpp:47-50` runs `Block::resolveBlocks()` then `Block::evalFunBlocks()`, and
`block.cpp:215` walks `_funBlocks` in construction order. `_funBlocks[0]` is the module
body, so **every module-scope declaration is numbered before any function-scope one**,
whatever line it sits on. Function-scope declarations follow in the parse order of their
enclosing `Function`/`Method`.

## Reading the original's order out of the exe

Scan for `or dword ptr [abs32], <power of two>` and group by the dword. Each group is a
flags word; the bits within it are consecutive and in emission order.
`scripts/workflow/w274_asm_compare.py` sits next to the throwaway scanner used for this;
the scan itself is four lines of `capstone` and worth re-writing rather than preserving.
It does not even need `capstone`: the two encodings are `81 0D disp32 imm32` and
`83 0D disp32 imm8`, so a raw byte scan finds every site.

**Scan the `code` section, not `.text`.** NSS5.exe has both, and the game's own compilation
unit is entirely in `code` (0x004BA000 up); `.text` holds the BRL/PUB modules and the C
runtime. A scanner pointed at `.text` returns 14 sites in two dwords and none of them are
the game's, which reads exactly like the theory being wrong.

Two checks confirm the grouping is a reading rather than a guess. `dat()` hands out dwords
in emission order, so within a unit their addresses increase in that order; and across all
98 sites of the game's unit the bit position rises strictly with VA, with no gap and no
repeat. Ordinal is then `32 * (index of the group) + (bit position)`.

NSS5.exe's own compilation unit, in order:

| flags dword | declarations | where |
|---|---|---|
| `0x00C5A31C` | 32 (#1..#32) | all inside `0x004BA034`, the module body |
| `0x00C65CC0` | 32 (#33..#64) | module body |
| `0x00C6E2AC` | 32 (#65..#96) | #65..#94 module body, #95 and #96 `TScreen.DoProgressBar` |
| `0x00C7DDDC` | 2 (#97..#98) | #97 `TScreen.DoProgressBar`, #98 `TProfile.CheckAchievement` |

98 declarations in the whole program; 94 of them in the module body; exactly two functions
in the game make one. That 94 is the same 94 enumerated in
`extracted/module_globals_decoded.tsv`.

Other units in the image (the BRL/PUB modules, and the C runtime in `.text`) have their own
independent runs starting again at bit 0, which is the direct confirmation that the counter
is per `bcc` invocation.

## The pragma

A body states the ordinal it really compiles at, and the probe walks the counter there
before building it:

```blitzmax
'!GlobalInit 95
```

The number is the 1-based ordinal, in the original's single `bcc` compilation unit, of the
FIRST `Global x:T = <non-constant>` declaration the body makes - read straight off the
table above. `harness.py` (`GLOBALINIT_PRAGMA`, `split_global_init`, `init_pad_decls`,
`declares_init_guard`) pads module scope with that many filler declarations, less however
many guarded declarations the probe already emits ahead of the body. It is the same kind of
pragma as `'!Global` and `'!Field`: a probe-context fact the isolated build cannot know,
written next to the body that depends on it.

`assemble.py` is untouched by it - `'!GlobalInit` is an ordinary BlitzMax comment there,
and the whole-program build gets its count from the real module body, which is still the
only number that decides whether the shipped body is right.

**Honest limit.** Only `(ordinal - 1) mod 32` reaches the emitted bytes: the flags dword
itself is an absolute address and the oracle masks it. Measured on `TScreen.DoProgressBar`
under `NSS5_NO_LEARN=1`: no pragma -> 1168, `94` -> 1183, `95` -> MATCH, `96` -> 1173, and
`63` and `127` -> MATCH as well. So a green probe confirms the ordinal modulo 32 and no
more. The absolute value has to come from the exe scan above, and if it ever comes from a
search instead, the body should say so.

## What this means for a body

`src/recovered/TScreen.DoProgressBar.bmx` is the worked example. Same source, four
measurements, all under `NSS5_NO_LEARN=1`:

* bare `harness.try_method`: MISMATCH, `mode=len`, 1178 vs 1168, first difference at
  original +20. Its three guards get bits 1, 2 and 4, which are 10 bytes shorter than the
  original's 0x40000000, 0x80000000 and bit 0 of a fresh word.
* the assembled whole-program build: `localise_diff.py` reports CLEAN, and
  `check_assembled.py`'s comparator (`harness.compare`, `learn=None`) reports `mode=reloc`,
  1178/1178, 97 masked. Every byte agrees.
* a probe with 94 filler `Global x:Int[1]` declarations placed ahead of the body and
  nothing else changed: `harness.try_method` returns MATCH, `mode=reloc`, 1178/1178.
* the same body carrying `'!GlobalInit 95`, which is that filler made first-class:
  `harness.try_method` returns MATCH, `mode=reloc`, 1178/1178, 97 masked, on two worker
  trees.

`src/recovered_unverified/TProfile.CheckAchievement.bmx` is the second, and it is the
proof that the pragma is not a one-body special case: 623 of 625 bytes were already
positionally identical, the two that differed were the `01` immediates at body offsets +51
and +101 where the original has `02`, and `'!GlobalInit 98` closes both. MATCH, `mode=reloc`,
625/625, 47 masked, on two worker trees.

So the answer for this class is neither "fixable in the file" nor "permanently
uncertifiable". It is: **state the ordinal, and it is certifiable by the ordinary oracle**
- while still needing the assembled build to be right about the real count, which is what
the next section is about.

## It is not stable, and only one check notices

That count drifts as the corpus grows. Within one hour on 2026-08-22 the assembled module
body emitted 104 initialised Globals and then 94. At 104 this body assembled to 1183 bytes
with bits 0x100/0x200/0x400: the same six differences as the isolated probe, opposite sign.
At 94 it is exact.

Ten module-scope declarations appearing or disappearing anywhere in the program moves it.
`scripts/check_assembled.py` is the only thing in the tooling that would see that happen;
the per-function oracle is structurally incapable of it, and `progress.py` counts the body
the same either way.

**`'!GlobalInit` does not change that, and must not be read as if it did.** The pragma
states what the ORIGINAL's ordinal is, so the probe is green whatever the reconstruction's
module body currently emits. Nothing is lost - before the pragma the probe reported a
MISMATCH that was noise rather than signal - but nothing is gained either: a green probe on
one of these bodies still says nothing about whether the assembled build's count is right.
`check_assembled.py` is still the only check that sees it.

## How to recognise another one

Symptoms, in order of how quickly they settle it:

1. `localise_diff.py` accounts for the whole delta with gaps and subs that are **all** at
   `and eax,<imm>` / `or dword [addr],<imm>` pairs, with the two immediates equal and a
   power of two.
2. The body contains a `Global x:T = <non-literal>` declaration, or a `Global x:T[N]`.
3. The original's immediate at the site is a different power of two from ours.

If all three hold, stop tuning the body. Count instead: read the original's bit, work out
which declaration number that is from the table above, and write it as `'!GlobalInit <n>`.
Then compare that number with the assembled build's, because the difference is the number
of module-scope initialised Globals the reconstruction has too many or too few, and that
half is fixed in the module body, not here.

Both bodies that hit this are now closed by the pragma. `TProfile.CheckAchievement`
(`0x0056CF70`, 625 bytes) owns the original's #98 and MATCHes 625/625 with
`'!GlobalInit 98`. The assembled build still emits no guard site for it at all, so its
Global is not written there as a `Global x:T = Expr` declaration - that discrepancy is
unchanged and is a job for the module body, not for the probe.
