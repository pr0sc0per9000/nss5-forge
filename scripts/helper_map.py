"""
Name the C-runtime helpers on BOTH sides of the byte comparison.

THE PROBLEM
===========
`bcc` emits FASM for game code, so game code is byte-reproducible. But calls into the
BlitzMax C runtime are `E8 rel32`, whose displacement depends on where the helper landed,
and our runtime is built by a DIFFERENT GCC than the original's. Measured: NSS5's
bbObjectDowncast at 0x004A8F60 is 37 bytes and agrees with ours in only 12 of them --
same algorithm, different instruction scheduling. So the helper is at a different address
AND has different bytes, and the displacement can never match by construction.

Census (scripts/runtime_call_census.py): game code calls exactly **71** distinct runtime
helpers across 9,399 call sites, and 1,174 of 1,850 game functions call at least one.
That is 63% of the codebase gated behind naming 71 addresses.

OUR SIDE -- exact, from the linker's own data
=============================================
bmk leaves the intermediate object beside the exe:
    .bmx/probe.bmx.console.release.win32.x86.o
`nm` gives every BlitzMax function's offset in the `code` section; `objdump -r` gives, for
every relocation, the offset of the operand and the NAME of the symbol it targets. One
BlitzMax method located in the exe by reflection fixes the base, and every relocation then
resolves to a concrete exe address with a real symbol name attached. Verified by hand:
`__bb_TCameraMan_UpdateAll` at .o+0x61C7 -> exe 0x0051B1FB gives base 0x00515034, and the
`DISP32 _bbObjectDowncast` relocation at .o+0x61F2 lands on 0x0051B226, exactly the rel32
operand of the `E8` at 0x0051B225. No guessing anywhere.

THE ORIGINAL SIDE -- bootstrapped, corroborated, recorded
=========================================================
NSS5.exe is stripped, so the original's helper addresses have no names. They are learned
by alignment: when a candidate body reproduces a function so exactly that the ONLY
differing bytes are rel32 operands, then the call at offset X in ours and the call at
offset X in the original are the same construct, so the original's target is the same
helper our relocation names. Each such observation is a witness; witnesses accumulate in
extracted/runtime_helpers.tsv. 405 different functions call 0x004A8F60 at downcast sites,
so corroboration is overwhelming -- but the count is recorded rather than assumed, and
single-witness entries are marked so a MATCH that leans on one can be seen for what it is.
"""

import os
import re
import subprocess
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

import bytematch as _bytematch

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
BIN = os.path.join(ROOT, "tools", "blitzmax", "BlitzMax", "MinGW32x86", "bin")
NM = os.path.join(BIN, "nm.exe")
OBJDUMP = os.path.join(BIN, "objdump.exe")
TABLE = os.path.join(ROOT, "extracted", "runtime_helpers.tsv")

RT_LO, RT_HI = 0x00401000, 0x004BA000          # the C runtime range in NSS5.exe
SYM_RX = re.compile(r"^([0-9a-fA-F]+)\s+[Tt]\s+(\S+)$", re.M)
BB_METHOD_RX = re.compile(r"^__bb_([A-Za-z_]\w*)_(\w+)$")


def _run(cmd):
    p = subprocess.run(cmd, capture_output=True, text=True, errors="replace")
    return p.stdout or ""


def object_symbols(objpath):
    """symbol -> offset within the object's `code` section"""
    return {m.group(2): int(m.group(1), 16) for m in SYM_RX.finditer(_run([NM, objpath]))}


def code_relocations(objpath):
    """[(offset, kind, symbol)] for the `code` section only"""
    out, cur = [], None
    for line in _run([OBJDUMP, "-r", objpath]).splitlines():
        m = re.match(r"RELOCATION RECORDS FOR \[(\w+)\]:", line.strip())
        if m:
            cur = m.group(1)
            continue
        if cur != "code":
            continue
        m = re.match(r"^([0-9a-fA-F]+)\s+(\S+)\s+(\S+)\s*$", line.strip())
        if m and m.group(2) != "TYPE":
            out.append((int(m.group(1), 16), m.group(2), m.group(3)))
    return out


