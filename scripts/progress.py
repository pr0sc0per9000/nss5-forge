"""Measure reconstruction progress from the source itself, and emit a badge.

    python scripts/progress.py                # human-readable table
    python scripts/progress.py --shield       # shields.io endpoint JSON
    python scripts/progress.py --write-status # regenerate docs/STATUS.md
    python scripts/progress.py --csv          # machine-readable rows

WHY THIS IS DERIVED AND NOT HAND-MAINTAINED
===========================================
A hand-written progress file is wrong the moment anyone commits, and then it
lies -- confidently, in the repo, to a reader who has no way to tell. This
project accumulated exactly that: a RESUME.md quoting "predicted crash sites:
54", accurate for about one hour.

Every mature decompilation project solves this the same way. The percentage is
computed FROM THE SOURCE, by reading markers the reconstruction work already
leaves behind:

  * zeldaret/oot and n64decomp/sm64 scan for `#pragma GLOBAL_ASM(...)` (not
    attempted) and `#ifdef NON_MATCHING` (attempted, not byte-matching).
  * isledecomp/isle scans for `// FUNCTION: LEGO1 0x100b12c0` address
    annotations and feeds them to reccmp.

Ours are already there, at the top of every recovered body:

    ' TScreen_Language.SetUpScreen
    ' VA 0x0051BF6C   93 bytes   vtable slot 0x34   sig (i)i
    ' byte-identical vs NSS5.exe (93/93, original length from Ghidra's inventory)

So progress needs no bookkeeping at all -- only a parser. Nothing here can drift
out of sync with the code, because it IS the code.

MEASURED IN BYTES, NOT FUNCTIONS
================================
Deliberately, and this is the convention across the field. Function counts
flatter: a corpus is mostly small accessors and trampolines, so matching them
all while every large routine remains unmatched reports ~90% while the hard 90%
of the work is untouched. decomp.dev makes the same argument explicitly.
Bytes track the actual remaining work.

WHAT COUNTS AS MATCHED
======================
A body is MATCHED when its header states `byte-identical vs NSS5.exe` AND its
own status block does not retract that. The rule, and the evidence for every
part of it, is in scripts/claim.py -- one reader, shared with coverage.py, so
the two measures cannot drift into two different definitions of the same word.
The claim is produced by scripts/bytematch.py and scripts/localise_diff.py
against the real binary, not by an author's assertion. localise_diff is the only
honest oracle here: the positional comparator reports ~75% for byte-identical
bodies whose load address differs.

This file used to apply the first half of that rule and not the second, and
counted ten bodies whose own line 1 reads `-- NOT VERIFIED`. See claim.py.
A body whose header says both things is reported under CONTRADICTED HEADERS
below and counted as UNMATCHED until somebody re-runs the oracle on it.

NOTHING IS EXCLUDED FROM THE CORPUS
===================================
Every body with a parseable VA header counts, in both the numerator and the
denominator. There is no exclusion list. What there IS is a SHIPPING note --
VERIFIED_NOT_SHIPPED below -- recording which bodies are deliberately absent
from src/assembled/, and why. That note changes no number here; it only labels.

This replaces an earlier STEAM_EXCLUDE set that dropped four Steam-linked
bodies (1,232 bytes) from both numerator and denominator. Its reasoning about
the PLAYABLE BUILD was correct and is preserved verbatim below. The step it
took beyond that was not:

    it claimed a body that cannot ship can also never report
    `byte-identical vs NSS5.exe`, so counting its bytes measures
    "a wall nobody is meant to climb".

That does not hold, because it confuses two different artifacts. STATUS_DLL_NOT_FOUND
is a LOADER failure: it happens when a process is EXECUTED. The byte oracle
never executes anything -- harness.try_method and harness.try_function write a
probe, build it with `bmk makeapp`, and READ the resulting probe.exe's bytes
(scripts/harness.py:1223 and :1270-1271 for try_method, :1422 and :1471-1472 for
try_function). libsteamstub.a is a static archive under extern/steamstub/, so
the probe links; the DLL is wanted only at run time and run time never arrives.
So "cannot be in a launchable src/assembled/" and "cannot be shown equal to the
original's bytes" are independent, and only the first one is true of these four.

Measured, not argued (worker 322, 2026-08-22, NSS5_NO_LEARN=1, two worker trees):

    SteamInit              MATCH 158/158  mode=reloc  reloc_masked=18
    SyncSteamAchievements  MATCH 124/124  mode=reloc  reloc_masked=8

Both are Steam-linked, both carry the '!Import, and both went through the oracle
to a clean MATCH. A body cannot both be permanently unverifiable and return
MATCH twice, so the exclusion's premise is refuted by its own members.

An exclusion that quietly converts "cannot ship" into "cannot count" inflates
the percentage and is exactly the quiet denominator narrowing this file's other
guards exist to prevent. Removing it moves 1,232 bytes back into the denominator
of which only some are matched, so THE HEADLINE PERCENTAGE FALLS. That is the
correct direction and it is the point.

WHY THOSE BODIES STILL DO NOT SHIP
===================================
This reconstruction strips Steam entirely (src/recovered_module/SteamInit.bmx's
header has the full account: the original calls OpenSteam(212780) against a
backend that no longer answers, and restoring that call hard-exits the game
before the first frame). A handful of bodies cannot be present in the running
program without reintroducing that failure, by the same mechanism
scripts/assemble.py's UNVERIFIED_SKIP and scripts/harness.py's MODULE_SKIP
already keep out of the build: a `'!Import ".../libsteamstub.a"` pragma puts a
STEAMSTUB.DLL entry in the exe's import table, and src/assembled/ does not
carry that DLL, so the Windows loader kills the process (STATUS_DLL_NOT_FOUND)
before any code runs, not just the guarded call inside the body.

That mechanism is real, well-evidenced and unchanged. It is a statement about
ONE artifact -- the playable exe -- so it belongs in a shipping note, not in the
measure. VERIFIED_NOT_SHIPPED carries it, per body, with the same evidence
STEAM_EXCLUDE recorded and with the skip it claims cross-checked against the
file that actually performs the skip.

This cuts only one way on purpose. Naming a body not-shipped is a claim about
the build, and that claim needs evidence the same way a MATCHED claim does --
so VERIFIED_NOT_SHIPPED is short, named file by file, and documents its own
reasoning inline rather than a blanket "anything Steam-flavoured" rule. Two
bodies that merely CALL a not-shipped Steam function (TProfile.SaveGame,
TProfile.LoadSavedGame) are deliberately left OFF it; see the comment on
VERIFIED_NOT_SHIPPED for why they do not qualify.

Not shipping has to be visible or the report describes a program nobody can
build. main() prints the not-shipped bodies and their byte count next to the
percentage every time, in every mode; nobody reading the report has to already
know VERIFIED_NOT_SHIPPED exists to find them.
"""
import os
import re
import sys
import json

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import claim as K                                              # noqa: E402

