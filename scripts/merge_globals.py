"""
Produce the single authoritative module-Global table.

Two sources, and they are good at different things:

  globals_named.tsv        every Global we know exists, with the name we chose and a type
                           guessed from how it is USED. Reliable for scalars (an Int slot
                           written with `mov [g],imm32` is an Int), weak for objects --
                           954 object slots and only 30 concrete Types, because BlitzMax
                           dispatches through the vtable and one or two observed slots
                           stay ambiguous across dozens of Types.

  globals_typed_by_new.tsv the concrete Type, taken from where the Global is ASSIGNED --
                           `push <classtable>; call bbObjectNew`, or the declared return
                           type of the factory it is assigned from. 601 Globals typed.

So: keep the names from the first, and let the second win on type wherever it has one,
because a construction site is evidence and a usage guess is not. Conflicting
construction sites are carried through as a warning rather than silently resolved.
"""

import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
NAMED = os.path.join(ROOT, "extracted", "globals_named.tsv")
BYNEW = os.path.join(ROOT, "extracted", "globals_typed_by_new.tsv")
OUT = os.path.join(ROOT, "extracted", "globals_final.tsv")
SLOTS = os.path.join(ROOT, "extracted", "globals_classtable_slots.tsv")
EXE = os.path.join(ROOT, "binary", "NSS5.exe")


# --------------------------------------------------------------------------------------
# Two things the extractor gets wrong, both corrected here rather than in the source
# tables, because both are derivable and would otherwise have to be hand-maintained.
# --------------------------------------------------------------------------------------

def _classtable_slots():
    """address -> 'Type+0xslot = Method sig' for every address inside a class table.

    A class table's interior is a run of METHOD POINTERS. The extractor sees a dword that
    code loads and never writes and calls it a read-only Int Global -- 924 of them, which
    is a third of the table, and every one of those rows tells a reader that
    0x00C61CC0 is an Int when it is really TScreen+0x94 (DoMessage).

    An address inside a class table's extent is NEVER a Global. helper_map.resolve_slot
    computes the extents (class-table start .. start + highest reflected slot + 4);
    corroborated independently by the load-time dword, which is a code pointer for 923 of
    the 924 and could not be for a Global.
    """
    try:
        sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
        import helper_map                                          # noqa: PLC0415
    except Exception as exc:                                       # noqa: BLE001
        print("  (class-table filter skipped: %s)" % exc)
        return {}
    if not os.path.exists(EXE):
        return {}
    names = {}
    vt = os.path.join(ROOT, "extracted", "vtable_map.tsv")
    if os.path.exists(vt):
        with open(vt, encoding="utf-8", errors="replace") as f:
            next(f, None)
            for line in f:
                p = line.rstrip("\n").split("\t")
                if len(p) >= 5:
                    try:
                        names[(p[0], int(p[4], 16))] = "%s %s" % (p[2], p[3])
                    except ValueError:
                        pass
    return helper_map, names


def _slot_label(helper_map, names, va):
    s = helper_map.resolve_slot(EXE, va)
    if not s:
        return None
    ty, _, off = s.partition("+")
    try:
        m = names.get((ty, int(off, 16)))
    except ValueError:
        m = None
    return "%s = %s" % (s, m) if m else s


def _slot_owners():
    """Type -> {slot: 'Name sig'}, following Extends, for re-testing uniqueness claims."""
    import collections                                             # noqa: PLC0415
    own = collections.defaultdict(dict)
    vt = os.path.join(ROOT, "extracted", "vtable_map.tsv")
    with open(vt, encoding="utf-8", errors="replace") as f:
        next(f, None)
        for line in f:
            p = line.rstrip("\n").split("\t")
            if len(p) >= 5:
                try:
                    own[p[0]][int(p[4], 16)] = "%s %s" % (p[2], p[3])
                except ValueError:
                    pass
    sup = {}
    ct = os.path.join(ROOT, "extracted", "class_tables.tsv")
    with open(ct, encoding="utf-8", errors="replace") as f:
        next(f, None)
        for line in f:
            p = line.rstrip("\n").split("\t")
            if len(p) >= 4:
                sup[p[0]] = p[3]

    def full(t, seen=None):
        seen = seen or set()
        if t in seen:
            return {}
        seen.add(t)
        d = {}
        s = sup.get(t)
        if s and not s.endswith("(runtime)"):
            d.update(full(s, seen))
        d.update(own.get(t, {}))
        return d

    return {t: full(t) for t in set(list(own) + list(sup))}


