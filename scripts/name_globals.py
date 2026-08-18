#!/usr/bin/env python3
"""
name_globals.py -- enumerate + type + NAME every module-level global touched by game code.

Original names are unrecoverable (no BBDEBUGDECL_GLOBAL records were emitted), so we
assign our own stable names. Behaviour is identical: names never reach compiled output.

Outputs:
  extracted/globals_named.tsv
  src/generated/globals.bmx
"""
import os, re, sys, json, struct
from collections import defaultdict, Counter
import capstone

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
EXE = os.path.join(ROOT, "binary", "NSS5.exe")
EX = os.path.join(ROOT, "extracted")


def load_pe():
    b = open(EXE, "rb").read()
    e = struct.unpack_from("<I", b, 0x3C)[0]
    img = struct.unpack_from("<I", b, e + 24 + 28)[0]
    ns = struct.unpack_from("<H", b, e + 6)[0]
    osz = struct.unpack_from("<H", b, e + 20)[0]
    so = e + 24 + osz
    secs = []
    for i in range(ns):
        o = so + i * 40
        nm = b[o:o + 8].rstrip(b"\x00").decode("ascii", "replace")
        vs, rva, rs, ro = struct.unpack_from("<IIII", b, o + 8)
        secs.append((nm, img + rva, vs, ro, rs))
    return b, secs


BIN, SECS = load_pe()
SECMAP = {nm: (base, vs, ro, rs) for nm, base, vs, ro, rs in SECS}


def sect_of(va):
    for nm, base, vs, ro, rs in SECS:
        if base <= va < base + vs:
            return nm
    return None


def rd(va, n=4):
    for nm, base, vs, ro, rs in SECS:
        if base <= va < base + vs:
            off = va - base
            if off + n <= rs:
                return BIN[ro + off:ro + off + n]
            return b"\x00" * n  # .bss / uninitialised tail
    return None


def rd32(va):
    d = rd(va, 4)
    return struct.unpack("<I", d)[0] if d else None


def tsv(path, key=None):
    rows = []
    with open(path, encoding="utf-8", errors="replace") as f:
        hdr = f.readline().rstrip("\n").split("\t")
        for ln in f:
            p = ln.rstrip("\n").split("\t")
            if len(p) < len(hdr):
                p += [""] * (len(hdr) - len(p))
            rows.append(dict(zip(hdr, p)))
    return rows


# ---------------------------------------------------------------- inputs
inv = tsv(os.path.join(EX, "ghidra", "function_inventory.tsv"))
FN = {}
GAME_FN = {}
for r in inv:
    a = int(r["addr"], 16)
    FN[a] = (r["name"], int(r["size"] or 0), r["block"])
    if r["block"] == "code":
        GAME_FN[a] = (r["name"], int(r["size"] or 0))

vt = tsv(os.path.join(EX, "vtable_map.tsv"))
VTH = vt and list(vt[0].keys()) or []
# slot -> set(type), and (type,slot) -> name/sig ; va -> (type,name,sig)
SLOT_TYPES = defaultdict(set)
VA_METHOD = {}
TYPE_SLOT_NAME = {}
for r in vt:
    try:
        slot = int(str(r.get("slot", "")).replace("0x", ""), 16) if str(r.get("slot", "")).startswith("0x") else int(r.get("slot") or -1)
    except Exception:
        slot = -1
    t = r.get("type", "")
    nm = r.get("name", "")
    sg = r.get("sig", "")
    if slot >= 0 and t:
        SLOT_TYPES[slot].add(t)
        TYPE_SLOT_NAME[(t, slot)] = (nm, sg)
    va = r.get("va", "")
    if va:
        try:
            VA_METHOD[int(va, 16)] = (t, nm, sg)
        except Exception:
            pass

