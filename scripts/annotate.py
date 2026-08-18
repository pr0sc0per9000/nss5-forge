"""
annotate.py - object-model-driven annotator for the NSS5 Ghidra corpus.

Design contract:
  * KIND=Method  -> param_1 IS Self (the owning Type). param_2.. map to SIG args 1..n.
  * KIND=Function-> NO Self exists. param_1..n map to SIG args 1..n. Never emit Self.
  * Inheritance chains come from extracted/class_tables.tsv (BBClass +0 super). Child shadows parent.
  * Every substitution is validated against R1-R5 BEFORE it is emitted. A site that fails any
    rule is left RAW and counted. Unresolved > wrong.
  * Byte offsets are computed with real C pointer arithmetic: `p + N` where p is declared
    `int *` is byte offset N*4, where p is declared `int` it is byte offset N. The declared
    type is read out of the decompiled prototype / local declarations, never guessed.

Usage:
  annotate.py --all                 batch the whole corpus -> extracted/decomp_annotated/
  annotate.py --file <name.c>       one file to stdout
  annotate.py --stats               batch + aggregate stats + v1 delta (no writes)
"""

import json
import os
import re
import sys
from collections import Counter, defaultdict

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
MODEL = os.path.join(ROOT, "extracted", "object_model.json")
CTABLES = os.path.join(ROOT, "extracted", "class_tables.tsv")
DECOMP = os.path.join(ROOT, "extracted", "decomp")
INDEX = os.path.join(DECOMP, "_index.tsv")
OUTDIR = os.path.join(ROOT, "extracted", "decomp_annotated")

NULL_DAT = "005c9c80"
HDR = 8                      # first user field offset: 0=class ptr, 4=GC word (R2)
RUNTIME_SLOTS = range(0x18, 0x30)   # ToString/Compare/SendMessage/ObjectEnumerator etc (R3)
BB_OBJECT_NEW = "004a8f20"   # verified: FUN_004a8f20(&PTR_*_<classtable_va>) == bbObjectNew

SITES_TSV = os.path.join(ROOT, "extracted", "call_sites.tsv")

# The symbol-layer resolvers are optional: if the arity scan has not been run, annotate
# still emits its base annotation rather than failing. Nothing downstream should ever have
# to care whether a table happened to be built.
try:
    import w8annot_resolve as _RES
except Exception:                                                     # noqa: BLE001
    _RES = None

_SITES = {}


def load_sites():
    """caller VA -> [(call_va, kind, target, argbytes, shape)] from w8annot_arity.py."""
    if _SITES or not os.path.exists(SITES_TSV):
        return _SITES
    with open(SITES_TSV, encoding="utf-8", errors="replace") as f:
        next(f, None)
        for line in f:
            p = line.rstrip("\n").split("\t")
            if len(p) < 6:
                continue
            try:
                caller = int(p[0], 16)
                cva = int(p[1], 16)
            except ValueError:
                continue
            tgt = None
            if p[3] != "-":
                try:
                    tgt = int(p[3], 16)
                except ValueError:
                    tgt = None
            argb = None if p[4] == "-" else int(p[4])
            _SITES.setdefault(caller, []).append((cva, p[2], tgt, argb, p[5]))
    return _SITES

# ---------------------------------------------------------------- model loading

def load_model():
    with open(MODEL, encoding="utf-8") as f:
        return {s["type"]: s for s in json.load(f)}


def load_ctables():
    """type -> (classtable_va:int, super_type:str|'', instance_size:int)"""
    out = {}
    with open(CTABLES, encoding="utf-8") as f:
        rows = [ln.rstrip("\n").split("\t") for ln in f]
    for r in rows[1:]:
        if len(r) < 5:
            continue
        t, cva, _sva, sup, isz = r[0], r[1], r[2], r[3], r[4]
        if sup.startswith("Object(") or sup == t:
            sup = ""
        try:
            out[t] = (int(cva, 16), sup, int(isz))
        except ValueError:
            continue
    return out


def split_sig_args(sig):
    """'(:TTeam,i,()i)$' -> [':TTeam','i','()i'] ; depth aware, [] tolerant."""
    if not sig.startswith("("):
        return [], sig
    d, i = 0, 0
    for i, ch in enumerate(sig):
        if ch == "(":
            d += 1
        elif ch == ")":
            d -= 1
            if d == 0:
                break
    inner, ret = sig[1:i], sig[i + 1:]
    args, d, cur = [], 0, ""
    for ch in inner:
        if ch in "([":
            d += 1
        elif ch in ")]":
            d -= 1
        if ch == "," and d == 0:
            args.append(cur)
            cur = ""
        else:
            cur += ch
    if cur.strip():
        args.append(cur)
    return [a for a in args if a != ""], ret


