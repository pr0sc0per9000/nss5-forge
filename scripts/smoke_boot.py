"""Boot the game briefly, kill it, and report how far it got.

    python scripts/smoke_boot.py            # 20s boot, then kill
    python scripts/smoke_boot.py 40         # longer

WHY
===
Two startup crashes in a row reached the user before they reached me, and both were
mechanically detectable after the fact but not before: an out-of-bounds array WRITE
(g_kitfiles String[1] indexed to 25, g_fansimg TImage[6] indexed to 9). Static analysis
now catches that specific class -- see check_array_bounds.py -- but "does it actually get
to the menu" is not something any static check answers.

This does. It launches the release build, lets it run for a fixed number of seconds, kills
it, and reports the tail of log.txt plus whether the process died on its own. A process
that exits BEFORE the timeout crashed; one still running when the timer fires booted.

WHY IT IS SAFE TO RUN UNATTENDED
================================
The game is full of modal loops -- TScreen.DoMessage, DoProgressBar, the Options language
rebuild -- that spin waiting for input that never comes. An automated click-sweep hit
exactly that and blocked for ten minutes needing a human to kill it. This never interacts:
it starts the process, waits, and kills it. There is nothing to block on.

WINDOWED MODE IS FORCED, VIA play.force_windowed(), BEFORE THE PROCESS STARTS.
An earlier version of this script relied on Settings/Options.ini next to the exe being
window=1. The game does not read that file. TOptions.LoadOptions reads
g_userpath + "Settings/Options.ini", which resolves to the user's Documents directory, so
the copy next to the exe had no effect at all. The game came up in exclusive fullscreen,
hung holding the display and the input queue, and the machine needed a power cycle. Twice.
play.force_windowed() rewrites every copy that exists, which is the only safe approach
because which one wins depends on how g_userpath resolves at runtime.

WHAT THE MARKERS MEAN
=====================
LogLine() writes progress to log.txt throughout start-up, so the last line before a crash
localises the failure to a specific load step. That is how both crashes above were found:
"unable to locate language file" pointed at the install-path prefix, and
"Load variable: basemask" pointed at TKit.SetUp's 26 writes into a 1-element array.
"""
import os
import re
import sys
import time
import subprocess

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import play  # noqa: E402  -- for force_windowed(); see WHY IT IS SAFE above

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
RUNDIR = os.path.join(ROOT, "src", "assembled")
EXE = os.path.join(RUNDIR, "nss5_assembled.exe")
LOG = os.path.join(RUNDIR, "log.txt")

# Ordered start-up milestones, matched against the process's own stdout.
#
# LogLine() writes to BOTH log.txt and stdout, but log.txt is opened late and buffered, so
# a crash before the stream is flushed leaves it empty -- an earlier version of this script
# read only log.txt and reported "milestones reached: none" for a run that had in fact
# booted all the way to the menu. stdout is captured from the first instruction.
#
# The last two markers are the ones that matter. "ScreensAllCreated" means every screen's
# CreateScreen ran without dying, and "SetActive:mainmenu" means the game handed control to
# the menu -- i.e. a complete, successful boot.
MARKERS = [
    ("settings read", r"saveloc|Settings/|\[boot\]"),
    ("language file loaded", r"Load variable:|Languages\.csv"),
    ("kits set up", r"basemask|baseshirt"),
    ("engine media loaded", r"EngineMedia"),
    ("game media loaded", r"GameMedia"),
    ("sounds loaded", r"Sound loaded"),
    ("screens created", r"Create Screen:"),
    ("ALL screens created", r"ScreensAllCreated"),
    ("MAIN MENU reached", r"SetActive:mainmenu"),
]


def main():
    secs = 20
    for a in sys.argv[1:]:
        if a.isdigit():
            secs = int(a)
    if not os.path.exists(EXE):
        raise SystemExit("no %s -- run scripts/assemble.py first" % EXE)

    # Never start the exe without this. See WINDOWED MODE above.
    print("  display : %s" % play.force_windowed())

    before = os.path.getsize(LOG) if os.path.exists(LOG) else 0
    cap = open(os.path.join(ROOT, "status", "smoke_stdout.txt"), "wb")
    p = subprocess.Popen([EXE], cwd=RUNDIR, stdout=cap, stderr=subprocess.STDOUT)
    died_at = None
    t0 = time.time()
    while time.time() - t0 < secs:
        if p.poll() is not None:
            died_at = round(time.time() - t0, 1)
            break
        time.sleep(0.5)
    alive = p.poll() is None
    if alive:
        p.kill()
        p.wait(timeout=10)
    cap.close()
    # stdout is the reliable stream -- see MARKERS. log.txt is a secondary source.
    text = open(os.path.join(ROOT, "status", "smoke_stdout.txt"),
                encoding="utf-8", errors="replace").read()
    out = b""
    if os.path.exists(LOG):
        with open(LOG, encoding="utf-8", errors="replace") as f:
            f.seek(before)
            text += "\n" + f.read()

    print("SMOKE BOOT  (%ds budget)" % secs)
    if alive:
        print("  RESULT : still running at %ds -- booted, killed by this script" % secs)
    else:
        print("  RESULT : PROCESS DIED on its own after %ss  (exit %s)"
              % (died_at, p.returncode))
    print("  log grew by %d bytes" % len(text))

    reached = [name for name, rx in MARKERS if re.search(rx, text, re.I)]
    print("  milestones reached : %s" % (", ".join(reached) if reached else "none"))
    missed = [n for n, _ in MARKERS if n not in reached]
    if missed:
        print("  not reached        : %s" % ", ".join(missed))

    lines = [l for l in text.split("\n") if l.strip()]
    print()
    print("  last %d log lines:" % min(12, len(lines)))
    for l in lines[-12:]:
        print("    %s" % l[:150])
    if out.strip():
        print()
        print("  stdout/stderr tail:")
        for l in out.decode("utf-8", "replace").split("\n")[-8:]:
            if l.strip():
                print("    %s" % l[:150])
    return 0 if alive else 1


if __name__ == "__main__":
    raise SystemExit(main())
