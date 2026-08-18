# The original binary

Established by direct analysis of `NSS5.exe` (9,383,424 bytes).

## What it is

| Property | Value |
|---|---|
| Language | BlitzMax (legacy 1.x, not NG) |
| Architecture | x86, 32-bit (PE machine `0x14c`) |
| Toolchain | GCC / MinGW (`.eh_fram` section present) |
| Packing | None |
| DRM wrapper | None |
| Anti-debug | None |
| Renderers | DirectX 7, DirectX 9, OpenGL |
| Audio | OpenAL (`OpenAL32.dll`, `wrap_oal.dll`), FreeAudio fallback |

## Section layout

| Section | Size | Contents |
|---|---:|---|
| `.text` | 755,712 | C runtime plus BlitzMax BRL/PUB modules (~1,459 functions) |
| `code` | 1,046,528 | The game logic. ~3,533 functions, average 296 bytes |
| `.data` | 84,480 | |
| `data` | 7,226,368 | Mostly incbin'd assets (music plus sprite sheet) |
| `.rdata` | 133,120 | |
| `.eh_fram` | 125,440 | GCC exception frames |
| `.bss` `.idata` `.CRT` `.tls` | - | |

About ~1 MB is actual game code.

## Legacy BlitzMax, not NG

A control build compiled with BlitzMax NG 0.154.3.58 (x86) produces sections
`.text .data .rdata .eh_fram .bss .edata .idata .CRT .tls .reloc`, whereas
`NSS5.exe` has `.text code .data data .rdata .eh_fram .bss .idata .CRT .tls`.

The extra `code` and `data` sections are a legacy BlitzMax signature. NG emits
into the standard `.text` and `.data`. Seven section names are shared,
confirming the same compiler family.

## Why this binary is a tractable target

1. **Small.** About 1 MB of game code. GTA San Andreas is about 5 MB; Skyrim SE
   is 30 MB and up.

2. **It ships a partial symbol table.** 85 debug-label strings are real function
   names the developer left in: `MatchLoop`, `PlayFixtures`, `CreateBall:`,
   `Kick:`, `KeeperDive:`, `CreateFixtureListLeague:`, `CreateFixtureListKO:`,
   `DoPromotionPlaces:`, `PopulateTeamPool:`, `CheckShootOutComplete:`,
   `CreatePlayerSimple:`, `SetUpSetPieceBall:`, `CreateScreensAll:`. With
   `debug=1` in `Settings/Settings.txt` these also print at runtime, giving a
   live control-flow trace.

3. **BlitzMax, not C++.** Regular codegen, no template bloat, uniform object
   layout (class pointer, refcount, fields). Decode one object and you have
   decoded the pattern.

4. **No defenses.** A debugger attaches and single-steps freely.

5. **The runtime is open source.** BlitzMax NG's `brl.*` and `pub.*` modules can
   be built locally with symbols and signature-matched against `.text`.

## Two match systems

These are different subsystems and are easy to confuse.

- **`MatchLoop`** is the full 2D physics simulation. 22 players, `Engine.ini`
  physics, formation geometry from `.tac` files. This is the match the player
  plays.

- **`PlayFixtures`** resolves every *other* match in the world from
  `teamstrength`. See the `>>> clubstrength = ` debug output and the
  `ClubStrength:` label. This is a statistical model, not a simulation.

## Assets stored inside the executable

Six music tracks, the player sprite sheet, the credits and the match-engine
config are `incbin`'d into the exe and are not present as files on disk. They
are extracted to `extracted/exe-assets/`.

| File | Size | Source offset | Notes |
|---|---:|---|---|
| `Player.png` | 71,316 | `0x1CD23C` | 2048x1536 = 16x12 grid of 128px frames = 192 sprites |
| `Intro.ogg` | 1,897,880 | `0x1F5914` | |
| `Main.ogg` | 2,266,131 | `0x3C4EE0` | |
| `Training_Loop1.ogg` | 715,626 | `0x5EE324` | |
| `Training_Loop2.ogg` | 432,198 | `0x69CED4` | |
| `Shopping_Loop1.ogg` | 540,964 | `0x706760` | |
| `Casino_Loop1.ogg` | 709,418 | `0x78A8C8` | |
| `Credits.txt` | 1,069 | `0x1CCE0C` | |
| `Engine.ini` | 2,422 | `0x837C34` | The complete match physics spec, plain ASCII |

## Assets shipped on disk

All plain, all editable.

| Path | Contents |
|---|---|
| `GameMedia/Data/Clubs.csv` | 5,438 clubs, 38 columns: strength, 3 rivals, stadium with capacity and lat/long, four full kit definitions, formation, nickname, nation, league, continental competition, B-team link |
| `GameMedia/Data/Competitions.csv` | 1,030 competitions, the entire calendar and competition engine |
| `GameMedia/Data/PromotionPlaces.csv` | The promotion, relegation and qualification graph |
| `GameMedia/Data/Nations.csv` | 213 nations plus climate and skin tones |
| `GameMedia/Data/Names.csv` | Per-nation forename and surname pools, including Cyrillic |
| `GameMedia/Languages/Languages.csv` | Every string in the game, 10 languages, about 2,000 tags |
| `GameMedia/Images/` and `EngineMedia/Match/` | 692 PNGs |
| `GameMedia/Sounds/` and `EngineMedia/Match/Sounds/` | 39 OGGs |
| `EngineMedia/Tactics/*.tac` | 13 formations, 105 bytes and 35 lines each |
| `EngineMedia/Fonts/*.fmf` | 2 bitmap fonts |

All `.csv` files are TAB-separated, not comma-separated.
