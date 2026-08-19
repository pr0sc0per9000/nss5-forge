# 21 - Module Globals: enumeration, typing, naming

Generator: `<repo>/scripts/name_globals.py`
Outputs: `extracted/globals_named.tsv`, `src/generated/globals.bmx`, `extracted/_globals_raw.json` (per-global raw evidence)

Original names are gone (no `BBDEBUGDECL_GLOBAL` records were emitted). We assign our own.
Names never reach compiled output, so this costs nothing in byte-match terms.

## 1. Enumeration - the true count

Disassembled all 3,537 `code`-section functions with capstone and collected every memory
operand with **base=0, index=0, absolute displacement inside `.data` / `data` / `.bss`**.
That is the exact shape bcc emits for a Global access (`mov eax,[0x00c5b1c4]`), and it
excludes string/class-table pushes, which are `push imm32`.

| stage | count |
|---|---|
| distinct absolute data addresses touched by game code | **4,587** |
| minus x87 literal-pool entries (see below) | -1,693 |
| **real module-level Globals** | **2,894** |

Address span `0x005c7bd4 .. 0x00cff590`. Distribution: 4,581 in `data`, 3 in `.data`, 3 in `.bss`.

**Literal-pool filter.** bcc materialises float/double constants as data words and loads
them with `fld dword [addr]`. Those are *not* Globals. Rule applied: **never written by any
game function** AND **x87-accessed** AND **non-zero init value that decodes as a finite
float**. 1,693 addresses matched; the top values are exactly what you'd expect for a game
(`0x3f000000`=0.5 x186, `0x3f800000`=1.0 x142, `0x40000000`=2.0 x142, `0x41200000`=10.0 x130).
A `Global f:Float` survives the filter because it is written somewhere.

## 2. Typing

### 2.1 The decisive signal: BlitzMax initialiser sentinels

bcc pre-initialises every Global's data slot at link time, and the sentinel identifies the
storage class exactly:

| init value | meaning | count |
|---|---|---|
| `0x005c9c80` | `&bbNullObject` (clas=0, refs=0x40000000 immortal) | **954** |
| `0x005c7c00` | `&bbEmptyArray` | **137** |
| `0x00000000` / scalar | plain scalar slot | 1,803 |

This is not inference - it is what the linker wrote. **954 Globals are object references and
137 are arrays, with certainty.** 953 of the 954 are also written by game code, and 916 are
passed to a call, confirming they are live object variables and not padding.

### 2.2 Concrete Type inference (this is where we are weak - read the honest numbers)

Evidence sources, in strength order:

1. **`stored_from`** - `call F` then `mov [G],eax` where F is a `New`/`Create`. Weight 3.
2. **self-receiver** - last `push` before `call M` where M is a **Method** (cdecl pushes args
   right-to-left, so the last push is `self`). Weight 4.
3. **arg0** - same position but the target is a static **Function**; type comes from arg 0 of
   the reflected signature. Weight 3.
4. **vtable-slot closure** - `mov eax,[G]` then `call [eax+S]`. Candidate = every Type whose
   slot set (own slots **unioned up the `Extends` chain** - a strict per-slot intersection is
   always empty because `vtable_map.tsv` lists a slot only under the Type that *declares* it)
   contains every observed S. Weight 6 if it resolves to a single Type, 1 each if 2-6.

Result:

| inferred type | n | note |
|---|---|---|
| Int | 1,534 | dword, non-FPU |
| **Object** | **924** | confirmed object, concrete Type NOT determined |
| Float | 192 | x87 dword, written |
| Object[] | 137 | `&bbEmptyArray` init; element type not recovered |
| Double | 77 | x87 qword |
| TPlayer | 29 | vtable-slot closure resolved to one Type |
| TCompetition | 1 | |

Confidence: **269 high, 709 medium, 1,916 low.**

**Honest assessment: concrete Type recovery failed.** Only 30 of 954 object Globals got a
named Type. Cause is structural, not a bug: BlitzMax dispatches through the vtable, so almost
every use site is `call [eax+S]` with 1-3 distinct S values, and with 133 Types sharing the
inherited `Object` slots a 1-3 slot signature is ambiguous across dozens of Types. 924 objects
have no direct-call site at all. Earlier drafts of this pass reported 230 `TScreen_Options`
and 140 `TFormation`; both were artefacts - the first from treating a static Function's arg 0
as `self`, the second from an intersection fallback that kept a stale candidate set when the
intersection went empty. Both are fixed; the resulting numbers are smaller and true. **Do not
resurrect the larger numbers.**

`globals_named.tsv` records the candidate set per global (`vtable-call slots 0x34,0x48 -> one
of {...}`) so a later pass can disambiguate without redoing the disassembly.

Confidence guard now in force: vtable-slot evidence alone can never yield better than `low`,
and a global whose only evidence is a wide candidate set is emitted as `Object`, not guessed.

## 3. Naming scheme

Names are ours; the scheme optimises for stability and for grep-ability against the evidence file.

