"""
Type the object Globals by finding where they are constructed.

WHY
===
The largest remaining structural unknown is the concrete Type of the object Globals.
name_globals.py could type only 30 of 954 object slots, because BlitzMax dispatches
through the vtable and one or two observed slots stay ambiguous across dozens of Types.
That gap is what leaves 80 functions BLOCKED (149,371 bytes, 26% of everything left):
their "unresolved indirect calls" are really calls on a Global whose Type is unknown, e.g.

    (**(code **)(*(int *)PTR_DAT_00C6BA50 + 0x54))(PTR_DAT_00C6BA50)

Given the Type, that is just `g_something.SomeMethod()` -- the slot is already in
vtable_map.tsv. Nothing about it is genuinely unresolvable.

HOW
===
A Global is typed where it is ASSIGNED, and BlitzMax construction has a rigid shape:

    68 <classtable>          push  &TFoo_classtable
    E8 <bbObjectNew>         call  bbObjectNew          (0x004A8F20, byte-proven)
    83 C4 04                 add   esp,4
    ...                      GC refcount dance, sometimes via a register
    A3 <global>              mov   [g],eax              (or 89 05 <global>)

The class table names the Type outright (class_tables.tsv). So: scan every function for
that push/call pair and take the first store-to-absolute that follows within a short
window. Conservative by construction -- a Global assigned only from a function return, or
through a register the scan loses, simply stays untyped rather than being guessed.

Conflicts (one Global constructed as two different Types) are reported, never merged: in
BlitzMax that would mean the declared type is a common supertype, which is a different
and weaker claim than what this script is for.
"""

import collections
import os
import struct
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

import bytematch as bm

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, "extracted", "globals_typed_by_new.tsv")

BB_OBJECT_NEW = 0x004A8F20
GAME_LO, GAME_HI = 0x004BA000, 0x0058DBF3
STORE_WINDOW = 96          # bytes to look ahead for the store


def class_tables():
    """classtable VA -> Type name"""
    out = {}
    with open(os.path.join(ROOT, "extracted", "class_tables.tsv"),
              encoding="utf-8", errors="replace") as f:
        next(f, None)
        for line in f:
            p = line.rstrip("\n").split("\t")
            if len(p) >= 2 and p[1].startswith("0x"):
                out[int(p[1], 16)] = p[0]
    return out


def known_globals():
    out = {}
    p = os.path.join(ROOT, "extracted", "globals_named.tsv")
    if not os.path.exists(p):
        return out
    with open(p, encoding="utf-8", errors="replace") as f:
        next(f, None)
        for line in f:
            q = line.rstrip("\n").split("\t")
            if len(q) >= 3 and q[0].startswith("0x"):
                out[int(q[0], 16)] = (q[2], q[1])       # va -> (our_name, inferred_type)
    return out


RET_BY_VA = {}
_SLOTRET = {}


def load_returns(ct):
    """Return types, keyed two ways: by method VA, and by (classtable+slot) address.

    A Global assigned from `TFoo.Create()` is a TFoo (or whatever Create returns), and the
    reflection signature already records that -- ':TFoo' as the return atom. Only object
    returns are useful here; scalar returns tell us nothing about an object Global.
    """
    base = {v: k for k, v in ct.items()}          # Type -> classtable VA
    with open(os.path.join(ROOT, "extracted", "vtable_map.tsv"),
              encoding="utf-8", errors="replace") as f:
        next(f, None)
        for line in f:
            q = line.rstrip("\n").split("\t")
            if len(q) < 6:
                continue
            sig = q[3]
            k = sig.rfind(")")
            ret = sig[k + 1:] if k >= 0 else sig
            if not ret.startswith(":"):
                continue                           # scalar return; not informative
            rt = ret[1:]
            if q[5].startswith("0x"):
                try:
                    RET_BY_VA[int(q[5], 16)] = rt
                except ValueError:
                    pass
            cb = base.get(q[0])
            if cb is not None:
                try:
                    _SLOTRET[cb + int(q[4], 16)] = rt
                except ValueError:
                    pass


def ret_of_slot(addr):
    return _SLOTRET.get(addr)


