"""Close the last loop: match each dead Global to the name its WRITER uses.

    python scripts/link_dead_to_writers.py                  # report
    python scripts/link_dead_to_writers.py --emit           # write global_alias_writers.tsv
    python scripts/link_dead_to_writers.py --missing        # which writer BODY is missing
    python scripts/link_dead_to_writers.py --missing --emit-missing   # + missing_writers.json
    python scripts/link_dead_to_writers.py --twins          # prose-address twin proposals
    python scripts/link_dead_to_writers.py --twins --min-reads 3

WHY A SECOND ALIGNMENT
======================
unify_names.py aligns every Global REFERENCE a body makes against every address the
original touches. That works well for small and medium bodies and resolved 1,653 names.
It does badly on exactly the bodies that matter most here: a screen's CreateScreen
references thirty or forty Globals, the machine-order list carries extra addresses the
filters cannot all remove, and the alignment ends up with too many equally-optimal paths
to force anything. So the WRITER's name for a slot stays AMBIGUOUS -- and the writer's
name is the one that decides whether a Global is dead.

The result is a split that survives everything upstream. `TScreen_MatchPrep.CreateScreen`
builds the status label into `g_lbl_Status`; `TScreen_MatchPrep.SetUpScreen` reads
`g_matchprep_lblstatus`. Same slot, 0x00C685C0. The reader is dead, and no amount of
reference-level alignment fixed it because the writer's own name never resolved.

STORES ARE A MUCH SHARPER SIGNAL
================================
A function references a Global on every read; it STORES to one rarely. Ghidra spells a
slot store distinctively -- `PTR_DAT_00c685c0 = puVar2` -- and it is trivially separable
from a field write THROUGH the slot (`*(int *)(PTR_DAT_00c685c0 + 4) = ...`), which is not
a store to the Global at all. Our side is just as clean: an assignment statement whose
target is a Global.

So this aligns assignment targets against store targets. Both lists are short, both are
in source order, and the type constraint still applies. Where the reference alignment sees
forty candidates it sees three, and forces them.

A WORKED CASE
=============
0x00C5B248 carries three names: `g_engine_player` (TEngine.EndMatch, the writer),
`g_player_tplayer01` and `g_newstar` (readers, both dead). The readers had already
resolved to 0x00C5B248, but they could not merge into anything live because the writer's
name had not. Aligning stores resolves `g_engine_player`, and all three collapse.

SAFETY
======
Same rules as everywhere else in this pipeline, because a wrong merge is worse than the
split it fixes:

  * the two names must never CO-OCCUR in a body -- that proves different slots;
  * declared types must be identical or related by inheritance;
  * the surviving name must actually be WRITTEN in the assembled program, since the whole
    point is to give the dead reader a live writer. A merge onto another dead name changes
    nothing and is skipped rather than emitted as a fake fix.

WHEN THE ALIGNMENT HAS NOTHING TO OFFER  (--missing)
====================================================
A dead Global whose slot no recovered body stores to is not a naming problem at all: the
function that would build the object has never been reconstructed. That backlog is
discoverable rather than guessable, because Ghidra decompiled all 2,805 original functions
and a store to a module Global appears as `PTR_DAT_00c653c4 = ...` or `DAT_00c5d254 = ...`.
Grepping the decompilations for a store to a dead address names the exact original function
that fills the slot; cross-referencing against src/recovered/ says whether we have it.

The report ranks by DEREF SITES REVIVED rather than by how many Globals a function touches,
because one missing CreateScreen can revive an entire screen. Adjudication reached the same
conclusion by hand for a handful of cases -- TScreen_MatchPrep.CreateScreen at 0x0055C09B,
TScreen_EditNations.SetUpScreen at 0x0052A8BC, TPitch.SetUpFans at 0x004E6014 -- and this
does all of them at once.

`writes_but_recovered` is the sanity check: if the body IS in src/recovered and the Global
is still dead, the write is either inside a branch our recovery dropped or lands under a
name that has not been unified, which is a residual alias split and therefore work for the
alignment above after all.

THE PROSE ROUTE, KEPT ONLY AS A SECOND OPINION  (--twins)
=========================================================
The bodies annotate their Globals with addresses in header prose, and a dead name whose
prose address is shared by a WRITTEN name is a merge candidate too. That route found
0x00C5B1C4 g_object15 -> g_font_match_m, which the store alignment does not reach because
the writer's own name never resolved there.

It is strictly weaker evidence and it is treated as such: prose is the weakest evidence in
this project, its two-pairs-per-line headers bind off by one (which once proposed merging
screen WIDTH into screen HEIGHT), and so --twins prints a REVIEW-ONLY block and never
writes to any table. Rows the store alignment already emitted are suppressed, so what is
left is exactly what this route adds. Paste into extracted/global_alias_overrides.tsv only
after checking; every row in that file carries evidence and a human decision, and a
generator that silently appended to it would destroy that property.
"""
import os
import re
import sys
import json
import collections

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import addr_oracle as AO                                        # noqa: E402
import unify_names as UN                                        # noqa: E402
import emit_unified_aliases as EU                               # noqa: E402
import validate_verdicts as VV                                  # noqa: E402
import find_dead_globals as FDG                                 # noqa: E402

