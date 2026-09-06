"""Find alias splits where BOTH halves are written -- the class find_dead_globals cannot see.

    python scripts/find_live_splits.py
    python scripts/find_live_splits.py --emit      # write extracted/unify_work/live_splits.json
    python scripts/find_live_splits.py --impact    # also rank the LIVE-LIVE ones by damage
    python scripts/find_live_splits.py --emit --impact

THE MIRROR CHECK LIVES IN find_name_collisions.py
=================================================
This file finds one ADDRESS wearing two names. The opposite -- one NAME standing for two
addresses -- is strictly worse, because assemble.py then emits ONE variable for two slots
and two subsystems share storage. It is not detectable from here (nothing about a split
address says another name is overloaded), so it has its own tool and its own gate:

    python scripts/find_name_collisions.py --check

Run both. Fixing a split by merging two names onto one canonical is exactly the operation
that creates a collision if the canonical is already in use for a different slot.

WHY THIS EXISTS
===============
find_dead_globals.py finds Globals that are READ but NEVER WRITTEN. That catches the split
where all the writes landed on one name and all the reads on another. It is blind to the
split where each half is written SOMEWHERE, because neither half looks dead.

That blind spot is not theoretical. It is why the game auto-fired a button on startup:

    TOptions.LoadOptions   g_opt_language = ReadSettingString(..., "language")   ' writes
    TScreen_Language.SetUpScreen   If g_lang_sel <> "0" Then ...                 ' reads

Both names are 0x00C5D290. Both are written somewhere, so both looked healthy. But the
value LoadOptions parsed out of Options.ini ("0", meaning "no language chosen yet") went
into one name and the test read the other, which was still "". `"" <> "0"` is True, so
SetUpScreen took the branch meant for "a language was already chosen", called
ButtonLanguage() with no gadget active, and drove the game through the language screen and
into the main menu without the user touching anything.

The byte-verified src/recovered/TScreen_Language.SetUpScreen.bmx names that slot g_optlang
and documents it as 0x00C5D290 -- so the original had ONE variable and we had two.

A live-live split is strictly worse than a dead one to diagnose: nothing is null, nothing
crashes, and in a release build the wrong branch just runs. It has to be found structurally.

HOW IT IS FOUND
===============
Two addresses agreeing is the whole signal. unify_names.solve() already returns, for every
Global name, the address the machine code says it lives at. Group names by that address; if
two names on one address are NOT already merged onto a single canonical, they are a split.
Classify by whether each side is assigned in the assembled source:

    LIVE-LIVE   both canonicals are written. Invisible to find_dead_globals. Reported here.
    LIVE-DEAD   one side never written -- already covered by find_dead_globals; listed but
                deprioritised so the two tools do not fight over the same work.

AMBIGUOUS names (the solver could not force an address) are also checked, because that is
exactly what happened above: g_opt_language came back AMBIGUOUS and so never joined the
group at its own address. For those, the address is taken from the body's own prose
annotation -- the weakest evidence in this project and never trusted alone, so such rows
are marked prose_only and must be confirmed before use.

WHY THE ADDRESS COMES FROM THE BINARY AND NOT FROM THE HEADERS
==============================================================
Bodies annotate their Globals with addresses in their header prose, and reading THOSE is
the obvious cheap way to find one address carrying several names. It was tried and it is
not good enough to act on:

  * it sees 1,576 of the 2,218 name/address adjacencies in the corpus, so a body whose
    header omits an address is simply invisible to it;
  * on the two-pairs-per-line headers this corpus uses constantly
    (`' 0x00C61740 g_screen_float03:Float   0x00C61744 g_screen_float04:Float`) it binds
    off by one, reading past one pair into the next pair's address. That is how a proposal
    to merge screen WIDTH into screen HEIGHT got generated.

Prose is the weakest evidence in this project. unify_names.solve() answers the same
question from the machine code, so that is what is used, and the prose route is kept only
for the AMBIGUOUS fallback below, where its rows are marked prose_only and must be
confirmed before use.

RANKING (--impact)
==================
Proving two names are one slot does not say whether the split MATTERS. Some are harmless:
both names are written and read in balanced ways, so each half works on its own little
island. Others are catastrophic, and the shape that makes them catastrophic is measurable
-- ALL the writes land on one name and ALL the reads come from the other, so the populated
variable is never read and the read variable is never populated.

TCompetition.New does `If Not g_lcompetitions Then g_lcompetitions = CreateList()` then
`g_lcompetitions.AddLast(Self)`, while all ~18 readers, including
`LogLine("Competitions:" + g_competitions.Count())`, read g_competitions. Both names are
0x00C6099C. The boot log says "Competitions:0" -- every league, cup and fixture in the game
is empty. Nothing crashed and no existing check flagged it.

--impact ranks the LIVE-LIVE groups this run just found, so detection and ranking are one
command and the ranking can never be computed against a stale live_splits.json.

THE GUARDS STILL APPLY
======================
A wrong merge corrupts two variables; a split only loses writes. So the same guards as
emit_unified_aliases.py gate every candidate, and anything failing one is dropped, not
reported as a maybe:
  CO-OCCURRENCE  two names declared in the same body are provably different slots. The
                 pragma scan MUST include src/module_body/, whose Globals carry no
                 '!Global pragmas -- omitting it once fused g_dataDir with g_savedir and
                 broke every asset path in the game.
  TYPE           identical, or one is a suffix-qualified form of the other
                 (brl.audio.TChannel vs TChannel). Unrelated types are dropped.
"""
import os
import re
import sys
import json
import collections

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