ct = tsv(os.path.join(EX, "class_tables.tsv"))
CLASSTAB = {}
SUPER = {}
for r in ct:
    try:
        CLASSTAB[int(r["classtable_va"], 16)] = r["type"]
    except Exception:
        pass
    SUPER[r["type"]] = r.get("super_type", "")

strings = tsv(os.path.join(EX, "ghidra", "strings_with_xrefs.tsv"))
STR_AT = {}
for r in strings:
    try:
        STR_AT[int(r["string_addr"], 16)] = r["string"]
    except Exception:
        pass

om = json.load(open(os.path.join(EX, "object_model.json"), encoding="utf-8"))
TYPES = om if isinstance(om, dict) else {}

# ---------------------------------------------------------------- disassemble
md = capstone.Cs(capstone.CS_ARCH_X86, capstone.CS_MODE_32)
md.detail = True

CODE_BASE, CODE_VS, CODE_RO, CODE_RS = SECMAP["code"]
DATA_RANGES = [(SECMAP[s][0], SECMAP[s][0] + SECMAP[s][1]) for s in (".data", "data", ".bss")]
CODE_RANGES = [(SECMAP[s][0], SECMAP[s][0] + SECMAP[s][1]) for s in (".text", "code")]


def in_data(va):
    return any(lo <= va < hi for lo, hi in DATA_RANGES)


def in_code(va):
    return any(lo <= va < hi for lo, hi in CODE_RANGES)


# per-global aggregation
G = defaultdict(lambda: dict(refs=0, fns=set(), rd=Counter(), wr=Counter(), size=Counter(),
                             fpu=0, deref_slots=Counter(), passed_to=Counter(),
                             self_to=Counter(), cmp_imm=Counter(), stored_from=Counter(),
                             idx=0, lea=0, near_str=Counter()))

REG_FULL = {}  # not needed globally


