#!/usr/bin/env python
r"""Verify that every String literal in src/recovered matches NSS5.exe. A permanent gate.

WHY THIS CANNOT BE LEFT TO THE ORACLE
=====================================
`harness.try_method` certifies a body by comparing its bytes against the original's, with
four documented masks applied. One of those masks is **absolute data addresses**: a string
literal reaches the code only as an immediate holding the .data address of a BBString, and
the two images place their BBStrings at different addresses, so the operand MUST be masked
or nothing with a literal in it could ever match.

The consequence is structural, not incidental:

    mov eax, 0x00C72AA4      ' original -> "PASS"
    mov eax, 0x005E1234      ' ours     -> "XXXX"

masks to `mov eax, <addr>` on both sides and the oracle returns MATCH. A MATCH therefore
certifies the SHAPE of a literal (that one exists at that point) and nothing whatsoever
about its CONTENT. `"Select Club"`, `"Xelect Club"` and `"AAAAAAAAAAA"` are all equally
byte-identical to the oracle; so, in fact, are literals of different lengths, because the
address is one dword either way. Every literal in the corpus is unverified by construction
and several were plainly guessed -- some recovered headers even say so in prose
("placeholders used").

The exe is authoritative. `harness.read_string(va)` decodes a BBString out of .data
(`[class][refs][length][UTF-16 chars]`, text at +12, length in CHARACTERS), so the real
text IS recoverable. This script closes the loop: for each recovered body it disassembles the
ORIGINAL at its VA, collects every immediate operand that points at a BBString, decodes it,
and compares that multiset against the literals lexed out of our source. Whenever the two
disagree, OUR SOURCE IS WRONG.

Signature used to recognise a BBString reference (all four must hold, which is why raw
address scanning does not produce false positives):
    dword[va+0] == 0x005C7D60   (bbStringClass in NSS5.exe)
    dword[va+4] in {0x7FFFFFFF, 0x40000000}   (the two immortal refcounts -- compiler-
                                emitted literals use 0x7FFFFFFF; the runtime's shared
                                bbEmptyString at 0x005C7D40, which is what `""` lowers to,
                                uses 0x40000000. Missing the second one made every
                                `Local s:String = ""` look like a spurious source literal.)
    dword[va+8] == char count, and the UTF-16 payload lies inside the image

Usage
-----
    python scripts/check_literals.py                 # gate: exits 1 on any disagreement
    python scripts/check_literals.py --verbose       # show every per-file difference
    python scripts/check_literals.py --files A.bmx B.bmx
    python scripts/check_literals.py --json out.json
    python scripts/check_literals.py --order         # the ORDER mode, below
    python scripts/check_literals.py --order --modfns          # module-level Functions
    python scripts/check_literals.py --order --limit-seconds 900 --max-bytes 2000
    python scripts/check_literals.py --order --files TBall.SetUpSetPieceBall.bmx

Statuses
--------
    OK              multisets identical (includes files with no literals at all)
    COUNT           different NUMBER of literal references
    CONTENT         same count, different text
    ENCODING        text agrees, but the literal cannot SURVIVE THE BUILD (see below)
    NO_VA           header has no parsable `VA 0x...` -- cannot be checked
    NO_SIZE         VA present but no byte count and none in Ghidra's inventory

--order: THE ORDER BLIND SPOT THIS MULTISET COMPARE STRUCTURALLY CANNOT SEE
==========================================================================
Everything above compares a MULTISET. Two DISTINCT literals swapped between two call sites
therefore PASS it, and pass the oracle too (a literal reaches the code only as a masked
address). The exposure is exactly the files with >= 2 distinct literal texts, measured at
400 of 1628. A file with 0 or 1 distinct text is swap-immune by construction.

WHY SOURCE ORDER IS NOT THE ANSWER. Let f be the permutation bcc applies to literal
positions when it lowers source to code (arguments are pushed right-to-left, so f is
genuinely non-identity). Our body MATCHes the original byte for byte, so the code STRUCTURE
is identical and f is the SAME map on both sides. Correctness is therefore
f(ours) == original_code_order, which is NOT the same question as
ours == original_code_order. Comparing source sequences answers the wrong one.

The sound method is to make f observable: build the body, disassemble OURS and the ORIGINAL,
key every BBString-referencing operand by its CODE OFFSET, and require the same text at the
same offset. Equal length is the precondition that makes the offsets correspond -- which a
MATCH gives for free.

    --order            src/recovered Type methods, through harness.try_method
    --order --modfns   src/recovered_module Functions, through harness.try_function

`--modfns` is the same method over the other tree, and it needs its own flag rather than
being folded into the same sweep because module-level Functions have no reflection record:
try_method cannot reach them at all, and their VA and length come from the file's own
header. Without that sweep the 13 files in that tree stay unproved for placement.

Order statuses: PROVED (every offset pairs, same text, same mnemonic) / DIFF (a real swap) /
LEN_DIFF (body length differs from the original's -- cannot pair) / ORACLE_MISMATCH /
NO_HEADER (--modfns, no parsable VA/length/sig line) / ERROR.

In --order mode `--files` names files INSIDE the tree being swept (bare `TBall.Foo.bmx`),
not paths, because both sweeps join it onto their own tree.

THE ENCODING CHECK
==================
Comparing our SOURCE text against the exe is necessary but not sufficient: the source still
has to reach the compiler intact. `harness.py` (probes) and `assemble.py` (the whole-program
build) must not write BlitzMax source with `encoding="latin-1", errors="replace"`. Latin-1
covers U+00A3 POUND SIGN as byte 0xA3, so `"£"` survives, but it cannot represent U+20AC
EURO SIGN, and `errors="replace"` then turns `"€ EUR"` into `"? EUR"` before bcc ever sees
it.

Such a substitution is invisible to the multiset check, which reads the .bmx as UTF-8 and
finds the correct character sitting in the file. Only pairing literals by CODE OFFSET
against a compiled probe catches it. The code bytes still match, because a literal reaches
the code only as a masked address -- so the emitted program is corrupt while every
byte-level check reports success: the same structural blind spot as the literal gate
itself, one level further down.

THE CURE IS THE SOURCE ENCODING. `_src/compiler/toker.cpp:302` selects among
LATIN1/UTF8/UTF16BE/UTF16LE and picks UTF8 only on an `EF BB BF` BOM, so both writers use
`encoding="utf-8-sig"`. Controlled A/B on `TScreen_Options.CreateScreen`, which holds
`"$ USD"`, `"£ GBP"` and `"€ EUR"`: MATCH 8290/8290 under BOTH encodings (as expected -- the
address is one dword either way), and the probe's own `.data` holds

    latin-1    '? EUR'   U+003F U+0020 U+0045 U+0055 U+0052
    utf-8-sig  '€ EUR'   U+20AC U+0020 U+0045 U+0055 U+0052

The check is still needed, because a limit exists one level lower: bcc's `tgetc()` decodes 1-,
2- and 3-byte UTF-8 and `return 0` for a lead byte >= 0xF0, so an astral codepoint
(> U+FFFF) would reach bcc as NUL. Nothing in NSS5.exe is astral today; the check is what
keeps that true.
"""