import unify_names as UN                                             # noqa: E402

ASSEMBLED = os.path.join(ROOT, "src", "assembled", "nss5_assembled.bmx")
OUT = os.path.join(ROOT, "extracted", "unify_work", "live_splits.json")

TREES = ["src/recovered", "src/recovered_unverified", "src/recovered_pending",
         "src/recovered_module"]
PRAGMA = re.compile(
    r"^\s*'!\s*Global\s+(\w+)\s*:\s*([A-Za-z_][\w.]*(?:\s*\[[,\s]*\])?)", re.M | re.I)
PROSE_ADDR = re.compile(r"(0x00C[0-9A-Fa-f]{5})\s*[:\-]?\s*(g_\w+)|(g_\w+)\s*[:\w.\[\]]*\s*\((0x00C[0-9A-Fa-f]{5})\)")


def alias_map():
    """Current alias -> canonical, across every table assemble.py honours."""
    out = {}
    for fn in ("global_alias_map.tsv", "global_alias_adjudicated.tsv",
               "global_alias_overrides.tsv", "global_alias_unified.tsv",
               "global_alias_writers.tsv"):
        p = os.path.join(ROOT, "extracted", fn)
        if not os.path.exists(p):
            continue
        for line in open(p, encoding="utf-8", errors="replace"):
            if line.startswith("#") or line.startswith("address"):
                continue
            f = line.rstrip("\n").split("\t")
            if len(f) >= 3 and f[1].strip() and f[2].strip():
                out[f[1].strip().lower()] = f[2].strip().lower()
    # Collapse chains so two names that reach the same sink compare equal.
    for _ in range(12):
        moved = False
        for k, v in list(out.items()):
            if v in out and out[v] != v and out[v] != k:
                out[k] = out[v]
                moved = True
        if not moved:
            break
    return out


def canonical(name, amap):
    return amap.get(name.lower(), name.lower())