def sig_obj(tok):
    """':TPlayer' -> 'TPlayer'. Anything else (scalar/array/funcptr) -> None."""
    return tok[1:] if tok.startswith(":") else None


class Model:
    def __init__(self):
        self.m = load_model()
        self.ct = load_ctables()
        self._fields = {}
        self._slots = {}
        self.ctva = {}          # class table VA -> Type
        for t, (cva, _s, _i) in self.ct.items():
            self.ctva[cva] = t
        # VA -> Type.Name  and  VA -> return sig, from the corpus index
        self.va_name, self.va_ret = {}, {}
        with open(INDEX, encoding="utf-8") as f:
            for ln in list(f)[1:]:
                c = ln.rstrip("\n").split("\t")
                if len(c) < 7:
                    continue
                try:
                    va = int(c[5], 16)
                except ValueError:
                    continue
                self.va_name[va] = "%s_%s" % (c[0], c[2])
                self.va_ret[va] = split_sig_args(c[3])[1]

    def chain(self, t):
        out, seen = [], set()
        while t and t in self.m and t not in seen:
            seen.add(t)
            out.append(t)
            t = self.ct.get(t, (0, "", 0))[1]
        return out

    def fields(self, t):
        """offset -> (name, sig) merged over the inheritance chain; CHILD SHADOWS PARENT."""
        if t in self._fields:
            return self._fields[t]
        merged = {}
        for anc in reversed(self.chain(t)):          # parent first, child overwrites
            for mem in self.m[anc]["members"]:
                if mem["kind"] == "Field":
                    merged[mem["offset"]] = (mem["name"], mem["sig"])
        self._fields[t] = merged
        return merged

    def slots(self, t):
        if t in self._slots:
            return self._slots[t]
        merged = {}
        for anc in reversed(self.chain(t)):
            for mem in self.m[anc]["members"]:
                if mem["kind"] in ("Method", "Function"):
                    merged[mem["offset"]] = (mem["name"], mem["sig"])
        self._slots[t] = merged
        return merged

    def isize(self, t):
        return self.ct.get(t, (0, "", 1 << 30))[2] or (1 << 30)

    # ---- validators -------------------------------------------------------
    def field_at(self, t, off):
        """R1 + R2. Returns (name, sig) or None with a reject reason."""
        if t is None or t not in self.m:
            return None, "no-type"
        if off < HDR:
            return None, "R2"                      # class ptr / GC word
        if off >= self.isize(t):
            return None, "R1-oob"                  # past instance_size
        hit = self.fields(t).get(off)
        if hit is None:
            return None, "R1-gap"                  # between declared fields
        return hit, None

    def slot_at(self, t, off):
        """R3."""
        if t is None or t not in self.m:
            return None, "no-type"
        if off in RUNTIME_SLOTS:
            return None, "R3-runtime"
        hit = self.slots(t).get(off)
        if hit is None:
            return None, "R3-unknown"
        return hit, None


# ---------------------------------------------------------------- C type sizes

_ELEM = {"undefined": 1, "byte": 1, "char": 1, "bool": 1,
         "undefined2": 2, "short": 2, "ushort": 2, "wchar": 2,
         "undefined4": 4, "int": 4, "uint": 4, "float": 4, "long": 4, "ulong": 4,
         "code": 4, "undefined8": 8, "double": 8, "longlong": 8}


def elem_size(ctype):
    """Byte stride of `x + 1` for a variable declared `ctype x`. 0 => not a pointer."""
    ctype = ctype.strip()
    stars = ctype.count("*")
    if stars == 0:
        return 0                       # scalar: `x + N` is byte offset N
    base = ctype.replace("*", "").strip()
    if stars > 1:
        return 4                       # pointer-to-pointer: stride 4 on win32
    return _ELEM.get(base, 0) or 4


# ---------------------------------------------------------------- file parsing

HDR_RE = re.compile(r"^// (TYPE|KIND|NAME|SIG|SLOT|VA)=(.*)$", re.M)
DECL_RE = re.compile(r"^[\w ]*?\**\s*FUN_[0-9a-f]{6,8}\((.*?)\)\s*$", re.M)
LOCAL_RE = re.compile(r"^  ([A-Za-z_][\w ]*?[\w *]*?)\s*(\*?\w+);\s*$", re.M)


def parse_header(text):
    return {k: v.strip() for k, v in HDR_RE.findall(text)}


def parse_params(text):
    """[(ctype, name)] from the decompiled prototype, in order."""
    m = DECL_RE.search(text)
    if not m:
        return None
    raw = m.group(1).strip()
    if raw in ("", "void"):
        return []
    out = []
    for p in raw.split(","):
        p = p.strip()
        mm = re.match(r"^(.*?)(\**)\s*(\w+)$", p)
        if not mm:
            continue
        out.append(((mm.group(1) + mm.group(2)).strip(), mm.group(3)))
    return out