import argparse
import collections
import glob
import json
import os
import re
import sys
import time

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(ROOT, "scripts"))
os.environ.setdefault("NSS5_WORKER", "check_literals")

import bytematch as _bytematch          # noqa: E402
import harness                          # noqa: E402

RECOVERED = os.path.join(ROOT, "src", "recovered")
MODULE_FNS = os.path.join(ROOT, "src", "recovered_module")
RECOVERED_DIRS = [RECOVERED, MODULE_FNS]

# src/recovered_thirdparty/<module>/*.bmx (zipengine, fontmachine) is ONE level deeper
# than the two dirs above, so it needs its own glob rather than RECOVERED_DIRS's flat
# os.listdir. TFontMachineVersion.Version shows what is at stake: a guessed literal
# ("Font Machine 1.5.1", the only Font-Machine-prefixed string in the exe) MATCHes the
# oracle at 14/14 while being the wrong BBString -- the real one is "Untitled 0.0.1". A file
# this glob does not reach is a file this gate cannot protect.
THIRDPARTY_GLOB = os.path.join(ROOT, "src", "recovered_thirdparty", "*", "*.bmx")

BBSTRING_CLASS = 0x005C7D60
IMMORTAL_REFS = (0x7FFFFFFF, 0x40000000)

# The encoding harness.py and assemble.py write BlitzMax source in. A literal that does not
# round-trip through it is destroyed on its way to bcc -- see the module docstring.
#
# "utf-8-sig" is what closes the latin-1 hole. With both writers on it, the binding limit
# is bcc's own UTF-8 decoder rather than the writer's: toker.cpp:330 handles 1-, 2- and
# 3-byte sequences and `return 0` for anything with a lead byte >= 0xF0. So every BMP
# codepoint reaches bcc, and any astral codepoint (> U+FFFF) is turned into NUL.
BUILD_ENCODING = "utf-8-sig"
BCC_MAX_CODEPOINT = 0xFFFF


