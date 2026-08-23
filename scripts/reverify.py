"""
Re-run the byte oracle over bodies already on disk. The guard against silent un-verification.

WHY. A recovered .bmx is a CLAIM, and the claim was true when it was written. It can stop
being true afterwards without anybody touching the reasoning, because `src/recovered` is a
live tree that many passes write to at once:

  * A body banked at 441/441 (TBall.CreateReplayBalls) can have its pragma rewritten from
    `'!Global g_replayballs:TList` to `:Object` by another process. As `Object` the body
    does not even compile; a wrong-but-compilable type instead shifts the vtable slot for
    `.Clear()` (0x34), `.AddLast()` (0x44) and `EachIn` (0x8C), producing a silently WRONG
    body that still builds.
  * A corpus-wide `sed` over the live tree rewrites whatever file another worker is
    holding open, mid-edit.

Neither is caught by "does it compile" and neither is caught by the assembled build, because
assemble.py merges Global types across files -- one file's good pragma masks another's bad
one. Only re-running the oracle per file catches it.

WHAT A FAILURE HERE MEANS. Not necessarily that the body is wrong: it may be that something
edited the file after verification. Read the diff before rewriting the body.

THE TWO ON-DISK FORMATS -- READ THIS BEFORE WRITING ANY CORPUS-WIDE TOOL
=======================================================================
`src/recovered/*.bmx` comes in two shapes:

    WRAPPED     ' comments
                    Function Update()
                        TCameraMan.UpdateAll()
                    End Function

    BODY-ONLY   ' comments
                TCameraMan.UpdateAll()

`harness.try_method` takes BODY-ONLY. Hand it a wrapped file and it does not error -- it
compiles the wrapper as if it were the body, emits an EMPTY function, and returns a
confident MISMATCH:

    orig  55 89 E5 FF 15 FC DD C5 00 B8 00 00 00 00 EB 00 89 EC 5D C3   (20 bytes)
    ours  55 89 E5 B8 00 00 00 00 EB 00 89 EC 5D C3                     (14 = empty stub)

Feeding wrapped text straight in reports 20 of 25 sampled bodies as broken -- a corpus-wide
catastrophe that does not exist, since every one of them MATCHes at full length once the
body is extracted. It is the same trap that can make assemble.py silently drop 126 verified
bodies, and it is worth stating the shared symptom:
**"our length is 14" almost always means the body never reached the compiler.**

--shard: THE SAME CODE PATH, SPLIT N WAYS
=========================================
`--all` takes about 40 minutes of wall clock. `--shard i/n` takes files[i::n] of the
identical sorted list and writes one TSV row per file, so n of them run at once and the
whole corpus finishes in minutes. It is deliberately not a second implementation: same
body_of, same try_method, same NSS5_NO_LEARN=1, same file list. Concatenating the shard
TSVs reproduces exactly what `--all` would have reported.

--pending: SCORING THE BODIES THAT ARE NOT VERIFIED YET
======================================================
Everything above re-checks bodies that already MATCHed. `--pending` runs the same oracle
over the trees where nothing has matched yet -- src/recovered_pending and
src/recovered_unverified -- and reports how close each one is, because the oracle is a
GRADIENT and not a pass/fail. It can say "your first 340 bytes are identical and then you
diverge here", which turns reconstruction into a search with feedback instead of a blind
guess. Without that feedback the guess really is blind: of eight functions written that way
and scored afterwards, six land at 2-6% agreement -- not near misses but different
implementations that happen to compile.

`--reports` additionally writes status/score/<Type.Method>.txt per body: the agreement, the
length delta, the offset of the first difference and the bytes on both sides around it. A
contributor handed "you match to byte 340, then the original has a compare-and-branch where
you emitted a call" can fix that specific statement.

Scoring goes through the ASSEMBLED exe (one build, everything scored at once) rather than
one probe per body, because the build is shared state: bmk drops its intermediates next to
the source, so two builds at once corrupt each other's object files, and thirty separate
builds would take thirty times as long.

THE PERCENTAGE IS A TRIAGE SIGNAL, NOT A FIDELITY MEASURE -- READ THIS
---------------------------------------------------------------------
bytematch.py compares POSITIONALLY: byte i of ours against byte i of the original. That is
the right check for a body that is supposed to be identical, and it is useless as a
gradient, because ONE length-changing difference early in a function desynchronises
everything after it. Every subsequent byte is then compared against the wrong byte and
counted as a mismatch. Measured, and it is not a small effect:

    body                              this score   scripts/localise_diff.py
    TBossMessage.Draw                     4.0%     CLEAN -- byte-identical
    TTeam.UpdatePlayerDestinations       92.6%     CLEAN -- byte-identical
    TBall.CanSeePlayer                   91.0%     CLEAN -- byte-identical
    TScreen_Leagues.SetUpLeagueFixtures  30.2%     11 gaps, +7 bytes total

A body reported at 4% was byte-perfect. Five of the six highest-scoring bodies were
byte-perfect while showing 91-94%. Any conclusion of the form "the corpus averages N%
fidelity" drawn from this number is wrong, and a "4% -> 90%" improvement may be mostly the
instrument rather than the body. USE scripts/localise_diff.py FOR ANY FIDELITY CLAIM: it
aligns before comparing, masks relocations, and reports what actually differs. What this
percentage IS good for is ranking bodies for attention and giving the offset of the FIRST
difference, which is genuinely where to start looking -- everything before it really does
match.

Usage:
    reverify.py                 sample 30 files
    reverify.py 100             sample 100
    reverify.py --all           the whole corpus (slow: hours)
    reverify.py --since <mtime-epoch>   only files modified since
    reverify.py --files a.bmx b.bmx     specific files
    reverify.py --shard 3/8             files[3::8], one TSV row per file
    reverify.py --shard 3/8 --out w.tsv write those rows to a file instead of stdout
    reverify.py --pending               score src/recovered_pending + _unverified
    reverify.py --pending --reports     ... and write status/score/<fn>.txt
    reverify.py --pending TEngine.GoalScored     score one body, or one Type
"""

