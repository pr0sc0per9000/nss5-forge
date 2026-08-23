"""
Does the corpus still byte-match AFTER assembly? -- the composition check, plus --layout.

WHY THIS IS NOT REDUNDANT WITH THE PER-FUNCTION ORACLE. Every one of the ~1,344 verified
bodies was compiled ALONE, inside a small probe program that harness.py generates: a
synthetic Type carrying just that one method, the module Globals it declares, and stubs
for what it calls. That proves the body is right IN THAT CONTEXT. It does not prove the
1,344 compose.

Ways assembly could change the emitted bytes even though every body is individually
correct, all of them real risks in bcc:
  * VTABLE SLOTS. A method's slot is decided by declaration order within its Type and by
    what the supertype occupies. In a probe, a Type has one method; in the assembly it has
    forty. Every `call [eax+N]` through a reconstructed object depends on getting N right,
    and N is a whole-program property.
  * GLOBAL TYPES. A Global declared TGadget in one probe and TButton in another compiles
    both times; assembled, one of them wins and changes the dispatch slot for the other.
    (This is exactly the g_pairs_buttons conflict.)
  * TYPE DECLARATION ORDER. bcc registers Types in source order and that order reaches the
    module body.
  * NAME COLLISIONS. Two Globals that were distinct in two probes can merge into one slot.

So the per-function pass and this pass answer different questions, and only this one
answers "would the real program have these bytes". A regression here means the corpus is
internally inconsistent, NOT that a body is wrong -- fix the assembly, not the body.

USE harness.compare, NEVER bytematch.compare
============================================
The first version of this script called bytematch.compare() and reported 35 of 40 sampled
functions as DIVERGED. Every one of those "divergences" was an absolute address or an E8
displacement:

    orig  55 89 E5 A1 A0 DC C5 00 50 8B 00 FF 50 34 ...
    ours  55 89 E5 A1 DC 9E 5B 00 50 8B 00 FF 50 34 ...
                     ^^^^^^^^^^^ the SAME Global, at its address in each image

bytematch.compare is the RAW differ -- it is the tool you want when you need to see the
literal bytes. Two independently-linked images can never agree on a relocated operand, so
raw-diffing them across images reports a catastrophe that is not there. harness.compare
applies the four masks (absolute addresses, class-table slot calls, and E8 to helpers or
methods NAMED ON BOTH SIDES) and is the only correct comparator across two link layouts.

A KNOWN FALSE POSITIVE: `Super.Delete` into a BRL Type
=====================================================
A Type that `Extends` a BRL Type compiles its `Delete` to "set the class pointer to the
super's table, then `call <super's Delete>`". The original side names that callee fine
(`0x005B7F77 = __brl_stream_TStreamFactory_Delete`, confidence 999) but OUR side often has
no exported symbol for it -- it lives inside the module's object blob -- and the mask needs a
name on BOTH sides. So the 4-byte `E8` operand stands and the row reports "diff 28/32".

`TZipEngineStreamFactory.Delete` is the worked example. Its two bodies are byte-identical
apart from the masked class-table pointer and that one call displacement:

    orig  55 89 e5 8b 45 08 c7 00 [5c 22 cb 00] 50 e8 [5d 89 02 00] 83 c4 04 ...
    ours  55 89 e5 8b 45 08 c7 00 [5c 39 64 00] 50 e8 [f5 c5 02 00] 83 c4 04 ...

28 = 32 minus exactly that operand. Before treating such a row as a defect, check whether
`helper_map.our_helpers()` has a symbol for our side's call target; if it does not, this is
the checker's limit, not a wrong body.

--layout: DID ASSEMBLY PRESERVE CLASS LAYOUT?
=============================================
Same two images, same question one level up from the bodies: is each Type shaped the same
in both. Two properties, two failure modes, both invisible to everything above.

FIELD LAYOUT (instance size). A Type's instance size is the sum of its declared fields plus
its super's, so comparing that one number per Type tests, across the whole corpus at once,
that every field is declared and none invented, that every field's TYPE is right (a String
is 4 bytes, a Double 8, an array 4), and that the inheritance chain is right. It matters
beyond tidiness: field offsets are baked into every body that touches the Type
(`mov eax,[ebx+0x3c]`). A size mismatch means some body is reading the wrong offset even
where it currently byte-matches, because a body verified against a probe Type carries that
probe's layout and not the assembled program's.

METHOD LAYOUT (class-table slots). Field offsets come from the field declarations in order;
method SLOTS come from the method declarations in order, after the super's. So a Type can
have a perfect instance size and still put `Draw` at 0x40 where the original has it at
0x3C -- one missing, extra or out-of-order method is enough -- and every
`call dword ptr [eax+0x3C]` through that Type then dispatches to the wrong method.

WHY THE ORACLE DOES NOT ALREADY COVER THE SLOTS. `harness.compare` MASKS class-table slot
calls; that is one of its four documented masks, because a probe's Type has different slots
by construction. A slot error is therefore invisible to per-function verification BY DESIGN,
and the composition check above catches it only if some sampled body happens to dispatch
through the wrong slot AND the difference survives masking. This checks it directly.

HOW A CLASS TABLE IS FOUND, in both images identically: locate the Type's reflection scope
(a `2` tag followed by a pointer to the Type's name), then find the class table that points
at that scope -- the scope pointer sits at +8, so the table starts 8 bytes earlier. Instance
size is at +0xC, and the member records that follow the scope tag carry the slot. This is
the same route `bytematch.find_method` uses, so both halves agree with the oracle by
construction rather than by a second guess.

Usage:  check_assembled.py [--all | N]        default: sample 80 functions
        check_assembled.py --layout [our_exe]  instance sizes and class-table slots
"""

