"""
localise_diff.py -- find WHERE a large reconstructed body diverges from NSS5.exe.

WHY THIS EXISTS
===============================================
`harness.try_method` answers "is this body right?" and, when it is not, hands back
`orig_hex`/`our_hex` (the first 96 bytes) and two 8-line disassembly windows. On a 60-byte
body that is the whole story. On a 4 KB body it is nothing: the windows sit wherever
`first_diff` landed, and `first_diff` itself is only meaningful when the two lengths AGREE.

    MISMATCH mode='len' reports `matched` -- a POSITIONAL count of equal bytes over the
    common prefix. It is NOT a common-prefix length and must never be quoted as one
    (docs/reference/codegen-patterns.md 11.3). This script reports no such number at all.

What actually localises a large body is an ALIGNMENT: line the two instruction streams up,
and report the places where the alignment has to insert or delete bytes. Those are the
length-changing gaps, and their deltas sum to the whole length deficit. Run by hand with
difflib the technique located a 54-byte deficit in a single pass; this script makes it
reusable.

THE TWO STAGES, AND WHY THEY ARE SEPARATE
=========================================
1. ALIGN (tolerant). Each instruction is reduced to a key: its bytes with every in-image
   absolute operand and every relative-branch displacement blanked. That is deliberately
   MORE tolerant than the oracle -- a call to the wrong function has the same key as a call
   to the right one -- because alignment only has to answer "does this instruction
   correspond to that one?". Blanking branch displacements is not optional: a 54-byte gap
   early in a body shifts every later jump displacement, and without blanking, everything
   after the first gap misaligns and the signal is lost.

2. ADJUDICATE (strict). Every byte difference inside an ALIGNED region is then decided by
   `harness.compare` -- the real oracle masking, called with `learn=None`, not a private
   reimplementation. So a wrong callee or a wrong class-table slot inside an aligned region
   is still reported, as a `sub` (same-length substitution). Differences that fall inside a
   relative-branch displacement are counted separately as `branch_shifts`: after a real
   length gap those are an arithmetic consequence of the gap, not independent findings.

Stage 1 can therefore never bless anything; it only decides what gets compared with what.

READING THE OUTPUT
==================
* `gaps`     -- length-changing. This is the signal. Each carries its ORIGINAL byte offset,
                the size on both sides, the delta, and both disassemblies with context.
* `delta_accounted` -- sum of gap deltas vs `our_len - orig_len`. If they agree, the gaps
                explain the entire length error and there is nothing else to find.
* `subs`     -- same length, genuinely different bytes (wrong callee, wrong field offset,
                wrong slot, wrong immediate). Real findings, just not length errors.
* `branch_shifts` -- count only. Expected whenever `gaps` is non-empty.

API
===
    import localise_diff as L
    r = L.localise('TProfile', 'SaveProfile', our_exe)          # a probe .exe
    r = L.localise_body('TProfile', 'SaveProfile', body_text)   # builds the probe for you
    r = L.localise_function(0x00505B91, our_exe, name='LogLine')          # module Function
    r = L.localise_function_body('LogLine', '(s$)', body, 0x00505B91)
    print(L.report(r))

CLI
===
    python scripts/localise_diff.py TType.Method                    # body from src/recovered
    python scripts/localise_diff.py TType.Method body.bmx
    python scripts/localise_diff.py TType.Method --exe <probe.exe>
    python scripts/localise_diff.py --va 0x00505B91 --name LogLine --sig "(s$)" body.bmx
    python scripts/localise_diff.py --va 0x00505B91 --name LogLine --exe <probe.exe>
    ... plus --context N (default 6), --json, --max-gaps N

NOTE ON `our_exe`. Any probe .exe works, but pass one whose build directory still exists
(`try_method(..., keep=True)` -> `res['workdir']`, exe at `<workdir>/probe.exe`). The
`.bmx/*.o` beside it is what names OUR call targets; without it `E8` operands cannot be
masked by name and the `subs` list fills with unmaskable call noise. `naming` in the result
says which of the two you got.
"""

