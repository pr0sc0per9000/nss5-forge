"""
Name the BRL/PUB module functions inside NSS5.exe.

    python scripts/name_brl.py

Writes extracted/brl_functions.tsv (va, symbol, archive, size) and, from the exe's own
reflection data, extracted/brl_type_methods.tsv (va, symbol, type, method, source).

WHY
===
NSS5.exe is stripped, so a call into BlitzMax module code is just an address. That matters
in two ways:
  * the oracle cannot mask an `E8` into module code unless it can name both sides;
  * more importantly, when reconstructing we need to know WHICH builtin a call goes to.
    Measured example: FUN_005071C3 is two 0-argument calls followed by `Flip`. Writing
    `Cls / Cls / Flip` reproduces the length exactly (34/34) and 25 of 34 bytes -- the
    shape is right and only the two callee identities are wrong. Guessing which builtin
    it is does not scale to 1,758 functions.

HOW
===
Module code is compiled by bcc/gcc from source we already have under
tools/blitzmax-legacy-src, and the compiled archives are on disk. So the same function
exists in both places and can be matched by its bytes -- once link-time relocations are
neutralised on both sides, since those necessarily differ:

  * NSS5.exe   -- the PE `.reloc` section lists every dword the loader patched.
  * archives   -- `objdump -r` lists every relocation offset in each member.

Zero those dwords on both sides, require identical length (Ghidra's inventory for the
original), and compare. An exact hit names the address.

This is deliberately conservative: a function whose length is unknown, or which is so
short that it carries no distinguishing bytes, is left unnamed rather than guessed.

AND WHERE REFLECTION CAN ANSWER, IT WINS
========================================
Byte matching is the only route for module-level Functions, but for Type METHODS there is
a second and better one. This tool runs both and reconciles them, because "which of these
two answers do I believe" is not a question a caller should have to hold.

BRL Types are reflected in NSS5.exe exactly like game Types: every Type carries a
BBDebugScope and a class table, and extracted/vtable_map.tsv already records
`Type, Method, slot -> VA`. The exe itself says which method lives at which address. That
is direct evidence, and masked-byte identity is not identity:

  * incomplete -- a short compiler-generated `New`/`Delete` carries almost no
    distinguishing bytes once relocations are excluded, so many are dropped as "weak" or
    land in an alias set too wide to keep (MAX_ALIASES).
  * wrong -- 0x005B78CC byte-matched
    `__brl_map_TMapEnumerator_New|__brl_map_TNodeEnumerator_New`, but reflection says it is
    `TStreamWrapper.New` and TMapEnumerator.New lives elsewhere. Masking keys on the NAME,
    so that row would let a call to TMapEnumerator.New mask against an original call to
    TStreamWrapper.New: a false MATCH, the exact hazard of a wrong helper table.
    142 addresses were in that state.

So the reflection pass runs here, and where the two disagree the archive guess is REPLACED
in brl_functions.tsv rather than left to be corrected downstream.

The symbol spelling matters both ways: the oracle names OUR side from the linker's own
relocation records, where a call into module code is a DISP32 against exactly that mangled
symbol. So a reflected name is emitted only when a symbol of that exact spelling exists in
the compiled archives -- if BlitzMax 1.50 has no such symbol, our side could never produce
it and naming the original's address would be pointless at best.

WHAT THE VA SET OF brl_functions.tsv DELIBERATELY DOES NOT DO
=============================================================
Reflection also names ~400 addresses that byte matching could not name at all. Those go to
brl_type_methods.tsv and are NOT added to brl_functions.tsv, even though they are perfectly
good names. coverage.py derives the project's universe by subtracting the addresses in
brl_functions.tsv, so a row added here moves the one canonical coverage denominator. This
file decides what is NAMED; it must not quietly decide what counts as the game's work.
Narrowing an existing row's symbol is safe on that measure and is what happens instead.
"""

import collections
import os
import re
import struct
import subprocess
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

