"""The one canonical coverage number. Run this; quote this; do not hand-roll another.

WHY THIS EXISTS. The same corpus supports at least three different denominators, each
honestly computed and each giving a different, confident-sounding percentage: 1,850 for a
narrowed method list (1,280 of which reads as 69.19%), 2,749 for every row of the raw
vtable_map, and 4,318 for "everything in Ghidra's inventory that is not in
brl_functions.tsv". A percentage whose denominator moves is not a measurement -- it is a
mood, and a rising one can hide a shrinking numerator. So: one script, one definition,
stated out loud in the output.

THE DEFINITION. The target of this project is the GAME's code, meaning code that came out
of the BlitzMax toolchain for this program, not code the BlitzMax distribution supplied.
A function counts toward the universe when it is:

  (a) a method/function in a class table for a Type declared BY THE GAME, or
  (b) a module-level Function of the game's own main module, or of one of the two
      modules the game bundles (zipengine, fontmachine),

and it does NOT count when it is:

  (c) a BRL/PUB module function (brl.*, pub.*), identified by extracted/brl_functions.tsv
      or by belonging to a Type that BlitzMax ships (TList, TStream, TMap, TImage, ...), or
  (d) a C-runtime helper (bbStringToDouble, bbObjectDowncast, ...), which is compiled from
      Simon Read's GCC and can never byte-match ours anyway, or
  (e) anything in the `.text` section, which is the MinGW C runtime and the C libraries
      linked beside it (1,634 functions, 453,000 bytes). The BlitzMax toolchain's output
      is the `code` section and nothing else.

(c), (d) and (e) are excluded because reproducing them is not reconstruction -- our
toolchain emits them from the same sources whether or not we ever look at them. Counting
them would inflate the number with work nobody has to do.

BYTES ARE THE HONEST METRIC, functions are the encouraging one. Small functions are a
third of the count and a sixth of the bytes, because the large functions are the hard ones.
Both are printed; when only one is quoted, quote bytes.

HOW (c) IS DECIDED, AND WHY IT CHANGED
======================================
It used to be decided by MODULE_TYPE_PREFIXES, a 24-entry tuple of name stems. That set
was both too small and unevidenced. Too small: it named 22 Types that are actually in the
reflection data, and left 148 others in the universe -- every Win32 struct BlitzMax
reflects (MSG, WNDCLASS, PAINTSTRUCT, DEVMODE, LOGFONTW), every DirectX struct
(D3DADAPTER_IDENTIFIER9 at 2,732 bytes was the second-largest "outstanding" item in the
whole report), brl.socket, brl.ramstream, brl.openalaudio, brl.freeaudioaudio,
brl.reflection, brl.max2d's driver types and BlitzMax's own exception hierarchy. 24,022
bytes of BlitzMax's own code sat in this project's denominator. Unevidenced: four of its
entries ("TD3D", "TGL", "TDX", "TDirect") matched nothing at all, because the test is
`tname == pre or tname.startswith(pre + "_")` and no reflected type is spelled `TD3D_x`.

MODULE_TYPES_SHIPPED replaces it, and every row carries its evidence: the BlitzMax module
whose source declares that Type, found by scanning `Type <name>` across
tools/blitzmax-legacy-src/mod. Re-derivable, per type, by anyone with the toolchain.

BE CONSERVATIVE HERE. Removing a Type from the universe RAISES the percentage, so a Type
goes on this list only when a BlitzMax module source is shown to declare it. Types this
project could not attribute STAY IN, and the report names them, because under-reporting is
recoverable and over-reporting is not. TVolume, TWinVolume, TWinVolumeDriver and TVolSpace
are the live example: their code sits at 0x00597fa5..0x00598a99, in the middle of BlitzMax's
own address range, so they are almost certainly a BlitzMax-ecosystem module -- and no
source in tools/blitzmax-legacy-src declares them, so they are still counted against this
project. 2,157 bytes the project probably does not owe, left owed.

A Type the GAME declares is never treated as a module type even if the name collides.
TGadget is both a game Type and a maxgui Type; type_declaration_order.tsv wins.
"""

