"""Ground-truth Global address<->name pairing, read out of NSS5.exe's machine code.

    python scripts/addr_oracle.py            # validate the oracle and report coverage
    python scripts/addr_oracle.py --dump     # write extracted/addr_oracle.json

WHY THIS EXISTS
===============
Name unification had been running on comment archaeology -- a body's header says
`0x00C679C4 g_stats_table` and build_alias_map.py believes it. That oracle is weak three
ways: it misses annotation spellings (the 364 `0xADDR -> name` rows alone hid the
TScreen_Stats split, where CreateScreen builds the table as g_stats_tblStats and
UpdateStatTable fills it as g_stats_table, so all 23 derefs hit Null); it mis-pairs
multi-pair lines; and fundamentally nobody ever verified it. The byte-oracle certifies a
body's CODE. It says nothing about whether the human who wrote the header put the right
address beside the right name.

The binary knows. This module asks it.

THE METHOD
==========
For a body we hold, the original function's machine code is in NSS5.exe at a known VA
with a known length. x86 encodes a module Global access as an absolute 32-bit
displacement, so scanning the function's bytes for little-endian dwords inside the
module-global band yields every Global the function touches, IN THE ORDER THE CODE
TOUCHES THEM. Our bodies are byte-identical to the originals, so that is also the order
OUR body first mentions each Global. Zip the two lists and the pairing is mechanical.

WHY NOT THE DECOMPILED C IN extracted/decomp/
=============================================
Because Ghidra's decompiler reorders statements and this pairing is order-sensitive.
Measured on TGadget.UpdateToolTip -- our body's first-use order is

    g_options_tooltips g_screen_usemouse g_screen_scrollx g_screen_scrolly
    g_screen_w g_screen_h g_screen_mousex g_screen_mousey g_activegadget

the decompiled C's first-appearance order is

    c5d258 c6173c c61cf8 c6efe8 c61740 c61744 c6efe4 c61724 c61728

which puts g_activegadget third when it is ninth, and would bind it to 0x00C6EFE8 -- the
screen-HEIGHT slot. The raw bytes of the same function give

    +32 c5d258   +46 c6173c   +121 c61740  +149 c61744  +179 c6efe4
    +253 c6efe8  +334 c61724  +352 c61728  +384 c61cf8

which is nine for nine against source order, and puts g_activegadget at 0x00C61CF8 --
agreeing with the pair a human had already verified by hand. Decompiled C scored 83%
against known pairs; this scores what validate() prints below. The decompilation is still
useful for TYPING a slot (`PTR_DAT_` is a pointer, `DAT_x >> 0x1f` is a signed-divide and
proves Int), and unify_names.py uses it for exactly that -- but never for order.

LIMITS, HANDLED BY REFUSING RATHER THAN GUESSING
================================================
  * A dword inside some unrelated instruction can land in the band by coincidence. It
    would insert a phantom address and shift every later pairing, so a body is only
    trusted when its address count EQUALS its Global count. Mismatched bodies still
    contribute set-level evidence to unify_names.py, which does not depend on order.
  * A Global read through a helper, or one the optimiser folded, appears in one list and
    not the other. Same treatment: the count check catches it.
  * Function length comes from Ghidra's inventory, which bytematch.py already documents
    as the authoritative source (scanning for a 0xC3 byte truncates any function that
    uses EBX as a loop counter, and once blessed a 199-byte function on 62 bytes).
"""
import os
import re
import sys
import json
import struct
import collections

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ORIG = os.path.join(ROOT, "binary", "NSS5.exe")
INVENTORY = os.path.join(ROOT, "extracted", "ghidra", "function_inventory.tsv")
DECOMP = os.path.join(ROOT, "extracted", "decomp")
TREES = [os.path.join(ROOT, "src", "recovered"),
         os.path.join(ROOT, "src", "recovered_module"),
         os.path.join(ROOT, "src", "recovered_unverified")]