import bytematch as bm

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
BIN = os.path.join(ROOT, "tools", "blitzmax", "BlitzMax", "MinGW32x86", "bin")
NM = os.path.join(BIN, "nm.exe")
OBJDUMP = os.path.join(BIN, "objdump.exe")
MODDIR = os.path.join(ROOT, "tools", "blitzmax-legacy-src", "mod")
OUT = os.path.join(ROOT, "extracted", "brl_functions.tsv")
VTABLE = os.path.join(ROOT, "extracted", "vtable_map.tsv")
TYPE_OUT = os.path.join(ROOT, "extracted", "brl_type_methods.tsv")

MOD_LO, MOD_HI = 0x0058DBF3, 0x005B9723        # BRL/PUB module code inside NSS5.exe
PAD_NOP = bytes([0x90])
PAD_INT3 = bytes([0xCC])
MIN_LEN = 12                                    # below this a match proves nothing

# An alias set is only useful while it is SMALL. Comparison here masks relocated dwords,
# so two functions that come out "identical" may differ in exactly the operand that was
# masked -- typically the class-table pointer of a one-line `New`. Hundreds of Types share
# such a body, and one address genuinely matched 234 archive symbols.
#
# Masking accepts any member of the set, so a 234-name set would let a call to TFoo.New
# mask against TBar.New: a wrong body would verify. Past this width the name carries no
# evidence and the address is better left unnamed, where the oracle reports an honest
# MISMATCH instead of a false MATCH.
MAX_ALIASES = 6

# Same reasoning for the reflected table. There a set can only widen when two different
# MODULES declare the same Type name with the same method, which is rare, so the cap is
# tighter.
MAX_METHOD_ALIASES = 4

# A BlitzMax method symbol is `__<module path with dots->underscores>_<Type>_<Method>`,
# as nm reports it. Anchoring on `T`/`_` is not safe (types like `NMLVGETINFOTIPW` exist),
# so the split is done by matching the trailing `_<Type>_<Method>` against the reflected
# pair instead. Named NM_SYM_RX, not SYM_RX: that name is already taken further down by the
# objdump disassembly-header pattern, and shadowing it made nm find zero symbols and every
# reflected method look unnameable.
NM_SYM_RX = re.compile(r"^([0-9a-fA-F]+)\s+[Tt]\s+(__\w+)$", re.M)


# ------------------------------------------------------------------ the original