def scan_fn(addr, size):
    off = CODE_RO + (addr - CODE_BASE)
    code = BIN[off:off + size]
    insns = list(md.disasm(code, addr))
    # track: reg <- [G]
    holder = {}   # reg_name -> global va
    lastcall = None
    fstr, fglob = set(), set()
    for i, ins in enumerate(insns):
        mn = ins.mnemonic
        ops = ins.operands
        # invalidate holders written by this insn (approximate: dest reg)
        # collect direct-memory operands
        gva = None
        gmemop = None
        for o in ops:
            if o.type == capstone.x86.X86_OP_MEM:
                m = o.mem
                if m.base == 0 and m.index == 0 and in_data(m.disp & 0xFFFFFFFF):
                    gva = m.disp & 0xFFFFFFFF
                    gmemop = o
                elif m.base == 0 and m.index != 0 and in_data(m.disp & 0xFFFFFFFF):
                    gva = m.disp & 0xFFFFFFFF
                    gmemop = o
                    G[gva]["idx"] += 1
        if gva is not None:
            g = G[gva]
            fglob.add(gva)
            g["refs"] += 1
            g["fns"].add(addr)
            g["size"][gmemop.size] += 1
            if mn.startswith("f"):
                g["fpu"] += 1
                if mn in ("fld", "fadd", "fmul", "fsub", "fdiv", "fcomp", "fcom", "fild"):
                    g["rd"][mn] += 1
                else:
                    g["wr"][mn] += 1
            elif mn in ("mov", "movzx", "movsx", "cmp", "test", "add", "sub", "inc", "dec",
                        "push", "and", "or", "xor", "lea", "imul"):
                # is it the destination?
                isdest = (ops and ops[0].type == capstone.x86.X86_OP_MEM and
                          ops[0].mem.disp & 0xFFFFFFFF == gva and mn not in ("cmp", "test", "push"))
                (g["wr"] if isdest else g["rd"])[mn] += 1
                if mn == "lea":
                    g["lea"] += 1
                if mn == "cmp" and len(ops) == 2 and ops[1].type == capstone.x86.X86_OP_IMM:
                    g["cmp_imm"][ops[1].imm] += 1
                # mov reg, [G]  -> remember holder
                if mn == "mov" and len(ops) == 2 and ops[0].type == capstone.x86.X86_OP_REG \
                        and ops[1].type == capstone.x86.X86_OP_MEM and (ops[1].mem.disp & 0xFFFFFFFF) == gva:
                    holder[ins.reg_name(ops[0].reg)] = gva
                # mov [G], reg -> stored from
                if isdest and mn == "mov" and len(ops) == 2 and ops[1].type == capstone.x86.X86_OP_REG:
                    if lastcall is not None and ins.reg_name(ops[1].reg) == "eax":
                        g["stored_from"][lastcall] += 1
                elif isdest and mn == "mov" and len(ops) == 2 and ops[1].type == capstone.x86.X86_OP_IMM:
                    g["wr"]["imm"] += 1
            else:
                g["rd"][mn] += 1
        # holder usage: call [reg+slot]  /  mov reg2,[reg+off]
        for o in ops:
            if o.type == capstone.x86.X86_OP_MEM and o.mem.base != 0:
                bn = ins.reg_name(o.mem.base)
                if bn in holder:
                    hv = holder[bn]
                    if mn == "call":
                        G[hv]["deref_slots"][o.mem.disp] += 1
                    elif o.mem.disp == 0x18 or (o.mem.index != 0 and o.mem.disp >= 0x18):
                        G[hv]["deref_slots"][-1] += 1  # array-data marker
        # push reg (holder) / push [G] then call known method -> arg typing.
        # cdecl: args pushed right-to-left, so the LAST push before the call is `self`.
        pushed = None
        if mn == "push" and ops:
            if ops[0].type == capstone.x86.X86_OP_REG and ins.reg_name(ops[0].reg) in holder:
                pushed = holder[ins.reg_name(ops[0].reg)]
            elif ops[0].type == capstone.x86.X86_OP_MEM and ops[0].mem.base == 0 \
                    and ops[0].mem.index == 0 and in_data(ops[0].mem.disp & 0xFFFFFFFF):
                pushed = ops[0].mem.disp & 0xFFFFFFFF
        if pushed is not None:
            npush = 0
            for j in range(i + 1, min(i + 10, len(insns))):
                mj = insns[j].mnemonic
                if mj == "push":
                    npush += 1
                elif mj == "call" and insns[j].operands and \
                        insns[j].operands[0].type == capstone.x86.X86_OP_IMM:
                    tgt = insns[j].operands[0].imm
                    G[pushed]["passed_to"][tgt] += 1
                    if npush == 0:          # self slot
                        G[pushed]["self_to"][tgt] += 1
                    break
                elif mj in ("jmp", "ret"):
                    break
        if mn == "call" and ops and ops[0].type == capstone.x86.X86_OP_IMM:
            lastcall = ops[0].imm
            holder.clear()
        elif mn in ("call", "jmp"):
            holder.clear()
        # immediate operands pointing at strings -> function-level label context
        for o in ops:
            if o.type == capstone.x86.X86_OP_IMM and (o.imm & 0xFFFFFFFF) in STR_AT:
                fstr.add(STR_AT[o.imm & 0xFFFFFFFF])
    for gv in fglob:
        for s in list(fstr)[:6]:
            G[gv]["near_str"][s] += 1


for a, (nm, sz) in GAME_FN.items():
    if sz and 0 < sz < 200000:
        try:
            scan_fn(a, sz)
        except Exception as e:
            pass

print("raw global candidates:", len(G), file=sys.stderr)

# ---------------------------------------------------------------- filter out non-globals
# strings, class tables, and anything inside a known string body
STR_SPAN = []
for a, s in STR_AT.items():
    STR_SPAN.append((a, a + len(s) + 1))
STR_SPAN.sort()


def is_string(va):
    if va in STR_AT:
        return True
    import bisect
    i = bisect.bisect_right(STR_SPAN, (va, 1 << 62)) - 1
    return i >= 0 and STR_SPAN[i][0] <= va < STR_SPAN[i][1]


