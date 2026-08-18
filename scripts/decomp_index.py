#!/usr/bin/env python3
"""
decomp_index.py -- the pass's door into the pre-exported decompilation corpus.

A reconstruction pass must NEVER run Ghidra. The project database takes an
EXCLUSIVE lock, so N passes would serialise on it and one crashed session leaves
a stale lock that blocks everyone. Decompilation is paid ONCE, in bulk
(scripts/ghidra_scripts/NSS5ExportAll.java + NSS5ExportList.java), and after that
the corpus is plain files that any number of passes read concurrently.

    python scripts/decomp_index.py --find TFormation.GetRow
    python scripts/decomp_index.py --find 0x004d8aba
    python scripts/decomp_index.py --coverage
    python scripts/decomp_index.py --todo            # writes extracted/decomp_todo.txt
"""

import argparse
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DECOMP = os.path.join(ROOT, "extracted", "decomp")
VTABLE_MAP = os.path.join(ROOT, "extracted", "vtable_map.tsv")
FUNC_INV = os.path.join(ROOT, "extracted", "ghidra", "function_inventory.tsv")
TODO = os.path.join(ROOT, "extracted", "decomp_todo.txt")

NAME_RE = re.compile(r"^(?P<stem>.+)@(?P<va>[0-9a-fA-F]{8})\.c$")


def index():
    """{va_lowercase_hex_no_prefix: absolute path}"""
    out = {}
    if not os.path.isdir(DECOMP):
        return out
    for fn in os.listdir(DECOMP):
        m = NAME_RE.match(fn)
        if m:
            out[m.group("va").lower()] = os.path.join(DECOMP, fn)
    return out


def rows(path, ncols):
    try:
        with open(path, encoding="utf-8-sig") as fh:
            fh.readline()
            for line in fh:
                p = line.rstrip("\n").split("\t")
                if len(p) >= ncols:
                    yield p
    except OSError:
        return


def resolve(token):
    """Accept 0xVA, VA, or Type.Member and return (va, path or None)."""
    t = token.strip()
    if re.fullmatch(r"(0x)?[0-9a-fA-F]{6,8}", t):
        va = t[2:] if t.lower().startswith("0x") else t
        va = va.rjust(8, "0").lower()
        return va, index().get(va)
    if "." in t:
        tname, member = t.split(".", 1)
        hits = [p for p in rows(VTABLE_MAP, 7)
                if p[0] == tname and p[2] == member and p[5]]
        if not hits:
            return None, None
        if len(hits) > 1:
            print("ambiguous, %d matches:" % len(hits))
            for p in hits:
                print("  %s  slot %s  sig %s" % (p[5], p[4], p[3]))
            return None, None
        va = hits[0][5][2:].lower()
        return va, index().get(va)
    return None, None


def main():
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--find", help="0xVA, VA, or Type.Member")
    ap.add_argument("--coverage", action="store_true")
    ap.add_argument("--todo", action="store_true",
                    help="write the address list for the remaining Ghidra pass")
    args = ap.parse_args()

    if args.find:
        va, path = resolve(args.find)
        if va is None:
            print("could not resolve %r" % args.find)
            return 2
        if path is None:
            print("0x%s  NOT EXPORTED\n"
                  "  This is one of the functions still missing from the corpus.\n"
                  "  Do NOT open Ghidra yourself -- add it to extracted/decomp_todo.txt\n"
                  "  (python scripts/decomp_index.py --todo) and report it as blocked."
                  % va)
            return 1
        print(path)
        return 0

    idx = index()
    code = [p for p in rows(FUNC_INV, 3) if p[2] == "code"]
    have = [p for p in code if p[0].lower() in idx]
    missing = [p for p in code if p[0].lower() not in idx]

    if args.coverage or not args.todo:
        print("decompilation corpus : %s" % DECOMP)
        print("exported files       : %d" % len(idx))
        print("`code` functions     : %d" % len(code))
        print("  exported           : %d" % len(have))
        print("  MISSING            : %d  (the unattributed module-level functions)"
              % len(missing))
        print("\nAgents read these files. Passes do not run Ghidra.")

    if args.todo:
        with open(TODO, "w", encoding="utf-8", newline="\n") as fh:
            fh.write("# addresses with no decompilation export yet.\n")
            fh.write("# feed to NSS5ExportList.java in ONE locked Ghidra session.\n")
            for p in sorted(missing, key=lambda r: r[0]):
                fh.write("%s\t%s\t%s\n" % (p[0], p[1], p[3] if len(p) > 3 else ""))
        print("wrote %s  (%d addresses)" % (TODO, len(missing)))
    return 0


if __name__ == "__main__":
    sys.exit(main())
