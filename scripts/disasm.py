#!/usr/bin/env python3
"""Minimal PE reader + capstone disassembler for NSS5.exe.

Usage:  python disasm.py 0x004CF671 [count]
        python disasm.py --ret 0x004CF671      # walk to first ret, report ret imm16
        python disasm.py --sections
"""
import os
import sys, struct
from capstone import Cs, CS_ARCH_X86, CS_MODE_32

_NSS5_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
EXE = os.path.join(_NSS5_ROOT, 'binary/NSS5.exe')

class PE:
    def __init__(self, path):
        self.data = open(path, 'rb').read()
        d = self.data
        e_lfanew = struct.unpack_from('<I', d, 0x3C)[0]
        assert d[e_lfanew:e_lfanew+4] == b'PE\0\0'
        coff = e_lfanew + 4
        self.machine, self.nsect, _, _, _, self.opt_size, self.chars = \
            struct.unpack_from('<HHIIIHH', d, coff)
        opt = coff + 20
        self.magic = struct.unpack_from('<H', d, opt)[0]
        self.image_base = struct.unpack_from('<I', d, opt+28)[0]
        self.entry = struct.unpack_from('<I', d, opt+16)[0]
        st = opt + self.opt_size
        self.sections = []
        for i in range(self.nsect):
            o = st + i*40
            name = d[o:o+8].rstrip(b'\0').decode('latin1')
            vsize, vaddr, rsize, raddr = struct.unpack_from('<IIII', d, o+8)
            flags = struct.unpack_from('<I', d, o+36)[0]
            self.sections.append(dict(name=name, vsize=vsize, vaddr=vaddr,
                                      rsize=rsize, raddr=raddr, flags=flags))

    def va2off(self, va):
        rva = va - self.image_base
        for s in self.sections:
            if s['vaddr'] <= rva < s['vaddr'] + max(s['vsize'], s['rsize']):
                off = rva - s['vaddr'] + s['raddr']
                if off < len(self.data):
                    return off
        return None

    def off2va(self, off):
        for s in self.sections:
            if s['raddr'] <= off < s['raddr'] + s['rsize']:
                return off - s['raddr'] + s['vaddr'] + self.image_base
        return None

    def read(self, va, n):
        o = self.va2off(va)
        if o is None:
            return None
        return self.data[o:o+n]


def disas(pe, va, count=40):
    md = Cs(CS_ARCH_X86, CS_MODE_32)
    code = pe.read(va, count*16)
    out = []
    for i in md.disasm(code, va):
        out.append((i.address, i.bytes.hex(), i.mnemonic, i.op_str))
        if len(out) >= count:
            break
    return out


def walk_to_ret(pe, va, limit=4000):
    """Linear sweep from va, record every ret encountered (crude but fine
    for reporting stack cleanup convention on straight-line-ending funcs)."""
    md = Cs(CS_ARCH_X86, CS_MODE_32)
    code = pe.read(va, limit)
    rets = []
    n = 0
    for i in md.disasm(code, va):
        n += 1
        if i.mnemonic == 'ret':
            rets.append((i.address, i.op_str))
        if i.mnemonic in ('ret',) and len(rets) > 6:
            break
    return rets, n


if __name__ == '__main__':
    pe = PE(EXE)
    a = sys.argv[1:]
    if not a or a[0] == '--sections':
        print(f"image_base=0x{pe.image_base:08X} entry_va=0x{pe.image_base+pe.entry:08X}")
        for s in pe.sections:
            print(f"  {s['name']:<8} VA 0x{pe.image_base+s['vaddr']:08X} "
                  f"vsize 0x{s['vsize']:X} raw 0x{s['raddr']:X} rsize 0x{s['rsize']:X} "
                  f"flags 0x{s['flags']:08X}")
        sys.exit(0)
    if a[0] == '--ret':
        for tgt in a[1:]:
            va = int(tgt, 0)
            rets, n = walk_to_ret(pe, va)
            print(f"{tgt}: {n} insns swept, rets: " +
                  ", ".join(f"0x{r[0]:08X} ret {r[1] or '(0)'}" for r in rets[:8]))
        sys.exit(0)
    va = int(a[0], 0)
    cnt = int(a[1]) if len(a) > 1 else 40
    for addr, b, m, o in disas(pe, va, cnt):
        print(f"0x{addr:08X}  {b:<20} {m} {o}")