# ---------------------------------------------------------------- runtime sentinels
initvals = Counter()
for va in G:
    v = rd32(va)
    if v:
        initvals[v] += 1
SENTINEL = {}
for v, c in initvals.most_common(8):
    if not in_data(v):
        continue
    cls = rd32(v)
    nm = CLASSTAB.get(cls)
    SENTINEL[v] = (nm or "?", c)
print("top init values:", [(hex(v), SENTINEL.get(v), c) for v, c in initvals.most_common(6)], file=sys.stderr)

# heuristically identify bbNullObject / bbEmptyString / bbEmptyArray by their class table name
NULLOBJ = EMPTYSTR = EMPTYARR = None
for v, c in initvals.most_common(20):
    if not in_data(v):
        continue
    cls = rd32(v)
    tn = (CLASSTAB.get(cls) or "").lower()
    if "string" in tn and EMPTYSTR is None:
        EMPTYSTR = v
    elif "array" in tn and EMPTYARR is None:
        EMPTYARR = v
    elif ("object" in tn or tn == "") and NULLOBJ is None and c > 20:
        NULLOBJ = v

out = []
for va, g in G.items():
    if va in CLASSTAB or is_string(va):
        continue
    out.append((va, g))
out.sort()
print("after string/classtable filter:", len(out), file=sys.stderr)

# ================================================================ TYPING
NULLOBJ = 0x5C9C80          # confirmed: refs=0x40000000 immortal, clas=0  -> bbNullObject
# the two other high-frequency .data sentinels are bbEmptyString / bbEmptyArray;
# distinguish by their class-table's own name slot
SENT_OTHER = [v for v, c in initvals.most_common(12)
              if in_data(v) and v != NULLOBJ and c > 50]


def sentinel_kind(v):
    if v == NULLOBJ:
        return "object"
    if v in SENT_OTHER:
        cls = rd32(v)
        # BBString: clas, refs, length, char[] ; BBArray: clas, refs, dims, type, ...
        d = rd(v, 16) or b""
        if len(d) >= 12:
            ln = struct.unpack_from("<I", d, 8)[0]
            if ln == 0:
                return "string"
        return "array"
    return None


TYPE_OF_FN = {}   # function va -> owning Type (from vtable map + inventory names)
for va, (t, nm, sg) in VA_METHOD.items():
    TYPE_OF_FN[va] = t
for a, (nm, sz, blk) in FN.items():
    if "." in nm and a not in TYPE_OF_FN:
        TYPE_OF_FN[a] = nm.split(".")[0]


# slot ownership including inheritance: a subclass inherits every ancestor slot, and
# vtable_map only lists a slot under the Type that DECLARES it, so a strict per-slot
# intersection is always empty. Build the closure instead.
DECL_SLOTS = defaultdict(set)
for (t, slot) in TYPE_SLOT_NAME:
    DECL_SLOTS[t].add(slot)
HAS_SLOT = {}
for t in list(DECL_SLOTS) + list(SUPER):
    seen, cur, acc = set(), t, set()
    while cur and cur not in seen and cur in DECL_SLOTS or (cur in SUPER and cur not in seen):
        seen.add(cur)
        acc |= DECL_SLOTS.get(cur, set())
        cur = SUPER.get(cur, "")
        if cur.endswith("(runtime)") or not cur:
            break
    if acc:
        HAS_SLOT[t] = acc

VA_KIND = {}
for r in vt:
    try:
        VA_KIND[int(r["va"], 16)] = r.get("kind", "")
    except Exception:
        pass

ATOM = re.compile(r":(?:[a-z0-9_.]+\.)?([A-Za-z_][A-Za-z0-9_]*)|(\[\])|([bsilfd$z*])")