import csv
import glob
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
EX = os.path.join(ROOT, "extracted")

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import claim as K                                              # noqa: E402

HEADER_VA = re.compile(r"VA\s+0x([0-9a-fA-F]+)")

# Which body files count as MATCHED is NOT decided here. scripts/claim.py is the single
# reader, shared with progress.py, and its docstring carries the rule and the evidence for
# it. Two readers for one fact is two facts: before they were merged, progress.py and
# coverage.py disagreed about 13 bodies and neither was right about all of them.

# Types BlitzMax ships, each with the module whose source declares it. A class table for
# one of these is not the game's to reconstruct. Derived by scanning `Type <name>` over
# tools/blitzmax-legacy-src/mod and intersecting with the Types that appear in
# extracted/vtable_map.tsv; game-declared Types are excluded from the intersection, so a
# name collision cannot remove a game Type from the universe.
#
# The assertion at the bottom of this file keeps it a superset of harness.MODULE_TYPES.
MODULE_TYPES_SHIPPED = {t: m for m, ts in {
    "brl.audio": ("TAudioDriver", "TChannel", "TSound"),
    "brl.audiosample": ("TAudioSample", "TAudioSampleLoader"),
    "brl.bank": ("TBank",),
    "brl.bankstream": ("TBankStream", "TBankStreamFactory"),
    "brl.blitz": ("TArrayBoundsException", "TBlitzException", "TNullFunctionException",
                  "TNullMethodException", "TNullObjectException", "TOutOfDataException",
                  "TRuntimeException"),
    "brl.d3d9max2d": ("TD3D9Max2DDriver",),
    "brl.dxgraphics": ("TD3D9Graphics", "TD3D9GraphicsDriver"),
    "brl.endianstream": ("TXEndianStream", "TXEndianStreamFactory"),
    "brl.event": ("TEvent",),
    "brl.font": ("TFont", "TFontLoader", "TGlyph"),
    "brl.freeaudioaudio": ("TFreeAudioAudioDriver", "TFreeAudioChannel", "TFreeAudioSound"),
    "brl.freetypefont": ("TFreeTypeFont", "TFreeTypeFontLoader", "TFreeTypeGlyph"),
    "brl.glgraphics": ("TGLGraphics", "TGLGraphicsDriver"),
    "brl.glmax2d": ("TGLImageFrame", "TGLMax2DDriver"),
    "brl.graphics": ("TGraphics", "TGraphicsDriver", "TGraphicsMode"),
    "brl.hook": ("THook",),
    "brl.httpstream": ("THTTPStreamFactory",),
    "brl.jpgloader": ("TPixmapLoaderJPG",),
    "brl.linkedlist": ("TLink", "TList", "TListEnum"),
    "brl.map": ("TKeyEnumerator", "TKeyValue", "TMap", "TMapEnumerator", "TNode",
                "TNodeEnumerator", "TValueEnumerator"),
    "brl.max2d": ("TImage", "TImageFont", "TImageFrame", "TImageGlyph", "TMax2DDriver",
                  "TMax2DGraphics", "TQuad", "rpoly"),
    "brl.oggloader": ("TAudioSampleLoaderOGG",),
    "brl.openalaudio": ("TOpenALAudioDriver", "TOpenALChannel", "TOpenALSound",
                        "TOpenALSource"),
    "brl.pixmap": ("TPixmap", "TPixmapLoader"),
    "brl.pngloader": ("TPixmapLoaderPNG",),
    "brl.ramstream": ("TRamStream", "TRamStreamFactory"),
    "brl.reflection": ("TClass", "TField", "TMember", "TMethod", "TTypeId"),
    "brl.socket": ("TSocket", "TSocketException"),
    "brl.socketstream": ("TSocketStream", "TSocketStreamFactory"),
    "brl.standardio": ("TCStandardIO",),
    "brl.stream": ("TCStream", "TIO", "TStream", "TStreamException", "TStreamFactory",
                   "TStreamReadException", "TStreamStream", "TStreamWrapper",
                   "TStreamWriteException"),
    "brl.system": ("TSystemDriver", "TWin32SystemDriver"),
    "brl.textstream": ("TTextStream", "TTextStreamFactory"),
    "pub.directx": ("D3DADAPTER_IDENTIFIER9", "D3DCAPS9", "D3DCLIPSTATUS", "D3DCLIPSTATUS9",
                    "D3DDEVTYPE", "D3DDISPLAYMODE", "D3DLIGHT9", "D3DLOCKED_RECT",
                    "D3DMATERIAL7", "D3DMATERIAL9", "D3DMATRIX", "D3DPRESENT_PARAMETERS",
                    "D3DRASTER_STATUS", "D3DRECTPATCH_INFO", "D3DSURFACE_DESC",
                    "D3DTRIPATCH_INFO", "D3DVERTEXBUFFERDESC", "D3DVERTEXELEMENT9",
                    "D3DVIEWPORT7", "D3DVIEWPORT9", "DDARGB", "DDBLTFX", "DDCAPS_DX1",
                    "DDCAPS_DX3", "DDCAPS_DX5", "DDCAPS_DX6", "DDCAPS_DX7",
                    "DDCOLORCONTROL", "DDCOLORKEY", "DDOPTSURFACEDESC", "DDOSCAPS",
                    "DDOVERLAYFX", "DDPIXELFORMAT", "DDRGBA", "DDSCAPS", "DDSCAPS2",
                    "DDSCAPSEX", "DDSURFACEDESC", "DDSURFACEDESC2", "DSBCAPS",
                    "DSBUFFERDESC", "DSCAPS", "WAVEFORMATEX"),
    "pub.freetype": ("FTFace", "FTGlyph", "FTMetrics"),
    "pub.win32": ("BITMAPINFOHEADER", "CHARFORMAT", "CHARFORMATW", "CHARRANGE",
                  "CHOOSECOLOR", "CHOOSEFONT", "COLORSCHEME", "COMBOBOXEXITEMW", "DEVMODE",
                  "FINDINFOW", "GUID", "LOGFONTW", "LVCOLUMNW", "LVHITTESTINFO", "LVITEMW",
                  "MENUITEMINFOW", "MINMAXINFO", "MSG", "PAINTSTRUCT", "PARAFORMAT",
                  "PIXELFORMATDESCRIPTOR", "SCROLLINFO", "TBBUTTON", "TCITEMW", "TEXTMETRIC",
                  "TEXTRANGEW", "TINITCOMMONCONTROLSEX", "TOOLINFOW", "TVINSERTSTRUCTW",
                  "TVITEMW", "VARIANT", "WINDOWINFO", "WNDCLASS", "WNDCLASSW"),
}.items() for t in ts}

