"""Inject a call tracer into the assembled source. Source-to-source, corpus untouched.

    python scripts/instrument_trace.py                       # trace everything
    python scripts/instrument_trace.py --filter "^TTraining" # only these
    python scripts/instrument_trace.py --arm "SetUpTraining_Pace"
    python scripts/instrument_trace.py --list                # what WOULD be instrumented

Writes src/assembled/nss5_trace.bmx and status/trace_symbols.tsv, then
`bash scripts/build_debug.sh --trace` builds it. Reads nss5_assembled.bmx and never
writes to it, so scripts/assemble.py and the byte corpus are unaffected.

WHY A SEPARATE FILE AND NOT A FLAG IN assemble.py
=================================================
assemble.py's output is the thing 1,973 verified bodies are assembled into and the thing
smoke_boot.py gates on. Adding a tracing mode to it means every future reader has to prove
the tracing path cannot affect the normal one. Reading its output and writing a different
file cannot, by construction.

WHAT YOU GET, AND WHAT YOU DO NOT
=================================
ENTRY TRACING ONLY. One `DbgTrace(id)` after each Function/Method header. Exits are not
traced, so the log is a CALL SEQUENCE, not a call tree -- you cannot read nesting depth
off it.

That is deliberate, not a shortcut. Tracing exits means injecting before every `Return` on
every path plus the implicit fall-off-the-end, in 1,854 bodies, and getting one wrong
corrupts the depth counter for the rest of the run. The two things exit tracing would buy
are already available for free and more reliably:

  * THE CALL STACK AT A FAULT -- the debug build's stub already prints a full StackTrace,
    see src/assembled/crash.log.
  * WHERE TIME GOES -- not what this is for.

What a call sequence IS good for is the thing this project actually needs: running the
same scenario twice and finding the first place the two runs diverge. That is exactly how
the byte oracle localises a defect (first_diff), lifted to runtime.

COST, AND THE TWO KNOBS THAT MAKE IT AFFORDABLE
===============================================
Instrumenting all 1,854 bodies and booting to the menu produces millions of records: the
per-frame render and update paths dominate everything else. Two knobs, and you normally
want both:

  --filter RX   Only bodies whose qualified name matches RX are instrumented. Costs
                nothing at runtime for anything excluded, because the call is not there.
  --arm RX      Tracing stays OFF until a body matching RX is first entered. The boot
                sequence is ~200k calls of noise before the interesting state; arming on
                the function that sets up the state you care about skips all of it.

`--arm` is the more important of the two. `--filter "^TTraining" --arm "SetUpTraining_Pace"`
gives a few thousand records covering exactly one training session.

CRASH SURVIVABILITY
===================
Records go to a stream flushed every 256 calls, NOT to an in-memory ring buffer. A ring is
faster and is the obvious design, but an access violation takes the process out without
unwinding and the ring dies with it -- which loses precisely the run you most wanted. The
flush bounds loss to at most 255 records at a hard crash, and those 255 are recoverable
anyway from the debug stub's StackTrace.
"""
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SRC = os.path.join(ROOT, "src", "assembled", "nss5_assembled.bmx")
OUT = os.path.join(ROOT, "src", "assembled", "nss5_trace.bmx")
SYMS = os.path.join(ROOT, "status", "trace_symbols.tsv")

# The trace file the instrumented exe writes, relative to its working directory.
# debug_game.py runs the exe with cwd=src/assembled, so this lands beside the exe.
TRACE_FILE = "trace.bin"

DECL = re.compile(r"^(\s*)(Function|Method)\s+([A-Za-z_]\w*)\s*(?::\s*[\w.\[\]]+(?:\s+Ptr)?)?\s*\(")
TYPE_DECL = re.compile(r"^\s*Type\s+([A-Za-z_]\w*)", re.I)
END_TYPE = re.compile(r"^\s*End\s*Type\b", re.I)
EXTERN_OPEN = re.compile(r"^\s*Extern\b", re.I)
EXTERN_CLOSE = re.compile(r"^\s*End\s+Extern\b", re.I)
ABSTRACT = re.compile(r"\bAbstract\s*$", re.I)
IMPORT_LINE = re.compile(r"^\s*(?:Import|Framework|SuperStrict|Strict)\b", re.I)

