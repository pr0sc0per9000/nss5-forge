"""Enumerate and TRIAGE every module Global that is read but never written.

    python scripts/dead_globals.py                 # ranked report
    python scripts/dead_globals.py --tsv out.tsv   # machine-readable, one row per Global
    python scripts/dead_globals.py --name g_gfxw   # everything about one Global
    python scripts/dead_globals.py --severity CRASH

WHY THIS EXISTS
===============
Every runtime bug found in this reconstruction so far has been the same defect: a Global is
WRITTEN by one function under a descriptive name (read out of Inc/Engine.ini, or assigned at
setup) and READ by another under a placeholder name. The alias tables failed to merge the
pair, so assemble.py emitted TWO separate BlitzMax Globals. The reader half is never written,
has no initialiser, and therefore holds 0 / 0.0 / Null for the entire life of the process.

Worked examples, all confirmed and fixed:

  g_player_float05   xvel = xvel * 0.0 every frame        -> player could not move at all
  g_ply_turnrate     direction = origDir every frame      -> moved, but could not steer
  g_screen_mousex    offsetX stuck at 0                   -> tooltip drawn far from cursor
  g_gfxw / g_gfxh    SetViewport(0,0,0,0) after fDraw     -> everything after it clipped away
  g_chn1/2/4, sfx    StopChannel(Null) on an unguarded .Stop -> hard crash on quit

The byte oracle cannot see any of this. TPlayer.UpdateMovement is 4137/4137 byte-identical and
TTraining.PlayerCanMove is 252/252, and the player still could not move. These defects live in
whole-program wiring, which a per-function probe never observes.

So the list this script produces is, approximately, the remaining bug backlog. Finding them one
crash at a time is the slow way round.

SEVERITY, AND WHY THE QUIET ONES ARE WORSE
==========================================
  CRASH        An object/array Global dereferenced with no enclosing Null guard. Faults the
               moment the line runs. Loud, easy to find, easy to fix -- the best kind.
  GUARDED      Dereferenced, but behind `If g_x <> Null`. Never crashes; the feature simply
               never happens. A sound that never plays, a panel that never draws.
  SILENT       A numeric Global used in arithmetic. No crash, no message, just a wrong number
               -- a sprite at the wrong offset, a loop that never runs, a scale of zero.
               These are the expensive ones: nothing announces them, and they are indis-
               tinguishable from "the reconstruction is subtly wrong" until someone looks.

GROUNDING IS STILL REQUIRED -- THIS SCRIPT ONLY FINDS CANDIDATES
================================================================
A row here says "this Global is never written", which is a fact about the emitted source. It
does NOT say which address the reader means. That must be established from the ORIGINAL's
machine code -- disassemble the reading body at its VA and read off the absolute address the
instruction actually loads -- before any alias row is written. A wrong alias row silently
corrupts two Globals at once and is worse than leaving one unfixed.

KNOWN LIMITS, STATED SO NOBODY RE-DISCOVERS THEM
================================================
  * An ARRAY ELEMENT write (`g_x[0] = 1`) is a real write to g_x. An earlier pass used a
    regex that missed those and produced four false positives on the control arrays. Counted
    here.
  * A Global passed to a function expecting `Var` is written without an `=` at the call site.
    Not detected. Such a Global may appear dead and not be.
  * Reads are counted by identifier occurrence, so a LOCAL variable with the same name would
    inflate the count. Every Global here is `g_`-prefixed by convention, which makes a
    collision unlikely but not impossible.
  * Guard detection looks for `If <name> <> Null` / `If Not <name>` in the enclosing block by
    indentation. A guard expressed some other way (an early Return, a flag) reads as
    unguarded, so CRASH is an over-approximation and each one needs a look.
  * SEVERITY UNDER-COUNTS CRASHES, and this one bit immediately. A Global PASSED AS AN
    ARGUMENT to a function that dereferences it faults just as hard as `g_x.foo`, but at the
    call site there is no `.` or `[` after the name, so it lands in SILENT. The worked example
    is the crash this list was built to prevent: `StopChannel(g_chn2)` is classified SILENT
    here, yet BRL's StopChannel is an unguarded `channel.Stop` and a Null g_chn2 took the
    process down on every quit. Closing that needs interprocedural analysis -- knowing which
    parameters each callee dereferences -- which this deliberately does not attempt.
    PRACTICAL CONSEQUENCE: CRASH is a lower bound on the crash surface, not the whole of it.
    Do not read a SILENT row on an object/array type as "cannot crash"; check whether it is
    handed to something that dereferences it.
"""
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SRC = os.path.join(ROOT, "src", "assembled", "nss5_assembled.bmx")

DECL = re.compile(r"^Global\s+(\w+)\s*:\s*([^=']+?)\s*(=.*)?$")
FNDECL = re.compile(r"^(\s*)(?:Function|Method)\s+(\w+)")
TYPEDECL = re.compile(r"^\s*Type\s+(\w+)")
ENDTYPE = re.compile(r"^\s*End\s*Type\b", re.I)

# Types whose zero value is Null and which therefore fault when dereferenced.
SCALARS = {"Int", "Float", "Double", "Long", "Short", "Byte", "String"}