def declared_together():
    """name -> set of names sharing a body with it (the co-occurrence exclusion)."""
    co = collections.defaultdict(set)
    files = []
    for t in TREES:
        d = os.path.join(ROOT, t)
        if os.path.isdir(d):
            files += [os.path.join(d, f) for f in os.listdir(d) if f.endswith(".bmx")]
    mb = os.path.join(ROOT, "src", "module_body")
    if os.path.isdir(mb):
        files += [os.path.join(mb, f) for f in os.listdir(mb) if f.endswith(".bmx")]

    for p in files:
        try:
            txt = open(p, encoding="utf-8", errors="replace").read()
        except OSError:
            continue
        names = {m.group(1).lower() for m in PRAGMA.finditer(txt)}
        if len(names) < 2:
            # module_body files carry no pragmas -- fall back to plain Global decls.
            names |= {m.group(1).lower()
                      for m in re.finditer(r"^\s*Global\s+(g_\w+)", txt, re.M | re.I)}
        for n in names:
            co[n] |= names - {n}
    return co


def written_names():
    """Canonical names the assembled program actually assigns."""
    if not os.path.exists(ASSEMBLED):
        return None
    txt = open(ASSEMBLED, encoding="utf-8-sig", errors="replace").read()
    code = "\n".join(l for l in txt.split("\n") if not l.lstrip().startswith("'"))
    w = set()
    for m in re.finditer(r"\b(g_\w+)\s*(?:\[[^\]]*\])?\s*=(?!=)", code, re.I):
        w.add(m.group(1).lower())
    # `Global name:Type = expr` -- the lazy-init idiom, legal inside a function body and
    # therefore indented. The pattern above cannot see it because the type sits between
    # the name and the `=`. Missing it makes a Global written only this way look dead.
    for m in re.finditer(r"(?m)^\s*Global\s+(g_\w+)\s*:\s*[\w.]+(?:\s*\[[^\]]*\])?\s*=(?!=)",
                         code, re.I):
        w.add(m.group(1).lower())
    return w


def types_mergeable(a, b):
    if not a or not b:
        return False
    a, b = a.lower().strip(), b.lower().strip()
    if a == b:
        return True
    # brl.audio.TChannel vs TChannel -- same type, differently qualified.
    return a.rsplit(".", 1)[-1] == b.rsplit(".", 1)[-1]


def prose_addresses():
    """name -> addresses its own body headers claim for it. Weakest evidence in the repo."""
    out = collections.defaultdict(collections.Counter)
    for t in TREES:
        d = os.path.join(ROOT, t)
        if not os.path.isdir(d):
            continue
        for fn in os.listdir(d):
            if not fn.endswith(".bmx"):
                continue
            try:
                txt = open(os.path.join(d, fn), encoding="utf-8", errors="replace").read()
            except OSError:
                continue
            for line in txt.split("\n"):
                if not line.lstrip().startswith("'"):
                    continue
                for m in PROSE_ADDR.finditer(line):
                    addr, name = (m.group(1), m.group(2)) if m.group(1) else (m.group(4), m.group(3))
                    if addr and name:
                        out[name.lower()]["0x%08X" % int(addr, 16)] += 1
    return out


# POPULATE vs mutate is the distinction that carries the signal. A list that is AddLast-ed
# is the one holding the data; a list that is only Clear()-ed or Remove()-d is being
# maintained by code that believes it holds the data. When those are different names, the
# second one is empty and every reader of it gets nothing. Lumping both together as
# "writes" hides exactly the case worth finding -- g_lcompetitions is AddLast-ed while
# g_competitions is Clear()-ed and read 50 times.
POPULATE = ("addlast", "addfirst", "insert")
MUTATE = ("remove", "clear", "removelast", "removefirst", "sort")


def counts(name, code):
    """-> (populates, assigns, mutates, reads)"""
    esc = re.escape(name)
    assigns = len(re.findall(r"\b%s\s*(?:\[[^\]]*\])?\s*=(?!=)" % esc, code, re.I))
    pop = sum(len(re.findall(r"\b%s\s*\.\s*%s\s*\(" % (esc, m), code, re.I))
              for m in POPULATE)
    mut = sum(len(re.findall(r"\b%s\s*\.\s*%s\s*\(" % (esc, m), code, re.I))
              for m in MUTATE)
    total = len(re.findall(r"\b%s\b" % esc, code, re.I))
    return pop, assigns, mut, max(0, total - pop - assigns - mut)