def main():
    b, img, secs = bm.load(bm.ORIG)
    va2off, _o, _c = bm._helpers(b, img, secs)
    sizes = bm.ghidra_sizes()
    ct = class_tables()
    gl = known_globals()
    load_returns(ct)
    span_hi = img + max(rva + sz for _n, rva, sz, _ro in secs)

    found = collections.defaultdict(collections.Counter)
    sites = 0
    for va, n in sizes.items():
        if not (GAME_LO <= va < GAME_HI):
            continue
        off = va2off(va)
        if off < 0:
            continue
        body = b[off:off + n]
        i = 0
        while i + 10 <= len(body):
            tname, adv = None, 1

            # (1) push <classtable> ; call bbObjectNew        ->  New TFoo
            if body[i] == 0x68 and body[i + 5] == 0xE8:
                imm = struct.unpack_from("<I", body, i + 1)[0]
                if imm in ct:
                    tgt = va + i + 10 + struct.unpack_from("<i", body, i + 6)[0]
                    if tgt == BB_OBJECT_NEW:
                        tname, adv = ct[imm], 10

            # (2) call [<classtable>+slot]                    ->  TFoo.Create() etc.
            #     Most Globals are not built with New at all; they are assigned from a
            #     factory. The slot's own signature in vtable_map gives the return type,
            #     which is exactly the Global's declared type.
            if tname is None and body[i] == 0xFF and body[i + 1] == 0x15:
                addr = struct.unpack_from("<I", body, i + 2)[0]
                rt = ret_of_slot(addr)
                if rt:
                    tname, adv = rt, 6

            # (3) call rel32 to a known game method            ->  same idea, direct call
            if tname is None and body[i] == 0xE8:
                tgt = va + i + 5 + struct.unpack_from("<i", body, i + 1)[0]
                rt = RET_BY_VA.get(tgt)
                if rt:
                    tname, adv = rt, 5

            if tname is None:
                i += 1
                continue
            # bbObjectNew returns in EAX, but bcc almost always parks the object in a
            # callee-saved register while it does the GC refcount dance, so the store is
            # `mov [g],ebx` and not `mov [g],eax`. Track which registers currently hold
            # the new object and accept a store from any of them.
            held = {0}                                               # 0 = eax
            j = i + adv
            stop = min(len(body) - 4, j + STORE_WINDOW)
            while j < stop:
                # mov r32, r32   (89 /r, mod=11): propagate or kill
                if body[j] == 0x89 and 0xC0 <= body[j + 1] <= 0xFF:
                    src = (body[j + 1] >> 3) & 7
                    dst_r = body[j + 1] & 7
                    if src in held:
                        held.add(dst_r)
                    else:
                        held.discard(dst_r)
                    j += 2
                    continue
                # mov [imm32], r32   (A3 = eax special case, or 89 /r with mod=00 rm=101)
                dst = None
                if body[j] == 0xA3 and 0 in held:
                    dst = struct.unpack_from("<I", body, j + 1)[0]
                elif body[j] == 0x89 and (body[j + 1] & 0xC7) == 0x05:
                    if ((body[j + 1] >> 3) & 7) in held:
                        dst = struct.unpack_from("<I", body, j + 2)[0]
                if dst is not None and img <= dst < span_hi and dst not in ct:
                    found[dst][tname] += 1
                    sites += 1
                    break
                j += 1
            i += adv
        # end per-function

    conflicts = {g: c for g, c in found.items() if len(c) > 1}
    with open(OUT, "w", encoding="utf-8", newline="\n") as f:
        f.write("global_va\ttype\tsites\tour_name\tprev_inferred\tconflict\n")
        for g in sorted(found):
            c = found[g]
            t, k = c.most_common(1)[0]
            nm, prev = gl.get(g, ("-", "-"))
            f.write("0x%08x\t%s\t%d\t%s\t%s\t%s\n"
                    % (g, t, k, nm, prev,
                       ";".join("%s=%d" % kv for kv in c.items()) if g in conflicts else ""))

    print("construction sites found : %d" % sites)
    print("object Globals typed     : %d" % len(found))
    print("  with a conflict        : %d  (reported, not merged)" % len(conflicts))
    upgraded = sum(1 for g in found if gl.get(g, ("", ""))[1] in ("Object", "-", ""))
    print("  previously untyped     : %d" % upgraded)
    print("written: %s" % OUT)
    print()
    for g in sorted(found)[:15]:
        t, k = found[g].most_common(1)[0]
        print("   0x%08x -> %-24s (%d site%s)" % (g, t, k, "" if k == 1 else "s"))


if __name__ == "__main__":
    main()
