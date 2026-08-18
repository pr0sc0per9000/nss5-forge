"""Dump everything known about one Global, so a merge decision can be made from evidence.

    python scripts/explain_global.py g_ec_club
    python scripts/explain_global.py 0x00C653D8      # or by address, for a whole group

Written for the passes finishing name unification. Each of them has to answer one of two
questions -- "which address does this name occupy?" or "are these two names the same slot,
and if so what type is it?" -- and both are answerable from the binary. This gathers the
evidence in one place so that work is reading rather than searching:

  * every recovered body that declares the name, with the type it declares and the lines
    that use it;
  * the addresses the ORIGINAL of each of those bodies touches, in machine-code order,
    which is the ordered evidence unify_names.py aligns against;
  * how Ghidra typed each candidate slot (pointer vs scalar, and Int vs Float from the
    `>> 0x1f` signed-divide idiom);
  * the other names already resolved to the same address, and what tier they hold;
  * co-occurrence: names sharing a body with this one, which CANNOT be the same slot;
  * whatever the body headers claim in prose, quoted but marked as unverified.

The prose is shown last and labelled, deliberately. It is the weakest evidence here -- it
is what a human typed while recovering the body, and the whole reason name unification was
needed is that those annotations disagree with each other.
"""
import os
import re
import sys
import collections

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import addr_oracle as AO                                        # noqa: E402
import unify_names as UN                                        # noqa: E402


def load_map():
    out = {}
    p = os.path.join(ROOT, "extracted", "global_address_map.tsv")
    if os.path.exists(p):
        for l in open(p, encoding="utf-8").read().splitlines()[1:]:
            f = l.split("\t")
            if len(f) >= 6:
                out[f[0]] = f[1:]
    return out


def main():
    if len(sys.argv) < 2:
        raise SystemExit(__doc__)
    arg = sys.argv[1].strip().lower()
    amap = load_map()
    excl = UN.excluded()

    if arg.startswith("0x"):
        want = "0x%08X" % int(arg, 16)
        names = sorted(n for n, v in amap.items() if v[0] == want)
        print("ADDRESS %s -- %d name(s) resolved here" % (want, len(names)))
        for n in names:
            v = amap[n]
            print("   %-34s %-16s %-10s %s bodies   %s"
                  % (n, v[2], v[1], v[3], v[4]))
        print()
        targets = names
    else:
        targets = [arg]

    bodies = AO.collect()
    by_name = collections.defaultdict(list)
    for b in bodies:
        for n in b["types"]:
            by_name[n].append(b)

    for name in targets:
        v = amap.get(name)
        print("=" * 78)
        print("GLOBAL %s" % name)
        if v:
            print("  solver: address=%s tier=%s type=%s bodies=%s  (%s)"
                  % (v[0], v[1], v[2], v[3], v[4]))
        else:
            print("  solver: not in the address map")
        bl = by_name.get(name, [])
        print("  declared by %d body/bodies pairable with an original" % len(bl))
        print()

        for b in bl:
            kinds, deref = UN.slot_kinds(b["decomp"])
            addrs = [a for a in b["addrs"]
                     if a in kinds and a in deref and a not in excl]
            print("  --- %s   (original at 0x%08X)" % (b["file"], b["va"]))
            print("      declares : %s" % ", ".join(
                "%s:%s" % (n, b["types"][n]) for n in b["use"]))
            print("      original touches, in machine-code order:")
            print("        %s" % "  ".join(
                "%08x[%s]" % (a, kinds.get(a, "?")) for a in addrs))
            path = None
            for tree in AO.TREES:
                p = os.path.join(tree, b["file"] + ".bmx")
                if os.path.exists(p):
                    path = p
                    break
            if path:
                for i, line in enumerate(open(path, encoding="utf-8",
                                              errors="replace"), 1):
                    if line.lstrip().startswith("'"):
                        continue
                    if re.search(r"\b%s\b" % re.escape(name), line, re.I):
                        print("      %-5d %s" % (i, line.rstrip()[:96]))
            print()

        co = set()
        for b in bl:
            co |= set(b["types"]) - {name}
        if co:
            print("  CANNOT be the same slot as (shares a body): %s"
                  % ", ".join(sorted(co)))

        if v and v[0] != "-":
            sib = sorted(n for n, x in amap.items()
                         if x[0] == v[0] and n != name)
            if sib:
                print("  already resolved to the SAME address: %s" % ", ".join(sib))
        print()

        quoted = []
        for tree in AO.TREES:
            if not os.path.isdir(tree):
                continue
            for fn in sorted(os.listdir(tree)):
                if not fn.endswith(".bmx"):
                    continue
                for line in open(os.path.join(tree, fn), encoding="utf-8",
                                 errors="replace"):
                    if line.strip().startswith("'") and re.search(
                            r"\b%s\b" % re.escape(name), line, re.I) and "0x" in line:
                        quoted.append("%-46s %s" % (fn[:-4], line.strip()[:100]))
        if quoted:
            print("  PROSE annotations (UNVERIFIED -- weakest evidence, may disagree):")
            for q in quoted[:12]:
                print("    %s" % q)
        print()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
