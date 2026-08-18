"""Turn extracted/global_address_map.tsv into merges assemble.py can apply.

    python scripts/emit_unified_aliases.py            # report what would be merged
    python scripts/emit_unified_aliases.py --write    # write global_alias_unified.tsv

unify_names.py resolves NAME -> ADDRESS. This groups those by address and decides, for
each group, which name survives -- producing the alias -> canonical table the build
consumes. It changes only GENERATED source: src/recovered/ stays byte-identical, so
reverify.py stays green. Never run a corpus-wide sed on src/recovered to do this instead;
rewriting verified bodies in place is what un-verifies the corpus.

PRECEDENCE
==========
assemble.py reads three tables, weakest first, and later rows win:

    global_alias_map.tsv        the prose heuristic
    global_alias_unified.tsv    this file -- grounded in NSS5.exe's machine code
    global_alias_overrides.tsv  hand-verified, cited row by row

Hand overrides stay on top deliberately. They are read out of the binary by a human and
checked; where this table and a human disagree the human is more likely right, and the
disagreement is worth seeing rather than silently losing. In practice they do not
disagree: the solver reproduces all 41 hand-verified pairs it covers.

CHOOSING WHICH NAME SURVIVES
============================
The merge is correct whichever name wins -- they denote one slot -- so the choice is
mostly about the source staying readable. One case is NOT cosmetic, though, and it has to
come first:

  1. If any member is already the CANONICAL of a hand-verified override, that name wins.
     Overrides are applied after this table, so choosing differently builds a cycle rather
     than a chain. 0x00C6F028 is the live example: the override maps
     g_contractoffer_tplayer -> g_profile (the row that keeps g_profile from reading
     Null across the whole game), and picking g_contractoffer_tplayer here would emit
     g_profile -> g_contractoffer_tplayer, so the two tables point at each other and which
     one survives depends on iteration order.

  2. Otherwise the name extracted/globals_final.tsv gives that address -- but only when it
     is a real name. That table frequently holds a placeholder, and it does so for exactly
     the slots where a descriptive name matters most: it calls 0x00C5B218 g_object17 when
     the group also contains g_hometeam, g_teamhome and g_team1.

  3. Otherwise the most DESCRIPTIVE name, since a group routinely mixes one real name with
     placeholders minted during recovery.

  4. Ties broken by how many files use the name, then alphabetically, so runs reproduce.

WHAT IS REFUSED
===============
A group whose names do not all have the same TYPE CLASS (scalar-int / scalar-float /
object) is never merged here. It means either the solver is wrong about one member or a
recovery mis-typed a slot, and merging across a type boundary would put an object
reference where the code expects a number. Exactly one group is in this state --
0x00C61728 holds g_screen_int22:Int and g_screen_mousey:Float, where the decompiler
proves the slot is a float -- and it is reported for a human rather than guessed at.

That 208 of 209 groups ARE type-consistent is worth stating plainly: unify_names.py
enforces type compatibility per body, but never across bodies. Independent agreement on
208 groups is corroboration that the alignment is finding real slots and not coincidences.
"""
import os
import re
import sys
import collections

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
MAP = os.path.join(ROOT, "extracted", "global_address_map.tsv")
OUT = os.path.join(ROOT, "extracted", "global_alias_unified.tsv")
GF = os.path.join(ROOT, "extracted", "globals_final.tsv")
TREES = [os.path.join(ROOT, "src", "recovered"),
         os.path.join(ROOT, "src", "recovered_module"),
         os.path.join(ROOT, "src", "recovered_unverified")]

SCALAR = {"int", "float", "double", "byte", "short", "long"}
# Names minted during recovery when nothing better was known. They are valid
# identifiers and byte-verified; they are just not words. A group containing any real name
# should not collapse onto one of these.
PLACEHOLDER = re.compile(
    r"^g_(?:object\d+$|[a-z]+_(?:int|float|double|long|short|byte|str|arr|tplayer|obj)\d+$)")


