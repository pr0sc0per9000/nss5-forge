"""Generate extracted/global_alias_map.tsv -- one canonical Global name per address.

Where the alias-split detectors report the problem, this script decides what to do about
it, and writes the decision to a table assemble.py consumes.

THE PROBLEM, RESTATED
---------------------
Every body is verified alone in a probe, where a Global's NAME cannot matter -- the probe
declares exactly what the pragma asks for. So independent passes can give one address
several different names and every body still MATCHes. 0x00C5B1FC is `g_matchstate` in
TBall.CheckSideLines, `g_matchmode` in TBall.HitPost and `g_player_int01` in TBall.Kick.

assemble.py emits one Global per distinct name, so the assembled program gets three
independent Ints where the original had one. Writes through one name are invisible through
the others. Nothing crashes: BlitzMax release builds return 0 for a null-deref rather than
faulting (language guide 18.26), so the program silently does less than it should. This is
why "the corpus composes and BUILD OK" was never the same claim as "the game works".

WHY THIS DOES NOT EDIT src/recovered/
-------------------------------------
A corpus-wide sed on src/recovered/ is forbidden (docs/RULES.md 5.3): it is a live tree
with several jobs writing to it concurrently. Renaming in place would also break every
byte-verified body it touched and light up reverify.py with
~177 false regressions, destroying the regression suite's signal exactly when it is most
needed. Instead this emits a MAPPING, and assemble.py applies it to the generated source
only. The verified corpus stays byte-identical and reverify.py stays green.

CHOOSING THE CANONICAL NAME
---------------------------
In priority order:
  1. the name extracted/globals_final.tsv gives that address, if it is one of the
     candidates -- that table is the project's own address->name authority;
  2. otherwise the candidate used in the most files, since renaming fewer references is
     less risk;
  3. ties broken alphabetically, so the output is deterministic across runs.

EVIDENCE STANDARD
-----------------
A name is only accepted as belonging to an address when SOME FILE BOTH declares that name
in a '!Global pragma AND mentions that address in its header. An address merely appearing
in prose near a word is not enough -- that is how a bad merge would happen, and a bad merge
silently fuses two genuinely distinct Globals, which is worse than the split it fixes.
"""
import os
import re
import collections

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
TREES = [os.path.join(ROOT, "src", "recovered"),
         os.path.join(ROOT, "src", "recovered_module")]
GLOBALS_FINAL = os.path.join(ROOT, "extracted", "globals_final.tsv")
OUT = os.path.join(ROOT, "extracted", "global_alias_map.tsv")

ADDR_NAME = re.compile(r"0x([0-9A-Fa-f]{6,8})\s*[:/]?\s*([A-Za-z_]\w*)")
# ...and the REVERSED spelling, `name:Type   ' 0xADDR`. Headers write the pairing both ways
# and an address-first-only regex silently misses half of them. That is a crash hazard:
# TCombo.CreateCombo.bmx:8 has "0x00C62D9C g_comboimg : TImage" (matched) while
# TCombo.Draw.bmx:16 has "Global g_combo_arrow:TImage    ' 0x00c62d9c" (missed) -- same
# slot, so CreateCombo loads Combo.png into g_comboimg while TCombo.Draw draws
# g_combo_arrow, which nothing ever assigns. DrawImage then dereferences Null on the first
# frame of any screen carrying a combo box.
#
# The address must be separated from the type by a COMMENT MARKER, i.e. the genuine
# "Global g_combo_arrow:TImage    ' 0x00c62d9c" idiom. Without that requirement this regex
# reads straight past the end of one pair into the next one's address, because headers
# routinely put two pairs on a line:
#     '   0x00C6EFE4 g_screen_w:Int       0x00C6EFE8 g_screen_h:Int
# There, "g_screen_w:Int   ...   0x00C6EFE8" matches and binds the WIDTH to the HEIGHT's
# slot. Measured damage without the comment-marker requirement: 425 spurious AMBIGUOUS
# rejections (a name that picks up a second, bogus address is refused wholesale), and a
# merge proposal that folds g_screen_w into g_engine_int163 -- silently swapping screen
# width and height across 41 read sites. The requirement in the pattern below is what
# keeps both out.
NAME_ADDR = re.compile(r"\b([A-Za-z_]\w*)\s*:\s*[A-Za-z_][\w\[\]]*\s*'\s*0x([0-9A-Fa-f]{6,8})")
ADDR_ANY = re.compile(r"0x([0-9A-Fa-f]{6,8})")
GLOBAL_DECL = re.compile(r"'!\s*Global\s+(\w+)\s*:", re.I)
GLOBAL_DECL_TYPED = re.compile(r"'!\s*Global\s+(\w+)\s*:\s*([A-Za-z_]\w*(?:\s*\[\s*\])?)", re.I)

