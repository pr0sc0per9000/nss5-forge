# New Star Soccer 5 Reconstruction

[Contributing](/CONTRIBUTING.md) | [Status](/docs/STATUS.md) | [Tools](/scripts/README.md) | [Game behaviour](/docs/game/README.md)

[![CI](https://github.com/pr0sc0per9000/nss5-forge/actions/workflows/ci.yml/badge.svg)](https://github.com/pr0sc0per9000/nss5-forge/actions/workflows/ci.yml)
[![Reconstructed](https://img.shields.io/endpoint?url=https%3A%2F%2Fraw.githubusercontent.com%2Fpr0sc0per9000%2Fnss5-forge%2Fmain%2Fdocs%2Fprogress.json)](/docs/STATUS.md)
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![Discord](https://img.shields.io/badge/discord-join-5865F2?logo=discord&logoColor=white)](https://discord.gg/RqxcxUzRcQ)

This project rebuilds New Star Soccer 5 from its own executable back into BlitzMax
source code. Compile that source, and the machine code should come out the same as
the original, byte for byte. Same idea as [re3](https://github.com/GTAmodding/re3)
and [isledecomp/isle](https://github.com/isledecomp/isle), applied to a BlitzMax game.

> **You need your own copy of the game.** New Star Soccer 5 belongs to New Star
> Games Ltd. None of it is included here. Windows only.

## Status

The badge above shows how much of the machine code matches. It is generated from
the source, so it is always current. [`docs/STATUS.md`](/docs/STATUS.md) breaks it
down.

The game builds and runs. A new career gets through character creation and the club
trial, and into training. It is not finished.

Most bugs left are naming bugs, not missing code. Two parts of the game can use
different names for the same piece of memory. One writes it, the other reads
something empty. The compiled code still matches byte for byte, so the usual checks
cannot see it.
[`docs/specs/21-module-globals.md`](/docs/specs/21-module-globals.md) §8 explains it.

## What you need

- **Windows, 64-bit.** The game it builds is 32-bit, but the tools need a 64-bit
  host. You cannot cross-compile.
- **Your own copy**
  ([Steam, appid 212780](https://store.steampowered.com/app/212780/)). The Steam
  release, not another one. `setup.py` finds it and copies what the build needs.
- **Python 3.8 or newer.** Nothing to install.
- **[BlitzMax legacy 1.x, 32-bit](https://github.com/blitz-research/blitzmax)** in
  `tools/blitzmax-legacy-src`. This is the compiler the original game used.
  Cloning it is not enough. That repository is the compiler's *source*: no
  `bmk.exe`, no MinGW. After cloning:
  1. Unpack `_src/win32_x86/mingw_v5b.7z` into `_mingw/`, so it lands at
     `tools/blitzmax-legacy-src/_mingw/mingw/bin`.
  2. Build `bcc` and `bmk`, following that repository's `README.TXT`.

  Keep the folder name. Every script looks for that exact path.
- **[Git Bash](https://git-scm.com/download/win)**, for the debug build only.
  [`build_debug.sh`](/scripts/build_debug.sh) will not run in `cmd.exe` or PowerShell.
- **[Ghidra](https://github.com/NationalSecurityAgency/ghidra/releases)** in
  `tools/ghidra_12.1.2_PUBLIC` and a **[JDK 21+](https://adoptium.net/)** in
  `tools/jdk`, only to decompile. Not needed to build.

## Build it

```bash
git clone https://github.com/pr0sc0per9000/nss5-forge
cd nss5-forge
python scripts/setup.py
python scripts/assemble.py
```

`setup.py` finds your Steam copy, checks it against
[`binary/checksums.json`](/binary/checksums.json), and reads your `NSS5.exe` to
build `extracted/`. **Run it first**, even if the game is already in place, because
`assemble.py` needs what it produces. If it stops, read its last few lines: they say
what to do. To point it at your install by hand:

```bash
python scripts/setup.py --steam-path "C:/Program Files (x86)/Steam/steamapps/common/New Star Soccer 5"
```

`assemble.py` then writes and compiles `src/assembled`. It takes a few minutes and
ends with `result: BUILD OK`.

## Run it

```bash
bash scripts/build_debug.sh
python scripts/debug_game.py --minutes 10
```

**Do not run the built `.exe` yourself.** It can start in full screen and lock up,
holding the display and the keyboard, and that needs a power cycle to clear.

[`debug_game.py`](/scripts/debug_game.py) is safe: it forces windowed mode in every
`Options.ini` the game reads, and kills the game on a timer. It runs the debug
build, which names a fault instead of closing without a word.
[`play.py`](/scripts/play.py) does the same for the release build. To check the game
still boots, `python scripts/smoke_boot.py 5` starts it, kills it, and reports how
far it got.

## If it does not work

**Please open an issue.** These steps only help if they work on someone else's
machine. Include your OS, your `python --version`, the exact command you ran, and
the full error as text with the whole traceback. Say which step you reached, and
paste the last lines of `setup.py`.

Four known problems, so you can rule them out first:

* **Stops on the language screen.** A fresh clone ships `language=0`, so the game
  waits for you to pick one and `smoke_boot.py` looks hung. Set `language=en` in
  both `src/assembled/Settings/Options.ini` and
  `src/assembled/New Star Soccer 5/Settings/Options.ini`.
* **`BUILD OK`, but the game will not start.** Windows Smart App Control and WDAC
  block new unsigned programs, which looks exactly like a broken build. Check
  Windows Security -> App & browser control, and Event Viewer under
  `Applications and Services Logs -> Microsoft -> Windows -> CodeIntegrity`.
* **`Build Error: Failed to link`, with no reason.** `bmk` calls `g++` without its
  own MinGW on `PATH`. Use `bash scripts/build_debug.sh`, which redoes the link.
* **`smoke_boot.py` stops at `settings read`.** The log is missing, not the game. It
  only writes one when `src/assembled/Settings/Settings.txt` says `debug=1`, and the
  shipped copy says `debug=0`. `setup.py` changes it; if you filled `src/assembled`
  by hand, change it yourself.

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
generated or downloaded, and are kept out of version control.

## Contributing

Read [CONTRIBUTING](/CONTRIBUTING.md). The main rule: copy the original exactly,
bugs included. Fixing one of the game's own bugs makes the code differ from the game
being rebuilt.

Do not contribute if you have seen leaked or unofficial source code for New Star
Soccer, or for BlitzMax's paid releases.

## Which version do I have?

This project targets the Steam release. Run `python scripts/setup.py --check`, or
compare by hand. Only `NSS5.exe` is required; the other two are listed so a wrong
install can be spotted.

* `NSS5.exe` 9,383,424 bytes, `sha256: 37d566150483da1ecba03b4b2421307fc741a26a63c3092c9a154de21535e8eb`
* `steamstub.dll` 498,688 bytes, `sha256: 3d9519249d4fc218c35a51a93e4aa5b1f5d81120674ec7d29706ad343d6445da`
* `IRClipboardFunctions.dll` 45,056 bytes, `sha256: 64c6dac03c8a8206d95d7bcd44e28e3d2459542b0a40556908a03fd421298032`

## Licence

Everything under `src/`, `scripts/` and `docs/` is [MIT](LICENSE). That covers this
project's own work only. New Star Soccer 5, its executable and its media belong to
New Star Games Ltd, are not distributed here, and are not covered by that licence.
This project is not connected to or endorsed by New Star Games Ltd.