# Types in the reflection data that this project could NOT attribute to a BlitzMax module
# and therefore still counts against itself. Named so the report can say so out loud
# rather than leaving the reader to discover them in the outstanding list. Adding a name
# here changes no number -- it only labels.
UNATTRIBUTED_PROBABLY_MODULE = {
    # Emitted at 0x00597fa5..0x00598a99, between brl.stream and brl.system, which is the
    # BlitzMax module region and nowhere near the game's or the two bundled modules'. No
    # source under tools/blitzmax-legacy-src/mod declares any of them, so they stay in.
    "TVolume", "TWinVolume", "TWinVolumeDriver", "TVolSpace",
}


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


def load_declared():
    """The Types the game's own main module declares."""
    decl = set()
    p = os.path.join(EX, "type_declaration_order.tsv")
    if os.path.exists(p):
        with open(p, encoding="utf-8") as f:
            for r in csv.DictReader(f, delimiter="\t"):
                decl.add(r["type"])
    return decl


def is_module_type(tname, declared=()):
    """True when BlitzMax ships this Type. A game-declared Type never is."""
    if tname in declared:
        return False
    return tname in MODULE_TYPES_SHIPPED


def load_universe(inv, brl):
    """-> ({va: label}, {va: owner}) for every function this project is on the hook for.

    owner is "game" for the game's own main module and "thirdparty" for the two modules
    it bundles but did not author.
    """
    declared = load_declared()
    rows = []
    owners_of = {}
    with open(os.path.join(EX, "vtable_map.tsv"), encoding="utf-8") as f:
        for r in csv.reader(f, delimiter="\t"):
            if len(r) > 5 and str(r[5]).startswith("0x"):
                va = _norm(r[5])
                rows.append((va, r[0], r[2]))
                owners_of.setdefault(va, set()).add(r[0])

    # WHEN THE CLASS TABLE OUTRANKS brl_functions.tsv. That file is built by matching
    # bytes against BRL module builds, and a 15-to-53-byte generic stub matches dozens
    # of them -- its own rows record the alternates, pipe-separated
    # (`__pub_win32_COLORSCHEME_New|__pub_win32_...`). Fifteen VAs, 654 bytes, are
    # flagged there whose ONLY class-table owner is a Type belonging to a module the
    # game bundles: ZipFile.Delete, tm.New, tm_zip.New, SZipFileEntry.Create,
    # TBitMapChar.Delete, TBitmapFontLoadException.ToString and the rest. Thirteen of
    # them already have a matched body in src/recovered_thirdparty/, which coverage.py
    # then reported as "recovered files outside the universe". The reflection data
    # naming the owning Type is direct evidence out of the binary; a byte-signature
    # collision is a guess, so the class table wins.
    #
    # Narrow on purpose. The override needs EVERY owner of the VA to be a bundled Type.
    # The shared 36-byte abstract-method stub at 0x005b95ac is owned by TBase_Team (the
    # game), TFont (brl.font) and TAudioSampleLoader at once -- the reflection data
    # itself shows it is shared runtime, so it does not qualify and stays excluded.
    def brl_overridden(va):
        ts = owners_of.get(va)
        if not ts:
            return False
        return all(t not in declared and t not in MODULE_TYPES_SHIPPED for t in ts)

    uni, owner = {}, {}
    for va, tname, mname in rows:
        if is_module_type(tname, declared):
            continue
        if va in brl and not brl_overridden(va):
            continue
        if va not in inv:
            continue
        uni[va] = "%s.%s" % (tname, mname)
        owner[va] = "game" if tname in declared else "thirdparty"

    # Module-level Functions: reached only from the module body, so they appear in no
    # class table and no reflection record. Derived by scripts/build_module_functions.py;
    # see that file for how, and for what it refuses to claim.
    #
    # THIS FILE USED TO BE ABSENT. os.path.exists() was False, the loop was skipped, and
    # the whole of criterion (b) -- 92 game functions, 31,751 bytes, GameMain and LogLine
    # and FormatMoney among them -- was missing from the universe while 89 of them sat
    # matched on disk and were reported as "recovered files outside the universe".
    modmap = os.path.join(EX, "module_functions.tsv")
    if os.path.exists(modmap):
        with open(modmap, encoding="utf-8") as f:
            for r in csv.reader(f, delimiter="\t"):
                if r and str(r[0]).startswith("0x"):
                    va = _norm(r[0])
                    if va in inv and va not in brl:
                        uni.setdefault(va, r[1] if len(r) > 1 else "module")
                        owner.setdefault(
                            va, "game" if len(r) > 3 and r[3] == "game" else "thirdparty")
    else:
        sys.stderr.write(
            "coverage.py: extracted/module_functions.tsv is missing, so every module-level\n"
            "             Function is absent from the universe and the percentage below is\n"
            "             OVERSTATED. Run: python scripts/build_module_functions.py\n")
    return uni, owner