import csv
import os
import random
import struct
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

os.environ.setdefault("NSS5_WORKER", "composition")
os.environ["NSS5_NO_LEARN"] = "1"      # an audit must never teach itself a name

import bytematch as _bm    # noqa: E402
import coverage as C       # noqa: E402
import harness as H        # noqa: E402
import helper_map as HM    # noqa: E402

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ASMDIR = os.path.join(ROOT, "src", "assembled")
ASM = os.path.join(ASMDIR, "nss5_assembled.exe")


def targets():
    inv = C.load_inventory()
    brl = C.load_brl()
    uni = C.load_universe(inv, brl)
    rec = C.load_recovered()
    out = []
    for va, (_path, ok) in sorted(rec.items()):
        if not ok or va not in uni or "." not in uni[va]:
            continue
        tname, mname = uni[va].split(".", 1)
        out.append((tname, mname, va, inv.get(va, 0)))
    return out


def staleness():
    """Bodies written since the exe was built. They are ABSENT from it, not broken.

    This bit the first run of this script: 3 of 40 sampled functions reported
    "LENGTH 610 vs 14" -- 14 being the empty-method stub -- and read exactly like the
    assembler silently dropping verified bodies. It had not. src/recovered is a LIVE tree
    that reconstruction passes write to continuously, and those three had landed in the
    minutes after assemble.py ran. Re-assembling made all three identical.

    A stale exe fails in the most alarming possible direction (a real body compared against
    an empty stub), so the check has to say so before anybody starts debugging a
    non-existent assembler defect.
    """
    if not os.path.exists(ASM):
        return []
    built = os.path.getmtime(ASM)
    newer = []
    for d in ("recovered", "recovered_module"):
        p = os.path.join(ROOT, "src", d)
        if not os.path.isdir(p):
            continue
        for fn in os.listdir(p):
            if fn.endswith(".bmx") and os.path.getmtime(os.path.join(p, fn)) > built:
                newer.append(fn)
    return sorted(newer)


# ------------------------------------------------------------------ --layout
# The reflection member kinds. 6 (Method) and 7 (Function) are the ones that occupy a
# class-table slot; the rest are fields and constants, which the instance-size half covers.
DECL_KIND = {1, 2, 3, 4, 5, 6, 7}