def pe_relocs(path):
    """Set of RVAs patched by the loader (HIGHLOW only -- 32-bit x86 uses nothing else)."""
    b = open(path, "rb").read()
    e = struct.unpack_from("<I", b, 0x3C)[0]
    opt = e + 24
    magic = struct.unpack_from("<H", b, opt)[0]
    dd = opt + (96 if magic == 0x10B else 112)
    rva, size = struct.unpack_from("<II", b, dd + 5 * 8)
    if not rva or not size:
        return set()
    ns = struct.unpack_from("<H", b, e + 6)[0]
    osz = struct.unpack_from("<H", b, e + 20)[0]
    so = e + 24 + osz
    secs = []
    for i in range(ns):
        o = so + i * 40
        _v, srva, ssz, sro = struct.unpack_from("<IIII", b, o + 8)
        secs.append((srva, ssz, sro))

    def r2o(r):
        for srva, ssz, sro in secs:
            if srva <= r < srva + ssz:
                return r - srva + sro
        return -1

    out, off, end = set(), r2o(rva), r2o(rva) + size
    while 0 < off < end:
        page, blk = struct.unpack_from("<II", b, off)
        if blk < 8:
            break
        for i in range((blk - 8) // 2):
            ent = struct.unpack_from("<H", b, off + 8 + i * 2)[0]
            if ent >> 12 == 3:
                out.add(page + (ent & 0xFFF))
        off += blk
    return out


def masked_orig(b, va2off, imgbase, relocs, va, n, span=None):
    """Bytes of the original function with every relocated dword zeroed.

    NSS5.exe ships with its relocation directory stripped (measured: the .reloc data
    directory is empty), so the authoritative list is unavailable and only functions
    containing no absolute addresses at all could ever match -- 7.2% of them.

    Fall back to the same test the oracle uses for masking: a dword that decodes to an
    address inside the image is a relocation site. Zero those, which lines them up with
    the archive side, where objdump -r has already identified them exactly. Applied
    symmetrically, so a constant that merely looks like an address is zeroed on both
    sides and costs nothing.
    """
    off = va2off(off_va := va)
    if off < 0:
        return None
    buf = bytearray(b[off:off + n])
    base_rva = off_va - imgbase
    if relocs:
        for k in range(n - 3):
            if base_rva + k in relocs:
                buf[k:k + 4] = b"\x00\x00\x00\x00"
        return bytes(buf)
    k = 0
    while k <= n - 4:
        v = struct.unpack_from("<I", buf, k)[0]
        if span and span[0] <= v < span[1]:
            buf[k:k + 4] = b"\x00\x00\x00\x00"
            k += 4
        else:
            k += 1
    return bytes(buf)


def mask_addresses(data, span):
    """Same address-zeroing applied to an archive function, so both sides align."""
    buf = bytearray(data)
    k = 0
    while k <= len(buf) - 4:
        v = struct.unpack_from("<I", buf, k)[0]
        if span[0] <= v < span[1]:
            buf[k:k + 4] = b"\x00\x00\x00\x00"
            k += 4
        else:
            k += 1
    return bytes(buf)


# ------------------------------------------------------------------- the archives

def _run(cmd):
    return subprocess.run(cmd, capture_output=True, text=True, errors="replace").stdout or ""


DIS_RX = re.compile(r"^\s*([0-9a-f]+):\s*((?:[0-9a-f]{2} )+)")
SYM_RX = re.compile(r"^([0-9a-f]+)\s+<([^>]+)>:")


def archive_functions(arc):
    """-> {symbol: masked bytes} for every function in every member of `arc`."""
    text = _run([OBJDUMP, "-d", arc])
    relocs = collections.defaultdict(set)
    cur = None
    for line in _run([OBJDUMP, "-r", arc]).splitlines():
        s = line.strip()
        m = re.match(r"^In archive .*|^(\S+\.o):\s*file format", s)
        if m and m.group(1) if m and m.lastindex else None:
            cur = m.group(1)
            continue
        m2 = re.match(r"^([0-9a-fA-F]+)\s+(\S+)\s+(\S+)", s)
        if m2 and cur and m2.group(2) != "TYPE":
            relocs[cur].add(int(m2.group(1), 16))

    out, sym, buf, start, rel = {}, None, bytearray(), 0, set()
    member = None
    for line in text.splitlines():
        s = line.rstrip()
        mm = re.match(r"^(\S+\.o):\s*file format", s.strip())
        if mm:
            member = mm.group(1)
            continue
        ms = SYM_RX.match(s.strip())
        if ms:
            if sym and len(buf) >= MIN_LEN:
                out[sym] = (bytes(buf), rel)
            sym, buf, start, rel = ms.group(2), bytearray(), int(ms.group(1), 16), set()
            continue
        md = DIS_RX.match(s)
        if md and sym is not None:
            off = int(md.group(1), 16)
            if not buf:
                start = off
            data = bytes(int(x, 16) for x in md.group(2).split())
            for k in relocs.get(member, ()):
                if off <= k < off + len(data):
                    rel.add(k - start)
            buf.extend(data)
    if sym and len(buf) >= MIN_LEN:
        out[sym] = (bytes(buf), rel)
    return out


# ------------------------------------------------------------------- reflection

def archive_symbols(arcs):
    """-> every function symbol the compiled BlitzMax archives define."""
    out = set()
    for a in arcs:
        p = subprocess.run([NM, a], capture_output=True, text=True, errors="replace")
        for m in NM_SYM_RX.finditer(p.stdout or ""):
            out.add(m.group(2))
    return out


def reflected_module_methods():
    """-> [(va, Type, Method)] for every reflected method whose code is in module range."""
    rows = []
    if not os.path.exists(VTABLE):
        return rows
    with open(VTABLE, encoding="utf-8", errors="replace") as f:
        next(f, None)
        for line in f:
            p = line.rstrip("\n").split("\t")
            if len(p) < 7 or not p[5].startswith("0x"):
                continue
            if p[6] != "OK":                      # ABSTRACT / BAD_SECTION carry no code
                continue
            try:
                va = int(p[5], 16)
            except ValueError:
                continue
            if not (MOD_LO <= va < MOD_HI):
                continue
            rows.append((va, p[0], p[2]))
    return rows


def reflect(arcs):
    """-> (final, refl, wide, unmatched): va -> symbol, va -> (Type, Method), and rejects."""
    allsyms = archive_symbols(arcs)
    rows = reflected_module_methods()
    print("archive symbols      : %d" % len(allsyms))
    print("reflected methods    : %d (in module range)" % len(rows))

    named, unmatched = {}, collections.Counter()
    for va, t, m in rows:
        tail = "_%s_%s" % (t, m)
        hits = {s for s in allsyms if s.endswith(tail)}
        if not hits:
            unmatched[t] += 1
            continue
        named.setdefault(va, set()).update(hits)

    final, wide = {}, []
    for va in sorted(named):
        syms = named[va]
        if len(syms) > MAX_METHOD_ALIASES:
            wide.append((va, syms))
            continue
        final[va] = "|".join(sorted(syms))
    return final, {va: (t, m) for va, t, m in rows}, wide, unmatched


def write_type_methods(final, refl):
    # NO COMMENT BLOCK. csv.DictReader parses leading `#` lines as data rows, so this
    # table starts at its header row and the commentary lives alongside it in
    # extracted/brl_type_methods.README.md. Emitting a comment block here breaks every
    # reader of the table, silently.
    with open(TYPE_OUT, "w", encoding="utf-8", newline="\n") as f:
        f.write("va\tsymbol\ttype\tmethod\tsource\n")
        for va in sorted(final):
            t, m = refl[va]
            f.write("0x%08x\t%s\t%s\t%s\treflection\n" % (va, final[va], t, m))


def main():
    b, imgbase, secs = bm.load(bm.ORIG)
    va2off, _o, _c = bm._helpers(b, imgbase, secs)
    relocs = pe_relocs(bm.ORIG)
    sizes = bm.ghidra_sizes()
    targets = {va: n for va, n in sizes.items()
               if MOD_LO <= va < MOD_HI and n >= MIN_LEN}
    print("PE relocations       : %d" % len(relocs))
    print("module functions     : %d" % len(targets))

    bylen = collections.defaultdict(list)
    raw = {}
    for va, n in targets.items():
        off = va2off(va)
        if off < 0:
            continue
        raw[va] = b[off:off + n]
        bylen[n].append(va)

    arcs = []
    for dirpath, _d, files in os.walk(MODDIR):
        for f in files:
            if f.endswith(".release.win32.x86.a"):
                arcs.append(os.path.join(dirpath, f))
    print("archives             : %d" % len(arcs))

    named, ambiguous, wide, weak = {}, 0, 0, 0
    for a in arcs:
        for sym, (data, rel) in archive_functions(a).items():
            skip = set()
            for r in rel:
                skip.update(range(r, r + 4))

            # A match only means something if enough bytes were actually COMPARED.
            # Relocation offsets are excluded, and a function dense in relocations has
            # most of its body excluded -- so it matches nearly anything of the same
            # length. That is what produced absurd alias sets: 0x005B9690 (48 bytes,
            # genuinely _bbFloatToInt) also "matched" a dozen unrelated FreeType stubs.
            # Require at least half the body, and never fewer than MIN_LEN bytes, to
            # survive the exclusions before this symbol may claim an address.
            informative = len(data) - len(skip)
            if informative < max(MIN_LEN, len(data) // 2):
                weak += 1
                continue

            hits = [va for va in bylen.get(len(data), ())
                    if all(x == y for k, (x, y) in enumerate(zip(raw[va], data))
                           if k not in skip)]
            # ALIASES, in BOTH directions.
            #
            # Several BRL functions can be byte-identical -- brl.gnet.GNetObjectState,
            # brl.stream.Eof, brl.timer.TimerTicks and pub.freeprocess.ProcessStatus are
            # all the same 21 bytes. Keeping only the first match mislabelled 0x005B80B9
            # as GNetObjectState when the caller meant Eof, and the oracle then refused to
            # mask a correct body (TTeamPool.LoadData: 102/102 length, one E8 differing).
            #
            # The mirror case is one archive symbol matching several original addresses.
            # Counting that "ambiguous" and dropping it discards 814 symbols and holds
            # coverage at 43.6%. Dropping is the wrong call: each of those originals
            # genuinely has bytes identical to this symbol, so the symbol belongs in every
            # one of their alias sets. The address cannot be narrowed to a single name and
            # the honest representation of that is a set, not a discard.
            if len(hits) > 1:
                ambiguous += 1
            for va in hits:
                named.setdefault(va, (set(), os.path.basename(a)))
                named[va][0].add(sym)

    refl_final, refl_pair, refl_wide, refl_unmatched = reflect(arcs)
    write_type_methods(refl_final, refl_pair)

    # Classify against what brl_functions.tsv will ACTUALLY carry, not against every
    # byte-match in memory: an address whose alias set was too wide is dropped from that
    # file, so reflection is supplying its name rather than overriding one.
    emitted = {va: syms for va, (syms, _arc) in named.items() if len(syms) <= MAX_ALIASES}
    agree, add, override = 0, 0, []
    for va, sym in refl_final.items():
        if va not in emitted:
            add += 1
        elif emitted[va] == set(sym.split("|")):
            agree += 1
        else:
            override.append((va, "|".join(sorted(emitted[va])), sym))

    with open(OUT, "w", encoding="utf-8", newline="\n") as f:
        f.write("va\tsymbol\tarchive\tsize\n")
        for va in sorted(named):
            syms, arc = named[va]
            if len(syms) > MAX_ALIASES:
                wide += 1
                continue
            # Pipe-separated alias set: several BRL functions can be byte-identical, so
            # the address genuinely cannot be narrowed to one name. The mask accepts any
            # member, which is correct -- if our side calls one of them, the original's
            # call at the same offset is the same construct.
            #
            # Unless reflection knows better, in which case it simply wins: the exe's own
            # class table is direct evidence and a masked-byte alias set is a guess.
            f.write("0x%08x\t%s\t%s\t%d\n"
                    % (va, refl_final.get(va) or "|".join(sorted(syms)), arc, sizes[va]))

    print()
    print("NAMED                : %d of %d (%.1f%%)"
          % (len(named), len(targets), 100.0 * len(named) / max(1, len(targets))))
    print("ambiguous (alias sets): %d" % ambiguous)
    print("dropped, set too wide : %d (>%d names -> no evidence)" % (wide, MAX_ALIASES))
    print("archive fns too weak  : %d (too few bytes survive relocation exclusion)" % weak)
    print("written              : %s" % OUT)
    for va in sorted(named)[:15]:
        print("   0x%08x  %s"
              % (va, refl_final.get(va) or "|".join(sorted(named[va][0]))))

    print()
    print("REFLECTED METHODS    : %d written to %s" % (len(refl_final), TYPE_OUT))
    print("  agree with archive : %d" % agree)
    print("  archive had nothing: %d (kept out of %s on purpose -- see the header)"
          % (add, os.path.basename(OUT)))
    print("  OVERRIDE archive   : %d" % len(override))
    print("  dropped, set > %d   : %d" % (MAX_METHOD_ALIASES, len(refl_wide)))
    print("  no archive symbol  : %d methods across %d types"
          % (sum(refl_unmatched.values()), len(refl_unmatched)))
    if override:
        print()
        print("!! archive matching disagreed with reflection at these addresses.")
        print("!! Reflection wins; the archive names are DROPPED because masking keys on")
        print("!! the NAME and a wrong one produces a FALSE MATCH (section 3b).")
        for va, old, new in override[:40]:
            print("   0x%08x" % va)
            print("      was : %s" % old)
            print("      now : %s" % new)
        if len(override) > 40:
            print("   ... %d more" % (len(override) - 40))
    if refl_wide:
        print()
        print("dropped (reflected alias set too wide):")
        for va, syms in refl_wide[:10]:
            print("   0x%08x  %s" % (va, "|".join(sorted(syms))))


if __name__ == "__main__":
    main()
