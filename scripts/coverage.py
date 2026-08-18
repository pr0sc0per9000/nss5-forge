"""
The one canonical coverage number. Run this; quote this; do not hand-roll another.

WHY THIS EXISTS. The same corpus supports at least three different denominators, each
honestly computed and each giving a different, confident-sounding percentage: 1,850 for a
narrowed method list (1,280 of which reads as 69.19%), 2,749 for every row of the raw
vtable_map, and 4,318 for "everything in Ghidra's inventory that is not in
brl_functions.tsv". A percentage whose denominator moves is not a measurement -- it is a
mood, and a rising one can hide a shrinking numerator. So: one script, one definition,
stated out loud in the output.

THE DEFINITION. The target of this project is the GAME's code, meaning code Simon Read
wrote, not code the BlitzMax distribution supplied. A function counts toward the universe
when it is:

  (a) a method/function in a class table for a Type declared BY THE GAME, or
  (b) a module-level Function of the game's own main module,

and it does NOT count when it is:

  (c) a BRL/PUB module function (brl.*, pub.*), identified by extracted/brl_functions.tsv
      or by belonging to a Type that BlitzMax ships (TList, TStream, TMap, TImage, ...), or
  (d) a C-runtime helper (bbStringToDouble, bbObjectDowncast, ...), which is compiled from
      Simon Read's GCC and can never byte-match ours anyway.

(c) and (d) are excluded because reproducing them is not reconstruction -- our toolchain
emits them from the same BlitzMax sources whether or not we ever look at them. Counting
them would inflate the number with work nobody has to do.

BYTES ARE THE HONEST METRIC, functions are the encouraging one. 1,382 small functions is
32% of the count but 15% of the bytes, because the large functions are the hard ones and
they are still outstanding. Both are printed; when only one is quoted, quote bytes.
"""

import csv
import glob
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
EX = os.path.join(ROOT, "extracted")

HEADER_VA = re.compile(r"VA\s+0x([0-9a-fA-F]+)")
# A file counts as recovered only if its header CLAIMS byte-equality. A body on disk with
# no such claim is work-in-progress, and counting it would be counting a hope.
#
# The corpus says this four ways, because it was written by many independent passes:
# "byte-identical vs NSS5.exe" (1,278 files), "MATCH n/n" (125), "verified" (143), and
# "byte-exact". They mean the same thing and all four must be accepted: recognising only
# \bMATCH\b reports 3.30% for a corpus that is really past 60%, which is the same class of
# error in the opposite direction. Any claim vocabulary this script does not know about
# reads as unverified, so it under-reports rather than over-reports; that is the safe
# direction, but a new spelling still has to be added to this pattern when one appears.
HEADER_MATCH = re.compile(r"\bMATCH\b|byte-identical|byte-exact|\bverified\b", re.I)
# A header can also carry an explicit negative, and a file saying MISMATCH must not count.
# UNVERIFIED needs \b too: without it the pattern fires on the substring inside a path
# reference like "src/recovered_unverified/Foo.bmx", which headers legitimately cite, and
# silently drops a genuine MATCH from the count. TProfile.FixturePlayed.bmx is the clearest
# case: its header claims byte-identical 2669/2669 and the oracle confirms MATCH, so a bare
# substring match would disqualify a verified body.
HEADER_BAD = re.compile(r"\bMISMATCH\b|\bUNVERIFIED\b|\bNOT VERIFIED\b", re.I)

# ...BUT ONLY IN THE STATUS BLOCK. Scanning the whole header for a negative under-reports
# real work, because good headers document NEGATIVE CONTROLS -- the alternative source
# forms that were tried and rejected:
#
#     ' TScreen_Shop.SetUpScreen
#     ' VA 0x005418DE   3072 bytes   mode=reloc   byte-identical vs NSS5.exe (3072/3072)
#     ...
#     '    Control: rewriting the panel one as If/ElseIf gives 3075 bytes, MISMATCH at 507.
#
# That last line is exactly the discipline this project asks for, and a whole-header scan
# revokes the verification of any file that documents one. Two such files verify 3072/3072
# and 3183/3183 under NSS5_NO_LEARN=1. So the STATUS BLOCK -- the first few comment lines, which
# by corpus convention carry the name, the VA/byte-count claim and the KIND/SIG -- decides,
# and everything after it is discussion.
STATUS_LINES = 6

