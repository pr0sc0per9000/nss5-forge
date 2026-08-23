# Game code that is in NSS5.exe but in no tree at all

**Question asked:** a function that is absent from the corpus is invisible to
`progress.py`, so it cannot lower the percentage. It only surfaces when it blocks
something. How many such functions are there?

**Answer measured:** **23**, all of them module-level `Function`s, totalling **5,193
bytes**. Twenty-one are now byte-identical and in `src/recovered_module/` (2,282 bytes);
two are in `src/recovered_unverified/` and are both structurally complete at the exact
original length, each with a single outstanding call operand (2,911 bytes).

Adding them moved the reported total **down**, from 99.6% to 99.2%, because 5,193 bytes of
denominator that nobody knew existed are now being counted. That is the audit working.

A second finding fell out of the largest of them and is the more serious one: **two rows in
`extracted/runtime_helpers.tsv` are swapped**, which has silently inverted `Upper`/`Lower`
in roughly 49 already-verified bodies without disturbing a single byte. Section 8.

Zero class-table methods were missing. The blind spot was entirely in the half of the
universe that `coverage.py`'s docstring describes but its code never actually reads.

---

## 1. Why the blind spot existed

`scripts/coverage.py` defines the universe as

> (a) a method/function in a class table for a Type declared BY THE GAME, or
> (b) a module-level Function of the game's own main module

and builds (b) from `extracted/module_functions.tsv`:

```python
    modmap = os.path.join(EX, "module_functions.tsv")
    if os.path.exists(modmap):
        ...
```

**`extracted/module_functions.tsv` does not exist.** It is not produced by any script in
`scripts/ghidra_scripts`, and nothing has ever written it. The `os.path.exists` guard
turns its absence into silence, so half the stated definition contributes nothing and the
universe is, in practice, "game Type methods" alone. That is why `coverage.py` reports 87
recovered files sitting "outside the universe" and lists module Functions such as
`ReadSettingFloat` and `LoadImageChecked` among them: they are real game code, they are
recovered, and the denominator does not contain them.

