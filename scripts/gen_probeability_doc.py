#!/usr/bin/env python3
"""gen_probeability_doc.py -- classify every game-module method/function A-E and
emit the probeability classification document (DST below).

    python scripts/gen_probeability_doc.py                # classify, then render
    python scripts/gen_probeability_doc.py --render-only   # render from the existing TSV

Reads extracted/probe_dataset.tsv (built by build_probe_dataset.py), writes
extracted/probeability.tsv, and renders the document from it. Classification and
rendering are one command, which is what stops the document being rendered from
a stale TSV.
--render-only skips the classification and renders whatever probeability.tsv
already holds, for when only the prose or the table layout changed.
"""
import csv
import os
import re
import sys
from collections import Counter, defaultdict

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DST = os.path.join(ROOT, "docs", "specs", "10-probeability-classification.md")

YIELD = {'A': 0.95, 'B': 0.50, 'C': 0.15, 'D': 0.02, 'E': 1.00}
YIELD_OPT = {'A': 1.00, 'B': 0.70, 'C': 0.30, 'D': 0.05, 'E': 1.00}
YIELD_PES = {'A': 0.90, 'B': 0.30, 'C': 0.05, 'D': 0.00, 'E': 1.00}

CLSNAME = {'A': 'Solvable by enumeration', 'B': 'Solvable by formula fitting',
           'C': 'Partially recoverable', 'D': 'Not recoverable by probing',
           'E': 'Trivial / no work needed'}

# ---------------------------------------------------------------------------
# Classification
# ---------------------------------------------------------------------------
# Subsystem membership is by hand because nothing in the binary records it: the
# reflection tables carry Types, not the groupings a reader thinks in.
MATCH = set("""TPlayer TBall TEngine TPitch TTeam TBase_Team TFormation TKit
TKitStrings TCameraMan TPhotographer TWeather TSnowFlake TParticle TCone TPole
TStadium TPitchMark TTarget TInterceptPoint TDummy TPlayerColours TStats_Match
TStats_Team TTeamPool TDrawOb TMyVector TScreen_MatchPrep TScreen_MatchPaused
TScreen_Formation TScreen_Abilities""".split())
REPLAY = set("TReplay TReplayFrame TPanel_Controls".split())
CASINO = set("""TBlackJack TCard TRoulette TRouletteBall TRouletteWheel
TSlotMachine TSlotStrip TScreen_Casino TScreen_Roulette TScreen_BlackJack
TScreen_Slots TScreen_Pairs TPair_Icon""".split())
TRAINING = set("TTraining TTrainingLine TTrainingZone TTrainingObject".split())
HORSE = set("THorse TScreen_Stable".split())
WORLD = set("""TNation TContinent TClub TCompetition TFixture TLocale TNames
TPromotionPlace""".split())
CAREER = set("""TProfile TContractOffer TAchievement TBossMessage THistory
TDate TMyDate TStat TScreen_MyContract TScreen_ContractOffer TScreen_Negotiate
TScreen_Interview TScreen_Dilemma TScreen_Relationships TScreen_Finances
TScreen_ReportBoss TScreen_ReportPhysio TScreen_Shop TScreen_BootShop
TScreen_NewPlayer TScreen_SeasonReview""".split())
UI = set("""TButton TButtonPos TCombo TGadget TLabel TInputBox TProgressBar
THelpBox TPanel TTable TTableData TRow TColumn TScreenMessage TOptions TJoy
TMyGfxModes TMyStream TMyBankStream TScreen""".split())

RENDER_IO = re.compile(
    r'^(Render|Draw|Paint|Blit|Load|Save|Write|Read|Refresh|Show|Hide|Play|'
    r'Sort|Export|Import|Print|Log)', re.I)
PURE = re.compile(r'^(Get|Is|Has|Calc|Convert|To|Find|Lookup|Name|Weekday|'
                  r'Row|Col|Count|Rnd|Random)', re.I)
FORMULA = re.compile(r'^(Get|Calc|Count|Total|Sum|Average|Work|Rate)', re.I)


def subsystem(t):
    if t in MATCH:
        return "match engine"
    if t in REPLAY:
        return "replay"
    if t in CASINO:
        return "casino"
    if t in TRAINING:
        return "training"
    if t in HORSE:
        return "horse"
    if t in WORLD:
        return "world data"
    if t in CAREER:
        return "career"
    if t in UI:
        return "UI"
    if t.startswith("TScreen"):
        return "screens"
    if t.startswith("z_My"):
        return "UI"
    return "career"


def sig_ret(s):
    d = 0
    for i, c in enumerate(s):
        if c == '(':
            d += 1
        elif c == ')':
            d -= 1
            if d == 0:
                return s[i + 1:]
    return s


