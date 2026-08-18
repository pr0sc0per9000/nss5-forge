"""Find module Globals the assembled program READS but NEVER WRITES.

This is the crash predictor. Run it against src/assembled/nss5_assembled.bmx after
assemble.py, and it lists, ranked by blast radius, every Global that can only ever hold
its zero value at runtime.

WHY THESE EXIST
---------------
Two causes, and the report separates them because the fixes differ:

  ALIAS SPLIT  -- one address, two recovered names. Every body is verified ALONE in a
      probe where a Global's NAME cannot matter, so independent passes can name the same
      slot differently and every body still byte-matches. assemble.py emits one Global per
      distinct name, so the writer updates one variable and the reader sees another that
      is never assigned. Fix: extracted/global_alias_map.tsv + global_alias_overrides.tsv.
      Confirmed instances: g_comboimg/g_combo_arrow (Combo.png loaded into one, drawn
      through the other -- Null deref on every screen with a combo box),
      g_opt_music/g_musicvol (no music), g_screen_int03/g_mouseactive/g_screen_showmouse
      (no cursor, no clicking), g_activegadget/g_selgadget (clicks never fired).

  UNWRITTEN  -- the only body that would have assigned it is still an empty stub, or was
      never recovered. Fix: write that body, or set the Global at start-up.

WHY IT MATTERS MORE THAN IT LOOKS
---------------------------------
blitzmax-language-guide 18.26: a RELEASE build silently swallows null-derefs and returns
0. So a dead object Global does not announce itself -- the feature just quietly does
nothing, which is exactly the "the button does nothing" and "the colour is black instead
of green" class of symptom. In a -d build the same line throws
"Attempt to access field or method of Null object" and the process dies.

RANKING
-------
  CRITICAL  object/array type AND a member is accessed through it (`g.foo`, `g.Bar()`,
            `g[i]`) -- this is a guaranteed crash in -d and silent nothing in release.
  HIGH      object/array type, passed as an argument somewhere (may deref inside callee).
  MEDIUM    String -- yields Null/"", so comparisons and concatenation misbehave quietly.
            This is how a colour constant renders as black instead of its real value.
  LOW       numeric -- reads as 0. Often harmless, sometimes a disabled feature.

    python scripts/find_dead_globals.py
    python scripts/find_dead_globals.py --all           # include LOW
    python scripts/find_dead_globals.py --batches       # also slice the list into 12 batches
    python scripts/find_dead_globals.py --batches 16    # 16 batches
    python scripts/find_dead_globals.py --batches --all # batches including the LOW band

BATCHES
-------
--batches writes extracted/unify_work/dead_batches.json: the same list, cut into N slices
for a fan-out over parallel passes. The work list is regenerated from the repo every time
(no list in this project is hand-maintained), so a batch file on disk is only a snapshot of
the run that wrote it and goes stale as soon as any of those Globals is resolved. Regenerate
it before handing it out.

Slices are round-robin over the ranked list rather than contiguous, so no single pass gets
all the hard CRITICAL cases and no pass gets a slice of nothing but one-read LOWs. Each
sees a comparable mix and the wall-clock across passes stays even.

Batching lives HERE, on the producer, rather than in a separate script. A separate script
has to run this file as a subprocess and regex-parse its stdout back into rows, which gives
it a second copy of the severity filter and a --all flag to forward. Two copies of a filter
drift: ask for a band the producer is still suppressing and the batches come out with none
of those rows in them, silently and with no error. Sharing one `show_all` between the report
and the batches makes that class of bug unrepresentable.
"""
import os
import re
import sys
import json
import collections

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SRC = os.path.join(ROOT, "src", "assembled", "nss5_assembled.bmx")
EXT = os.path.join(ROOT, "src", "assembled", "nss5_external.bmx")
ALIAS = os.path.join(ROOT, "extracted", "global_alias_map_skipped.tsv")
BATCH_OUT = os.path.join(ROOT, "extracted", "unify_work", "dead_batches.json")

SEVERITY_ORDER = {"CRITICAL": 0, "HIGH": 1, "MEDIUM": 2, "LOW": 3}

DECL = re.compile(r"^Global\s+(\w+)\s*:\s*([^\s'=]+)", re.M)
NUMERIC = {"int", "float", "double", "byte", "short", "long"}


def strip_comments(text):
    out = []
    for line in text.split("\n"):
        s = line.lstrip()
        if s.startswith("'"):
            continue
        # strip trailing comment, naively but adequately: ' outside a string literal
        q = False
        for i, ch in enumerate(line):
            if ch == '"':
                q = not q
            elif ch == "'" and not q:
                line = line[:i]
                break
        out.append(line)
    return "\n".join(out)


