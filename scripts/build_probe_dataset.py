#!/usr/bin/env python3
"""
build_probe_dataset.py -- rebuild a COMPLETE method->address->size table for the
game module, then emit it as a joined TSV for probeability classification.

Fixes a staleness bug: extracted/vtable_map.tsv was generated from an older
object_model.json and is missing 15 types entirely, including TPlayer (134
methods, the core match-engine entity).

Output: extracted/probe_dataset.tsv
"""
import csv
import importlib.util
import json
import os
import struct
from collections import defaultdict

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
LO, HI = 0x857000, 0x86D000          # game module file-offset window
ABSTRACT_STUB = 0x005B95AC
DATA_SECTIONS = (".data", "data", ".rdata")
CODE_SECTIONS = (".text", "code")

spec = importlib.util.spec_from_file_location(
    "rv", os.path.join(ROOT, "scripts", "resolve_vtables.py"))
rv = importlib.util.module_from_spec(spec)
spec.loader.exec_module(rv)


def resolve_all(img, model):
    """Return {type: classtable_va} for every scope we can validate."""
    scope_va = {}
    for e in model:
        va = img.off2va(e["at"])
        if va is not None:
            scope_va[e["type"]] = va

    wanted = defaultdict(list)
    for t, va in scope_va.items():
        wanted[va].append(t)

    cands = defaultdict(list)
    for name, base, vsz, ro, rsz in img.secs:
        if name not in DATA_SECTIONS or not rsz:
            continue
        blob = img.data[ro:ro + rsz]
        for off in range(0, len(blob) - 3, 4):
            v = struct.unpack_from("<I", blob, off)[0]
            if v in wanted:
                for t in wanted[v]:
                    cands[t].append(base + off)

    tables = {}
    for e in model:
        t = e["type"]
        maxf = max([m["offset"] for m in e["members"] if m["kind"] == "Field"],
                   default=4)
        for ref in cands.get(t, []):
            cb = ref - 8
            sup, free, isz = img.rd32(cb), img.rd32(cb + 4), img.rd32(cb + 12)
            if (img.section_of(sup) in DATA_SECTIONS
                    and img.section_of(free) in CODE_SECTIONS
                    and isz is not None and maxf < isz < 8192):
                tables[t] = cb
                break
    return tables


def main():
    img = rv.Image(os.path.join(ROOT, "binary", "NSS5.exe"))
    model = json.load(open(os.path.join(ROOT, "extracted", "object_model.json"),
                           encoding="utf-8"))
    tables = resolve_all(img, model)

    # Ghidra function inventory: address -> (size, called_by, calls)
    ginv = {}
    with open(os.path.join(ROOT, "extracted", "ghidra", "function_inventory.tsv"),
              encoding="utf-8") as fh:
        for r in csv.DictReader(fh, delimiter="\t"):
            ginv[int(r["addr"], 16)] = (int(r["size"]),
                                        int(r["called_by_count"]),
                                        int(r["calls_count"]))

    # prior cold-call emulation verdicts (stale set, joined where present)
    sweep = {}
    p = os.path.join(ROOT, "extracted", "emu_sweep.tsv")
    if os.path.exists(p):
        for r in csv.DictReader(open(p, encoding="utf-8"), delimiter="\t"):
            sweep[(r["type"], r["name"], r["sig"])] = (r["verdict"], r["eax"])

    game = [e for e in model if LO <= e["at"] < HI]
    out = []
    for e in game:
        t = e["type"]
        cb = tables.get(t)
        nfields = sum(1 for m in e["members"] if m["kind"] == "Field")
        for m in e["members"]:
            if m["kind"] not in ("Method", "Function"):
                continue
            va = img.rd32(cb + m["offset"]) if cb else None
            if va == ABSTRACT_STUB:
                status, size, cby, cls = "ABSTRACT", 0, 0, 0
            elif va and img.section_of(va) in CODE_SECTIONS:
                status = "OK"
                size, cby, cls = ginv.get(va, (-1, -1, -1))
            else:
                status, size, cby, cls = "UNRESOLVED", -1, -1, -1
            v, eax = sweep.get((t, m["name"], m["sig"]), ("", ""))
            out.append(dict(type=t, kind=m["kind"], name=m["name"], sig=m["sig"],
                            slot=m["offset"], va=("0x%08x" % va) if va else "",
                            status=status, size=size, called_by=cby, calls=cls,
                            nfields=nfields, sweep=v, eax=eax))

    dst = os.path.join(ROOT, "extracted", "probe_dataset.tsv")
    with open(dst, "w", encoding="utf-8", newline="\n") as fh:
        w = csv.DictWriter(fh, fieldnames=list(out[0].keys()), delimiter="\t",
                           lineterminator="\n")
        w.writeheader()
        w.writerows(out)

    print("game scopes            : %d" % len(game))
    print("methods+functions      : %d" % len(out))
    print("  resolved to code     : %d" % sum(1 for r in out if r["status"] == "OK"))
    print("  abstract stub        : %d" % sum(1 for r in out if r["status"] == "ABSTRACT"))
    print("  unresolved           : %d" % sum(1 for r in out if r["status"] == "UNRESOLVED"))
    print("  with Ghidra size     : %d" % sum(1 for r in out if r["size"] > 0))
    print("  with prior sweep row : %d" % sum(1 for r in out if r["sweep"]))
    print("total code bytes       : %d" % sum(r["size"] for r in out if r["size"] > 0))
    print("wrote %s" % dst)


if __name__ == "__main__":
    main()
