"""Ground-truth address -> type, read from the game's own bootstrap code.

    python scripts/module_body_types.py            # print the table
    from module_body_types import types_by_address # {addr: (name, type, why)}

WHY THIS IS GROUND TRUTH AND THE ALIGNMENT IS NOT
=================================================
Almost every address in this project is inferred: a body's declared-name list is lined up
against the addresses its machine code touches, and the pairing falls out of the order.
That inference is good but it is an inference, and it has a known failure mode -- cdecl
pushes call arguments right-to-left, so `PlaySound(sound, channel)` touches the CHANNEL
first. Get that backwards and you pin the sound's name onto the channel's address.

The module body is different. It does not need aligning, because it says what it allocates:

    Global g_Object857:TChannel = AllocChannel()   ' 0x00C6F088
    Global g_Object859:TChannel = AllocChannel()   ' 0x00C6F090
    Global g_Object860:TSound   = LoadSoundChecked("GameMedia/Sounds/Cash.ogg", 0)  ' 0x00C6F0D4

`AllocChannel()` can only return a TChannel. So 0x00C6F090 is a TChannel, full stop, and
any claim that a TSound lives there is wrong no matter how the alignment reads.

WHAT WENT WRONG WITHOUT THIS
============================
extracted/global_address_adjudicated.tsv pinned BOTH arguments of the same call to one
address -- g_slot_snd_win (the sound) and g_audio_channel (the channel) were both given
0x00C6F090, with the second row's own evidence quoting "arg 2 of _brl_audio_PlaySound".
Seven TSound names in total landed on that TChannel slot (g_snd_negotiate, g_snd_win,
g_sound_fail, g_sound_success, g_object802, g_slot_snd_win, g_snd_alert), every one from a
PlaySound call site read in the wrong argument order. Applying those merges would have
fused a TSound name into a TChannel slot.

Two independent sources agree against them: this file's `AllocChannel()` line, and the
byte-verified src/recovered_module/UpdateAudio.bmx header ("0x00C6F090 g_speechchannel
:TChannel -- same slot [0x38 SetVolume]").

THE EXPRESSION OUTRANKS THE DECLARED TYPE
=========================================
Where the annotation and the initialiser disagree, the initialiser wins -- it is what the
program actually does, whereas the `:Type` is what a recovery pass believed. Recognised
constructors are listed in EXPR_TYPE below; anything unrecognised falls back to the
declared type and is marked as such in `why`, so a caller can weight it lower.

This covers only the ~21 Globals the bootstrap allocates, which is a small fraction of
1,700+. It is not a general address map -- it is a small set of facts that outrank
inference wherever they overlap.
"""
import os
import re

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SRC = os.path.join(ROOT, "src", "recovered_unverified", "ModuleBody_RealProgram.bmx")

# Constructor -> the type it can only ever return.
EXPR_TYPE = [
    (re.compile(r"\bAllocChannel\s*\(", re.I), "TChannel"),
    (re.compile(r"\bLoadSound(?:Checked)?\s*\(", re.I), "TSound"),
    (re.compile(r"\bLoadImage(?:Checked)?\s*\(", re.I), "TImage"),
    (re.compile(r"\bLoadAnimImage(?:Checked)?\s*\(", re.I), "TImage"),
    (re.compile(r"\bCreateList\s*\(", re.I), "TList"),
    (re.compile(r"\bCreateMap\s*\(", re.I), "TMap"),
    (re.compile(r"\bNew\s+([A-Za-z_][\w.]*)", re.I), None),   # None -> use the captured name
]

DECL = re.compile(
    r"^\s*Global\s+(\w+)\s*:\s*([A-Za-z_][\w.]*(?:\s*\[[^\]]*\])?)\s*"
    r"(=\s*(.*?))?\s*'\s*(0x00[0-9A-Fa-f]{6})", re.M)


def norm(addr):
    return "0x%08X" % int(addr, 16)


def types_by_address():
    """-> {address: (name, type, why)}  for Globals the bootstrap allocates."""
    if not os.path.exists(SRC):
        return {}
    text = open(SRC, encoding="utf-8", errors="replace").read()
    out = {}
    for m in DECL.finditer(text):
        name, declared, _, expr, addr = m.groups()
        declared = declared.strip()
        ty, why = declared, "declared type (no recognised constructor)"
        if expr:
            for rx, fixed in EXPR_TYPE:
                hit = rx.search(expr)
                if not hit:
                    continue
                cand = fixed or hit.group(1)
                ty = cand
                why = "allocated by %s" % hit.group(0).rstrip("( ")
                break
        out[norm(addr)] = (name, ty, why)
    return out


def conflicts(addr, ty, table=None):
    """True if `ty` contradicts what the bootstrap allocates at `addr`.

    Compared on the leaf name so brl.audio.TChannel and TChannel agree. Unknown addresses
    never conflict -- this table is a small set of facts, not a whitelist.
    """
    table = types_by_address() if table is None else table
    known = table.get(norm(addr) if addr else "")
    if not known or not ty:
        return False
    a = known[1].split("[")[0].strip().rsplit(".", 1)[-1].lower()
    b = ty.split("[")[0].strip().rsplit(".", 1)[-1].lower()
    return a != b


def main():
    t = types_by_address()
    print("MODULE-BODY TYPE ORACLE  (%d addresses)" % len(t))
    print("  source: %s" % os.path.relpath(SRC, ROOT))
    print()
    print("  %-12s %-30s %-12s %s" % ("ADDRESS", "NAME", "TYPE", "WHY"))
    for a in sorted(t):
        n, ty, why = t[a]
        print("  %-12s %-30s %-12s %s" % (a, n[:30], ty, why))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
