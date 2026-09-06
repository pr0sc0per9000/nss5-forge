"""
Assemble every verified body into ONE program and compile it.

WHY THIS IS THE MISSING TEST
============================
1,215 functions are verified byte-identical -- individually. Each was proved inside a probe
that contained exactly ONE real body and 134 Types of stubs. Nothing has ever put them
together, so nothing has tested:

  * do the Globals different bodies assume actually agree? Each body declares its own via
    '!Global pragmas, chosen independently by different passes. Two
    bodies can disagree about the TYPE of the same Global and both verify alone.
  * do the module Functions collide by name?
  * does anything reference a Type member that only existed as a stub?
  * does the whole thing still compile once the stub bodies are real?

That gap is the entire distance between "N functions verified" and "a game that boots", and
it widens with every body banked. This measures it.

WHAT IT DOES NOT CLAIM
======================
Compiling is NOT byte-matching. A successful build here proves the corpus is internally
consistent, not that the assembled program equals NSS5.exe. Whole-image byte comparison
needs the module body and the original's exact GCC for the C runtime. This is the
consistency gate that has to pass first.

--check-selfcontained: THE GATE, WITHOUT THE BUILD
==================================================
A recovered file is supposed to be the durable artefact -- the thing that can be rebuilt
from itself years from now with nothing but the exe and the harness. A body that references
a module Global the FILE never declares is not that: it verifies only because the pass that
wrote it happened to have the declaration in its probe. Per-function verification is
structurally incapable of catching this, because the probe is built from the pass's message
and not from the file.

The defect is common and it renews itself: of 66 files that landed in src/recovered during
one hour of concurrent work, three had it -- so this regresses at roughly one file per
twenty minutes of corpus growth unless something checks.

This assembler already reads every recovered file's body, its '!Global pragmas and its
comments, and already reports the Globals it had to recover from PROSE or INFER from usage.
`--check-selfcontained` reports that, adds the per-FILE test those two tiers cannot make
(see selfcontained_defects), and returns before writing or compiling anything, so it is
usable as a pre-commit gate and in CI. Exit 1 if any file is not self-contained.

Usage:  assemble.py [--keep]
        assemble.py --check-selfcontained    the Globals gate only; no build
"""

import collections
import os
import re
import subprocess
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

import harness as H

ROOT = H.ROOT
RECOVERED = os.path.join(ROOT, "src", "recovered")
MODULE_FNS = os.path.join(ROOT, "src", "recovered_module")
OUT_DIR = os.path.join(ROOT, "src", "assembled")

DECL_ORDER = os.path.join(ROOT, "extracted", "type_declaration_order.tsv")
GLOBAL_OVERRIDES = os.path.join(ROOT, "extracted", "globals_type_overrides.tsv")
MODTREE = os.path.join(ROOT, "tools", "blitzmax-legacy-src", "mod")
MODULE_GLOBALS_DECODED = os.path.join(ROOT, "extracted", "module_globals_decoded.tsv")

# ---- the module body -------------------------------------------------------------
# The top-level program: 11 Incbin statements, the module-scope Globals, and the tail
# that ends in GameMain(). Without these the assembled source compiles but is not a
# program -- it declares 135 Types and ~2,700 Globals and then does nothing.
UNVERIFIED = os.path.join(ROOT, "src", "recovered_unverified")

# Near-miss bodies that are known NOT TO COMPILE, and why. Excluded from the build so one
# blocked body cannot take the whole program down with it; each is left as the empty stub
# an unrecovered function gets.
#
# The three ZipFile delegates that used to be listed here are gone: all of them invented a
# callee name on the zip container Type (getCount / getEntry / getEntryByName) where the
# real TZipFileList methods are getFileCount @0x34, getFileInfo @0x38 and findFile @0x3c.
# TZipFileList's full member set was always in the reflection data
# (extracted/vtable_map.tsv lines 2783-2791, extracted/object_model.json) and harness.py
# always emitted it as a real stub with the correct slots; the headers blaming a missing
# placeholder were wrong. All three are byte-verified and now live in the recovered trees.
UNVERIFIED_SKIP = {
    # --- Steam. Excluded because this reconstruction strips Steam entirely, not because
    # they are broken. Each carries '!Import ".../libsteamstub.a" plus a '!Raw Extern block,
    # and those pragmas are collected from the FILE, not from whichever body wins the tier
    # contest -- so leaving them in re-imports the whole Steam link surface that
    # src/recovered_module/SteamInit.bmx is written to avoid, and breaks the
    # build outright with "'End Extern' without matching 'Extern'".
    "Fn_0058D987.SteamPostPlayerValue.bmx",   # The dead leaderboard call: it stalls every
                                              # save for up to 2s waiting on a server that
                                              # does not answer. MOVED 2026-08-22 to
                                              # src/recovered_module/ (byte-identical,
                                              # 325/325) so helper_map.orig_functions() can
                                              # name VA 0x0058D987 for its caller; it is
                                              # kept out of the build by harness.py
                                              # MODULE_SKIP now, not by this line. The name
                                              # is retained here only as a guard in case the
                                              # file ever returns to recovered_unverified.
    "TLocale.SetUp.bmx",                      # Duplicate: the VERIFIED body already exists
                                              # at src/recovered/TLocale.SetUp.bmx and wins
                                              # the tier contest anyway. Listing it here
                                              # keeps its Steam pragmas out too.
    # TProfile.SaveGame.bmx WAS LISTED HERE AND IS NOT ANY MORE.
    # It was skipped for two stated reasons, and both were wrong by the time they were
    # written:
    #   1. "assembling this body would leave an undefined reference" to
    #      SteamPostPlayerValue, which harness.MODULE_SKIP keeps out of the build. It does
    #      not. The file carries its own
    #          '!Raw Function SteamPostPlayerValue:Int()
    #          '!Raw End Function
    #      and the raw-pragma path a few dozen lines below emits that verbatim into the
    #      assembled program -- exactly as it already does for the identical
    #      SyncSteamAchievements placeholder in src/recovered/TProfile.LoadSavedGame.bmx,
    #      which has been in every build for months (grep the emitted source: `Function
    #      SyncSteamAchievements()` is there). No Import is involved: the file declares no
    #      '!Import, so no Steam link surface comes with it, and the empty placeholder also
    #      removes the up-to-2s leaderboard stall the real callee would add to every save.
    #   2. "moot under the clean-break save format (this project writes its own)". Nothing
    #      ever wrote one. src/behaviour/ was empty and TProfile.SaveGame assembled to
    #      `Method SaveGame:Int(a0:String) / End Method` -- an empty stub -- while its six
    #      callers (TProfile.StartCareer, TProfile.FixturePlayed, TScreen_GameMenu.ButtonQuit,
    #      TScreen_Options.ButtonTick, TScreen_SeasonReview.ButtonPlay and
    #      TScreen_WorldMap.SetUpScreen's pre-travel autosave) all called it and got nothing.
    #      That is the whole "saving does not save, and no career appears in the load list"
    #      defect: no .sav was ever written, so TScreen_MainMenu.UpdateLoadTable's scan of
    #      g_userpath + "Save/" found an empty directory. The clean break is now real and
    #      lives in src/behaviour/Zip{Writer,Reader}.* -- see those files.
    "TProfile.CheckAchievement.bmx",          # Steam. The other two reasons this entry
                                              # used to give are both FIXED and no longer
                                              # true (2026-08-22): the Extern block is
                                              # '!Raw pragmas now, not ordinary statements,
                                              # so there is no orphan `End Extern`; and the
                                              # body does NOT perform an extra
                                              # reference-release -- the original retains
                                              # only (`inc [eax+4]` @0x0056cfc7), which is
                                              # bcc's initGlobalRef path, and the body
                                              # reproduces it. It now builds and reaches
                                              # MATCH 625/625 mode=reloc (it needs its
                                              # '!GlobalInit 98 pragma; see the file's own
                                              # header). Kept here purely because it
                                              # Imports libsteamstub.a, which
                                              # src/recovered_module/SteamInit.bmx exists to
                                              # keep out of the shipped build -- the same
                                              # reason the equally-matched
                                              # Fn_0058D987.SteamPostPlayerValue.bmx is
                                              # listed above.
}
# A '!Global pragma's TYPE is the rest of the declaration, not one whitespace-delimited
# token. The old `(\S+)` stopped at the first space, so
#     '!Global g_hookFn:Byte Ptr(a:Int, b:Int)      (src/recovered_module/Fn_00595EF3.bmx)
# was emitted into the assembled program as
#     Global g_hookfn:Byte
# and the call through it failed the whole-program build with
#     Compile Error: Expression of type 'Byte' cannot be invoked
# -- an error naming a type nothing in the corpus ever declares, pointing at a call site
# rather than at the declaration that mistyped it. Single-body probes never see this:
# harness.merge_globals folds the pragma in verbatim, so the body verifies byte-identical
# while the assembled build cannot compile.
#
# Stop at `=` (an initialiser) and at `'` (a trailing comment), both of which follow the
# type rather than belong to it, and otherwise take everything to end of line.
GLOBAL_DECL_RX = re.compile(r"Global\s+(\w+)\s*:\s*([^=']+?)\s*(?:=|'|$)")

BEHAVIOUR = os.path.join(ROOT, "src", "behaviour")
PLACEHOLDER = os.path.join(ROOT, "src", "placeholder")
MODBODY_DIR = os.path.join(ROOT, "src", "module_body")
MODBODY_TAIL = os.path.join(MODBODY_DIR, "tail.bmx")
MODBODY_GLOBALS = os.path.join(MODBODY_DIR, "globals.tsv")
INCBIN_SRC = os.path.join(ROOT, "extracted", "incbin")

# The eleven Incbin'd assets, IN THE ORDER the module body registers them
# (the eleven _bbIncbinAdd calls sit at body offset +54..+344, each 29 bytes apart,
# and each call's arguments were cross-checked against the asset VAs).
#
# The string here is the resource NAME as well as the path: BlitzMax registers an
# Incbin under the literal text given, and game code reaches these as
# "incbin::Inc/<name>" (LoadImageChecked's `a0.StartsWith("incbin")` fast path exists
# precisely for them). So the spelling must stay exactly "Inc/..." and the tree must
# sit next to the generated source -- copy_incbin_tree() below does that.
INCBIN_ORDER = [
    "Inc/Credits.txt",
    "Inc/Player.png",
    "Inc/TCCEB.TTF",
    "Inc/RUSSIAN.TTF",
    "Inc/Music/Intro.ogg",
    "Inc/Music/Main.ogg",
    "Inc/Music/Training_Loop1.ogg",
    "Inc/Music/Training_Loop2.ogg",
    "Inc/Music/Shopping_Loop1.ogg",
    "Inc/Music/Casino_Loop1.ogg",
    "Inc/Engine.ini",
]


# Modules the module body itself needs, which no recovered Type method or module
# Function happens to reference (so imports_needed() cannot discover them -- it works
# from Type names appearing in the emitted text, and these are plain Functions).
#
# Cross-check: the original's module-init chain (+362..+432, 15 calls 5 bytes apart)
# says the ORIGINAL had exactly 15 direct Imports, 7 of them identified by name --
# blitz, ramstream, retro, freeaudioaudio, freejoy, openalaudio, freetypefont. Every one
# of those either appears below or is already in the generated header. That is the
# program stating its own import list, and it agrees with what the tail needs to compile.
MODBODY_IMPORTS = [
    "BRL.Retro",          # Lower, Trim, Right, Replace
    "BRL.FileSystem",     # CreateDir, CurrentDir
    "BRL.Random",         # SeedRnd
    "BRL.GLMax2D",        # GLMax2DDriver()
    "BRL.D3D9Max2D",      # D3D9Max2DDriver()
    "BRL.D3D7Max2D",      # D3D7Max2DDriver()
    "PUB.FreeJoy",        # JoyCount()
    "BRL.OpenALAudio",    # SetAudioDriver("OpenAL")
    "BRL.FreeAudioAudio",  # SetAudioDriver("FreeAudio") fallback
    "BRL.PNGLoader",      # every GameMedia image is a .png
    "BRL.OggLoader",      # every sound and all six music tracks are .ogg
    "BRL.FreeTypeFont",   # the two Incbin'd TTFs
]

# Modules the ORIGINAL did not import, that this reconstruction does. Kept separate from
# MODBODY_IMPORTS so that list stays a faithful record of the original's own 15.
#
# PUB.ZLib: the original reached zlib through minizip, which is C linked into NSS5.exe and
# cannot be reconstructed as BlitzMax (see src/behaviour/ZipReader.OpenZip.bmx). A genuine
# retail save is a ZipCrypto-encrypted, DEFLATED zip entry -- measured:
#     flag=0x0001 method=8 csize=985503 usize=8439894
# so without an inflate the reconstruction can write and read its own saves and still not
# open a single save a player already owns. src/behaviour/ZipReader.ExtractFile.bmx uses
# this module's uncompress(); ZipCrypto itself is BlitzMax in that same file.
RECON_IMPORTS = [
    "PUB.ZLib",
]


def copy_incbin_tree():
    """Mirror extracted/incbin/Inc into the generated-source directory.

    `Incbin "Inc/Player.png"` is resolved by bmk RELATIVE TO THE SOURCE FILE, and the
    literal string doubles as the runtime resource name, so the tree has to be reachable
    as `Inc/...` from src/assembled/ and cannot simply be pointed at with a ../.. path
    (that would change the registered name to "../../extracted/incbin/Inc/Player.png"
    and every `incbin::Inc/...` lookup in the game would miss).

    Copies only when size differs, so repeat runs do not rewrite 6.4 MB.
    """
    import shutil
    n = 0
    for rel in INCBIN_ORDER:
        src = os.path.join(INCBIN_SRC, rel.replace("/", os.sep))
        dst = os.path.join(OUT_DIR, rel.replace("/", os.sep))
        if not os.path.exists(src):
            raise SystemExit("missing incbin asset: %s\n"
                             "  regenerate with: python scripts/extract_incbin.py" % src)
        if os.path.exists(dst) and os.path.getsize(dst) == os.path.getsize(src):
            continue
        os.makedirs(os.path.dirname(dst), exist_ok=True)
        shutil.copy2(src, dst)
        n += 1
    return n


