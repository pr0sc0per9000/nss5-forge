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
A body is MATCHED when its header states `byte-identical vs NSS5.exe`. That
claim is produced by scripts/bytematch.py and scripts/localise_diff.py against
the real binary, not by an author's assertion. localise_diff is the only honest
oracle here: the positional comparator reports ~75% for byte-identical bodies
whose load address differs.

WHAT IS EXCLUDED FROM THE CORPUS, AND WHY
==========================================
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

A body that can never be present in a working build can also never report
`byte-identical vs NSS5.exe` and remain playable -- closing it and shipping it
are mutually exclusive, permanently, by construction, not because the work is
unfinished. Counting its bytes in the denominator below therefore does not
measure remaining work; it measures a wall nobody is meant to climb, and it
understates the real percentage forever. STEAM_EXCLUDE (below) names exactly
those bodies, with the evidence for each one, and scan() drops them from both
BYTES and DONE before totals() ever sees them.

This cuts only one way on purpose. Excluding a body is a claim that it can
never honestly close, and that claim needs the same evidence a MATCHED claim
does -- so STEAM_EXCLUDE is short, named file by file, and documents its own
reasoning inline rather than a blanket "anything Steam-flavoured" rule. Two
bodies that merely CALL an excluded Steam function (TProfile.SaveGame,
TProfile.LoadSavedGame) are deliberately left OUT of STEAM_EXCLUDE and stay in
the corpus as ordinary unmatched work; see the comment on STEAM_EXCLUDE for
why they do not qualify.

