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

AN ARGUMENT IS A DEREFERENCE TOO
--------------------------------
`PlaySound(g_x, chan)` writes no dot and no bracket, so the syntactic scan above cannot see
it -- yet brl.mod/audio.mod/audio.bmx:224 is `Function PlaySound:TChannel( sound:TSound,
channel:TChannel=Null ) Return sound.Play( channel )`, a method call straight through
argument 1. Every slot on 0x00C6C550 (the casino win chime, read by six bodies under five
names) and 0x00C6F0D4 (the shop purchase chime) faults exactly there, and every one of them
reads as clean to a scan that only matches `g_x.`.

So the second pass reads the CALLEE. `deref_arg_table()` parses every Function and Method
in the BlitzMax module sources and in the assembled game source, and records an argument
position when that parameter's own name appears as `p.` or `p[` inside the body. A dead
Global passed at such a position is reported; passed anywhere else it is not.

Deriving the table rather than listing callees by hand is what keeps the report honest in
both directions. PlaySound's argument 2 is the same syntax as its argument 1, but `channel`
is only handed on to `Play`, whose signature defaults it to Null -- so a never-written
TChannel there is correct code, and it is the parse of the callee, not an allowlist someone
has to maintain, that separates the two.

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

# Callee bodies for the BRL/PUB functions the game links. They are not part of the
# reconstruction, so the only place PlaySound's `Return sound.Play( channel )` can be read
# is the BlitzMax distribution setup.py downloads.
BMX_MODULES = os.path.join(ROOT, "tools", "blitzmax-legacy-src", "mod")

# A parameter typed as one of these cannot be a Null dereference.
SCALAR_PARAM = NUMERIC | {"$", "%", "#", "!", ""}

_FUNC = re.compile(r"^\s*Function\s+(\w+)\s*:?\s*[\w\[\]$%#!.]*\s*\(([^)]*)\)", re.I)
_METH = re.compile(r"^\s*Method\s+(\w+)\s*:?\s*[\w\[\]$%#!.]*\s*\(([^)]*)\)", re.I)
_ENDF = re.compile(r"^\s*End\s*Function", re.I)
_ENDM = re.compile(r"^\s*End\s*Method", re.I)
_CALL = re.compile(r"\b([A-Za-z_]\w*(?:\.[A-Za-z_]\w*)*)\s*\(([^()]*)\)")


def _split_top(s):
    """Split an argument or parameter list on commas that are not inside brackets."""
    out, depth, cur = [], 0, ""
    for ch in s:
        if ch in "([":
            depth += 1
        elif ch in ")]":
            depth -= 1
        if ch == "," and depth == 0:
            out.append(cur)
            cur = ""
        else:
            cur += ch
    if cur.strip():
        out.append(cur)
    return [p.strip() for p in out]


def _scan_callees(text, table):
    """Record (callee -> {1-based positions}) for every parameter the body dereferences."""
    lines = text.split("\n")
    i = 0
    while i < len(lines):
        fm, mm = _FUNC.match(lines[i]), _METH.match(lines[i])
        if not (fm or mm):
            i += 1
            continue
        m = fm or mm
        closer = _ENDF if fm else _ENDM
        body, j = [], i + 1
        while j < len(lines) and not closer.match(lines[j]):
            if _FUNC.match(lines[j]) or _METH.match(lines[j]):
                break
            body.append(lines[j])
            j += 1
        btxt = "\n".join(l for l in body if not l.lstrip().startswith("'"))
        for idx, p in enumerate(_split_top(m.group(2))):
            pm = re.match(r"(\w+)\s*(?::\s*([\w\[\]$%#!.]+))?", p)
            if not pm:
                continue
            if (pm.group(2) or "").split("[")[0].lower() in SCALAR_PARAM:
                continue
            if re.search(r"\b%s\s*(\.|\[)" % re.escape(pm.group(1)), btxt, re.I):
                table.setdefault(m.group(1).lower(), set()).add(idx + 1)
        i = j if j > i else i + 1


def deref_arg_table():
    """-> {callee name lower: {argument positions whose parameter the body dereferences}}.

    Read out of the callee sources, never listed by hand. An allowlist would have to be
    right about PlaySound's two arguments separately -- argument 1 is `sound.Play(...)` and
    faults, argument 2 is handed to a parameter that defaults to Null and does not -- and
    keeping such a list correct across brl.mod is the kind of maintenance that silently
    stops happening.
    """
    table = {}
    if os.path.isdir(BMX_MODULES):
        for dirpath, _dirnames, filenames in os.walk(BMX_MODULES):
            if os.sep + "doc" in dirpath or os.sep + "tests" in dirpath:
                continue
            for fn in filenames:
                if not fn.endswith(".bmx"):
                    continue
                try:
                    text = open(os.path.join(dirpath, fn), encoding="utf-8",
                                errors="replace").read()
                except OSError:
                    continue
                _scan_callees(text, table)
    if os.path.exists(SRC):
        _scan_callees(open(SRC, encoding="utf-8-sig", errors="replace").read(), table)
    return table


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
    deref_args = deref_arg_table()

    hits, arg_hits = [], []
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
                for m in _CALL.finditer(line):
                    callee, argstr = m.group(1), m.group(2)
                    if not argstr.strip():
                        continue
                    positions = deref_args.get(callee.split(".")[-1].lower(), ())
                    for idx, a in enumerate(_split_top(argstr)):
                        g = a.strip().lower()
                        if not re.fullmatch(r"g_\w+", g):
                            continue
                        if g not in dead or g in guarded or (idx + 1) not in positions:
                            continue
                        arg_hits.append((fn[:-4], i, g, dead[g], callee, idx + 1))

    if handlers_only:
        hits = [h for h in hits if re.search(r"\.(Button|Combo|Do|Click)\w*$", h[0])]
        arg_hits = [h for h in arg_hits
                    if re.search(r"\.(Button|Combo|Do|Click)\w*$", h[0])]

    print("PREDICTED CRASH SITES -- deref of a Global the program never writes")
    print("  dead object/array Globals : %d" % len(dead))
    print("  unguarded deref sites     : %d  across %d bodies"
          % (len(hits), len({h[0] for h in hits})))
    print("  dereferenced as an argument: %d  across %d bodies"
          % (len(arg_hits), len({h[0] for h in arg_hits})))
    print()

    if arg_hits:
        print("DEREFERENCED THROUGH A CALL ARGUMENT")
        print("  the callee's own body does `p.` or `p[` on this parameter, so the Null")
        print("  reaches a method call and faults there rather than at the line below.")
        for fn, ln, g, ty, callee, pos in sorted(arg_hits):
            print("   %-44s:%-4d %-26s %-10s %s arg %d"
                  % (fn, ln, g, ty, callee, pos))
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