def analyse():
    """-> (decls, rows, skipped). rows are (severity, name, type, reads, derefs), ranked.

    Split out of main() so other tools can ask this file the question directly instead of
    running it as a subprocess and scraping the printed table. Scraping makes the report's
    LAYOUT part of the contract, where a column change silently empties the caller's list.
    """
    if not os.path.exists(SRC):
        raise SystemExit("no %s -- run scripts/assemble.py first" % SRC)

    text = open(SRC, encoding="utf-8-sig", errors="replace").read()
    if os.path.exists(EXT):
        text += "\n" + open(EXT, encoding="utf-8-sig", errors="replace").read()

    decls = {m.group(1).lower(): m.group(2).strip() for m in DECL.finditer(text)}
    code = strip_comments(text)
    # drop the declaration lines themselves so `Global g:T = init` still counts as a write
    # but a bare `Global g:T` does not
    # THE LEADING \s* IS LOAD-BEARING. Anchoring `Global` to column 0 misses every
    # indented declaration.
    #
    # BlitzMax allows a Global declaration INSIDE a function body, where it is the legacy
    # lazy-init idiom: the initialiser runs once, on first entry, and the value persists.
    # Those declarations are indented, so a column-0 anchor misses them twice over: the
    # name is not recorded as written, AND the declaration line falls through into `body`,
    # where the name is then counted as a READ. Read-but-never-written is the definition
    # of dead, so the Global gets reported CRITICAL on the strength of its own declaration.
    #
    # Measured cost of getting this wrong: TScreen.DoProgressBar declares g_dpb_bar,
    # g_dpb_bg and g_dpb_panTip exactly this way (`Global g_dpb_bar:TProgressBar =
    # TProgressBar.CreateProgressBar(...)`, matching the guarded store in
    # extracted/decomp/TScreen.DoProgressBar@00512de9.c), and all three come out CRITICAL
    # dead, accounting for ~22 predicted crash sites that do not exist. A false "dead" is
    # not harmless: it invites a merge that would fuse two
    # live Globals, which is the one failure mode worse than a split.
    body_lines, init_written = [], set()
    for line in code.split("\n"):
        m = re.match(r"^\s*Global\s+(\w+)\s*:\s*[\w.]+(?:\s*\[[^\]]*\])?\s*=(?!=)", line)
        if m:
            init_written.add(m.group(1).lower())
            continue
        if re.match(r"^\s*Global\s+\w+\s*:", line):
            continue
        body_lines.append(line)
    body = "\n".join(body_lines)

    written = set(init_written)
    # Assignment at statement position: `name = v`, and BlitzMax's COMPOUND form.
    #
    # BlitzMax compound assignment is `name :+ v` -- a colon and an operator, with NO `=`
    # anywhere. A pattern that requires an `=` (`(?::[-+*/|&~]?)?=`) therefore matches the
    # C-style `:+=` this language does not have, and misses every real compound assignment
    # in the corpus.
    #
    # That silently marks live Globals dead: TEngine.RenderScoreboard does
    # `g_sbalpha :+ g_sbfadein` and `g_sbalpha :- g_sbfadeout`, TEngine.PauseEngine does
    # `g_pausedms :+ (g_matchclock - g_pauseticks)`, and both names come out reported as
    # never written. Numeric Globals are the ones most often updated this way -- counters,
    # timers, accumulators, fades -- which is exactly the LOW severity band, so the false
    # positives concentrated there.
    for m in re.finditer(
            r"(?m)^\s*(\w+)\s*(?::(?:[-+*/|&~]|shl\b|shr\b|sar\b)|=(?!=))", body):
        written.add(m.group(1).lower())
    # Varptr passes the address out; treat as a write (callee may fill it).
    for m in re.finditer(r"\bVarptr\s+(\w+)", body):
        written.add(m.group(1).lower())

    # SINGLE-LINE `If cond Then x = y`. The statement-position pattern above anchors to the
    # start of a line, so it misses every assignment written in the one-line If form -- and
    # this corpus uses it constantly. That produces a false CRITICAL: g_options_prevscreen
    # reads as never-written although TScreen_Options.SetUpScreen assigns it via
    # `If g_activescreen.name <> "controls" Then g_options_prevscreen = g_activescreen.name`.
    # A false "dead" is not harmless here -- it invites a merge that would fuse two live
    # Globals, which is the one failure mode worse than the split.
    for m in re.finditer(r"(?i)\bThen\s+(\w+)\s*(?::[-+*/|&~]?)?=(?!=)", body):
        written.add(m.group(1).lower())
    for m in re.finditer(r"(?i)\bThen\s+(\w+)\s*\[[^\]]*\]\s*(?::[-+*/|&~]?)?=(?!=)", body):
        written.add(m.group(1).lower())

    # A SIZED ARRAY DECLARATION IS ITSELF AN ALLOCATION. `Global g:String[300]` produces a
    # live 300-element array, so the Global is not dead however few times it is assigned --
    # the real writes are element writes (`g[i] = v`), which never match the statement-level
    # assignment pattern above because of the subscript.
    #
    # Getting this wrong inflates the report from ~600 rows to 1,150 and puts
    # g_options_arr01:String[300] at the very top of the CRITICAL list with 114 "derefs",
    # when it is simply a correctly allocated array being indexed 114 times. An unsized
    # `Global g:TFoo[]` IS dead, though -- length 0, and every index throws in a -d build
    # and silently returns 0 in release (blitzmax-language-guide 18.26).
    for name, ty in decls.items():
        m = re.search(r"\[\s*([0-9]+)\s*\]\s*$", ty)
        if m and int(m.group(1)) > 0:
            written.add(name)
    # element writes are real writes for arrays
    for m in re.finditer(r"(?m)^\s*(\w+)\s*\[[^\]]*\]\s*(?::[-+*/|&~]?)?=(?!=)", body):
        written.add(m.group(1).lower())

    read = collections.Counter()
    member = collections.Counter()
    for m in re.finditer(r"\b(g_\w+)\b", body):
        read[m.group(1).lower()] += 1
    for m in re.finditer(r"\b(g_\w+)\s*(\.|\[)", body):
        member[m.group(1).lower()] += 1

    # names that build_alias_map.py refused to merge -- likely the same slot as a live one
    skipped = {}
    if os.path.exists(ALIAS):
        with open(ALIAS, encoding="utf-8") as f:
            for line in f:
                p = line.rstrip("\n").split("\t")
                if len(p) >= 3 and p[1].strip():
                    skipped[p[1].strip().lower()] = (p[0], p[2])

    rows = []
    for name, ty in decls.items():
        if name in written or not read.get(name):
            continue
        base = ty.split("[")[0].lower()
        is_obj = base not in NUMERIC and base != "string"
        is_arr = "[" in ty
        if member.get(name) and (is_obj or is_arr):
            sev = "CRITICAL"
        elif is_obj or is_arr:
            sev = "HIGH"
        elif base == "string":
            sev = "MEDIUM"
        else:
            sev = "LOW"
        rows.append((sev, name, ty, read[name], member.get(name, 0)))

    rows.sort(key=lambda r: (SEVERITY_ORDER[r[0]], -r[4], -r[3], r[1]))
    return decls, rows, skipped