def survives_build(s):
    """True if `s` reaches bcc intact through the build's source encoding.

    Two gates, because the writer and the reader disagree about what is expressible:
    Python must be able to encode it, and bcc's tgetc() must be able to decode it.
    """
    try:
        s.encode(BUILD_ENCODING)
    except UnicodeEncodeError:
        return False
    return all(ord(c) <= BCC_MAX_CODEPOINT for c in s)

# Three header dialects are in the tree: the documented `' VA 0x004CC5E2   98 bytes`,
# `' VA=0x0050D54B  LEN=110`, and `' VA 0x00508FB1   length 414` (5 files).
# Accept all three rather than rewrite other passes' files.
_VA_RE = re.compile(r"\bVA[=\s]\s*0x([0-9A-Fa-f]{6,8})")
_BYTES_RE = re.compile(r"(\d+)\s*bytes\b|\bLEN=(\d+)|\blength\s+(\d+)")


# ---------------------------------------------------------------- the original side
_STR_CACHE = {}


def string_at(va):
    """Decoded literal at `va`, or None if `va` is not a BBString literal in NSS5.exe.

    Empty-string references (`Return ""`) point at the shared immortal BBString whose
    length is 0; harness.read_string rejects those, so the header is decoded here and the
    non-empty case is delegated rather than reimplemented.
    """
    if va in _STR_CACHE:
        return _STR_CACHE[va]
    out = None
    b, va2off = harness._exe(_bytematch.ORIG)
    o = va2off(va)
    if 0 <= o and o + 12 <= len(b):
        cls = int.from_bytes(b[o:o + 4], "little")
        refs = int.from_bytes(b[o + 4:o + 8], "little")
        ln = int.from_bytes(b[o + 8:o + 12], "little")
        if cls == BBSTRING_CLASS and refs in IMMORTAL_REFS and ln < 4096 \
                and o + 12 + ln * 2 <= len(b):
            out = "" if ln == 0 else harness.read_string(va)
    _STR_CACHE[va] = out
    return out


_CS = []


def _cs():
    if not _CS:
        import capstone
        md = capstone.Cs(capstone.CS_ARCH_X86, capstone.CS_MODE_32)
        md.detail = True
        _CS.append((md, capstone))
    return _CS[0]


def original_literals(va, nbytes):
    """Ordered list of literals referenced by the original function body at `va`.

    Literal references are always IMMEDIATES in bcc output (`push imm32`,
    `mov reg,imm32`, `mov [mem],imm32`); memory displacements are also examined because
    they cost nothing -- the four-part BBString signature is what rejects non-literals,
    not the operand kind.
    """
    md, capstone = _cs()
    b, va2off = harness._exe(_bytematch.ORIG)
    off = va2off(va)
    if off < 0 or off + nbytes > len(b):
        return None
    out = []
    for ins in md.disasm(b[off:off + nbytes], va):
        cand = []
        for op in ins.operands:
            if op.type == capstone.x86.X86_OP_IMM:
                cand.append(op.imm & 0xFFFFFFFF)
            elif op.type == capstone.x86.X86_OP_MEM and op.mem.base == 0 \
                    and op.mem.index == 0:
                cand.append(op.mem.disp & 0xFFFFFFFF)
        for v in cand:
            s = string_at(v)
            if s is not None:
                out.append(s)
    return out


# ---------------------------------------------------------------- our side
_ESCAPES = {"q": '"', "n": "\n", "t": "\t", "r": "\r", "0": "\0", "~": "~"}


_PRAGMA = re.compile(r"^[ \t]*'!\s*(?:Field|Global|Raw)\b")