def parse_locals(text):
    """name -> ctype for the declaration block."""
    out = {}
    body = text.split("{", 1)[-1]
    for ctype, nm in LOCAL_RE.findall(body):
        stars = nm.count("*")
        nm = nm.lstrip("*")
        out[nm] = (ctype + "*" * stars).strip()
    return out


# ---------------------------------------------------------------- the annotator

H = r"(?:0x[0-9a-fA-F]+|\d+)"          # defect #1: hex OR decimal, everywhere


def ival(s):
    return int(s, 16) if s.lower().startswith("0x") else int(s)


class Annotator:
    def __init__(self, mdl):
        self.M = mdl

    def run(self, text, path_name=""):
        M = self.M
        hd = parse_header(text)
        owner = hd.get("TYPE", "")
        kind = hd.get("KIND", "")
        sig = hd.get("SIG", "")
        st = Counter()
        rej = Counter()
        self.st, self.rej = st, rej

        args, _ret = split_sig_args(sig)
        expected = (1 if kind == "Method" else 0) + len(args)
        decl = parse_params(text)
        locals_ = parse_locals(text)
        st["expected_params"] = expected
        st["decl_params"] = -1 if decl is None else len(decl)

        # ---- bind param_N -> (display name, Type or None)  [R4 / R6] --------
        bind = {}
        ctypes = {}
        if decl is not None:
            for i, (ct, nm) in enumerate(decl, start=1):
                ctypes[nm] = ct
            for i in range(1, len(decl) + 1):
                nm = decl[i - 1][1]
                if not re.fullmatch(r"param_\d+", nm):
                    continue
                if i > expected:
                    st["phantom_param"] += 1        # Ghidra invented it; leave raw
                    continue
                if kind == "Method":
                    if i == 1:
                        bind[nm] = ("Self", owner)
                    else:
                        tok = args[i - 2] if i - 2 < len(args) else None
                        bind[nm] = (nm, sig_obj(tok) if tok else None)
                else:
                    tok = args[i - 1] if i - 1 < len(args) else None
                    bind[nm] = (nm, sig_obj(tok) if tok else None)
        if kind == "Method" and decl is not None and len(decl) < expected:
            # Ghidra dropped params (Delete stubs / trailing unused). Positional
            # mapping still holds for the ones it kept; nothing to do but record it.
            st["short_prototype"] = 1

        ctypes.update(locals_)
        self.ctypes = ctypes
        self.bind = bind
        self.owner = owner
        self.kind = kind

        # ---- local type inference (strict: single assignment, seeded) -------
        inferred = self.infer_locals(text, bind, ctypes)
        self.inferred = inferred
        st["typed_locals"] = len(inferred)

        # base var -> (display, Type, is_high_confidence)
        self.base = {}
        for v, (disp, t) in bind.items():
            self.base[v] = (disp, t, True)
        for v, t in inferred.items():
            self.base[v] = (v, t, False)

        self.med_lines = set()
        out = self.substitute(text)
        out = self.resolve_symbols(out)
        self.legend = {}
        self.calls = []
        try:
            self.va = int(hd.get("VA", "0"), 16)
        except ValueError:
            self.va = None
        out = self.annotate_addresses(out)
        self.calls = self.call_table(self.va)
        return out, hd, st, rej, inferred

    # -------- local type inference -----------------------------------------
    def infer_locals(self, text, bind, ctypes):
        M = self.M
        body = text.split("{", 1)[-1]
        cands = defaultdict(list)
        asg = re.compile(r"(?<![=!<>+\-*/&|^])\b(\w+) = (?!=)(.*?);", re.S)
        counts = Counter()
        rhs = {}
        for m in asg.finditer(body):
            v = m.group(1)
            if v not in ctypes or v in bind:
                continue
            counts[v] += 1
            rhs[v] = m.group(2)
        typed = {}
        for _ in range(3):
            changed = False
            for v, r in rhs.items():
                if counts[v] != 1 or v in typed:
                    continue          # strict: reassigned vars are never typed
                t = self.type_of_expr(r, typed)
                if t:
                    typed[v] = t
                    changed = True
            if not changed:
                break
        return typed

    def type_of_expr(self, r, typed):
        M = self.M
        r = r.strip()
        # bbObjectNew(&PTR_*_<classtable VA>)
        m = re.search(r"FUN_" + BB_OBJECT_NEW + r"\(&PTR_\w*?_?([0-9a-fA-F]{6,8})\)", r)
        if m:
            return M.ctva.get(int(m.group(1), 16))
        # direct call to a known function whose SIG returns an object
        m = re.match(r"^\(?[\w *]*\)?\s*FUN_([0-9a-f]{6,8})\(", r)
        if m:
            va = int(m.group(1), 16)
            if va in M.va_ret:
                return sig_obj(M.va_ret[va])
        # vtable call on an already-typed receiver
        m = re.match(r"^\(?[\w *]*\)?\s*\(\*\*\(code \*\*\)\(\*(?:\([\w *]+\))?(\w+) \+ (" + H + r")\)\)", r)
        if m:
            recv = m.group(1)
            rt = typed.get(recv) or (self.bind.get(recv, (None, None))[1])
            hit, _ = M.slot_at(rt, ival(m.group(2)))
            if hit:
                return sig_obj(split_sig_args(hit[1])[1])
        # read of an object-typed field of an already-anchored base
        m = re.match(r"^\(?[\w *]*\)?\s*\*\([\w ]+\*+\)\((\w+) \+ (" + H + r")\)$", r)
        if m:
            return self._fieldtype(m.group(1), ival(m.group(2)), typed, scaled=True)
        m = re.match(r"^\(?[\w *]*\)?\s*(\w+)\[(" + H + r")\]$", r)
        if m:
            return self._fieldtype(m.group(1), ival(m.group(2)), typed, scaled=True)
        return None

    def _fieldtype(self, var, n, typed, scaled):
        t = typed.get(var) or (self.bind.get(var, (None, None))[1])
        if not t:
            return None
        off = self.byte_off(var, n)
        if off is None:
            return None
        hit, _ = self.M.field_at(t, off)
        return sig_obj(hit[1]) if hit else None

    # -------- offset arithmetic --------------------------------------------
    def byte_off(self, var, n):
        """Real C semantics: stride from the DECLARED type of `var`."""
        ct = self.ctypes.get(var)
        if ct is None:
            return None
        s = elem_size(ct)
        return n * s if s else n

    def idx_off(self, var, n):
        """`var[n]` is only legal on a pointer; stride from declared type."""
        ct = self.ctypes.get(var)
        if ct is None:
            return None
        s = elem_size(ct)
        return n * (s or 4)

    # -------- substitution --------------------------------------------------
    def emit(self, var, text_out, conf_high):
        if not conf_high:
            self.med = True
        return text_out

    def substitute(self, text):
        M, st, rej = self.M, self.st, self.rej
        B = self.base
        varpat = "|".join(sorted((re.escape(v) for v in B), key=len, reverse=True)) or r"\0"

        def basetype(v):
            return B[v][1] if v in B else None

        def disp(v):
            return B[v][0] if v in B else v

        def conf(v):
            return B[v][2] if v in B else False

        med_flag = [False]

        def mark(v):
            if not conf(v):
                med_flag[0] = True

        # 1. vtable call through a field:  (**(code **)(**(T **)(V + O) + S))(*(T **)(V + O)
        def vc_field(m):
            v, o, s = m.group(1), ival(m.group(2)), ival(m.group(3))
            t = basetype(v)
            off = self.byte_off(v, o)
            if off is None:
                rej["no-decl"] += 1
                return m.group(0)
            f, why = M.field_at(t, off)
            if not f:
                rej[why or "no-type"] += 1
                return m.group(0)
            ft = sig_obj(f[1])
            if not ft:
                rej["R5-not-object"] += 1
                return m.group(0)
            sl, why = M.slot_at(ft, s)
            if not sl:
                rej[why] += 1
                return m.group(0)
            st["vcall_field"] += 1
            mark(v)
            return "%s.%s.%s(" % (disp(v), f[0], sl[0])
        text = re.sub(
            r"\(\*\*\(code \*\*\)\(\*\*\([\w ]+\*+\)\((" + varpat + r") \+ (" + H +
            r")\) \+ (" + H + r")\)\)\(\*\([\w ]+\*+\)\(\1 \+ \2\),?\s*",
            vc_field, text)

        # 2. vtable call on a bound/typed base:  (**(code **)(*V + S))(V, ...
        def vc(m):
            v, s = m.group(1), ival(m.group(2))
            t = basetype(v)
            sl, why = M.slot_at(t, s)
            if not sl:
                rej[why] += 1
                return m.group(0)
            st["vcall"] += 1
            mark(v)
            return "%s.%s(" % (disp(v), sl[0])
        text = re.sub(
            r"\(\*\*\(code \*\*\)\(\*(?:\([\w ]+\*+\))?(" + varpat + r") \+ (" + H +
            r")\)\)\(\((?:[\w ]+\*+)\)?\1,?\s*", vc, text)
        text = re.sub(
            r"\(\*\*\(code \*\*\)\(\*(?:\([\w ]+\*+\))?(" + varpat + r") \+ (" + H +
            r")\)\)\((?:\1)?,?\s*", vc, text)

        # 3. nested field, byte-offset form:  *(T *)(*(T *)(V + O1) + O2)
        def nested_b(m):
            v, o1, o2 = m.group(1), ival(m.group(2)), ival(m.group(3))
            t = basetype(v)
            off1 = self.byte_off(v, o1)
            if off1 is None:
                rej["no-decl"] += 1
                return m.group(0)
            f1, why = M.field_at(t, off1)
            if not f1:
                rej[why or "no-type"] += 1
                return m.group(0)
            t2 = sig_obj(f1[1])
            if not t2 or t2 not in M.m:
                rej["R5-not-object"] += 1
                return m.group(0)
            f2, why = M.field_at(t2, o2)
            if not f2:
                rej[why] += 1
                return m.group(0)
            st["nested"] += 1
            mark(v)
            return "%s.%s.%s" % (disp(v), f1[0], f2[0])
        text = re.sub(
            r"\*\([\w ]+\*+\)\(\*\([\w ]+\*+\)\((" + varpat + r") \+ (" + H +
            r")\) \+ (" + H + r")\)", nested_b, text)

        # 4. nested field, index form:  *(T *)(V[K] + O)
        def nested_i(m):
            v, k, o = m.group(1), ival(m.group(2)), ival(m.group(3))
            t = basetype(v)
            off1 = self.idx_off(v, k)
            f1, why = M.field_at(t, off1) if off1 is not None else (None, "no-decl")
            if not f1:
                rej[why or "no-type"] += 1
                return m.group(0)
            t2 = sig_obj(f1[1])
            if not t2 or t2 not in M.m:
                rej["R5-not-object"] += 1
                return m.group(0)
            f2, why = M.field_at(t2, o)
            if not f2:
                rej[why] += 1
                return m.group(0)
            st["nested"] += 1
            mark(v)
            return "%s.%s.%s" % (disp(v), f1[0], f2[0])
        text = re.sub(
            r"\*\([\w ]+\*+\)\((" + varpat + r")\[(" + H + r")\] \+ (" + H + r")\)",
            nested_i, text)

        # 5. direct field read/write:  *(T *)(V + O)     (any number of stars in the cast)
        def direct(m):
            v, o = m.group(1), ival(m.group(2))
            t = basetype(v)
            off = self.byte_off(v, o)
            if off is None:
                rej["no-decl"] += 1
                return m.group(0)
            f, why = M.field_at(t, off)
            if not f:
                rej[why or "no-type"] += 1
                return m.group(0)
            st["direct"] += 1
            mark(v)
            return "%s.%s" % (disp(v), f[0])
        text = re.sub(r"\*\([\w ]+\*+\)\((" + varpat + r") \+ (" + H + r")\)", direct, text)

        # 6. address-of a field (no leading deref):  (T *)(V + O)  ->  &V.field
        def addr(m):
            v, o = m.group(1), ival(m.group(2))
            t = basetype(v)
            off = self.byte_off(v, o)
            if off is None:
                rej["no-decl"] += 1
                return m.group(0)
            f, why = M.field_at(t, off)
            if not f:
                rej[why or "no-type"] += 1
                return m.group(0)
            st["addr"] += 1
            mark(v)
            return "&%s.%s" % (disp(v), f[0])
        text = re.sub(r"(?<![*\w])\([\w ]+\*+\)\((" + varpat + r") \+ (" + H + r")\)",
                      addr, text)

        # 7. bare index:  V[K]
        def bare(m):
            v, k = m.group(1), ival(m.group(2))
            t = basetype(v)
            off = self.idx_off(v, k)
            f, why = M.field_at(t, off) if off is not None else (None, "no-decl")
            if not f:
                rej[why or "no-type"] += 1
                return m.group(0)
            st["bare"] += 1
            mark(v)
            return "%s.%s" % (disp(v), f[0])
        text = re.sub(r"\b(" + varpat + r")\[(" + H + r")\]", bare, text)

        # 8. bare pointer arithmetic passed by reference:  (V + K)  ->  &V.field
        def parith(m):
            v, k = m.group(1), ival(m.group(2))
            t = basetype(v)
            off = self.byte_off(v, k)
            if off is None:
                rej["no-decl"] += 1
                return m.group(0)
            f, why = M.field_at(t, off)
            if not f:
                rej[why or "no-type"] += 1
                return m.group(0)
            st["addr"] += 1
            mark(v)
            return "&%s.%s" % (disp(v), f[0])
        text = re.sub(r"(?<=[(,])(" + varpat + r") \+ (" + H + r")(?=[,)])", parith, text)

        # 9. whole-object rename: ONLY for bound params (Self / SIG args). Never blanket.
        for v, (d, _t, _c) in B.items():
            if d != v:
                text = re.sub(r"\b%s\b" % re.escape(v), d, text)

        # per-line medium-confidence marker
        if med_flag[0]:
            names = set(self.inferred)
            lines = text.split("\n")
            for i, ln in enumerate(lines):
                for nm in names:
                    if re.search(r"\b%s\." % re.escape(nm), ln):
                        lines[i] = ln + "  // ~inferred-type"
                        break
            text = "\n".join(lines)
        self.medium = med_flag[0]
        return text

    # -------- symbol resolution (zero-risk lookups) -------------------------
    def resolve_symbols(self, text):
        M, st = self.M, self.st

        def fun(m):
            va = int(m.group(1), 16)
            nm = M.va_name.get(va)
            if nm:
                st["fun_named"] += 1
                return nm
            return m.group(0)
        text = re.sub(r"\bFUN_([0-9a-f]{6,8})\b", fun, text)

        def ctref(m):
            t = M.ctva.get(int(m.group(1), 16))
            if t:
                st["classtable_named"] += 1
                return "ClassTable_%s" % t
            return m.group(0)
        text = re.sub(r"&PTR_\w*?_?([0-9a-fA-F]{6,8})\b", ctref, text)

        n = text.count("&DAT_" + NULL_DAT)
        if n:
            st["null_named"] += n
            text = text.replace("&DAT_" + NULL_DAT, "Null")
        return text

    # ============================================================ SYMBOL LAYER
    # Five things that are otherwise re-derived by hand, one function at a time. Each is a
    # LOOKUP against a table with known provenance, and each returns nothing rather than
    # a guess -- the same contract the offset rules R1-R5 already run under.
    #
    #   1 call target NAMES        brl_functions / runtime_helpers / vtable_map /
    #                              src/recovered_module headers
    #   2 argument COUNTS          the `add esp,N` after each call, tabulated by
    #                              a separate arity scan
    #   3 string LITERALS          BBString decode, gated on the class pointer
    #   4 GLOBALS                  globals_final.tsv, with class-table slots called out
    #   5 class-table INDIRECTS    helper_map.resolve_slot + the inheritance walk

    #   Ghidra token forms that carry an address. LAB_ is a local label, not data.
    TOKEN_RX = re.compile(r"(&?)\b((?!LAB_)\w+?)_(00[0-9a-fA-F]{6})\b")

    def annotate_addresses(self, text):
        """Inline substitution of every address token this project can prove a meaning for.

        The raw token is never simply dropped: each substitution is recorded in `self.legend`
        so the annotated file still carries the address, the evidence class, and the full
        detail. Unresolvable tokens are left exactly as Ghidra wrote them.
        """
        R = _RES
        st = self.st
        self.legend = {}
        if R is None:
            return text

        def sub(m):
            amp, pre, hexs = m.group(1), m.group(2), m.group(3)
            va = int(hexs, 16)
            if va == int(NULL_DAT, 16):
                return m.group(0)                    # already handled -> Null
            d = R.describe(va, self.M)
            if d is None:
                raw = R.raw_note(va)
                if raw and pre in ("DAT", "_DAT", "PTR_DAT", "PTR_PTR", "UNK"):
                    self.legend.setdefault(m.group(0).lstrip("&"), (va, raw))
                    st["raw_noted"] += 1
                return m.group(0)
            kind, rest = d.split(" ", 1)
            if kind == "STR":
                st["string_decoded"] += 1
                self.legend.setdefault(m.group(0).lstrip("&"), (va, d))
                return rest                          # the literal text, in place
            if kind == "FN":
                st["call_named"] += 1
                self.legend.setdefault(rest, (va, d))
                return rest
            if kind == "CTSLOT":
                st["ctslot_resolved"] += 1
                nm = rest.split(" = ")
                if len(nm) == 2 and "+0x" in nm[0]:
                    t = nm[0].split("+")[0]
                    meth = nm[1].split(" ")[0]
                    disp = "%s.%s" % (t, meth)
                else:
                    disp = rest.replace(" ", "_")
                self.legend.setdefault(disp, (va, d))
                return disp
            if kind == "GLOBAL":
                st["global_named"] += 1
                nm = rest.split(":")[0]
                self.legend.setdefault(nm, (va, d))
                return nm
            self.legend.setdefault(m.group(0).lstrip("&"), (va, d))
            return m.group(0)

        return self.TOKEN_RX.sub(sub, text)

    def call_table(self, va):
        """The `add esp,N` derived argument counts for every call site in this function.

        THIS IS THE ANSWER TO 'how many arguments does that call really take'. Ghidra's
        printed list is not: in one measured sample, 4 of 10 bodies written from it had
        the count wrong. Sites are listed in address order; a callee that is called more than once
        appears once per site, because a disagreement between two sites is information.
        """
        R = _RES
        if R is None or va is None:
            return []
        rows = _SITES.get(va, [])
        out = []
        for cva, kind, tgt, argb, shape in rows:
            if kind == "direct" and tgt is not None:
                who = R.name_for(tgt) or ("FUN_%08x" % tgt)
            elif kind == "ct" and tgt is not None:
                d = R.describe(tgt, self.M) or ""
                who = d[7:] if d.startswith("CTSLOT ") else ("[0x%08x]" % tgt)
            elif kind == "virt":
                who = "vtable +0x%x (receiver-dependent)" % tgt
            else:
                who = "indirect"
            if argb is None:
                note = "args=UNKNOWN (%s)" % (shape or "no add esp")
            else:
                n = len([s for s in shape.split(",") if s]) if shape else 0
                note = "args=%d bytes=%d [%s]" % (n, argb, shape)
                if kind in ("direct", "ct") and tgt is not None:
                    a = R.arity_for(kind, tgt)
                    if a:
                        # a[3]=sites agreeing with the mode, a[4]=all sites, a[5]=sites the
                        # scanner could not read at all. An UNREADABLE site is NOT a site
                        # that disagreed, and conflating the two would manufacture doubt
                        # about counts that nothing actually contradicts.
                        unread = a[5] if len(a) > 5 else 0
                        conflict = a[4] - a[3] - unread
                        if conflict:
                            note += " (callee DISPUTED: %d/%d sites, %d disagree)" % (
                                a[3], a[4], conflict)
                        elif unread:
                            note += " (%d sites agree, %d unreadable)" % (a[3], unread)
                        else:
                            note += " (%d sites agree)" % a[4]
            out.append((cva, kind, who, note))
        return out


