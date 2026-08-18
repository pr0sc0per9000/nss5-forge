# 11 - Reconstruction Dependency Graph

**Purpose.** Turn "1,758 method slots and 92 nameless functions" into a *strictly ordered* work
programme: which function depends on which, what can be written today with no prerequisites, what the
smallest playable slice is, and how to cut the whole thing into pass-sized units that only ever depend
on already-finished units.

Everything below is derived from `binary/NSS5.exe` by two committed tools, not estimated:

| Tool | What it does |
|---|---|
| `scripts/ghidra_scripts/NSS5CallGraph.java` | whole-program call-graph pass. Read-only, `-noanalysis`. Emits raw observation: direct edges, indirect call sites with the vtable slot, a backward def-use chain for every receiver, the cdecl stack cleanup (= call arity), every store to an absolute address, and every immediate argument of every direct call. |
| `scripts/build_dependency_graph.py` | resolves the indirect calls against the object model, builds the graph, condenses SCCs, layers it, computes leaves / vertical slice / work units. |
| `scripts/extract_globals.py` | tries to recover module-level `Global` names+types from the debug metadata. **Negative result - see §2.4.** |

```sh
tools/ghidra_12.1.2_PUBLIC/support/analyzeHeadless.bat ghidra-project NSS5 \
  -process NSS5.exe -noanalysis -readOnly \
  -scriptPath scripts/ghidra_scripts -postScript NSS5CallGraph.java extracted/callgraph
python scripts/build_dependency_graph.py
```

Generated data (all under `extracted/`, all TSV, UTF-8, no BOM):

| File | Rows | Contents |
|---|---:|---|
| `callgraph/callgraph_functions.tsv` | 5,171 | every function: section, size, instruction count, call counts |
| `callgraph/callgraph_direct.tsv` | 24,815 | `call rel32` and tail-jump edges |
| `callgraph/callgraph_indirect.tsv` | 13,731 | every indirect call site: slot, arity, receiver def-use chain |
| `callgraph/callgraph_globalstores.tsv` | 2,869 | every `mov [abs], reg` with the traced source |
| `callgraph/callgraph_callargs.tsv` | 10,358 | immediate arguments of direct calls (this is what types `New`/casts) |
| `callgraph_resolved.tsv` | 36,451 | **every call edge**, with resolution kind, callee, evidence, confidence |
| `callgraph_unresolved.tsv` | 2,095 | every site we could *not* resolve, with the reason |
| `globals_typed.tsv` | 662 | module-level global VA → inferred type + evidence |
| `dep_layers.tsv` | 1,850 | per function: SCC, layer (two graphs), fan-in/out, unresolved count, unit |
| `type_deps.tsv` / `type_layers.tsv` | 73 / 132 | Type→Type dependency edges and Type layering |
| `leaves.tsv` | 649 | functions with no in-scope callee |
| `vertical_slice.tsv` | 900 | functions reachable from the boot/menu/data/match roots |
| `work_units.tsv` / `work_unit_members.tsv` | 159 / 1,850 | the proposed work breakdown |

---

## 1. Scope: what is actually ours to reconstruct

Re-derived from `class_tables.tsv` + `vtable_map.tsv` while writing this document.

