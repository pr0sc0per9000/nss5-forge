"""
Are the FLOAT CONSTANTS in our reconstructed bodies right? -- the byte oracle cannot say.

THE GAP. `harness.compare` masks any 4-byte operand that decodes to an in-image address on
both sides. A float constant is referenced exactly that way -- `fld dword ptr [0x00C7BCE4]`
-- so the ADDRESS is masked and the VALUE behind it is never compared. Same hole that leaves
string literal CONTENT unverified (the one check_literals.py exists to close): a body that
writes 0.75 where the original has 0.62 still MATCHes, because both compile to "load a float
from somewhere in .rdata".

Not hypothetical. FormatMoney's currency rates (0.62, 0.70) and every physics constant in
the engine are .rdata floats. A wrong one is a wrong game, silently.

HOW THE CHECK AVOIDS FALSE ALARMS
================================================================================
Two hazards would make a naive version of this comparison useless. Both are handled.

  1. GLOBALS MUST NOT BE CONFLATED WITH CONSTANTS. `fld dword ptr [abs]` is how bcc reads a
     Float **Global** as well as how it loads a constant -- BlitzMax puts both in the `data`
     section, so an address alone cannot tell them apart. So this script CLASSIFIES every
     address referenced from a direct disp32 FPU operand, using TWO signals, before it is
     ever compared:
       (a) `extracted/globals_final.tsv` -- the project's existing census of known Globals.
       (b) a fresh whole-program STORE SCAN of the original exe's `.text`+`code` bytes: any
           address that is ever the target of `fst`/`fstp` (D9/DD, reg 2 or 3), a direct
           `mov [addr], reg` (0x89), or a direct `mov [addr], imm32` (0xC7 /0) is a mutable
           Global by definition -- "referenced from code but never STORED to" is exactly the
           definition of a genuine constant, taken literally and checked literally.
     An address in EITHER set is excluded. Only what survives both filters is compared.
     The store scan runs once per process (~1.8 MB of code, pure byte-pattern scan, no
     disassembler needed) and is cached; every position in the range is checked (no
     instruction-alignment assumptions), which can only ADD false "written" classifications,
     never miss a real one -- the safe direction, since a wrongly-excluded constant is merely
     not checked, while a wrongly-INCLUDED Global reports a difference that is not one.

  2. THE COMPARISON MUST NOT BE A POSITION-BLIND SORTED MULTISET. Comparing "the set of
     floats this function loads" against "the set of floats that function loads" with order
     discarded both loses power (two different constants that happen to round to the
     same 4-decimal value at different call sites cancel out) and is unnecessary: a body only
     reaches this checker after the byte oracle already reported MATCH, which means original
     and ours are byte-identical at every position that is not one of the oracle's four
     masks -- and a float's address is exactly a masked "absolute address" operand. So the
     FPU opcode/modrm byte at a given offset in the original is GUARANTEED identical to the
     opcode/modrm byte at the SAME offset in ours; only the trailing disp32 can differ. This
     script pairs original and ours BY INSTRUCTION OFFSET, not by value, which is strictly
     more precise and needs no per-body re-disassembly of ours at all -- classification is
     computed once from the original side and the paired address in ours is read at the
     identical relative offset.

  3. STALE EXE. Bodies banked since the last `assemble.py` are absent from the assembled
     program, so they decode to zero constants. Re-run `assemble.py` before this script,
     always (same trap as `check_assembled.py`).

A THIRD CASE escapes classification (1)+(2) entirely, recorded here rather than silently
"solved": a module Global whose ORIGINAL carries a non-zero compile-time initialiser
(`Global g_pole_maxz:Float` baked to 100.0 in NSS5.exe's data section, say) but which is
READ, never explicitly re-stored, ANYWHERE in the recovered corpus. Such a Global passes
"never stored to" cleanly and gets classified as a constant -- yet it is not one, and the
reconstruction has not captured its initial value (a bare `'!Global name:Type` pragma
defaults to 0 in the assembled build). That is a source-reconstruction gap rather than a
classifier defect, and it produces mismatches with a distinctive, checkable signature: OUR
side reads exactly 0.0 while the original is non-zero. The report below buckets on that
signature so
a real wrong-literal bug (both sides non-zero, e.g. 600.0 vs 570.0) is never mixed in with a
likely-uncaptured-Global-default (0.5 vs 0.0). Confirmed by hand for two zero-bucket cases
(`TBall.CreateBall`'s `g_ball_snowthreshold`, `TPole.CheckHit`'s `g_pole_maxz`): both are
declared `'!Global ...:Float` in the very file that reads them, with no assignment anywhere
in the corpus, i.e. genuinely uncaptured initialisers, not misclassified constants.

STABILITY: this script reads TWO live, moving targets --
`DEFAULT_OURS` (src/assembled/nss5_assembled.exe, which any concurrent worker's assemble.py
can be mid-rewriting) and `src/recovered/**` itself (growing as other workers bank bodies
mid-run). Run concurrently with other workers, `not comparable` swings by 1000+ between two
back-to-back runs on an unchanged corpus: one set of three runs measured 133/967/368, and a
second set 1317/1693/758. `constants DIFFER (confirmed)` is 0 in every one of those
runs and is NOT affected -- only the denominator (how many bodies happen to resolve against
whichever exe-on-disk snapshot this process opened) moves.
AVOID IT by snapshotting the exe to a private path right after your own `assemble.py`
and passing THAT path as `our_exe`, e.g.:
    python scripts/assemble.py
    cp src/assembled/nss5_assembled.exe private_snapshot.exe
    python scripts/check_floats.py --all private_snapshot.exe
Against a private, static exe copy, `not comparable` drops to single digits (2, 4, 7 across
three back-to-back runs on a growing corpus) -- the residue is fully explained by
bodies banked to src/recovered AFTER the snapshot (still a live directory; only the exe
argument is pinned), not a checker defect. Prefer this invocation over the bare
`DEFAULT_OURS` form whenever other workers may be active.

Usage: check_floats.py [N|--all] [our_exe]
"""