GLOBAL_ALIAS_MAP = os.path.join(ROOT, "extracted", "global_alias_map.tsv")
# Generated by scripts/unify_names.py + scripts/emit_unified_aliases.py. Unlike the prose
# map above, every row is grounded in NSS5.exe: each body's Global uses are aligned against
# the original function's machine code, so the pairing is read off the shipped binary
# rather than off a header comment. Applied between the prose map and the hand overrides.
GLOBAL_ALIAS_UNIFIED = os.path.join(ROOT, "extracted", "global_alias_unified.tsv")
# Merges adjudicated one at a time against the original function's machine code, then
# checked by scripts/validate_verdicts.py for co-occurrence, type compatibility and
# address membership. Applied after the generated table because each row was decided
# individually, and before the hand overrides, which still win.
GLOBAL_ALIAS_ADJUDICATED = os.path.join(ROOT, "extracted",
                                        "global_alias_adjudicated.tsv")
# Dead Globals linked to the name their WRITER uses for the same slot, established by
# aligning assignment targets against the original's store targets
# (scripts/link_dead_to_writers.py). This is what revives a Global whose reader and writer
# were recovered under different names -- the reader is dead until they are unified.
GLOBAL_ALIAS_WRITERS = os.path.join(ROOT, "extracted", "global_alias_writers.tsv")
# Hand-verified merges, applied on top of (and overriding) the generated map -- including
# the groups build_alias_map.py refused. See that file's header for the evidence per row.
GLOBAL_ALIAS_OVERRIDES = os.path.join(ROOT, "extracted", "global_alias_overrides.tsv")


def global_alias_map():
    """-> {alias lower: canonical lower} for Globals where ONE ADDRESS ended up with
    SEVERAL NAMES across the corpus.

    Regenerate with `python scripts/build_alias_map.py`; find the raw problem with
    `python scripts/find_live_splits.py`.

    Every body is verified ALONE, in a probe that declares exactly one Global per
    '!Global pragma -- so the NAME a pass chooses is never load-bearing and two passes can
    name 0x00C5D224 `g_opt_music` and `g_musicvol` with both bodies MATCHing. This file
    emits one Global per distinct name, so those become two independent variables and a
    write through one is invisible through the other. Nothing crashes: release builds
    return 0 for a null-deref instead of faulting (blitzmax-language-guide 18.26), so the
    program silently does less than it should.

    Three cases confirmed by hand:
      * 0x00C5D224 g_opt_music / g_musicvol -- TOptions.LoadOptions reads "music=100" from
        Options.ini into one; PlayTrack tests the other, finds 0, and stops every track.
        That is the "no music" symptom, exactly.
      * 0x00C61740/44 g_screen_float03/04 vs g_screen_mousex/mousey -- TScreen.GetInput
        writes the scaled mouse position every frame, and reading the other name draws the
        cursor at (0,0) forever. TScreen.DrawMouse.bmx spells the name that matches at
        source, the evidence there being unambiguous.
      * g_inpname TGadget/TInputBox -- this file ALREADY reports that one, because those
        two bodies disagree about the TYPE. It cannot see the others: they agree perfectly
        about type and disagree only about the name, and a name disagreement is invisible
        to every check that works on names.

    The map is deliberately conservative. build_alias_map.py refuses a merge when the name
    is claimed by more than one address, or when two names for one address declare
    different types -- 61 rows were refused on those grounds, and they remain real splits
    in the build (extracted/global_alias_map_skipped.tsv). A wrong merge is worse than the
    split it fixes: a split makes one variable two and loses writes; a merge makes two
    variables one and corrupts both.
    """
    out, rank = {}, {}
    for prec, path in enumerate((GLOBAL_ALIAS_MAP, GLOBAL_ALIAS_UNIFIED,
                                 GLOBAL_ALIAS_WRITERS, GLOBAL_ALIAS_ADJUDICATED,
                                 GLOBAL_ALIAS_OVERRIDES)):
        if not os.path.exists(path):
            continue
        with open(path, encoding="utf-8") as f:
            hdr_seen = False
            for line in f:
                if line.startswith("#"):
                    continue
                p = line.rstrip("\n").split("\t")
                if not hdr_seen:
                    hdr_seen = True
                    if p and p[0].strip().lower() == "address":
                        continue
                if len(p) >= 3 and p[1].strip() and p[2].strip():
                    a, c = p[1].strip().lower(), p[2].strip().lower()
                    out[a] = c
                    rank[a] = prec
                    rank.setdefault("=" + c, prec)
                    if prec > rank.get("=" + c, -1):
                        rank["=" + c] = prec

    # A name that a HIGHER-precedence table calls canonical must not stay an alias in a
    # lower-precedence one. Without this the three tables can point at each other: the
    # prose map says g_np_cmbnation -> g_np_combonation while the hand-verified override
    # says g_np_combonation -> g_np_cmbnation, citing the line where CreateScreen builds
    # cmb_Nation. Both edges survive, the collapse loop below terminates on its `seen` set,
    # and the build succeeds with the winner decided by dict iteration order. Eight pairs
    # sit in that state -- six New Player combos, g_opt_radar, and the Options back-button
    # slot -- and NSS5.exe confirms every one of them is a single slot, so the merge itself
    # is right and only the direction is in doubt.
    for a in list(out):
        keep = rank.get("=" + a, -1)
        if keep > rank.get(a, -1):
            del out[a]

    # An override may name a canonical that is itself an alias in another table; collapse
    # chains so every alias lands on a final name in one pass.
    for k in list(out):
        seen = {k}
        v = out[k]
        while v in out and v not in seen:
            seen.add(v)
            v = out[v]
        out[k] = v
    return {k: v for k, v in out.items() if k != v}


def apply_alias_map(text, alias):
    """Rewrite every aliased Global reference in generated source to its canonical name.

    Applied to the GENERATED text only. src/recovered/ is never touched -- docs/RULES.md 5.3
    forbids a corpus-wide rewrite of that tree, and doing one here would also break every
    byte-verified body it edited and fill reverify.py with ~230 false regressions, which
    destroys the regression suite's signal precisely when it is most needed.

    Word-boundary, case-insensitive: BlitzMax identifiers are case-insensitive, and
    different passes use different casing for the same slot.
    """
    if not alias:
        return text, 0
    pat = re.compile(r"\b(%s)\b" % "|".join(sorted(map(re.escape, alias),
                                                   key=len, reverse=True)), re.I)
    n = [0]

    def sub(m):
        n[0] += 1
        return alias[m.group(1).lower()]
    return pat.sub(sub, text), n[0]


def modbody_globals():
    """-> {lower name: type} for module-scope Globals the tail assigns but no recovered
    body declares via a '!Global pragma.

    These are folded into the SAME gtypes map the pragma-derived Globals use, so they get
    the existing dedup and conflict reporting for free rather than a second, parallel
    emission path that could disagree with it.
    """
    out = {}
    if not os.path.exists(MODBODY_GLOBALS):
        return out
    with open(MODBODY_GLOBALS, encoding="utf-8") as f:
        hdr = None
        for line in f:
            p = line.rstrip("\n").split("\t")
            if hdr is None:
                hdr = p
                continue
            if len(p) >= 2 and p[0].strip():
                out[p[0].strip().lower()] = p[1].strip()
    return out

# The forms in which a BlitzMax source text can REFERENCE a Type. Used to decide which
# imported module a dropped Type still needs, so the Import list stays minimal and
# evidence-driven rather than "import everything that owns something".
_REF_FORMS = (r":\s*%s\b", r"\bNew\s+%s\b", r"\b%s\s*\.", r"\bExtends\s+%s\b",
              r"\b%s\s*\[", r"\b%s\s*\(")

# The member header, then everything up to the matching End.
#
# THE HEADER MAY SPAN LINES, so the pattern must absorb any run of continuation lines.
# BlitzMax continues a line with `..`, and TCombo.CreateCombo has a 13-parameter signature
# written across two:
#     Function CreateCombo:TCombo(a0:String, a1:String, a2:Int, a3:Int, a4:Int, a5:Int, ..
#             a6:Int, a7:Int, a8:String, a9:String, a10:Float, a11:Int(), a12:Int)
# A bare `.*?$` stops at the first end-of-line, which captures the second HALF OF THE
# SIGNATURE as the first statement of the body and emits it as code. That is a corrupted
# body, not a dropped one -- the assembler's own regenerated header is correct, so the
# leaked fragment lands after it as `a6:Int, ... a12:Int)` and bcc reports
#     Compile Error: Expecting expression but encountered ')'
# One file in the corpus wraps its signature today, and nothing stops the next hand-written
# one from wrapping.
BODY_RX = re.compile(
    r"^[ \t]*(Method|Function)\s+(\w+)\s*[:(]"
    r"(?:[^\n]*\.\.[ \t]*\r?\n)*[^\n]*$"
    r"(.*?)^[ \t]*End\s+(?:Method|Function)",
    re.M | re.S)


NOT_SELF_CONTAINED = []

GREF_RX = re.compile(r"\b(g_\w+)\b")

# A prose declaration, anywhere in a comment, in any of the phrasings the corpus actually
# uses. Measured against all 1,139 files -- these are the forms passes wrote, not guesses:
#     '   Global g_achievement_int:Int
#     ' globals: g_ball_float01/02/03:Float (0x00C5A4CC/D0/D4), g_player_int33:Int
#     ' module Global at 0x00c65034 declared as g_curnat:TNation
#     ' ASSUMPTION: module Global 'g_stat_int:Int' at 0x00C6A8A4
#     '   g_ball_minspeed:Float @ 0x00C7264C
#     ' Globals: 0x00C6C168 g_snd_card:TSound, 0x00C6F090 g_chan:TChannel.
# Every pair on a line has to be read, and the scan has to run even when the file already
# has a pragma: a file mixing one pragma with three prose Globals would otherwise recover
# nothing.
PROSE_RX = re.compile(r"\b(g_\w+)\s*:\s*([A-Za-z_]\w*)\s*(\[\s*\])?")

# Slash-lists share one type across several names, and the corpus uses two spellings:
#     g_ch1/g_ch2/g_ch3:TChannel          full names
#     g_ball_float01/02/03:Float          the tail entries are bare SUFFIXES
# Neither leaves `name:Type` adjacent for any name but the last, so PROSE_RX sees only one.
PROSE_SLASH_RX = re.compile(
    r"\b(g_\w+(?:/\w+)+)\s*:\s*([A-Za-z_]\w*)\s*(\[\s*\])?")


# ADDRESS-KEYED prose. Several files record the type against the Global's ADDRESS and
# never next to its name, so no name:Type regex can reach them:
#     '   Global 0x00C625F0 is an INT, not a Float: the original loads it with
#     '   Globals 0x00C7E260 / 0x00C7E264 are Floats (x87 dword access).
#     '   0x00C6C17C : Int    -- the "a hand is in play" flag
# This is MEASURED evidence from a byte-verified file -- TTable.AddColumn proves Int by
# the `fild` widening and says a Float comes out 7 bytes short -- so it outranks any
# structural inference. It is only safe where the association is unambiguous, so it is
# applied only when the file has exactly ONE unresolved Global and every address-keyed
# type mentioned in that file agrees.
ADDR_TYPE_RX = re.compile(
    r"0x[0-9A-Fa-f]{6,8}[^\n]{0,60}?(?:\bis\b|\bare\b|:)\s*an?\s*"
    r"([A-Za-z_]\w*)s?\b|0x[0-9A-Fa-f]{6,8}\s*:\s*([A-Za-z_]\w*)")

_CANON = {"int": "Int", "ints": "Int", "float": "Float", "floats": "Float",
          "string": "String", "strings": "String", "object": "Object"}


def addr_prose_type(comments):
    """-> the single type this file records against addresses, or None."""
    found = set()
    for m in ADDR_TYPE_RX.finditer(comments):
        w = (m.group(1) or m.group(2) or "").strip()
        if not w:
            continue
        c = _CANON.get(w.lower())
        if c is None and w[:1] == "T" and w[1:2].isupper():
            c = w                                  # a Type name, e.g. TImage
        if c:
            found.add(c)
    return sorted(found)[0] if len(found) == 1 else None


def prose_decls(comments):
    """-> {lower name: BlitzMax type} for every declaration spelled in a comment."""
    out = {}
    for m in PROSE_SLASH_RX.finditer(comments):
        ty = m.group(2) + ("[]" if m.group(3) else "")
        parts = m.group(1).split("/")
        stem = parts[0]
        for p in parts:
            if p.startswith("g_"):
                out.setdefault(p.lower(), ty)
            else:
                # bare suffix: g_ball_float01/02/03 -> replace the stem's trailing run
                base = re.sub(r"\w{%d}$" % len(p), "", stem)
                out.setdefault((base + p).lower(), ty)
    for m in PROSE_RX.finditer(comments):
        out.setdefault(m.group(1).lower(),
                       m.group(2) + ("[]" if m.group(3) else ""))
    return out


def split_top_level(s):
    """Split a parameter list on commas that are not inside parens or brackets."""
    out, depth, cur = [], 0, ""
    for ch in s:
        if ch in "([":
            depth += 1
        elif ch in ")]":
            depth -= 1
        if ch == "," and depth == 0:
            out.append(cur)
            cur = ""
        else:
            cur += ch
    if cur.strip():
        out.append(cur)
    return out


