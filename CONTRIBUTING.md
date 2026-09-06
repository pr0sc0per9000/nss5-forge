# Contributing

## Getting started

If you are comfortable finding your way around the repository and confident in
your abilities, open a pull request and reconstruct some functions. You do not
need permission and you do not need to be an expert first.

Useful reading before you start:

* [`docs/reference/blitzmax-language-guide.md`](/docs/reference/blitzmax-language-guide.md)
  for the language, which differs from C in ways that will catch you out.
* [`docs/reference/codegen-patterns.md`](/docs/reference/codegen-patterns.md) for
  how `bcc` emits code, which is what you are matching against.
* A few verified bodies under [`src/recovered`](/src/recovered) next to the
  original disassembly, to see what a finished one looks like.

A good first contribution is a small function that is already listed as
unrecovered. `python scripts/outstanding_game.py` lists them, and small accessors
are usually a single afternoon. If you get stuck on one, say so in the pull
request; a body that nearly matches is still useful, and
[`src/recovered_unverified`](/src/recovered_unverified) exists exactly for that.

## The original binary

You need your own copy of New Star Soccer 5 (Steam appid 212780). None of the
game ships here, and nothing in this repository works without it.

```bash
python scripts/setup.py
```

That locates your Steam install, verifies it against `binary/checksums.json`, and
copies what the build needs into directories excluded from version control. The
target is `NSS5.exe`, 9,383,424 bytes, SHA-256
`37d566150483da1ecba03b4b2421307fc741a26a63c3092c9a154de21535e8eb`. Every byte
comparison in the project is made against that file.

Do not contribute if you have seen leaked or unauthorised source code for New
Star Soccer or for BlitzMax's commercial releases. Everything here is derived
from the retail binary, its own embedded reflection tables, and observed
behaviour.

## Ghidra