def source_literals(text):
    """Ordered list of BlitzMax String literals in `text`, comments excluded.

    Hand-lexed rather than regexed because a `'` inside a string does not start a comment
    and a `~q` inside a string does not end it.

    `'!Field` / `'!Global` / `'!Raw` lines look like comments but are NOT: harness.py
    lifts them into real declarations and they generate code. `'!Field colour = "FFFF00"`
    is the only place a Type's default field initialiser can be recorded, and bcc emits
    that initialiser inside the Type declaration ahead of every body statement -- so a
    New() whose literals live in field defaults has them here or nowhere.
    """
    out = []
    for line in text.split("\n"):
        if _PRAGMA.match(line):
            line = line.replace("'!", "  ", 1)     # lex the pragma as source
        i, n = 0, len(line)
        while i < n:
            c = line[i]
            if c == "'":
                break                      # rest of line is a comment
            if c != '"':
                i += 1
                continue
            i += 1
            buf = []
            while i < n and line[i] != '"':
                if line[i] == "~" and i + 1 < n:
                    buf.append(_ESCAPES.get(line[i + 1], line[i + 1]))
                    i += 2
                else:
                    buf.append(line[i])
                    i += 1
            i += 1                         # closing quote (or end of line)
            out.append("".join(buf))
    return out


def encode_literal(s):
    """BlitzMax source spelling of `s`, with the escapes bcc understands."""
    out = []
    for ch in s:
        if ch == "~":
            out.append("~~")
        elif ch == '"':
            out.append("~q")
        elif ch == "\n":
            out.append("~n")
        elif ch == "\r":
            out.append("~r")
        elif ch == "\t":
            out.append("~t")
        elif ch == "\0":
            out.append("~0")
        else:
            out.append(ch)
    return '"' + "".join(out) + '"'


# ---------------------------------------------------------------- per-file check
def header_va_size(text):
    va = size = None
    for line in text.split("\n"):
        if not line.lstrip().startswith("'"):
            break
        m = _VA_RE.search(line)
        if m and va is None:
            va = int(m.group(1), 16)
        m = _BYTES_RE.search(line)
        if m and size is None:
            size = int(m.group(1) or m.group(2) or m.group(3))
    return va, size


def check_file(path):
    text = open(path, encoding="utf-8", errors="replace").read()
    rec = {"file": os.path.relpath(path, ROOT).replace("\\", "/"),
           "status": "OK", "va": None, "bytes": None,
           "orig": [], "ours": [], "missing": [], "extra": []}
    va, size = header_va_size(text)
    if va is None:
        rec["status"] = "NO_VA"
        rec["ours"] = source_literals(text)
        return rec
    rec["va"] = "0x%08X" % va
    # GHIDRA'S INVENTORY IS THE AUTHORITY ON LENGTH, NOT THE HEADER.
    # The header is prose a pass wrote, and prose about codegen is full of byte counts
    # that are not THIS function's length. Reasoning text like "`If g = Null` is 9 bytes
    # shorter" or "6 bytes short" scrapes out as a 9- or 6-byte window in front of real
    # functions of 414 and 581 bytes. That is the worst failure a gate can have: such a
    # window contains no literal references, so the file reports OK while being entirely
    # unchecked. Taking the length from the
    # inventory removes the whole class; the header is only a fallback, and a disagreement
    # is reported rather than silently resolved.
    inv = _bytematch.ghidra_sizes().get(va)
    if inv and size and inv != size:
        rec["header_bytes"] = size
        rec["note"] = "header claims %d bytes, Ghidra inventory says %d; using %d" \
                      % (size, inv, inv)
    size = inv or size
    if not size:
        rec["status"] = "NO_SIZE"
        return rec
    rec["bytes"] = size
    orig = original_literals(va, size)
    if orig is None:
        rec["status"] = "NO_SIZE"
        return rec
    ours = source_literals(text)
    rec["orig"], rec["ours"] = orig, ours
    # The EMPTY string is deliberately not compared. It has no content to get wrong, and
    # a reference to the shared bbEmptyString is emitted by four different source forms
    # that are indistinguishable in the bytes: `Return ""`, `Local s:String = ""`, a bare
    # `Local s:String` (implicit default init), and bcc's automatic initialisation of
    # every String Field inside New(). Counting it produces 30 false alarms in both
    # directions across the corpus and cannot ever produce a true one.
    co = collections.Counter(x for x in orig if x != "")
    cu = collections.Counter(x for x in ours if x != "")
    # Reported even when the multisets agree: the text being RIGHT in the .bmx is exactly
    # the case where this defect hides, because every other check then passes.
    rec["unencodable"] = sorted({x for x in orig if x and not survives_build(x)})
    if co == cu:
        if rec["unencodable"]:
            rec["status"] = "ENCODING"
        return rec
    missing = co - cu                      # in the exe, absent from our source
    extra = cu - co                        # in our source, absent from the exe
    rec["missing"] = sorted(missing.elements())
    rec["extra"] = sorted(extra.elements())
    rec["status"] = "CONTENT" if sum(co.values()) == sum(cu.values()) else "COUNT"
    return rec


