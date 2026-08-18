"""Check adjudicated Global merges against the binary before any of them are applied.

    python scripts/validate_verdicts.py                  # every round, combined
    python scripts/validate_verdicts.py --emit           # ... and write the alias table
    python scripts/validate_verdicts.py --collect <journal.jsonl>     # harvest, then check
    python scripts/validate_verdicts.py --collect <journal.jsonl> --collect-out <out.json>
    python scripts/validate_verdicts.py <file.json>      # dry run on one file
    python scripts/validate_verdicts.py <file.json> --emit --emit-subset   # see below

--emit OVERWRITES extracted/global_alias_adjudicated.tsv. IT DOES NOT APPEND.
=============================================================================
So it must always be run against the COMBINED verdict set, never against one round's file.
Running it on a single round silently discards every merge adjudicated in earlier rounds:
emitting the 54 live-split verdicts on their own cut the table from 192 rows to 58 and
dropped 188 established merges, which the next build would have silently un-merged.

That is why COMBINING IS THE DEFAULT and there is no way to do it by hand any more. With no
file arguments this reads every extracted/unify_work/verdicts*.json, unions them, and
validates the union. Naming a file instead restricts the input to that file, and doing that
together with --emit -- the exact shape of the incident above -- is refused unless
--emit-subset is also passed, which prints a banner saying how many rows the overwrite is
about to drop. Combining is built in rather than left as a shell one-liner to
copy out of this docstring: a one-liner nobody runs is how the table loses rows.

Keep every round's verdicts_*.json. They are the only record from which the table can be
rebuilt, and rebuilding from them is the recovery path if this happens again.

COLLECTING A WORKFLOW'S VERDICTS  (--collect)
=============================================
Passes return their verdicts as a value, and that value is delivered as a notification and
TRUNCATED when large -- the live-split run returned ~116 KB and arrived clipped mid
sentence. The journal is the complete record: one {"type":"result",...} line per completed
pass carrying that pass's full return value, and it survives a partial run, so a workflow
that lost passes to an API error still yields every verdict the surviving passes produced.

--collect walks a journal for anything shaped like a verdict row, de-duplicates by
(name, decision) keeping the first (the second-look stage in some workflows re-reports a
name the first pass already returned), and writes {"ambiguous_results": [...]} into
extracted/unify_work/ where it joins the combined set. Validation then runs immediately,
over the combination, because collecting and checking were always run back to back and
collecting is not a step anyone should be able to stop after: nothing collected is trusted
until the checks below have had it.

WHY THIS EXISTS INSTEAD OF A SECOND REVIEWER
============================================
Name unification produces claims of the form "these two names are one slot" or "this name
lives at this address". Re-reading them by hand is slower than this script and weaker than
it, because every such claim is MECHANICALLY decidable against the same evidence:

  * two names that appear in one body are provably different slots -- no judgement needed;
  * two types are compatible or they are not, and class_tables.tsv settles it;
  * the claimed address either appears in the machine-code order of a body declaring that
    name, at the position that name's first use implies, or it does not.

So this checks all of it, deterministically and for free. A pass's prose reasoning is
kept for the audit trail but never trusted on its own.

WHAT EACH CHECK CATCHES
=======================
CO-OCCURRENCE   the one class of error the alignment cannot see for itself. It already
                caught g_snd_win/g_snd_lose and g_profile/g_np_nameinput being grouped
                onto one address.
TYPE            catches a merge across unrelated types (TSound into TChannel), which
                breaks the build with a message that looks unrelated to aliasing --
                "Duplicate identifier", "Unable to convert from 'Object' to 'TChannel'".
                Base/derived pairs are allowed; assemble.py resolves those by depth.
ADDRESS         catches a merge onto a slot the code never touches, i.e. an invented one.
LIVE-LIVE       a merge where BOTH names are already written somewhere is flagged rather
                than accepted. If the claim is right the merge is still correct, but this
                is where a wrong claim does the most damage -- two live variables fused,
                each corrupting the other -- so it wants a human eye.

Anything that fails is reported and NOT emitted. A rejected claim leaves a split, which
loses writes; an accepted wrong claim corrupts two variables. The asymmetry is the whole
reason this file is strict.
"""
import os
import re
import sys
import glob
import json
import collections

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import addr_oracle as AO                                        # noqa: E402
import unify_names as UN                                        # noqa: E402
import emit_unified_aliases as EU                               # noqa: E402
import module_body_types as MBT                                 # noqa: E402