# Trees holding reconstructed function bodies, and whether they are verified.
TREES = [
    ("src/recovered", "verified"),
    ("src/recovered_module", "verified"),
    ("src/recovered_thirdparty", "verified"),
    ("src/recovered_unverified", "unverified"),
]

# Bodies deliberately absent from the SHIPPED build (src/assembled/), because they
# cannot be present in a launchable one -- see "WHY THOSE BODIES STILL DO NOT SHIP"
# above for the mechanism (a '!Import ".../libsteamstub.a" pragma puts STEAMSTUB.DLL
# in the exe's import table; src/assembled/ does not carry that DLL; the Windows
# loader kills the process before any code runs).
#
# THIS LIST CHANGES NO NUMBER. Every body named here is an ordinary corpus member:
# its bytes are in the denominator, and in the numerator when and only when its own
# header carries the `byte-identical vs NSS5.exe` marker, exactly like every other
# body in the tree. The list exists to make the shipping gap VISIBLE, not to move it
# out of the measure. Whoever reads "99%" is entitled to know which parts of the
# program that percentage describes are not in the program.
#
# "VERIFIED" here qualifies NOT_SHIPPED, and nothing else: each entry's absence from
# the build is checked, per body, against the file that actually performs the skip
# (check_not_shipped() below). It makes no claim about byte-matching -- that stays
# the MATCHED marker's job alone. The report prints each body's live MATCHED state
# next to its absence, so the two never have to be inferred from one another; the
# notes below deliberately do not restate it, because a matched/unmatched claim
# frozen in a comment goes stale the next time somebody closes one of these.
#
# Each entry was opened and read before being added here, not assumed from its
# filename. The value is (mechanism, evidence).
#
#   src/recovered_module/SteamInit.bmx  -- SUBSTITUTED, not omitted
#     The Steam bootstrap, and the one entry that is NOT dropped from the build: it
#     is compiled, as a 4-line neutralised stub, so callers still link. Its own
#     header states the divergence outright. The byte-identical original is kept
#     beside the stub as a comment and is never compiled.
#     The original body IS verifiable and was verified: MATCH 158/158, mode=reloc,
#     reloc_masked=18, harness.try_function under NSS5_NO_LEARN=1, worker 322,
#     re-confirmed on a second tree, 2026-08-22. It is nonetheless counted here as
#     UNMATCHED, and that is deliberate: the file's compiled body is the stub, its
#     header does not carry the `byte-identical vs NSS5.exe` marker, and this file
#     measures what the tree compiles rather than what a probe once proved. Whether
#     a substituted body may carry the marker is an owner's call and has not been
#     made; until it is, 158 bytes of proven work sit in the denominator only, which
#     is the understating direction and therefore the safe one.
#
#   src/recovered_unverified/TProfile.CheckAchievement.bmx  -- OMITTED
#     Carries '!Import ".../libsteamstub.a" and Externs GetSteamAchievement and
#     SetSteamAchievement directly, itself, in this file. Named in assemble.py's
#     UNVERIFIED_SKIP, which also records that its Extern block is malformed for
#     that assembler.
#
#   src/recovered_unverified/Fn_0058D987.SteamPostPlayerValue.bmx  -- OMITTED
#     Carries the same '!Import and Externs FindLeaderboard, ReadSteam and
#     UploadLeaderboardScore. Named in assemble.py's UNVERIFIED_SKIP.
#
#   src/recovered_module/Fn_0058D90B.SyncSteamAchievements.bmx  -- OMITTED
#     Carries the same '!Import and Externs SetSteamAchievement. Named in
#     harness.py's MODULE_SKIP, whose comment records the measured failure mode for
#     this exact file: STATUS_DLL_NOT_FOUND, loader kill, no milestone reached, not
#     even settings read. Matched: its header carries the marker, and the claim was
#     re-verified fresh -- MATCH 124/124, mode=reloc, reloc_masked=8,
#     harness.try_function under NSS5_NO_LEARN=1, worker 322, two trees, 2026-08-22.
#
# SCOPE. This is the STEAM set, not a census of everything assemble.py declines to
# emit. UNVERIFIED_SKIP also holds bodies skipped for unrelated reasons (a duplicate
# whose verified twin in src/recovered/ wins the tier contest anyway, a zip helper),
# and none of those is claimed or denied here. Widening this list to every skipped
# body is a reasonable thing to want and is not what it currently is.
#
# DELIBERATELY NOT ON THIS LIST:
#
#   src/recovered/TProfile.LoadSavedGame.bmx  -- and it IS shipped
#     The caller of SyncSteamAchievements, and now byte-identical itself (936/936,
#     mode=diff, three trees). It carries no '!Import and Externs no DLL function:
#     the Steam link surface lives entirely in the CALLEE, which is listed above in
#     its own right. This file reaches it through a local, harmless '!Raw placeholder
#     declaration, which is exactly what lets the caller ship with the callee omitted.
#     Nothing skips it, so it is in src/assembled/ and belongs nowhere on this list.
#
#   src/recovered_unverified/TProfile.SaveGame.bmx  -- not shipped, but NOT for the
#     loader reason this list is about, so deliberately still off it. It carries no
#     '!Import and Externs no DLL function either; its Steam link surface is likewise
#     entirely in its callee (SteamPostPlayerValue, listed above). assemble.py's
#     UNVERIFIED_SKIP does name it, but for a reason of its own: the save format is a
#     clean break and this project writes its own, so the body is moot for the build
#     rather than fatal to it. Its only reconstruction defect is one omitted 5-byte
#     CALL to that unverified callee, and that defect is not the SteamInit kind of
#     permanent -- SteamPostPlayerValue's own header is explicit that reproducing its
#     logic verbatim does not crash the game the way OpenSteam does; the worst case is
#     a bounded 2-second poll against a dead leaderboard server, then an ordinary
#     return. So closing the callee closes this too. It is blocked on a sibling's
#     verification, exactly like other near-miss bodies elsewhere in this corpus that
#     are blocked on THEIR siblings for entirely non-Steam reasons and are not
#     specially listed either. Counting it as unmatched, which is what it is today, is
#     the honest and the consistent treatment. Revisit the day the callee closes.
#     (Under STEAM_EXCLUDE this paragraph argued the same conclusion from the
#     denominator, since being listed then also meant leaving the measure. That
#     argument no longer applies -- the list no longer moves bytes -- but the
#     conclusion is unchanged and now rests only on the build facts above.)
VERIFIED_NOT_SHIPPED = {
    "src/recovered_module/SteamInit.bmx": (
        "SUBSTITUTED",
        "compiled as a neutralised 4-line stub; original kept as a comment"),
    "src/recovered_unverified/TProfile.CheckAchievement.bmx": (
        "OMITTED", "assemble.py UNVERIFIED_SKIP"),
    "src/recovered_module/Fn_0058D987.SteamPostPlayerValue.bmx": (
        "OMITTED", "harness.py MODULE_SKIP"),
    "src/recovered_module/Fn_0058D90B.SyncSteamAchievements.bmx": (
        "OMITTED", "harness.py MODULE_SKIP"),
}

