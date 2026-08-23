"""Run the game under full instrumentation and keep everything it produced.

    python scripts/debug_game.py                      # debug build, watchdog, capture all
    python scripts/debug_game.py --trace              # the instrumented build
    python scripts/debug_game.py --release            # release build (rarely what you want)
    python scripts/debug_game.py --minutes 15
    python scripts/debug_game.py --detach             # leave it running for Ghidra, safely
    python scripts/debug_game.py --stop               # kill a detached run
    python scripts/debug_game.py --show LAST          # re-print a run's summary
    python scripts/debug_game.py --globals-diff A B   # what state differs between two runs

WHAT THIS ADDS OVER play.py
===========================
play.py's job is to make running the game SAFE -- forced windowed, hard watchdog -- and it
does that well enough that this script calls straight into it rather than reimplementing it.
What play.py does not do is KEEP anything: it prints a tail to the terminal and the evidence
is gone with the scrollback. Every run here lands in status/debugruns/<timestamp>/ with:

    stdout.txt     the game's own LogLine output, from the first instruction
    stderr.txt     the debug stub's stream -- the exception and the StackTrace live here
    log.txt        the game's own log file, if it got far enough to flush one
    trace.bin      the call trace, if this was a --trace build
    trace.txt      that trace decoded to names, most recent call LAST
    globals.tsv    every Global and its value at the fault  (see below -- this is free)
    summary.txt    everything below, so a run can be read without re-running it

THE FREE STATE SNAPSHOT NOBODY WAS COLLECTING
=============================================
On an unhandled exception BlitzMax's debug stub prints, after the StackTrace, EVERY module
Global with its value:

    Global g_activeball:TBall=Null
    Global g_achievements:TList=$03537d40

That is a complete dump of program state at the moment of the fault -- 2,512 of them in the
crash.log already sitting in src/assembled/ -- and it costs nothing because the runtime does
it anyway. This script parses it into a TSV so it can be diffed.

WHY THE DIFF NORMALISES POINTERS, AND WHY THAT IS THE WHOLE TRICK
=================================================================
Diffing two runs' globals raw is useless: every heap pointer differs between runs, so
essentially every object-typed Global shows as changed and the real signal drowns. But the
DISTINCTION THAT MATTERS is not the address, it is whether the thing exists:

    Null  ->  $03537d40      something got allocated
    $0353 ->  Null           something got torn down
    $0353 ->  $03a1c220      nothing meaningful; noise

So --globals-diff compares a CLASSIFICATION (null / allocated / scalar value) rather than
the raw text, and reports scalar Globals by exact value. This is precisely the shape of the
bug that has already cost this project two days: g_currentscreen and g_curscreen were one
address under two names, the reader always saw Null, and the boot died. A null-vs-allocated
diff against a working reference run names that class of defect immediately.

DETACHED RUNS AND THE SAFETY GUARANTEE
======================================
--detach leaves the game running so the Ghidra MCP debugger can attach to it, and prints the
PID to attach to. It does NOT drop play.py's guarantee: it spawns an independent watchdog
process that kills the game after the cap even if this script is long gone. A detached game
with no watchdog is exactly the scenario that cost two power cycles, so it is not offered.
"""
import os
import re
import sys
import time
import json
import struct
import shutil
import subprocess
import datetime

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import play  # noqa: E402  -- force_windowed(); see play.py for why it must not be bypassed

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
RUNDIR = os.path.join(ROOT, "src", "assembled")
RUNS = os.path.join(ROOT, "status", "debugruns")
SYMS = os.path.join(ROOT, "status", "trace_symbols.tsv")
PIDFILE = os.path.join(ROOT, "status", "debug_game.pid")
# status/ is gitignored, so it does not exist in a fresh clone and the PID file
# write is the first thing this does. Create it once, here, rather than at each use.
os.makedirs(RUNS, exist_ok=True)

# EVERY LINE THE DEBUG STUB EMITS IS PREFIXED `~>`. That includes the StackTrace frames and
# all ~2,500 Global lines. Anchoring on ^Global therefore matches NOTHING and the whole state
# dump is silently discarded -- measured: a real crash produced 1,691 Global lines in
# stderr.txt while this script reported "globals: 0 captured". The prefix is stripped in
# parse_globals() before matching; keep it out of the pattern itself so the pattern still
# works on a hand-saved log someone has already cleaned up.
GLOBAL_RX = re.compile(r"^Global\s+([A-Za-z_]\w*)\s*:\s*(.+?)\s*=\s*(.*)$")
STUB_PREFIX = re.compile(r"^~>")
PTR_RX = re.compile(r"^\$[0-9a-fA-F]+$")
FAULT_RX = re.compile(r"Unhandled Exception|Attempt to access|EXCEPTION_|Access Violation",
                      re.I)