# ---------------------------------------------------------------------------
# Two rejection filters. Both exist because a WRONG MERGE IS WORSE THAN THE SPLIT
# it fixes: a split makes one variable into two (some writes go unseen), while a
# bad merge fuses two genuinely distinct variables into one (writes to either
# corrupt the other). The split is a silent omission; the merge is silent
# corruption. So this table is deliberately conservative and reports what it
# skipped rather than guessing.
#
# 1. AMBIGUOUS NAME -- the same name is paired with more than one address
#    somewhere in the corpus, so we cannot tell which slot it means. Measured:
#    7 of 284 names, including g_matchstate (claimed by 0x00C5B1CC, 0x00C5B1FC
#    AND a training global) and g_opponentteam (claimed by both the home and away
#    team slots -- merging those would make the two teams the same object).
#
# 2. TYPE MISMATCH -- two names for one address must have the same declared type.
#    The heuristic pairs g_myprofile:TProfile with g_player_int01:Int at
#    0x00C5B1FC purely because both appear near that address in prose. A TProfile
#    and an Int are not the same slot, and merging them would put an object
#    reference where the match-state code expects a small integer.
# ---------------------------------------------------------------------------


def canonical_from_table():
    """address -> name, from the project's own globals table."""
    out = {}
    if not os.path.exists(GLOBALS_FINAL):
        return out
    with open(GLOBALS_FINAL, encoding="utf-8", errors="replace") as f:
        for line in f:
            p = line.rstrip("\n").split("\t")
            if len(p) >= 3 and p[0].startswith("0x"):
                out[p[0][2:].upper().zfill(8)] = p[2].strip().lower()
    return out