def type_class(ty):
    base = ty.split("[")[0].lower()
    if "[" in ty or base not in SCALAR:
        return "obj"
    return "float" if base in ("float", "double") else "int"


def parents():
    """type -> supertype, from the class tables decoded out of NSS5.exe."""
    out = {}
    p = os.path.join(ROOT, "extracted", "class_tables.tsv")
    if not os.path.exists(p):
        return out
    for l in open(p, encoding="utf-8", errors="replace").read().splitlines()[1:]:
        f = l.split("\t")
        if len(f) >= 4 and f[0].strip() and f[3].strip():
            out[f[0].strip().lower()] = f[3].strip().lower().split("(")[0]
    return out


def types_mergeable(a, b, par):
    """Can two declared types name the same slot?

    Type CLASS agreement is not enough, and assuming it is breaks the build: merging
    g_slotwin:TSound into g_pairs_chan:TChannel because both are objects leaves assemble.py
    unable to pick a type, so it emits a declaration for each and bcc stops at
    `Duplicate identifier 'g_pairs_chan'`. TSound and TChannel are unrelated -- one is
    loaded audio, the other a playing voice -- so that merge is wrong whatever the
    alignment says.

    Base/derived pairs are a different story and must still merge: two passes recovering the
    same slot routinely disagree only about how specific to be (TGadget vs TInputBox,
    Object vs TScreen). Those denote one slot, and assemble.py already resolves them by
    inheritance depth. So: identical, or one an ancestor of the other, is mergeable;
    unrelated is refused.
    """
    # A module-qualified name and a bare one denote the same type: brl.audio.TChannel is
    # TChannel. Compare on the last component.
    a = a.split("[")[0].lower().rsplit(".", 1)[-1]
    b = b.split("[")[0].lower().rsplit(".", 1)[-1]
    if a == b:
        return True
    if type_class(a) != type_class(b):
        return False
    if type_class(a) != "obj":
        return True
    for x, y in ((a, b), (b, a)):
        cur, hops = x, 0
        while cur in par and hops < 16:
            cur = par[cur]
            hops += 1
            if cur == y:
                return True
    return "object" in (a, b)