import json
import os
import random
import re
import subprocess
import sys
import time

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

os.environ.setdefault("NSS5_WORKER", "reverify")
os.environ["NSS5_NO_LEARN"] = "1"      # a check must never teach itself the answer

import assemble as A  # noqa: E402   -- for BODY_RX, the one place the wrapper regex lives
import harness as H   # noqa: E402

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
RECOVERED = os.path.join(ROOT, "src", "recovered")
HEADER_VA = re.compile(r"VA\s+0x([0-9a-fA-F]+)")
SIG_RX = re.compile(r"(?:Method|Function)\s+\w+[^(\n]*\(([^)]*)\)")

# --pending: the trees where no body has matched yet, the build they are scored against,
# and where the per-function reports go.
PENDING_TREES = [os.path.join(ROOT, "src", "recovered_unverified"),
                 os.path.join(ROOT, "src", "recovered_pending")]
ASSEMBLED = os.path.join(ROOT, "src", "assembled", "nss5_assembled.exe")
SCORE_DIR = os.path.join(ROOT, "status", "score")
SCORE_JSON = os.path.join(ROOT, "extracted", "unify_work", "body_scores.json")


def body_of(text):
    """File text -> what harness.try_method actually wants, either format.

    Keeps the '!Global pragmas (harness re-reads them to declare the module Globals) and
    drops every other comment line. If the file is WRAPPED, unwrap it first -- see the
    module docstring for what happens when you don't.
    """
    stripped, gdecls = H.split_globals(text)
    mo = A.BODY_RX.search(stripped)
    raw = mo.group(3) if mo else stripped
    # KEEP every '! pragma. Dropping ALL comment lines also drops '!Field, which is how
    # the synthetic Type learns a sized-array field ("Field newcol:String[24]"). Without it
    # the probe's Type has no such field, `New` emits only the plain prologue, and the file
    # reports a confident MISMATCH (TKit.New 32/77) although the body is correct. Measured
    # over the whole corpus: 15 of the 24 non-MATCHes are this and nothing else -- every
    # one a `.New` carrying '!Field, 100% correlation.
    body = "\n".join(l for l in raw.split("\n")
                     if (not l.lstrip().startswith("'")) or l.lstrip().startswith("'!"))
    # A WRAPPED file declares its own parameter names ("Function PixelsToYards:Float(p:Float)")
    # but unwrapping throws the signature away and harness.try_method regenerates the probe's
    # parameters as a0, a1, ... So a body referring to `p` fails to build with
    # "Identifier 'p' not found" -- which reads exactly like a broken body. Map the wrapper's
    # declared names positionally onto a0.. Measured: 8 of 24 corpus non-MATCHes are this and
    # nothing else, and all 8 MATCH at full length once renamed.
    if mo:
        sig = SIG_RX.search(mo.group(0))
        if sig:
            names = [p.split(":")[0].strip().split()[-1]
                     for p in sig.group(1).split(",") if p.strip()]
            for i, n in enumerate(names):
                if n and n != "a%d" % i and n.isidentifier():
                    body = re.sub(r"\b%s\b" % re.escape(n), "a%d" % i, body)

    # HOIST '! PRAGMAS THAT LIVE OUTSIDE THE WRAPPER. Keeping '! lines (above) only helps
    # when they fall inside BODY_RX's group(3). In a WRAPPED file the pragma is normally
    # written before the Method line:
    #
    #     '!Field oldversion = -1
    #     Method New()
    #     End Method
    #
    # so group(3) is the empty interior and the pragma is discarded with the wrapper. That
    # leaves TMyStream.New (31/41, first_diff=+25) and TTable.New (101/119, +93) reporting
    # confident MISMATCHes for correct bodies -- both are empty `New`s whose ONLY
    # source-level content is a non-zero field initialiser (oldversion = -1 emitting
    # `mov dword [ebx+0xc],0xffffffff`; showheadings = 1). Scan the WHOLE text, not the
    # extracted region.
    #
    # Hoisted AFTER the parameter rename above, deliberately: a pragma naming a field that
    # happens to collide with a parameter name must not be rewritten to a0/a1.
    if mo:
        outside = [l for l in (stripped[:mo.start(3)] + stripped[mo.end(3):]).split("\n")
                   if l.lstrip().startswith("'!")]
        if outside:
            body = "\n".join(outside) + "\n" + body
    # RE-ATTACH THE PRAGMAS AS PRAGMAS, NOT AS CODE.
    #
    # H.split_globals() returns the pragma PAYLOAD with the "'!" marker stripped:
    # GLOBAL_PRAGMA (harness.py:689) captures group(1) starting at the literal word
    # "Global", and RAW_PRAGMA (harness.py:713) captures whatever followed "'!Raw ".
    # Joining those payloads straight onto the body hands harness.try_method plain
    # STATEMENTS where it expected pragmas.
    #
    # For a '!Global that is merely redundant. For a multi-line '!Raw it is fatal:
    # TProfile.LoadSavedGame carries
    #     '!Raw Function SyncSteamAchievements()
    #     '!Raw End Function
    # as a placeholder for its not-yet-promoted callee, and the bare payloads were
    # injected into the body as a nested Function definition inside the probe's own
    # Function -- so the body could never build, and the file reported a confident
    # MISMATCH that had nothing to do with its 936 bytes of reconstruction.
    #
    # Restore the marker by prefix, which is the same discriminator scripts/assemble.py
    # documents for this identical list: a payload beginning "Global " can only have come
    # from GLOBAL_PRAGMA, anything else can only have come from RAW_PRAGMA. Note that
    # H.parse_global_decl() is the WRONG test here -- it anchors end-to-end, so a '!Global
    # carrying a trailing inline comment fails it and would be mis-restored as '!Raw.
    if not gdecls:
        return body
    restored = []
    for g in gdecls:
        gs = g.strip()
        if not gs:
            continue
        restored.append(("'!" + gs) if re.match(r"^Global\s", gs, re.I)
                        else ("'!Raw " + gs))
    return "\n".join(restored) + "\n" + body