def game_types():
    """The Types the game's own module declares, in declaration order."""
    out = []
    with open(os.path.join(ROOT, "extracted", "type_declaration_order.tsv"),
              encoding="utf-8") as f:
        for r in csv.DictReader(f, delimiter="\t"):
            out.append(r["type"])
    return out


def class_table_size(path, tname):
    """-> instance size for tname in `path`, or None."""
    b, img, secs = _bm.load(path)
    va2off, off2va, cstr = _bm._helpers(b, img, secs)
    scope_va = None
    for i in range(0, len(b) - 32, 4):
        if struct.unpack_from("<I", b, i)[0] != 2:
            continue
        p = struct.unpack_from("<I", b, i + 4)[0]
        if p < img or cstr(va2off(p)) != tname:
            continue
        scope_va = off2va(i)
        break
    if scope_va is None:
        return None
    nd = struct.pack("<I", scope_va)
    k = b.find(nd)
    while k != -1:
        c = k - 8
        if c > 0:
            sup, _f, _d, isz = struct.unpack_from("<IIII", b, c)
            if 0 < isz < 20000 and (sup == 0 or sup > img):
                return isz
        k = b.find(nd, k + 1)
    return None


def slots_of(path, wanted):
    """-> {type: {method: slot}} for the Types in `wanted`, read from the reflection table."""
    b, img, secs = _bm.load(path)
    va2off, off2va, cstr = _bm._helpers(b, img, secs)
    out = {}
    i = 0
    while i < len(b) - 32:
        if struct.unpack_from("<I", b, i)[0] != 2:
            i += 4
            continue
        p = struct.unpack_from("<I", b, i + 4)[0]
        if p < img:
            i += 4
            continue
        tname = cstr(va2off(p))
        if tname not in wanted or tname in out:
            i += 4
            continue
        meth, j = {}, i + 8
        while j < len(b) - 16:
            k = struct.unpack_from("<I", b, j)[0]
            if k not in DECL_KIND:
                break
            np = struct.unpack_from("<I", b, j + 4)[0]
            sp = struct.unpack_from("<I", b, j + 8)[0]
            if np < img or sp < img:
                break
            nn = cstr(va2off(np))
            if nn is None:
                break
            if k in (6, 7):               # Method / Function -- the ones with a slot
                meth[nn] = struct.unpack_from("<I", b, j + 12)[0]
            j += 16
        out[tname] = meth
        i += 4
    return out


def instance_sizes(ours, decl):
    """FIELD layout. -> 0 if every Type's instance size agrees, 1 otherwise."""
    orig_sizes = {}
    with open(os.path.join(ROOT, "extracted", "class_tables.tsv"), encoding="utf-8") as f:
        for r in csv.DictReader(f, delimiter="\t"):
            orig_sizes[r["type"]] = int(r["instance_size"])

    print("INSTANCE SIZE: NSS5.exe vs %s" % os.path.basename(ours))
    print("over the %d Types the game's own module declares" % len(decl))
    print()

    same = diff = missing = 0
    bad = []
    for t in decl:
        o = orig_sizes.get(t)
        if o is None:
            o = class_table_size(_bm.ORIG, t)
        u = class_table_size(ours, t)
        if o is None or u is None:
            missing += 1
            bad.append((t, o, u, "not locatable"))
            continue
        if o == u:
            same += 1
        else:
            diff += 1
            bad.append((t, o, u, "%+d" % (u - o)))

    print("  identical : %d" % same)
    print("  DIFFERENT : %d" % diff)
    print("  not found : %d" % missing)
    if bad:
        print()
        print("  %-42s %8s %8s %s" % ("Type", "orig", "ours", "delta"))
        for t, o, u, why in bad[:40]:
            print("  %-42s %8s %8s %s" % (t, o, u, why))
        print()
        print("  A delta is a FIELD-LAYOUT defect: a missing, extra or mis-typed field, or a")
        print("  wrong super. Every body that touches such a Type is reading offsets that do")
        print("  not correspond to the original, even where it currently byte-matches.")
    return 1 if (diff or missing) else 0