# ---------------------------------------------------------------- the --order mode
FUNC_HDR = re.compile(r"^\s*Function\s+\w+[^(\n]*\(([^)]*)\)", re.M)
MODFN_HDR_RE = re.compile(r"VA\s+0x([0-9A-Fa-f]{6,8})\s+(\d+)\s*bytes\s+sig\s+(\S+)")


def lits_by_offset(md, capstone, buf, va, resolve):
    """offset -> (literal, mnemonic) for every operand in `buf` pointing at a BBString."""
    out = {}
    for ins in md.disasm(buf, va):
        for op in ins.operands:
            v = None
            if op.type == capstone.x86.X86_OP_IMM:
                v = op.imm & 0xFFFFFFFF
            elif op.type == capstone.x86.X86_OP_MEM and op.mem.base == 0 \
                    and op.mem.index == 0:
                v = op.mem.disp & 0xFFFFFFFF
            if v is None:
                continue
            s = resolve(v)
            if s is not None:
                out[ins.address - va] = (s, ins.mnemonic)
    return out


def our_string_at(exe, va, ourcls):
    """The BBString signature test again, against OUR probe image."""
    b, va2off = harness._exe(exe)
    o = va2off(va)
    if o < 0 or o + 12 > len(b):
        return None
    if int.from_bytes(b[o + 4:o + 8], "little") not in IMMORTAL_REFS:
        return None
    ln = int.from_bytes(b[o + 8:o + 12], "little")
    if ln >= 4096 or o + 12 + ln * 2 > len(b):
        return None
    # bbStringClass sits at a DIFFERENT address in every probe -- each is a separately
    # linked image. Caching it across files makes our side resolve zero literals and
    # reports clean files as DIFF. It is recomputed per file, hence the parameter.
    if int.from_bytes(b[o:o + 4], "little") != ourcls:
        return None
    return b[o + 12:o + 12 + ln * 2].decode("utf-16-le", "replace")


def modal_string_class(md, capstone, exe, blob, va):
    """The most common class word among immortal-refcount targets in our probe body.

    On a body with only 2-3 literals, an unrelated operand (a Global address,
    a jump-table entry, a plain integer constant) can coincidentally satisfy the loose
    "refcount word looks immortal" test at whatever 4 bytes follow it, and its class word --
    often 0x00000000, since that is what an unrelated zero-initialised dword reads as -- then
    outvotes the real bbStringClass. Measured on UpdateAudio.bmx: candidates are
    {0x00000000: 10, 0x00565D20 (the probe's real class): 6}, so a modal pick over that set
    is wrong and every genuine literal in the body is then rejected by our_string_at's class
    check, reporting paired=0/6 -- the signature of a whole sweep of DIFFs at paired=0.
    Requiring the LENGTH field to be sane too (the same bound string_at already enforces on
    the original side) rejects that class of coincidence without weakening a real match,
    because a genuine BBString's length always satisfies it.
    """
    cnt = collections.Counter()
    bb, v2o = harness._exe(exe)
    for ins in md.disasm(blob, va):
        for op in ins.operands:
            if op.type != capstone.x86.X86_OP_IMM:
                continue
            o = v2o(op.imm & 0xFFFFFFFF)
            if o < 0 or o + 12 > len(bb):
                continue
            if int.from_bytes(bb[o + 4:o + 8], "little") not in IMMORTAL_REFS:
                continue
            ln = int.from_bytes(bb[o + 8:o + 12], "little")
            if ln >= 4096 or o + 12 + ln * 2 > len(bb):
                continue
            cls = int.from_bytes(bb[o:o + 4], "little")
            # A REAL class word is a pointer to a class-table structure inside the image and
            # can never be 0. Class-0 "hits" are always the same coincidence: an operand that
            # is really an unrelated address (Null-object compare was the measured case on
            # UpdateAudio.bmx -- 0x00567C40, hit 10 times, sitting in front of zero .bss bytes
            # that happen to read refs=0x40000000/len=0) outvoting the true class, which on a
            # short body may have only a handful of genuine references. Reject it outright;
            # a genuine literal's class is never the null pointer.
            if cls == 0:
                continue
            cnt[cls] += 1
    return cnt.most_common(1)[0][0] if cnt else None


