#!/usr/bin/env python3
"""emu_probe.py -- call NSS5.exe functions inside a Unicorn x86-32 emulator.

Proof-of-concept for the probing proposal: no game process, no Steam, no GC,
no runtime init at all. The PE image is mapped at its preferred base, a stack
is synthesised, arguments are pushed under the (verified) cdecl convention and
the function is executed to its `ret`.

Return marshalling:
  i / :TFoo / $ / []X  -> EAX
  f / d                -> ST(0)   (read out of the FPU save area)
  l                    -> hidden out-pointer, first slot after self

Usually imported as a library (`from emu_probe import Emu`). It also carries one
mode of its own:

    python scripts/emu_probe.py --sweep            # cold-call every resolved body
    python scripts/emu_probe.py --sweep 200        # ... the first 200 only

--sweep tries to call every resolved method/function with zero runtime
initialisation and classifies what happens, which measures the size of the
"callable with no live game" subset. It writes extracted/emu_sweep.tsv, which
build_probe_dataset.py joins in when it is present.
"""
import collections, csv, os, struct, sys, time
_NSS5_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from disasm import PE
from unicorn import *
from unicorn.x86_const import *

EXE = os.path.join(_NSS5_ROOT, 'binary/NSS5.exe')
MAGIC_RET = 0x0F000000          # sentinel return address
STACK_BASE = 0x02000000
STACK_SIZE = 0x00100000
HEAP_BASE = 0x03000004          # deliberately NOT 16-byte aligned: legacy
HEAP_SIZE = 0x00100000          # tstMemBit() ignores such pointers entirely
PAGE = 0x1000

# Immortal singletons the compiler baked into the image, reused as probe values
# so the sweep never has to allocate one of them.
STRING_CLASS = 0x005C7D60
EMPTY_STRING = 0x005C7D40
NULL_OBJECT = 0x005C9C80
EMPTY_ARRAY = 0x005C7C00
INSN_CAP = 300_000              # a cold call that runs this long is not returning


def align_down(x):
    return x & ~(PAGE - 1)


def align_up(x):
    return (x + PAGE - 1) & ~(PAGE - 1)


class Emu:
    def __init__(self, exe=EXE):
        self.pe = PE(exe)
        self.uc = Uc(UC_ARCH_X86, UC_MODE_32)
        base = self.pe.image_base
        # map every section (virtual size), zero-filled, then blit raw data
        for s in self.pe.sections:
            va = base + s['vaddr']
            size = align_up(max(s['vsize'], s['rsize']))
            lo, hi = align_down(va), align_up(va + size)
            try:
                self.uc.mem_map(lo, hi - lo)
            except UcError:
                pass  # overlapping page already mapped
            if s['rsize']:
                self.uc.mem_write(va, self.pe.data[s['raddr']:s['raddr'] + s['rsize']])
        # PE headers page (some code reads the image base)
        try:
            self.uc.mem_map(align_down(base), PAGE)
            self.uc.mem_write(base, self.pe.data[:PAGE])
        except UcError:
            pass
        self.uc.mem_map(STACK_BASE, STACK_SIZE)
        self.uc.mem_map(HEAP_BASE & ~(PAGE - 1), HEAP_SIZE)
        self.uc.mem_map(MAGIC_RET, PAGE)
        self.heap = HEAP_BASE
        self.faults = []
        self.uc.hook_add(UC_HOOK_MEM_INVALID, self._badmem)

    def _badmem(self, uc, access, address, size, value, ud):
        self.faults.append((access, address, size))
        return False

    # ---- guest memory helpers -------------------------------------------
    def alloc(self, n, align=4):
        p = (self.heap + align - 1) & ~(align - 1)
        self.heap = p + n
        return p

    def rd(self, va, n):
        return self.uc.mem_read(va, n)

    def rd32(self, va):
        return struct.unpack('<I', self.rd(va, 4))[0]

    def wr32(self, va, v):
        self.uc.mem_write(va, struct.pack('<I', v & 0xFFFFFFFF))

    # ---- BlitzMax object construction -----------------------------------
    def new_object(self, classtable_va, instance_size, fields=None):
        """A bare BlitzMax object: {BBClass* clas; int refs; ...fields}.
        refs is pinned to 0x7FFFFFFF, exactly as the compiler pins the static
        String constants it bakes into the image."""
        p = self.alloc(instance_size + 16)
        self.uc.mem_write(p, b'\0' * (instance_size + 16))
        self.wr32(p + 0, classtable_va)
        self.wr32(p + 4, 0x7FFFFFFF)
        for off, val in (fields or {}).items():
            if isinstance(val, float):
                self.uc.mem_write(p + off, struct.pack('<f', val))
            else:
                self.wr32(p + off, val)
        return p

    def new_string(self, s, string_class_va):
        """BBString{ clas, refs, length, BBChar buf[] } - UTF-16LE, immortal."""
        data = s.encode('utf-16-le')
        p = self.alloc(12 + len(data) + 2)
        self.wr32(p + 0, string_class_va)
        self.wr32(p + 4, 0x7FFFFFFF)
        self.wr32(p + 8, len(s))
        self.uc.mem_write(p + 12, data + b'\0\0')
        return p

    def read_string(self, p):
        if p == 0:
            return None
        try:
            clas, refs, length = struct.unpack('<IIi', self.rd(p, 12))
        except UcError:
            return f"<unreadable @0x{p:08X}>"
        if length < 0 or length > 4096:
            return f"<bad len {length} @0x{p:08X}>"
        raw = bytes(self.rd(p + 12, length * 2))
        return raw.decode('utf-16-le', errors='replace')

    # ---- the call ---------------------------------------------------------
    def call(self, addr, args, ret='i', timeout_insns=2_000_000):
        """args: list of ('i',v) ('f',v) ('d',v) ('l',v) ('p',v).
        Returns dict with eax / st0 / long / faults."""
        uc = self.uc
        self.faults = []
        sp = STACK_BASE + STACK_SIZE - 0x1000
        blob = b''
        longbuf = None
        for kind, v in args:
            if kind == 'f':
                blob += struct.pack('<f', v)
            elif kind == 'd':
                blob += struct.pack('<d', v)
            elif kind == 'l':
                blob += struct.pack('<q', v)
            else:
                blob += struct.pack('<I', v & 0xFFFFFFFF)
        sp -= len(blob)
        sp &= ~3
        uc.mem_write(sp, blob)
        sp -= 4
        uc.mem_write(sp, struct.pack('<I', MAGIC_RET))
        for r in (UC_X86_REG_EAX, UC_X86_REG_EBX, UC_X86_REG_ECX, UC_X86_REG_EDX,
                  UC_X86_REG_ESI, UC_X86_REG_EDI):
            uc.reg_write(r, 0)
        uc.reg_write(UC_X86_REG_ESP, sp)
        uc.reg_write(UC_X86_REG_EBP, STACK_BASE + STACK_SIZE - 0x800)
        err = None
        try:
            uc.emu_start(addr, MAGIC_RET, count=timeout_insns)
        except UcError as e:
            err = str(e)
        out = dict(eax=uc.reg_read(UC_X86_REG_EAX), err=err,
                   faults=list(self.faults), eip=uc.reg_read(UC_X86_REG_EIP))
        if ret in ('f', 'd'):
            out['st0'] = uc.reg_read(UC_X86_REG_ST0)
        return out