import difflib
import json
import os
import struct
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

os.environ.setdefault("NSS5_WORKER", "localise")

import bytematch as _bm      # noqa: E402
import harness as H          # noqa: E402
import helper_map as _hm     # noqa: E402

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
RECOVERED = os.path.join(ROOT, "src", "recovered")

MAX_ADJUDICATE = 64          # per-block iteration cap; a block with more is reported as-is


# ------------------------------------------------------------------ instructions

class _Ins(object):
    __slots__ = ("off", "size", "bytes", "mn", "op")

    def __init__(self, off, size, b, mn, op):
        self.off, self.size, self.bytes, self.mn, self.op = off, size, b, mn, op

    def text(self):
        return ("%s %s" % (self.mn, self.op)).strip()


def _decode(buf, va):
    """Whole-body instruction list. Never returns a partial decode."""
    md = H._cs()
    if not md:
        raise RuntimeError("capstone is unavailable; localise_diff needs it")
    out = [_Ins(x.address - va, x.size, bytes(x.bytes), x.mnemonic, x.op_str)
           for x in md.disasm(bytes(buf), va)]
    got = sum(i.size for i in out)
    if got < len(buf):                       # skipdata should prevent this; be explicit
        out.append(_Ins(got, len(buf) - got, bytes(buf[got:]), "db",
                        " ".join("%02X" % b for b in buf[got:])))
    return out


def _rel_field(ib):
    """(start, width) of an instruction's relative-branch displacement, else None."""
    n = len(ib)
    if n == 5 and ib[0] in (0xE8, 0xE9):
        return (1, 4)
    if n == 6 and ib[0] == 0x0F and 0x80 <= ib[1] <= 0x8F:
        return (2, 4)
    if n == 2 and (ib[0] == 0xEB or 0x70 <= ib[0] <= 0x7F or 0xE0 <= ib[0] <= 0xE3):
        return (1, 1)
    return None


def _key(ib, span):
    """Alignment key: instruction bytes with link-layout-dependent operands blanked.

    Blanked: the relative-branch displacement, and every 4-byte window (from offset 1 on)
    that decodes to an address inside the instruction's own image. Opcode, ModRM, register
    selection, field offsets and small immediates all survive, which is what makes the
    alignment meaningful. This key is for ALIGNMENT ONLY -- see the module docstring.
    """
    b = bytearray(ib)
    rf = _rel_field(ib)
    if rf:
        b[rf[0]:rf[0] + rf[1]] = b"\x00" * rf[1]
    st = 1
    while st + 4 <= len(b):
        v = struct.unpack_from("<I", bytes(b), st)[0]
        if span[0] <= v < span[1]:
            b[st:st + 4] = b"\x00\x00\x00\x00"
            st += 4
        else:
            st += 1
    return bytes(b)


# ------------------------------------------------------------------ oracle context

class _Ctx(object):
    """Everything `harness.compare` needs, resolved once."""

    def __init__(self, our_exe, workdir=None):
        self.opath = _bm.ORIG
        self.upath = our_exe
        self.ospan = H._span(self.opath)
        self.uspan = H._span(our_exe)
        self.origtab = _hm.full_table()
        self.ournames, self.ourfns, self.naming = {}, {}, "none"
        wd = workdir or os.path.dirname(os.path.abspath(our_exe))
        objdir = os.path.join(wd, ".bmx")
        try:
            objs = [os.path.join(objdir, f) for f in os.listdir(objdir)
                    if f.endswith(".o")]
            objpath = max(objs, key=os.path.getsize)
            syms = _hm.object_symbols(objpath)
            base = _hm.resolve_base(objpath, our_exe, syms)
            self.ournames = {v: s for s, v in _hm.our_helpers(wd, our_exe)[0].items()}
            self.ourfns = _hm.our_functions(objpath, our_exe, syms, base)
            self.naming = "full" if self.ournames else "partial"
        except Exception:                                          # noqa: BLE001
            self.naming = "none"

    def unmasked(self, ob, ub, ova, uva):
        """Offsets inside [ob] where harness.compare finds a difference it cannot mask.

        `learn` is None on every call: a diagnostic must never teach the helper table a
        name and then use it to make its own output look clean
        (docs/reference/codegen-patterns.md 13.1).
        """
        hits, base = [], 0
        while base < len(ob) and len(hits) < MAX_ADJUDICATE:
            o, u = ob[base:], ub[base:]
            if o == u:
                break
            try:
                _m, _s, _t, _msk, first = H.compare(
                    o, u, self.ospan, self.uspan,
                    (self.opath, ova + base), (self.upath, uva + base),
                    ournames=self.ournames, origtab=self.origtab,
                    learn=None, ourfns=self.ourfns)
            except Exception:                                      # noqa: BLE001
                first = next((i for i, (x, y) in enumerate(zip(o, u)) if x != y), -1)
            if first is None or first < 0:
                break
            hits.append(base + first)
            base += first + 1
        return hits