# Every tree that holds a reconstructed body, and whether the tree name asserts
# verification. src/recovered_unverified IS scanned: 48 of its 64 bodies carry an
# oracle-produced byte-equality claim and assemble.py builds all but UNVERIFIED_SKIP into
# the shipped exe, so 66,935 bytes of finished, shipping work were being reported as
# outstanding by a scanner that simply did not look in that directory.
#
# That the bodies are THERE rather than in src/recovered/ is a separate defect, and a real
# one: docs/RULES.md 5.1 says byte-exact bodies go in src/recovered/. Fixing the measure
# does not fix the placement, and this comment is not permission to leave them. But the
# measure must describe the corpus that exists, not the one the rules describe.
BODY_TREES = ("src/recovered/*.bmx",
              "src/recovered_module/*.bmx",
              "src/recovered_thirdparty/*/*.bmx",
              "src/recovered_thirdparty/*.bmx",
              "src/recovered_unverified/*.bmx")


def load_recovered():
    """{va: (path, matched)} for every body on disk, MATCH or not."""
    rec = {}
    for pat in BODY_TREES:
        for p in sorted(glob.glob(os.path.join(ROOT, pat.replace("/", os.sep)))):
            head, vs, matched = K.read(p)
            if not vs:
                m = HEADER_VA.search(head)
                if not m:
                    continue
                va = _norm(m.group(1))
            else:
                va = _norm(vs[0])
            # A verified tree wins a tie: recovered/ is scanned before
            # recovered_unverified/, and the first body for a VA keeps the slot unless the
            # later one is matched and the earlier one is not.
            if va in rec and not (matched and not rec[va][1]):
                continue
            rec[va] = (p, matched)
    return rec