def sig_args(sig):
    """(argatoms) from a BlitzMax signature '(:TFoo$i)i' -> ['TFoo','$','i']."""
    m = re.match(r"^\(([^)]*)\)", sig or "")
    if not m:
        return []
    body, outp, i = m.group(1), [], 0
    while i < len(body):
        c = body[i]
        if c == ":":
            j = i + 1
            while j < len(body) and (body[j].isalnum() or body[j] in "_."):
                j += 1
            outp.append(body[i + 1:j].split(".")[-1])
            i = j
        elif c == "[":
            i += 2
            if outp:
                outp[-1] += "[]"
        else:
            outp.append(c)
            i += 1
    return outp


def arg0_type(fnva):
    m = VA_METHOD.get(fnva)
    if not m:
        return None
    a = sig_args(m[2])
    return a[0] if a else None


def ret_type_of(fnva):
    """Type constructed/returned by fnva, if it is a New/Create-shaped method."""
    m = VA_METHOD.get(fnva)
    if m:
        t, nm, sg = m
        if re.match(r"^(New|Create|Get|Init|Load)", nm or ""):
            mm = re.search(r"\)\s*:?([A-Za-z_][A-Za-z0-9_]*)", sg or "")
            if mm and mm.group(1) in TYPES:
                return mm.group(1)
        return None
    return None


def infer_type(va, g):
    """Return (type_string, confidence, evidence_string)."""
    ev = []
    init = rd32(va) or 0
    kind = sentinel_kind(init)
    votes = Counter()
    # (1) last push before a call. cdecl: args right-to-left, so for a METHOD this
    #     slot is `self` (=> global has the owner's type); for a static FUNCTION it is
    #     declared arg 0 (=> take arg 0's type out of the signature).
    for tgt, c in g["self_to"].items():
        k = VA_KIND.get(tgt)
        if k == "Method":
            t = TYPE_OF_FN.get(tgt)
            if t and t in TYPES:
                votes[t] += 4 * c
                ev.append("self-recv of %s.%s" % (t, VA_METHOD[tgt][1]))
        elif k == "Function":
            a0 = arg0_type(tgt)
            if a0 in TYPES:
                votes[a0] += 3 * c
                ev.append("arg0 of %s.%s:%s" % (VA_METHOD[tgt][0], VA_METHOD[tgt][1], a0))
    # (2) stored from a constructor call
    for tgt, c in g["stored_from"].items():
        t = ret_type_of(tgt) or TYPE_OF_FN.get(tgt)
        if t and t in TYPES:
            votes[t] += 3 * c
            ev.append("stored-from %s" % (VA_METHOD.get(tgt, (t, "?", ""))[0] + "." +
                                          VA_METHOD.get(tgt, ("", "?", ""))[1]))
    # (3) non-self argument position
    for tgt, c in g["passed_to"].items():
        if tgt in g["self_to"]:
            continue
        m = VA_METHOD.get(tgt)
        if m:
            args = re.findall(r":([A-Za-z_][A-Za-z0-9_]*)", (m[2] or "").split(")")[0])
            for a in args:
                if a in TYPES:
                    votes[a] += 1
    # (4) vtable slot intersection
    # A slot number alone is weak: most Types define slot 0x30/0x34. Only vote when the
    # intersection over ALL observed slots is genuinely narrow, and never let it alone
    # decide a type (it may not break a tie against nothing).
    slots = [s for s in g["deref_slots"] if s >= 0]
    if slots:
        want = set(slots)
        cand = {t for t, hs in HAS_SLOT.items() if want <= hs}
        # prefer the shallowest candidate: if a base and its descendants both fit the
        # slot set, the base is the honest answer.
        if cand:
            cand = {t for t in cand if not (SUPER.get(t) in cand)} or cand
            # Print the WHOLE slot set and its size. The intersection is taken over the
            # full observed set, so printing a truncated sample leaves recorded evidence
            # that does not support the recorded conclusion: re-testing four printed
            # slots finds 16-32 Types carrying them and makes the note look false. The
            # claim has to be re-derivable by anyone reading the table.
            allslots = sorted(slots)
            slotev = ",".join(hex(s) for s in allslots)
            if len(cand) == 1:
                t = next(iter(cand))
                votes[t] += 6 if len(slots) >= 3 else 4
                ev.append("vtable-call slots [%d] %s -> only %s has them all"
                          % (len(allslots), slotev, t))
            elif len(cand) <= 6:
                for t in cand:
                    votes[t] += 1
                ev.append("vtable-call slots %s -> one of {%s}" % (slotev, "|".join(sorted(cand))))
            else:
                ev.append("vtable-call slots %s ambiguous (%d types)" % (slotev, len(cand)))
            g["_vt_cand"] = cand
    best = votes.most_common(1)
    if best and kind == "object":
        t, sc = best[0]
        tot = sum(votes.values())
        strong = bool(g["self_to"]) or bool(g["stored_from"]) or len(g.get("_vt_cand") or ()) == 1
        if not strong:                       # vtable-slot / arg-position evidence only
            conf = "low"
        elif sc >= 8 and sc / tot > 0.7:
            conf = "high"
        elif sc / tot > 0.5:
            conf = "medium"
        else:
            conf = "low"
        if conf == "low" and not strong and sc < 4:
            return "Object", "low", ("unresolved: " + "; ".join(ev[:2])) or "no typing evidence"
        return t, conf, "; ".join(ev[:3]) or "vote"
    if kind == "object":
        return "Object", "low", "init=bbNullObject, no call-site typing"
    if kind == "string":
        return "String", "high", "init=bbEmptyString"
    if kind == "array":
        # element type from access stride is not recoverable cheaply -> Int[] default
        return "Object[]", "medium", "init=bbEmptyArray"
    # scalars
    sz = g["size"].most_common(1)
    w = sz[0][0] if sz else 4
    if g["fpu"]:
        if w == 8:
            return "Double", "high", "x87 qword access"
        return "Float", "high", "x87 dword access"
    if w == 1:
        return "Byte", "medium", "byte-width access"
    if w == 2:
        return "Short", "medium", "word-width access"
    if not g["wr"]:
        return "Int", "low", "read-only int slot"
    return "Int", "medium", "dword int access, %d writes" % sum(g["wr"].values())


