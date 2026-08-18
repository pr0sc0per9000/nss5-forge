"""Resolve every recovered Global name to the address it actually occupies.

    python scripts/unify_names.py              # solve and report
    python scripts/unify_names.py --emit       # write extracted/global_address_map.tsv
    python scripts/unify_names.py --residual   # list what is still unresolved

This finishes name unification. It replaces comment archaeology with evidence taken from
NSS5.exe itself. addr_oracle.py explains where the evidence comes from; this is what
decides with it.

THE SHAPE OF THE PROBLEM
========================
For a body we hold, addr_oracle gives the module-global addresses the ORIGINAL function
touches, in machine-code order, and our body gives the Global names it uses, in first-use
order. Because our bodies are byte-identical, those two sequences describe the same
accesses in the same order -- so pairing them resolves names to addresses.

They are not the same LENGTH, though, and that is the whole difficulty. Only 158 of 356
bodies have equal counts. A function's code also carries dwords that are not Globals:
class-table pointers (TBall.New references 0x00C5AE98, which class_tables.tsv confirms is
TBall's own class table), lazy-init flags words (0x00C5A31C, 0x00C65CC0, 0x00C6E2AC --
every access to a lazily-initialised Global reads its guard first, which is why these
appear in hundreds of functions), and static string constants (0x00C5D284 and 0x00C5D680
appear only as `&PTR_PTR_...` passed to bbStringCompare -- address-taken, never
dereferenced, so they are literals rather than slots).

WHY NOT JUST FILTER THEM OUT AND ZIP
====================================
Because a filter that is even slightly too aggressive is worse than useless here, and
this was measured rather than assumed:

    exclusions                          bodies with equal counts    accuracy
    none                                            35                 71.4%
    + decompiler-confirmed refs only                99                 88.9%
    + class tables, flags words                    158                 92.9%
    + address-taken-only literals                  325                 75.5%

The last row is the trap. Dropping literals made almost every body's counts agree, which
looks like success and is the opposite: removing one real address shifts every later pair
by one. It transposed g_snd_click and g_snd_select -- adjacent slots, 0x00C6171C and
0x00C61720 -- and slid g_continents_combo one slot off. A zip demands a perfect filter,
and no filter is perfect.

WHAT IS ACTUALLY TRUE is weaker and safe: the names are a SUBSEQUENCE of the addresses,
in order. Extra addresses are gaps. So this aligns rather than zips, and uses the
conservative exclusion set (the 92.9% row) because the aligner does not need count
equality.

THE ALIGNER
===========
Ordinary sequence alignment: every name must be consumed, addresses may be skipped, order
is preserved. Each candidate pair is scored, and an incompatible pair is forbidden
outright:

  TYPE, from how the decompiler used the slot. Ghidra writes a pointer slot PTR_DAT_ or
    PTR_PTR_ and a scalar slot DAT_; `DAT_x >> 0x1f` is the signed-divide idiom and proves
    Int, while `(double)DAT_x` and `*(float *)&DAT_x` prove Float. In BlitzMax a String
    and an array are both object references, so both need a pointer slot. This is often
    decisive by itself: in TGadget.UpdateToolTip, g_activegadget is the only object Global
    and 0x00C61CF8 the only pointer slot, so the pair is forced without using order at all.

  SEEDS, the pairs a human already verified by hand in global_alias_overrides.tsv. These
    act as anchors that hold the alignment in frame across a gap.

  PROSE, the header annotations, worth little -- enough to break a tie, never enough to
    overrule the binary.

CERTAINTY IS COMPUTED, NOT ASSUMED
==================================
Taking one optimal alignment and believing it would hide the fact that several different
alignments often score identically. So this computes, for each name, every address that
lies on ANY optimal path (a forward and a backward pass, the standard construction). A
pair is FORCED only when exactly one address does. Everything else stays ambiguous and is
reported, because a wrong merge is worse than the split it fixes: a split makes one
variable into two and some writes go unseen, while a bad merge fuses two distinct
variables so writes to either corrupt the other. Silent omission versus silent corruption.

Bodies then vote. A name is only resolved when its bodies agree, and the tiers are:

    CERTAIN     forced in >=2 bodies, unanimous; or forced in 1 body and seed-confirmed
    STRONG      forced in exactly 1 body, or a >=80% majority across bodies
    AMBIGUOUS   bodies disagree, or no alignment forced it
    UNGROUNDED  the name appears in no body pairable with an original -- the binary has
                nothing to say, and only reading code will settle it
"""
import os
import re
import sys
import collections

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import addr_oracle as AO                                        # noqa: E402

