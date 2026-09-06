#!/usr/bin/env python
"""
Reconstruction harness for NSS5 byte-exact source recovery.

Given (TypeName, MethodName, candidate BlitzMax body) this:
  1. emits a self-contained .bmx with EVERY game Type (exact field order/offsets,
     methods as stubs in exact vtable slot order, correct Extends),
     the target method carrying the candidate body;
  2. builds it with the legacy BlitzMax toolchain (mingw put on PATH -- gcc fails
     silently otherwise);
  3. runs bytematch.py and returns MATCH / MISMATCH / BUILD_FAIL.

Library:  from harness import try_method; r = try_method("TFormation","GetRow", body)
CLI:      python harness.py TFormation GetRow body.bmx  [--keep]
          python harness.py --selftest

Concurrency-safe: every invocation gets its own uuid temp dir.
"""

import json
import os
import re
import shutil
import subprocess
import sys
import random
import struct
import tempfile
import time
import uuid

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
# PER-WORKER TOOLCHAIN
# ===================
# bmk/fasm/gcc keep scratch state inside the BlitzMax tree, so two concurrent builds in
# the same tree corrupt each other -- measured at 6 parallel builds producing 4 false
# MISMATCHes. A global mutex prevents that, but it serialises every verification in the
# project on one ~1.2s build, which with a dozen passes is the throughput ceiling for the
# whole effort.
#
# Giving each worker its own copy of the tree removes the shared state entirely, so the
# lock only has to be per-tree and builds genuinely run in parallel. A copy is 212 MB.
# Set NSS5_WORKER=<n> to use (or lazily create) tools/bmx-workers/<n>, or point
# NSS5_BMX_ROOT at a tree directly.
BASE_BMX_ROOT = os.path.join(ROOT, "tools", "blitzmax-legacy-src")
WORKERS_DIR = os.path.join(ROOT, "tools", "bmx-workers")

# ---------------------------------------------------------------- NSS5_NO_LEARN
# STUBBING helper_map.record IS NOT ENOUGH TO TURN LEARNING OFF, and any check that
# relies on it to claim "no function can contribute the table row that then masks its own
# call operand" is unsound. Stubbing record() suppresses only the PERSISTENCE of a learned
# row to extracted/runtime_helpers.tsv. In-run learning is independent of it:
#
#     _persisted, conflicts = _helper_map.record(...)   <- stubbing reaches only THIS
#     for _v, _sy, _known in learn:
#         origtab.setdefault(_v, (_sy, 1))              <- and this still runs
#     ... then re-compares with mode == "learn"
#
# so a body that differs from the original at exactly one unnamed call operand teaches
# itself the name and re-compares clean, inside the same try_method() call, whether or not
# record() is a no-op. That is precisely the self-fulfilling masking the stub is meant to
# prevent, and any row reporting `learned_helpers` is decided that way.
#
# NSS5_NO_LEARN=1 forces `learn=None`, so an unnamed original-side call operand simply
# fails to mask and the row reports MISMATCH. Default OFF: normal batch work still learns,
# which is how the runtime-helper table is bootstrapped. ANY CHECK OF THE CORPUS MUST SET
# IT. Measured blast radius of switching it on: 4 of 1,284 rows change verdict.
NO_LEARN = os.environ.get("NSS5_NO_LEARN", "") not in ("", "0", "false", "False")


def _resolve_bmx_root():
    explicit = os.environ.get("NSS5_BMX_ROOT")
    if explicit:
        return explicit
    w = os.environ.get("NSS5_WORKER")
    if not w:
        return BASE_BMX_ROOT
    tree = os.path.join(WORKERS_DIR, str(w))
    if not os.path.exists(os.path.join(tree, "bin", "bmk.exe")):
        os.makedirs(WORKERS_DIR, exist_ok=True)
        # A HALF-POPULATED SLOT USED TO FAIL OBSCURELY. os.replace() cannot overwrite a
        # non-empty directory on Windows, so if `tree` already existed without a toolchain
        # in it, this raised from deep inside the copy rather than saying what was wrong.
        #
        # The two cases are worth separating, and the difference is not cosmetic:
        #
        #   EMPTY -- nothing is lost by removing it, and it is the ordinary residue of an
        #   interrupted run or a deletion pass. Self-heal silently.
        #
        #   NON-EMPTY -- this function never produces that. A failed copy lands in
        #   `tree + ".partial"` and is only renamed into place once complete, so a populated
        #   `tree` with no bin/bmk.exe was put there by something else. It happened:
        #   tools/bmx-workers/603 held hand-written null-dereference probes (now in
        #   scripts/probes/), and a reclamation pass spared them only by accident. Deleting
        #   to make regeneration work would destroy exactly the kind of work that has no
        #   other copy, so refuse and say so instead.
        if os.path.isdir(tree):
            if os.listdir(tree):
                raise RuntimeError(
                    "NSS5_WORKER=%s points at %s, which exists and is not empty but has no "
                    "bin/bmk.exe, so it is not a toolchain copy.\nThis is NOT deleted "
                    "automatically: worker trees are disposable, but whatever is in this one "
                    "was not put there by the harness and may be the only copy.\nMove its "
                    "contents somewhere durable, remove the empty directory, and re-run -- "
                    "the tree then rebuilds itself in 30-60s." % (w, tree))
            os.rmdir(tree)
        tmp = tree + ".partial"
        shutil.rmtree(tmp, ignore_errors=True)
        shutil.copytree(BASE_BMX_ROOT, tmp)      # ~30-60s, once per worker
        os.replace(tmp, tree)
    return tree


BMX_ROOT = _resolve_bmx_root()
BMK = os.path.join(BMX_ROOT, "bin", "bmk.exe")
MINGW = os.path.join(BMX_ROOT, "_mingw", "mingw", "bin")
BYTEMATCH = os.path.join(ROOT, "scripts", "bytematch.py")
OBJECT_MODEL = os.path.join(ROOT, "extracted", "object_model.json")
VTABLE_MAP = os.path.join(ROOT, "extracted", "vtable_map.tsv")
CLASS_TABLES = os.path.join(ROOT, "extracted", "class_tables.tsv")
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import bytematch as _bytematch          # noqa: E402
import helper_map as _helper_map        # noqa: E402

# Types that live in BRL/PUB modules. We never Import them (module type names would
# collide and slow the build); they become empty local placeholders. Object fields are
# 4-byte pointers regardless of type, so offsets stay correct. Bodies that actually
# CALL methods on these cannot be matched by this harness -- excluded from the workset.
RUNTIME_SUPERS = {"Object(runtime)", "Object", "", "-"}

# TList MUST come from BRL, never a local stub Type. Around 10 of 17 bodies in a batch
# genuinely call items.Count() / list.AddLast(), and a stub cannot produce the
# right call. BRL 1.50's LinkedList slot layout is identical to the original's
# (Count at [eax+0x70], AddLast at [eax+0x44]), so Import the real module instead of
# emitting these, and keep the names in the known-type set so ':TList' in a signature
# stays TList rather than degrading to Object.
MODULE_TYPES = {"TList": "BRL.LinkedList",
                "TLink": "BRL.LinkedList",
                "TListEnum": "BRL.LinkedList",
                # Same reasoning as TList: these are BRL Types, not game Types, so a
                # local stub produces the wrong call. Import the real module and let its
                # slot layout be the authority. Each addition must be re-validated by the
                # regression gate (selftest + the three probe scripts).
                "TStream": "BRL.Stream",
                "TStreamWrapper": "BRL.Stream",
                "TTextStream": "BRL.TextStream",
                # THE BRL MEDIA TYPES. Import them; never stub them, and never work around
                # this in a private copy of the harness -- a body that only builds against
                # a patched harness is not reproducible for anyone else.
                #
                # These Types are reflected out of NSS5.exe like game Types, so without
                # this entry _build_prelude emits a local `Type TImage / End Type` that
                # SHADOWS BRL's real one -- while DrawImage/PlaySound/StopChannel, reached
                # through the imports, still want BRL's. The symptom is the self-contradictory
                # `Compile Error: Unable to convert from 'TSound' to 'TSound'`.
                #
                # Slot layout was checked against NSS5's own reflection before adding each
                # one, because an Imported type's slots become the authority for any
                # method call on it:
                #   TImage      0x30 _pad,0x34 Frame,0x38 Lock,0x3c SetPixmap,0x40 Create,
                #               0x44 Load,0x48 LoadAnim          -- identical, and the
                #               instance size agrees exactly (52 = 8 hdr + 44 fields)
                #   TChannel    0x30 Stop,0x34 SetPaused,0x38 SetVolume,0x3c SetPan,
                #               0x40 SetDepth,0x44 SetRate,0x48 Playing   -- identical
                #   TSound      Play/Cue/Load, no fields, size 8          -- identical
                #   TMap        0x30 Clear .. 0x74 _DeleteFixup, size 12  -- identical
                # TImageFont and TPixmap likewise come from the same two modules.
                "TImage": "BRL.Max2D",
                "TImageFont": "BRL.Max2D",
                "TPixmap": "BRL.Pixmap",
                "TSound": "BRL.Audio",
                "TChannel": "BRL.Audio",
                "TMap": "BRL.Map",
                # TOptions.SetUp walks GraphicsModes():TGraphicsMode[] (BRL.Graphics).
                # Same shadowing symptom as TImage/TSound above ("Unable to convert from
                # 'TGraphicsMode' to 'TGraphicsMode'"). Reflection confirms identical layout:
                # Field width,height,depth,hertz @ 8,12,16,20; New=0x10,Delete=0x14,
                # ToString=0x18 -- matches brl.mod/graphics.mod/graphics.bmx exactly.
                "TGraphicsMode": "BRL.Graphics",
                # TProfile.SaveGame calls CreateBank(0), which returns BRL's own
                # TBank. Same shadowing symptom as TSound/TImage/TGraphicsMode above
                # ("Unable to convert from 'TBank' to 'TBank'"). Reflection (vtable_map.tsv)
                # confirms identical layout against bank.mod/bank.bmx: New=0x10, Delete=0x14,
                # _pad=0x30, Buf=0x34, Lock=0x38, Unlock=0x3c, Size=0x40, Capacity=0x44,
                # Resize=0x48, Read=0x4c, Write=0x50, PeekByte..PokeDouble=0x54..0x80,
                # Save=0x84, Load=0x88 (Function), Create=0x8c (Function),
                # CreateStatic=0x90 (Function) -- matches the module source exactly.
                "TBank": "BRL.Bank"}

_CACHE = {}
_GAME = set()      # every Type we emit; unknown object types degrade to Object (4 bytes)
_TYPETEXT = {}     # tname -> emitted stub text (prelude cache; see build_source)
_ORDER = []
_PRELUDE = {}      # tname -> (head, tail) joined text around the target Type
_HEADER = []       # [0] = SuperStrict + Imports + placeholder Types