| class | pattern | example |
|---|---|---|
| typed object singleton | `g_<Type minus leading T>` | `g_Player`, `g_Competition` |
| multiple of one Type | same + 2-digit ordinal | `g_Player01 .. g_Player29` |
| untyped object | `g_<subsystem>_object<nn>` | `g_ball_object03` |
| array | `g_<subsystem>_arr<nn>` | `g_engine_arr07` |
| scalar | `g_<subsystem>[_<labelhint>]_<type><nn>` | `g_ball_float01`, `g_engine_int42` |

`<subsystem>` is the Type that owns the majority of the referencing functions (from
`vtable_map.tsv` + `function_inventory.tsv` custom names) - e.g. a global touched only from
`TBall.*` methods becomes `g_ball_*`. 422 globals have no majority owner and fall back to
`g_misc_*`. `<labelhint>` folds in a debug string seen in the same function when it looks like
a label (the "No Foul: Got ball" / "Yellow card: From behind" family); this fires rarely and is
cosmetic only. The trailing ordinal is dropped when a base name turns out unique.

## 4. Payoff - what this unblocks

Measured over the 2,749 functions in `extracted/decomp/_index.tsv`:

| bucket | n | status |
|---|---|---|
| touch no absolute data operand at all | 1,484 | already addressable |
| touch only literal-pool floats | 46 | already addressable (constants, not globals) |
| touch globals that are **all scalars** | 427 | **newly addressable** - declare and go |
| touch >=1 global, all at >=medium confidence | 192 | newly addressable |
| touch >=1 object global still typed `Object` | ~792 | **still blocked on Type recovery** |

Total addressable after this pass: **~1,957 of 2,749 (71%)**, up from 1,530 (56%).
1,219 functions reference at least one real global (median 3 per function); before this pass
every one of them showed bare `DAT_`/`PTR_` and could not be written as BlitzMax at all. All
1,219 now have a declared name and slot.

Across the whole decompiled corpus, 1,219 functions are blocked on unresolved globals.

## 5. `src/generated/globals.bmx`

2,894 `Global` declarations grouped by subsystem, each carrying its address, refcount,
confidence and evidence as a trailing comment. Declaration **order does not matter**: bcc gives
each Global its own data slot and referencing code is address-independent, so nothing here can
perturb a byte-match. The file imports `BRL.LinkedList` and `BRL.Map` because the real `TList`
/ `TMap` must be used (BRL 1.50 slots match the original - `Count` at `[eax+0x70]`).

## 6. Caveats - do not treat this file as settled

- **UNCERTAIN:** the 1,534 `Int` globals are typed by access width alone. Any of them could be
  a `Byte`/`Short` widened by the compiler, or a Pointer. Only the 269 `high` rows (x87 access
  or sentinel init) are safe to rely on.
- **UNCERTAIN:** BlitzMax emits Type-scoped `Global` and Function-scoped `Global` into the same
  flat data slots as module Globals. Some fraction of the 2,894 belong inside a `Type ... End
  Type` rather than at module scope. That distinction does not change codegen for the *access*,
  but it does change where the declaration must live for the source to compile.
- The literal-pool filter is heuristic. A `Global` that is genuinely read-only from game code
  and initialised to a non-zero float will have been discarded as a constant. Estimated
  exposure is small but non-zero; re-check any function that reads a float constant it also
  seems to expect to change.
- Element types for the 137 arrays are not recovered; all are declared `Object[]` as a
  placeholder and **will need fixing before any function using them can byte-match**.

## 7. Next action (highest value)

Type the 924 `Object` globals. The cheapest path is not more static analysis - it is the
`stored_from` edge: find the *writer* of each slot and read what the writer's callee returns.
Only 46 of 954 currently have a `stored_from` edge because writes are frequently
`mov [G],eax` several instructions after the call, past my 1-instruction window, or via a
register saved across a block. Widening that window with a small dataflow pass over the
writing function should convert several hundred `Object` rows into concrete Types.

## 8. One slot, several names - the defect class that costs playability

Section 3 says naming "costs nothing in byte-match terms". That is true and it is also the
trap. Because the name is free, two passes can name one address differently and **both
bodies still byte-match**. `assemble.py` then emits one `Global` per distinct name, so the
writer updates one variable and the reader sees another that nothing ever assigns.

This is the single largest source of *runtime* defects in the reconstruction. It does not
show up as a lower percentage; it shows up as the game not working.

### 8.1 Why nothing catches it automatically

- **The byte oracle cannot.** `harness.compare` masks relocations, and a Global reference
  *is* a relocation. `mov eax,[A]` and `mov eax,[B]` compare equal. A body can be 100%
  byte-identical and still read the wrong slot. `TEngine.SkipTime` was byte-identical while
  reading two wrong Globals.
- **`find_dead_globals.py` cannot, on its own.** It asks "read but never written". That
  finds the easy half. It is blind whenever *both* survivors have a writer - which is the
  common case, because the second name usually belongs to a real writer somewhere else.
