"""Acquire the BlitzMax toolchain, so a player never has to build a compiler.

WHY THIS EXISTS
===============
Everything else a player needs is either theirs already (the game) or ships with the
installer (this project's source). The toolchain is the one gap, and CONTRIBUTING.md
describes filling it by hand: clone BlitzMax, unpack a 7-Zip archive into the right
place, then build bcc and bmk from source following another project's README. Nobody
installing a football game is going to do that.

WHAT IS ACTUALLY REQUIRED, WHICH IS LESS THAN THE DOCS SUGGEST
==============================================================
The documented "build bcc and bmk from source" step is not needed. blitz-research/
blitzmax ships them prebuilt at _src/win32_x86/bin, and its own install.bat does no
compiler bootstrap at all - it copies that bin and lib to the top level, then rebuilds
the modules using the compiler it just copied. Confirmed against the upstream repository:

    _src/win32_x86/bin/bcc.exe    1,270,272 bytes
    _src/win32_x86/bin/bmk.exe      221,184 bytes
    _src/win32_x86/mingw_v5b.7z  13,147,494 bytes

The top-level bin/ is absent upstream, which is what the "it ships no bmk.exe" note in
CONTRIBUTING.md is describing. The binaries are there; they are one directory down.

NOTHING HERE IS REDISTRIBUTED
=============================
Every byte is fetched from its own publisher at install time. BlitzMax is under the
zlib/libpng licence, which would permit shipping its binaries, but fetching is better
anyway: it keeps this installer small, it matches what .gitignore already says about
toolchains being fetched and never vendored, and it sidesteps the source-offer
obligation that redistributing MinGW would carry, MinGW being GCC and under the GPL.
7zr is fetched from 7-zip.org for the same reason.

STEPS
=====
    1. 7zr.exe            from 7-zip.org, to unpack the MinGW archive
    2. BlitzMax           the repository as a zip, extracted to tools/blitzmax-legacy-src
    3. bin/ and lib/      copied up from _src/win32_x86, which is what install.bat does
    4. MinGW              mingw_v5b.7z unpacked to _mingw/
    5. modules            rebuilt with the compiler from step 3

Steps 1 to 4 are quick. Step 5 compiles the BlitzMax module tree and is the slow one.
"""

import os
import shutil
import subprocess
import zipfile
import urllib.request

BLITZMAX_ZIP = "https://github.com/blitz-research/blitzmax/archive/refs/heads/master.zip"
SEVENZR_URL = "https://www.7-zip.org/a/7zr.exe"

# Where every build script in this project expects the toolchain. Do not rename: setup.py
# probes these exact paths by name.
BMX_REL = os.path.join("tools", "blitzmax-legacy-src")
MINGW_PROBE = os.path.join("_mingw", "mingw", "bin", "g++.exe")
BMK_PROBE = os.path.join("bin", "bmk.exe")


def probe(root):
    """What is missing, as a list of short names. Empty means ready to build."""
    bmx = os.path.join(root, BMX_REL)
    missing = []
    if not os.path.isfile(os.path.join(bmx, BMK_PROBE)):
        missing.append("bmk")
    if not os.path.isfile(os.path.join(bmx, MINGW_PROBE)):
        missing.append("mingw")
    return missing


def _download(url, dest, on_line, label):
    """Fetch with coarse progress. Coarse on purpose: a percentage that updates hundreds
    of times a second floods the log pane and tells the reader nothing."""
    on_line("  downloading %s" % label)
    tmp = dest + ".part"
    last = [-1]

    def hook(blocks, block_size, total):
        if total <= 0:
            return
        pct = min(100, int(blocks * block_size * 100 / total))
        if pct >= last[0] + 10:
            last[0] = pct - (pct % 10)
            on_line("    %d%% of %.1f MB" % (last[0], total / 1048576.0))

    urllib.request.urlretrieve(url, tmp, reporthook=hook)
    if os.path.exists(dest):
        os.remove(dest)
    os.rename(tmp, dest)
    return dest


def _ensure_7zr(work, on_line):
    """7zr, only to unpack MinGW. Fetched rather than shipped: it is LGPL, and
    redistributing it would bring a source obligation for no benefit."""
    exe = os.path.join(work, "7zr.exe")
    if os.path.isfile(exe):
        return exe
    return _download(SEVENZR_URL, exe, on_line, "7zr.exe")


