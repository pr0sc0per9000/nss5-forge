"""
Does the missing `Framework` statement explain our oversized .text? -- a controlled probe.

THE OBSERVATION. NSS5.exe's `.text` (GCC output: the C runtime and the C half of the
BRL/PUB modules) is 755,712 bytes. Our assembled build's `.text` is 1,128,960 -- 373 KB
MORE, for a program containing a fraction of the game's code. Something is linking modules
the original never used.

THE HYPOTHESIS. `src/assembled/nss5_assembled.bmx` opens with `SuperStrict` and eight
`Import` lines and NO `Framework` statement. In BlitzMax, omitting `Framework` makes bcc
auto-import the default module set rather than only what is reachable from an explicit
framework -- the standard reason a BlitzMax exe comes out far larger than it needs to be.

WHY A PROBE RATHER THAN AN EDIT. scripts/assemble.py is a shared build file that other
passes edit. Rewriting a shared file to test a hypothesis risks corrupting work in flight,
so this measures the mechanism in isolation, on two throwaway programs, and changes nothing
shared.

WHAT IT PROVES AND WHAT IT DOES NOT. It establishes whether `Framework` is the lever and how
large the effect is. It does NOT by itself give the original's exact framework/import list.
That list has to come from the module body's own init chain -- though the 49 archives that
contributed named functions to NSS5.exe (extracted/brl_functions.tsv, column 3) bound it
from below.

Usage: framework_probe.py
"""

import os
import shutil
import struct
import subprocess
import sys
import tempfile

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

os.environ.setdefault("NSS5_WORKER", "fwprobe")

import harness as H   # noqa: E402

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

BODY = """
Local l:TList = New TList
l.AddLast("x")
Local p:TPixmap = CreatePixmap(4, 4, PF_RGBA8888)
Local s:TStream = WriteStream("::probe::")
Print l.Count()
"""

NO_FRAMEWORK = """SuperStrict
Import BRL.Audio
Import BRL.LinkedList
Import BRL.Map
Import BRL.Max2D
Import BRL.Pixmap
Import BRL.Stream
Import BRL.TextStream
""" + BODY

WITH_FRAMEWORK = """SuperStrict
Framework BRL.Blitz
Import BRL.LinkedList
Import BRL.Map
Import BRL.Pixmap
Import BRL.Stream
Import BRL.StandardIO
""" + BODY


def sections(path):
    d = open(path, "rb").read()
    pe = struct.unpack_from("<I", d, 0x3C)[0]
    nsec = struct.unpack_from("<H", d, pe + 6)[0]
    optsz = struct.unpack_from("<H", d, pe + 20)[0]
    off = pe + 24 + optsz
    out = {}
    for i in range(nsec):
        b = d[off + i * 40:off + i * 40 + 40]
        name = b[:8].rstrip(b"\x00").decode("latin1")
        _vs, _va, rawsz, _raw = struct.unpack_from("<IIII", b, 8)
        out[name] = rawsz
    return len(d), out


def build(label, src):
    wd = tempfile.mkdtemp(prefix="fwprobe_")
    path = os.path.join(wd, "probe.bmx")
    with open(path, "w", encoding="utf-8", newline="\n") as f:
        f.write(src)
    # Serialise through the same cross-process mutex the oracle uses: bmk/fasm/gcc keep
    # scratch state inside the BlitzMax tree, and another build may be running at the
    # same time.
    # env=H._env() is REQUIRED, not optional: it puts mingw on PATH. Without it bcc and
    # fasm both succeed, bmk prints "Linking:probe.exe", and gcc then fails SILENTLY --
    # no error, no exe, and nothing in the output to say why.
    with H.BuildLock():
        p = subprocess.run([H.BMK, "makeapp", "-r", "-t", "console", path],
                           capture_output=True, text=True, cwd=H.BMX_ROOT, env=H._env())
    exe = path[:-4] + ".exe"
    if not os.path.exists(exe):
        # bmk does not always drop the exe beside the source; find whatever it produced.
        found = [os.path.join(dp, fn) for dp, _dn, fns in os.walk(wd)
                 for fn in fns if fn.lower().endswith(".exe")]
        if found:
            exe = max(found, key=os.path.getsize)
        else:
            print("  %-16s BUILD FAILED (rc=%s)" % (label, p.returncode))
            msg = ((p.stdout or "") + (p.stderr or "")).strip()
            print("    " + (msg[-900:] if msg else "<no output at all>").replace("\n", "\n    "))
            return None
    total, secs = sections(exe)
    print("  %-16s total %9d   .text %8d   code %8d   data %9d"
          % (label, total, secs.get(".text", 0), secs.get("code", 0), secs.get("data", 0)))
    shutil.rmtree(wd, ignore_errors=True)
    return secs


def installed_modules():
    """{short name -> 'namespace.short'} for every module in the tree.

    Namespaces are NOT guessable. `maxlua` lives at mod/brl.mod/maxlua.mod (so BRL.MaxLua,
    not MaxLua.MaxLua) and `freejoy` at mod/pub.mod/freejoy.mod (so PUB.FreeJoy, not
    BRL.FreeJoy). Guessing wrong makes bmk fail -- sometimes with an EMPTY error message,
    which reads like a broken toolchain instead of a typo. Read them off disk.
    """
    root = os.path.join(H.BMX_ROOT, "mod")
    out = {}
    for ns in sorted(os.listdir(root)):
        if not ns.endswith(".mod"):
            continue
        nsdir = os.path.join(root, ns)
        if not os.path.isdir(nsdir):
            continue
        for m in sorted(os.listdir(nsdir)):
            if not m.endswith(".mod"):
                continue
            short = m[:-4]
            # An interface (.i) must exist or bcc reports "Can't find interface for module".
            has_i = any(f.endswith(".release.win32.x86.i")
                        for f in os.listdir(os.path.join(nsdir, m)))
            out.setdefault(short.lower(), (ns[:-4] + "." + short, has_i))
    return out


