# w702 -- audit of the 2026-08-22 address-map regeneration

Every claim below is tagged **MEASURED** (I ran it and diffed the bytes) or **INFERRED**
(read from code, not executed).

## Verdict in one line

**Yes, there was collateral damage, and it is exactly three names: `g_player_int27`,
`g_player_int28`, `g_player_int29`.** Nothing else in the corpus moved. **Neither
reported runtime bug is on the affected path** -- the steering path and the tooltip path
are bit-for-bit unchanged across the regeneration, so both bugs are pre-existing and must
be fixed forward, not reverted. **MEASURED.**

There is also a separate, more dangerous finding that the change did not cause but did
arm: `extracted/global_alias_unified.tsv` was never actually rewritten (the script's write
flag is `--write`, not `--emit`), so it is stale and is the *only* thing still supplying
the three correct merges the regenerated map dropped. See "The armed landmine" below.

---

## 1. How the baseline was reconstructed

`extracted/` is gitignored in full (`.gitignore` line 73), so there is no history. I built
four complete private trees in scratch, each a full snapshot of `scripts/`, `binary/`,
`src/recovered*`, `src/module_body` and `extracted/`, taken at one instant so that the
concurrent edits two other workers are making to `global_alias_overrides.tsv` cannot move
under the experiment. The live `extracted/` tree was never written to. **MEASURED.**

| tree | `global_address_adjudicated.tsv` | `global_alias_overrides.tsv` | what it represents |
|---|---|---|---|
| **A** | without the 2 pins | without rows 851-852 | true pre-change baseline |
| **B** | **with** the 2 pins | without rows 851-852 | state immediately after the regeneration |
| **C** | with the 2 pins | **with** rows 851-852 | current live state |
| **D** | without the 2 pins | with rows 851-852 | proposed state if the pins are removed |

Fidelity check: tree **B**'s `global_address_map.tsv` is **byte-identical** to the live
`extracted/global_address_map.tsv` (`diff` exit 0, 2780 lines). The reconstruction is
exact, not approximate -- so every diff below is the real diff the author was told to take
and did not. **MEASURED.**

Solver statistics per tree:

| tree | CERTAIN | STRONG | AMBIGUOUS | UNGROUNDED | seed pairs | seed accuracy |
|---|---|---|---|---|---|---|
| A (baseline) | 544 | **1176** | **1046** | 13 | 459 | 100.0% |
| B (= live) | 544 | **1171** | **1051** | 13 | 461 | 100.0% |
| C (live + overrides) | 546 | 1169 | 1051 | 13 | 463 | 100.0% |
| D (overrides, no pins) | 546 | 1169 | 1051 | 13 | 463 | 100.0% |

---

## 2. The complete diff: every binding and every tier that changed

`diff A/global_address_map.tsv B/global_address_map.tsv` -- **five lines, and only five,
out of 2779 names.** **MEASURED.**

```
-g_player_int27	0x00C5DE30	STRONG	Int	1	forced in 1 body
-g_player_int28	0x00C5DE34	STRONG	Int	1	forced in 1 body
-g_player_int29	0x00C5DE38	STRONG	Int	1	forced in 1 body
-g_player_int30	0x00C5DE40	STRONG	Int	1	forced in 1 body
-g_player_int31	0x00C5DE3C	STRONG	Int	1	forced in 1 body
+g_player_int27	-	AMBIGUOUS	Int	1	no alignment forced it (1 bodies)
+g_player_int28	-	AMBIGUOUS	Int	1	no alignment forced it (1 bodies)
+g_player_int29	-	AMBIGUOUS	Int	1	no alignment forced it (1 bodies)
+g_player_int30	-	AMBIGUOUS	Int	1	no alignment forced it (1 bodies)
+g_player_int31	-	AMBIGUOUS	Int	1	no alignment forced it (1 bodies)
```

Against the intended blast radius of 7 names:

| intended | what actually happened |
|---|---|
| `g_player_int30` | did not bind; went `STRONG 0x00C5DE40` -> `AMBIGUOUS`. Intended target, intended-ish outcome (the old value was wrong anyway). **MEASURED** |
| `g_player_int31` | same, `STRONG 0x00C5DE3C` -> `AMBIGUOUS`. **MEASURED** |
| `g_player_handlex` | **unchanged by the regeneration** (`0x00C5DE3C STRONG` in both A and B). It only moved to `CERTAIN` later, when the override rows were added. **MEASURED** |
| `g_player_handley` | same, `0x00C5DE40`. **MEASURED** |
| five movement Globals (`g_player_float05/06/09/10/17`) | **unchanged**. They were already override rows in the baseline; all five are `AMBIGUOUS` in the map in A, B, C and D alike. **MEASURED** |
| -- | **`g_player_int27`, `g_player_int28`, `g_player_int29`: UNINTENDED. Three correct `STRONG` bindings destroyed.** **MEASURED** |

So the true blast radius is 5 names, not 7, and 3 of the 5 were not intended to move at all.

### Why it happened -- the mechanism, proven

`extracted/decomp/TPlayer.PaintPlayer@004ee011.c` line 29:

```c
FUN_005ae336(*(undefined4 *)(param_1 + 0xc),(float)DAT_00c5de3c,(float)DAT_00c5de40);
```

`addr_oracle.statement_groups()` matches call argument lists with
`\w+\s*\(([^();]*)\)`. `[^();]*` cannot span the nested `*(undefined4 *)(param_1 + 0xc)`,
so this call emits **no** group and its cdecl right-to-left correction is silently skipped.
Line 20's `FUN_005ae2bc(uVar3,DAT_00c5de30,DAT_00c5de34,0,DAT_00c5de38,0xffffffff)` has no
nested parens, so *that* call is corrected normally. **MEASURED** (regex read; behaviour
confirmed by the probe below).

I instrumented `AO.collect()` + `UN.align()` directly on this body:

```
names     : [g_player_int27, g_player_int28, g_player_int29, g_player_int30, g_player_int31]
addrs     : [00c5de30, 00c5de34, 00c5de38, 00c5de40, 00c5de3c]     <-- 40 BEFORE 3c
tree A  (no seeds on this body):  int27->30  int28->34  int29->38  int30->40  int31->3c
tree D  (seeds int30->3c, int31->40):  ALL FIVE -> []   (empty)
```

**MEASURED.** The address list has `0x...40` at index 3 and `0x...3C` at index 4. A seed
that forces `int30 -> 0x...3C` and `int31 -> 0x...40` demands index 4 before index 3,
which no *monotone* alignment can satisfy. `align()` then hits `f[n][m] == NEG` and returns
an empty candidate set **for every name in the body**, not just for the pinned ones.

**This is the important structural lesson: an order-infeasible pin does not merely fail --
it silently voids every Global in every body that declares it.** The three casualties were
simply the other names in `TPlayer.PaintPlayer`. **MEASURED** (mechanism) / **INFERRED**
(that this generalises to other bodies -- no other body in the corpus is affected today,
per the exhaustive 5-line diff).

Note that the *override rows alone* reproduce the damage: tree D has no pins and still
loses all five. The pins are not uniquely to blame. **MEASURED.**

---

## 3. Is the new binding right or wrong? Judged from machine code

`TPlayer.PaintPlayer`, VA `0x004EE011`, 161 bytes, byte-identical. `python scripts/disasm.py 0x004EE011 161`:

```
0x004EE040  6aff                 push -1
0x004EE042  ff3538dec500         push dword ptr [0xc5de38]
0x004EE048  6a00                 push 0
0x004EE04A  ff3534dec500         push dword ptr [0xc5de34]
0x004EE050  ff3530dec500         push dword ptr [0xc5de30]
0x004EE056  50                   push eax                      ; the TPixmap
0x004EE057  e860020c00           call 0x5ae2bc                 ; LoadAnimImage
...
0x004EE078  a140dec500           mov eax, dword ptr [0xc5de40] ; pushed FIRST  -> LAST arg
0x004EE089  a13cdec500           mov eax, dword ptr [0xc5de3c] ; pushed SECOND -> arg2
0x004EE09A  ff730c               push dword ptr [ebx + 0xc]    ; imgPlayer     -> arg1
0x004EE09D  e894020c00           call 0x5ae336                 ; SetImageHandle
```