def emit_batches(rows, show_all, n):
    """Cut the ranked list into n round-robin slices and write dead_batches.json.

    `rows` and `show_all` are the SAME objects the report above printed from. That is the
    point of doing this here: there is no second severity filter to keep in step and no
    flag to forward, so the batches can never describe a different list than the report.
    """
    want = {"CRITICAL", "HIGH", "MEDIUM"}
    if show_all:
        # LOW is ~140 Globals that are read once and never dereferenced. They are real, but
        # they cost nothing at runtime and mixing them in triples the batch size for almost
        # no behavioural gain, so they join only when the report shows them too.
        want.add("LOW")
    scope = [{"name": r[1], "type": r[2], "severity": r[0],
              "reads": r[3], "derefs": r[4]} for r in rows if r[0] in want]
    if not scope:
        print()
        print("DEAD GLOBAL BATCHES")
        print("  nothing in scope -- no batches written")
        return

    batches = [[] for _ in range(n)]
    for i, row in enumerate(scope):
        batches[i % n].append(row)
    batches = [b for b in batches if b]

    os.makedirs(os.path.dirname(BATCH_OUT), exist_ok=True)
    with open(BATCH_OUT, "w", encoding="utf-8") as f:
        json.dump(batches, f, indent=1)

    counts = collections.Counter(r["severity"] for r in scope)
    print()
    print("DEAD GLOBAL BATCHES")
    print("  globals in scope : %d   (%s)"
          % (len(scope), ", ".join("%s=%d" % (k, counts[k])
                                   for k in sorted(counts, key=lambda s: SEVERITY_ORDER[s]))))
    print("  batches written  : %d   (%d-%d globals each)"
          % (len(batches), min(len(b) for b in batches), max(len(b) for b in batches)))
    print("  -> %s" % BATCH_OUT)
    for i, b in enumerate(batches):
        print("    batch %-2d : %s" % (i, ", ".join(x["name"] for x in b)))


def main():
    show_all = "--all" in sys.argv
    batches = "--batches" in sys.argv
    nbatch = 12
    for a in sys.argv[1:]:
        if a.isdigit():
            nbatch = int(a)

    decls, rows, skipped = analyse()

    counts = collections.Counter(r[0] for r in rows)
    print("DEAD GLOBALS -- read by the program, never written")
    print("  Globals declared : %d" % len(decls))
    print("  never written    : %d   (CRITICAL %d, HIGH %d, MEDIUM %d, LOW %d)"
          % (len(rows), counts["CRITICAL"], counts["HIGH"],
             counts["MEDIUM"], counts["LOW"]))
    print()
    for sev, name, ty, nread, nmem in rows:
        if sev == "LOW" and not show_all:
            continue
        note = ""
        if name in skipped:
            note = "   <- alias of %s @ %s, merge REFUSED" % (skipped[name][1], skipped[name][0])
        print("  %-9s %-34s %-14s reads=%-4d derefs=%-4d%s"
              % (sev, name, ty, nread, nmem, note))
    if not show_all and counts["LOW"]:
        print("\n  (%d LOW numeric globals hidden; --all to see them)" % counts["LOW"])

    if batches:
        emit_batches(rows, show_all, nbatch)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