# ---------------------------------------------------------------- signature parsing
def parse_sig_atom(s, i):
    """-> (blitzmax type string, next index)"""
    c = s[i]
    if c == "[":
        j = s.index("]", i)
        dims = s[i + 1:j].count(",")
        inner, k = parse_sig_atom(s, j + 1)
        return inner + "[" + "," * dims + "]", k
    if c == "*":
        inner, k = parse_sig_atom(s, i + 1)
        if inner not in ("Byte", "Short", "Int", "Long", "Float", "Double"):
            # `*` in a reflection signature is BY-REFERENCE, which BlitzMax spells `Var`.
            # For a SCALAR, `Int Var` and `Int Ptr` are the same four bytes and the same
            # codegen, so scalars are lowered to `Ptr`: every verified body with a
            # `*i`/`*f` parameter is written against `Ptr` and must not be disturbed.
            #
            # For a STRING or an OBJECT the `Ptr` lowering is wrong and not merely
            # cosmetic: `String Ptr` is illegal in BlitzMax, so it degrades to `Byte Ptr`
            # and bcc rejects every body that uses the parameter with
            #     Compile Error: Pointer type mismatch
            # -- which is indistinguishable from a wrong body. `String Var` / `TFoo Var`
            # are legal and are what the original declared. Measured: no file in
            # src/recovered/ or src/recovered_module/ has a `*$` or `*:T` parameter (all
            # 12 `*` sigs in the corpus are scalar), so the `Var` lowering cannot alter any
            # existing verification -- it only makes an otherwise unbuildable shape build.
            return inner + " Var", k
        return inner + " Ptr", k
    if c == ":":
        # A reflection signature may NAMESPACE a class name -- `(:brl.stream.TStream)i` --
        # so the scan must consume '.' as part of the name. Stopping at the first '.'
        # yields the type `brl` and re-parses `.stream.TStream` as a run of bogus atoms:
        # the method decodes to `Object` followed by junk Int parameters, every body using
        # the parameter fails with
        #     Compile Error: Unable to convert from 'Object' to 'TStream'
        # which is indistinguishable from a wrong body, and assembly is blocked outright.
        #
        # '.' cannot appear in a reflection signature except inside a namespaced class
        # name, so consuming it is unambiguous. Blast radius measured over the whole
        # reflection table: THREE methods carry a namespaced type -- SZIPCentralFileHeader
        # .fill, SZIPFileDataDescriptor.fill, ZipWriter.AddStream -- and none of the three
        # is buildable without this, so no existing verification can change.
        j = i + 1
        while j < len(s) and (s[j].isalnum() or s[j] in "_."):
            j += 1
        nm = s[i + 1:j].split(".")[-1]
        return (nm if (not _GAME or nm in _GAME) else "Object"), j
    if c == "(":                      # function pointer
        depth, j = 1, i + 1
        while depth:
            if s[j] == "(":
                depth += 1
            elif s[j] == ")":
                depth -= 1
            j += 1
        args = split_args(s[i + 1:j - 1])
        ret, k = parse_sig_atom(s, j)
        named = ",".join("p%d:%s" % (n, a) for n, a in enumerate(args))
        return "%s(%s)" % (ret, named), k
    return {"b": "Byte", "s": "Short", "i": "Int", "l": "Long", "f": "Float",
            "d": "Double", "$": "String", "v": "Int", "z": "Byte Ptr"}.get(c, "Int"), i + 1


def split_args(s):
    out, i = [], 0
    while i < len(s):
        if s[i] == ",":
            i += 1
            continue
        t, i = parse_sig_atom(s, i)
        out.append(t)
    return out


def parse_sig(sig):
    """'(i,f)i' -> (['Int','Float'], 'Int')"""
    if not sig.startswith("("):
        return [], parse_sig_atom(sig, 0)[0]
    depth, j = 1, 1
    while depth:
        if sig[j] == "(":
            depth += 1
        elif sig[j] == ")":
            depth -= 1
        j += 1
    return split_args(sig[1:j - 1]), parse_sig_atom(sig, j)[0]


def field_type(sig):
    return parse_sig_atom(sig, 0)[0]


def field_size(bmt):
    if bmt.endswith("]") or bmt.endswith("Ptr") or bmt == "String" or bmt[:1] == "T":
        return 4
    return {"Byte": 1, "Short": 2, "Int": 4, "Float": 4, "Long": 8, "Double": 8}.get(bmt, 4)


# ---------------------------------------------------------------- data loading
def _require(path):
    """Fail with the command that creates `path`, not with a bare traceback.

    A tracked-files-only checkout has no extracted/ at all, so load_data() used to
    raise FileNotFoundError on extracted/object_model.json -- which is the first
    thing a newcomer sees after following the README, and it names neither the
    tool that writes the file nor the fact that setup.py is what runs it.
    """
    if os.path.exists(path):
        return path
    name = os.path.basename(path)
    how = {"object_model.json": "python scripts/parse_reflection.py",
           "vtable_map.tsv": "python scripts/resolve_vtables.py",
           "class_tables.tsv": "python scripts/resolve_vtables.py"}.get(name)
    raise SystemExit(
        "\nMISSING: extracted/%s\n\n"
        "  This is derived from your own copy of the game and is not in the\n"
        "  repository. Run setup, which populates all of it:\n\n"
        "      python scripts/setup.py\n"
        "%s\n"
        "  If binary/NSS5.exe is also missing, setup.py is what puts it there --\n"
        "  see the Building section of README.md.\n"
        % (name, ("\n  (this one file alone: %s)\n" % how) if how else ""))


def load_data():
    if _CACHE:
        return _CACHE
    fields = {}
    for t in json.load(open(_require(OBJECT_MODEL), encoding="utf8")):
        fields[t["type"]] = [m for m in t["members"] if m["kind"] == "Field"]
    methods = {}
    with open(_require(VTABLE_MAP), encoding="utf8") as f:
        next(f)
        for line in f:
            p = line.rstrip("\n").split("\t")
            if len(p) < 6:
                continue
            methods.setdefault(p[0], []).append(
                {"kind": p[1], "name": p[2], "sig": p[3], "slot": int(p[4], 16), "va": p[5]})
    supers = {}
    with open(_require(CLASS_TABLES), encoding="utf8") as f:
        next(f)
        for line in f:
            p = line.rstrip("\n").split("\t")
            if len(p) >= 4:
                supers[p[0]] = p[3]
    _GAME.update(set(methods) | set(fields))
    _CACHE.update(fields=fields, methods=methods, supers=supers)
    return _CACHE


# ---------------------------------------------------------------- emission
def emit_type(tname, d, target=None, body=None, field_decls=None, bodies=None):
    """Emit one Type. `target`/`body` fill ONE member; `bodies` fills MANY.

    THIS FUNCTION REPLACES, IT DOES NOT ACCUMULATE. It builds its output from `d` alone
    and returns a fresh string; it never reads the previous text for this Type. So calling
    it in a loop, once per recovered body, and assigning the result back into _TYPETEXT
    keeps only the LAST body: for a Type with N recovered bodies the first N-1 vanish.
    Measured over the whole corpus: 1,144 bodies fed in that way, 144 in the emitted file,
    1,000 discarded (TPlayer: 71 bodies in, 1 out), and a counter that reports "bodies
    placed" from the input side shows nothing wrong.

    `bodies` is {exact member name: body text} and fills every one of them in a single
    pass, which is the correct way to place more than one. The single-target path must
    keep producing byte-identical probes, because build_source() -- the verification
    path -- uses it.
    """
    fields = d["fields"].get(tname, [])
    field_decls = field_decls or {}
    tb = dict(bodies or {})
    if target is not None:
        tb[target] = body
    methods = sorted(d["methods"].get(tname, []), key=lambda m: m["slot"])
    sup = d["supers"].get(tname, "Object")
    ext = "" if sup in RUNTIME_SUPERS or sup not in d["supers"] else " Extends " + sup

    out = ["Type %s%s" % (tname, ext)]

    # -- fields, in offset order, padding any hole so offsets stay exact
    cur = 8
    if ext:
        cur = None                        # inherited layout; trust declared offsets
    npad = 0
    for f in fields:
        bt = field_type(f["sig"])
        if cur is not None and f["offset"] > cur:
            # NEVER pad with `Byte[n]`. In BlitzMax an array field is a 4-byte POINTER,
            # not n inline bytes, so a 2-byte hole silently became 4 and every later
            # field shifted (SZIPCentralFileHeader.ExternalFileAttributes landed at
            # 0x2C instead of 0x28 -> `8B 40 2C` where the original has `8B 40 28`).
            # Fill with scalars whose size IS their storage, largest first, respecting
            # natural alignment so bcc does not insert padding of its own.
            # DO NOT PAD A HOLE bcc WOULD CREATE ANYWAY.
            #
            # Measured, not assumed: a probe with `Field t:Byte / Field w:Int` puts w at
            # +4, and so does `Field t:Byte / Field p1:Byte / Field p2:Short / Field w:Int`
            # -- bcc aligns a field to its own natural boundary with no help from us. So
            # for a hole that is EXACTLY that natural padding, an explicit __pad field is
            # redundant for layout and actively harmful for codegen: bcc's generated New
            # zero-initialises every declared field, so each pad adds a store the original
            # never had. TSnowFlake.New (t:Byte@0x20, w:Int@0x24) came out 124 bytes
            # against the original's 114, the whole 10-byte excess being
            # `mov byte [ebx+0x21],0` + `mov word [ebx+0x22],0` for two pads.
            #
            # Only holes LARGER than natural alignment are real and still get filled.
            # Blast radius of this rule over the whole object model is exactly two Types,
            # SZIPCentralFileHeader (+0x26 -> +0x28) and TSnowFlake (+0x21 -> +0x24);
            # every other hole is a genuine one and is padded.
            # The cap is 8, not 4: bcc aligns a Long/Double field to EIGHT, and a hole
            # in front of one is therefore padding it would create anyway. zip_fileinfo
            # is the case that proves it -- tmz_date:tm_zip ends at +0xC and dosDate:Long
            # starts at +0x10, and the original `New` (0x0058EED0, 95 bytes) zeroes
            # +0x10..+0x27, the three Longs, and never touches +0xC. Capping at 4 made
            # that hole look real, added `Field __pad0:Int`, and the extra
            # `mov [ebx+0xC],0` alone put our New at 134 bytes.
            # Blast radius of 4 -> 8 over the whole object model is exactly two Types,
            # zip_fileinfo and TVolSpace; no other hole sits in front of an 8-byte field.
            _al = min(field_size(bt), 8)
            if (cur + _al - 1) // _al * _al == f["offset"]:
                cur = f["offset"]
            rem = f["offset"] - cur
            while rem > 0:
                if cur % 4 == 0 and rem >= 4:
                    sz, ty = 4, "Int"
                elif cur % 2 == 0 and rem >= 2:
                    sz, ty = 2, "Short"
                else:
                    sz, ty = 1, "Byte"
                out.append("\tField __pad%d:%s" % (npad, ty))
                npad += 1
                cur += sz
                rem -= sz
            cur = f["offset"]
        # A '!Field pragma may override the DECLARATION TEXT of this field (to attach an
        # initialiser, or to size an array). It never changes the field's SIZE -- the
        # offset arithmetic below still uses the object-model type, so layout is safe.
        ov = field_decls.get(f["name"].lower())
        if ov is None:
            out.append("\tField %s:%s" % (f["name"], bt))
        elif ov.startswith(":"):
            out.append("\tField %s%s" % (f["name"], ov))
        else:
            out.append("\tField %s:%s %s" % (f["name"], bt, ov))
        if cur is not None:
            cur = f["offset"] + field_size(bt)

    # -- methods, in vtable slot order, with pad stubs across holes
    slot = None
    seen = set()
    for m in methods:
        name, kind, sig = m["name"], m["kind"], m["sig"]
        if name in ("New", "Delete") and m["slot"] in (0x10, 0x14):
            if name not in tb:
                continue                  # implicit; emitting empties is noise
        # pad only inside the user-slot region; 0x10..0x2C are Object's own slots
        # (New/Delete/ToString/Compare/SendMessage...) and must never be padded.
        # NEVER pad a Type that Extends: the parent already supplies the low slots, so
        # an extra stub shifts EVERY child slot (TCone Extends TTrainingObject emitted
        # FF 50 50 where the original has FF 50 4C).
        if slot is not None and m["slot"] >= 0x30 and not ext:
            for s in range(max(slot + 4, 0x30), m["slot"], 4):
                out.append("\tMethod __slot%02X:Int()\n\tEnd Method" % s)
        slot = m["slot"]
        key = (name.lower(),)
        emit_name = name
        if key in seen and name not in tb:
            emit_name = name + "__dup%X" % m["slot"]
        seen.add(key)

        args, ret = parse_sig(sig)
        arglist = ", ".join("a%d:%s" % (i, a) for i, a in enumerate(args))
        kw = "Function" if kind == "Function" else "Method"
        if emit_name in ("New", "Delete"):
            head = "\tMethod %s()" % emit_name
        else:
            head = "\t%s %s:%s(%s)" % (kw, emit_name, ret, arglist)
        out.append(head)
        if name in tb:
            for ln in tb[name].rstrip().split("\n"):
                out.append("\t\t" + ln.rstrip())
        out.append("\tEnd %s" % ("Method" if kw == "Method" or emit_name in ("New", "Delete") else "Function"))

    out.append("End Type")
    return "\n".join(out)