def argval(flag, default=None):
    if flag in sys.argv:
        i = sys.argv.index(flag)
        if i + 1 < len(sys.argv):
            return sys.argv[i + 1]
    return default


# ------------------------------------------------------------------ globals snapshot
def classify(value):
    """Raw dumped value -> (class, comparable). See the docstring on pointer normalising."""
    v = value.strip()
    if v == "Null":
        return "null", "null"
    if PTR_RX.match(v):
        return "alloc", "alloc"          # address itself is noise across runs
    return "scalar", v


def parse_globals(stderr_text):
    out = {}
    for line in stderr_text.split("\n"):
        m = GLOBAL_RX.match(STUB_PREFIX.sub("", line.strip()))
        if m:
            name, ty, val = m.group(1), m.group(2), m.group(3)
            cls, cmpv = classify(val)
            out[name] = (ty, val, cls, cmpv)
    return out


def write_globals_tsv(path, g):
    with open(path, "w", encoding="utf-8", newline="") as f:
        f.write("# name\ttype\traw_value\tclass\tcomparable\n")
        for k in sorted(g):
            ty, val, cls, cmpv = g[k]
            f.write("%s\t%s\t%s\t%s\t%s\n" % (k, ty, val, cls, cmpv))


def read_globals_tsv(path):
    g = {}
    for line in open(path, encoding="utf-8", errors="replace"):
        if line.startswith("#") or not line.strip():
            continue
        p = line.rstrip("\n").split("\t")
        if len(p) >= 5:
            g[p[0]] = (p[1], p[2], p[3], p[4])
    return g


# ------------------------------------------------------------------ trace decode
def load_symbols():
    syms = {}
    if not os.path.exists(SYMS):
        return syms
    for line in open(SYMS, encoding="utf-8", errors="replace"):
        if line.startswith("#") or not line.strip():
            continue
        p = line.rstrip("\n").split("\t")
        if len(p) >= 2:
            syms[int(p[0])] = p[1]
    return syms


# Records decoded into trace.txt. The .bin keeps everything; this caps only the text view.
#
# MEASURED, and the reason this constant exists: a 21-second boot to the main menu with all
# 1,854 bodies instrumented produced 40,957,952 records -- 164MB of .bin and, before this
# cap, a 734MB trace.txt. 857MB for one 21-second run of a game sitting idle on its menu.
# The per-frame gadget update path (TGadget.UpdateChildren / UpdateToolTip / TButton.Update)
# accounts for almost all of it.
#
# So: full instrumentation is a CAPABILITY CHECK, not a working configuration. Real use is
# --filter and --arm, which cut this by three or four orders of magnitude. The cap keeps an
# un-filtered run merely large instead of filling the disk.
TRACE_TEXT_CAP = 200000


def decode_trace(binpath, outpath, tail=None):
    """trace.bin (little-endian int32 ids) -> names, most recent LAST. Returns (n, [tail])."""
    if not os.path.exists(binpath):
        return 0, []
    syms = load_symbols()
    raw = open(binpath, "rb").read()
    n = len(raw) // 4
    ids = struct.unpack("<%di" % n, raw[:n * 4]) if n else ()
    keep = ids[-TRACE_TEXT_CAP:] if n > TRACE_TEXT_CAP else ids
    first = n - len(keep)
    names = [syms.get(i, "id_%d" % i) for i in keep]
    with open(outpath, "w", encoding="utf-8", newline="") as f:
        f.write("# %d records total, most recent LAST. ENTRY trace: sequence, not nesting.\n" % n)
        if first:
            f.write("# TRUNCATED: showing the last %d only. The full sequence is in "
                    "trace.bin.\n" % len(keep))
            f.write("# Use --filter/--arm on instrument_trace.py to make a run this large "
                    "unnecessary.\n")
        for i, nm in enumerate(names, start=first):
            f.write("%d\t%s\n" % (i, nm))
    k = tail or 40
    return n, names[-k:]


