"""Populate a fresh clone from your own copy of New Star Soccer 5.

    python scripts/setup.py
    python scripts/setup.py --steam-path "C:/.../steamapps/common/New Star Soccer 5"
    python scripts/setup.py --check        # verify only, copy nothing

WHY A SETUP SCRIPT EXISTS AT ALL
================================
This repository contains our reconstruction of the SOURCE of New Star Soccer 5.
It does not, and will never, contain the game. NSS5 is a commercial product,
still sold (Steam appid 212780), and its executable and media belong to New Star
Games Ltd.

That is the universal convention in this field, not a local preference:

    "This repository does not include any of the assets necessary to build the
     ROM. A prior copy of the game is required to extract the needed assets."
        -- zeldaret/oot

    "CorsixTH aims to reimplement the game engine of Theme Hospital ... This
     means that you will need a purchased copy of Theme Hospital."
        -- CorsixTH

    "KeeperFX is a standalone game but requires a copy of the original game
     files as proof of ownership."
        -- dkfans/keeperfx

So the repo holds a precise DESCRIPTION of the data -- filenames, sizes,
SHA-256s, and where to find them -- and this script turns that description plus
your install into a working tree. binary/checksums.json is that description.

WHY IT VERIFIES BEFORE IT COPIES
================================
Because the failure it prevents is expensive and confusing. A different build of
the game produces a reconstruction that mismatches everywhere at once, and the
symptom surfaces forty minutes later as an inexplicable byte-comparison failure
with no obvious cause. Checking a hash up front turns that into one clear line
naming the problem. isledecomp/isle publishes per-binary MD5s under a heading
literally called "Which version of LEGO Island do I have?" for the same reason.
"""
import os
import re
import sys
import json
import shutil
import hashlib

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
MANIFEST = os.path.join(ROOT, "binary", "checksums.json")
STEAM_APPID = "212780"
GAME_DIRNAME = "New Star Soccer 5"

# Media directories copied out of the install, and where the build expects them.
ASSET_DIRS = ["GameMedia", "EngineMedia", "Inc", "Settings"]
ASSET_DEST = os.path.join(ROOT, "src", "assembled")

# Loose DLLs that sit BESIDE the exe in a real install, so they have to sit beside
# ours too. They are not in checksums.json because they are not what identifies a
# build -- but the game links OpenAL, and a machine with no system-wide OpenAL has
# nothing to load without these. Copied only if your install has them; absence is
# not an error. steam_api.dll and steamstub.dll are deliberately NOT copied: the
# Steam entry points are stubbed out (see STEAM_EXCLUDE in progress.py).
RUNTIME_DLLS = ["OpenAL32.dll", "wrap_oal.dll"]

# Toolchain the build needs. Fetched by you, never committed -- all three are
# public downloads, and vendoring is reserved for tools that cannot be obtained
# any other way (n64decomp/sm64 commits a 1990s SGI compiler for that reason;
# nothing we use is in that category).
#
# EACH ROW NAMES A FILE, NOT A DIRECTORY, AND THE DIRECTORY IS THE ONE THE BUILD
# ACTUALLY USES. Both halves of that were wrong here and each one on its own is
# enough to strand a newcomer:
#
#   * The path said `tools/blitzmax`. Every build script reads
#     `tools/blitzmax-legacy-src` (assemble.py -> harness.py BASE_BMX_ROOT,
#     build_debug.sh BMX). So this reported MISSING with a complete working
#     toolchain on disk, and reported "present" for a directory nothing reads --
#     after which assemble.py died in subprocess with a bare
#     `FileNotFoundError: [WinError 2] The system cannot find the file specified`,
#     naming neither BlitzMax nor bmk.
#   * Testing `os.path.isdir` passes on the bare `git clone` of BlitzMax, which
#     ships NO compiler: `bin/*` is gitignored upstream and there is no `_mingw`.
#     A clone that has never been bootstrapped looks installed to a directory
#     check and fails at the first build. Probe for the binary instead.
#
# `required` marks what a BUILD needs. Ghidra and the JDK are for decompiling; a
# missing one is a note, not a failure.
TOOLS = [
    ("blitzmax", "tools/blitzmax-legacy-src", "bin/bmk.exe", True,
     "BlitzMax (legacy 1.x, 32-bit)", "https://github.com/blitz-research/blitzmax"),
    ("mingw", "tools/blitzmax-legacy-src/_mingw/mingw", "bin/g++.exe", True,
     "  its bundled MinGW (_src/win32_x86/mingw_v5b.7z)", None),
    ("ghidra", "tools/ghidra_12.1.2_PUBLIC", "ghidraRun.bat", False,
     "Ghidra 12.1.2 (only to decompile)",
     "https://github.com/NationalSecurityAgency/ghidra/releases"),
    ("jdk", "tools/jdk", "bin/java.exe", False,
     "JDK 21+ (only to decompile; Ghidra requires it)", "https://adoptium.net/"),
]