def _build_prelude(d):
    """Emit every Type ONCE and cache the text.

    Cost measurement: emitting all 348 Types on every candidate attempt is the dominant
    python-side cost next to the ~1s build. The stub text for a non-target Type
    never changes, so it is emitted once per process and thereafter only the target Type
    is re-emitted. _PRELUDE[tname] holds the joined text before/after the target's slot
    in the declaration order, so a candidate costs two string concatenations.
    """
    if _TYPETEXT:
        return
    game = set(d["methods"]) | set(d["fields"])
    refs = set()
    for t in game:
        for f in d["fields"].get(t, []):
            for m in re.finditer(r":([A-Za-z_]\w*)", f["sig"]):
                refs.add(m.group(1))
        for mm in d["methods"].get(t, []):
            for m in re.finditer(r":([A-Za-z_]\w*)", mm["sig"]):
                refs.add(m.group(1))
        s = d["supers"].get(t, "")
        if s not in RUNTIME_SUPERS:
            refs.add(s)
    placeholders = sorted(r for r in refs
                          if r not in game and r not in MODULE_TYPES and r != "Object"
                          and re.match(r"^[A-Z]\w+$", r))

    head = ["SuperStrict", "' generated by harness.py -- do not edit"]
    for mod in sorted(set(MODULE_TYPES.values())):
        head.append("Import " + mod)
    head.append("")
    for p in placeholders:
        head.append("Type %s\nEnd Type" % p)
    head.append("")
    _HEADER.append("\n".join(head))

    # Types supplied by an imported module must NOT also be declared locally --
    # a local `Type TList` shadows/collides with BRL.LinkedList's. Emit neither a stub
    # nor a placeholder for them; the real module type is used.
    order = sorted((t for t in game if t not in MODULE_TYPES),
                   key=lambda t: (0 if d["supers"].get(t, "") in RUNTIME_SUPERS else 1, t))
    _ORDER.extend(order)
    for t in order:
        _TYPETEXT[t] = emit_type(t, d)


# ------------------------------------------------------- recovered module Functions
#
# Game code calls module-level Functions constantly -- LogLine alone from 47 functions --
# so a harness that cannot emit one leaves every such body unbuildable even when the
# module Function itself is already recovered and verified.
#
# Everything in src/recovered_module/ is byte-verified, so emitting it into the probe is
# safe: the call resolves, our side is named `_bb_<Name>` by the linker, and the original
# side is named from these same headers (see helper_map.orig_functions), so the call
# operand masks by name like any other.
MODULE_FUNC_DIR = os.path.join(ROOT, "src", "recovered_module")
MODFUNC_SEP = "\n"

# src/recovered_module/ has no tier contest -- unlike src/recovered_unverified/, which
# skips files via assemble.py's UNVERIFIED_SKIP, every file here is unconditionally wired
# into every probe and into the whole-program build. That includes its '!Import and
# '!Raw pragmas (module_imports() below), so a file here that Externs a DLL function
# makes every build and every probe that pulls in "other" module Functions demand that
# DLL at process start, whether or not the guarded call inside the body ever runs.
#
# Fn_0058D90B.SyncSteamAchievements.bmx Externs SetSteamAchievement out of
# extern/steamstub/libsteamstub.a, so its mere presence links STEAMSTUB.DLL into the
# assembled exe's import table. src/assembled/ (the run directory) does not carry
# STEAMSTUB.DLL -- it exists only under binary/, the read-only original install -- so the
# loader kills the process before any code runs (STATUS_DLL_NOT_FOUND, 0xC0000135) and no
# milestone is ever reached, not even settings read. This is exactly the Steam link
# surface src/recovered_module/SteamInit.bmx exists to keep out of the build entirely
# (see its header): that file already strips its own '!Import/'!Raw Extern pair and
# leaves the assembled program with zero Steam link surface, and this file's mere
# presence undoes that guarantee. Skip it here the same way UNVERIFIED_SKIP does for its
# siblings Fn_0058D987.SteamPostPlayerValue.bmx and TProfile.CheckAchievement.bmx --
# the body stays in the tree as byte-verified work, just not linked into anything that
# runs. TProfile.LoadSavedGame.bmx (src/recovered_unverified/) is the sole caller and
# carries its own local '!Raw placeholder declaration so the call site still compiles
# with the real body excluded.
#
# Fn_0058D987.SteamPostPlayerValue.bmx joins it for the identical reason: it Externs
# FindLeaderboard/ReadSteam/UploadLeaderboardScore out of the same import library. It moved
# into src/recovered_module/ once it reached 325/325 so that helper_map.orig_functions()
# can name VA 0x0058D987 -- without that name its sole caller, TProfile.SaveGame, has an
# `E8` that cannot mask (measured: 850/850 mode=diff, one differing operand, even with the
# real 325-byte body compiled into the probe, because compare()'s byte-level _same_callee
# fallback recurses WITHOUT the helper tables and so cannot prove a callee that itself calls
# C-runtime helpers). Being listed here is what keeps the DLL out of every probe and out of
# src/assembled/, exactly as for the sibling above; the caller carries its own '!Raw
# placeholder so the call site still compiles.
MODULE_SKIP = {
    "Fn_0058D90B.SyncSteamAchievements.bmx",
    "Fn_0058D987.SteamPostPlayerValue.bmx",
}
_MODFUNCS = []


_MODGLOBALS = []
# THE THIRD-PARTY SUBSET, kept separately as well as in _MODGLOBALS.
#
# assemble.py emits third-party module-level Functions into nss5_external.bmx, a SEPARATE
# compilation unit that nss5_assembled.bmx pulls in with `Import`. An imported unit cannot
# see the importer's Globals, so a `'!Global` lifted out of one of those files has to be
# declared in the EXTERNAL unit or the function using it does not compile at all --
# "Identifier 'g_zipfilefunc_streams' not found", from zipengine's Fn_0058FB20.
# _MODGLOBALS alone cannot express that: it is one flat list shared with
# src/recovered_module/, whose functions DO belong in the main unit. Probe builds keep
# reading _MODGLOBALS and are unaffected; only assemble.py reads this.
_TPGLOBALS = []
_MODIMPORTS = []


def module_functions():
    """-> list of full `Function ... End Function` texts, verified, ready to emit.

    Any `'!Global` pragma in one of these files is lifted into _MODGLOBALS, because a
    module Function must be self-contained: LogLine references a log TStream Global, and
    without carrying that declaration along every probe that emits LogLine fails to
    compile with "Identifier 'g_logstream' not found".

    A `'!Import` pragma must be lifted here the same way `'!Global`/`'!Raw` are. Left
    unlifted it is swallowed by the trailing "strip every comment line" filter below,
    because an unlifted `'!Import ...` line still starts with `'`, and the loss is silent
    until a file actually needs one. SteamInit.bmx is that file: it Externs `OpenSteam`
    out of libsteamstub.a, and its `'!Raw Extern Function OpenSteam...` IS lifted (via
    split_globals's RAW_PRAGMA). Without the matching Import, every OTHER probe that
    bundles SteamInit.bmx among its "others" compiles a call to a declared Extern with no
    library linked in -- `undefined reference to OpenSteam` at link time, in a probe that
    has nothing to do with Steam. Same shape as split_globals/_MODGLOBALS, so it gets the
    same treatment: lifted into _MODIMPORTS, merged by build_source_function/build_source
    via module_imports().
    """
    if _MODFUNCS:
        return _MODFUNCS
    if not os.path.isdir(MODULE_FUNC_DIR):
        return _MODFUNCS
    for fn in sorted(os.listdir(MODULE_FUNC_DIR)):
        if not fn.endswith(".bmx"):
            continue
        if fn in MODULE_SKIP:
            continue
        text = open(os.path.join(MODULE_FUNC_DIR, fn),
                    encoding="utf-8", errors="replace").read()
        text, imps = split_imports(text)
        _MODIMPORTS.extend(imps)
        text, decls = split_globals(text)
        _MODGLOBALS.extend(decls)
        lines = [l for l in text.split("\n") if not l.lstrip().startswith("'")]
        body = "\n".join(lines).strip()
        if body:
            # de-indent one level: these files are stored indented to read as members
            _MODFUNCS.append("\n".join(
                l[1:] if l.startswith("\t") else l for l in body.split("\n")))
    return _MODFUNCS


# ------------------------------------------------- third-party module Functions
# The two community modules NSS5 links (fontmachine, zipengine) have module-level
# Functions of their own, and until now nothing emitted them. A file under
# src/recovered_thirdparty/<mod>/ whose stem carries no dot is one of those -- the same
# convention load_recovered() already uses to tell a `<Type>.<Member>` file apart from a
# bare Function, which it skips outright.
#
# They must be emitted for the same reason src/recovered_module/ is: without the
# declaration, any body that CALLS one cannot be built at all, so the caller is
# unverifiable rather than merely unverified. TPrivateBitmapFont's three Draw*Text bodies
# each call both of fontmachine's point helpers (0x00592A13, 0x00592A37), which is every
# glyph the game draws.
#
# They are kept apart from module_functions() rather than folded into it because
# assemble.py routes the two lists to different compilation units: the game's own module
# Functions belong in the main module, and these belong in the external unit next to the
# third-party Types they work on.
THIRDPARTY_DIR = os.path.join(ROOT, "src", "recovered_thirdparty")
_TPFUNCS = []


def thirdparty_functions():
    """-> list of full `Function ... End Function` texts from the third-party trees."""
    if _TPFUNCS:
        return _TPFUNCS
    if not os.path.isdir(THIRDPARTY_DIR):
        return _TPFUNCS
    for sub in sorted(os.listdir(THIRDPARTY_DIR)):
        d = os.path.join(THIRDPARTY_DIR, sub)
        if not os.path.isdir(d):
            continue
        for fn in sorted(os.listdir(d)):
            if not fn.endswith(".bmx") or "." in fn[:-4]:
                continue
            text = open(os.path.join(d, fn), encoding="utf-8", errors="replace").read()
            text, imps = split_imports(text)
            _MODIMPORTS.extend(imps)
            text, decls = split_globals(text)
            _MODGLOBALS.extend(decls)
            _TPGLOBALS.extend(decls)
            lines = [l for l in text.split("\n") if not l.lstrip().startswith("'")]
            body = "\n".join(lines).strip()
            if body:
                _TPFUNCS.append("\n".join(
                    l[1:] if l.startswith("\t") else l for l in body.split("\n")))
    return _TPFUNCS


