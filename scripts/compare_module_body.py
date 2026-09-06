"""
Byte-compare the MODULE BODY -- NSS5's top-level program -- against NSS5.exe.

WHAT THIS COMPARES
==================
Exactly two regions of NSS5.exe, and nothing else:

    0x004BA034  7,933 B  `__bb_main`          the module body: every top-level statement
                                              of the main source file, compiled into one
                                              compiler-synthesised function.
    0x004BA000     52 B  the module register  the "have I run yet?" wrapper that calls it
                                              (`E8 0B 00 00 00` at 0x004BA024 -> 0x004BA034,
                                              read out of the exe, not assumed).

Both extents come from Ghidra's function inventory, like every other verification here.

WHY THIS SCRIPT HAS TO EXIST
============================
`harness.try_method` finds a Type method through its BBDebugScope reflection record.
`harness.try_function` finds a module-level Function through its `_bb_<Name>` linker
symbol. The module body has neither: it is not declared anywhere in the source, it is
what is left over after the declarations. So 7,985 bytes of the program -- the single
largest unmeasured region in the reconstruction -- had no oracle at all. This is it.

OUR SIDE'S LENGTH: WHY NOT THE EPILOGUE SCAN
============================================
`bytematch.epilogue_len` finds our side's extent everywhere else by scanning for the
BlitzMax epilogue `89 EC 5D C3`. On the module body that rule is WRONG, and wrong in the
silent direction. bcc opens `__bb_main` with a run-once guard whose early return is a real
epilogue:

    004BA034  55 89 E5 53              push ebp; mov ebp,esp; push ebx
    004BA038  83 3D 08F05C00 00        cmp dword [0x005CF008],0
    004BA03F  74 0A                    je +10
    004BA041  B8 00000000              mov eax,0
    004BA046  5B 89 EC 5D C3           pop ebx; mov esp,ebp; pop ebp; ret   <-- +19

`epilogue_len(0x004BA034)` therefore returns 23 for a 7,933-byte function. Comparing 23
bytes and reporting agreement would be the exact 0xC3-truncation failure bytematch's
header warns about, one order of magnitude worse. So OUR length is taken from the object
file's own symbol table: the offset of the next `T` symbol after `__bb_main` minus
`__bb_main`'s own offset. That is the linker's own record of where the function ends and
it cannot be fooled by an epilogue in the middle.

WHAT THIS REFUSES TO CLAIM
==========================
* A MATCH verdict is decided by exactly the rule the rest of the project uses:
  `harness.compare` returning mode 'exact' or 'reloc' over EQUAL lengths. Nothing here
  loosens that. There is no prefix pass, no "close enough", no region-level MATCH.
* The per-region and prefix figures this prints are DIAGNOSTICS, not verdicts. A region
  that reports 100% agreement is not verified -- regions are not independently locatable
  and a shifted instruction upstream can realign downstream by luck. Only the whole-body
  verdict means anything, and only over the full 7,933 bytes.
* It does not claim the module body is "n% recovered". Byte agreement between two
  differently-ordered emission sequences is not a recovery fraction; it is a gradient to
  follow. `first_diff` is the number that is actually actionable.
* It does not write a 'byte-identical' marker anywhere, and it does not touch
  progress.py's accounting.
* It never learns. `compare(..., learn=None)` is hardcoded, so unlike try_method /
  try_function this script CANNOT teach the helper table a name off its own alignment and
  then mask its own call operand with it -- the failure NSS5_NO_LEARN exists to stop is
  structurally impossible here. What NSS5_NO_LEARN still governs is whether rows learned
  by EARLIER runs of other tools are in `full_table()`, so set it anyway; the result dict
  records which way it was set.

USAGE
=====
    python compare_module_body.py                       compare src/assembled/nss5_assembled.exe
                                                        as it stands (no rebuild)
    python compare_module_body.py --exe PATH [--obj O]  compare an already-built exe
    python compare_module_body.py --build SRC.bmx       compile SRC.bmx, then compare
    python compare_module_body.py --entry               the 52-byte register stub instead
    python compare_module_body.py --json                machine-readable

Library:
    import compare_module_body as CMB
    r = CMB.compare_body(exe_path)          # same result-dict shape as harness.try_function
    r = CMB.build_and_compare(src_path)
"""

import json
import os
import subprocess
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