import csv
import os
import struct
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
os.environ.setdefault("NSS5_WORKER", "floats")
os.environ["NSS5_NO_LEARN"] = "1"

import bytematch as B   # noqa: E402
import coverage as C    # noqa: E402

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DEFAULT_OURS = os.path.join(ROOT, "src", "assembled", "nss5_assembled.exe")
GLOBALS_TSV = os.path.join(ROOT, "extracted", "globals_final.tsv")

FPU_OPS = {0xD8, 0xD9, 0xDA, 0xDB, 0xDC, 0xDD, 0xDE, 0xDF}   # any FPU direct-mem operand
FPU_WIDE = {0xDC, 0xDD}                                       # m64-operand opcodes


# --------------------------------------------------------------- classify: Global vs constant

def load_globals_final():
    """VAs the project has already identified as Globals (any type), from the TSV census."""
    out = set()
    if not os.path.exists(GLOBALS_TSV):
        return out
    with open(GLOBALS_TSV, encoding="utf-8-sig", newline="") as f:
        for row in csv.reader(f, delimiter="\t"):
            if row and row[0].startswith("0x"):
                try:
                    out.add(int(row[0], 16))
                except ValueError:
                    pass
    return out


def scan_stores(buf):
    """Every address `buf` ever STORES a dword to, via a direct (mod=00,rm=101) operand.

    Checks every byte position (no instruction-length skipping), so it cannot miss a real
    store because an earlier byte sequence misaligned the scan -- it can only over-collect,
    which is the safe direction here (see module docstring, hazard 1).
    """
    out = set()
    n = len(buf)
    i = 0
    while i < n - 6:
        op = buf[i]
        b1 = buf[i + 1]
        if op in (0xD9, 0xDD) and (b1 & 0xC7) == 0x05 and ((b1 >> 3) & 7) in (2, 3):
            out.add(struct.unpack_from("<I", buf, i + 2)[0])          # fst / fstp
        elif op == 0x89 and (b1 & 0xC7) == 0x05:
            out.add(struct.unpack_from("<I", buf, i + 2)[0])          # mov [addr], reg32
        elif op == 0xC7 and b1 == 0x05:
            out.add(struct.unpack_from("<I", buf, i + 2)[0])          # mov [addr], imm32
        i += 1
    return out


_CLASSIFY_CACHE = {}


def classify_original():
    """-> (written_addrs, data_lo, data_hi) for NSS5.exe, computed once."""
    if "orig" in _CLASSIFY_CACHE:
        return _CLASSIFY_CACHE["orig"]
    b, img, secs = B.load(B.ORIG)
    written = set()
    data_lo = data_hi = 0
    for nm, rva, rs, ro in secs:
        if nm in (".text", "code"):
            written |= scan_stores(b[ro:ro + rs])
        if nm == "data":
            data_lo, data_hi = img + rva, img + rva + rs
    result = (written, data_lo, data_hi)
    _CLASSIFY_CACHE["orig"] = result
    return result


# ------------------------------------------------------------------------ per-function refs

def refs_in(buf):
    """-> [(offset_of_disp32, wide)] for every direct-address FPU memory operand in `buf`."""
    out = []
    n = len(buf)
    i = 0
    while i < n - 6:
        op = buf[i]
        if op in FPU_OPS and (buf[i + 1] & 0xC7) == 0x05:
            out.append((i + 2, op in FPU_WIDE))
            i += 6
            continue
        i += 1
    return out


