"""Installer for the New Star Soccer 5 reconstruction.

WHAT THIS SHIPS, AND WHAT IT NEVER SHIPS
========================================
It ships tooling. It never ships the game.

There is no NSS5.exe, no GameMedia and no reconstructed build inside this installer or
inside any release of it. Every byte of the game comes off the user's own Steam install
at install time, and the playable exe is compiled on their machine from source. Remove
that property and this stops being a build tool and starts being a redistribution of a
commercial product that is still on sale. Nothing in here may cross that line.

WHAT IT ACTUALLY DOES
=====================
Four steps, in order, each refusing to start until the one before it passed:

  1. FIND      locate the Steam install of New Star Soccer 5
  2. VERIFY    checksum it against binary/checksums.json, so a wrong or modified copy
               is named as such rather than producing a confusing build failure later
  3. TOOLCHAIN make sure bcc, bmk and MinGW are present, and say exactly what is missing
  4. BUILD     scripts/setup.py, then scripts/assemble.py

Steps 1, 2 and 4 are already implemented by scripts/setup.py. This module imports it
rather than reimplementing it: two copies of Steam-library parsing would drift, and
setup.py's is the one the rest of the project is tested against.

Step 3 is the one this installer exists for. `git clone` of BlitzMax gets you the
compiler's SOURCE. It ships no bcc.exe, no bmk.exe and no unpacked MinGW, so the
documented path asks a player to build a 2010s compiler from source before they can
play a football game. Nobody does that, so installer/toolchain.py fetches and installs
it instead. Nothing of the toolchain is redistributed here; that module explains why.

RUNNING IT
==========
    python installer/nss5_setup.py            # window
    python installer/nss5_setup.py --cli       # same steps, text only
    python installer/nss5_setup.py --check     # steps 1-3 only, changes nothing

--check is the safe one. It never writes, never builds and never launches the game, so
it is what to ask a bug reporter for.

BUILDING THE EXECUTABLE
=======================
play_launcher.py builds first and is then bundled as data, because the installer writes
play.exe out beside source_code:

    pyinstaller --onefile --noconsole --name play installer/play_launcher.py
    pyinstaller --onefile --noconsole --name "Install New Star Soccer 5" \\
        --add-data "scripts;scripts" --add-data "src;src" \\
        --add-data "extracted;extracted" --add-data "extern;extern" \\
        --add-data "binary/checksums.json;binary" --add-data "dist/play.exe;." \\
        --paths installer --hidden-import gui --hidden-import toolchain \\
        --hidden-import uuid --hidden-import csv --hidden-import hashlib ... \\
        installer/nss5_setup.py

The hidden imports are not optional. scripts/ travels as DATA, so PyInstaller never
analyses it and bundles none of what it imports. Pass every module the tree imports, or
the build dies on the first one missing. Collect them with ast over scripts/*.py.

Do not add binary/ as a directory. A working checkout has NSS5.exe in it.
"""

import io
import os
import sys
import shutil
import runpy
import subprocess


# ---------------------------------------------------------------- frozen exe

FROZEN = getattr(sys, "frozen", False)


def _python_passthrough():
    """Let the frozen exe stand in for python.exe, and exit if it just did.

    A PyInstaller build has no python.exe, and sys.executable is this installer. That
    breaks the build in two places at once: run_script() would relaunch the installer
    instead of running a script, and worse, scripts/setup.py itself shells out to
    [sys.executable, <script>] when it derives extracted/, so it would fork installers.

    So: if the first argument is a .py file, run it and exit. sys.executable then behaves
    like an interpreter for anything that calls it that way, including setup.py, without
    setup.py needing to know this installer exists.
    """
    if len(sys.argv) > 1 and sys.argv[1].lower().endswith(".py"):
        script = sys.argv[1]
        if os.path.isfile(script):
            sys.argv = sys.argv[1:]
            sys.path.insert(0, os.path.dirname(os.path.abspath(script)))
            try:
                runpy.run_path(script, run_name="__main__")
            except SystemExit as e:
                raise SystemExit(e.code)
            raise SystemExit(0)


_python_passthrough()


# BUNDLE is where the shipped copy of the reconstruction lives: inside the exe when
# frozen, the repository itself when running from source.
# ROOT is the tree the build actually happens in. Those differ when frozen, because
# PyInstaller unpacks to a temporary directory that is deleted on exit, and a build
# written there would vanish with it.
# The folder the player picks holds three things and nothing else:
#
#     source_code/   the reconstruction, and where the build happens
#     play.exe       starts the game
#     README.txt     how to play it and how to report a bug
#
# INSTALL_DIR is that folder. ROOT is the tree the build runs in, which is source_code
# inside it. Running from source there is no installation: the repository is the tree.
SOURCE_DIRNAME = "source_code"