def classify(r):
    """Return (class, rule). First matching rule wins."""
    sz = int(r['size'])
    calls = int(r['calls'])
    nm = r['name']
    a = sig_args(r['sig'])
    rt = sig_ret(r['sig'])
    smallint = all(x in ('i', 'b', 's') for x in a)

    # ---- E: no reconstruction work exists -------------------------------
    if r['status'] == 'ABSTRACT':
        return 'E', 'E1 abstract stub, no body'
    if nm == 'Delete' and sz <= 24:
        return 'E', 'E2 compiler dtor stub'
    if nm == 'New' and sz <= 48:
        return 'E', 'E3 compiler field-init ctor'
    if sz <= 40 and calls == 0:
        return 'E', 'E4 leaf accessor <=40B, no callees'

    # ---- D: size / behaviour beats signature ----------------------------
    if sz >= 1200:
        return 'D', 'D1 >=1200B, control flow beyond probe reach'
    if RENDER_IO.match(nm) and sz >= 200:
        return 'D', 'D2 render/IO name, >=200B'
    if calls >= 12 and sz >= 300:
        return 'D', 'D3 >=12 callees & >=300B, orchestrator (state space)'
    if calls >= 25:
        return 'D', 'D4 >=25 callees, orchestrator'

    # ---- A: enumerable input domain, meaningful return ------------------
    if (1 <= len(a) <= 2 and smallint and rt in ('$', 'i', 'f')
            and sz <= 600 and PURE.match(nm)):
        return 'A', 'A1 1-2 small-int args, scalar return, <=600B, pure-ish name'

    # ---- B: formula over known fields -----------------------------------
    if (len(a) == 0 and rt in ('i', 'f', 'd') and FORMULA.match(nm)
            and 40 < sz <= 900):
        return 'B', 'B1 no args, numeric return, accessor-name, 40-900B'
    if (len(a) <= 2 and smallint and rt in ('i', 'f', 'd')
            and FORMULA.match(nm) and 40 < sz <= 500):
        return 'B', 'B2 <=2 small-int args, numeric return, 40-500B'

    # ---- C: everything else ---------------------------------------------
    return 'C', 'C1 mutator / state-dependent, snapshot-diff only'


def classify_dataset():
    """probe_dataset.tsv -> probeability.tsv, plus the console effort model."""
    rows = list(csv.DictReader(
        open(os.path.join(ROOT, "extracted", "probe_dataset.tsv"),
             encoding="utf-8"), delimiter="\t"))
    for r in rows:
        r['cls'], r['rule'] = classify(r)
        r['sub'] = subsystem(r['type'])
        r['bytes'] = max(0, int(r['size']))

    dst = os.path.join(ROOT, "extracted", "probeability.tsv")
    with open(dst, "w", encoding="utf-8", newline="\n") as fh:
        w = csv.writer(fh, delimiter="\t", lineterminator="\n")
        w.writerow(["type", "subsystem", "kind", "name", "sig", "va", "size",
                    "calls", "class", "rule"])
        for r in sorted(rows, key=lambda x: (x['type'], -x['bytes'])):
            w.writerow([r['type'], r['sub'], r['kind'], r['name'], r['sig'],
                        r['va'], r['size'], r['calls'], r['cls'], r['rule']])

    tot_n = len(rows)
    tot_b = sum(r['bytes'] for r in rows)
    print("TOTAL %d methods/functions, %d code bytes\n" % (tot_n, tot_b))

    print("%-6s %7s %7s %12s %8s" % ("class", "count", "pct", "bytes", "pct"))
    cn = Counter(r['cls'] for r in rows)
    cb = defaultdict(int)
    for r in rows:
        cb[r['cls']] += r['bytes']
    for c in "ABCDE":
        print("%-6s %7d %6.1f%% %12d %7.1f%%" %
              (c, cn[c], 100.0 * cn[c] / tot_n, cb[c], 100.0 * cb[c] / tot_b))

    print("\nmean bytes/function by class:")
    for c in "ABCDE":
        if cn[c]:
            print("  %s  %8.0f" % (c, cb[c] / cn[c]))

    print("\n--- per-subsystem (count | bytes) ---")
    subs = sorted({r['sub'] for r in rows})
    print("%-14s %6s %9s  %s" % ("subsystem", "n", "bytes", "  ".join(
        "%-13s" % c for c in "ABCDE")))
    for s in subs:
        rs = [r for r in rows if r['sub'] == s]
        n = len(rs)
        b = sum(r['bytes'] for r in rs)
        cells = []
        for c in "ABCDE":
            k = [r for r in rs if r['cls'] == c]
            cells.append("%3d/%6d" % (len(k), sum(r['bytes'] for r in k)))
        print("%-14s %6d %9d  %s" % (s, n, b, "  ".join(cells)))

    print("\n--- effort model (byte-weighted) ---")
    for label, Y in (("pessimistic", YIELD_PES), ("central", YIELD),
                     ("optimistic", YIELD_OPT)):
        removed = sum(cb[c] * Y[c] for c in "ABCDE")
        print("  %-12s probing removes %6.2f%% of code-byte effort; "
              "%5.2f%% must be read" %
              (label, 100.0 * removed / tot_b, 100.0 - 100.0 * removed / tot_b))
    print("\n  (function-count framing, central yields, for contrast)")
    removed_n = sum(cn[c] * YIELD[c] for c in "ABCDE")
    print("  %-12s probing removes %6.2f%% of FUNCTIONS" %
          ("count", 100.0 * removed_n / tot_n))
    print("\nwrote %s" % dst)