# ---------------------------------------------------------------- extracted/
# extracted/ holds the data the assembler reads. Two kinds live there, and the
# difference is the whole reason this section exists.
#
# DERIVED: recomputed from your own binary/NSS5.exe, every time, by scripts in
# this repository. Verified byte-identical to a full working tree's copies. These
# are why setup.py now RUNS them rather than only reporting on them: without
# extracted/object_model.json, `python scripts/assemble.py` -- the very next
# command the README gives -- stopped on line 1 of its data load with a raw
# FileNotFoundError, and nothing in the documented flow ever created that file.
DERIVE = [
    ("parse_reflection.py", [], ["object_model.json"]),
    ("resolve_vtables.py", [], ["vtable_map.tsv", "class_tables.tsv"]),
    ("extract_imports.py", [], ["dll_imports.tsv"]),
    ("extract_incbin.py", ["--write"], ["incbin"]),
]

# COMMITTED: tracked in git, because nothing can recompute them from the exe --
# see the note in .gitignore. Listed here so a checkout that predates them, or one
# where .gitignore swallowed them, says so in one line instead of failing somewhere
# inside a 1,900-line assembler.
BUILD_INPUTS = [
    "global_address_map.tsv", "global_alias_adjudicated.tsv", "global_alias_map.tsv",
    "global_alias_overrides.tsv", "global_alias_unified.tsv", "global_alias_writers.tsv",
    "globals_type_overrides.tsv", "module_globals_decoded.tsv",
    "type_declaration_order.tsv",
]


def sha256(path, blocks=1 << 20):
    h = hashlib.sha256()
    with open(path, "rb") as f:
        for chunk in iter(lambda: f.read(blocks), b""):
            h.update(chunk)
    return h.hexdigest()


def steam_libraries():
    """Every Steam library root on this machine, from libraryfolders.vdf.

    Steam installs can live on any drive, so a single hardcoded path is not
    enough -- libraryfolders.vdf is the authoritative list. OpenRCT2 solves the
    same problem by hardcoding a dozen candidate paths; parsing the manifest is
    the same idea done properly.
    """
    roots, seen = [], set()
    candidates = [
        os.environ.get("ProgramFiles(x86)"),
        os.environ.get("ProgramFiles"),
        os.path.expanduser("~/.steam/steam"),
        os.path.expanduser("~/.local/share/Steam"),
    ]
    for base in candidates:
        if not base:
            continue
        for steam in (os.path.join(base, "Steam"), base):
            vdf = os.path.join(steam, "steamapps", "libraryfolders.vdf")
            if not os.path.exists(vdf):
                continue
            if steam not in seen:
                seen.add(steam)
                roots.append(steam)
            try:
                text = open(vdf, encoding="utf-8", errors="replace").read()
            except OSError:
                continue
            for m in re.finditer(r'"path"\s*"([^"]+)"', text):
                p = m.group(1).replace("\\\\", os.sep)
                if p not in seen:
                    seen.add(p)
                    roots.append(p)
    return roots


def find_install():
    """Locate the game directory, or None."""
    for root in steam_libraries():
        p = os.path.join(root, "steamapps", "common", GAME_DIRNAME)
        if os.path.isdir(p):
            return p
    guesses = [
        os.path.join(os.environ.get("ProgramFiles(x86)", ""), "Steam",
                     "steamapps", "common", GAME_DIRNAME),
        os.path.join(os.environ.get("ProgramFiles", ""), "Steam",
                     "steamapps", "common", GAME_DIRNAME),
        os.path.expanduser(os.path.join("~", "Documents", GAME_DIRNAME)),
    ]
    for guess in guesses:
        if guess and os.path.isdir(guess):
            return guess
    return None


