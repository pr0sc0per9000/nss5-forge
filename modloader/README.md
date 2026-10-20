# NSS5 mod loader

Drop it into the Steam copy of New Star Soccer 5 and click Play as normal. Steam keeps its
own playtime, achievements, overlay and cloud. Mods are loose files in a folder.

It also runs this project's own rebuilt game in place of the retail one, so fixes and features
from the reconstruction reach players through the same Play button. The rebuilt game is made on
the player's machine from their own NSS5.exe the first time they play, so no game code or art
is distributed.

## Install

[Download NSS5-Mod-Loader.zip](https://github.com/pr0sc0per9000/nss5-forge/raw/download/NSS5-Mod-Loader.zip).
Step by step with screenshots: [INSTALL.md](/INSTALL.md).

Unzip into the game folder (the one with NSS5.exe), so it ends up with:

    New Star Soccer 5/
      NSS5.exe
      winmm.dll            <- the loader
      Mods/
        core/              <- the rebuilt game and the launcher
        <your mods>/

Click Play. First launch takes a second longer while it builds the game. Uninstall: delete
winmm.dll and the Mods folder.

## How it works

NSS5.exe loads winmm.dll by name from its own folder before Windows' own, which is an ordinary
mod-loader hook. The DLL does two jobs depending on which program loaded it:

- In **NSS5.exe**, if `Mods\core` is present it starts the rebuilt game (`Mods\core\launcher.exe`)
  and keeps NSS5.exe alive and idle as the process Steam is watching, so playtime, overlay and
  achievements stay attached. It exits with the game's exit code. Put an empty file
  `Mods\core\off` to play the retail game instead. With no `Mods\core`, it just applies file
  mods to the retail game.
- In the **rebuilt game** (`Mods\core\nss5_forge.exe`), it points the game's data reads
  (GameMedia, EngineMedia) at the real game folder and lays enabled mods on top.

The launcher, on first play, builds `nss5_forge.exe` from the shipped `nss5_forge.exe.stripped`
(this project's own code, with the game's embedded files removed) and the player's own NSS5.exe,
checks the result's hash, then starts it. A small progress window shows what it is doing and
closes when the game window appears. It also checks this repo's GitHub releases and pulls a
newer build when one is published.

Nothing in the game folder is written to. Our build reads the retail assets in place; saves go
to the usual Documents folder.

## Making a mod

A mod is a folder in `Mods` laid out like the game folder, holding only the files it changes:

    Mods/MyKits/GameMedia/Images/Backgrounds/StadiumBG.jpg

The game reads that file instead of its own. Keep images the same size as the originals. Files
the game keeps inside its exe (fonts, the player sprite, the credits) cannot be replaced.

`Mods/load_order.txt` lists enabled mods, one per line; the lower one wins a conflict; `#` turns
a line off. `core` is the engine and is never a content mod. An empty file `Mods/log_all_reads`
makes the loader log every file the game reads to `Mods/loader.log`, to find what to replace.

## Build

    python modloader/build.py          # winmm.dll and launcher.exe (32-bit MinGW)
    python modloader/pack_release.py <built nss5_forge exe> <out dir>

`build.py` also stamps version info into both files (and a manifest into launcher.exe) with
`stamp.py`, since the toolchain has no resource compiler. Do any code signing after it.

`pack_release.py` strips the game's embedded files out of a built exe and assembles the release
layout. Needs the BlitzMax toolchain (see the main README) for the compiler.

The download zip is rebuilt by CI ([`modloader.yml`](/.github/workflows/modloader.yml)) on every
change here and on every release, and lives on the `download` branch. CI cannot build the game,
so `download_zip.py` takes `nss5_forge.exe.stripped` and `refill.bin` from the newest release
when it carries them, otherwise from the previous zip. Attach both to a release to ship a new game
build: the launcher updates to it and the zip picks it up.
