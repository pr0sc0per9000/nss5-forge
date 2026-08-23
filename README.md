# New Star Soccer 5 Reconstruction

[Contributing](/CONTRIBUTING.md) | [Status](/docs/STATUS.md) | [Tools](/scripts/README.md) | [Game behaviour](/docs/game/README.md)

[![CI](https://github.com/pr0sc0per9000/nss5-forge/actions/workflows/ci.yml/badge.svg)](https://github.com/pr0sc0per9000/nss5-forge/actions/workflows/ci.yml)
[![Reconstructed](https://img.shields.io/endpoint?url=https%3A%2F%2Fraw.githubusercontent.com%2Fpr0sc0per9000%2Fnss5-forge%2Fmain%2Fdocs%2Fprogress.json)](/docs/STATUS.md)
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

This is a source reconstruction of New Star Soccer 5, rebuilding the game from
its own executable back into BlitzMax source. It aims to be as accurate as
possible, matching the recompiled machine code to the original as closely as it
can. It follows the same approach as [re3](https://github.com/GTAmodding/re3) and
[isledecomp/isle](https://github.com/isledecomp/isle), applied to a BlitzMax
title.

> **Note:** This repository does not include the game. New Star Soccer 5 is a
> commercial product and its executable and media belong to New Star Games Ltd.
> You need your own copy. It will not build for anything other than 32-bit
> Windows.

## Status

94.2% of the machine code is byte-identical to the original: 817,360 of 867,288
bytes across 1,943 function bodies. That figure is derived from the source by
[`scripts/progress.py`](/scripts/progress.py) and never written by hand; see
[`docs/STATUS.md`](/docs/STATUS.md) for the breakdown.

Both halves of that ratio moved this pass, in opposite directions, and neither move
was a regression. `progress.py` walked each tree with a flat `os.listdir`, so
`src/recovered_thirdparty` -- which keeps its bodies one level down, under a
directory per module -- was listed in `TREES` and counted in neither the numerator
nor the denominator; it now contributes 108 matched bodies. Against that, three
newly reconstructed bodies entered the denominator as near-misses. An unrecovered
function is not in the denominator at all, so reconstructing one to within a few
bytes always lowers the percentage before it raises it.

A further 4 bodies are excluded from that count. They call into Steam, whose
2011 backend no longer answers, and linking them makes the Windows loader
refuse to start the process. `STEAM_EXCLUDE` in
[`scripts/progress.py`](/scripts/progress.py) names them and says why.

The game builds, boots, and a new career now runs through character creation into
the club trial and draws its first training. It is not yet playable end to end.

Getting that far was not a matter of recovering more machine code -- the byte figure
above did not move. It was a naming defect. One memory address routinely collected
several recovered names, and because a Global's name never reaches compiled output,
every body involved byte-matched perfectly while the writer updated one variable and
the reader saw another that nothing ever assigned. Twenty slots have now been
collapsed onto one name each, including the player profile, the match ball and the
engine state. [`docs/specs/21-module-globals.md`](/docs/specs/21-module-globals.md)
§8 records what was fixed, the three shapes this defect takes, why neither the byte
oracle nor the name-based tooling can see it, and the 62 addresses still outstanding.

Beyond the rebuild, [`docs/game`](/docs/game/README.md) documents how the game
actually behaves: the match engine, AI decisions, injuries, cards, transfers and
the economy, each claim carrying the function it came from.

## Building

### Prerequisites

- **64-bit Windows.** The build is 32-bit x86 and there is no cross-compile path.
- **Your own copy of New Star Soccer 5**
  ([Steam, appid 212780](https://store.steampowered.com/app/212780/)). The Steam
  release specifically; see [Which version do I have?](#which-version-do-i-have)
  below. `setup.py` finds it for you and copies what the build needs.
- **Python 3.8 or newer.** No third-party packages -- the standard library is all
  of it, so there is nothing to `pip install` and no virtualenv to make.
- **[BlitzMax legacy 1.x, 32-bit](https://github.com/blitz-research/blitzmax)**,
  at `tools/blitzmax-legacy-src`. This is the compiler the original game was built
  with, and all contributions are graded against its output. **Cloning it is not
  installing it** -- that repository is compiler *source*, it ships no `bmk.exe`
  (`bin/*` is gitignored upstream) and no MinGW. To make it usable:

  ```
  git clone https://github.com/blitz-research/blitzmax tools/blitzmax-legacy-src
  cd tools/blitzmax-legacy-src
  # 1. unpack the bundled MinGW that its own build expects on PATH:
  #    _src/win32_x86/mingw_v5b.7z  ->  _mingw/
  #    (must end up as tools/blitzmax-legacy-src/_mingw/mingw/bin)
  # 2. build bcc and bmk following that repo's README.TXT (_src/win32_x86)
  ```

  `python scripts/setup.py` checks for `bin/bmk.exe` and `_mingw/mingw/bin/g++.exe`
  by name and tells you which is missing. Do not rename the directory: every build
  script reads that exact path.
- **[Git Bash](https://git-scm.com/download/win)**, if you want the debug build.
  [`scripts/build_debug.sh`](/scripts/build_debug.sh) is a shell script and uses
  `cygpath`; it does not run under `cmd.exe` or PowerShell. Everything else is
  Python and runs anywhere.
- [Ghidra](https://github.com/NationalSecurityAgency/ghidra/releases) at
  `tools/ghidra_12.1.2_PUBLIC` and a [JDK 21+](https://adoptium.net/) at
  `tools/jdk`, **only** if you intend to decompile. Neither is needed to build.

### Compiling

```bash
git clone https://github.com/pr0sc0per9000/nss5-forge
cd nss5-forge
python scripts/setup.py
python scripts/assemble.py
```

`setup.py` locates your Steam install, verifies it against
[`binary/checksums.json`](/binary/checksums.json), copies what the build needs into
directories excluded from version control, and then derives `extracted/` from your
own `binary/NSS5.exe` -- the object model, the class tables, the DLL imports and the
embedded assets. `assemble.py` reads all of that, so **run `setup.py` first even if
you already have the game in place.** If it cannot find the install, pass it
directly:

```bash
python scripts/setup.py --steam-path "C:/Program Files (x86)/Steam/steamapps/common/New Star Soccer 5"
```

`setup.py` exits non-zero and prints what to do if anything the build needs is
absent. It is worth reading the last few lines rather than moving straight on.

`assemble.py` emits `src/assembled` from the recovered bodies and compiles it. It
takes a few minutes, and ends with `result: BUILD OK`.

## Usage

```bash
python scripts/debug_game.py --minutes 10
```

Do not run the built executable directly. It can start in exclusive fullscreen and
hang holding the display and the input queue, which needs a power cycle to clear.
[`debug_game.py`](/scripts/debug_game.py) forces windowed mode across every
`Options.ini` the game reads and kills the process after a time limit, and runs the
debug build, which names a fault instead of exiting silently. Build that first with
`bash scripts/build_debug.sh`. [`play.py`](/scripts/play.py) is the same guarantees
around the release build.

## If it does not work

**Please open an issue.** These instructions are only worth anything if they work
on a machine that is not the one they were written on, and the only way that gets
found out is if you say so. A report that stops at "it does not build" cannot be
acted on; one that includes the four things below usually can be fixed the same
day.

Include:

1. **Your OS** -- `Windows 11 24H2`, and whether it is 64-bit.
2. **Your Python version** -- the output of `python --version`.
3. **The exact command you ran**, copied, including any arguments.
4. **The full error**, copied as text rather than a screenshot, including the whole
   traceback if there is one. The last line on its own is rarely enough.

Also say which step of [Compiling](#compiling) you reached, and paste the final
lines of `python scripts/setup.py` -- that output names most of what goes wrong.

Two known ones, so you can rule them out first:

* **`result: BUILD OK` but the game will not start, or starts and closes at once.**
  Windows Smart App Control and WDAC block freshly built, unsigned executables, and
  the symptom is indistinguishable from a broken build -- a byte-identical copy of a
  known-good exe has been blocked here. Check Windows Security -> App & browser
  control -> Smart App Control, and look in Event Viewer under
  `Applications and Services Logs -> Microsoft -> Windows -> CodeIntegrity`.
* **`Build Error: Failed to link`, with no cause.** `bmk` shells out to `g++`
  without putting its own bundled MinGW on `PATH`. Use
  `bash scripts/build_debug.sh`, which redoes the link step with it.
* **`scripts/smoke_boot.py` says it got no further than `settings read`, and the
  last line is `CALLING GameMain`.** That is almost always a missing log, not a
  hang. The game writes its startup log only when
  `src/assembled/Settings/Settings.txt` says `debug=1`, and the copy that ships
  with the game says `debug=0`. `setup.py` flips it; if you populated
  `src/assembled` by hand, set it yourself.

## Layout

```
src/recovered/             byte-verified function bodies
src/recovered_unverified/  reconstructions not yet byte-identical
src/recovered_module/      module-level functions
src/recovered_thirdparty/  community modules the game links
src/module_body/           the program's top-level bootstrap
scripts/                   reconstruction, comparison and build tooling
docs/                      game behaviour and binary specifications
binary/                    where your copy of the game goes
```

`src/assembled/`, `extracted/`, `ghidra-project/`, `status/` and `tools/` are
generated or downloaded and are excluded from version control.

## Contributing

If you're interested in helping or contributing to this project, check out the
[CONTRIBUTING](/CONTRIBUTING.md) page. The overriding rule is that the original is
reproduced exactly, bugs included; a corrected bug is a divergence from the game
being rebuilt.

Contributors must not have seen leaked or unauthorised source for New Star Soccer
or for BlitzMax's commercial releases.

## Additional Information

### Which version do I have?

This reconstruction targets the Steam release. You can verify you have the
matching files with the checksums below, or by running
`python scripts/setup.py --check`, which does it for you.

* `NSS5.exe` 9,383,424 bytes, `sha256: 37d566150483da1ecba03b4b2421307fc741a26a63c3092c9a154de21535e8eb`
* `steamstub.dll` 498,688 bytes, `sha256: 3d9519249d4fc218c35a51a93e4aa5b1f5d81120674ec7d29706ad343d6445da`
* `IRClipboardFunctions.dll` 45,056 bytes, `sha256: 64c6dac03c8a8206d95d7bcd44e28e3d2459542b0a40556908a03fd421298032`

Only `NSS5.exe` is required; the other two are recorded so a mismatched install
can be identified.

## Licence

The reconstruction, meaning every file under `src/`, `scripts/` and `docs/`, is
released under the [MIT Licence](LICENSE).

That covers this project's own work only. New Star Soccer 5 itself, its executable
and all of its media remain the property of New Star Games Ltd, are not
distributed here, and are not covered by that licence. This project is not
affiliated with or endorsed by New Star Games Ltd.
