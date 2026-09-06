"""Launch the game SAFELY: forced windowed, watchdog-killed, output captured.

    python scripts/play.py                 # release build, 5 minute hard cap
    python scripts/play.py --debug         # debug build -- null checks on, names the bug
    python scripts/play.py --minutes 15    # longer cap
    python scripts/play.py --forever       # no cap  (NOT RECOMMENDED -- read below)

WHY THIS EXISTS -- READ BEFORE REMOVING THE WATCHDOG
====================================================
Running the exe directly locked a machine hard enough to need a full power cycle: the game
came up covering the screen, then hung, and with it holding input focus there was no way to
reach a terminal or Task Manager to kill it. Nothing in the game guarantees it will ever
give the display or the input queue back, and a reconstruction under active repair hangs
often. A hang must never cost the user their session.

So this launcher makes two guarantees the bare exe cannot:

  WINDOWED   Settings/Options.ini is rewritten to window=1 BEFORE every launch,
             at every path the game might read one from. If none of those exist yet, one is
             created at the path TOptions.LoadOptions actually reads, rather than leaving
             the game to start from its own compiled defaults, which are not documented
             anywhere as windowed. The game rewrites that file itself via
             TOptions.SaveOptions, so a fullscreen value can come back at any time --
             checking once is not enough, it is reset on every run. If the guarantee cannot
             be confirmed on disk, this refuses to start the exe at all: a safeguard that
             launches anyway when it fails to apply is not a safeguard.
  BOUNDED    A watchdog kills the process after --minutes no matter what. Even a completely
             frozen game releases the screen on its own within the cap. This is the part
             that makes it safe to run at all.

The cap is a backstop, not a schedule -- close the window normally and this exits at once.

WHY --debug IS USUALLY THE ONE YOU WANT
=======================================
A release build strips null and bounds checks, so a null dereference is a raw memory access
that Windows kills with no message at all -- the log simply stops. The debug build keeps the
checks and prints `Unhandled Exception: Attempt to access field or method of Null object`,
which turns "it froze" into a specific defect. It runs slower; that is the whole cost.

Build it first if it is missing or stale:
    bash scripts/build_debug.sh

That script exists because `bmk makeapp -d` alone does not work here: bmk shells out
to g++ without putting its own bundled mingw on PATH, so the link dies with a bare
"Build Error: Failed to link" and no cause. It redoes only the link step.

THE DEBUG STUB DOES NOT EXIT ON A FAULT
=======================================
After an unhandled exception BlitzMax's debug stub sits in its debugger protocol loop
emitting a bare `~>` heartbeat forever. One crashed session produced an 872,000-line
log of which about forty lines mattered. The watchdog below kills the process, and the
capture drops bare heartbeats while KEEPING lines like `~>Unhandled Exception: ...`,
which carry content after the marker and are the reason for running this build.
"""
import os
import re
import sys
import time
import subprocess

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
RUNDIR = os.path.join(ROOT, "src", "assembled")
INI = os.path.join(RUNDIR, "Settings", "Options.ini")
STATUS = os.path.join(ROOT, "status")

# Display keys forced before every launch. window=1 is the one that matters; screen=0 keeps
# it off an exclusive mode switch, which is what leaves the desktop unrecoverable when the
# process dies without restoring it.
# `window` is a flag and is the only key that has to be forced: window=1 is what keeps the
# game out of exclusive fullscreen.
#
# `screen` is NOT a flag. It is an INDEX into g_gfxmodes, which TOptions.SetUp builds from
# GraphicsModes() filtered to height >= 600 and sorts ascending by width, so the list and
# therefore the meaning of any index is machine-specific. Index 0 is simply the narrowest
# mode that machine offers. The game's own TOptions.WriteNewOptionsIni writes
# `screen=` + FindRes800600(), i.e. it looks the index up rather than assuming one, and
# pinning a literal here overrides whatever resolution the player chose.
#
# So `screen` is left alone on an ini that already exists. Only when this script has to
# create one from scratch does it write SCREEN_RESOLVE, and that value is deliberately out
# of range: TOptions.LoadOptions bounds-checks with `If g_opt_screen >= g_gfxmodes.Count()`
# and falls back to FindRes800600(), so an out-of-range value makes the game resolve 800x600
# against its own mode list on any machine.
FORCE = {"window": "1", "music": "0", "soundfx": "0"}
SCREEN_RESOLVE = "99"