OUT = os.path.join(ROOT, "extracted", "global_alias_writers.tsv")
MISSING_OUT = os.path.join(ROOT, "extracted", "missing_writers.json")
DECOMP = os.path.join(ROOT, "extracted", "decomp")
INVENTORY = os.path.join(ROOT, "extracted", "ghidra", "function_inventory.tsv")
# --missing needs unverified bodies too: a body that is read but not yet byte-proven is
# still a body we HAVE, and listing it as never reconstructed would send someone to write
# it twice.
BODY_TREES = [os.path.join(ROOT, "src", "recovered"),
              os.path.join(ROOT, "src", "recovered_module"),
              os.path.join(ROOT, "src", "recovered_unverified")]
PROSE_TREES = [os.path.join(ROOT, "src", "recovered"),
               os.path.join(ROOT, "src", "recovered_module")]
ASSEMBLED = os.path.join(ROOT, "src", "assembled", "nss5_assembled.bmx")

# A store to the SLOT itself: the reference is the whole left-hand side. Anything with an
# offset or a dereference around it (`*(int *)(PTR_DAT_x + 4) = `) writes THROUGH the
# Global into the object it points at, which is not a store to the Global.
SLOT_STORE = re.compile(r"^\s*(?:_?PTR_)*_?DAT_(00c[0-9a-f]{5})\s*=(?!=)", re.M)
# Our side: a statement whose assignment target is a Global.
ASSIGN = re.compile(r"^\s*(g_\w+)\s*(?::[-+*/|&~]?)?=(?!=)", re.M | re.I)
ASSIGN_THEN = re.compile(r"\bThen\s+(g_\w+)\s*(?::[-+*/|&~]?)?=(?!=)", re.I)

# --missing looks for a store ANYWHERE in a decompiled function, not just at statement
# start, so it uses its own looser pair. The negative lookbehind keeps `==`, `<=`, `>=`
# and `!=` out; the second form catches the write-through-a-cast spelling, which for this
# question still identifies the function that fills the slot.
STORE = re.compile(r"(?:_?PTR_)*(?:_?DAT_)(00c[0-9a-f]{5})\s*(?<![=!<>])=(?!=)")
DEREF_STORE = re.compile(r"\*\s*\(?[^=;]*?(00c[0-9a-f]{5})[^=;]*?\)?\s*(?<![=!<>])=(?!=)")

# --twins, from the bodies' own header prose.
ADDR_NAME = re.compile(r"0x([0-9A-Fa-f]{6,8})\s*[:/]?\s*([A-Za-z_]\w*)")
# Requires a comment marker between the type and the address -- see the long note in
# build_alias_map.py. Without it this reads past one pair into the next one's address on
# the two-pairs-per-line headers this corpus uses, which proposed merging screen WIDTH
# into screen HEIGHT.
NAME_ADDR = re.compile(r"\b([A-Za-z_]\w*)\s*:\s*[A-Za-z_][\w\[\]]*\s*'\s*0x([0-9A-Fa-f]{6,8})")
GLOBAL_DECL = re.compile(r"'!\s*Global\s+(\w+)\s*:", re.I)


def store_set(path):
    """Addresses this original function stores INTO -- the SET, not an order.

    Ghidra is authoritative about WHICH references are stores and which are reads, but not
    about the order they happen in: its decompiler reorders statements, which is the same
    trap that made reference-level decompiled order score 83%. Taking store order from the
    decompiled text got TScreen_MatchPrep.CreateScreen's stores as
    c685bc, c685c8, c685c0, c685c4 and produced a shifted mapping -- it paired
    g_matchprep_lblreason with g_lbl_status and g_matchprep_lblstatus with
    g_lbl_selection, each one slot out, which is the classic off-by-one signature.

    So: classification from the decompilation, ORDER from the machine code. Same division
    of labour as addr_oracle.py.
    """
    out = set()
    for m in SLOT_STORE.finditer(open(path, encoding="utf-8", errors="replace").read()):
        a = int(m.group(1), 16)
        if AO.BAND_LO <= a < AO.BAND_HI:
            out.add(a)
    return out