if FROZEN:
    BUNDLE = sys._MEIPASS
    # Only a suggestion. The player picks, so these are not constants: set_install_root()
    # moves them and everything downstream reads them at call time.
    DEFAULT_INSTALL_DIR = os.path.join(os.path.expanduser("~"), "New Star Soccer 5")
    INSTALL_DIR = DEFAULT_INSTALL_DIR
    ROOT = os.path.join(INSTALL_DIR, SOURCE_DIRNAME)
else:
    BUNDLE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    DEFAULT_INSTALL_DIR = BUNDLE
    INSTALL_DIR = BUNDLE
    ROOT = BUNDLE

SCRIPTS = os.path.join(ROOT, "scripts")


def set_install_root(path):
    """Choose the folder the game is installed into.

    Ignored when running from source, where the repository is already the tree and
    moving it would build a copy of the checkout somewhere else.
    """
    global INSTALL_DIR, ROOT, SCRIPTS
    if not FROZEN:
        return INSTALL_DIR
    INSTALL_DIR = os.path.abspath(path)
    ROOT = os.path.join(INSTALL_DIR, SOURCE_DIRNAME)
    SCRIPTS = os.path.join(ROOT, "scripts")
    return INSTALL_DIR


README_TEXT = """New Star Soccer 5
=================

HOW TO PLAY
-----------
Double-click play.exe.

That is all. The game was built on this machine from your own copy of New Star
Soccer 5, so it starts straight away.

If a window does not appear, wait a few seconds. The first start is the slowest.


WHAT IS IN THIS FOLDER
----------------------
play.exe        starts the game
source_code/    the source the game was built from
README.txt      this file

The game itself is not in this folder and is not given away by this project. It
was read from the copy of New Star Soccer 5 you already own on Steam.


WHAT THIS IS
------------
This is a rebuild of New Star Soccer 5 from its own program file back into
source code. The aim is to match the original exactly.

    https://github.com/pr0sc0per9000/nss5-forge


IF SOMETHING GOES WRONG
-----------------------
Please tell us. Bugs are only found when someone says what happened.

Report one here:

    https://github.com/pr0sc0per9000/nss5-forge/issues/new

A good report says four things:

    1. Where it happened. "After I accepted my first contract."
    2. What the original game does instead.
    3. What you saw. A screenshot helps.
    4. Whether it happens every time.

If the game closed on its own, there is a log that helps a lot. Find it at:

    source_code/status/debugruns/

Open the newest folder in there and attach stderr.txt to your report.
"""

# What a build needs out of the repository. Everything here is this project's own work.
#
# NO GAME CONTENT IS IN THIS LIST AND NONE MAY EVER BE ADDED TO IT. The game arrives from
# the player's own install, at install time, and never from us.
#
# Note what is NOT here: binary/. A working checkout has NSS5.exe, steamstub.dll and
# IRClipboardFunctions.dll sitting in it, put there by setup.py from the player's own
# Steam copy. Shipping that directory would ship the game. Only the checksum manifest
# travels, and it is named explicitly below rather than by directory, so that no file
# dropped into binary/ later is picked up by accident.
TREE = ["scripts", "src", "extracted", "extern"]

# Single files, listed one by one for the reason above.
TREE_FILES = [os.path.join("binary", "checksums.json")]

# setup.py owns Steam discovery, the checksum manifest and the toolchain table. Import it
# from the bundle so there is exactly one implementation of each. It guards its own
# main(), so importing it runs nothing.
sys.path.insert(0, os.path.join(BUNDLE, "scripts"))
import setup as nss_setup  # noqa: E402


def ensure_tree(on_line=None):
    """Put the shipped reconstruction on disk where it can be built.

    Only meaningful when frozen. Copies rather than links so that a build, which writes
    src/assembled next to the source, has somewhere real to write.
    """
    if not FROZEN:
        return ROOT

    say = on_line or (lambda _s: None)
    if not os.path.isdir(ROOT):
        os.makedirs(ROOT)
    for name in TREE:
        src = os.path.join(BUNDLE, name)
        dst = os.path.join(ROOT, name)
        if not os.path.isdir(src):
            continue
        if os.path.isdir(dst):
            # Refresh in place. dirs_exist_ok keeps a previous install's src/assembled,
            # so a rebuild does not start from nothing every time.
            shutil.copytree(src, dst, dirs_exist_ok=True)
        else:
            say("  unpacking %s" % name)
            shutil.copytree(src, dst)

    for rel in TREE_FILES:
        src = os.path.join(BUNDLE, rel)
        dst = os.path.join(ROOT, rel)
        if os.path.isfile(src):
            if not os.path.isdir(os.path.dirname(dst)):
                os.makedirs(os.path.dirname(dst))
            shutil.copy2(src, dst)

    # The two files that sit beside source_code. play.exe is carried inside this
    # installer and written out here, so the player never types a command.
    launcher_src = os.path.join(BUNDLE, "play.exe")
    launcher_dst = os.path.join(INSTALL_DIR, "play.exe")
    if os.path.isfile(launcher_src):
        say("  writing play.exe")
        shutil.copy2(launcher_src, launcher_dst)

    say("  writing README.txt")
    with io.open(os.path.join(INSTALL_DIR, "README.txt"), "w",
                 encoding="utf-8", newline="\r\n") as f:
        f.write(README_TEXT)
    return ROOT


