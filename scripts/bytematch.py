"""
Byte-compare one reconstructed method against the original NSS5.exe.

Both binaries are legacy BlitzMax and carry BBDebugScope/BBDebugDecl reflection tables,
so a method is located in EACH exe by the same route: Type scope -> class table ->
vtable slot -> code address.

FUNCTION LENGTH -- READ THIS BEFORE CHANGING ANYTHING
=====================================================
Never find the end of a function by scanning forward for the first 0xC3 byte on the theory
that 0xC3 is `ret`. That is WRONG: 0xC3 also appears inside other instructions, e.g.
`83 C3 01` (add ebx,1) and `89 C3` (mov ebx,eax). Any function using EBX as a loop counter
is then silently truncated, compared over a fraction of its real length, and reported as a
confident MATCH: that is how a 199-byte function gets blessed on 62 bytes of agreement,
with a wrong body.

Lengths therefore come from two independent places:
  * ORIGINAL length is taken from Ghidra's own function inventory (authoritative).
  * OUR length is found by scanning for the real BlitzMax epilogue `89 EC 5D C3`
    (mov esp,ebp / pop ebp / ret), not a bare 0xC3.
A match REQUIRES both that the lengths agree and that every byte agrees. Comparing a
prefix is never sufficient.

Usage: bytematch.py <ourExe> <TypeName> <MethodName>
"""

import os
import struct
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ORIG = os.path.join(ROOT, "binary", "NSS5.exe")
INVENTORY = os.path.join(ROOT, "extracted", "ghidra", "function_inventory.tsv")

DECL_KIND = {1, 2, 3, 4, 5, 6, 7}
EPILOGUE = b"\x89\xEC\x5D\xC3"          # mov esp,ebp ; pop ebp ; ret
MAX_FN = 65536


# --------------------------------------------------------------------------- PE

def load(path):
    b = open(path, "rb").read()
    e = struct.unpack_from("<I", b, 0x3C)[0]
    img = struct.unpack_from("<I", b, e + 24 + 28)[0]
    ns = struct.unpack_from("<H", b, e + 6)[0]
    osz = struct.unpack_from("<H", b, e + 20)[0]
    so = e + 24 + osz
    secs = []
    for i in range(ns):
        o = so + i * 40
        nm = b[o:o + 8].rstrip(b"\x00").decode("ascii", "replace")
        _v, rva, rs, ro = struct.unpack_from("<IIII", b, o + 8)
        secs.append((nm, rva, rs, ro))
    return b, img, secs


def _helpers(b, img, secs):
    def va2off(v):
        r = v - img
        for _n, rva, sz, ro in secs:
            if rva <= r < rva + sz:
                return r - rva + ro
        return -1

    def off2va(o):
        for _n, rva, sz, ro in secs:
            if ro <= o < ro + sz:
                return o - ro + rva + img
        return -1

    def cstr(o, lim=200):
        if o < 0 or o >= len(b):
            return None
        e = o
        while e < len(b) and 32 <= b[e] < 127 and e - o < lim:
            e += 1
        return b[o:e].decode("ascii") if e < len(b) and b[e] == 0 and e > o else None

    return va2off, off2va, cstr


# --------------------------------------------------------- module-scope VA access
#
# The harness hands back only a ~10 instruction window and the first 96 hex bytes, which is
# nowhere near enough on a typical body (median well past 250 bytes, largest 16 KB), and
# some matches only come out after reading the original's FULL disassembly. Without the
# wrappers below, reading the original at an arbitrary VA means re-deriving the section
# walk from load() by hand, because va2off is otherwise a closure created inside _helpers
# and used inside main(). So the three primitives are exposed at module scope.
_LOADED = {}


def _img(path):
    if path not in _LOADED:
        b, img, secs = load(path)
        _LOADED[path] = (b, img, secs) + _helpers(b, img, secs)
    return _LOADED[path]


def va2off(va, path=None):
    """File offset of `va` in `path` (default NSS5.exe), or -1 if not mapped."""
    return _img(path or ORIG)[3](va)


def read_va(va, n, path=None):
    """`n` bytes at virtual address `va`, or None if the range is not wholly mapped."""
    b = _img(path or ORIG)[0]
    off = va2off(va, path)
    if off < 0 or off + n > len(b):
        return None
    return b[off:off + n]


def disasm_original(va, n=None, path=None):
    """Full disassembly text of the function at `va` -- the whole body, not a window.

    `n` defaults to Ghidra's authoritative size for that VA, so
    `disasm_original(0x004bd132)` is the complete original of a workset row.
    """
    n = n or ghidra_sizes().get(va)
    if not n:
        return "0x%08X: length unknown (not in Ghidra's inventory); pass n=" % va
    buf = read_va(va, n, path)
    if buf is None:
        return "0x%08X: +%d is not wholly inside the image" % (va, n)
    try:
        import capstone
    except ImportError:
        return " ".join("%02X" % x for x in buf)
    md = capstone.Cs(capstone.CS_ARCH_X86, capstone.CS_MODE_32)
    md.skipdata = True
    return "\n".join(
        "%08X  %-4d %-21s %s %s" % (x.address, x.address - va,
                                    " ".join("%02X" % b for b in x.bytes),
                                    x.mnemonic, x.op_str)
        for x in md.disasm(bytes(buf), va))