STRLIT_RX = re.compile(r'"[^"\n]*"')


def positional_rename(header, body):
    """Rename the file's own parameter names to the a0/a1/... the emitted header uses.

    emit_type() regenerates every signature from object_model.json
    and always names the parameters `a0:Type, a1:Type, ...` (harness.py:386). A recovered
    file that declares its own names -- TPitch.PixelsToYards is
    `Function PixelsToYards:Float(p:Float)` with `Return p / 10.0` -- is perfectly
    self-consistent on disk, but assembly keeps the BODY and throws the HEADER away, so
    without this rename the body refers to a parameter that does not exist in the emitted
    signature:
        Compile Error: Identifier 'p' not found
    That is an assembler defect, not a bad body, and the file must not be edited to work
    around it. Names have no effect on codegen, so rewriting them to the positional
    convention is semantics-preserving. String literals are masked first so a parameter
    called `p` cannot corrupt the contents of a string.
    """
    o = header.find("(")
    if o < 0:
        return body, []
    depth, j = 0, o
    while j < len(header):
        if header[j] == "(":
            depth += 1
        elif header[j] == ")":
            depth -= 1
            if depth == 0:
                break
        j += 1
    renames = []
    for i, part in enumerate(split_top_level(header[o + 1:j])):
        nm = re.match(r"\s*([A-Za-z_]\w*)", part)
        if nm and nm.group(1).lower() != "a%d" % i:
            renames.append((nm.group(1), "a%d" % i))
    if not renames:
        return body, []
    lits = []

    def stash(m):
        lits.append(m.group(0))
        return "\x00%d\x00" % (len(lits) - 1)

    masked = STRLIT_RX.sub(stash, body)
    done = []
    for old, new in renames:
        masked, n = re.subn(r"\b%s\b" % re.escape(old), new, masked)
        if n:
            done.append("%s->%s" % (old, new))
    masked = re.sub(r"\x00(\d+)\x00", lambda m: lits[int(m.group(1))], masked)
    return masked, done


PARAM_RENAMED = []


def _recovered_files():
    """[(dirpath, filename)] over EVERY tree that holds verified bodies.

    src/recovered_thirdparty/<module>/ must be walked too. Those bodies are verified and on
    disk, and listing only src/recovered leaves the assembler emitting EMPTY STUBS for their
    Types, which the composition check then flags as diverged -- "LENGTH 51 vs 14" for
    TDrawTextException.ToString, SZipFileEntry.Less and others, 89 verified functions'
    worth.

    They still must not be declared in the MAIN module -- a Type declared there enters the
    module body's Type-registration sequence, so folding these in would corrupt the recorded
    declaration order that the `data` class tables follow from. And they are not:
    assemble.py already routes Types no installed module declares into the separate external
    compilation unit. This only fills in their BODIES; it does not change where the Type is
    declared.
    """
    out = []
    for fn in sorted(os.listdir(RECOVERED)):
        out.append((RECOVERED, fn))
    tp = os.path.join(ROOT, "src", "recovered_thirdparty")
    if os.path.isdir(tp):
        for sub in sorted(os.listdir(tp)):
            d = os.path.join(tp, sub)
            if os.path.isdir(d):
                for fn in sorted(os.listdir(d)):
                    out.append((d, fn))

    # src/recovered_unverified/ -- NEAR-MISS bodies. Real, complete reconstructions that do
    # not (yet) byte-match. Listed after the verified trees so a verified body always wins.
    #
    # Leaving them out costs far more than it looks. 45 of the 52 files here contain real
    # code; only 7 are genuinely unwritten research notes. Each of the other 45 would be
    # emitted as an empty 14-byte stub. TLabel.CreateLabel is the example that settles it:
    # 800 bytes, +3 over the original, with the entire delta traced to one
    # register-allocation tie -- and absent from the build, CreateLabel returns Null, so
    # THelpBox.Create dereferences Null and no screen in the game can be built. A body that
    # is three bytes off is not "unfinished"; it is finished and unproven.
    #
    # Worth knowing when reading behaviour off this build: these bodies are adjudicated for
    # functional equivalence against the byte oracle, with the full per-body record in
    # docs/archive/analysis/nearmiss-verdict.md. Most match or are judged equivalent. Three
    # do not yet byte-match under a fresh oracle run and remain open: TGadget.RenderHighlight
    # (728 of 748 bytes), TProfile.CheckAchievement (623 of 625 bytes), TScreenMessage.Draw
    # (1115 of 1119 bytes). Preserve-by-default does not protect them until they close.
    #
    # A file here that is 100% comments contributes nothing and stays an empty stub --
    # load_recovered() finds no statements and skips it.
    if os.path.isdir(UNVERIFIED):
        for fn in sorted(os.listdir(UNVERIFIED)):
            if fn in UNVERIFIED_SKIP:
                continue
            out.append((UNVERIFIED, fn))

    # src/placeholder/ -- DELIBERATELY NOT BYTE-EXACT bodies, listed LAST so a real
    # recovered body always wins if one ever appears for the same (Type, Method).
    #
    # These exist because an unrecovered function is emitted as an empty 14-byte stub, and
    # an empty stub that should return an object returns Null instead. That is fine for a
    # consistency build and fatal for a running program: TKit.GetPaintedFan is never-opened,
    # so TPitch.SetUp gets Null crowd pixmaps and the boot dies inside MidHandleImage.
    # A placeholder that returns something structurally valid lets the boot continue and
    # reach the next real problem, which is the whole point of keeping this tree.
    #
    # They must never live in src/recovered/ (that tree means "byte-verified", and
    # reverify.py would correctly report them as broken) and must never be mistaken for
    # recovered work: every file here states in its header what it fakes and what the real
    # body is supposed to do. Deleting the file restores the empty-stub behaviour exactly.
    # src/behaviour/ -- bodies written from OBSERVED GAME BEHAVIOUR rather than from the
    # binary. They are meant to be functionally right and are NOT claimed to be byte-exact,
    # so they carry no `VA ... N bytes` header and no `byte-identical vs NSS5.exe` marker,
    # and progress.py does not scan this tree. Ranked above placeholder, because a body that
    # implements the real behaviour beats one that only keeps the boot alive, and below every
    # recovered tree, because a body derived from the binary always wins.
    if os.path.isdir(BEHAVIOUR):
        for fn in sorted(os.listdir(BEHAVIOUR)):
            out.append((BEHAVIOUR, fn))

    if os.path.isdir(PLACEHOLDER):
        for fn in sorted(os.listdir(PLACEHOLDER)):
            out.append((PLACEHOLDER, fn))
    return out


def load_recovered():
    """(Type, Method) -> (body, pragma globals, comment text, filename)"""
    out, dupes = {}, []
    for _dir, fn in _recovered_files():
        if not fn.endswith(".bmx"):
            continue
        base = fn[:-4]
        if "." not in base:
            continue
        tname, mname = base.split(".", 1)
        text = open(os.path.join(_dir, fn), encoding="utf-8", errors="replace").read()
        text, gdecls = H.split_globals(text)
        comments = "\n".join(l for l in text.split("\n") if l.lstrip().startswith("'"))

        # TWO ON-DISK FORMATS, and both must be read.
        #
        # Most files wrap the statements in `Function Foo:Int() ... End Function`. 126 of
        # them are in the harness's BODY-ONLY format instead -- statements alone, no
        # wrapper, exactly what emit_type() and build_source() take. BODY_RX cannot match
        # those, so skipping a non-match drops the body AND the file's '!Global pragmas
        # with it. Silently, too: the "bodies found" counter counts only what survives, so
        # those 126 verified bodies would be absent from the assembly while Globals they
        # legitimately declare (g_screen_cursor:TImage in TScreen.SetUp.bmx,
        # g_snow_alpha:Float in TSnowFlake.UpdateAll.bmx) read as undeclared.
        m = BODY_RX.search(text)
        if m:
            raw = m.group(3)
        else:
            raw = text
        body = "\n".join(l for l in raw.split("\n")
                         if not l.lstrip().startswith("'"))
        if m:
            header = m.group(0)[:m.start(3) - m.start(0)]
            body, ren = positional_rename(header, body)
            if ren:
                PARAM_RENAMED.append((fn, ren))
        if not body.strip() and not m:
            # Nothing but comments and pragmas. Keep the pragmas -- they are still a
            # declaration -- but the empty body is a legitimate compiler-generated member
            # (a body that really is empty, confirmed at scale), so record it as such.
            body = ""
        if (tname, mname) in out:
            dupes.append((tname, mname))
        # TIER PRECEDENCE. This dict is last-wins and _recovered_files() emits the trees in
        # descending order of trust: verified -> verified third-party -> near-miss ->
        # placeholder. Without this guard a lower tier would silently displace a higher one,
        # which is the worst available failure mode: the build looks fine and quietly runs
        # unverified or fake code in place of a byte-exact body.
        #
        # ...BUT A HIGHER TIER ONLY OUTRANKS A LOWER ONE WHEN IT ACTUALLY HAS A BODY.
        # The note two paragraphs up already states the intended rule -- "A file here that
        # is 100% comments contributes nothing and stays an empty stub" -- and until this
        # guard was qualified the code did the opposite: a research note was inserted with
        # body "" and then BLOCKED every lower tier, so the pair emitted an empty stub that
        # nothing could fill. Measured across the whole corpus, exactly two pairs are
        # affected, both of them 100%-comment files in src/recovered_unverified/ that exist
        # to record why the original cannot be reconstructed at all:
        #     TZipEStream.find_file.bmx  -- "THIS FILE IS DELIBERATELY 100% COMMENTS"
        #     TZipEStream.Eof.bmx        -- same, and it documents Pos and Read too
        # Both are minizip C entry points with no BlitzMax equivalent, so no reconstruction
        # will ever land there; meanwhile they were silently vetoing the src/behaviour/
        # bodies that make the zip layer -- and therefore the whole save/load feature --
        # work. Those two notes are worth keeping, so the guard is corrected instead.
        # The incumbent's prose is carried forward, because the prose-declaration scanner
        # reads Global types out of it and an empty body is no reason to lose that.
        if _dir in (UNVERIFIED, BEHAVIOUR, PLACEHOLDER) and (tname, mname) in out:
            if out[(tname, mname)][0].strip():
                continue
            comments = "\n".join(c for c in (out[(tname, mname)][2], comments) if c)
        out[(tname, mname)] = (body.rstrip(), gdecls, comments, fn)
    return out, dupes


# ------------------------------------------------------------------ usage inference
# Last resort, and ONLY for a Global no file declares in a pragma and no comment spells
# `name:Type` for. Those files record the type against the ADDRESS instead of the name
# ("0x00C6C17C : Int -- the hand-in-play flag"), so the name-to-type association exists
# only in the author's head and no regex can recover it.
#
# Every rule below reads evidence out of the BODY, which is byte-verified, so the
# inference is grounded in code rather than in prose. It is still an inference: each one
# is reported by name so a real '!Global pragma can replace it.

# The BRL builtins whose parameter types are load-bearing here. Small on purpose: each
# entry is a signature from the BlitzMax module docs, not a guess about NSS5.
BRL_PARAMS = {
    "drawimage":     ["TImage", "Float", "Float", "Int"],
    "drawimagerect": ["TImage", "Float", "Float", "Float", "Float", "Int"],
    "drawimagearea": ["TImage", "Float", "Float", "Int", "Int", "Int", "Int", "Int"],
    "setimagehandle": ["TImage", "Float", "Float"],
    "midhandleimage": ["TImage"],
    "setalpha":      ["Float"],
    "setscale":      ["Float", "Float"],
    "setrotation":   ["Float"],
    "playsound":     ["TSound"],
    "cuesound":      ["TSound"],
    "setchannelvolume": ["TChannel", "Float"],
    "stopchannel":   ["TChannel"],
    "resumechannel": ["TChannel"],
    "pausechannel":  ["TChannel"],
    "channelplaying": ["TChannel"],
}


def _model_index(d):
    """-> (param types by callee name, field types by field name, method owners)."""
    params, fields, owners = {}, collections.defaultdict(set), collections.defaultdict(set)
    for tname, ms in d["methods"].items():
        for m in ms:
            try:
                args, _ret = H.parse_sig(m["sig"])
            except Exception:
                continue
            params.setdefault(m["name"].lower(), args)
            owners[m["name"].lower()].add(tname)
    for tname, fs in d["fields"].items():
        for f in fs:
            fields[f["name"].lower()].add(H.field_type(f["sig"]))
    return params, fields, owners


def _owner_type(name, owners, d):
    """The Type to declare a Global on, given a method it is called through.

    If several Types declare the method, walk each candidate's Extends chain and keep the
    highest ancestor that still declares it -- `.Show()` is TGadget's, inherited by TPanel
    and TButton, so the answer is TGadget rather than an arbitrary subclass.
    """
    cands = owners.get(name.lower())
    if not cands:
        return None
    roots = set()
    for c in cands:
        cur, best = c, c
        seen = set()
        while cur and cur not in seen:
            seen.add(cur)
            if any(m["name"].lower() == name.lower() for m in d["methods"].get(cur, [])):
                best = cur
            cur = d["supers"].get(cur)
            if cur in ("Object", None) or cur not in d["supers"]:
                break
        roots.add(best)
    return sorted(roots)[0] if len(roots) == 1 else None