def pair_offsets(ol, ul):
    """-> (paired, bad) for the two offset -> (literal, mnemonic) maps."""
    bad, paired = [], 0
    for off, (s, mn) in sorted(ol.items()):
        if off not in ul:
            bad.append({"off": off, "orig": s, "ours": None})
        elif ul[off][1] != mn:
            bad.append({"off": off, "orig": s, "ours": ul[off][0],
                        "mnemonic": [mn, ul[off][1]]})
        elif ul[off][0] != s:
            bad.append({"off": off, "orig": s, "ours": ul[off][0]})
        else:
            paired += 1
    return paired, bad


def exposed_files(d):
    """Files in `d` with >= 2 DISTINCT non-empty literals in the exe -- the whole exposure."""
    out = []
    for fn in sorted(os.listdir(d)):
        if not fn.endswith(".bmx"):
            continue
        if d == RECOVERED and "." not in fn[:-4]:
            continue
        rec = check_file(os.path.join(d, fn))
        lits = [x for x in rec["orig"] if x != ""]
        if len(set(lits)) >= 2 and rec["status"] == "OK":
            out.append((fn, len(set(lits)), len(lits), rec["bytes"] or 0))
    return out


def order_methods(args, md, capstone):
    """--order over src/recovered, through harness.try_method."""
    # Imported HERE and not at the top of the module. reverify pulls in assemble.py (for
    # BODY_RX) and sets NSS5_NO_LEARN in the environment as it loads, and this file is the
    # permanent literal gate that every worker runs: the default path must not start
    # importing the whole assembler to answer a question about strings. Only --order needs
    # body_of, so only --order pays for it.
    import reverify as R

    if args.files:
        work = [(f, 0, 0, 0) for f in args.files]
    else:
        work = [w for w in exposed_files(RECOVERED) if w[3] <= args.max_bytes]
        # cheapest first: the point is maximum files proved per minute of build time.
        work.sort(key=lambda t: t[3])
    print("%d exposed files to prove" % len(work), flush=True)

    results, t0 = [], time.time()
    for i, (fn, ndist, nlit, nb) in enumerate(work):
        if time.time() - t0 > args.limit_seconds:
            print("time limit reached after %d files" % i)
            break
        rec = {"file": fn, "distinct": ndist, "refs": nlit, "bytes": nb, "status": "?"}
        try:
            text = open(os.path.join(RECOVERED, fn), encoding="utf-8",
                        errors="replace").read()
            tname, mname = fn[:-4].split(".", 1)
            r = harness.try_method(tname, mname, R.body_of(text), keep=True)
            rec["oracle"] = "%s %s/%s" % (r.get("status"), r.get("matched"),
                                          r.get("orig_len"))
            if r.get("orig_len") != r.get("our_len"):
                rec["status"] = "LEN_DIFF"
                results.append(rec)
                continue
            if r.get("status") != "MATCH":
                # Equal LENGTH is not equal BYTES. The argument for pairing by
                # code offset ("f is the same map on both sides") depends on the two bodies
                # being byte-identical -- a MISMATCH that happens to compile to the same
                # length can still have every literal operand line up by pure coincidence
                # while the surrounding code differs, which is a false PROVED on a body that
                # law 1 says must never be banked at all. TScreen_MatchPrep.SetUpScreen.bmx
                # is the demonstration: oracle MISMATCH 3812/5081 (first_diff=2509), yet
                # 5081==5081 would carry it to PROVED on a length test alone.
                # Report it as its own status instead of either PROVED or the unrelated
                # LEN_DIFF bucket.
                rec["status"] = "ORACLE_MISMATCH"
                results.append(rec)
                continue
            exe = os.path.join(r["workdir"], "probe.exe")
            a = _bytematch.find_method(_bytematch.ORIG, tname, mname)
            c = _bytematch.find_method(exe, tname, mname)
            ourcls = modal_string_class(md, capstone, exe, c["bytes"], c["va"])
            ol = lits_by_offset(md, capstone, a["bytes"], a["va"], string_at)
            ul = lits_by_offset(md, capstone, c["bytes"], c["va"],
                                lambda v: our_string_at(exe, v, ourcls))
            paired, bad = pair_offsets(ol, ul)
            rec["paired"], rec["bad"] = paired, bad
            rec["status"] = "PROVED" if not bad and len(ul) == len(ol) else "DIFF"
        except Exception as exc:                                        # noqa: BLE001
            rec["status"] = "ERROR"
            rec["err"] = str(exc)[:200]
        results.append(rec)
        print("%4d/%d %-9s %-52s %s" % (i + 1, len(work), rec["status"], fn,
                                        rec.get("oracle", "")), flush=True)
        if args.json:
            json.dump(results, open(args.json, "w", encoding="utf-8"),
                      indent=1, ensure_ascii=False)

    tally = collections.Counter(r["status"] for r in results)
    print("\n%d files, %.0fs" % (len(results), time.time() - t0))
    for k, v in tally.most_common():
        print("  %-9s %d" % (k, v))
    return 1 if tally.get("DIFF") else 0