# ---------------------------------------------------------------------- rendering

def _dis(ins, i1, i2, va, context):
    lines = []
    for k in range(max(0, i1 - context), min(len(ins), i2 + context)):
        x = ins[k]
        lines.append("  %s +%-5d %08X  %-23s %s"
                     % (">>" if i1 <= k < i2 else "  ", x.off, va + x.off,
                        " ".join("%02X" % b for b in x.bytes)[:23], x.text()))
    return "\n".join(lines)


def _extent(ins, i1, i2, total):
    """(byte offset, byte length) of instructions [i1,i2) -- 0 length for an empty range."""
    if i1 >= i2:
        return (ins[i1].off if i1 < len(ins) else total), 0
    return ins[i1].off, ins[i2 - 1].off + ins[i2 - 1].size - ins[i1].off


# ------------------------------------------------------------------------- core

def _localise(ob, ova, ub, uva, ctx, label, context=6, max_gaps=12):
    o_ins, u_ins = _decode(ob, ova), _decode(ub, uva)
    o_keys = [_key(i.bytes, ctx.ospan) for i in o_ins]
    u_keys = [_key(i.bytes, ctx.uspan) for i in u_ins]

    sm = difflib.SequenceMatcher(None, o_keys, u_keys, autojunk=False)
    gaps, subs = [], []
    branch_shifts = 0
    first_div = None

    for tag, i1, i2, j1, j2 in sm.get_opcodes():
        ooff, olen = _extent(o_ins, i1, i2, len(ob))
        uoff, ulen = _extent(u_ins, j1, j2, len(ub))

        if tag == "equal":
            # Aligned 1:1. Adjudicate each differing instruction with the real oracle.
            for k in range(i2 - i1):
                a, c = o_ins[i1 + k], u_ins[j1 + k]
                if a.bytes == c.bytes:
                    continue
                rf = _rel_field(a.bytes)
                if rf and a.bytes[:rf[0]] == c.bytes[:rf[0]] \
                        and a.bytes[rf[0] + rf[1]:] == c.bytes[rf[0] + rf[1]:]:
                    # differs ONLY inside the displacement
                    if a.bytes[0] in (0xE8, 0xE9) or (len(a.bytes) == 6):
                        pass                     # may still be a wrong callee -> adjudicate
                    if ctx.unmasked(a.bytes, c.bytes, ova + a.off, uva + c.off):
                        branch_shifts += 1
                    continue
                if not ctx.unmasked(a.bytes, c.bytes, ova + a.off, uva + c.off):
                    continue
                if first_div is None:
                    first_div = a.off
                subs.append({"orig_off": a.off, "size": a.size,
                             "orig": "%08X  %-23s %s" % (
                                 ova + a.off,
                                 " ".join("%02X" % b for b in a.bytes)[:23], a.text()),
                             "ours": "%08X  %-23s %s" % (
                                 uva + c.off,
                                 " ".join("%02X" % b for b in c.bytes)[:23], c.text())})
            continue

        if first_div is None:
            first_div = ooff
        if olen == ulen:
            # Same byte count, different instructions: still a real finding, but not a
            # length error. Adjudicate the whole block so relocation noise is excluded.
            if not ctx.unmasked(ob[ooff:ooff + olen], ub[uoff:uoff + ulen],
                                ova + ooff, uva + uoff):
                continue
            subs.append({"orig_off": ooff, "size": olen, "block": True,
                         "orig": _dis(o_ins, i1, i2, ova, 0),
                         "ours": _dis(u_ins, j1, j2, uva, 0)})
            continue

        gaps.append({
            "kind": tag, "delta": ulen - olen,
            "orig_off": ooff, "orig_len": olen, "orig_va": ova + ooff,
            "our_off": uoff, "our_len": ulen, "our_va": uva + uoff,
            "orig_disasm": _dis(o_ins, i1, i2, ova, context),
            "our_disasm": _dis(u_ins, j1, j2, uva, context),
        })

    gaps.sort(key=lambda g: -abs(g["delta"]))
    acc = sum(g["delta"] for g in gaps)
    res = {
        "target": label,
        "orig_va": ova, "our_va": uva,
        "orig_len": len(ob), "our_len": len(ub), "delta": len(ub) - len(ob),
        "naming": ctx.naming,
        "gaps": gaps[:max_gaps], "gap_count": len(gaps),
        "subs": subs[:max_gaps], "sub_count": len(subs),
        "branch_shifts": branch_shifts,
        "delta_accounted": acc,
        "delta_explained": acc == len(ub) - len(ob),
        "first_divergence": first_div,
    }
    if not gaps and not subs:
        res["verdict"] = ("CLEAN -- byte-identical modulo the oracle's masks"
                          if len(ob) == len(ub) else
                          "NO GAPS FOUND but lengths differ -- report this, it is a bug")
    elif not gaps:
        res["verdict"] = "SAME LENGTH; %d real byte difference(s)" % len(subs)
    else:
        res["verdict"] = ("%d length-changing gap(s), %+d bytes total"
                          % (len(gaps), acc))
    return res