OUT = os.path.join(ROOT, "extracted", "global_address_map.tsv")
SCALAR = {"int", "float", "double", "byte", "short", "long"}
NEG = float("-inf")

REF = re.compile(r"(&\s*)?\b(PTR_FUN_|PTR_PTR_|PTR_DAT_|FUN_|_?DAT_|s_)?(00c[0-9a-f]{5})\b")
PRAGMA = AO.PRAGMA


# ------------------------------------------------------------------ address typing

def excluded():
    """Addresses in the band that are provably not Globals."""
    out = set()
    ct = os.path.join(ROOT, "extracted", "class_tables.tsv")
    if os.path.exists(ct):
        for l in open(ct, encoding="utf-8", errors="replace").read().splitlines()[1:]:
            for c in l.split("\t")[1:3]:
                c = c.strip()
                if c.startswith("0x"):
                    try:
                        a = int(c, 16)
                    except ValueError:
                        continue
                    if AO.BAND_LO <= a < AO.BAND_HI:
                        out.add(a)
    # lazy-init guard words, decoded in module_emission_order.tsv
    for fn in ("module_emission_order.tsv", "module_globals_decoded.tsv"):
        p = os.path.join(ROOT, "extracted", fn)
        if not os.path.exists(p):
            continue
        lines = open(p, encoding="utf-8", errors="replace").read().splitlines()
        if not lines:
            continue
        head = lines[0].split("\t")
        ix = [i for i, h in enumerate(head) if "flags" in h.lower()]
        for l in lines[1:]:
            p2 = l.split("\t")
            for i in ix:
                if i < len(p2) and p2[i].strip().startswith("0x"):
                    try:
                        out.add(int(p2[i], 16))
                    except ValueError:
                        pass
    return out


def slot_kinds(path):
    """{addr: kind} from the decompilation. kind is ptr / int / float / num.

    Also returns the set of addresses the decompiler ever DEREFERENCES, which is what
    distinguishes a real slot from a static literal that is only address-taken.
    """
    kinds, deref = {}, set()
    for line in open(path, encoding="utf-8", errors="replace"):
        if line.strip().startswith("//"):
            continue
        for m in REF.finditer(line):
            amp, pre, hexa = m.group(1), m.group(2) or "", m.group(3)
            if pre.startswith("PTR_FUN") or pre == "FUN_" or pre == "s_":
                continue
            a = int(hexa, 16)
            if not (AO.BAND_LO <= a < AO.BAND_HI):
                continue
            if not amp:
                deref.add(a)
            if pre.startswith("PTR_"):
                kinds[a] = "ptr"
                continue
            if kinds.get(a) == "ptr":
                continue
            tok = "DAT_" + hexa
            k = kinds.get(a, "num")
            if re.search(re.escape(tok) + r"\s*(?:>>|&|\||\^|%)", line):
                k = "int"
            elif re.search(r"\(double\)\s*\(?\s*" + re.escape(tok), line) or \
                    re.search(r"\(float\s*\*\)\s*&\s*" + re.escape(tok), line):
                k = "float" if k in ("num", "float") else k
            kinds[a] = k
    return kinds, deref


def compat(decl_type, kind):
    t = decl_type.split("[")[0].lower()
    if "[" in decl_type or t not in SCALAR:
        return kind in ("ptr", None)
    if kind == "ptr":
        return False
    if kind == "int":
        return t in ("int", "byte", "short", "long")
    if kind == "float":
        return t in ("float", "double")
    return True


# ---------------------------------------------------------------------- alignment

