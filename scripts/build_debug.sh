#!/usr/bin/env bash
# Build the DEBUG binary: src/assembled/nss5_dbg.exe
#
# WHY A SEPARATE SCRIPT
# blitzmax-language-guide 18.26, verified the hard way this session: a RELEASE build
# silently swallows null-derefs and array overruns, returning 0. Only a `-d` build throws.
# So every "it just closed with no message" symptom is invisible in the build assemble.py
# produces, and the debug binary is the only thing that will name the fault.
#
# WHY NOT JUST `bmk makeapp -d`
# bmk shells out to g++ WITHOUT putting its own bundled mingw on PATH, so the link step
# dies with a bare "Build Error: Failed to link" and no cause. Running the exact same
# command with _mingw/mingw/bin on PATH succeeds. The compile step is bmk's; only the link
# is redone here.
#
#   bash scripts/build_debug.sh
#
# Assumes scripts/assemble.py has already written src/assembled/nss5_assembled.bmx.
set -u

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BMX="$ROOT/tools/blitzmax-legacy-src"
MW="$BMX/_mingw/mingw"
SRC="$ROOT/src/assembled/nss5_assembled.bmx"
DBG="$ROOT/src/assembled/nss5_dbg.bmx"
OUT="$ROOT/src/assembled/nss5_dbg.exe"

[ -f "$SRC" ] || { echo "missing $SRC -- run scripts/assemble.py first"; exit 1; }

cp "$SRC" "$DBG"

echo "compiling (debug) ..."
# This is expected to fail at the LINK step; the compile output is what we want.
"$BMX/bin/bmk.exe" makeapp -d -t console -g x86 "$DBG" 2>&1 | grep -vi "^Build Error: Failed to link" | tail -5

LD="$BMX/tmp/ld.tmp"
[ -f "$LD" ] || { echo "no $LD -- the compile step failed, see above"; exit 1; }

echo "linking (with bundled mingw on PATH) ..."
PATH="$MW/bin:$PATH" "$MW/bin/g++.exe" -m32 -static -s \
  -o "$(cygpath -m "$OUT" 2>/dev/null || echo "$OUT")" \
  -L"$(cygpath -m "$BMX/lib" 2>/dev/null || echo "$BMX/lib")" \
  @"$(cygpath -m "$LD" 2>/dev/null || echo "$LD")" || { echo "link failed"; exit 1; }

ls -la "$OUT"
echo
echo "Run it from src/assembled so relative asset paths resolve:"
echo "  cd src/assembled && ./nss5_dbg.exe"
echo "On a fault it prints the BlitzMax error and a stack trace instead of vanishing."