def impact(rows):
    """Rank the LIVE-LIVE groups by how badly each one actually breaks the program.

    Read counts come from the assembled source, so they reflect what the program actually
    does after unification, not what the recovered bodies intended.
    """
    if not os.path.exists(ASSEMBLED):
        raise SystemExit("no assembled source -- run scripts/assemble.py first")
    text = open(ASSEMBLED, encoding="utf-8-sig", errors="replace").read()
    code = "\n".join(l for l in text.split("\n") if not l.lstrip().startswith("'"))

    groups = collections.defaultdict(set)
    for r in rows:
        if r["kind"] == "LIVE-LIVE":
            groups[r["address"]].add(r["a"])
            groups[r["address"]].add(r["b"])

    out = []
    for addr, names in groups.items():
        stat = {n: counts(n, code) for n in sorted(names)}
        # The fatal signature: one name is POPULATED (AddLast/Insert/CreateList) and barely
        # read, while a DIFFERENT name carries the bulk of the reads and is never populated.
        # The data goes into the first; every reader looks at the second and sees nothing.
        filler, victim = None, None
        for n, (pop, asg, _mut, r) in stat.items():
            if pop == 0:
                continue
            for m, (mpop, _masg, _mmut, mr) in stat.items():
                if m == n or mpop:
                    continue
                if mr >= 8 and mr >= 4 * max(r, 1):
                    if not victim or mr > stat[victim][3]:
                        filler, victim = n, m
        out.append({"address": addr, "stat": stat,
                    "filler": filler, "victim": victim,
                    "reads": sum(v[3] for v in stat.values())})

    out.sort(key=lambda d: (d["victim"] is None, -(d["stat"][d["victim"]][3]
                                                   if d["victim"] else 0)))
    print()
    print("LIVE-SPLIT IMPACT  (%d groups)" % len(out))
    print()
    broken = [d for d in out if d["victim"]]
    print("  BROKEN SUBSYSTEM -- one name is filled with the data, a different name carries")
    print("  the reads and is never filled. Everything reading it sees an empty container:")
    for d in broken:
        print("    %s" % d["address"])
        for n, (pop, asg, mut, r) in sorted(d["stat"].items(), key=lambda kv: -kv[1][3]):
            mark = ""
            if n == d["filler"]:
                mark = "   <== THE DATA GOES HERE"
            elif n == d["victim"]:
                mark = "   <== EVERYTHING READS THIS, it is never filled"
            print("      %-32s fill=%-2d assign=%-2d mutate=%-2d reads=%-3d%s"
                  % (n, pop, asg, mut, r, mark))
    if not broken:
        print("    none")
    print()
    print("  REST -- one slot, two names, but no clean fill/read separation. Still wrong,")
    print("  and still worth merging, but not provably fatal from counts alone:")
    for d in out:
        if d["victim"]:
            continue
        print("    %-12s %s" % (d["address"],
                                ", ".join("%s(fill%d/asg%d/r%d)" % (n, v[0], v[1], v[3])
                                          for n, v in sorted(d["stat"].items()))))