# literal-pool detector: never written by ANY game function, FPU-read only, non-zero init
def is_literal(va, g):
    if g["wr"]:
        return False
    init = rd32(va) or 0
    if sentinel_kind(init):
        return False
    if g["fpu"] and init != 0:
        f = struct.unpack("<f", struct.pack("<I", init))[0]
        if f != 0 and abs(f) < 1e12:
            return True
    return False


# ================================================================ NAMING
def subsystem_of(g):
    c = Counter()
    for fa in g["fns"]:
        t = TYPE_OF_FN.get(fa)
        if t:
            c[t] += 1
    return c.most_common(1)[0][0] if c else None


LABELISH = re.compile(r"^[A-Z][A-Za-z0-9 :'\-]{2,40}$")


def label_hint(g):
    for s, c in g["near_str"].most_common(4):
        s = s.strip()
        if LABELISH.match(s) and " " not in s[:1]:
            return re.sub(r"[^A-Za-z0-9]", "", s.title())[:24]
    return None


rows = []
used = Counter()
for va, g in out:
    if is_literal(va, g):
        continue
    t, conf, ev = infer_type(va, g)
    sub = subsystem_of(g)
    if t in TYPES or t == "Object":
        base = "g_%s" % (t[1:] if t.startswith("T") and len(t) > 1 else t)
    elif t in ("String", "Object[]"):
        stem = (sub[1:] if sub and sub.startswith("T") else sub) or "misc"
        base = "g_%s_%s" % (stem.lower(), "str" if t == "String" else "arr")
    else:
        stem = (sub[1:] if sub and sub.startswith("T") else sub) or "misc"
        hint = label_hint(g)
        base = "g_%s%s_%s" % (stem.lower(), "_" + hint.lower() if hint else "", t.lower())
    used[base] += 1
    name = "%s%02d" % (base, used[base]) if True else base
    rows.append(dict(addr="0x%08x" % va, type=t, name=name, conf=conf,
                     refs=g["refs"], nfns=len(g["fns"]), sub=sub or "-", ev=ev))