The body reads `LoadAnimImage(p, g_player_int27, g_player_int28, 0, g_player_int29, -1)`
and `SetImageHandle(imgPlayer, g_player_int30, g_player_int31)`. cdecl pushes right to
left, so:

| name | address, from machine code | old (A) | new (B) | verdict |
|---|---|---|---|---|
| `g_player_int27` (cell width) | **`0x00C5DE30`** | `0x00C5DE30` | `-` | **old was RIGHT, new is a LOSS** |
| `g_player_int28` (cell height) | **`0x00C5DE34`** | `0x00C5DE34` | `-` | **old was RIGHT, new is a LOSS** |
| `g_player_int29` (frame count) | **`0x00C5DE38`** | `0x00C5DE38` | `-` | **old was RIGHT, new is a LOSS** |
| `g_player_int30` (handle X, arg2) | **`0x00C5DE3C`** | `0x00C5DE40` | `-` | old was WRONG; new is merely absent, so this is an improvement in the weak sense that a wrong answer was replaced by no answer |
| `g_player_int31` (handle Y, arg3) | **`0x00C5DE40`** | `0x00C5DE3C` | `-` | same |

**MEASURED.** Two independent corroborations, both from byte-verified bodies:

* `TPlayer.SetUp` (VA `0x004EC179`, 4821/4821 byte-identical) declares
  `g_player_spritewidth / spriteheight / spritecount / handlex / handley` and writes them
  from `Engine.ini` keys `spritewidth_player`, `spriteheight_player`, `spritecount_player`,
  `handlex_player`, `handley_player`. `python scripts/disasm.py 0x004EC1F0 180` shows the
  stores land at `[0xc5de34]`, `[0xc5de38]`, `[0xc5de3c]`, `[0xc5de40]` in that order (and
  `[0xc5de30]` just above), then `fstp [0xc5de44]` for `spritescale`. **MEASURED.**
* `extracted/globals_final.tsv` rows 464-468 already record
  `0x00c5de30..0x00c5de40 = g_player_int27..int31` sequentially -- i.e. it independently
  agrees with the corrected pairing, not with the pre-change map. **MEASURED.**

I found **no** case where the regeneration improved a binding. It removed three correct
ones and two incorrect ones. Net: strictly worse for the map, though the two incorrect
ones are now supplied correctly by the override rows.

---

## 4. The two reported bugs: did the regeneration touch either path? NO.

Since the entire A-to-B diff is five lines confined to `0x00C5DE30..0x00C5DE40`, the answer
follows immediately, but I verified it positively as well, pulling every `'!Global` pragma
from each body and comparing its row in A against its row in B. **MEASURED -- zero
differences on either path.**

### Steering path

| body | globals checked | any changed? |
|---|---|---|
| `TJoy.Update` (`0x004D9CFA`) | 14 (incl. `g_opt_ctrlup/down/left/right`, `g_ply_turnrate`) | **none** |
| `TPlayer.UpdateJoy` (`0x004F19AA`) | 4 | **none** |
| `TPlayer.UpdateMovement` (`0x004F0468`) | 27 | **none** |

Spot values, identical pre and post: `g_opt_ctrlup 0x00C5D1B4 CERTAIN`,
`g_opt_ctrldown 0x00C5D1BC STRONG`, `g_opt_ctrlleft 0x00C5D1C4 CERTAIN`,
`g_opt_ctrlright 0x00C5D1CC STRONG`. `g_ply_turnrate` is `AMBIGUOUS` in **both** A and B --
it was already unresolved before the change, and it is the only `turnrate`-like name in the
corpus. **MEASURED.**

### Tooltip path