def resolve_base(objpath, exepath, syms=None):
    """Offset from `code`-section offsets to exe VAs.

    Computed from several BlitzMax method symbols independently; they must all agree,
    which is a free consistency check on the whole mapping.
    """
    syms = syms or object_symbols(objpath)
    bases, tried = {}, 0
    for sym, off in syms.items():
        m = BB_METHOD_RX.match(sym)
        if not m:
            continue
        tname, mname = m.group(1), m.group(2)
        try:
            r = _bytematch.find_method(exepath, tname, mname)
        except Exception:                                        # noqa: BLE001
            continue
        if not r:
            continue
        bases[r["va"] - off] = bases.get(r["va"] - off, 0) + 1
        tried += 1
        if tried >= 8:
            break
    if not bases:
        return None
    base, n = max(bases.items(), key=lambda kv: kv[1])
    if len(bases) > 1:                     # disagreement means the mapping is unsound
        return None
    return base if n else None


def our_helpers(workdir, exepath):
    """symbol -> address in OUR exe, for every runtime symbol this build calls.

    Only DISP32 (pc-relative) relocations are used: those are the call/jmp operands.
    """
    bmxdir = os.path.join(workdir, ".bmx")
    objs = [f for f in os.listdir(bmxdir)] if os.path.isdir(bmxdir) else []
    objs = [os.path.join(bmxdir, f) for f in objs if f.endswith(".o")]
    if not objs:
        return {}, None
    objpath = max(objs, key=os.path.getsize)

    syms = object_symbols(objpath)
    base = resolve_base(objpath, exepath, syms)
    if base is None:
        return {}, None

    b, _img, secs = _bytematch.load(exepath)
    va2off, _o2v, _c = _bytematch._helpers(b, _img, secs)

    import struct
    out = {}
    for off, kind, sym in code_relocations(objpath):
        if kind != "DISP32":
            continue
        site = base + off                       # VA of the rel32 operand
        o = va2off(site)
        if o < 0 or o + 4 > len(b):
            continue
        rel = struct.unpack_from("<i", b, o)[0]
        out.setdefault(sym, site + 4 + rel)
    return out, base


# ------------------------------------------------------------------ original side

def load_table():
    """orig_va -> (symbol, witness_count)"""
    t = {}
    if not os.path.exists(TABLE):
        return t
    with open(TABLE, encoding="utf-8") as f:
        next(f, None)
        for line in f:
            p = line.rstrip("\n").split("\t")
            if len(p) >= 3:
                try:
                    t[int(p[0], 16)] = (p[1], int(p[2]))
                except ValueError:
                    pass
    return t


def save_table(t):
    os.makedirs(os.path.dirname(TABLE), exist_ok=True)
    with open(TABLE, "w", encoding="utf-8", newline="\n") as f:
        f.write("va\tsymbol\twitnesses\n")
        for va in sorted(t):
            sym, n = t[va]
            f.write("0x%08x\t%s\t%d\n" % (va, sym, n))


_BRL = None
BRL_TABLE = os.path.join(ROOT, "extracted", "brl_functions.tsv")


