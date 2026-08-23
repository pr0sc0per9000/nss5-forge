"""
Parse the BlitzMax reflection / debug-metadata tables out of NSS5.exe.

Legacy BlitzMax emits, for every Type, a scope header followed by a run of 16-byte
declaration records, terminated by a zero kind:

    BBDebugScope:
        uint32  kind          # 2 = Type scope
        char   *name          # "TBall"
        BBDebugDecl decls[]   # until kind == 0

    BBDebugDecl:              # 16 bytes
        uint32  kind          # per blitz_debug.h: 1=Const 2=Local 3=Field 4=Global 6=Method 7=Function
        char   *name          # "replayframes"
        char   *type_tag      # BlitzMax signature, e.g. "(:TPlayer,f,f,i,i)i"
        uint32  offset        # Field -> byte offset in the object; Method -> vtable slot

Field offsets give the exact in-memory layout of every Type. Offsets 0 and 4 are the
BlitzMax object header (class/vtable pointer, then GC word), so user fields start at 8.

Outputs:
    docs/specs/07-object-model.md
    extracted/object_model.json
    src/generated/types_skeleton.bmx      (BlitzMax Type skeletons)
"""

import json
import os
import re
import struct

_NSS5_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
EXE = os.path.join(_NSS5_ROOT, 'binary/NSS5.exe')
OUT_DIR = os.path.join(_NSS5_ROOT, 'extracted')
SPEC_DIR = os.path.join(_NSS5_ROOT, 'docs/specs')
GEN_DIR = os.path.join(_NSS5_ROOT, 'src/generated')

# Kind values per the official BlitzMax blitz_debug.h. An earlier version of this
# parser omitted kind 1 (Const) and had 2/4 swapped; because the decl loop breaks on
# any unrecognised kind, a single Const declaration truncated its whole Type. That
# silently dropped TPlayer -- 100 fields, 135 methods -- from the output entirely.
DECL_KIND = {1: "Const", 2: "Local", 3: "Field", 4: "Global",
             5: "Var", 6: "Method", 7: "Function"}

IDENT_RE = re.compile(r"^[A-Za-z_][A-Za-z0-9_]{0,63}$")
# A class name in a signature may be NAMESPACED -- `:brl.max2d.TImage` -- and the decl
# loop breaks on the first signature it cannot parse, so refusing the dot TRUNCATES the
# whole Type at that member. TBitMapChar lost `Image:TImage` and three methods that way,
# and TBitmapFont lost fifteen (GetFaceImage .. GetShadowBlend, slots 0x5C-0x94), which
# is every accessor the Font Machine draw path needs. Measured over the whole table the
# change is purely additive: 8 Types gain members, none loses one, and no game Type is
# affected -- all 8 are third-party or BRL Types whose fields cite a module-qualified
# name. `.` cannot appear in a signature except inside such a name, so consuming it is
# unambiguous (the same reasoning harness.parse_sig_atom already records).
TYPE_ATOM = r"(?:\[\])*\*?(?:[bsilfdz$]|:[A-Za-z_][A-Za-z0-9_.]*)"
SIG_RE = re.compile(r"^(?:\(.*\)(?:%s)?|%s)$" % (TYPE_ATOM, TYPE_ATOM))

# BlitzMax signature atom -> readable BlitzMax type
ATOM = {"b": "Byte", "s": "Short", "i": "Int", "l": "Long",
        "f": "Float", "d": "Double", "$": "String", "z": "CString"}


def load_pe(path):
    with open(path, "rb") as f:
        b = f.read()
    e = struct.unpack_from("<I", b, 0x3C)[0]
    img = struct.unpack_from("<I", b, e + 24 + 28)[0]
    ns = struct.unpack_from("<H", b, e + 6)[0]
    osz = struct.unpack_from("<H", b, e + 20)[0]
    so = e + 24 + osz
    secs = []
    for i in range(ns):
        o = so + i * 40
        nm = b[o:o + 8].rstrip(b"\x00").decode("ascii", "replace")
        _vs, rva, rs, ro = struct.unpack_from("<IIII", b, o + 8)
        secs.append((nm, rva, rs, ro))
    return b, img, secs