# ------------------------------------------------------------------ run collection
def collect(rundir, stdout_path, stderr_path, traced, secs, killed, rc):
    os.makedirs(rundir, exist_ok=True)
    out_text = open(stdout_path, encoding="utf-8", errors="replace").read()
    err_text = open(stderr_path, encoding="utf-8", errors="replace").read()

    # The debug stub emits a bare `~>` heartbeat forever after a fault; one session made
    # 872,000 of them. Drop the empty ones, keep any line with content after the marker.
    beats = len(re.findall(r"(?m)^~>[ \t]*$", err_text))
    if beats:
        err_text = re.sub(r"(?m)^~>[ \t]*\n", "", err_text)

    shutil.copyfile(stdout_path, os.path.join(rundir, "stdout.txt"))
    open(os.path.join(rundir, "stderr.txt"), "w", encoding="utf-8",
         errors="replace", newline="").write(err_text)
    for extra in ("log.txt",):
        src = os.path.join(RUNDIR, extra)
        if os.path.exists(src):
            shutil.copyfile(src, os.path.join(rundir, extra))

    g = parse_globals(err_text)
    if g:
        write_globals_tsv(os.path.join(rundir, "globals.tsv"), g)

    ntrace, tail = 0, []
    if traced:
        src = os.path.join(RUNDIR, "trace.bin")
        if os.path.exists(src):
            shutil.copyfile(src, os.path.join(rundir, "trace.bin"))
            ntrace, tail = decode_trace(os.path.join(rundir, "trace.bin"),
                                        os.path.join(rundir, "trace.txt"))

    faults = [l.strip() for l in (out_text + "\n" + err_text).split("\n")
              if FAULT_RX.search(l)]
    stack = []
    m = re.search(r"StackTrace\{(.*?)(?:\n\}|Global )", err_text, re.S)
    if m:
        stack = [l for l in m.group(1).split("\n") if l.strip()][:25]

    loglines = [l for l in out_text.split("\n") if l.strip()]

    lines = []
    lines.append("run       : %s" % os.path.basename(rundir))
    lines.append("exit      : %s after %ss" % (
        "KILLED by watchdog" if killed else "exited on its own (code %s)" % rc, secs))
    lines.append("globals   : %d captured" % len(g))
    if traced:
        mb = os.path.getsize(os.path.join(rundir, "trace.bin")) / 1048576.0 \
            if os.path.exists(os.path.join(rundir, "trace.bin")) else 0.0
        lines.append("trace     : %d records, %.1fMB" % (ntrace, mb))
        if ntrace > 2000000:
            lines.append("            ^ that is an UNFILTERED trace and it is mostly the")
            lines.append("              per-frame gadget update loop. Re-instrument with")
            lines.append("              --filter / --arm before drawing conclusions from it.")
    else:
        lines.append("trace     : not a --trace build")
    lines.append("")
    if faults:
        lines.append("FAULT:")
        for f in faults[:6]:
            lines.append("   " + f[:200])
        lines.append("")
    if stack:
        lines.append("STACK (from the debug stub):")
        for s in stack:
            lines.append("   " + s.rstrip()[:200])
        lines.append("")
    if tail:
        lines.append("LAST %d CALLS BEFORE EXIT (most recent last):" % len(tail))
        for t in tail:
            lines.append("   " + t)
        lines.append("")
    lines.append("LAST 20 LOG LINES:")
    for l in loglines[-20:]:
        lines.append("   " + l[:200])
    if not faults:
        lines.append("")
        lines.append("No fault text found. If the game vanished with no message this was")
        lines.append("probably a RELEASE build -- it strips null checks and dies silently.")
        lines.append("Re-run without --release.")

    text = "\n".join(lines)
    open(os.path.join(rundir, "summary.txt"), "w", encoding="utf-8",
         errors="replace", newline="").write(text)
    json.dump({"run": os.path.basename(rundir), "killed": killed, "rc": rc,
               "seconds": secs, "globals": len(g), "trace_records": ntrace,
               "faults": faults[:6]},
              open(os.path.join(rundir, "run.json"), "w", encoding="utf-8"), indent=1)
    return text


def latest_run():
    if not os.path.isdir(RUNS):
        return None
    ds = sorted(d for d in os.listdir(RUNS) if os.path.isdir(os.path.join(RUNS, d)))
    return os.path.join(RUNS, ds[-1]) if ds else None


def resolve_run(token):
    if token.upper() == "LAST":
        return latest_run()
    p = token if os.path.isdir(token) else os.path.join(RUNS, token)
    return p if os.path.isdir(p) else None


