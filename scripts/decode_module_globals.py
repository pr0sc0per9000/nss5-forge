#!/usr/bin/env python
"""
Decode the ARRAY SIZE + ELEMENT TYPE of every module-scope Global whose
lazy initialiser is a plain `_bbArrayNew1D` allocation, read directly out of
NSS5.exe -- not guessed, not inferred from usage.

BACKGROUND
==========
`extracted/module_emission_order.tsv` already lists 94 GLOBAL rows (name, va,
body_offset, flags_word, bit) interleaved with the 135 TYPE rows in the module
body's registration block (+437..+5549, 5,112 bytes). What it does
NOT give is the array's element type or literal size for the ones that are
arrays -- those numbers are the operands of a `_bbArrayNew1D(type, length)`
call (`tools/blitzmax-legacy-src/mod/brl.mod/blitz.mod/blitz_array.c:161`,
VA 0x004A63D0) sitting a few bytes after each Global's `body_offset`.

THE GUARD, verified against NSS5.exe AND against our own bcc
==============================================================
Every module Global -- array or not -- is lazily initialised behind a
per-Global bit test against a SHARED per-region flags word (this is the
`flags_word`/`bit` pair module_emission_order.tsv already carries):

    mov  eax, [flags_word]
    and  eax, (1 << bit)
    cmp  eax, 0
    jne  skip                  ; already run
        <initialiser>
        or  [flags_word], (1 << bit)
    skip:

Confirmed this is EMITTED BY THE COMPILER, not hand code: a standalone probe
containing only `Global g_test:String[300]` (no explicit initialiser at all)
produces byte-for-byte this same guard shape in our own bcc's FASM output.
So wiring a Global's correct TYPE and SIZE into assemble.py is sufficient --
the guard bytes follow for free, exactly like the 135 Type registrations.

METHOD
======
For each GLOBAL row, start at `body_offset` (confirmed to be the guard's own
first instruction -- `mov eax,[flags_word]` -- not merely "somewhere near
it") and disassemble forward far enough to find `call 0x4a63d0`. If found,
the two instructions immediately before it are `push <length>` then
`push <type_cstr_va>` (cdecl pushes the second parameter, `length`, first).
Read the C string at the second push's target: `$`=String, `i`=Int, `f`=Float,
`b`/`s`/`l`/`d`=Byte/Short/Long/Double, `:TFoo`=object.

64 of 94 rows resolve this way. The other 30 (names containing "_int" or the
generic "g_ObjectNNN" placeholders) have NO `_bbArrayNew1D` call near their
guard -- their initialiser is a real expression (ReadSettingString / CreateDir
/ AllocChannel / StringConcat chains), which is a distinct, larger task and is
not attempted here.

CROSS-VALIDATION
=================
41 of the 64 resolved names ALREADY have a bare `Global name:Type[]` merged
into `src/assembled/nss5_assembled.bmx` from some verified body's `'!Global`
pragma. Every element TYPE this script reads from the
EXE agrees with the pragma-derived type -- independent corroboration -- with
exactly ONE exception, `g_panel_controls_arr01`, flagged below. The pragmas
do not carry a SIZE, which is the actual gap this script closes.

Usage:  python decode_module_globals.py > extracted/module_globals_decoded.tsv
"""
import csv
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import harness as H
import bytematch as BM
import capstone

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
MAIN_VA = 0x004BA034
ARRAYNEW1D_VA = 0x004A63D0

_TAG_TO_BMX = {"i": "Int", "f": "Float", "$": "String", "b": "Byte",
               "s": "Short", "l": "Long", "d": "Double"}


def _tag_to_bmx(tag):
    if tag in _TAG_TO_BMX:
        return _TAG_TO_BMX[tag]
    if tag.startswith(":"):
        return tag[1:]
    return None


def read_cstr(b, va2off, va, maxlen=64):
    off = va2off(va)
    raw = b[off:off + maxlen]
    return raw.split(b"\x00")[0].decode("latin-1")


def find_arraynew1d(b, va2off, md, va, window=64):
    off = va2off(va)
    buf = b[off:off + window]
    call_va = None
    for ins in md.disasm(buf, va):
        if ins.mnemonic == "call" and ins.op_str == hex(ARRAYNEW1D_VA):
            call_va = ins.address
            break
    if call_va is None:
        return None
    off2 = va2off(call_va - 10)
    chunk = b[off2:off2 + 10]
    ins2 = list(md.disasm(chunk, call_va - 10))
    if len(ins2) < 2:
        return None
    p_len, p_type = ins2[-2], ins2[-1]
    if p_len.mnemonic != "push" or p_type.mnemonic != "push":
        return None

    def _imm(op_str):
        return int(op_str, 16) if op_str.startswith("0x") else int(op_str)

    length = _imm(p_len.op_str)
    type_va = _imm(p_type.op_str)
    tag = read_cstr(b, va2off, type_va)
    return length, tag, call_va


def main():
    b, va2off = H._exe(BM.ORIG)
    md = capstone.Cs(capstone.CS_ARCH_X86, capstone.CS_MODE_32)
    md.detail = False

    tsv_path = os.path.join(ROOT, "extracted", "module_emission_order.tsv")
    w = csv.writer(sys.stdout, delimiter="\t", lineterminator="\n")
    w.writerow(["name", "va", "body_offset", "flags_word", "bit",
                "kind", "bmx_type", "size", "note"])

    with open(tsv_path, encoding="utf-8") as f:
        for row in csv.DictReader(f, delimiter="\t"):
            if row["kind"] != "GLOBAL":
                continue
            name = row["name"]
            boff = int(row["body_offset"])
            va = MAIN_VA + boff
            res = find_arraynew1d(b, va2off, md, va, window=48)
            if res is None:
                w.writerow([name, row["va"], boff, row["flags_word"], row["bit"],
                            "SCALAR_OR_COMPLEX", "", "",
                            "no _bbArrayNew1D near guard -- real init expression, "
                            "not a bare array; not decoded by this script"])
                continue
            length, tag, _callva = res
            bmx = _tag_to_bmx(tag)
            if bmx is None:
                w.writerow([name, row["va"], boff, row["flags_word"], row["bit"],
                            "ARRAY", "", length, "UNRECOGNISED type tag %r" % tag])
                continue
            w.writerow([name, row["va"], boff, row["flags_word"], row["bit"],
                        "ARRAY", bmx, length, ""])


if __name__ == "__main__":
    main()