def main():
    # solve() -> (resolutions, types, seeds, votes); resolutions are name -> (int addr, tier, why)
    solved_all = UN.solve()
    res, solver_types = solved_all[0], solved_all[1]
    amap = alias_map()
    co = declared_together()
    written = written_names()
    prose = prose_addresses()

    types = {k.lower(): v for k, v in solver_types.items()}
    for t in TREES:
        d = os.path.join(ROOT, t)
        if not os.path.isdir(d):
            continue
        for fn in os.listdir(d):
            if fn.endswith(".bmx"):
                try:
                    txt = open(os.path.join(d, fn), encoding="utf-8",
                               errors="replace").read()
                except OSError:
                    continue
                for m in PRAGMA.finditer(txt):
                    types.setdefault(m.group(1).lower(), m.group(2).strip())

    by_addr = collections.defaultdict(set)
    solved = {}
    for name, v in res.items():
        addr = v[0] if isinstance(v, (tuple, list)) else v
        if addr:
            a = "0x%08X" % (addr if isinstance(addr, int) else int(str(addr), 16))
            by_addr[a].add(name.lower())
            solved[name.lower()] = a

    # An AMBIGUOUS name whose own prose puts it on an address that resolved names own is
    # exactly the g_opt_language shape -- the reason this file exists. Marked prose_only.
    prose_only = set()
    for name, counter in prose.items():
        if name in solved or name not in types:
            continue
        for a, _n in counter.most_common(1):
            if a in by_addr:
                by_addr[a].add(name)
                prose_only.add(name)

    rows = []
    for addr, names in sorted(by_addr.items()):
        if len(names) < 2:
            continue
        groups = collections.defaultdict(set)
        for n in names:
            groups[canonical(n, amap)].add(n)
        if len(groups) < 2:
            continue                      # already unified onto one canonical -- fine
        cans = sorted(groups)
        for i in range(len(cans)):
            for j in range(i + 1, len(cans)):
                a, b = cans[i], cans[j]
                na = sorted(groups[a])
                nb = sorted(groups[b])
                if any(y in co.get(x, ()) for x in na for y in nb):
                    continue              # provably different slots
                ta = types.get(na[0], types.get(a, ""))
                tb = types.get(nb[0], types.get(b, ""))
                if not types_mergeable(ta, tb):
                    continue
                wa = written is None or a in written
                wb = written is None or b in written
                kind = "LIVE-LIVE" if (wa and wb) else "LIVE-DEAD"
                rows.append({
                    "address": addr,
                    "a": a, "b": b,
                    "a_names": na, "b_names": nb,
                    "type": ta or tb,
                    "a_written": bool(wa), "b_written": bool(wb),
                    "kind": kind,
                    "prose_only": bool((set(na) | set(nb)) & prose_only),
                    "tier_a": (res.get(na[0]) or ("", "", ""))[1] if na[0] in res else "PROSE",
                    "tier_b": (res.get(nb[0]) or ("", "", ""))[1] if nb[0] in res else "PROSE",
                })

    rows.sort(key=lambda r: (r["kind"] != "LIVE-LIVE", r["prose_only"], r["address"]))
    live = [r for r in rows if r["kind"] == "LIVE-LIVE"]

    print("LIVE SPLITS -- one address, two names that were never merged")
    print("  addresses carrying >1 unmerged canonical : %d" % len({r["address"] for r in rows}))
    print("  LIVE-LIVE pairs (invisible to find_dead_globals) : %d" % len(live))
    print("  LIVE-DEAD pairs (already covered elsewhere)       : %d"
          % (len(rows) - len(live)))
    print()
    if live:
        print("  LIVE-LIVE -- both sides written, so nothing looks broken and the wrong")
        print("  branch simply runs. These are the expensive ones:")
        print("    %-12s %-30s %-30s %s" % ("ADDRESS", "A", "B", "TYPE"))
        for r in live[:60]:
            print("    %-12s %-30s %-30s %s%s"
                  % (r["address"], r["a"][:30], r["b"][:30], r["type"],
                     "   [prose only]" if r["prose_only"] else ""))
        if len(live) > 60:
            print("    ... and %d more" % (len(live) - 60))
    if not rows:
        print("  none -- every address resolves to a single canonical")

    if "--emit" in sys.argv:
        os.makedirs(os.path.dirname(OUT), exist_ok=True)
        with open(OUT, "w", encoding="utf-8") as f:
            json.dump(rows, f, indent=1)
        print("\n  wrote %d rows to %s" % (len(rows), OUT))

    if "--impact" in sys.argv:
        impact(rows)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
