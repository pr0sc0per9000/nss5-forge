#!/usr/bin/env python3
"""
resolve_vtables.py -- turn the recovered object model into code addresses.

Input : binary/NSS5.exe
        extracted/object_model.json      (337 types, members with slot offsets)
Output: extracted/vtable_map.tsv         (type, kind, name, sig, slot, VA, status)
        extracted/class_tables.tsv       (type, classtable VA, super VA, super name, instance size)

Technique (verified against NSS5.exe):
  1. object_model.json "at" is a FILE OFFSET of the BBDebugScope record. Convert to VA.
  2. Scan the initialised data sections for a dword equal to that VA. That dword is the
     BBClass.debugscope member, which sits at classtable+8.
  3. Validate the candidate: classtable+0 (super) must point into data, classtable+4
     (free fn) must point into code, classtable+12 (instance size) must be sane and
     strictly greater than the highest declared field offset. Two types have a
     coincidental false-positive dword, so validation is mandatory, not optional.
  4. code_addr = *(classtable + member.offset) for every Method and Function.

BBClass layout (32-bit, legacy BlitzMax):
  +0x00 BBClass* super
  +0x04 void (*free)(BBObject*)
  +0x08 BBDebugScope* debugscope
  +0x0c int instance_size
  +0x10 New            <- first slot named by the debug scope
  +0x14 Delete
  +0x18 ToString
  +0x1c Compare
  +0x20 SendMessage
  +0x24..0x2c reserved runtime slots
  +0x30 first user-declared method/function slot
"""

import json
import os
import struct
import sys
from collections import defaultdict

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
EXE = os.path.join(ROOT, "binary", "NSS5.exe")
OBJ_MODEL = os.path.join(ROOT, "extracted", "object_model.json")
OUT_MAP = os.path.join(ROOT, "extracted", "vtable_map.tsv")
OUT_CLASSES = os.path.join(ROOT, "extracted", "class_tables.tsv")

# Address of the shared "abstract method called" thrower. Any slot pointing here
# is an Abstract declaration with NO body to recover.
ABSTRACT_STUB = 0x005B95AC

DATA_SECTIONS = (".data", "data", ".rdata")
CODE_SECTIONS = (".text", "code")


def load_pe(path):
    data = open(path, "rb").read()
    pe = struct.unpack_from("<I", data, 0x3C)[0]
    if data[pe:pe + 4] != b"PE\0\0":
        raise SystemExit("not a PE file: %s" % path)
    nsec = struct.unpack_from("<H", data, pe + 6)[0]
    optsz = struct.unpack_from("<H", data, pe + 20)[0]
    opt = pe + 24
    imgbase = struct.unpack_from("<I", data, opt + 28)[0]
    secs = []
    so = opt + optsz
    for i in range(nsec):
        o = so + i * 40
        name = data[o:o + 8].rstrip(b"\0").decode("latin1")
        vsz, va, rsz, ro = struct.unpack_from("<IIII", data, o + 8)
        secs.append((name, va + imgbase, vsz, ro, rsz))
    return data, imgbase, secs


class Image(object):
    def __init__(self, path):
        self.data, self.imgbase, self.secs = load_pe(path)

    def off2va(self, off):
        for name, base, vsz, ro, rsz in self.secs:
            if ro and ro <= off < ro + rsz:
                return base + (off - ro)
        return None

    def va2off(self, va):
        if va is None:
            return None
        for name, base, vsz, ro, rsz in self.secs:
            if base <= va < base + vsz:
                d = va - base
                if d < rsz:
                    return ro + d
        return None

    def section_of(self, va):
        if va is None:
            return "OUT"
        for name, base, vsz, ro, rsz in self.secs:
            if base <= va < base + vsz:
                return name
        return "OUT"

    def rd32(self, va):
        off = self.va2off(va)
        if off is None or off + 4 > len(self.data):
            return None
        return struct.unpack_from("<I", self.data, off)[0]