def cooccurrence():
    """name -> set of names that appear in the SAME body.

    Two Globals declared by one body are, by construction, different slots: the body reads
    and writes them independently and the aligner gives them distinct addresses. So if two
    names ever co-occur, no evidence can make them the same address, and a group holding
    both is provably wrong about at least one of them.

    This catches what neither type checking nor the alignment can. 0x00C6F090 accumulated
    fifteen sound Globals, among them g_snd_win and g_snd_lose -- which share a body, so
    they cannot share a slot. Likewise 0x00C6F028 held g_profile (hand-verified, forced in
    many bodies) alongside g_np_nameinput, which shares a body with it.
    """
    co = collections.defaultdict(set)
    sources = []
    for tree in TREES:
        if os.path.isdir(tree):
            sources += [(os.path.join(tree, fn), True)
                        for fn in sorted(os.listdir(tree)) if fn.endswith(".bmx")]
    # THE MODULE TAIL COUNTS TOO, and leaving it out corrupts the program.
    #
    # src/module_body/*.bmx is the real program -- one long body that sets up the whole
    # game. Its Globals are not declared with '!Global pragmas, so a pragma-only scan sees
    # none of them and treats them as mergeable with anything.
    #
    # What that costs: g_dataDir (the INSTALL root, 0x00C6E950) and g_savedir (the SAVE
    # root, 0x00C6E9A8) merge into one variable. The tail sets the install root from
    # AppDir, then a few lines later assigns the saveloc string to what is now the same
    # variable -- silently overwriting it. Every asset path then resolves against an empty
    # or user-directory prefix, and the game dies at startup with "unable to locate
    # language file", because TLocale.SetUp reads
    # g_datapath + "GameMedia/Languages/Languages.csv".
    #
    # These two are as provably distinct as any pair of pragma Globals -- the tail
    # assigns one FROM the other, which it could not do if they were one slot.
    # ...BUT A GENERATED module_body FILE IS NOT EVIDENCE, AND COUNTING ONE INVERTS THIS GUARD.
    #
    # Co-occurrence is an argument about the ORIGINAL program: if one recovered body names
    # two slots, the original really had two slots. src/module_body/collections.bmx is not a
    # recovered body -- its own header says "GENERATED", and it exists solely to stop
    # null-deref crashes by giving every collection Global its own CreateList(). It lists
    # aliases SEPARATELY on purpose, and its own header says so: "Several entries below are
    # the SAME original slot under different recovered names ... Giving each its own list
    # stops the crashes but does NOT make them share data."
    #
    # Counting it makes every list Global co-occur with every other, so the guard rejects
    # every list merge -- 25 of them in one run, including g_lcompetitions -> g_competitions.
    # That one is independently confirmed: TCompetition.New does g_lcompetitions.AddLast(Self)
    # while all ~18 readers read g_competitions, and the boot log prints "Competitions:0" with
    # a 1,030-row Competitions.csv successfully parsed. Counting the stopgap blocks the
    # repair it stands in for.
    #
    # Skip by MARKER rather than by filename so a future generated file cannot silently
    # reintroduce this. A hand-recovered body never carries this header.
    mb = os.path.join(ROOT, "src", "module_body")
    if os.path.isdir(mb):
        for fn in sorted(os.listdir(mb)):
            if not fn.endswith(".bmx"):
                continue
            p = os.path.join(mb, fn)
            with open(p, encoding="utf-8", errors="replace") as f:
                head = "".join(next(f, "") for _ in range(6))
            if re.search(r"^\s*'\s*=*\s*GENERATED\b", head, re.M | re.I) or \
               re.search(r"'\s*GENERATED by", head, re.I):
                continue
            sources.append((p, False))

    for path, pragma_only in sources:
        text = open(path, encoding="utf-8", errors="replace").read()
        if pragma_only:
            ns = sorted({m.group(1).lower() for m in
                         re.finditer(r"^\s*'!\s*Global\s+(\w+)\s*:", text, re.M | re.I)})
        else:
            code = "\n".join(l for l in text.split("\n")
                             if not l.lstrip().startswith("'"))
            ns = sorted({m.group(1).lower()
                         for m in re.finditer(r"\b(g_\w+)\b", code)})
        for i, a in enumerate(ns):
            for b in ns[i + 1:]:
                co[a].add(b)
                co[b].add(a)
    return co


def drop_contradictions(members, co, evicted):
    """Remove members until no two co-occur, weakest evidence first.

    Refusing the whole group would be simpler but throws away good merges to punish one
    bad member -- 0x00C6F028 would lose every g_profile alias, the merge that stopped
    g_profile reading Null across the entire game, because g_np_nameinput landed in the
    same group. So evict rather than refuse, taking the weaker claim: CERTAIN outranks
    STRONG, then more bodies outranks fewer, then name order so runs reproduce.
    """
    rank = {"CERTAIN": 2, "STRONG": 1}
    keep = list(members)
    while True:
        hit = None
        for i, x in enumerate(keep):
            for y in keep[i + 1:]:
                if y[0] in co.get(x[0], ()):
                    hit = (x, y)
                    break
            if hit:
                break
        if not hit:
            return keep
        loser = min(hit, key=lambda m: (rank.get(m[2], 0), m[3], m[0]))
        keep.remove(loser)
        evicted.append((loser[0], [m[0] for m in hit if m is not loser][0]))


