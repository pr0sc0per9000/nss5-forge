"""List the game main module's still-unrecovered functions -- the ones nobody has opened.

The endgame question changed from "byte-exact everything" to "is there a surprise hiding in
the part we have never read". That needs the list split three ways, because "outstanding" in
coverage.py conflates them:

  NEVER OPENED   no file anywhere in src/ -- genuinely unread code
  IN PROGRESS    a candidate exists in src/recovered_unverified/ -- read and understood,
                 just not byte-exact yet
  ON DISK        a file exists in src/recovered/ without a byte-equality claim

Only the first group can hide a surprise. Usage:

    python scripts/outstanding_game.py [--shards N] [--never-opened]
    python scripts/outstanding_game.py --thirdparty [--shards N]

THE OTHER TREE  (--thirdparty)
------------------------------
Same coverage.py calls, the other side of the same partition: everything in the universe
the game's own main module does not own. Those live in
src/recovered_thirdparty/<module>/ -- the zip module and the bitmap-font/text renderer --
and nothing in the large/sweep phases touches them, so a pass sharding over Types here
cannot collide with one working the main list.

Two things in this view are not really the bundled modules' and are listed anyway,
because nobody has proved otherwise: the TVolume/TWinVolume/TWinVolumeDriver/TVolSpace
family (2,157 bytes -- see coverage.UNATTRIBUTED_PROBABLY_MODULE) and the six BLIde
`z_*` background Types, one pair per bundled module. Both are counted against this
project until somebody can name the module that ships them.

That view groups by owning Type rather than by size, and the difference is deliberate:
these modules are mostly 14-byte New/Delete stubs hanging off a Type, so a pass that owns a
whole Type reads its field layout once and banks every stub on it, instead of 20 passes
each re-deriving the same layout. --shards therefore packs whole Types, not functions.
"""
import csv
import glob
import os
import re
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import coverage as C

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))


def candidate_index():
    """{label_lower: path} for every body sitting in the unverified/candidate trees.

    Note that src/recovered_unverified/ is now scanned by coverage.load_recovered()
    itself, so a body there that carries an unretracted byte-equality claim already
    counts as MATCHED and never reaches this index. What lands in IN PROGRESS is what
    is genuinely still open.
    """
    idx = {}
    for d in ("recovered_unverified", "recovered", "recovered_module"):
        for p in glob.glob(os.path.join(ROOT, "src", d, "*.bmx")):
            base = os.path.basename(p)[:-4]
            idx.setdefault(base.lower(), p)
            # files are named Type.Method.bmx or Fn_<va>.Name.bmx
            m = re.match(r"^(Fn_[0-9a-fA-F]+)\.", base)
            if m:
                idx.setdefault(m.group(1).lower(), p)
    return idx


def thirdparty(inv, uni, owner_of, matched, decl, shards):
    """The functions the game's own module does NOT own, grouped by owning Type.

    Ownership comes from coverage.load_universe()'s own owner map, not from
    re-deriving it out of the label here: a module-level Function's label carries no
    dot, so the old `lab.split(".")[0] in decl` test filed every one of them under
    "third-party". coverage.py now decides it once, from
    extracted/type_declaration_order.tsv for Type methods and from
    extracted/module_functions.tsv's `owner` column for module-level Functions.
    """
    out = []
    for va, lab in uni.items():
        if va in matched:
            continue
        if owner_of.get(va) == "game":
            continue
        out.append((va, lab, inv[va]))

    bytype = {}
    for va, lab, n in out:
        bytype.setdefault(lab.split(".", 1)[0] if "." in lab else "<module>",
                          []).append((va, lab, n))

    groups = sorted(bytype.items(), key=lambda kv: -sum(x[2] for x in kv[1]))
    total = sum(n for _v, _l, n in out)
    print("outstanding bundled-module: %d functions, %d bytes, %d Types"
          % (len(out), total, len(groups)))
    print()
    for t, items in groups:
        print("%-28s %4d fns %7d bytes" % (t, len(items), sum(x[2] for x in items)))

    if shards > 1:
        # greedy longest-processing-time bin packing on bytes, so no pass gets a shard
        # that is all 14-byte stubs while another gets every real body.
        bins = [[] for _ in range(shards)]
        load = [0] * shards
        for t, items in groups:
            i = load.index(min(load))
            bins[i].append(t)
            load[i] += sum(x[2] for x in items)
        print()
        for i, b in enumerate(bins):
            print("SHARD %d  (%d bytes): %s" % (i, load[i], " ".join(b)))


def main():
    shards = 1
    if "--shards" in sys.argv:
        shards = int(sys.argv[sys.argv.index("--shards") + 1])
    only_never = "--never-opened" in sys.argv

    inv = C.load_inventory()
    brl = C.load_brl()
    uni, owner_of = C.load_universe(inv, brl)
    rec = C.load_recovered()
    matched = {va for va, (_p, ok) in rec.items() if ok}

    decl = set()
    with open(os.path.join(C.EX, "type_declaration_order.tsv"), encoding="utf-8") as f:
        for r in csv.DictReader(f, delimiter="\t"):
            decl.add(r["type"])

    if "--thirdparty" in sys.argv:
        thirdparty(inv, uni, owner_of, matched, decl, shards)
        return

    cand = candidate_index()

    rows = []
    for va, lab in uni.items():
        if va in matched:
            continue
        if owner_of.get(va) != "game":
            continue          # bundled module code, shown by --thirdparty
        n = inv.get(va, 0)
        if va in rec:
            state = "ON DISK"
            path = rec[va][0]
        else:
            hit = cand.get(lab.lower()) or cand.get(("fn_" + va[2:]).lower())
            if hit:
                state = "IN PROGRESS"
                path = hit
            else:
                state = "NEVER OPENED"
                path = "-"
        rows.append((state, va, lab, n, path))

    rows.sort(key=lambda r: -r[3])
    if only_never:
        rows = [r for r in rows if r[0] == "NEVER OPENED"]

    agg = {}
    for state, _va, _lab, n, _p in rows:
        agg.setdefault(state, [0, 0])
        agg[state][0] += 1
        agg[state][1] += n
    print("game main module, still unmatched:")
    for k in ("NEVER OPENED", "IN PROGRESS", "ON DISK"):
        if k in agg:
            print("   %-13s %4d fns %8d bytes" % (k, agg[k][0], agg[k][1]))
    print()

    for state, va, lab, n, path in rows:
        tail = "" if path == "-" else "   <- " + os.path.relpath(path, ROOT).replace("\\", "/")
        print("%-13s %s %7d  %s%s" % (state, va, n, lab, tail))

    if shards > 1:
        print()
        bins = [[] for _ in range(shards)]
        load = [0] * shards
        for state, va, lab, n, _p in rows:
            i = load.index(min(load))
            bins[i].append("%s %s %d" % (va, lab, n))
            load[i] += n
        for i, b in enumerate(bins):
            print("SHARD %d (%d bytes, %d fns): %s" % (i, load[i], len(b), "; ".join(b)))


if __name__ == "__main__":
    main()