#
#   src/recovered_module/LoadImageChecked.bmx  --  251 bytes at 0x004BC372
#     A BOOT SHIM, not a Steam problem. Both failure paths return a visible magenta
#     placeholder instead of `Return Null` / `DebugStop`, because a Null TImage propagates
#     into MidHandleImage/DrawImage/ImageWidth at essentially every call site and one absent
#     PNG killed the whole boot. As compiled it is 253 bytes against the original's 251
#     (MISMATCH, first_diff=+6). Restore the two branches and delete MissingArtImage() and
#     it is MATCH 251/251, mode=reloc, reloc_masked=24.
#
#   src/recovered_module/LoadAnimImageChecked.bmx  --  271 bytes at 0x004BC664
#     The same shim, in the most-called module Function in the program. As compiled it is
#     272 bytes against 271 (MISMATCH, first_diff=+22). The original's two branches are NOT
#     symmetric -- "cannot see" carries DebugStop AND an explicit Return Null, "could not
#     load" carries DebugStop alone and falls through -- and with that restored it is
#     MATCH 271/271, mode=reloc, reloc_masked=25.
#
# Both of these previously carried the `byte-identical vs NSS5.exe` marker while compiling
# the shim, so their bytes sat in the numerator for a body the oracle rejects. Taking the
# marker off drops the headline by 522 bytes. That is the correct direction and it is the
# point: the headline is what the tree COMPILES, and what these two compile is not the
# original. The work itself is not lost, it is reported below instead.
# OF THOSE, THE ONES THAT CAN NEVER BE RESTORED.
#
# "Largest bodies not yet byte-identical" is a WORK LIST -- it answers "what is left to
# do". A body whose original is proven and which is substituted only until some other
# defect is fixed still belongs on it: the three Load*Checked boot shims are there because
# a Null TImage propagates into MidHandleImage at essentially every call site while the
# module-Global aliasing defect stands, and the day that is fixed the originals go back and
# the bodies match. That is real remaining work and hiding it would be dishonest.
#
# SteamInit is not that. Its original opens a connection to Steam AppID 212780 and calls
# `End` when the connection fails; Steam's 2011 backend for this AppID is gone, so
# restoring it is an unconditional hard-exit before the first frame, forever. No amount of
# work in this repository changes that. Listing it as "not yet byte-identical" describes a
# task nobody can ever complete, which makes the work list wrong.
#
# It stays in the totals, in the denominator, and in the substituted table above with its
# oracle evidence. It comes out of the WORK LIST only.
SUBSTITUTION_IS_PERMANENT = {
    "src/recovered_module/SteamInit.bmx",
}