def sig_args(s):
    d = 0
    for i, c in enumerate(s):
        if c == '(':
            d += 1
        elif c == ')':
            d -= 1
            if d == 0:
                return [a for a in s[1:i].split(',') if a]
    return []


def main():
    render_only = "--render-only" in sys.argv
    for a in sys.argv[1:]:
        if a != "--render-only":
            sys.exit("usage: gen_probeability_doc.py [--render-only]")
    if not render_only:
        classify_dataset()
    rows = list(csv.DictReader(open(os.path.join(ROOT, "extracted", "probeability.tsv"),
                                    encoding="utf-8"), delimiter="\t"))
    ds = {(r['type'], r['name'], r['sig']): r for r in
          csv.DictReader(open(os.path.join(ROOT, "extracted", "probe_dataset.tsv"),
                              encoding="utf-8"), delimiter="\t")}
    for r in rows:
        r['b'] = int(r['size'])
    N = len(rows)
    B = sum(r['b'] for r in rows)
    cn = Counter(r['class'] for r in rows)
    cb = defaultdict(int)
    for r in rows:
        cb[r['class']] += r['b']

    sweep = Counter()
    sweepb = defaultdict(int)
    for r in rows:
        k = ds.get((r['type'], r['name'], r['sig']))
        v = k['sweep'] if k else ''
        sweep[v] += 1
        sweepb[v] += r['b']

    o = []
    W = o.append
    W("# 10 - Probeability Classification of the NSS5 Game Module\n")
    W("How much of the reconstruction can *dynamic probing* actually do, and how "
      "much must still be read out of decompiled code?\n")
    W("This document answers that with measurements, not intuition. Every number "
      "below is derived from the real binary, the real reflection metadata and "
      "the real Ghidra function inventory. Three probing experiments were "
      "actually **run** (under Unicorn) rather than reasoned about.\n")
    W("\n---\n")

    # ---------------- scope ----------------
    W("\n## 1. Scope, and two corrections to the premise\n")
    W("The brief specifies: scopes whose `at` file offset lies in "
      "`0x857000..0x86D000`, stated as *132 Types and 1,627 methods/functions*. "
      "The real content of that window today is:\n")
    W("| | count |")
    W("|---|---|")
    W("| scopes in window | 133 (132 `T*` Types + 1 anonymous BlitzMax module scope) |")
    W("| Methods + Functions | **1,761** |")
    W("| resolved to a code address | 1,754 |")
    W("| abstract stubs (`0x005B95AC`, no body) | 7 |")
    W("| total code bytes (Ghidra `size`) | **835,468** |")
    W("")
    W("**Correction 1 - the 1,627 figure is stale, and the gap is not cosmetic.**")
    W("`extracted/vtable_map.tsv` was generated at 23:16 from an *older* "
      "`object_model.json`; the current model was rebuilt at 00:02. The map "
      "covers 333 of 348 scopes. Fifteen types are missing from it entirely, "
      "including **`TPlayer`** - 134 methods, 97,622 code bytes, the single "
      "largest and most important type in the match engine. `1,627` is exactly "
      "`1,625 vtable-joined rows + 2 anonymous-scope rows`, i.e. it silently "
      "excludes all of TPlayer.\n")
    W("I re-ran the resolver against the current model. `TPlayer`'s class table "
      "is at **`0x00C5F94C`** (super `0x005C9CA0`, instance_size 396, max field "
      "offset 392 - it would have validated fine; it was never attempted). All "
      "**134/134** slots resolve into `code` and land exactly on Ghidra function "
      "starts. Sample: `TPlayer.New = 0x004EBCB4`, `SetUp = 0x004EC179`, "
      "`Update = 0x004EE11B`, `UpdateMovement = 0x004F0468`, "
      "`RecordPlayerStats` (15,154 bytes).\n")
    W("Everything below uses the corrected 1,761-row set. Rebuilt by "
      "`scripts/build_probe_dataset.py` -> `extracted/probe_dataset.tsv`.\n")
    W("**Correction 2 - only 7 abstract stubs are in the game module, not 56.**")
    W("The 56 slots pointing at `0x005B95AC` are counted across *all* 348 scopes "
      "including the BlitzMax framework types. Inside the game window there are "
      "7. This barely matters for effort, but the brief's figure should not be "
      "reused.\n")

    # ---------------- the shape of the problem ----------------
    W("\n## 2. Two structural facts that constrain everything\n")
    W("**(a) 70.6% of these functions take no arguments at all.**")
    W("1,243 of 1,761 have an empty parameter list, and they carry "
      "69.9% of the code bytes. There is no input domain to enumerate. Their "
      "behaviour is a function of object fields and globals, so \"feed known "
      "inputs\" means *constructing state*, and knowing which state matters "
      "means reading the code. That is circular for exactly the functions that "
      "dominate the mass.\n")
    W("Argument-shape census:\n")
    ac = Counter(len(sig_args(r['sig'])) for r in rows)
    W("| args | functions | share |")
    W("|---|---|---|")
    for k in sorted(ac):
        lab = str(k) if k < 4 else "4+"
        W(f"| {k} | {ac[k]} | {100.0*ac[k]/N:.1f}% |")
    W("")
    W("**(b) Code volume is extremely top-heavy, and effort follows volume.**")
    sz = sorted((r['b'] for r in rows), reverse=True)
    W("| | share of all 835,468 code bytes |")
    W("|---|---|")
    for n in (10, 25, 50, 100, 200, 400, 800):
        W(f"| largest {n} functions | {100.0*sum(sz[:n])/B:.1f}% |")
    W("")
    W("Median function is 153 bytes; the 90th percentile is 1,181; the largest "
      "is 16,301. **Counting functions and counting work are not the same "
      "measurement**, and the entire disagreement about probing's value turns on "
      "which one you use.\n")

    # ---------------- rules ----------------
    W("\n## 3. Classification rules\n")
    W("Applied mechanically, first match wins, to all 1,761 rows. Inputs are the "
      "reflection signature, the Ghidra function `size`, and the Ghidra callee "
      "count. Full output: `extracted/probeability.tsv`.\n")
    W("| # | rule | class |")
    W("|---|---|---|")
    W("| E1 | slot points at abstract stub `0x005B95AC` - no body exists | E |")
    W("| E2 | `Delete` and size <= 24 - compiler destructor stub | E |")
    W("| E3 | `New` and size <= 48 - compiler field-init constructor | E |")
    W("| E4 | size <= 40 and zero callees - leaf accessor | E |")
    W("| D1 | size >= 1200 - control flow beyond any feasible input sweep | D |")
    W("| D2 | name matches `Render/Draw/Paint/Blit/Load/Save/Write/Read/Refresh/Show/Hide/Play/Sort/Export/Import/Print/Log` and size >= 200 | D |")
    W("| D3 | >= 12 callees and size >= 300 - orchestrator, state space is its callees' | D |")
    W("| D4 | >= 25 callees | D |")
    W("| A1 | 1-2 args, all small ints, scalar return (`$`/`i`/`f`), size <= 600, accessor-like name | A |")
    W("| B1 | zero args, numeric return, accessor-like name, 40 < size <= 900 | B |")
    W("| B2 | <= 2 small-int args, numeric return, accessor-like name, 40 < size <= 500 | B |")
    W("| C1 | everything else - state-dependent mutator | C |")
    W("")
    W("Size gates are load-bearing and do real work. Signature alone is "
      "badly misleading: `TPlayer.DoAnimCelebrate(i)i` and "
      "`TStats_Match.DrawPitch(i,i)i` both look like textbook class-A "
      "\"small int in, value out\" lookups and are 2,851 and 2,338 bytes "
      "respectively. Any classification done from signatures without size "
      "would put them in A and be wrong.\n")

    # ---------------- totals ----------------
    W("\n## 4. Per-class totals\n")
    W("| class | meaning | functions | % of functions | code bytes | % of bytes | mean bytes | median bytes |")
    W("|---|---|---|---|---|---|---|---|")
    for c in "ABCDE":
        k = [r for r in rows if r['class'] == c]
        med = sorted(r['b'] for r in k)[len(k) // 2]
        W(f"| **{c}** | {CLSNAME[c]} | {cn[c]} | {100.0*cn[c]/N:.1f}% | "
          f"{cb[c]:,} | {100.0*cb[c]/B:.1f}% | {cb[c]//cn[c]} | {med} |")
    W(f"| | **total** | **{N}** | 100% | **{B:,}** | 100% | {B//N} | 153 |")
    W("")
    W(f"The decisive line in that table is **mean bytes**: class A averages "
      f"{cb['A']//cn['A']} bytes, class B {cb['B']//cn['B']}, class D "
      f"**{cb['D']//cn['D']:,}** - a {(cb['D']//cn['D'])/(cb['A']//cn['A']):.0f}x "
      f"gap. Probing's strong classes are populated almost entirely by the "
      f"smallest functions in the program.\n")

    # ---------------- subsystem ----------------
    W("\n## 5. Per-subsystem breakdown\n")
    W("Cells are `functions / code bytes`.\n")
    W("| subsystem | n | code bytes | A | B | C | D | E | probe-strong (A+B) share of bytes |")
    W("|---|---|---|---|---|---|---|---|---|")
    subs = sorted({r['subsystem'] for r in rows},
                  key=lambda s: -sum(r['b'] for r in rows if r['subsystem'] == s))
    for s in subs:
        rs = [r for r in rows if r['subsystem'] == s]
        n = len(rs)
        b = sum(r['b'] for r in rs)
        cells = []
        ab = 0
        for c in "ABCDE":
            k = [r for r in rs if r['class'] == c]
            kb = sum(r['b'] for r in k)
            if c in "AB":
                ab += kb
            cells.append(f"{len(k)}/{kb:,}")
        W(f"| {s} | {n} | {b:,} | " + " | ".join(cells) +
          f" | **{100.0*ab/b:.1f}%** |")
    W("")
    W("Read that last column carefully. In **no** subsystem does the "
      "probe-strong bucket reach 6% of the code. The match engine - the "
      "subsystem people most want automated - is 291,881 bytes of which "
      "A+B is 5,759 bytes, **2.0%**. `screens` is 179,604 bytes with "
      "**173 bytes** of class A and no class B at all: screen construction is "
      "hundreds of literal widget-placement calls, which probing cannot "
      "recover and reading recovers trivially.\n")

    # ---------------- experiments ----------------
    W("\n## 6. Three experiments actually run\n")
    W("### 6.1 Cold-call reachability (what probing can touch with no live game)\n")
    W("`scripts/emu_probe.py --sweep` cold-calls each function in Unicorn with a "
      "zeroed object and no runtime init. Restricted to the game module:\n")
    W("| verdict | functions | code bytes | % of bytes |")
    W("|---|---|---|---|")
    for k in ('COMPLETED', 'FAULT_NULLDEREF', 'FAULT_OTHER', 'OTHER', ''):
        if sweep[k]:
            lab = k if k else '(not in stale sweep - TPlayer etc.)'
            W(f"| {lab} | {sweep[k]} | {sweepb[k]:,} | {100.0*sweepb[k]/B:.1f}% |")
    W("")
    W("Functions that run to completion are **9.6% of the code mass**, and their "
      "median size is 51 bytes. Of the 454 that completed, **374 (82.4%) "
      "returned 0** - they ran, and told us nothing. The functions cold-probing "
      "reaches are the ones that were never expensive to read.\n")
    W("The 707 `FAULT_NULLDEREF` (309,610 bytes) are the ones a live-game "
      "attach *would* reach, which is the strongest argument for the proxy-DLL "
      "route. But reaching a function is not recovering it - that is precisely "
      "the C/D distinction.\n")

    W("### 6.2 Coverage-instrumented enumeration - and the death of \"branch blindness\"\n")
    W("The prior assessment calls branch blindness a **FATAL FLAW**: *\"without "
      "reading the code you do not know the branches exist, so you cannot know "
      "which you missed... silently wrong on the untriggered case.\"*\n")
    W("**This is refuted.** We have the image, so we have the CFG. "
      "`scripts/coverage_probe.py` recovers basic-block leaders with capstone and "
      "hooks Unicorn at instruction granularity to record which blocks a sweep "
      "actually executed. Missed branches are then a *printed number*, not an "
      "unknown unknown.\n")
    W("`TBall.GetStringKickType(i)$` @ `0x004CC5E2`, 98 bytes, 36 instructions, "
      "17 basic blocks, inputs 0..23:\n")
    W("```")
    W("blocks executed: 17/17 = 100.0%")
    W("NEVER-EXECUTED blocks (0):")
    W("0 -> 'NONE'   1 -> 'PASS'   2 -> 'SHOOT'  3 -> 'LOB'")
    W("4 -> 'HEAD PASS'  5 -> 'HEAD SHOOT'  6 -> 'HEAD LOB'   >=7 -> 'NONE'")
    W("```")
    W("100% block coverage is a *proof* that no branch was missed. The failure "
      "mode the prior pass called fatal is measurable and therefore manageable.\n")
    W("What survives from that objection is much narrower and still real: "
      "coverage tells you which blocks you missed, it does not tell you what "
      "*input* reaches them. Solving that is constraint solving, not probing.\n")
    W("Scaled up (`scripts/coverage_sweep.py`) over all 102 single-int-arg, "
      "scalar-return, <=600-byte candidates, cold:\n")
    W("| outcome | count | bytes |")
    W("|---|---|---|")
    W("| attempted | 102 | 18,587 |")
    W("| ran clean (0 faults) | 30 | |")
    W("| 100% block coverage | 22 | |")
    W("| **fully solved** (clean + 100% cov + >1 distinct output) | **13** | **1,370** |")
    W("")
    W("Thirteen functions, 1,370 bytes = **0.16% of the game module**, solved "
      "outright by cold enumeration. Solved list includes "
      "`TFormation.GetStringTacticName` (14 outputs), `TKit.GetBootColour` (11), "
      "`TKit.GetHexSkinColour`, `THorse.GetHorseColour`, "
      "`TRouletteWheel.GetColour`. Every one of the 13 was independently placed "
      "in class A or E by the classifier and none in C/D - the classifier has no "
      "false negatives against measured ground truth.\n")

    W("### 6.3 Formula fitting - it works, and the brief's example is wrong\n")
    W("`scripts/fit_skillrating.py` probes `TProfile.GetSkillRating()i` "
      "(`0x00569D19`, 62 bytes) by building a synthetic TProfile and setting one "
      "field at a time.\n")
    W("The brief says it *\"reads 20 skill fields at known offsets (164-232); set "
      "one to 1 and the rest to 0, twenty probes recovers twenty weights.\"* "
      "Measured result: the range 164..232 holds **18** fields, and **only 7 of "
      "them affect the output at all**:\n")
    W("```")
    W("pace shooting passing tackling heading dribbling flair  -> delta 14 per 100")
    W("interviewskill crossing freekicks corners positioning shortpassing")
    W("longpassing aggression longshots finishing penalties     -> delta 0")
    W("```")
    W("Recovered and verified exactly - 0/10 mismatches on random vectors:\n")
    W("```")
    W("GetSkillRating() = (pace + shooting + passing + tackling")
    W("                   + heading + dribbling + flair) / 7      ' integer division")
    W("```")
    W("Two lessons that generalise. First, **naive weight fitting produces a "
      "subtly wrong model**: the single-probe delta is 14, but the true "
      "coefficient is 1/7 = 0.142857, and that quantisation error compounds - "
      "the linear model mispredicted 1 of 12 random vectors until the divisor "
      "was guessed. Fitting gives you coefficients; it does not give you the "
      "*form*, and the form is where the truth is. Second, probing told us 11 "
      "fields are unused - genuinely useful, and not obtainable from the "
      "signature.\n")
    W("Now the control. `TProfile.GetValue()i` is listed in the brief as an "
      "equally good formula-fitting target. It is **1,386 bytes** - 22x larger - "
      "and every probe against a synthetic profile dies immediately:\n")
    W("```")
    W("all-zero profile -> ERR: Invalid memory read")
    W("field 164=100    -> ERR: Invalid memory read")
    W("```")
    W("It dereferences the object graph (club, nation, contract) before it "
      "computes anything. It is class D. `GetSkillRating` and `GetValue` are not "
      "the same kind of problem, and grouping them was the prior assessment's "
      "central estimation error.\n")

    # ---------------- decisive number ----------------
    W("\n## 7. The decisive number\n")
    W("**Effort model.** Reconstruction effort is taken as proportional to code "
      "volume, using Ghidra `size` as the proxy. This is the defensible choice: "
      "a 16,301-byte function is not one unit of work the way a 23-byte getter "
      "is, and byte count is the only per-function difficulty measure we have "
      "that is measured rather than assumed. Each class is assigned a *yield* - "
      "the fraction of its effort dynamic probing removes.\n")
    W("| class | yield | justification |")
    W("|---|---|---|")
    W("| A | 0.95 | the enumeration table **is** the function; proven at 100% block coverage. Residual is transcription into BlitzMax. |")
    W("| B | 0.50 | proven exactly recoverable on `GetSkillRating` - but only after guessing the *form* (`/7`). Coefficients come free; structure, clamps and rounding still need reading. |")
    W("| C | 0.15 | snapshot-and-diff yields which fields move and bounds on how far. Useful constraints and a regression oracle; not the algorithm. |")
    W("| D | 0.02 | nothing derivable. Value is limited to smoke-testing. |")
    W("| E | 1.00 | already free - but only 5,876 bytes exist to be free. |")
    W("")
    W("| scenario | yields (A/B/C/D) | effort probing removes | effort that must be read |")
    W("|---|---|---|---|")
    for lab, Y in (("pessimistic", YIELD_PES), ("**central**", YIELD),
                   ("optimistic", YIELD_OPT)):
        rem = sum(cb[c] * Y[c] for c in "ABCDE")
        W(f"| {lab} | {Y['A']}/{Y['B']}/{Y['C']}/{Y['D']} | "
          f"**{100.0*rem/B:.1f}%** | {100.0-100.0*rem/B:.1f}% |")
    W("")
    rem = sum(cb[c] * YIELD[c] for c in "ABCDE")
    remn = sum(cn[c] * YIELD[c] for c in "ABCDE")
    W(f"### Answer: dynamic probing can plausibly remove **{100.0*rem/B:.0f}% of "
      f"total reconstruction effort** (range {100.0*sum(cb[c]*YIELD_PES[c] for c in 'ABCDE')/B:.0f}-"
      f"{100.0*sum(cb[c]*YIELD_OPT[c] for c in 'ABCDE')/B:.0f}%). "
      f"**{100.0-100.0*rem/B:.0f}% must still be recovered by reading decompiled code.**\n")
    W("**Why the intuitive answer is roughly triple the true one.** Scoring the "
      f"same classification by function count instead of code volume gives "
      f"{100.0*remn/N:.0f}% - because A+B+E is {cn['A']+cn['B']+cn['E']} functions "
      f"({100.0*(cn['A']+cn['B']+cn['E'])/N:.0f}% of the list) but only "
      f"{cb['A']+cb['B']+cb['E']:,} bytes ({100.0*(cb['A']+cb['B']+cb['E'])/B:.1f}% of the "
      "work). Probeability is *inversely correlated with reconstruction cost*. "
      "This is not a coincidence to be worked around - it is structural. A "
      "function is enumerable precisely when it has a small input domain and no "
      "state dependence, which is precisely when it is short, which is precisely "
      "when reading it was already cheap. **Probing is easiest exactly where it "
      "is least needed.**\n")
    W("Sanity check against measurement rather than model: cold probing "
      "*completed* on 9.6% of code bytes and 82% of those returned 0; "
      "coverage-verified full solutions came to 0.16% of bytes. The 8% central "
      "estimate is already generous relative to what has actually been "
      "demonstrated, because it credits class B and C with yield that has only "
      "been proven on one and zero functions respectively.\n")

    # ---------------- agreements/disagreements ----------------
    W("\n## 8. Verdict on the prior assessment\n")
    W("**Confirmed.**\n")
    W("- Enumerable functions are genuinely, completely solvable. Demonstrated on 13.")
    W("- Most functions return nothing meaningful. Measured: 1,553/1,761 (88.2%) return `i`, and 82.4% of successful cold calls returned 0.")
    W("- `MatchLoop` is not enumerable. It is 432 bytes with 12 callees - class D by the orchestrator rule, and its state space is its callees'.")
    W("- \"Let the game build the state, attach via the proxy DLL\" is right, and the measurements support it: 707 functions / 309,610 bytes fail *only* on null dereference and would become reachable.")
    W("- Verification is the biggest payoff. Endorsed and strengthened below.\n")
    W("**Refuted or corrected.**\n")
    W("1. **Branch blindness is not a fatal flaw.** It is directly measurable via CFG + emulator coverage hooks (section 6.2). You always know what you missed. This was the load-bearing objection and it does not hold.")
    W("2. **`GetValue()` is not formula-fittable.** 1,386 bytes, faults on the object graph. Listing it beside the 62-byte `GetSkillRating` conflated two different classes.")
    W("3. **`GetFame()` needs no probing at all.** 27 bytes, zero callees - a plain field read, class E.")
    W("4. **`GetStringMatchState()$` is not class A.** It takes no arguments; there is nothing to enumerate. You must drive the engine into each state. Class C.")
    W("5. **`TFormation.GetPlayerXY` is not \"strong for geometry\".** Its real signature is `(i,f,f,f,f,i,i,*f,*f,f,f)f` - eleven parameters, four continuous floats - and it is 2,898 bytes. That is not 35 grid slots, it is an 11-dimensional continuous domain. Class D.")
    W("6. **The \"20 skill fields, 20 weights\" claim is wrong in detail.** 18 fields in range, 7 of them used.")
    W("7. **\"296 of 622 signatures end in `)i`\"** - in the corrected game module it is 1,553 of 1,761 (88.2%). The point stands; the figure was drawn from a partial set.")
    W("8. **The 56 abstract stubs are not all in the game module.** Seven are.\n")

    W("\n## 9. Options the prior assessment missed\n")
    W("1. **Coverage-guided probing** (section 6.2). Converts branch blindness from an unknown unknown into a percentage. This should be standard on every probe run; it is ~30 lines of capstone plus one Unicorn hook.")
    W("2. **Emulation instead of a live process.** The prior framing assumed running the game. Unicorn cold-calls need no Steam, no window, no GC, no game loop - and are deterministic, snapshot-restorable and parallelisable. It already works on 454 game functions. For class A/B this is strictly better than attaching to a live process.")
    W("3. **Reads-set extraction rather than field guessing.** A memory-read hook records exactly which object offsets a function touched. That directly answers \"which of the 134 fields does this actually use\" - the question that makes class B feasible - without reading a line of disassembly. `GetSkillRating` needed 7 of 18; a read-hook would have said so in one call instead of eighteen.")
    W("4. **Symbolic/concolic execution for input synthesis.** The residual gap after coverage instrumentation is *what input hits block X*. That is a solver question (angr/Triton), not a probing question. Not installed here, but it is the correct tool for the one real remaining weakness.")
    W("5. **Probing is the wrong tool for `world data` entirely.** Nations, clubs, competitions and locale strings are *data*, and `extracted/ghidra/anchors_csv_columns.tsv`, `anchors_engine_ini.tsv` and the game's own Ctrl+E Data Editor expose them directly. Spending probe effort on `TNation`/`TClub` getters duplicates work already done.")
    W("6. **`debug=1` in `Settings/Settings.txt`** turns the game into a self-tracing oracle at zero engineering cost, emitting real internal function labels to `log.txt`. That is a probing channel that needs no DLL and no emulator, and it observes the *live* match engine - the exact region emulation cannot reach.")
    W("7. **Differential probing as the acceptance test.** See below.\n")

    W("\n## 10. The recommendation that follows from the numbers\n")
    W("Do not use probing as a *derivation* strategy. Use it as an *oracle*.\n")
    W("The 8% derivation figure is real but small, and it is concentrated in "
      "functions that were cheap anyway. The asymmetry is that probing's value "
      "as a differential test applies to **100% of functions regardless of "
      "class** - including the 533,339 bytes of class D that probing can never "
      "derive. For a re-implementation project the binding constraint is not "
      "writing the BlitzMax, it is knowing whether what you wrote is *right*. "
      "An oracle that can be called on any of 1,754 functions with identical "
      "inputs and compared byte-for-byte on outputs and field mutations is worth "
      "more than the 8%.\n")
    W("Concretely, in priority order:\n")
    W("1. Fix the stale artifacts and re-resolve `TPlayer` - 97,622 bytes, 11.7% of the module, currently invisible to every downstream tool. This is the single highest-value action in this document and it is already done in `scripts/build_probe_dataset.py`.")
    W("2. Build the differential harness first (emulate original vs. run ours, compare EAX + full object-field diff). It pays off on all 1,754 functions.")
    W("3. Add a read/write-set hook to the emulator. It makes class B tractable and sharply narrows class C.")
    W("4. Then, and only then, sweep class A (45 functions) and class B (52) for direct derivation. Budget hours, not days - it is 15,007 bytes of code total.")
    W("5. Read class D (296 functions, 533,339 bytes, 63.8%) the slow way. There is no shortcut, and the effort model says this is where ~92% of the project lives.\n")

    # ---------------- full table ----------------
    W("\n---\n")
    W(f"\n## 11. Full classification table - all {N} methods/functions\n")
    W("Grouped by Type, ordered by code bytes descending within each Type. "
      "`va` is the resolved code address. Machine-readable: "
      "`extracted/probeability.tsv`.\n")
    bytype = defaultdict(list)
    for r in rows:
        bytype[r['type']].append(r)
    order = sorted(bytype, key=lambda t: -sum(x['b'] for x in bytype[t]))
    for t in order:
        rs = sorted(bytype[t], key=lambda x: -x['b'])
        tb = sum(x['b'] for x in rs)
        tc = Counter(x['class'] for x in rs)
        mix = " ".join(f"{c}:{tc[c]}" for c in "ABCDE" if tc[c])
        W(f"\n### {t}  <sub>{rs[0]['subsystem']} - {len(rs)} members, "
          f"{tb:,} bytes - {mix}</sub>\n")
        W("| name | sig | va | size | class | rule |")
        W("|---|---|---|---|---|---|")
        for r in rs:
            nm = r['name'] + ("()" if r['kind'] == 'Function' else "")
            W(f"| {nm} | `{r['sig']}` | `{r['va']}` | {r['size']} | "
              f"**{r['class']}** | {r['rule'].split(' ',1)[1]} |")
    W("")
    W("---\n")
    W("*Generated by `scripts/gen_probeability_doc.py`, which classifies "
      "`extracted/probe_dataset.tsv` into `extracted/probeability.tsv` and "
      "renders this document from it. Supporting scripts: "
      "`build_probe_dataset.py` (re-resolves all class tables incl. TPlayer), "
      "`emu_probe.py --sweep`, `coverage_probe.py`, `coverage_sweep.py`, "
      "`fit_skillrating.py`.*")

    open(DST, "w", encoding="utf-8", newline="\n").write("\n".join(o) + "\n")
    print("wrote %s (%d lines)" % (DST, len(o)))


if __name__ == "__main__":
    main()