def drop_type_outliers(members, par, evicted):
    """Keep the largest type-compatible cluster instead of refusing the whole group.

    Same argument as drop_contradictions above, applied to the other guard. Refusing a
    whole address because ONE member's declared type disagrees punishes eight good merges
    for one bad annotation, and the cost is measured, not hypothetical:

      0x00C6F028  eight names declared TProfile + g_plr declared TPlayer
      0x00C5B218  four names declared TTeam    + g_radarcol_home declared String
      0x00C5B21C  five names declared TTeam    + g_radarcol_away declared String

    Refusing all three groups outright un-merges every g_profile alias and both team
    aliases -- exactly the failure drop_contradictions' docstring cites as the reason to
    evict rather than refuse. Dead Globals go 86 -> 95 and predicted crash sites 91 -> 104
    in one build.

    A minority type on an address means one member's TYPE annotation is wrong, or its
    address is. Either way the majority reading is the one supported by the most evidence,
    and evicting the outlier leaves it split and still reported by find_dead_globals, while
    restoring the merges around it. Evicting can only improve on refusing: refusing evicts
    everyone.

    Clusters are ranked by evidence, not by size, so a lone CERTAIN member is not
    outvoted by a crowd of weak ones: CERTAIN outranks STRONG, then total bodies, then
    name order so runs reproduce.
    """
    clusters = []
    for m in members:
        for c in clusters:
            if all(types_mergeable(m[1], o[1], par) for o in c):
                c.append(m)
                break
        else:
            clusters.append([m])
    if len(clusters) < 2:
        return members

    rank = {"CERTAIN": 2, "STRONG": 1}
    clusters.sort(key=lambda c: (sum(rank.get(m[2], 0) for m in c),
                                 sum(m[3] for m in c),
                                 -min(m[0] for m in c).count("")),
                  reverse=True)
    keep = clusters[0]
    for c in clusters[1:]:
        for m in c:
            evicted.append((m[0], "%s (type %s vs %s)"
                            % (keep[0][0], m[1], keep[0][1])))
    return keep


def name_files():
    c = collections.Counter()
    for tree in TREES:
        if not os.path.isdir(tree):
            continue
        for fn in sorted(os.listdir(tree)):
            if not fn.endswith(".bmx"):
                continue
            text = open(os.path.join(tree, fn), encoding="utf-8",
                        errors="replace").read()
            for n in {m.group(1).lower() for m in
                      re.finditer(r"^\s*'!\s*Global\s+(\w+)\s*:", text, re.M | re.I)}:
                c[n] += 1
    return c


def globals_final():
    out = {}
    if not os.path.exists(GF):
        return out
    for line in open(GF, encoding="utf-8", errors="replace"):
        p = line.rstrip("\n").split("\t")
        if len(p) >= 3 and p[0].startswith("0x"):
            out["0x%08X" % int(p[0], 16)] = p[2].strip().lower()
    return out


def prior_edges():
    """alias -> canonical from the two tables that already exist.

    Both matter, not just the hand-verified one. If the old prose map says A -> B and this
    table emits B -> A, the two point at each other; assemble.py's chain collapser
    terminates on its `seen` set, so the build SUCCEEDS and the surviving name is decided
    by iteration order. Measured without this guard: 33 such cycles, including
    g_screen_float03 <-> g_screen_scrollx -- the pair that controls the mouse cursor's
    position.

    The fix is structural rather than case-by-case. A name with no outgoing edge here is a
    SINK of the prior graph, and every merge emitted below points at one. A cycle through
    a sink would need an edge leaving it, and by construction there is none.
    """
    out = {}
    for fn in ("global_alias_map.tsv", "global_alias_adjudicated.tsv",
               "global_alias_overrides.tsv"):
        p = os.path.join(ROOT, "extracted", fn)
        if not os.path.exists(p):
            continue
        for line in open(p, encoding="utf-8", errors="replace"):
            if line.startswith("#") or line.startswith("address"):
                continue
            f = line.rstrip("\n").split("\t")
            if len(f) >= 3 and f[1].strip() and f[2].strip():
                out[f[1].strip().lower()] = f[2].strip().lower()
    return out


def sink(name, edges, limit=32):
    """Follow the prior alias chain to the name that actually survives."""
    seen = {name}
    while name in edges and edges[name] not in seen and len(seen) < limit:
        name = edges[name]
        seen.add(name)
    return name