INFER_RULES = [
    # (regex over the body with %s = the global, inferred type, why)
    (r"EachIn\s+%s\b", "TList", "iterated with For EachIn"),
    (r"\bDrawImage(?:Rect|Area)?\s*\(\s*%s\b", "TImage", "passed to DrawImage*"),
    (r"\b(?:PlaySound|CueSound)\s*\(\s*%s\b", "TSound", "passed to PlaySound/CueSound"),
    (r"%s\s*=\s*(?:PlaySound|CueSound)\b", "TChannel", "assigned from PlaySound/CueSound"),
    (r"\b(?:StopChannel|SetChannelVolume|ChannelPlaying|ResumeChannel|PauseChannel)"
     r"\s*\(\s*%s\b", "TChannel", "passed to a channel call"),
    (r"%s\s*=\s*(?:Lower|Upper|Trim|GetText|String)\s*\(", "String", "assigned a String expr"),
    (r'%s\s*=\s*"', "String", "assigned a String literal"),
    (r"%s\s*=\s*New\s+(T\w+)", None, "assigned New <Type>"),
    (r"%s\s*=\s*(T\w+)\.Create\b", None, "assigned <Type>.Create"),
    (r"Local\s+\w+\s*:\s*([A-Za-z_]\w*(?:\[\])?)\s*=\s*%s\s*$", None,
     "assigned into a typed Local"),
    (r"%s\s*(?:=|<>|>|<|>=|<=|:\+|:-)\s*-?\d+\.\d", "Float", "compared/assigned a Float literal"),
    (r"%s\s*(?:=|<>|>|<|>=|<=|:\+|:-)\s*-?\d+\b", "Int", "compared/assigned an Int literal"),
]

# `Select g` whose Cases are integer literals. The subject's type is what the Case
# comparisons are against, and bcc compares a Select subject once against each Case.
SELECT_RX = re.compile(r"Select\s+%s\s*$(.*?)^\s*End\s+Select", re.M | re.S | re.I)


def infer_type(name, bodies, params, fields, owners, d):
    """-> (type, reason) or (None, None). `bodies` is every body that references it."""
    blob = "\n".join(bodies)
    esc = re.escape(name)

    # -- Select subject: the Case literals ARE the subject's type
    sm = re.search(r"Select\s+%s\s*$(.*?)^\s*End\s+Select" % esc, blob, re.M | re.S | re.I)
    if sm:
        if re.search(r'^\s*Case\s+"', sm.group(1), re.M | re.I):
            return "String", "Select subject, String Cases"
        if re.search(r"^\s*Case\s+-?\d+", sm.group(1), re.M | re.I):
            return "Int", "Select subject, Int Cases"

    # -- called as a method through the Global: the declaring Type is the type
    mm = re.search(r"%s\s*\.\s*(\w+)\s*\(" % esc, blob, re.I)
    if mm:
        owner = _owner_type(mm.group(1), owners, d)
        if owner:
            return owner, "calls .%s() -> %s declares it" % (mm.group(1), owner)
        # Ambiguous: several Types declare it. The DOWNCASTS in the same body narrow it --
        # `TInputBox(g_focus)` and `TTable(g_focus)` both appear, so the Global's static
        # type is their common ancestor, and it is the right answer only if that ancestor
        # declares the method being called.
        casts = {c for c in re.findall(r"\b(T\w+)\s*\(\s*%s\s*\)" % esc, blob)
                 if c in d["supers"]}
        if casts:
            chains = []
            for c in casts:
                chain, cur, seen = [], c, set()
                while cur and cur in d["supers"] and cur not in seen:
                    seen.add(cur)
                    chain.append(cur)
                    cur = d["supers"].get(cur)
                chains.append(chain)
            common = [t for t in chains[0] if all(t in ch for ch in chains[1:])]
            for anc in common:
                if any(m["name"].lower() == mm.group(1).lower()
                       for m in d["methods"].get(anc, [])):
                    return anc, "downcast to %s; .%s() on common ancestor" % (
                        "/".join(sorted(casts)), mm.group(1))

    # -- passed as an argument to a call whose parameter types we know
    for cm in re.finditer(r"\b(\w+)\s*(?:\.\s*(\w+)\s*)?\(([^()]*)\)", blob):
        callee = (cm.group(2) or cm.group(1)).lower()
        sig = params.get(callee) or BRL_PARAMS.get(callee)
        if not sig:
            continue
        for i, arg in enumerate(cm.group(3).split(",")):
            if re.fullmatch(r"\s*%s\s*" % esc, arg, re.I) and i < len(sig):
                return sig[i], "argument %d of %s()" % (i, callee)
    # statement-form calls have no parens: `DrawImage g_img, x, y, 0`
    for cm in re.finditer(r"^\s*(\w+)\s+([^\n]+)$", blob, re.M):
        sig = BRL_PARAMS.get(cm.group(1).lower())
        if not sig:
            continue
        for i, arg in enumerate(cm.group(2).split(",")):
            if re.fullmatch(r"\s*%s\s*" % esc, arg, re.I) and i < len(sig):
                return sig[i], "argument %d of %s" % (i, cm.group(1))

    # -- arithmetic against a Field whose type the object model knows
    fm = re.search(r"\.\s*(\w+)\s*(?:[-+*/]|:\+|:-)\s*%s\b" % esc, blob) or \
        re.search(r"%s\s*(?:[-+*/])\s*\w*\.\s*(\w+)\b" % esc, blob)
    if fm:
        cand = fields.get(fm.group(1).lower())
        if cand and len(cand) == 1:
            return sorted(cand)[0], "arithmetic with field .%s" % fm.group(1)

    # -- inside a Float(...) conversion
    if re.search(r"Float\s*\([^()]*\)\s*[*/+-]\s*%s\b" % esc, blob) or \
       re.search(r"%s\s*[*/+-]\s*Float\s*\(" % esc, blob):
        return "Float", "operand of a Float() expression"

    # -- integer-only operators. Mod/Shl/Shr/Sar/~ do not apply to an object, so this
    # settles Int outright: g_engine_replaytimer was inferred Object by the Null-test
    # fallback below and then failed the build on `g Mod 2000` -- "Types 'Object' and
    # 'Int' are unrelated".
    if re.search(r"%s\s*(?:Mod|Shl|Shr|Sar)\b" % esc, blob, re.I) or \
       re.search(r"\b(?:Mod|Shl|Shr|Sar)\s*%s\b" % esc, blob, re.I):
        return "Int", "operand of Mod/Shl/Shr/Sar"

    for pat, ty, why in INFER_RULES:
        m = re.search(pat % esc, blob, re.I | re.M)
        if m:
            if ty is None:                       # type captured from the source text
                return m.group(1), why
            return ty, why

    # -- plain arithmetic against an integer literal
    if re.search(r"%s\s*[-+*/]\s*-?\d+\b(?!\.)" % esc, blob) or \
       re.search(r"(?<![\w.])-?\d+\s*[-+*/]\s*%s\b" % esc, blob):
        return "Int", "arithmetic with an Int literal"

    # Only ever tested against Null -> it is a reference, and Object is the weakest claim
    # that still compiles. Anything calling a method through it will fail the build loudly,
    # which is the correct outcome: that is a real unknown, not something to paper over.
    # The test must be the WHOLE condition: `If g Mod 2000 < 1000` is not a Null test, and
    # matching it as one is what produced the Object/Int failure above.
    if re.search(r"%s\s*(?:=|<>)\s*Null" % esc, blob, re.I) or \
       re.search(r"\bIf\s+(?:Not\s+)?%s\s*(?:Then\b|$)" % esc, blob, re.I | re.M):
        return "Object", "only Null-tested"
    return None, None


_MODSUPPLY = {}


def module_supplied_types():
    """-> {lower Type name: {module namespace, ...}} for every Type an INSTALLED module
    declares, read off tools/blitzmax-legacy-src/mod.

    This is the other half of the 135-Types-not-341 rule below. Emitting only the game's 135
    Types in the MAIN module keeps the registration sequence clean, but that alone merely
    moves the other 201 into a second compilation unit -- and 166 of them are Types
    an imported module already declares. A second declaration of `TBank` is still a second
    TBank: the program links ours, whose methods are 14-byte empty stubs, instead of
    brl.bank's real ones. Measured without this filter: of 1,039 non-game Type methods
    present in both images, 397 are empty stubs on our side.

    The namespace is read off the DIRECTORY, never guessed -- brl.mod/maxlua.mod is
    BRL.MaxLua and pub.mod/freejoy.mod is PUB.FreeJoy, and a wrong namespace makes bmk
    fail with an empty error message that reads like a broken toolchain.
    """
    if _MODSUPPLY:
        return _MODSUPPLY
    rx = re.compile(r"^\s*Type\s+([A-Za-z_]\w*)", re.I)
    for dp, _dn, fns in os.walk(MODTREE):
        rel = os.path.relpath(dp, MODTREE).replace("\\", "/").split("/")
        if len(rel) < 2 or not rel[0].endswith(".mod") or not rel[1].endswith(".mod"):
            continue
        ns = rel[0][:-4] + "." + rel[1][:-4]
        for f in fns:
            if not f.lower().endswith(".bmx"):
                continue
            try:
                txt = open(os.path.join(dp, f), encoding="latin-1",
                           errors="replace").read()
            except OSError:
                continue
            for line in txt.split("\n"):
                m = rx.match(line)
                if m:
                    _MODSUPPLY.setdefault(m.group(1).lower(), set()).add(ns)
    return _MODSUPPLY


def imports_needed(text, dropped, supply):
    """-> ([Import lines], {ns: [Types]}) for the dropped Types `text` still references.

    Import the module that OWNS the reference, not every module that owns something. A
    Type declared by two namespaces (e.g. a driver Type re-declared per backend) is
    ambiguous, so it is returned for the caller to report rather than resolved silently.
    """
    need, ambiguous = collections.defaultdict(list), []
    for t in dropped:
        pat = "|".join(f % re.escape(t) for f in _REF_FORMS)
        if not re.search(pat, text, re.I):
            continue
        ns = supply[t.lower()]
        if len(ns) > 1:
            ambiguous.append((t, sorted(ns)))
        for n in sorted(ns):
            need[n].append(t)
    return need, ambiguous


def type_order():
    order = []
    if os.path.exists(DECL_ORDER):
        with open(DECL_ORDER, encoding="utf-8", errors="replace") as f:
            next(f, None)
            for line in f:
                p = line.rstrip("\n").split("\t")
                if len(p) >= 4:
                    order.append(p[3])
    return order


def field_pragmas():
    """-> {Type: {lower field name: declaration suffix}} from every '!Field pragma.

    '!Field lines must be split out as well as '!Global ones. A '!Field line starts with a
    quote, so anything that only calls split_globals() strips it as an ordinary comment and
    throws its initialiser away, silently breaking the 13 bodies that depend on one.
    TTeam.New is the clearest case: 160 bytes that are ENTIRELY bcc's field-default
    prologue, matching only because `Field newstarselno:Int = -1` puts 0xFFFFFFFF at +0x3c.
    Without the pragma the assembled Type stores 0 there and the assembled body stops
    corresponding to the verified one. The build does not care, which is exactly why this
    has to be measured rather than waited for.

    Read in a separate pass so load_recovered()'s return shape is untouched.
    """
    out, conflicts = collections.defaultdict(dict), []
    # Same tree set as load_recovered(): a third-party Type's '!Field initialiser is exactly
    # as load-bearing as a game Type's, and scanning only src/recovered drops them.
    for _dir, fn in _recovered_files():
        if not fn.endswith(".bmx") or "." not in fn[:-4]:
            continue
        tname = fn[:-4].split(".", 1)[0]
        text = open(os.path.join(_dir, fn), encoding="utf-8", errors="replace").read()
        _t, fd = H.split_field_decls(text)
        for k, v in fd.items():
            if k in out[tname] and out[tname][k] != v:
                conflicts.append((tname, k, out[tname][k], v, fn))
            out[tname][k] = v
    return out, conflicts


def global_initialisers(recovered):
    """-> ({lower name: (initialiser text, evidence file)}, [conflicts]).

    A bare `'!Global g_x:Float` gives the assembled build's copy of
    the Global no starting value, so it silently defaults to 0 -- wrong for any Global whose
    ORIGINAL data-section value is non-zero (`g_pole_maxz` = 100.0, `g_ball_snowthreshold` =
    0.5, ... see check_floats.py's "zero-bucket"). The source-level fix is an initialiser on
    the pragma line itself (`'!Global g_pole_maxz:Float = 100.0`), parsed once by
    harness.parse_global_decl and carried here as a SEPARATE PASS, exactly the shape
    field_pragmas() uses for '!Field -- the type-conflict machinery below (`gtypes`) already
    has its own job (deciding WHICH type a name is); bolting a second, differently-shaped
    piece of data onto it would make that code harder to read for both purposes at once.

    A name with no initialiser anywhere never enters the returned dict, so gout emits the
    plain declaration for the ~2,900 Globals nobody has captured an initial value for yet.
    """
    out, conflicts = {}, []

    def consider(g, fn):
        parsed = H.parse_global_decl(g)
        if not parsed:
            return
        name, _ty, init = parsed
        if not init:
            return
        key = name.lower()
        if key in out and out[key][0] != init:
            conflicts.append((key, out[key][0], init, out[key][1], fn))
            return
        out.setdefault(key, (init, fn))

    for (_t, _m), (_b, gd, _c, fn) in recovered.items():
        for g in gd:
            consider(g, fn)
    for g in H._MODGLOBALS:                  # module Functions carry their own pragmas too
        consider(g, "<module function>")
    return out, conflicts


def parent_before_child(order, d):
    """Stable reorder so no Type is emitted before the Type it Extends.

    type_declaration_order.tsv records the ORIGINAL declaration order but covers only 135
    of the 336 Types; the remaining 201 are appended after it. That puts three children
    ahead of their parents (TMyBankStream at row 31 vs TBankStream at 280, and both
    Max2D drivers vs TMax2DDriver) -- an ordering the original program cannot have had.
    Hoist only the parents that need it and leave every other position alone, so the
    recorded order is preserved wherever it is actually known.
    """
    pos = {t: i for i, t in enumerate(order)}
    out, placed = [], set()

    def add(t, guard):
        if t in placed or t not in pos or t in guard:
            return                            # unknown super, or a cycle: leave as-is
        guard.add(t)
        add(d["supers"].get(t, "Object"), guard)
        guard.discard(t)
        placed.add(t)
        out.append(t)

    for t in order:
        add(t, set())
    return out