# ---------------------------------------------------------------------- entries

def localise(tname, mname, our_exe, context=6, max_gaps=12, workdir=None):
    """Localise a TYPE METHOD. `our_exe` is any probe exe containing it."""
    a = _bm.find_method(_bm.ORIG, tname, mname)
    c = _bm.find_method(our_exe, tname, mname)
    if not a:
        return {"error": "%s.%s not found in NSS5.exe" % (tname, mname)}
    if not c:
        return {"error": "%s.%s not found in %s" % (tname, mname, our_exe)}
    if a["length_source"] != "ghidra":
        return {"error": "original length for %s.%s is not Ghidra-authoritative (%s)"
                         % (tname, mname, a["length_source"])}
    ctx = _Ctx(our_exe, workdir)
    return _localise(a["bytes"], a["va"], c["bytes"], c["va"], ctx,
                     "%s.%s" % (tname, mname), context, max_gaps)


def localise_function(orig_va, our_exe, name=None, our_va=None, workdir=None,
                      context=6, max_gaps=12):
    """Localise a MODULE-LEVEL Function, which has no reflection record.

    The original is identified by VA (its callers' target), with the length from Ghidra.
    Ours is found by the mangled symbol `_bb_<name>` unless `our_va` is given outright.
    """
    if isinstance(orig_va, str):
        orig_va = int(orig_va, 16 if orig_va.lower().startswith("0x") else 10)
    n = _bm.ghidra_sizes().get(orig_va)
    if not n:
        return {"error": "0x%08X is not in Ghidra's inventory" % orig_va}
    ob = H._fn_bytes(_bm.ORIG, orig_va, n)
    if ob is None:
        return {"error": "0x%08X +%d is not wholly inside NSS5.exe" % (orig_va, n)}

    wd = workdir or os.path.dirname(os.path.abspath(our_exe))
    if our_va is None:
        if not name:
            return {"error": "give either our_va= or name= so the probe side can be found"}
        try:
            objdir = os.path.join(wd, ".bmx")
            objs = [os.path.join(objdir, f) for f in os.listdir(objdir)
                    if f.endswith(".o")]
            objpath = max(objs, key=os.path.getsize)
            syms = _hm.object_symbols(objpath)
            base = _hm.resolve_base(objpath, our_exe, syms)
            off = syms.get("_bb_" + name)
            if base is None or off is None:
                return {"error": "could not locate _bb_%s in %s" % (name, our_exe)}
            our_va = base + off
        except Exception as ex:                                    # noqa: BLE001
            return {"error": "symbol lookup failed: %s: %s" % (type(ex).__name__, ex)}
    b, va2off = H._exe(our_exe)
    our_n = _bm.epilogue_len(b, va2off(our_va))
    ub = H._fn_bytes(our_exe, our_va, our_n)
    if ub is None:
        return {"error": "could not read our body at 0x%08X" % our_va}
    ctx = _Ctx(our_exe, wd)
    return _localise(ob, orig_va, ub, our_va, ctx,
                     "%s @ 0x%08X" % (name or "Function", orig_va), context, max_gaps)