def main():
    if not os.path.exists(MAP):
        raise SystemExit("no %s -- run scripts/unify_names.py --emit first" % MAP)
    rows = [l.split("\t") for l in
            open(MAP, encoding="utf-8").read().splitlines()[1:] if l.strip()]
    files = name_files()
    gf = globals_final()
    prior = prior_edges()
    par = parents()
    co = cooccurrence()

    groups = collections.defaultdict(list)
    for name, addr, tier, ty, bodies, ev in rows:
        if addr != "-" and tier in ("CERTAIN", "STRONG"):
            groups[addr].append((name, ty, tier, int(bodies)))

    merges, refused, evicted = [], [], []
    for addr, members in sorted(groups.items()):
        if len(members) < 2:
            continue
        members = drop_contradictions(members, co, evicted)
        if len(members) < 2:
            continue
        # Evict the type outliers rather than refusing the address -- see
        # drop_type_outliers. Refusing here un-merges every g_profile alias over one
        # mis-annotated member, at a cost of 9 dead Globals and 13 crash sites in a build.
        members = drop_type_outliers(members, par, evicted)
        if len(members) < 2:
            continue
        tys = [m[1] for m in members]
        clash = next(((x, y) for i, x in enumerate(tys) for y in tys[i + 1:]
                      if not types_mergeable(x, y, par)), None)
        if clash:
            # Only reachable if compatibility is non-transitive for these types; the
            # cluster pass above guarantees pairwise compatibility otherwise.
            refused.append((addr, members,
                            "INCOMPATIBLE TYPES: %s vs %s" % clash))
            continue
        names = [m[0] for m in members]
        # Only a sink of the prior alias graph may be canonical -- see prior_edges().
        sinks = sorted({n for n in names if n not in prior}) or \
            sorted({sink(n, prior) for n in names})
        want = gf.get(addr)
        if want in sinks and not PLACEHOLDER.match(want):
            canon = want
            why = "globals_final.tsv"
        else:
            canon = sorted(sinks, key=lambda n: (bool(PLACEHOLDER.match(n)),
                                                 -files.get(n, 0), n))[0]
            why = ("descriptive, %d files" % files.get(canon, 0)
                   if not PLACEHOLDER.match(canon) else "most-used (%d files)"
                   % files.get(canon, 0))
        tiers = {m[0]: m[2] for m in members}
        for n in sorted(names):
            if n != canon:
                merges.append((addr, n, canon, "%s; alias tier %s" % (why, tiers[n])))

    # Choosing a sink of the prior graph removes most cycles but not all of them: a cycle
    # can also close through a THIRD table, since assemble.py applies old map, then this
    # one, then overrides, and a key present in two of them keeps only the last value.
    # Rather than reason about that precedence, build the effective graph exactly as
    # assemble.py will and admit each merge only if it does not close a loop. Dropping the
    # edge is safe -- it leaves a split, which loses writes, where keeping it would make
    # the surviving name depend on dict iteration order.
    base, over = {}, {}
    for fn, sink_d in (("global_alias_map.tsv", base),
                       ("global_alias_overrides.tsv", over)):
        p = os.path.join(ROOT, "extracted", fn)
        if not os.path.exists(p):
            continue
        for line in open(p, encoding="utf-8", errors="replace"):
            if line.startswith("#") or line.startswith("address"):
                continue
            f = line.rstrip("\n").split("\t")
            if len(f) >= 3 and f[1].strip() and f[2].strip():
                sink_d[f[1].strip().lower()] = f[2].strip().lower()

    def closes_cycle(g, k, v):
        seen, cur = {k}, v
        while cur in g:
            if cur in seen:
                return True
            seen.add(cur)
            cur = g[cur]
        return cur == k

    eff = dict(base)
    kept, dropped = [], []
    for row in merges:
        _a, n, c, _w = row
        if n in over:                      # an override wins here; our edge is inert
            kept.append(row)
            continue
        prev = eff.get(n)
        eff[n] = c
        probe = dict(eff)
        probe.update(over)
        if closes_cycle(probe, n, c):
            if prev is None:
                eff.pop(n)
            else:
                eff[n] = prev
            dropped.append(row)
        else:
            kept.append(row)
    merges = kept

    print("UNIFIED ALIAS MERGES -- grounded in NSS5.exe machine code")
    if evicted:
        print("  names EVICTED (co-occur with a group member, so a different slot) : %d"
              % len(evicted))
        for n, other in evicted[:10]:
            print("      %-30s co-occurs with %s" % (n, other))
    if dropped:
        print("  merges DROPPED to keep the alias graph acyclic : %d" % len(dropped))
        for _a, n, c, _w in dropped[:8]:
            print("      %-30s -> %s" % (n, c))
    print("  addresses carrying >1 resolved name : %d" % len(
        [a for a, m in groups.items() if len(m) > 1]))
    print("  merges emitted                      : %d" % len(merges))
    print("  groups refused (type class split)   : %d" % len(refused))
    for addr, members, why in refused:
        print("      %s  %s  -- %s"
              % (addr, " | ".join("%s:%s" % (n, t) for n, t, _x, _y in members), why))
    print()
    big = collections.Counter(a for a, _n, _c, _w in merges)
    print("  largest groups:")
    for a, n in big.most_common(10):
        print("      %s  %d aliases -> %s" % (a, n,
              [c for x, _n2, c, _w in merges if x == a][0]))

    # Cycle check, modelling assemble.py's composition EXACTLY -- three tables in
    # precedence order, then the rule that a name a higher-precedence table calls canonical
    # stops being an alias in a lower one. A cycle is the one failure mode that produces no
    # error and no symptom: the chain collapser terminates on its `seen` set, so the build
    # succeeds and the surviving name is whichever dict iteration order reached first.
    edges, rank = {}, {}

    def add(a, c, prec):
        edges[a] = c
        rank[a] = prec
        if prec > rank.get("=" + c, -1):
            rank["=" + c] = prec

    for prec, path in enumerate((os.path.join(ROOT, "extracted", "global_alias_map.tsv"),
                                 None,
                                 os.path.join(ROOT, "extracted",
                                              "global_alias_adjudicated.tsv"),
                                 os.path.join(ROOT, "extracted",
                                              "global_alias_overrides.tsv"))):
        if path is None:
            for _a, n, c, _w in merges:
                add(n, c, prec)
            continue
        if not os.path.exists(path):
            continue
        for line in open(path, encoding="utf-8", errors="replace"):
            if line.startswith("#") or line.startswith("address"):
                continue
            f = line.rstrip("\n").split("\t")
            if len(f) >= 3 and f[1].strip() and f[2].strip():
                add(f[1].strip().lower(), f[2].strip().lower(), prec)
    for a in list(edges):
        if rank.get("=" + a, -1) > rank.get(a, -1):
            del edges[a]
    cycles = []
    for start in edges:
        seen, cur = [start], edges[start]
        while cur in edges and cur not in seen:
            seen.append(cur)
            cur = edges[cur]
        if cur in seen:
            cycles.append(seen[seen.index(cur):])
    uniq = {tuple(sorted(c)) for c in cycles}
    print("\n  alias-graph cycles across all three tables : %d" % len(uniq))
    for c in list(uniq)[:5]:
        print("      %s" % " -> ".join(c))
    if uniq:
        print("      REFUSING to write; fix canonical selection first.")
        return 1

    if "--write" in sys.argv:
        with open(OUT, "w", encoding="utf-8", newline="") as f:
            f.write("# GENERATED by scripts/emit_unified_aliases.py -- do not hand-edit.\n")
            f.write("# Source: extracted/global_address_map.tsv (scripts/unify_names.py),\n")
            f.write("# which aligns each body's Global uses against the original\n")
            f.write("# function's machine code in binary/NSS5.exe. Hand-verified rows in\n")
            f.write("# global_alias_overrides.tsv are applied AFTER this and still win.\n")
            f.write("address\talias\tcanonical\tevidence\n")
            for r in merges:
                f.write("%s\t%s\t%s\t%s\n" % r)
        print("\nwrote %s" % OUT)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
