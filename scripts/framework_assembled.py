"""
Would a `Framework` statement work on the REAL assembled program? -- run on a copy.

WHY A COPY. The Import header comes from `harness._build_prelude`, which every probe also
uses, and `scripts/assemble.py` may be running concurrently. Editing either would change
the codegen of everything else in flight. This copies the emitted source to
a scratch directory, rewrites only the copy's header, builds it, and reports. Nothing shared
is touched.

WHAT IT ANSWERS. A five-line probe established that omitting `Framework` makes bcc
auto-import the default module set: our `.text` is 1,128,960 bytes against the original's
755,712, and the identical 1,128,960 appears for a five-line program and for our
31,000-line assembly, because `.text` depends only on the module set.
That was a probe. This asks whether the real program still BUILDS with a framework, and what
it costs -- which is the question that actually matters.

WHAT IT DOES NOT ANSWER. `.text == 755712` is NOT a pass/fail oracle: `.text` is GCC output
and our GCC is not Simon Read's, so the number brackets the module set but cannot certify
it. Only the module body's own 15-call init chain, which states the original's real Import
list, can.
"""

import os
import shutil
import struct
import subprocess
import sys
import tempfile

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
os.environ.setdefault("NSS5_WORKER", "fwasm")

import framework_probe as FP   # noqa: E402
import harness as H            # noqa: E402

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ASM = os.path.join(ROOT, "src", "assembled", "nss5_assembled.bmx")
EXT = os.path.join(ROOT, "src", "assembled", "nss5_external.bmx")
TARGET_TEXT = 755712


def sections(path):
    d = open(path, "rb").read()
    pe = struct.unpack_from("<I", d, 0x3C)[0]
    n = struct.unpack_from("<H", d, pe + 6)[0]
    o = struct.unpack_from("<H", d, pe + 20)[0]
    off = pe + 24 + o
    out = {}
    for i in range(n):
        b = d[off + i * 40:off + i * 40 + 40]
        nm = b[:8].rstrip(b"\x00").decode("latin1")
        _vs, _va, rs, _ro = struct.unpack_from("<IIII", b, 8)
        out[nm] = rs
    return len(d), out


def build(wd, label):
    src = os.path.join(wd, "nss5_assembled.bmx")
    with H.BuildLock():
        p = subprocess.run([H.BMK, "makeapp", "-r", "-t", "console", src],
                           capture_output=True, text=True, cwd=H.BMX_ROOT, env=H._env())
    exe = src[:-4] + ".exe"
    if not os.path.exists(exe):
        msg = ((p.stdout or "") + (p.stderr or "")).strip()
        err = next((l for l in msg.splitlines() if "Error" in l), msg[-300:] or "<no output>")
        print("  %-22s BUILD FAILED  %s" % (label, err[:150]))
        return None
    total, s = sections(exe)
    print("  %-22s total %9d  .text %8d  code %8d  data %8d"
          % (label, total, s.get(".text", 0), s.get("code", 0), s.get("data", 0)))
    return s


def main():
    if not os.path.exists(ASM):
        print("no assembled source -- run scripts/assemble.py first")
        return 2

    text = open(ASM, encoding="utf-8", errors="replace").read()
    lines = text.split("\n")
    n_import = sum(1 for l in lines if l.startswith("Import "))
    has_fw = any(l.strip().startswith("Framework ") for l in lines)
    print("current header: %d Import lines, Framework present: %s" % (n_import, has_fw))
    print()

    # The 34-module base -- the archives credited with >=5 matched functions by
    # name_brl.py. Namespaces are read off disk, never guessed.
    #
    # PLUS the loaders. This is the better evidence: with the >=5 base alone the real program
    # does not COMPILE -- "Identifier 'LoadPixmapPNG' not found" -- so brl.pngloader is
    # REQUIRED, not merely plausible. A missing-symbol error names a needed module directly,
    # which beats marginal-.text arithmetic over the base set (that can only bracket, because
    # our GCC differs). Each of these was added because the build demanded it.
    inst = FP.installed_modules()
    base = []
    for short in FP.archives_used(5):
        if short == "blitz":
            continue
        ent = inst.get(short)
        if ent and ent[1]:
            base.append(ent[0])
    for short in ("pngloader", "jpgloader", "oggloader", "standardio", "random", "timer"):
        ent = inst.get(short)
        if ent and ent[1] and ent[0] not in base:
            base.append(ent[0])
    # Whatever the emitted source already imports must stay, or the program loses symbols.
    for l in lines:
        if l.startswith("Import ") and not l.startswith('Import "'):
            m = l.split(None, 1)[1].strip()
            if m.lower() not in [b.lower() for b in base]:
                base.append(m)

    baseline_dir = tempfile.mkdtemp(prefix="fwasm_base_")
    fw_dir = tempfile.mkdtemp(prefix="fwasm_fw_")
    for wd in (baseline_dir, fw_dir):
        shutil.copy(ASM, os.path.join(wd, "nss5_assembled.bmx"))
        if os.path.exists(EXT):
            shutil.copy(EXT, os.path.join(wd, "nss5_external.bmx"))

    # Rewrite ONLY the copy's header: drop the bare Imports, insert Framework + the list.
    p = os.path.join(fw_dir, "nss5_assembled.bmx")
    src = open(p, encoding="utf-8", errors="replace").read().split("\n")
    out, done = [], False
    for l in src:
        if l.startswith("Import ") and not l.startswith('Import "'):
            if not done:
                out.append("Framework BRL.Blitz")
                out.extend("Import " + m for m in base)
                done = True
            continue                      # drop the original bare Import
        out.append(l)
    open(p, "w", encoding="utf-8", newline="\n").write("\n".join(out))
    print("framework variant: Framework BRL.Blitz + %d imports" % len(base))
    print()

    a = build(baseline_dir, "as-is (no Framework)")
    b = build(fw_dir, "with Framework")
    print()
    print("  %-22s              .text %8d   <- the target" % ("NSS5.exe", TARGET_TEXT))
    if a and b:
        d = a.get(".text", 0) - b.get(".text", 0)
        print()
        print("  .text saved: %d bytes; remaining gap to target: %+d"
              % (d, b.get(".text", 0) - TARGET_TEXT))
        print("  code section: %d -> %d (original 1,046,528)"
              % (a.get("code", 0), b.get("code", 0)))
        print()
        print("  NOTE: .text cannot certify the import list -- our GCC is not Simon Read's")
        print("  This establishes only that a Framework BUILDS and what it costs.")
    for wd in (baseline_dir, fw_dir):
        shutil.rmtree(wd, ignore_errors=True)
    return 0


if __name__ == "__main__":
    sys.exit(main())