def assign_targets(path, types):
    """Globals our body assigns to, in first-assignment order."""
    text = "\n".join(l for l in open(path, encoding="utf-8", errors="replace")
                     .read().split("\n") if not l.lstrip().startswith("'"))
    seen, order = set(), []
    for rx in (ASSIGN, ASSIGN_THEN):
        for m in rx.finditer(text):
            n = m.group(1).lower()
            if n in types and n not in seen:
                seen.add(n)
                order.append(n)
    return order


def sizes():
    """va -> byte length, from Ghidra's inventory. Ranks the missing-writer backlog."""
    out = {}
    if not os.path.exists(INVENTORY):
        return out
    for line in open(INVENTORY, encoding="utf-8",
                     errors="replace").read().splitlines()[1:]:
        p = line.split("\t")
        if len(p) > 3:
            try:
                out[int(p[0], 16)] = int(p[3])
            except ValueError:
                pass
    return out


def recovered_bodies():
    have = set()
    for tree in BODY_TREES:
        if not os.path.isdir(tree):
            continue
        for fn in os.listdir(tree):
            if fn.endswith(".bmx"):
                have.add(fn[:-4])
    return have


def report_missing(want, emit):
    """Which ORIGINAL function stores to each dead slot, and do we have that body."""
    have = recovered_bodies()
    size = sizes()

    writers = collections.defaultdict(set)
    for fn in os.listdir(DECOMP):
        if not fn.endswith(".c"):
            continue
        text = open(os.path.join(DECOMP, fn), encoding="utf-8",
                    errors="replace").read()
        for rx in (STORE, DEREF_STORE):
            for m in rx.finditer(text):
                a = int(m.group(1), 16)
                if a in want:
                    writers[a].add(fn)

    missing, present, orphan = collections.defaultdict(list), [], []
    for a, globs in want.items():
        fns = writers.get(a)
        if not fns:
            orphan.append((a, globs))
            continue
        for fn in fns:
            m = re.match(r"(.+)@([0-9a-fA-F]{6,8})\.c$", fn)
            if not m:
                continue
            base, va = m.group(1), int(m.group(2), 16)
            if base in have:
                present.append((base, a, globs))
            else:
                missing[(base, va)].append((a, globs))

    rows = []
    for (base, va), items in missing.items():
        revived = sum(d for _a, gl in items for _n, _t, d in gl)
        names = sorted({n for _a, gl in items for n, _t, _d in gl})
        rows.append((revived, base, va, size.get(va, 0), names))
    rows.sort(key=lambda r: -r[0])

    print()
    print("MISSING WRITER BODIES -- ranked by dead dereferences they would revive")
    print("  missing writer functions          : %d" % len(rows))
    print("  deref sites they would revive     : %d" % sum(r[0] for r in rows))
    print("  addresses with NO writer anywhere : %d" % len(orphan))
    print()
    print("  %-46s %6s %7s  %s" % ("FUNCTION", "BYTES", "REVIVES", "GLOBALS"))
    for revived, base, va, sz, names in rows[:40]:
        print("  %-46s %6d %7d  %s" % (base[:46], sz, revived,
                                       ", ".join(names[:4]) +
                                       (" +%d" % (len(names) - 4) if len(names) > 4 else "")))
    if present:
        print()
        print("  RESIDUAL ALIAS SPLITS -- writer IS recovered but the Global is still dead:")
        seen = set()
        for base, a, globs in present:
            k = (base, a)
            if k in seen:
                continue
            seen.add(k)
            print("    %-46s %08x  %s" % (base[:46], a,
                                          ", ".join(n for n, _t, _d in globs)))

    if emit:
        with open(MISSING_OUT, "w", encoding="utf-8") as f:
            json.dump([{"function": b, "va": "0x%08X" % v, "bytes": s,
                        "revives": r, "globals": n}
                       for r, b, v, s, n in rows], f, indent=1)
        print("\nwrote %s (%d functions)" % (MISSING_OUT, len(rows)))