def pick():
    args = sys.argv[1:]
    files = sorted(f for f in os.listdir(RECOVERED) if f.endswith(".bmx") and "." in f[:-4])
    if "--files" in args:
        return args[args.index("--files") + 1:]
    if "--since" in args:
        cut = float(args[args.index("--since") + 1])
        return [f for f in files
                if os.path.getmtime(os.path.join(RECOVERED, f)) >= cut]
    if "--all" in args:
        return files
    n = 30
    for a in args:
        if a.isdigit():
            n = int(a)
    random.shuffle(files)
    return files[:n]


def argval(name):
    """-> the argument after `name`, or None. argv is read by hand here, as pick() does."""
    args = sys.argv[1:]
    if name in args and args.index(name) + 1 < len(args):
        return args[args.index(name) + 1]
    return None


# ------------------------------------------------------------------------ --shard
def run_shard(spec, out):
    """files[i::n] of the SAME sorted list, one TSV row per file. -> exit code."""
    idx, n = (int(x) for x in spec.split("/", 1))
    files = sorted(f for f in os.listdir(RECOVERED)
                   if f.endswith(".bmx") and "." in f[:-4])
    mine = files[idx::n]

    t0 = time.time()
    fh = open(out, "w", encoding="utf-8") if out else sys.stdout
    try:
        fh.write("#shard %d/%d  %d files  worker=%s\n"
                 % (idx, n, len(mine), os.environ.get("NSS5_WORKER")))
        for i, fn in enumerate(mine):
            path = os.path.join(RECOVERED, fn)
            text = open(path, encoding="utf-8", errors="replace").read()
            tname, mname = fn[:-4].split(".", 1)
            try:
                r = H.try_method(tname, mname, body_of(text))
                st = r.get("status")
                detail = "%s/%s" % (r.get("matched"), r.get("orig_len"))
                if r.get("first_diff") is not None:
                    detail += " first_diff=+%s" % r["first_diff"]
                if st != "MATCH":
                    detail += " | " + str(r.get("error") or r.get("mode") or "")[:160]
            except Exception as exc:                                   # noqa: BLE001
                st, detail = "ERROR", str(exc)[:200].replace("\t", " ").replace("\n", " ")
            fh.write("%s\t%s\t%s\t%.0f\n" % (fn, st, detail, os.path.getmtime(path)))
            fh.flush()
            # Progress goes to stderr so it cannot land in the TSV when --out is left off
            # and the rows are going to stdout.
            if (i + 1) % 25 == 0:
                sys.stderr.write("shard %d: %d/%d  %.0fs\n"
                                 % (idx, i + 1, len(mine), time.time() - t0))
                sys.stderr.flush()
    finally:
        if out:
            fh.close()
    print("shard %d done %d files %.0fs" % (idx, len(mine), time.time() - t0))
    return 0


