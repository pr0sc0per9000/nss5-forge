"""Build modloader/build/winmm.dll with the 32-bit MinGW the BlitzMax toolchain ships.

Usage: python modloader/build.py [--gcc path\\to\\gcc.exe]
"""

import os
import shutil
import subprocess
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
GCC = os.path.join(ROOT, "tools", "blitzmax-legacy-src", "_mingw", "mingw", "bin", "gcc.exe")


def main():
    gcc = sys.argv[sys.argv.index("--gcc") + 1] if "--gcc" in sys.argv else GCC
    if not os.path.isfile(gcc):
        gcc = shutil.which("gcc") or gcc
    if not os.path.isfile(gcc):
        sys.exit("no 32-bit gcc: install the BlitzMax toolchain (README) or pass --gcc")
    out = os.path.join(HERE, "build")
    lau = os.path.join(HERE, "launcher")
    os.makedirs(out, exist_ok=True)
    env = dict(os.environ, PATH=os.path.dirname(gcc) + os.pathsep + os.environ.get("PATH", ""))

    builds = [
        # the winmm proxy: anchor in NSS5.exe, asset redirect + mods in our build
        ([gcc, "-m32", "-O2", "-s", "-shared", "-static-libgcc", "-Wall",
          "-o", os.path.join(out, "winmm.dll"),
          os.path.join(HERE, "winmm.c"), os.path.join(HERE, "exports.S"),
          os.path.join(HERE, "winmm.def")], "winmm.dll"),
        # the launcher: first-run refill, update, progress window. GUI subsystem, no console.
        ([gcc, "-m32", "-O2", "-s", "-mwindows", "-static-libgcc", "-Wall",
          "-o", os.path.join(out, "launcher.exe"),
          os.path.join(lau, "launcher.c"), os.path.join(lau, "forge_core.c"),
          os.path.join(lau, "update.c"),
          "-I", lau, "-lcomctl32", "-lwininet"], "launcher.exe"),
    ]
    for cmd, name in builds:
        if subprocess.run(cmd, env=env).returncode:
            sys.exit("build failed: " + name)
        print("built", os.path.join(out, name))


if __name__ == "__main__":
    main()