def main():
    b, img, secs = load_pe(EXE)

    def va2off(va):
        r = va - img
        for _nm, rva, sz, off in secs:
            if rva <= r < rva + sz:
                return r - rva + off
        return -1

    def cstr(o, lim=200):
        if o < 0 or o >= len(b):
            return None
        e = o
        while e < len(b) and 32 <= b[e] < 127 and e - o < lim:
            e += 1
        return b[o:e].decode("ascii") if e < len(b) and b[e] == 0 and e > o else None

    def strptr(v):
        if v < img:
            return None
        return cstr(va2off(v))

    data = next(s for s in secs if s[0] == "data")
    _n, _r, dsize, doff = data

    # ---- find scope headers: [kind==2][ptr->TypeName][kind in DECL_KIND][ptr->ident][ptr->sig]
    scopes = []
    i = doff
    end = doff + dsize - 32
    while i < end:
        if struct.unpack_from("<I", b, i)[0] == 2:
            nm = strptr(struct.unpack_from("<I", b, i + 4)[0])
            if nm and IDENT_RE.match(nm) and not SIG_RE.match(nm):
                k1 = struct.unpack_from("<I", b, i + 8)[0]
                if k1 in DECL_KIND:
                    n1 = strptr(struct.unpack_from("<I", b, i + 12)[0])
                    s1 = strptr(struct.unpack_from("<I", b, i + 16)[0])
                    if n1 and s1 and IDENT_RE.match(n1) and SIG_RE.match(s1):
                        members = []
                        j = i + 8
                        while j < end:
                            k = struct.unpack_from("<I", b, j)[0]
                            if k not in DECL_KIND:
                                break
                            nn = strptr(struct.unpack_from("<I", b, j + 4)[0])
                            ss = strptr(struct.unpack_from("<I", b, j + 8)[0])
                            if not nn or not ss or not IDENT_RE.match(nn) or not SIG_RE.match(ss):
                                break
                            off = struct.unpack_from("<I", b, j + 12)[0]
                            members.append({"kind": DECL_KIND[k], "name": nn,
                                            "sig": ss, "offset": off})
                            j += 16
                        if members:
                            scopes.append({"type": nm, "at": i, "members": members})
                            i = j
                            continue
        i += 4

    # de-duplicate by type name, keeping the richest definition
    best = {}
    for s in scopes:
        p = best.get(s["type"])
        if p is None or len(s["members"]) > len(p["members"]):
            best[s["type"]] = s
    scopes = sorted(best.values(), key=lambda s: s["type"])

    tot_f = sum(1 for s in scopes for m in s["members"] if m["kind"] == "Field")
    tot_m = sum(1 for s in scopes for m in s["members"] if m["kind"] in ("Method", "Function"))
    print("Type scopes recovered : %d" % len(scopes))
    print("fields                : %d" % tot_f)
    print("methods + functions   : %d" % tot_m)

    # The game's own compilation unit occupies one contiguous scope region in `data`.
    # Everything outside it is BlitzMax runtime, Win32 or DirectX metadata.
    # Anchors: TNation at 0x85764C ... THorse at 0x86C25C, plus a margin.
    GAME_LO, GAME_HI = 0x857000, 0x86D000
    game = [s for s in scopes if GAME_LO <= s["at"] <= GAME_HI]
    game.sort(key=lambda s: s["at"])   # keep original source declaration order

    os.makedirs(OUT_DIR, exist_ok=True)
    os.makedirs(SPEC_DIR, exist_ok=True)
    os.makedirs(GEN_DIR, exist_ok=True)
    with open(os.path.join(OUT_DIR, "object_model.json"), "w", encoding="utf-8") as f:
        json.dump(scopes, f, indent=1)

    # ---------------- markdown spec ----------------
    L = []
    L.append("# NSS5 Object Model\n\n")
    L.append("Recovered from the BlitzMax reflection (`BBDebugScope` / `BBDebugDecl`) tables inside "
             "`NSS5.exe`. These are the **original source's own** Type names, field names, method "
             "names and type signatures - not inferred, not guessed.\n\n")
    L.append("## Record format\n\n```\nBBDebugScope: [uint32 kind=2] [char* typeName] "
             "[BBDebugDecl...] [kind=0 terminator]\nBBDebugDecl : [uint32 kind] [char* name] "
             "[char* signature] [uint32 offset]   // 16 bytes\n\nkind 3 = Field    offset = byte "
             "offset within the object\nkind 6 = Method   offset = vtable slot\nkind 7 = Function "
             "(Type function / static)\nkind 2 = Global   kind 4 = Const\n```\n\n")
    L.append("Object header occupies offsets 0 (class/vtable pointer) and 4 (GC word); user fields "
             "start at **offset 8**.\n\n")
    L.append("## Signature encoding\n\n| Tag | Type |\n|---|---|\n")
    for k, v in ATOM.items():
        L.append("| `%s` | %s |\n" % (k, v))
    L.append("| `:TFoo` | object of Type TFoo |\n| `[]X` | array of X |\n| `*X` | pointer to X |\n"
             "| `(a,b)r` | function taking a,b returning r |\n\n")
    L.append("**Totals: %d Types, %d fields, %d methods/functions "
             "(%d game Types).**\n\n---\n" % (len(scopes), tot_f, tot_m, len(game)))

    for s in game:
        F = [m for m in s["members"] if m["kind"] == "Field"]
        M = [m for m in s["members"] if m["kind"] == "Method"]
        Fn = [m for m in s["members"] if m["kind"] == "Function"]
        G = [m for m in s["members"] if m["kind"] in ("Global", "Const", "Local", "Var")]
        L.append("\n## %s\n\n_%d fields, %d methods, %d functions_\n" %
                 (s["type"], len(F), len(M), len(Fn)))
        if F:
            L.append("\n### Fields - exact object layout\n\n| Offset | Name | Type |\n|---:|---|---|\n")
            for m in sorted(F, key=lambda x: x["offset"]):
                L.append("| %d | `%s` | `%s` |\n" % (m["offset"], m["name"], m["sig"]))
        if G:
            L.append("\n### Globals / Consts\n\n| Name | Type |\n|---|---|\n")
            for m in G:
                L.append("| `%s` | `%s` |\n" % (m["name"], m["sig"]))
        if M:
            L.append("\n### Methods\n\n| Slot | Name | Signature |\n|---:|---|---|\n")
            for m in M:
                L.append("| %d | `%s` | `%s` |\n" % (m["offset"], m["name"], m["sig"]))
        if Fn:
            L.append("\n### Functions\n\n| Slot | Name | Signature |\n|---:|---|---|\n")
            for m in Fn:
                L.append("| %d | `%s` | `%s` |\n" % (m["offset"], m["name"], m["sig"]))

    with open(os.path.join(SPEC_DIR, "07-object-model.md"), "w", encoding="utf-8") as f:
        f.writelines(L)

    # ---------------- BlitzMax skeletons ----------------
    def rd(sig):
        """render a signature atom as BlitzMax source"""
        arr = ""
        while sig.startswith("[]"):
            arr += "[]"
            sig = sig[2:]
        if sig.startswith(":"):
            return sig[1:] + arr
        return ATOM.get(sig, sig) + arr

    def render_params(inner):
        if not inner.strip():
            return ""
        out, depth, cur = [], 0, ""
        for ch in inner:
            if ch == "(":
                depth += 1
            elif ch == ")":
                depth -= 1
            if ch == "," and depth == 0:
                out.append(cur)
                cur = ""
            else:
                cur += ch
        if cur:
            out.append(cur)
        return ", ".join("_%d:%s" % (i, rd(p)) for i, p in enumerate(out))

    B = ["' ============================================================\n",
         "' NSS5 Type skeletons, generated from the reflection metadata\n",
         "' inside NSS5.exe. Field order and byte offsets are the ORIGINAL\n",
         "' layout. Do not reorder fields.\n",
         "' ============================================================\n\n",
         "SuperStrict\n\n"]
    for s in game:
        F = sorted([m for m in s["members"] if m["kind"] == "Field"], key=lambda x: x["offset"])
        M = [m for m in s["members"] if m["kind"] in ("Method", "Function")]
        B.append("Type %s\n" % s["type"])
        for m in F:
            B.append("\tField %s:%s\t' +%d\n" % (m["name"], rd(m["sig"]), m["offset"]))
        if F and M:
            B.append("\n")
        for m in M:
            kw = "Method" if m["kind"] == "Method" else "Function"
            sig = m["sig"]
            if sig.startswith("("):
                d, ci = 0, -1
                for idx, ch in enumerate(sig):
                    if ch == "(":
                        d += 1
                    elif ch == ")":
                        d -= 1
                        if d == 0:
                            ci = idx
                            break
                params = render_params(sig[1:ci])
                ret = sig[ci + 1:]
            else:
                params, ret = "", sig
            rets = (":" + rd(ret)) if ret else ""
            B.append("\t%s %s%s(%s)\n\tEnd %s\n\n" % (kw, m["name"], rets, params, kw))
        B.append("End Type\n\n")
    with open(os.path.join(GEN_DIR, "types_skeleton.bmx"), "w", encoding="utf-8") as f:
        f.writelines(B)

    print("\ngame Types: %d" % len(game))
    print("\nLargest game Types:")
    for s in sorted(game, key=lambda x: -len(x["members"]))[:30]:
        nf = sum(1 for m in s["members"] if m["kind"] == "Field")
        print("  %-20s %3d members (%d fields)" % (s["type"], len(s["members"]), nf))


if __name__ == "__main__":
    main()