# ------------------------------------------------------------------ true sizes

_SIZES = None


def ghidra_sizes():
    """VA -> true function size, straight from Ghidra's analysis of NSS5.exe."""
    global _SIZES
    if _SIZES is not None:
        return _SIZES
    _SIZES = {}
    try:
        with open(INVENTORY, encoding="utf-8", errors="replace") as f:
            next(f, None)
            for line in f:
                p = line.rstrip("\n").split("\t")
                if len(p) < 4:
                    continue
                try:
                    _SIZES[int(p[0], 16)] = int(p[3])
                except ValueError:
                    pass
    except OSError:
        pass
    return _SIZES


def epilogue_len(b, off, cap=MAX_FN):
    """Length of the function at `off`, ending at the first real BlitzMax epilogue."""
    end = b.find(EPILOGUE, off, min(off + cap, len(b)))
    return (end - off + len(EPILOGUE)) if end != -1 else None


# ------------------------------------------------------------------- locate fn

def find_method(path, tname, mname):
    """-> dict(off, va, length, bytes, length_source) or None"""
    b, img, secs = load(path)
    va2off, off2va, cstr = _helpers(b, img, secs)

    scope_va = slot = None
    for i in range(0, len(b) - 32, 4):
        if struct.unpack_from("<I", b, i)[0] != 2:
            continue
        p = struct.unpack_from("<I", b, i + 4)[0]
        if p < img or cstr(va2off(p)) != tname:
            continue
        j, found = i + 8, None
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
            if nn == mname and k in (6, 7):
                found = struct.unpack_from("<I", b, j + 12)[0]
            j += 16
        if found is not None:
            scope_va, slot = off2va(i), found
            break
    if scope_va is None:
        return None

    nd = struct.pack("<I", scope_va)
    ct, k = None, b.find(nd)
    while k != -1:
        c = k - 8
        if c > 0:
            sup, _f, _d, isz = struct.unpack_from("<IIII", b, c)
            if 0 < isz < 20000 and (sup == 0 or sup > img):
                ct = c
                break
        k = b.find(nd, k + 1)
    if ct is None:
        return None

    addr = struct.unpack_from("<I", b, ct + slot)[0]
    off = va2off(addr)
    if off < 0:
        return None

    # Authoritative size for the original; epilogue scan for anything else.
    n = ghidra_sizes().get(addr) if os.path.abspath(path) == os.path.abspath(ORIG) else None
    src = "ghidra"
    if n is None:
        n = epilogue_len(b, off)
        src = "epilogue"
    if n is None:
        return None

    return {"off": off, "va": addr, "length": n,
            "bytes": b[off:off + n], "length_source": src}


# ----------------------------------------------------------------------- main

def compare(ours_path, tname, mname):
    a = find_method(ORIG, tname, mname)
    c = find_method(ours_path, tname, mname)
    if not a:
        return {"status": "NOT_FOUND", "where": "original"}
    if not c:
        return {"status": "NOT_FOUND", "where": "ours"}

    same_len = a["length"] == c["length"]
    same_bytes = a["bytes"] == c["bytes"]
    matched = sum(1 for x, y in zip(a["bytes"], c["bytes"]) if x == y)

    res = {
        "status": "MATCH" if (same_len and same_bytes) else "MISMATCH",
        "orig_va": a["va"], "orig_len": a["length"], "orig_len_from": a["length_source"],
        "our_va": c["va"], "our_len": c["length"],
        "matched": matched, "compared": min(a["length"], c["length"]),
    }
    if res["status"] == "MISMATCH":
        for i, (x, y) in enumerate(zip(a["bytes"], c["bytes"])):
            if x != y:
                res["first_diff"] = i
                res["orig_hex"] = " ".join("%02X" % v for v in a["bytes"][max(0, i - 8):i + 24])
                res["our_hex"] = " ".join("%02X" % v for v in c["bytes"][max(0, i - 8):i + 24])
                break
        if not same_len:
            res["reason"] = "length differs (%d vs %d)" % (a["length"], c["length"])
    return res


def main():
    ours, tname, mname = sys.argv[1], sys.argv[2], sys.argv[3]
    r = compare(ours, tname, mname)
    if r["status"] == "MATCH":
        print("*** BYTE-IDENTICAL  (%d/%d bytes, length from %s) ***"
              % (r["orig_len"], r["orig_len"], r["orig_len_from"]))
        return 0
    if r["status"] == "NOT_FOUND":
        print("NOT FOUND in %s" % r["where"])
        return 2
    print("MISMATCH: %d/%d bytes equal   orig_len=%d (%s) our_len=%d"
          % (r["matched"], r["compared"], r["orig_len"], r["orig_len_from"], r["our_len"]))
    if "reason" in r:
        print("  " + r["reason"])
    if "first_diff" in r:
        print("  first difference at byte %d" % r["first_diff"])
        print("  orig: " + r["orig_hex"])
        print("  ours: " + r["our_hex"])
    return 1


if __name__ == "__main__":
    sys.exit(main())
