"""Resolve `!! UNRESOLVED CONFLICT` Global type disagreements by INHERITANCE DEPTH.

Run after scripts/assemble.py whenever a merge round exposes new conflicts, then rebuild:

    python scripts/assemble.py
    python scripts/resolve_type_conflicts.py
    python scripts/assemble.py

WHY THIS KEEPS HAPPENING
------------------------
Unifying two names for one address makes their TYPE declarations meet for the first time.
While the names were separate, each body got its own Global and no check could see the
disagreement -- the split was hiding it, not resolving it. So every alias-merge round
surfaces a fresh batch, and each one breaks the build with a message that looks unrelated
to aliasing: "Identifier 'id' not found", "Unable to convert from 'Object' to 'TChannel'",
"Identifier 'GetText' not found".

WHY ALPHABETICAL IS THE WRONG TIE-BREAK
---------------------------------------
assemble.py picks alphabetically and says so in its own output ("emitted ALPHABETICALLY,
i.e. arbitrarily"). That systematically favours the BASE type: Object < TChannel,
TGadget < TInputBox, Object < TTeam. The base type is always the weaker claim -- it is
what a body produces when it only compares the value against Null, or when the type was
inferred rather than declared. Choosing it breaks every member access through the Global.

THE RULE
--------
If every claim for a Global is an ancestor of one particular claim, take that most-derived
claim. It is the only choice that satisfies all use sites: it supplies the members the
specific bodies call, and a Null comparison remains legal on a derived type, so the bodies
that declared an ancestor lose nothing.

Conflicts that are NOT a single inheritance chain (two unrelated types) are left alone and
reported -- those are genuine disagreements needing a human.
"""
import os
import re

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SRC = os.path.join(ROOT, "src", "assembled", "nss5_assembled.bmx")
EXT = os.path.join(ROOT, "src", "assembled", "nss5_external.bmx")
OVER = os.path.join(ROOT, "extracted", "globals_type_overrides.tsv")

CONFLICT = re.compile(r"^Global (\w+):(\S+)\s*'\s*!! UNRESOLVED CONFLICT: (.+)$", re.M)

# `g_kits_home = TClub.SelectById(...)` / `g_x = New TFoo` -- the types actually stored.
ASSIGN = re.compile(
    r"^\s*(g_\w+)\s*=\s*(?:New\s+)?([A-Z]\w*)\s*[.(]", re.M)
TREES = ("src/recovered", "src/recovered_unverified", "src/recovered_module",
         "src/module_body")


def assigned_types(name):
    """Concrete types the corpus stores into this Global.

    Read from the recovered bodies rather than the assembled file, because the assembled
    file is what we are about to regenerate -- and because a body's own source is the
    statement of intent. Only `= TFoo.Something(...)` and `= New TFoo` are counted; a plain
    `= someLocal` says nothing about the type without following the local.
    """
    want, out = name.lower(), set()
    for tree in TREES:
        d = os.path.join(ROOT, tree)
        if not os.path.isdir(d):
            continue
        for fn in os.listdir(d):
            if not fn.endswith(".bmx"):
                continue
            try:
                txt = open(os.path.join(d, fn), encoding="utf-8", errors="replace").read()
            except OSError:
                continue
            if want not in txt.lower():
                continue
            code = "\n".join(l for l in txt.split("\n") if not l.lstrip().startswith("'"))
            for m in ASSIGN.finditer(code):
                if m.group(1).lower() == want:
                    out.add(m.group(2))
    return out


def fits(cand, got, base, ancestors):
    """True if `cand` can hold every type in `got` -- i.e. it is each one's ancestor."""
    return all(base(cand) == base(g) or base(cand) in ancestors(base(g)) for g in got)


def main():
    text = open(SRC, encoding="utf-8-sig", errors="replace").read()
    all_text = text
    if os.path.exists(EXT):
        all_text += "\n" + open(EXT, encoding="utf-8-sig", errors="replace").read()

    parent = {}
    for m in re.finditer(r"^Type\s+(\w+)(?:\s+Extends\s+(\w+))?", all_text, re.M):
        parent[m.group(1).lower()] = (m.group(2) or "Object").lower()

    def ancestors(t):
        t, out, seen = t.lower(), [], set()
        while t and t not in seen:
            seen.add(t)
            out.append(t)
            if t == "object":
                break
            t = parent.get(t, "object")
        return out

    def base(c):
        return c.split(".")[-1].split("[")[0].lower()

    existing = set()
    if os.path.exists(OVER):
        for line in open(OVER, encoding="utf-8", errors="replace"):
            if line.strip() and not line.startswith("#"):
                existing.add(line.split("\t")[0].strip().lower())

    resolved, manual = [], []
    for m in CONFLICT.finditer(text):
        name, chosen = m.group(1), m.group(2)
        claims = [c.strip() for c in m.group(3).split(" vs ")]
        if name.lower() in existing:
            continue
        win = None
        for c in claims:
            if all(base(c) == base(o) or base(o) in ancestors(base(c)) for o in claims):
                if win is None or len(ancestors(base(c))) > len(ancestors(base(win))):
                    win = c

        # DEEPEST IS NOT ALWAYS RIGHT -- CHECK WHAT IS ACTUALLY ASSIGNED TO THE GLOBAL.
        #
        # Picking the deepest claim assumes the shallower ones are imprecision. That holds
        # for Object vs TImage. It is wrong when a Global is assigned from two SIBLING
        # subclasses, where the base is not vagueness but the only type that fits both.
        #
        # TScreen_Kits.SetUpScreen assigns g_kits_home from TClub.SelectById AND from
        # TNation.SelectById. This rule chose TClub (deeper than TBase_Team) and wrote it
        # here, and the build failed with "Unable to convert from 'TNation' to 'TClub'".
        # Worse, main() skips any name already present in this file, so a wrong auto-row
        # is permanent until a human edits it.
        #
        # So: the declared type must be an ancestor-or-equal of EVERY type the corpus
        # assigns to the Global. If the deepest claim is not, fall back to the shallowest
        # claim that is -- their join.
        if win is not None:
            got = assigned_types(name)
            if got and not fits(win, got, base, ancestors):
                better = [c for c in claims if fits(c, got, base, ancestors)]
                if better:
                    win = min(better, key=lambda c: len(ancestors(base(c))))
                else:
                    manual.append((name, claims + ["assigned:%s" % ",".join(sorted(got))]))
                    continue

        if win is None:
            manual.append((name, claims))
        elif win.lower() != chosen.lower():
            resolved.append((name, win, claims))

    if resolved:
        with open(OVER, "a", encoding="utf-8") as f:
            for name, win, claims in resolved:
                f.write("%s\t%s\t%s\n" % (name, win,
                        "Auto-resolved by scripts/resolve_type_conflicts.py (inheritance "
                        "depth). Claims: %s -- all ancestors of %s, so they describe one "
                        "slot at different precisions, not a disagreement. Surfaced when an "
                        "alias merge unified this slot's names; while they were separate "
                        "each body had its own Global and nothing could see the mismatch. "
                        "assemble.py's alphabetical tie-break favours the BASE type, which "
                        "breaks every member access through the Global."
                        % (", ".join(claims), win)))
    print("resolved by inheritance depth : %d" % len(resolved))
    for n, w, c in resolved:
        print("   %-30s -> %-14s (was %s)" % (n, w, ", ".join(c)))
    if manual:
        print("\nNEEDS A HUMAN -- claims are not one inheritance chain: %d" % len(manual))
        for n, c in manual:
            print("   %-30s %s" % (n, " vs ".join(c)))
    if resolved:
        print("\nre-run scripts/assemble.py to apply.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