RUNTIME = '''
' ==================== TRACE RUNTIME (injected, not hand-written) ====================
' Written by scripts/instrument_trace.py. Every Global and Function here is prefixed
' g_dbg_/Dbg so it cannot collide with a reconstructed name.
Global g_dbg_armed:Int = %(armed)d
Global g_dbg_stream:TStream = Null
Global g_dbg_count:Int = 0
Global g_dbg_since:Int = 0

Function DbgTraceOpen()
	g_dbg_stream = WriteStream("%(tracefile)s")
	If g_dbg_stream = Null
		Print "[dbg] COULD NOT OPEN %(tracefile)s -- tracing disabled"
	Else
		Print "[dbg] tracing to %(tracefile)s  armed=" + g_dbg_armed
	EndIf
End Function

' Flush every 256 records rather than every record. An access violation does not unwind,
' so anything still in the buffer is lost; 256 bounds that loss while keeping the common
' path to one WriteInt.
Function DbgTrace(id:Int)
	If g_dbg_armed = 0 Then Return
	If g_dbg_stream = Null Then Return
	g_dbg_stream.WriteInt(id)
	g_dbg_count :+ 1
	g_dbg_since :+ 1
	If g_dbg_since >= 256
		g_dbg_since = 0
		g_dbg_stream.Flush()
	EndIf
End Function

Function DbgTraceArm()
	If g_dbg_armed = 0
		g_dbg_armed = 1
		Print "[dbg] ARMED"
	EndIf
End Function

Function DbgTraceClose()
	If g_dbg_stream <> Null
		g_dbg_stream.Flush()
		CloseStream g_dbg_stream
		g_dbg_stream = Null
	EndIf
	Print "[dbg] trace records written: " + g_dbg_count
End Function
DbgTraceOpen()
' ================== END TRACE RUNTIME ==================
'''


def argval(flag, default=None):
    if flag in sys.argv:
        i = sys.argv.index(flag)
        if i + 1 < len(sys.argv):
            return sys.argv[i + 1]
    return default


def walk(lines):
    """Yield (index, qualified_name, indent) for every instrumentable body.

    Skips Extern blocks (declarations, no body -- injecting there is a compile error) and
    Abstract methods (same reason). Tracks the enclosing Type so names are qualified:
    853 Methods across 135 Types include a great many New/Delete/Update, and an unqualified
    trace of "Update" would be unreadable.
    """
    cur_type = None
    in_extern = False
    for i, line in enumerate(lines):
        if EXTERN_OPEN.match(line) and not EXTERN_CLOSE.match(line):
            in_extern = True
            continue
        if EXTERN_CLOSE.match(line):
            in_extern = False
            continue
        mt = TYPE_DECL.match(line)
        if mt:
            cur_type = mt.group(1)
            continue
        if END_TYPE.match(line):
            cur_type = None
            continue
        if in_extern:
            continue
        m = DECL.match(line)
        if not m or ABSTRACT.search(line):
            continue
        indent, _kind, name = m.group(1), m.group(2), m.group(3)
        qual = "%s.%s" % (cur_type, name) if cur_type else name
        yield i, qual, indent