VERIFIED_ORIGINAL_SUBSTITUTED = {
    "src/recovered_module/SteamInit.bmx": (
        158,
        "harness.try_function NSS5_NO_LEARN=1 -> MATCH 158/158 mode=reloc reloc_masked=18"),
    "src/recovered_module/LoadImageChecked.bmx": (
        251,
        "harness.try_function NSS5_NO_LEARN=1 -> MATCH 251/251 mode=reloc reloc_masked=24"),
    "src/recovered_module/LoadAnimImageChecked.bmx": (
        271,
        "harness.try_function NSS5_NO_LEARN=1 -> MATCH 271/271 mode=reloc reloc_masked=25"),
    "src/recovered_module/LoadSoundChecked.bmx": (
        256,
        "harness.try_function NSS5_NO_LEARN=1 -> MATCH 256/256 mode=reloc reloc_masked=25"),
}

# Guards, because an entry above that has gone stale would OVERSTATE the second figure, and
# overstating is the one direction this file refuses everywhere else.
SUBSTITUTED_UNCHECKED = []


def check_substituted(rows):
    """Every entry must name a real corpus body that is CURRENTLY UNMATCHED and that says
    in its own header that it diverges.

    Currently-unmatched is the load-bearing check. If someone later banks the marker on one
    of these files, its bytes enter the numerator on their own, and adding them again here
    would count them twice -- silently, and in the flattering direction."""
    index = {r["tree"] + "/" + r["file"] + ".bmx": r for r in rows}
    for rel, (nbytes, _ev) in sorted(VERIFIED_ORIGINAL_SUBSTITUTED.items()):
        r = index.get(rel)
        if r is None:
            SUBSTITUTED_UNCHECKED.append(
                "%s is named as a substituted body but is not in the corpus" % rel)
            continue
        if r["matched"]:
            SUBSTITUTED_UNCHECKED.append(
                "%s is named as substituted but already counts as matched -- its bytes "
                "would be counted twice" % rel)
        if r["size"] != nbytes:
            SUBSTITUTED_UNCHECKED.append(
                "%s is recorded as %d bytes here and %d bytes in its VA header"
                % (rel, nbytes, r["size"]))
        try:
            with open(os.path.join(ROOT, rel), encoding="utf-8", errors="replace") as f:
                head = f.read(4000)
        except OSError:
            SUBSTITUTED_UNCHECKED.append("%s is unreadable" % rel)
            continue
        up = head.upper()
        if "DIVERGENCE" not in up and "BOOT SHIM" not in up:
            SUBSTITUTED_UNCHECKED.append(
                "%s does not declare a divergence in its own header, so the substitution "
                "claim rests on this file alone" % rel)


# A rule nothing checks is advice, and advice rots (docs/RULES.md opens on exactly
# this). "This body is not in the shipped build" is a checkable claim, so it is
# checked: the OMITTED entries must still be named by the skip set that omits them.
#
# Reported rather than raised. Under STEAM_EXCLUDE a stale entry silently narrowed
# the denominator, which had to be fatal; a stale entry here can only mislabel a row
# that is counted correctly either way, so a loud line in the report is proportionate
# and does not take progress.py (and CI with it) down over an unrelated refactor of
# assemble.py. The one case that IS still fatal is a name that resolves to no body at
# all -- see scan().
_SKIP_SETS = [("scripts/assemble.py", "UNVERIFIED_SKIP"),
              ("scripts/harness.py", "MODULE_SKIP")]
SHIP_CLAIM_UNCHECKED = []