# ------------------------------------------------------------------ globals diff
def globals_diff(a_tok, b_tok):
    a_dir, b_dir = resolve_run(a_tok), resolve_run(b_tok)
    if not a_dir or not b_dir:
        raise SystemExit("could not resolve both runs (%r -> %s, %r -> %s)"
                         % (a_tok, a_dir, b_tok, b_dir))
    pa = os.path.join(a_dir, "globals.tsv")
    pb = os.path.join(b_dir, "globals.tsv")
    for p in (pa, pb):
        if not os.path.exists(p):
            raise SystemExit("%s has no globals.tsv -- that run did not fault, so the "
                             "debug stub never dumped state." % os.path.dirname(p))
    A, B = read_globals_tsv(pa), read_globals_tsv(pb)

    only_a = sorted(set(A) - set(B))
    only_b = sorted(set(B) - set(A))
    changed = [(k, A[k], B[k]) for k in sorted(set(A) & set(B))
               if A[k][3] != B[k][3]]

    print("GLOBAL STATE DIFF")
    print("  A = %s   (%d globals)" % (os.path.basename(a_dir), len(A)))
    print("  B = %s   (%d globals)" % (os.path.basename(b_dir), len(B)))
    print()
    print("  Raw pointer values are NORMALISED -- they differ every run and mean nothing.")
    print("  What is compared: null vs allocated vs exact scalar value.")
    print()
    if only_a:
        print("  ONLY IN A (%d): %s" % (len(only_a), ", ".join(only_a[:12])))
    if only_b:
        print("  ONLY IN B (%d): %s" % (len(only_b), ", ".join(only_b[:12])))
    if not changed:
        print("  NO MEANINGFUL DIFFERENCES.")
        return 0

    # A Global that is allocated in one run and Null in the other is the highest-value
    # signal this tool produces -- it is the g_curscreen failure mode exactly.
    lifecycle = [c for c in changed if "null" in (c[1][3], c[2][3])]
    scalar = [c for c in changed if c not in lifecycle]

    print("  %d differ.  %d are null/allocated LIFECYCLE differences (look here first):"
          % (len(changed), len(lifecycle)))
    print()
    print("  %-38s %-22s %-12s %s" % ("GLOBAL", "TYPE", "A", "B"))
    for k, a, b in lifecycle:
        print("  %-38s %-22s %-12s %s" % (k[:38], a[0][:22], a[3], b[3]))
    if scalar:
        print()
        print("  %d scalar value differences:" % len(scalar))
        for k, a, b in scalar[:60]:
            print("  %-38s %-22s %-12s %s" % (k[:38], a[0][:22], a[3][:12], b[3][:40]))
        if len(scalar) > 60:
            print("  ... and %d more (see globals.tsv in each run)" % (len(scalar) - 60))
    return 0


# ------------------------------------------------------------------ detach / stop
def spawn_watchdog(pid, cap):
    """An independent process that kills `pid` after `cap` seconds.

    The whole reason --detach is allowed to exist. It must outlive this script, so it is
    spawned fully detached rather than as a child.
    """
    code = ("import os,sys,time,subprocess;"
            "time.sleep(%f);"
            "subprocess.run(['taskkill','/F','/T','/PID','%d'],"
            "capture_output=True)" % (cap, pid))
    flags = 0
    if os.name == "nt":
        flags = getattr(subprocess, "DETACHED_PROCESS", 0x00000008) | \
                getattr(subprocess, "CREATE_NEW_PROCESS_GROUP", 0x00000200)
    subprocess.Popen([sys.executable, "-c", code], creationflags=flags,
                     stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL,
                     stdin=subprocess.DEVNULL, close_fds=True)


def do_stop():
    if not os.path.exists(PIDFILE):
        print("no detached run recorded at %s" % PIDFILE)
        return 1
    pid = int(open(PIDFILE).read().strip())
    r = subprocess.run(["taskkill", "/F", "/T", "/PID", str(pid)],
                       capture_output=True, text=True)
    print((r.stdout or r.stderr).strip())
    os.remove(PIDFILE)
    return 0