_ONLY = re.compile(r"vtable-call slots ([0x0-9a-fA-F,]+)\s*->\s*only (\w+) has them all")


def _recheck_only(note, table):
    """Re-test an 'only X has them all' note against the FULL class-table set.

    Those notes inferred a Type by asserting a slot combination was unique, but the
    uniqueness was tested against an incomplete candidate set -- 0x00C5DEA4 was typed
    TPlayer that way and is really TBall. Returns (new_note, still_unique) or None.
    """
    m = _ONLY.search(note or "")
    if not m:
        return None
    try:
        slots = [int(x, 16) for x in m.group(1).split(",") if x.strip()]
    except ValueError:
        return None
    claimed = m.group(2)
    cands = sorted(t for t, d in table.items() if all(s in d for s in slots))
    sl = ",".join(hex(s) for s in slots)
    if len(cands) == 1 and cands[0] == claimed:
        return ("vtable-call slots %s -> %s is the ONLY Type with all of them, re-tested "
                "against all %d class tables" % (sl, claimed, len(table)), True)
    return ("UNSOUND uniqueness claim: slots %s are shared by %d Types (%s%s), not only "
            "%s. Type is a GUESS -- re-derive from a construction site before relying on "
            "it." % (sl, len(cands), ", ".join(cands[:6]),
                              ", ..." if len(cands) > 6 else "", claimed), False)