def ini_paths():
    """EVERY Options.ini the game might read -- not just the obvious one.

    THIS IS THE WHOLE BUG THAT COST TWO MACHINE LOCKUPS. The game does not read the
    Options.ini next to the exe. TOptions.LoadOptions reads

        ReadSettingFloat(g_userpath + "Settings/Options.ini", "window", 0, 1)

    and g_userpath resolves to the user's Documents\\New Star Soccer 5\\ -- the original
    game's real save location. Forcing window=1 in src/assembled/Settings/Options.ini
    therefore changed nothing at all, and reported "already windowed" while the file the
    game actually loaded said window=0. It came up in exclusive fullscreen at display mode
    13, hung, and held the display and input queue until a power cycle.

    So: rewrite every copy that exists. Which one wins depends on how g_userpath resolves
    at runtime, and that has already changed once during this project when the Global was
    merged -- so pinning a single path would be the same mistake again.

    When NONE of these exist, force_windowed() does not return empty-handed. It creates
    one at the Documents-based path in the loop above, because that is exactly the path
    this docstring traces g_userpath to. A missing ini is not a reason to skip the
    guarantee, it is the reason the guarantee has to create the file first.
    """
    out, seen = [], set()
    cands = [INI, os.path.join(RUNDIR, "New Star Soccer 5", "Settings", "Options.ini")]
    home = os.path.expanduser("~")
    for base in (os.path.join(home, "Documents"), home,
                 os.environ.get("APPDATA", ""), os.environ.get("LOCALAPPDATA", "")):
        if base:
            cands.append(os.path.join(base, "New Star Soccer 5", "Settings",
                                      "Options.ini"))
    for p in cands:
        rp = os.path.normcase(os.path.abspath(p))
        if rp not in seen and os.path.exists(p):
            seen.add(rp)
            out.append(p)
    return out


def force_windowed():
    """Rewrite the display keys in EVERY Options.ini, preserving other settings.

    If no Options.ini exists at any candidate path, one is created at the path
    TOptions.LoadOptions actually reads -- see the note at the end of ini_paths() above --
    so the forced keys exist before the exe ever starts instead of leaving it to boot from
    its own compiled defaults.

    Every write is read back from disk and checked before this returns, because a write
    that silently failed or landed somewhere the game does not read is exactly the failure
    that already cost two power cycles. If any candidate cannot be confirmed to hold
    window=1 on disk, this raises SystemExit instead of returning a status string
    that main() would print and launch past anyway: the whole point of this function is a
    guarantee, and a guarantee that cannot be kept must stop the launch, not report on it.
    """
    paths = ini_paths()
    created = None
    if not paths:
        target = os.path.join(os.path.expanduser("~"), "Documents", "New Star Soccer 5",
                              "Settings", "Options.ini")
        try:
            os.makedirs(os.path.dirname(target), exist_ok=True)
            # Seed the new file with an out-of-range screen index so
            # TOptions.LoadOptions resolves it through FindRes800600()
            # against this machine's own mode list.
            with open(target, "w", encoding="utf-8") as fh:
                fh.write("screen=" + SCREEN_RESOLVE + chr(10))
        except OSError as e:
            raise SystemExit(
                "REFUSING TO LAUNCH: no Options.ini exists anywhere, and one could not\n"
                "be created at %s\n"
                "  (%s)\n"
                "This launcher's only job is to guarantee the game cannot come up\n"
                "fullscreen. With no ini to force window=1 into and no way to create one,\n"
                "that guarantee cannot be made, so the exe will not start." % (target, e))
        paths = [target]
        created = target

    notes = []
    failed = []
    for path in paths:
        short = path.replace(os.path.expanduser("~"), "~")
        try:
            text = open(path, encoding="utf-8", errors="replace").read()
            changed = []
            for key, want in FORCE.items():
                rx = re.compile(r"(?mi)^(%s)\s*=\s*(.*)$" % re.escape(key))
                m = rx.search(text)
                if m:
                    if m.group(2).strip() != want:
                        changed.append("%s %s->%s" % (key, m.group(2).strip(), want))
                    text = rx.sub("%s=%s" % (key, want), text, count=1)
                else:
                    text = text.rstrip("\n") + "\n%s=%s\n" % (key, want)
                    changed.append("%s added=%s" % (key, want))
            open(path, "w", encoding="utf-8").write(text)

            # Confirm what landed on disk rather than trusting the write call. This is the
            # same class of gap that made the earlier bug invisible: the launcher reported
            # "already windowed" while the file the game actually loaded said window=0.
            check = open(path, encoding="utf-8", errors="replace").read()
            for key, want in FORCE.items():
                rx = re.compile(r"(?mi)^(%s)\s*=\s*(.*)$" % re.escape(key))
                m = rx.search(check)
                if not m or m.group(2).strip() != want:
                    raise ValueError("%s did not verify on disk (found %r)"
                                     % (key, m.group(2).strip() if m else None))
        except (OSError, ValueError) as e:
            failed.append("%s: %s" % (short, e))
            notes.append("%s [FAILED: %s]" % (short, e))
            continue

        tag = "created, " if path == created else ""
        notes.append("%s [%s%s]" % (short, tag, ", ".join(changed) if changed else "ok"))

    if failed:
        raise SystemExit(
            "REFUSING TO LAUNCH: could not guarantee windowed mode.\n"
            "  window=1 did not verify on disk for:\n"
            + "\n".join("    %s" % f for f in failed) + "\n"
            "  This launcher's only job is to guarantee the game cannot come up fullscreen,\n"
            "  and it cannot make that guarantee here, so it will not start the exe.")

    return "\n            ".join(notes)


