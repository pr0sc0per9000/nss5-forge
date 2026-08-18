"""Predict every crash site WITHOUT running the game.

    python scripts/predict_crashes.py                 # ranked report
    python scripts/predict_crashes.py --by-screen     # grouped by screen/Type
    python scripts/predict_crashes.py --handlers      # button handlers only

WHY STATIC AND NOT A SWEEP
--------------------------
An automated click-everything harness (src/module_body/tail_exercise.bmx) does work and did
find real bugs, but it cannot be left unattended: the game is full of MODAL loops --
TScreen.DoMessage, TScreen.DoProgressBar, TScreen_Options.ButtonLanguage's full screen
rebuild -- that spin waiting for input that never comes. Measured: the sweep blocked for
ten minutes on a single click and needed a human to kill it, which is the opposite of what
it was for. Skipping the blocking handlers one by one is whack-a-mole and shrinks coverage
every time.

This does the same job by reading the code, so it covers every handler including the ones
that block, and finishes in a second.

WHAT IT LOOKS FOR
-----------------
A guaranteed fault is: dereference (`g_x.field`, `g_x.Method()`, `g_x[i]`) of a Global that
the assembled program never writes. In a -d build that throws TNullObjectException; in
release it silently returns 0 and the feature just does nothing
(blitzmax-language-guide 18.26) -- which is the "button does nothing" half of the bug
reports, and is why these are invisible without either this tool or a debug build.

Guarded dereferences are excluded: if the same body tests `If g_x` / `If g_x <> Null` /
`If Not g_x` before the deref, the author handled it. That check is deliberately crude
(same body, test anywhere before the line) and will let some real bugs through rather than
drown the report in false ones -- a missed bug costs a click, a false one costs a wrong
"fix" to a body that was right.

WHAT IT CANNOT SEE
------------------
Nulls that arise at RUNTIME -- an object created but left Null because its creator hit an
error, a list element that is Null, a downcast that failed. It only knows about Globals
that are never written anywhere. So an empty report does not mean no crashes; it means no
crashes of this one (dominant) kind.
"""
import os
import re
import sys
import collections

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SRC = os.path.join(ROOT, "src", "assembled", "nss5_assembled.bmx")
TREES = [os.path.join(ROOT, "src", "recovered"),
         os.path.join(ROOT, "src", "recovered_module"),
         os.path.join(ROOT, "src", "recovered_unverified")]

NUMERIC = {"int", "float", "double", "byte", "short", "long", "string"}


def dead_globals():
    """Globals the assembled program reads but never writes, with their declared types."""
    text = open(SRC, encoding="utf-8-sig", errors="replace").read()
    decls = {m.group(1).lower(): m.group(2).strip()
             for m in re.finditer(r"^Global\s+(\w+)\s*:\s*([^\s'=]+)", text, re.M)}
    body, written = [], set()
    for line in text.split("\n"):
        if line.lstrip().startswith("'"):
            continue
        m = re.match(r"^Global\s+(\w+)\s*:\s*[^\s=]+\s*=", line)
        if m:
            written.add(m.group(1).lower())
            continue
        if re.match(r"^Global\s+\w+\s*:", line):
            continue
        body.append(line)
    body = "\n".join(body)
    pats = [r"(?m)^\s*(\w+)\s*(?::[-+*/|&~]?)?=(?!=)",
            r"(?m)^\s*(\w+)\s*\[[^\]]*\]\s*(?::[-+*/|&~]?)?=(?!=)",
            r"\bVarptr\s+(\w+)",
            r"(?i)\bThen\s+(\w+)\s*(?::[-+*/|&~]?)?=(?!=)",
            r"(?i)\bThen\s+(\w+)\s*\[[^\]]*\]\s*(?::[-+*/|&~]?)?=(?!=)"]
    for p in pats:
        for m in re.finditer(p, body):
            written.add(m.group(1).lower())
    for name, ty in decls.items():
        m = re.search(r"\[\s*([0-9]+)\s*\]\s*$", ty)
        if m and int(m.group(1)) > 0:
            written.add(name)
    out = {}
    for name, ty in decls.items():
        if name in written:
            continue
        base = ty.split("[")[0].lower()
        if base in NUMERIC and "[" not in ty:
            continue                      # a numeric 0 does not fault
        out[name] = ty
    return out


def main():
    by_screen = "--by-screen" in sys.argv
    handlers_only = "--handlers" in sys.argv
    dead = dead_globals()

    hits = []
    for tree in TREES:
        if not os.path.isdir(tree):
            continue
        for fn in sorted(os.listdir(tree)):
            if not fn.endswith(".bmx"):
                continue
            path = os.path.join(tree, fn)
            raw = open(path, encoding="utf-8", errors="replace").read()
            lines = raw.split("\n")
            code = "\n".join(l for l in lines if not l.lstrip().startswith("'"))
            # Globals this body guards -- crude on purpose, see the module docstring.
            guarded = set()
            for m in re.finditer(r"\bIf\s+(?:Not\s+)?(g_\w+)\b\s*(?:<>\s*Null|=\s*Null|Then|\)|And|Or|$)",
                                 code, re.I | re.M):
                guarded.add(m.group(1).lower())
            for i, line in enumerate(lines, 1):
                if line.lstrip().startswith("'"):
                    continue
                for m in re.finditer(r"\b(g_\w+)\s*(\.|\[)", line):
                    g = m.group(1).lower()
                    if g not in dead or g in guarded:
                        continue
                    hits.append((fn[:-4], i, g, dead[g], line.strip()[:90]))

    if handlers_only:
        hits = [h for h in hits if re.search(r"\.(Button|Combo|Do|Click)\w*$", h[0])]

    print("PREDICTED CRASH SITES -- deref of a Global the program never writes")
    print("  dead object/array Globals : %d" % len(dead))
    print("  unguarded deref sites     : %d  across %d bodies"
          % (len(hits), len({h[0] for h in hits})))
    print()

    if by_screen:
        groups = collections.defaultdict(list)
        for fn, ln, g, ty, src in hits:
            groups[fn.split(".")[0]].append((fn, ln, g, ty, src))
        for t in sorted(groups, key=lambda k: -len(groups[k])):
            print("== %s  (%d sites)" % (t, len(groups[t])))
            for fn, ln, g, ty, src in groups[t][:6]:
                print("     %-46s:%-4d %-28s %s" % (fn, ln, g, ty))
            if len(groups[t]) > 6:
                print("     ... and %d more" % (len(groups[t]) - 6))
            print()
    else:
        worst = collections.Counter(h[2] for h in hits)
        print("Globals causing the most crash sites:")
        for g, n in worst.most_common(25):
            bodies = sorted({h[0] for h in hits if h[2] == g})
            print("   %-30s %-14s %3d sites   e.g. %s"
                  % (g, dead[g], n, bodies[0]))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