def _extract_zip(zip_path, dest, on_line):
    """Extract the repository zip, dropping GitHub's single top-level wrapper directory
    so the result is tools/blitzmax-legacy-src/... and not .../blitzmax-master/..."""
    on_line("  extracting BlitzMax")
    with zipfile.ZipFile(zip_path) as z:
        names = z.namelist()
        if not names:
            raise RuntimeError("the BlitzMax zip is empty")
        prefix = names[0].split("/")[0] + "/"
        for name in names:
            if not name.startswith(prefix) or name.endswith("/"):
                continue
            target = os.path.join(dest, name[len(prefix):].replace("/", os.sep))
            parent = os.path.dirname(target)
            if parent and not os.path.isdir(parent):
                os.makedirs(parent)
            with z.open(name) as src, open(target, "wb") as out:
                shutil.copyfileobj(src, out)


def _copy_tree_contents(src, dst):
    if not os.path.isdir(src):
        return 0
    if not os.path.isdir(dst):
        os.makedirs(dst)
    n = 0
    for name in os.listdir(src):
        s = os.path.join(src, name)
        d = os.path.join(dst, name)
        if os.path.isdir(s):
            shutil.copytree(s, d, dirs_exist_ok=True)
        else:
            shutil.copy2(s, d)
        n += 1
    return n


def acquire(root, on_line, work_dir=None, build_modules=True):
    """Put a working toolchain at <root>/tools/blitzmax-legacy-src.

    Returns (ok, message). Safe to re-run: each step is skipped when its result is
    already present, so a failure part way through can be retried without starting over.
    """
    bmx = os.path.join(root, BMX_REL)
    work = work_dir or os.path.join(root, "tools", "_download")
    if not os.path.isdir(work):
        os.makedirs(work)

    missing = probe(root)
    if not missing:
        return True, "Toolchain already present."

    try:
        sevenzr = _ensure_7zr(work, on_line)

        if not os.path.isdir(os.path.join(bmx, "_src")):
            zip_path = os.path.join(work, "blitzmax.zip")
            if not os.path.isfile(zip_path):
                _download(BLITZMAX_ZIP, zip_path, on_line, "BlitzMax")
            _extract_zip(zip_path, bmx, on_line)

        # What install.bat does: the prebuilt compiler and libraries live one directory
        # down, and the top-level bin/ and lib/ are what every build script reads.
        win32 = os.path.join(bmx, "_src", "win32_x86")
        if not os.path.isfile(os.path.join(bmx, BMK_PROBE)):
            on_line("  installing bcc, bmk and lib")
            _copy_tree_contents(os.path.join(win32, "bin"), os.path.join(bmx, "bin"))
            _copy_tree_contents(os.path.join(win32, "lib"), os.path.join(bmx, "lib"))

        if not os.path.isfile(os.path.join(bmx, MINGW_PROBE)):
            archive = os.path.join(win32, "mingw_v5b.7z")
            if not os.path.isfile(archive):
                return False, "mingw_v5b.7z is not in the BlitzMax download."
            on_line("  unpacking MinGW")
            out = os.path.join(bmx, "_mingw")
            if not os.path.isdir(out):
                os.makedirs(out)
            p = subprocess.run([sevenzr, "x", "-y", "-o" + out, archive],
                               stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
                               universal_newlines=True)
            if p.returncode != 0:
                return False, "7zr could not unpack MinGW:\n" + (p.stdout or "")[-400:]

        still = probe(root)
        if still:
            return False, "Still missing after install: %s" % ", ".join(still)

        if build_modules:
            # The module tree has to be compiled before anything can link against it.
            # This is the slow step, and it runs bmk with MinGW on PATH, the same
            # arrangement build_debug.sh documents.
            on_line("  building BlitzMax modules, this is the slow part")
            env = dict(os.environ)
            env["PATH"] = (os.path.join(bmx, "_mingw", "mingw", "bin") + os.pathsep
                           + env.get("PATH", ""))
            p = subprocess.Popen([os.path.join(bmx, "bin", "bmk.exe"), "makemods"],
                                 cwd=bmx, env=env, stdout=subprocess.PIPE,
                                 stderr=subprocess.STDOUT, universal_newlines=True,
                                 bufsize=1)
            tail = []
            for line in p.stdout:
                line = line.rstrip("\n")
                tail.append(line)
                del tail[:-40]
                if "Compiling" in line or "Error" in line:
                    on_line("    " + line[:110])
            p.wait()
            if p.returncode != 0:
                return False, "Building modules failed:\n" + "\n".join(tail[-12:])

        return True, "Toolchain ready."
    except Exception as e:  # noqa: BLE001 - surfaced to the user, not swallowed
        return False, "%s: %s" % (type(e).__name__, e)