def align(names, types, addrs, kinds, seed, prose):
    """Every address on some optimal monotone alignment, per name.

    Returns [set_of_addrs] parallel to names. A name whose set has one element was
    FORCED: every optimal alignment agrees on it.
    """
    n, m = len(names), len(addrs)
    if n == 0 or m < n:
        return [set() for _ in names]

    def score(i, j):
        ty, a = types[names[i]], addrs[j]
        if not compat(ty, kinds.get(a)):
            return NEG
        s = 1.0
        if seed.get(names[i]) == a:
            s += 10.0
        elif names[i] in seed:
            return NEG          # a verified pair forbids every other address
        if prose.get(names[i], {}).get(a):
            s += 3.0
        return s

    # forward: f[i][j] = best score aligning names[:i] into addrs[:j]
    f = [[NEG] * (m + 1) for _ in range(n + 1)]
    for j in range(m + 1):
        f[0][j] = 0.0
    for i in range(1, n + 1):
        for j in range(1, m + 1):
            best = f[i][j - 1]                       # skip address j-1
            if f[i - 1][j - 1] > NEG:
                s = score(i - 1, j - 1)
                if s > NEG:
                    best = max(best, f[i - 1][j - 1] + s)
            f[i][j] = best
    if f[n][m] == NEG:
        return [set() for _ in names]

    # backward: b[i][j] = best score aligning names[i:] into addrs[j:]
    b = [[NEG] * (m + 2) for _ in range(n + 2)]
    for j in range(m + 1):
        b[n][j] = 0.0
    for i in range(n - 1, -1, -1):
        for j in range(m - 1, -1, -1):
            best = b[i][j + 1]
            s = score(i, j)
            if s > NEG and b[i + 1][j + 1] > NEG:
                best = max(best, b[i + 1][j + 1] + s)
            b[i][j] = best

    opt = f[n][m]
    out = [set() for _ in names]
    for i in range(n):
        for j in range(m):
            s = score(i, j)
            if s == NEG or f[i][j] == NEG or b[i + 1][j + 1] == NEG:
                continue
            if abs(f[i][j] + s + b[i + 1][j + 1] - opt) < 1e-9:
                out[i].add(addrs[j])
    return out


# -------------------------------------------------------------------- prose prior
#
# Tokenise a comment line into ADDRESS and NAME atoms in positional order and pair
# ADJACENT atoms of opposite kind. A regex cannot do this safely: on
#     '   g_homeTeam:TTeam 0x00C5B218  g_possessionhome 0x00C5B25C
# an address-first regex binds 0x00C5B218 to g_possessionhome, off by one. As an atom
# stream the line reads N A N A, giving the two correct pairs. A line that does not
# alternate cleanly contributes nothing rather than a guess.

ATOM = re.compile(r"0x([0-9A-Fa-f]{6,8})|\b(g_[A-Za-z_]\w*)")


def prose_votes():
    votes = collections.defaultdict(collections.Counter)
    for tree in AO.TREES:
        if not os.path.isdir(tree):
            continue
        for fn in sorted(os.listdir(tree)):
            if not fn.endswith(".bmx"):
                continue
            text = open(os.path.join(tree, fn), encoding="utf-8",
                        errors="replace").read()
            decls = {m.group(1).lower() for m in PRAGMA.finditer(text)}
            if not decls:
                continue
            for line in text.split("\n"):
                if not line.strip().startswith("'"):
                    continue
                atoms = [("A", int(m.group(1), 16)) if m.group(1)
                         else ("N", m.group(2).lower())
                         for m in ATOM.finditer(line)]
                for i in range(len(atoms) - 1):
                    (k1, v1), (k2, v2) = atoms[i], atoms[i + 1]
                    if k1 == k2:
                        continue
                    a, nm = (v1, v2) if k1 == "A" else (v2, v1)
                    if nm in decls and AO.BAND_LO <= a < AO.BAND_HI:
                        votes[nm][a] += 1
    return votes


# ------------------------------------------------------------------------- solve

