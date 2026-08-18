# Repo rules

Rules here are **enforced by a script**. That is the house convention and it is not
decorative: every invariant this project actually keeps is kept because something checks
it (`coverage.py`, `reverify.py`, `check_assembled.py`). Invariants that are only written
down get broken. `assemble.py` silently skipped `src/recovered_thirdparty/` for weeks, and
`runtime_helpers.tsv` carried a wrong row that blessed ten wrong bodies, because in both
cases the rule was advice rather than a check.

**If you want a rule to survive, add it to `scripts/check_docs.py` or an equivalent checker.
Otherwise do not bother writing it here.**

Run all of them:

```bash
python scripts/check_docs.py
```

---

## 1. What goes where

The single most important distinction in this repo is between **what the game does** and
**what we did to find out**. They had been mixed together; they are now separated, because
only the first one is the deliverable.

| Directory | Holds | Lifetime |
|---|---|---|
| `docs/game/` | **How New Star Soccer 5 actually behaves.** Match rules, AI decisions, injuries, cards, transfers, economy, file formats. | **Permanent. This is the product.** |
| `docs/specs/` | What the *binary* is: object model, string tables, asset formats, module globals. | Permanent, but about NSS5.exe rather than about football. |
| `docs/reference/` | Reference material needed to read the source, such as the language guide. | Permanent, working reference. |

**Rule 1.1** - A claim about *game behaviour* belongs in `docs/game/`. If you learn how
yellow cards work while byte-matching `TPlayer.CheckFoul`, the football rule goes in
`docs/game/match/` where a reader will find it.

**Rule 1.2** - Do not create new top-level directories under `docs/` without adding them to
this table and to `check_docs.py`.

**Rule 1.3** - Existing files stay where they are. The specs are not being re-filed;
several of them (01, 02, 03, 04, 09) contain real game-behaviour content and are linked
from `docs/game/README.md` instead. New behaviour documentation goes in `docs/game/`.

---

## 2. Provenance - the documentation equivalent of the byte oracle

This is the rule that matters most.

The byte oracle works because a body either matches the original or it does not; there is no
room for a confident-sounding assertion. Prose has no such discipline, which is exactly how
documentation rots into plausible fiction. So every behavioural claim carries the function it
came from, and the checker verifies both that the function exists and that the confidence
tag does not overstate what we actually know about it.

**Rule 2.1** - Every file under `docs/game/` (except `README.md`) begins with a source block:

```markdown
# How fouls and cards are decided

> **Source:** `TPlayer.CheckFoul` @ 0x004f4d5f (VERIFIED) · `TEngine.GoalScored` @ 0x004d39d6 (READ)
> **Confidence:** HIGH
> **Last checked:** 2026-08-15
```

**Rule 2.2** - Every VA in a source block must exist in the Ghidra inventory. This catches
typos and invented addresses. A wrong address is worse than no address: it sends the next
reader to unrelated code and they trust what they find there.

**Rule 2.3** - The tag after each source is one of:

| Tag | Means | Checker requires |
|---|---|---|
| `VERIFIED` | The body is byte-exact against the original. | The VA is MATCHed per `coverage.py`. |
| `READ` | A human or pass read the disassembly/decompile, but it is not byte-matched. | The VA exists. |
| `INFERRED` | Deduced from strings, assets, data files, or behaviour - not from reading that function. | The VA exists. |
| `OBSERVED` | Seen by running the actual game. | Free-form; no VA required. |

**You may not tag a source `VERIFIED` unless it is actually byte-matched.** The checker
fails on this. This is the whole point: it makes "we have proven this" mechanically
distinguishable from "we believe this", forever, without trusting anyone's memory.

**Rule 2.4** - `Confidence:` is `HIGH`, `MEDIUM` or `LOW`, and describes the *behavioural
claim*, not the byte match. A byte-exact function whose purpose we do not understand is
`VERIFIED` provenance with `LOW` confidence, and saying so is not a failure - it is the
honest state and it tells the next person where to look.

**Rule 2.5** - When a claim is uncertain, write the uncertainty into the prose. "The
threshold is 0.8" and "the threshold is the float at +0x1C, which we believe is 0.8 but have
not confirmed against gameplay" are different sentences and the second one is worth more.

---

## 3. Writing style

The owner is not a compilers person and will be reading this to build on it.

**Rule 3.1** - Plain English. Explain in simple words what happens in the game. If you must
use a technical term, put the plain meaning next to it the first time.

**Rule 3.2** - Lead with the football, not the assembly. "A player is booked when he makes a
sliding tackle from behind and his speed is above X" is the claim. The register allocation
that got you there does not belong in the same paragraph.

**Rule 3.3** - Give the numbers. Thresholds, probabilities, ranges, frame counts. A
behavioural document without constants is an essay; with them it is a specification someone
can reimplement or rebalance.

**Rule 3.4** - Where a value comes from a data file rather than code, say which file and
which column. Most of this game's content is loose on disk in
`GameMedia/Data/*.csv`, `GameMedia/Languages/Languages.csv` and `EngineMedia/Tactics/*.tac`.

---

## 4. Indexing

**Rule 4.1** - Every file under `docs/game/` is linked from `docs/game/README.md`. An
unlinked document is one nobody finds. The checker reports orphans.

**Rule 4.2** - `docs/game/README.md` is the map of what is known and what is not. Gaps are
listed explicitly, because an absent section reads as "nothing to say" when it usually means
"nobody has looked".

---

## 5. Source tree rules (existing, restated so they are in one place)

**Rule 5.1** - Byte-exact bodies go in `src/recovered/`. Third-party module bodies go in
`src/recovered_thirdparty/<module>/` and **never** in `src/recovered/` - folding them in
corrupts the main module's Type declaration order.

**Rule 5.2** - A near miss goes in `src/recovered_unverified/`, never left outside the
tree. A 6208/6249 candidate was lost exactly once and that was enough.

**Rule 5.3** - Never run a corpus-wide `sed` on `src/recovered/`. It is a live tree with several
jobs writing to it concurrently.

**Rule 5.4** - Re-run `assemble.py` before `check_assembled.py`. A stale exe makes every
newly written body read as `LENGTH n vs 14` and looks like an assembler defect.

**Rule 5.5** - Always set `NSS5_NO_LEARN=1` for any verification run. Without it a body can
teach itself a helper name and then re-compare clean.
