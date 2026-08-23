"""Guard the original's OWN unguarded Null reads, in the debug source only.

    bash scripts/build_debug.sh          # runs this after the copy, before the compile
    python scripts/debug_shims.py        # or by hand, on src/assembled/nss5_dbg.bmx
    python scripts/debug_shims.py --list # the registry and its evidence, touching nothing

Reads src/assembled/nss5_dbg.bmx, rewrites it in place, and never opens nss5_assembled.bmx
or anything under src/recovered*. Same shape and same reason as scripts/instrument_trace.py:
source-to-source on a generated file, so the corpus and the byte figures cannot move.

WHAT THIS IS FOR
================
NSS5.exe contains reads through pointers that can be Null, with the Null test AFTER the
read rather than before it. Retail survives every one of them, because in BlitzMax `Null`
is the real address of `bbNullObject` (0x005C9C80 in this binary, which is what every
`cmp reg,0x5c9c80` in the disassembly is testing against). A field read through it lands in
.data and returns whatever is sitting there, and the code then takes a branch that happens
to be harmless. `makeapp -r` compiles no check, so retail never notices.

`makeapp -d` compiles the check, so the same read raises "Attempt to access field or method
of Null object" and the process dies. That is the debug build being MORE correct than the
game, and it makes the debug build useless for finding the defects it exists to find: the
player cannot walk past the original's own bug to reach ours.

So each entry here replaces one such read with a guard that produces the value retail
produces. Not a fix, not a fallback, not a safety net -- a transcription of what the
original observably does, into a form `-d` will accept.

WHY NOT FIX THE BODIES
======================
Because they are not broken. Every site here is byte-identical or better against NSS5.exe,
and several already carry a `BUG (original), preserved` note telling the next reader not to
add a Null guard. Adding one would change the bytes and lose the reconstruction. The guard
belongs to the debug BUILD, not to the reconstruction, which is why it lives in a generated
file that release never sees.

WHAT AN ENTRY HAS TO PROVE
==========================
Three things, all from the binary, none from inference:

  1. The original performs the same read with no Null test in front of it. Cited as the VA
     of the read, and of the test that comes after it.
  2. Retail survives. The read is a FIELD read, not a method call -- `bbNullObject.clas` is
     0, so a method call through Null faults in retail too and is NOT in this class -- and
     the value it returns from .data is quoted, along with the branch retail then takes.
  3. The guard reproduces that branch exactly. Not a shorter path to the same screen: the
     same value in the same variable, with the rest of the body left alone.

An entry that cannot carry all three is not registered. A guard nobody can check is worse
than the crash, because the crash at least tells the truth.

WHY A MISSING ANCHOR IS A HARD FAILURE
======================================
If a registered anchor no longer appears in the generated source, this exits non-zero and
build_debug.sh refuses to link. A shim that silently stopped applying because a body was
rewritten is the worst outcome available: the reporter would be told the build is guarded,
walk into the fault anyway, and have no reason to suspect the tool rather than the game.
"""
import os
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DEFAULT_TARGET = os.path.join(ROOT, "src", "assembled", "nss5_dbg.bmx")

# Every line this writes carries this tag, so a reader of nss5_dbg.bmx can tell injected
# text from reconstructed text without knowing this script exists.
TAG = "' [debug-shim]"

SITES = [
    {
        "id": "UpdateNavPanel-fx-compid",
        "function": "TScreen_GameMenu.UpdateNavPanel",
        "va": "0x0053AD21",
        "original": [
            "mov  eax,[ebp-0xc]     ; fx, stored at 0x0053ACF7 from GetNextFixture",
            "push dword [eax+0x40]  ; fx.compid, with no cmp against 0x5c9c80 before it",
            "call dword [0xc6160c]  ; = 0x0050A60F TCompetition.SelectById",
            "the Null test for fx is at 0x0053AD35, four instructions AFTER the read",
        ],
        "retail": [
            "fx is Null the first time a career signs a contract: fixtures do not exist",
            "until StartCareer runs, and TContractOffer.SignForNewClub calls UpdateNavPanel",
            "before the accept callback that starts the career. Retail therefore reads",
            "[0x005C9C80+0x40] = [0x005C9CC0] = 0x004A8E80 and asks SelectById for that id.",
            "SelectById (0x0050A60F, 102 bytes, byte-identical) is a bare",
            "`For Local c:TCompetition = EachIn g_competitions` with no side effect of any",
            "kind, so a lookup that misses and a lookup never made are the same event: comp",
            "ends up Null, the `fx <> Null And opp <> Null And comp <> Null` block below is",
            "skipped either way, and the tail writes tla_ToBeConfirmed as intended.",
        ],
        "faithful": [
            "Not a reconstruction defect. fx comes from a Method call, not from a module",
            "Global, so this is not the unmerged-alias failure dead_globals.py hunts. The",
            "body is CLEAN 1361/1361 under localise_diff and its header already carries the",
            "preserve-by-default note for this exact line.",
        ],
        "anchor": "Local comp:TCompetition = TCompetition.SelectById(fx.compid)",
        "lines": [
            "Local comp:TCompetition = Null",
            "If fx <> Null Then comp = TCompetition.SelectById(fx.compid)",
        ],
    },
    {
        "id": "GetStringArrayForTeamId-c-comptype",
        "function": "TFixture.GetStringArrayForTeamId",
        "va": "0x004C3EE5",
        "original": [
            "004C3D21  cmp dword [ebp-0x10],0x5c9c80   ; c, from SelectById at 0x004C3D15",
            "004C3D28  je  0x004C3EE5                  ; c IS Null -> jump to the read below",
            "004C3EE5  mov eax,[ebp-0x10]              ; the je lands ON the unguarded read",
            "004C3EE8  mov eax,[eax+0x24]              ; c.comptype",
            "the guard block that tested c closes at 0x004C3EE5; this read is outside it",
        ],
        "retail": [
            "With c Null retail reads [0x005C9C80+0x24] = [0x005C9CA4] = 0x004A8EE0, which is",
            "not 1, so `cmp eax,1`/sete/je at 0x004C3EEB..0x004C3EF7 falls straight through to",
            "0x004C3F11 and the whole condition is False. The second operand is a method call",
            "(`call dword [eax+0xd4]` at 0x004C3EFF, dispatched through c's class pointer) and",
            "would fault in retail too -- bbNullObject.clas is 0 -- but the And short-circuits",
            "before reaching it. So the guard has to make the condition False, which is what",
            "prepending `c <> Null` does, and it must stay in front so the call is still",
            "unreachable when c is Null.",
        ],
        "faithful": [
            "Not a reconstruction defect. The body is byte-identical 2842/2842 and its own",
            "header records this as ORIGINAL BUG (preserved, not fixed), with the note that",
            "the absence of the guard was confirmed in the original bytes.",
        ],
        "anchor": "If c.comptype = 1 And c.AllFixturesPopulated() = 0",
        "lines": [
            "If c <> Null And c.comptype = 1 And c.AllFixturesPopulated() = 0",
        ],
    },
]