OUT = os.path.join(ROOT, "extracted", "global_alias_adjudicated.tsv")
WORK = os.path.join(ROOT, "extracted", "unify_work")
VERDICT_GLOB = os.path.join(WORK, "verdicts*.json")


def written_globals():
    """Globals the assembled program actually writes -- for the live-live check."""
    p = os.path.join(ROOT, "src", "assembled", "nss5_assembled.bmx")
    if not os.path.exists(p):
        return set()
    text = open(p, encoding="utf-8-sig", errors="replace").read()
    body, written = [], set()
    for line in text.split("\n"):
        if line.lstrip().startswith("'"):
            continue
        # Leading \s* required: BlitzMax allows a Global declaration inside a function
        # body as the lazy-init idiom, and those are indented. Anchoring to column 0
        # missed every one of them, so a Global written only that way looked unwritten.
        # See the same fix and its measured cost in scripts/find_dead_globals.py.
        m = re.match(r"^\s*Global\s+(\w+)\s*:\s*[\w.]+(?:\s*\[[^\]]*\])?\s*=(?!=)", line)
        if m:
            written.add(m.group(1).lower())
            continue
        if re.match(r"^\s*Global\s+\w+\s*:", line):
            continue
        body.append(line)
    body = "\n".join(body)
    for pat in (r"(?m)^\s*(\w+)\s*(?::[-+*/|&~]?)?=(?!=)",
                r"(?m)^\s*(\w+)\s*\[[^\]]*\]\s*(?::[-+*/|&~]?)?=(?!=)",
                r"(?i)\bThen\s+(\w+)\s*(?::[-+*/|&~]?)?=(?!=)"):
        for m in re.finditer(pat, body):
            written.add(m.group(1).lower())
    return written


def walk_verdicts(node, out):
    """Collect every dict that looks like a verdict row, wherever it is nested."""
    if isinstance(node, dict):
        if "name" in node and "decision" in node:
            out.append(node)
            return
        for v in node.values():
            walk_verdicts(v, out)
    elif isinstance(node, list):
        for v in node:
            walk_verdicts(v, out)


def collect(journal, dest):
    """Pull adjudicated verdicts out of a workflow journal into a verdicts file."""
    if not os.path.exists(journal):
        raise SystemExit("no such journal: %s" % journal)

    rows, lines, results = [], 0, 0
    for line in open(journal, encoding="utf-8", errors="replace"):
        line = line.strip()
        if not line:
            continue
        lines += 1
        try:
            rec = json.loads(line)
        except ValueError:
            continue
        # A pass's return value may itself be a JSON string rather than an object.
        payload = rec.get("result", rec) if isinstance(rec, dict) else rec
        if isinstance(payload, str):
            try:
                payload = json.loads(payload)
            except ValueError:
                continue
        before = len(rows)
        walk_verdicts(payload, rows)
        if len(rows) > before:
            results += 1

    seen, uniq = set(), []
    for r in rows:
        k = (str(r.get("name", "")).lower(), r.get("decision"))
        if k in seen:
            continue
        seen.add(k)
        uniq.append(r)

    counts = collections.Counter(r.get("decision", "?") for r in uniq)
    if os.path.dirname(dest):
        os.makedirs(os.path.dirname(dest), exist_ok=True)
    with open(dest, "w", encoding="utf-8") as f:
        json.dump({"ambiguous_results": uniq}, f, indent=1)

    print("COLLECTED from %s" % os.path.basename(journal))
    print("  journal lines            : %d" % lines)
    print("  lines carrying verdicts  : %d" % results)
    print("  verdict rows             : %d  (%d after de-dup)" % (len(rows), len(uniq)))
    print("  %s" % ", ".join("%s=%d" % kv for kv in sorted(counts.items())))
    print("  -> %s" % dest)
    print()
    print("  NOTHING COLLECTED IS TRUSTED. The checks below re-derive every claim from")
    print("  NSS5.exe; the pass's own reasoning is kept for the audit trail only.")
    print()