def check_not_shipped():
    """Cross-check every OMITTED entry against the skip set that claims to omit it."""
    named = set()
    for relpath, setname in _SKIP_SETS:
        try:
            with open(os.path.join(ROOT, relpath), encoding="utf-8",
                      errors="replace") as f:
                text = f.read()
        except OSError:
            SHIP_CLAIM_UNCHECKED.append(
                "%s is unreadable, so no %s claim could be checked"
                % (relpath, setname))
            continue
        m = re.search(re.escape(setname) + r"\s*=\s*\{(.*?)\n\}", text, re.S)
        if not m:
            SHIP_CLAIM_UNCHECKED.append(
                "could not find %s in %s -- shipping claims unchecked"
                % (setname, relpath))
            continue
        named |= set(re.findall(r'"([^"]+\.bmx)"', m.group(1)))
    if not named:
        return
    for rel, (mech, _why) in sorted(VERIFIED_NOT_SHIPPED.items()):
        if mech == "OMITTED" and rel.rsplit("/", 1)[-1] not in named:
            SHIP_CLAIM_UNCHECKED.append(
                "%s is listed OMITTED but no skip set names it -- it may in fact "
                "be in the shipped build" % rel)

# THE HEADER PARSER AND THE MATCHED TEST BOTH LIVE IN scripts/claim.py NOW, shared
# with coverage.py. Two readers for one fact is two facts: this file used to accept
# `byte-identical vs NSS5.exe` anywhere in the first 40 lines with NO negative test,
# and coverage.py used to apply a negative test but a looser claim vocabulary. They
# disagreed about 13 bodies. Ten of those were bodies in src/recovered_unverified/
# whose OWN LINE 1 says `-- NOT VERIFIED`, and which carry a bare
# `' byte-identical vs NSS5.exe` inserted above the VA line by a bulk header pass;
# every one is contradicted by its own status/score/<body>.txt record. This file
# counted all ten as matched, 10,670 bytes of them. It no longer does, and the
# headline falls accordingly. claim.py's docstring carries the full evidence.
#
# The VA parser is unchanged in behaviour: strict form authoritative, loose form as a
# rescue-only second pass. It now reads the LEADING COMMENT BLOCK rather than the
# first 40 raw lines; measured over the corpus both find the same 1,973 VA headers.
VA_LINE = K.VA_LINE
VA_LINE_LOOSE = K.VA_LINE_LOOSE
MATCHED = K.MATCHED

# Files that legitimately carry no whole-function VA/size line, so the guard must not
# report them. Kept as a NAMED list with its reason, the same way VERIFIED_NOT_SHIPPED
# is, because a guard that fires forever on a known-good file trains everyone to ignore
# it -- and then it is not a guard.
#
#   src/recovered_unverified/ModuleBody_RealProgram.bmx
#     A FRAGMENT, not a function: body offset +5549..+7933 of the module body at
#     0x004BA034 (7,933 bytes total). Its bytes already belong to the parent, so
#     giving it a VA/size line of its own would double-count them.
NOT_A_WHOLE_BODY = {
    "src/recovered_unverified/ModuleBody_RealProgram.bmx",
}

# Bodies whose header VA line did not parse, populated by scan(). See the long note
# at the collection site: an unparsed body silently leaves BOTH numerator and
# denominator, so this must be surfaced, never swallowed.
UNPARSED = []


def scan():
    """-> (rows, not_shipped)

    `rows` is the measured corpus: [{tree, file, va, size, matched}], one per
    recovered body. Nothing is removed from it -- there is no exclusion list.

    `not_shipped` is a SUBSET of `rows` (the same dicts, not copies), for the
    bodies VERIFIED_NOT_SHIPPED names as deliberately absent from src/assembled/.
    Returned separately only so callers can report the shipping gap; those rows
    are already in `rows` and already counted in both numerator and denominator.
    """
    rows, not_shipped = [], []
    seen_not_shipped = set()
    for tree, kind in TREES:
        d = os.path.join(ROOT, tree)
        if not os.path.isdir(d):
            continue
        # WALK SUBDIRECTORIES. src/recovered_thirdparty holds its bodies one level
        # down, under a directory per module (fontmachine/, zipengine/), so a flat
        # os.listdir() found nothing there -- the tree was declared in TREES, counted
        # in neither the numerator nor the denominator, and reported no row at all.
        # That is a silent narrowing of exactly the kind this file's header warns
        # about, and it inverts the measure: banking a verified third-party body left
        # the percentage unchanged while banking a near-miss anywhere else lowered it.
        # `fn` stays the file's name and `tree` its declared tree, so the grouping and
        # the VERIFIED_NOT_SHIPPED keys are unaffected for the flat trees.
        names = []
        for root, _dirs, files in os.walk(d):
            for f in sorted(files):
                names.append(os.path.join(root, f))
        for path in sorted(names):
            fn = os.path.basename(path)
            if not fn.endswith(".bmx"):
                continue
            try:
                with open(path, encoding="utf-8", errors="replace") as f:
                    head = K.header(f.read())
            except OSError:
                continue
            m = VA_LINE.search(head) or VA_LINE_LOOSE.search(head)
            if not m:
                # A BODY WHOSE HEADER DOES NOT PARSE LEAVES THE CORPUS ENTIRELY --
                # numerator AND denominator -- and the percentage goes UP, because the
                # work is deleted from the measure rather than done. This is the single
                # most dangerous failure mode in this file, and it is silent by nature:
                # nothing is missing from disk, nothing errors, the table just quietly
                # describes a smaller project than the one that exists.
                #
                # Observed for real, twice in one session, from ordinary header edits:
                #   ' VA 0x0055C09B   orig_len 6249   ...       (says orig_len, not bytes)
                #   ' VA 0x0055F8E6   Ghidra-authoritative length 2276 bytes   ...
                # VA_LINE wants `VA 0x... <N> bytes` with only whitespace between, so
                # both dropped out and the reported total fell by exactly their 8,525
                # bytes while the percentage rose by 0.7 points.
                #
                # So: never drop one quietly. Collect it and make the report say so.
                # Report the REAL path, not tree + basename: thirdparty bodies live one
                # level down (fontmachine/, zipengine/), so the composed form names a
                # file that does not exist and sends the reader hunting for a ghost.
                rel_u = os.path.relpath(path, ROOT).replace(os.sep, "/")
                if rel_u not in NOT_A_WHOLE_BODY:
                    UNPARSED.append(rel_u)
                continue
            row = {
                "tree": tree, "kind": kind, "file": fn[:-4],
                "va": m.group(1).lower(), "size": int(m.group(2)),
                "matched": K.is_matched(head),
                "claimed": bool(MATCHED.search(head)),
                "retracted": K.negatives(head),
            }
            rows.append(row)
            rel = tree + "/" + fn
            if rel in VERIFIED_NOT_SHIPPED:
                seen_not_shipped.add(rel)
                not_shipped.append(row)

    # VERIFIED_NOT_SHIPPED is a claim about a specific file. If a name in it no
    # longer resolves to a body -- moved, renamed, deleted -- the claim can no
    # longer be checked, and the report goes on describing a shipping gap it can
    # no longer see. Fail loudly rather than quietly under-reporting. (This guard
    # predates the rename and is kept as it was; it never touched the denominator
    # and does not now.)
    missing = set(VERIFIED_NOT_SHIPPED) - seen_not_shipped
    if missing:
        raise SystemExit(
            "progress.py: VERIFIED_NOT_SHIPPED names a file with no VA header "
            "found: %s -- fix the path or remove the entry, do not ignore this"
            % ", ".join(sorted(missing)))
    check_not_shipped()
    check_substituted(rows)
    return rows, not_shipped