def banner(site, indent):
    """The comment block that goes above a guard, in the generated file."""
    out = [indent + TAG + " " + site["function"] + "  retail " + site["va"],
           indent + TAG + " Injected by scripts/debug_shims.py. NOT reconstructed code, and",
           indent + TAG + " not present in the release build. Do not copy it into src/."]
    for line in site["original"]:
        out.append(indent + TAG + "   " + line)
    for line in site["retail"]:
        out.append(indent + TAG + " " + line)
    return out


def marker(site):
    return TAG + " " + site["id"]


def apply_site(lines, site):
    """Return (new_lines, line_number) or ('already', n) or raise SystemExit."""
    anchor = site["anchor"]
    hits = [i for i, l in enumerate(lines) if l.strip() == anchor]
    done = [i for i, l in enumerate(lines) if marker(site) in l]

    if len(hits) == 1:
        i = hits[0]
        indent = lines[i][:len(lines[i]) - len(lines[i].lstrip())]
        block = banner(site, indent)
        for n, l in enumerate(site["lines"]):
            block.append(indent + l + "   " + marker(site))
        return lines[:i] + block + lines[i + 1:], i + 1

    if not hits and done:
        # build_debug.sh --trace can be re-run over an already-patched nss5_trace.bmx.
        # Distinguishable from a lost anchor because the tag is still there.
        return None, done[0] + 1

    raise SystemExit(
        "debug shim %s NO LONGER APPLIES.\n"
        "  function : %s   retail %s\n"
        "  wanted   : %s\n"
        "  found    : %d matching line(s), %d already tagged\n"
        "The generated source moved under the registry. Re-derive the anchor and the\n"
        "evidence in scripts/debug_shims.py before building: a debug binary that silently\n"
        "stopped being guarded is worse than one that was never guarded, because the\n"
        "reporter would believe they are testing something they are not."
        % (site["id"], site["function"], site["va"], anchor, len(hits), len(done)))


def show_registry():
    print("%d site(s) registered" % len(SITES))
    for s in SITES:
        print()
        print("  %s   retail %s" % (s["function"], s["va"]))
        print("    anchor : %s" % s["anchor"])
        for l in s["original"]:
            print("      %s" % l)
        print("    retail behaviour:")
        for l in s["retail"]:
            print("      %s" % l)
        print("    why this is the original's bug and not ours:")
        for l in s["faithful"]:
            print("      %s" % l)
    return 0


def main():
    argv = [a for a in sys.argv[1:] if a != "--list"]
    if "--list" in sys.argv:
        return show_registry()

    target = argv[0] if argv else DEFAULT_TARGET
    if not os.path.exists(target):
        raise SystemExit("no %s -- run scripts/assemble.py, then build_debug.sh"
                         % os.path.relpath(target, ROOT))

    lines = open(target, encoding="utf-8-sig", errors="replace").read().split("\n")
    applied = []
    for site in SITES:
        new, n = apply_site(lines, site)
        if new is None:
            applied.append((site, n, "already present"))
        else:
            lines = new
            applied.append((site, n, "applied"))

    with open(target, "w", encoding="utf-8", newline="") as f:
        f.write("\n".join(lines))

    print("debug shims -> %s" % os.path.relpath(target, ROOT))
    for site, n, how in applied:
        print("  %-34s retail %s  line %-6d %s"
              % (site["function"], site["va"], n, how))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