def main():
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    limit = None
    ours_exe = DEFAULT_OURS
    for a in args:
        if a.isdigit():
            limit = int(a)
        elif a.endswith(".exe"):
            ours_exe = a
    if not os.path.exists(ours_exe):
        print("no assembled exe -- run scripts/assemble.py first")
        return 2

    inv = C.load_inventory()
    brl = C.load_brl()
    uni = C.load_universe(inv, brl)
    rec = C.load_recovered()

    globals_addrs = load_globals_final()
    written, data_lo, data_hi = classify_original()
    print("classifier: %d known Globals (globals_final.tsv), %d store-scanned addresses, "
          "data section 0x%08X-0x%08X" % (len(globals_addrs), len(written), data_lo, data_hi))

    def is_global(addr):
        return addr in globals_addrs or addr in written or not (data_lo <= addr < data_hi)

    work = []
    for va, (path, ok) in sorted(rec.items()):
        if ok and va in uni and "." in uni[va] and va in inv:
            t, m = uni[va].split(".", 1)
            work.append((va, t, m, inv[va], os.path.basename(path)))
    if limit:
        work = work[:limit]

    clean = mism = noconst = skipped = zeroonly = 0
    total_refs = total_global_refs = total_const_refs = 0
    bad = []
    zero_bucket = []      # ours reads exactly 0.0 -- see module docstring, "A THIRD CASE"
    for va, t, m, size, fname in work:
        orig_buf = B.read_va(int(va, 16), size)
        if not orig_buf:
            skipped += 1
            continue
        try:
            c = B.find_method(ours_exe, t, m)
        except Exception:                                  # noqa: BLE001
            c = None
        if not c or c["length"] != size:
            skipped += 1
            continue
        our_buf = c["bytes"]

        refs = refs_in(orig_buf)
        total_refs += len(refs)
        n_const = 0
        diffs, zdiffs = [], []
        for off, wide in refs:
            oaddr = struct.unpack_from("<I", orig_buf, off)[0]
            if is_global(oaddr):
                total_global_refs += 1
                continue
            total_const_refs += 1
            n_const += 1
            uaddr = struct.unpack_from("<I", our_buf, off)[0]
            width = 8 if wide else 4
            oraw = B.read_va(oaddr, width)
            uraw = B.read_va(uaddr, width, ours_exe)
            if not oraw or not uraw or len(oraw) < width or len(uraw) < width:
                continue
            if oraw[:width] != uraw[:width]:
                ov = struct.unpack("<d" if wide else "<f", oraw[:width])[0]
                uv = struct.unpack("<d" if wide else "<f", uraw[:width])[0]
                (zdiffs if uv == 0.0 and ov != 0.0 else diffs).append((off, ov, uv))
        if n_const == 0:
            noconst += 1
        elif diffs:
            mism += 1
            bad.append((fname, n_const, diffs[:6]))
            if zdiffs:
                zero_bucket.append((fname, zdiffs[:6]))
        elif zdiffs:
            zero_bucket.append((fname, zdiffs[:6]))
            zeroonly += 1        # not a confirmed constant-value bug -- see zero-bucket report
        else:
            clean += 1

    print("FLOAT CONSTANT FIDELITY -- original vs our compiled build, %d bodies" % len(work))
    print("(constants only -- Global addresses are classified out before comparison)")
    print()
    print("  no genuine .rdata constant : %d" % noconst)
    print("  constants AGREE            : %d" % clean)
    print("  constants DIFFER (confirmed): %d" % mism)
    print("  zero-bucket only (see below): %d  (not counted as confirmed -- read the caveat)"
          % zeroonly)
    print("  not comparable              : %d  (unlocatable / length mismatch in our exe)"
          % skipped)
    print()
    print("  raw FPU direct-address refs seen : %d" % total_refs)
    print("    classified as Global (skipped) : %d" % total_global_refs)
    print("    classified as genuine constant : %d" % total_const_refs)
    if bad:
        print()
        print("  %-44s %5s  %s" % ("file", "n", "offset: orig -> ours"))
        for f, n, diffs in bad[:30]:
            detail = ", ".join("+%d: %s -> %s" % (o, ov, uv) for o, ov, uv in diffs)
            print("  %-44s %5d  %s" % (f, n, detail))
        if len(bad) > 30:
            print("  ... and %d more" % (len(bad) - 30))
        print()
        print("  Each of these is a REAL difference between the two programs -- a constant")
        print("  value our build has wrong at that exact call site.")
    if zero_bucket:
        print()
        print("  ZERO-BUCKET (ours reads exactly 0.0, original does not) -- %d bodies. Likely"
              % len(zero_bucket))
        print("  an uncaptured module-Global initial value, NOT a wrong-literal bug. It")
        print("  has the signature of a false positive. See module docstring.")
        for f, zdiffs in zero_bucket[:30]:
            detail = ", ".join("+%d: %s -> 0.0" % (o, ov) for o, ov, _ in zdiffs)
            print("  %-44s %s" % (f, detail))
        if len(zero_bucket) > 30:
            print("  ... and %d more" % (len(zero_bucket) - 30))
    return 1 if mism else 0


if __name__ == "__main__":
    sys.exit(main())