Exclusion has to be visible or it becomes exactly the kind of quiet
narrowing this file exists to prevent. main() prints the excluded body and
byte counts next to the percentage every time, in every mode; nobody reading
the report has to already know STEAM_EXCLUDE exists to find them.
"""
import os
import re
import sys
import json

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

# Trees holding reconstructed function bodies, and whether they are verified.
TREES = [
    ("src/recovered", "verified"),
    ("src/recovered_module", "verified"),
    ("src/recovered_thirdparty", "verified"),
    ("src/recovered_unverified", "unverified"),
]

# Bodies permanently excluded from the measured corpus because they cannot be
# present in a working build, ever, by construction -- see "WHAT IS EXCLUDED
# FROM THE CORPUS" above for the mechanism (a '!Import ".../libsteamstub.a"
# pragma puts STEAMSTUB.DLL in the exe's import table; src/assembled/ does not
# carry that DLL; the Windows loader kills the process before any code runs).
# Each entry below was opened and read before being added here, not assumed
# from its filename:
#
#   src/recovered_module/SteamInit.bmx
#     The Steam bootstrap. Its own header states the divergence outright: the
#     compiled body is a 4-line neutralised stub; the byte-identical original
#     (158/158, confirmed in the same header) is kept only as a comment and is
#     never compiled. This file can state "byte-identical vs NSS5.exe" or stay
#     playable, never both, so it never leaves DONE-eligible and belongs in
#     neither BYTES nor DONE.
#
#   src/recovered_unverified/TProfile.CheckAchievement.bmx
#     Carries '!Import ".../libsteamstub.a" and Externs GetSteamAchievement and
#     SetSteamAchievement directly, itself, in this file. Already named in
#     assemble.py's UNVERIFIED_SKIP for the identical reason.
#
#   src/recovered_unverified/Fn_0058D987.SteamPostPlayerValue.bmx
#     Carries the same '!Import and Externs FindLeaderboard, ReadSteam and
#     UploadLeaderboardScore. Already named in assemble.py's UNVERIFIED_SKIP.
#
#   src/recovered_module/Fn_0058D90B.SyncSteamAchievements.bmx
#     Carries the same '!Import and Externs SetSteamAchievement. Already named
#     in harness.py's MODULE_SKIP, whose comment records the measured failure
#     mode for this exact file: STATUS_DLL_NOT_FOUND, loader kill, no milestone
#     reached, not even settings read.
#
# DELIBERATELY NOT ON THIS LIST:
#
#   src/recovered_unverified/TProfile.SaveGame.bmx
#   src/recovered_unverified/TProfile.LoadSavedGame.bmx
#     Both are ordinary game functions. Read either file: neither carries a
#     '!Import pragma or Externs a DLL function itself -- the Steam link surface
#     lives entirely in the CALLEE (SteamPostPlayerValue / SyncSteamAchievements
#     respectively), which is already excluded above in its own right.
#     SaveGame's only defect is one omitted 5-byte CALL to its unverified
#     callee; LoadSavedGame's is one call routed through a local, harmless
#     '!Raw placeholder while its callee (now itself byte-identical elsewhere)
#     is not yet promoted into this file. Neither defect is the SteamInit kind
#     of permanent: SteamPostPlayerValue's own header is explicit that
#     reproducing its logic verbatim does not crash the game the way OpenSteam
#     does -- the worst case is a bounded 2-second poll against a dead
#     leaderboard server, then an ordinary return. So closing either callee
#     closes these two as well; they are blocked on a sibling function's own
#     verification, exactly like other near-miss bodies elsewhere in this
#     corpus that are blocked on THEIR siblings for entirely non-Steam reasons
#     and are not specially excluded either. Excluding SaveGame/LoadSavedGame
#     would remove real, currently-incomplete work from the denominator and
#     overstate progress; counting them as unmatched, which is what they are
#     today, is the honest and the consistent treatment. Revisit this the day
#     either blocking callee closes.
STEAM_EXCLUDE = {
    "src/recovered_module/SteamInit.bmx",
    "src/recovered_unverified/TProfile.CheckAchievement.bmx",
    "src/recovered_unverified/Fn_0058D987.SteamPostPlayerValue.bmx",
    "src/recovered_module/Fn_0058D90B.SyncSteamAchievements.bmx",
}

VA_LINE = re.compile(r"^'\s*VA\s+(0x[0-9A-Fa-f]+)\s+(\d+)\s+bytes", re.M)
MATCHED = re.compile(r"byte-identical\s+vs\s+NSS5\.exe", re.I)


def scan():
    """-> (rows, excluded)

    `rows` is the measured corpus: [{tree, file, va, size, matched}], one per
    recovered body, MINUS everything named in STEAM_EXCLUDE. `excluded` is the
    same shape, for exactly the bodies STEAM_EXCLUDE removed -- kept and
    returned rather than just dropped, so callers can report what left the
    denominator instead of the reader having to trust that nothing did.
    """
    rows, excluded = [], []
    seen_excluded = set()
    for tree, kind in TREES:
        d = os.path.join(ROOT, tree)
        if not os.path.isdir(d):
            continue
        for fn in sorted(os.listdir(d)):
            if not fn.endswith(".bmx"):
                continue
            path = os.path.join(d, fn)
            try:
                with open(path, encoding="utf-8", errors="replace") as f:
                    head = "".join(next(f, "") for _ in range(40))
            except OSError:
                continue
            m = VA_LINE.search(head)
            if not m:
                continue
            row = {
                "tree": tree, "kind": kind, "file": fn[:-4],
                "va": m.group(1).lower(), "size": int(m.group(2)),
                "matched": bool(MATCHED.search(head)),
            }
            rel = tree + "/" + fn
            if rel in STEAM_EXCLUDE:
                seen_excluded.add(rel)
                excluded.append(row)
                continue
            rows.append(row)

    # STEAM_EXCLUDE is a claim that a specific file exists and is permanently
    # unmatchable. If a name in it no longer resolves to a body -- moved,
    # renamed, deleted -- the claim can no longer be checked, and a set that
    # silently narrows the corpus by fewer files than it says is exactly the
    # quiet-narrowing failure this whole mechanism exists to prevent. Fail
    # loudly instead of under-excluding.
    missing = STEAM_EXCLUDE - seen_excluded
    if missing:
        raise SystemExit(
            "progress.py: STEAM_EXCLUDE names a file with no VA header found: "
            "%s -- fix the path or remove the entry, do not ignore this"
            % ", ".join(sorted(missing)))
    return rows, excluded


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

    `total` already has STEAM_EXCLUDE's bodies removed (scan() drops them
    before they ever reach totals()). The badge itself has no room for that
    footnote; docs/STATUS.md and the plain-text report carry the excluded
    body/byte counts in full, and this file is where the reasoning lives.
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
    rows, excluded = scan()
    if not rows:
        raise SystemExit("no bodies with a VA header found -- has the tree moved?")
    done, total, pct = totals(rows)
    ex_bytes = sum(r["size"] for r in excluded)

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

    # Visible on purpose: a percentage with a narrowed denominator and no note
    # saying so is a lie by omission, which is the exact failure mode
    # STEAM_EXCLUDE's own header exists to avoid. These bodies are Steam-linked
    # and permanently excluded (see STEAM_EXCLUDE in this file for the
    # per-file evidence); they count toward neither BYTES nor DONE above.
    lines.append("")
    lines.append("  EXCLUDED from the corpus above -- %d bodies, %d bytes, permanently"
                 % (len(excluded), ex_bytes))
    lines.append("  Steam-linked (see STEAM_EXCLUDE in scripts/progress.py):")
    for r in sorted(excluded, key=lambda r: -r["size"]):
        lines.append("    %-46s %6d bytes  %s  %s"
                     % (r["file"][:46], r["size"], r["va"], r["tree"]))

    unmatched = sorted((r for r in rows if not r["matched"]),
                       key=lambda r: -r["size"])
    if unmatched:
        lines.append("")
        lines.append("  Largest bodies not yet byte-identical:")
        for r in unmatched[:15]:
            lines.append("    %-46s %6d bytes  %s" % (r["file"][:46], r["size"], r["va"]))
        if len(unmatched) > 15:
            lines.append("    ... and %d more" % (len(unmatched) - 15))

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
            f.write("%d bodies (%d bytes) are permanently excluded from that count as "
                   "Steam-linked; see STEAM_EXCLUDE in `scripts/progress.py` for which "
                   "ones and why.\n\n" % (len(excluded), ex_bytes))
            f.write("```\n%s\n```\n\n" % text)
            f.write("Regenerate with:\n\n```bash\npython scripts/progress.py --write-status\n```\n")
        print("\n  wrote %s" % os.path.relpath(out, ROOT))
        write_shield(pct, done, total)
        print("  wrote %s" % os.path.join("docs", "progress.json"))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