import harness as H
import bytematch as _bytematch
import helper_map as _helper_map

ROOT = H.ROOT
MAIN_VA = 0x004BA034          # __bb_main -- the module body
INIT_VA = 0x004BA000          # its run-once register wrapper
MAIN_SYM = "__bb_main"        # as `nm` prints it (win32 adds one leading underscore)

DEFAULT_EXE = os.path.join(ROOT, "src", "assembled", "nss5_assembled.exe")

# Landmarks inside the original body, for the per-region diagnostic. These are the
# boundaries assemble.py's own header records (11 _bbIncbinAdd calls at +54, 29 bytes
# apart; the module-init chain; the 135 Type registrations interleaved with the Global
# initialisers; then the real program that ModuleBody_RealProgram.bmx reconstructs).
# They are DESCRIPTIVE. Nothing below treats a region as separately verifiable.
REGIONS = [
    (0, 54, "prologue + run-once guard"),
    (54, 344, "11 Incbin registrations"),
    (344, 437, "module-init chain"),
    (437, 5549, "Type registrations + Global initialisers"),
    (5549, 7933, "the real program (ModuleBody_RealProgram.bmx)"),
]


# --------------------------------------------------------------------- locate ours

def _release_objects(exe):
    """Every release object that contributes to `exe`, newest-name-sorted.

    An assembled build links the main module AND nss5_external.bmx, and bmk leaves an
    object per build ever run in the same directory -- including the DEBUG builds, which
    are bigger. 'biggest .o' therefore picks the wrong image and every call operand
    becomes unnameable, which reads as a pile of differences. Same rule as
    check_assembled.py: by exe stem, debug objects excluded.
    """
    objdir = os.path.join(os.path.dirname(os.path.abspath(exe)), ".bmx")
    if not os.path.isdir(objdir):
        return []
    stem = os.path.splitext(os.path.basename(exe))[0]
    out = [os.path.join(objdir, f) for f in os.listdir(objdir)
           if f.endswith(".o") and ".debug." not in f
           and (f.startswith(stem + ".bmx") or f.startswith("nss5_external.bmx"))]
    return sorted(out)


def _main_object(exe, objs=None):
    """The object that actually defines __bb_main."""
    for o in (objs if objs is not None else _release_objects(exe)):
        try:
            if MAIN_SYM in _helper_map.object_symbols(o):
                return o
        except Exception:                                         # noqa: BLE001
            continue
    return None


def locate_ours(exe, objpath=None):
    """-> dict(va, length, base, syms, objpath) for __bb_main in `exe`, or None.

    `length` is next-T-symbol-minus-own-offset. See the header for why the epilogue scan
    is not usable here.
    """
    objpath = objpath or _main_object(exe)
    if objpath is None:
        return None
    syms = _helper_map.object_symbols(objpath)
    off = syms.get(MAIN_SYM)
    base = _helper_map.resolve_base(objpath, exe, syms)
    if off is None or base is None:
        return None
    nxt = sorted(v for v in syms.values() if v > off)
    if not nxt:
        return None
    return {"va": base + off, "length": nxt[0] - off, "base": base,
            "syms": syms, "objpath": objpath, "obj_off": off}


def _our_entry_stub(exe, ours):
    """Our side's register wrapper -> (va, length), or (None, reason).

    The wrapper carries NO linker symbol on either side, so it cannot be looked up the way
    __bb_main is. In NSS5.exe it sits at 0x004BA000 and the `E8 0B 00 00 00` at its +36
    targets 0x004BA034 -- the wrapper ends exactly where the body begins. bcc emits the
    pair adjacently, so ours is the same 52 bytes back from our __bb_main.

    That is a LAYOUT ASSUMPTION, and an unchecked layout assumption is how you compare the
    wrong 52 bytes and call it a match. So it is not assumed: the candidate is accepted
    only if it actually contains a `call` to our own __bb_main, which is the wrapper's
    defining behaviour and is read out of our exe. If no such call is there, this returns
    a refusal and --entry reports ERROR rather than a verdict.
    """
    n = _bytematch.ghidra_sizes().get(INIT_VA)
    if not n:
        return None, "0x%08X is not in Ghidra's inventory" % INIT_VA
    va = ours["va"] - n
    buf = H._fn_bytes(exe, va, n)
    if buf is None:
        return None, "the 52 bytes before our __bb_main are not inside the image"
    for i in range(n - 5):
        if buf[i] in H.CALL_REL32:
            t = va + i + 5 + int.from_bytes(buf[i + 1:i + 5], "little", signed=True)
            if t == ours["va"]:
                return va, n
    return None, ("the 52 bytes before our __bb_main at 0x%08X contain no call to it, so "
                  "they are not its register wrapper -- refusing to compare them" % va)