def prose_addresses():
    """name -> best-supported address, from the corpus's own header annotations."""
    votes = collections.defaultdict(collections.Counter)
    for tree in PROSE_TREES:
        if not os.path.isdir(tree):
            continue
        for fn in sorted(os.listdir(tree)):
            if not fn.endswith(".bmx"):
                continue
            t = open(os.path.join(tree, fn), encoding="utf-8", errors="replace").read()
            decls = {m.group(1).lower() for m in GLOBAL_DECL.finditer(t)}
            if not decls:
                continue
            for line in t.split("\n"):
                if not line.strip().startswith("'"):
                    continue
                for m in ADDR_NAME.finditer(line):
                    if m.group(2).lower() in decls:
                        votes[m.group(2).lower()][m.group(1).upper().zfill(8)] += 2
                for m in NAME_ADDR.finditer(line):
                    if m.group(1).lower() in decls:
                        votes[m.group(1).lower()][m.group(2).upper().zfill(8)] += 2
    return {n: c.most_common(1)[0][0] for n, c in votes.items() if c}


def report_twins(deadrows, decls, live, already, minreads):
    """Dead names whose header prose puts them on an address a WRITTEN name also claims.

    Deliberately review-only. The dead set is find_dead_globals', not a second private
    reading of the assembled source: the tool that owns that question knows about the
    BlitzMax compound form (`g_sbalpha :+ ...`, no `=` anywhere), about Varptr, and about
    sized array declarations being their own allocation. A private copy that missed those
    reported live Globals as dead, and a false dead invites a merge that fuses two live
    variables -- the one failure mode worse than the split.
    """
    addr = prose_addresses()
    by_addr = collections.defaultdict(list)
    for n, a in addr.items():
        if n in decls:
            by_addr[a].append(n)

    proposals, orphans = [], []
    for _sev, name, ty, nread, _nmem in deadrows:
        if nread < minreads or name in already:
            continue
        a = addr.get(name)
        if not a:
            orphans.append((name, ty, nread, "no address annotation"))
            continue
        twins = [t for t in by_addr[a] if t != name and t in live]
        if not twins:
            orphans.append((name, ty, nread, "no written twin at 0x%s" % a))
            continue
        same = [t for t in twins if decls.get(t, "").lower() == ty.lower()]
        pick = (same or twins)[0]
        proposals.append((a, name, pick, ty, decls.get(pick, "?"), nread,
                          "same type" if same else "TYPE DIFFERS"))

    proposals.sort(key=lambda r: -r[5])
    print()
    print("DEAD GLOBALS WITH A LIVE TWIN, from header prose -- REVIEW ONLY: %d"
          % len(proposals))
    print("DEAD GLOBALS WITH NO TWIN     -- need a missing body    : %d" % len(orphans))
    print("  (rows the store alignment above already emitted are not repeated here)")
    print()
    if proposals:
        print("--- paste into extracted/global_alias_overrides.tsv after reviewing ---")
        for a, dead, twin, dty, lty, nr, note in proposals:
            flag = "" if note == "same type" else "   # %s: %s vs %s" % (note, dty, lty)
            print("0x%s\t%s\t%s\tDEAD->LIVE: %s is read %d time(s) and written nowhere; "
                  "%s shares 0x%s and IS written.%s"
                  % (a, dead, twin, dead, nr, twin, a, flag))
    print()
    print("Top orphans (no live twin -- these need the missing function written):")
    for name, ty, nr, why in sorted(orphans, key=lambda r: -r[2])[:15]:
        print("   %-34s %-14s reads=%-4d %s" % (name, ty, nr, why))