def module_imports():
    """-> deduplicated list of '!Import arguments lifted from src/recovered_module/."""
    module_functions()          # populates _MODIMPORTS as a side effect
    thirdparty_functions()      # ... and so does this one
    seen, out = set(), []
    for i in _MODIMPORTS:
        if i not in seen:
            seen.add(i)
            out.append(i)
    return out


# Uncaptured Global INITIALISERS. A bare `'!Global
# g_x:Float` declares the Global but gives it no starting value, so the assembled build
# defaults it to 0 -- silently wrong for any Global whose ORIGINAL data-section value is
# non-zero (`g_pole_maxz` = 100.0, `g_ball_snowthreshold` = 0.5, etc; see check_floats.py's
# "zero-bucket"). The fix is an initialiser on the SAME pragma line, plain BlitzMax syntax,
# nothing new to parse at the pragma-detection level (GLOBAL_PRAGMA already captures the
# whole `Global ...` remainder verbatim):
#
#     '!Global g_pole_maxz:Float = 100.0
#
# parse_global_decl() is the one place that knows how to pull (name, type, initialiser)
# back OUT of that text, mirroring split_field_decls()/FIELD_PRAGMA's separate-pass design
# rather than teaching every caller its own regex. Both harness.py (single-body probes,
# where the raw text is emitted as-is) and assemble.py (the whole-program build, which
# regenerates its OWN canonical `Global name:Type` text per name and must carry the
# initialiser through that regeneration) resolve through it.
GLOBAL_DECL_RX = re.compile(
    r"^Global\s+(\w+)\s*:\s*([^\s=]+)(?:\s*=\s*(.+?))?\s*$")


def strip_inline_comment(text):
    """Drop a trailing BlitzMax comment, respecting double-quoted strings.

    A bare `text.split("'")[0]` would corrupt `Global g_s:String = "it's"`, and this runs
    over declarations that legitimately carry string initialisers, so track quote state.
    """
    inq = False
    for i, ch in enumerate(text):
        if ch == '"':
            inq = not inq
        elif ch == "'" and not inq:
            return text[:i]
    return text


def parse_global_decl(text):
    """'Global g_x:Float = 100.0' -> ('g_x', 'Float', '100.0'); no initialiser -> None.

    A TRAILING INLINE COMMENT IS STRIPPED FIRST. GLOBAL_DECL_RX anchors end-to-end, so
    without this a pragma written as

        '!Global g_profile:TProfile            ' 0x00C6F028

    fails to parse and returns None. That is not a harmless miss:

      * merge_globals() falls back to keying dedup on the WHOLE RAW LINE when parsing
        fails, so the commented form and the plain `Global g_profile:TProfile` coming from
        _MODGLOBALS get different keys, BOTH are emitted, and the probe dies with
        "Compile Error: Duplicate identifier 'g_profile'". Measured: 52 such pragmas across
        12 files, all in src/recovered/, of which 3 bodies could not build at all
        (TPlayer.RecordReplayFrame, TScreen_MatchPrep.ButtonBooze,
        TScreen_Options.ButtonTick) -- bodies counted as byte-verified whose per-function
        probe was in fact unbuildable.
      * assemble.py's global_initialisers() uses this function to lift captured initial
        values; a commented pragma silently lost its initialiser there too.

    The address in that trailing comment is exactly the kind of provenance the corpus
    should keep, so the parser accommodates it rather than the corpus dropping it.
    """
    m = GLOBAL_DECL_RX.match(strip_inline_comment(text).strip())
    if not m:
        return None
    return m.group(1), m.group(2), m.group(3)


def merge_globals(body_decls):
    """All Global declarations to emit, deduplicated by declared name.

    The body may declare the same Global the module Functions already need; declaring it
    twice will not compile. If one declaration carries an initialiser and another of the
    same name does not, the initialiser-bearing one wins regardless of which was seen
    first: losing a captured initial value to declaration order is precisely the defect
    the initialiser pragma exists to prevent.
    """
    module_functions()                       # populates _MODGLOBALS
    thirdparty_functions()                   # ... and so does this one
    by_key = {}
    order = []
    for d in list(body_decls) + list(_MODGLOBALS):
        # AN EXTERN DELIMITER IS NEVER A DUPLICATE.
        #
        # '!Raw payloads arrive here flattened: module_functions() does
        # _MODGLOBALS.extend(decls) per file, so two files' Extern blocks become one list
        # with no record of which line closes which block. Keying those lines on bare
        # lowercased text then makes every bare `End Extern` collide, and the SECOND one is
        # dropped -- leaving the first block open, swallowing every Global declared after
        # it, and killing the probe with
        #     Syntax error in extern block - expecting Const, Global, Function or Type
        # ...reported at the swallowed declaration, nowhere near the missing closer.
        #
        # Reproduced between src/recovered_module/Fn_0058D987.SteamPostPlayerValue.bmx and
        # Fn_0058D81A.GetClipboardText.bmx. Both files currently defend themselves by
        # hanging a trailing comment off `End Extern` to keep its TEXT unique -- a
        # convention no tool enforces and every future author has to know.
        #
        # Dropping a block terminator is never correct, so exempt delimiters from the
        # dedupe outright. Two genuinely identical blocks then emit as one full block plus
        # a bare `Extern "..."` / `End Extern` pair with its declarations deduped away,
        # which is an empty extern block and legal.
        if re.match(r"^(Extern\b|End\s+Extern\b)", d.strip(), re.I):
            order.append(d)
            by_key[d] = (d, False)
            continue
        parsed = parse_global_decl(d)
        key = parsed[0].lower() if parsed else d.strip().lower()
        has_init = bool(parsed and parsed[2])
        if key not in by_key:
            by_key[key] = (d, has_init)
            order.append(key)
        elif has_init and not by_key[key][1]:
            by_key[key] = (d, has_init)
    return [by_key[k][0] for k in order]


# ---------------------------------------------------------------- module Globals
# NSS5 keeps a lot of state in module-level Globals, so a harness that cannot emit one
# leaves every body that touches one unbuildable. That is the real blocker behind most
# of what the work set files as NEEDS_RUNTIME: a `For ... EachIn`
# over a global list fails not because of TList (TList verifies fine, measured) but
# because the list itself has nowhere to live.
#
# The original names are unrecoverable -- NSS5.exe carries no BBDEBUGDECL_GLOBAL records
# -- and names have no effect on codegen, so a body declares the globals it needs inline:
#
#     '!Global g_cameramen:TList
#     For Local c:TCameraMan = EachIn g_cameramen
#
# The pragma lines are lifted to module scope and stripped from the body. Declaring them
# in the file is deliberate: the DECLARED TYPE does change codegen (a virtual call is
# `call [eax+slot]`, and the slot comes from the static type), so it is an assumption the
# reconstruction is making and it belongs on the record next to the body that assumes it.
GLOBAL_PRAGMA = re.compile(r"^[ \t]*'!\s*(Global\s+[^\r\n]+?)[ \t]*$", re.M)

# FIELD INITIALISERS.
#
# object_model.json carries no default VALUE, so emitting every field as a bare
# `Field <name>:<Type>` makes any Type whose declaration has a non-zero field default
# unmatchable. bcc emits a field initialiser INSIDE the Type declaration, ahead of
# every body statement, so no body can reproduce it -- writing `Self.x = 150` in New
# lands AFTER bcc's own `mov [ebx+off],0` and is strictly longer. Measured evidence:
# TTeam.New reaches 160/160 bytes with a single differing dword, orig
# `mov dword [ebx+0x3c],0xffffffff` vs ours `mov dword [ebx+0x3c],0`.
#
#     '!Field newstarselno = -1        -> Field newstarselno:Int = -1
#     '!Field newcol:String[24]        -> Field newcol:String[24]   (full type override)
#
# The override is TEXT ONLY: field_size() still uses the object-model sig, so the offset
# arithmetic and hole padding are untouched and a pragma cannot corrupt the layout.
# Like '!Global, it applies only to the TARGET Type, and it is an assumption the
# reconstruction is making, so it belongs on the record next to the body.
FIELD_PRAGMA = re.compile(r"^[ \t]*'!\s*Field\s+([A-Za-z_]\w*)[ \t]*((?::|=)[^\r\n]*?)[ \t]*$",
                          re.M)

# A verbatim module-scope line. Needed for anything bcc requires at module level that is
# neither a Global nor a Type -- an Extern block around a Win32 import, for instance.
RAW_PRAGMA = re.compile(r"^[ \t]*'!\s*Raw[ \t]+([^\r\n]*?)[ \t]*$", re.M)

# ---------------------------------------------------------------- once-init ordinal
# THE GLOBAL-INIT GUARD COUNTER IS WHOLE-PROGRAM, so a body carrying a lazily initialised
# Global cannot be certified by a probe that starts the counter at zero. This pragma is
# how such a body states where in the original's count it really sits, exactly as '!Global
# states which module Globals it really sees and '!Field states what the Type's field
# defaults really are: a probe-context fact the isolated build cannot know, written down
# next to the body that depends on it.
#
#     '!GlobalInit 95
#
# The number is the 1-based ordinal, in the ORIGINAL program's single bcc compilation
# unit, of the FIRST `Global x:T = <non-constant>` declaration this body makes.
#
# WHY IT CHANGES BYTES. `GlobalDeclStm::eval` (stm.cpp:182) sends any Global whose
# initialiser fails `Val::constant()` (val.cpp:63 -- a CGLit or CGSym, i.e. a bare
# literal) to `Block::initGlobalRef` (block.cpp:142), which holds
#     static int init_bit; static CGExp *init_var;
# as C++ FUNCTION-LOCAL STATICS. They are never reset -- not per file, not per Type, not
# per Function -- so they live as long as the bcc process and every such declaration in
# the unit takes the next bit of one shared flags dword, a fresh dword being allocated
# once 32 bits are gone. The bit reaches the instruction stream twice as an immediate:
#     bits 1..0x40      `83 E0 ib`  AND (3 bytes)   `83 0D disp32 ib` OR (7 bytes)
#     bits 0x80 and up  `25 id`     AND (5 bytes)   `81 0D disp32 id` OR (10 bytes)
# so the body's LENGTH depends on its position in the whole program's declaration order.
# `Global x:T[N]` counts as non-constant too: parser.cpp's parseInitDecl turns the
# dimension into an ArrayExp, which is a bbArrayNew1D call.
#
# WHAT THE PROBE DOES WITH IT. bcc.cpp:47-50 evaluates `_funBlocks` in construction order
# and `_funBlocks[0]` is the module body, so every module-scope declaration is numbered
# before any function-scope one whatever line it sits on. Padding module scope with
# filler declarations of the same shape is therefore enough to walk the counter forward;
# `init_pad_decls()` emits `ordinal - 1` of them, less however many the probe already
# emits ahead of the body itself.
#
# HOW TO DERIVE THE NUMBER, rather than search for one that passes. Scan NSS5.exe's code
# sections for `or dword ptr [abs32], <power of two>`; that OR is the guard's second
# immediate and nothing else in bcc emits the shape. Group the sites by flags dword. Each
# group is one 32-declaration run, `dat()` hands out dwords in emission order so within a
# unit the dword ADDRESSES increase in that order, and a group is confirmed full when it
# carries all 32 distinct bits. The ordinal is 32 * (index of the group) + (bit position).
# For TScreen.DoProgressBar: bit 0x40000000 in 0x00C6E2AC, the third of the game unit's
# four dwords (0x00C5A31C and 0x00C65CC0 precede it and both hold 32 distinct bits, and
# their sites run VA-contiguously into it), so 2 * 32 + 31 = 95.
#
# HONEST LIMIT ON WHAT A PROBE CAN CONFIRM. Only `(ordinal - 1) mod 32` reaches the
# emitted bytes -- the flags dword itself is an absolute address and the oracle masks it.
# So a MATCH confirms the ordinal modulo 32 and no more; 95 and 127 are indistinguishable
# here. The absolute value comes from the exe scan above, not from the probe.
#
# THIS DOES NOT AFFECT THE ASSEMBLED BUILD, and must not: there the real module body
# supplies the real count, which is the only number that decides whether the shipped body
# is right. See docs/reference/whole-program-counters.md.
GLOBALINIT_PRAGMA = re.compile(r"^[ \t]*'!\s*GlobalInit[ \t]+(\d+)[ \t]*$", re.M)