def solve():
    excl = excluded()
    seed = AO.seeds()
    prose = prose_votes()
    bodies = AO.collect()

    forced = collections.defaultdict(collections.Counter)     # name -> addr -> bodies
    seen_in = collections.Counter()
    for b in bodies:
        kinds, deref = slot_kinds(b["decomp"])
        addrs = [a for a in b["addrs"]
                 if a in kinds and a in deref and a not in excl]
        names = b["use"]
        for n in names:
            seen_in[n] += 1
        res = align(names, b["types"], addrs, kinds, seed, prose)
        for nm, cands in zip(names, res):
            if len(cands) == 1:
                forced[nm][next(iter(cands))] += 1

    out = {}
    for nm, votes in forced.items():
        tot = sum(votes.values())
        addr, hits = votes.most_common(1)[0]
        frac = float(hits) / tot
        if len(votes) == 1 and hits >= 2:
            tier, why = "CERTAIN", "forced in %d bodies, unanimous" % hits
        elif len(votes) == 1 and seed.get(nm) == addr:
            tier, why = "CERTAIN", "forced, agrees with verified pair"
        elif len(votes) == 1:
            tier, why = "STRONG", "forced in 1 body"
        elif frac >= 0.8:
            tier, why = "STRONG", "%d/%d bodies agree" % (hits, tot)
        else:
            out[nm] = (None, "AMBIGUOUS", "bodies disagree: %s"
                       % " ".join("%08x:%d" % kv for kv in votes.most_common()))
            continue
        out[nm] = (addr, tier, why)

    # every declared name, so ungrounded ones are still accounted for
    types = {}
    for tree in AO.TREES:
        if not os.path.isdir(tree):
            continue
        for fn in sorted(os.listdir(tree)):
            if not fn.endswith(".bmx"):
                continue
            t = open(os.path.join(tree, fn), encoding="utf-8",
                     errors="replace").read()
            for m in PRAGMA.finditer(t):
                types.setdefault(m.group(1).lower(), re.sub(r"\s+", "", m.group(2)))
    for nm in types:
        if nm not in out:
            out[nm] = (None, "AMBIGUOUS" if seen_in.get(nm) else "UNGROUNDED",
                       "no alignment forced it (%d bodies)" % seen_in.get(nm, 0)
                       if seen_in.get(nm) else "in no body pairable with an original")
    return out, types, seed, seen_in


def main():
    res, types, seed, seen_in = solve()
    tiers = collections.Counter(v[1] for v in res.values())
    print("NAME UNIFICATION -- alignment against NSS5.exe machine code")
    print("  distinct Global names : %d" % len(res))
    for t in ("CERTAIN", "STRONG", "AMBIGUOUS", "UNGROUNDED"):
        print("    %-11s %d" % (t, tiers[t]))
    print()

    ok = bad = 0
    wrong = []
    for nm, a in seed.items():
        r = res.get(nm)
        if r and r[0] is not None:
            if r[0] == a:
                ok += 1
            else:
                bad += 1
                wrong.append((nm, r[0], a, r[1]))
    tot = ok + bad
    print("VALIDATION against %d hand-verified pairs (%d resolved)" % (len(seed), tot))
    print("  agree %d  disagree %d  accuracy %.1f%%"
          % (ok, bad, (100.0 * ok / tot) if tot else 0.0))
    for nm, g, w, t in wrong[:12]:
        print("    %-28s solver=%08x human=%08x [%s]" % (nm, g, w, t))
    print()

    groups = collections.defaultdict(list)
    for nm, (a, t, _w) in res.items():
        if a is not None:
            groups[a].append(nm)
    multi = {a: v for a, v in groups.items() if len(v) > 1}
    print("ALIAS SPLITS: %d addresses carry >1 name  (%d names to merge away)"
          % (len(multi), sum(len(v) - 1 for v in multi.values())))
    for a in sorted(multi, key=lambda k: -len(multi[k]))[:15]:
        print("    %08x  %s" % (a, "  ".join(sorted(multi[a]))))

    if "--residual" in sys.argv:
        print("\nUNRESOLVED")
        for nm, (a, t, w) in sorted(res.items()):
            if a is None:
                print("  %-11s %-34s %-14s %s" % (t, nm, types.get(nm, "?"), w))

    if "--emit" in sys.argv:
        with open(OUT, "w", encoding="utf-8", newline="") as f:
            f.write("name\taddress\ttier\ttype\tbodies\tevidence\n")
            for nm, (a, t, w) in sorted(res.items()):
                f.write("%s\t%s\t%s\t%s\t%d\t%s\n"
                        % (nm, ("0x%08X" % a) if a is not None else "-", t,
                           types.get(nm, "?"), seen_in.get(nm, 0), w))
        print("\nwrote %s" % OUT)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