def main():
    img = Image(EXE)
    model = json.load(open(OBJ_MODEL, encoding="utf-8"))

    scope_va = {}
    for entry in model:
        va = img.off2va(entry["at"])
        if va is None:
            print("WARN: cannot map scope file offset %#x for %s" % (entry["at"], entry["type"]))
            continue
        scope_va[entry["type"]] = va

    # Reverse index: scope VA -> every data location holding that pointer.
    wanted = defaultdict(list)
    for tname, va in scope_va.items():
        wanted[va].append(tname)
    candidates = defaultdict(list)
    for name, base, vsz, ro, rsz in img.secs:
        if name not in DATA_SECTIONS or not rsz:
            continue
        blob = img.data[ro:ro + rsz]
        for off in range(0, len(blob) - 3, 4):
            v = struct.unpack_from("<I", blob, off)[0]
            if v in wanted:
                for tname in wanted[v]:
                    candidates[tname].append(base + off)

    by_name = {e["type"]: e for e in model}
    class_table = {}
    for tname, entry in by_name.items():
        max_field = max([m["offset"] for m in entry["members"] if m["kind"] == "Field"], default=4)
        for ref in candidates.get(tname, []):
            cb = ref - 8
            super_ptr = img.rd32(cb)
            free_fn = img.rd32(cb + 4)
            isize = img.rd32(cb + 12)
            if (img.section_of(super_ptr) in DATA_SECTIONS
                    and img.section_of(free_fn) in CODE_SECTIONS
                    and isize is not None and max_field < isize < 8192):
                class_table[tname] = cb
                break

    cb2type = {cb: t for t, cb in class_table.items()}

    rows = []
    for entry in model:
        tname = entry["type"]
        cb = class_table.get(tname)
        for m in entry["members"]:
            if m["kind"] not in ("Method", "Function"):
                continue
            if cb is None:
                rows.append((tname, m["kind"], m["name"], m["sig"], m["offset"], None, "NO_CLASSTABLE"))
                continue
            addr = img.rd32(cb + m["offset"])
            sect = img.section_of(addr)
            if addr == ABSTRACT_STUB:
                status = "ABSTRACT"
            elif sect in CODE_SECTIONS:
                status = "OK"
            else:
                status = "BAD_SECTION:" + sect
            rows.append((tname, m["kind"], m["name"], m["sig"], m["offset"], addr, status))

    with open(OUT_MAP, "w", encoding="utf-8", newline="\n") as fh:
        fh.write("type\tkind\tname\tsig\tslot\tva\tstatus\n")
        for t, k, n, s, slot, addr, status in rows:
            fh.write("%s\t%s\t%s\t%s\t0x%02x\t%s\t%s\n"
                     % (t, k, n, s, slot, ("0x%08x" % addr) if addr else "", status))

    with open(OUT_CLASSES, "w", encoding="utf-8", newline="\n") as fh:
        fh.write("type\tclasstable_va\tsuper_va\tsuper_type\tinstance_size\n")
        for tname in sorted(class_table):
            cb = class_table[tname]
            sup = img.rd32(cb)
            fh.write("%s\t0x%08x\t0x%08x\t%s\t%d\n"
                     % (tname, cb, sup, cb2type.get(sup, "Object(runtime)"), img.rd32(cb + 12)))

    ok = sum(1 for r in rows if r[6] == "OK")
    abstract = sum(1 for r in rows if r[6] == "ABSTRACT")
    bad = len(rows) - ok - abstract
    uniq = len(set(r[5] for r in rows if r[6] == "OK"))
    print("types            : %d / %d class tables resolved" % (len(class_table), len(model)))
    print("slots            : %d total" % len(rows))
    print("  resolved (OK)  : %d  (%d distinct addresses)" % (ok, uniq))
    print("  abstract stub  : %d  (no body exists)" % abstract)
    print("  unresolved     : %d" % bad)
    print("wrote %s" % OUT_MAP)
    print("wrote %s" % OUT_CLASSES)
    return 0 if bad == 0 else 1


if __name__ == "__main__":
    sys.exit(main())