def count_placed(src):
    """Members that actually carry a body IN THE EMITTED TEXT.

    NEVER report a placement number taken from the input side. Counting what is fed to
    emit_type gives "1,131 bodies placed" for a file that contains 144 of them. Re-parse
    the output and make the two agree, so this class of defect cannot hide.
    """
    lines = src.split("\n")
    n = 0
    for i, l in enumerate(lines):
        if re.match(r"^\t(?:Method|Function)\s+\w+", l):
            if i + 1 < len(lines) and not re.match(r"^\tEnd\s+(?:Method|Function)",
                                                   lines[i + 1]):
                n += 1
    return n


def global_overrides():
    """-> {lower name: (type, evidence)} resolving '!Global type conflicts.

    globals_corrections.tsv is keyed by VA and cannot express "this NAME is TGadget, not
    Object", which is the form these four conflicts take. One `name<TAB>type<TAB>evidence`
    row each, resolved from the code, because the name table is wrong in both
    directions about object-vs-scalar and the refcount traffic is what settles it.
    """
    over = {}
    if not os.path.exists(GLOBAL_OVERRIDES):
        return over
    with open(GLOBAL_OVERRIDES, encoding="utf-8", errors="replace") as f:
        for line in f:
            if line.startswith("#") or not line.strip():
                continue
            p = line.rstrip("\n").split("\t")
            if len(p) >= 2 and p[0].strip().lower() != "name":
                over[p[0].strip().lower()] = (p[1].strip(),
                                              p[2].strip() if len(p) > 2 else "")
    return over


def module_global_array_sizes():
    """-> {lower name: (bmx_type, size, va)} for every module-scope Global whose exact
    array element type AND literal size were read directly out of NSS5.exe.

    `extracted/module_emission_order.tsv` lists 94 module-level Globals the ORIGINAL module
    body itself declares -- entirely separate from the ~2,900 Globals the block above
    collects from recovered Type-method/module-Function '!Global pragmas.
    64 of those 94 are plain array allocations (`Global g_x:T[N]`, no explicit initialiser
    -- bcc's own lazy-init guard supplies the rest, confirmed compiler-emitted against a
    standalone probe); `scripts/decode_module_globals.py` recovers each one's
    element TYPE and literal SIZE from the `_bbArrayNew1D(type, length)` call operands
    sitting a few bytes after the Global's own guard, and writes them to
    extracted/module_globals_decoded.tsv. That is ground truth from the binary, not a
    guess, and it is worth real bytes: a standalone test of the same data carried
    __bb_main from 2,190 to 5,195 of its 7,933 bytes in one step.

    The 30 remaining GLOBAL rows (kind=SCALAR_OR_COMPLEX) have a real initialiser
    expression instead of a bare allocation and are NOT returned here -- decoding those is
    its own task.
    """
    out = {}
    if not os.path.exists(MODULE_GLOBALS_DECODED):
        return out
    with open(MODULE_GLOBALS_DECODED, encoding="utf-8", errors="replace") as f:
        header = None
        for line in f:
            p = line.rstrip("\n").split("\t")
            if header is None:
                header = p
                continue
            row = dict(zip(header, p))
            if row.get("kind") != "ARRAY" or not row.get("bmx_type") or not row.get("size"):
                continue
            out[row["name"].strip().lower()] = (row["bmx_type"].strip(),
                                                 row["size"].strip(),
                                                 row.get("va", "").strip())
    return out


# ------------------------------------------------------- --check-selfcontained (the gate)
# A prose declaration of a NON-g_ Global, stated in a header comment as "Global <name>:<Type>".
# Nearly every module Global in the corpus is named g_*, which GREF_RX already finds; the one
# exception so far is a function-pointer Global (fReject), which is why an undeclared name
# spelled out this way in a comment is checked too.
NAMED_GLOBAL_RX = re.compile(r"\bGlobal\s+([A-Za-z_]\w*)\s*:\s*[A-Za-z_]")


def _file_defects(body, gdecls, comments):
    """-> the module Globals `body` references that its OWN pragmas do not declare."""
    have = set()
    for g in gdecls:
        m = re.match(r"Global\s+([A-Za-z_]\w*)", g.strip())
        if m:
            have.add(m.group(1).lower())
    miss = set(GREF_RX.findall(body))
    for m in NAMED_GLOBAL_RX.finditer(comments):
        if re.search(r"\b%s\b" % re.escape(m.group(1)), body):
            miss.add(m.group(1))
    return sorted(n for n in miss if n.lower() not in have)


def selfcontained_defects(recovered):
    """-> [(file, [undeclared names])] over src/recovered and src/recovered_module.

    WHY THIS IS NOT `NOT_SELF_CONTAINED`, AND WHY THAT LIST CANNOT BE THE GATE. The PROSE
    and INFERENCE tiers in main() build that list from names undeclared ACROSS THE WHOLE
    CORPUS (`set(refs) - pragma_declared`). The two measures do not contain one another in
    either direction:

      * a file that references g_matchtime and declares nothing is INVISIBLE to the tiers
        the moment any OTHER file declares g_matchtime -- which is the normal case, and
        exactly the defect this gate exists for: the body verified only because the pass
        that wrote it had the declaration in its probe, and the assembly compiles only
        because some unrelated file supplies it;
      * and the tiers flag names that ARE declared, by the very file that references them,
        whenever an alias is involved. `pragma_declared` is canonicalised through
        global_alias_map() and the reference side is not, so `'!Global g_players:TList` in
        TBall.CanSeePlayer.bmx registers as g_object79 while the body's reference registers
        as g_players. Measured over the tree as it stands: 1,122 names are undeclared
        against the canonical set and 3 against the raw pragma names, so 1,119 of the
        assembler's "recovered from prose / inferred / unresolved" rows are that asymmetry
        and not a missing declaration. (Left alone deliberately -- the canonicalisation is
        load-bearing for what gets EMITTED, and this gate is not the place to change it.)

    So the tiers are reported below as context, and the exit code is decided by this
    per-file test, which is the property "a recovered file rebuilds from itself" actually
    means.

    Both halves reuse what already exists rather than re-reading the tree: the src/recovered
    half comes straight out of the `recovered` map main() has already loaded (body with
    comment lines already stripped, the file's own pragmas already split out), and only the
    tree membership is looked up. That means it sees exactly the files load_recovered()
    parsed, i.e. the ones named `Type.Method.bmx` -- every file in the tree today, and if
    one ever is not, it is a file the assembler ignores too. src/recovered_module has to be
    walked, because
    harness.module_functions() folds every file's pragmas into ONE flat _MODGLOBALS list
    and the per-FILE association -- the only thing this check is about -- is gone by the
    time the assembler sees it.

    src/recovered_unverified, src/recovered_thirdparty, src/behaviour and src/placeholder
    are deliberately NOT gated. They are near-miss, borrowed, behaviour-derived and
    admittedly-fake bodies; holding them to the durable-artefact standard would fail the
    gate on files nobody claims are finished.
    """
    mine = {fn for _d, fn in _recovered_files() if _d == RECOVERED}
    bad = []
    for (_t, _m), (body, gdecls, comments, fn) in sorted(recovered.items(),
                                                         key=lambda kv: kv[1][3]):
        if fn not in mine:
            continue
        miss = _file_defects(body, gdecls, comments)
        if miss:
            bad.append(("recovered/" + fn, miss))

    if os.path.isdir(MODULE_FNS):
        for fn in sorted(os.listdir(MODULE_FNS)):
            if not fn.endswith(".bmx"):
                continue
            text = open(os.path.join(MODULE_FNS, fn),
                        encoding="utf-8", errors="replace").read()
            stripped, gdecls = H.split_globals(text)
            code = "\n".join(l for l in stripped.split("\n")
                             if not l.lstrip().startswith("'"))
            comments = "\n".join(l for l in text.split("\n")
                                 if l.lstrip().startswith("'"))
            miss = _file_defects(code, gdecls, comments)
            if miss:
                bad.append(("recovered_module/" + fn, miss))
    return bad


def report_selfcontained(recovered, recovered_prose, inferred, unresolved):
    """Print the gate and return its exit code. Everything here is already computed."""
    bad = selfcontained_defects(recovered)

    print("what the assembler had to do to resolve the Globals it was handed:")
    print("  recovered from PROSE : %d   (a comment is not a declaration)"
          % len(recovered_prose))
    print("  INFERRED from usage  : %d   (no name:Type against that spelling)"
          % len(inferred))
    print("  UNRESOLVED           : %d   (no type evidence at all; these block the build)"
          % len(unresolved))
    print("  Counts, not defects: most rows are the alias asymmetry documented on")
    print("  selfcontained_defects, not a missing pragma. Run assemble.py with no flags")
    print("  for the full lists.")
    for k, ty, fn in recovered_prose[:8]:
        print("     prose      %-28s %-16s %s" % (k, ty, fn))
    print()

    if not bad:
        print("check_selfcontained: OK -- every recovered file declares its own Globals")
        return 0
    print("check_selfcontained: %d file(s) reference a module Global they do not declare."
          % len(bad))
    print("Add a real `'!Global <name>:<Type>` pragma inside the body. The type is the")
    print("assumption the body verified against -- take it from the file's own header")
    print("comment, then from extracted/globals_final.tsv (NEVER from a row marked")
    print("type_source=classtable-slot: those are class-table interiors, not Globals).")
    print("Re-verify with harness.try_method afterwards; a pragma is lifted to module")
    print("scope and stripped from the body, so a still-correct file still MATCHes.")
    for fn, miss in bad:
        print("  %-58s %s" % (fn, ", ".join(miss)))
    return 1


# extracted/ files this assembler READS and cannot recompute. Every one is tracked
# in git (see the note in .gitignore); a checkout that lacks them still assembles
# and still links, which is exactly the problem -- the damage is a runtime one.
# Absence is silent per file: a missing alias table just contributes no rows, so
# the merge count drops instead of the build stopping. Measured on a checkout
# holding only the five adjudication files: 507 merges instead of 1,280, i.e. two
# thirds of the split Globals left split, with no error anywhere.
_REQUIRED_INPUTS = [
    "global_address_map.tsv", "global_alias_adjudicated.tsv", "global_alias_map.tsv",
    "global_alias_overrides.tsv", "global_alias_unified.tsv", "global_alias_writers.tsv",
    "globals_type_overrides.tsv", "module_globals_decoded.tsv",
    "type_declaration_order.tsv",
]


def _check_inputs():
    ex = os.path.join(ROOT, "extracted")
    gone = [n for n in _REQUIRED_INPUTS if not os.path.exists(os.path.join(ex, n))]
    if not gone:
        return
    print("  !! MISSING BUILD INPUTS -- %d file(s) under extracted/:" % len(gone))
    for n in gone:
        print("  !!     %s" % n)
    print("  !! These are tracked in git and cannot be recomputed from the exe.")
    print("  !! The build will SUCCEED and the game will be broken at runtime:")
    print("  !! Globals sharing one address stay split, so the player does not")
    print("  !! respond, animation runs far too fast and quitting crashes.")
    print("  !!     git pull        (then: python scripts/setup.py)")
    print()


