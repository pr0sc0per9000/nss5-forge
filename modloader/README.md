# NSS5 mod loader

A `winmm.dll` for the Steam copy of New Star Soccer 5. Put it in the game folder and
click Play in Steam as normal. The game reads mod files in place of its own.

## Install

1. Put `winmm.dll` in the game folder, next to `NSS5.exe`.
2. Put each mod in its own folder in `Mods`.
3. Click Play in Steam.

Uninstall: delete `winmm.dll`.

Steam Deck and Linux (Proton): set the game's launch options to
`WINEDLLOVERRIDES="winmm=n,b" %command%`, or Proton uses its own winmm.

## Making a mod

A mod is a folder laid out like the game folder, holding only the files it changes.

    Mods/MyKits/GameMedia/Images/Backgrounds/StadiumBG.jpg

The game then reads that file instead of `GameMedia/Images/Backgrounds/StadiumBG.jpg`.
Keep images the same size as the originals.

Files built into NSS5.exe (fonts, the player sprite, the credits) cannot be replaced
this way.

To see which files the game reads, create an empty file `Mods/log_all_reads`, play, and
read `Mods/loader.log`.

## Load order

`Mods/load_order.txt` is written on first run with every mod folder in it. One mod per
line. When two mods change the same file, the lower one wins. Put `#` in front of a line
to turn that mod off. Conflicts are listed in `Mods/loader.log`.

## How it works

NSS5.exe loads winmm.dll by name, and Windows looks in the game folder first. Every winmm
call goes straight on to the real winmm.dll. The loader then points the game's file opens
(`_wfopen`, `fopen`, `_wstat`, `_stat` in its import table) at its own, which check the
enabled mods first. Reads only. Nothing in the game folder is changed.

With no mods enabled the game is not touched. NSS5.exe's sha256 is checked at start: file
mods work on any build, hooks into game code (none yet) only on the Steam build.

## Build

    python modloader/build.py

Needs the 32-bit MinGW from the BlitzMax toolchain (see the main README). `gen_exports.py`
regenerates the export stubs from the system's 32-bit winmm.dll.