def archives_used(min_count=1):
    """Short module names whose archive contributed >= min_count NAMED functions.

    THE COUNT IS THE CONFIDENCE. name_brl.py matches by comparing bytes with relocation
    offsets excluded, so a module credited with ONE function is weak evidence -- one small
    routine can coincide across modules. Modules credited with dozens are not in doubt.
    Raising the threshold is therefore a real filter, not arbitrary trimming, and it matters
    because importing a spurious module (maxgui, maxlua) drags in a large C dependency and
    inflates .text rather than shrinking it.
    """
    import collections
    import csv
    counts = collections.Counter()
    p = os.path.join(ROOT, "extracted", "brl_functions.tsv")
    with open(p, encoding="utf-8") as f:
        for r in csv.reader(f, delimiter="\t"):
            if len(r) < 3 or not r[2].endswith(".a"):
                continue
            counts[r[2].split(".")[0].lower()] += 1
    return [n for n, c in counts.most_common() if c >= min_count]


def candidate_source(min_count=1):
    inst = installed_modules()
    lines, missing, nointf = [], [], []
    for short in archives_used(min_count):
        if short in ("blitz",):
            continue                      # the Framework itself
        ent = inst.get(short)
        if not ent:
            missing.append(short)
            continue
        full, has_i = ent
        if not has_i:
            nointf.append(full)
            continue
        lines.append("Import " + full)
    return ("SuperStrict\nFramework BRL.Blitz\n" + "\n".join(lines) + "\n" + BODY,
            missing, nointf)


_UNUSED_CANDIDATE = """SuperStrict
Framework BRL.Blitz
Import BRL.Max2D
Import BRL.Bank
Import BRL.BankStream
Import BRL.DXGraphics
Import BRL.Stream
Import BRL.Reflection
Import BRL.D3D7Max2D
Import BRL.D3D9Max2D
Import BRL.GLMax2D
Import BRL.FileSystem
Import BRL.LinkedList
Import BRL.Map
Import BRL.Pixmap
Import BRL.TextStream
Import BRL.GNet
Import BRL.Socket
Import BRL.SocketStream
Import BRL.HTTPStream
Import BRL.EndianStream
Import BRL.FreeJoy
Import BRL.OpenALAudio
Import BRL.Audio
Import BRL.FreeAudioAudio
Import BRL.DirectSoundAudio
Import BRL.AudioSample
Import BRL.GLGraphics
Import BRL.System
Import BRL.PolledInput
Import BRL.Retro
Import BRL.Event
Import BRL.FreeTypeFont
Import BRL.Graphics
Import BRL.JPGLoader
Import BRL.PNGLoader
Import BRL.OGGLoader
Import BRL.Hook
Import BRL.Random
Import BRL.StandardIO
Import BRL.Font
Import MaxGUI.MaxGUI
Import MaxGUI.Win32MaxGUIEx
Import MaxGUI.Localization
Import BRL.MaxLua
""" + BODY
# NOTE the namespaces: maxlua lives at mod/brl.mod/maxlua.mod, so it is BRL.MaxLua, NOT
# MaxLua.MaxLua. Getting that wrong makes bmk fail with an EMPTY error message, which reads
# like a toolchain problem rather than a typo.


def main():
    print("FRAMEWORK PROBE -- identical program, three module-set declarations")
    print()
    a = build("no Framework", NO_FRAMEWORK)
    b = build("with Framework", WITH_FRAMEWORK)
    print()
    print("  sweeping the name_brl confidence threshold (a module credited with N matched")
    print("  functions; N=1 is weak evidence, N>=20 is not in doubt):")
    print()
    best = None
    for thr in (1, 5, 10, 20, 30):
        cand, missing, nointf = candidate_source(thr)
        nmods = cand.count("Import ")
        c = build("thr>=%-2d (%2d mods)" % (thr, nmods), cand)
        if c:
            got = c.get(".text", 0)
            print("      -> .text %8d   delta vs 755712 = %+d" % (got, got - 755712))
            if best is None or abs(got - 755712) < abs(best[1] - 755712):
                best = (thr, got, nmods)
        if thr == 1:
            if missing:
                print("      modules NSS5 used that are NOT INSTALLED: %s" % ", ".join(missing))
            if nointf:
                print("      installed but NOT BUILT (no .i): %s" % ", ".join(nointf))
    print()
    if best:
        print("  closest: threshold >=%d, %d modules, .text %d (delta %+d)"
              % (best[0], best[2], best[1], best[1] - 755712))
        print("  This is a LOWER bound on the import list: a module whose functions were all")
        print("  inlined or left unnamed contributes no archive row at any threshold.")
    print()
    print("  NSS5.exe (target)          .text   755712")
    if a and b:
        d = a.get(".text", 0) - b.get(".text", 0)
        print()
        print("  .text saved by Framework : %d bytes (%.1f%%)"
              % (d, 100.0 * d / max(1, a.get(".text", 1))))
        print()
        if d > 0:
            print("  CONFIRMED: `Framework` is the lever. The assembled program must declare one,")
            print("  and the exact framework/import list is part of reconstructing the module")
            print("  body -- it is not a build-script preference, it decides which modules are")
            print("  linked and therefore what lands in BOTH .text and `code`.")
        else:
            print("  NOT CONFIRMED on this probe: Framework did not reduce .text here. The size")
            print("  gap has another cause; do not act on the hypothesis.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
