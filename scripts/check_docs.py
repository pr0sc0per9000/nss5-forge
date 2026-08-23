#!/usr/bin/env python
"""
check_docs.py -- the checker docs/RULES.md tells everyone to run.

    python scripts/check_docs.py          # report, exit 1 on any ERROR
    python scripts/check_docs.py --warn   # also exit 1 on WARN

WHY THIS EXISTS
===============
docs/RULES.md has said, for a long time:

    "If you want a rule to survive, add it to scripts/check_docs.py or an equivalent
     checker. Otherwise do not bother writing it here."

...and referenced this file three times while it did not exist. So the repo's central
convention -- rules survive only as checks -- had no check behind it, and the rules it
protects were advice. RULES.md names two things that broke for exactly that reason:
assemble.py silently skipped src/recovered_thirdparty/ for weeks, and runtime_helpers.tsv
carried a wrong row that blessed ten wrong bodies.

Everything below is a defect that ACTUALLY OCCURRED in this corpus and that costs nothing
to detect. None of these needs a build; the whole run is a few seconds of file reading, so
there is no excuse for not running it.

WHAT IT CHECKS, AND THE INCIDENT BEHIND EACH
============================================
1. Every body's VA header parses.
   A body whose header does not parse leaves the corpus ENTIRELY -- numerator and
   denominator -- and the reported percentage GOES UP, because the work is deleted from the
   measure rather than done. Two bodies were lost this way in one session from ordinary
   header edits ("orig_len 6249", "Ghidra-authoritative length 2276 bytes"); the total fell
   by exactly their 8,525 bytes while the headline rose 0.7 points.

2. No two bodies claim the same VA.
   Two files describing one function means one of them is wrong, and both are counted.

3. No NEAR-MISS match markers.
   progress.py counts the literal phrase "byte-identical vs NSS5.exe". A header saying
   "byte-identical TO NSS5.exe", or "VERIFIED MATCH", is making the claim in a form nothing
   counts. TFormation.GetPlayerXY sat miscounted as outstanding for a whole day for exactly
   this, while being byte-identical the entire time. This one silently UNDER-reports, which
   is why it survives so long: nobody investigates a number that is too low.

4. Files that RULES.md tells people to run actually exist.
   This file's own absence is the worked example.

WHAT IT DELIBERATELY DOES NOT CHECK
===================================
Whether a body actually matches. That needs the byte oracle, costs a build per body, and
already has a home in scripts/reverify.py (--shard i/n, and always with NSS5_NO_LEARN=1).
Keeping this script build-free is what makes it cheap enough to run every time.
"""
import os
import re
import sys
import subprocess

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(ROOT, "scripts"))

TREES = ["src/recovered", "src/recovered_module", "src/recovered_thirdparty",
         "src/recovered_unverified"]

VA_LINE = re.compile(r"^'\s*VA\s+(0x[0-9A-Fa-f]+)\s+(\d+)\s+bytes", re.M)
VA_LOOSE = re.compile(r"^'.*?\bVA\s+(0x[0-9A-Fa-f]+)[,\s]\s*(\d+)\s+bytes", re.M)
MATCHED = re.compile(r"byte-identical\s+vs\s+NSS5\.exe", re.I)

# Claims that LOOK like a match marker but are not the phrase progress.py greps for.
NEAR_MISS = [
    (re.compile(r"byte-identical\s+to\s+NSS5\.exe", re.I), 'says "to NSS5.exe", not "vs"'),
    (re.compile(r"\bVERIFIED\s+MATCH\b", re.I), 'says "VERIFIED MATCH"'),
    (re.compile(r"byte-exact\s+vs\s+NSS5\.exe", re.I), 'says "byte-exact", not "byte-identical"'),
]

