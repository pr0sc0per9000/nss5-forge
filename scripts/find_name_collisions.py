"""One IDENTIFIER standing for two module-Global SLOTS. The mirror of find_live_splits.py.

    python scripts/find_name_collisions.py             # report
    python scripts/find_name_collisions.py --check     # exit 1 on anything not in the baseline
    python scripts/find_name_collisions.py --baseline  # rewrite the baseline from this run

WHY THIS EXISTS
===============
find_live_splits.py finds one address wearing two names: the assembler emits two variables
where the original had one, and writes are lost. This finds the opposite, and it is worse.
When two bodies pick the SAME identifier for DIFFERENT addresses, assemble.py's
apply_alias_map rewrites by NAME across the whole corpus, so it emits ONE variable where
the original has two. Two subsystems then share storage, and which one wins is decided by
construction order rather than by anything in the source.

It does not look like a naming problem from the outside. Every instance found so far
presented as an unrelated gameplay bug:

    g_pairs_time on the MilliSecs clock       the pairs minigame froze face-up
    g_prg_achievements over two bars          the title-bar energy gauge read "1%"
    g_img_relationships over two icons        `If Not g_img_relationships` skipped the whole
                                              image block, so Fame drew "0%" and the
                                              achievements button had no icon
    g_screen over six TScreen slots           unpausing a match set the background on the
                                              data-editor screen
    g_object872 over MessageBg and a kit      refreshing the kit screen replaced the
                                              message-box background with a shirt texture
    g_matchspeed over length and speed        the match clock ran ten times too slow

None of those is visible to a byte comparison, because a Global reaches compiled output
only as an absolute address and the oracle masks relocations. A body can be byte-identical
and still read the wrong memory. That is exactly why this has to be checked structurally.

HOW A SLOT IS DECIDED
=====================
Candidate addresses for a name are gathered GENEROUSLY -- every address any header pairs
with it, plus every address an alias table files it under. Which candidate a body actually
means is then decided by the ORIGINAL function's machine code: addr_oracle.collect() lists
every module-global address the original touches, and a candidate the code never touches
cannot be what the body meant.

Recall costs nothing here and precision would cost a lot, because the decision is made from
the binary either way. Being stingy with candidates is what makes a real collision read as
clean: measured on this corpus, swapping one prose regex for another flipped 30 of 76
verdicts in both directions while the machine evidence never moved.

THE ORDERED PAIRING IS NOT USED, AND THE PROSE REGEX IS NOT TRUSTED ALONE
========================================================================
addr_oracle's ordered zip (name[i] <-> address[i]) self-reports 83% against hand-verified
pairs: one phantom dword or one folded reference shifts every later name by one slot. Set
membership is a literal dword search and only ever fails open, so that is what decides.

Header prose supplies candidates only, and it is parsed per LINE by token position because
the corpus writes its Global tables both ways round, frequently several pairs to a line:

    '     0x00C66944 g_img_shirt:TImage        0x00C66948 g_img_finances:TImage
    '     g_sr_panStats:TPanel   0x00C687C8    g_sr_tblSeason:TTable   0x00C687CC

A pattern that only binds ADDRESS-then-NAME reads the second layout off by one and pairs
0x00C687C8 with g_sr_tblSeason, which is 0x00C687CC. That misreading alone invented a
collision in TScreen_SeasonReview that the machine code refutes.

THE BASELINE
============
The corpus starts with a backlog, so a gate that fails on any collision at all fails on
day one and gets switched off. `--check` fails only on collisions absent from
extracted/name_collisions_baseline.tsv, which makes the ratchet one-directional: existing
ones may be fixed and removed, new ones cannot be added. The baseline is meant to shrink to
nothing; when it is empty, drop the file and let --check fail on any collision.
"""
import os
import re
import sys
import collections

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

import addr_oracle as AO                                             # noqa: E402

BASELINE = os.path.join(ROOT, "extracted", "name_collisions_baseline.tsv")
TREES = ["src/recovered", "src/recovered_unverified", "src/recovered_pending",
         "src/recovered_module", "src/module_body"]