class Result(object):
    """Outcome of one step. `detail` is for the log pane, `hint` is what to do about it."""

    def __init__(self, ok, summary, detail="", hint=""):
        self.ok = ok
        self.summary = summary
        self.detail = detail
        self.hint = hint


def step_find(steam_path=None):
    """Locate the game. An explicit path always wins, so a non-standard install is not
    argued with."""
    if steam_path:
        if not os.path.isdir(steam_path):
            return Result(False, "That path does not exist", steam_path,
                          "Point --steam-path at the folder holding NSS5.exe.")
        return Result(True, "Using the path you gave", steam_path)

    found = nss_setup.find_install()
    if not found:
        return Result(
            False, "Could not find New Star Soccer 5",
            "Searched every Steam library in libraryfolders.vdf, then the usual "
            "Program Files locations.",
            "If you own it somewhere else, pass --steam-path. If you do not own it, "
            "this project cannot help you: none of the game ships here.")
    return Result(True, "Found your Steam copy", found)


def step_verify(game_dir):
    """Checksum the install. A modified or non-Steam copy is named here, rather than
    surfacing later as a build error that looks like our bug."""
    exe = os.path.join(game_dir, "NSS5.exe")
    if not os.path.isfile(exe):
        return Result(False, "No NSS5.exe in that folder", exe,
                      "Check the path points at the game folder itself.")

    size = os.path.getsize(exe)
    digest = nss_setup.sha256(exe)
    detail = "NSS5.exe\n  %s bytes\n  sha256 %s" % ("{:,}".format(size), digest)

    expected_size = 9383424
    expected_sha = ("37d566150483da1ecba03b4b2421307f"
                    "c741a26a63c3092c9a154de21535e8eb")
    if digest == expected_sha:
        return Result(True, "Your copy matches the Steam release", detail)

    # Not fatal. Say what it means and let the caller decide, because an unknown build
    # may still assemble, and finding out is useful information for the project.
    return Result(
        False, "Your copy is not the build this targets", detail,
        "Expected %s bytes, sha256 %s.\nThis reconstruction is graded against the Steam "
        "release. Another build may still work, but nothing is verified against it. "
        "Please open an issue with the two hashes." % ("{:,}".format(expected_size),
                                                       expected_sha))


def step_toolchain():
    """Report the toolchain from setup.py's own table, so this cannot drift from what
    the build actually looks for."""
    missing_required = []
    missing_optional = []
    lines = []

    for key, rel, probe, required, label, url in nss_setup.TOOLS:
        target = os.path.join(ROOT, rel.replace("/", os.sep), probe.replace("/", os.sep))
        present = os.path.isfile(target)
        lines.append("  [%s] %s" % ("ok" if present else "  ", label.strip()))
        if present:
            continue
        (missing_required if required else missing_optional).append((label.strip(), url))

    detail = "\n".join(lines)

    if missing_required:
        # Not an error the player has to act on. "Install and build" fetches these, so
        # say that rather than listing download links they do not need to follow.
        hint = ["These are missing, which is normal before the first install.",
                "'Install and build' downloads them for you. Nothing to do by hand."]
        return Result(False, "Toolchain not installed yet", detail, "\n".join(hint))

    note = ""
    if missing_optional:
        # Name the ones actually missing. A fixed sentence here went stale the first
        # time it ran, claiming Ghidra was absent while it was present.
        names = ", ".join(label for label, _ in missing_optional)
        note = "%s absent. Only decompiling needs %s." % (
            names, "them" if len(missing_optional) > 1 else "it")
    return Result(True, "Toolchain is ready", detail, note)


def step_get_toolchain(on_line):
    """Fetch the compiler. Imported here rather than at module top so the installer still
    starts and can diagnose on a machine where this module is unavailable."""
    import toolchain

    ensure_tree(on_line)
    missing = toolchain.probe(ROOT)
    if not missing:
        return Result(True, "Toolchain already present")

    on_line("Fetching the toolchain. Nothing of it is shipped in this installer;")
    on_line("every piece comes from its own publisher.")
    ok, message = toolchain.acquire(ROOT, on_line)
    return Result(ok, message if ok else "Could not get the toolchain", "",
                  "" if ok else message)