def method_slots(ours, decl):
    """METHOD layout. -> 0 if every method sits at the same slot in both, 1 otherwise."""
    print("CLASS-TABLE SLOTS: NSS5.exe vs %s" % os.path.basename(ours))
    print("over the %d Types the game's own module declares" % len(decl))
    print()

    wanted = set(decl)
    o = slots_of(_bm.ORIG, wanted)
    u = slots_of(ours, wanted)

    same = moved = only_o = only_u = 0
    bad = []
    for t in decl:
        om, um = o.get(t), u.get(t)
        if om is None or um is None:
            bad.append((t, "-", "Type not locatable in %s"
                        % ("NSS5.exe" if om is None else "ours")))
            continue
        for m, s in sorted(om.items()):
            if m not in um:
                only_o += 1
                bad.append((t + "." + m, "0x%x" % s, "ABSENT from ours"))
            elif um[m] != s:
                moved += 1
                bad.append((t + "." + m, "0x%x" % s, "ours 0x%x  <== SLOT MOVED" % um[m]))
            else:
                same += 1
        for m in sorted(um):
            if m not in om:
                only_u += 1
                bad.append((t + "." + m, "-", "EXTRA in ours (slot 0x%x)" % um[m]))

    print("  same slot        : %d" % same)
    print("  SLOT MOVED       : %d" % moved)
    print("  missing from ours: %d" % only_o)
    print("  extra in ours    : %d" % only_u)
    if bad:
        print()
        for n, s, why in bad[:40]:
            print("    %-50s orig %-8s %s" % (n, s, why))
        if len(bad) > 40:
            print("    ... and %d more" % (len(bad) - 40))
        print()
        print("  A MOVED slot means every `call [obj+slot]` through that Type dispatches to")
        print("  the wrong method. The oracle cannot see this: it MASKS class-table slot")
        print("  calls by design, because a probe's Type has different slots.")
    return 1 if (moved or only_o) else 0


def layout():
    """Both halves of the layout check, over the same exe the composition check reads."""
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    ours = args[0] if args else ASM
    if not os.path.exists(ours):
        print("no assembled exe at %s -- run scripts/assemble.py first" % ours)
        return 2
    decl = game_types()
    rc = instance_sizes(ours, decl)
    print()
    if method_slots(ours, decl):
        rc = 1
    return rc


