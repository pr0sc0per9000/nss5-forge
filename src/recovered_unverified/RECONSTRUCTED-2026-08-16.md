# Eight writer bodies reconstructed 2026-08-16 - byte scores, read before trusting

These were written to revive Globals that name unification had proved were *read but never
written*, because the one function that builds the object had never been reconstructed.
They compile, they are wired into the build, and they cut predicted crash sites from 178
to 126.

**None of them byte-matches the original.** They are in `src/recovered_unverified/` for
exactly that reason. Scored with `scripts/bytematch.py` against `NSS5.exe`:

| body | bytes equal | our len / orig len | reading |
|---|---|---|---|
| `TScreen_EditNations.SetUpScreen` | 1228 / 1556 (79%) | 1556 / 1556 | **near miss** - exact length, worth finishing |
| `TScreen_ReportBoss.SetUpScreen` | 1031 / 1490 (69%) | 1490 / 1492 | **near miss** - 2 bytes short |
| `TTraining.SetUpTraining` | 104 / 1764 (6%) | 1745 / 1764 | different implementation |
| `TEngine.GoalScored` | 100 / 1713 (6%) | 1736 / 1713 | different implementation |
| `TScreen_BlackJack.CreateScreen` | 62 / 1290 (5%) | 1249 / 1290 | different implementation |
| `TPitch.SetUpFans` | 62 / 1533 (4%) | 1468 / 1533 | different implementation |
| `TTraining.RenderScoreboard` | 61 / 1626 (4%) | 1509 / 1626 | different implementation |
| `TScreen_EditMenu.CreateScreen` | 33 / 1446 (2%) | 1375 / 1446 | different implementation |

## What that means

The bottom six are **not** near misses. A body agreeing on 4% of its bytes is a plausible
reimplementation of what the decompilation appeared to say, not a reconstruction of what
the original does. They will build the right kinds of gadget and assign the right slots - 
that is why the dead Globals came back to life - but their control flow, their argument
values and their edge cases are unverified guesses.

They were kept rather than discarded because the alternative is worse in a specific,
measurable way: without them those Globals stay Null, and a BlitzMax release build returns
0 for a null dereference instead of faulting (`blitzmax-language-guide` §18.26), so the
whole feature silently does nothing. A screen that builds approximately the right gadgets
beats a screen that builds none. That trade is only acceptable because this directory
means "not verified" - do not promote any of these to `src/recovered/` on the strength of
the build being green.

## Where to pick up

1. `TScreen_EditNations.SetUpScreen` and `TScreen_ReportBoss.SetUpScreen` are close enough
   that the byte oracle can be used as a gradient - diff the compiled body against the
   original and fix the differing runs. Both are plausibly finishable to 1556/1556 and
   1492/1492.
2. The other six need redoing against the decompilation with the oracle in the loop from
   the start, rather than written once and scored afterwards. Writing blind and checking at
   the end is what produced 4%.
3. Each file's own header records where its author was uncertain. `TEngine.GoalScored`
   flags two: the address for `g_goalline` (four CERTAIN-tier names claim `0x00C5D638`
   from different bodies - a genuine unresolved corpus conflict) and the reading of the
   "swap to `lastkickedby` only when `lasttouchedby` is not carded" branch.

## Reproducing the scores

```bash
python scripts/bytematch.py src/assembled/nss5_assembled.exe TEngine GoalScored
```