# ---------------------------------------------------------------- v1 replay

def v1_replay(text, owner, mdl):
    """Reproduce the simpler v1 ruleset (four offset rules plus a blanket param_1 rename),
    and classify each resolution as CORRECT or WRONG under the v2 rules this module
    applies. Counting only, no output."""
    m = mdl.m.get(owner)
    if not m:
        return Counter()
    F = {x["offset"]: x for x in m["members"] if x["kind"] == "Field"}
    if owner in ("TClub", "TNation") and "TBase_Team" in mdl.m:
        F.update({x["offset"]: x for x in mdl.m["TBase_Team"]["members"] if x["kind"] == "Field"})
    S = {x["offset"]: x for x in m["members"] if x["kind"] in ("Method", "Function")}
    hd = parse_header(text)
    kind = hd.get("KIND", "")
    args, _ = split_sig_args(hd.get("SIG", ""))
    # under v2: param_1 is Self only for Methods
    p1_is_owner = (kind == "Method")
    c = Counter()
    for mm in re.finditer(r"\(\*\*\(code \*\*\)\(\*param_1 \+ (0x[0-9a-fA-F]+)\)\)\(param_1,?\s*", text):
        if ival(mm.group(1)) in S:
            c["v1_res"] += 1
            c["v1_wrong" if not p1_is_owner else "v1_ok"] += 1
    for mm in re.finditer(r"\*\((\w+) \*\)\(param_1\[(0x[0-9a-fA-F]+|\d+)\] \+ (0x[0-9a-fA-F]+)\)", text):
        c["v1_res"] += 1
        c["v1_wrong" if not p1_is_owner else "v1_ok"] += 1
    for mm in re.finditer(r"param_1\[(0x[0-9a-fA-F]+|\d+)\]", text):
        if ival(mm.group(1)) * 4 in F:
            c["v1_res"] += 1
            c["v1_wrong" if not p1_is_owner else "v1_ok"] += 1
    for mm in re.finditer(r"\*\((\w+) \*\)\(param_1 \+ (0x[0-9a-fA-F]+)\)", text):
        if ival(mm.group(2)) in F:
            c["v1_res"] += 1
            c["v1_wrong" if not p1_is_owner else "v1_ok"] += 1
    c["v1_selfrename"] = len(re.findall(r"\bparam_1\b", text))
    if not p1_is_owner:
        c["v1_selfrename_wrong"] = c["v1_selfrename"]
    return c