def main():
    if "--layout" in sys.argv:
        return layout()

    if not os.path.exists(ASM):
        print("no assembled exe at %s -- run scripts/assemble.py first" % ASM)
        return 2

    stale = staleness()
    if stale:
        print("!! STALE: %d recovered bodies are newer than the assembled exe." % len(stale))
        print("!! They are not IN it, so they will read as 'LENGTH n vs 14' (the empty stub)")
        print("!! and look like the assembler dropped them. Re-run scripts/assemble.py first.")
        for fn in stale[:10]:
            print("!!    %s" % fn)
        print()

    arg = sys.argv[1] if len(sys.argv) > 1 else "80"
    all_t = targets()
    if arg == "--all":
        work = all_t
    else:
        random.Random(20260804).shuffle(all_t)
        work = all_t[: int(arg)]

    # Name resolution for the assembled side, exactly as try_method builds it.
    ournames, origtab, ourfns = {}, {}, {}
    try:
        origtab = HM.full_table()
        # PICK THE OBJECT THAT BELONGS TO nss5_assembled.exe, BY NAME.
        #
        # `max(objs, key=getsize)` looked reasonable and was catastrophically wrong. bmk
        # drops its intermediates next to the source, so src/assembled/.bmx accumulates
        # objects from every build ever run there -- including nss5_dbg and nss5_dbgprobe,
        # the DEBUG builds, which carry debug metadata and are half again the size of the
        # release object. The biggest .o is therefore whichever debug build ran last,
        # possibly days ago and against different source.
        #
        # The failure is silent and it inverts this whole check: `ourfns` then holds the
        # wrong image's symbols, so compare()'s (a0) path can name neither side of a
        # game-to-game call, no E8 masks, and every body that calls anything reads as
        # DIVERGED. Measured on the tree this was found in: 52 of 80 sampled bodies
        # reported diverged, 79 of 80 identical once the right object is used -- and the
        # 52 were not a regression in any of them.
        _objdir = os.path.join(ASMDIR, ".bmx")
        _stem = os.path.basename(ASM)[:-4]                   # nss5_assembled
        objs = [os.path.join(_objdir, f) for f in os.listdir(_objdir)
                if f.endswith(".o") and ".debug." not in f
                and (f.startswith(_stem + ".bmx") or f.startswith("nss5_external.bmx"))]
        if not objs:
            raise RuntimeError("no release object for %s in %s -- re-run assemble.py"
                               % (_stem, _objdir))
        # BOTH objects, merged. nss5_assembled.exe is linked from the main module AND
        # nss5_external.bmx, which is where every third-party body lives, so reading one
        # object leaves the other unit's calls unnameable on our side -- they cannot mask
        # and their bodies read as diverged however right they are. TBitmapFont.Load was
        # the one that showed it: MATCH 1855/1855 as a probe, DIVERGED at the GCResume
        # call operand here, purely because the relocation naming it sits in the external
        # object.
        for _o in sorted(objs):
            try:
                _syms, _ = HM.our_helpers(ASMDIR, ASM, objpath=_o)
            except Exception:                                     # noqa: BLE001
                continue
            for _s, _va in _syms.items():
                ournames.setdefault(_va, _s)
            ourfns.update(HM.our_functions(_o, ASM))
    except Exception as exc:                                      # noqa: BLE001
        print("WARNING: could not build the assembled-side symbol tables (%s)." % exc)
        print("Without them nothing can be masked and every relocation reads as a diff.")

    ospan, uspan = H._span(_bm.ORIG), H._span(ASM)

    print("composition check: %d of %d verified Type methods" % (len(work), len(all_t)))
    print("  %s" % ASM)
    print("  comparator: harness.compare (relocation-aware), NSS5_NO_LEARN=1")
    print()

    exact = reloc = bad = missing = 0
    failures = []
    for tname, mname, va, size in work:
        try:
            a = _bm.find_method(_bm.ORIG, tname, mname)
            c = _bm.find_method(ASM, tname, mname)
        except Exception as exc:                                  # noqa: BLE001
            missing += 1
            failures.append((tname, mname, va, size, "locate failed: %s" % exc))
            continue
        if not a or not c:
            missing += 1
            failures.append((tname, mname, va, size, "not present in one of the images"))
            continue
        ab, cb = a["bytes"], c["bytes"]
        if len(ab) != len(cb):
            bad += 1
            failures.append((tname, mname, va, size,
                             "LENGTH %d vs %d" % (len(ab), len(cb))))
            continue
        mode, same, total, _masked, first = H.compare(
            ab, cb, ospan, uspan, (_bm.ORIG, a["va"]), (ASM, c["va"]),
            ournames=ournames, origtab=origtab, learn=None, ourfns=ourfns)
        if mode == "exact":
            exact += 1
        elif mode == "reloc":
            reloc += 1
        else:
            bad += 1
            failures.append((tname, mname, va, size,
                             "%s %d/%d, first diff at +%d" % (mode, same, total, first)))

    print("  identical, even addresses : %d" % exact)
    print("  identical modulo reloc    : %d" % reloc)
    print("  DIVERGED after assembly   : %d" % bad)
    print("  not locatable             : %d" % missing)
    if failures:
        print()
        for tname, mname, va, size, why in failures[:30]:
            print("    %-46s %s %6d  %s" % (tname + "." + mname, va, size, why))
    print()
    if bad or missing:
        print("  NOT a body defect by default: each of these verified ALONE. Suspect the")
        print("  whole-program facts first -- vtable slot order, Global types, Type order.")
        return 1
    print("  THE CORPUS COMPOSES: every sampled body survives assembly unchanged.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
