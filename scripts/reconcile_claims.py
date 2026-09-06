"""Compare what the ORACLE says about a body against what its HEADER claims.

    python scripts/reverify.py --tree src/recovered_module --out status/treeverify/module.tsv
    python scripts/reverify.py --tree src/recovered_thirdparty --out status/treeverify/thirdparty.tsv
    python scripts/reverify.py --tree src/recovered_unverified --out status/treeverify/unverified.tsv
    python scripts/reverify.py --tree src/recovered --out status/treeverify/recovered.tsv
    python scripts/reconcile_claims.py            # then this

WHY THIS EXISTS, AND WHY IT IS SEPARATE FROM reverify.py
========================================================
reverify.py answers "does this body still compile to the original's bytes". That is the
oracle, and it is the hard half. It does NOT answer the question the percentage actually
rests on, which is a different one:

    does every body that CLAIMS to be byte-identical actually match,
    and does every body that matches actually carry the claim?

A marker is a sentence someone typed. The oracle is a measurement. Nothing in this project
compared the two across the whole corpus until this file, and the gap was not theoretical:

  * Ten bodies in src/recovered_unverified/ carry a bare `byte-identical vs NSS5.exe`
    inserted ABOVE the VA line by a bulk header pass, while line 1 of the same header still
    reads `-- NOT VERIFIED`. Every one is contradicted by its own status/score/ record.
    10,670 bytes counted as done.
  * Three Load*Checked bodies in src/recovered_module/ carried the marker while compiling a
    deliberate BOOT SHIM the oracle rejects (253 vs 251, 272 vs 271, 253 vs 256).
    src/recovered_module was walked by NOTHING before reverify.py grew --tree, so those
    markers had never been checked at all.

Both classes move the headline in the flattering direction, and neither is visible to
"does it compile" or to the assembled build.

ONE READER, NOT TWO. The claim side comes from scripts/claim.py -- the same module
progress.py and coverage.py use. If this file had its own idea of what the marker means,
it would be a third definition of "matched" and the project would have three measures that
disagree instead of two. That was the original defect.

THE BUCKETS
===========
    OK        header claims matched, oracle says MATCH             nothing to do
    FALSE     header claims matched, oracle disagrees              <- fix these
    UNBANKED  header does not claim it, oracle says MATCH          <- free bytes
    KNOWN     header does not claim it, oracle disagrees           honest near miss
    STALE     the TSV row predates the file's current mtime        re-run the oracle
    UNPROBED  the oracle could not reach the body at all           not a pass

UNPROBED IS NOT A PASS, and it is reported as loudly as FALSE. A body the oracle cannot
build is exactly how the three shim markers survived: whatever cannot be measured cannot be
contradicted, so it keeps whatever claim it was given.

Exit status is 1 if anything is FALSE or UNPROBED, so this can gate CI.
"""
import os
import sys
import glob

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import claim as K                                                     # noqa: E402

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
TSV_DIR = os.path.join(ROOT, "status", "treeverify")

# reverify.py --tree writes: relpath \t STATUS \t detail \t mtime
MATCH_STATES = ("MATCH",)
# States that mean "the oracle ran and disagreed" rather than "the oracle never ran".
DISAGREE_STATES = ("MISMATCH", "NO LONGER", "LENGTH")


def rows():
    for p in sorted(glob.glob(os.path.join(TSV_DIR, "*.tsv"))):
        with open(p, encoding="utf-8", errors="replace") as f:
            for line in f:
                if line.startswith("#") or not line.strip():
                    continue
                parts = line.rstrip("\n").split("\t")
                if len(parts) < 3:
                    continue
                rel, status, detail = parts[0], parts[1], parts[2]
                mtime = float(parts[3]) if len(parts) > 3 and parts[3] else 0.0
                yield rel, status, detail, mtime


def classify():
    out = {k: [] for k in
           ("OK", "FALSE", "UNBANKED", "KNOWN", "STALE", "UNPROBED", "GONE")}
    for rel, status, detail, mtime in rows():
        path = os.path.join(ROOT, rel)
        if not os.path.exists(path):
            out["GONE"].append((rel, status, detail))
            continue
        # A verdict recorded before the file was last edited says nothing about the file
        # as it stands now. Silently trusting it is how a body drifts out of verification
        # without anyone touching the reasoning -- reverify.py's whole premise.
        if mtime and os.path.getmtime(path) > mtime + 1:
            out["STALE"].append((rel, status, detail))
            continue
        with open(path, encoding="utf-8", errors="replace") as f:
            head = K.header(f.read())
        claimed = K.is_matched(head)
        matched = status in MATCH_STATES
        probed = matched or any(status.startswith(s) for s in DISAGREE_STATES)
        if not probed:
            out["UNPROBED"].append((rel, status, detail))
        elif claimed and matched:
            out["OK"].append((rel, status, detail))
        elif claimed and not matched:
            out["FALSE"].append((rel, status, detail))
        elif matched:
            out["UNBANKED"].append((rel, status, detail))
        else:
            out["KNOWN"].append((rel, status, detail))
    return out


def main():
    if not os.path.isdir(TSV_DIR) or not glob.glob(os.path.join(TSV_DIR, "*.tsv")):
        print("no oracle output in status/treeverify/ -- run reverify.py --tree first")
        print("(see this file's docstring for the four commands)")
        return 2
    buckets = classify()
    total = sum(len(v) for v in buckets.values())
    print("CLAIM vs ORACLE   (%d bodies with a recorded verdict)\n" % total)
    for k in ("OK", "KNOWN", "UNBANKED", "FALSE", "UNPROBED", "STALE", "GONE"):
        if buckets[k]:
            print("  %-9s %d" % (k, len(buckets[k])))

    for k, why in (
        ("FALSE", "MARKERS THE ORACLE REJECTS -- these are counted and should not be"),
        ("UNBANKED", "MATCHES WITH NO MARKER -- free bytes, the banking step was missed"),
        ("UNPROBED", "THE ORACLE COULD NOT REACH THESE -- not a pass, and the exact gap "
                     "that let three false markers survive"),
        ("STALE", "EDITED SINCE THE VERDICT -- re-run the oracle on these"),
        ("GONE", "IN THE TSV BUT NOT ON DISK -- the run is out of date"),
    ):
        if buckets[k]:
            print("\n%s:" % why)
            for rel, status, detail in buckets[k]:
                print("  %-58s %-9s %s" % (rel, status, detail[:60]))

    return 1 if (buckets["FALSE"] or buckets["UNPROBED"]) else 0


if __name__ == "__main__":
    raise SystemExit(main())
