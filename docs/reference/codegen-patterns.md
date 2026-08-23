# bcc codegen patterns - measured, not assumed

Every rule here was established by putting a candidate through the byte oracle and reading
the result. Where a plausible rule turns out not to hold, the counter-evidence is kept as
well, because a wrong belief is the thing that costs time.

`bcc` has its own code generator emitting FASM. GCC never touches game code - it only
compiles the C runtime. That is why byte-exact reconstruction is achievable at all.

---

## 1. What the oracle will and will not certify

A MATCH requires **equal length** (original length from Ghidra's inventory, never guessed)
**and every byte equal**. `mode=exact` and `mode=reloc` are both genuine matches;
`mode=reloc` means absolute addresses were masked and the emitted code is identical.
`UNCERTAIN_LEN` means the original's length is not in the inventory - never claim it.

Four things are masked, each only after being **positively resolved on both sides**:

| what | how it is proved |
|---|---|
| absolute data addresses | both decode to an address inside their own image |
| `call [classtable+slot]` | both resolve to the **same `Type+slot`** via reflection |
| `E8` to a C-runtime helper | both resolve to the **same symbol name** (see §2) |
| `E8` to a BlitzMax method | both resolve to the **same `Type.Method`** (see §2) |

Masking blind is how a wrong reconstruction gets blessed. It has happened: calling
`TScreen_TestMenu.SetUpScreen()` in place of `TScreen_EditMenu.SetUpScreen()` matched 20/20
before class-table slots were resolved. Every masking rule now has a negative control.

---

## 2. Why the two images differ at all

The C runtime in our build is compiled by a **different GCC** from the original's. Measured:
`bbObjectDowncast` is 37 bytes in NSS5.exe and agrees with ours in only 12 of them - same
algorithm, different instruction scheduling. So runtime helpers sit at different addresses
with different bodies, and any `E8` into them can never match by construction.

Game code is unaffected: `bcc` emits FASM directly and reproduces exactly.

Game code calls exactly **71 distinct runtime helpers** across 9,399 call sites, touching
1,174 of 1,850 game functions. Both sides get named:

- **ours** - `nm` and `objdump -r` on the intermediate object beside the exe. Relocations
  name the callee outright (`_bbObjectDowncast`), and one method located by reflection
  fixes the object-offset-to-VA base.
- **the original** - learned by alignment and corroborated across functions, in
  `extracted/runtime_helpers.tsv` with witness counts.

Do not hand-edit that table.

---

## 3. Things believed to be blockers that are not

Each of these was filed as a blocker by the work-set classifier, then measured and found
free. The pattern repeats often enough to be worth naming: **the classifier counted
assumptions, not measurements.**

| assumed blocker | reality | evidence |
|---|---|---|
| `TList` / `TListEnum` / `TLink` calls | free - the real `BRL.LinkedList` is imported and its slot layout matches | standalone probe, 4/4 exact |
| `For ... EachIn` | free - the blocker is missing **Global** support, not TList | standalone probe, 3/3, 0 leaks |
| static cross-Type calls `TFoo.Bar()` | free | standalone probe, 4/4, 2/2 controls |
| module-level `Global`s | free via the `'!Global` pragma | - |
| `Super.Method()` | free once both call targets are named | 21/21 on both `TBitmapFontLoadException` thunks |
| most `FUN_xxxxxxxx` blockers | BRL/PUB module code or compiler-emitted; 132 of 134 are above `0x0058DBF3` | - |
| `FUN_005b9690` (gates 144) | the Double→Int truncation helper `bcc` emits for `Int(x)` | disassembly |

---

## 3a. Which BlitzMax builtin is `FUN_005xxxxx`? Look it up.

`extracted/brl_functions.tsv` names **735 of the 1,687 BRL/PUB module functions** inside
NSS5.exe (`va → symbol`). Built by `scripts/name_brl.py`, which matches every module
function against the compiled BlitzMax archives byte-for-byte with relocation sites
excluded - direct identification, not inference.

**Check this table before guessing.** A call to `FUN_0059F089` is `Rand()`; there is no
need to infer it from context:

| VA | symbol | what to write |
|---|---|---|
| `0x005B9690` | `_bbFloatToInt` | nothing - `bcc` emits it for `Int(x)` |
| `0x0059F089` | `_brl_random_Rand` | `Rand(...)` |
| `0x0059B25E` | `_brl_audio_PlaySound` | `PlaySound(...)` |
| `0x005AD711` | `_brl_max2d_DrawImage` | `DrawImage(...)` |
| `0x005B8307` | `_brl_stream_WriteLine` | `WriteLine(...)` |
| `0x005AE38D` | `_brl_max2d_MidHandleImage` | `MidHandleImage(...)` |
| `0x005AE336` | `_brl_max2d_SetImageHandle` | `SetImageHandle(...)` |
| `0x0059CC21` | `_brl_standardio_Print` | `Print ...` |

The oracle also consults this table, so an `E8` into a *named* BRL function is masked by
name on both sides. An `E8` into one of the 952 still-unnamed ones is not maskable, and
the result is an honest MISMATCH - say so rather than working around it.

If a body reproduces the original's **length** exactly and differs only inside `E8`
operands, the shape is right and only the callee identity is wrong. That is a lookup
problem, not a logic problem.

## 3b. The helper table can be wrong - audit it

`extracted/runtime_helpers.tsv` is *bootstrapped*: our side is named exactly by the
linker, the original's side is learned by alignment. That makes a wrong entry possible,
and a wrong entry is dangerous, because masking keys on the NAME - so it can hide a real
difference instead of revealing it.

This has already happened once. `0x004A6C20` was learned as `_bbStringFind`, and
`TProfile.GetOriginalName` was blessed byte-identical using `.Find()`. It was wrong:
`0x004A6C20` is `_bbStringFindLast` (it loads both string lengths up front and computes
`len - start`, scanning backward; the real `_bbStringFind` at `0x004A6B60` branchlessly
clamps a negative start with `xor eax,-1 / sar eax,31`). With the table corrected the old
body is rejected at 64/79 and `.FindLast()` is exact.

Run the audit whenever the table has grown:

```bash
python scripts/helper_map.py
```

It flags **one symbol claimed by two different addresses** - the exact shape of that bug - 
and lists single-witness entries. Investigate anything it prints; do not assume the table.

The same table also *corrects* mistakes: `FUN_00505BCB` was first reconstructed as
returning a trimmed String and came out 2 bytes long. The table identified the callee as
`_bbStringToInt`, not `_bbStringTrim`, so the field is parsed as an integer - and with
that the function is exact at 153/153.

## 3c. Parallel builds: use your own toolchain

`bmk`/FASM/GCC keep scratch state inside the BlitzMax tree, so two builds in one tree
corrupt each other (measured: 6 parallel builds → 4 false MISMATCHes). Each worker gets
its own 212 MB copy instead:

```bash
NSS5_WORKER=3 python -c "...try_method(...)"
```

The first call creates the copy, later calls reuse it. Verified: 4 concurrent workers each
returned 4/4 selftest in the same wall-clock time as one worker alone. **Always set it** - 
without it you share one tree with every other pass and serialise behind them.

## 3d. Bodies that are EMPTY

A large share of the corpus is compiler-generated and has **no source at all**. In one
173-function sample, 156 matched this way, every one on the first attempt.

| shape | body |
|---|---|
| `New`, 34 bytes: `FUN_004A8E50(param_1); *param_1 = &classtable` | **empty** (confirmed 63/63) |
| `Delete`, 14 bytes | **empty** - Type with no heap-reference fields |
| `Delete`, 34 bytes: load field, `dec [field+4]`, if zero call `FUN_004A8590` | **empty** - inlined BBRELEASE of the Type's single heap field (confirmed 9/9) |

`FUN_004A8590` is the GC free called from inlined BBRELEASE; it is never written in
source. Do not try to reproduce teardown by hand - declare the method and leave it empty.

Other one-liners worth recognising:

| decompiled | source |
|---|---|
| `FUN_004A8F20(&PTR_DAT_<classtable>)` | `New <Type>` |
| a 19-byte function whose only statement is `FUN_004A4620()` | `End` |
| a `()$` method returning `&PTR_PTR_00C5D284` | `Return ""` |
| `(*(code *)PTR_FUN_00Cxxxxx)(args)` where the pointer is *this Type's* class table + slot | a plain call to a sibling Function: `Foo(0)`, **no** `Type.` prefix |

`mode=reloc` on a tiny float function is expected, not a warning: float constants live in
`.rdata` and their operands relocate.

## 3e. Working a LARGE function

Big bodies dominate what is left - 142 functions of 1000+ bytes hold 58% of the outstanding
READY bytes, and the median is 272. These will not match first try, so do not treat a
mismatch as failure.

Use `first_diff`. `bcc` emits statements in source order, so the first differing byte
localises the *first wrong statement* - everything before it is already correct. The loop:

1. write the whole body from the decompilation
2. run the oracle; read `first_diff` and the two disassembly windows
3. fix only the statement that byte belongs to
4. repeat

Each pass nails down one statement, and the diff offset should march forward every time.
If it moves *backwards*, the last edit broke something that already matched - revert
it. At ~1.5s a build a 1000-byte function is perhaps 10-20 iterations, which is minutes,
not hours.

Read the length first: **our length longer than the original** almost always means a
subexpression is computed twice and the original used a Local (see §6). **Shorter**
usually means a missing branch or an early return where the original cascades.

## 3f. "Unresolved indirect calls" are usually just untyped Globals

80 functions (149,371 bytes, 26% of everything outstanding) were classified BLOCKED on
*unresolved indirect calls*. They are not blocked. The calls look like this:

```c
(**(code **)(*(int *)PTR_DAT_00C6BA50 + 0x54))(PTR_DAT_00C6BA50)
```

which is a method call on a module Global - and the only missing piece is the Global's
**Type**. With the Type, the slot is an ordinary lookup in `vtable_map.tsv`.

`extracted/globals_final.tsv` is the authoritative table: `va, type, name, type_source,
confidence, subsystem, note`. **601 Globals are typed from their construction site** - 
either `push <classtable>; call bbObjectNew` or the declared return type of the factory
they are assigned from - which is evidence, unlike a guess from usage. `type_source`
tells you which you are relying on; 23 rows have conflicting construction sites and say so
in `note`.

Worked example - `TRoulette.Spin`, filed as BLOCKED on this shape, is **116/116 exact**:

```
0x00C6BA50 TPanel          slot 0x54 = TGadget.Hide   (inherited)
0x00C6BA58 TButton         slot 0x54 = TGadget.Hide   (inherited)
0x00C6BBBC TRouletteWheel  slot 0x34 = Reset()
0x00C6BBC0 TRouletteBall   slot 0x34 = Reset(:TRouletteWheel)
```

Note the slot may be **inherited** - `TPanel` and `TButton` have no 0x54 of their own; it
comes from `TGadget`. Walk the `Extends` chain in `class_tables.tsv` before concluding a
slot is unknown.

That function also shows the guard pattern: `cmp [g],0 / jne body / mov eax,0 / jmp end`
is an **early return**, not an If-block. As an If-block it comes out 109 bytes instead of
116. (`If g = 0 Then Return 0` and `If Not g Then Return 0` emit identical bytes.)

## 3g. Recovered module Functions are callable

Everything in `src/recovered_module/` is emitted into every probe, so a body can just call
it. `LogLine` is the big one - 47 functions call it, and it is a **function-entry trace
logger**: the string literal is the calling function's own name.

```blitzmax
LogLine("ButtonHelpOk")
g_screen_helpok = 1
```

`TScreen.ButtonHelpOk` is 37/37 exact that way. Those files carry their own `'!Global`
pragmas, so their Globals come along automatically and are deduplicated against yours.

## 3h. BRL names can be an ALIAS SET

`brl_functions.tsv` symbols may be pipe-separated:

```
0x005B80B9  _brl_gnet_GNetObjectState|_brl_stream_Eof|_brl_timer_TimerTicks|_pub_freeprocess_ProcessStatus
```

Those four BRL functions have byte-identical 21-byte bodies, so the address genuinely
cannot be narrowed further. The mask accepts any member. Pick the one that makes sense in
context - for a `TStream` loop that is `Eof`. 33 addresses are alias sets.

If a body reproduces the length exactly and differs only in one `E8` operand, this is very
often why. `TTeamPool.LoadData` is exactly that case: a correct reconstruction that certifies
only once the alias set is applied, at 102/102.

## 4. Declaring module Globals

Module Globals have no debug record - the original names are **unrecoverable**, and names
do not affect codegen. Declare what a body needs, inside the body:

```blitzmax
'!Global g_players:TList
For Local p:TPlayer = EachIn g_players
	If p.newstar Then Return p
Next
Return Null
```

The pragma lines are lifted to module scope and stripped from the body. **The declared
type is load-bearing** - it selects the vtable slot for any call through it - so it is a
real assumption and belongs in the file's header comment.

---

## 5. `For ... EachIn`

Decompiled shape:

```c
enum = (**(code **)(*list + 0x8c))(list);        // TList.ObjectEnumerator
while ((**(code **)(*enum + 0x30))(enum)) {      // TListEnum.HasNext
  o = (**(code **)(*enum + 0x34))(enum);         // TListEnum.NextObject
  x = FUN_004a8f60(o, &classtable);              // bbObjectDowncast
  ...
}
```

is simply:

```blitzmax
For Local x:TSomething = EachIn thelist
	...
Next
```

`TListEnum.NextObject` takes **no argument** - its reflection signature is `():Object`.
The second argument Ghidra shows is really `bbObjectDowncast`'s class-table argument;
Ghidra models that helper's signature wrongly. The class table identifies the loop
variable's type, so check it against `class_tables.tsv` to get the type right.

---

## 6. Expression and statement forms

- `To N` emits `jle`; `Until N` emits `jl`.
- `> -1` and `>= 0` are different instructions. Match the decompilation.
- `Self.` has no codegen effect.
- **bcc does no CSE.** If the original computes something once, your source must too.
- `:+` emits `add [mem],reg` for a **memory** operand. For a register-allocated local,
  `x :+ 1` and `x = x + 1` are identical - the rule does not discriminate there.
- A bare `Return` in a method declared `:Int` fails to build. Many `()i` methods are
  simply `Method Foo()` with no explicit return; bcc emits `return 0`.
- Cascade-down `If`/`ElseIf` usually beats a chain of early returns - but check both.
  `TFormation.GetSelectionNoFromSeg` was 2 bytes short until it used the early-return form
  (`75 02 EB 07` rather than `74 05`).
- x87 sum chains print in FPU pop order, often reversed from source order.

### Float locals are kept in x87 registers

A `Float` Local consumed by the following expression gets **no memory slot** - it stays on
the x87 stack - and squaring it emits `fmul st(0)` (`D8 C8`). This makes the Local form
*shorter* than the inlined one, which is the opposite of the usual intuition:

```blitzmax
' 51 bytes, exact
Local dx:Float = a0 - a2
Local dy:Float = a1 - a3
Return Sqr(dx*dx + dy*dy)

' 61 bytes -- bcc has no CSE, so each difference is computed twice
Return Sqr((a0-a2)*(a0-a2) + (a1-a3)*(a1-a3))
```

---

## 7. Module-level Functions

Functions declared at module scope (not inside a Type) have **no reflection record**, so
`bytematch.find_method` cannot locate them. Use `harness.try_function(name, sig, body,
orig_va)` instead:

- ours is found by symbol - bcc mangles module functions `_bb_<Name>` (Type methods get
  `__bb_<Type>_<Method>`)
- the original is identified by the address its callers use, with the length from Ghidra

There are 92 such functions in game code (31,751 bytes); 42 are referenced as blockers.
Their names are ours to choose, exactly like Globals.

Recovered so far, in `src/recovered_module/`:

| ours | VA | bytes | gates | what |
|---|---|---|---|---|
| `GetText` | 0x004C5549 | 22 | 101 | forwards to `TLocale.GetLocaleText` |
| `LogLine` | 0x00505B91 | 58 | 47 | writes to a log `TStream`, then `Print` |
| `ClampInt` | 0x00505F6D | 35 | 12 | clamps `*a0` into `[a1,a2]` |
| `ClampFloat` | 0x00505F90 | 75 | 8 | Float twin of `ClampInt` |
| `Dist2D` | 0x00505DA2 | 51 | 6 | `Sqr(dx*dx+dy*dy)` |
| `ColourGreen` | 0x00507DC1 | 14 | 5 | returns the constant `"00FF00"` |

---

## 8. Reading the decompilation

Object header is 8 bytes; **user fields start at +8**.

`param_1` is `Self` for `KIND=Method` and is **NOT** `Self` for `KIND=Function` - those are
static with no implicit Self. Treating a static function's first argument as Self is one of
the largest sources of wrong reconstructions.

```
*(int *)(param_1 + 0x2c)                  ->  Self.<field at 0x2c>
(**(code **)(*param_1 + 0x40))(param_1)   ->  Self.<method at slot 0x40>
(*(code *)PTR_FUN_00c5ddfc)()             ->  <Type>.<Function>()   -- classtable+slot
&DAT_005c9c80                             ->  Null
```

An indirect call through a data pointer is not scary: resolve the pointer against
`class_tables.tsv`. If it lands inside a class table it is `Type + slot`, so look the slot
up in `vtable_map.tsv` and write the ordinary static call.

---

## 9. Debugging a near-miss

The oracle returns `first_diff` plus a capstone disassembly of both sides. Read it.

- a one-byte difference in a **field offset** (`8B 40 2C` vs `8B 40 28`) means the object
  layout is wrong, not the logic
- a different **jump opcode** means the loop or comparison form is wrong
- **our length longer than the original** usually means a subexpression is being computed
  twice - look for a Local the original used
- a difference only inside an `E8` operand means the call target could not be named on both
  sides; that is a tooling gap, not a bad body - report it

If something looks like a harness defect rather than a bad body, **say so**. Three times on
this project the tooling was the bug: a `0xC3` truncation that blessed wrong bodies, a
`Byte[n]` pad that silently moved every field after a sub-word hole, and blind masking that
hid which type a static call went to.

---

# 10. Emission rules the decompilation does not show

Read `extracted/decomp_annotated/` BEFORE `extracted/decomp/`. It resolves `Self.<field>`
names and class-table identities and removes most offset arithmetic.

## 10.1 Ghidra normalises things that are byte-observable

**Comparison operand order.** `If yy > bot` and `If bot < yy` are logically identical and
emit different bytes (`cmp esi,[bot] / jle` vs `cmp [bot],esi / jge`). Ghidra prints one
form regardless. `TCombo.GetNoofDisplayItems` matched only in the first. Same length, diff
at byte 101. Never trust Ghidra's operand order - read the `cmp`.

**Relational spelling.** `a0 <= 0` is `cmp esi,0 / setle`; `a0 < 1` is `cmp esi,1 / setl`.
Match the `setcc` and its immediate, not the meaning.

**Which side the parameter sits on.** `If a1 >= r.fields.Length` emits `3B 7A 14 / 7C`;
`If r.fields.Length <= a1` emits `39 7A 14 / 7F`.

## 10.2 Select is not If/ElseIf

`Select` evaluates the subject ONCE, emits **every** `Case` compare back to back, then a
`jmp` for the no-match path, then all the bodies. If/ElseIf interleaves test and body and
always comes out shorter.

> If the decompilation shows a run of `cmp`/`je` with every target past the LAST compare,
> it is a `Select`.

Measured: `TScreen_Options.ButtonCam` 156 as ElseIf, **160 exact** as Select.
`TCompetition.GetStringLocale` 85 vs **87**. `TScreen_Options.ButtonCorners` 121 vs **125**.
Holds for String subjects too, where each test is a `_bbStringCompare` call.

A Select with **no** `Default` differs again: the fallback is a statement *after*
`End Select`, which is what emits the trailing `jmp`.

## 10.3 Null tests have two distinct emissions

| source | bytes |
|---|---|
| `If x = Null` | `cmp dword [g], <bbNullObject> / je` - 12 bytes |
| `If Not x` | `mov eax,[g] / cmp eax,<bbNullObject> / setne al / movzx eax,al / cmp eax,0 / jne` - 21 bytes, branch sense inverted |

The tell is `setne al / movzx eax,al`. Nine bytes apart, so length alone usually decides it.

## 10.4 More empty bodies

Section 3d lists 14- and 34-byte `Delete`. Add: a **51-byte `Delete` that releases one
heap field AND tail-chains to a non-runtime Super** (e.g. `TPole.Delete` →
`TTrainingObject.Delete`) is also entirely compiler-generated. Empty body.

## 10.5 Float Locals - the rule scales

The LAST Float Local stays on the x87 stack; earlier ones spill to Float slots.
`TProfile.GetStatus` is 153 bytes inlined and **133 exact** as five
`Local x:Float = call()` followed by `Return (a+b+c+d+e)/5.0`.

## 10.6 Reading traps

- **Refcount traffic looks like logic.** `DAT_00c639f0 = DAT_00c639f0 + 1` is
  `inc dword [ebx+4]` - the retain half of a String assignment. Any `DAT_<x+4>` increment
  just before a store of `&PTR_PTR_<x>` is refcounting, not code.
- **A function-pointer Field is compared against the empty function `FUN_005B95D0`, not
  against zero.** `if (fRet != FUN_005B95D0) fRet()` is just `If Self.fRet Then Self.fRet()`.
  bcc also stores `FUN_005B95D0` into `()i` fields during default init.
- **`For ... EachIn` already emits its own null-skip.** Do not add an explicit one.
- **`To` and `Until` can MIX in one function.** `TOptions.WaitForJoyRelease` uses `To 255`
  for keys and `Until 15` for the joystick. Read each `cmp` immediate.
- **Module Globals are re-read from memory**, not kept in registers that still hold equal
  parameters. `TWeather.SetWeatherTimes` needs `If g_finish < g_start`, not `If a1 < a0` - 
  12 bytes short otherwise.

## 10.7 `globals_final.tsv` can be wrong about object-vs-Int

`0x00C5B254` and `0x00C6EFD4` are listed as `TScreen` (with a flagged construction-site
conflict) but `TEngine.DoShootOut` copies them with a bare `mov eax,[a] / mov [b],eax` and
**no refcount traffic** - so both are Ints.

> A plain dword copy between two Globals with no retain/release means **Int**.
> Trust the code over the table.

Conversely, an `Object` Global can be typed `TList` cheaply by checking whether any of its
other call sites uses slot `0x8C` (`ObjectEnumerator`). TList slot `0x74` is
`Remove(:Object)`.

## 10.8 The inferred BRL table is usable

`brl_functions_inferred.tsv` entries **do** get masked by the oracle - `KeyHit`
(`0x005B46EE`) appears only there and `TOptions.WaitForJoyRelease` still matched with
`reloc_masked=8`. It is evidence, not advisory.

Alias set `0x005B40BF` (`CreateList|CreateMap|TGNetHost.Create`) was `CreateList` every
time; the confirming tell is a following `TList.AddLast` at slot `0x44`.

## 10.9 Guard shape is per-function - check both

Both forms genuinely occur and they differ by several bytes.

- `TTable.SetItemText` needs the bounds check to **enclose** the body with one `Return 0`
  after it (early-return form gives 192 instead of 181).
- `TBlackJack.GetDealerScore` is the opposite: a real early return (If-block form gives 210
  instead of 216).
- Section 3f's guard generalises past zero: `TScreen_Negotiate.ButtonLower` is
  `If g > 4 Then Return 0` (150 exact), not a block (143).

`Continue` inside `For EachIn` emits `74 02 EB xx`. `If A Or B Then Continue` + stmt is
2 bytes LONGER than `If Not (A Or B) Then stmt`; `TTeam.GetShootoutPositions` needed the
`Continue` form (133 vs 135).

---

# 11. Arrays, Global types and length mismatches

## 11.1 Array truth test vs `.Length` - a source form, not a toolchain divergence

Array-length lowering looks like a toolchain divergence that "blocks EVERY function testing
an array's length": NSS5 emits `cmp dword [eax+0x10]` where our bcc emits
`cmp dword [eax+0x14]`, and four spellings all give `+0x14`.

It is a **source-form difference**, measured on a standalone probe:

| source | emits | header field |
|---|---|---|
| `If a.Length <> 0`, `If a.Length` | `83 78 14 00` | `scales[0]` (+0x14) |
| **`If a`, `If Not a`** | **`83 78 10 00`** | **`size` (+0x10)** |

A *bare array truth test* lowers to `size`; `.Length` lowers to `scales[0]`. For a 1-D array
both are non-zero together, so they are semantically identical and only the bytes differ.

> If the original tests `[eax+0x10]`, the source is `If arr` / `If Not arr`.
> If it tests `[eax+0x14]`, the source is `If arr.Length`.

BBArray header (`brl.mod/blitz.mod/blitz_array.h`), confirmed identical on both sides:
`0x00 clas / 0x04 refs / 0x08 type / 0x0C dims / 0x10 size / 0x14 scales[0] / 0x18 data`.
Data at +0x18 was independently confirmed by `TProfile.vehicles[i]` at `[eax+esi*4+0x18]`.

## 11.2 `globals_final.tsv` is wrong in both directions - trust the refcount traffic

Section 10.7 gives the object→Int direction. The inverse occurs as well, so the rule is:

> **Refcount traffic decides the type, not the access width.**
> A retain (`FF 40 04`) on the incoming value and a release (`FF 48 04` + conditional
> `bbGCFree`) on the outgoing one means it holds a **reference** (String or object).
> A bare `mov` with no refcount traffic means **Int**.

Known-wrong rows, all confirmed by reading the code:

| address | table says | actually |
|---|---|---|
| `0x00C5D290`, `0x00C639FC` | Int | **String** (full retain/release) |
| `0x00C5B1FC` | TPlayer (1 construction site) | **Int** (`TTraining.Fail` stores 11, bare mov) |
| `0x00C5DEA4` | TPlayer | **TBall** (see below) |
| `0x00C5DF00`, `0x00C5DF18` | Object[] | **Int[]** |
| `0x00C6AD80`, `0x00C6D9F4` | Object | **TList**, **TImage** |

**Construction-site typing is not automatically safe when only ONE site was found.**

And any row whose note reads *"only X has them all"* should be distrusted outright: the
uniqueness was tested against an incomplete candidate set. `0x00C5DEA4` was typed TPlayer
because "only TPlayer has slots 0x68,0x84,0x88,0x90" - but TBall has all four as well
(Kick / NewController / KeeperHolding / Deflect), and it is TBall.

## 11.3 `first_diff` is meaningless when the lengths differ

In `mode='len'` the oracle applies **no** relocation masking, so `first_diff` lands on the
first absolute-address operand - typically byte 4-19 - and localises nothing. `matched` is
a positional count over the shorter body, not a common-prefix length.

**On a length mismatch, only the two disassembly windows are usable.** Do not chase a
phantom byte 4. Fix the length first (see §3e: longer usually means a subexpression
computed twice; shorter usually means a missing branch).

## 11.4 Types extending a BRL Type

`brl_functions.tsv` names BRL module *functions*, not BRL Type *methods*, so a
compiler-generated `New`/`Delete` that chains into a BRL Super cannot have its call operand
named on the original side and will not mask - even with a provably correct empty body.
Measured: `TMyStream.New` 35/41 (Super.New into `TStreamWrapper.New` at `0x005B78CC`),
`TMyStream.Delete` 26/32. Both bodies are correct; neither can be banked yet.

Related and dangerous: `0x005B78F9` carries the single name
`__brl_socketstream_TSocketStream_Delete`, but the call site in `TMyStream.Delete` is
unambiguously `TStreamWrapper.Delete` (the class-table immediate stored just before the call
is `0x00CB1D94` = TStreamWrapper). Those two BRL `Delete` bodies are byte-identical, i.e.
exactly the alias-set condition from §10.8 - so this is a **missing** alias set, which by
§3b can hide a real difference elsewhere.

## 11.5 `KIND=Function` rows are static methods

`KIND=Function` rows in the work set are **static methods on a Type** - use `try_method`,
not `try_function`. `try_function` with a dotted name fails deep inside the generated probe
with `Missing type specifier`, which reads like a bad body.

---

# 12. The Globals table, and function families

## 12.1 A third of `globals_final.tsv` was never Globals

924 of 2,894 rows are **class-table interiors** - runs of method pointers, which the
extractor saw as dwords that code loads and never writes, and filed as "read-only Int
Globals". `0x00C61CC0` is not an Int; it is `TScreen+0x94` = `DoMessage`.

They are now marked `type_source=classtable-slot` and carry the resolved `Type+slot =
Method sig`. **An address inside a class table's extent is never a Global.** Corroborated
independently: the load-time dword is a code pointer for 923 of the 924, which it could not
be for a Global.

So the real Global population is **1,970**, not 2,894. 18 hand-verified corrections now live
in `globals_corrections.tsv`, which `merge_globals.py` applies over every automatic source.

`"only X has them all"` notes are re-tested against the full class-table set on every
regeneration: unsound ones are rewritten to say the slots are shared, name the sharers, and
mark the Type a GUESS. Never rely on one of those without a construction site.

## 12.2 Look for FAMILIES before grinding functions individually

This has now paid off four times. The asset loaders share one shape - `"incbin"` bypass,
path resolution against two Globals, four log messages, `GCCollect` on failure - and once
the first was understood the rest matched on the FIRST attempt:

| ours | VA | bytes | loads |
|---|---|---|---|
| `LoadImageChecked` | 0x004BC372 | 251 | `LoadImage` |
| `LoadSoundChecked` | 0x004BC564 | 256 | `LoadSound` |
| `LoadPixmapChecked` | 0x004BC46D | 247 | `LoadPixmap` |
| `LoadAnimImageChecked` | 0x004BC664 | 271 | `LoadAnimImage` (**91 callers**) |

`FUN_004BBFC1` (settings reader) shares the same opening but tests the two path Globals in
the OPPOSITE order - operand order is byte-observable, so check it rather than assuming.

Two module Functions can also be **byte-identical twins**: `SplitString` (0x005070DD) and
`SplitString2` (0x005062B7) are both 230 bytes with the same body. `NextField` is the String
twin of `NextFieldInt`. When a body resists, look for a sibling that is already solved.

---

# 13. Three ways a verification can fake itself

## 13.1 AUDITS MUST SET `NSS5_NO_LEARN=1`

Stubbing `helper_map.record` to a no-op does **not** establish that "no function can
contribute the table row that then masks its own call operand". Stubbing `record()`
suppresses only PERSISTENCE. In-run learning is separate and still runs:

```python
_persisted, conflicts = _helper_map.record(...)   # the audit stubbed THIS
for _v, _sy, _known in learn:
    origtab.setdefault(_v, (_sy, 1))              # and this still ran
# ... then re-compared with mode == "learn"
```

So a body differing from the original at exactly one unnamed call operand teaches itself the
name and re-compares clean **inside the same `try_method` call**, whether or not `record()`
is a no-op. That is precisely the self-fulfilling masking the stub is meant to prevent, and
any row reporting `learned_helpers` was decided that way.

`NSS5_NO_LEARN=1` forces `learn=None`, so an unnamed original-side call operand simply
fails to mask. Default OFF - ordinary verification still learns, which is how the table was
bootstrapped. **An audit must set it.** Measured blast radius on first use: 4 of 1,284 rows.

## 13.2 String literals ARE recoverable - use `harness.read_string(va)`

`bytematch.read_va` returns None for literals in `.data`, which invites the conclusion that
literal CONTENTS cannot be read, that "every reconstructed literal is a placeholder" and that
faithfulness is permanently capped. **That is wrong**, and acting on it would put placeholder
text throughout the source. The three addresses that look unreadable:

    0x00C725EC 'FF0000'      0x00C84868 'Select Club'      0x00C914E4 'UpdateFaces'

A BBString is `[class][refs][length][UTF-16 chars]`: text at +12, `length` counts
CHARACTERS not bytes. `harness.read_string(va)` does it - do not write a fourth private
version.

**Always recover the real literal.** The oracle masks the literal's ADDRESS, so it can
never tell `"~~t"` from `"~t"` - literal contents are outside what a MATCH certifies, which
makes reading them from the exe the only thing that keeps them faithful.

## 13.3 Never stub a module Function to make a caller mask

`harness.module_functions()` treats everything in `src/recovered_module/` as verified, and
`helper_map.orig_functions()` names the ORIGINAL side from those same file headers. So
writing a placeholder file for an unrecovered VA makes a caller's `E8` mask by name and
return MATCH on a body that was never verified - self-fulfilling masking again. The right
response is to leave a fully decoded body unbanked rather than fake a match: `0x004BC88C` is
the worked case, and declining to stub it was correct.

# 14. Composition - the per-function oracle is not the whole proof

## 14.1 What a per-function MATCH does and does not establish

Every verified body was compiled **alone**, inside a probe program `harness.py` generates:
a synthetic Type carrying that one method, the Globals it declares, stubs for what it
calls. A MATCH proves the body is right *in that context*. It does not prove the corpus
composes, and four whole-program facts can change the emitted bytes without any body being
wrong:

* **vtable slots** - a method's slot comes from declaration order within its Type and from
  what the supertype occupies. In a probe the Type has one method; assembled it has forty.
  Every `call [eax+N]` through a reconstructed object depends on N, and N is a
  whole-program property.
* **Global types** - a Global declared `TGadget` in one probe and `TButton` in another
  compiles both times. Assembled, one wins and shifts the dispatch slot for the other.
* **Type declaration order** - bcc registers Types in source order, and that order reaches
  the module body.
* **name collisions** - two Globals distinct in two probes can merge into one slot.

`scripts/check_assembled.py` is the second proof. **Result: 400 of 400 sampled verified
methods are byte-identical inside the assembled program** (76 exact, 324 modulo
relocation, 0 diverged). The corpus composes.

## 14.2 Use `harness.compare` across images, never `bytematch.compare`

The first version of the composition check used `bytematch.compare()` and reported 35 of 40
functions DIVERGED. Every one was an absolute address or an `E8` displacement:

    orig  55 89 E5 A1 A0 DC C5 00 50 8B 00 FF 50 34 ...
    ours  55 89 E5 A1 DC 9E 5B 00 50 8B 00 FF 50 34 ...
                     ^^^^^^^^^^^ the SAME Global, at its address in each image

`bytematch.compare` is the **raw** differ - right when you want to see literal bytes, wrong
across two independently-linked images, which can never agree on a relocated operand.
`harness.compare` applies the four masks and is the only correct cross-image comparator.

## 14.3 A stale assembled exe fails in the most alarming direction

The corrected check then reported 3 of 40 as `LENGTH 610 vs 14` - 14 being the empty-method
stub - which reads exactly like the assembler silently dropping verified bodies. It had
not: `src/recovered` is a **live tree**, and those three bodies landed in it in the minutes
after `assemble.py` ran. Re-assembling made all three identical.

Always re-run `assemble.py` before `check_assembled.py`. The script warns when any body is
newer than the exe, but the general lesson stands for every corpus-wide measurement:
**a number computed over a tree that is still being written to has a timestamp**, and
comparing across that boundary invents defects.

## 14.4 One coverage number, one denominator

`scripts/coverage.py` is the canonical metric - run it, quote it, do not hand-roll another.
Three denominators were in circulation simultaneously (1,850 / 2,749 / 4,318), all computed
honestly, all reported as "the" coverage. A percentage whose denominator moves is not a
measurement, and a rising one can hide a shrinking numerator.

The universe is game Type methods plus game module Functions; BRL/PUB module code and
C-runtime helpers are excluded, because our toolchain emits those from the same BlitzMax
sources whether or not we ever look at them - counting them would inflate the number with
work nobody has to do.

**Quote bytes, not function counts.** The counts flatter: the small functions went first,
so 61.7% of functions is 23.5% of bytes. The large ones are the remaining work.

# 15. Naming an original-side callee WITHOUT the learn path

## 15.1 The circularity, and the way out

The oracle masks an `E8` displacement only when the target is named on BOTH sides. When the
original side is unnamed, `harness` can LEARN the name from our linker symbol - but if the
only witness is the very body being verified, that body taught itself the name and then used
it to pass. Four asset loaders sat in exactly that state, correctly flagged
`!! NOT CERTIFIED` and blocked on `0x005B9660`.

**A module callee can be named by comparing it against our own build of the same module.**
`code` is bcc output, and we compile the same BRL sources, so a BRL function exists in both
images and can be diffed directly - no game body involved, no learning, no circularity.

Worked example, `0x005B9660` (20 bytes):

1. It is byte-identical to our `___bb_blitz_blitz+0x3c4` **except bytes 6-7**, the relocated
   operand of its `FF 15`. Two independently-linked images cannot agree on that operand, so
   this is equality.
2. Its shape is `push ebp / mov ebp,esp / call dword ptr [abs] / mov eax,0 / jmp +0 /
   leave / ret` - a no-arg BlitzMax Function whose whole body is one call through a
   **function-pointer Global**, result discarded.
3. `brl.blitz` declares `Global OnDebugStop()="bbOnDebugStop"`. A pointer Global is exactly
   what compiles to `call dword ptr [abs]` instead of `E8`, and
   `Function DebugStop() ; OnDebugStop ; End Function` is the only body in `brl.blitz` with
   that shape.
4. `helper_map.brl_table()` already holds `0x005b9660 = _brl_blitz_DebugStop`. It is easy to
   call a VA "unnamed in every table" after checking `runtime_helpers.tsv`, `vtable_map` and
   `orig_functions` but not `brl_table`. **Check `full_table()` before concluding a VA is
   unnamed.**

## 15.2 `GCCollect` is not a wrapper - extern aliases never are

`brl.blitz` declares `Function GCCollect()="bbGCCollect"`, an **extern alias**: it compiles
to a direct call to the C symbol and can never be a 20-byte BlitzMax wrapper. Any
`Function Foo()="bbFoo"` behaves this way. So a call landing on a 20-byte BlitzMax function
is definitively *not* one of these, which is what ruled `GCCollect` out on structure alone.

## 15.3 The result, and why it was a real discrimination

All four loaders MISMATCH with `GCCollect` and MATCH at full length with `DebugStop` under
`NSS5_NO_LEARN=1`:

| body | GCCollect | DebugStop |
|---|---|---|
| LoadAnimImageChecked | MISMATCH 190/271 | **MATCH 271/271** |
| LoadImageChecked | MISMATCH 174/251 | **MATCH 251/251** |
| LoadPixmapChecked | MISMATCH 173/247 | **MATCH 247/247** |
| LoadSoundChecked | MISMATCH 175/256 | **MATCH 256/256** |
| TButton.SetIcon | **MATCH 77/77** | MISMATCH 64/77 |
| TEngine.EndMatch | **MATCH 530/530** | MISMATCH 346/530 |

The last two rows are the control: they really are `GCCollect`, and they reject `DebugStop`.
The test discriminates in both directions, so this is not a spelling that merely happens to
have the right length. `DebugStop` in an asset-loader failure path is also what the code is
plainly for - it stops in the debugger when an asset cannot be loaded.

**Both call sites emit five bytes**, which is why length alone never caught this and why
four bodies could carry a wrong statement while reporting the correct byte count. Where a
body calls a no-arg helper, the byte count constrains nothing about *which* helper.

## 15.4 The technique works for bcc output and FAILS for GCC output

Cross-image comparison names a callee because bcc is deterministic: the same BlitzMax source
gives the same bytes in both images, so a BRL *BlitzMax* function can be matched directly.

It does **not** extend to the C runtime. Our GCC differs from the original's, and the
difference is structural, not cosmetic. `bbStringToFloat`:

    original 0x004A6E90, 47 bytes, THREE calls
        +11 -> 0x004a6e20     (bbStringToCString)
        +21 -> 0x004b4750     (atof)
        +33 -> 0x004a8da0     (bbMemFree)

    ours, 60+ bytes, TWO calls -- our GCC INLINED the UTF-16 -> char conversion, visible as
    `8a 44 57 0c` (mov al,[edi+edx*2+0xc], the BBString character walk) in the body itself.

So "name the unnamed callee by its ordinal position inside an already-named function" is
sound for `code` and unsound for `.text`: the call sequences are not in correspondence.
`0x004a6e20` and `0x004a8da0` remain unnamed for this reason, and guessing them from
position would have been wrong.

**Check `helper_map.full_table()` before declaring anything unnamed.** `0x005B9660` reads as
"unnamed in every table" while `brl_table()` holds `_brl_blitz_DebugStop`, and `0x004A6E90` -
which looks like the biggest unnamed helper at ~63 call sites - is in `full_table()` as
`_bbStringToFloat`. Its `fld qword` return spill reads like a Double, but spill width is how
GCC preserved the value across `bbMemFree`, not the declared return type; that inference
would have overwritten a correct name with a wrong one.

# 16. Large-body work

## 16.1 `:+` and `= x +` are NOT the same bytes

`+` is left-associative, so the two forms parse differently and bcc emits the concats in a
different order:

    s = s + "~t" + X     parses (s + "~t") + X   -> concat(s, tab) FIRST, then concat(_, X)
    s :+ "~t" + X        evaluates the RHS as a unit -> concat(tab, X) first, then concat(s, _)

**Tell:** a `concat(literal, value)` immediately followed by `concat(accumulator, result)`
is `:+`. `TProfile.SaveProfile` uses `:+` for ~130 appended fields; getting this right on
the first draft produced 4,572 of 4,574 bytes.

## 16.2 Argument push order exposes whether a temporary existed

bcc pushes arguments right-to-left and evaluates a nested **first-argument** call LAST. So:

    SplitString2(ReadSettingString(...), ",")          pushes "," BEFORE calling ReadSettingString
    Local ln:String = ReadSettingString(...)           calls ReadSettingString FIRST,
    SplitString2(ln, ",")                              then pushes ","

Both are **exactly 32 bytes**. When lengths are equal and `first_diff` lands on a push
sequence around a nested call, stop hunting for a missing branch and try a `Local`.
Corroborated against an already-verified body: `TEngine.RenderGameEngine` (0x004CF821,
587/587) emits `DrawText(TEngine.GetStringMatchState(), x, y)` by pushing x and y first.

**A String Local consumed by the very next statement costs ZERO bytes** - it stays in eax
with no stack slot and no refcount traffic. Same phenomenon as the Float-locals rule (6/10.5).

## 16.3 Read `sub esp,N` BEFORE writing anything

The prologue counts the source's Locals directly. `TOptions.LoadOptions`: original
`sub esp,0x14` (5 slots) vs our `sub esp,0x1c` (7) proved ONE loop counter is reused across
three CSV loops rather than three separate counters. Ghidra does show a single `local_c`,
but it reads like decompiler variable-merging and is easy to dismiss.

On a large body this is decisive: `TTeam.UpdatePlayerDestinations` opens `sub esp,0xD0` - 
**52 dword slots** - and holds `desx`/`desy` at `[ebp-0xC4]`/`[ebp-0xC0]`. Every local-slot
displacement in the body depends on the COMPLETE declaration list, so **no prefix probe can
converge until that list is reconstructed.** Do not iterate on a prefix of such a function.

Related: bcc **elides** `Local x:Float = 0.0` entirely, but the original emits real stores
(`fld [const]` / `fstp [ebp-0xC4]`). Those are therefore bare `Local` declarations followed
by *separate assignment statements*.

## 16.4 Before grinding a `Save*`/`Write*` body, find its `Load*`/`Read*` twin

`TProfile.SaveProfile` (4,574 bytes) fell out almost free because `TProfile.LoadProfile`
(6,481) was already banked: same file format, so the reader supplied field names, Global
identities and names, record boundaries, and both of the format's odd orderings. The same
pairing exists for **TClub, TCompetition, TContinent, TNation, TFormation, TOptions,
TReplayFrame**.

## 16.5 Two accumulator conventions can appear in ONE function

`WriteLine(a0, Self.tipcount)` is 2 bytes shorter than `s = Self.tipcount` +
`WriteLine(a0, s)`. `TProfile.SaveProfile` routes `tipcount` through the accumulator
(`mov ebx,eax` / `push ebx`) but routes `skillshash` inline four lines earlier. The only
tell is a redundant-looking `mov ebx,eax` before the `push`. Do not normalise these.

## 16.6 `try_method`'s diff output cannot localise a large body

`orig_hex`/`our_hex` are the first 96 bytes and the disassembly windows are 8 lines, so
neither locates anything in a 4 KB body. Derive full byte arrays with
`_bytematch.find_method` on both exes and run an alignment that reports only
**length-changing** gaps, ignoring relocation noise. That found a 54-byte deficit in a
single pass. Use `scripts/localise_diff.py`.

## 16.7 Global-type corrections found by direct evidence

* `0x00C59097` is the BBArray element-type descriptor for **Int** (first byte `0x69` = `'i'`).
  It is passed to every `bbArrayNew1D`/`bbArraySlice` in `TOptions.LoadOptions`, which types
  all 32 globals `0x00C5DEAC..0x00C5DF28` (`g_player_arr01..arr32`) as `Int[]` from direct
  evidence. `globals_final.tsv` types 27 of them `Object[]` and is wrong.
* `0x00C5DE2C` is a **String**, not the Int `globals_final.tsv` claims - it carries full
  retain/release traffic around its store (pattern 11.2: refcount traffic decides the type).
* `0x00C6E900` is a **String**, not the Int claimed; it is pushed straight into
  `_bbStringConcat` with no Int→String conversion. Fifth independent contradiction of that row.

## 16.8 Reproduce the original's quirks, do not tidy them

`TOptions.LoadOptions` assigns its 32 array globals **out of address order** (arr24 and
arr25 before arr22 and arr23), and only the THIRD CSV loop calls `LogLine("Adding:" + s)`.
Both are load-bearing for the byte count.

# 17. Local register allocation - what it is NOT (measured over 1,494 verified bodies)

These figures come from mining the verified corpus rather than synthetic probes: every body
in it already byte-matches, so each is a source form whose allocation is known-correct.

## 17.1 "the last three declared Locals get ebx/edi/esi" does not generalise

Measured on a single function that rule looks right. Over the corpus it fails badly:

| declared Locals | bodies | registers actually saved |
|---|---|---|
| **0** | 850 | 445 use none - but **303 use 1, 79 use 2, 23 use 3** |
| 1 | 304 | only 58 use 1; **118 use all three** |
| 2 | 159 | only 29 use 2; **97 use all three** |
| 3 | 63 | 49 use three (78%) |
| 7 | 13 | 13 use three (100%) |

**850 bodies declare no Locals at all and 405 of them still save callee-saved registers.**
So ebx/esi/edi are not a "Locals" resource: bcc puts `Self`, loop counters, hidden `EachIn`
enumerators, invocants and expression temporaries in them too. Counting declared Locals
cannot predict the register set, and any rule phrased purely in terms of Locals is wrong.

What *does* hold reasonably: **frame size = max(0, N−3) × 4** in 78.3% of bodies (2.6% come
in under - elided `Local x:Float = 0.0`, section 16.3 - and 19.1% over, from spills and
enumerators). So "about three things live in registers and the remaining Locals go to the
frame" is a decent sizing heuristic, and a useful sanity check on a candidate Local list,
but it says nothing about *which*.

## 17.2 The choice is syntactic, not frequency-based - which is why permuting works

`TScreen_MatchPrep.CreateScreen` is the decisive case. The **original** keeps `h` (read ~50×)
on the stack at `[ebp-4]` and `wnum` (read ~24×) in `edi`; our build does the reverse. If bcc
were choosing by use-count it would have made the opposite choice, so it is **not**
optimising - it is following a deterministic syntactic rule, and the original's source simply
declared these Locals in a different order or position than our reconstruction did.

That is good news: it means the fix is a **permutation of the source**, not a compiler
mystery. When `localise_diff` reports the delta is fully accounted for by displacement swaps
(all gaps and subs being the same Local mapped differently), do not hunt for a missing
statement - reorder and reposition the `Local` declarations.

Corpus mining cannot say whether the rule keys on declaration order, first-*use* order, or
declaration *position* (function top vs inside a loop body); that needs a controlled
experiment, and §18 has one. Section 16.3's negative result - `Local i:Int` + `For i = ...`
is byte-identical to `For Local i:Int = ...` - shows declaration *position* alone does not
move a For control variable, so that axis is ruled out.

---

# 18. The register-allocation rule (controlled probes)

## 18.1 Read the allocator instead of guessing at it

`tools/blitzmax-legacy-src/_src/` **is bcc's own source**, and it is the shortest route to
any of this. `_src/compiler/bcc.cpp` shows the pipeline (`FunBlock::genAssem`, namespace `CG`);
`_src/codegen/cgallocregs.cpp` is an iterated-coalescing Chaitin/Briggs **graph colouring**
allocator. Four facts from it govern every Local:

| fact | file |
|---|---|
| colours are `0=eax 1=edx 2=ecx 3=ebx 4=esi 5=edi`, mask `0x3f` (never ebp/esp) | `cgframe_x86.cpp` ctor |
| a node takes the **lowest free colour**; a call defines eax/edx/ecx, so anything live across a call starts at ebx | `selectRegs` |
| spill victim = **lowest `usage / (degree × block_count)`**; `usage` counts each def and use weighted `10^loop_level`; `block_count` is 1 + the blocks where the value is live-in **and** live-out | `spill`, `createGraph` |
| stack slots come from `local_sz += 4; mem(ebp,-local_sz)`, handed out in the order nodes **fail to colour** | `cgframe_x86.cpp:898` |

Consequences worth internalising:

* A `Local` is an ordinary CG temporary. It gets a frame slot **only when it fails to
  colour**, so `sub esp,N` counts *spilled* Locals, never declared ones. This is the exact
  mechanism behind §17.1's `max(0, N−3) × 4` heuristic and behind its 22% of exceptions.
* `Self`, loop counters, `EachIn` enumerators and expression temporaries are nodes too and
  compete on equal terms - which is why 405 bodies with **zero** declared Locals still save
  callee-saved registers (§17.1).
* `ebx`, `esi` and `edi` all `push` in one byte. **Which** of the three a Local lands in is
  byte-neutral. The only byte-observable question is **register versus stack**. Do not spend
  time predicting the identity.

## 18.2 The rule, and the probe that established it

Probe shape: `Int` Locals `a..e` plus an accumulator, all live across `Rand()` calls, each
Local given a unique sentinel initialiser `0x1111000N` so the emitted code labels its own
storage map. The rig puts many probe Functions in one `bmk` run.

> **Locals that keep a register are those with the highest reference count. Ties are broken
> by DECLARATION ORDER, earliest first. The losers take `[ebp-4]`, `[ebp-8]`, `[ebp-0xc]`.**

Established by three separated measurements:

* **Declaration order is the tie-break, and it moves everything.** Identical code, identical
  use order, declarations permuted - the map is *positional in declaration order*:
  `a b c d e` → `a`=edi `b`=esi `c`=[-4] `d`=[-8] `e`=[-0xc];
  `e d c b a` → `e`=edi `d`=esi `c`=[-4] `b`=[-8] `a`=[-0xc];
  `c a e b d` → `c`=edi `a`=esi `e`=[-4] `b`=[-8] `d`=[-0xc]. All 198 bytes.
* **Use order is not a lever.** Declarations fixed, use order permuted three ways: register
  set `{a,b}` every time.
* **Reference count outranks declaration order, and it is a RANK, not a weight.** One extra
  flat use of `c` promotes `c` into a register and demotes `b`. *Nine* extra uses give the
  identical map. The margin never matters.

Confirmed by predictions registered **before** the build: seven variants, register set
predicted correctly **7 of 7**
(`FLATA`→`{a,b}`, `FLATB`→`{a,b}`, `FLATD`→`{a,d}`, `FLATE`→`{a,e}`, `FLATDE`→`{d,e}`,
`FLATCDE`→`{c,d}`, and `FLATE_rev` with reversed declarations →`{e,d}`). The *slot ordering*
among the spilled was predicted 4 of 7 - it carries a second-order `degree` (live-range
length) dependence that rank alone does not capture, so treat slot depth as diagnostic
output, not as something to predict.

## 18.3 A use inside a `For` loop does NOT act like ten flat uses

`10^loop_level` invites the opposite conclusion. Measured: moving one extra use of `c`
inside `For Local k:Int = 1 To 2` leaves the map **identical to the baseline** (`c` still
spilled), while the same extra use written flat promotes `c`. The loop's own counter and its
extra blocks cancel the weighting. Never reason about loop weighting from the source alone.

## 18.4 When rank cannot be the answer: `block_count`

`block_count` divides the spill cost, so **a value that is live in every block is cheap to
spill** and a value with holes is cheap to keep. This is invisible in small functions and
decisive in gadget-construction bodies: `TScreen_MatchPrep.CreateScreen` has **86 basic
blocks, 49 of them after its Locals appear** - one per Global gadget store, from the inlined
BBRELEASE `jne`. These bodies are not straight-line.

That is how a 28-reference Local can outrank a 50-reference one, and it is the only
remaining explanation when two builds agree on every reference count and still disagree on
the map. When that happens the difference is a **live-range** difference - one reference
sitting in the wrong place, keeping a value alive across a stretch where the original lets it
die. Look for it with a per-storage touch census plus the gaps between touches, not by
permuting declarations.

## 18.5 Corollaries, and what they rule out

* "What makes bcc put a Local in `edi`?" is the wrong question (§18.1, byte-neutral).
* A Local's storage is **not** claimed at its first non-elided assignment: storage is decided
  in the colouring pass, long after emission order is fixed.
* Declaration order **is** a lever (§18.2). It is inert only where the reference counts are
  already distinct, which is exactly the shape of body that suggests otherwise.
* Resources are handed out in descending reference-count order, which is right about the
  ordering and incomplete on its own: it omits the tie-break, and a probe whose Locals have
  five distinct counts cannot see one.

# 18. The register allocator - the rule, and what it rules OUT

Read this section together with the one above it before attempting any body whose only
defect is Local placement.

## 18.1 bcc's allocator source is IN THIS REPO

`tools/blitzmax-legacy-src/_src/codegen/cgallocregs.cpp` - an iterated-coalescing
Chaitin/Briggs **graph-colouring** allocator. Stop guessing; read it. Four facts drive
everything:

* colours `0=eax 1=edx 2=ecx 3=ebx 4=esi 5=edi`, mask `0x3f` (never ebp/esp)
* a node takes the **lowest-numbered free colour**, so anything live across a call - which
  defines eax/edx/ecx - starts at **ebx**
* spill victim = lowest **`usage / (degree × block_count)`**, `usage` counting every def and
  use weighted `10^loop_level`
* stack slots come from `allocLocal`: `local_sz += 4; mem(ebp,-local_sz)`, handed out in the
  order nodes **fail to colour** - so slot depth is an allocation-order fingerprint

A BlitzMax `Local` is an ordinary CG temporary. It gets a stack slot **only when it fails to
colour**, so `sub esp,N` counts *spilled* Locals, not declared ones. (This is why section
17's corpus census found 850 bodies with no Locals still saving registers.)

## 18.2 The rule, confirmed 7/7 by advance prediction

**The Locals that keep a register are those of highest reference count, ties broken by
declaration order (earliest wins). Losers take `[ebp-4]`, `[ebp-8]`, `[ebp-0xc]` in
declaration order.**

Measured, with the predictions registered *before* the run: register set 7 of 7; slot order
among the spilled 4 of 7 (the residual has a second-order `degree` dependence). Physical
register identity was deliberately not predicted - `ebx`/`esi`/`edi` all push in one byte,
so only register-vs-stack is byte-observable.

Supporting measurements:
* **Declaration order is a lever** - permuting declarations alone moves the map, all bodies
  staying 198 bytes.
* **Use order is not** - permuting uses leaves the register set unchanged.
* **Reference count is a RANK, not a weight** - *one* extra flat use flips the decision, and
  nine extra uses give the identical map.
* **A use inside a `For` loop does NOT act like ten flat uses**, despite the `10^loop_level`
  weighting: the loop's own counter and extra blocks cancel it. Do not reason about loop
  weighting from the source alone.

## 18.3 What this RULES OUT - do not retry it

Applied to `TScreen_MatchPrep.CreateScreen` (the −41-byte body), reference counts are
`y` 82, `h` 50, `x` 36, `w` 29, `wnum` 28, and `esi` is unavailable (the original uses it as
the per-row gadget temporary at 31 sites). The rule predicts the register set `{y, h}` - 
**which is exactly what our build already produces**, against the original's `{y, wnum}`.

So the rule *explains our output rather than fixing it*, and it makes a strong negative
claim: **no permutation of the `Local` declarations can reach the original's map**, because
declaration order is only the tie-break and 50 vs 28 is not a tie. That rules out the
"reorder the Locals" lever.

**The remaining lever is LIVENESS**, i.e. `degree` and `block_count`. On the original,
`h` is live essentially everywhere (no hole larger than 132 bytes across +1740..+5660) so
its cost is divided down, while `wnum` is written three times with real holes (238 and 227
bytes) between them. A 28-reference Local outranks a 50-reference one when it is *deader
between its assignments*. The next experiment is therefore not a reordering but finding
which reference keeps our `wnum` alive across the original's holes.

## 15.5 A WRONG name in the table blesses WRONG source - worked case

The masking rule is "mask the `E8` when our symbol name equals the original-side table name".
That is symmetric in a dangerous way: if the table's name is **wrong**, the source that
produces the *matching wrong* symbol gets masked and passes, while the **correct** source is
rejected. A bad row does not merely block progress - it manufactures false MATCHes.

`extracted/runtime_helpers.tsv` named `0x004A6BF0` **`_bbStringStartsWith`**. It is
**`_bbStringContains`**. The function is 44 bytes and is exactly:

    sub esp,0xc / <push x> / third arg = 0 / call 0x004A6B60 (_bbStringFind) /
    inc eax / setne al / and eax,0xff / ret

which is literally `blitz_string.c:265` - 
`int bbStringContains( BBString *x,BBString *y ){ return bbStringFind( x,y,0 )!=-1; }`.
`bbStringStartsWith` and `bbStringEndsWith` are **call-free loops** in that same file, so
neither can be a function that makes a call; the real ones are at `0x004A6AA0` and
`0x004A6B00`.

**Ten already-verified bodies carried the wrong predicate**, every one of them written
`.StartsWith` where the binary calls `Contains` - the asset loaders, the settings readers,
`TKitStrings.CheckKitColours`, `TScreen.CreateScreen`, `TProfile.LoadProfile`,
`TProfile.GetNewTip`. In each file the `.StartsWith` count equalled the call-site count
exactly, so every occurrence was wrong.

Confirmed in both directions with the row corrected - `LoadImageChecked` is
**MISMATCH 176/251 as `.StartsWith` and MATCH 251/251 as `.Contains`** - and all 11 affected
bodies certify, including `FormatMoney` (617/617), which was deliberately left un-certified
while the table row was in doubt. A 50-file random sample confirmed no regression elsewhere.

**Two lessons.** First, a table row is evidence like any other and can be checked: these are
C-runtime functions whose sources are in `tools/blitzmax-legacy-src/mod/brl.mod/blitz.mod/`,
so read them. Second, when a body is *semantically* odd - `StartsWith(".")` on a rendered
number like `"1.5"` is never true, making both `While` loops in `FormatMoney` dead code - 
that is a signal the predicate is wrong, not that the game has dead code.

## 15.6 A wrapper is not the function it wraps - `Lower`/`Upper`, and 152 inverted call sites

`extracted/runtime_helpers.tsv` is learned and **gitignored**, so a wrong row there survives
only until somebody regenerates it - and comes straight back when they do. These two rows are
recorded here because they were wrong for a long time and cost 41 verified bodies:

| VA | learned (WRONG) | correct |
|---|---|---|
| `0x004A7410` | `_brl_retro_Lower`, 205 witnesses | **`_bbStringToUpper`** |
| `0x004A74E0` | `_brl_retro_Upper`, 14 witnesses | **`_bbStringToLower`** |

They were not merely swapped. **Neither address is a `brl.retro` wrapper at all**, and that
distinction is the whole lesson: `Function Lower$(str$) Return str.ToLower()` compiles to a
21-byte wrapper that *calls* `bbStringToLower`, so the wrapper and the C function are two
different `E8` targets and the source forms `Lower(s)` and `s.ToLower()` are **not
interchangeable**. NSS5 uses both, in different places.

Four independent proofs, none of them the oracle:

1. **The instruction that does the work.** `0x004A74E0` is `lea eax,[edi-0x41] / cmp eax,0x19 /
   or edi,0x20` - tests `A`-`Z` and *sets* bit 0x20, so it lowercases. `0x004A7410` is
   `lea eax,[edi-0x61] / cmp eax,0x19 / and edi,0xFFFFFFDF` - tests `a`-`z` and *clears* it.
2. **`blitz_string.c`.** `bbStringToLower` gates its ASCII path on `c<192` and `bbStringToUpper`
   on `c<181`; the two bodies compare against `0xBF` and `0xB4` respectively.
3. **NSS5.exe names them itself.** The `brl.retro` wrappers survive in the original at
   `0x0059C8E8` Trim / `0x0059C8FD` Lower / `0x0059C912` Upper - 21 bytes each, in the same
   `Mid/Instr/Left/Right/LSet/RSet/Replace/Trim/Lower/Upper/Hex` order and byte sizes as our
   own build of `retro.mod`, with `Replace` at `0x0059C8CB` and `Hex` at `0x0059C927` already
   named in `brl_functions.tsv`. Each is one call: Trim to `0x004A7740` (independently named
   `_bbStringTrim`), Lower to `0x004A74E0`, Upper to `0x004A7410`.
4. **Semantics.** With the old rows `RGBToHex` returned lowercase hex while every colour
   literal in the game is uppercase (`"FFFFFF"`, `"00FF00"`), `Sha256Hex` returned an
   uppercase digest, and `TCompetition.IsCupFinal` tested `Lower(c.tla) = "SUPER CUP"`, which
   can never be true. Section 15.5's rule again: a semantically dead predicate means the name
   is wrong, not that the game has dead code.

**The oracle cannot pick between the candidate namings, and that is the point.** Measured on
`TScreen.CreateScreen` (381 bytes, the differing byte is the operand of the `E8` at
`0x005104A2`), a 3x4 matrix of table row against source form:

| table | `Lower(s.name)` | `s.name.ToLower()` | `Upper(s.name)` | `s.name.ToUpper()` |
|---|---|---|---|---|
| `7410=retro_Lower, 74E0=retro_Upper` (as learned) | MISMATCH | MISMATCH | **MATCH 381/381** | MISMATCH |
| `7410=retro_Upper, 74E0=retro_Lower` (swapped) | **MATCH 381/381** | MISMATCH | MISMATCH | MISMATCH |
| `7410=bbToUpper, 74E0=bbToLower` (correct) | MISMATCH | **MATCH 381/381** | MISMATCH | MISMATCH |

Three different sources all certify at full length; only the binary decides which is right.

**Blast radius is computable exactly, and does not need a corpus sweep.** A row is consulted
only at an `E8` whose target is that VA, so scan the original for them. In NSS5.exe there are
142 calls to `0x004A7410` and 34 to `0x004A74E0`, of which 140 and 12 are in game code,
spread over **50 functions**. Four call sites reach the `Lower` wrapper at `0x0059C8FD`
(`ReadSettingFloat`, `ReadSettingString`) and five reach the `Trim` wrapper at `0x0059C8E8`
(`TProfile.LoadProfile`); the `Upper` wrapper at `0x0059C912` is called from nowhere. Those
nine sites are genuinely `Lower(...)` and `Trim(...)` in source and are masked through
`brl_functions.tsv`'s alias set, not through this table.

**Cross-check any `_brl_*` name that lands on a C-runtime address.** Every other row in the
C-runtime range `0x00401000..0x004BA000` is a `_bb*` symbol. A BlitzMax module symbol sitting
in that range is the shape of this defect.

**That cross-check is now a checker, not advice** (RULES.md's rule about rules).
`python scripts/helper_map.py` has two additional audits:
`audit_module_symbols_in_runtime_range()` fails any `.text` row carrying a `_brl_*`/`_pub_*`
symbol - wrong by construction, because bcc output lives in `code` at `0x004BA000+` - and
`audit_cross_table_symbols()` fails any symbol claimed by a runtime-helper row **and** by a
different address in `brl_functions.tsv`. Both fire on the old rows and are silent on the
corrected ones. Either would have caught this the day it was learned.

**Witness counts are not evidence.** Once a wrong pairing is learned, every later site that
repeats the same wrong source spelling is counted as corroboration, so 205 witnesses were 205
repetitions of one mistake. The audit's "single-witness entries" warning points at the
*weakest* rows; this row was the strongest-looking one in the table and the most wrong.

**Two earlier passes already had this and it still shipped.**
`docs/archive/waves/wave11-helper-naming.md` reached the correct pair from the same
instruction evidence and did not rewrite the table.
`docs/archive/waves/wave13-modulebody.md` rewrote the conclusion the wrong way round -
`0x004A7410 = _bbStringToLower` - by keeping the old rows' *semantics* while fixing their
*symbol*, and it is self-refuting: its own table row shows `ReadSettingFloat`'s `Lower(a1)`
reaching `0x0059C8FD`, and `0x0059C8FD` calls `0x004A74E0`, so `0x004A74E0` is the lowercaser
and `0x004A7410` is not. Read the wrapper's own `E8`, and do not trust an archived
conclusion over the binary.

# 19. Whole-program invariants the ORACLE CANNOT CHECK

The per-function oracle proves method bodies. It deliberately masks four things, and two of
them hide whole-program properties that must be checked separately. All three checks below
are cheap, run in minutes, and each has caught or could catch a class of defect nothing else
would see.

| check | script | what it proves | result |
|---|---|---|---|
| composition | `check_assembled.py` | bodies still byte-match once assembled together | 250/250 |
| field layout | `check_assembled.py --layout` | every field present, correctly typed, right super | **135/135** |
| method layout | `check_assembled.py --layout` | every method at the same class-table slot | **1,765/1,765** |

## 19.1 Why slot checking is not redundant

`harness.compare` **masks class-table slot calls** - it has to, because a probe Type carries
one method and the real Type carries forty, so the slots differ by construction. That means
a wrong slot is **invisible to per-function verification by design**. A Type can have a
perfect instance size and still place `Draw` at 0x40 where the original has 0x3C, if a method
is missing, extra, or declared in the wrong order - and then every
`call dword ptr [obj+0x3C]` through it dispatches to the wrong method while every individual
body still reports MATCH.

## 19.2 Why instance size is a good one-number test

A Type's instance size is the sum of its declared fields plus its super's. One integer per
Type therefore tests four things at once: no field missing, none invented, each correctly
typed (String 4, Double 8, array 4, …), and the inheritance chain right. It matters because
field offsets are baked into every body that touches the Type, and a body verified against a
*probe* carries the probe's layout - nothing else confirms the probe's layout matches the
assembled program's.

## 19.3 Run all three after any change to the Type set or declaration order

They are the regression suite for `assemble.py`. When the Type-set fix removed 206 Types
from the main module, these three checks are what established that it broke nothing.

# 20. Preserving a near miss

**The rule.** If a body gets close and cannot be closed, write the candidate to
`src/recovered_unverified/<Type>.<Method>.bmx` with a header that says plainly it is NOT
verified, plus:

* the exact numbers - ours N of M, delta, `delta_accounted` COMPLETE or not
* the gap list by ORIGINAL offset
* what has been ruled out

This does not inflate anything: `scripts/coverage.py` counts only bodies whose header claims
byte-equality, and it reports files in that directory separately.

# 21. The solo-relational If/Else branch-swap rule

Found on `TPlayer.UpdatePassPotential` (2277 bytes) and confirmed at 9 independent sites in
that one body, so treat it as established, not a hunch.

> **A single (non-compound) RELATIONAL comparison (`<`,`>`,`<=`,`>=`, and - surprisingly - 
> plain `=` at one site) that is the SOLE condition of an `If ... Then ... Else ...` whose
> two branches hold genuinely DIFFERENT code gets compiled by bcc as the LOGICAL NEGATION of
> the written comparison, with the Then/Else content SWAPPED.** To reproduce the original's
> `setae` (`>=`) test guarding branches `{T, F}`, the source must read
> `If x < y Then F Else T`, not `If x >= y Then T Else F`.

Does **not** apply to (all confirmed by counter-example in the same body):
- an `If` with **no** `Else` - every innermost rung of a threshold cascade is unnegated;
- a comparison used as **one term of a compound `And`/`Or`** - including ones built from the
  identical relational operator that negates when it is the sole condition;
- anything already covered by an existing rule (§10.1's operand-order note is orthogonal:
  that is about which operand Ghidra prints first, this is about which physical branch bcc
  emits first).

`Self.goalside = 0` - an **equality**, not an inequality - still needed the swap, because it
had two real branches. So this is a **shape** rule (solo relational condition, genuinely
different content on both sides), not an operator-class rule. Do not assume `=`/`<>` are
exempt; check whether the specific `If` has two distinct bodies.

**How to apply it:** when a solo relational `If/Else` mismatches only in its `setcc`
byte (`setae`↔`setb`, `seta`↔`setbe`) and the two branches are otherwise byte-correct, do
not hunt for a logic bug - negate the written comparison and swap which block is `Then` and
which is `Else`. Verify on ONE site with `bytematch.disasm_original` against the probe exe
before applying it at every other site; the swap does not require touching the branch
*content*, only the comparison operator and which literal block follows `Then` versus
`Else`.

A related, secondary effect: an `If cond Then A Else B` whose `A` is itself the last
statement of an enclosing `Then`-arm (e.g. training-mode vs match-logic split into two big
`Then`/`Else` halves) still needs its own **explicit trailing `Return 0`** if the arm should
not fall into whatever follows the enclosing `If` - omitting it merges the tail with a later
`Return` and costs bytes (5 in this body). This is unrelated to the swap rule; it is just an
easy thing to skip once a body has multiple return points.

# 21. Masked constants are UNVERIFIED - and wrong ones were found

`scripts/check_floats.py` compares the float constants the ORIGINAL loads against the ones
OUR build loads, pairing them **by instruction offset** (safe, because a body only reaches
this checker after the oracle reported MATCH, so the opcode/modrm bytes are identical at
every offset and only the masked disp32 can differ).

It found real defects on its first clean run:

* **`TPlayer.HeadBallAdvanced` read `12.34` at FOUR sites.** The header documented it as a
  deliberate placeholder, reasoning that the constants are `fld [rdata]` operands whose
  addresses are reloc-masked and whose "VALUES are not observable in the machine code". The
  first half is true; the conclusion does not follow. **The address is masked; the value sits
  at that address in the exe and reads out directly** - 15.0, 50.0, 0.07, 0.08. Corrected and
  re-verified MATCH. This is the same error as the "string literals are unrecoverable" claim
  in §13.2: masked ≠ unknowable.
* **`TPlayer.BlockSave` read `12.0` where the original loads `2.0`** (`fld [0x00C79F08]`).
  Corrected, re-verified MATCH.

Both bodies matched perfectly with the wrong number, because two non-trivial floats compile
to the same instruction with a different masked operand. **A MATCH says nothing about any
masked constant.** Read the value out of the exe; never leave a placeholder.

## 21.1 The zero-bucket is a DIFFERENT defect: uncaptured Global initialisers

The checker separates a second signature - ours reads exactly 0.0 where the original is
non-zero - because it has a different cause and a different fix. Those are module Globals
with a **non-zero compile-time initialiser** in the original (`g_pole_maxz:Float` = 100.0,
`g_ball_snowthreshold` = 0.5) that our `'!Global name:Float` pragma declares as plain, so the
assembled build defaults them to 0. The body is right; the Global's *initial value* was never
captured. Confirmed by hand on two cases: both are declared in the very file that reads them,
with no assignment anywhere in the corpus.

That is a source-reconstruction gap, not a classifier bug, and it needs a pragma that can
carry an initialiser. Do not "fix" it by editing the body.

## 21.2 Classifying a constant vs a Global

`fld dword ptr [abs]` is how bcc reads a Float **Global** as well as how it loads a constant,
and BlitzMax puts both in `data`, so an address alone cannot separate them. The working test
is **"referenced from code but never STORED to"**, taken literally: scan `.text`+`code` for
every `fst`/`fstp`, `mov [addr],reg` and `mov [addr],imm32` target, and exclude those plus
everything in `globals_final.tsv`. Over-collecting stores is the safe direction - a
wrongly-excluded constant is merely unchecked, whereas a wrongly-included Global was the
entire original bug.

## 21.3 The Global pragma carries an initialiser

`'!Global name:Type = value` - plain BlitzMax syntax on the SAME pragma line. No new pragma,
no new parser at the detection level: `GLOBAL_PRAGMA` in `harness.py` already captured the
whole `Global ...` remainder verbatim, so the only real work was giving `assemble.py` a way
to carry the initialiser through its OWN regenerated `Global name:Type` text, which otherwise
throws everything past the type away. Two additions, both a separate pass (the '!Field
shape, not bolted onto the type-conflict code):

  * `harness.parse_global_decl(text)` - `'Global g_x:Float = 100.0'` -> `('g_x','Float',
    '100.0')`. Shared by `harness.merge_globals` (now initialiser-aware: an initialiser-
    bearing declaration wins over a bare one of the same name regardless of which was seen
    first) and by `assemble.py`.
  * `assemble.global_initialisers(recovered)` - a second pass over the same `recovered`
    dict `gtypes` already walks, `{lower name: (init text, evidence file)}` plus conflicts.
    `gout`'s emission appends `" = %s" % ginits[k][0]` when present; nothing else about the
    Global-conflict machinery changed.

Applied to all 9 bodies in `check_floats.py`'s zero-bucket: `TPole.CheckHit`
(`g_pole_maxz` = 100.0), `TBall.CreateBall` (`g_ball_snowthreshold` = 0.5), `TEngine.Render`
(`g_engine_oldx/oldy/oldz` = 1.0 each), `TEngine.RenderScoreboard` (`g_sbfadein/g_sbfadeout`
= 0.025, `g_possbarh/g_possbara` = 100.0, `g_sbfontscale` = 0.8, `g_joyposthresh` = 0.5,
`g_joynegthresh` = -0.5 - the last surfaced only after the first six were fixed and the
function became comparable again), `TPlayer.GetShootOutPosition` (`g_shootout_xoff/yoff` =
180.0 - this also resolves the file's own "UNSURE, could not read the stored values"
comment: they read back non-zero, so they ARE Globals, not literals), `TBall.UpdateAnimation`
(`g_ball_minspeed` = 0.1), `TProgressBar.Update` (`g_pbf1` = 0.03, `g_pbf2` = 0.0025),
`TScreen_MainMenu.Update` (`g_mm_offx` = 10.0, `g_mm_offw` = 20.0), `TSlotStrip.Draw`
(`g_slot_viewx` = 215.0, `g_slot_viewy1/viewy2` = 20.0 each). 22 initialisers, 9 files.

Values were read directly out of `NSS5.exe`'s data section at the exact address each
zero-bucket offset's masked `fld dword ptr [addr]` operand resolves to (not guessed from
context) - `check_floats.refs_in()`'s offset is the disp32's own position, not the
instruction start, so read 4 bytes AT the offset, not 2 past it. Every one of the 9 bodies
still scores `MATCH` after the edit (initialisers are a data-section fact, invisible to a
function's own code bytes) and `check_floats.py --all`'s zero-bucket went from 9 to 0.

**Not done**: a literal address-by-address sweep of every non-zero float in `data` regardless
of whether any recovered body currently reads it. That set is not actionable - nothing to
verify an initialiser AGAINST until some body's pragma names the address - so the zero-bucket
(the full set of Globals BOTH already referenced by a MATCHed body AND misread as 0) is the
correct current frontier, and it is currently empty. It will grow again as new bodies get
recovered and reference more Globals; re-run `check_floats.py --all` after any sweep.

# 22. `block_count` is a reachable source-level lever

Section 18.4 diagnoses a case where a lower-reference-count Local outranks a
higher-reference-count one for a register because of `block_count` (basic blocks where the
value is live-in AND live-out) without identifying a source-level lever for it.
`TTable.Draw` (2792 bytes) closes one instance of that.

The body reaches **length-exact, 6/2792 bytes wrong**, all six the same cause: two hidden
`For...EachIn` enumerator temps (a single-level header loop's and a two-level-nested
row-inner loop's, both `For Local col:TColumn = EachIn Self.columns`) landing in swapped
stack slots. The reference-count tie-break (§18.2) does not explain it, and a structural
rewrite guessed blind is not an acceptable next step.

The fix: the row-inner loop's `col.w < 1` guard was shaped as `If cond Then <body
nested in Else>` (semantically fine, independently length-exact, `colidx :+ 1`
duplicated in both branches). Reshaping it to match the header loop's `If col.w < 1
Then colidx :+ 1 ; Continue` - an early back-edge jump instead of an `Else`-nested
body - changed the row-inner enumerator's live-range block structure and flipped its
spill slot to match the original, with **zero other bytes affected**. First try after
the reshape: **MATCH, mode=reloc, 2792/2792**.

**Consequence for the next stuck-on-a-tie-break body:** when a length-exact candidate
has a small number of same-length `sub`s that localise to a *compiler-generated* temp
(a hidden `EachIn` enumerator, not a named Local) rather than to visible logic, do not
conclude the residual is unreachable from source. Look for an `If/Else` vs
`If-then-Continue` (or similarly CFG-shape-changing but semantically-neutral) rewrite
of a guard *inside that temp's scope* before accepting the diagnosis as terminal - 
reference count and declaration order are not the only levers; the guard's own block
shape is one too, and it costs nothing to try since both shapes are typically
independently length-exact. This does not necessarily transfer to every §18.4 residual
unchanged - `TScreen_MatchPrep.CreateScreen`'s `wnum`/`h` case is reference-count-driven
(50 vs 28, not a tie), a different kind of imbalance - but it is a concrete,
verified technique to try, not just a theory.

# 22. The spill mechanism, read out of bcc's own source

Several bodies are now **length-exact and still MISMATCH**, differing only in which stack
slot a spilled value lands in - `TBall.CheckForPlayerRatings` (2867/2867, 6 bytes differing,
three interchangeable slots), `TFormation.GetPlayerXY` (2898/2898), `TPlayer.RecordPlayerStats`
(15154/15154). Textual guessing has been exhausted on all three. The answer is in the
compiler, which ships with this repo.

## 22.1 The spill victim formula - exact

`_src/codegen/cgallocregs.cpp`, `spill()`:

```c
float cost = (float)t->usage / ((float)t->degree * (float)t->block_count);
if( cost < min ){ node = t; min = cost; }
```

* **`usage`** - every def and use, weighted `10^loop_level`
* **`degree`** - interference-graph degree (how many live ranges it overlaps)
* **`block_count`** - 1 + the number of basic blocks where it is live-in *and* live-out

The victim is the node of **lowest** cost. The comparison is strict `<`, so on an exact tie
the node **earlier in the `_spill` list wins**. Section 18.2's "highest reference count keeps
a register" is the numerator only - it holds when degree and block_count are comparable, and
that is exactly why it explains `TScreen_MatchPrep.CreateScreen`'s map without fixing it
(h has 50 references but is live nearly everywhere, so its large `block_count` divides its
cost down below wnum's).

Note the two-pass guard: pass 0 skips `t->reg->id >= max_spill_id`, i.e. **registers created
by a previous spill are not re-spilled until pass 1**. Original values are always preferred
as victims.

## 22.2 Slot depth IS spill order

`_src/codegen/cgframe_x86.cpp`:

```c
CGMem *CGFrame_X86::allocLocal( int type ){
    int n = (type==CG_FLOAT64 || type==CG_INT64) ? 8 : 4;
    local_sz += n;
    return mem( type, ebp, -local_sz );
}
```

Slots are handed out **in the order values fail to colour**. So `[ebp-4]` went to the *first*
value spilled, `[ebp-8]` the second, and so on. A "wrong slot" is never a wrong declaration - 
**it is a different spill ORDER**, i.e. a different cost ranking.

`allocSpill()` first checks whether the value is `Self` (→ `[ebp+8]`) or a parameter (→ its
argument slot) before falling through to `allocLocal`, which is why parameters never consume
frame slots.

## 22.3 What this means for a length-exact mismatch

When two bodies are the same length and differ only in `[ebp-N]` displacements, **stop
permuting source text**. The lever is the cost ranking of the competing values, and only
three things move it:

1. **`usage`** - add or remove a reference. One extra flat use flips a rank (§18.2); a use
   inside a `For` does *not* act like ten (§18.2, measured).
2. **`degree`** - change what the value's live range overlaps.
3. **`block_count`** - change how many blocks it is live across, i.e. shorten or lengthen the
   distance between its definition and its last use.

(3) is the untried lever on every currently-blocked body, and it is a *statement-placement*
question, not a declaration-order one: moving an assignment closer to its use shrinks
`block_count`, raises the cost, and protects the value from being spilled early.

## 22.4 The frame size is a first-class clue

`TPlayer.RecordPlayerStats` reached exactly 15,154 bytes and still fails at **+3**: the
original's prologue is `sub esp,0x54`, ours `sub esp,0x4C` - the original's frame is **two
dwords larger**. That is a same-length instruction, so it is invisible to gap-based triage,
which is why it is so easy to miss. Two more values spill in the original than in ours.

**Read `sub esp,N` first, always** (§16.3), and treat a difference there as the primary
finding rather than a detail - it means the two builds disagree about how many values live
in memory, which by §22.2 also shifts every slot below it.

# 23. Expression shape - four rules that cost 150+ bytes to learn

All four came out of `Sha256Hex` (0x0058C960, 1,776 bytes), which went from a 23-gap first
draft to an exact MATCH once they were understood. They are not specific to that body;
every one is a general property of how bcc lowers an expression, and the first two in
particular will bite any body doing bit manipulation or string building.

## 23.1 `Mod` is ALWAYS `idiv`, even against a power of two

bcc does not strength-reduce. `x Mod 4` emits a full `idiv`; `x & 3` emits `and`. They are
arithmetically identical for non-negative `x`, so a candidate using `Mod` compiles, runs
correctly, and is simply **62 bytes longer** than the original across the message schedule.

**If a length gap is large and diffuse rather than localised, look for `Mod` before looking
at the register allocator.** This is a source-level fix; §18/§22 are not.

## 23.2 Decomposing an expression into named Locals changes the register allocation

The obvious readable spelling of a SHA-256 round - 

```blitzmax
Local s0:Long = Rotr(a,2) ~ Rotr(a,13) ~ Rotr(a,22)
Local maj:Long = (a & b) ~ (a & c) ~ (b & c)
Local t2:Long = s0 + maj
```

 - is **85 bytes** away from the original, which writes each round as one flat expression.
Naming the sub-results creates live ranges that overlap the array reads, which raises
pressure enough to reorder the reloads (§22.1: `degree` goes up, so the cost ranking moves).

This is the mirror image of §18's advice. Reordering *declarations* is only a tie-break, but
**introducing or removing a Local is not** - it changes the interference graph. When a body
is diffusely long and reads like tidy code, try collapsing it into the flat expression the
original probably wrote.

## 23.3 A flat `+` chain evaluates RIGHT to LEFT

`Upper(Hex(h0) + Hex(h1) + ... + Hex(h7))` does not evaluate `Hex(h0)` first. bcc evaluates
the operands of a flat `+` chain from the **rightmost inward**, then folds the concatenations
forward. So the disassembly shows the `Hex` calls in reverse order relative to the source.

This is directly useful and not just trivia: it lets you **read the intended source order off
the execution order** instead of guessing. It is what let `TProfile.CheckSkillHash`'s
`String(pace) + String(shooting) + …` digest expression be ordered correctly from the
disassembly alone, first try, rather than permuting seven operands.

## 23.4 Operand order survives into the bytes even when the operation commutes

The final two-byte residual on `Sha256Hex` was `a = t2 + t1` where the draft had
`t1 + t2`. Addition commutes; the emitted code does not. Same class as §10.1's comparison
operand order - when everything else matches and a small even residual remains, try swapping
the operands of a commutative binary operation before reaching for the allocator.

## 23.5 Two smaller ones from the same body

* **`Until N` vs `To N-1`** is byte-observable: `jl` versus `jle`. They are the same loop and
  they are not the same code.
* **A count that also exists as `array.Length` still needs its own Local** if the original
  declared one - `wordcount` and `w.Length` are interchangeable in meaning, but omitting the
  Local made the frame one dword short.

# 24. Conversions bcc does for you, and why writing them out is not equivalent

## 24.1 A String argument to a `Byte Ptr` parameter converts itself, and frees itself

`Val::funArgCast` (`_src/compiler/val.cpp`:352, the "convert string to cstring/wstring"
block at :381) fires whenever a `String` argument meets a `Byte Ptr` (or `Short Ptr`)
parameter. It emits `bbStringToCString`, stores the result into a compiler temp, and pushes
`bbMemFree(temp)` onto the **call's cleanup list**, which is emitted after the call returns:

```
push <the String>
call bbStringToCString
add  esp,4
mov  ebx,eax            <- the temp
push ebx
call <the Extern>
add  esp,4
push ebx
call bbMemFree          <- the cleanup, after the call
add  esp,4
```

So `FindLeaderboard("Player Value")` on its own produces all ten of those instructions.
**If you see that shape, do not reconstruct it as a Local plus an explicit `MemFree`.**

## 24.2 The hand-written spelling is NOT byte-equivalent - it moves a live range

This is the part that costs time if you get it wrong, because both spellings compile and
both look right. Writing it out by hand:

```blitzmax
Local q:Byte Ptr = obj.name.ToCString()
Extern_Fn(2, obj.GetValue(), q)
MemFree q
```

puts the conversion in its own **earlier statement**. Letting `funArgCast` do it folds the
conversion into the call statement, and the statements hoisted out of the arguments then come
out **left to right**: the receiver materialisation for `obj.GetValue()` first, then the
`bbStringToCString` call for the later argument. That single reordering changes which values
are live across which calls, and therefore the register assignment and the frame:

| spelling | receiver temp | its load | frame |
|---|---|---|---|
| hand-written Local + `MemFree` | short-lived, **eax** | `mov eax,esi` survives as a real copy | no spill |
| `funArgCast` does it | live across the conversion call, so **callee-saved esi** | folds into `mov esi,[global]` | a fourth value competes, one spills, `sub esp,4` appears |

Measured on `SteamPostPlayerValue` (0x0058D987): the hand-written form was 327 bytes, the
compiler-converted form is 325, byte-identical. The two bytes were the `89 F0 mov eax,esi`,
and fifteen different spellings of the *receiver* had already been measured trying to remove
it - the receiver was never the cause.

## 24.3 The receiver copy itself is unconditional - stop trying to spell it away

`type.cpp` `ClassType::resolve` builds a non-final virtual method's template as
`vfn( mem(CG_PTR, tmp("@type"), slot), tmp("@self") )`. `Val::find` (`val.cpp`:513) counts
`n_self=1` and `n_type=1` for **every** ordinary virtual call, so `n_self+n_type>1` always
holds and it always emits `mov cg,cg_exp` to materialise the receiver into a fresh temp.
No source spelling of the receiver avoids that branch. Whether the `mov` survives into the
bytes is decided by whether the allocator can fold the temp into the register the receiver
already occupies, and that is decided by the temp's **live range** - which, per 24.2, is a
property of statement structure. Look at the statements around the call, not at the receiver.

## 24.4 `_same_callee` cannot prove a callee that calls C-runtime helpers

Related, and worth knowing before you try to close a caller by compiling its callee into the
probe. `harness.compare`'s masking has three routes for an `E8`: (a) by name, (b) by bytes
via `_same_callee`, (c) learn. Route (b) recurses with **no** `ournames`/`origtab`/`ourfns`,
so inside the callee any call to a C-runtime helper (`bbStringToCString`, `bbMemFree`, ...)
cannot mask, the callee compares `diff`, and the fallback correctly refuses.

Consequence: **route (b) only works for a callee that is pure game code.** For anything else
the ORIGINAL side must be named, and `helper_map.orig_functions()` builds that table by
scanning `src/recovered_module/` and nothing else. Measured on `TProfile.SaveGame`:
compiling the real 325-byte callee into the probe gave 850/850 `mode=diff` with one differing
operand; moving the callee's file into `src/recovered_module/` gave 850/850 `mode=reloc`,
MATCH. That is not 13.3 stubbing - 13.3 forbids a *placeholder file for an unrecovered VA*,
and the name here is earned by a body that is itself byte-identical.