def enable_debug_log():
    """Set debug=1 in the copied src/assembled/Settings/Settings.txt.

    THE STOCK FILE SAYS debug=0, AND THAT MAKES A WORKING BUILD LOOK BROKEN.
    Everything the game reports about its own startup -- the language file, the
    kits, the media, the screens -- goes to log.txt, and log.txt is only written
    when debug=1. smoke_boot.py reads that log to decide how far boot got, so with
    the stock setting it sees the process alive, no log, and reports:

        milestones reached : settings read
        not reached        : language file loaded, ... MAIN MENU reached

    which reads as a hang immediately after `CALLING GameMain`. Measured on a clean
    checkout: flipping this one value took the same untouched binary from one
    milestone to seven and the last stdout line from `CALLING GameMain` to
    `SetActive:language`. Nothing about the build changed. This is the difference
    between a newcomer filing "it builds but hangs on startup" and seeing the game
    come up on its language screen.
    """
    p = os.path.join(ASSET_DEST, "Settings", "Settings.txt")
    if not os.path.exists(p):
        return
    with open(p, "r", encoding="utf-8", errors="replace", newline="") as f:
        text = f.read()
    fixed = re.sub(r"(?m)^debug=0\s*$",
                   lambda m: m.group(0).replace("debug=0", "debug=1"), text)
    if fixed != text:
        with open(p, "w", encoding="utf-8", newline="") as f:
            f.write(fixed)
        print("    src/assembled/Settings/Settings.txt  debug=0 -> debug=1")
        print("      (the startup log the tooling reads is only written when this is 1)")


def derive():
    """Recompute extracted/ from binary/NSS5.exe. -> list of failures.

    Judged on whether the OUTPUT appeared, not on the exit code: resolve_vtables.py
    exits 1 on a completely successful run because 5 of 2,862 class-table slots do
    not resolve, which is a reported condition and not a failure. Anything that
    treats its status as fatal stops a working setup dead.
    """
    import subprocess
    ex = os.path.join(ROOT, "extracted")
    os.makedirs(ex, exist_ok=True)
    bad = []
    for script, args, outs in DERIVE:
        path = os.path.join(ROOT, "scripts", script)
        p = subprocess.run([sys.executable, path] + args, cwd=ROOT,
                           capture_output=True, text=True, errors="replace")
        made = [o for o in outs if os.path.exists(os.path.join(ex, o))]
        if len(made) == len(outs):
            print("    %-24s -> %s" % (script, ", ".join(outs)))
        else:
            miss = [o for o in outs if o not in made]
            print("    %-24s FAILED (no %s)" % (script, ", ".join(miss)))
            tail = ((p.stdout or "") + (p.stderr or "")).strip().split("\n")
            for line in tail[-4:]:
                print("        %s" % line)
            bad.append(script)
    return bad


def check_build_inputs():
    """-> list of committed extracted/ files that are missing."""
    ex = os.path.join(ROOT, "extracted")
    return [n for n in BUILD_INPUTS if not os.path.exists(os.path.join(ex, n))]


def verify(src, name, spec):
    """-> (ok, message). Size is checked first because it is instant."""
    path = os.path.join(src, name)
    if not os.path.exists(path):
        return (not spec.get("required", False),
                "missing" + ("" if spec.get("required") else " (optional)"))
    size = os.path.getsize(path)
    if size != spec["size"]:
        return False, "WRONG SIZE: %d, expected %d" % (size, spec["size"])
    got = sha256(path)
    if got != spec["sha256"]:
        return False, "WRONG SHA-256: %s..." % got[:16]
    return True, "ok"