A missing class-table method is visible three ways over (vtable_map, the decompile corpus,
the Type's own file). A missing module Function is visible nowhere: it has no reflection
record, no vtable slot, no `Type.Method` filename, and no row in any table. The 83-byte
clipboard helper at `0x0058D81A` that blocked `TInputBox.Update` was exactly this, and it
was not a one-off: **it was one of 24.**

## 2. How the universe was rebuilt, and why the boundary is exact

The game's own module object occupies **one contiguous run** of the code section:

```
  0x004BA000 .. 0x0058DACC     1,849 functions     867,020 bytes
```

This is not an estimate. Three independent facts pin it:

* **Zero gap bytes.** Walking Ghidra's inventory from `0x004BA000`, every function ends
  exactly where the next begins, all the way to `0x0058DACC`. Below `0x004BA000` there is
  alignment padding after `FUN_004B9628`; a linker put an object boundary there.
* **The bracket functions are the module's own head and tail.** `0x004BA000` (52 bytes) is
  the standard BlitzMax module-init stub: a `[0x005CF000]` once-guard, a call to
  `___bb_blitz_blitz`, then a call to `0x004BA034`. `0x004BA034` (7,933 bytes) is the
  module body itself, whose last 2,384 bytes are already reconstructed in
  `src/module_body/tail.bmx` as VA `0x004BB5E1..0x004BBF31`.
* **`0x0058DACC` belongs to the next module, not this one.** It has the same once-guard
  shape and registers the class tables at `0x00C94988`, `0x00C94B28` and `0x00C94C5C`,
  which `extracted/class_tables.tsv` names `ZipFile`, `ZipWriter` and `ZipReader`. It is
  the zip module's init, so the game's object ends immediately before it.

Within that run, the split is:

| | functions | bytes |
|---|---:|---:|
| class-table methods of the 135 game Types | 1,758 | 835,564 |
| module-level Functions (no vtable slot) | 91 | 31,456 |
| **total** | **1,849** | **867,020** |

and the 91 module-level Functions were:

| | functions | bytes |
|---|---:|---:|
| had a body somewhere under `src/` before this audit | 66 | 18,330 |
| compiler glue / module body (see below) | 2 | 7,985 |
| **had no body anywhere: the blind spot** | **23** | **5,193** |

Nothing else in the exe is game code. Everything below `0x004BA000` (1,292 unaccounted
functions, 446,471 bytes) is the C runtime and the BRL/PUB modules. Everything above
`0x0058DACC` (165 unaccounted functions, 30,838 bytes) is BRL module code too: each of
those 165 sits wedged between two functions that `extracted/brl_functions.tsv` already
names out of a shipped `.a` archive (`dxgraphics`, `max2d`, `d3d7max2d`, `openalaudio`,
`glgraphics`, ...), so they are unnamed rows of a known archive, not unrecovered game
code. Both regions are excluded for exactly the reason `coverage.py`'s docstring gives:
our toolchain emits them from the same BlitzMax sources whether or not anyone looks.

### The two entries counted as glue rather than as blind spot

* `0x004BA000`, 52 bytes. The module-init stub. bcc generates it; nobody writes it.
* `0x004BA034`, 7,933 bytes. The module body. `src/module_body/tail.bmx` reconstructs its
  last 2,384 bytes and `assemble.py` generates the Global declarations that make up the
  first 5,549. Its header carries VA `0x004BB5E1`, not the function's real start, which is
  why a VA-keyed scan reports it as bodyless. Flagged here so the next scan does not
  re-discover it as a defect.

## 3. The inventory

Ranked by size. "Callers" is from a brute scan of **every** `E8`/`E9` rel32 in the exe's
code sections, computed independently of `extracted/callgraph_resolved.tsv`, so a zero is
a real zero and not a hole in the callgraph. None of the 23 is reachable through a
function-pointer table either: a search of the whole file for each VA as a little-endian
dword found no absolute reference to any of them.

| VA | bytes | callers | what it is | status |
|---|---:|---:|---|---|
| `0x0058BC02` | 2848 | 0 | **MD5 digest**, string in, 32-char lowercase hex out | 2848 long, 1 site open, section 5 |
| `0x00506ED2` | 523 | 0 | `ColourIndex` - 17-entry palette lookup by hex string | MATCH 523/523 |
| `0x0050802D` | 260 | **1** | `GreyscaleImage` - luminance-convert a TPixmap, return a TImage | MATCH 260/260 |
| `0x005085FF` | 227 | 0 | `URLDecode` - the inverse of the live `URLEncode` | MATCH 227/227 |
| `0x00508789` | 213 | 0 | `FilterName` - keep only name-legal characters | MATCH 213/213 |
| `0x0058C8B2` | 174 | 4 | `Md5Hex` - one state word as little-endian hex | MATCH 174/174 |
| `0x0058D78D` | 141 | 0 | `SetClipboardText` - the write half of the clipboard pair | MATCH 141/141 |
| `0x0058D094` | 107 | 0 | `SwapHex` - byte-order swap via `Hex()` | MATCH 107/107 |
| `0x00505FDB` | 75 | 0 | `ClampDouble` - the Double twin of ClampInt/ClampFloat | MATCH 75/75 |
| `0x0058C788` | 66 | 16 | `Md5FF` - MD5 round-1 step | MATCH 66/66 |
| `0x0058C7CA` | 66 | 16 | `Md5GG` - MD5 round-2 step | MATCH 66/66 |
| `0x0058C80C` | 66 | 16 | `Md5HH` - MD5 round-3 step | MATCH 66/66 |
| `0x0058C84E` | 66 | 16 | `Md5II` - MD5 round-4 step | MATCH 66/66 |
| `0x0050874A` | 63 | 0 | `DecodeText` - RamStream + LoadText round trip | 43/63, near miss |
| `0x005086E2` | 60 | 1 | `ParseHex` - `Int("$"+s)` with a prefix guard | MATCH 60/60 |
| `0x0050885E` | 33 | 0 | `IntPow` - integer power by repeated multiply | MATCH 33/33 |
| `0x0058C890` | 34 | 4 | `Md5Rotl` - rotate left | MATCH 34/34 |
| `0x0058D050` | 34 | 0 | `Rotl` - rotate left, a second copy in the SHA-256 group | MATCH 34/34 |
| `0x00506026` | 35 | 0 | `ApproachFloat` - in-place lerp towards a target | MATCH 35/35 |
| `0x0058C722` | 30 | 16 | `Md5F` - `(x&y)\|(~x&z)` | MATCH 30/30 |
| `0x0058C740` | 26 | 16 | `Md5G` - `(x&z)\|(y&~z)` | MATCH 26/26 |
| `0x0058C770` | 24 | 16 | `Md5I` - `y~(x\|~z)` | MATCH 24/24 |
| `0x0058C75A` | 22 | 16 | `Md5H` - `x~y~z` | MATCH 22/22 |

Ranked by callers, which is the ranking that says which ones can block work:

* **16 callers each:** `Md5F`, `Md5G`, `Md5H`, `Md5I` (called by the four round steps).
* **16 callers each:** `Md5FF`, `Md5GG`, `Md5HH`, `Md5II` (called by `0x0058BC02`).
* **4 callers:** `Md5Rotl`, `Md5Hex`.
* **1 caller each:** `GreyscaleImage` (from `TScreen_Stable.Update`), `ParseHex` (from
  `URLDecode`).
* **0 callers:** the remaining 11.

Every one of those call sites except one is internal to the group it belongs to. **The
single exception is the one that matters:** `GreyscaleImage` at `0x0050802D` is called
from `TScreen_Stable.Update` (`0x00588C99`, 1,072 bytes, still unrecovered). That is the
same shape as the clipboard helper and `TInputBox.Update`: a caller nobody could finish
because a callee nobody knew about was missing.

## 4. What was found on the way, about the game

Reconstructing these turned up behaviour worth recording, all of it read off the
disassembly:

* **The game contains a complete, working MD5 implementation that nothing calls.** Eleven
  functions, 3,422 contiguous bytes at `0x0058BC02..0x0058C960`, sitting immediately
  before the live `Sha256Hex`. Four rounds of sixteen steps, the canonical
  `0x67452301 / 0xEFCDAB89 / 0x98BADCFE / 0x10325476` state, hand-written lowercase hex
  output. It was written, and then SHA-256 was written next to it and used instead.
* **Ctrl+C was written and never wired up.** `SetClipboardText` at `0x0058D78D` is the
  mirror of the `GetClipboardText` that `TInputBox.Update` uses for Ctrl+V, and it has
  zero callers. It also carries two defects that would have surfaced immediately if it had
  been used: the C string it allocates is never freed, and it calls `GlobalFree` on the
  handle **after** `SetClipboardData` has given ownership of that handle to the clipboard.
* **`FilterName` lets six punctuation characters through.** Its allowed range is a single
  `65..122` span, which spans the gap between `Z` and `a`, so `[ \ ] ^ _ ` ` all pass a
  filter that plainly meant letters. Preserved and annotated in the body.
* **`GreyscaleImage` drops alpha.** It writes `(c Shl 16) | (c Shl 8) | c` with no alpha
  term. It only works because the pixmap has just been converted to `PF_RGB888`.
* **`URLDecode` still has a debugging `MilliSecs()` in it**, called and discarded, before
  the loop. Five bytes of dead call in the shipped exe.
* **`DecodeText` frees its buffer before reading it.** `MemFree` at `0x00508770`,
  `LoadText` over that same buffer at `0x00508779`. Nothing calls it, so it never fires.

## 5. `0x0058BC02`, the MD5 digest: 2,848 of 2,848 bytes long, one site open

`src/recovered_unverified/Fn_0058BC02.Md5.bmx`. Signature `($)$`: a String in, the
32-character hex digest out.

```
  0058BC0B   eax = a0.length ; (eax+8) Shr 6 + 1        ; block count
  0058BC24   push 0x00C944E4 ; call 0x004A63D0          ; New Int[blocks*16]
  0058BC34   edi = 0x67452301 ; [ebp-0x14] = 0xEFCDAB89
  0058BC40   [ebp-4] = 0x98BADCFE ; esi = 0x10325476    ; the MD5 IV
  0058BC53   an explicit zeroing loop over the array bcc has already zeroed
  0058BC8A   pack the string little-endian, then the 0x80 pad and the bit length
  0058BD4E   64 steps, four blocks of 16, into 0x0058C788 / 7CA / 80C / 84E
  0058C6CA   Md5Hex(a) + Md5Hex(b) + Md5Hex(c) + Md5Hex(d), lower-cased
```

The reconstruction is the exact original length, every instruction in the right place, and
73 of its 74 relocation sites mask. **The single site that does not is the last call**, and
it does not mask because of the swapped table rows in section 8, not because of anything in
the body. Spelling that last line `Upper(...)` instead of `Lower(...)` reaches
MATCH 2848/2848 under `NSS5_NO_LEARN=1`; that was measured and deliberately not banked,
because the mask would come from a row this file's own disassembly disproves. Swap the two
rows and the body matches as written.

All 64 step lines were extracted from the disassembly rather than written from knowledge of
the algorithm: the message-word index is the `add edx, k` before each `x` push, the rotate
is the second push and the additive constant the first. They agree with RFC 1321 exactly,
which is a check on the extraction rather than its source.

## 6. Class-table methods: none missing

For completeness, the other half of the universe was diffed the same way. Inside the
game's module object, of 1,758 class-table methods exactly **two** have no body anywhere:

| VA | bytes | method | callers |
|---|---:|---|---:|
| `0x004BF221` | 1411 | `TNation.ButtonizeFlag` | 3 |
| `0x00588C99` | 1072 | `TScreen_Stable.Update` | (screen dispatch) |

Both are already in `coverage.py`'s universe and both already appear in its outstanding
list, so neither is a blind spot: they are ordinary unrecovered work, visible to the
number. `TScreen_Stable.Update` is the one that was blocked by `GreyscaleImage` and is now
unblocked.

Outside the game's module object, 913 class-table methods have no body. All 913 belong to
Types the game *links* rather than declares (the zip module and the bitmap-font module,
plus BRL's own Types), which `coverage.py` already reports separately as "third-party
modules" at 22% and warns against bulk-banking. They are out of scope here.

## 7. Ambiguous, listed rather than silently classified

* **`0x0058DACC`, 295 bytes, 1 caller (the game's module body).** The zip module's init
  function. It is third-party module code, not BRL and not the game's, and our toolchain
  would emit its equivalent from the zip module's own source. It is the reason the game's
  region ends where it does, and it is deliberately **not** counted above.
* **`0x004BA000` and `0x004BA034`.** Compiler-generated module glue and the module body.
  Real code in the exe, already handled by `src/module_body/` and `assemble.py`, but not
  reachable by a VA-keyed scan. Counted as neither recovered nor blind spot.
* **The 165 unnamed functions above `0x0058DACC`.** Each is bracketed by two functions
  named out of a shipped BRL archive, so the strong reading is "BRL rows nobody has added
  to `brl_functions.tsv` yet". None was included. If that reading is ever overturned they
  become in-scope, and the split by archive is reproducible from
  `scripts/workflow/audit5_325.py`.

## 8. `Upper` and `Lower` are swapped in `runtime_helpers.tsv`

Found while closing `0x0058BC02`, and much more serious than anything else on this page.
It is the same failure RULES.md already names ("`runtime_helpers.tsv` carried a wrong row
that blessed ten wrong bodies"), except this one has blessed about forty-nine.

**The evidence.** Two 190-byte C-runtime functions sit next to each other, and each
contains exactly one instruction that decides what it is:

```
  0x004A7410   8D 47 9F   lea eax, [edi - 0x61]     ; c - 'a'
               83 F8 19   cmp eax, 0x19             ; ... <= 25, i.e. 'a'..'z'
               83 E7 DF   and edi, 0xFFFFFFDF       ; CLEAR bit 5  -> UPPER case

  0x004A74E0   8D 47 BF   lea eax, [edi - 0x41]     ; c - 'A'
               83 F8 19   cmp eax, 0x19             ; ... <= 25, i.e. 'A'..'Z'
               83 CF 20   or  edi, 0x20             ; SET bit 5    -> LOWER case
```

`extracted/runtime_helpers.tsv` has them the other way round:

```
  0x004a7410   _brl_retro_Lower    205 witnesses     <- is the UPPER-caser
  0x004a74e0   _brl_retro_Upper     14 witnesses     <- is the LOWER-caser
```

**Why no byte test can catch it.** Both sides emit `E8 rel32` and the oracle masks the
operand when the two names agree. A body that writes `Lower(s)` where the original wrote
`Upper(s)` differs in nothing but that operand, so it masks, matches, and is banked. The
name is never checked against what the callee actually does. This is the call-target twin
of the Globals trap in CONTRIBUTING.md: byte-identical, and reading the wrong thing.

**Blast radius, counted rather than estimated.** Of the game module's own bodies:

| callee | game callers | with a body | what those files write |
|---|---:|---:|---|
| `0x004A7410` (really upper) | 44 | 43 | `Lower(` 158 times, `ToLower(` twice, `Upper(` once |
| `0x004A74E0` (really lower) | 7 | 6 | `Upper(` 18 times, `Lower(` 3 times |

so roughly **49 verified bodies are semantically inverted at those call sites**, including
`TScreen.SetActive`, `TScreen.SetActiveGadget`, `TScreen.CreateScreen`,
`TCombo.SelectItemByLetter`, `TEngine.GoalScored`, `TClub.CreateClub` and
`Sha256Hex`. `Sha256Hex` is the one with visible consequences: the original lower-cases the
digest it returns and the reconstruction upper-cases it, which changes every hash the game
sends anywhere.

**Why this audit did not fix it.** Swapping the rows flips all 49 to MISMATCH until each
file's `Upper`/`Lower` is flipped to match, and `src/recovered/` is a live tree with other
jobs writing to it. It is a self-contained job for someone who can take the tree: swap the
two rows, flip the word in each of the 49 bodies, re-verify. **It costs zero bytes** -- the
emitted instruction is identical either way -- so the whole exercise should end at exactly
the same percentage it started at, with 49 bodies that now do what the original does. If
the re-verification does not come back at parity, the swap is wrong and this section is
wrong with it.

The symbol family is worth settling at the same time. Our build emits four distinct
symbols, measured off the object file: `_bbStringToLower`, `_bbStringToUpper`,
`_brl_retro_Lower`, `_brl_retro_Upper`. The original's call goes straight to the 190-byte
runtime body, not through a 21-byte `retro` wrapper (those live at `0x0059C8E8` and
neighbours), so the faithful reading of the source is the METHOD form `s.ToUpper()` /
`s.ToLower()` and the faithful rows are `_bbStringToUpper` / `_bbStringToLower`. That is a
second, independent reason the existing rows are wrong, and it holds whichever way round
the direction goes.

## 9. The one thing worth fixing in the tooling

`coverage.py` will keep under-reporting its own definition until
`extracted/module_functions.tsv` exists. The contiguous-run method in section 2 produces
it directly: every function in `0x004BA000..0x0058DACC` that is not in `vtable_map.tsv`
is a module-level Function of the game's own module, and there are 91 of them. Writing
that file would add 31,456 bytes to the denominator and 26,263 of them to the numerator,
and, more to the point, would make the next one of these visible the day it is missing
rather than the day it blocks something.

---

*Method note: the region walk, the reference scan and the region classification are
`scripts/workflow/audit3_325.py`, `audit4_325.py`, `audit5_325.py` and `relcalls_325.py`.
`scripts/workflow` is not tracked, so treat those as working notes; every number above is
reproducible from `extracted/ghidra/function_inventory.tsv`, `extracted/vtable_map.tsv`,
`extracted/brl_functions*.tsv`, `extracted/class_tables.tsv` and the exe itself. Every
MATCH claimed here was produced by `harness.try_function` under `NSS5_NO_LEARN=1` and
re-run from the on-disk file on two separately created worker trees.*