def brl_table():
    """orig_va -> symbol, for BRL/PUB module functions inside NSS5.exe.

    Produced by scripts/name_brl.py, which matches each module function against the
    compiled BlitzMax archives byte-for-byte with relocation sites excluded. That is
    direct identification, not inference, so these need no witness count.
    """
    global _BRL
    if _BRL is not None:
        return _BRL
    _BRL = {}
    if os.path.exists(BRL_TABLE):
        with open(BRL_TABLE, encoding="utf-8", errors="replace") as f:
            next(f, None)
            for line in f:
                p = line.rstrip("\n").split("\t")
                if len(p) >= 2 and p[0].startswith("0x"):
                    try:
                        _BRL[int(p[0], 16)] = p[1]
                    except ValueError:
                        pass

    # Structurally-inferred names, kept in their own file so the distinction between
    # "proved by bytes" and "argued from structure" never gets lost. setdefault, so a
    # byte-proven name always wins over an inferred one.
    inf = os.path.join(ROOT, "extracted", "brl_functions_inferred.tsv")
    if os.path.exists(inf):
        with open(inf, encoding="utf-8", errors="replace") as f:
            for line in f:
                if line.startswith("#") or line.startswith("va\t"):
                    continue
                p = line.rstrip("\n").split("\t")
                if len(p) >= 2 and p[0].startswith("0x"):
                    try:
                        _BRL.setdefault(int(p[0], 16), p[1])
                    except ValueError:
                        pass

    # BRL/PUB Type METHODS, named by REFLECTION (scripts/name_brl_methods.py).
    #
    # This one OVERRIDES rather than setdefault, and that is deliberate. The other two
    # tables identify an address by comparing bytes with relocation sites excluded, which
    # cannot separate two Types whose method bodies differ ONLY in a masked operand -- the
    # class-table pointer of a compiler-generated New is exactly that. NSS5.exe's own
    # reflection data says outright which Type+slot lives at which VA, so it is direct
    # evidence and the byte-match guess must yield to it.
    #
    # Dropping the loser is the point, not a side effect. Masking keys on the NAME, so
    # leaving `__brl_map_TMapEnumerator_New` attached to 0x005B78CC (really
    # TStreamWrapper.New) would let a probe that calls the WRONG BRL method mask clean --
    # a false MATCH, the hazard of a wrong helper table. Without the reflection rows, 142
    # addresses sit in that state.
    tm = os.path.join(ROOT, "extracted", "brl_type_methods.tsv")
    if os.path.exists(tm):
        with open(tm, encoding="utf-8", errors="replace") as f:
            for line in f:
                if line.startswith("#") or line.startswith("va\t"):
                    continue
                p = line.rstrip("\n").split("\t")
                if len(p) >= 2 and p[0].startswith("0x"):
                    try:
                        _BRL[int(p[0], 16)] = p[1]
                    except ValueError:
                        pass

    # DLL IMPORT THUNKS (scripts/extract_imports.py -> extracted/dll_imports.tsv).
    #
    # A call into a DLL targets a six-byte `jmp dword ptr [IAT slot]` thunk that carries no
    # name, so it reads as <UNNAMED> and blocks the body that makes it. The name is a
    # LOOKUP, not an inference: the PE import directory says which slot holds which symbol
    # of which DLL, and each thunk points at exactly one slot. 324 thunks across 11 DLLs.
    #
    # setdefault, so anything byte-proven or reflection-proven keeps priority. --verify on
    # extract_imports.py reports collisions rather than silently overwriting; it found none.
    #
    # Worked example: the module Function at 0x0058D987 makes three unnamed calls, and they
    # are STEAMSTUB.DLL's FindLeaderboard / ReadSteam / UploadLeaderboardScore -- not the
    # save-directory scan the loop's shape suggests.
    #
    # THE LEADING UNDERSCORE IS ADDED HERE. Every other table in this file stores symbols
    # exactly as they appear in an object file's relocations, which on this toolchain always
    # carry the C/cdecl leading underscore ("_bbSin", "__brl_max2d_..."). dll_imports.tsv is
    # an honest transcript of the PE import directory, which holds the UNDECORATED name
    # ("OpenSteam"), so without the prefix it never matches `ournames` (built from
    # `objdump -r`, which reports "_OpenSteam"). Only a byte-verified '!Import body exposes
    # this, which is why it stays easy to miss (SteamPostPlayerValue is still a near-miss).
    # Measured on SteamInit @ 0x0058D86D: the OpenSteam call operand is the only unmasked
    # byte range once the prefix is added, and the whole 158-byte body then matches.
    # Prefixing here rather than editing the TSV keeps the extractor's output faithful.
    imp = os.path.join(ROOT, "extracted", "dll_imports.tsv")
    if os.path.exists(imp):
        with open(imp, encoding="utf-8", errors="replace") as f:
            for line in f:
                if line.startswith("#") or line.startswith("thunk_va\t"):
                    continue
                p = line.rstrip("\n").split("\t")
                if len(p) >= 2 and p[0].startswith("0x"):
                    try:
                        _BRL.setdefault(int(p[0], 16), "_" + p[1])
                    except ValueError:
                        pass
    return _BRL


