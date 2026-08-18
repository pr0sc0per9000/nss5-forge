"""Find arrays the program indexes past their declared length.

    python scripts/check_array_bounds.py

WHY
===
This is the failure mode that crashes the game on startup rather than degrading quietly,
so it is worth a dedicated check.

A null dereference in a BlitzMax RELEASE build returns 0 instead of faulting
(blitzmax-language-guide 18.26) -- that is why most defects in this project present as "the
button does nothing". An out-of-bounds ARRAY WRITE does not get that treatment: it stores
through a computed address and the process dies with an access violation.

It happened for real. `globals_type_overrides.tsv` pinned g_kitfiles to `String[1]`,
reasoning at the time that "this Global is not in module_globals_decoded.tsv, so no table
carries its size; largest observed index implies length 1". Correct when written. Then an
alias merge landed g_kit_arr01 -- which IS in that table, as String[26] -- onto g_kitfiles,
and the guess won over the binary. TKit.SetUp writes basemask, baseshirt1 and 24 more into
indices 0..25 of a one-element array, and the game died on startup.

The general lesson, which this file exists to catch: a merge can invalidate a hand-written
override whose justification depended on facts the merge changed. The override does not
know it has gone stale. Nothing re-derives it.

WHAT IS CHECKED
===============
For every Global declared with an explicit array length, the highest CONSTANT index the
assembled program uses is compared against that length. Three outcomes:

  OVERFLOW   a constant index >= the declared length. A guaranteed out-of-bounds access,
             and if it is ever a write, a crash.
  UNSIZED    declared `T[]` with no length. Length 0, so EVERY index is out of bounds --
             it throws in a -d build and silently returns 0 in release.
  ok         no constant index reaches the end.

Variable indices (`a[i]`) cannot be checked statically and are not reported; a clean run
here does not prove the program is in bounds, only that no literal index is out of range.
"""
import os
import re
import collections

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SRC = os.path.join(ROOT, "src", "assembled", "nss5_assembled.bmx")

DECL = re.compile(r"^Global\s+(\w+)\s*:\s*([A-Za-z_][\w.]*)\s*\[\s*(\d*)\s*\]", re.M)


def main():
    if not os.path.exists(SRC):
        raise SystemExit("no %s -- run scripts/assemble.py first" % SRC)
    text = open(SRC, encoding="utf-8-sig", errors="replace").read()

    sized, unsized = {}, {}
    for m in DECL.finditer(text):
        name, ty, n = m.group(1).lower(), m.group(2), m.group(3)
        if n:
            sized[name] = (ty, int(n))
        else:
            unsized[name] = ty

    code = "\n".join(l for l in text.split("\n") if not l.lstrip().startswith("'"))
    maxidx = collections.defaultdict(lambda: -1)
    writes = set()
    for m in re.finditer(r"\b(g_\w+)\s*\[\s*(\d+)\s*\]\s*(=(?!=))?", code, re.I):
        n, i = m.group(1).lower(), int(m.group(2))
        if i > maxidx[n]:
            maxidx[n] = i
        if m.group(3):
            writes.add(n)

    over, unsized_used = [], []
    for name, (ty, ln) in sorted(sized.items()):
        hi = maxidx.get(name, -1)
        if hi >= ln:
            over.append((name, ty, ln, hi, name in writes))
    for name, ty in sorted(unsized.items()):
        hi = maxidx.get(name, -1)
        if hi >= 0:
            unsized_used.append((name, ty, hi, name in writes))

    print("ARRAY BOUNDS CHECK")
    print("  sized array Globals    : %d" % len(sized))
    print("  unsized array Globals  : %d" % len(unsized))
    print("  OVERFLOW (const index >= length) : %d" % len(over))
    print("  UNSIZED but indexed              : %d" % len(unsized_used))
    print()
    if over:
        print("  OVERFLOW -- a write here is an access violation, not a silent no-op:")
        for name, ty, ln, hi, w in over:
            print("    %-34s %s[%d]  max index %d   %s"
                  % (name, ty, ln, hi, "WRITE" if w else "read"))
        print()
    if unsized_used:
        print("  UNSIZED but indexed -- length 0, so every access is out of bounds:")
        for name, ty, hi, w in unsized_used[:30]:
            print("    %-34s %s[]  max index %d   %s"
                  % (name, ty, hi, "WRITE" if w else "read"))
        if len(unsized_used) > 30:
            print("    ... and %d more" % (len(unsized_used) - 30))
    if not over and not unsized_used:
        print("  no constant index out of range")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