# The module-global band. Every game Global that extracted/globals_final.tsv derives from
# a construction site lands inside it; above is BRL runtime state, below is .rdata.
BAND_LO, BAND_HI = 0x00C59000, 0x00C71000

# Leading whitespace is REQUIRED to be optional. Many bodies indent their pragma block to
# the nesting level of the code, and an unanchored-to-column-0 regex silently skipped every
# one of them: 287 Globals -- including g_pitch_arr05, g_cmb1 and g_stable_table, between
# them 40+ deref sites -- never entered the address map at all, and were mis-reported as
# "declared nowhere in the corpus" rather than as unresolved.
# The type may be MODULE-QUALIFIED -- `brl.audio.TChannel` is how several bodies spell the
# type that others write plainly as `TChannel`. Capturing only up to the first dot yields
# the type "brl", which is not a type at all, and made five channel groups look like
# "INCOMPATIBLE TYPES: TChannel vs brl" when every member was in fact a TChannel.
PRAGMA = re.compile(
    r"^\s*'!\s*Global\s+(\w+)\s*:\s*([A-Za-z_][\w.]*(?:\s*\[[,\s]*\])?)",
    re.M | re.I)


# ------------------------------------------------------------------------- PE access

def pe():
    b = open(ORIG, "rb").read()
    e = struct.unpack_from("<I", b, 0x3C)[0]
    img = struct.unpack_from("<I", b, e + 24 + 28)[0]
    ns = struct.unpack_from("<H", b, e + 6)[0]
    osz = struct.unpack_from("<H", b, e + 20)[0]
    secs = []
    for i in range(ns):
        o = e + 24 + osz + i * 40
        _v, rva, rs, ro = struct.unpack_from("<IIII", b, o + 8)
        secs.append((rva, rs, ro))

    def va2off(v):
        r = v - img
        for rva, sz, ro in secs:
            if rva <= r < rva + sz:
                return r - rva + ro
        return -1
    return b, va2off


def inventory():
    """VA -> function length, from Ghidra's own inventory (authoritative)."""
    out = {}
    if not os.path.exists(INVENTORY):
        return out
    for line in open(INVENTORY, encoding="utf-8", errors="replace").read().splitlines()[1:]:
        p = line.split("\t")
        if len(p) > 3:
            try:
                out[int(p[0], 16)] = int(p[3])
            except ValueError:
                pass
    return out


def machine_addrs(buf, off, length):
    """Distinct module-global addresses in the order the function's code touches them."""
    seen, order = set(), []
    if off < 0 or length <= 4:
        return order
    for i in range(off, min(off + length - 3, len(buf) - 3)):
        d = struct.unpack_from("<I", buf, i)[0]
        if BAND_LO <= d < BAND_HI and d not in seen:
            seen.add(d)
            order.append(d)
    return order