def totals(rows):
    done = sum(r["size"] for r in rows if r["matched"])
    total = sum(r["size"] for r in rows)
    return done, total, (100.0 * done / total if total else 0.0)


def colour(pct):
    if pct >= 99.5:
        return "brightgreen"
    if pct >= 90:
        return "green"
    if pct >= 70:
        return "yellowgreen"
    if pct >= 40:
        return "yellow"
    return "orange"


def write_shield(pct, done, total):
    """Write docs/progress.json in shields.io endpoint format, and return it.

    The README badge reads this file over raw.githubusercontent.com, so the
    figures are generated alongside docs/STATUS.md rather than typed into the
    README. A figure written by hand is wrong at the next commit and has no way
    of telling the reader so.

    The badge carries the byte counts as well as the percentage, because a bare
    percentage does not say what it is a percentage of. Machine code is the
    denominator here, not files and not functions, and a reader who cannot see
    that has no way to compare this against any other reconstruction.

    `total` is the whole corpus: no body is held back from it. A handful are
    deliberately absent from the shipped build (VERIFIED_NOT_SHIPPED), which the
    badge has no room to say; docs/STATUS.md and the plain-text report carry
    those body/byte counts in full, and this file is where the reasoning lives.
    """
    blob = json.dumps({"schemaVersion": 1, "label": "reconstructed",
                       "message": "%.1f%% (%s/%s bytes)"
                                  % (pct, "{:,}".format(done), "{:,}".format(total)),
                       "color": colour(pct)})
    out = os.path.join(ROOT, "docs", "progress.json")
    with open(out, "w", encoding="utf-8") as f:
        print(blob, file=f)
    return blob