def module_body(text):
    """try_function()/build_source_function() supply their OWN `Function name(...)` header
    and trailing `End Function` -- unlike harness.module_functions() (which emits OTHER
    functions verbatim so they can be called), the TARGET here must be handed just the
    interior statements. Strip plain comments (keep '!Global/'!Raw so try_function's own
    split_globals sees them), de-indent one level, then peel the header/trailer line off.

    The file declares its OWN parameter names (`Function KitColour:String(idx:Int)`), but
    build_source_function regenerates them positionally as a0, a1, ... (same trap
    reverify.body_of documents for try_method) -- rename here or a body using `idx` fails
    to compile with "Identifier 'idx' not found", indistinguishable from a broken body."""
    lines = [l for l in text.split("\n")
             if (not l.lstrip().startswith("'")) or l.lstrip().startswith("'!")]
    body = "\n".join(lines).strip()
    body = "\n".join(l[1:] if l.startswith("\t") else l for l in body.split("\n"))
    m = FUNC_HDR.search(body)
    if m:
        start = body.index("\n", m.end()) + 1
        end = body.rindex("End Function")
        interior = body[start:end]
        names = [p.split(":")[0].strip().split()[-1]
                 for p in m.group(1).split(",") if p.strip()]
        for i, n in enumerate(names):
            if n and n != "a%d" % i and n.isidentifier():
                interior = re.sub(r"\b%s\b" % re.escape(n), "a%d" % i, interior)
        body = interior
    return body


def module_header(text):
    """-> (va, length, signature) off a module Function file's own header comment."""
    for line in text.split("\n"):
        if not line.lstrip().startswith("'"):
            break
        m = MODFN_HDR_RE.search(line)
        if m:
            return int(m.group(1), 16), int(m.group(2)), m.group(3)
    return None, None, None


def order_modfns(args, md, capstone):
    """--order --modfns over src/recovered_module, through harness.try_function."""
    if args.files:
        work = [(f, 0, 0, 0) for f in args.files]
    else:
        work = sorted(exposed_files(MODULE_FNS), key=lambda t: t[3])
    print("%d exposed module functions to prove" % len(work), flush=True)

    results = []
    for fn, _nd, _nl, _nb in work:
        path = os.path.join(MODULE_FNS, fn)
        text = open(path, encoding="utf-8", errors="replace").read()
        va, size, sig = module_header(text)
        name = fn[:-4]
        rec = {"file": fn, "status": "?"}
        if va is None:
            rec["status"] = "NO_HEADER"
            results.append(rec)
            print("%-9s %-40s" % (rec["status"], fn))
            continue
        r = harness.try_function(name, sig, module_body(text), va, keep=True)
        rec["oracle"] = "%s %s/%s" % (r.get("status"), r.get("matched"), r.get("orig_len"))
        if r.get("status") != "MATCH":
            rec["status"] = "NOT_MATCH"
            results.append(rec)
            print("%-9s %-40s %s" % (rec["status"], fn, rec["oracle"]))
            continue
        exe = os.path.join(r["workdir"], "probe.exe")
        our_va = int(r["our_va"], 16)
        n = r["orig_len"]
        ab = harness._fn_bytes(_bytematch.ORIG, va, n)
        cb = harness._fn_bytes(exe, our_va, n)
        ourcls = modal_string_class(md, capstone, exe, cb, our_va)
        ol = lits_by_offset(md, capstone, ab, va, string_at)
        ul = lits_by_offset(md, capstone, cb, our_va,
                            lambda v: our_string_at(exe, v, ourcls))
        paired, bad = pair_offsets(ol, ul)
        rec["paired"], rec["bad"] = paired, bad
        rec["status"] = "PROVED" if not bad and len(ul) == len(ol) else "DIFF"
        results.append(rec)
        print("%-9s %-40s %s  paired=%d/%d"
              % (rec["status"], fn, rec["oracle"], paired, len(ol)))

    if args.json:
        json.dump(results, open(args.json, "w", encoding="utf-8"),
                  indent=1, ensure_ascii=False)
    tally = collections.Counter(r["status"] for r in results)
    print()
    for k, v in tally.most_common():
        print("  %-9s %d" % (k, v))
    return 1 if tally.get("DIFF") else 0