def main():
    # per file: which Globals it declares, which addresses it mentions
    file_decls, file_addrs, name_files = {}, {}, collections.defaultdict(set)
    pair_votes = collections.defaultdict(collections.Counter)   # addr -> name -> votes
    name_types = collections.defaultdict(collections.Counter)   # name -> type -> votes

    for tree in TREES:
        if not os.path.isdir(tree):
            continue
        for fn in sorted(os.listdir(tree)):
            if not fn.endswith(".bmx"):
                continue
            text = open(os.path.join(tree, fn), encoding="utf-8",
                        errors="replace").read()
            decls = {m.group(1).lower() for m in GLOBAL_DECL.finditer(text)}
            if not decls:
                continue
            for m in GLOBAL_DECL_TYPED.finditer(text):
                name_types[m.group(1).lower()][
                    re.sub(r"\s+", "", m.group(2)).lower()] += 1
            comments = [l for l in text.splitlines() if l.strip().startswith("'")]
            addrs = set()
            for l in comments:
                for m in ADDR_ANY.finditer(l):
                    addrs.add(m.group(1).upper().zfill(8))
            file_decls[fn], file_addrs[fn] = decls, addrs
            for d in decls:
                name_files[d].add(fn)
            # a direct `0xADDR name` adjacency is the strongest signal
            for l in comments:
                for m in ADDR_NAME.finditer(l):
                    a, n = m.group(1).upper().zfill(8), m.group(2).lower()
                    if n in decls:
                        pair_votes[a][n] += 2
                for m in NAME_ADDR.finditer(l):
                    n, a = m.group(1).lower(), m.group(2).upper().zfill(8)
                    if n in decls:
                        pair_votes[a][n] += 2
            # a file that declares exactly one Global and names exactly one address is
            # itself an unambiguous pairing, even without adjacency
            if len(decls) == 1 and len(addrs) == 1:
                pair_votes[next(iter(addrs))][next(iter(decls))] += 1

    # filter 1: a name paired with more than one address.
    #
    # Rejecting these outright is far too blunt. Address annotations are prose, so a name
    # picks up a spurious second address whenever it happens to sit near one in a comment
    # ("0x00C5B208 / 0x00C5B210 / ... are Ints", a header listing several slots at once).
    # Wholesale rejection throws away the CORRECT pairing too, and it rejects by
    # GROUP -- one bad member kills every merge at that address. Measured cost: 425
    # refused rows, and find_dead_globals.py attributes a large share of the program's
    # 495 CRITICAL never-written Globals to exactly those refusals -- the Edit Controls
    # key-binding arrays, the options value array, the match HUD labels.
    #
    # So: resolve rather than refuse. Each (address, name) pairing carries a vote count --
    # 2 per explicit adjacency, 1 for a file that declares exactly one Global and names
    # exactly one address. A name belongs to the address that has STRICTLY MORE votes for
    # it. Only a genuine tie is unusable, because then the evidence really is balanced and
    # a coin-flip merge could fuse two distinct slots.
    name_addrs = collections.defaultdict(dict)
    for addr, votes in pair_votes.items():
        for n, v in votes.items():
            name_addrs[n][addr] = v

    ambiguous = set()
    for n, addrs in name_addrs.items():
        if len(addrs) < 2:
            continue
        ranked = sorted(addrs.items(), key=lambda kv: -kv[1])
        if ranked[0][1] == ranked[1][1]:
            ambiguous.add(n)                      # genuine tie -> unusable
            continue
        winner = ranked[0][0]
        for a, _v in ranked[1:]:                  # drop the weaker pairings
            pair_votes[a].pop(n, None)

    def decl_type(n):
        c = name_types.get(n)
        return c.most_common(1)[0][0] if c else None

    table = canonical_from_table()
    rows, skipped = [], []
    for addr, votes in sorted(pair_votes.items()):
        names = sorted(votes)
        if len(names) < 2:
            continue
        tn = table.get(addr)
        if tn in names:
            canon, why = tn, "globals_final.tsv"
        else:
            best = max(names, key=lambda n: (len(name_files[n]), n))
            canon, why = best, "most-used (%d files)" % len(name_files[best])
        ctype = decl_type(canon)
        for n in names:
            if n == canon:
                continue
            if n in ambiguous or canon in ambiguous:
                skipped.append((addr, n, canon, "AMBIGUOUS: name maps to %d addresses"
                                % len(name_addrs[n if n in ambiguous else canon])))
                continue
            ntype = decl_type(n)
            if ntype and ctype and ntype != ctype:
                skipped.append((addr, n, canon,
                                "TYPE MISMATCH: %s vs %s" % (ntype, ctype)))
                continue
            rows.append((addr, n, canon, why, len(name_files[n])))

    with open(OUT, "w", encoding="utf-8", newline="") as f:
        f.write("address\talias\tcanonical\treason\talias_files\n")
        for r in rows:
            f.write("0x%s\t%s\t%s\t%s\t%d\n" % r)

    skip_path = OUT.replace(".tsv", "_skipped.tsv")
    with open(skip_path, "w", encoding="utf-8", newline="") as f:
        f.write("address\talias\tproposed_canonical\twhy_skipped\n")
        for r in skipped:
            f.write("0x%s\t%s\t%s\t%s\n" % r)

    print("wrote %s" % OUT)
    print("  addresses with >1 confirmed name : %d" % len({r[0] for r in rows}))
    print("  aliases ACCEPTED for rewrite     : %d" % len(rows))
    print("  aliases SKIPPED (unsafe)         : %d  -> %s"
          % (len(skipped), os.path.basename(skip_path)))
    for a, n, c, w in skipped[:6]:
        print("      0x%s %-24s %s" % (a, n, w))
    if len(skipped) > 6:
        print("      ... and %d more" % (len(skipped) - 6))
    print()
    print("  Applied by assemble.py to the GENERATED source only.")
    print("  src/recovered/ is not modified; reverify.py stays green.")
    print("  SKIPPED rows are real splits still present in the build -- they need")
    print("  a human decision, and each one is a silently-inert Global until then.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