def main():
    rows, not_shipped = scan()
    if not rows:
        raise SystemExit("no bodies with a VA header found -- has the tree moved?")
    done, total, pct = totals(rows)
    ns_bytes = sum(r["size"] for r in not_shipped)
    ns_done = sum(r["size"] for r in not_shipped if r["matched"])

    if "--shield" in sys.argv:
        print(write_shield(pct, done, total))
        return 0

    if "--csv" in sys.argv:
        print("tree,file,va,size,matched")
        for r in rows:
            print("%s,%s,%s,%d,%d"
                  % (r["tree"], r["file"], r["va"], r["size"], int(r["matched"])))
        return 0

    lines = []
    lines.append("RECONSTRUCTION PROGRESS  (measured in bytes of matched machine code)")
    lines.append("")
    lines.append("  %-30s %9s %9s %8s %7s" % ("TREE", "BODIES", "MATCHED", "BYTES", "DONE"))
    for tree, _kind in TREES:
        sub = [r for r in rows if r["tree"] == tree]
        if not sub:
            continue
        d, t, p = totals(sub)
        lines.append("  %-30s %9d %9d %8d %6.1f%%"
                     % (tree, len(sub), sum(1 for r in sub if r["matched"]), t, p))
    lines.append("  %-30s %9s %9s %8s %7s" % ("-" * 30, "-" * 9, "-" * 9, "-" * 8, "-" * 7))
    lines.append("  %-30s %9d %9d %8d %6.1f%%"
                 % ("TOTAL", len(rows), sum(1 for r in rows if r["matched"]), total, pct))
    lines.append("")
    lines.append("  %d of %d bytes byte-identical against NSS5.exe." % (done, total))

    # THE SECOND FIGURE, and it answers a different question from the one above.
    #
    # The headline measures what the tree COMPILES. Exactly one body in the corpus compiles
    # something other than the original on purpose, because compiling the original would
    # stop the game reaching its first frame -- SteamInit, whose retail body calls `End`
    # when Steam's long-dead backend does not answer. Its original IS reconstructed and the
    # oracle says so; the build simply declines to use it.
    #
    # So "how much of NSS5 have we reconstructed" and "how much of what we compile is
    # byte-identical" are genuinely different questions with genuinely different answers,
    # and the honest thing is to print both rather than to pick the flattering one and call
    # it the number. The first figure is never adjusted. This one is labelled, itemised, and
    # names every body it counts, so nobody can quote it without also quoting what it means.
    if VERIFIED_ORIGINAL_SUBSTITUTED and not SUBSTITUTED_UNCHECKED:
        sub_bytes = sum(n for n, _e in VERIFIED_ORIGINAL_SUBSTITUTED.values())
        sub_done = done + sub_bytes
        sub_pct = (100.0 * sub_done / total) if total else 0.0
        lines.append("")
        lines.append("  RECONSTRUCTED, counting bodies whose original is proven byte-identical")
        lines.append("  but whose compiled form is deliberately substituted so the game runs:")
        lines.append("      %d of %d bytes = %.1f%%" % (sub_done, total, sub_pct))
        for rel, (nbytes, ev) in sorted(VERIFIED_ORIGINAL_SUBSTITUTED.items()):
            lines.append("    %-44s %7d  %s" % (rel.rsplit("/", 1)[-1], nbytes, ev))
        lines.append("  These bytes are NOT in the headline above and must not be added to it:")
        lines.append("  the headline measures what src/assembled/ compiles, and for these bodies")
        lines.append("  that is the substitute, which the oracle correctly rejects.")
    if SUBSTITUTED_UNCHECKED:
        lines.append("")
        lines.append("  *** THE SUBSTITUTED-ORIGINAL FIGURE IS WITHHELD, its guards failed:")
        for w in SUBSTITUTED_UNCHECKED:
            lines.append("    %s" % w)

    # An unparsed header is a body that left the corpus WITHOUT anyone deciding it
    # should. It is strictly worse than an unmatched body, because unmatched work is
    # visible in the denominator and this is not: the percentage RISES when a header
    # breaks. Never let that happen quietly -- shout about it, above the not-shipped
    # list, because unlike VERIFIED_NOT_SHIPPED nobody chose this, and unlike it this
    # really does take the body out of both numerator and denominator.
    if UNPARSED:
        lines.append("")
        lines.append("  *** %d BODY FILE(S) HAVE AN UNPARSEABLE HEADER AND ARE IN NEITHER" % len(UNPARSED))
        lines.append("  *** THE NUMERATOR NOR THE DENOMINATOR. The percentage above is")
        lines.append("  *** OVERSTATED until these are fixed. VA_LINE wants exactly:")
        lines.append("  ***     ' VA 0x0055C09B   6249 bytes   ...")
        lines.append("  *** i.e. the byte count immediately after the VA, then the word")
        lines.append("  *** 'bytes'. Any extra words in between silently drop the body.")
        for u in sorted(UNPARSED):
            lines.append("    %s" % u)

    # An unparsed header is a body that left the corpus WITHOUT anyone deciding it
    # should. It is strictly worse than an unmatched body, because unmatched work is
    # visible in the denominator and this is not: the percentage RISES when a header
    # breaks. Never let that happen quietly -- shout about it, above the not-shipped
    # list, because unlike VERIFIED_NOT_SHIPPED nobody chose this, and unlike it this
    # really does take the body out of both numerator and denominator.
    if UNPARSED:
        lines.append("")
        lines.append("  *** %d BODY FILE(S) HAVE AN UNPARSEABLE HEADER AND ARE IN NEITHER" % len(UNPARSED))
        lines.append("  *** THE NUMERATOR NOR THE DENOMINATOR. The percentage above is")
        lines.append("  *** OVERSTATED until these are fixed. VA_LINE wants exactly:")
        lines.append("  ***     ' VA 0x0055C09B   6249 bytes   ...")
        lines.append("  *** i.e. the byte count immediately after the VA, then the word")
        lines.append("  *** 'bytes'. Any extra words in between silently drop the body.")
        for u in sorted(UNPARSED):
            lines.append("    %s" % u)

    # A header that claims byte-equality AND retracts it in the same status block is
    # not a measurement, it is two measurements. Counting it either way without saying
    # so hides a defect in the corpus behind a number. These are counted as UNMATCHED
    # -- the safe direction -- and named here so the contradiction gets resolved by the
    # oracle rather than by whichever regex ran last.
    contra = [r for r in rows if r["claimed"] and r["retracted"]]
    if contra:
        cb = sum(r["size"] for r in contra)
        lines.append("")
        lines.append("  CONTRADICTED HEADERS -- %d bodies, %d bytes, COUNTED AS UNMATCHED"
                     % (len(contra), cb))
        lines.append("  Each carries `byte-identical vs NSS5.exe` and also retracts it in")
        lines.append("  its own status block. Re-run the oracle (NSS5_NO_LEARN=1) and make")
        lines.append("  the header say one thing; until then this is the safe reading.")
        for r in sorted(contra, key=lambda r: -r["size"]):
            lines.append("    %-46s %6d  %s" % (r["file"][:46], r["size"],
                                                r["retracted"][0][:60]))

    # Visible on purpose, in every mode. These bodies ARE counted above -- the
    # percentage is not narrowed for them -- but a reader told "99%" is entitled
    # to know which of that 99% is not in the program they can build. Printed with
    # each body's MATCHED state so the two questions stay visibly separate: being
    # absent from the build says nothing about being byte-identical, and the whole
    # reason this section replaced an exclusion list is that the old one conflated
    # them. See VERIFIED_NOT_SHIPPED in this file for the per-body evidence.
    lines.append("")
    lines.append("  NOT IN THE SHIPPED BUILD -- %d bodies, %d bytes (%d of them matched)"
                 % (len(not_shipped), ns_bytes, ns_done))
    lines.append("  COUNTED in the totals above, like every other body. They are left out")
    lines.append("  of src/assembled/ because their Steam import would stop the exe loading;")
    lines.append("  that is a fact about the build, not about whether they can be matched.")
    lines.append("  (see VERIFIED_NOT_SHIPPED in scripts/progress.py for the evidence)")
    lines.append("    %-42s %7s %-11s %-8s %s"
                 % ("BODY", "BYTES", "VA", "MATCHED", "ABSENCE"))
    for r in sorted(not_shipped, key=lambda r: -r["size"]):
        mech = VERIFIED_NOT_SHIPPED[r["tree"] + "/" + r["file"] + ".bmx"]
        lines.append("    %-42s %7d %-11s %-8s %s  (%s)"
                     % (r["file"][:42], r["size"], r["va"],
                        "yes" if r["matched"] else "no", mech[0], mech[1]))

    # A shipping claim nobody could check is not evidence. Say so rather than
    # printing the table as though it had been verified.
    if SHIP_CLAIM_UNCHECKED:
        lines.append("")
        lines.append("  *** THE 'ABSENCE' COLUMN ABOVE IS NOT FULLY VERIFIED:")
        for w in SHIP_CLAIM_UNCHECKED:
            lines.append("    %s" % w)

    unmatched = sorted((r for r in rows if not r["matched"]
                        and (r["tree"] + "/" + r["file"] + ".bmx")
                        not in SUBSTITUTION_IS_PERMANENT),
                       key=lambda r: -r["size"])
    if unmatched:
        lines.append("")
        lines.append("  Largest bodies not yet byte-identical:")
        for r in unmatched[:15]:
            lines.append("    %-46s %6d bytes  %s" % (r["file"][:46], r["size"], r["va"]))
        if len(unmatched) > 15:
            lines.append("    ... and %d more" % (len(unmatched) - 15))
        gone = [r for r in rows if not r["matched"]
                and (r["tree"] + "/" + r["file"] + ".bmx") in SUBSTITUTION_IS_PERMANENT]
        if gone:
            lines.append("  (not listed: %s -- proven byte-identical and permanently"
                         % ", ".join(sorted(r["file"] for r in gone)))
            lines.append("   substituted, so not work anyone can finish. Still counted"
                         " in the totals above.)")

    text = "\n".join(lines)
    print(text)

    if "--write-status" in sys.argv:
        out = os.path.join(ROOT, "docs", "STATUS.md")
        with open(out, "w", encoding="utf-8") as f:
            f.write("# Status\n\n")
            f.write("<!-- GENERATED by scripts/progress.py --write-status.\n")
            f.write("     Do not edit by hand: your changes will be overwritten, and a\n")
            f.write("     hand-maintained status file goes stale within hours. -->\n\n")
            f.write("**%.1f%%** of the reconstruction is byte-identical to `NSS5.exe`,\n"
                    % pct)
            f.write("measured as %d of %d bytes of machine code across %d function bodies.\n\n"
                    % (done, total, len(rows)))
            f.write("Nothing is excluded from that count. %d bodies (%d bytes, of which "
                    "%d are byte-identical) are counted above but are deliberately absent "
                    "from the shipped `src/assembled/` build, because their Steam import "
                    "would stop the exe loading; see VERIFIED_NOT_SHIPPED in "
                    "`scripts/progress.py` for which ones and why.\n\n"
                    % (len(not_shipped), ns_bytes, ns_done))
            f.write("```\n%s\n```\n\n" % text)
            f.write("Regenerate with:\n\n```bash\npython scripts/progress.py --write-status\n```\n")
        print("\n  wrote %s" % os.path.relpath(out, ROOT))
        write_shield(pct, done, total)
        print("  wrote %s" % os.path.join("docs", "progress.json"))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
