"""Static lint over src/assembled/: is any Global CALLED whose declared type is not callable?

WHY THIS EXISTS
===============
`bcc` reports this class of defect as

    Compile Error: Expression of type 'Byte' cannot be invoked

with NO file and NO line number (exp.cpp:500, `InvokeExp::_eval`, reached whenever the
callee expression is neither a FunType, a ClassType nor -- outside SuperStrict -- an
ArrayType). On a 48,000-line generated file that message localises nothing, and the whole
`assemble.py` gate is dead until somebody bisects it by hand.

The defect it caught, measured 2026-08-22 on worker 324:

    src/recovered_module/Fn_00595EF3.bmx declares
        '!Global g_hookFn:Byte Ptr(a:Int, b:Int)        ' a function-pointer Global
    and calls it
        Local p:Byte Ptr = g_hookFn(0, 4101)
    The assembler emitted the declaration with the type truncated at the first space:
        Global g_hookfn:Byte
    so the call became an invocation of a Byte. bcc said 'Byte' cannot be invoked and
    named no line.

That truncation is the general hazard, not a one-off: assemble.py REGENERATES a canonical
`Global <name>:<Type>` line per name rather than emitting the pragma text verbatim, so any
regex in that path that stops at whitespace silently rewrites `Byte Ptr(a:Int, b:Int)` to
`Byte`, `Int Ptr` to `Int`, and so on. A Global's declared type is also the only thing that
decides which vtable slot a call through it uses, so the same truncation is exactly the
shape CONTRIBUTING warns about under "a byte match does not prove your Globals are right":
every individual body still verifies, because each probe emits its own pragma text as-is.

docs/RULES.md: a rule that is only written down gets broken. This is the check.

WHAT IT REPORTS
===============
A module-scope `Global name:Type` whose Type is NOT callable, where `name(` appears
somewhere in the same compilation unit. Callable, per bcc's parser (parser.cpp
`parseType`) and `InvokeExp::_eval`:

  * a function type      -- the declared type contains a parameter list, `Int()`,
                            `Byte Ptr(a:Int, b:Int)`, ...        -> invokeFun
  * a class/object type  -- `TFoo`, `Object`, `String`           -> performCast
  * an array type        -- callable ONLY outside SuperStrict; every unit we emit is
                            SuperStrict, so an invoked array is reported

Everything else -- Byte, Short, Int, Long, Float, Double, and their `Ptr` forms -- is a
hard compile error at the call site.

FALSE POSITIVES
===============
A Global whose name collides with a Function name cannot reach this check: bcc rejects
that pair as a duplicate identifier long before `InvokeExp`. String literals and comments
are stripped before the call scan, so `"g_x(1)"` inside a message does not count.

USAGE
=====
    python scripts/check_global_calls.py            # both assembled units
    python scripts/check_global_calls.py <file.bmx> # any single .bmx

Exit status 0 = clean, 1 = at least one non-callable Global is invoked.
"""
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ASSEMBLED = os.path.join(ROOT, "src", "assembled")
UNITS = ["nss5_assembled.bmx", "nss5_external.bmx"]

# Module scope only: assemble.py emits every Global declaration flush left. A Global
# declared inside a Type or a Function is a different scope and a different question.
GLOBAL_RX = re.compile(r"^Global\s+(\w+)\s*:\s*(.+?)\s*$")

SCALARS = {"byte", "short", "int", "long", "float", "double"}


def strip_code(line):
    """-> the line with string literals and the trailing comment removed.

    BlitzMax opens a comment with `'` anywhere outside a string, and `~q` (not `\\"`) is
    how a quote is escaped inside one, so a plain quote toggle is correct here.
    """
    out, in_str = [], False
    for ch in line:
        if ch == '"':
            in_str = not in_str
            continue
        if ch == "'" and not in_str:
            break
        out.append(" " if in_str else ch)
    return "".join(out)


def callable_type(ty):
    """Would bcc let `x(...)` through for a Global declared `:ty`? (SuperStrict rules.)"""
    t = ty.strip()
    if "(" in t:                       # function type: Int(), Byte Ptr(a:Int, b:Int)
        return True
    if t.endswith("]"):                # array -- NOT invokable under SuperStrict
        return False
    base = t.replace(" Ptr", "").replace(" Var", "").strip().lower()
    return base not in SCALARS         # anything left is a class/object/String -> a cast


def check(path):
    """-> list of (name, declared type, line number of the declaration, [call lines])."""
    lines = open(path, encoding="utf-8-sig", errors="replace").read().split("\n")
    decls = {}
    for i, raw in enumerate(lines, 1):
        m = GLOBAL_RX.match(raw)
        if m and not callable_type(m.group(2)):
            decls[m.group(1).lower()] = (m.group(1), m.group(2), i)
    if not decls:
        return []
    # One pass over the file per unit, not one per name: the corpus carries ~2,900
    # Globals and a scan each would be 140 million line matches.
    call_rx = re.compile(r"\b(%s)\s*\(" % "|".join(re.escape(n) for n in decls),
                         re.IGNORECASE)
    hits = {}
    for i, raw in enumerate(lines, 1):
        if i in {d[2] for d in decls.values()}:
            continue
        for m in call_rx.finditer(strip_code(raw)):
            hits.setdefault(m.group(1).lower(), []).append(i)
    return [(decls[k][0], decls[k][1], decls[k][2], v) for k, v in sorted(hits.items())]


def main(argv):
    paths = argv[1:] or [os.path.join(ASSEMBLED, u) for u in UNITS]
    bad = 0
    for p in paths:
        if not os.path.exists(p):
            print("  MISSING %s -- run scripts/assemble.py first" % p)
            continue
        rows = check(p)
        print("%s: %d non-callable Global(s) invoked" % (os.path.basename(p), len(rows)))
        for name, ty, dline, calls in rows:
            bad += 1
            print("  !! Global %s:%s  declared at line %d" % (name, ty, dline))
            print("     invoked at line(s) %s" % ", ".join(str(c) for c in calls[:8]))
            print("     bcc will say: Expression of type '%s' cannot be invoked"
                  % ty.strip())
    if bad:
        print()
        print("A Global's declared type is regenerated by assemble.py, not copied from the")
        print("'!Global pragma. Compare the emitted line against the pragma in src/ before")
        print("touching any body: a truncated function-pointer type looks exactly like this.")
    return 1 if bad else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