# ------------------------------------------------------------------------ compare

def _name_tables(exe, objs):
    """(ournames, origtab, ourfns) -- merged across every contributing object.

    Reading only one object leaves the other unit's calls unnameable on our side, so they
    cannot mask and read as differences however correct the body is.
    """
    ournames, ourfns = {}, {}
    err = None
    for o in objs:
        try:
            syms, _base = _helper_map.our_helpers(None, exe, objpath=o)
        except Exception as ex:                                   # noqa: BLE001
            err = "%s: %s" % (type(ex).__name__, ex)
            continue
        for s, va in syms.items():
            ournames.setdefault(va, s)
        try:
            ourfns.update(_helper_map.our_functions(o, exe))
        except Exception as ex:                                   # noqa: BLE001
            err = "%s: %s" % (type(ex).__name__, ex)
    return ournames, _helper_map.full_table(), ourfns, err


def _region_report(ab, cb, ospan, uspan, octx, uctx, ournames, origtab, ourfns):
    """Per-region first_diff and positional agreement. DIAGNOSTIC ONLY.

    Each region is compared as its own byte range, which means a region reporting no
    difference has NOT been verified: the two bodies could be misaligned across the
    boundary and realign inside it. The number is here to say where to look next.
    """
    out = []
    n = min(len(ab), len(cb))
    for lo, hi, label in REGIONS:
        if lo >= n:
            out.append({"lo": lo, "hi": hi, "label": label, "status": "past our end"})
            continue
        h = min(hi, n)
        a, c = ab[lo:h], cb[lo:h]
        same = sum(1 for x, y in zip(a, c) if x == y)
        first = H.masked_first_diff(a, c, ospan, uspan,
                                    (octx[0], octx[1] + lo), (uctx[0], uctx[1] + lo),
                                    ournames, origtab, ourfns)
        out.append({"lo": lo, "hi": hi, "label": label, "compared": h - lo,
                    "same": same, "first_diff": (lo + first) if first < h - lo else None})
    return out


def unmaskable_calls(ab, va, origtab, ospan):
    """Call sites in the ORIGINAL whose target has no name, so they can NEVER mask.

    WHY THIS IS PRINTED NEXT TO first_diff
    ======================================
    compare()'s call-masking rules are all keyed on being able to NAME or FETCH the
    original's call target. Where the original calls something that is in neither
    `helper_map.orig_functions()` nor `helper_map.full_table()`, the rel32 operand cannot
    be masked even when our side calls the very same thing, because a probe and NSS5.exe
    are laid out differently and the displacements therefore differ by construction.

    So first_diff can be PESSIMISTIC: it may point at a site that is actually correct.
    Measured on the module body: 22 in-image sites of 321, and ten of those twenty-two are
    the module-init chain at +362..+432 -- exactly where first_diff lands. Reporting
    first_diff without this alongside would send the next pass hunting a bug at an offset
    that the oracle is merely blind to. It does NOT mean the site is right, only that this
    oracle cannot speak to it.
    """
    of = _helper_map.orig_functions()
    sites, i = [], 0
    while i < len(ab) - 5:
        if ab[i] in H.CALL_REL32:
            t = va + i + 5 + int.from_bytes(ab[i + 1:i + 5], "little", signed=True)
            # An out-of-image target means this 0xE8 is not really a call opcode -- it is
            # a byte inside some other instruction. compare() rejects those the same way.
            if ospan[0] <= t < ospan[1]:
                sites.append((i, t, t in of or t in origtab))
            i += 5
        else:
            i += 1
    return sites