def st0_to_float(raw):
    """unicorn returns ST0 as a python int holding the 80-bit value"""
    if isinstance(raw, float):
        return raw
    b = int(raw).to_bytes(10, 'little', signed=False)
    mant = int.from_bytes(b[0:8], 'little')
    se = int.from_bytes(b[8:10], 'little')
    sign = -1.0 if se & 0x8000 else 1.0
    exp = se & 0x7FFF
    if exp == 0 and mant == 0:
        return 0.0 * sign
    return sign * mant * 2.0 ** (exp - 16383 - 63)


# ---- BlitzMax signature helpers -------------------------------------------
# These were written for the calling-convention survey; they live here now
# because marshalling arguments is what they are actually for.

def split_args(sig):
    """'(i,f,:TFoo)i' -> (['i','f',':TFoo'], 'i')"""
    assert sig.startswith("(")
    depth = 0
    for i, c in enumerate(sig):
        if c == "(":
            depth += 1
        elif c == ")":
            depth -= 1
            if depth == 0:
                inner, ret = sig[1:i], sig[i+1:]
                break
    args = []
    if inner:
        depth = 0
        cur = ""
        for c in inner:
            if c == "(":
                depth += 1
            elif c == ")":
                depth -= 1
            if c == "," and depth == 0:
                args.append(cur); cur = ""
            else:
                cur += c
        args.append(cur)
    return args, ret


# ---- cold-call sweep -------------------------------------------------------