# ----------------------------------------------------------------------- --pending
def pending_candidates():
    """(Type, Method, base) for every body in the pending trees."""
    out = []
    for d in PENDING_TREES:
        if not os.path.isdir(d):
            continue
        for fn in sorted(os.listdir(d)):
            if not fn.endswith(".bmx") or "." not in fn[:-4]:
                continue
            base = fn[:-4]
            ty, _, me = base.partition(".")
            if ty and me:
                out.append((ty, me, base))
    return out


def score_one(ty, me):
    """-> (equal, total, orig_len, our_len, first_diff, orig_hex, our_hex) or None."""
    try:
        r = subprocess.run([sys.executable,
                            os.path.join(ROOT, "scripts", "bytematch.py"),
                            ASSEMBLED, ty, me],
                           capture_output=True, text=True, timeout=240)
    except subprocess.TimeoutExpired:
        return None
    txt = r.stdout + r.stderr
    m = re.search(r"(MATCH|MISMATCH):\s*(\d+)/(\d+) bytes equal", txt)
    if not m:
        return None
    equal, total = int(m.group(2)), int(m.group(3))
    ol = re.search(r"orig_len=(\d+)", txt)
    nl = re.search(r"our_len=(\d+)", txt)
    fd = re.search(r"first difference at byte (\d+)", txt)
    oh = re.search(r"orig:\s*([0-9A-Fa-f ]+)", txt)
    nh = re.search(r"ours:\s*([0-9A-Fa-f ]+)", txt)
    return (equal, total,
            int(ol.group(1)) if ol else 0,
            int(nl.group(1)) if nl else 0,
            int(fd.group(1)) if fd else -1,
            (oh.group(1).strip() if oh else ""),
            (nh.group(1).strip() if nh else ""))


def write_score_report(base, eq, tot, ol, nl, fd, oh, nh, band):
    pct = (100.0 * eq / tot) if tot else 0.0
    with open(os.path.join(SCORE_DIR, base + ".txt"), "w", encoding="utf-8") as f:
        f.write("BODY            : %s\n" % base)
        f.write("BYTE AGREEMENT  : %d/%d  (%.1f%%)  [%s]\n" % (eq, tot, pct, band))
        f.write("LENGTH          : ours %d, original %d  (delta %+d)\n" % (nl, ol, nl - ol))
        if fd >= 0:
            f.write("FIRST DIFFERENCE: byte %d\n" % fd)
            f.write("  original: %s\n" % oh)
            f.write("  ours    : %s\n" % nh)
        f.write("\nHOW TO USE THIS\n")
        f.write("The bytes above start AT the first difference. Everything before\n")
        f.write("byte %d already matches, so the statement to fix is the one that\n"
                % max(fd, 0))
        f.write("compiles to that offset -- not the whole body. A length delta\n")
        f.write("that is positive means you emitted more code than the original\n")
        f.write("(usually an extra branch, or an If where the original used a\n")
        f.write("Select); negative means you dropped a branch.\n")


