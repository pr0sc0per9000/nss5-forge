"""Rebuild extracted/runtime_helpers.tsv from an assembled build.

    python scripts/assemble.py
    python scripts/learn_helpers.py

WHY
===
The byte oracle masks a call into the C runtime only when it can name both ends.
Our side names itself (`objdump -r` on the object), but NSS5.exe is stripped, so the
original's helper addresses have to be learned, and they were learned one probe at a
time into extracted/runtime_helpers.tsv. That file is generated and gitignored, so a fresh
clone has none, and with none the oracle reads every runtime call as a difference.

This rebuilds it in one pass. For every body that carries the byte-identical marker, it
takes our copy out of the assembled exe and the original at the body's own VA: where our
object has a relocation to a runtime symbol, the rel32 at the same offset in the original
is that symbol's address there. Only bodies whose length agrees, and only call and jump
sites whose opcode byte agrees, are used. One address seen under two names is printed and
left out.
"""
import os
import struct
import sys
from collections import Counter, defaultdict

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import bytematch as B          # noqa: E402
import claim as K              # noqa: E402
import helper_map as H         # noqa: E402

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
EXE = os.path.join(ROOT, "src", "assembled", "nss5_assembled.exe")
TREES = ("src/recovered", "src/recovered_module", "src/recovered_thirdparty")


def main():
    if not os.path.exists(EXE):
        print("no %s -- run scripts/assemble.py first" % EXE)
        return 2
    objdir = os.path.join(ROOT, "src", "assembled", ".bmx")
    objs = [os.path.join(objdir, f) for f in os.listdir(objdir)
            if f.endswith(".o") and ".debug." not in f]
    sizes = B.ghidra_sizes()
    ob, oimg, osecs = B.load(B.ORIG)
    ova2off = B._helpers(ob, oimg, osecs)[0]
    ub, uimg, usecs = B.load(EXE)
    uva2off = B._helpers(ub, uimg, usecs)[0]

    ourva, sites = {}, {}
    for o in objs:
        syms = H.object_symbols(o)
        base = H.resolve_base(o, EXE, syms)
        if base is None:
            continue
        for s, off in syms.items():
            m = H.BB_METHOD_RX.match(s)
            if m:
                ourva.setdefault("%s.%s" % (m.group(1), m.group(2)), base + off)
            elif s.startswith("_bb_"):
                ourva.setdefault(s[4:], base + off)
        for off, kind, sym in H.code_relocations(o):
            if kind == "DISP32":
                sites[base + off] = sym

    votes, used = defaultdict(Counter), 0
    for tree in TREES:
        for dp, _dn, fns in os.walk(os.path.join(ROOT, tree)):
            for fn in fns:
                if not fn.endswith(".bmx"):
                    continue
                _head, vs, matched = K.read(os.path.join(dp, fn))
                if not matched or not vs:
                    continue
                ova = int(vs[0], 16)
                n = sizes.get(ova)
                stem = fn[:-4]
                if stem.startswith("Fn_") and "." in stem:
                    stem = stem.split(".", 1)[1]
                uva = ourva.get(stem)
                if not n or uva is None:
                    continue
                a = ob[ova2off(ova):ova2off(ova) + n]
                c = ub[uva2off(uva):uva2off(uva) + n]
                if len(a) != n or len(c) != n or a[:3] != c[:3]:
                    continue
                used += 1
                for k in range(1, n - 3):
                    s = sites.get(uva + k)
                    if s is None or s.startswith(("__bb_", "_bb_")):
                        continue
                    if a[k - 1] != c[k - 1] or a[k - 1] not in (0xE8, 0xE9):
                        continue
                    votes[ova + k + 4 + struct.unpack_from("<i", a, k)[0]][s] += 1

    table = {}
    for va, c in votes.items():
        if not (H.RT_LO <= va < H.RT_HI):
            continue
        if len(c) > 1:
            print("  two names for 0x%08x, left out: %s" % (va, dict(c)))
            continue
        (sym, n), = c.most_common(1)
        table[va] = (sym, n)
    H.save_table(table)
    print("bodies aligned: %d   runtime helpers written: %d   -> %s"
          % (used, len(table), os.path.relpath(H.TABLE, ROOT)))
    return 0


if __name__ == "__main__":
    sys.exit(main())