# Types BlitzMax ships. A class table for one of these is not the game's to reconstruct.
# Kept in sync with harness.MODULE_TYPES by the assertion at the bottom.
MODULE_TYPE_PREFIXES = (
    "TList", "TLink", "TListEnum", "TMap", "TNode", "TMapEnum", "TKeyValue",
    "TStream", "TStreamWrapper", "TTextStream", "TStreamFactory", "TCStream",
    "TImage", "TImageFont", "TPixmap", "TSound", "TChannel", "TBank", "TBankStream",
    "TAudioSample", "TMax2D", "TGraphics", "TField", "TMethod", "TFunction",
    "TTypeId", "TConstant", "TGlobal", "TVar", "TD3D", "TGL", "TDX", "TDirect",
)


def _norm(va):
    return "0x%08x" % int(str(va).replace("0x", ""), 16)


def load_inventory():
    inv = {}
    with open(os.path.join(EX, "ghidra", "function_inventory.tsv"), encoding="utf-8") as f:
        for r in csv.DictReader(f, delimiter="\t"):
            inv[_norm(r["addr"])] = int(r["size"])
    return inv


def load_brl():
    """VAs positively identified as BRL/PUB module code, plus C-runtime helpers."""
    brl = set()
    for name in ("brl_functions.tsv", "brl_functions_inferred.tsv", "runtime_helpers.tsv"):
        p = os.path.join(EX, name)
        if not os.path.exists(p):
            continue
        with open(p, encoding="utf-8") as f:
            for r in csv.reader(f, delimiter="\t"):
                if r and r[0].strip().startswith("0x"):
                    brl.add(_norm(r[0]))
    return brl


def is_module_type(tname):
    for pre in MODULE_TYPE_PREFIXES:
        if tname == pre or tname.startswith(pre + "_"):
            return True
    # BLIde's generated background Types are the game's, despite the odd names.
    return False


def load_universe(inv, brl):
    """{va: label} for every function this project is actually on the hook for."""
    uni = {}
    with open(os.path.join(EX, "vtable_map.tsv"), encoding="utf-8") as f:
        for r in csv.reader(f, delimiter="\t"):
            if len(r) > 5 and str(r[5]).startswith("0x"):
                va = _norm(r[5])
                if va in brl or is_module_type(r[0]):
                    continue
                if va not in inv:
                    continue
                uni[va] = "%s.%s" % (r[0], r[2])
    # Module-level Functions of the game's own module: reached only from the module body,
    # so they never appear in any class table.
    modmap = os.path.join(EX, "module_functions.tsv")
    if os.path.exists(modmap):
        with open(modmap, encoding="utf-8") as f:
            for r in csv.reader(f, delimiter="\t"):
                if r and str(r[0]).startswith("0x"):
                    va = _norm(r[0])
                    if va in inv and va not in brl:
                        uni.setdefault(va, r[1] if len(r) > 1 else "module")
    return uni


def load_recovered():
    """{va: (path, matched)} for every body on disk, MATCH or not."""
    rec = {}
    # src/recovered_thirdparty/<module>/ holds the zip and bitmap-font modules the game
    # links but did not author. They are deliberately NOT in src/recovered/ -- that is the
    # main module, and folding them in would corrupt the Type declaration order.
    # They still count: their code is in NSS5.exe's `code` section, so it is part of the
    # target. Scanning only the two flat directories under-reports them as zero.
    for p in glob.glob(os.path.join(ROOT, "src", "recovered", "*.bmx")) + \
             glob.glob(os.path.join(ROOT, "src", "recovered_module", "*.bmx")) + \
             glob.glob(os.path.join(ROOT, "src", "recovered_thirdparty", "*", "*.bmx")) + \
             glob.glob(os.path.join(ROOT, "src", "recovered_thirdparty", "*.bmx")):
        with open(p, encoding="utf-8", errors="replace") as f:
            text = f.read()
        # Read the claim from the COMMENT HEADER only. Scanning the whole file would let
        # the word "verified" inside a body comment promote an unverified body.
        head = "\n".join(l for l in text.split("\n") if l.startswith("'"))
        m = HEADER_VA.search(head)
        if not m:
            continue
        status = "\n".join(head.split("\n")[:STATUS_LINES])
        ok = bool(HEADER_MATCH.search(head)) and not HEADER_BAD.search(status)
        rec[_norm(m.group(1))] = (p, ok)
    return rec