def full_table():
    """Everything usable for masking: directly-identified BRL names plus learned helpers.

    Kept separate from load_table() on purpose -- record()/save_table() must only ever
    write back the bootstrapped runtime-helper entries, never the BRL ones.
    """
    t = {va: (sym, 999) for va, sym in brl_table().items()}
    t.update(load_table())
    return t


def record(observations):
    """observations: [(orig_va, symbol)] -> merged table, plus any conflicts found.

    A conflict means one original address was aligned to two different helper names,
    which would mean the alignment logic is wrong. It is reported, never averaged away.
    """
    t = load_table()
    conflicts = []
    for va, sym in observations:
        if not (RT_LO <= va < RT_HI):
            continue
        if va in t and t[va][0] != sym:
            conflicts.append((va, t[va][0], sym))
            continue
        t[va] = (sym, t.get(va, (sym, 0))[1] + 1)
    save_table(t)
    return t, conflicts


# --------------------------------------------- game methods, named on BOTH sides
#
# A direct call to another BlitzMax function -- `Super.ToString()`, or any non-virtual
# call bcc resolves statically -- is `E8 rel32`, so the operand differs by layout and is
# unmaskable by the absolute-address rule. Comparing the two call targets byte-for-byte
# does not work either: in a probe every non-target method is an emitted STUB, so our
# parent's body legitimately differs from the original's real one. The oracle was right
# to refuse, but the refusal is fixable, because both sides can be NAMED outright:
#   * ours     -- `nm` on the object file: `__bb_<Type>_<Method>` / `_bb_<Function>`
#   * original -- vtable_map.tsv already records the VA of every Type.Method
# No bootstrap and no inference: if both names resolve and are equal, it is the same
# method, and the displacement is pure layout.

_ORIGFN = None


def orig_functions():
    """VA in NSS5.exe -> 'Type.Method'"""
    global _ORIGFN
    if _ORIGFN is not None:
        return _ORIGFN
    _ORIGFN = {}

    # Recovered module-level Functions. They have no reflection record, so their VA is
    # known only from the header written when they are verified. Without this a body that
    # calls e.g. LogLine has an E8 whose original target cannot be named, so the operand
    # never masks and the body is reported bad when it is correct.
    md = os.path.join(ROOT, "src", "recovered_module")
    if os.path.isdir(md):
        # SORTED, DELIBERATELY. os.listdir() makes no ordering promise, so an unsorted
        # scan combined with last-write-wins turns a second claim on the same VA into a
        # coin flip that can land differently between two runs of the identical tree.
        # claimed_by tracks which file first named each VA so a second, different file
        # claiming it is a detectable COLLISION rather than a silent overwrite -- see the
        # raise below for what happens when that collision is not caught.
        claimed_by = {}
        for fn in sorted(os.listdir(md)):
            if not fn.endswith(".bmx"):
                continue
            # READ THE WHOLE FILE. A bounded read (`.read(400)`) silently truncates the
            # header of any file with a long preamble: LoadImageChecked,
            # LoadAnimImageChecked, LoadPixmapChecked and LoadSoundChecked each carry an
            # 11-line `' !!` note ABOVE their `' VA 0x...` line, so their VA never
            # registers and EVERY caller's E8 into them is unmaskable -- reported as a bad
            # body when the body is correct. Measured on TScreen.UpdateOffset: 500/500
            # bytes, one four-byte diff at the LoadImageChecked call operand, and MATCH
            # once the VA is seen. The regex is anchored on `VA 0x` either way.
            head = open(os.path.join(md, fn), encoding="utf-8", errors="replace").read()
            m = re.search(r"^'\s*VA\s+0x([0-9a-fA-F]+)", head, re.M)
            if not m:
                continue
            va = int(m.group(1), 16)
            if va in claimed_by and claimed_by[va] != fn:
                # Two files reconstructing the SAME original address under two DIFFERENT
                # names is a corpus defect, not an ordering question -- there is no correct
                # way to pick a winner here, only an arbitrary one. Left unchecked, whichever
                # file os.listdir() happens to return last silently becomes the name every
                # caller's compare() masking sees for this VA, and the loser's callers then
                # compare their call operand against the WRONG name; compare()'s (a0) name
                # check treats "both present but unequal" as a genuine difference and breaks
                # out of the masking search without ever trying the byte-level _same_callee
                # proof. Measured: exactly this turned a full 5081/5081 match into a reported
                # MISMATCH 3808/5081. Raising here, at table-build time, stops that before any
                # body is scored against a table that cannot be trusted.
                raise RuntimeError(
                    "orig_functions(): VA 0x%08x is claimed by both %s and %s in "
                    "src/recovered_module -- duplicate VA is a corpus defect, resolve it "
                    "there before re-running" % (va, claimed_by[va], fn))
            claimed_by[va] = fn
            _ORIGFN[va] = fn[:-4]

    vt = os.path.join(ROOT, "extracted", "vtable_map.tsv")
    with open(vt, encoding="utf-8", errors="replace") as f:
        next(f, None)
        for line in f:
            p = line.rstrip("\n").split("\t")
            if len(p) >= 6 and p[5].startswith("0x"):
                try:
                    _ORIGFN[int(p[5], 16)] = "%s.%s" % (p[0], p[2])
                except ValueError:
                    pass
    return _ORIGFN