# A right-hand side that assigns the type's own zero value. Assigning only this leaves the
# Global holding what it would have held with no assignment at all. Anchored and complete so
# `Null` matches but `NullCheck(x)` and `0 + g_y` do not; a trailing comment is tolerated.
ZERO_RHS = re.compile(r"""^(?:Null|0|0\.0|0\.|\.0|""|"")\s*(?:'.*)?$""", re.I)

# Names that read like geometry/layout. A zero here is a wrong position or a loop that never
# runs -- the failure mode that produced the tooltip and viewport bugs.
GEOM = re.compile(r"(^|_)(x|y|w|h|width|height|scale|offset|off[xy]|pos|left|right|top|"
                  r"bottom|size|radius|dist|speed|rate|zoom|cam)([0-9]*$|_)", re.I)


def argval(flag, default=None):
    if flag in sys.argv:
        i = sys.argv.index(flag)
        if i + 1 < len(sys.argv):
            return sys.argv[i + 1]
    return default


def analyse(path):
    lines = open(path, encoding="utf-8-sig", errors="replace").read().split("\n")

    # KEY EVERYTHING CASE-FOLDED. BlitzMax identifiers are case-INSENSITIVE, and assemble.py
    # lower-cases the declaration while leaving each body's own casing alone. So the
    # declaration `Global g_continents_tbltable:TTable` and its only write,
    # `g_continents_tblTable = TTable.CreateTable(...)`, are ONE slot -- already correctly
    # wired -- and a case-sensitive scan sees a read with no write and cries wolf.
    #
    # Measured cost of getting this wrong: 72 of 230 rows were false positives, including 45
    # of the 64 CRASH rows. Three workers were prioritising off that list before it was caught.
    # Safe to fold: no Global in the emitted program collides with another when lower-cased
    # (checked -- 1663 declared, 0 collisions), and the file is SuperStrict, so an identifier
    # that resolved to nothing would be a compile error rather than a silent dead read.
    decls = {}
    for l in lines:
        m = DECL.match(l)
        if m:
            decls[m.group(1).lower()] = (m.group(2).strip(), bool(m.group(3)), m.group(1))

    # Enclosing Type.Function for every line, so a read can be attributed.
    owner, cur_type, stack = {}, None, []
    for i, l in enumerate(lines):
        mt = TYPEDECL.match(l)
        if mt:
            cur_type = mt.group(1)
        if ENDTYPE.match(l):
            cur_type = None
        mf = FNDECL.match(l)
        if mf:
            stack = [("%s.%s" % (cur_type, mf.group(2))) if cur_type else mf.group(2)]
        if re.match(r"^\s*End\s*(Function|Method)\b", l, re.I):
            stack = []
        owner[i] = stack[0] if stack else "<module body>"

    writes, reads, sites, clears = {}, {}, {}, {}
    for i, l in enumerate(lines):
        if DECL.match(l):
            continue
        s = l.strip()
        if s.startswith("'"):
            continue
        # WRITES. `=` IS BOTH ASSIGNMENT AND EQUALITY IN BLITZMAX, so a bare search for
        # `name =` counts `If g_x = 5` and `If g_x[i] = g_y` as writes and the Global then
        # looks alive when nothing ever assigns it. That hid at least six real defects from
        # this enumerator, including g_screen_negotiate_int02 (12 reads, never assigned).
        #
        # An assignment's target begins a STATEMENT, so only accept `=` at a statement start:
        # the start of the line, or immediately after Then / Else. The compound forms
        # (:+ :- :* :/) are unambiguous -- they cannot be comparisons -- so they count
        # anywhere. Array-element assignment (`g_x[0] = ...`) counts as a write to g_x.
        #
        # AND THE INVERSE BLIND SPOT: `g_x = Null` IS NOT A LIVE WRITE.
        # A Global whose ONLY assignments are the zero value can never hold anything else,
        # so it is exactly as dead as one with no assignment at all -- but a naive counter
        # sees a write and calls it alive. This hid a real crash: g_playerteam's only
        # assignment in the whole 50,000-line program is `g_playerteam = Null` in
        # TEngine.EndMatch's teardown, while 34 other occurrences read it, several as
        # unguarded field dereferences. It took the game down at nss5_assembled.bmx:2748,
        # `If g_playerteam.id = p.teamid`, on the first ball pickup.
        # Tracked separately so the report can say WHICH kind of dead it is.
        for m in re.finditer(r"(?:^\s*|\bThen\s+|\bElse\s+)(\w+)\s*(?:\[[^\]]*\])?\s*=(?!=)"
                             r"\s*(.*)$", l, re.I):
            k = m.group(1).lower()
            if ZERO_RHS.match(m.group(2).strip()):
                clears[k] = clears.get(k, 0) + 1
            else:
                writes[k] = writes.get(k, 0) + 1
        # COMPOUND ASSIGNMENT IS `:+`, NOT `:+=`. The earlier pattern demanded a trailing
        # `=`, and `:+=` occurs ZERO times in the corpus while `:+` occurs 1,139 -- so this
        # branch matched nothing at all and every Global whose only writes are compound
        # looked dead. Seven rows were false positives, among them g_pausedms, whose sole
        # store in the whole image is `add [0xc6efd8],eax` and whose source line is
        # `g_pausedms :+ (g_matchtime - g_pauseticks)`. A false positive here is worse than
        # a miss: it sends someone to "fix" a Global that already works.
        for m in re.finditer(r"(?<![.\w])(\w+)\s*(?:\[[^\]]*\])?\s*"
                             r":(?:[-+*/|&~]|shl\b|shr\b|mod\b)", l, re.I):
            k = m.group(1).lower()
            writes[k] = writes.get(k, 0) + 1
        for m in re.finditer(r"(?<![.\w])(\w+)", l):
            k = m.group(1).lower()
            if k in decls:
                reads[k] = reads.get(k, 0) + 1
                after = l[m.end():m.end() + 1]
                sites.setdefault(k, []).append((i, owner.get(i, "?"), after, s))

    out = []
    for g, (ty, has_init, shown) in decls.items():
        if has_init or writes.get(g, 0) or not reads.get(g, 0):
            continue
        why = "only ever assigned Null/0" if clears.get(g, 0) else "never assigned"
        my = sites.get(g, [])
        deref = [s for s in my if s[2] in (".", "[")]
        guarded = 0
        for ln, _fn, _a, _s in deref:
            # Look back a few lines within the same function for a Null guard.
            ctx = " ".join(x.strip() for x in lines[max(0, ln - 4):ln + 1])
            if re.search(r"If\s+(Not\s+)?%s\s*(<>\s*Null|=\s*Null)?" % re.escape(g), ctx, re.I) \
               and re.search(r"(<>\s*Null|If\s+Not\s+%s)" % re.escape(g), ctx, re.I):
                guarded += 1
        is_obj = ty not in SCALARS
        if deref and is_obj and guarded < len(deref):
            sev = "CRASH"
        elif deref and is_obj:
            sev = "GUARDED"
        else:
            sev = "SILENT"
        out.append({
            "name": shown, "type": ty, "reads": len(my), "derefs": len(deref), "why": why,
            "guarded": guarded, "severity": sev,
            "geom": bool(GEOM.search(g)),
            "fns": sorted({s[1] for s in my}),
            "sites": my,
        })
    return out