- **Name-based tools cannot see the mirror image.** One *name* can mean two *addresses*.
  `g_options_int06` meant `0x00C5B1CC` in one body and `0x00C5D24C` in another; merging on
  the name corrupted both.

### 8.2 The three shapes

| shape | what it looks like | how to find it |
|---|---|---|
| One address, several names | `assemble.py` emits 2+ `Global`s for one slot | group every recorded name by address, resolve each through `global_alias_map()`, flag any address with **2+ distinct surviving names** - do *not* filter to "one is unwritten" |
| One name, several addresses | one identifier, different slot per body | disassemble the body and read the absolute displacement at each site; compare against the file's own header |
| Array allocated, elements never filled | `Global g:TLabel[10]` looks written - the ten elements are Null | test element writes (`g[i] = ...`) separately from the array itself |

The array shape is easy to miss because a sized declaration allocates a real array, so every
"is this Global assigned" check passes. `g_ctl_lbl` had 114 element dereferences and no
element writer at all.

### 8.3 What a body's own header is worth

Repeatedly, the recovered body **already recorded the right address** and the alias tables
overrode it. `TEngine.SkipTime.bmx:9` reads `0x00C6CF90 -> g_trainingon  0x00C6CF98 ->
g_trainingmode`, which is exactly what the original does - and the tables bound both names
to `0x00C6CF90` because *other* files use the name `g_trainingmode` for that slot.

**When a header and the alias tables disagree, disassemble before believing either.**
`scripts/disasm.py <VA> <len>` and read the displacement. That is ground truth and it takes
one command.

### 8.4 Slots corrected

Each row was confirmed against the binary or against a byte-identical writer's own header.
Every merge below is name-only: no machine code changed, and the 94.6% figure is unmoved.

| address | names collapsed onto | symptom while split |
|---|---|---|
| `0x00C6F028` | `g_profile` (8 names) | the player profile was Null for 168 dereferences; new career crashed before the first training |
| `0x00C5DEA4` | `g_ball` (6 names) | the match ball was Null for 29 files; only assignment reachable was `= Null` |
| `0x00C5B1C4` | `g_font_match_m` (4 names) | training scroll text measured against a Null font |
| `0x00C6F08C` | `g_musicchannel` | boot allocated the music channel under another name, so with `music=0` in Options.ini `ResumeChannel(Null)` threw |
| `0x00C6F090` | `g_object859` | shared SFX channel Null in training and blackjack |
| `0x00C6F34C` / `0x00C6F3B0` | `g_object872` / `g_object873` | message-panel images Null unless the Kits screen had been opened; killed the first frame of any training |
| `0x00C5B32C` | `g_engine_labels` | scoreboard team-name labels Null in `SetUpMatch` |
| `0x00C6DD50` / `54` / `60` / `6C` | `g_panel_controls_pan` / `panreplay` / `lbl` / `kick` | the in-match controls panel; one *name* covered two panels, and `RenderKickToContinue` read the wrong array |
| `0x00C67DA4` / `0x00C67DAC` | `g_mc_cmb_nation` / `g_mc_cmb_club` | My Contract nation/club combos |
| `0x00C65C70` | `g_editkits_team` | Edit Kits quit handler |
| `0x00C5B1CC` vs `0x00C5D24C` | split per body in `TEngine.SetUpMatch` | one name for the engine state *and* the player-cam option; the engine state was never set, so `MatchLoop` exited on its first pass and every trial auto-failed |
| `0x00C6CF90` vs `0x00C6CF98` | split per body in `TEngine.SkipTime` | training-active flag vs challenge state; `StartChallenge` was unreachable, so KICK did nothing |
| `0x00C6E9A8` | `g_userpath` in `TOptions.SetUp` | `SetUp` tested the install dir while `WriteNewOptionsIni`/`LoadOptions` used the save dir, so no options file was ever written and every setting - key bindings included - loaded as 0 |

### 8.5 Still outstanding

The sweep in 8.2 reports **62 addresses** still carrying 2+ surviving names. They are not all
real: `0x00000000` collects seven names, and `g_camerax1`/`g_cameray1` appear at *both*
`0x00C5DCB0` and `0x00C5DCB4`, which is an unresolved pairing rather than an identity. Each
needs adjudicating against the disassembly before it is merged - **a wrong merge fuses two
live variables, which is worse than the split it replaces.**

The ones that look real and matter most are the engine's own audio channels
(`0x00C5B33C/40/44/48`, e.g. `g_chan_a`/`g_chn2`), which sit in `TEngine.UpdateSounds`'
non-training branch and would affect a real match the way the training faults above did.

Hand-verified merges live in `extracted/global_alias_overrides.tsv`, each row cited. **That
file is inside the gitignored `extracted/` tree**, so it does not survive a fresh clone; the
merges above are therefore also applied at source, by renaming in `src/`, which is what
actually makes them durable. Prefer the source rename. Use the override row for the evidence
trail and to stop a regenerated `globals_final.tsv` re-splitting the slot.