# A header that carries the MATCHED marker while ALSO declaring, in its own words, that the
# oracle cannot build it. Both cannot be true: BUILD_FAIL means nothing ever compared this
# body's bytes against NSS5.exe, so the marker is counting an unproven body in the numerator.
#
# Deliberately narrow -- BUILD_FAIL only, never MISMATCH. A header very often NARRATES a past
# mismatch it has since fixed ("was MISMATCH 482/575, root cause was the table"), and 5 of the
# 6 bodies a MISMATCH-based version of this check flagged were exactly that, all reporting
# MATCH under the oracle. A check that cries wolf 5 times out of 6 gets ignored, and then it
# is not a check. BUILD_FAIL as a self-declared current state had 1 true positive and 0 false
# ones: ZipFile.getFileInfoByName, which claimed byte-identical on line 29 while line 1 said
# "BUILD_FAIL, oracle-confirmed", and was counted for 28 bytes for as long as both stood.
SELF_DECLARED_BUILD_FAIL = [
    re.compile(r"^'\s*=*\s*BUILD_FAIL\b", re.I | re.M),
    re.compile(r"->\s*BUILD_FAIL\b", re.I),
]

# Files that legitimately carry no whole-function VA header. Named, with the reason, the
# same way progress.py's own allowlist is -- a check that fires forever on a known-good file
# trains everyone to ignore it, and then it is not a check.
#
#   ModuleBody_RealProgram.bmx: a FRAGMENT of the module body at 0x004BA034, not a function.
#     Its bytes belong to the parent; giving it a VA header would double-count them.
NOT_A_WHOLE_BODY = {
    "src/recovered_unverified/ModuleBody_RealProgram.bmx",
}


def bodies():
    for tree in TREES:
        d = os.path.join(ROOT, tree)
        if not os.path.isdir(d):
            continue
        for root, _dirs, files in os.walk(d):
            for fn in sorted(files):
                if fn.endswith(".bmx"):
                    p = os.path.join(root, fn)
                    yield os.path.relpath(p, ROOT).replace(os.sep, "/"), p


