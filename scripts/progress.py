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

VA_LINE = re.compile(r"^'\s*VA\s+(0x[0-9A-Fa-f]+)\s+(\d+)\s+bytes", re.M)
MATCHED = re.compile(r"byte-identical\s+vs\s+NSS5\.exe", re.I)


def scan():
    """-> list of {tree, file, va, size, matched}"""
    rows = []
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
            rows.append({
                "tree": tree, "kind": kind, "file": fn[:-4],
                "va": m.group(1).lower(), "size": int(m.group(2)),
                "matched": bool(MATCHED.search(head)),
            })
    return rows


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
    rows = scan()
    if not rows:
        raise SystemExit("no bodies with a VA header found -- has the tree moved?")
    done, total, pct = totals(rows)

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
            f.write("```\n%s\n```\n\n" % text)
            f.write("Regenerate with:\n\n```bash\npython scripts/progress.py --write-status\n```\n")
        print("\n  wrote %s" % os.path.relpath(out, ROOT))
        write_shield(pct, done, total)
        print("  wrote %s" % os.path.join("docs", "progress.json"))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