def main():
    argv = sys.argv[1:]
    check_only = "--check" in argv
    src = None
    for i, a in enumerate(argv):
        if a == "--steam-path" and i + 1 < len(argv):
            src = argv[i + 1]

    manifest = json.load(open(MANIFEST, encoding="utf-8"))
    print("nss5-forge setup")
    print("  target : %s (Steam appid %s)"
          % (manifest["game"]["title"], STEAM_APPID))
    print()

    if not src:
        src = find_install()
        if src:
            print("  found install: %s" % src)
        else:
            print("  Could not locate a New Star Soccer 5 install automatically.")
            print()
            print("  Pass it explicitly:")
            print('    python scripts/setup.py --steam-path "<path to the game folder>"')
            print()
            print("  In Steam: right-click the game -> Manage -> Browse local files.")
            return 2
    if not os.path.isdir(src):
        print("  ERROR: not a directory: %s" % src)
        return 2

    print()
    print("  Verifying your copy against binary/checksums.json ...")
    ok = True
    for name, spec in sorted(manifest["files"].items()):
        good, why = verify(src, name, spec)
        print("    %-28s %s" % (name, why))
        ok = ok and good
    if not ok:
        print()
        print("  VERIFICATION FAILED.")
        print("  Your copy differs from the build this reconstruction targets.")
        print("  That is worth knowing now rather than as a confusing build")
        print("  failure later -- it is not a fault in your install.")
        return 1
    print("  All present files verified.")

    if check_only:
        print()
        print("  --check given; nothing copied.")
        return 0

    print()
    print("  Copying (destinations are gitignored) ...")
    n = 0
    for name in manifest["files"]:
        s = os.path.join(src, name)
        if not os.path.exists(s):
            continue
        shutil.copy2(s, os.path.join(ROOT, "binary", name))
        print("    binary/%s" % name)
        n += 1

    os.makedirs(ASSET_DEST, exist_ok=True)
    for sub in ASSET_DIRS:
        s = os.path.join(src, sub)
        if not os.path.isdir(s):
            continue
        d = os.path.join(ASSET_DEST, sub)
        if os.path.isdir(d):
            shutil.rmtree(d)
        shutil.copytree(s, d)
        size = sum(os.path.getsize(os.path.join(dp, f))
                   for dp, _dn, fn in os.walk(d) for f in fn)
        print("    src/assembled/%-14s %6.1f MB" % (sub, size / 1e6))
        n += 1

    for dll in RUNTIME_DLLS:
        s = os.path.join(src, dll)
        if os.path.exists(s):
            shutil.copy2(s, os.path.join(ASSET_DEST, dll))
            print("    src/assembled/%s" % dll)
            n += 1
    print("  Copied %d items." % n)

    enable_debug_log()

    # Working directories every tool writes into. All gitignored, so a fresh clone
    # has none of them, and ten of the twelve scripts that write there assume they
    # already exist -- smoke_boot.py died on `status/smoke_stdout.txt` with a bare
    # FileNotFoundError immediately after a completely successful build. Creating
    # them here costs nothing and removes the whole class.
    for sub in ("status", "logs", "extracted"):
        os.makedirs(os.path.join(ROOT, sub), exist_ok=True)

    print()
    print("  Deriving extracted/ from your binary/NSS5.exe ...")
    failed = derive()

    print()
    print("  Toolchain (public downloads; never committed) ...")
    missing = []
    for _key, rel, probe, need, label, url in TOOLS:
        there = os.path.exists(os.path.join(ROOT, rel, probe))
        print("    %-42s %s" % (label, "present" if there else "MISSING"))
        if not there and need:
            missing.append((rel, probe, label, url))
    if missing:
        print()
        print("  The build needs these. Install into the paths shown, then re-run:")
        for rel, probe, _label, url in missing:
            print("    %-38s <- %s" % (rel + "/" + probe, url or "(see README)"))
        print()
        print("  BlitzMax is a SOURCE repository -- cloning it is not installing it.")
        print("  It ships no compiler (bin/* is gitignored upstream) and no MinGW.")
        print("  After cloning it to tools/blitzmax-legacy-src:")
        print("    1. extract _src/win32_x86/mingw_v5b.7z to _mingw/ in that tree")
        print("       (it must end up as tools/blitzmax-legacy-src/_mingw/mingw/bin)")
        print("    2. build bcc and bmk per its own README.TXT (_src/win32_x86)")
        print("  Nothing else in this repository needs building.")

    gone = check_build_inputs()
    if gone:
        print()
        print("  MISSING BUILD INPUTS -- %d file(s) under extracted/ that the" % len(gone))
        print("  assembler reads and NOTHING can recompute from the exe:")
        for n in gone:
            print("    extracted/%s" % n)
        print()
        print("  These are tracked in git, so a normal clone has them. If yours does")
        print("  not, your checkout predates them. Update it:  git pull")
        print("  Do not build without them: assemble.py will not stop, it will merge")
        print("  0 Global aliases instead of 1,280 and produce a binary whose player")
        print("  cannot move and which crashes on quit.")

    if failed or missing or gone:
        print()
        print("  SETUP INCOMPLETE -- resolve the above before running assemble.py.")
        return 1

    print()
    print("  Next:")
    print("    python scripts/assemble.py     # build the reconstruction")
    print("    python scripts/progress.py     # how much is byte-identical")
    print("    python scripts/debug_game.py   # run it (windowed, watchdogged)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