# Filler declarations are named with a prefix no recovered body would choose, because a
# collision with a real Global would not fail the build -- it would silently redeclare it.
INIT_PAD_PREFIX = "__bmx_initpad_"

# `Val::constant()` in one regex: a bare literal. Anything else -- a call, an operator, a
# `New`, an identifier reference -- is not, and costs a bit. Deliberately narrow: a
# declaration this cannot parse is treated as costing NOTHING, which is the state of every
# recovered body today (measured: the whole corpus emits one initialised module Global,
# `Global g_replay_div:Int = 25`, which is constant), and a body that breaks the
# assumption fails loudly at the oracle rather than quietly padding wrong.
INIT_CONST_RX = re.compile(
    r"^(?:-?\d+(?:\.\d*)?(?:[eE][-+]?\d+)?|-?\.\d+|\$[0-9A-Fa-f]+|%[01]+"
    r"|\"[^\"]*\"|Null|True|False|Pi)$", re.I)


def declares_init_guard(decl):
    """True if this `Global ...` declaration costs an initGlobalRef bit."""
    text = decl.strip()
    if not re.match(r"^Global\s", text, re.I):
        return False
    head, sep, init = text.partition("=")
    if sep:
        return not INIT_CONST_RX.match(init.strip())
    # No initialiser. Only a sized array type builds one (`Global x:Int[4]`); a bare
    # array type (`Global x:Int[]`) defaults to Null, which is constant.
    return bool(re.search(r"\[\s*[^\]\s]", head))


def count_init_guards(text):
    """How many initGlobalRef bits the `Global` declarations in `text` consume."""
    return sum(1 for line in text.split("\n") if declares_init_guard(line))


def split_global_init(body):
    """-> (body without the pragma line, declared ordinal or None)"""
    found = {int(m) for m in GLOBALINIT_PRAGMA.findall(body)}
    if len(found) > 1:
        raise ValueError("conflicting '!GlobalInit ordinals: %s" % sorted(found))
    return GLOBALINIT_PRAGMA.sub("", body), (found.pop() if found else None)


def init_pad_decls(ordinal, ahead=0):
    """Module-scope filler declarations that walk the once-init counter to `ordinal`.

    `ahead` is how many guard-costing declarations the probe already emits before the
    target body, so the padding does not double-count them.
    """
    if ordinal is None:
        return []
    n = ordinal - 1 - ahead
    if n < 0:
        raise ValueError(
            "'!GlobalInit %d is unreachable: the probe already emits %d guarded Global "
            "declaration(s) ahead of the body" % (ordinal, ahead))
    return ["Global %s%04d:Int[1]" % (INIT_PAD_PREFIX, i) for i in range(n)]


# ---------------------------------------------------------------- DLL imports
# bcc rejects `Import` anywhere but the very top of the file ("'Import' must appear at top
# of file"), so '!Raw cannot carry one -- Raw lines are emitted after the Type block.
# '!Import is therefore its own pragma, injected directly into the generated header
# alongside the module Imports.
#
#     '!Import ".../extern/steamstub/libsteamstub.a"
#     '!Raw Extern
#     '!Raw Function FindLeaderboard(name:Byte Ptr)
#     '!Raw End Extern
#
# Why a body needs this at all: a call into a DLL targets a six-byte `jmp dword ptr [IAT]`
# thunk, and unless our side resolves the SAME symbol name the E8 cannot mask and the body
# is unverifiable. Declaring the Extern makes bcc emit `extrn _FindLeaderboard`; the import
# library (generated from the shipped DLL with dlltool, see extern/) is what lets ld
# resolve it. That is a real import of the real DLL, not a stub standing in for game code
# -- rule 13.3 forbids the latter and this is deliberately not that: the callee is outside
# the reconstruction boundary and the original's own call target is an import thunk too.
#
# Found while recovering the Steam leaderboard poster at 0x0058D987. 324 import thunks
# across 11 DLLs are named in extracted/dll_imports.tsv, so this will not be the last body
# that needs it.
IMPORT_PRAGMA = re.compile(r"^[ \t]*'!\s*Import[ \t]+([^\r\n]*?)[ \t]*$", re.M)


def split_imports(body):
    """-> (body without '!Import lines, [import arguments])

    A tracked '!Import line writes its path as `<repo>/...` rather than a real path,
    because a real absolute path would be machine-specific (this developer's Windows
    username, this clone's drive letter) and a real RELATIVE path has nothing to be
    relative TO: bcc resolves it against the harness's randomly named per-run temp build
    directory, not the working directory and not the repo, so no relative spelling written
    in a tracked file can ever reach extern/. <repo> is substituted here, at emission time,
    with the ROOT this process is actually running from, which keeps the tracked .bmx
    machine independent while still giving bcc something it can resolve. Forward slashes
    only: a backslash inside a BlitzMax string is not an escape character, but mixing
    Windows' own backslash separator into an Import path is untested and forward slashes
    are known to work, so ROOT is normalised to them here rather than left as-is.
    """
    imps = [m.group(1).replace("<repo>", ROOT.replace("\\", "/"))
            for m in IMPORT_PRAGMA.finditer(body)]
    return IMPORT_PRAGMA.sub("", body), imps


def _header_with(imports):
    """The cached header, with extra Imports spliced in after the module Imports.

    Appending them to the end of the header would put them after the placeholder Type
    declarations, which is exactly the position bcc rejects.
    """
    head = _HEADER[0]
    if not imports:
        return head
    lines = head.split("\n")
    last = max((i for i, l in enumerate(lines) if l.startswith("Import ")), default=1)
    extra = ["Import " + i for i in imports]
    return "\n".join(lines[:last + 1] + extra + lines[last + 1:])


def split_globals(body):
    """-> (body without pragma lines, [module-scope declarations])"""
    decls = [m.group(1) for m in GLOBAL_PRAGMA.finditer(body)]
    decls += [m.group(1) for m in RAW_PRAGMA.finditer(body)]
    return RAW_PRAGMA.sub("", GLOBAL_PRAGMA.sub("", body)), decls


def split_field_decls(body):
    """-> (body without pragma lines, {lowercased field name: declaration suffix})"""
    over = {m.group(1).lower(): m.group(2).strip() for m in FIELD_PRAGMA.finditer(body)}
    return FIELD_PRAGMA.sub("", body), over


def build_source(tname, mname, body, d=None):
    d = d or load_data()
    if tname not in d["methods"]:
        raise KeyError("unknown type " + tname)
    if not any(m["name"] == mname for m in d["methods"][tname]):
        raise KeyError("unknown method %s.%s" % (tname, mname))
    if tname in MODULE_TYPES:
        raise KeyError("%s comes from %s; not reconstructible here" % (tname, MODULE_TYPES[tname]))
    _build_prelude(d)

    body, imports_ = split_imports(body)
    body, ginit = split_global_init(body)
    body, globals_ = split_globals(body)
    body, fdecls = split_field_decls(body)

    if tname not in _PRELUDE:
        i = _ORDER.index(tname)
        _PRELUDE[tname] = ("\n".join(_TYPETEXT[t] for t in _ORDER[:i]),
                           "\n".join(_TYPETEXT[t] for t in _ORDER[i + 1:]))
    head, tail = _PRELUDE[tname]

    # Globals go after every Type so their declared types are already in scope.
    # bcc resolves module-scope declarations across the whole file, so a method body
    # emitted earlier may still reference them.
    #
    # The target Method is parsed before the module Functions below it, so only these
    # module-scope declarations can consume an init bit ahead of it -- see
    # GLOBALINIT_PRAGMA.
    gdecls = merge_globals(globals_)
    gtext = "\n".join(init_pad_decls(ginit, sum(map(declares_init_guard, gdecls)))
                      + gdecls)

    # Merge in any '!Import a bundled module Function needs (e.g. SteamInit's
    # libsteamstub.a) -- see module_imports()'s docstring / module_functions()'s FIX note.
    all_imports = list(dict.fromkeys(list(imports_) + module_imports()))
    return "\n".join([_header_with(all_imports), head,
                      emit_type(tname, d, target=mname, body=body, field_decls=fdecls),
                      tail, "",
                      gtext, "",
                      MODFUNC_SEP.join(module_functions()), "",
                      MODFUNC_SEP.join(thirdparty_functions()), "",
                      "Local __keep:%s = New %s" % (tname, tname),
                      "If __keep = Null Then End"]) + "\n"


# ---------------------------------------------------------------- build + compare
def _span(path):
    """(imagebase, end_va) of a PE -- used to recognise absolute addresses."""
    _b, img, secs = _bytematch.load(path)
    return img, img + max(rva + sz for _n, rva, sz, _ro in secs)


_EXE_CACHE = {}
CALL_REL32 = (0xE8, 0xE9)          # call rel32 / jmp rel32
MAX_CALL_DEPTH = 2


def read_string(va, path=None):
    """Decode the BlitzMax String literal at `va` in NSS5.exe. None if it is not one.

    STRING LITERAL CONTENTS ARE RECOVERABLE. `bytematch.read_va` returns None for literals
    in .data, which invites the conclusion that every reconstructed literal must be a
    placeholder and faithfulness is permanently capped. It is not so, and the difference
    matters, because that conclusion puts placeholder text into the source. Addresses that
    read as unrecoverable decode fine here:
        0x00C725EC 'FF0000'   0x00C84868 'Select Club'   0x00C914E4 'UpdateFaces'

    A BBString is [class][refs][length][UTF-16 chars]; the text starts at +12 and `length`
    counts CHARACTERS, not bytes. Provided so nobody writes a fourth private version of it.
    """
    b, va2off = _exe(path or _bytematch.ORIG)
    o = va2off(va)
    if o < 0 or o + 12 > len(b):
        return None
    _cls, _refs, ln = struct.unpack_from("<III", b, o)
    if not 0 < ln < 4096 or o + 12 + ln * 2 > len(b):
        return None
    return b[o + 12:o + 12 + ln * 2].decode("utf-16-le", errors="replace")


def disasm_original(va, n=None, before=0, after=200):
    """Disassemble NSS5.exe at `va`. For working large bodies.

    The oracle returns a ten-instruction window, which is not enough on a 1,000-byte
    function: those are solvable only by dumping the original outright. bytematch's va2off
    is nested inside main(), so reaching it otherwise means re-deriving the section walk.
    Exposed here so nobody has to.
    """
    b, va2off = _exe(_bytematch.ORIG)
    if n is None:
        n = _bytematch.ghidra_sizes().get(va)
    if not n:
        return "no size for 0x%08X in Ghidra's inventory" % va
    off = va2off(va)
    return disasm_window(b[off:off + n], va, 0, before=before, after=after)