def _no_learn(fn, *a, **kw):
    """Run a probe build with learning off. A diagnostic must not teach itself."""
    old = H.NO_LEARN
    H.NO_LEARN = True
    try:
        return fn(*a, **kw)
    finally:
        H.NO_LEARN = old


def localise_body(tname, mname, body, context=6, max_gaps=12, keep=False):
    """Build a probe from `body` (BODY-ONLY text) and localise it in one call."""
    r = _no_learn(H.try_method, tname, mname, body, keep=True)
    if r.get("status") in ("BUILD_FAIL", "ERROR", "UNCERTAIN_LEN"):
        return {"error": "%s: %s" % (r["status"], r.get("message", "")[:800]),
                "workdir": r.get("workdir")}
    exe = os.path.join(r["workdir"], "probe.exe")
    out = localise(tname, mname, exe, context, max_gaps, workdir=r["workdir"])
    out["oracle_status"] = r.get("status")
    out["oracle_mode"] = r.get("mode")
    out["workdir"] = r["workdir"]
    if not keep:
        import shutil
        shutil.rmtree(r["workdir"], ignore_errors=True)
    return out


def localise_function_body(name, sig, body, orig_va, decl=None, context=6, max_gaps=12,
                           keep=False):
    """try_function's twin: build the probe, then localise the module Function."""
    r = _no_learn(H.try_function, name, sig, body, orig_va, keep=True, decl=decl)
    if r.get("status") in ("BUILD_FAIL", "ERROR", "UNCERTAIN_LEN"):
        return {"error": "%s: %s" % (r["status"], r.get("message", "")[:800]),
                "workdir": r.get("workdir")}
    exe = os.path.join(r["workdir"], "probe.exe")
    our_va = int(r["our_va"], 16) if isinstance(r.get("our_va"), str) else r.get("our_va")
    out = localise_function(orig_va, exe, name=name, our_va=our_va,
                            workdir=r["workdir"], context=context, max_gaps=max_gaps)
    out["oracle_status"] = r.get("status")
    out["oracle_mode"] = r.get("mode")
    out["workdir"] = r["workdir"]
    if not keep:
        import shutil
        shutil.rmtree(r["workdir"], ignore_errors=True)
    return out


# ---------------------------------------------------------------------- report