def main():
    named = {}
    order = []
    with open(NAMED, encoding="utf-8", errors="replace") as f:
        next(f, None)
        for line in f:
            p = line.rstrip("\n").split("\t")
            if len(p) >= 8 and p[0].startswith("0x"):
                va = int(p[0], 16)
                named[va] = {"type": p[1], "name": p[2], "conf": p[3],
                             "refs": p[4], "subsystem": p[6], "evidence": p[7]}
                order.append(va)

    bynew = {}
    if os.path.exists(BYNEW):
        with open(BYNEW, encoding="utf-8", errors="replace") as f:
            next(f, None)
            for line in f:
                p = line.rstrip("\n").split("\t")
                if len(p) >= 3 and p[0].startswith("0x"):
                    bynew[int(p[0], 16)] = (p[1], int(p[2]),
                                            p[5] if len(p) > 5 else "")

    # Hand-verified corrections win over every automatic source, because
    # globals_final.tsv is wrong in BOTH directions about object-vs-scalar and the
    # refcount traffic in the code is what settles it. Each correction carries its
    # own evidence in the file.
    corr = {}
    cp = os.path.join(ROOT, "extracted", "globals_corrections.tsv")
    if os.path.exists(cp):
        with open(cp, encoding="utf-8", errors="replace") as f:
            for line in f:
                if line.startswith("#") or line.startswith("va\t"):
                    continue
                q = line.rstrip("\n").split("\t")
                if len(q) >= 2 and q[0].startswith("0x"):
                    corr[int(q[0], 16)] = q[1]

    hm = _classtable_slots()
    helper_map, slotnames = hm if hm else (None, {})
    slottable = _slot_owners()

    upgraded = added = conflicts = 0
    ct_rows = downgraded = confirmed_unique = superseded = 0
    slotout = open(SLOTS, "w", encoding="utf-8", newline="\n")
    slotout.write("# Addresses the Global extractor reported that are really the interior of a\n"
                  "# class table, i.e. METHOD POINTERS. They are NOT Globals. Kept here so a\n"
                  "# lookup of one of these addresses lands on the truth instead of nothing.\n"
                  "va\tclasstable_slot\textractor_said\textractor_name\n")
    with open(OUT, "w", encoding="utf-8", newline="\n") as f:
        f.write("va\ttype\tname\ttype_source\tconfidence\tsubsystem\tnote\n")
        for va in sorted(set(order) | set(bynew)):
            rec = named.get(va, {"type": "Object", "name": "g_unnamed_%08x" % va,
                                 "conf": "low", "subsystem": "-", "evidence": ""})
            ty, src, conf, note = rec["type"], "usage", rec["conf"], rec["evidence"]
            if va in bynew:
                t2, sites, conflict = bynew[va]
                if t2 != ty:
                    upgraded += 1
                ty, src = t2, "construction"
                conf = "high" if sites > 1 and not conflict else "medium"
                note = ("%d construction site(s)" % sites) + (
                    ("  CONFLICT: " + conflict) if conflict else "")
                if conflict:
                    conflicts += 1
                if va not in named:
                    added += 1
            # Hand-verified corrections beat every automatic source, including
            # construction-site typing -- which is not safe when only one site was found.
            if va in corr:
                ty, src, conf = corr[va], "verified", "high"
                note = "hand-verified; see globals_corrections.tsv"

            # An "only X has them all" note asserted uniqueness against an incomplete
            # candidate set. Re-test it; downgrade the row when the claim does not hold.
            rc = _recheck_only(note, slottable)
            if rc and src not in ("verified", "construction"):
                note, ok = rc
                if ok:
                    confirmed_unique += 1
                else:
                    conf, src = "low", "guess"
                    downgraded += 1
            elif _ONLY.search(rec["evidence"] or ""):
                # A better source already won, but the ORIGINAL usage guess rested on an
                # uniqueness claim. Say so, because the two disagree where they overlap.
                rc2 = _recheck_only(rec["evidence"], slottable)
                if rc2 and not rc2[1]:
                    note += "  [superseded usage guess was unsound: %s]" % rc2[0]
                    superseded += 1

            # A class-table interior is never a Global -- overrides everything above,
            # including the construction-site typing, which cannot apply to a method slot.
            lbl = _slot_label(helper_map, slotnames, va) if helper_map else None
            if lbl:
                slotout.write("0x%08x\t%s\t%s\t%s\n" % (va, lbl, ty, rec["name"]))
                ty, src, conf = "-", "classtable-slot", "n/a"
                note = "NOT A GLOBAL: class-table interior, %s" % lbl
                ct_rows += 1

            f.write("0x%08x\t%s\t%s\t%s\t%s\t%s\t%s\n"
                    % (va, ty, rec["name"], src, conf, rec["subsystem"], note))
    slotout.close()

    total = len(set(order) | set(bynew))
    print("rows in final table    : %d" % total)
    print("  REAL Globals                  : %d" % (total - ct_rows))
    print("  class-table interiors, NOT     ")
    print("    Globals (marked, listed in    ")
    print("    globals_classtable_slots.tsv): %d" % ct_rows)
    print("  type from a construction site : %d" % len(bynew))
    print("  type CHANGED by that evidence : %d" % upgraded)
    print("  not previously listed at all  : %d" % added)
    print("  conflicting construction sites: %d (flagged in the note column)" % conflicts)
    print("  hand-verified corrections     : %d" % len(corr))
    print("  'only X has them all' claims  : %d re-confirmed, %d DOWNGRADED to guess/low"
          % (confirmed_unique, downgraded))
    print("  superseded unsound claims     : %d (warning appended to the note)" % superseded)
    print("written: %s" % OUT)
    print("written: %s" % SLOTS)


if __name__ == "__main__":
    main()