def run_script(args, on_line):
    """Run a project script, streaming output. Returns the exit code.

    Streamed rather than captured because assemble.py takes minutes, and an installer
    that shows nothing for minutes reads as a hang. That misreading has already cost
    this project time, so do not reintroduce it.
    """
    proc = subprocess.Popen(
        [sys.executable] + args, cwd=ROOT, stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT, universal_newlines=True, bufsize=1)
    for line in proc.stdout:
        on_line(line.rstrip("\n"))
    proc.wait()
    return proc.returncode


def step_build(game_dir, on_line):
    """setup.py then assemble.py. setup.py must run first even when the game is already
    in place, because assemble.py reads what it derives from the user's own exe."""
    # When frozen, the shipped source still has to reach a real directory: PyInstaller
    # unpacks to a temporary one that is deleted on exit, so a build written there would
    # not survive the installer closing.
    if FROZEN:
        on_line("Installing into %s" % INSTALL_DIR)
        on_line("  %s\\" % SOURCE_DIRNAME)
        on_line("  play.exe")
        on_line("  README.txt")
        ensure_tree(on_line)
        on_line("")

    args = ["scripts/setup.py"]
    if game_dir:
        args += ["--steam-path", game_dir]

    on_line("$ python %s" % " ".join(args))
    if run_script(args, on_line) != 0:
        return Result(False, "setup.py did not finish",
                      hint="Its last lines above name what is missing.")

    on_line("")
    on_line("$ python scripts/assemble.py")
    if run_script(["scripts/assemble.py"], on_line) != 0:
        return Result(False, "assemble.py did not finish",
                      hint="If this is 'Build Error: Failed to link' with no cause, bmk "
                           "called g++ without its own MinGW on PATH. Try "
                           "bash scripts/build_debug.sh.")

    return Result(True, "Build finished",
                  os.path.join(ROOT, "src", "assembled", "nss5_assembled.exe"))


def run_cli(steam_path=None, check_only=False):
    """Text mode. --check stops after the diagnosis and writes nothing."""
    def out(s=""):
        print(s)
        sys.stdout.flush()

    out("New Star Soccer 5 reconstruction installer")
    out("=" * 58)

    steps = [("Finding your copy of the game", lambda: step_find(steam_path))]
    game_dir = None
    failed = False

    for title, fn in steps:
        out()
        out(title)
        r = fn()
        out("  %s" % r.summary)
        if r.detail:
            for line in r.detail.splitlines():
                out("  %s" % line)
        if not r.ok:
            if r.hint:
                out()
                for line in r.hint.splitlines():
                    out("  %s" % line)
            return 1
        game_dir = r.detail

    for title, fn in (("Checking it is the build this targets",
                       lambda: step_verify(game_dir)),
                      ("Checking the toolchain", step_toolchain)):
        out()
        out(title)
        r = fn()
        out("  %s" % r.summary)
        if r.detail:
            for line in r.detail.splitlines():
                out("  %s" % line)
        if r.hint:
            out()
            for line in r.hint.splitlines():
                out("  %s" % line)
        if not r.ok:
            failed = True

    if check_only:
        out()
        out("Checked only. Nothing was written and nothing was built.")
        return 1 if failed else 0

    if failed:
        out()
        out("Getting the toolchain. This takes a while.")
        r = step_get_toolchain(out)
        out("  %s" % r.summary)
        if r.hint:
            for line in r.hint.splitlines():
                out("  %s" % line)
        if not r.ok:
            return 1

    out()
    out("Building. This takes a few minutes.")
    out("-" * 58)
    r = step_build(game_dir, out)
    out("-" * 58)
    out(r.summary)
    if r.detail:
        out("  %s" % r.detail)
    if r.hint:
        for line in r.hint.splitlines():
            out("  %s" % line)
    if not r.ok:
        return 1

    out()
    out("Run it with:  python scripts/play.py")
    out("Do not run the exe directly. It can start in full screen and lock up the "
        "display, which needs a power cycle to clear. play.py forces windowed mode.")
    return 0


def main():
    argv = sys.argv[1:]
    steam_path = None
    if "--steam-path" in argv:
        i = argv.index("--steam-path")
        if i + 1 >= len(argv):
            print("--steam-path needs a path after it")
            return 2
        steam_path = argv[i + 1]

    if "--check" in argv:
        return run_cli(steam_path, check_only=True)
    if "--cli" in argv:
        return run_cli(steam_path)

    try:
        import gui
    except ImportError:
        print("The window needs tkinter, which this Python does not have.")
        print("Falling back to text mode.")
        print()
        return run_cli(steam_path)
    # Hand this module to the window rather than letting it import us back. Neither
    # module then imports the other, so there is no cycle and the tkinter fallback above
    # keeps working.
    return gui.run(sys.modules[__name__], steam_path)


if __name__ == "__main__":
    raise SystemExit(main())
