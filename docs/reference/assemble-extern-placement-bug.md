# `assemble.py` mis-places a module-scope `Extern` block -- whole-program build broken

**Status: FIXED 2026-08-22. Both gates green** -- `python scripts/assemble.py` reports
`BUILD OK`, and `python scripts/smoke_boot.py 5` reaches `MAIN MENU reached` with the full
milestone list. The byte-matching corpus was never affected.

It took **three** fixes, because each error masked the next:

1. **`'!Raw` line-level dedupe** (`assemble.py`) -- a placeholder `Function …` / `End Function`
   pair lost its terminator to an identical earlier `End Function`, leaving an unterminated
   function. bcc said `Expecting expression but encountered end-of-file`, pointing at EOF
   ~1,900 lines from the defect. Now dedupes whole fragments, so a terminator can never be
   stripped from its opener.
2. **Global type truncation** (`assemble.py`) -- the type pattern stopped at the first space,
   so `'!Global g_hookFn:Byte Ptr(a:Int, b:Int)` was emitted as `Global g_hookfn:Byte` and
   calling through it gave `Expression of type 'Byte' cannot be invoked`. `GLOBAL_DECL_RX`
   now takes the rest of the declaration, stopping at `=` or a trailing `'`.
3. **Duplicate `GetClipboardText`** -- a stale `'!Raw` placeholder left behind after the real
   body landed; resolved when that body was promoted.

Why #2 survived so long is the part worth keeping: **a single-body probe never sees it.**
`harness.merge_globals` folds the pragma in verbatim, so `Fn_00595EF3` verifies
byte-identical while the assembled build cannot compile -- a whole-program-only defect,
invisible to the per-function oracle.

A related hazard in the same family was closed too: `harness.merge_globals` deduped `'!Raw`
payloads by bare text, so two files whose Extern blocks both ended in a bare `End Extern`
lost one, leaving a block open (`Syntax error in extern block`). Two files were defending
themselves with a trailing comment to keep the text unique -- a convention nothing enforced.
`merge_globals` now never dedupes an Extern delimiter; verified by stripping the workaround
from `Fn_0058D987.SteamPostPlayerValue.bmx`, which still reports `MATCH 325/325`.

The original diagnosis follows unchanged, for the record.

## Symptom

```
$ python scripts/assemble.py
COMPILING ...
  result: BUILD FAILED
    Compile Error: Expecting expression but encountered end-of-file
```

"end-of-file" is misleading: nothing is truncated. The tail of
`src/assembled/nss5_assembled.bmx` is well-formed. An unterminated block mid-file makes bcc
consume everything after it and only notice at EOF.

## Locating it

Only `If` has an inline form in BlitzMax, so every other block pair is unambiguous and can be
counted directly. Over the assembled file's 42,469 code lines:

| pair | open | close |
|---|---:|---:|
| `Method` / `End Method` | 853 | 853 |
| `Type` / `End Type` | 135 | 135 |
| `For` / `Next` | 797 | 797 |
| `While` / `Wend` | 46 | 46 |
| `Select` / `End Select` | 566 | 566 |
| `Repeat` / `Until\|Forever` | 42 | 42 |
| **`Function` / `End Function`** | **986** | **979** |

Seven unclosed `Function`s, all in one contiguous region.

> Note for anyone re-running this: a naive block-balance checker over `src/**/*.bmx` reports
> `src/recovered/TTableData.Compare.bmx` as +31 unbalanced. That is a **false positive** -- the
> file uses 31 single-line `If cond Return n` statements, the inline form with no `Then` and
> no `EndIf`. Any checker that only treats `If ... Then <stmt>` as inline will mis-flag it.

## The actual defect

`src/assembled/nss5_assembled.bmx`, around line 46850:

```blitzmax
Function GetClipboardText:String()
End Function                        ' <-- body dropped entirely
Function SyncSteamAchievements()    ' <-- opened, never closed
Extern "Win32"
Function OpenClipboard(hwnd:Int)
Function CloseClipboard()
Function IsClipboardFormatAvailable(fmt:Int)
Function GetClipboardData(fmt:Int)
Function GlobalLock:Byte Ptr(h:Int)
Function GlobalUnlock(h:Int)
End Extern
```

Three faults, one cause:

1. `GetClipboardText` is emitted with an **empty body**.
2. `SyncSteamAchievements` is emitted with **no `End Function`**.
3. The `Extern "Win32"` block is spliced **inside** that unterminated function rather than at
   module scope.

The six `Function` lines inside `Extern`/`End Extern` are *declarations* and correctly have no
`End Function`; they are not the bug, but they are why the raw count is off by seven rather
than one.

**The source file is not at fault.** `src/recovered_module/Fn_0058D81A.GetClipboardText.bmx`
is well-formed -- a complete `Function ... End Function` with the real body
(`OpenClipboard` / `IsClipboardFormatAvailable` / `GetClipboardData` / `GlobalLock` /
`String.FromCString` / `GlobalUnlock` / `CloseClipboard`) plus its own module-scope `Extern`
block. `assemble.py` takes that file apart and puts the pieces back in the wrong places.

## Why it appeared now

This is a **new** regression, not a latent one. `Fn_0058D81A.GetClipboardText.bmx` was created
today to unblock `TInputBox.Update` (which has since closed, 699 bytes). It is the first
recovered module body to carry its own module-scope `Extern` block, so it is the first input
that exercises this path in `assemble.py`.

## The fix

`assemble.py` must hoist a module body's `Extern ... End Extern` block to module scope,
ahead of the function definitions, rather than emitting it inline at the point the body was
spliced -- and must not lose the function body while doing so. `scripts/harness.py` already has
established handling for `Extern`/`Import` placement (bcc rejects `Import` anywhere but the
top of the file, and `Extern` has its own scope rules); that logic is the reference.

Verify the fix with both gates, not just the first:

```bash
python scripts/assemble.py && python scripts/smoke_boot.py 5
```

5 seconds, not the 40-45 the docs suggest. The full milestone list must still appear: settings
read, language file loaded, kits set up, engine media loaded, game media loaded, sounds
loaded, screens created, ALL screens created, MAIN MENU reached.