def masked_first_diff(ab, cb, ospan, uspan, octx, uctx, ournames, origtab, ourfns):
    """First MEANINGFUL difference over the common prefix, with masking applied.

    When the two lengths differ the oracle returns mode='len' and skips masking entirely,
    so `first_diff` lands on the first absolute-address operand -- usually within the first
    twenty bytes -- and localises nothing. That phantom offset costs real time on any large
    function. Comparing the common prefix WITH masking gives an offset that actually points
    at the first wrong statement.
    """
    k = min(len(ab), len(cb))
    try:
        _m, _s, _t, _mask, first = compare(
            ab[:k], cb[:k], ospan, uspan, octx, uctx,
            ournames=ournames, origtab=origtab, learn=None, ourfns=ourfns)
        return first if first >= 0 else k
    except Exception:                                             # noqa: BLE001
        return next((i for i, (x, y) in enumerate(zip(ab, cb)) if x != y), k)


def _exe(path):
    if path not in _EXE_CACHE:
        b, img, secs = _bytematch.load(path)
        va2off, _o2v, _c = _bytematch._helpers(b, img, secs)
        _EXE_CACHE[path] = (b, va2off)
    return _EXE_CACHE[path]


def _fn_bytes(path, va, n):
    """`n` bytes at `va`, or None if that range isn't wholly inside the image.

    The extent always comes from Ghidra's inventory for the ORIGINAL and is then applied
    to both images. Do not be tempted to derive our side's length from the BlitzMax
    epilogue here: call targets are frequently C-runtime helpers compiled by GCC, which
    end `5D C3` or `C9 C3` and contain no `89 EC 5D C3` at all -- the scan then runs off
    into the next function or fails outright. Measuring the original's function against
    the same number of bytes in ours is the sound comparison anyway: if ours were a
    different function the bytes would diverge almost immediately.
    """
    b, va2off = _exe(path)
    off = va2off(va)
    if off < 0 or n is None or n < 4 or n > _bytematch.MAX_FN or off + n > len(b):
        return None
    return b[off:off + n]


def compare(orig, ours, ospan, uspan, octx=None, uctx=None, depth=0, seen=None,
            ournames=None, origtab=None, learn=None, ourfns=None):
    """Byte compare that tolerates link-time relocations.

    A probe .exe is laid out differently from NSS5.exe, so every absolute address
    baked into an instruction (data-constant pointers, &bbNullObject, string
    literals) differs by construction and can NEVER match. Where two 4-byte windows
    both decode to an address inside their own image we treat the slot as a
    relocation, mask it and continue.  mode='exact' -> even addresses matched;
    mode='reloc' -> emitted CODE is identical, which is also a success.

    RELATIVE CALL DISPLACEMENTS -- READ BEFORE LOOSENING
    ====================================================
    `E8 rel32` encodes target-minus-next-instruction, so a call to the *same* function
    from two differently-laid-out images has a *different* displacement, and the dword
    it forms (e.g. 0xFFFBD8F7) is not an in-image address, so the absolute-relocation
    rule above can never mask it. That is why the two `Super.` thunks and every
    `For ... EachIn` body -- which calls the bbObjectDowncast helper -- were reported as
    MISMATCH while being structurally perfect.

    The temptation is to mask any E8 whose two targets are both in-image. DO NOT: that
    would equally bless a call to the WRONG function, which is precisely the class of
    error the 0xC3 truncation bug taught us to design against. Instead the displacement
    is masked only when the two call targets have been FETCHED and PROVEN identical --
    recursively, under these same rules. If either target's extent cannot be established
    the diff stands and the result is an honest MISMATCH.
    """
    if orig == ours:
        return "exact", len(orig), len(orig), 0, -1
    seen = seen if seen is not None else set()

    # LENGTH MISMATCH -- the verdict is fixed ('len' -> MISMATCH) and nothing below can
    # change it. But the DIAGNOSTIC still has to be usable. A raw positional zip diff with
    # NO relocation masking always lands, on a length disagreement, on the first
    # absolute-address operand (measured: bytes 5-19 in every observed case) and localises
    # nothing. That phantom costs real time on every large function, and the iterate-on-
    # first_diff loop in docs/reference/codegen-patterns.md 3e depends on precisely this
    # mode. So: walk the COMMON PREFIX under the same masking rules and report first_diff
    # over the masked streams.
    #
    # Two safety properties are preserved deliberately:
    #   * the verdict is decided by the length test BEFORE the walk, so masking is still
    #     structurally incapable of turning a length disagreement into a MATCH;
    #   * `learn` is forced to None. A body whose length is wrong must never contribute a
    #     helper-name row to the evidence table on the strength of an alignment that we
    #     already know is broken further along.
    length_differs = len(orig) != len(ours)
    n = min(len(orig), len(ours)) if length_differs else len(orig)
    if length_differs:
        learn = None
    i, masked, first = 0, 0, -1
    while i < n:
        if orig[i] == ours[i]:
            i += 1
            continue
        hit = False
        for st in (i - 3, i - 2, i - 1, i):          # differing byte may be mid-dword
            if st < 0 or st + 4 > n:
                continue
            ov = struct.unpack_from("<I", orig, st)[0]
            uv = struct.unpack_from("<I", ours, st)[0]
            if ospan[0] <= ov < ospan[1] and uspan[0] <= uv < uspan[1]:
                # An absolute operand that lands inside a class table is `Type + slot`,
                # i.e. a static cross-Type call or a Type reference. Masking it blind
                # hides WHICH Type -- measured: calling TScreen_TestMenu.SetUpScreen()
                # instead of TScreen_EditMenu.SetUpScreen() matched 20/20. Resolve both
                # sides and require agreement. Only reject when BOTH resolve and differ,
                # so an approximate class-table extent can never invent a mismatch.
                if octx and uctx:
                    osl = _helper_map.resolve_slot(octx[0], ov)
                    usl = _helper_map.resolve_slot(uctx[0], uv)
                    if osl and usl and osl != usl:
                        break                       # genuine difference; do not mask
                i, masked, hit = st + 4, masked + 1, True
                break
        if not hit and octx and uctx and depth < MAX_CALL_DEPTH:
            # Is this differing byte inside the rel32 field of a call/jmp present at the
            # same position in BOTH bodies?
            for p in (i - 4, i - 3, i - 2, i - 1):
                if p < 0 or p + 5 > n:
                    continue
                if orig[p] != ours[p] or orig[p] not in CALL_REL32:
                    continue
                ot = octx[1] + p + 5 + struct.unpack_from("<i", orig, p + 1)[0]
                ut = uctx[1] + p + 5 + struct.unpack_from("<i", ours, p + 1)[0]
                # FALSE-POSITIVE `p`. The loop below commits to the FIRST candidate that
                # merely looks like a call opcode, and any 0xE8 byte qualifies -- including
                # one that is really part of the PRECEDING instruction. Measured, in
                # TScreen_Stats.UpdateStatTable at +2332:
                #     FF 75 E8  push dword [ebp-0x18]   <- the -0x18 displacement IS 0xE8
                #     E8 82 79 FB FF  call FormatDecimals
                # p = i-1 selects the push's displacement byte, yields a target outside the
                # image, resolves to nothing, and the loop then abandons the search before
                # ever trying the real opcode at p = i. Four ratio arrays in that function
                # hit it, and the body is reported MISMATCH although it is correct.
                # A genuine intra-image `E8 rel32` always targets its own image, so a
                # candidate whose target does not is not a call. Rejecting it here is a
                # pure no-op for anything that currently masks -- every rule below is keyed
                # on an IN-IMAGE address (orig_functions / origtab / ournames / Ghidra's
                # size inventory), so an out-of-image target could never have satisfied
                # one. It can therefore only let a real call be found, never bless one.
                if not (ospan[0] <= ot < ospan[1] and uspan[0] <= ut < uspan[1]):
                    continue

                # (a) By NAME. Our side is named exactly by the linker's own relocation
                #     records; the original's by the corroborated bootstrap table. Equal
                #     names is proof. UNEQUAL names is a real error and must not mask --
                #     that is the case where we called the wrong helper.
                # (a0) Both sides are a named BlitzMax method/function. This covers
                #      Super. calls and any statically-resolved call between game code.
                #      Byte-comparing those targets is wrong: in a probe every non-target
                #      method is a STUB, so the parent legitimately differs.
                ofn = _helper_map.orig_functions().get(ot)
                ufn = ourfns.get(ut) if ourfns else None
                if ofn and ufn:
                    if ofn == ufn:
                        i, masked, hit = p + 5, masked + 1, True
                    break

                usym = ournames.get(ut) if ournames else None
                osym = origtab.get(ot, (None, 0))[0] if origtab else None
                if usym and osym:
                    # osym may be a pipe-separated ALIAS SET: several BRL functions can
                    # have byte-identical bodies (brl.stream.Eof, brl.gnet.GNetObjectState,
                    # brl.timer.TimerTicks and pub.freeprocess.ProcessStatus are all the
                    # same 21 bytes), so the address cannot be narrowed to one name.
                    # Accepting any member is correct and avoids rejecting good bodies.
                    if usym in osym.split("|"):
                        i, masked, hit = p + 5, masked + 1, True
                        # Corroboration is evidence too. Without this the witness count
                        # would freeze at 1 for every helper -- the table would claim its
                        # weakest possible support while actually having hundreds of
                        # independent confirmations.
                        if learn is not None:
                            learn.append((ot, usym, True))
                    break

                # (b) By BYTES. Calls to other *game* functions are reproducible, so the
                #     two targets can simply be compared. This never applies to C-runtime
                #     helpers (different GCC), which is exactly why (a) exists.
                if _same_callee(octx[0], ot, uctx[0], ut, ospan, uspan, depth, seen):
                    i, masked, hit = p + 5, masked + 1, True
                    break

                # (c) Our side is named but the original's address is not in the table
                #     yet. Cannot prove -- but if everything else in this function agrees
                #     the alignment itself is the evidence, so hand it back as something
                #     to LEARN rather than silently accepting or silently failing.
                if usym and learn is not None:
                    learn.append((ot, usym, False))
                    i, hit = p + 5, True
                break
        if not hit:
            if first < 0:
                first = i
            i += 1
    same = sum(1 for x, y in zip(orig, ours) if x == y)
    if length_differs:
        # first < 0 here means the whole common prefix agreed once relocations were
        # masked, i.e. the bodies diverge only at the end -- report the prefix end, which
        # is where to look. `matched` stays the positional count over the common prefix
        # and `total` the longer length, as before.
        return "len", same, max(len(orig), len(ours)), masked, (n if first < 0 else first)
    if first < 0:
        # 'learn' = every byte agreed except call operands whose original-side helper is
        # not in the table yet. Not a MATCH on its own; the caller must record and re-run.
        return ("learn" if any(not k for _v, _s, k in (learn or [])) else "reloc"),             n, n, masked, -1
    return "diff", same, n, masked, first


def _same_callee(opath, ova, upath, uva, ospan, uspan, depth, seen):
    """True only if the two call targets are provably the same function."""
    key = (ova, uva)
    if key in seen:
        return True                     # already being proved higher up the stack
    n = _bytematch.ghidra_sizes().get(ova)
    ob = _fn_bytes(opath, ova, n)
    ub = _fn_bytes(upath, uva, n)
    if ob is None or ub is None:
        return False                    # cannot establish -> cannot prove -> do not mask
    seen.add(key)
    mode, _s, _t, _m, _f = compare(ob, ub, ospan, uspan,
                                   (opath, ova), (upath, uva), depth + 1, seen)
    if mode not in ("exact", "reloc"):
        seen.discard(key)
        return False
    return True


# One lock PER TREE. With per-worker trees there is no shared scratch state, so two
# workers never contend; within a tree the mutex is still required.
LOCK = os.path.join(tempfile.gettempdir(), "nssforge",
                    "build.%s.lock" % re.sub(r"[^A-Za-z0-9]", "_", BMX_ROOT)[-40:])