def compare_body(exe, objpath=None, va=MAIN_VA, regions=True):
    """Compare `exe`'s __bb_main against NSS5.exe's module body at `va`.

    Returns the same result-dict shape harness.try_function returns. The verdict rule is
    identical to try_function's: equal lengths AND compare() mode in ('exact','reloc').
    """
    res = {"function": "__bb_main (module body)", "orig_va": "0x%08X" % va, "exe": exe,
           "no_learn": H.NO_LEARN}
    n = _bytematch.ghidra_sizes().get(va)
    if not n:
        res["status"] = "UNCERTAIN_LEN"
        res["message"] = "0x%08X is not in Ghidra's inventory" % va
        return res
    ab = H._fn_bytes(_bytematch.ORIG, va, n)

    objs = _release_objects(exe)
    if objpath and objpath not in objs:
        objs = [objpath] + objs
    ours = locate_ours(exe, objpath)
    if ours is None:
        res["status"] = "ERROR"
        res["message"] = ("could not locate %s in %s -- no release object defining it, "
                          "or resolve_base disagreed with itself" % (MAIN_SYM, exe))
        return res
    our_va, our_n = ours["va"], ours["length"]

    if va == INIT_VA:
        our_va, our_n = _our_entry_stub(exe, ours)
        if our_va is None:
            res["status"] = "ERROR"
            res["message"] = our_n
            return res
        res["note"] = ("the register wrapper carries no linker symbol on either side. "
                       "Ours is the 52 bytes before our __bb_main, ACCEPTED ONLY because "
                       "they contain a call to it -- verified against our exe, not assumed.")

    cb = H._fn_bytes(exe, our_va, our_n) if our_n else None
    res.update(orig_len=n, our_len=our_n, our_va="0x%08X" % our_va,
               orig_len_from="ghidra", objpath=ours["objpath"],
               our_len_from=("ghidra (the wrapper is the same size on both sides; its "
                             "start is proved by its call to our __bb_main)"
                             if va == INIT_VA else
                             "next symbol in %s" % os.path.basename(ours["objpath"])))
    if ab is None or cb is None:
        res["status"] = "ERROR"
        res["message"] = "could not read one of the bodies (ab=%s cb=%s)" % (
            ab is not None, cb is not None)
        return res

    ournames, origtab, ourfns, nerr = _name_tables(exe, objs)
    if nerr:
        res["naming_error"] = nerr
    if not ournames:
        # Never swallow this. With no name map NOTHING masks by name and every call
        # operand reads as a difference, which looks exactly like a bad reconstruction.
        res["naming_error"] = res.get("naming_error") or "our-side symbol table is empty"

    ospan, uspan = H._span(_bytematch.ORIG), H._span(exe)
    octx, uctx = (_bytematch.ORIG, va), (exe, our_va)
    # learn=None ALWAYS. This region is 7,933 bytes of unverified reconstruction; letting
    # it teach the helper table a name off its own alignment is exactly the self-fulfilling
    # masking NSS5_NO_LEARN exists to stop, and at this size it would be unauditable.
    mode, same, total, masked, first = H.compare(
        ab, cb, ospan, uspan, octx, uctx,
        ournames=ournames, origtab=origtab, learn=None, ourfns=ourfns)
    res.update(mode=mode, matched=same, total=total, reloc_masked=masked,
               status="MATCH" if (mode in ("exact", "reloc") and n == our_n)
                      else "MISMATCH")
    if n != our_n:
        res["reason"] = "length differs (orig %d vs ours %d)" % (n, our_n)
    if res["status"] == "MISMATCH":
        res["first_diff"] = first
        sites = unmaskable_calls(ab, va, origtab, ospan)
        blind = [(o, t) for o, t, known in sites if not known]
        res["call_sites"] = len(sites)
        res["unmaskable_call_sites"] = ["+%d->0x%08X" % (o, t) for o, t in blind]
        res["first_diff_is_unmaskable_call"] = any(o <= first < o + 5 for o, _t in blind)
        res["disasm_orig"] = H.disasm_window(ab, va, first)
        res["disasm_ours"] = H.disasm_window(cb, our_va, first)
        if regions and va == MAIN_VA:
            res["regions"] = _region_report(ab, cb, ospan, uspan, octx, uctx,
                                            ournames, origtab, ourfns)
    return res


# -------------------------------------------------------------------------- build