def main():
    debug = "--debug" in sys.argv
    minutes = 5.0
    for i, a in enumerate(sys.argv):
        if a == "--minutes" and i + 1 < len(sys.argv):
            minutes = float(sys.argv[i + 1])
    cap = None if "--forever" in sys.argv else minutes * 60

    exe = os.path.join(RUNDIR,
                       "nss5_dbg.exe" if debug else "nss5_assembled.exe")
    if not os.path.exists(exe):
        raise SystemExit("no %s\n%s" % (exe, "run: bash scripts/build_debug.sh" if debug
            else "run scripts/assemble.py first"))

    os.makedirs(STATUS, exist_ok=True)
    log = os.path.join(STATUS, "play_debug.txt" if debug else "play.txt")

    print("PLAY  (%s build)" % ("DEBUG -- null checks ON" if debug else "release"))
    if debug:
        # PREFER debug_game.py FOR ANY ACTUAL DEBUGGING.
        #
        # This script captures the exception LINE and nothing else. After a fault the
        # BlitzMax debug stub prints `~>` and BLOCKS in its command loop waiting to be
        # asked; it never volunteers the stack trace or the state dump. This script does
        # not answer that prompt, so the two most valuable artefacts a crash produces are
        # thrown away. Measured on the quit crash: 3,417 captured lines, one fault
        # message, ZERO stack frames and ZERO Globals.
        #
        # debug_game.py sends the stub `t`, which makes it emit StackTrace{...} plus every
        # module Global and its value -- 1,691 of them on that same crash, which is what
        # localised it to StopChannel(Null) in the end.
        print("  NOTE: this captures the fault MESSAGE but not the stack trace or the")
        print("        Globals dump -- the debug stub waits to be asked and this script")
        print("        does not ask. For debugging use:")
        print("            python scripts/debug_game.py --minutes %g" % minutes)
    print("  display : %s" % force_windowed())
    print("  watchdog: %s" % ("NONE -- --forever was passed" if cap is None
                              else "hard kill after %g minutes" % minutes))
    print("  output  : %s" % log)
    print("  exe     : %s" % os.path.basename(exe))
    print()
    print("  Close the game window normally when done; this exits immediately after.")
    if cap is None:
        print("  !! With --forever a hang can lock the display until you power-cycle.")
    print()

    cap_file = open(log, "wb")
    p = subprocess.Popen([exe], cwd=RUNDIR, stdout=cap_file,
                         stderr=subprocess.STDOUT)
    t0 = time.time()
    killed = False
    try:
        while p.poll() is None:
            if cap is not None and time.time() - t0 > cap:
                p.kill()
                killed = True
                break
            time.sleep(0.5)
    except KeyboardInterrupt:
        p.kill()
        killed = True
    finally:
        try:
            p.wait(timeout=10)
        except Exception:
            pass
        cap_file.close()

    secs = round(time.time() - t0, 1)
    text = open(log, encoding="utf-8", errors="replace").read()

    # A bare `~>` is the debug stub's heartbeat and there can be hundreds of
    # thousands of them. A line with content AFTER the marker is a real message,
    # the Unhandled Exception line included, so match only the empty ones.
    beats = len(re.findall(r"(?m)^~>[ \t]*$", text))
    if beats:
        text = re.sub(r"(?m)^~>[ \t]*\n", "", text)
        open(log, "w", encoding="utf-8", errors="replace").write(text)
        print("  stripped %d bare heartbeat lines from the log" % beats)

    print("  ran for %ss, %s" % (secs, "KILLED by watchdog" if killed
                                 else "exited on its own (code %s)" % p.returncode))

    # The debug build's whole point: it names the fault instead of dying silently.
    hits = [l.strip() for l in text.split("\n")
            if re.search(r"Unhandled Exception|Attempt to access|EXCEPTION_", l)]
    if hits:
        print()
        print("  FAULT REPORTED BY THE RUNTIME:")
        for h in hits[:5]:
            print("    %s" % h)
    lines = [l for l in text.split("\n") if l.strip()]
    print()
    print("  last %d log lines:" % min(15, len(lines)))
    for l in lines[-15:]:
        print("    %s" % l[:150])
    if not hits and not debug:
        print()
        print("  No fault text. A release build kills silently on a null deref --")
        print("  re-run with --debug to get the actual error.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