def order_check(args):
    """--order: prove literal PLACEMENT, not just presence. Both trees enter here."""
    # A VERIFICATION RUN MUST NOT TEACH ITSELF A NAME, and setting the environment variable
    # here is too late to say so: harness snapshots it into H.NO_LEARN at IMPORT time
    # (harness.py:69), and this module imports harness at the top, long before any flag is
    # parsed. A standalone script gets it for free by setting the variable ABOVE its own
    # imports; a mode inside check_literals cannot, so it assigns the attribute the way
    # localise_diff.py does around its own compare. The environment is set too, for anything
    # spawned from here.
    harness.NO_LEARN = True
    os.environ["NSS5_NO_LEARN"] = "1"
    md, capstone = _cs()
    if args.modfns:
        return order_modfns(args, md, capstone)
    return order_methods(args, md, capstone)


def main():
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    ap.add_argument("--files", nargs="*", help="specific .bmx paths (default: whole tree); "
                                               "with --order, bare names inside the tree")
    ap.add_argument("--verbose", "-v", action="store_true")
    ap.add_argument("--json", help="write full per-file results here")
    ap.add_argument("--quiet", "-q", action="store_true", help="summary only")
    ap.add_argument("--order", action="store_true",
                    help="prove literal PLACEMENT by pairing operands by code offset")
    ap.add_argument("--modfns", action="store_true",
                    help="with --order: src/recovered_module Functions instead")
    ap.add_argument("--limit-seconds", type=float, default=1e9,
                    help="--order only: stop after this many seconds of building")
    ap.add_argument("--max-bytes", type=int, default=10 ** 9,
                    help="--order only: skip bodies longer than this")
    args = ap.parse_args()

    if args.order:
        return order_check(args)

    if args.files:
        paths = [os.path.abspath(p) for p in args.files]
    else:
        paths = []
        for d in RECOVERED_DIRS:
            if os.path.isdir(d):
                paths += [os.path.join(d, f) for f in sorted(os.listdir(d))
                          if f.endswith(".bmx")]
        paths += sorted(glob.glob(THIRDPARTY_GLOB))

    results = [check_file(p) for p in paths]
    tally = collections.Counter(r["status"] for r in results)
    bad = [r for r in results if r["status"] in ("CONTENT", "COUNT", "ENCODING")]

    if not args.quiet:
        for r in bad:
            print("%-8s %-52s %s" % (r["status"], os.path.basename(r["file"]), r["va"]))
            if args.verbose or r["status"] == "ENCODING":
                for s in r.get("missing", []):
                    print("      exe has, source lacks : %s" % encode_literal(s))
                for s in r.get("extra", []):
                    print("      source has, exe lacks : %s" % encode_literal(s))
                for s in r.get("unencodable", []):
                    print("      destroyed by the %s source write : %s  (%s)"
                          % (BUILD_ENCODING, encode_literal(s),
                             " ".join("U+%04X" % ord(c) for c in s if ord(c) > 127)))

    n_lit = sum(len(r["orig"]) for r in results)
    print("\n%d files checked, %d literal references in the exe" % (len(results), n_lit))
    for k in ("OK", "CONTENT", "COUNT", "ENCODING", "NO_VA", "NO_SIZE"):
        if tally.get(k):
            print("  %-8s %d" % (k, tally[k]))

    if args.json:
        with open(args.json, "w", encoding="utf-8") as fh:
            json.dump(results, fh, indent=1, ensure_ascii=False)

    return 1 if bad else 0


if __name__ == "__main__":
    sys.exit(main())