# ---------------------------------------------------------------- batch driver

def rows():
    with open(INDEX, encoding="utf-8") as f:
        head = f.readline().rstrip("\n").split("\t")
        for ln in f:
            c = ln.rstrip("\n").split("\t")
            if len(c) >= 7:
                yield dict(zip(head, c))


def collision_rate(mdl):
    """Red-team measurement: what fraction of 4-aligned in-range offsets land on a field?"""
    tot = hit = 0
    per = []
    for t in mdl.m:
        isz = mdl.isize(t)
        if isz >= 1 << 29 or isz <= HDR:
            continue
        F = mdl.fields(t)
        slots = range(HDR, isz, 4)
        h = sum(1 for o in slots if o in F)
        n = len(list(slots))
        tot += n
        hit += h
        per.append((t, h, n))
    return hit, tot, per


def header_blocks(ann):
    """The CALLS and SYMBOLS blocks, in the comment header of every annotated file."""
    out = []
    if ann.calls:
        out.append("//")
        out.append("// ---- CALLS -- argument counts from the `add esp,N` after each call.")
        out.append("//      GHIDRA'S PRINTED ARGUMENT LIST IS NOT EVIDENCE: it merges a")
        out.append("//      callee's arguments with the pushes of the FOLLOWING call.")
        out.append("//      These counts are. bytes=8 for one argument means a Double.")
        for cva, kind, who, note in ann.calls:
            out.append("// CALL 0x%08x  %-6s %-46s %s" % (cva, kind, who[:46], note))
    if ann.legend:
        out.append("//")
        out.append("// ---- SYMBOLS -- every address token this project can prove a meaning for.")
        out.append("//      The substituted name appears inline in the body below; the raw")
        out.append("//      address is kept here so nothing is lost. Tokens absent from this")
        out.append("//      block were left exactly as Ghidra wrote them.")
        for nm, (va, what) in sorted(ann.legend.items(), key=lambda kv: kv[1][0]):
            out.append("// SYM  0x%08x  %-34s %s" % (va, nm[:34], what))
    return ("\n".join(out) + "\n") if out else ""