def main():
    inv = load_inventory()
    brl = load_brl()
    uni, owner = load_universe(inv, brl)
    rec = load_recovered()

    matched = {va for va, (_p, ok) in rec.items() if ok}
    hit = set(uni) & matched
    onpaper = set(uni) & set(rec)

    ub = sum(inv[va] for va in uni)
    rb = sum(inv[va] for va in hit)

    print("NSS5 RECONSTRUCTION COVERAGE")
    print("universe: game Type methods + game and bundled-module Functions;")
    print("          BRL/PUB module code, C-runtime helpers and the .text section")
    print("          excluded (see docstring).")
    print()
    print("  functions MATCHed : %5d of %5d  = %6.2f%%" % (len(hit), len(uni), 100.0 * len(hit) / len(uni)))
    print("  bytes     MATCHed : %5d of %5d  = %6.2f%%   <-- quote this one" % (rb, ub, 100.0 * rb / ub))

    # SPLIT BY WHOSE CODE IT IS. The universe above is "not BRL/PUB", which is not the same
    # as "the game's". extracted/type_declaration_order.tsv holds the Types the game's main
    # module actually declares (recovered from the module body's registration sequence).
    # Everything else in the universe belongs to the two modules the game LINKS but did not
    # author -- zipengine (ZipFile, tm_zip, SZIPFileDataDescriptor) and the
    # bitmap-font/text-renderer module (TBitmapFont, TPrivateFontKerning, TRectangle,
    # TDrawingPoint).
    #
    # This matters twice over. It keeps the headline number honest, and it stops anyone
    # bulk-banking the empty 14-byte Delete stubs those Types carry: they are cheap
    # function-count wins that would land in src/recovered/ and therefore in the MAIN
    # module, corrupting the recorded Type declaration order.
    for label, key in (("game main module", "game"), ("bundled modules", "thirdparty")):
        group = [v for v in uni if owner.get(v) == key]
        tb = sum(inv[v] for v in group)
        if not tb:
            continue
        hb = sum(inv[v] for v in group if v in hit)
        nh = sum(1 for v in group if v in hit)
        print("     %-20s %5d/%5d fns  %6.2f%%   %6d/%6d bytes  %6.2f%%"
              % (label, nh, len(group), 100.0 * nh / len(group),
                 hb, tb, 100.0 * hb / tb))

    if len(onpaper) != len(hit):
        print()
        print("  on disk without a byte-equality claim: %d (NOT counted)" % (len(onpaper) - len(hit)))
        for va in sorted(onpaper - hit, key=lambda v: -inv[v]):
            print("     %s %7d  %s" % (va, inv[va], os.path.basename(rec[va][0])))

    never = sorted(set(uni) - set(rec), key=lambda v: -inv[v])
    if never:
        print()
        print("  NEVER OPENED -- in the universe, no body anywhere in src/: %d functions, %d bytes"
              % (len(never), sum(inv[v] for v in never)))
        for va in never[:15]:
            print("     %s %7d  %s" % (va, inv[va], uni[va]))
        if len(never) > 15:
            print("     ... and %d more" % (len(never) - 15))
    print()

    out = sorted(((inv[va], va, uni[va]) for va in uni if va not in hit), reverse=True)
    print("  outstanding: %d functions, %d bytes" % (len(out), sum(s for s, _v, _l in out)))
    print("  largest 15:")
    for s, va, lab in out[:15]:
        print("     %s %7d  %s" % (va, s, lab))

    # Types this project could not attribute to a BlitzMax module and is therefore still
    # counting against itself. Under-reporting, deliberately; see the docstring.
    unatt = [(inv[v], v, uni[v]) for v in uni
             if uni[v].split(".", 1)[0] in UNATTRIBUTED_PROBABLY_MODULE]
    if unatt:
        print()
        print("  counted against this project but probably not its code: %d functions, %d bytes"
              % (len(unatt), sum(s for s, _v, _l in unatt)))
        print("    %s -- emitted inside BlitzMax's own address range, but no module source"
              % ", ".join(sorted(UNATTRIBUTED_PROBABLY_MODULE)))
        print("    in tools/blitzmax-legacy-src declares them, so they stay in the universe.")

    # Files on disk whose VA is NOT in the universe -- either genuinely out of scope
    # (BRL bodies somebody reconstructed anyway) or a sign the universe filter is wrong.
    stray = sorted(set(rec) - set(uni), key=lambda v: -inv.get(v, 0))
    if stray:
        print()
        print("  %d recovered files sit outside the universe, %d bytes (BRL bodies, or filter too tight):"
              % (len(stray), sum(inv.get(v, 0) for v in stray)))
        for va in stray[:8]:
            print("     %s %7d  %s" % (va, inv.get(va, 0), os.path.basename(rec[va][0])))
        if len(stray) > 8:
            print("     ... and %d more" % (len(stray) - 8))
    return 0