def main():
    if not os.path.exists(SRC):
        raise SystemExit("no %s -- run scripts/assemble.py first" % SRC)
    rows = analyse(SRC)

    one = argval("--name")
    if one:
        for r in rows:
            if r["name"].lower() == one.lower():
                print("%s : %s   severity=%s  reads=%d  derefs=%d (%d guarded)"
                      % (r["name"], r["type"], r["severity"], r["reads"], r["derefs"],
                         r["guarded"]))
                for ln, fn, _a, s in r["sites"]:
                    print("   line %-7d %-38s %s" % (ln + 1, fn, s[:90]))
                return 0
        print("%s is not dead (or not a module Global)" % one)
        return 1

    want = argval("--severity")
    if want:
        rows = [r for r in rows if r["severity"] == want.upper()]

    order = {"CRASH": 0, "GUARDED": 1, "SILENT": 2}
    rows.sort(key=lambda r: (order[r["severity"]], not r["geom"], -r["reads"]))

    tsv = argval("--tsv")
    if tsv:
        with open(tsv, "w", encoding="utf-8", newline="") as f:
            f.write("name\ttype\tseverity\twhy\treads\tderefs\tguarded\tgeometry\tfunctions\n")
            for r in rows:
                f.write("%s\t%s\t%s\t%s\t%d\t%d\t%d\t%s\t%s\n"
                        % (r["name"], r["type"], r["severity"], r["why"], r["reads"],
                           r["derefs"], r["guarded"], "yes" if r["geom"] else "",
                           ",".join(r["fns"][:6])))
        print("wrote %s (%d rows)" % (tsv, len(rows)))

    counts = {}
    for r in rows:
        counts[r["severity"]] = counts.get(r["severity"], 0) + 1
    print("DEAD GLOBALS -- read, never written, no initialiser: %d" % len(rows))
    print("  " + "   ".join("%s=%d" % kv for kv in sorted(counts.items())))
    print()
    nulled = sum(1 for r in rows if r["why"] != "never assigned")
    if nulled:
        print("  %d are ONLY EVER ASSIGNED Null/0. A teardown line like `g_x = Null` is not a"
              % nulled)
        print("  live writer; counting it as one hid the crash at TBall.CheckSideLines.")
        print()
    print("  %-28s %-13s %-8s %-24s %5s  %s"
          % ("NAME", "TYPE", "SEVERITY", "WHY", "READS", "READ BY"))
    for r in rows[:70]:
        print("  %-28s %-13s %-8s %-24s %5d  %s"
              % (r["name"][:28], r["type"][:13], r["severity"], r["why"], r["reads"],
                 ", ".join(r["fns"][:2])[:42]))
    if len(rows) > 70:
        print("  ... and %d more (use --tsv for the full list)" % (len(rows) - 70))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