class BuildLock(object):
    """Cross-process mutex. bmk/fasm/gcc share scratch state inside the BlitzMax
    tree, so two concurrent builds corrupt each other's output (measured: 6 parallel
    builds -> 4 false MISMATCHes). Codegen is ~1s, so serialising the build step is
    cheap and every pass can still call try_method() freely."""

    def __init__(self, timeout=1800, stale=600):
        self.timeout, self.stale, self.fd = timeout, stale, None

    def __enter__(self):
        os.makedirs(os.path.dirname(LOCK), exist_ok=True)
        t0 = time.time()
        while True:
            try:
                self.fd = os.open(LOCK, os.O_CREAT | os.O_EXCL | os.O_RDWR)
                os.write(self.fd, str(os.getpid()).encode())
                return self
            except FileExistsError:
                try:
                    if time.time() - os.path.getmtime(LOCK) > self.stale:
                        os.unlink(LOCK)
                        continue
                except OSError:
                    pass
                if time.time() - t0 > self.timeout:
                    raise RuntimeError("build lock timeout")
                time.sleep(0.15 + random.random() * 0.2)

    def __exit__(self, *a):
        try:
            os.close(self.fd)
            os.unlink(LOCK)
        except OSError:
            pass


def _env():
    e = dict(os.environ)
    e["PATH"] = MINGW + os.pathsep + e.get("PATH", "")
    e["BLITZMAXPATH"] = BMX_ROOT
    return e


# ---------------------------------------------------------------- disassembly
_CS = None


def _cs():
    global _CS
    if _CS is None:
        try:
            import capstone
            _CS = capstone.Cs(capstone.CS_ARCH_X86, capstone.CS_MODE_32)
            _CS.skipdata = True
        except Exception:                                     # noqa: BLE001
            _CS = False
    return _CS


def disasm_window(buf, va, first_diff, before=4, after=6):
    """Disassembled text around first_diff.

    A raw hex window is unreadable and, worse, cannot be aligned by eye because x86 is
    a variable-length encoding. Disassembly always starts at byte 0
    of the function -- a known instruction boundary -- so the decode is correct, and the
    instruction CONTAINING first_diff is marked.
    """
    md = _cs()
    if not md:
        lo = max(0, first_diff - 8)
        return "  (capstone unavailable) " + " ".join("%02X" % x for x in buf[lo:first_diff + 24])
    ins = list(md.disasm(bytes(buf), va))
    hit = 0
    for k, x in enumerate(ins):
        if x.address - va <= first_diff < x.address - va + x.size:
            hit = k
            break
    out = []
    for x in ins[max(0, hit - before):hit + after]:
        off = x.address - va
        out.append("  %s %08X  %-24s %s %s" % (
            ">>" if off <= first_diff < off + x.size else "  ",
            x.address, " ".join("%02X" % b for b in x.bytes),
            x.mnemonic, x.op_str))
    return "\n".join(out)


def try_method(tname, mname, body, keep=False, workdir=None):
    """-> dict(status=MATCH|MISMATCH|BUILD_FAIL|ERROR, ...)"""
    wd = workdir or os.path.join(tempfile.gettempdir(), "nssforge", uuid.uuid4().hex[:12])
    os.makedirs(wd, exist_ok=True)
    src = os.path.join(wd, "probe.bmx")
    exe = os.path.join(wd, "probe.exe")
    res = {"type": tname, "method": mname, "workdir": wd}
    try:
        # utf-8-sig, NOT latin-1: bcc's toker.cpp (_src/compiler/toker.cpp:302) picks UTF8
        # only on an EF BB BF BOM and otherwise falls back to LATIN1. Latin-1 cannot represent
        # U+20AC EURO SIGN, so errors="replace" silently turned NSS5's "€ EUR" into "? EUR"
        # before bcc ever saw it -- invisible to every byte check, because a literal reaches
        # the code only as a masked address. Proved by w15_S1: TScreen_Options.CreateScreen is
        # MATCH 8290/8290 both ways, and the probe .data holds U+003F with latin-1 and U+20AC
        # with the BOM.
        open(src, "w", encoding="utf-8-sig").write(
            build_source(tname, mname, body))
        with BuildLock():
            p = subprocess.run([BMK, "makeapp", "-r", "-t", "console", src],
                               cwd=BMX_ROOT, env=_env(), capture_output=True,
                               text=True, errors="replace", timeout=900)
        if p.returncode != 0 or not os.path.exists(exe):
            res["status"] = "BUILD_FAIL"
            res["message"] = ((p.stdout or "") + (p.stderr or "")).strip()[-1500:]
            return res
        a = _bytematch.find_method(_bytematch.ORIG, tname, mname)
        c = _bytematch.find_method(exe, tname, mname)
        if not a or not c:
            res["status"] = "ERROR"
            res["message"] = "method not located in " + ("original" if not a else "probe")
            return res
        # bytematch.find_method returns a dict; ORIGINAL length comes from Ghidra's
        # inventory, ours from the real epilogue scan. Never index this positionally.
        ab, cb = a["bytes"], c["bytes"]
        res.update(orig_len=a["length"], our_len=c["length"],
                   orig_len_from=a["length_source"], orig_va="0x%08X" % a["va"])

        # (1) The original's length MUST be the authoritative Ghidra one. If the VA is
        # absent from the inventory, bytematch fell back to an epilogue scan, which can
        # stop early on a function with an interior `mov esp,ebp/pop ebp/ret`. We refuse
        # to bless that rather than quietly reporting a MATCH.
        if a["length_source"] != "ghidra":
            res["status"] = "UNCERTAIN_LEN"
            res["message"] = ("original length not in Ghidra inventory (source=%s); "
                              "cannot certify" % a["length_source"])
            return res

        # (2) A length disagreement is fatal and is decided BEFORE any relocation
        # masking runs, so masking is structurally incapable of hiding it. The
        # diagnostic, however, goes through the same masked walk as everything else --
        # see compare()'s length-mismatch note. first_diff is over the MASKED common
        # prefix; `matched` remains a positional count and is not a prefix length.
        if a["length"] != c["length"]:
            _m, _same, _tot, _msk, _raw = compare(
                ab, cb, _span(_bytematch.ORIG), _span(exe),
                (_bytematch.ORIG, a["va"]), (exe, c["va"]))
            # compare() short-circuits on unequal lengths WITHOUT masking, so its
            # first_diff points at the first absolute-address operand and localises
            # nothing. Re-derive it over the masked common prefix.
            first = masked_first_diff(ab, cb, _span(_bytematch.ORIG), _span(exe),
                                      (_bytematch.ORIG, a["va"]), (exe, c["va"]),
                                      {}, _helper_map.full_table(), {})
            res.update(status="MISMATCH", mode="len", reloc_masked=_msk, first_diff=first,
                       matched=_same, total=_tot,
                       reason="length differs (orig %d vs ours %d)" % (a["length"], c["length"]))
            res["disasm_orig"] = disasm_window(ab, a["va"], first)
            res["disasm_ours"] = disasm_window(cb, c["va"], first)
            res["orig_hex"] = " ".join("%02X" % x for x in ab[:96])
            res["our_hex"] = " ".join("%02X" % x for x in cb[:96])
            return res

        # Name our own call targets from the linker's relocation records, and load the
        # corroborated original-side table. Both are optional: without them the oracle
        # simply refuses to mask call operands, which is the old, stricter behaviour.
        try:
            ournames_by_va = {}
            syms, _base = _helper_map.our_helpers(wd, exe)
            for _s, _va in syms.items():
                ournames_by_va[_va] = _s
            origtab = _helper_map.full_table()
            _objdir = os.path.join(wd, ".bmx")
            _objs = [os.path.join(_objdir, f) for f in os.listdir(_objdir)
                     if f.endswith(".o")]
            ourfns = _helper_map.our_functions(max(_objs, key=os.path.getsize), exe)
        except Exception:                                         # noqa: BLE001
            ournames_by_va, origtab, ourfns = {}, {}, {}

        ospan, uspan = _span(_bytematch.ORIG), _span(exe)
        octx, uctx = (_bytematch.ORIG, a["va"]), (exe, c["va"])
        learn = None if NO_LEARN else []
        mode, same, total, masked, first = compare(
            ab, cb, ospan, uspan, octx, uctx,
            ournames=ournames_by_va, origtab=origtab, learn=learn, ourfns=ourfns)

        # Everything agreed except call operands we could not yet name on the original
        # side. The alignment IS the evidence: same length, same opcode at the same
        # offset, every other byte equal. Record the correspondence and re-compare with
        # the table in place, so the MATCH is decided by the table like any other.
        if learn:
            # Do NOT rebind origtab to record()'s return value. record() persists and
            # returns only the bootstrapped C-runtime table, so rebinding silently drops
            # every BRL name that full_table() had merged in -- and the re-compare below
            # then cannot mask a call to e.g. _brl_filesystem_FileType, which looks like a
            # bad body. Merge the newly learned entries into the table we already have.
            # record() also ignores addresses outside the C-runtime range, so the BRL-range
            # entries we just learned exist only here.
            _persisted, conflicts = _helper_map.record([(v, sy) for v, sy, _k in learn])
            for _v, _sy, _known in learn:
                origtab.setdefault(_v, (_sy, 1))
            new = sorted({"0x%08x=%s" % (v, sy) for v, sy, k in learn if not k})
            if new:
                res["learned_helpers"] = new
            if conflicts:
                res["helper_conflicts"] = ["0x%08x %s vs %s" % c for c in conflicts]
        if mode == "learn":
            mode, same, total, masked, first = compare(
                ab, cb, ospan, uspan, octx, uctx,
                ournames=ournames_by_va, origtab=origtab, learn=None, ourfns=ourfns)

        res.update(mode=mode, matched=same, total=total, reloc_masked=masked)
        if mode in ("exact", "reloc"):
            res["status"] = "MATCH"
        else:
            res["status"] = "MISMATCH"
            res["first_diff"] = first
            res["disasm_orig"] = disasm_window(ab, a["va"], first)
            res["disasm_ours"] = disasm_window(cb, c["va"], first)
            res["orig_hex"] = " ".join("%02X" % x for x in ab[:96])
            res["our_hex"] = " ".join("%02X" % x for x in cb[:96])
        return res
    except Exception as ex:                                   # noqa: BLE001
        res["status"] = "ERROR"
        res["message"] = "%s: %s" % (type(ex).__name__, ex)
        return res
    finally:
        if not keep and res.get("status") in ("MATCH", "MISMATCH") and workdir is None:
            shutil.rmtree(wd, ignore_errors=True)


def build_source_function(name, sig, body, d=None, decl=None):
    """A probe whose target is a MODULE-LEVEL Function rather than a Type member.

    `decl` overrides the generated parameter list. Needed for what the reflection
    signature grammar cannot express -- above all `Var` parameters. A scalar `Var`
    compiles identically to a Ptr (which is how ClampInt and ClampFloat were matched),
    but `String Var` has no Ptr spelling, so the list must be given directly:

        decl="s:String Var, sep:String"
    """
    d = d or load_data()
    _build_prelude(d)
    body, imports_ = split_imports(body)
    body, ginit = split_global_init(body)
    body, globals_ = split_globals(body)
    body, _ = split_field_decls(body)      # no target Type here; strip so they are inert
    args, ret = parse_sig(sig)
    plist = decl if decl is not None else ", ".join(
        "a%d:%s" % (i, a) for i, a in enumerate(args))
    decl = "Function %s:%s(%s)" % (name, ret, plist)
    fn = "\n".join([decl, body, "End Function"])
    # Other recovered module Functions are emitted too, so one can call another. The
    # target itself is skipped -- we are defining it here, and a duplicate declaration
    # would not compile.
    others = [f for f in (module_functions() + thirdparty_functions())
              if ("Function %s:" % name) not in f and ("Function %s(" % name) not in f]
    # Merge in any '!Import a bundled "other" module Function needs (e.g. SteamInit's
    # libsteamstub.a) -- see module_imports()'s docstring / module_functions()'s FIX note.
    all_imports = list(dict.fromkeys(list(imports_) + module_imports()))
    # Unlike build_source, the target Function is emitted AFTER `others`, so a
    # function-scope guarded Global in one of those would also be numbered first.
    gdecls = merge_globals(globals_)
    ahead = sum(map(declares_init_guard, gdecls)) + count_init_guards("\n".join(others))
    return "\n".join([_header_with(all_imports),
                      "\n".join(_TYPETEXT[t] for t in _ORDER),
                      "\n".join(init_pad_decls(ginit, ahead) + gdecls), "",
                      MODFUNC_SEP.join(others), "",
                      fn, "",
                      "If AppTitle = \"\" Then End"]) + "\n"