def main():
    _check_inputs()
    d = H.load_data()
    H._build_prelude(d)
    recovered, dupes = load_recovered()

    # Globals: every body declares what it needs. Two bodies disagreeing about the TYPE of
    # the same Global is exactly the inconsistency this script exists to find, so collect
    # them all and report conflicts rather than silently taking the first.
    # Key by LOWERCASE name: BlitzMax identifiers are case-insensitive, so g_awayteam and
    # g_AwayTeam are the same Global and emitting both is `Duplicate identifier`. Different
    # passes pick different casing for the same slot, which no single-body verification
    # could ever catch.
    # One address, several names (see global_alias_map()). Canonicalise the NAME as the
    # declaration map is built, so two aliases collapse into a single Global here and the
    # existing conflict reporting below sees them as one slot -- which is what they are.
    alias = global_alias_map()

    gtypes = collections.defaultdict(set)
    for (_t, _m), (_b, gd, _c, _f) in recovered.items():
        for g in gd:
            mm = re.match(GLOBAL_DECL_RX, g.strip())
            if mm:
                nm = mm.group(1).lower()
                gtypes[alias.get(nm, nm)].add(mm.group(2))
    # Module Functions carry their own '!Global pragmas, which harness.merge_globals folds
    # in for a single-body probe. The assembled program needs them for the same reason.
    H.module_functions()                      # populates H._MODGLOBALS
    # ... and so does this, which ALSO populates H._TPGLOBALS. It has to run here rather
    # than where tpfns is built further down, or the third-party functions' pragmas are
    # lifted after this loop has already read the list and are silently dropped.
    H.thirdparty_functions()
    # Names declared by a THIRD-PARTY module Function go to the external unit instead --
    # see tp_gtext below. Emitting them here as well would put the same identifier in both
    # compilation units, so they are held out of gtypes entirely.
    tp_names = set()
    for g in H._TPGLOBALS:
        mm = re.match(GLOBAL_DECL_RX, g.strip())
        if mm:
            nm = mm.group(1).lower()
            tp_names.add(alias.get(nm, nm))
    for g in H._MODGLOBALS:
        mm = re.match(GLOBAL_DECL_RX, g.strip())
        if mm:
            nm = mm.group(1).lower()
            nm = alias.get(nm, nm)
            if nm in tp_names:
                continue
            gtypes[nm].add(mm.group(2))

    # The module body's own Globals. The tail ASSIGNS these; nothing declares them,
    # because no recovered Type method or module Function happens to touch them.
    # Folded in here rather than emitted separately so they share this map's dedup and
    # conflict reporting: if a recovered body ever turns out to declare one of these with
    # a different type, that shows up as a normal UNRESOLVED CONFLICT instead of a
    # duplicate-identifier build failure.
    modbody_g = modbody_globals()
    for k, ty in modbody_g.items():
        gtypes[k].add(ty)

    conflicts = {k: v for k, v in gtypes.items() if len(v) > 1}
    ginits, ginit_conflicts = global_initialisers(recovered)

    # '!Import / '!Raw pragmas. harness.py's SINGLE-BODY probe builder honours both (worked
    # example: src/recovered_module/SteamInit.bmx, verified 158/158 on its own), and this
    # whole-program assembler has to honour them as well.
    # split_globals() strips '!Raw lines from a body exactly like '!Global ones
    # and folds their captured text into the SAME `gd`/`_MODGLOBALS` lists this file
    # already reads above -- but the loop above only recognises text shaped like
    # "Global name:Type", so a Raw fragment ("Extern" / "Function OpenSteam:Int(appid:Int)"
    # / "End Extern") would silently vanish, and without a split_imports() call the DLL
    # Import would vanish with it. The failure is easy to see in isolation: with
    # SteamInit.bmx out of the tree the assembled build is BUILD OK; with it present and
    # its pragmas dropped the build fails "Identifier 'OpenSteam' not found", which blocks
    # every `assemble.py` run for every worker.
    #
    # A Raw-derived fragment can be told apart from a Global one PURELY BY PREFIX: every
    # GLOBAL_PRAGMA match is captured starting at the literal word "Global" (harness.py:619,
    # `r"'!\s*(Global\s+[^\r\n]+?)"`), so anything in this same `gd`/`_MODGLOBALS` list that
    # does NOT start with "Global" can only have come from RAW_PRAGMA. H.parse_global_decl()
    # is the WRONG test here -- that regex requires the ENTIRE line to
    # match end-to-end (harness.py:567, anchored `$`), so a `'!Global` pragma carrying a
    # trailing inline comment (common in this corpus) fails it and lands in the "Raw"
    # bucket, duplicating that Global's declaration against the canonical one this file
    # already regenerates below ("Duplicate identifier").
    # `re.match` with no `$` anchor -- exactly what the `gtypes` loop above already uses --
    # does not have that failure mode.
    # DEDUPE WHOLE FRAGMENTS, NEVER INDIVIDUAL LINES.
    #
    # A '!Raw fragment is a BLOCK -- `Extern "Win32"` / declarations / `End Extern`, or a
    # placeholder `Function Foo()` / `End Function` pair. Deduping line by line silently
    # deletes a block's TERMINATOR as soon as any earlier fragment used the same closer,
    # because `End Function` is textually identical everywhere it appears.
    #
    # That is not hypothetical. Measured: TProfile.LoadSavedGame carries a placeholder
    #     '!Raw Function SyncSteamAchievements()
    #     '!Raw End Function
    # and an earlier fragment had already contributed a bare `End Function`. The line-level
    # `seen_raw` dropped LoadSavedGame's copy, so the assembled source contained
    #     Function SyncSteamAchievements()
    #     Extern "Win32"
    #     ...
    # with no closer. bcc then consumed the rest of the file looking for one and reported
    # "Expecting expression but encountered end-of-file" -- pointing at EOF, ~1,900 lines
    # from the actual defect, with nothing truncated and every other block pair balanced.
    # The whole-program build was broken outright; the byte corpus was unaffected, which is
    # exactly why it could go unnoticed.
    #
    # Grouping by contributor keeps each fragment intact and still collapses the genuine
    # duplicate case this dedupe exists for: two bodies carrying the SAME Extern block
    # produce identical tuples and the second is skipped whole. Two bodies carrying
    # DIFFERENT blocks now both survive, which is the correct outcome and the one the
    # line-level version could not express.
    raw_groups = [list(gd) for (_t, _m), (_b, gd, _c, _f) in recovered.items()]
    raw_groups.append(list(H._MODGLOBALS))
    seen_raw, raw_lines = set(), []
    for group in raw_groups:
        frag = [g.strip() for g in group
                if g.strip() and not re.match(r"^Global\s", g.strip(), re.I)]
        if not frag:
            continue
        key = tuple(frag)
        if key in seen_raw:
            continue
        seen_raw.add(key)
        raw_lines.extend(frag)
    # No file under src/recovered/ or src/recovered_thirdparty/ uses '!Import, so
    # H.module_imports() -- which covers src/recovered_module/ only -- is complete. If a
    # Type-method file ever needs one, load_recovered() will also need its own
    # H.split_imports() pass; not added speculatively, since only what is actually
    # exercised should be wired.
    import_lines = H.module_imports()

    # ---- recover the Globals that exist only in prose --------------------------------
    # A pragma is authoritative, so resolve names in three tiers and never let a weaker
    # tier override a stronger one. Tier 1 (pragmas) is already in gtypes above.
    pragma_declared = set(gtypes)
    refs = collections.defaultdict(list)          # lower name -> [bodies referencing it]
    ref_files = collections.defaultdict(set)      # lower name -> {files}
    prose_hits = {}                               # lower name -> (type, file)
    seen_by_file = {}                             # file -> {names it references}
    addr_prose = {}                               # file -> the one address-keyed type
    for (_t, _m), (body, _gd, comments, fn) in recovered.items():
        seen = {g.lower() for g in GREF_RX.findall(body)}
        seen_by_file[fn] = seen
        addr_prose[fn] = addr_prose_type(comments)
        for k in seen:
            refs[k].append(body)
            ref_files[k].add(fn)
        # Tier 2: this file's own comments, but only for names it actually references --
        # a comment naming a Global some OTHER file owns is not a declaration.
        for k, ty in prose_decls(comments).items():
            if k in seen and k not in pragma_declared:
                prose_hits.setdefault(k, (ty, fn))

    params, fieldtypes, owners = _model_index(d)
    undeclared = sorted(set(refs) - pragma_declared)

    # Tier 2b: address-keyed prose, usable only where the name-to-address association is
    # forced -- the file leaves exactly one Global unresolved and records one type.
    still = set(undeclared) - set(prose_hits)
    addr_hits = {}
    for fn, seen in seen_by_file.items():
        ty = addr_prose.get(fn)
        mine = seen & still
        if ty and len(mine) == 1:
            addr_hits.setdefault(next(iter(mine)), (ty, fn))

    recovered_prose, inferred, unresolved = [], [], []
    for k in undeclared:
        # Canonicalise here too. This pass recovers Globals that are REFERENCED by a body
        # but declared by no '!Global pragma, so an alias reaches it that the two pragma
        # loops above never saw -- and it would then be emitted as its own declaration and
        # renamed into a collision with the canonical one by apply_alias_map (this is what
        # produced "Duplicate identifier 'g_bj_bet'": g_bet is referenced, never declared).
        k = alias.get(k, k)
        if k in prose_hits or k in addr_hits:
            ty, fn = prose_hits.get(k) or addr_hits[k]
            gtypes[k].add(ty)
            recovered_prose.append((k, ty, fn))
            NOT_SELF_CONTAINED.append(fn)
        else:
            ty, why = infer_type(k, refs[k], params, fieldtypes, owners, d)
            if ty:
                gtypes[k].add(ty)
                inferred.append((k, ty, why, sorted(ref_files[k])[0]))
                NOT_SELF_CONTAINED.append(sorted(ref_files[k])[0])
            else:
                unresolved.append((k, sorted(ref_files[k])))

    # ---- the Globals gate, if that is all that was asked for -------------------------
    # Placed HERE and not at the end: everything the gate reports is complete at this
    # point, and everything after it emits src/assembled/ and then spends minutes in bmk.
    # A gate that rebuilds the program to answer a question about pragmas would not get run
    # before a commit, and the build is shared state -- two workers assembling at once
    # corrupt each other's object files (the reason scripts/verify_function.py builds in
    # private directories at all).
    if "--check-selfcontained" in sys.argv:
        return report_selfcontained(recovered, recovered_prose, inferred, unresolved)

    # ---- THE MAIN MODULE DECLARES 135 TYPES, NOT 341 --------------------------------
    #
    # A program's reflection table lists every Type in the LINKED IMAGE, so building the
    # emit set from it sweeps in 213 Types the game's main module never declared: Windows
    # API and D3D structs, 174 BRL/pub Types, and three third-party modules. Declaring
    # those in the main module shadows the imported originals -- our TBank.Resize would be
    # a 14-byte empty stub against the original's 104 -- and, worse, puts 213 spurious
    # entries into the module body's Type-registration sequence, which is the very thing
    # extracted/type_declaration_order.tsv records and the `data` class tables follow from.
    #
    # type_declaration_order.tsv IS the main module's own set: 135 Types, recovered from
    # the registration sequence, and the test is clean both ways (TPlayer/TGadget in,
    # TBank/TField/TList/BITMAPINFOHEADER out). Emit exactly those, in that order.
    #
    # The other 213 still have to EXIST for the program to compile -- 8 of them appear in
    # the 135's own signatures and 2 more in surviving bodies. They go into a SEPARATE
    # compilation unit pulled in with `Import "nss5_external.bmx"`. bcc gives an imported
    # source file its own module body, so its Types register in ITS sequence, not the main
    # module's, which is exactly the property being protected. Folding them back into the
    # main file would corrupt the declaration order everything else depends on.
    #
    # ...and of those 213, 166 are Types an INSTALLED module already declares. A second
    # compilation unit keeps them out of the registration sequence but does NOT stop them
    # shadowing: a second `Type TBank` is a second TBank, and ours is a wall of
    # 14-byte empty methods. Drop them and let `Import` supply them; keep only the Types no
    # module on disk declares.
    fdecls, fdecl_conflicts = field_pragmas()
    decl_order = type_order()
    supply = module_supplied_types()
    main_set = [t for t in decl_order if t in H._TYPETEXT]
    # If one of the game's own 135 were also declared by a module we would be choosing
    # between two authorities; none is, so assert that instead of assuming it.
    main_shadow = [t for t in main_set if t.lower() in supply]
    side_all = [t for t in H._ORDER if t not in set(main_set)]
    dropped = [t for t in side_all if t.lower() in supply]
    side_set = [t for t in side_all if t.lower() not in supply]

    def extends_violations(seq):
        p = {t: i for i, t in enumerate(seq)}
        return [(t, d["supers"][t]) for t in seq
                if d["supers"].get(t) in p and p[d["supers"][t]] > p[t]]

    # Within each unit, a parent must precede its child. Across units the Import does it:
    # nothing in the external unit extends a Type from the 135 (checked), and the two
    # main Types that extend outward (TMyStream->TStreamWrapper, TMyBankStream->
    # TBankStream) reach a Type the Import has already declared.
    hoisted = extends_violations(main_set) + extends_violations(side_set)
    main_set = parent_before_child(main_set, d)
    side_set = parent_before_child(side_set, d)
    assert not extends_violations(main_set), "parent_before_child left a violation"
    assert not extends_violations(side_set), "parent_before_child left a violation"

    def emit(seq):
        out, n = [], 0
        for t in seq:
            methods = {m["name"] for m in d["methods"].get(t, [])}
            bodies = {mn: b for (tn, mn), (b, _g, _c, _f) in recovered.items()
                      if tn == t and mn in methods}
            # emit_type() BUILDS FROM `d` AND RETURNS A FRESH STRING -- it never reads the
            # previous text for this Type. Calling it once per body and assigning the
            # result back is replacement, not accumulation: for a Type with N recovered
            # bodies the first N-1 were overwritten and only the last survived (TPlayer:
            # 71 in, 1 out). `bodies=` fills every member in a single pass.
            n += len(bodies)
            if bodies or fdecls.get(t):
                H._TYPETEXT[t] = H.emit_type(t, d, bodies=bodies,
                                             field_decls=fdecls.get(t))
            out.append(H._TYPETEXT[t])
        return out, n

    chunks, filled = emit(main_set)
    side_chunks, side_filled = emit(side_set)
    order = main_set                          # what the MAIN module declares

    # A conflict is REPORTED, not silently resolved. The declared type picks the vtable
    # slot for every call through the Global, so choosing alphabetically is choosing at
    # random; say so in the source next to the declaration and in the exit status.
    over = global_overrides()
    array_sizes = module_global_array_sizes()

    # ARRAY SIZES ARE KEYED BY NAME, AND THAT IS NOT ENOUGH.
    #
    # module_globals_decoded.tsv records each size under the name that table happens to
    # use. If the corpus knows the same slot by a DIFFERENT name -- which is the normal
    # case in this project, and the entire reason name unification exists -- the size never
    # reaches the declaration, and the Global is emitted with a length guessed from however
    # far the corpus happens to index it.
    #
    # Such a guess causes startup crashes, both of them out-of-bounds WRITES, which unlike
    # a null deref are not swallowed by a release build (18.26) but kill the process:
    #   g_kitfiles  emitted String[1]  while 0x00C5C1E4 is String[26]  (as g_kit_arr01)
    #   g_fansimg   emitted TImage[6]  while 0x00C5D60C is TImage[10]  (as g_pitch_arr04)
    # In both cases globals_type_overrides.tsv carries an explicit, reasoned note saying no
    # table has the size, which holds only until the address is known.
    #
    # So resolve sizes by ADDRESS as well. extracted/global_address_map.tsv gives the
    # address for a name whatever spelling it uses, so a decoded size reaches every name
    # for that slot regardless of which one the table was written under.
    _size_by_va = {}
    for _n, (_t, _s, _va) in array_sizes.items():
        if _va:
            try:
                _size_by_va["0x%08X" % int(_va, 16)] = (_t, _s, _va)
            except ValueError:
                pass
    _amap = os.path.join(ROOT, "extracted", "global_address_map.tsv")
    if _size_by_va and os.path.exists(_amap):
        for _line in open(_amap, encoding="utf-8").read().splitlines()[1:]:
            _f = _line.split("\t")
            if len(_f) >= 2 and _f[1].startswith("0x") and _f[1] in _size_by_va:
                array_sizes.setdefault(_f[0].strip().lower(), _size_by_va[_f[1]])

    # These three dicts are keyed by the name their SOURCE TABLE used, which may be an
    # alias. gtypes was already canonicalised, but the emission loop below unions its keys
    # with array_sizes' -- so an alias surviving here is emitted as its own declaration and
    # then renamed into a collision with the canonical one ("Duplicate identifier
    # 'g_bj_bet'", caught by the build). Canonicalise the keys, not just the references.
    def _canon_keys(d):
        out = {}
        for k, v in d.items():
            out[alias.get(k, k)] = v
        return out

    over, array_sizes, ginits = _canon_keys(over), _canon_keys(array_sizes), _canon_keys(ginits)
    array_sizes_new, array_sizes_filled, array_size_conflicts = [], [], []
    gout = []
    for k in sorted(set(gtypes) | set(array_sizes)):
        v = gtypes.get(k, set())
        # Carry the captured initial value through the regenerated declaration.
        # A conflicting initialiser is suspicious enough to leave OFF rather than
        # guess -- ginit_conflicts already records it for the printed report below.
        init = " = %s" % ginits[k][0] if k in ginits else ""
        if k in over:
            ty, note = over[k][0], ""
        elif len(v) > 1:
            ty, note = sorted(v)[0], "\t' !! UNRESOLVED CONFLICT: %s" % " vs ".join(sorted(v))
        elif v:
            ty, note = sorted(v)[0], ""
        else:
            ty, note = None, ""

        # Fold in a literal array SIZE read directly from the exe. Never
        # override an EXISTING base type -- a body
        # elsewhere may dispatch a method through this Global's declared class, and a wrong
        # substitution (TButton -> TLabel is the one measured case) can fail the
        # build outright ("Method 'X' not found") or silently change which override a call
        # resolves to. Only the SIZE is new information here; the base type is not.
        if k in array_sizes:
            dty, dsz, _dva = array_sizes[k]
            if ty is None:
                ty, note = "%s[%s]" % (dty, dsz), ""
                array_sizes_new.append((k, dty, dsz))
            elif ty.rstrip().endswith("[]"):
                ty = "%s[%s]" % (ty.rstrip()[:-2], dsz)
                array_sizes_filled.append((k, ty, dty))
            elif ty.rstrip().endswith("]"):
                # Already carries an explicit size -- but a size READ OUT OF THE BINARY
                # beats one inferred from how the corpus happens to index the array, and it
                # must never be allowed to SHRINK the allocation.
                #
                # This is a live hazard whenever an alias merge lands a decoded array onto
                # a name whose size was guessed. globals_type_overrides.tsv pins
                # g_kitfiles to String[1], reasoning that "this Global is not in
                # module_globals_decoded.tsv ... largest observed index implies length 1".
                # g_kit_arr01 IS in that table, as String[26], and merges into g_kitfiles,
                # so without this rule the guess wins. TKit.SetUp writes basemask,
                # baseshirt1 and 24 more into indices 0..25 of a 1-element array: an
                # out-of-bounds write, and an access violation on startup rather than the
                # quiet nothing a null deref would give.
                mm = re.search(r"\[\s*(\d+)\s*\]\s*$", ty)
                try:
                    have = int(mm.group(1)) if mm else 0
                    need = int(dsz)
                except (TypeError, ValueError):
                    have = need = 0
                if need > have:
                    ty = "%s[%s]" % (ty.rstrip()[:ty.rstrip().rindex("[")], dsz)
                    array_sizes_filled.append((k, ty, dty))
            else:
                array_size_conflicts.append((k, ty, dty, dsz))

        if ty is None:
            continue
        gout.append("Global %s:%s%s%s" % (k, ty, init, note))
    gtext = "\n".join(gout)
    modfns = "\n".join(H.module_functions())
    # Module-level Functions belonging to the two THIRD-PARTY modules (a file under
    # src/recovered_thirdparty/<mod>/ whose stem carries no dot). They belong with the
    # EXTERNAL unit, not the main module: they are that module's own code, they call and
    # are called by its Types, and the main module never declares them.
    #
    # Until this existed load_recovered() dropped every one of them on its
    # `if "." not in base: continue` line and they reached no build at all. That is not a
    # cosmetic gap: fontmachine's two point helpers (0x00592A13, 0x00592A37) are called by
    # all three Draw*Text bodies, i.e. by every glyph the game draws, so without them the
    # text layer cannot even be compiled, let alone run.
    tpfns = "\n".join(H.thirdparty_functions())

    # The Globals those functions declare, emitted HERE and not in the main unit. The
    # external unit is Imported by nss5_assembled.bmx, and an imported unit cannot see the
    # importer's Globals, so a declaration left in the main file is invisible to the code
    # that needs it. zipengine's Fn_0058FB20 is the case: it declares
    # `'!Global g_zipfilefunc_streams:TMap` and calls .Insert on it, and with the
    # declaration in the wrong unit the build fails outright with
    # "Identifier 'g_zipfilefunc_streams' not found". Deduplicated by name, and typed from
    # the pragma verbatim, because nothing else in the program declares these.
    tp_seen, tp_lines = set(), []
    for g in H._TPGLOBALS:
        mm = re.match(GLOBAL_DECL_RX, g.strip())
        if not mm:
            # A '!Raw pragma rather than a '!Global one: emit it verbatim, same as the
            # main unit does, since that is exactly what Raw means.
            if g.strip() and g.strip() not in tp_seen:
                tp_seen.add(g.strip())
                tp_lines.append(g.strip())
            continue
        nm = alias.get(mm.group(1).lower(), mm.group(1).lower())
        if nm in tp_seen:
            continue
        tp_seen.add(nm)
        tp_lines.append("Global %s:%s" % (nm, mm.group(2)))
    tp_gtext = "\n".join(
        (["' Globals declared by the third-party module Functions below. They live in this",
          "' unit, not the main one, because an Imported unit cannot see the importer's",
          "' Globals -- see assemble.py's note at this site."] + tp_lines) if tp_lines else [])

    # H._HEADER[0] is SuperStrict + the BRL Imports + `Type X / End Type` placeholders for
    # names referenced in a signature but absent from the reflection table. The
    # placeholders are declarations too, so they belong with the external unit; the main
    # file keeps only SuperStrict and the Imports.
    head_lines = H._HEADER[0].split("\n")
    ph, keep, i, ph_shadow = [], [], 0, []
    while i < len(head_lines):
        m = re.match(r"^Type\s+(\w+)\s*$", head_lines[i])
        if m:
            block = [head_lines[i]]
            if i + 1 < len(head_lines) and head_lines[i + 1].strip() == "End Type":
                block.append(head_lines[i + 1])
                i += 1
            # A placeholder for a Type a module declares shadows it exactly as a stub
            # does, and is the same defect in a cheaper disguise. Drop it too.
            if m.group(1).lower() in supply:
                ph_shadow.append(m.group(1))
            else:
                ph.extend(block)
        else:
            keep.append(head_lines[i])
        i += 1

    # Which of the dropped Types does the remaining source still NAME? Only those decide
    # the Import list, and it is computed from the emitted text rather than assumed, so a
    # Type that stops being referenced stops costing us a module.
    body_text = "\n".join(chunks + side_chunks + [gtext, modfns, tpfns] + ph)
    need, ambiguous = imports_needed(body_text, dropped, supply)
    have = {l.split(None, 1)[1].strip().lower() for l in keep if l.startswith("Import ")}
    add = [n for n in sorted(need) if n.lower() not in have]
    if add:
        keep = keep + ["' Imports supplying Types the main module must NOT redeclare "
                       "(a local copy shadows the real one with empty stubs)"] + \
            ["Import %s.%s" % (n.split(".")[0].upper(), n.split(".", 1)[1]) for n in add]
    # '!Import pragmas (see above) -- these are FILE-PATH imports ('!Import already
    # captures the argument WITH its surrounding quotes, so "Import " + i is directly
    # valid syntax), not NS.module names, so they cannot share `have`'s dotted-name
    # dedup key; compare on the raw argument text instead.
    have_paths = {l.split(None, 1)[1].strip() for l in keep if l.startswith("Import ")}
    add_imports = [i for i in import_lines if i not in have_paths]
    if add_imports:
        keep = keep + ["' '!Import pragmas from src/recovered_module/ (DLL import libraries)"] + \
            ["Import " + i for i in add_imports]
    # Modules the module body needs. Added after the discovery-driven lists above so a
    # name already found by imports_needed() is not emitted twice.
    have_all = {l.split(None, 1)[1].strip().lower() for l in keep if l.startswith("Import ")}
    add_mb = [m for m in MODBODY_IMPORTS if m.lower() not in have_all]
    if add_mb:
        keep = keep + ["' Modules the module body itself needs (the original's 15 Imports)"] + \
            ["Import " + m for m in add_mb]
    # Modules THIS RECONSTRUCTION needs and the original did not, kept in their own list so
    # MODBODY_IMPORTS above stays an honest record of the original's 15.
    have_all = {l.split(None, 1)[1].strip().lower() for l in keep if l.startswith("Import ")}
    add_rc = [m for m in RECON_IMPORTS if m.lower() not in have_all]
    if add_rc:
        keep = keep + ["' Modules this reconstruction needs that the original did not "
                       "(see assemble.py's RECON_IMPORTS)"] + \
            ["Import " + m for m in add_rc]

    ext_head = "\n".join(keep + [""] + ph)

    # ---- the zipengine module body's one surviving top-level statement ------------------
    #
    # A BlitzMax TStreamFactory subclass registers ITSELF, from TStreamFactory.New(), into
    # the chain BRL.Stream walks in OpenStream(). Constructing one and throwing the handle
    # away is the whole registration, and the zipengine module's own module body does
    # exactly that -- read off the original at 0x0058DBB2 and recorded in
    # src/recovered_unverified/Fn_0058DACC.ZipEngineModuleInit.bmx:
    #     push 0x00C9590C ; call _bbObjectNew ; add esp,4     -> New TZipEngineStreamFactory
    #     (result DISCARDED; the next instruction reloads eax from elsewhere)
    # That file's own note says why it matters: "It is why `ReadFile("zip::...")` works at
    # all."
    #
    # This assembler has no module body for an imported third-party module, so that
    # statement had nowhere to go and was simply absent. The consequence was total and
    # silent: with no factory in the chain, OpenStream never recognises the "zipe" protocol,
    # so EVERY `ReadStream("zipe::" + ...)` in the game returned Null --
    # TProfile.LoadSavedGame, TScreen_MainMenu.UpdateLoadTable and TReplay.LoadReplayFile
    # alike. UpdateLoadTable reads a Null there as a corrupt file and offers to delete the
    # save. Emitting it here puts it in the same place BlitzMax puts it: an imported unit's
    # module body runs before the importer's, so the factory is registered before any game
    # code can ask for a url.
    zipe_init = "\n".join([
        "' The zipengine module body's own top-level statement, reproduced. See",
        "' assemble.py's note at this site and",
        "' src/recovered_unverified/Fn_0058DACC.ZipEngineModuleInit.bmx.",
        "' A TStreamFactory subclass registers itself from TStreamFactory.New(), so",
        "' constructing one and discarding it IS the registration -- without it the",
        "' \"zipe\" protocol is unknown to OpenStream and every save, replay and load",
        "' url resolves to Null.",
        "New TZipEngineStreamFactory",
    ]) if any(re.match(r"\s*Type\s+TZipEngineStreamFactory\b", l)
              for c in side_chunks for l in c.split("\n")) else ""

    os.makedirs(OUT_DIR, exist_ok=True)
    ext = "\n".join([
        "' generated by assemble.py -- do NOT edit",
        "' Types that are NOT declared by the game's main module. They are in",
        "' NSS5.exe's reflection table because they are in the linked image, not because",
        "' the main module declares them. Kept in a separate compilation unit so they do",
        "' not enter the main module's Type-registration sequence.",
        ext_head, "\n".join(side_chunks), "", tp_gtext, "", tpfns, "", zipe_init, ""])
    # Rewrite aliased Global references in the emitted bodies. The declarations above are
    # already canonical (gtypes was keyed through the map), so this only touches uses.
    ext, ext_renames = apply_alias_map(ext, alias)
    ext_path = os.path.join(OUT_DIR, "nss5_external.bmx")
    # utf-8-sig, NOT latin-1: bcc's toker.cpp (_src/compiler/toker.cpp:302) picks UTF8
    # only on an EF BB BF BOM and otherwise falls back to LATIN1. Latin-1 cannot represent
    # U+20AC EURO SIGN, so errors="replace" silently turns NSS5's "€ EUR" into "? EUR"
    # before bcc ever sees it -- invisible to every byte check, because a literal reaches
    # the code only as a masked address. Measured on TScreen_Options.CreateScreen: MATCH
    # 8290/8290 both ways, while the probe .data holds U+003F with latin-1 and U+20AC
    # with the BOM.
    open(ext_path, "w", encoding="utf-8-sig").write(ext)

    rawtext = "\n".join(raw_lines)

    # ---- THE MODULE BODY -----------------------------------------------------------
    # The generated source must end in a real program. A placeholder tail such as
    # `If AppTitle = "~q~q" Then End` makes the file syntactically valid without being a
    # program: every Type and Global declared and then nothing done, no Incbin
    # registrations, no start-up sequence, no GameMain call. BUILD OK would then mean "the
    # corpus agrees with itself", never "this is the game".
    #
    # Order matters and is not arbitrary. In the original body the Incbin registrations
    # come first (+54..+344), then the module-init chain, then the 135 Type registrations
    # interleaved with the Global initialisers (+437..+5549), then the real program
    # (+5549..+7933). Emitting Incbin at the top and the tail last reproduces that
    # sequence at the source level -- the Globals are already initialised by the time the
    # tail runs, and the tail is the last thing in the file, so GameMain() is the last
    # thing that happens. What is NOT reproduced is the fine-grained interleaving of
    # individual Types against individual Globals (extracted/module_emission_order.tsv
    # has it); that only matters for byte-matching the body, not for running it.
    incbin_lines = ["' The 11 Incbin'd assets, in the original's registration order",
                    "' 6,731,720 bytes, round-trip verified by",
                    "' scripts/extract_incbin.py --verify."] + \
                   ['Incbin "%s"' % p for p in INCBIN_ORDER]
    copied = copy_incbin_tree()

    # NSS5_TAIL=exercise swaps in src/module_body/tail_exercise.bmx, which boots exactly as
    # GameMain does and then walks every screen and fires every button inside Try/Catch
    # instead of entering the game loop. That is how the whole bug list comes out of one
    # unattended run; the normal build is untouched.
    tail_path = MODBODY_TAIL
    if os.environ.get("NSS5_TAIL", "").lower() == "exercise":
        tail_path = os.path.join(MODBODY_DIR, "tail_exercise.bmx")
        print("  MODULE BODY TAIL            : EXERCISE (automated screen/button sweep)")
    if not os.path.exists(tail_path):
        raise SystemExit("missing module body tail: %s" % tail_path)
    tail = open(tail_path, encoding="utf-8").read()

    # Collection Globals the corpus uses but never assigns -- must run after every Global
    # is declared and before any game code touches one. See that file's header.
    coll = ""
    coll_path = os.path.join(MODBODY_DIR, "collections.bmx")
    if os.path.exists(coll_path):
        coll = open(coll_path, encoding="utf-8").read()

    src = "\n".join(["\n".join(keep), 'Import "nss5_external.bmx"', "",
                     "\n".join(incbin_lines), "",
                     "\n".join(chunks), "", gtext, "", rawtext, "", modfns, "",
                     coll, "", tail]) + "\n"

    src, src_renames = apply_alias_map(src, alias)
    print("  Global alias merges applied : %d names, %d references rewritten"
          % (len(alias), src_renames + ext_renames))
    print("                                (one address had several recovered names;")
    print("                                 scripts/build_alias_map.py, --skipped for the rest)")

    # ZERO IS NOT A NEUTRAL RESULT, IT IS THE BROKEN BUILD.
    # A checkout missing extracted/global_alias_*.tsv reaches here, prints "0 names,
    # 0 references rewritten", and goes on to compile and link successfully. What it
    # produces is the split-Globals binary: one address carrying several names, the
    # writer updating one variable and the reader seeing another that nothing ever
    # assigns. Measured on a tracked-files-only checkout -- 0 merges against 1,280,
    # and 2,797 distinct Globals declared against 1,551. The exe builds either way,
    # so this line is the only place the difference is visible before the player
    # stops responding to the keyboard.
    if not alias:
        print()
        print("  !! NO GLOBAL ALIASES MERGED. This build will be broken at RUNTIME,")
        print("  !! not at compile time: Globals that share one address stay split,")
        print("  !! so the player will not move, animation runs far too fast and")
        print("  !! quitting crashes. Expected roughly 1,280 merges, got 0.")
        print("  !! Cause is almost always missing input files. Check with:")
        print("  !!     python scripts/setup.py")

    path = os.path.join(OUT_DIR, "nss5_assembled.bmx")
    # utf-8-sig, NOT latin-1: bcc's toker.cpp (_src/compiler/toker.cpp:302) picks UTF8
    # only on an EF BB BF BOM and otherwise falls back to LATIN1. Latin-1 cannot represent
    # U+20AC EURO SIGN, so errors="replace" silently turns NSS5's "€ EUR" into "? EUR"
    # before bcc ever sees it -- invisible to every byte check, because a literal reaches
    # the code only as a masked address. Measured on TScreen_Options.CreateScreen: MATCH
    # 8290/8290 both ways, while the probe .data holds U+003F with latin-1 and U+20AC
    # with the BOM.
    open(path, "w", encoding="utf-8-sig").write(src)

    in_file = count_placed(src) + count_placed(ext)
    agree = in_file == filled + side_filled

    print("ASSEMBLY")
    print("  .bmx files in src/recovered : %d"
          % len([f for f in os.listdir(RECOVERED) if f.endswith(".bmx")]))
    print("  recovered bodies found      : %d" % len(recovered))
    print("  bodies placed into a Type   : %d  (%d main module, %d external unit)"
          % (filled + side_filled, filled, side_filled))
    print("  bodies present IN THE FILE  : %d   %s"
          % (in_file, "OK" if agree else "!! MISMATCH -- bodies are being lost"))
    print("  Types carrying >=1 body     : %d"
          % len({t for (t, _m) in recovered if t in H._TYPETEXT}))
    print("  field-initialiser pragmas   : %d over %d Types"
          % (sum(len(v) for v in fdecls.values()),
             len([t for t, v in fdecls.items() if v])))
    if hoisted:
        print("  Extends order violations fixed: %d %s" % (len(hoisted), hoisted[:4]))
    if PARAM_RENAMED:
        print("  params renamed to a0/a1/... : %d file(s) (file declared its own names;"
              % len(PARAM_RENAMED))
        print("                                 emit_type regenerates the signature)")
        for fn, ren in PARAM_RENAMED[:8]:
            print("     %-44s %s" % (fn, ", ".join(ren)))
    if fdecl_conflicts:
        print("  !! FIELD PRAGMA CONFLICTS   : %d %s"
              % (len(fdecl_conflicts), fdecl_conflicts[:3]))
    print("  Global initialisers captured : %d"
          % len(ginits))
    if ginit_conflicts:
        print("  !! GLOBAL INITIALISER CONFLICTS : %d %s"
              % (len(ginit_conflicts), ginit_conflicts[:3]))
    print("  module-scope array Globals sized : %d new, %d filled  (of 94"
          % (len(array_sizes_new), len(array_sizes_filled)))
    print("                                     module-level Globals; 64 resolve to a"
          " bare array allocation, 30 do not and are not attempted here)")
    if array_size_conflicts:
        print("  !! ARRAY-SIZE CONFLICTS      : %d -- exe evidence says these are arrays,"
              % len(array_size_conflicts))
        print("  !! an existing body's Global usage says otherwise. Left UNCHANGED (the"
              " existing type governs); reconcile by hand before trusting either.")
        for k, ty, dty, dsz in array_size_conflicts[:8]:
            print("     %-30s declared %-14s exe says %s[%s]" % (k, ty, dty, dsz))
    if raw_lines or import_lines:
        print("  '!Import / '!Raw pragmas wired : %d Import path(s), %d Raw text line(s)"
              % (len(import_lines), len(raw_lines)))
    print("  module Functions            : %d" % len(H.module_functions()))
    print("  Types in the MAIN module    : %d   (recorded declaration order: %d)"
          % (len(chunks), len(decl_order)))
    print("  Types dropped to an Import  : %d   (declared by an installed module; a local"
          % len(dropped))
    print("                                     copy would shadow it with empty stubs)")
    print("  Types in the external unit  : %d   %s   (no module on disk declares these)"
          % (len(side_chunks), os.path.basename(ext_path)))
    if main_shadow:
        print("  !! %d of the game's own 135 are ALSO declared by a module: %s"
              % (len(main_shadow), main_shadow[:6]))
    if ph_shadow:
        print("  placeholders dropped        : %d  %s"
              % (len(ph_shadow), ", ".join(sorted(ph_shadow)[:8])))
    if add:
        print("  Imports added for dropped Types : %d" % len(add))
        for n in add:
            print("     %-24s %s" % (n, ", ".join(sorted(need[n]))[:70]))
    if ambiguous:
        print("  !! %d dropped Types are declared by MORE THAN ONE module -- the Import"
              % len(ambiguous))
        print("  !! list is therefore not forced: %s" % ambiguous[:4])
    print("  distinct Globals declared   : %d" % len(gtypes))
    print("  source size                 : %d bytes, %d lines"
          % (len(src), src.count("\n")))
    if NOT_SELF_CONTAINED:
        print("  NOT self-contained (Global in a comment, not a pragma): %d file(s)"
              % len(set(NOT_SELF_CONTAINED)))
    if recovered_prose:
        print("  Globals recovered from PROSE  : %d  (need a real '!Global pragma)"
              % len(recovered_prose))
        for k, ty, fn in recovered_prose[:8]:
            print("     %-30s %-16s %s" % (k, ty, fn))
    if inferred:
        print("  Globals INFERRED from usage   : %d  (no name:Type anywhere -- the file"
              % len(inferred))
        print("                                     records the type against the ADDRESS)")
        for k, ty, why, fn in inferred:
            print("     %-30s %-16s %-28s %s" % (k, ty, why, fn))
    if unresolved:
        print("  !! UNRESOLVED Globals          : %d -- referenced, declared nowhere,"
              % len(unresolved))
        print("  !! and usage gives no evidence of a type. These block the build.")
        for k, fl in unresolved:
            print("     %-30s %s" % (k, ", ".join(fl[:3])))
    if dupes:
        print("  DUPLICATE bodies            : %d %s" % (len(dupes), dupes[:5]))
    if conflicts:
        print()
        print("  !! GLOBAL TYPE CONFLICTS -- different bodies assume different types for")
        print("  !! the same Global. Each verified alone; they cannot all be right.")
        for k, v in sorted(conflicts.items())[:20]:
            tag = ("resolved -> %s" % over[k][0]) if k in over else "UNRESOLVED"
            print("     %-30s %-22s %s" % (k, " vs ".join(sorted(v)), tag))
        if [k for k in conflicts if k not in over]:
            print("  !! Unresolved conflicts are emitted ALPHABETICALLY, i.e. arbitrarily.")
            print("  !! The declared type picks the vtable slot for every call through the")
            print("  !! Global, so resolve from the CODE and record")
            print("  !! the answer in extracted/globals_type_overrides.tsv.")
    print()
    print("  written: %s" % path)

    if not agree:
        print()
        print("  ABORTING: %d bodies went in and %d came out. The assembler is losing"
              % (filled, in_file))
        print("  bodies, so no build result from it would mean anything. Fix that first.")
        return 2

    print()
    print("COMPILING ...")
    # Without this, a missing toolchain surfaces as subprocess raising
    # `FileNotFoundError: [WinError 2] The system cannot find the file specified`
    # out of CreateProcess -- twenty frames of Popen internals naming neither bmk
    # nor BlitzMax. That is the single least actionable failure on the setup path,
    # and it is what a newcomer hits the first time they reach this line.
    if not os.path.exists(H.BMK):
        print("  result: CANNOT COMPILE")
        print("    no BlitzMax compiler at %s" % H.BMK)
        print("    The assembled source WAS written (above) -- only the build is")
        print("    blocked. Install the toolchain, then re-run:")
        print("        python scripts/setup.py     # reports exactly what is missing")
        return 2
    p = subprocess.run([H.BMK, "makelib" if False else "makeapp", "-r", "-t", "console", path],
                       cwd=H.BMX_ROOT, env=H._env(), capture_output=True,
                       text=True, errors="replace", timeout=1800)
    ok = p.returncode == 0
    msg = ((p.stdout or "") + (p.stderr or "")).strip()
    print("  result: %s" % ("BUILD OK" if ok else "BUILD FAILED"))
    # KEEP THE SOURCE LOCATION. "bcc does not report a line number" has been believed
    # here for a while and it is FALSE -- bcc prints the offending position on its OWN
    # line, right after the message, and that line contains neither "Error" nor "error":
    #     Compile Error: Expression of type 'Byte' cannot be invoked
    #     [C:/.../src/assembled/nss5_assembled.bmx;47126;2]
    # Filtering on the word "Error" alone threw the second line away, which is the entire
    # reason failures of this gate have had to be bisected by hand over a 48,000-line
    # generated file. Measured 2026-08-22 (worker 324) against a deliberately truncated
    # Global declaration: bmk relayed the `[file;line;col]` line every time.
    _lines = msg.split("\n")
    _loc = re.compile(r"^\[.+;\d+;\d+\]$")
    errs = []
    for _i, _l in enumerate(_lines):
        if "Error" in _l or "error" in _l:
            errs.append(_l)
            _nxt = _lines[_i + 1].strip() if _i + 1 < len(_lines) else ""
            if _loc.match(_nxt):
                errs.append(_nxt)
    for l in errs[:25]:
        print("    " + l.strip()[:160])
    if not errs and not ok:
        print("    " + msg[-1200:])
    if not ok:
        # Only on failure, and advisory only: a static lint for the one bcc error that
        # this generator can produce by itself, a Global whose regenerated declaration
        # lost its type. See scripts/check_global_calls.py for the worked case.
        try:
            import check_global_calls
            for _u in (path, os.path.join(os.path.dirname(path), "nss5_external.bmx")):
                if not os.path.exists(_u):
                    continue
                for _n, _ty, _dl, _calls in check_global_calls.check(_u):
                    print("    !! %s line %d: Global %s:%s is not callable, but is"
                          % (os.path.basename(_u), _dl, _n, _ty))
                    print("       invoked at line(s) %s"
                          % ", ".join(str(c) for c in _calls[:8]))
        except Exception as _e:                  # a lint must never mask the real error
            print("    (check_global_calls unavailable: %s)" % _e)
    return 0 if ok else 1


if __name__ == "__main__":
    sys.exit(main())