# collapse the trailing counter for names that turned out unique
cnt = Counter(r["name"][:-2] for r in rows)
for r in rows:
    if cnt[r["name"][:-2]] == 1:
        r["name"] = r["name"][:-2]

with open(os.path.join(EX, "globals_named.tsv"), "w", encoding="utf-8", newline="") as f:
    f.write("address\tinferred_type\tour_name\tconfidence\trefcount\tn_funcs\tsubsystem\tevidence\n")
    for r in rows:
        f.write("%s\t%s\t%s\t%s\t%d\t%d\t%s\t%s\n" %
                (r["addr"], r["type"], r["name"], r["conf"], r["refs"], r["nfns"], r["sub"], r["ev"]))

os.makedirs(os.path.join(ROOT, "src", "generated"), exist_ok=True)
with open(os.path.join(ROOT, "src", "generated", "globals.bmx"), "w", encoding="utf-8", newline="") as f:
    f.write("' globals.bmx -- AUTO-GENERATED by scripts/name_globals.py. Do not hand-edit.\n")
    f.write("' Module-level Globals recovered from NSS5.exe. Original names were never\n")
    f.write("' emitted (no BBDEBUGDECL_GLOBAL records); these names are ours. Declaration\n")
    f.write("' ORDER here does not have to match the original -- bcc allocates each Global\n")
    f.write("' its own data slot and referencing code is address-independent.\n\n")
    f.write("SuperStrict\n\nImport BRL.LinkedList\nImport BRL.Map\n\n")
    bysub = defaultdict(list)
    for r in rows:
        bysub[r["sub"]].append(r)
    for sub in sorted(bysub, key=lambda s: -len(bysub[s])):
        f.write("' ---- %s (%d) ----\n" % (sub, len(bysub[sub])))
        for r in sorted(bysub[sub], key=lambda x: x["addr"]):
            f.write("Global %s:%s\t' %s refs=%d conf=%s %s\n" %
                    (r["name"], r["type"], r["addr"], r["refs"], r["conf"], r["ev"][:60]))
        f.write("\n")

print("EMITTED %d globals (%d literal-pool entries excluded)" %
      (len(rows), len(out) - len(rows)), file=sys.stderr)
print("by confidence:", Counter(r["conf"] for r in rows), file=sys.stderr)
print("by type:", Counter(r["type"] for r in rows).most_common(12), file=sys.stderr)

json.dump({hex(k): dict(refs=v["refs"], nfns=len(v["fns"]),
                        rd=dict(v["rd"]), wr=dict(v["wr"]), size=dict(v["size"]),
                        fpu=v["fpu"], idx=v["idx"], lea=v["lea"],
                        slots={hex(s): c for s, c in v["deref_slots"].items()},
                        passed={hex(a): c for a, c in v["passed_to"].items()},
                        stored={hex(a): c for a, c in v["stored_from"].items()},
                        cmpi=dict(v["cmp_imm"]),
                        init=hex(rd32(k) or 0), sect=sect_of(k),
                        strs=list(v["near_str"])[:3],
                        fns=[hex(x) for x in sorted(v["fns"])][:12])
           for k, v in out},
          open(os.path.join(EX, "_globals_raw.json"), "w"), indent=0)
print("SENT null=%s str=%s arr=%s" % (NULLOBJ and hex(NULLOBJ), EMPTYSTR and hex(EMPTYSTR),
                                      EMPTYARR and hex(EMPTYARR)), file=sys.stderr)
