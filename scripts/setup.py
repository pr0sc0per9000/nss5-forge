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

# Toolchain the build needs. Fetched by you, never committed -- all three are
# public downloads, and vendoring is reserved for tools that cannot be obtained
# any other way (n64decomp/sm64 commits a 1990s SGI compiler for that reason;
# nothing we use is in that category).
TOOLS = [
    ("blitzmax", "tools/blitzmax",
     "BlitzMax (legacy 1.x, 32-bit)", "https://github.com/blitz-research/blitzmax"),
    ("ghidra", "tools/ghidra_12.1.2_PUBLIC",
     "Ghidra 12.1.2", "https://github.com/NationalSecurityAgency/ghidra/releases"),
    ("jdk", "tools/jdk",
     "JDK 21+ (Ghidra requires it)", "https://adoptium.net/"),
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
    print("  Copied %d items." % n)

    print()
    print("  Toolchain (public downloads; never committed) ...")
    missing = []
    for _key, rel, label, url in TOOLS:
        there = os.path.isdir(os.path.join(ROOT, rel))
        print("    %-38s %s" % (label, "present" if there else "MISSING"))
        if not there:
            missing.append((rel, label, url))
    if missing:
        print()
        print("  Install these into the paths shown, then re-run:")
        for rel, _label, url in missing:
            print("    %-24s <- %s" % (rel, url))

    print()
    print("  Next:")
    print("    python scripts/assemble.py     # build the reconstruction")
    print("    python scripts/progress.py     # how much is byte-identical")
    print("    python scripts/play.py         # run it (windowed, watchdogged)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