def report(r):
    if "error" in r:
        return "ERROR: " + r["error"]
    L = []
    L.append("%s   orig 0x%08X %d bytes   ours 0x%08X %d bytes   delta %+d"
             % (r["target"], r["orig_va"], r["orig_len"],
                r["our_va"], r["our_len"], r["delta"]))
    L.append("verdict : %s" % r["verdict"])
    L.append("naming  : %s   (E8 operands mask by name only when this is 'full')"
             % r["naming"])
    if r["first_divergence"] is not None:
        L.append("first real divergence at ORIGINAL offset +%d (0x%X)"
                 % (r["first_divergence"], r["first_divergence"]))
    if r["gaps"]:
        L.append("delta accounted for by gaps: %+d of %+d  -> %s"
                 % (r["delta_accounted"], r["delta"],
                    "COMPLETE" if r["delta_explained"] else
                    "INCOMPLETE, something else is also wrong"))
    if r["branch_shifts"]:
        L.append("branch displacement shifts: %d (an arithmetic consequence of the gaps)"
                 % r["branch_shifts"])
    L.append("")
    for n, g in enumerate(r["gaps"]):
        L.append("---- GAP %d/%d  %s  %+d bytes  at ORIGINAL +%d (0x%08X)"
                 % (n + 1, r["gap_count"], g["kind"], g["delta"],
                    g["orig_off"], g["orig_va"]))
        L.append("     original %d bytes here, ours %d" % (g["orig_len"], g["our_len"]))
        L.append("  -- ORIGINAL --")
        L.append(g["orig_disasm"] or "     (nothing -- ours has extra code here)")
        L.append("  -- OURS --")
        L.append(g["our_disasm"] or "     (nothing -- ours is missing code here)")
        L.append("")
    if r["gap_count"] > len(r["gaps"]):
        L.append("(%d further gaps not shown; raise --max-gaps)"
                 % (r["gap_count"] - len(r["gaps"])))
    for n, s in enumerate(r["subs"]):
        L.append("---- SUB %d/%d  same length, real difference at ORIGINAL +%d"
                 % (n + 1, r["sub_count"], s["orig_off"]))
        L.append("  orig: " + s["orig"])
        L.append("  ours: " + s["ours"])
    if r["sub_count"] > len(r["subs"]):
        L.append("(%d further substitutions not shown)" % (r["sub_count"] - len(r["subs"])))
    return "\n".join(L)


# ------------------------------------------------------------------------- CLI

def _body_of(path):
    import assemble as A
    text = open(path, encoding="utf-8", errors="replace").read()
    stripped, gdecls = H.split_globals(text)
    mo = A.BODY_RX.search(stripped)
    raw = mo.group(3) if mo else stripped
    body = "\n".join(l for l in raw.split("\n") if not l.lstrip().startswith("'"))
    return ("\n".join(gdecls) + "\n" + body) if gdecls else body


def main():
    a = sys.argv[1:]
    if not a or a[0] in ("-h", "--help"):
        print(__doc__)
        return 0

    def opt(flag, default=None):
        return a[a.index(flag) + 1] if flag in a else default

    context = int(opt("--context", 6))
    max_gaps = int(opt("--max-gaps", 12))
    as_json = "--json" in a
    exe = opt("--exe")
    va = opt("--va")
    name = opt("--name")
    sig = opt("--sig")
    decl = opt("--decl")
    pos = [x for i, x in enumerate(a)
           if not x.startswith("--") and (i == 0 or a[i - 1] not in
                                          ("--exe", "--va", "--name", "--sig", "--decl",
                                           "--context", "--max-gaps", "--our-va"))]

    if va:
        if exe:
            r = localise_function(va, exe, name=name, our_va=opt("--our-va"),
                                  context=context, max_gaps=max_gaps)
        else:
            if not (name and sig and pos):
                print("--va without --exe needs --name, --sig and a body file")
                return 2
            r = localise_function_body(name, sig, _body_of(pos[0]), va, decl=decl,
                                       context=context, max_gaps=max_gaps)
    else:
        if not pos or "." not in pos[0]:
            print("give Type.Method (or --va for a module Function). --help for more.")
            return 2
        tname, mname = pos[0].split(".", 1)
        if exe:
            r = localise(tname, mname, exe, context=context, max_gaps=max_gaps)
        else:
            src = pos[1] if len(pos) > 1 else os.path.join(
                RECOVERED, "%s.%s.bmx" % (tname, mname))
            if not os.path.exists(src):
                print("no body file: " + src)
                return 2
            r = localise_body(tname, mname, _body_of(src),
                              context=context, max_gaps=max_gaps)

    print(json.dumps(r, indent=1) if as_json else report(r))
    return 0 if not r.get("error") else 1


if __name__ == "__main__":
    sys.exit(main())