def build_and_compare(src_path, keep=False, workdir=None):
    """Compile `src_path` as-is (it must already be a complete program) and compare.

    Mirrors harness.try_function's build step exactly -- same bmk invocation, same
    utf-8-sig source encoding rule, same BuildLock.
    """
    src_path = os.path.abspath(src_path)
    wd = workdir or os.path.dirname(src_path)
    exe = os.path.splitext(src_path)[0] + ".exe"
    res = {"src": src_path, "workdir": wd}
    with H.BuildLock():
        p = subprocess.run([H.BMK, "makeapp", "-r", "-t", "console", src_path],
                           cwd=H.BMX_ROOT, env=H._env(), capture_output=True,
                           text=True, errors="replace", timeout=1800)
    if p.returncode != 0 or not os.path.exists(exe):
        res["status"] = "BUILD_FAIL"
        res["message"] = ((p.stdout or "") + (p.stderr or "")).strip()[-2500:]
        return res
    res.update(compare_body(exe))
    return res


# --------------------------------------------------------------------------- main

def _print(r):
    print("MODULE BODY  %s  ->  %s" % (r.get("orig_va"), r.get("status")))
    if r.get("message"):
        print("  " + r["message"][:2000])
        return
    print("  original : %s bytes at %s (%s)"
          % (r.get("orig_len"), r.get("orig_va"), r.get("orig_len_from")))
    print("  ours     : %s bytes at %s (%s)"
          % (r.get("our_len"), r.get("our_va"), r.get("our_len_from")))
    print("  compare  : mode=%s  positional agreement %s/%s  relocations masked %s"
          % (r.get("mode"), r.get("matched"), r.get("total"), r.get("reloc_masked")))
    if r.get("reason"):
        print("  " + r["reason"])
    if r.get("naming_error"):
        print("  NAMING: %s" % r["naming_error"])
    if not r.get("no_learn"):
        print("  !! NSS5_NO_LEARN is not set. Helper names learned from this body's own")
        print("  !! alignment can mask its own call operands. Re-run with NSS5_NO_LEARN=1.")
    if r.get("first_diff") is not None:
        print("  first meaningful difference (masked): +%d" % r["first_diff"])
    if r.get("call_sites"):
        blind = r.get("unmaskable_call_sites", [])
        print("  original-side call sites: %d, of which %d have an unnamed target and can"
              % (r["call_sites"], len(blind)))
        print("  NEVER mask however correct our side is -- first_diff is pessimistic there.")
        if blind:
            print("    %s%s" % (" ".join(blind[:12]), " ..." if len(blind) > 12 else ""))
        if r.get("first_diff_is_unmaskable_call"):
            print("  !! first_diff LANDS ON one of those unnameable call sites. This oracle")
            print("  !! cannot say whether that call is right or wrong. Name the target in")
            print("  !! extracted/runtime_helpers.tsv before treating +%d as a defect."
                  % r["first_diff"])
    for g in r.get("regions", []):
        if "status" in g:
            print("    +%-5d..+%-5d  %-44s %s" % (g["lo"], g["hi"], g["label"], g["status"]))
            continue
        fd = "+%d" % g["first_diff"] if g["first_diff"] is not None else "none in region"
        print("    +%-5d..+%-5d  %-44s %5d/%-5d bytes equal   first_diff %s"
              % (g["lo"], g["hi"], g["label"], g["same"], g["compared"], fd))
    print()
    print("  DIAGNOSTIC ONLY. Regions are not independently verifiable and a region with")
    print("  no difference is NOT a verified region. The only verdict is the line above.")
    if r.get("disasm_orig"):
        print("\n  ORIGINAL around the first difference:\n" + r["disasm_orig"])
        print("\n  OURS around the first difference:\n" + r["disasm_ours"])


def main():
    a = sys.argv[1:]
    exe, obj, src, va, as_json = DEFAULT_EXE, None, None, MAIN_VA, False
    i = 0
    while i < len(a):
        if a[i] == "--exe":
            i += 1; exe = a[i]
        elif a[i] == "--obj":
            i += 1; obj = a[i]
        elif a[i] == "--build":
            i += 1; src = a[i]
        elif a[i] == "--entry":
            va = INIT_VA
        elif a[i] == "--json":
            as_json = True
        else:
            print(__doc__)
            return 2
        i += 1
    r = build_and_compare(src) if src else compare_body(exe, obj, va=va)
    if as_json:
        print(json.dumps(r, indent=1, default=str))
    else:
        _print(r)
    return 0 if r.get("status") == "MATCH" else 1


if __name__ == "__main__":
    sys.exit(main())