def main():
    errors, warns = [], []
    seen_va = {}

    for rel, path in bodies():
        try:
            with open(path, encoding="utf-8", errors="replace") as f:
                head = "".join(next(f, "") for _ in range(40))
        except OSError as exc:
            errors.append("%s: unreadable (%s)" % (rel, exc))
            continue

        m = VA_LINE.search(head) or VA_LOOSE.search(head)
        if not m:
            if rel not in NOT_A_WHOLE_BODY:
                errors.append("%s: VA header does not parse -- this body is in NEITHER the "
                              "numerator NOR the denominator. Wanted: "
                              "' VA 0x0055C09B   6249 bytes   ..." % rel)
            continue

        va = m.group(1).lower()
        if va in seen_va:
            errors.append("%s: VA %s already claimed by %s -- one of them is wrong and both "
                          "are counted" % (rel, va, seen_va[va]))
        else:
            seen_va[va] = rel

        if MATCHED.search(head):
            for rx in SELF_DECLARED_BUILD_FAIL:
                if rx.search(head):
                    errors.append("%s: header claims 'byte-identical vs NSS5.exe' AND declares "
                                  "BUILD_FAIL. The oracle cannot build this body, so nothing has "
                                  "compared its bytes -- yet progress.py counts them. Drop the "
                                  "marker or make the body verifiable." % rel)
                    break

        if not MATCHED.search(head):
            for rx, why in NEAR_MISS:
                if rx.search(head):
                    warns.append("%s: %s, so progress.py does NOT count it. Use the literal "
                                 "phrase 'byte-identical vs NSS5.exe'." % (rel, why))
                    break

    # HAND-MAINTAINED ADJUDICATION LIVING IN A GENERATED, UNTRACKED TREE.
    #
    # /extracted/ is gitignored, deliberately and with a good reason: it is derived from the
    # user's own copy of the game. But five files in there are not derived from anything --
    # they are hand-written adjudications, each row decided by reading the original's machine
    # code, and they are INPUTS that the generators read rather than outputs they write.
    # Nothing in git protects them, and losing one is silent: the generators simply resolve
    # differently and the build goes quietly wrong.
    #
    # This is not hypothetical. On 2026-08-22 a corrected row in extracted/brl_functions.tsv
    # was lost exactly this way -- extracted/ was regenerated, the correction went with it,
    # and TReplay.LoadReplayFile silently stopped matching while its header still claimed it
    # did. The same day, five alias rows fixing the player-movement split slots and two
    # fixing a transposed SetImageHandle were added to two of the files below.
    #
    # A row count is a weak guard, but it converts a silent wipe into a loud one, which is
    # the difference that matters. Back these up before running scripts/setup.py.
    # Floors are DATA ROWS, not file lines, at roughly 85% of the count on 2026-08-22.
    # Getting this wrong once already produced a false alarm worth avoiding: the floor for
    # global_alias_overrides.tsv was first set from its 852-line length, but 736 of those
    # lines are comment -- every row in these files carries its evidence inline -- so the
    # check fired at 116 real rows and read exactly like the wipe it exists to detect.
    HAND_MAINTAINED = {
        "global_alias_overrides.tsv": 100,      # 116 rows
        "global_address_adjudicated.tsv": 260,  # 308
        "global_alias_adjudicated.tsv": 224,    # 264
        "globals_type_overrides.tsv": 190,      # 224
        "globals_corrections.tsv": 49,          # 58
    }
    for fn, floor in sorted(HAND_MAINTAINED.items()):
        p = os.path.join(ROOT, "extracted", fn)
        if not os.path.exists(p):
            warns.append("extracted/%s is MISSING. It is hand-written adjudication, not "
                         "generated output -- regenerating extracted/ does not bring it "
                         "back. Restore it before trusting any build." % fn)
            continue
        rows = sum(1 for l in open(p, encoding="utf-8", errors="replace")
                   if l.strip() and not l.startswith("#"))
        if rows < floor:
            warns.append("extracted/%s has %d data rows, expected at least %d. Hand-verified "
                         "adjudication may have been lost to a regeneration." % (fn, rows, floor))

    # RULES.md must not tell people to run scripts that do not exist.
    rules = os.path.join(ROOT, "docs", "RULES.md")
    if os.path.exists(rules):
        text = open(rules, encoding="utf-8", errors="replace").read()
        for name in sorted(set(re.findall(r"scripts/([A-Za-z0-9_]+\.py)", text))):
            if not os.path.exists(os.path.join(ROOT, "scripts", name)):
                errors.append("docs/RULES.md tells people to run scripts/%s, which does not "
                              "exist" % name)

    # docs/STATUS.md is generated; a stale one lies confidently to anyone reading the repo.
    status = os.path.join(ROOT, "docs", "STATUS.md")
    if os.path.exists(status):
        try:
            live = subprocess.run([sys.executable, os.path.join(ROOT, "scripts", "progress.py")],
                                  capture_output=True, text=True, cwd=ROOT, timeout=300).stdout
            live_pct = re.search(r"TOTAL\s+\d+\s+\d+\s+\d+\s+([\d.]+)%", live)
            file_pct = re.search(r"TOTAL\s+\d+\s+\d+\s+\d+\s+([\d.]+)%",
                                 open(status, encoding="utf-8", errors="replace").read())
            if live_pct and file_pct and live_pct.group(1) != file_pct.group(1):
                warns.append("docs/STATUS.md says %s%% but progress.py says %s%% -- regenerate "
                             "with: python scripts/progress.py --write-status"
                             % (file_pct.group(1), live_pct.group(1)))
        except Exception as exc:                                        # noqa: BLE001
            warns.append("could not compare docs/STATUS.md against progress.py (%s)" % exc)

    print("check_docs: %d bodies inspected" % len(seen_va))
    for e in errors:
        print("  ERROR  " + e)
    for w in warns:
        print("  WARN   " + w)
    if not errors and not warns:
        print("  all checks pass")
    print("  %d error(s), %d warning(s)" % (len(errors), len(warns)))
    if errors:
        return 1
    if warns and "--warn" in sys.argv:
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