def main():
    mode = sys.argv[1] if len(sys.argv) > 1 else "--all"
    load_sites()
    mdl = Model()
    ann = Annotator(mdl)

    if mode == "--collision":
        hit, tot, per = collision_rate(mdl)
        print("collision: %d/%d = %.2f%%" % (hit, tot, 100.0 * hit / tot))
        dense = sum(1 for _t, h, n in per if h == n)
        print("fully dense types: %d / %d" % (dense, len(per)))
        for t, h, n in sorted(per, key=lambda x: x[1] / max(x[2], 1))[:8]:
            print("  sparsest %-22s %d/%d" % (t, h, n))
        return

    if mode == "--file":
        p = os.path.join(DECOMP, sys.argv[2])
        text = open(p, encoding="utf-8", errors="replace").read()
        out, hd, st, rej, inf = ann.run(text, sys.argv[2])
        print(header_blocks(ann) + out)
        sys.stderr.write("%s\n%s\n%s\n" % (dict(st), dict(rej), inf))
        return

    write = (mode == "--all")
    if write:
        os.makedirs(OUTDIR, exist_ok=True)
    agg, agg_rej, v1agg = Counter(), Counter(), Counter()
    nfiles = 0
    conf_counts = Counter()
    for r in rows():
        p = os.path.join(DECOMP, r["file"])
        if not os.path.exists(p):
            continue
        text = open(p, encoding="utf-8", errors="replace").read()
        out, hd, st, rej, inf = ann.run(text, r["file"])
        nfiles += 1
        for k, v in st.items():
            if k not in ("expected_params", "decl_params"):
                agg[k] += v
        agg_rej.update(rej)
        v1agg.update(v1_replay(text, r["type"], mdl))
        resolved = sum(st[k] for k in ("bare", "direct", "nested", "vcall", "vcall_field", "addr"))
        rejected = sum(rej.values())
        agg["resolved"] += resolved
        agg["rejected"] += rejected
        conf = "NONE" if resolved == 0 else ("MEDIUM" if ann.medium else "HIGH")
        conf_counts[conf] += 1
        if write:
            hdr = ("// ANNOTATED-BY=annotate (symbol layer)\n"
                   "// CONFIDENCE=%s\n"
                   "// STATS resolved=%d rejected-raw=%d typed-locals=%d\n"
                   "// SELF=%s\n" % (conf, resolved, rejected, len(inf),
                                     "param_1" if r["kind"] == "Method" else "none (KIND=Function)"))
            if inf:
                hdr += "// INFERRED " + " ".join("%s:%s" % kv for kv in sorted(inf.items())) + "\n"
            hdr += header_blocks(ann)
            open(os.path.join(OUTDIR, r["file"]), "w", encoding="utf-8", newline="\n").write(hdr + out)
            json.dump({"file": r["file"], "type": r["type"], "kind": r["kind"],
                       "confidence": conf, "resolved": resolved, "rejected": rejected,
                       "sites": dict(st), "rejects": dict(rej), "inferred": inf,
                       "calls": [{"va": "0x%08x" % c[0], "kind": c[1],
                                  "target": c[2], "args": c[3]} for c in ann.calls],
                       "legend": {k: {"va": "0x%08x" % v[0], "what": v[1]}
                                  for k, v in sorted(ann.legend.items())}},
                      open(os.path.join(OUTDIR, r["file"] + ".stats.json"), "w",
                           encoding="utf-8", newline="\n"), indent=1, sort_keys=True)
    print("files=%d" % nfiles)
    print("v2 " + " ".join("%s=%d" % kv for kv in sorted(agg.items())))
    print("rej " + " ".join("%s=%d" % kv for kv in sorted(agg_rej.items())))
    print("v1 " + " ".join("%s=%d" % kv for kv in sorted(v1agg.items())))
    print("conf " + " ".join("%s=%d" % kv for kv in sorted(conf_counts.items())))


if __name__ == "__main__":
    main()