`TGadget.UpdateToolTip`, 9 globals, all identical pre and post:
`g_options_tooltips 0x00C5D258 CERTAIN`, `g_screen_usemouse 0x00C6173C CERTAIN`,
`g_activegadget 0x00C61CF8 CERTAIN`, `g_screen_mousex 0x00C61724 CERTAIN`,
`g_screen_mousey 0x00C61728 CERTAIN`, `g_screen_scrollx 0x00C61740 STRONG`,
`g_screen_scrolly 0x00C61744 STRONG`, `g_screen_w - AMBIGUOUS`,
`g_screen_h 0x00C6EFE8 CERTAIN`. **MEASURED.**

I also swept the whole `0x00C617xx` family (26 names, including all five at `0x00C6173C`:
`g_mouseactive`, `g_screen_int03`, `g_screen_showmouse`, `g_screen_usemouse`,
`g_screenflag`). **Every one identical pre and post.** **MEASURED.**

### Corroborating argument, independent of the diff

Nothing downstream of the map was actually rewritten by this change.
`extracted/global_alias_unified.tsv` has mtime **2026-08-17 02:00:38**, five days *before*
`global_address_map.tsv` (2026-08-22 20:29:50). The only other build-path consumer of the
map is `assemble.py:1565`, which uses it solely to propagate **array sizes** by address --
and `globals_final.tsv` types all five affected slots as scalar `Int`, so that path is not
reached either. **MEASURED.**

**Conclusion: the arrow-key steering bug and the 495px tooltip offset cannot be collateral
damage from this regeneration. Both are pre-existing. Fix forward; do not revert.** Two
workers can stop looking for a cause here.

---

## 5. The armed landmine (found while auditing; not caused by this change, but exposed by it)

`emit_unified_aliases.py` writes only when passed `--write`. The landed change ran it as
`python scripts/emit_unified_aliases.py`, which computes and prints but writes nothing --
which is why `global_alias_unified.tsv` still carries its 2026-08-17 mtime. **MEASURED.**

When I regenerate it properly (`--write`) from tree A vs tree B, **five rows disappear**:

```
-0x00C5DE30	g_player_int27	g_player_spritewidth	descriptive, 1 files; alias tier STRONG
-0x00C5DE34	g_player_int28	g_player_spriteheight	descriptive, 1 files; alias tier STRONG
-0x00C5DE38	g_player_int29	g_player_spritecount	descriptive, 1 files; alias tier STRONG
-0x00C5DE3C	g_player_int31	g_player_handlex	descriptive, 1 files; alias tier STRONG
-0x00C5DE40	g_player_int30	g_player_handley	descriptive, 1 files; alias tier STRONG
```

**MEASURED** (identical whether or not the pins are present -- trees B and C both drop all
five).

Those merges are **load-bearing, not cosmetic**. `TPlayer.SetUp` writes
`g_player_spritewidth/height/count`; `TPlayer.PaintPlayer` reads `g_player_int27/28/29`.
The current assembled output confirms they are one storage each:
`src/assembled/.bmx/nss5_assembled.bmx.console.release.win32.x86.s` has
`mov dword [_bb_g_player_spritewidth],eax` (line 71398, in SetUp) and
`push dword [_bb_g_player_spritewidth]` (line 73538, in PaintPlayer). **MEASURED.**

Right now the build is correct only by accident: the stale unified table still supplies the
three `int27/28/29` merges, and `assemble.py:global_alias_map()` composes
`global_alias_map -> global_alias_unified -> global_alias_writers -> global_alias_adjudicated
-> global_alias_overrides` with **overrides highest**, so the overrides correctly overwrite
the stale table's transposed `int31->handlex` / `int30->handley` rows with
`int30->handlex` / `int31->handley`. **MEASURED** (precedence tuple read at
`scripts/assemble.py:290-292`; cycle check reports 0 cycles).

**The next person who runs `emit_unified_aliases.py --write` deletes the three
`int27/28/29` merges, and `LoadAnimImage(p, 0, 0, 0, 0, -1)` breaks the player sprite
outright.** That is a real, imminent regression and it is the highest-value item in this
report. **INFERRED** from the two measured facts above (row deletion; merges load-bearing).

Second-order warning: `global_alias_unified.tsv` is now 5 days stale against the source
trees. Regenerating it today changes **175 lines** (99 dropped, 76 added) beyond the five
discussed here, because other workers have landed bodies since. **Do not regenerate it as a
side effect of this fix.** **MEASURED.**