| Quantity | Value |
|---|---:|
| Class tables recovered in total | **348** |
| - with class-table VA `< 0x00C94988` (NSS5's own types) | **135** |
| - of those, compiler/BLIde-generated `z_*` | 3 |
| **Real game Types** | **132** |
| Slot rows belonging to game Types | 1,765 |
| - resolved to a body (`status=OK`) | **1,758** |
| - `Abstract` (point at the thrower `0x005B95AC`) | 7 |
| Ghidra functions in `code` below `0x0058DBF3` | **1,850** |
| - that are a known slot body | 1,758 |
| - unattributed (module-level `Function`s, module init, helpers) | **92** |
| Total bytes of game code | **867,315** |

> **Use these counts, not the older 337 types / 131 game types / 1,618 resolved game slots.** The
> current `extracted/object_model.json` says **348 / 132 / 1,758**. The difference is real and in our
> favour: `parse_reflection.py` was fixed (its own header comment records it) so that a `Const`
> declaration no longer truncates a scope, which recovered `TPlayer` - 100 fields and 135 methods -
> plus ten other types. **The progress denominator is 1,758, not 1,618.**

### 1.1 The game/module boundary is exact

Game-Type slot bodies occupy `0x004BBF31 - 0x0058D5DA`; module-Type (`TList`, `TStream`, `ZipFile`,
D3D drivers, …) slot bodies occupy `0x0058DBF3 - 0x005B9550`. **Zero overlap.** So

```
in_scope(addr)  ==  0x004BA000 <= addr < 0x0058DBF3
```

is an exact filter, and the 92 unattributed functions inside it are genuinely NSS5's own module-level
code, not BRL/PUB internals. Everything at `0x0058DBF3` and above, plus all of `.text`, plus the 2
`.idata` imports, is **runtime** - supplied by BlitzMax NG and never reconstructed.

---

## 2. Extracting the call graph

### 2.1 Four kinds of call, not one

Legacy BlitzMax + GCC emits four distinguishable call forms. Getting this taxonomy right is most of
the work; a whole class of edge was initially mis-binned as "imports" and it flattened the graph.

| Form | x86 | Count | How resolved |
|---|---|---:|---|
| **direct** | `call rel32` | 24,815 | trivially |
| **static Type-Function** | `call dword ptr [0x00cXXXXX]` | **4,234** | GCC folds *(class table + slot)* into an absolute operand. Read the dword at that address → callee. See §2.2. |
| **virtual dispatch** | `mov R,[Self]` ; `call dword ptr [R + slot]` | **8,963** | requires the receiver's static type. See §2.3. |
| **import** | `call dword ptr [.idata]` | 2 | IAT |

### 2.2 The 4,234 "absolute" calls are static calls, not imports

`TEngine.MatchLoop` contains `call dword ptr [0x00C5BA84]`. `0x00C5BA84` is not in `.idata` - it is
`TEngine`'s class table (`0x00C5BA30`) `+ 0x54`, and slot `0x54` of `TEngine` is `Update`. Reading the
dword gives `0x004CFA6C`, which `vtable_map.tsv` confirms is `TEngine.Update`.

Because `TEngine`, `TScreen`, `TProfile` etc. are effectively static/singleton classes whose members are
declared `Function` rather than `Method`, the compiler knows the class table at compile time and folds
the address. **4,230 of the 4,234 targets land in `code`; 4,176 land exactly on a known slot body.**
These are ordinary, fully-certain edges. Treating them as imports (as a naive `[abs] → IAT` rule does)
deletes 17% of the entire call graph and makes the game look like a collection of disconnected leaves.

### 2.3 Resolving virtual dispatch

The receiver type is not in the instruction. `NSS5CallGraph.java` records, per site, a backward
def-use walk to the value's origin - e.g. for `TFormation.GetRowFromSelectionNo` at `0x004D8AF3`:

```
0x004D8B1F  call dword ptr [EAX + 0x4c]
   chain:  EAX=[EAX+0x0] ; EAX=[EBP+0x8]        term: PARAM+0x8   slot: 0x4c   cleanup: 8
```

`[EBP+8]` on a `Method` is `Self`, so the receiver is `TFormation` and slot `0x4C` is `GetRow`. The
Python side then applies four *sound* constraints to type every receiver value:

| # | Constraint | Why it is sound |
|---|---|---|
| 1 | **Signature seeding.** `PARAM+0xN` maps through the caller's own recovered signature (cdecl, `Self` at `+8`, `Long`/`Double` take 8 bytes). Direct-call return values take the callee's declared return type. | the signatures are the original's own metadata |
| 2 | **Runtime-helper class tables.** `bbObjectNew(BBClass*)`, `bbObjectDowncast(obj, BBClass*)` and `bbArrayNew(const char *type_tag, …)` all take their type as a literal argument, recovered by walking the `PUSH` sequence backwards. | the argument *is* the type |
| 3 | **Structural compatibility.** A candidate type must own a field at every byte offset the site dereferences, whose declared type carries the next deref, and must have the invoked slot in its merged slot table. | the true type satisfies every observed use, so it is never excluded |
| 4 | **Call arity.** The cdecl cleanup `add esp,N` after the call gives `N/4 = (Self? + argument dwords)`. A candidate whose slot signature has a different arity is impossible. | verified against 2,235 independently-resolved sites: **2,229 match to the byte** (the 6 exceptions are Type `Function`s cleaning 4 bytes more than their signature accounts for, which the check tolerates) |

Constraints 3 and 4 leave a **candidate set**, not necessarily a single type. That is deliberate: a set
still yields a *sound over-approximation* of the callee set, which is exactly what a work-ordering graph
needs - over-approximating can only make a function look less leaf-like than it is, never more.
A monotone fixpoint then propagates: each resolved site tells us the return type at that site, which
shrinks the candidate set of whatever consumed it.

Adding the arity constraint alone took game-code virtual resolution from 57.7% to 82.8%; deepening the
def-use walk from 200 to 1,500 instructions took it to 88.9%.

### 2.4 Module-level `Global`s - a well-evidenced negative result

4,512 of the 8,963 virtual sites dispatch through a module-level global (`TEngine`/`TScreen`/`TProfile`
keep all their state there). `scripts/extract_globals.py` therefore went looking for the metadata that
would name them. Per `tools/blitzmax-legacy-src/mod/brl.mod/blitz.mod/blitz_debug.h`:

```c
enum{ BBDEBUGDECL_END=0, CONST=1, LOCAL=2, FIELD=3, GLOBAL=4, VARPARAM=5,
      TYPEMETHOD=6, TYPEFUNCTION=7 };
struct BBDebugDecl{ int kind; const char *name,*type_tag;
                    union{ ...; int field_offset; void *global_address; }; };
enum{ BBDEBUGSCOPE_FUNCTION=1, BBDEBUGSCOPE_USERTYPE=2, BBDEBUGSCOPE_LOCALBLOCK=3 };
```

A `kind==4` record would hand us a Global's original name, its BlitzMax type *and* its address.

**Result: NSS5.exe contains zero `BBDEBUGDECL_GLOBAL` records and zero `BBDEBUGSCOPE_FUNCTION`
scopes.** A loose scan of the whole `data`/`.data`/`.rdata` for any 16-byte record shaped like a
`BBDebugDecl` finds 348 `USERTYPE` scopes and exactly 53 `Const` records (the BLIde
`Name`/`MajorVersion`/`VersionString` assembly-info block) and nothing else. The binary was built in
release mode, where bcc emits type scopes (the class table points at them) but no function scopes.

**Consequence: module-level Global names and declared types are NOT recoverable from the binary.** They
must be inferred from behaviour, or invented and flagged. Do not spend more time looking.

What *is* recoverable is a Global's runtime type, from what gets stored into it. The strongest chain:

```
0x004BB9E2  push 0x00C6A4C0          ; TProfile's class table
0x004BB9E7  call 0x004A8F20          ; bbObjectNew
0x004BB9EF  inc  dword ptr [eax+4]   ; retain
0x004BB9F2  mov  dword ptr [0x00C6F028], eax
```

→ the global at `0x00C6F028` is a `TProfile`, and **605 call sites dispatch through it**. It is the
game-state singleton. 261 of 601 observed global receivers are typed this way or by structural
narrowing; 174 of them to a game Type.

<<<globals_top>>>

### 2.5 Runtime helpers identified (corrections for the methodology guide's §4.3 table)

| Address | Actual identity | Evidence |
|---|---|---|
| `0x004A8F20` | **`bbObjectNew(BBClass*)`** - allocates `[cls+0x0C]` bytes then calls slot `0x10` (`New`) | disassembly: `cmp [ebx+0x14],0x4a8e60` (Delete slot vs runtime default), `mov eax,[ebx+0xc]` (instance size) → allocator → `call dword ptr [ebx+0x10]`. 333 call sites, **all 333** pass a valid class-table immediate. |
| `0x004A8F60` | **`bbObjectDowncast(obj, BBClass*)`** - walks the super chain, returns the object or the null singleton `0x005C9C80` | disassembly is the chain walk; 893 sites, 873 pass a class table as arg 1; callers immediately `cmp eax, 0x5c9c80` |
| `0x004A63D0` | **`bbArrayNew(const char *type_tag, …)`** | arg 0 points at the ASCII tags `"$"`, `"i"`, `":TFoo"` |

> The methodology guide currently labels `0x004A8F20` "build exception / string for throw
> (confidence: High)". **That is wrong.** It is the object allocator. This matters: 258 call sites were
> being read as error paths.

### 2.6 Resolution results - and the honest unresolved number

| | sites | share |
|---|---:|---:|
| Virtual dispatch sites (whole program) | 8,963 | 100% |
| - exactly resolved (receiver type known, one target) | 5,603 | 62.5% |
| - narrowed to one target by candidate set | 407 | 4.5% |
| - 2…12 candidate targets (sound over-approximation) | 1,390 | 15.5% |
| - **any target at all** | **7,400** | **82.6%** |
| - **UNRESOLVED** | **1,563** | **17.4%** |
| Virtual sites in *game* code | 7,563 | 100% |
| - resolved to at least one target | **6,720** | **88.9%** |

Where the remaining game-code failures are (852 sites):

| Reason | Sites | What it means |
|---|---:|---|
| candidate explosion (>12 possible targets) | 758 | receiver is an untyped global (645) or an untyped call result (131); the constraints leave too many types to be useful |
| no candidate type at all | 45 | our model is wrong somewhere for these - most likely a Type `Global` holding a module type, or a receiver reached through a pointer we mis-modelled. **Worth a look; treat these functions' callee lists as incomplete.** |
| def-use walk gave up / crossed a call | 40 | register pressure defeats the linear backward walk |
| not a virtual dispatch (no class-table load) | 9 | genuine function-pointer call |

**The number that actually matters for work planning: only 172 of the 1,850 game functions (9.3%) have
even one unresolved call site.** For the other 1,678 the callee set is complete. Every table below
marks the 172, and no function with an unresolved site is ever certified as a leaf.

---

## 3. Type-level dependency graph

This needs no disassembly: a Type `T` depends on `U` if `U` appears in `T`'s field types, in any of
`T`'s method/function signatures, or is `T`'s super. 132 game Types - and only **73 edges**
(`extracted/type_deps.tsv`).

**That sparsity is a finding, not a bug.** NSS5 leans hard on a static-namespace idiom:
**67 of the 132 game Types have `instance_size == 8`** - object header only, i.e. *no fields at all*.
`TEngine` is one of them: 56 slots, 54 of which are declared `Function` (only `New`/`Delete` are
`Method`s). So are `TScreen_MainMenu` and most of the 53 `TScreen_*` types; their signatures are almost
entirely `()i`. All their state lives in module-level Globals, and their real coupling is therefore
invisible at the signature level - `TScreen_MainMenu` does *not* extend `TScreen` (`super = Object`),
yet `TScreen_MainMenu.CreateScreen` certainly calls `TScreen.CreateScreen`.

So the Type graph is **necessary but nowhere near sufficient** for ordering: use it to order the *type
declarations*, and use the call graph in §4 to order the *bodies*.

<<<type_layers>>>

Only **two** cycles exist at Type level, and both are trivially explainable:

| Cycle | Why it exists | How to break it |
|---|---|---|
| `TBall` ↔ `TPlayer` ↔ `TTeam` ↔ `TReplay` | the match-engine object graph is genuinely mutual - a `TPlayer` holds a `TBall`, a `TBall` records who last touched it, a `TTeam` holds `TPlayer[]`, a `TReplay` snapshots all three | **do not break it.** Declare all four Types (fields + method signatures) in one `.bmx` file, then fill bodies independently. BlitzMax resolves forward references within a file, so declaration order inside the file is irrelevant. |
| `TGadget` ↔ `TLabel` | `TGadget` (base widget) has a `TLabel` for its caption; `TLabel` extends `TGadget` | same file. This is a base-class/derived-class cycle and is normal. |

The type graph is 5 layers deep and has 128 SCCs for 132 types. **Type declarations can therefore be
written in a strict order today, before any function body exists** - and they should be, because every
function body needs its field offsets.

Hubs (write these first; everything hangs off them):

<<<type_hubs>>>

---

## 4. Function-level layering

Layer definition, as requested: **layer 0 = calls nothing inside the game (only runtime/BRL/imports);
layer N = calls only functions in layers < N.** Computed on the condensation of the call graph, layer =
longest path to a sink.

Two graphs are reported, and the difference between them is the honest measure of our uncertainty:

* **certain graph** - direct edges + static class-table edges + virtual sites resolved to exactly one
  target: 26,183 of the 27,323 game-code call records.
* **sound graph** - the above plus every over-approximated candidate edge (1,140 poly sites in game
  code, ≤12 targets each). Guaranteed to contain the true graph.

<<<fn_layers>>>

### 4.1 Cycles - report and proposal

| Graph | Functions in a cycle | SCCs of size > 1 |
|---|---:|---:|
| certain | **6** | 3 (all pairs) |
| sound | 244 | 2 (one of 242, one of 2) |

The three certain cycles are all genuine mutual recursion and all small:

<<<cycles>>>

Each was checked in both directions in `callgraph_resolved.tsv`; all six edges are `high` confidence,
so these cycles are proven, not inferred:

| cycle | forward edge | back edge |
|---|---|---|
| `TEngine.SetUpSetPiece` ↔ `TEngine.DoShootOut` - the shoot-out re-enters set-piece setup for each penalty | `0x004D2F8D` (static) | `0x004D77F7` (static) |
| `TCompetition.DoPromotionPlaces` ↔ `TCompetition.PromoteToMe` - the promotion/relegation graph is walked recursively across linked competitions | `0x0050F438`, `0x0050F4EF` (virtual) | `0x0050FA42`, `0x0050FA9A` (virtual) |
| `TGadget.CreateToolTip` ↔ `TLabel.CreateLabel` - a tooltip is built out of labels, and a label can carry a tooltip | `0x00514D40` (static) | `0x00519B63` (virtual) |

**Proposal for these three: do not break them.** Each pair is 2 functions and ≤3.0 KB total. Assign
each pair to a single pass as one indivisible unit (they already are: the unit builder never splits an
SCC). The `work_units.tsv` `n_cyclic` column flags them.

The 242-function SCC in the *sound* graph is a different matter. It spans:

<<<bigscc>>>

**It is almost certainly not real.** It exists only because of over-approximated polymorphic edges: when
those are dropped, it collapses completely (6 cyclic functions remain, in unrelated pairs). The honest
statement is: *we have not proven the screen/engine/player core is acyclic, but we have no certain
evidence that it is cyclic either.* Treat the 242 as "ordering unknown within the group" rather than as
a required simultaneous rewrite, and use the **certain** layer column for scheduling. If a real cycle
does surface during reconstruction, the break is the standard one for this codebase: the mutual edge
almost always goes through a global singleton (`TProfile` at `0x00C6F028`, the active `TScreen` at
`0x00C66D18`), so writing the two sides against the global rather than against each other removes the
static dependency without changing behaviour.

---

## 5. The leaves - start here, all in parallel, today

**649 game functions call nothing else in the game.** Of those, **636 are *clean*: no in-scope callee
*and* zero unresolved call sites**, so their callee set is provably empty. They total **79,656 bytes**.
239 of them call nothing at all - not even the BlitzMax runtime - and are pure computation, ideal for
Oracle C differential testing.

The remaining 13 leaves have at least one unresolved indirect site and are **not** certified - they are
listed in `leaves.tsv` with `clean=0`.

<<<leaf_buckets>>>

The 40 largest clean leaves - the ones worth a careful pass rather than a batch:

<<<leaf_top>>>

### 5.1 Full clean-leaf list, grouped by owning Type

Every row below is a function with a provably empty in-game callee set. `unit` is the proposed work
unit from §7. The authoritative machine-readable copy is `extracted/leaves.tsv`.

<<<leaves_full>>>

---

## 6. Minimum vertical slice - boot → menu → load a real club → play one match

Roots taken from the call graph (`ANCHOR_GROUPS` in `build_dependency_graph.py`):

| Phase | Roots |
|---|---|
| entry | the only game function called from outside game code: `0x004BA000` (module init), called from `0x004B7610` in `.text`, itself called from `0x004010C8` on the CRT startup path from the PE entry `0x00401320` |
| boot | `TLocale.SetUp`, `TOptions.SetUp`, `TOptions.LoadOptions`, `TGadget.SetUp`, `TScreen.SetUp`, `TScreen.SetUpFonts` |
| menu | `TScreen.SetActive`, `.Update`, `.Render`, `.GetInput`, `TScreen_MainMenu.CreateScreen`, `.SetUpScreen`, `.Update`, `.NewGame` |
| data | `TContinent/TNation/TClub/TCompetition/TStadium/TPromotionPlace/TTeamPool.LoadData`, `TCompetition.SetUpCompetitionsAll`, `TTeam.CreateSquadSimple` |
| match | `TEngine.SetUp`, `.SetUpMatch`, `.MatchLoop`, `.Update`, `.Render`, `.CheckInput`, `.MatchOver`, `.EndMatch`, `TCompetition.PlayFixtures` |

Forward reachability from those roots:

| Phase | functions (certain graph) | bytes | functions (sound graph) | bytes |
|---|---:|---:|---:|---:|
| entry | 264 | 239,733 | 864 | 570,042 |
| boot | 23 | 10,831 | 749 | 397,672 |
| menu | 165 | 67,485 | 773 | 405,656 |
| data | 140 | 56,907 | 744 | 394,357 |
| match | **600** | **335,413** | 769 | 414,034 |
| **union** | **762** | **521,676** | **900** | **582,942** |

**The answer: 762 functions, 521,676 bytes - 41% of the game's functions and 60% of its code.**
(The sound-graph figure, 900 / 582,942, is the upper bound.)

That is much larger than a "vertical slice" usually implies, and the reason is worth stating plainly:
**NSS5's match engine is not separable from the rest of the game.** `TEngine.MatchLoop` reaches 600
functions on certain edges alone, because a match needs `TPlayer` (123 functions, 93.2 KB in the slice),
`TBall`, `TPitch`, `TTeam`, `TKit`, the `TScreen` overlay system, `TProfile` state and `TCompetition`
fixtures. There is no smaller honest slice; a smaller one would be a different program.

Composition of the certain slice by Type:

<<<slice_by_type>>>

The 60 largest functions on the match path specifically (`groups` contains `match` in
`extracted/vertical_slice.tsv`) - this is the critical path for a playable build:

<<<slice_match>>>

---

## 7. Work units

**Construction rules** (in `build_dependency_graph.py` §8):

1. never split an SCC across units - a cycle has to be written together;
2. group by declaring Type, the natural unit (shared fields, shared idioms, shared helpers, one
   `status/<Type>.tsv` claim file per §6.2 of the methodology guide);
3. split a Type larger than 20 slots into certain-layer-ordered chunks of ≤20;
4. bundle Types with fewer than 5 slots into mixed units at the same layer, so no pass gets a
   two-function job;
5. a unit's dependencies are the units owning any in-scope callee of any of its members.

Unit `type` is the declaring Type; **`_free` is the pseudo-type for the 92 unattributed functions**
(module-level `Function`s, the module initialiser at `0x004BA000`, and compiler helpers) - they have no
recovered name and must be named `Fn_<VA>` per methodology guide §7.3. Per-unit function lists are in
`extracted/work_unit_members.tsv`.

**159 units, 1,850 functions, 867,315 bytes - the whole reconstruction target, partitioned.**

Effort scale is derived directly from total code size:

<<<unit_effort>>>

### 7.1 Ready now - zero in-scope dependencies, fully parallel

These nine units depend on nothing but the BlitzMax runtime. They can be claimed simultaneously by nine
passes on day one. **142 functions, 19,524 bytes.**

<<<units_ready>>>

> `U002 TCompetition[1]` and `U005 TTable[1]` carry a few unresolved sites; their passes must treat the
> callee list as possibly incomplete and re-check during decompilation.
> `U009` includes the three `z_*` BLIde-generated types - **do not reconstruct those**, NG generates its
> own (methodology guide §7.3). They are listed only so the partition is exhaustive.

### 7.2 Layers 0-3

66 units, 818 functions, 242,252 bytes - 44% of the functions and 28% of the code. Finish these and the
bottom of the graph is done.

<<<units_l0_l3>>>

### 7.3 Full unit list

Ordered by certain layer, then by size. `deps` lists the units that must be finished (or stubbed) first.

<<<units_all>>>

---

## 8. Recommended execution order

1. **Write all 132 Type declarations first**, in the Type-layer order of §3 (layer 0 → 5), with the two
   Type cycles co-located in single files. No function bodies. This is mechanical - the field offsets
   and signatures are already in `object_model.json` - and it unblocks everything, plus it immediately
   gives Oracle D (reflection self-check, methodology guide §5.4) something to diff.
2. **Fan out on the 9 ready units** (§7.1) in parallel. 636 clean leaves means a very wide front.
3. **Then layers 1-3** (§7.2), which is where `TFormation`, `TMyDate`, `TKit`, `TStats_Team`,
   `TTableData` and the first `TEngine`/`TClub`/`TBall` chunks sit.
4. **The match path** (§6) is the long pole at 600 functions / 335 KB. Start it as soon as `TPlayer`,
   `TBall` and `TPitch` chunks clear layer 3 - do not wait for the menu system.
5. **Chase the 45 "no candidate type" sites and the 645 untyped-global sites** in parallel with the
   above. Each global that gets typed collapses a candidate set and converts poly edges into certain
   edges, which sharpens the layering for everyone. The highest-value targets are in
   `globals_typed.tsv` sorted by `nsites` with an empty `type` column.

---

## 9. Limitations - read before trusting a number

* **The 17.4% unresolved is a real hole.** For the 172 game functions that contain an unresolved site,
  the callee list in `dep_layers.tsv` is a *lower bound*. They are marked (`n_unresolved > 0`) and are
  never certified as leaves, but their *layer* may be too low.
* **Poly edges over-approximate.** A `cand4` edge means "one of these four", and all four are added to
  the graph. That is safe for ordering and for leaf certification, and unsafe for claiming a
  dependency is *real*. Use the `certain` columns when the question is "does A really call B?".
* **The 242-function SCC is unproven** (§4.1). Do not plan a simultaneous 242-function rewrite on it.
* **Backward def-use walking is not a dataflow analysis.** The walk is linear over the function body,
  not path-sensitive, and it crosses basic-block boundaries. It is right for this codegen - the
  receiver load is emitted immediately before the call in every case checked - but a hand-written
  assembly quirk would defeat it silently. 4 sites reported `CROSSCALL` and were dropped rather than
  guessed.
* **Global *names* are gone** (§2.4) and no amount of further binary work will recover them. Every
  global in the reconstruction is a naming decision, and per methodology guide §7.3 it must be recorded
  as such (`_DAT_00c6f028` → name it from context, note the address on the declaration).
* **A zero caller count does not mean dead code.** The graph only contains calls made *by game code*.
  `New` bodies are invoked by the runtime allocator (`bbObjectNew` does `call dword ptr [cls+0x10]`),
  `Delete` by the collector, and `Compare`/`ToString` by `TList.Sort` and friends - all through class
  tables owned by the runtime, which this pass deliberately does not model. That is why
  `TPlayer.New`, `TCompetition.Compare`, `TTableData.Compare` etc. appear with `n_callers = 0`. They
  are reachable and required; reconstruct them.
* Layer numbers are *not* effort. `TPlayer[1]` is layer 0 and 20 functions; the match engine is layer 14
  and one function of it can be 4 KB. Use `bytes`/`effort`, not `layer`, to size a pass's job.