def our_functions(objpath, exepath, syms=None, base=None):
    """VA in OUR exe -> 'Type.Method' (or 'Function' for module-level)"""
    syms = syms or object_symbols(objpath)
    base = base if base is not None else resolve_base(objpath, exepath, syms)
    if base is None:
        return {}
    out = {}
    for sym, off in syms.items():
        m = BB_METHOD_RX.match(sym)
        if m:
            out[base + off] = "%s.%s" % (m.group(1), m.group(2))
        elif sym.startswith("_bb_"):
            out[base + off] = sym[4:]
    return out


# ------------------------------------------------------- class tables, on BOTH sides
#
# A static cross-Type call compiles to `call [classtable + slot]`, an ABSOLUTE operand.
# The two images lay their class tables out differently, so that operand always differs
# and the relocation rule masks it -- which also masks WHICH TYPE is being called.
# Measured: `TScreen_EditContinents.ButtonQuit` reconstructed as
# `TScreen_TestMenu.SetUpScreen()` matched 20/20 just as happily as the correct
# `TScreen_EditMenu.SetUpScreen()`. The oracle could see the shape and not the callee.
#
# So resolve the operand on both sides to (Type, slot) and require those to agree. The
# index is built by reflection, the same route find_method uses: BBDebugScope records
# give Type name -> scope VA, and a class table is recognised by its debugscope field
# (+8) pointing at one of those scopes.

_CT_CACHE = {}


def _max_slots():
    """Type -> highest vtable slot, from the shared object model."""
    import collections
    top = collections.defaultdict(int)
    vt = os.path.join(ROOT, "extracted", "vtable_map.tsv")
    with open(vt, encoding="utf-8", errors="replace") as f:
        next(f, None)
        for line in f:
            p = line.rstrip("\n").split("\t")
            if len(p) >= 5:
                try:
                    top[p[0]] = max(top[p[0]], int(p[4], 16))
                except ValueError:
                    pass
    return top


def class_index(path):
    """-> sorted [(ct_va, ct_end, type)] for every Type with a class table in `path`."""
    if path in _CT_CACHE:
        return _CT_CACHE[path]
    import struct
    b, img, secs = _bytematch.load(path)
    va2off, off2va, cstr = _bytematch._helpers(b, img, secs)

    scopes = {}                                    # scope VA -> type name
    for i in range(0, len(b) - 12, 4):
        if struct.unpack_from("<I", b, i)[0] != 2:
            continue
        p = struct.unpack_from("<I", b, i + 4)[0]
        if p < img:
            continue
        nm = cstr(va2off(p))
        if nm and re.match(r"^[A-Za-z_]\w*$", nm):
            v = off2va(i)
            if v > 0:
                scopes[v] = nm

    top = _max_slots()
    out = []
    for i in range(0, len(b) - 16, 4):
        dbg = struct.unpack_from("<I", b, i)[0]
        if dbg not in scopes:
            continue
        ct = i - 8                                  # debugscope sits at classtable + 8
        if ct < 0:
            continue
        sup, _free, _d, isz = struct.unpack_from("<IIII", b, ct)
        if not (0 < isz < 20000 and (sup == 0 or sup > img)):
            continue
        t = scopes[dbg]
        va = off2va(ct)
        if va > 0:
            out.append((va, va + top.get(t, 0x30) + 4, t))
    out.sort()
    _CT_CACHE[path] = out
    return out