# A rule nothing checks is advice, and advice rots. harness.py imports the real BRL module
# for the Types in its MODULE_TYPES map rather than stubbing them, which is the harness
# saying out loud "BlitzMax ships this". Anything the harness treats that way must also be
# out of this file's universe, or the two disagree about whose code it is. The check runs
# one way only: MODULE_TYPES_SHIPPED is much larger (it covers every reflected BlitzMax
# Type, not just the ones the harness has needed to import), and growing it must not force
# an edit to harness.py.
#
# harness.py is READ, not imported. Importing it is not free: under NSS5_WORKER it copies
# the whole BlitzMax root to a per-worker tree (30-60s) as an import side effect, and a
# measurement script must not do that. progress.py's check_not_shipped() reads
# assemble.py's UNVERIFIED_SKIP the same way, for the same reason.
def _check_in_sync_with_harness():
    p = os.path.join(os.path.dirname(os.path.abspath(__file__)), "harness.py")
    try:
        with open(p, encoding="utf-8", errors="replace") as f:
            text = f.read()
    except OSError:
        return
    m = re.search(r"^MODULE_TYPES\s*=\s*\{(.*?)^\s*\"TBank\":[^\n]*\}", text, re.S | re.M)
    if not m:
        m = re.search(r"^MODULE_TYPES\s*=\s*\{(.*?)\}\s*$", text, re.S | re.M)
    if not m:
        raise SystemExit(
            "coverage.py: could not find MODULE_TYPES in scripts/harness.py, so the two "
            "measures' idea of whose code is whose is unchecked. Fix the pattern here "
            "rather than deleting the check.")
    named = re.findall(r'"([A-Za-z_][A-Za-z0-9_]*)"\s*:\s*"', m.group(0))
    missing = sorted(t for t in named if t not in MODULE_TYPES_SHIPPED)
    if missing:
        raise SystemExit(
            "coverage.py: harness.MODULE_TYPES treats %s as BlitzMax-shipped but "
            "MODULE_TYPES_SHIPPED does not -- the two measures disagree about whose "
            "code it is. Add it here, with the module that declares it." % ", ".join(missing))


_check_in_sync_with_harness()


if __name__ == "__main__":
    sys.exit(main())
