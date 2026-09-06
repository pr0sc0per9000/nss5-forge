"""Derive extracted/module_functions.tsv -- the half of the universe with no class table.

WHY
===
coverage.py's stated universe is (a) methods of Types the GAME declares plus
(b) module-level Functions of the game's own module. Half (a) comes from
extracted/vtable_map.tsv. Half (b) came from extracted/module_functions.tsv --
a file that DID NOT EXIST. `os.path.exists(modmap)` was False, the loop was
skipped, and the universe silently contained no module-level Function at all.

The size of that hole: 92 functions, 31,751 bytes of the game's own module-level
code, including GameMain, LogLine, FormatMoney, TileDrawFrame, Sha256Hex and the
whole Md5 family. 89 of them already have a body on disk in
src/recovered_module/, and coverage.py reported every one of those as a
"recovered file outside the universe" -- work done, shipped, and invisible to the
measure that is supposed to say what is left.

A module-level Function is reached only from the module body, so it appears in no
class table and there is no reflection record to read it out of. It has to be
derived, and that is what this script does. It is a derivation, not a judgement:
run it again and it reproduces the file.

THE DERIVATION
==============
Start from Ghidra's function inventory and remove, in order:

  1. everything outside the `code` section. NSS5.exe has two executable sections:
     `code` (3,537 functions, 1,046,180 bytes) is what the BlitzMax toolchain
     emitted, `.text` (1,634 functions, 453,000 bytes) is the MinGW C runtime and
     the C libraries linked beside it. `.text` is not this project's target under
     coverage.py criterion (d) and never was.
  2. every VA that already appears in extracted/vtable_map.tsv. Those are class
     table slots; half (a) of the universe owns them.
  3. every VA in the BRL/PUB and C-runtime-helper sets
     (brl_functions.tsv, brl_functions_inferred.tsv, runtime_helpers.tsv) --
     criteria (c) and (d).

What remains, 264 functions, is module-level code with no class table anywhere:
the game's own Functions, the two bundled modules' Functions, and BlitzMax's own
module-level Functions that nobody has listed in brl_functions.tsv yet.

Those three are told apart BY ADDRESS, because BlitzMax emits one module's code
contiguously and the class tables pin the boundaries exactly:

    0x004bbf31 .. 0x0058dbf2   game main module. First game-Type class-table slot
                               is 0x004bbf31; the ONLY game-Type slot above this
                               range is the shared 36-byte abstract-method stub at
                               0x005b95ac, which 7 game slots and several BlitzMax
                               ones all point at.
    0x0058dbf3 .. 0x00592f25   the two bundled modules, contiguous: zipengine
                               (ZipFile's first slot 0x0058dbf3 .. TZipEStream)
                               then fontmachine (TBitmapFont .. TDrawingPoint,
                               last slot 0x005929f9).
    0x00592f26 ..              BlitzMax brl.* / pub.* module code. First slot is
                               TClass.New (brl.reflection).

Only the first two ranges are emitted. Everything from 0x00592f26 up is BlitzMax's
own and stays out of the universe, exactly as it is today -- this script does not
move it in either direction, it only declines to claim it.

WHICH DIRECTION THE UNCERTAINTY RUNS
====================================
Including the bundled-module range ADDS 3,044 bytes of mostly unrecovered code to
the denominator and 489 matched bytes to the numerator, so it LOWERS the reported
percentage. The attribution is an inference from link order rather than a
reflection record, and it is made in the direction that costs the project points
rather than awards them. If it is wrong, it is wrong the safe way.

WHAT THIS DELIBERATELY DOES NOT DO
==================================
It does not invent names. A derived VA and size is a fact; a derived name is a
guess, and the corpus already carries the real names in the headers of
src/recovered_module/. Where a recovered body exists this script copies the name
out of that body and records where it came from in the `evidence` column; where
none exists the label stays `Fn_<VA>` so the reader can see nobody has opened it.
"""

import csv
import glob
import os
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
EX = os.path.join(ROOT, "extracted")
OUT = os.path.join(EX, "module_functions.tsv")

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import claim as K                                              # noqa: E402

BUNDLED_START = 0x0058DBF3
BLITZMAX_START = 0x00592F26


def _norm(va):
    return "0x%08x" % int(str(va).replace("0x", ""), 16)


def brl_vas():
    out = set()
    for name in ("brl_functions.tsv", "brl_functions_inferred.tsv", "runtime_helpers.tsv"):
        p = os.path.join(EX, name)
        if not os.path.exists(p):
            continue
        with open(p, encoding="utf-8") as f:
            for r in csv.reader(f, delimiter="\t"):
                if r and r[0].strip().startswith("0x"):
                    out.add(_norm(r[0]))
    return out


def classtable_vas():
    out = set()
    with open(os.path.join(EX, "vtable_map.tsv"), encoding="utf-8") as f:
        for r in csv.reader(f, delimiter="\t"):
            if len(r) > 5 and str(r[5]).startswith("0x"):
                out.add(_norm(r[5]))
    return out


def recovered_names():
    """{va: (name, tree)} read out of the bodies already on disk."""
    out = {}
    pats = [("src/recovered/*.bmx", "src/recovered"),
            ("src/recovered_module/*.bmx", "src/recovered_module"),
            ("src/recovered_unverified/*.bmx", "src/recovered_unverified"),
            ("src/recovered_thirdparty/*/*.bmx", "src/recovered_thirdparty")]
    for pat, tree in pats:
        for p in glob.glob(os.path.join(ROOT, pat.replace("/", os.sep))):
            _head, vs, _m = K.read(p)
            if not vs:
                continue
            stem = os.path.basename(p)[:-4]
            if stem.lower().startswith("fn_") and "." in stem:
                stem = stem.split(".", 1)[1]
            out.setdefault(vs[0], (stem, tree))
    return out


def build():
    brl = brl_vas()
    ct = classtable_vas()
    names = recovered_names()
    rows = []
    with open(os.path.join(EX, "ghidra", "function_inventory.tsv"), encoding="utf-8") as f:
        for r in csv.DictReader(f, delimiter="\t"):
            if r["block"] != "code":
                continue
            va = _norm(r["addr"])
            if va in ct or va in brl:
                continue
            a = int(va, 16)
            if a >= BLITZMAX_START:
                continue
            owner = "game" if a < BUNDLED_START else "bundled"
            name, tree = names.get(va, (None, None))
            rows.append((va, name or ("Fn_" + va[2:].upper()), int(r["size"]), owner,
                         tree if tree else "no body on disk"))
    rows.sort()
    return rows


def main():
    rows = build()
    with open(OUT, "w", encoding="utf-8", newline="") as f:
        w = csv.writer(f, delimiter="\t", lineterminator="\n")
        w.writerow(["va", "name", "size", "owner", "evidence"])
        for r in rows:
            w.writerow(r)
    print("wrote %s" % os.path.relpath(OUT, ROOT))
    for owner in ("game", "bundled"):
        g = [r for r in rows if r[3] == owner]
        print("  %-8s %3d functions %7d bytes (%d with a body on disk, %d never opened)"
              % (owner, len(g), sum(r[2] for r in g),
                 sum(1 for r in g if r[4] != "no body on disk"),
                 sum(1 for r in g if r[4] == "no body on disk")))
    return 0


if __name__ == "__main__":
    sys.exit(main())
