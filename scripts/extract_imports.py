"""Name every DLL import thunk in NSS5.exe.

WHY. A call into a DLL looks like any other `E8 rel32` in a body, and the target is a
six-byte thunk (`FF 25 <IAT slot>` + two NOP pad bytes) that carries no name of its own. So
every such call reads as `<UNNAMED>` to the oracle, cannot be masked, and blocks the body
that makes it. That is not a small class: NSS5.exe imports from WINMM, OPENAL32, STEAMSTUB,
KERNEL32, USER32, GDI32 and more, and the game calls into them constantly.

The names are not a guess. They are in the PE import directory, and each thunk points at
exactly one Import Address Table slot, so thunk -> DLL + symbol is a lookup, not an
inference. This was found while recovering the module Function at 0x0058D987, whose three
unnamed calls turned out to be STEAMSTUB.DLL's FindLeaderboard, ReadSteam and
UploadLeaderboardScore -- the working hypothesis in the caller's notes had been a
save-directory scan, which the names immediately disproved.

Emits extracted/dll_imports.tsv:  thunk_va, symbol, dll, iat_va

    python scripts/extract_imports.py [--verify]
"""

import os
import struct
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
EXE = os.path.join(ROOT, "binary", "NSS5.exe")
OUT = os.path.join(ROOT, "extracted", "dll_imports.tsv")


def _sections(d, pe):
    n = struct.unpack_from("<H", d, pe + 6)[0]
    opthdr = struct.unpack_from("<H", d, pe + 20)[0]
    out = []
    for i in range(n):
        o = pe + 24 + opthdr + i * 40
        vs, va, rs, pr = struct.unpack_from("<IIII", d, o + 8)
        out.append((va, vs, rs, pr))
    return out


def parse(path=EXE):
    d = open(path, "rb").read()
    pe = struct.unpack_from("<I", d, 0x3C)[0]
    opt = pe + 24
    base = struct.unpack_from("<I", d, opt + 28)[0]
    imp_rva = struct.unpack_from("<I", d, opt + 96 + 8)[0]
    secs = _sections(d, pe)

    def r2o(rva):
        for va, vs, rs, pr in secs:
            if va <= rva < va + max(vs, rs):
                return pr + (rva - va)
        return None

    def cstr(off):
        return d[off:d.index(b"\0", off)].decode("latin1")

    # ---- IAT slot VA -> (dll, symbol) -------------------------------------
    iat = {}
    o = r2o(imp_rva)
    while True:
        oft, _ts, _fc, namerva, fthunk = struct.unpack_from("<IIIII", d, o)
        if namerva == 0:
            break
        dll = cstr(r2o(namerva))
        t = r2o(oft or fthunk)
        i = 0
        while True:
            v = struct.unpack_from("<I", d, t + i * 4)[0]
            if v == 0:
                break
            if v & 0x80000000:
                sym = "%s_ordinal_%d" % (dll.split(".")[0].lower(), v & 0xFFFF)
            else:
                sym = cstr(r2o(v) + 2)
            iat[base + fthunk + i * 4] = (dll, sym)
            i += 1
        o += 20

    # ---- find the `jmp dword ptr [IAT]` thunks that point at them ---------
    # Scanning for the two-byte FF 25 opcode and validating the operand against the IAT
    # map is safe in a way that scanning for a lone byte is not: a false positive has to
    # be followed by four bytes that happen to be a live IAT slot address.
    thunks = {}
    for va, vs, rs, pr in secs:
        blob = d[pr:pr + rs]
        start = 0
        while True:
            k = blob.find(b"\xff\x25", start)
            if k < 0:
                break
            start = k + 2
            if k + 6 > len(blob):
                break
            slot = struct.unpack_from("<I", blob, k + 2)[0]
            if slot in iat:
                thunks[base + va + k] = iat[slot] + (slot,)
    return base, iat, thunks


def main():
    base, iat, thunks = parse()
    with open(OUT, "w", encoding="utf-8", newline="\n") as f:
        f.write("thunk_va\tsymbol\tdll\tiat_va\n")
        for tva in sorted(thunks):
            dll, sym, slot = thunks[tva]
            f.write("0x%08x\t%s\t%s\t0x%08x\n" % (tva, sym, dll, slot))

    bydll = {}
    for _tva, (dll, _s, _slot) in thunks.items():
        bydll[dll] = bydll.get(dll, 0) + 1
    print("IAT slots        : %d" % len(iat))
    print("thunks resolved  : %d" % len(thunks))
    print("written          : %s" % os.path.relpath(OUT, ROOT))
    print()
    for dll, n in sorted(bydll.items(), key=lambda kv: -kv[1]):
        print("   %-20s %4d" % (dll, n))

    if "--verify" in sys.argv:
        # every thunk must be 6 bytes of jmp + padding, and must not collide with a name
        # we already have from another table
        sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
        import helper_map as HM
        tab = HM.full_table()
        clash = []
        for tva, (dll, sym, _s) in thunks.items():
            for k in (tva, "0x%08x" % tva):
                if k in tab:
                    have = tab[k]
                    have = have[0] if isinstance(have, tuple) else have
                    if have != sym:
                        clash.append((tva, have, sym, dll))
        print()
        if clash:
            print("!! %d thunk(s) already carry a DIFFERENT name in an existing table:" % len(clash))
            for tva, have, sym, dll in clash[:20]:
                print("   0x%08x  existing=%-28s import=%s (%s)" % (tva, have, sym, dll))
            print("   Investigate before trusting either. A wrong name blesses wrong source.")
            return 1
        print("   no name collisions with existing tables")
    return 0


if __name__ == "__main__":
    sys.exit(main())