def sweep(limit=None, kinds=("Method", "Function")):
    """Try to COLD-CALL every resolved method/function and classify what happens.

    Writable sections are restored from the on-disk image before every call so
    the probes stay independent of each other.
    """
    e = Emu()
    pe = e.pe
    # snapshot writable sections
    snaps = []
    for s in pe.sections:
        if s['name'] in ('.data', 'data', '.bss'):
            va = pe.image_base + s['vaddr']
            raw = pe.data[s['raddr']:s['raddr'] + s['rsize']] if s['rsize'] else b''
            snaps.append((va, raw, max(s['vsize'], s['rsize'])))

    def restore():
        for va, raw, vsz in snaps:
            if raw:
                e.uc.mem_write(va, raw)
            if vsz > len(raw):
                e.uc.mem_write(va + len(raw), b'\0' * (vsz - len(raw)))

    classes = {}
    for r in csv.DictReader(open(os.path.join(_NSS5_ROOT, "extracted", "class_tables.tsv"),
                                 encoding="utf-8"), delimiter="\t"):
        classes[r['type']] = (int(r['classtable_va'], 16), int(r['instance_size']))

    rows = [r for r in csv.DictReader(open(os.path.join(_NSS5_ROOT, "extracted", "vtable_map.tsv"),
                                            encoding="utf-8"), delimiter="\t")
            if r['status'] == 'OK' and r['kind'] in kinds]
    if limit:
        rows = rows[:limit]

    # pre-build reusable guest values (heap grows monotonically; harmless)
    probe_str = e.new_string("1", STRING_CLASS)
    scratch = e.alloc(256, 16)

    verdicts = collections.Counter()
    detail = []
    t0 = time.time()
    for n, r in enumerate(rows):
        va = int(r['va'], 16)
        args, ret = split_args(r['sig'])
        vals = []
        skip = None
        if r['kind'] == 'Method':
            ci = classes.get(r['type'])
            if not ci:
                skip = 'NO_CLASS'
            else:
                vals.append(('i', e.new_object(ci[0], ci[1])))
        if ret == 'l':
            vals.append(('i', scratch))
        for a in args:
            if a in ('i', 'b', 's'):
                vals.append(('i', 1))
            elif a == 'f':
                vals.append(('f', 1.0))
            elif a == 'd':
                vals.append(('d', 1.0))
            elif a == 'l':
                vals.append(('l', 1))
            elif a == '$':
                vals.append(('i', probe_str))
            elif a.startswith(':'):
                nm = a[1:].split('.')[-1]
                ci = classes.get(nm)
                vals.append(('i', e.new_object(*ci) if ci else NULL_OBJECT))
            elif a.startswith('[]'):
                vals.append(('i', EMPTY_ARRAY))
            elif a.startswith('*'):
                vals.append(('i', scratch))
            elif a.startswith('('):
                vals.append(('i', 0))
            else:
                skip = 'UNSUPPORTED_ARG:' + a
                break
        if skip:
            verdicts[skip.split(':')[0]] += 1
            detail.append((r, skip, None))
            continue
        restore()
        try:
            res = e.call(va, vals, ret=ret, timeout_insns=INSN_CAP)
        except Exception as ex:
            verdicts['HARNESS_ERR'] += 1
            continue
        if res['err'] is None and res['eip'] in (MAGIC_RET, 0):
            v = 'COMPLETED'
        elif res['err'] is None:
            v = 'INSN_CAP'
        elif 'UNMAPPED' in (res['err'] or '') or 'INSN_INVALID' in (res['err'] or ''):
            v = 'FAULT'
        else:
            v = 'OTHER'
        if v == 'FAULT':
            fa = res['faults'][0][1] if res['faults'] else None
            if fa is not None and fa < 0x10000:
                v = 'FAULT_NULLDEREF'
            elif res['eip'] and not (0x00400000 <= res['eip'] < 0x00D10000):
                v = 'FAULT_WILD_JUMP'
            else:
                v = 'FAULT_OTHER'
        verdicts[v] += 1
        detail.append((r, v, res))
        if n % 250 == 0:
            print(f"  ... {n}/{len(rows)}  {time.time()-t0:.0f}s", file=sys.stderr)

    print("\n=== COLD-CALL SWEEP (no runtime init, no game process) ===")
    tot = sum(verdicts.values())
    for k, c in verdicts.most_common():
        print(f"  {k:<18} {c:5d}  ({100.0*c/tot:.1f}%)")

    # break down by kind
    per = collections.Counter()
    for r, v, res in detail:
        per[(r['kind'], v)] += 1
    print("\n  by kind:")
    for k, c in sorted(per.items()):
        print(f"    {k[0]:<9} {k[1]:<12} {c}")

    with open(os.path.join(_NSS5_ROOT, "extracted", "emu_sweep.tsv"), "w",
              encoding="utf-8", newline="\n") as fh:
        fh.write("type\tkind\tname\tsig\tva\tverdict\teax\n")
        for r, v, res in detail:
            fh.write("%s\t%s\t%s\t%s\t%s\t%s\t%s\n" % (
                r['type'], r['kind'], r['name'], r['sig'], r['va'], v,
                ("0x%08x" % res['eax']) if res else ""))
    print("\nwrote extracted/emu_sweep.tsv")


if __name__ == "__main__":
    # Nothing runs on a bare invocation: this file is first of all the library
    # every other probe script imports.
    if "--sweep" in sys.argv:
        pos = [a for a in sys.argv[1:] if not a.startswith("-")]
        sweep(limit=int(pos[0]) if pos else None)
    elif len(sys.argv) > 1:
        sys.exit("usage: emu_probe.py [--sweep [limit]]")