def main():
    if not os.path.exists(SRC):
        raise SystemExit("no %s -- run scripts/assemble.py first" % SRC)

    filt = argval("--filter")
    arm = argval("--arm")
    frx = re.compile(filt) if filt else None
    arx = re.compile(arm) if arm else None

    raw = open(SRC, encoding="utf-8-sig", errors="replace").read()
    lines = raw.split("\n")

    targets = [(i, q, ind) for i, q, ind in walk(lines)]
    chosen = [t for t in targets if not frx or frx.search(t[1])]
    armed_at = [t for t in chosen if arx and arx.search(t[1])]

    if arx and not armed_at:
        # Silence here would produce a run that traces NOTHING and looks like a broken
        # build rather than a bad pattern.
        raise SystemExit("--arm %r matches none of the %d selected bodies. Nothing would "
                         "ever arm and the trace would be empty.\nTry --list to see names."
                         % (arm, len(chosen)))

    if "--list" in sys.argv:
        print("%d bodies instrumentable, %d selected by --filter %r"
              % (len(targets), len(chosen), filt))
        for _i, q, _ind in chosen[:80]:
            print("   ", q, "  <-- ARMS TRACING" if arx and arx.search(q) else "")
        if len(chosen) > 80:
            print("    ... and %d more" % (len(chosen) - 80))
        return 0

    # Build the output back-to-front so earlier indices stay valid.
    ids = {}
    for n, (i, q, ind) in enumerate(chosen, start=1):
        ids[i] = (n, q, ind)
    out = []
    for i, line in enumerate(lines):
        out.append(line)
        if i in ids:
            n, q, ind = ids[i]
            body_ind = ind + "\t"
            if arx and arx.search(q):
                out.append(body_ind + "DbgTraceArm()")
            out.append(body_ind + "DbgTrace(%d)" % n)

    text = "\n".join(out)

    # The runtime goes immediately after the Import block, which makes DbgTraceOpen()
    # the first executable statement in the module -- everything above it is a directive.
    last_import = 0
    for i, line in enumerate(text.split("\n")[:200]):
        if IMPORT_LINE.match(line):
            last_import = i
    parts = text.split("\n")
    runtime = RUNTIME % {"armed": 0 if arx else 1, "tracefile": TRACE_FILE}
    parts.insert(last_import + 1, runtime)

    # Flush and report on the way out of the normal exit path.
    #
    # ANCHOR ON THE BOOT LINE, NOT ON `If g_logstream <> Null`. That condition appears
    # twice: once in the module tail, and once inside Function LogLine -- which runs on
    # every log line in the game. An unanchored .replace(..., 1) takes LogLine's copy
    # because it comes first, so DbgTraceClose() fires on the FIRST log line, closes the
    # stream, and every later DbgTrace() returns early on the Null check. Measured: a full
    # boot to the main menu produced 2 trace records instead of hundreds of thousands,
    # while printing "[dbg] trace records written: 2" once per log line. That reads as a
    # broken tracer rather than as one misplaced statement, which is why it is worth this
    # paragraph and the hard failure below.
    tail = "\n".join(parts)
    anchor = 'Print "[boot] GameMain returned"'
    if tail.count(anchor) != 1:
        raise SystemExit("expected exactly one %r to anchor DbgTraceClose(), found %d.\n"
                         "Injecting blind would silently disable the tracer."
                         % (anchor, tail.count(anchor)))
    tail = tail.replace(anchor, anchor + "\nDbgTraceClose()", 1)

    os.makedirs(os.path.dirname(SYMS), exist_ok=True)
    with open(OUT, "w", encoding="utf-8", newline="") as f:
        f.write(tail)
    with open(SYMS, "w", encoding="utf-8", newline="") as f:
        f.write("# id\tqualified_name\n")
        for i, q, _ind in chosen:
            f.write("%d\t%s\n" % (ids[i][0], q))

    print("instrumented %d of %d bodies" % (len(chosen), len(targets)))
    if filt:
        print("  --filter %r" % filt)
    if arm:
        print("  --arm    %r  -> arms at %d site(s): %s"
              % (arm, len(armed_at), ", ".join(q for _i, q, _n in armed_at[:5])))
    else:
        print("  tracing starts ARMED (no --arm given): expect a very large trace")
    print("  wrote %s" % os.path.relpath(OUT, ROOT))
    print("  wrote %s" % os.path.relpath(SYMS, ROOT))
    print()
    print("next:")
    print("  bash scripts/build_debug.sh --trace")
    print("  python scripts/debug_game.py --trace")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