---

## 6. Should the two adjudicated pins be removed? YES -- but they are not the fix

Quantified, from the C vs D comparison (both with the override rows present, differing only
in whether the two pins exist):

* `global_address_map.tsv`: **byte-identical** (same md5). **MEASURED.**
* `global_alias_unified.tsv` regenerated with `--write`: **byte-identical**. **MEASURED.**
* seed count: 463 in both -- the pins map `int30 -> 0x00C5DE3C` and `int31 -> 0x00C5DE40`,
  which is exactly what override rows 851-852 already contribute, so they are **exact
  duplicates**. **MEASURED.**

So removing them changes **nothing**, in either table. They are pure redundancy with a
misleading provenance note (the pin's own evidence column claims a binding the map does not
contain). Remove them for hygiene. **But removing them does not restore `int27/28/29`** --
tree D still loses all five, because the override rows are order-infeasible on this body in
exactly the same way. **MEASURED.**

### Proposed rows (for the parent to apply -- I did not touch the live tree)

**Required.** Append to `extracted/global_alias_overrides.tsv`. These make the three merges
independent of the solver, so the landmine in §5 is defused and the next
`emit_unified_aliases.py --write` is safe. I validated them in a private tree: the
alias-graph cycle check reports **0 cycles**. **MEASURED.**

```
0x00C5DE30	g_player_int27	g_player_spritewidth	LoadAnimImage cellwidth. TPlayer.PaintPlayer 0x004EE050 pushes [0xc5de30] as arg2 of _brl_max2d_LoadAnimImage; TPlayer.SetUp 0x004EC1xx writes ini "spritewidth_player" to 0x00C5DE30. Needed as an override because the adjudicated/override pins on int30/int31 make this body's alignment order-infeasible, so the solver forces nothing here at all.
0x00C5DE34	g_player_int28	g_player_spriteheight	LoadAnimImage cellheight. 0x004EE04A pushes [0xc5de34]; TPlayer.SetUp 0x004EC205 stores ini "spriteheight_player" to 0x00C5DE34. Same reason.
0x00C5DE38	g_player_int29	g_player_spritecount	LoadAnimImage frame count. 0x004EE042 pushes [0xc5de38]; TPlayer.SetUp 0x004EC231 stores ini "spritecount_player" to 0x00C5DE38. Same reason.
```

**Recommended.** Delete these two now-inert rows from
`extracted/global_address_adjudicated.tsv` (they are the last two lines of the file):

```
g_player_int30	0x00C5DE3C	...
g_player_int31	0x00C5DE40	...
```

Measured effect of deleting them: zero rows change in `global_address_map.tsv` and zero in
`global_alias_unified.tsv`. **MEASURED.**

**Root-cause fix (optional, strictly better).** Teach
`addr_oracle.statement_groups()` to match a call's argument list across nested parentheses
(the current `\w+\s*\(([^();]*)\)` cannot). I tested the outcome by feeding `align()` the
corrected address order `[30, 34, 38, 3C, 40]` for this body:

```
g_player_int27 -> 00c5de30    g_player_int28 -> 00c5de34    g_player_int29 -> 00c5de38
g_player_int30 -> 00c5de3c    g_player_int31 -> 00c5de40
```

**All five forced, all five correct, no overrides needed. MEASURED.** This is the real fix;
the override rows above are the safe stopgap. Note the header of `statement_groups()`
records that widening the correction to whole decompiled *lines* was measured as worse
(362 CERTAIN vs 411) -- so the change must be strictly "let the argument-list matcher span
balanced parens", not "reorder every address on the line".

---

## 7. Reproduction

Nothing in the live `extracted/` tree was written. The four trees, the emitted maps, the
alias tables and the probe scripts are under
`.../scratchpad/w702/{A,B,pre,post,E}` with the run logs beside them, plus
`live_hashes_at_snapshot.txt` recording the live-file md5s at snapshot time so the
experiment can be re-pinned. `scripts/assemble.py` and `scripts/build_debug.sh` were not
run.