def statement_groups(path):
    """Ordered address groups that belong to ONE statement, in SOURCE order.

    Machine order is source order BETWEEN statements but not WITHIN one, because two
    separate x86 evaluation rules both run backwards relative to how the source reads:

      CALL ARGUMENTS. BlitzMax emits cdecl calls, which push right to left, so the last
        argument's Global is touched first. `PlaySound(g_ball_postsound,
        g_ball_postchannel)` in TBall.HitPost compiles to bytes referencing 0x00C5A510
        before 0x00C5A51C. Read literally, that pairs the SOUND name with the CHANNEL slot
        -- which is what produced this project's entire TSound-vs-TChannel family of
        "incompatible type" groups: nine of them, none actually a type error.

      ASSIGNMENT. The right-hand side is evaluated before the store target's address is
        taken. `g_ec_club.name = g_ec_ib_name.GetText()` touches g_ec_ib_name first, so
        naive order swaps the TClub and TInputBox slots -- reading g_ec_club as
        0x00C653D8 when it is 0x00C653C4, corroborated by TScreen_EditClubs.SetUpScreen,
        where three bodies agree unanimously.

    ONLY THE CALL CASE IS CORRECTED HERE, and that is a measured decision rather than a
    concession. Ghidra states both correctly -- it writes a call as FUN(arg1, arg2) and an
    assignment as target = rhs, both in source order -- so generalising to "reorder every
    address on a decompiled line" looks obviously right. It is worse:

        correction scope            CERTAIN   verified pairs covered   accuracy
        call arguments only            411              92               100%
        whole decompiled line          362              79               100%

    A decompiled line is not a source statement. Ghidra nests subexpressions, hoists
    temporaries and folds several source statements onto one line, so line-wide reordering
    permutes pairs that machine order already had right. The parenthesised argument list is
    the one construct whose ordering the C reliably reports, so that is the only one taken
    from it.

    Assignment reversals are real but rarer, and they are handled downstream instead: they
    surface as an unresolved or type-conflicted group, get adjudicated against the machine
    code one at a time, and land in global_address_adjudicated.tsv as pins. g_ec_club is
    one such -- pinned to 0x00C653C4 on the strength of three bodies agreeing.
    """
    groups = []
    for line in open(path, encoding="utf-8", errors="replace"):
        s = line.strip()
        if s.startswith("//") or s.startswith("/*") or not s:
            continue
        for m in re.finditer(r"\w+\s*\(([^();]*)\)", line):
            args = []
            for a in re.finditer(r"\b(?:_?PTR_|_?DAT_)*(00c[0-9a-f]{5})\b", m.group(1)):
                v = int(a.group(1), 16)
                if BAND_LO <= v < BAND_HI and v not in args:
                    args.append(v)
            if len(args) > 1:
                groups.append(args)
    return groups


def apply_source_order(order, groups):
    """Permute `order` so each statement's Globals follow source order."""
    pos = {a: i for i, a in enumerate(order)}
    out = list(order)
    for g in groups:
        idx = sorted(pos[a] for a in g if a in pos)
        if len(idx) < 2:
            continue
        for slot, a in zip(idx, [x for x in g if x in pos]):
            out[slot] = a
        for i, a in zip(idx, [out[i] for i in idx]):
            pos[a] = i
    return out


# ---------------------------------------------------------------------- source side

def decomp_index():
    out = {}
    if not os.path.isdir(DECOMP):
        return out
    for fn in os.listdir(DECOMP):
        m = re.match(r"(.+)@([0-9a-fA-F]{6,8})\.c$", fn)
        if m:
            out[m.group(1)] = (int(m.group(2), 16), os.path.join(DECOMP, fn))
    return out


def body_globals(path):
    """({name: type}, [names in first-use order]).

    First-use order is taken from the CODE, not the pragma block: the compiler emits a
    Global reference when execution reaches it, whereas the pragma block is documentation
    that assemble.py hoists into declarations and whose order carries no meaning.
    """
    text = open(path, encoding="utf-8", errors="replace").read()
    types = {}
    for m in PRAGMA.finditer(text):
        types[m.group(1).lower()] = re.sub(r"\s+", "", m.group(2))
    if not types:
        return {}, []
    use, seen = [], set()
    for line in text.split("\n"):
        if line.lstrip().startswith("'"):
            continue
        for m in re.finditer(r"\b(g_\w+)\b", line):
            n = m.group(1).lower()
            if n in types and n not in seen:
                seen.add(n)
                use.append(n)
    return types, use


def collect():
    """Every body pairable with its original, with both ordered lists."""
    buf, va2off = pe()
    inv = inventory()
    idx = decomp_index()
    out = []
    for tree in TREES:
        if not os.path.isdir(tree):
            continue
        for fn in sorted(os.listdir(tree)):
            if not fn.endswith(".bmx"):
                continue
            base = fn[:-4]
            if base not in idx:
                continue
            types, use = body_globals(os.path.join(tree, fn))
            if not use:
                continue
            va, dpath = idx[base]
            addrs = apply_source_order(machine_addrs(buf, va2off(va), inv.get(va, 0)),
                                       statement_groups(dpath))
            out.append({"file": base, "tree": os.path.basename(tree), "va": va,
                        "use": use, "types": types, "addrs": addrs,
                        "exact": len(use) == len(addrs), "decomp": dpath})
    return out


