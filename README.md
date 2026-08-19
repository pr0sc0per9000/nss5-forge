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

94.6% of the machine code is byte-identical to the original: 809,362 of 855,959
bytes across 1,830 function bodies. That figure is derived from the source by
[`scripts/progress.py`](/scripts/progress.py) and never written by hand; see
[`docs/STATUS.md`](/docs/STATUS.md) for the breakdown.

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

- Your own copy of New Star Soccer 5
  ([Steam, appid 212780](https://store.steampowered.com/app/212780/)).
- Python 3.
- [BlitzMax legacy 1.x, 32-bit](https://github.com/blitz-research/blitzmax). This
  is the compiler the original game was built with, and all contributions are
  graded against its output.
- [Ghidra](https://github.com/NationalSecurityAgency/ghidra/releases) and a
  [JDK 21+](https://adoptium.net/), if you intend to decompile rather than just
  build.

### Compiling

```bash
git clone https://github.com/pr0sc0per9000/nss5-forge
cd nss5-forge
python scripts/setup.py
python scripts/assemble.py
```

`setup.py` locates your Steam install, verifies it against
[`binary/checksums.json`](/binary/checksums.json), and copies what the build needs
into directories excluded from version control. It also reports which parts of the
toolchain are missing, with links. If it cannot find the install, pass it
directly:

```bash
python scripts/setup.py --steam-path "C:/Program Files (x86)/Steam/steamapps/common/New Star Soccer 5"
```

`assemble.py` emits `src/assembled` from the recovered bodies and compiles it.

## Usage

```bash
python scripts/play.py --minutes 10
```

Do not run the built executable directly. It can start in exclusive fullscreen and
hang holding the display and the input queue, which needs a power cycle to clear.
`play.py` forces windowed mode across every `Options.ini` the game reads and kills
the process after a time limit. `--debug` runs the debug build, which names a
fault instead of exiting silently.

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