def main():
    emit_missing = "--emit-missing" in sys.argv
    want_missing = "--missing" in sys.argv or emit_missing   # asking for the file is asking
    want_twins = "--twins" in sys.argv
    minreads = 1
    if "--min-reads" in sys.argv:
        minreads = int(sys.argv[sys.argv.index("--min-reads") + 1])

    # find_dead_globals answers "which Globals are read and never written". Ask it
    # directly rather than running it as a subprocess and scraping the printed table: the
    # old way carried a private copy of the severity filter in a regex, so the report's
    # column layout was part of this file's contract and a change to it would have emptied
    # the work list silently. CRITICAL/HIGH/MEDIUM only, exactly as that regex matched --
    # LOW is numeric, reads as 0, and is not what the writer alignment is for.
    decls, deadrows, _skipped = FDG.analyse()
    dead = {}
    for sev, name, ty, _nread, nmem in deadrows:
        if sev in ("CRITICAL", "HIGH", "MEDIUM"):
            dead[name] = (ty, nmem)

    amap = {}
    p = os.path.join(ROOT, "extracted", "global_address_map.tsv")
    for line in open(p, encoding="utf-8").read().splitlines()[1:]:
        f = line.split("\t")
        if len(f) >= 3 and f[1] != "-":
            amap[f[0]] = int(f[1], 16)
    p = os.path.join(ROOT, "extracted", "global_address_adjudicated.tsv")
    if os.path.exists(p):
        for line in open(p, encoding="utf-8").read().splitlines():
            if line.startswith("#") or line.startswith("name") or not line.strip():
                continue
            f = line.split("\t")
            if len(f) >= 2 and f[1].startswith("0x"):
                amap[f[0]] = int(f[1], 16)

    want = collections.defaultdict(list)
    for n, (ty, d) in dead.items():
        if n in amap:
            want[amap[n]].append((n, ty, d))
    if not want:
        print("nothing to link")
        # --twins does not depend on the store alignment, so it still has something to say
        # when nothing here does.
        if want_twins:
            report_twins(deadrows, decls, VV.written_globals(), set(), minreads)
        return 0

    seed = AO.seeds()
    prose = UN.prose_votes()
    excl = UN.excluded()
    par = EU.parents()
    co = EU.cooccurrence()
    live = VV.written_globals()

    # body -> which of its assignment targets holds which address
    resolved, wtypes = {}, {}
    for b in AO.collect():
        sset = store_set(b["decomp"])
        st = [a for a in b["addrs"] if a in sset and a not in excl]
        if not st:
            continue
        path = None
        for tree in AO.TREES:
            q = os.path.join(tree, b["file"] + ".bmx")
            if os.path.exists(q):
                path = q
                break
        if not path:
            continue
        names = assign_targets(path, b["types"])
        if not names:
            continue
        # COUNT PARITY, but only where it is actually load-bearing.
        #
        # The whole ordering argument rests on our body being identical to the original.
        # For src/recovered and src/recovered_module that is not an assumption -- those
        # bodies are byte-verified against NSS5.exe -- so a count mismatch there just means
        # the usual extra-address noise, and the gap-tolerant alignment handles it exactly
        # as it does everywhere else.
        #
        # src/recovered_unverified is different. Those bodies are complete, plausible
        # reconstructions that have NOT been proven byte-identical, and they are included
        # here deliberately because that is where the big CreateScreen writers live. For
        # them, exact parity is the cheapest available evidence that the assumption holds:
        # TScreen_MatchPrep.CreateScreen offers 41 assignments against 41 stores, and its
        # g_btn_play -> 0x00C685C8 pairing is independently corroborated by
        # TScreen_MatchPrep.SetUpScreen.
        #
        # Demanding parity everywhere silently dropped real fixes: TScreen_EditClubs.
        # SetUpScreen is byte-verified and has 2 assignments against 1 store, so it was
        # skipped -- leaving g_editclub dead even though that body assigns its slot.
        if "unverified" in os.path.basename(os.path.dirname(path)) \
                and len(names) != len(st):
            continue
        kinds, _deref = UN.slot_kinds(b["decomp"])
        if len(st) >= len(names):
            cands = UN.align(names, b["types"], st, kinds, seed, prose)
            for n, c in zip(names, cands):
                if len(c) == 1:
                    resolved.setdefault(next(iter(c)),
                                        collections.Counter())[n] += 1
                    wtypes.setdefault(n, b["types"][n])
        else:
            # FEWER STORES THAN ASSIGNMENTS. align() insists every NAME is consumed and
            # gives up when there are not enough addresses, which is the wrong constraint
            # in this direction -- it is the STORES that must all be accounted for, while
            # an assignment may have no in-band store behind it (Ghidra did not classify
            # it as one, or the target is outside the module-global band).
            #
            # Left unhandled this quietly dropped real fixes: TScreen_EditClubs.SetUpScreen
            # assigns two Globals against one in-band store, so nothing was forced and
            # g_editclub stayed dead even though that body writes its slot.
            #
            # Type alone is usually decisive when the store list is this short, so force
            # only the unambiguous case: exactly one assignment target whose declared type
            # can occupy the slot.
            #
            # Note the candidate set is kept WIDE here and narrowed later against the dead
            # Global's own declared type. Ghidra's slot kind cannot separate two object
            # types, and in BlitzMax a String is an object too -- so
            # TScreen_EditClubs.SetUpScreen's g_editclubs_club:TClub and
            # g_editclubs_caller:String both "fit" a ptr slot and neither is forced. The
            # dead Global at that address is a TClub, which settles it.
            for a in st:
                for n in names:
                    if UN.compat(b["types"][n], kinds.get(a)):
                        resolved.setdefault(a, collections.Counter())[n] += 1
                        wtypes.setdefault(n, b["types"][n])

    rows, skipped = [], []
    for addr, globs in sorted(want.items()):
        holders = resolved.get(addr)
        if not holders:
            continue
        canon = None
        want_ty = globs[0][1]
        for n, _v in holders.most_common():
            if n not in live:
                continue
            wt = wtypes.get(n)
            if wt and not EU.types_mergeable(want_ty, wt, par):
                continue          # a String assignment is not the TClub slot
            canon = n
            break
        if not canon:
            skipped.append((addr, [g[0] for g in globs],
                            "writer name %s is itself never written"
                            % holders.most_common(1)[0][0]))
            continue
        for n, ty, d in globs:
            if n == canon:
                continue
            if canon in co.get(n, ()):
                skipped.append((addr, [n], "CO-OCCUR with %s" % canon))
                continue
            cty = None
            for b in AO.collect():
                if canon in b["types"]:
                    cty = b["types"][canon]
                    break
            if cty and not EU.types_mergeable(ty, cty, par):
                skipped.append((addr, [n], "TYPE %s vs %s" % (ty, cty)))
                continue
            rows.append(("0x%08X" % addr, n, canon, d))

    print("DEAD GLOBALS LINKED TO THEIR WRITER'S NAME")
    print("  dead Globals with a known address : %d"
          % sum(len(v) for v in want.values()))
    print("  addresses whose writer resolved   : %d" % len(resolved))
    print("  merges emitted                    : %d" % len(rows))
    print("  deref sites revived               : %d" % sum(r[3] for r in rows))
    print("  skipped                           : %d" % len(skipped))
    print()
    for a, n, c, d in sorted(rows, key=lambda r: -r[3])[:25]:
        print("    %s  %-32s -> %-30s %d sites" % (a, n, c, d))
    if skipped:
        print()
        for a, ns, why in skipped[:10]:
            print("    skip %08x %-40s %s" % (a, ",".join(ns)[:40], why))

    # Captured before --emit rebinds `rows` to the accumulated table: --twins reports only
    # what the store alignment did NOT already produce, so it needs THIS run's aliases.
    emitted = {n for _a, n, _c, _d in rows}

    if "--emit" in sys.argv:
        # ACCUMULATE. This tool derives its work list from the Globals that are dead in the
        # CURRENT build -- so once its own rows are applied those Globals are alive, the
        # next run finds almost nothing, and a plain overwrite would delete the very
        # merges that fixed them. Measured: a second pass emitted 10 rows where the first
        # emitted 105, and rewriting the file put predicted crash sites straight back from
        # 194 to 441.
        #
        # Keeping prior rows is safe because each one is a claim about a fixed fact -- which
        # address a name occupies -- not about the current build state. A row is only
        # replaced when this run has a new canonical for the same alias.
        prior = {}
        if os.path.exists(OUT):
            for line in open(OUT, encoding="utf-8", errors="replace"):
                if line.startswith("#") or line.startswith("address"):
                    continue
                f2 = line.rstrip("\n").split("\t")
                if len(f2) >= 3 and f2[1].strip() and f2[2].strip():
                    prior[f2[1].strip().lower()] = (f2[0], f2[2].strip(),
                                                    f2[3] if len(f2) > 3 else "")
        for a, n, c, d in rows:
            prior[n] = (a, c, "writer-store alignment; revives %d deref sites" % d)
        rows = [(v[0], k, v[1], v[2]) for k, v in sorted(prior.items())]
        print("  rows after accumulating prior runs : %d" % len(rows))
        with open(OUT, "w", encoding="utf-8", newline="") as f:
            f.write("# GENERATED by scripts/link_dead_to_writers.py -- each row merges a\n")
            f.write("# dead Global into the name its WRITER uses for the same slot,\n")
            f.write("# established by aligning assignment targets against the original's\n")
            f.write("# store targets. Checked for co-occurrence, type compatibility, and\n")
            f.write("# that the surviving name is actually written.\n")
            f.write("address\talias\tcanonical\tevidence\n")
            for a, n, c, ev in rows:
                f.write("%s\t%s\t%s\t%s\n" % (a, n, c, ev))
        print("\nwrote %s (%d rows)" % (OUT, len(rows)))

    if want_missing:
        report_missing(want, emit_missing)
    if want_twins:
        report_twins(deadrows, decls, live, emitted, minreads)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