def try_function(name, sig, body, orig_va, keep=False, workdir=None, decl=None):
    """Verify a module-level Function against NSS5.exe.

    Module-level Functions carry NO reflection record -- BlitzMax only emits BBDebugScope
    data for Types -- so bytematch.find_method cannot locate them in either image. Two
    different routes replace it:
      * OURS  is found by symbol. bcc mangles a module Function as `_bb_<Name>` (Type
        methods get `__bb_<Type>_<Method>`), and helper_map already establishes the
        offset from object-file offsets to exe VAs.
      * THE ORIGINAL is identified by the address its callers use, which is how these
        functions were discovered in the first place, with the length taken from Ghidra's
        inventory as everywhere else.
    Their original names are unrecoverable, exactly like module Globals, so `name` is
    ours to choose and has no effect on the emitted bytes.
    """
    # KIND=Function rows in the workset are STATIC METHODS declared inside a Type, and must
    # go through try_method. Passing 'TScreen_X.ButtonY' here emits
    # `Function TScreen_X.ButtonY:Int()` into the probe, and bcc's "Missing type
    # specifier" points at a line deep inside generated source -- which reads like a bad
    # body rather than a misuse of the API. Reject it where the mistake was made.
    if "." in name:
        return {"function": name, "status": "ERROR",
                "message": "'%s' names a Type member; use try_method('%s', '%s', body). "
                           "try_function is only for module-level Functions."
                           % ((name,) + tuple(name.split(".", 1)))}
    if isinstance(orig_va, str):
        orig_va = int(orig_va, 16 if orig_va.lower().startswith("0x") else 10)
    wd = workdir or os.path.join(tempfile.gettempdir(), "nssforge", uuid.uuid4().hex[:12])
    os.makedirs(wd, exist_ok=True)
    src, exe = os.path.join(wd, "probe.bmx"), os.path.join(wd, "probe.exe")
    res = {"function": name, "orig_va": "0x%08X" % orig_va, "workdir": wd}
    try:
        # utf-8-sig, NOT latin-1: bcc's toker.cpp (_src/compiler/toker.cpp:302) picks UTF8
        # only on an EF BB BF BOM and otherwise falls back to LATIN1. Latin-1 cannot represent
        # U+20AC EURO SIGN, so errors="replace" silently turned NSS5's "€ EUR" into "? EUR"
        # before bcc ever saw it -- invisible to every byte check, because a literal reaches
        # the code only as a masked address. Proved by w15_S1: TScreen_Options.CreateScreen is
        # MATCH 8290/8290 both ways, and the probe .data holds U+003F with latin-1 and U+20AC
        # with the BOM.
        open(src, "w", encoding="utf-8-sig").write(
            build_source_function(name, sig, body, decl=decl))
        with BuildLock():
            p = subprocess.run([BMK, "makeapp", "-r", "-t", "console", src],
                               cwd=BMX_ROOT, env=_env(), capture_output=True,
                               text=True, errors="replace", timeout=900)
        if p.returncode != 0 or not os.path.exists(exe):
            res["status"] = "BUILD_FAIL"
            res["message"] = ((p.stdout or "") + (p.stderr or "")).strip()[-1500:]
            return res

        n = _bytematch.ghidra_sizes().get(orig_va)
        if not n:
            res["status"] = "UNCERTAIN_LEN"
            res["message"] = "0x%08X is not in Ghidra's inventory" % orig_va
            return res
        ab = _fn_bytes(_bytematch.ORIG, orig_va, n)

        objdir = os.path.join(wd, ".bmx")
        objs = [os.path.join(objdir, f) for f in os.listdir(objdir) if f.endswith(".o")]
        objpath = max(objs, key=os.path.getsize)
        syms = _helper_map.object_symbols(objpath)
        base = _helper_map.resolve_base(objpath, exe, syms)
        off = syms.get("_bb_" + name)
        if base is None or off is None:
            res["status"] = "ERROR"
            res["message"] = "could not locate _bb_%s in the probe" % name
            return res
        our_va = base + off
        b, va2off = _exe(exe)
        our_n = _bytematch.epilogue_len(b, va2off(our_va))
        cb = _fn_bytes(exe, our_va, our_n)
        res.update(orig_len=n, our_len=our_n, our_va="0x%08X" % our_va,
                   orig_len_from="ghidra")

        if ab is None or cb is None:
            res["status"] = "ERROR"
            res["message"] = "could not read one of the bodies"
            return res
        if n != our_n:
            # This path reports disasm_orig/disasm_ours and hex, exactly as try_method
            # does. An asymmetry between the two bites precisely when the disassembly is
            # most needed, so both report the same thing.
            _m, _same, _tot, _msk, _raw = compare(
                ab, cb, _span(_bytematch.ORIG), _span(exe),
                (_bytematch.ORIG, orig_va), (exe, our_va))
            first = masked_first_diff(ab, cb, _span(_bytematch.ORIG), _span(exe),
                                      (_bytematch.ORIG, orig_va), (exe, our_va),
                                      {}, _helper_map.full_table(), {})
            res.update(status="MISMATCH", mode="len", reloc_masked=_msk, first_diff=first,
                       matched=_same, total=_tot,
                       reason="length differs (orig %d vs ours %d)" % (n, our_n))
            res["disasm_orig"] = disasm_window(ab, orig_va, first)
            res["disasm_ours"] = disasm_window(cb, our_va, first)
            res["orig_hex"] = " ".join("%02X" % x for x in ab[:96])
            res["our_hex"] = " ".join("%02X" % x for x in cb[:96])
            return res

        try:
            ournames = {v: s for s, v in _helper_map.our_helpers(wd, exe)[0].items()}
            origtab = _helper_map.full_table()
            ourfns = _helper_map.our_functions(objpath, exe, syms, base)
        except Exception as ex:                                   # noqa: BLE001
            # Never swallow this silently. Empty name maps mean NOTHING masks by name,
            # which surfaces as a pile of unexplained call-operand differences and looks
            # exactly like a bad reconstruction. Record why.
            ournames, origtab, ourfns = {}, {}, {}
            res["naming_error"] = "%s: %s" % (type(ex).__name__, ex)
        learn = None if NO_LEARN else []
        ospan, uspan = _span(_bytematch.ORIG), _span(exe)
        mode, same, total, masked, first = compare(
            ab, cb, ospan, uspan, (_bytematch.ORIG, orig_va), (exe, our_va),
            ournames=ournames, origtab=origtab, learn=learn, ourfns=ourfns)
        if learn:
            # Do NOT rebind origtab to record()'s return value. record() persists and
            # returns only the bootstrapped C-runtime table, so rebinding silently drops
            # every BRL name that full_table() had merged in -- and the re-compare below
            # then cannot mask a call to e.g. _brl_filesystem_FileType, which looks like a
            # bad body. Merge the newly learned entries into the table we already have.
            # record() also ignores addresses outside the C-runtime range, so the BRL-range
            # entries we just learned exist only here.
            _persisted, conflicts = _helper_map.record([(v, sy) for v, sy, _k in learn])
            for _v, _sy, _known in learn:
                origtab.setdefault(_v, (_sy, 1))
            new = sorted({"0x%08x=%s" % (v, sy) for v, sy, k in learn if not k})
            if new:
                res["learned_helpers"] = new
            if conflicts:
                res["helper_conflicts"] = ["0x%08x %s vs %s" % c for c in conflicts]
        if mode == "learn":
            mode, same, total, masked, first = compare(
                ab, cb, ospan, uspan, (_bytematch.ORIG, orig_va), (exe, our_va),
                ournames=ournames, origtab=origtab, learn=None, ourfns=ourfns)

        res.update(mode=mode, matched=same, total=total, reloc_masked=masked,
                   status="MATCH" if mode in ("exact", "reloc") else "MISMATCH")
        if res["status"] == "MISMATCH":
            res["first_diff"] = first
            res["disasm_orig"] = disasm_window(ab, orig_va, first)
            res["disasm_ours"] = disasm_window(cb, our_va, first)
        return res
    except Exception as ex:                                       # noqa: BLE001
        res["status"] = "ERROR"
        res["message"] = "%s: %s" % (type(ex).__name__, ex)
        return res
    finally:
        if not keep and workdir is None and res.get("status") in ("MATCH", "MISMATCH"):
            shutil.rmtree(wd, ignore_errors=True)


SELFTEST = [
    ("TFormation", "GetRow",
     "Local r:Int = 4\nIf a0 < 28 Then r = 3\nIf a0 < 21 Then r = 2\n"
     "If a0 < 14 Then r = 1\nIf a0 < 7 Then r = 0\nReturn r"),
    ("TFormation", "GetCol", "Return a0 Mod 7"),
    ("TBall", "GetHeightScale", "Return 1.0 + a0 * 0.01"),
    ("TBall", "KeeperHolding",
     "If controlledby <> Null And controlledby.KeeperHoldingBall() Then Return True\n"
     "Return False"),
]


def selftest(verbose=True):
    """Must be 4/4. Every result is over the FULL Ghidra length -- no prefix passes."""
    ok, t0 = 0, time.time()
    for t, m, b in SELFTEST:
        t1 = time.time()
        r = try_method(t, m, b)
        det = "mode=%-6s %s/%s reloc=%s orig_len=%s(%s) our_len=%s" % (
            r.get("mode"), r.get("matched"), r.get("total"), r.get("reloc_masked"),
            r.get("orig_len"), r.get("orig_len_from"), r.get("our_len"))
        print("%-12s %-16s %-9s %5.1fs  %s" % (t, m, r["status"], time.time() - t1, det))
        if r.get("reason"):
            print("    reason: " + r["reason"])
        if r.get("message"):
            print("    " + r["message"].replace("\n", "\n    ")[:600])
        if verbose and r.get("disasm_orig"):
            print("    first diff at byte %d" % r["first_diff"])
            print("    -- original --\n" + r["disasm_orig"])
            print("    -- ours --\n" + r["disasm_ours"])
        ok += r["status"] == "MATCH"
    print("selftest: %d/%d MATCH   (%.1fs total)" % (ok, len(SELFTEST), time.time() - t0))
    return ok


def main():
    a = sys.argv[1:]
    if not a or a[0] == "--selftest":
        return 0 if selftest() == len(SELFTEST) else 1
    tname, mname, bodyfile = a[0], a[1], a[2]
    body = open(bodyfile, encoding="utf8").read()
    r = try_method(tname, mname, body, keep="--keep" in a)
    print(json.dumps(r, indent=1))
    return 0 if r["status"] == "MATCH" else 1


if __name__ == "__main__":
    sys.exit(main())