ALIAS_TABLES = ("global_alias_map.tsv", "global_alias_unified.tsv",
                "global_alias_writers.tsv", "global_alias_adjudicated.tsv",
                "global_alias_overrides.tsv", "global_alias_map_skipped.tsv",
                "global_address_adjudicated.tsv")

PRAGMA = re.compile(r"^\s*'!\s*Global\s+(\w+)\s*:", re.M | re.I)
ADDR = re.compile(r"0x00C[0-9A-Fa-f]{5}", re.I)
NAME = re.compile(r"\bg_\w+", re.I)


def line_pairs(line):
    """name <-> address pairs on ONE header line, bound by token position.

    Both header layouts are covered by reading the tokens in order and zipping them; a line
    whose counts disagree is refused rather than guessed at, which is what keeps the
    `0xAAA -> name (0xBBB = something else)` shape from inventing a pair.
    """
    toks = sorted([(m.start(), "a", int(m.group(0), 16)) for m in ADDR.finditer(line)] +
                  [(m.start(), "n", m.group(0).lower()) for m in NAME.finditer(line)])
    addrs = [t[2] for t in toks if t[1] == "a"]
    names = [t[2] for t in toks if t[1] == "n"]
    if not addrs or len(addrs) != len(names):
        return []
    return list(zip(names, addrs))


def scan_corpus():
    """-> (name -> [body], body -> {name: {addr}}, name -> {addr} from prose anywhere)."""
    decl = collections.defaultdict(list)
    prose = {}
    anywhere = collections.defaultdict(set)
    for tree in TREES:
        d = os.path.join(ROOT, tree)
        if not os.path.isdir(d):
            continue
        for fn in sorted(os.listdir(d)):
            if not fn.endswith(".bmx"):
                continue
            txt = open(os.path.join(d, fn), encoding="utf-8", errors="replace").read()
            comments, code = [], []
            for line in txt.split("\n"):
                (comments if line.lstrip().startswith("'") else code).append(line)
            for line in comments:
                for n, a in line_pairs(line):
                    anywhere[n].add(a)
            declared = {m.group(1).lower() for m in PRAGMA.finditer(txt)}
            if not declared:
                continue
            mine = collections.defaultdict(set)
            for line in comments:
                for n, a in line_pairs(line):
                    if n in declared:
                        mine[n].add(a)
            prose[fn[:-4]] = mine
            used = {m.group(1).lower() for m in re.finditer(r"\b(g_\w+)\b", "\n".join(code))}
            for n in declared & used:
                decl[n].append(fn[:-4])
    return decl, prose, anywhere


def table_addresses():
    """name -> every address an alias table files it under, either side of the row."""
    out = collections.defaultdict(set)
    for fn in ALIAS_TABLES:
        p = os.path.join(ROOT, "extracted", fn)
        if not os.path.exists(p):
            continue
        for line in open(p, encoding="utf-8", errors="replace"):
            if line.startswith("#"):
                continue
            f = line.rstrip("\n").split("\t")
            if len(f) >= 2 and f[0].strip().lower().startswith("0x"):
                try:
                    a = int(f[0].strip(), 16)
                except ValueError:
                    continue
                for c in f[1:3]:
                    if c.strip().lower().startswith("g_"):
                        out[c.strip().lower()].add(a)
            elif (len(f) >= 2 and f[0].strip().lower().startswith("g_")
                  and f[1].strip().lower().startswith("0x")):
                try:
                    out[f[0].strip().lower()].add(int(f[1].strip(), 16))
                except ValueError:
                    pass
    return out


