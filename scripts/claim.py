"""ONE definition of "this body is byte-identical", shared by every measure.

WHY THIS FILE EXISTS
====================
progress.py and coverage.py each had their own reader for the same header, and
they disagreed about 13 bodies. Two readers for one fact is two facts, and the
project then has a headline percentage that no single rule produces.

The disagreement was not symmetric, and neither reader was right:

  * progress.py accepted `byte-identical vs NSS5.exe` anywhere in the first 40
    lines and applied NO negative test at all. Ten bodies in
    src/recovered_unverified/ open with `-- NOT VERIFIED` on line 1 and carry a
    bare `' byte-identical vs NSS5.exe` on line 2, inserted above the VA line by
    a bulk header pass (commit 122bd86). In TScreen_Interview.Update.bmx the
    inserted line lands in the MIDDLE of a wrapped sentence, so lines 1 and 3
    read as one statement with the claim wedged between them. Every one of the
    ten is contradicted by its own status/score/<body>.txt record (42.9%, 26.2%,
    40.8%, 36.4%, 73.3%, 4.4%, 44.5%, 72.8%, 81.1%, 60.0% -- not one MATCH) and
    by the tree it sits in. progress.py counted all ten as matched.

  * coverage.py did apply a negative test, over the first STATUS_LINES lines,
    which is right and catches all ten. But it revoked TEngine.SetUpMatch.bmx,
    whose line 5 reads `Before: MISMATCH, mode=diff ...` -- the body's own record
    of the state it was in before the fix, i.e. exactly the negative-control
    discipline this project asks authors for. A measure that punishes a body for
    documenting what did not work teaches people to stop documenting it.

  * coverage.py also accepted three other spellings (`MATCH`, `byte-exact`, bare
    `verified`). Measured over the corpus today those spellings add exactly two
    bodies that carry no canonical marker, and both must NOT count:
    src/recovered_module/SteamInit.bmx (the compiled body is a neutralised stub;
    the word `verified` appears in prose ABOUT the original, which is kept as a
    comment) and src/recovered_unverified/ZipFile.getFileInfoByName.bmx (header
    line 1: `BUILD_FAIL, oracle-confirmed`). The loose vocabulary buys nothing
    real and costs those two, so it is gone.

THE RULE
========
A body is MATCHED when, and only when:

  1. its LEADING COMMENT BLOCK carries the canonical marker
     `byte-identical vs NSS5.exe`, produced by the oracle
     (harness.try_method / harness.try_function reporting MATCH n/n), and
  2. no line of the STATUS BLOCK -- the first STATUS_LINES lines of that comment
     block, which by corpus convention carry the name, the VA/size claim and the
     KIND/SIG -- states a CURRENT negative,
  3. where a line introduced by a HISTORY MARKER (`Before:`, `Control:`,
     `Previously:`, `Was:`) is not a current negative but a record of a rejected
     alternative, and does not revoke anything.

Everything after the status block is discussion. Scanning the whole header for a
negative revokes 50 genuinely verified bodies, because good headers say things
like "with the row corrected, this body is MISMATCH as .StartsWith and MATCH as
.Contains" -- that sentence is evidence FOR the body, not against it.

DIRECTION OF ERROR
==================
Every judgement call here is resolved towards NOT counting. A claim vocabulary
this file does not know reads as unverified; a contradicted header reads as
unverified; a history marker this file does not know costs a real body its claim
until someone adds the marker. Under-reporting is recoverable by reading a file.
Over-reporting is a number nobody can audit.
"""

import re

# The claim. One spelling, the one scripts/bytematch.py and scripts/localise_diff.py
# put there. Adding a spelling here is adding bodies to the numerator, so it needs
# the same standard of evidence as any other change that raises the percentage.
MATCHED = re.compile(r"byte-identical\s+vs\s+NSS5\.exe", re.I)

# A current negative verdict. `\b` on UNVERIFIED matters: without it the pattern
# fires on the substring inside a path reference like
# "src/recovered_unverified/Foo.bmx", which headers legitimately cite.
NEGATIVE = re.compile(r"\bMISMATCH\b|\bUNVERIFIED\b|\bNOT VERIFIED\b", re.I)

# Prefixes that mark a line as a record of a PAST or REJECTED state rather than
# the body's current verdict. Both spellings below are attested in this corpus:
#   src/recovered/TEngine.SetUpMatch.bmx:5
#     ' Before: MISMATCH, mode=diff, 1776/1776 LENGTH-EXACT, first_diff=+15.
#   src/recovered/TScreen_Shop.SetUpScreen.bmx:40
#     '    Control: rewriting the panel one as If/ElseIf gives 3075 bytes, MISMATCH at 507.
# `Previously:` and `Was:` are the same construction and are accepted so an author
# reaching for the obvious synonym is not silently penalised. The marker must
# INTRODUCE the line -- a MISMATCH sentence that merely mentions the word "before"
# somewhere is still a current negative.
HISTORY = re.compile(r"^(before|control|previously|was)\b\s*[:\-]", re.I)

# The status block: the first few comment lines, which by corpus convention carry
# the name, the VA/byte-count claim and the KIND/SIG.
STATUS_LINES = 6

# The VA/size header line. The strict form is authoritative; the loose form is a
# SECOND pass that only ever rescues a body which would otherwise be dropped
# silently, and can never re-interpret one that already parses. Two real headers
# spell the same fact with a comma:
#     ' VA 0x00592319, 18 bytes
#     ' ZipFile.getName -- VA 0x0058DD7C, 15 bytes
VA_LINE = re.compile(r"^'\s*VA\s+(0x[0-9A-Fa-f]+)\s+(\d+)\s+bytes", re.M)
VA_LINE_LOOSE = re.compile(r"^'.*?\bVA\s+(0x[0-9A-Fa-f]+)[,\s]\s*(\d+)\s+bytes", re.M)


def header(text):
    """-> the body's LEADING COMMENT BLOCK, as one string.

    The leading run of `'` lines and nothing else. Not "every line in the file
    that starts with a quote" (a comment at column 0 deep inside a body would
    then be read as a claim) and not "the first 40 lines" (which stops mid-header
    on the few very long ones). Measured over the whole corpus the three readers
    find the same 1,973 VA headers, so this is a tightening with no cost.
    """
    out = []
    for line in text.split("\n"):
        if line.startswith("'"):
            out.append(line)
        else:
            break
    return "\n".join(out)


def status_block(head):
    return head.split("\n")[:STATUS_LINES]


def negatives(head):
    """-> [line] -- current negative verdicts in the status block, history excluded."""
    bad = []
    for line in status_block(head):
        body = line.lstrip("'").strip()
        if HISTORY.match(body):
            continue
        if NEGATIVE.search(line):
            bad.append(line.strip())
    return bad


def is_matched(head):
    """-> True when this header claims byte-equality and nothing in it retracts."""
    return bool(MATCHED.search(head)) and not negatives(head)


def va_and_size(head):
    """-> (va_lowercase, size) or None."""
    m = VA_LINE.search(head) or VA_LINE_LOOSE.search(head)
    if not m:
        return None
    return m.group(1).lower(), int(m.group(2))


def read(path):
    """-> (header_text, (va, size) or None, matched) for one body file."""
    with open(path, encoding="utf-8", errors="replace") as f:
        head = header(f.read())
    return head, va_and_size(head), is_matched(head)