def main():
    inv = load_inventory()
    brl = load_brl()
    uni = load_universe(inv, brl)
    rec = load_recovered()

    matched = {va for va, (_p, ok) in rec.items() if ok}
    hit = set(uni) & matched
    onpaper = set(uni) & set(rec)

    ub = sum(inv[va] for va in uni)
    rb = sum(inv[va] for va in hit)

    print("NSS5 RECONSTRUCTION COVERAGE")
    print("universe: game Type methods + game module Functions;")
    print("          BRL/PUB module code and C-runtime helpers excluded (see docstring).")
    print()
    print("  functions MATCHed : %5d of %5d  = %6.2f%%" % (len(hit), len(uni), 100.0 * len(hit) / len(uni)))
    print("  bytes     MATCHed : %5d of %5d  = %6.2f%%   <-- quote this one" % (rb, ub, 100.0 * rb / ub))

    # SPLIT BY WHOSE CODE IT IS. The universe above is "not BRL/PUB", which is not the same
    # as "the game's". extracted/type_declaration_order.tsv holds the 135 Types the game's
    # main module actually declares (recovered from the module body's registration
    # sequence). Everything else in the universe belongs to third-party modules the game
    # LINKS but did not author -- the zip module (ZipFile, tm_zip, SZIPFileDataDescriptor)
    # and the bitmap-font/text-renderer module (TBitmapFont, TPrivateFontKerning,
    # TRectangle, TDrawingPoint).
    #
    # This matters twice over. It keeps the headline number honest, and it stops anyone
    # bulk-banking the ~270 empty 14-byte Delete stubs those Types carry: they are cheap
    # function-count wins that would land in src/recovered/ and therefore in the MAIN
    # module, making the 341-vs-135 Type-set defect worse.
    decl = set()
    dpath = os.path.join(EX, "type_declaration_order.tsv")
    if os.path.exists(dpath):
        with open(dpath, encoding="utf-8") as f:
            for r in csv.DictReader(f, delimiter="\t"):
                decl.add(r["type"])
    if decl:
        def own(va):
            lab = uni[va]
            return "." in lab and lab.split(".", 1)[0] in decl
        g_u = [v for v in uni if own(v)]
        o_u = [v for v in uni if not own(v)]
        for label, group in (("game main module", g_u), ("third-party modules", o_u)):
            tb = sum(inv[v] for v in group)
            hb = sum(inv[v] for v in group if v in hit)
            nh = sum(1 for v in group if v in hit)
            if not tb:
                continue
            print("     %-20s %5d/%5d fns  %6.2f%%   %6d/%6d bytes  %6.2f%%"
                  % (label, nh, len(group), 100.0 * nh / len(group),
                     hb, tb, 100.0 * hb / tb))
    if len(onpaper) != len(hit):
        print("  on disk without a byte-equality claim: %d (NOT counted)" % (len(onpaper) - len(hit)))
        for va in sorted(onpaper - hit):
            print("     %s  %s" % (va, os.path.basename(rec[va][0])))
    print()

    out = sorted(((inv[va], va, uni[va]) for va in uni if va not in hit), reverse=True)
    print("  outstanding: %d functions, %d bytes" % (len(out), sum(s for s, _v, _l in out)))
    print("  largest 15:")
    for s, va, lab in out[:15]:
        print("     %s %7d  %s" % (va, s, lab))

    # Files on disk whose VA is NOT in the universe -- either genuinely out of scope
    # (BRL bodies somebody reconstructed anyway) or a sign the universe filter is wrong.
    stray = sorted(set(rec) - set(uni))
    if stray:
        print()
        print("  %d recovered files sit outside the universe (BRL bodies, or filter too tight):" % len(stray))
        for va in stray[:8]:
            print("     %s  %s" % (va, os.path.basename(rec[va][0])))
    return 0


if __name__ == "__main__":
    sys.exit(main())