def run_pending(only, reports):
    """Score the pending trees against the assembled build. -> exit code."""
    if not os.path.exists(ASSEMBLED):
        raise SystemExit("no %s -- run scripts/assemble.py first" % ASSEMBLED)

    rows = []
    for ty, me, base in pending_candidates():
        if only and base not in only and ty not in only:
            continue
        s = score_one(ty, me)
        if s is None:
            rows.append((base, 0, 0, 0, 0, -1, "", "", "NO ORACLE RESULT"))
            continue
        equal, total, ol, nl, fd, oh, nh = s
        pct = (100.0 * equal / total) if total else 0.0
        band = ("EXACT" if pct >= 99.9 else "close" if pct >= 70 else
                "partial" if pct >= 20 else "different")
        rows.append((base, equal, total, ol, nl, fd, oh, nh, band))

    rows.sort(key=lambda r: -(r[1] / r[2] if r[2] else 0))
    print("BODY SCORES vs NSS5.exe   (%d bodies)" % len(rows))
    print("  %-46s %7s %7s  %s" % ("BODY", "AGREE", "LEN", "BAND"))
    for base, eq, tot, ol, nl, fd, _oh, _nh, band in rows:
        pct = (100.0 * eq / tot) if tot else 0.0
        print("  %-46s %6.1f%% %4d/%-4d %s" % (base[:46], pct, nl, ol, band))

    counts = {}
    for r in rows:
        counts[r[8]] = counts.get(r[8], 0) + 1
    print()
    print("  " + "  ".join("%s=%d" % kv for kv in sorted(counts.items())))

    if reports:
        os.makedirs(SCORE_DIR, exist_ok=True)
        for row in rows:
            write_score_report(*row)
        print("\nwrote %d reports to %s" % (len(rows), SCORE_DIR))

    with open(SCORE_JSON, "w", encoding="utf-8") as f:
        json.dump([{"fn": r[0], "equal": r[1], "total": r[2], "our_len": r[4],
                    "orig_len": r[3], "band": r[8]} for r in rows], f, indent=1)
    return 0


def main():
    # The two borrowed modes, dispatched before pick() sees argv. Neither re-implements
    # anything: --shard runs this file's own body_of/try_method over files[i::n], and
    # --pending runs the same byte oracle over the trees that have not matched yet.
    if "--shard" in sys.argv:
        shard = argval("--shard") or ""
        if not re.match(r"^\d+/\d+$", shard):
            # Said out loud rather than falling through: without this, a mistyped --shard
            # silently reverts to the 30-file SAMPLE, which prints a perfectly healthy
            # report and looks exactly like a shard that finished early.
            print("--shard wants i/n, e.g. --shard 3/8 (got %r)" % shard)
            return 2
        return run_shard(shard, argval("--out"))
    if "--pending" in sys.argv:
        return run_pending([a for a in sys.argv[1:] if not a.startswith("--")],
                           "--reports" in sys.argv)

    work = pick()
    print("re-verifying %d bodies under NSS5_NO_LEARN=1" % len(work))
    print()
    ok = fail = err = 0
    bad = []
    t0 = time.time()
    for i, fn in enumerate(work):
        path = os.path.join(RECOVERED, fn)
        if not os.path.exists(path):
            print("  %-52s MISSING" % fn)
            err += 1
            continue
        text = open(path, encoding="utf-8", errors="replace").read()
        base = fn[:-4]
        tname, mname = base.split(".", 1)
        try:
            r = H.try_method(tname, mname, body_of(text))
        except Exception as exc:                                  # noqa: BLE001
            err += 1
            bad.append((fn, "ERROR %s" % exc))
            continue
        st = r.get("status")
        if st == "MATCH":
            ok += 1
        else:
            fail += 1
            bad.append((fn, "%s %s/%s%s" % (st, r.get("matched"), r.get("orig_len"),
                                            "  first_diff=+%s" % r["first_diff"]
                                            if r.get("first_diff") is not None else "")))
        if (i + 1) % 10 == 0:
            print("  ... %d/%d  (%d ok, %d failing)  %.0fs"
                  % (i + 1, len(work), ok, fail, time.time() - t0))

    print()
    print("  still MATCH : %d" % ok)
    print("  NO LONGER   : %d" % fail)
    print("  errored     : %d" % err)
    if bad:
        print()
        print("  A failure is not automatically a bad body -- check whether the FILE was")
        print("  edited after it was verified (pragma types are the usual casualty).")
        for fn, why in bad[:40]:
            print("    %-52s %s" % (fn, why))
    return 1 if (fail or err) else 0


if __name__ == "__main__":
    sys.exit(main())