def collisions():
    """-> [(name, {addr: [bodies]}, [bodies whose slot could not be decided])]"""
    decl, prose, anywhere = scan_corpus()
    tabled = table_addresses()
    bodies = {b["file"]: b for b in AO.collect()}

    rows = []
    for name, users in sorted(decl.items()):
        if len(users) < 2:
            continue
        cand = set(anywhere.get(name, ())) | set(tabled.get(name, ()))
        if len(cand) < 2:
            continue
        byslot = collections.defaultdict(list)
        ambiguous, undecided = [], []
        # Pass 1: a body whose original touches exactly ONE candidate has settled it. This
        # is the only step that may create a slot, so a body that touches both candidates
        # can never invent a second one on the strength of its own prose.
        for base in users:
            b = bodies.get(base)
            touched = set(b["addrs"]) if b else set()
            hits = {a for a in cand if a in touched}
            if len(hits) == 1:
                byslot[next(iter(hits))].append(base)
            else:
                ambiguous.append((base, hits))
        # Pass 2, in decreasing order of evidence. Prose is last because it is wrong often
        # enough to matter: TTraining.UpdateSounds' header runs three channel addresses and
        # two unrelated names onto one line, and TScreen.DoHelp's wraps a pair across two,
        # and both mis-parses invent a slot that the machine code refutes.
        for base, hits in ambiguous:
            b = bodies.get(base)
            claimed = prose.get(base, {}).get(name, set())
            zipped = None
            if b and b["exact"]:
                z = dict(zip(b["use"], b["addrs"]))
                zipped = z.get(name)
            if zipped in hits:
                byslot[zipped].append(base)
            elif len(hits & set(byslot)) == 1:
                byslot[next(iter(hits & set(byslot)))].append(base)
            elif len(claimed & hits) == 1:
                byslot[next(iter(claimed & hits))].append(base)
            elif not hits and len(claimed) == 1 and next(iter(claimed)) in byslot:
                byslot[next(iter(claimed))].append(base)
            else:
                undecided.append(base)
        if len(byslot) > 1:
            rows.append((name, dict(byslot), undecided))
    return rows


def load_baseline():
    if not os.path.exists(BASELINE):
        return {}
    out = {}
    for line in open(BASELINE, encoding="utf-8", errors="replace"):
        if line.startswith("#") or not line.strip():
            continue
        f = line.rstrip("\n").split("\t")
        if len(f) >= 2:
            out[f[0].strip().lower()] = f[1].strip()
    return out


def key(byslot):
    return ",".join("0x%08X" % a for a in sorted(byslot))


def main():
    rows = collisions()
    base = load_baseline()

    if "--baseline" in sys.argv:
        with open(BASELINE, "w", encoding="utf-8") as fh:
            fh.write("# Known one-name-two-slots collisions, the backlog "
                     "find_name_collisions.py --check tolerates.\n")
            fh.write("# A row here is a defect that has not been fixed yet, not a decision "
                     "that it is acceptable.\n")
            fh.write("# Remove the row when the name is split; never add one to silence a "
                     "new collision.\n")
            fh.write("name\tslots\tbodies\n")
            for name, byslot, _u in rows:
                fh.write("%s\t%s\t%s\n"
                         % (name, key(byslot),
                            " | ".join("0x%08X=%s" % (a, ",".join(sorted(v)))
                                       for a, v in sorted(byslot.items()))))
        print("wrote %d rows to %s" % (len(rows), os.path.relpath(BASELINE, ROOT)))
        return 0

    new = [r for r in rows if base.get(r[0]) != key(r[1])]
    print("NAME COLLISIONS -- one identifier, more than one module-Global slot")
    print("  collisions found : %d" % len(rows))
    print("  in the baseline  : %d" % (len(rows) - len(new)))
    print("  NOT in the baseline : %d" % len(new))
    print()
    for name, byslot, undecided in rows:
        mark = "  NEW" if base.get(name) != key(byslot) else ""
        print("%-32s %d slots%s" % (name, len(byslot), mark))
        for a in sorted(byslot):
            print("      0x%08X  %s" % (a, ", ".join(sorted(byslot[a]))[:150]))
        if undecided:
            print("      undecided   %s" % ", ".join(sorted(undecided))[:150])
    if "--check" in sys.argv:
        if new:
            print()
            print("FAIL: %d collision(s) not in %s."
                  % (len(new), os.path.relpath(BASELINE, ROOT)))
            print("Two bodies are using one identifier for two different slots in NSS5.exe, "
                  "so assemble.py will emit one variable for both. Rename the body whose "
                  "subsystem is smaller to the name the slot's construction site uses.")
            return 1
        print()
        print("OK: no collision outside the baseline.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