def combine(paths):
    """Union the verdict files, de-duplicated, so --emit always sees every round.

    De-duplication is by (name, decision) for ambiguous rows and by the merge itself for
    type verdicts, which is what makes it safe to list verdicts_all.json alongside the
    rounds it was built from -- the union is idempotent.
    """
    amb, amb_seen = [], set()
    tv, tv_seen = [], set()
    contributed = []
    for p in paths:
        try:
            data = json.load(open(p, encoding="utf-8"))
        except (ValueError, OSError) as e:
            print("  !! skipping %s: %s" % (os.path.basename(p), e))
            continue
        if not isinstance(data, dict):
            print("  !! skipping %s: not a verdicts object" % os.path.basename(p))
            continue
        a0, t0 = len(amb), len(tv)
        for r in data.get("ambiguous_results") or []:
            k = (str(r.get("name", "")).lower(), r.get("decision"))
            if k in amb_seen:
                continue
            amb_seen.add(k)
            amb.append(r)
        for v in data.get("type_verdicts") or []:
            k = (str(v.get("canonical", "")).lower(),
                 tuple(sorted(str(a).lower() for a in (v.get("aliases") or []))),
                 str(v.get("address", "")), v.get("decision"))
            if k in tv_seen:
                continue
            tv_seen.add(k)
            tv.append(v)
        contributed.append((os.path.basename(p), len(amb) - a0, len(tv) - t0))
    return {"ambiguous_results": amb, "type_verdicts": tv}, contributed