# ------------------------------------------------------------------ main
def main():
    if "--stop" in sys.argv:
        return do_stop()
    if "--globals-diff" in sys.argv:
        i = sys.argv.index("--globals-diff")
        if i + 2 >= len(sys.argv):
            raise SystemExit("--globals-diff wants two runs, e.g. --globals-diff LAST 20260822-193000")
        return globals_diff(sys.argv[i + 1], sys.argv[i + 2])
    if "--show" in sys.argv:
        d = resolve_run(argval("--show", "LAST") or "LAST")
        if not d:
            raise SystemExit("no runs in %s" % RUNS)
        print(open(os.path.join(d, "summary.txt"), encoding="utf-8",
                   errors="replace").read())
        return 0

    traced = "--trace" in sys.argv
    release = "--release" in sys.argv
    detach = "--detach" in sys.argv
    minutes = float(argval("--minutes", "5"))
    cap = minutes * 60

    exe = os.path.join(RUNDIR, "nss5_trace.exe" if traced else
                       ("nss5_assembled.exe" if release else "nss5_dbg.exe"))
    if not os.path.exists(exe):
        hint = ("python scripts/instrument_trace.py && bash scripts/build_debug.sh --trace"
                if traced else ("python scripts/assemble.py" if release
                                else "bash scripts/build_debug.sh"))
        raise SystemExit("no %s\nbuild it with:\n  %s" % (exe, hint))

    stamp = datetime.datetime.now().strftime("%Y%m%d-%H%M%S")
    rundir = os.path.join(RUNS, stamp)
    os.makedirs(rundir, exist_ok=True)

    # Clear the previous trace so a build that writes nothing is not mistaken for a run
    # that reused stale data.
    tb = os.path.join(RUNDIR, "trace.bin")
    if traced and os.path.exists(tb):
        os.remove(tb)

    print("DEBUG RUN  %s" % stamp)
    print("  exe     : %s" % os.path.basename(exe))
    print("  display : %s" % play.force_windowed())
    print("  watchdog: hard kill after %g minutes" % minutes)
    print("  output  : %s" % os.path.relpath(rundir, ROOT))
    print()

    so = open(os.path.join(rundir, "_stdout.raw"), "wb")
    se = open(os.path.join(rundir, "_stderr.raw"), "wb")
    # stdin MUST be a pipe: on a fault the debug stub does not volunteer anything, it sits
    # at a `~>` prompt waiting to be asked. See ask_for_stack_trace().
    p = subprocess.Popen([exe], cwd=RUNDIR, stdout=so, stderr=se, stdin=subprocess.PIPE)

    if detach:
        open(PIDFILE, "w").write(str(p.pid))
        spawn_watchdog(p.pid, cap)
        print("  DETACHED.  pid = %d" % p.pid)
        print()
        print("  Attach the Ghidra MCP debugger to that pid for one-off inspection.")
        print("  An independent watchdog will kill it after %g minutes even if this" % minutes)
        print("  script is gone. To end it now and collect the run:")
        print("      python scripts/debug_game.py --stop")
        print("  Then collect with:  python scripts/debug_game.py --show LAST")
        return 0

    t0 = time.time()
    killed = False
    asked = False
    err_path = os.path.join(rundir, "_stderr.raw")
    out_path = os.path.join(rundir, "_stdout.raw")

    def seen_fault():
        for pth in (err_path, out_path):
            try:
                with open(pth, "rb") as fh:
                    if FAULT_RX.search(fh.read().decode("utf-8", "replace")):
                        return True
            except OSError:
                pass
        return False

    try:
        while p.poll() is None:
            if time.time() - t0 > cap:
                p.kill()
                killed = True
                break
            # THE STUB WILL NOT VOLUNTEER THE CRASH STATE -- IT WAITS TO BE ASKED.
            #
            # After an unhandled exception BlitzMax's debug stub prints `~>` and blocks on
            # its command loop. A passive log reader therefore captures the exception line
            # and then nothing but heartbeats, which is exactly what
            # status/play_debug.txt showed for the quit crash: 3,417 lines, one fault
            # message, zero stack frames and zero Globals.
            #
            # Sending `t` makes it emit StackTrace{ ... } via DumpScopeStack -- the stack
            # AND every module Global with its value. That is the whole state snapshot this
            # script's --globals-diff is built on, and without this it was never being
            # produced. (See the stub's command loop in
            # tools/blitzmax-legacy-src/mod/brl.mod/appstub.mod/debugger.stdio.bmx.)
            if not asked and seen_fault():
                asked = True
                print("  fault detected -- asking the debug stub for a stack trace")
                try:
                    p.stdin.write(b"t\n")
                    p.stdin.flush()
                except (OSError, ValueError):
                    print("  (could not reach the stub's stdin; it may already be gone)")
                # Give DumpScopeStack time to walk the scope stack and ~2,500 Globals.
                time.sleep(3.0)
                p.kill()
                killed = True
                break
            time.sleep(0.4)
    except KeyboardInterrupt:
        p.kill()
        killed = True
    finally:
        try:
            p.wait(timeout=10)
        except Exception:                                            # noqa: BLE001
            pass
        so.close()
        se.close()

    secs = round(time.time() - t0, 1)
    text = collect(rundir, os.path.join(rundir, "_stdout.raw"),
                   os.path.join(rundir, "_stderr.raw"), traced, secs, killed, p.returncode)
    for junk in ("_stdout.raw", "_stderr.raw"):
        try:
            os.remove(os.path.join(rundir, junk))
        except OSError:
            pass
    print(text)
    print()
    print("  kept in %s" % os.path.relpath(rundir, ROOT))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