Decompilation is done in [Ghidra](https://ghidra-sre.org/). There is no shared
server; the corpus is exported locally by the scripts in
[`scripts/ghidra_scripts`](/scripts/ghidra_scripts), and
[`scripts/decomp_index.py`](/scripts/decomp_index.py) is how you read it
afterwards without opening Ghidra at all. Ghidra takes an exclusive lock on its
project database, so going through the exported corpus is usually faster and lets
several people work at once.

## General Guidelines

Someone will review and merge your pull request, or give feedback, as soon as
possible.

Keep pull requests small and understandable. This is a collaborative project, so
others need to be able to follow along. Large pull requests are much harder to
review, which makes it more likely for an error to go undetected, and they
conflict with everything else in flight. A good guideline is one Type at a time.
Some Types are too interlinked for that to be practical, so it is not a hard
rule, but if you are modifying more than ten or so files it is probably too big.

This repository has one goal: accuracy to the original executable. We are byte
matching as far as possible, which means the priority is making the original
compiler produce code that matches the original game. Modernisations and bug
fixes will be rejected.

Reproduce the original, bugs included. If the decompilation shows an off-by-one
or a comparison that can never be true, reproduce it and annotate it:

```blitzmax
' BUG (original): index runs to 26 on a 25-element table. Preserved.
```

### A byte match does not prove your Globals are right

This is the one trap worth knowing before you start. A Global's *name* never reaches
compiled output, so it cannot affect a byte match -- and a Global reference is a
relocation, which the oracle masks. `mov eax,[A]` and `mov eax,[B]` compare equal.

So a body can be 100% byte-identical and still read the wrong memory. If your body
and someone else's pick different names for one address, `assemble.py` emits two
`Global`s, the writer updates one and you read the other, which is Null forever.
Both bodies still MATCH. In a release build a Null read silently returns 0, so the
feature just quietly does nothing until something calls a method through it.

Two rules follow:

* **Put the address in your header, next to the name**, exactly as the recovered
  bodies already do. It is the only record of what you meant.
* **When your header and the alias tables disagree, disassemble before believing
  either.** `python scripts/disasm.py <VA> <length>` and read the absolute
  displacement. That is ground truth and it takes one command. Several bodies had
  the right address in their own header and were overridden by a table built from a
  name tally.

[`docs/specs/21-module-globals.md`](/docs/specs/21-module-globals.md) §8 has the
three shapes this takes, worked examples, and the addresses still outstanding.

## Overview

* [`binary`](/binary): Metadata about the original game files. The files
  themselves are never committed; `setup.py` puts your own copy here.
* [`docs/game`](/docs/game): How New Star Soccer 5 behaves. Match engine, AI,
  career progression, economy, file formats. Every claim carries the function it
  came from.
* [`docs/specs`](/docs/specs): What the binary is. Object model, string tables,
  asset formats, module globals.
* [`docs/reference`](/docs/reference): The BlitzMax language guide and the
  codegen patterns needed to read `bcc` output.
* [`extern`](/extern): Definitions for libraries the game links that are not part
  of the reconstruction.
* [`scripts`](/scripts): Tooling for reconstruction, comparison and building.
* [`src/recovered`](/src/recovered): Byte-verified function bodies. Individual,
  evidenced fixes only, never bulk edits.
* [`src/recovered_unverified`](/src/recovered_unverified): Reconstructions that
  are not yet byte-identical. Most work happens here.
* [`src/recovered_module`](/src/recovered_module): Module-level functions.
* [`src/recovered_thirdparty`](/src/recovered_thirdparty): Two BlitzMax community
  modules the game links that our BlitzMax install does not ship. These must not
  be declared in the main module.
* [`src/module_body`](/src/module_body): The program's top-level bootstrap, which
  runs before `GameMain`.

`src/assembled`, `extracted`, `ghidra-project`, `status` and `tools` are
generated or downloaded and are excluded from version control.

## Tooling

[`scripts/README.md`](/scripts/README.md) lists the tooling and what each tool is
for. You will want it open while you work.

## Notes on BlitzMax 1.x and bcc

The compiler is `bcc` from legacy BlitzMax 1.x, driven by `bmk`. A few of its
properties shape everything about this project.

A release build strips null and bounds checks, so a null dereference is a raw
memory access that Windows kills with no message and a null-object defect
presents as a button that does nothing. Only a debug build names the fault. An
out-of-bounds write is the exception: it kills the process outright.

The build tree is shared state. `bmk` drops intermediates next to the source, so
two concurrent builds in the same tree corrupt each other's object files. Build
in a private tree if you are running anything in parallel.

Declaration order is load-bearing. The main module declares its Types in a
recorded order that the class tables follow, so folding a third-party module's
Types into `src/recovered` corrupts that order and breaks matching across the
whole program.

## Code Style

We are not exhaustively strict about style, but some conventions follow from the
original codebase and from what the tooling can check.

### BlitzMax

* `'` starts a comment. `=` is equality, `<>` is not-equal, `And`/`Or`/`Not` are
  the logical operators.
* `^` is exponentiation and `~` is XOR, not what a C programmer expects. `Mod`,
  not `%`. There is no `++` or `--`; use `:+` and `:-`.
* `..` continues a line.
* Do not reorder fields in a Type. Field order and byte offsets are the
  original's, and changing them changes the layout.

### Everything else

* Plain hyphens. Em dashes and en dashes are rejected anywhere in the repository.
* Comments explain why, not what.
* No absolute paths and no usernames. Scripts derive their own location:
  `ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))`
* One-off analysis goes in `scripts/workflow`, which is not tracked.

## Before opening a pull request

* `python scripts/assemble.py` builds
* `python scripts/find_name_collisions.py --check` passes. It fails when two bodies use one
  identifier for two different addresses in NSS5.exe, which makes the assembler emit a
  single variable for both and silently merges two subsystems' state. A byte match cannot
  see it, so nothing else will catch it.
* `python scripts/smoke_boot.py` reaches `MAIN MENU reached` (5s default)
* if you changed a function body, run `python scripts/progress.py --write-status`
  and commit the regenerated `docs/STATUS.md`. CI fails if it is stale.

## Questions?

Open an issue.