def resolve_slot(path, addr):
    """Absolute address -> 'Type+0xslot' if it lands inside a class table, else None."""
    import bisect
    idx = class_index(path)
    if not idx:
        return None
    i = bisect.bisect_right([x[0] for x in idx], addr) - 1
    if i < 0:
        return None
    va, end, t = idx[i]
    if va <= addr < end:
        return "%s+0x%x" % (t, addr - va)
    return None


def audit_table():
    """Integrity checks on the bootstrapped runtime-helper table.

    Masking requires our name to equal the original's name, so a WRONG entry can hide a
    genuine error. Two failure shapes are worth surfacing:

      * one symbol claimed by two different original addresses. Masking keys on the name,
        so if the original calls A and we call B and both are labelled `_bbStringFind`,
        a real difference is masked. Sometimes legitimate (thunks, overloads), never
        something to accept silently.
      * single-witness entries -- one observation, no corroboration.
    """
    t = load_table()
    by_sym = {}
    for va, (sym, n) in t.items():
        by_sym.setdefault(sym, []).append((va, n))
    dupes = {s: v for s, v in by_sym.items() if len(v) > 1}
    singles = sorted(va for va, (_s, n) in t.items() if n < 2)
    return t, dupes, singles


def audit_brl():
    """The same name-collision check, applied to the BRL/PUB name table.

    audit_table() covers only runtime_helpers.tsv, but the BRL table is masked against by
    exactly the same rule -- our symbol name must appear in the original's alias set -- so
    it can fail in exactly the same way, and it is 60x larger. One symbol sitting at two
    addresses means a call to the one can mask against a call to the other.

    Measured: with reflection (extracted/brl_type_methods.tsv) overriding the archive
    byte-match, 110 symbols are claimed by more than one address; without those rows it is
    180. The reflection rows alone are a bijection -- 852 addresses, 852 distinct symbols,
    zero collisions -- which is what a table built from the exe's own Type+slot records
    should look like.
    """
    t = brl_table()
    by_sym = {}
    for va, s in t.items():
        for n in s.split("|"):
            by_sym.setdefault(n, []).append(va)
    dupes = {s: sorted(v) for s, v in by_sym.items() if len(v) > 1}
    return t, by_sym, dupes


def main():
    bt, bsyms, bdupes = audit_brl()
    print("BRL/PUB name table  : %d addresses, %d distinct symbols" % (len(bt), len(bsyms)))
    if bdupes:
        print("!! %d symbols claimed by more than one address. Masking keys on the NAME,"
              % len(bdupes))
        print("!! so each of these could mask a call to the WRONG BRL function.")
        print("!! Reflection (extracted/brl_type_methods.tsv) resolves these where the")
        print("!! address belongs to a reflected Type method; the residue is module-level")
        print("!! Functions, which reflection cannot reach.")
        for s in sorted(bdupes)[:12]:
            print("   %-52s %s" % (s, ", ".join("0x%08x" % v for v in bdupes[s])))
        if len(bdupes) > 12:
            print("   ... %d more" % (len(bdupes) - 12))
    print()

    t, dupes, singles = audit_table()
    print("runtime helper table: %d entries" % len(t))
    if dupes:
        print()
        print("!! one symbol at multiple addresses -- masking keys on the NAME, so these")
        print("!! could mask a real difference. Verify before trusting:")
        for sym, vs in sorted(dupes.items()):
            print("   %-28s %s" % (sym, ", ".join("0x%08x(w=%d)" % (v, n) for v, n in vs)))
    if singles:
        print()
        print("single-witness entries (weakest evidence): %s"
              % ", ".join("0x%08x" % v for v in singles))
    print()
    single = [va for va, (_s, n) in t.items() if n < 2]
    print("  single-witness (weakest evidence): %d" % len(single))
    for va in sorted(t):
        sym, n = t[va]
        print("  0x%08x  %-34s witnesses=%d" % (va, sym, n))


if __name__ == "__main__":
    main()