def main():
    argv = sys.argv[1:]
    emit = "--emit" in argv
    emit_subset = "--emit-subset" in argv
    journal, collect_out, files, skip = None, None, [], set()
    for i, a in enumerate(argv):
        if i in skip:
            continue
        if a == "--collect" and i + 1 < len(argv):
            journal = argv[i + 1]
            skip.add(i + 1)
        elif a == "--collect-out" and i + 1 < len(argv):
            collect_out = argv[i + 1]
            skip.add(i + 1)
        elif not a.startswith("-"):
            files.append(a)
    if "--collect" in argv and not journal:
        raise SystemExit("--collect needs a journal path: --collect <journal.jsonl>")

    collected = None
    if journal:
        collected = collect_out or os.path.join(
            WORK, "verdicts_%s.json"
            % re.sub(r"\W+", "_", os.path.splitext(os.path.basename(journal))[0]))
        collect(journal, collected)

    if files:
        # A NAMED FILE IS A SUBSET, and --emit overwrites the whole table from whatever it
        # was given. This is the 192-rows-to-58 incident, so it is refused by default and
        # only ever proceeds when the operator has said so in a second, separate flag.
        paths = files
        allp = sorted(glob.glob(VERDICT_GLOB))
        if emit and not emit_subset:
            full, _c = combine(allp)
            part, _c = combine(paths)
            raise SystemExit(
                "\n"
                "REFUSING TO EMIT FROM A SUBSET\n"
                "==============================\n"
                "  --emit OVERWRITES extracted/global_alias_adjudicated.tsv from whatever\n"
                "  it validated. You named %d file(s) carrying %d ambiguous rows, while\n"
                "  %s holds %d across %d files.\n"
                "  Emitting the subset would drop the rest, exactly as emitting one round\n"
                "  on its own once cut the table from 192 rows to 58.\n"
                "\n"
                "  Drop the filename to validate and emit the combined set:\n"
                "      python scripts/validate_verdicts.py --emit\n"
                "  If you really mean to rebuild the table from these files alone, say so:\n"
                "      python scripts/validate_verdicts.py %s --emit --emit-subset\n"
                % (len(paths), len(part["ambiguous_results"]),
                   os.path.relpath(WORK, ROOT).replace("\\", "/"),
                   len(full["ambiguous_results"]), len(allp), " ".join(paths)))
        if emit:
            print("!! EMITTING FROM A SUBSET -- %s will be rebuilt from %s ALONE, and any\n"
                  "!! merge adjudicated elsewhere will be dropped from it."
                  % (os.path.relpath(OUT, ROOT).replace("\\", "/"), ", ".join(paths)))
            print()
    else:
        paths = sorted(glob.glob(VERDICT_GLOB))
        if not paths and not collected:
            raise SystemExit("no verdict files in %s" % VERDICT_GLOB)

    # A collection written outside extracted/unify_work/ would not be picked up by the
    # glob, and silently validating everything EXCEPT what was just collected is the worst
    # possible outcome of a --collect run. Add it explicitly.
    if collected:
        have = {os.path.normcase(os.path.abspath(p)) for p in paths}
        if os.path.normcase(os.path.abspath(collected)) not in have:
            paths = paths + [collected]

    data, contributed = combine(paths)
    print("VERDICT INPUT")
    for name, na, nt in contributed:
        print("  %-32s %4d ambiguous  %3d type" % (name, na, nt))
    print("  %-32s %4d ambiguous  %3d type"
          % ("COMBINED", len(data["ambiguous_results"]), len(data["type_verdicts"])))
    print()

    bodies = AO.collect()
    excl = UN.excluded()
    par = EU.parents()
    co = EU.cooccurrence()
    live = written_globals()

    types, touched = {}, collections.defaultdict(set)
    for b in bodies:
        kinds, deref = UN.slot_kinds(b["decomp"])
        ok = {a for a in b["addrs"] if a in kinds and a in deref and a not in excl}
        for n, t in b["types"].items():
            types.setdefault(n, t)
            touched[n] |= ok

    # ---- address pins -------------------------------------------------------------
    # A relocation says "this name does not live at the address the solver gave it, it
    # lives here". That is not a merge; it is a correction to the address map, and it has
    # to be fed back in BEFORE grouping so every downstream guard sees the corrected
    # picture. A RESOLVED ambiguous name is the same kind of statement.
    pins, pin_reject = {}, []
    for v in data.get("type_verdicts", []):
        for r in (v.get("relocate") or []):
            pins[r["name"].lower()] = (r["address"], v.get("evidence", ""))
    for r in data.get("ambiguous_results", []):
        if r.get("decision") == "RESOLVED" and r.get("address"):
            pins.setdefault(r["name"].lower(), (r["address"], r.get("evidence", "")))
    # The bootstrap says what it allocates -- see scripts/module_body_types.py. That
    # outranks any alignment, because `AllocChannel()` can only return a TChannel however
    # the touch list reads. Without this check, seven TSound names were pinned onto the
    # TChannel slot 0x00C6F090, all from PlaySound(sound, channel) sites read in the wrong
    # argument order; two of them were the two arguments of the SAME call, which cannot
    # both be one address.
    mbt = MBT.types_by_address()

    for name, (addr, ev) in sorted(pins.items()):
        try:
            a = int(addr, 16)
        except (ValueError, TypeError):
            pin_reject.append((name, addr, "unparseable address"))
            continue
        if touched.get(name) and a not in touched[name]:
            pin_reject.append((name, addr,
                               "no body declaring %s touches %08x" % (name, a)))
        elif MBT.conflicts(addr, types.get(name), mbt):
            known = mbt[MBT.norm(addr)]
            pin_reject.append((name, addr,
                               "MODULE-BODY TYPE: the bootstrap %s at this address as "
                               "%s:%s, so %s:%s cannot live here"
                               % (known[2], known[0], known[1],
                                  name, types.get(name, "?"))))
    for name, addr, _why in pin_reject:
        pins.pop(name, None)

    claims = []
    for v in data.get("type_verdicts", []):
        if v.get("decision") != "MERGE" or not v.get("canonical"):
            continue
        for a in v.get("aliases", []):
            claims.append((a.lower(), v["canonical"].lower(),
                           v.get("address", ""), v.get("evidence", "")))
    for r in data.get("ambiguous_results", []):
        if r.get("decision") == "RESOLVED" and r.get("merge_into"):
            claims.append((r["name"].lower(), r["merge_into"].lower(),
                           r.get("address", ""), r.get("evidence", "")))

    accepted, rejected = [], []
    for alias, canon, addr, ev in claims:
        if alias == canon:
            continue
        why = None
        if canon in co.get(alias, ()):
            why = "CO-OCCUR: the two names share a body, so they are different slots"
        elif alias in types and canon in types and \
                not EU.types_mergeable(types[alias], types[canon], par):
            why = "TYPE: %s vs %s are unrelated" % (types[alias], types[canon])
        else:
            try:
                a = int(addr, 16) if addr else None
            except ValueError:
                a = None
            if a is not None and touched.get(alias) and a not in touched[alias]:
                why = ("ADDRESS: %08x is not touched by any body declaring %s" % (a, alias))
            elif addr and (MBT.conflicts(addr, types.get(alias), mbt) or
                           MBT.conflicts(addr, types.get(canon), mbt)):
                known = mbt[MBT.norm(addr)]
                why = ("MODULE-BODY TYPE: the bootstrap %s at %s as %s:%s -- merging "
                       "%s:%s into %s:%s would put the wrong type in that slot"
                       % (known[2], addr, known[0], known[1],
                          alias, types.get(alias, "?"), canon, types.get(canon, "?")))
        if why:
            rejected.append((alias, canon, why, ev))
        else:
            flag = "LIVE-LIVE (both already written)" \
                if alias in live and canon in live else ""
            accepted.append((alias, canon, addr, flag, ev))

    # ---- reversed pairs ---------------------------------------------------------------
    # Two rounds can rule the same address in opposite directions -- A->B from one and
    # B->A from another. Both are saying "these are one slot"; they differ only on which
    # name survives, so the FINDING is right and only the direction is contradictory.
    # Emitting both writes a 2-cycle into the alias graph, and emit_unified_aliases.py
    # then refuses to write at all ("alias-graph cycles ... REFUSING to write"), which
    # loses every other merge in the round.
    #
    # This happened with g_userpath <-> g_screen_mainmenu_int26 at 0x00C6E9A8. Collecting
    # rounds into one file cannot catch it by de-duplicating on NAME, because the two rows
    # have different names.
    #
    # Resolve toward the better-established sink: keep the direction pointing at whichever
    # name more other aliases already point at. g_userpath was the target of g_optroot and
    # g_savedir as well, g_screen_mainmenu_int26 of nothing else -- and it is a placeholder
    # name carrying "int26" for a String. Ties break on name order so runs reproduce.
    incoming = collections.Counter(c for _a, c, _ad, _f, _e in accepted)
    pairs = {(a, c) for a, c, _ad, _f, _e in accepted}
    drop = set()
    for a, c in sorted(pairs):
        if (c, a) not in pairs or (a, c) in drop or (c, a) in drop:
            continue
        loser = (a, c) if (incoming[c], c) < (incoming[a], a) else (c, a)
        drop.add(loser)
    if drop:
        kept = []
        for row in accepted:
            a, c = row[0], row[1]
            if (a, c) in drop:
                rejected.append((a, c,
                                 "REVERSED PAIR: %s -> %s is also claimed; keeping the "
                                 "direction toward the better-established sink (%d other "
                                 "aliases point at %s, %d at %s)"
                                 % (c, a, incoming[a], a, incoming[c], c), row[4]))
            else:
                kept.append(row)
        accepted = kept

    print("VERDICT VALIDATION")
    print("  merge claims        : %d" % len(claims))
    print("  accepted            : %d" % len(accepted))
    print("  rejected            : %d" % len(rejected))
    flagged = [r for r in accepted if r[3]]
    print("  accepted but FLAGGED: %d  (both names already written -- review these)"
          % len(flagged))
    print()
    for alias, canon, why, ev in rejected[:25]:
        print("  REJECT %-30s -> %-28s %s" % (alias, canon, why))
    if flagged:
        print()
        for alias, canon, addr, flag, ev in flagged[:15]:
            print("  FLAG   %-30s -> %-28s %s" % (alias, canon, addr))

    needs_code = [r for r in data.get("ambiguous_results", [])
                  if r.get("decision") == "NEEDS_CODE"]
    unres = [r for r in data.get("ambiguous_results", [])
             if r.get("decision") == "UNRESOLVED"]
    print()
    print("  ambiguous -> NEEDS_CODE (writer body missing): %d" % len(needs_code))
    print("  ambiguous -> UNRESOLVED                      : %d" % len(unres))

    print()
    print("  address pins accepted : %d" % len(pins))
    print("  address pins rejected : %d" % len(pin_reject))
    for name, addr, why in pin_reject[:12]:
        print("      %-30s %-12s %s" % (name, addr, why))

    if emit:
        pin_path = os.path.join(ROOT, "extracted", "global_address_adjudicated.tsv")
        with open(pin_path, "w", encoding="utf-8", newline="") as f:
            f.write("# Adjudicated Global addresses. Each was decided by reading the\n")
            f.write("# original function's machine code, then checked here against the\n")
            f.write("# same binary. unify_names.py pins these before solving.\n")
            f.write("name\taddress\tevidence\n")
            for name, (addr, ev) in sorted(pins.items()):
                f.write("%s\t0x%08X\t%s\n"
                        % (name, int(addr, 16), ev.replace("\t", " ")[:220]))
        print("\nwrote %s (%d pins)" % (pin_path, len(pins)))

        with open(OUT, "w", encoding="utf-8", newline="") as f:
            f.write("# GENERATED by scripts/validate_verdicts.py from adjudicated\n")
            f.write("# merges, each checked against NSS5.exe for co-occurrence, type\n")
            f.write("# compatibility and machine-code address membership.\n")
            f.write("address\talias\tcanonical\tevidence\n")
            for alias, canon, addr, flag, ev in accepted:
                f.write("%s\t%s\t%s\t%s\n"
                        % (addr or "-", alias, canon,
                           (flag + " " if flag else "") + ev.replace("\t", " ")[:200]))
        print("\nwrote %s (%d rows)" % (OUT, len(accepted)))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