# --------------------------------------------------------------------- validation

def seeds():
    """name -> address for every pairing already established outside the solver.

    Two sources, both authoritative enough to anchor an alignment and to forbid any other
    address for that name:

      * global_alias_overrides.tsv -- hand-verified, each row citing the header it came
        from. These also serve as the scoring set in validate() and main().
      * global_address_adjudicated.tsv -- decided by reading the original function's
        machine code, then checked by validate_verdicts.py against co-occurrence, type
        compatibility and address membership. Anything that failed those checks was
        dropped before the file was written.
    """
    out = {}
    ov = os.path.join(ROOT, "extracted", "global_alias_overrides.tsv")
    if os.path.exists(ov):
        for line in open(ov, encoding="utf-8", errors="replace"):
            if line.startswith("#") or line.startswith("address"):
                continue
            p = line.rstrip("\n").split("\t")
            if len(p) >= 3 and p[0].strip().startswith("0x"):
                try:
                    a = int(p[0].strip(), 16)
                except ValueError:
                    continue
                if BAND_LO <= a < BAND_HI:
                    out[p[1].strip().lower()] = a
                    out[p[2].strip().lower()] = a
    adj = os.path.join(ROOT, "extracted", "global_address_adjudicated.tsv")
    if os.path.exists(adj):
        for line in open(adj, encoding="utf-8", errors="replace"):
            if line.startswith("#") or line.startswith("name"):
                continue
            p = line.rstrip("\n").split("\t")
            if len(p) >= 2 and p[1].strip().startswith("0x"):
                try:
                    a = int(p[1].strip(), 16)
                except ValueError:
                    continue
                if BAND_LO <= a < BAND_HI:
                    out[p[0].strip().lower()] = a
    return out


def pairs_from(bodies):
    """name -> {addr: votes}, from bodies whose two lists are the same length."""
    votes = collections.defaultdict(collections.Counter)
    for b in bodies:
        if not b["exact"]:
            continue
        for n, a in zip(b["use"], b["addrs"]):
            votes[n][a] += 1
    return votes


def main():
    bodies = collect()
    exact = [b for b in bodies if b["exact"]]
    print("ADDRESS ORACLE -- machine-code order, read from NSS5.exe")
    print("  bodies pairable with an original : %d" % len(bodies))
    print("  counts agree (ordered bijection) : %d" % len(exact))
    print("  counts differ (set evidence)     : %d" % (len(bodies) - len(exact)))
    print()

    votes = pairs_from(bodies)
    sd = seeds()
    ok = bad = 0
    wrong = []
    for n, a in sd.items():
        v = votes.get(n)
        if not v:
            continue
        got = v.most_common(1)[0][0]
        if got == a:
            ok += 1
        else:
            bad += 1
            wrong.append((n, got, a, dict(v)))
    tot = ok + bad
    print("VALIDATION against %d hand-verified pairs (%d covered)" % (len(sd), tot))
    print("  agree %d   disagree %d   accuracy %.1f%%"
          % (ok, bad, (100.0 * ok / tot) if tot else 0.0))
    for n, got, want, v in wrong[:15]:
        print("    %-30s oracle=%08x human=%08x  votes=%s"
              % (n, got, want, {"%08x" % k: c for k, c in v.items()}))
    print()

    conflict = {n: v for n, v in votes.items() if len(v) > 1}
    print("  names with a unanimous address   : %d" % (len(votes) - len(conflict)))
    print("  names with conflicting votes     : %d" % len(conflict))

    if "--dump" in sys.argv:
        out = os.path.join(ROOT, "extracted", "addr_oracle.json")
        with open(out, "w", encoding="utf-8") as f:
            json.dump([{k: v for k, v in b.items() if k != "decomp"} for b in bodies],
                      f, indent=1)
        print("\nwrote %s (%d bodies)" % (out, len(bodies)))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
