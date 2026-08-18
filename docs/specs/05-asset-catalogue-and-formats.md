# 05 - Asset Catalogue and File Formats

**Project:** NSS5-Forge - faithful source reconstruction of *New Star Soccer 5* (Steam appid 212780)
**Scope of this document:** every non-code asset shipped in the game's install folder - images, audio,
tactics files, fonts, and the small loose data files (`Horse.ini`, `Achievements.csv`, `Names.csv`,
`venues*.txt`, `Settings.txt`).
**Not in scope here:** `Clubs.csv`, `Competitions.csv`, `Continents.csv`, `Nations.csv`,
`PromotionPlaces.csv`, `Languages.csv` (large game-database tables - covered by the data-schema document),
and `Engine.ini` (incbin'd match-physics config - covered by the match-engine document).

**Source of truth:** `C:/Program Files (x86)/Steam/steamapps/common/New Star Soccer 5` (read-only).
Every dimension, byte count, colour type, sample rate and duration in this document was read directly
out of the file headers, not inferred from filenames.

---

## 0. Method

| What | How it was obtained |
|------|---------------------|
| PNG width/height/bit depth/colour type/interlace | Direct read of the IHDR chunk: bytes 16-23 = width then height as big-endian `uint32`; byte 24 = bit depth; byte 25 = colour type; byte 28 = interlace. All 692 files verified to start with the 8-byte PNG signature `89 50 4E 47 0D 0A 1A 0A`. |
| PNG ancillary chunks / palette size | Full chunk walk (`length:u32be`, `type:4`, `data`, `crc:u32`) from offset 8 to `IEND`. `PLTE` length / 3 = palette entry count. |
| Alpha | Colour type 6 (RGBA) or 4 (grey+alpha) ⇒ has an alpha channel. **No file in the game contains a `tRNS` chunk**, so palette and RGB images have no PNG-level transparency at all (see §2.2 - they use a colour key instead). |
| Mask colour | `GetPixel(0,0)` on every PNG, cross-referenced against colour type. |
| OGG | Ogg page header at offset 0 (`OggS`, segment count at byte 26), then the Vorbis identification packet: `0x01 "vorbis"`, version `u32`, channels `u8`, sample rate `u32le`, bitrate max/nominal/min `i32le`. Duration = granule position of the last `OggS` page ÷ sample rate. |
| `.tac` | Full byte dump plus a 13-way cross-comparison of every line (§4). |
| `.fmf` | Byte-level structural parse, validated by parsing both files end-to-end to *exactly* EOF with zero slack (§5). |

Where a claim could not be verified from the bytes it is flagged **UNCERTAIN**.

---

## 1. Top-level inventory

The install folder contains **798 files** in 37 directories. By extension:

| Ext | Count | Total bytes | Notes |
|-----|-------|-------------|-------|
| `.png` | 692 | 17,937,740 | All valid PNG, all non-interlaced |
| `.ogg` | 61 | 8,005,479 | Ogg Vorbis, on-disk SFX; music is incbin'd in the exe |
| `.tac` | 13 | 1,365 | Tactics formations, 105 bytes each |
| `.csv` | 8 | 3,263,453 | Tab-separated despite the extension |
| `.dll` | 5 | 1,190,016 | `OpenAL32`, `wrap_oal`, `steam_api`, `steamstub`, `IRClipboardFunctions` |
| `.txt` | 5 | 176 | 4 × `venues*.txt` + `Settings/Settings.txt` |
| `.jpg` | 4 | 2,863,452 | All in `GameMedia/Images/Backgrounds` |
| `.fmf` | 2 | 6,046,259 | Font Machine bitmap fonts |
| `.sfk` | 2 | 504 | **Stray** Sound Forge peak files (§7) |
| `.db` | 2 | 185,856 | **Stray** Windows `Thumbs.db` (§7) |
| `.exe` | 1 | 9,383,424 | `NSS5.exe` |
| `.pspimage` | 1 | 43,342 | **Stray** Paint Shop Pro source file (§7) |
| `.lib` | 1 | 5,394 | `steamstub.lib` - **stray** build artefact |
| `.ini` | 1 | 3,605 | `GameMedia/Data/Horse.ini` (not actually an INI - §6.1) |

Directory tree (asset-bearing directories only):

```
New Star Soccer 5/
├─ EngineMedia/
│  ├─ Fonts/            2 .fmf
│  ├─ Match/
│  │  ├─ Ball/          4 png
│  │  ├─ Other/        25 png
│  │  ├─ Pitch/        56 png  (+ Thumbs.db)
│  │  │  └─ Ads/        9 png  (+ AdBoard.pspimage)
│  │  ├─ Player/       22 png  (+ Thumbs.db)
│  │  └─ Sounds/       39 ogg  (+ StopWatchBeep.ogg.sfk)
│  └─ Tactics/         13 .tac
├─ GameMedia/
│  ├─ Data/             7 csv/ini + 4 venue txt
│  ├─ Images/
│  │  ├─ Backgrounds/  14 png + 4 jpg
│  │  ├─ Casino/       11 png
│  │  │  ├─ BlackJack/ 54 png
│  │  │  ├─ HigherLower/ 11 png
│  │  │  ├─ Pairs/     31 png
│  │  │  ├─ Roulette/   4 png
│  │  │  └─ Slots/      4 png
│  │  ├─ Icons/        95 png
│  │  ├─ Interface/    49 png
│  │  │  └─ Buttons/   17 png
│  │  ├─ Nations/     212 png
│  │  ├─ Relationships/ 10 png
│  │  ├─ Shop/
│  │  │  ├─ Boots/     10 png
│  │  │  ├─ Items/     10 png
│  │  │  ├─ Property/  10 png
│  │  │  └─ Vehicles/  10 png
│  │  └─ Stable/       13 png
│  │     ├─ Horse/      5 png
│  │     └─ Jockey/     6 png
│  ├─ Languages/        1 csv
│  └─ Sounds/          12 ogg
│     └─ Casino/       10 ogg  (+ Gallop.ogg.sfk)
└─ Settings/           Settings.txt
```

---

## 2. Images

### 2.1 Global PNG facts

Verified across all 692 PNGs:

| Property | Value | Count |
|----------|-------|-------|
| Signature | `89 50 4E 47 0D 0A 1A 0A` | 692 / 692 |
| Compression method | 0 (deflate) | 692 / 692 |
| Filter method | 0 (adaptive) | 692 / 692 |
| Interlace | 0 (none) - **no ADAM7 anywhere** | 692 / 692 |
| `tRNS` chunk present | **never** | 0 / 692 |

Colour-type / bit-depth breakdown:

| PNG colour type | Bit depth | Meaning | Count | Has alpha channel |
|-----------------|-----------|---------|-------|-------------------|
| 6 | 8 | RGBA | 338 | yes |
| 2 | 8 | RGB (truecolour) | 277 | no |
| 3 | 8 | Indexed, ≤256 colours | 53 | no |
| 3 | 4 | Indexed, ≤16 colours | 23 | no |
| 0 | 8 | Greyscale | 1 (`EngineMedia/Match/Pitch/Snow.png`) | no |

Chunk-set breakdown (ancillary chunks tell you which tool produced each file - useful when
re-exporting assets for the reconstruction so byte sizes stay in the same ballpark):

| Chunk set (after IHDR, before IDAT) | Count | Producer signature |
|-------------------------------------|-------|--------------------|
| `tIME + pHYs + gAMA` | 334 | Paint Shop Pro / generic |
| `tEXt + tIME + pHYs + gAMA` | 246 | as above, with a `Creation Time` tEXt |
| `tIME + pHYs + gAMA + PLTE` | 47 | palettised, generic |
| `tEXt` only | 29 | `Software: Adobe ImageReady` |
| `tEXt + tIME + pHYs + gAMA + PLTE` | 29 | palettised, generic |
| `gAMA + tEXt` | 5 | Adobe ImageReady |
| `tEXt + iTXt` | 2 | Adobe ImageReady + XMP packet |

The `tEXt` payloads seen are either `Creation Time <RFC-1123 date>` (dates range from
**11 May 2005** to **8 Mar 2011**) or `Software Adobe ImageReady`. Nothing functional depends on
these chunks; they can be dropped in a re-export.

### 2.2 Colour-key transparency - `#08846B` (IMPORTANT)

Because no PNG carries a `tRNS` chunk, every non-RGBA image that needs transparency relies on
**BlitzMax colour-key masking**. Sampling pixel (0,0) of all 354 non-RGBA PNGs shows **76 of them
have the exact corner colour `RGB(8, 132, 107)` = `#08846B`** - a dark green that appears nowhere as
a legitimate art colour. These are precisely the sprite sheets.

> **Reconstruction requirement:** the loader must call the BlitzMax equivalent of
> `SetMaskColor 8, 132, 107` before `LoadImage(..., MASKEDIMAGE)` for these files, and restore the
> default afterwards if other loads depend on it. Getting this wrong produces green boxes around
> every player, ball, horse and crowd sprite.
> **UNCERTAIN:** whether the game sets the mask colour once globally at startup or per-load. The
> exe's UTF-16 string table contains no literal for it (it would be three integer immediates in code),
> so this must be confirmed from the disassembly of the image-loading routine.

The 76 mask-keyed files:

| Folder | Files |
|--------|-------|
| `EngineMedia/Match/Ball` (2) | `Ball.png`, `Marker.png` |
| `EngineMedia/Match/Pitch` (16) | `Boss.png`, `Camera.png`, `CameraMan.png`, `Dugout.png`, `Fans.png`, `Goal1.png`, `Goal2.png`, `Photographer.png`, `Photographer2.png`, `Pitch.png`, `Pitch3.png`, `Pitch4.png`, `Poles.png`, `StadiumBottom.png`, `StadiumBottomGrass.png`, `StadiumTunnelBarrier.png` |
| `EngineMedia/Match/Player` (17) | `Keeper.png` and all 16 `Player_*.png` kit sheets |
| `GameMedia/Images/Interface` (31) | `MessageLine.png`, the 15 `Player_*.png` and the 15 `sPlayer_*.png` kit previews |
| `GameMedia/Images/Stable/Horse` (4) | `Horse_01.png` … `Horse_04.png` |
| `GameMedia/Images/Stable/Jockey` (6) | `Jockey_01.png` … `Jockey_06.png` |

Note that `Stable/Horse/Shadow.png` is RGBA and therefore *not* keyed, while the four horse sheets
next to it are. The remaining 278 non-RGBA PNGs are opaque backgrounds, flags and UI plates that need
no transparency at all.

A handful of non-keyed sprite sheets use a different corner colour and are drawn opaque or with their
own art background: `Mow0/Mow1/Mows.png` (corner `#000000`), `Goal1_Net.png` (`#C5C4C4`),
`Pitch1/1b/2/2b.png` (`#AED9A9` / `#FFFFFF`), `Snow.png` (greyscale, `#000000` - almost certainly
drawn additively rather than masked, **UNCERTAIN**).

### 2.3 Byte-identical duplicates

Seven groups of PNGs are byte-for-byte identical. A reconstruction can share one file per group, but
the shipped game keeps both copies and the *paths* are what the code references:

| Files | Note |
|-------|------|
| `EngineMedia/Match/Other/TacticsPitch.png` = `GameMedia/Images/Interface/TacticsPitch.png` | 600×400 RGBA, same art in match engine and front-end |
| `EngineMedia/Match/Other/Trophy.png` = `GameMedia/Images/Icons/Trophy.png` | |
| `GameMedia/Images/Casino/Pairs/Boss_2.png` = `.../Pairs/Sponsors_3.png` | Pairs mini-game card faces |
| `.../Pairs/Boss_4.png` = `.../Pairs/Fans_3.png` = `GameMedia/Images/Icons/Player.png` | |
| `.../Pairs/Fans_4.png` = `.../Pairs/Sponsors_4.png` = `GameMedia/Images/Icons/Media.png` | |
| `GameMedia/Images/Nations/NationIm_45.png` = `NationIm_x209.png` | `x209` is a disabled/backup entry (leading `x`) |
| `GameMedia/Images/Nations/NationIm_56b.png` = `NationIm_57.png` | `56b` is an alternate for nation 56 |

Additionally the nine pitch-side ad boards are only **three distinct images**. They are not
byte-identical (their `tIME` stamps differ) but their decoded pixel data hashes prove it - all nine
are 256 × 36 RGBA:

| Group | Files | Pixel MD5 | PNG bytes |
|-------|-------|-----------|-----------|
| A | `AdBoard_1`, `AdBoard_4`, `AdBoard_7` | `770D90A9DDB3DAE72193B32589732D98` | 5,542 |
| B | `AdBoard_2`, `AdBoard_5`, `AdBoard_8` | `C59633FCB42332D643D6D00109D2C644` | 13,354 |
| C | `AdBoard_3`, `AdBoard_6`, `AdBoard_9` | `AF13165C06F14B6A48F849F9EE85FEEC` | 12,471 |

So the perimeter hoarding cycles three designs; the nine filenames exist so the match renderer can
index nine boards without special-casing.

### 2.4 Non-PNG images

| File | Bytes | Dimensions | Format |
|------|-------|------------|--------|
| `GameMedia/Images/Backgrounds/StadiumBG.jpg` | 1,456,268 | 1810 × 1360 | Baseline JPEG, 24-bit RGB |
| `GameMedia/Images/Backgrounds/StadiumBG2.jpg` | 255,681 | 1280 × 600 | Baseline JPEG, 24-bit RGB |
| `GameMedia/Images/Backgrounds/WorldMap2.jpg` | 357,198 | 1280 × 640 | Baseline JPEG, 24-bit RGB |
| `GameMedia/Images/Backgrounds/WorldMap4.jpg` | 794,305 | 2560 × 1280 | Baseline JPEG, 24-bit RGB |
| `EngineMedia/Match/Pitch/Ads/AdBoard.pspimage` | 43,342 | - | **Not a game asset.** Paint Shop Pro source file; header is the ASCII string `Paint Shop Pro Image File\n\x1a` followed by `00 00 00 00 08 00 00 00`. Shipped by accident; the game only loads `AdBoard_1..9.png`. |

`WorldMap2.jpg` (1280×640) and `WorldMap4.jpg` (2560×1280) are the same map at 1× and 2× - almost
certainly a resolution-tier pair, as are `StadiumBG2.jpg` (1280×600) and `StadiumBG.jpg` (1810×1360).
**UNCERTAIN:** the exact selection rule.

### 2.5 Per-folder summary

| # | Folder | Files | PNG | JPG | Other | Total bytes | Distinct pixel sizes |
|---|--------|-------|-----|-----|-------|-------------|----------------------|
| 1 | `GameMedia/Images/Backgrounds` | 18 | 14 | 4 | 0 | 5,058,832 | 3 |
| 2 | `GameMedia/Images/Casino` | 11 | 11 | 0 | 0 | 187,224 | 2 |
| 3 | `GameMedia/Images/Casino/BlackJack` | 54 | 54 | 0 | 0 | 944,338 | 2 |
| 4 | `GameMedia/Images/Casino/HigherLower` | 11 | 11 | 0 | 0 | 42,856 | 1 |
| 5 | `GameMedia/Images/Casino/Pairs` | 31 | 31 | 0 | 0 | 222,975 | 6 |
| 6 | `GameMedia/Images/Casino/Roulette` | 4 | 4 | 0 | 0 | 763,646 | 4 |
| 7 | `GameMedia/Images/Casino/Slots` | 4 | 4 | 0 | 0 | 240,990 | 4 |
| 8 | `GameMedia/Images/Icons` | 95 | 95 | 0 | 0 | 221,522 | 56 |
| 9 | `GameMedia/Images/Interface` | 49 | 49 | 0 | 0 | 499,113 | 18 |
| 10 | `GameMedia/Images/Interface/Buttons` | 17 | 17 | 0 | 0 | 31,194 | 1 |
| 11 | `GameMedia/Images/Nations` | 212 | 212 | 0 | 0 | 239,783 | 2 |
| 12 | `GameMedia/Images/Relationships` | 10 | 10 | 0 | 0 | 1,681,356 | 1 |
| 13 | `GameMedia/Images/Shop/Boots` | 10 | 10 | 0 | 0 | 46,780 | 1 |
| 14 | `GameMedia/Images/Shop/Items` | 10 | 10 | 0 | 0 | 154,038 | 1 |
| 15 | `GameMedia/Images/Shop/Property` | 10 | 10 | 0 | 0 | 212,521 | 1 |
| 16 | `GameMedia/Images/Shop/Vehicles` | 10 | 10 | 0 | 0 | 157,976 | 1 |
| 17 | `GameMedia/Images/Stable` | 13 | 13 | 0 | 0 | 49,001 | 8 |
| 18 | `GameMedia/Images/Stable/Horse` | 5 | 5 | 0 | 0 | 47,103 | 2 |
| 19 | `GameMedia/Images/Stable/Jockey` | 6 | 6 | 0 | 0 | 7,398 | 1 |
| 20 | `EngineMedia/Match/Ball` | 4 | 4 | 0 | 0 | 15,822 | 4 |
| 21 | `EngineMedia/Match/Other` | 25 | 25 | 0 | 0 | 369,558 | 19 |
| 22 | `EngineMedia/Match/Pitch` | 56 | 56 | 0 | 0 | 8,367,408 | 30 |
| 23 | `EngineMedia/Match/Pitch/Ads` | 10 | 9 | 0 | 1 | 137,443 | 1 |
| 24 | `EngineMedia/Match/Player` | 22 | 22 | 0 | 0 | 1,145,657 | 5 |


### 2.6 Sprite-sheet grids (derived)

Several of the mask-keyed sheets have a regular frame grid, recoverable by finding rows/columns that
are entirely mask colour. Results:

| Sheet | Sheet size | Fully-blank row ranges | Fully-blank col ranges | Deduced grid | Confidence |
|-------|-----------|------------------------|------------------------|--------------|------------|
| `Match/Player/Player_Plain.png` (and all other `Player_*.png`) | 2048 × 1536 | 0-36, 127, 512-535, 639, 1024-1055, 1151 | none | **128 × 128 cells, 16 cols × 12 rows = 192 frames** - blanks land exactly on cell boundaries 127 / 639 / 1151 | High |
| `Match/Player/Keeper.png` | 2048 × 1536 | 0-36, 127, 512-535, 639, 896-902, 1019-1055, 1151, 1408-1433, 1535 | 256-292, 363-383 | Same 128 × 128 / 16 × 12 grid; keeper simply uses fewer cells | High |
| `Stable/Horse/Horse_01..04.png` | 1024 × 80 | 0-21 | 0-13, 111-146, 240-272, 369-396, 495-523, 626-647, 754-778, 881-913, 1007-1023 | **128 × 80 cells, 8 frames in a row** (gaps recur every 128 px); art occupies rows 22-79 | High |
| `Stable/Jockey/Jockey_01..06.png` | 1024 × 80 | 0-15, 44-79 | recurring every 128 px | **128 × 80 cells, 8 frames**; art occupies rows 16-43 only | High |
| `Match/Pitch/Fans.png` | 384 × 640 | 0-29, 127-168, 255-288, 383-418, 511-547, 639 | 0-5, 51-70, 122-143, 182-197, 243-262, 314-335, 374-383 | **64 × 128 cells, 6 cols × 5 rows = 30 crowd sprites** | Medium-High |
| `Match/Ball/Ball.png` | 120 × 40 | none | none | No blank separators. 120 = 3 × 40, so most likely **3 frames of 40 × 40**; could also be a single 120×40 strip | **UNCERTAIN** |
| `Match/Pitch/Mows.png` | 512 × 128 | none | 128-190 (etc.) | Mow-stripe tiles; **UNCERTAIN**, corner colour is black not the mask green |

Cross-check: `EngineMedia/Match/Player/` contains **16** kit-pattern sheets, all 2048 × 1536 indexed:
`Player_Chequered`, `Player_DiagonalSplit`, `Player_Hoop`, `Player_Hoops`, `Player_Hoopsb`,
`Player_Plain`, `Player_Segments`, `Player_SleeveR`, `Player_Sleeves`, `Player_Split`,
`Player_StripeC`, `Player_StripeLR`, `Player_StripeR`, `Player_Stripes`, `Player_Trim`, `Player_V`.
`GameMedia/Images/Interface/` mirrors 15 of them (no `Hoopsb`) at 114 × 240 for the large kit preview
and again at 40 × 84 with an `s` prefix for the small kit preview. Because these are indexed images
the game almost certainly **re-maps palette entries at load time to apply each club's kit colours** - 
the `Player_*.png` palettes are only 22-27 entries, far too few for arbitrary artwork but exactly
right for a recolourable 3-4-colour kit plus skin/shorts/socks ramps.
**UNCERTAIN:** the exact palette-index → kit-colour-slot mapping. That must come from the disassembly.

### 2.7 Full image catalogue

Every image file, grouped by folder. `Bits` = PNG bit depth; `Colour type` uses the PNG names
(`RGBA` = type 6, `RGB` = type 2, `Indexed` = type 3, `Grey` = type 0); `Alpha` is the presence of a
real alpha channel (no file uses `tRNS`, so `no` means fully opaque unless the file is colour-keyed
per §2.2).


#### `GameMedia/Images/Backgrounds`  (18 files)

| File | W x H | Bits | Colour type | Alpha | Bytes | Extra PNG chunks |
|------|-------|------|-------------|-------|-------|------------------|
| Grass.png | 1280 x 720 | 8 | RGB | no | 270,327 | tEXt + tIME + pHYs + gAMA |
| Hands_1.png | 800 x 600 | 8 | RGBA | yes | 74,804 | tEXt + tIME + pHYs + gAMA |
| Hands_2.png | 800 x 600 | 8 | RGBA | yes | 73,264 | tEXt + tIME + pHYs + gAMA |
| Hands_3.png | 800 x 600 | 8 | RGBA | yes | 69,471 | tEXt + tIME + pHYs + gAMA |
| Hands_4.png | 800 x 600 | 8 | RGBA | yes | 44,581 | tEXt + tIME + pHYs + gAMA |
| Hands_5.png | 800 x 600 | 8 | RGBA | yes | 74,236 | tEXt + tIME + pHYs + gAMA |
| Interview.png | 800 x 600 | 8 | RGB | no | 282,494 | tIME + pHYs + gAMA |
| MyBg.png | 800 x 600 | 8 | RGB | no | 374,944 | tEXt + tIME + pHYs + gAMA |
| MyBg2.png | 800 x 600 | 8 | RGB | no | 339,520 | tEXt + tIME + pHYs + gAMA |
| Newspaper.png | 800 x 600 | 8 | RGB | no | 225,340 | tEXt + tIME + pHYs + gAMA |
| NewspaperPhoto.png | 800 x 600 | 8 | RGBA | yes | 237,686 | tEXt + tIME + pHYs + gAMA |
| report_boss.png | 400 x 440 | 8 | RGB | no | 41,412 | tIME + pHYs + gAMA |
| report_physio.png | 400 x 440 | 8 | RGB | no | 46,335 | gAMA + tEXt |
| StadiumBG.jpg | - | - | - | - | 1,456,268 | JPEG (see 2.4) |
| StadiumBG2.jpg | - | - | - | - | 255,681 | JPEG (see 2.4) |
| WebPage.png | 800 x 600 | 8 | RGB | no | 40,966 | tEXt + tIME + pHYs + gAMA |
| WorldMap2.jpg | - | - | - | - | 357,198 | JPEG (see 2.4) |
| WorldMap4.jpg | - | - | - | - | 794,305 | JPEG (see 2.4) |

#### `GameMedia/Images/Casino`  (11 files)

| File | W x H | Bits | Colour type | Alpha | Bytes | Extra PNG chunks |
|------|-------|------|-------------|-------|-------|------------------|
| btn_BlackJack.png | 220 x 150 | 8 | RGB | no | 48,513 | tIME + pHYs + gAMA |
| btn_Racing.png | 220 x 150 | 8 | RGB | no | 43,692 | tIME + pHYs + gAMA |
| btn_Roulette.png | 220 x 150 | 8 | RGB | no | 46,322 | tIME + pHYs + gAMA |
| btn_slots.png | 220 x 150 | 8 | RGB | no | 38,359 | tIME + pHYs + gAMA |
| Chip_100.png | 32 x 32 | 8 | RGBA | yes | 1,454 | tIME + pHYs + gAMA |
| Chip_1000.png | 32 x 32 | 8 | RGBA | yes | 1,410 | tIME + pHYs + gAMA |
| Chip_250.png | 32 x 32 | 8 | RGBA | yes | 1,618 | tIME + pHYs + gAMA |
| Chip_2500.png | 32 x 32 | 8 | RGBA | yes | 1,568 | tIME + pHYs + gAMA |
| Chip_50.png | 32 x 32 | 8 | RGBA | yes | 1,572 | tIME + pHYs + gAMA |
| Chip_500.png | 32 x 32 | 8 | RGBA | yes | 1,340 | tIME + pHYs + gAMA |
| Chip_5000.png | 32 x 32 | 8 | RGBA | yes | 1,376 | tIME + pHYs + gAMA |

#### `GameMedia/Images/Casino/BlackJack`  (54 files)

| File | W x H | Bits | Colour type | Alpha | Bytes | Extra PNG chunks |
|------|-------|------|-------------|-------|-------|------------------|
| 1_club.png | 84 x 122 | 8 | RGBA | yes | 3,989 | tIME + pHYs + gAMA |
| 1_diamond.png | 84 x 122 | 8 | RGBA | yes | 2,441 | tIME + pHYs + gAMA |
| 1_heart.png | 84 x 122 | 8 | RGBA | yes | 2,569 | tIME + pHYs + gAMA |
| 1_spade.png | 84 x 122 | 8 | RGBA | yes | 2,257 | tIME + pHYs + gAMA |
| 10_club.png | 84 x 122 | 8 | RGBA | yes | 6,093 | tIME + pHYs + gAMA |
| 10_diamond.png | 84 x 122 | 8 | RGBA | yes | 6,055 | tIME + pHYs + gAMA |
| 10_heart.png | 84 x 122 | 8 | RGBA | yes | 6,732 | tIME + pHYs + gAMA |
| 10_spade.png | 84 x 122 | 8 | RGBA | yes | 5,311 | tIME + pHYs + gAMA |
| 11_club.png | 84 x 122 | 8 | RGBA | yes | 17,278 | tIME + pHYs + gAMA |
| 11_diamond.png | 84 x 122 | 8 | RGBA | yes | 16,542 | tIME + pHYs + gAMA |
| 11_heart.png | 84 x 122 | 8 | RGBA | yes | 16,930 | tIME + pHYs + gAMA |
| 11_spade.png | 84 x 122 | 8 | RGBA | yes | 17,569 | tIME + pHYs + gAMA |
| 12_club.png | 84 x 122 | 8 | RGBA | yes | 16,969 | tIME + pHYs + gAMA |
| 12_diamond.png | 84 x 122 | 8 | RGBA | yes | 16,960 | tIME + pHYs + gAMA |
| 12_heart.png | 84 x 122 | 8 | RGBA | yes | 19,096 | tIME + pHYs + gAMA |
| 12_spade.png | 84 x 122 | 8 | RGBA | yes | 16,929 | tIME + pHYs + gAMA |
| 13_club.png | 84 x 122 | 8 | RGBA | yes | 17,903 | tIME + pHYs + gAMA |
| 13_diamond.png | 84 x 122 | 8 | RGBA | yes | 18,137 | tIME + pHYs + gAMA |
| 13_heart.png | 84 x 122 | 8 | RGBA | yes | 16,896 | tIME + pHYs + gAMA |
| 13_spade.png | 84 x 122 | 8 | RGBA | yes | 17,285 | tIME + pHYs + gAMA |
| 2_club.png | 84 x 122 | 8 | RGBA | yes | 2,828 | tIME + pHYs + gAMA |
| 2_diamond.png | 84 x 122 | 8 | RGBA | yes | 2,693 | tIME + pHYs + gAMA |
| 2_heart.png | 84 x 122 | 8 | RGBA | yes | 2,923 | tIME + pHYs + gAMA |
| 2_spade.png | 84 x 122 | 8 | RGBA | yes | 2,596 | tIME + pHYs + gAMA |
| 3_club.png | 84 x 122 | 8 | RGBA | yes | 3,439 | tIME + pHYs + gAMA |
| 3_diamond.png | 84 x 122 | 8 | RGBA | yes | 3,249 | tIME + pHYs + gAMA |
| 3_heart.png | 84 x 122 | 8 | RGBA | yes | 3,602 | tIME + pHYs + gAMA |
| 3_spade.png | 84 x 122 | 8 | RGBA | yes | 3,123 | tIME + pHYs + gAMA |
| 4_club.png | 84 x 122 | 8 | RGBA | yes | 3,591 | tIME + pHYs + gAMA |
| 4_diamond.png | 84 x 122 | 8 | RGBA | yes | 3,444 | tIME + pHYs + gAMA |
| 4_heart.png | 84 x 122 | 8 | RGBA | yes | 3,745 | tIME + pHYs + gAMA |
| 4_spade.png | 84 x 122 | 8 | RGBA | yes | 3,255 | tIME + pHYs + gAMA |
| 5_club.png | 84 x 122 | 8 | RGBA | yes | 4,162 | tIME + pHYs + gAMA |
| 5_diamond.png | 84 x 122 | 8 | RGBA | yes | 3,958 | tIME + pHYs + gAMA |
| 5_heart.png | 84 x 122 | 8 | RGBA | yes | 4,437 | tIME + pHYs + gAMA |
| 5_spade.png | 84 x 122 | 8 | RGBA | yes | 3,721 | tIME + pHYs + gAMA |
| 6_club.png | 84 x 122 | 8 | RGBA | yes | 4,664 | tIME + pHYs + gAMA |
| 6_diamond.png | 84 x 122 | 8 | RGBA | yes | 4,531 | tIME + pHYs + gAMA |
| 6_heart.png | 84 x 122 | 8 | RGBA | yes | 5,057 | tIME + pHYs + gAMA |
| 6_spade.png | 84 x 122 | 8 | RGBA | yes | 4,189 | tIME + pHYs + gAMA |
| 7_club.png | 84 x 122 | 8 | RGBA | yes | 4,821 | tIME + pHYs + gAMA |
| 7_diamond.png | 84 x 122 | 8 | RGBA | yes | 4,608 | tIME + pHYs + gAMA |
| 7_heart.png | 84 x 122 | 8 | RGBA | yes | 5,149 | tIME + pHYs + gAMA |
| 7_spade.png | 84 x 122 | 8 | RGBA | yes | 4,298 | tIME + pHYs + gAMA |
| 8_club.png | 84 x 122 | 8 | RGBA | yes | 5,347 | tIME + pHYs + gAMA |
| 8_diamond.png | 84 x 122 | 8 | RGBA | yes | 5,314 | tIME + pHYs + gAMA |
| 8_heart.png | 84 x 122 | 8 | RGBA | yes | 5,873 | tIME + pHYs + gAMA |
| 8_spade.png | 84 x 122 | 8 | RGBA | yes | 4,746 | tIME + pHYs + gAMA |
| 9_club.png | 84 x 122 | 8 | RGBA | yes | 5,672 | tIME + pHYs + gAMA |
| 9_diamond.png | 84 x 122 | 8 | RGBA | yes | 5,695 | tIME + pHYs + gAMA |
| 9_heart.png | 84 x 122 | 8 | RGBA | yes | 6,357 | tIME + pHYs + gAMA |
| 9_spade.png | 84 x 122 | 8 | RGBA | yes | 4,970 | tIME + pHYs + gAMA |
| back.png | 84 x 122 | 8 | RGBA | yes | 19,183 | tIME + pHYs + gAMA |
| bg.png | 800 x 600 | 8 | RGB | no | 545,157 | tIME + pHYs + gAMA |

#### `GameMedia/Images/Casino/HigherLower`  (11 files)

| File | W x H | Bits | Colour type | Alpha | Bytes | Extra PNG chunks |
|------|-------|------|-------------|-------|-------|------------------|
| Player1.png | 52 x 54 | 8 | RGBA | yes | 3,661 | tIME + pHYs + gAMA |
| Player10.png | 52 x 54 | 8 | RGBA | yes | 3,962 | tIME + pHYs + gAMA |
| Player11.png | 52 x 54 | 8 | RGBA | yes | 3,628 | tIME + pHYs + gAMA |
| Player2.png | 52 x 54 | 8 | RGBA | yes | 3,939 | tIME + pHYs + gAMA |
| Player3.png | 52 x 54 | 8 | RGBA | yes | 4,062 | tIME + pHYs + gAMA |
| Player4.png | 52 x 54 | 8 | RGBA | yes | 3,785 | tIME + pHYs + gAMA |
| Player5.png | 52 x 54 | 8 | RGBA | yes | 3,991 | tIME + pHYs + gAMA |
| Player6.png | 52 x 54 | 8 | RGBA | yes | 3,987 | tIME + pHYs + gAMA |
| Player7.png | 52 x 54 | 8 | RGBA | yes | 3,838 | tIME + pHYs + gAMA |
| Player8.png | 52 x 54 | 8 | RGBA | yes | 4,038 | tIME + pHYs + gAMA |
| Player9.png | 52 x 54 | 8 | RGBA | yes | 3,965 | tIME + pHYs + gAMA |

#### `GameMedia/Images/Casino/Pairs`  (31 files)

| File | W x H | Bits | Colour type | Alpha | Bytes | Extra PNG chunks |
|------|-------|------|-------------|-------|-------|------------------|
| BG_1.png | 86 x 86 | 8 | RGB | no | 11,206 | tEXt |
| BG_2.png | 86 x 86 | 8 | RGB | no | 12,105 | tEXt |
| BG_3.png | 86 x 86 | 8 | RGB | no | 11,406 | tEXt |
| BG_4.png | 86 x 86 | 8 | RGB | no | 10,450 | tEXt |
| BG_5.png | 86 x 86 | 8 | RGB | no | 10,632 | tEXt |
| Boss_1.png | 49 x 60 | 8 | RGBA | yes | 3,927 | tEXt + tIME + pHYs + gAMA |
| Boss_2.png | 60 x 80 | 8 | RGBA | yes | 6,294 | tEXt |
| Boss_3.png | 86 x 86 | 8 | RGBA | yes | 7,220 | tIME + pHYs + gAMA |
| Boss_4.png | 60 x 80 | 8 | RGBA | yes | 5,199 | tEXt |
| Fans_1.png | 60 x 60 | 8 | RGBA | yes | 3,488 | tIME + pHYs + gAMA |
| Fans_2.png | 64 x 60 | 8 | RGBA | yes | 6,643 | tIME + pHYs + gAMA |
| Fans_3.png | 60 x 80 | 8 | RGBA | yes | 5,199 | tEXt |
| Fans_4.png | 60 x 80 | 8 | RGBA | yes | 5,700 | tEXt |
| Friends_1.png | 86 x 86 | 8 | RGBA | yes | 9,194 | tEXt |
| Friends_2.png | 86 x 86 | 8 | RGBA | yes | 9,609 | tEXt + tIME + pHYs + gAMA |
| Friends_3.png | 86 x 86 | 8 | RGBA | yes | 10,234 | tEXt |
| Friends_4.png | 86 x 86 | 8 | RGBA | yes | 7,295 | tEXt |
| Girl_1.png | 86 x 86 | 8 | RGBA | yes | 7,827 | tEXt |
| Girl_2.png | 86 x 86 | 8 | RGBA | yes | 6,064 | tEXt |
| Girl_3.png | 86 x 86 | 8 | RGBA | yes | 10,578 | tEXt |
| Girl_4.png | 86 x 86 | 8 | RGBA | yes | 6,317 | tIME + pHYs + gAMA |
| Sponsors_1.png | 86 x 86 | 8 | RGBA | yes | 6,449 | tEXt |
| Sponsors_2.png | 60 x 80 | 8 | RGBA | yes | 6,107 | tEXt |
| Sponsors_3.png | 60 x 80 | 8 | RGBA | yes | 6,294 | tEXt |
| Sponsors_4.png | 60 x 80 | 8 | RGBA | yes | 5,700 | tEXt |
| Team_1.png | 86 x 86 | 8 | RGBA | yes | 6,719 | tEXt + tIME + pHYs + gAMA |
| Team_2.png | 84 x 84 | 8 | RGBA | yes | 4,362 | tEXt + tIME + pHYs + gAMA |
| Team_3.png | 49 x 60 | 8 | RGBA | yes | 3,927 | tEXt + tIME + pHYs + gAMA |
| Team_4.png | 60 x 60 | 8 | RGBA | yes | 5,392 | tEXt + tIME + pHYs + gAMA |
| Team_6.png | 60 x 80 | 8 | RGBA | yes | 5,488 | tEXt |
| Team_8.png | 60 x 80 | 8 | RGBA | yes | 5,950 | tEXt |

#### `GameMedia/Images/Casino/Roulette`  (4 files)

| File | W x H | Bits | Colour type | Alpha | Bytes | Extra PNG chunks |
|------|-------|------|-------------|-------|-------|------------------|
| Ball.png | 8 x 8 | 8 | RGBA | yes | 325 | tEXt + tIME + pHYs + gAMA |
| bg.png | 800 x 600 | 8 | RGB | no | 619,298 | tIME + pHYs + gAMA |
| Wheel.png | 354 x 354 | 8 | RGBA | yes | 80,243 | tEXt + iTXt |
| Wheel_Inner.png | 204 x 204 | 8 | RGBA | yes | 63,780 | tEXt + iTXt |

#### `GameMedia/Images/Casino/Slots`  (4 files)

| File | W x H | Bits | Colour type | Alpha | Bytes | Extra PNG chunks |
|------|-------|------|-------------|-------|-------|------------------|
| bg.png | 800 x 600 | 8 | RGB | no | 162,231 | tIME + pHYs + gAMA |
| Button.png | 81 x 55 | 8 | RGBA | yes | 5,955 | tEXt + tIME + pHYs + gAMA |
| glass.png | 400 x 300 | 8 | RGBA | yes | 28,575 | tIME + pHYs + gAMA |
| Strip.png | 86 x 688 | 8 | RGBA | yes | 44,229 | tIME + pHYs + gAMA |

#### `GameMedia/Images/Icons`  (95 files)

| File | W x H | Bits | Colour type | Alpha | Bytes | Extra PNG chunks |
|------|-------|------|-------------|-------|-------|------------------|
| ArrowD.png | 20 x 28 | 8 | RGBA | yes | 858 | tIME + pHYs + gAMA |
| ArrowD_Red.png | 20 x 28 | 8 | RGBA | yes | 806 | tIME + pHYs + gAMA |
| ArrowL.png | 39 x 28 | 8 | RGBA | yes | 1,034 | tIME + pHYs + gAMA |
| ArrowR.png | 39 x 28 | 8 | RGBA | yes | 951 | tIME + pHYs + gAMA |
| ArrowRs.png | 20 x 14 | 8 | RGBA | yes | 556 | tIME + pHYs + gAMA |
| ArrowU.png | 20 x 28 | 8 | RGBA | yes | 829 | tIME + pHYs + gAMA |
| Ball.png | 32 x 32 | 8 | RGBA | yes | 2,269 | tEXt + tIME + pHYs + gAMA |
| Boot22.png | 34 x 22 | 8 | RGBA | yes | 1,747 | tIME + pHYs + gAMA |
| Boot28.png | 48 x 28 | 8 | RGBA | yes | 2,464 | tIME + pHYs + gAMA |
| BootBoost.png | 64 x 64 | 8 | RGBA | yes | 2,534 | tIME + pHYs + gAMA |
| Booze.png | 28 x 40 | 8 | RGBA | yes | 2,672 | tIME + pHYs + gAMA |
| Booze28.png | 48 x 28 | 8 | RGBA | yes | 2,431 | tIME + pHYs + gAMA |
| BoozeBoost.png | 64 x 64 | 8 | RGBA | yes | 5,888 | tIME + pHYs + gAMA |
| Boss.png | 26 x 38 | 8 | RGBA | yes | 2,232 | tIME + pHYs + gAMA |
| Casino.png | 31 x 32 | 8 | RGBA | yes | 2,789 | tEXt + tIME + pHYs + gAMA |
| Casino120.png | 81 x 100 | 8 | RGBA | yes | 5,366 | tIME + pHYs + gAMA |
| Cherry.png | 28 x 26 | 8 | RGBA | yes | 1,729 | tIME + pHYs + gAMA |
| Club.png | 28 x 28 | 8 | RGBA | yes | 2,046 | tIME + pHYs + gAMA |
| Console.png | 50 x 28 | 8 | RGBA | yes | 2,487 | tIME + pHYs + gAMA |
| Contract.png | 28 x 28 | 8 | RGBA | yes | 1,357 | tIME + pHYs + gAMA |
| Contract14.png | 14 x 14 | 8 | RGBA | yes | 599 | tIME + pHYs + gAMA |
| Contract20.png | 20 x 20 | 8 | RGBA | yes | 873 | tIME + pHYs + gAMA |
| Country.png | 28 x 28 | 8 | RGBA | yes | 1,988 | tIME + pHYs + gAMA |
| Cross.png | 30 x 30 | 8 | RGBA | yes | 1,415 | tEXt + tIME + pHYs + gAMA |
| CrossSmall.png | 16 x 16 | 8 | RGBA | yes | 903 | tEXt + tIME + pHYs + gAMA |
| Drugs28.png | 24 x 28 | 8 | RGBA | yes | 1,940 | tIME + pHYs + gAMA |
| DrugsBoost.png | 64 x 64 | 8 | RGBA | yes | 3,476 | tIME + pHYs + gAMA |
| Eye.png | 28 x 28 | 8 | RGBA | yes | 1,753 | tEXt + tIME + pHYs + gAMA |
| facebook.png | 20 x 20 | 8 | RGBA | yes | 1,036 | tIME + pHYs + gAMA |
| Fans.png | 36 x 34 | 8 | RGBA | yes | 2,815 | tIME + pHYs + gAMA |
| Finances.png | 18 x 28 | 8 | RGBA | yes | 1,345 | tEXt + tIME + pHYs + gAMA |
| Finances20.png | 13 x 20 | 8 | RGBA | yes | 927 | tEXt + tIME + pHYs + gAMA |
| Forum.png | 18 x 18 | 8 | RGBA | yes | 1,116 | tEXt + tIME + pHYs + gAMA |
| Friend.png | 28 x 35 | 8 | RGBA | yes | 2,731 | tEXt + tIME + pHYs + gAMA |
| Friend20.png | 16 x 20 | 8 | RGBA | yes | 992 | tEXt + tIME + pHYs + gAMA |
| Girlfriend.png | 25 x 36 | 8 | RGBA | yes | 1,914 | tIME + pHYs + gAMA |
| Help.png | 21 x 28 | 8 | RGBA | yes | 1,189 | tIME + pHYs + gAMA |
| Home.png | 29 x 26 | 8 | RGBA | yes | 1,539 | tIME + pHYs + gAMA |
| Home20.png | 20 x 18 | 8 | RGBA | yes | 1,094 | tIME + pHYs + gAMA |
| Media.png | 60 x 80 | 8 | RGBA | yes | 5,700 | tEXt |
| Mobile.png | 10 x 20 | 8 | RGBA | yes | 567 | tIME + pHYs + gAMA |
| Money.png | 24 x 34 | 8 | RGBA | yes | 1,933 | tIME + pHYs + gAMA |
| Money120.png | 140 x 80 | 8 | RGBA | yes | 10,961 | tIME + pHYs + gAMA |
| MusicPlayer.png | 44 x 28 | 8 | RGBA | yes | 2,895 | tIME + pHYs + gAMA |
| NRG.png | 17 x 40 | 8 | RGBA | yes | 2,144 | tIME + pHYs + gAMA |
| NRG28.png | 48 x 28 | 8 | RGBA | yes | 2,446 | tIME + pHYs + gAMA |
| NRGBoost.png | 64 x 64 | 8 | RGBA | yes | 3,757 | tIME + pHYs + gAMA |
| Offline.png | 20 x 20 | 8 | RGBA | yes | 1,353 | tEXt + tIME + pHYs + gAMA |
| Options.png | 30 x 28 | 8 | RGBA | yes | 2,400 | tEXt + tIME + pHYs + gAMA |
| PainKiller.png | 44 x 30 | 8 | RGBA | yes | 1,659 | tEXt + tIME + pHYs + gAMA |
| PlayBall.png | 72 x 28 | 8 | RGBA | yes | 2,652 | tIME + pHYs + gAMA |
| PlayBoss.png | 72 x 28 | 8 | RGBA | yes | 1,968 | tIME + pHYs + gAMA |
| PlayCoach.png | 72 x 28 | 8 | RGBA | yes | 1,951 | tIME + pHYs + gAMA |
| PlayCup.png | 72 x 28 | 8 | RGBA | yes | 2,683 | tIME + pHYs + gAMA |
| Player.png | 60 x 80 | 8 | RGBA | yes | 5,199 | tEXt |
| PlayFreeTime.png | 72 x 28 | 8 | RGBA | yes | 2,604 | tIME + pHYs + gAMA |
| PlayIncident.png | 72 x 28 | 8 | RGBA | yes | 2,075 | tIME + pHYs + gAMA |
| PlayNewspaper.png | 72 x 28 | 8 | RGBA | yes | 2,220 | tIME + pHYs + gAMA |
| PlayPhysio.png | 72 x 28 | 8 | RGBA | yes | 1,739 | tIME + pHYs + gAMA |
| PlayRace.png | 72 x 28 | 8 | RGBA | yes | 1,783 | tIME + pHYs + gAMA |
| PlayRelations.png | 72 x 28 | 8 | RGBA | yes | 2,442 | tIME + pHYs + gAMA |
| PlayWeb.png | 72 x 28 | 8 | RGBA | yes | 2,190 | tIME + pHYs + gAMA |
| Profile.png | 27 x 30 | 8 | RGBA | yes | 2,184 | tIME + pHYs + gAMA |
| QuestionMark.png | 15 x 20 | 8 | RGBA | yes | 760 | tIME + pHYs + gAMA |
| Refresh.png | 25 x 32 | 8 | RGBA | yes | 1,688 | tIME + pHYs + gAMA |
| Relationships.png | 24 x 28 | 8 | RGBA | yes | 1,805 | tIME + pHYs + gAMA |
| Relationships120.png | 194 x 90 | 8 | RGBA | yes | 22,496 | tEXt + tIME + pHYs + gAMA |
| Relationships20.png | 17 x 20 | 8 | RGBA | yes | 1,111 | tIME + pHYs + gAMA |
| Replays.png | 33 x 32 | 8 | RGBA | yes | 1,782 | tEXt + tIME + pHYs + gAMA |
| ShinPads28.png | 48 x 28 | 8 | RGBA | yes | 2,043 | tEXt + tIME + pHYs + gAMA |
| ShinPadsBoost.png | 64 x 64 | 8 | RGBA | yes | 5,489 | tEXt + tIME + pHYs + gAMA |
| Shirt.png | 27 x 28 | 8 | RGBA | yes | 1,625 | tIME + pHYs + gAMA |
| Shirt14.png | 14 x 14 | 8 | RGBA | yes | 712 | tIME + pHYs + gAMA |
| Shirt20.png | 19 x 20 | 8 | RGBA | yes | 1,030 | tIME + pHYs + gAMA |
| Spanner.png | 30 x 28 | 8 | RGBA | yes | 2,138 | tEXt + tIME + pHYs + gAMA |
| Sponsors.png | 38 x 38 | 8 | RGBA | yes | 1,964 | tIME + pHYs + gAMA |
| Stable.png | 29 x 22 | 8 | RGBA | yes | 1,104 | tEXt + tIME + pHYs + gAMA |
| Star.png | 32 x 32 | 8 | RGBA | yes | 1,291 | tIME + pHYs + gAMA |
| Star14.png | 14 x 13 | 8 | RGBA | yes | 570 | tIME + pHYs + gAMA |
| Star20.png | 20 x 20 | 8 | RGBA | yes | 826 | tIME + pHYs + gAMA |
| Star28.png | 28 x 28 | 8 | RGBA | yes | 1,398 | tIME + pHYs + gAMA |
| StarGrey.png | 32 x 32 | 8 | RGBA | yes | 1,179 | tIME + pHYs + gAMA |
| StarGrey28.png | 28 x 28 | 8 | RGBA | yes | 1,239 | tIME + pHYs + gAMA |
| Tablet.png | 44 x 28 | 8 | RGBA | yes | 2,062 | tIME + pHYs + gAMA |
| Team.png | 37 x 32 | 8 | RGBA | yes | 2,745 | tIME + pHYs + gAMA |
| Tick.png | 37 x 28 | 8 | RGBA | yes | 1,853 | tEXt + tIME + pHYs + gAMA |
| TickSmall.png | 21 x 16 | 8 | RGBA | yes | 880 | tEXt + tIME + pHYs + gAMA |
| Training.png | 31 x 26 | 8 | RGBA | yes | 1,859 | tEXt + tIME + pHYs + gAMA |
| Training120.png | 105 x 90 | 8 | RGBA | yes | 11,749 | tEXt + tIME + pHYs + gAMA |
| Trophy.png | 28 x 30 | 8 | RGBA | yes | 1,835 | tIME + pHYs + gAMA |
| Trophy14.png | 13 x 14 | 8 | RGBA | yes | 751 | tIME + pHYs + gAMA |
| twitter.png | 20 x 20 | 8 | RGBA | yes | 1,084 | tIME + pHYs + gAMA |
| World.png | 28 x 28 | 8 | RGBA | yes | 2,131 | tIME + pHYs + gAMA |
| World14.png | 14 x 14 | 8 | RGBA | yes | 798 | tIME + pHYs + gAMA |
| World20.png | 20 x 20 | 8 | RGBA | yes | 1,330 | tIME + pHYs + gAMA |

#### `GameMedia/Images/Interface`  (49 files)

| File | W x H | Bits | Colour type | Alpha | Bytes | Extra PNG chunks |
|------|-------|------|-------------|-------|-------|------------------|
| Arrow.png | 59 x 19 | 8 | RGBA | yes | 239 | tIME + pHYs + gAMA |
| Blob.png | 9 x 9 | 8 | RGBA | yes | 375 | tIME + pHYs + gAMA |
| Block.png | 11 x 11 | 8 | RGB | no | 150 | tIME + pHYs + gAMA |
| Combo.png | 9 x 16 | 8 | RGBA | yes | 224 | tEXt + tIME + pHYs + gAMA |
| Cursor.png | 44 x 33 | 8 | RGBA | yes | 599 | tIME + pHYs + gAMA |
| Heatmap.png | 128 x 128 | 8 | RGBA | yes | 2,509 | tIME + pHYs + gAMA |
| Joystick.png | 48 x 48 | 8 | RGBA | yes | 2,310 | tIME + pHYs + gAMA |
| Joystick2.png | 48 x 48 | 8 | RGBA | yes | 2,446 | tIME + pHYs + gAMA |
| Keys.png | 64 x 64 | 8 | RGBA | yes | 362 | tIME + pHYs + gAMA |
| ListDown.png | 16 x 9 | 8 | RGBA | yes | 224 | tEXt + tIME + pHYs + gAMA |
| ListUp.png | 16 x 9 | 8 | RGBA | yes | 215 | tEXt + tIME + pHYs + gAMA |
| MessageBg.png | 800 x 110 | 8 | RGBA | yes | 893 | tEXt + tIME + pHYs + gAMA |
| MessageLine.png | 800 x 4 | 4 | Indexed / 3 col | no | 881 | tEXt + tIME + pHYs + gAMA + PLTE |
| Player_Chequered.png | 114 x 240 | 8 | Indexed / 25 col | no | 1,322 | tIME + pHYs + gAMA + PLTE |
| Player_DiagonalSplit.png | 114 x 240 | 8 | Indexed / 25 col | no | 1,291 | tIME + pHYs + gAMA + PLTE |
| Player_Hoop.png | 114 x 240 | 8 | Indexed / 25 col | no | 1,288 | tIME + pHYs + gAMA + PLTE |
| Player_Hoops.png | 114 x 240 | 8 | Indexed / 23 col | no | 1,292 | tIME + pHYs + gAMA + PLTE |
| Player_Plain.png | 114 x 240 | 8 | Indexed / 22 col | no | 1,257 | tIME + pHYs + gAMA + PLTE |
| Player_Segments.png | 114 x 240 | 8 | Indexed / 25 col | no | 1,296 | tIME + pHYs + gAMA + PLTE |
| Player_SleeveR.png | 114 x 240 | 8 | Indexed / 25 col | no | 1,284 | tIME + pHYs + gAMA + PLTE |
| Player_Sleeves.png | 114 x 240 | 8 | Indexed / 25 col | no | 1,294 | tIME + pHYs + gAMA + PLTE |
| Player_Split.png | 114 x 240 | 8 | Indexed / 25 col | no | 1,288 | tIME + pHYs + gAMA + PLTE |
| Player_StripeC.png | 114 x 240 | 8 | Indexed / 25 col | no | 1,294 | tIME + pHYs + gAMA + PLTE |
| Player_StripeLR.png | 114 x 240 | 8 | Indexed / 25 col | no | 1,314 | tIME + pHYs + gAMA + PLTE |
| Player_StripeR.png | 114 x 240 | 8 | Indexed / 25 col | no | 1,293 | tIME + pHYs + gAMA + PLTE |
| Player_Stripes.png | 114 x 240 | 8 | Indexed / 25 col | no | 1,332 | tIME + pHYs + gAMA + PLTE |
| Player_Trim.png | 114 x 240 | 8 | Indexed / 23 col | no | 1,272 | tIME + pHYs + gAMA + PLTE |
| Player_V.png | 114 x 240 | 8 | Indexed / 25 col | no | 1,301 | tIME + pHYs + gAMA + PLTE |
| Pointer.png | 32 x 16 | 8 | RGBA | yes | 292 | tEXt + tIME + pHYs + gAMA |
| sPlayer_Chequered.png | 40 x 84 | 8 | Indexed / 25 col | no | 969 | tIME + pHYs + gAMA + PLTE |
| sPlayer_DiagonalSplit.png | 40 x 84 | 8 | Indexed / 25 col | no | 935 | tIME + pHYs + gAMA + PLTE |
| sPlayer_Hoop.png | 40 x 84 | 8 | Indexed / 25 col | no | 934 | tIME + pHYs + gAMA + PLTE |
| sPlayer_Hoops.png | 40 x 84 | 8 | Indexed / 23 col | no | 925 | tIME + pHYs + gAMA + PLTE |
| sPlayer_Plain.png | 40 x 84 | 8 | Indexed / 22 col | no | 908 | tIME + pHYs + gAMA + PLTE |
| sPlayer_Segments.png | 40 x 84 | 8 | Indexed / 25 col | no | 935 | tIME + pHYs + gAMA + PLTE |
| sPlayer_SleeveR.png | 40 x 84 | 8 | Indexed / 25 col | no | 923 | tIME + pHYs + gAMA + PLTE |
| sPlayer_Sleeves.png | 40 x 84 | 8 | Indexed / 25 col | no | 931 | tIME + pHYs + gAMA + PLTE |
| sPlayer_Split.png | 40 x 84 | 8 | Indexed / 25 col | no | 933 | tIME + pHYs + gAMA + PLTE |
| sPlayer_StripeC.png | 40 x 84 | 8 | Indexed / 25 col | no | 936 | tIME + pHYs + gAMA + PLTE |
| sPlayer_StripeLR.png | 40 x 84 | 8 | Indexed / 25 col | no | 954 | tIME + pHYs + gAMA + PLTE |
| sPlayer_StripeR.png | 40 x 84 | 8 | Indexed / 25 col | no | 935 | tIME + pHYs + gAMA + PLTE |
| sPlayer_Stripes.png | 40 x 84 | 8 | Indexed / 25 col | no | 970 | tIME + pHYs + gAMA + PLTE |
| sPlayer_Trim.png | 40 x 84 | 8 | Indexed / 23 col | no | 921 | tIME + pHYs + gAMA + PLTE |
| sPlayer_V.png | 40 x 84 | 8 | Indexed / 25 col | no | 944 | tIME + pHYs + gAMA + PLTE |
| Star128.png | 128 x 128 | 8 | RGBA | yes | 7,166 | tIME + pHYs + gAMA |
| Star52.png | 60 x 60 | 8 | RGBA | yes | 2,777 | tIME + pHYs + gAMA |
| Star52Grey.png | 52 x 52 | 8 | RGBA | yes | 2,376 | tIME + pHYs + gAMA |
| StatsPitch.png | 362 x 482 | 8 | RGBA | yes | 170,758 | tEXt + tIME + pHYs + gAMA |
| TacticsPitch.png | 600 x 400 | 8 | RGBA | yes | 270,846 | tEXt + tIME + pHYs + gAMA |

#### `GameMedia/Images/Interface/Buttons`  (17 files)

| File | W x H | Bits | Colour type | Alpha | Bytes | Extra PNG chunks |
|------|-------|------|-------------|-------|-------|------------------|
| btn1.png | 32 x 32 | 8 | RGBA | yes | 1,825 | tEXt + tIME + pHYs + gAMA |
| btn10.png | 32 x 32 | 8 | RGBA | yes | 1,822 | tEXt + tIME + pHYs + gAMA |
| btn11.png | 32 x 32 | 8 | RGBA | yes | 1,709 | tEXt + tIME + pHYs + gAMA |
| btn12.png | 32 x 32 | 8 | RGBA | yes | 1,815 | tEXt + tIME + pHYs + gAMA |
| btn13.png | 32 x 32 | 8 | RGBA | yes | 1,818 | tEXt + tIME + pHYs + gAMA |
| btn14.png | 32 x 32 | 8 | RGBA | yes | 1,777 | tEXt + tIME + pHYs + gAMA |
| btn15.png | 32 x 32 | 8 | RGBA | yes | 1,805 | tEXt + tIME + pHYs + gAMA |
| btn16.png | 32 x 32 | 8 | RGBA | yes | 1,831 | tEXt + tIME + pHYs + gAMA |
| btn2.png | 32 x 32 | 8 | RGBA | yes | 1,988 | tEXt + tIME + pHYs + gAMA |
| btn3.png | 32 x 32 | 8 | RGBA | yes | 2,161 | tEXt + tIME + pHYs + gAMA |
| btn4.png | 32 x 32 | 8 | RGBA | yes | 2,099 | tEXt + tIME + pHYs + gAMA |
| btn5.png | 32 x 32 | 8 | RGBA | yes | 1,797 | tEXt + tIME + pHYs + gAMA |
| btn6.png | 32 x 32 | 8 | RGBA | yes | 1,826 | tEXt + tIME + pHYs + gAMA |
| btn7.png | 32 x 32 | 8 | RGBA | yes | 1,756 | tEXt + tIME + pHYs + gAMA |
| btn8.png | 32 x 32 | 8 | RGBA | yes | 1,823 | tEXt + tIME + pHYs + gAMA |
| btn9.png | 32 x 32 | 8 | RGBA | yes | 1,819 | tEXt + tIME + pHYs + gAMA |
| stick.png | 32 x 32 | 8 | RGBA | yes | 1,523 | tEXt + tIME + pHYs + gAMA |

#### `GameMedia/Images/Nations`  (212 files)

| File | W x H | Bits | Colour type | Alpha | Bytes | Extra PNG chunks |
|------|-------|------|-------------|-------|-------|------------------|
| NationIm_0.png | 60 x 40 | 8 | RGB | no | 2,888 | tEXt + tIME + pHYs + gAMA |
| NationIm_1.png | 60 x 40 | 8 | RGB | no | 959 | tEXt + tIME + pHYs + gAMA |
| NationIm_10.png | 60 x 40 | 8 | RGB | no | 271 | tEXt + tIME + pHYs + gAMA |
| NationIm_100.png | 60 x 40 | 8 | RGB | no | 1,435 | tEXt + tIME + pHYs + gAMA |
| NationIm_101.png | 60 x 40 | 8 | RGB | no | 1,203 | tEXt + tIME + pHYs + gAMA |
| NationIm_102.png | 60 x 40 | 8 | RGB | no | 2,247 | tEXt + tIME + pHYs + gAMA |
| NationIm_103.png | 60 x 40 | 8 | RGB | no | 697 | tEXt + tIME + pHYs + gAMA |
| NationIm_104.png | 60 x 40 | 8 | RGB | no | 1,306 | tEXt + tIME + pHYs + gAMA |
| NationIm_105.png | 60 x 40 | 8 | RGB | no | 819 | tEXt + tIME + pHYs + gAMA |
| NationIm_106.png | 60 x 40 | 8 | RGB | no | 279 | tEXt + tIME + pHYs + gAMA |
| NationIm_107.png | 60 x 40 | 8 | RGB | no | 1,271 | tEXt + tIME + pHYs + gAMA |
| NationIm_108.png | 60 x 40 | 8 | RGB | no | 924 | tEXt + tIME + pHYs + gAMA |
| NationIm_109.png | 60 x 40 | 8 | RGB | no | 844 | tEXt + tIME + pHYs + gAMA |
| NationIm_11.png | 60 x 40 | 8 | RGB | no | 717 | tEXt + tIME + pHYs + gAMA |
| NationIm_110.png | 60 x 40 | 8 | RGB | no | 233 | tEXt + tIME + pHYs + gAMA |
| NationIm_111.png | 60 x 40 | 8 | RGB | no | 778 | tEXt + tIME + pHYs + gAMA |
| NationIm_112.png | 60 x 40 | 8 | RGB | no | 290 | tEXt + tIME + pHYs + gAMA |
| NationIm_113.png | 60 x 40 | 8 | RGB | no | 280 | tEXt + tIME + pHYs + gAMA |
| NationIm_114.png | 60 x 40 | 8 | RGB | no | 1,451 | tEXt + tIME + pHYs + gAMA |
| NationIm_115.png | 60 x 40 | 8 | RGB | no | 277 | tIME + pHYs + gAMA |
| NationIm_116.png | 60 x 40 | 8 | RGB | no | 1,041 | tIME + pHYs + gAMA |
| NationIm_117.png | 60 x 40 | 8 | RGB | no | 1,374 | tIME + pHYs + gAMA |
| NationIm_118.png | 60 x 40 | 8 | RGB | no | 746 | tIME + pHYs + gAMA |
| NationIm_119.png | 60 x 40 | 8 | RGBA | yes | 252 | tIME + pHYs + gAMA |
| NationIm_12.png | 60 x 40 | 8 | RGB | no | 2,269 | tEXt + tIME + pHYs + gAMA |
| NationIm_120.png | 60 x 40 | 8 | RGB | no | 504 | tIME + pHYs + gAMA |
| NationIm_121.png | 60 x 40 | 8 | RGB | no | 1,004 | tIME + pHYs + gAMA |
| NationIm_122.png | 60 x 40 | 8 | RGBA | yes | 297 | tIME + pHYs + gAMA |
| NationIm_123.png | 60 x 40 | 8 | RGB | no | 1,044 | tIME + pHYs + gAMA |
| NationIm_124.png | 60 x 40 | 8 | RGB | no | 653 | tIME + pHYs + gAMA |
| NationIm_125.png | 60 x 40 | 8 | RGBA | yes | 1,121 | tIME + pHYs + gAMA |
| NationIm_126.png | 60 x 40 | 8 | RGB | no | 1,677 | tEXt + tIME + pHYs + gAMA |
| NationIm_127.png | 60 x 40 | 8 | RGB | no | 2,511 | tIME + pHYs + gAMA |
| NationIm_128.png | 60 x 40 | 8 | RGB | no | 638 | tIME + pHYs + gAMA |
| NationIm_129.png | 60 x 40 | 8 | RGB | no | 1,493 | tIME + pHYs + gAMA |
| NationIm_13.png | 60 x 40 | 8 | RGB | no | 280 | tEXt + tIME + pHYs + gAMA |
| NationIm_130.png | 60 x 40 | 8 | RGBA | yes | 1,298 | tIME + pHYs + gAMA |
| NationIm_131.png | 60 x 40 | 8 | RGB | no | 2,535 | tIME + pHYs + gAMA |
| NationIm_132.png | 60 x 40 | 8 | RGBA | yes | 2,269 | tIME + pHYs + gAMA |
| NationIm_133.png | 60 x 40 | 8 | RGB | no | 224 | tIME + pHYs + gAMA |
| NationIm_134.png | 60 x 40 | 8 | RGB | no | 578 | tIME + pHYs + gAMA |
| NationIm_135.png | 60 x 40 | 8 | RGB | no | 277 | tEXt + tIME + pHYs + gAMA |
| NationIm_136.png | 60 x 40 | 8 | RGBA | yes | 2,285 | tIME + pHYs + gAMA |
| NationIm_137.png | 60 x 40 | 8 | RGBA | yes | 989 | tIME + pHYs + gAMA |
| NationIm_138.png | 60 x 40 | 8 | RGB | no | 713 | tIME + pHYs + gAMA |
| NationIm_139.png | 60 x 40 | 8 | RGB | no | 224 | tIME + pHYs + gAMA |
| NationIm_14.png | 60 x 40 | 8 | RGB | no | 923 | tEXt + tIME + pHYs + gAMA |
| NationIm_140.png | 60 x 40 | 8 | RGB | no | 951 | tIME + pHYs + gAMA |
| NationIm_141.png | 60 x 40 | 8 | RGB | no | 688 | tIME + pHYs + gAMA |
| NationIm_142.png | 60 x 40 | 8 | RGBA | yes | 876 | tIME + pHYs + gAMA |
| NationIm_143.png | 60 x 40 | 8 | RGB | no | 1,065 | tIME + pHYs + gAMA |
| NationIm_144.png | 60 x 40 | 8 | RGB | no | 1,106 | tIME + pHYs + gAMA |
| NationIm_145.png | 60 x 40 | 8 | RGB | no | 818 | tIME + pHYs + gAMA |
| NationIm_146.png | 60 x 40 | 8 | RGB | no | 2,081 | tIME + pHYs + gAMA |
| NationIm_147.png | 60 x 40 | 8 | RGBA | yes | 811 | tIME + pHYs + gAMA |
| NationIm_148.png | 60 x 40 | 8 | RGB | no | 1,234 | tIME + pHYs + gAMA |
| NationIm_149.png | 60 x 40 | 8 | RGBA | yes | 1,536 | tIME + pHYs + gAMA |
| NationIm_15.png | 60 x 40 | 8 | RGB | no | 950 | tEXt + tIME + pHYs + gAMA |
| NationIm_150.png | 60 x 40 | 8 | RGB | no | 205 | tIME + pHYs + gAMA |
| NationIm_151.png | 60 x 40 | 8 | RGB | no | 1,276 | tEXt + tIME + pHYs + gAMA |
| NationIm_152.png | 60 x 40 | 8 | RGB | no | 1,448 | tIME + pHYs + gAMA |
| NationIm_153.png | 60 x 40 | 8 | RGB | no | 911 | tIME + pHYs + gAMA |
| NationIm_154.png | 60 x 40 | 8 | RGB | no | 276 | tEXt + tIME + pHYs + gAMA |
| NationIm_155.png | 60 x 40 | 8 | RGBA | yes | 254 | tIME + pHYs + gAMA |
| NationIm_156.png | 60 x 40 | 8 | RGB | no | 212 | tIME + pHYs + gAMA |
| NationIm_157.png | 60 x 40 | 8 | RGBA | yes | 1,021 | tIME + pHYs + gAMA |
| NationIm_158.png | 60 x 40 | 8 | RGB | no | 2,414 | tIME + pHYs + gAMA |
| NationIm_159.png | 60 x 40 | 8 | RGB | no | 1,091 | tIME + pHYs + gAMA |
| NationIm_16.png | 60 x 40 | 8 | RGB | no | 524 | tEXt + tIME + pHYs + gAMA |
| NationIm_160.png | 60 x 40 | 8 | RGBA | yes | 1,134 | tIME + pHYs + gAMA |
| NationIm_161.png | 60 x 40 | 8 | RGBA | yes | 871 | tIME + pHYs + gAMA |
| NationIm_162.png | 60 x 40 | 8 | RGB | no | 1,351 | tIME + pHYs + gAMA |
| NationIm_163.png | 60 x 40 | 8 | RGB | no | 1,469 | tIME + pHYs + gAMA |
| NationIm_164.png | 60 x 40 | 8 | RGB | no | 1,207 | tIME + pHYs + gAMA |
| NationIm_165.png | 60 x 40 | 8 | RGBA | yes | 680 | tIME + pHYs + gAMA |
| NationIm_166.png | 60 x 40 | 8 | RGB | no | 1,411 | tEXt + tIME + pHYs + gAMA |
| NationIm_167.png | 60 x 40 | 8 | RGB | no | 1,554 | tIME + pHYs + gAMA |
| NationIm_168.png | 60 x 40 | 8 | RGBA | yes | 239 | tIME + pHYs + gAMA |
| NationIm_169.png | 60 x 40 | 8 | RGB | no | 854 | tIME + pHYs + gAMA |
| NationIm_17.png | 60 x 40 | 8 | RGB | no | 1,083 | tEXt + tIME + pHYs + gAMA |
| NationIm_170.png | 60 x 40 | 8 | RGB | no | 1,249 | tIME + pHYs + gAMA |
| NationIm_171.png | 60 x 40 | 8 | RGB | no | 800 | tIME + pHYs + gAMA |
| NationIm_172.png | 60 x 40 | 8 | RGBA | yes | 1,715 | tIME + pHYs + gAMA |
| NationIm_173.png | 60 x 40 | 8 | RGB | no | 631 | tIME + pHYs + gAMA |
| NationIm_174.png | 60 x 40 | 8 | RGB | no | 1,745 | tIME + pHYs + gAMA |
| NationIm_175.png | 60 x 40 | 8 | RGB | no | 921 | tEXt + tIME + pHYs + gAMA |
| NationIm_176.png | 60 x 40 | 8 | RGBA | yes | 2,067 | tIME + pHYs + gAMA |
| NationIm_177.png | 60 x 40 | 8 | RGB | no | 951 | tIME + pHYs + gAMA |
| NationIm_178.png | 60 x 40 | 8 | RGBA | yes | 885 | tIME + pHYs + gAMA |
| NationIm_179.png | 60 x 40 | 8 | RGB | no | 2,174 | tIME + pHYs + gAMA |
| NationIm_18.png | 60 x 40 | 8 | RGB | no | 975 | tEXt + tIME + pHYs + gAMA |
| NationIm_180.png | 60 x 40 | 8 | RGB | no | 468 | tIME + pHYs + gAMA |
| NationIm_181.png | 60 x 40 | 8 | RGBA | yes | 675 | tIME + pHYs + gAMA |
| NationIm_182.png | 60 x 40 | 8 | RGB | no | 583 | tIME + pHYs + gAMA |
| NationIm_183.png | 60 x 40 | 8 | RGB | no | 1,248 | tIME + pHYs + gAMA |
| NationIm_184.png | 60 x 40 | 8 | RGB | no | 1,192 | tIME + pHYs + gAMA |
| NationIm_185.png | 60 x 40 | 8 | RGB | no | 888 | tIME + pHYs + gAMA |
| NationIm_186.png | 60 x 40 | 8 | RGB | no | 1,964 | tIME + pHYs + gAMA |
| NationIm_187.png | 60 x 40 | 8 | RGB | no | 251 | tIME + pHYs + gAMA |
| NationIm_188.png | 60 x 40 | 8 | RGB | no | 1,825 | tEXt + tIME + pHYs + gAMA |
| NationIm_189.png | 60 x 40 | 8 | RGB | no | 891 | tIME + pHYs + gAMA |
| NationIm_19.png | 60 x 39 | 8 | RGB | no | 1,238 | tEXt + tIME + pHYs + gAMA |
| NationIm_190.png | 60 x 40 | 8 | RGB | no | 624 | tIME + pHYs + gAMA |
| NationIm_191.png | 60 x 40 | 8 | RGB | no | 1,929 | tIME + pHYs + gAMA |
| NationIm_192.png | 60 x 40 | 8 | RGB | no | 1,065 | tIME + pHYs + gAMA |
| NationIm_193.png | 60 x 40 | 8 | RGB | no | 861 | tIME + pHYs + gAMA |
| NationIm_194.png | 60 x 40 | 8 | RGB | no | 1,706 | tIME + pHYs + gAMA |
| NationIm_195.png | 60 x 40 | 8 | RGBA | yes | 2,360 | tIME + pHYs + gAMA |
| NationIm_196.png | 60 x 40 | 8 | RGB | no | 3,646 | tIME + pHYs + gAMA |
| NationIm_197.png | 60 x 40 | 8 | RGB | no | 1,035 | tEXt + tIME + pHYs + gAMA |
| NationIm_198.png | 60 x 40 | 8 | RGB | no | 216 | tIME + pHYs + gAMA |
| NationIm_199.png | 60 x 40 | 8 | RGB | no | 371 | tIME + pHYs + gAMA |
| NationIm_2.png | 60 x 40 | 8 | RGB | no | 1,434 | tEXt + tIME + pHYs + gAMA |
| NationIm_20.png | 60 x 40 | 8 | RGB | no | 267 | tEXt + tIME + pHYs + gAMA |
| NationIm_200.png | 60 x 40 | 8 | RGB | no | 1,530 | tIME + pHYs + gAMA |
| NationIm_201.png | 60 x 40 | 8 | RGB | no | 1,131 | tIME + pHYs + gAMA |
| NationIm_202.png | 60 x 40 | 8 | RGB | no | 833 | tIME + pHYs + gAMA |
| NationIm_203.png | 60 x 40 | 8 | RGBA | yes | 2,295 | tIME + pHYs + gAMA |
| NationIm_204.png | 60 x 40 | 8 | RGB | no | 868 | tIME + pHYs + gAMA |
| NationIm_205.png | 60 x 40 | 8 | RGB | no | 988 | tIME + pHYs + gAMA |
| NationIm_206.png | 60 x 40 | 8 | RGB | no | 3,143 | tIME + pHYs + gAMA |
| NationIm_207.png | 60 x 40 | 8 | RGB | no | 211 | tIME + pHYs + gAMA |
| NationIm_208.png | 60 x 40 | 8 | RGB | no | 800 | tIME + pHYs + gAMA |
| NationIm_209.png | 60 x 40 | 8 | RGB | no | 1,798 | tEXt + tIME + pHYs + gAMA |
| NationIm_21.png | 60 x 40 | 8 | RGB | no | 2,959 | tEXt + tIME + pHYs + gAMA |
| NationIm_22.png | 60 x 40 | 8 | RGB | no | 372 | tEXt + tIME + pHYs + gAMA |
| NationIm_23.png | 60 x 40 | 8 | RGB | no | 2,826 | tEXt + tIME + pHYs + gAMA |
| NationIm_24.png | 60 x 40 | 8 | RGB | no | 2,301 | tEXt + tIME + pHYs + gAMA |
| NationIm_25.png | 60 x 40 | 8 | RGB | no | 711 | tEXt + tIME + pHYs + gAMA |
| NationIm_26.png | 60 x 40 | 8 | RGB | no | 1,669 | tEXt + tIME + pHYs + gAMA |
| NationIm_27.png | 60 x 40 | 8 | RGB | no | 291 | tEXt + tIME + pHYs + gAMA |
| NationIm_28.png | 60 x 40 | 8 | RGB | no | 1,838 | tEXt + tIME + pHYs + gAMA |
| NationIm_29.png | 60 x 40 | 8 | RGB | no | 2,906 | tEXt + tIME + pHYs + gAMA |
| NationIm_3.png | 60 x 40 | 8 | RGB | no | 1,272 | tEXt + tIME + pHYs + gAMA |
| NationIm_30.png | 60 x 40 | 8 | RGB | no | 2,397 | tEXt + tIME + pHYs + gAMA |
| NationIm_31.png | 60 x 40 | 8 | RGB | no | 275 | tEXt + tIME + pHYs + gAMA |
| NationIm_32.png | 60 x 40 | 8 | RGB | no | 645 | tEXt + tIME + pHYs + gAMA |
| NationIm_33.png | 60 x 40 | 8 | RGB | no | 1,989 | tEXt + tIME + pHYs + gAMA |
| NationIm_34.png | 60 x 40 | 8 | RGB | no | 1,516 | tEXt + tIME + pHYs + gAMA |
| NationIm_35.png | 60 x 40 | 8 | RGB | no | 533 | tEXt + tIME + pHYs + gAMA |
| NationIm_36.png | 60 x 40 | 8 | RGB | no | 733 | tEXt + tIME + pHYs + gAMA |
| NationIm_37.png | 60 x 40 | 8 | RGB | no | 1,011 | tEXt + tIME + pHYs + gAMA |
| NationIm_38.png | 60 x 40 | 8 | RGB | no | 2,522 | tEXt + tIME + pHYs + gAMA |
| NationIm_39.png | 60 x 40 | 8 | RGB | no | 955 | tEXt + tIME + pHYs + gAMA |
| NationIm_4.png | 60 x 40 | 8 | RGB | no | 2,072 | tEXt + tIME + pHYs + gAMA |
| NationIm_40.png | 60 x 40 | 8 | RGB | no | 329 | tEXt + tIME + pHYs + gAMA |
| NationIm_41.png | 60 x 40 | 8 | RGB | no | 622 | tEXt + tIME + pHYs + gAMA |
| NationIm_42.png | 60 x 40 | 8 | RGB | no | 604 | tEXt + tIME + pHYs + gAMA |
| NationIm_43.png | 60 x 40 | 8 | RGB | no | 893 | tEXt + tIME + pHYs + gAMA |
| NationIm_44.png | 60 x 40 | 8 | RGB | no | 294 | tEXt + tIME + pHYs + gAMA |
| NationIm_45.png | 60 x 40 | 8 | RGB | no | 1,745 | tEXt + tIME + pHYs + gAMA |
| NationIm_46.png | 60 x 40 | 8 | RGB | no | 1,142 | tEXt + tIME + pHYs + gAMA |
| NationIm_47.png | 60 x 40 | 8 | RGB | no | 1,603 | tEXt + tIME + pHYs + gAMA |
| NationIm_48.png | 60 x 40 | 8 | RGB | no | 2,687 | tEXt + tIME + pHYs + gAMA |
| NationIm_49.png | 60 x 40 | 8 | RGB | no | 905 | tEXt + tIME + pHYs + gAMA |
| NationIm_5.png | 60 x 40 | 8 | RGB | no | 1,299 | tEXt + tIME + pHYs + gAMA |
| NationIm_50.png | 60 x 40 | 8 | RGB | no | 1,644 | tEXt + tIME + pHYs + gAMA |
| NationIm_51.png | 60 x 40 | 8 | RGB | no | 1,394 | tEXt + tIME + pHYs + gAMA |
| NationIm_52.png | 60 x 40 | 8 | RGB | no | 1,329 | tEXt + tIME + pHYs + gAMA |
| NationIm_53.png | 60 x 40 | 8 | RGB | no | 935 | tEXt + tIME + pHYs + gAMA |
| NationIm_54.png | 60 x 40 | 8 | RGB | no | 275 | tEXt + tIME + pHYs + gAMA |
| NationIm_55.png | 60 x 40 | 8 | RGB | no | 461 | tEXt + tIME + pHYs + gAMA |
| NationIm_56.png | 60 x 40 | 8 | RGB | no | 1,100 | tEXt + tIME + pHYs + gAMA |
| NationIm_56b.png | 60 x 40 | 8 | RGB | no | 1,658 | tEXt + tIME + pHYs + gAMA |
| NationIm_57.png | 60 x 40 | 8 | RGB | no | 1,658 | tEXt + tIME + pHYs + gAMA |
| NationIm_58.png | 60 x 40 | 8 | RGB | no | 993 | tEXt + tIME + pHYs + gAMA |
| NationIm_59.png | 60 x 40 | 8 | RGB | no | 1,495 | tEXt + tIME + pHYs + gAMA |
| NationIm_6.png | 60 x 40 | 8 | RGB | no | 1,378 | tEXt + tIME + pHYs + gAMA |
| NationIm_60.png | 60 x 40 | 8 | RGB | no | 623 | tEXt + tIME + pHYs + gAMA |
| NationIm_61.png | 60 x 40 | 8 | RGB | no | 870 | tEXt + tIME + pHYs + gAMA |
| NationIm_62.png | 60 x 40 | 8 | RGB | no | 490 | tEXt + tIME + pHYs + gAMA |
| NationIm_63.png | 60 x 40 | 8 | RGB | no | 1,398 | tEXt + tIME + pHYs + gAMA |
| NationIm_64.png | 60 x 40 | 8 | RGB | no | 2,011 | tEXt + tIME + pHYs + gAMA |
| NationIm_65.png | 60 x 40 | 8 | RGB | no | 264 | tEXt + tIME + pHYs + gAMA |
| NationIm_66.png | 60 x 40 | 8 | RGB | no | 1,443 | tEXt + tIME + pHYs + gAMA |
| NationIm_67.png | 60 x 40 | 8 | RGB | no | 2,322 | tIME + pHYs + gAMA |
| NationIm_68.png | 60 x 40 | 8 | RGB | no | 799 | tEXt + tIME + pHYs + gAMA |
| NationIm_69.png | 60 x 40 | 8 | RGB | no | 2,296 | tEXt + tIME + pHYs + gAMA |
| NationIm_7.png | 60 x 40 | 8 | RGB | no | 2,255 | tEXt + tIME + pHYs + gAMA |
| NationIm_70.png | 60 x 40 | 8 | RGB | no | 478 | tEXt + tIME + pHYs + gAMA |
| NationIm_71.png | 60 x 40 | 8 | RGB | no | 277 | tEXt + tIME + pHYs + gAMA |
| NationIm_72.png | 60 x 40 | 8 | RGB | no | 286 | tEXt + tIME + pHYs + gAMA |
| NationIm_73.png | 60 x 40 | 8 | RGB | no | 303 | tEXt + tIME + pHYs + gAMA |
| NationIm_74.png | 60 x 40 | 8 | RGB | no | 928 | tEXt + tIME + pHYs + gAMA |
| NationIm_75.png | 60 x 40 | 8 | RGB | no | 257 | tEXt + tIME + pHYs + gAMA |
| NationIm_76.png | 60 x 40 | 8 | RGB | no | 783 | tEXt + tIME + pHYs + gAMA |
| NationIm_77.png | 60 x 40 | 8 | RGB | no | 682 | tEXt + tIME + pHYs + gAMA |
| NationIm_78.png | 60 x 40 | 8 | RGB | no | 2,138 | tEXt + tIME + pHYs + gAMA |
| NationIm_79.png | 60 x 40 | 8 | RGB | no | 277 | tEXt + tIME + pHYs + gAMA |
| NationIm_8.png | 60 x 40 | 8 | RGB | no | 1,835 | tEXt + tIME + pHYs + gAMA |
| NationIm_80.png | 60 x 40 | 8 | RGB | no | 1,164 | tEXt + tIME + pHYs + gAMA |
| NationIm_81.png | 60 x 40 | 8 | RGB | no | 876 | tEXt + tIME + pHYs + gAMA |
| NationIm_82.png | 60 x 40 | 8 | RGB | no | 278 | tEXt + tIME + pHYs + gAMA |
| NationIm_83.png | 60 x 40 | 8 | RGB | no | 744 | tEXt + tIME + pHYs + gAMA |
| NationIm_84.png | 60 x 40 | 8 | RGB | no | 2,113 | tEXt + tIME + pHYs + gAMA |
| NationIm_85.png | 60 x 40 | 8 | RGB | no | 879 | tEXt + tIME + pHYs + gAMA |
| NationIm_86.png | 60 x 40 | 8 | RGB | no | 839 | tEXt + tIME + pHYs + gAMA |
| NationIm_87.png | 60 x 40 | 8 | RGB | no | 1,092 | tEXt + tIME + pHYs + gAMA |
| NationIm_88.png | 60 x 40 | 8 | RGB | no | 279 | tEXt + tIME + pHYs + gAMA |
| NationIm_89.png | 60 x 40 | 8 | RGB | no | 804 | tEXt + tIME + pHYs + gAMA |
| NationIm_9.png | 60 x 40 | 8 | RGB | no | 783 | tEXt + tIME + pHYs + gAMA |
| NationIm_90.png | 60 x 40 | 8 | RGB | no | 998 | tEXt + tIME + pHYs + gAMA |
| NationIm_91.png | 60 x 40 | 8 | RGB | no | 269 | tEXt + tIME + pHYs + gAMA |
| NationIm_92.png | 60 x 40 | 8 | RGB | no | 1,673 | tEXt + tIME + pHYs + gAMA |
| NationIm_93.png | 60 x 40 | 8 | RGB | no | 959 | tEXt + tIME + pHYs + gAMA |
| NationIm_94.png | 60 x 40 | 8 | RGB | no | 1,057 | tEXt + tIME + pHYs + gAMA |
| NationIm_95.png | 60 x 40 | 8 | RGB | no | 279 | tEXt + tIME + pHYs + gAMA |
| NationIm_96.png | 60 x 40 | 8 | RGB | no | 1,626 | tEXt + tIME + pHYs + gAMA |
| NationIm_97.png | 60 x 40 | 8 | RGB | no | 773 | tEXt + tIME + pHYs + gAMA |
| NationIm_98.png | 60 x 40 | 8 | RGB | no | 1,094 | tEXt + tIME + pHYs + gAMA |
| NationIm_99.png | 60 x 40 | 8 | RGB | no | 1,772 | tEXt + tIME + pHYs + gAMA |
| NationIm_x209.png | 60 x 40 | 8 | RGB | no | 1,745 | tEXt + tIME + pHYs + gAMA |

#### `GameMedia/Images/Relationships`  (10 files)

| File | W x H | Bits | Colour type | Alpha | Bytes | Extra PNG chunks |
|------|-------|------|-------------|-------|-------|------------------|
| boss.png | 400 x 440 | 8 | RGB | no | 83,567 | tEXt |
| bowling.png | 400 x 440 | 8 | RGB | no | 154,366 | tEXt |
| cinema.png | 400 x 440 | 8 | RGB | no | 204,206 | gAMA + tEXt |
| fans.png | 400 x 440 | 8 | RGB | no | 135,489 | tEXt |
| golf_course.png | 400 x 440 | 8 | RGB | no | 174,005 | gAMA + tEXt |
| pub.png | 400 x 440 | 8 | RGB | no | 189,567 | tEXt |
| restaurant.png | 400 x 440 | 8 | RGB | no | 223,792 | tEXt |
| shopping.png | 400 x 440 | 8 | RGB | no | 167,928 | gAMA + tEXt |
| sponsors.png | 400 x 440 | 8 | RGB | no | 79,671 | tEXt |
| training_ground.png | 400 x 440 | 8 | RGB | no | 268,765 | gAMA + tEXt |

#### `GameMedia/Images/Shop/Boots`  (10 files)

| File | W x H | Bits | Colour type | Alpha | Bytes | Extra PNG chunks |
|------|-------|------|-------------|-------|-------|------------------|
| Boots_1.png | 60 x 44 | 8 | RGBA | yes | 4,291 | tIME + pHYs + gAMA |
| Boots_10.png | 60 x 44 | 8 | RGBA | yes | 4,840 | tIME + pHYs + gAMA |
| Boots_2.png | 60 x 44 | 8 | RGBA | yes | 4,596 | tIME + pHYs + gAMA |
| Boots_3.png | 60 x 44 | 8 | RGBA | yes | 5,689 | tIME + pHYs + gAMA |
| Boots_4.png | 60 x 44 | 8 | RGBA | yes | 4,947 | tIME + pHYs + gAMA |
| Boots_5.png | 60 x 44 | 8 | RGBA | yes | 4,927 | tIME + pHYs + gAMA |
| Boots_6.png | 60 x 44 | 8 | RGBA | yes | 4,040 | tIME + pHYs + gAMA |
| Boots_7.png | 60 x 44 | 8 | RGBA | yes | 4,648 | tIME + pHYs + gAMA |
| Boots_8.png | 60 x 44 | 8 | RGBA | yes | 4,072 | tIME + pHYs + gAMA |
| Boots_9.png | 60 x 44 | 8 | RGBA | yes | 4,730 | tIME + pHYs + gAMA |

#### `GameMedia/Images/Shop/Items`  (10 files)

| File | W x H | Bits | Colour type | Alpha | Bytes | Extra PNG chunks |
|------|-------|------|-------------|-------|-------|------------------|
| Items_1.png | 143 x 91 | 8 | RGB | no | 16,831 | tIME + pHYs + gAMA |
| Items_10.png | 143 x 91 | 8 | RGB | no | 17,757 | tIME + pHYs + gAMA |
| Items_2.png | 143 x 91 | 8 | RGB | no | 14,231 | tIME + pHYs + gAMA |
| Items_3.png | 143 x 91 | 8 | RGB | no | 18,412 | tIME + pHYs + gAMA |
| Items_4.png | 143 x 91 | 8 | RGB | no | 11,130 | tEXt + tIME + pHYs + gAMA |
| Items_5.png | 143 x 91 | 8 | RGB | no | 9,339 | tIME + pHYs + gAMA |
| Items_6.png | 143 x 91 | 8 | RGB | no | 14,549 | tIME + pHYs + gAMA |
| Items_7.png | 143 x 91 | 8 | RGB | no | 17,469 | tIME + pHYs + gAMA |
| Items_8.png | 143 x 91 | 8 | RGB | no | 16,381 | tIME + pHYs + gAMA |
| Items_9.png | 143 x 91 | 8 | RGB | no | 17,939 | tIME + pHYs + gAMA |

#### `GameMedia/Images/Shop/Property`  (10 files)

| File | W x H | Bits | Colour type | Alpha | Bytes | Extra PNG chunks |
|------|-------|------|-------------|-------|-------|------------------|
| Property_1.png | 143 x 90 | 8 | RGB | no | 21,421 | tIME + pHYs + gAMA |
| Property_10.png | 143 x 90 | 8 | RGB | no | 18,104 | tIME + pHYs + gAMA |
| Property_2.png | 143 x 90 | 8 | RGB | no | 22,837 | tIME + pHYs + gAMA |
| Property_3.png | 143 x 90 | 8 | RGBA | yes | 26,292 | tIME + pHYs + gAMA |
| Property_4.png | 143 x 90 | 8 | RGB | no | 23,944 | tIME + pHYs + gAMA |
| Property_5.png | 143 x 90 | 8 | RGB | no | 19,962 | tIME + pHYs + gAMA |
| Property_6.png | 143 x 90 | 8 | RGB | no | 20,173 | tIME + pHYs + gAMA |
| Property_7.png | 143 x 90 | 8 | RGB | no | 15,562 | tIME + pHYs + gAMA |
| Property_8.png | 143 x 90 | 8 | RGB | no | 20,979 | tIME + pHYs + gAMA |
| Property_9.png | 143 x 90 | 8 | RGB | no | 23,247 | tIME + pHYs + gAMA |

#### `GameMedia/Images/Shop/Vehicles`  (10 files)

| File | W x H | Bits | Colour type | Alpha | Bytes | Extra PNG chunks |
|------|-------|------|-------------|-------|-------|------------------|
| Vehicles_1.png | 143 x 90 | 8 | RGB | no | 15,039 | tIME + pHYs + gAMA |
| Vehicles_10.png | 143 x 90 | 8 | RGB | no | 14,872 | tIME + pHYs + gAMA |
| Vehicles_2.png | 143 x 90 | 8 | RGB | no | 14,504 | tIME + pHYs + gAMA |
| Vehicles_3.png | 143 x 90 | 8 | RGB | no | 16,216 | tIME + pHYs + gAMA |
| Vehicles_4.png | 143 x 90 | 8 | RGB | no | 16,978 | tIME + pHYs + gAMA |
| Vehicles_5.png | 143 x 90 | 8 | RGB | no | 15,720 | tIME + pHYs + gAMA |
| Vehicles_6.png | 143 x 90 | 8 | RGB | no | 13,151 | tIME + pHYs + gAMA |
| Vehicles_7.png | 143 x 90 | 8 | RGB | no | 15,448 | tIME + pHYs + gAMA |
| Vehicles_8.png | 143 x 90 | 8 | RGB | no | 19,283 | tIME + pHYs + gAMA |
| Vehicles_9.png | 143 x 90 | 8 | RGB | no | 16,765 | tIME + pHYs + gAMA |

#### `GameMedia/Images/Stable`  (13 files)

| File | W x H | Bits | Colour type | Alpha | Bytes | Extra PNG chunks |
|------|-------|------|-------------|-------|-------|------------------|
| ArrowD.png | 28 x 41 | 8 | RGBA | yes | 938 | tEXt + tIME + pHYs + gAMA |
| Bg.png | 200 x 275 | 8 | RGB | no | 23,870 | tIME + pHYs + gAMA |
| FinishLine.png | 17 x 235 | 8 | RGB | no | 7,615 | tEXt + tIME + pHYs + gAMA |
| FinishPost.png | 52 x 197 | 8 | RGBA | yes | 1,581 | tIME + pHYs + gAMA |
| Grass.png | 64 x 64 | 8 | RGB | no | 6,245 | tIME + pHYs + gAMA |
| Post_1.png | 27 x 64 | 8 | RGBA | yes | 860 | tEXt + tIME + pHYs + gAMA |
| Post_2.png | 27 x 64 | 8 | RGBA | yes | 987 | tEXt + tIME + pHYs + gAMA |
| Post_3.png | 27 x 64 | 8 | RGBA | yes | 1,020 | tEXt + tIME + pHYs + gAMA |
| Post_4.png | 27 x 64 | 8 | RGBA | yes | 937 | tEXt + tIME + pHYs + gAMA |
| Post_5.png | 27 x 64 | 8 | RGBA | yes | 1,032 | tEXt + tIME + pHYs + gAMA |
| Post_6.png | 27 x 64 | 8 | RGBA | yes | 1,020 | tEXt + tIME + pHYs + gAMA |
| Railing_01.png | 108 x 64 | 8 | RGB | no | 1,647 | tEXt + tIME + pHYs + gAMA |
| Star.png | 29 x 28 | 8 | RGBA | yes | 1,249 | tIME + pHYs + gAMA |

#### `GameMedia/Images/Stable/Horse`  (5 files)

| File | W x H | Bits | Colour type | Alpha | Bytes | Extra PNG chunks |
|------|-------|------|-------------|-------|-------|------------------|
| Horse_01.png | 1024 x 80 | 8 | Indexed / 33 col | no | 9,378 | tEXt + tIME + pHYs + gAMA + PLTE |
| Horse_02.png | 1024 x 80 | 8 | Indexed / 39 col | no | 9,917 | tEXt + tIME + pHYs + gAMA + PLTE |
| Horse_03.png | 1024 x 80 | 8 | Indexed / 34 col | no | 9,021 | tEXt + tIME + pHYs + gAMA + PLTE |
| Horse_04.png | 1024 x 80 | 8 | Indexed / 38 col | no | 10,530 | tEXt + tIME + pHYs + gAMA + PLTE |
| Shadow.png | 1024 x 100 | 8 | RGBA | yes | 8,257 | tEXt + tIME + pHYs + gAMA |

#### `GameMedia/Images/Stable/Jockey`  (6 files)

| File | W x H | Bits | Colour type | Alpha | Bytes | Extra PNG chunks |
|------|-------|------|-------------|-------|-------|------------------|
| Jockey_01.png | 1024 x 80 | 4 | Indexed / 16 col | no | 1,233 | tEXt + tIME + pHYs + gAMA + PLTE |
| Jockey_02.png | 1024 x 80 | 4 | Indexed / 16 col | no | 1,233 | tEXt + tIME + pHYs + gAMA + PLTE |
| Jockey_03.png | 1024 x 80 | 4 | Indexed / 16 col | no | 1,233 | tEXt + tIME + pHYs + gAMA + PLTE |
| Jockey_04.png | 1024 x 80 | 4 | Indexed / 16 col | no | 1,233 | tEXt + tIME + pHYs + gAMA + PLTE |
| Jockey_05.png | 1024 x 80 | 4 | Indexed / 16 col | no | 1,233 | tEXt + tIME + pHYs + gAMA + PLTE |
| Jockey_06.png | 1024 x 80 | 4 | Indexed / 16 col | no | 1,233 | tEXt + tIME + pHYs + gAMA + PLTE |

#### `EngineMedia/Match/Ball`  (4 files)

| File | W x H | Bits | Colour type | Alpha | Bytes | Extra PNG chunks |
|------|-------|------|-------------|-------|-------|------------------|
| Ball.png | 120 x 40 | 4 | Indexed / 16 col | no | 1,984 | tIME + pHYs + gAMA + PLTE |
| Marker.png | 9 x 7 | 4 | Indexed / 3 col | no | 224 | tEXt + tIME + pHYs + gAMA + PLTE |
| Shadow.png | 20 x 10 | 8 | RGBA | yes | 248 | tEXt + tIME + pHYs + gAMA |
| TenYards.png | 400 x 400 | 8 | RGBA | yes | 13,366 | tEXt + tIME + pHYs + gAMA |

#### `EngineMedia/Match/Other`  (25 files)

| File | W x H | Bits | Colour type | Alpha | Bytes | Extra PNG chunks |
|------|-------|------|-------------|-------|-------|------------------|
| BallIcon.png | 36 x 36 | 8 | RGBA | yes | 2,654 | tEXt + tIME + pHYs + gAMA |
| Booze.png | 28 x 26 | 8 | RGBA | yes | 2,144 | tIME + pHYs + gAMA |
| BoozeFace.png | 26 x 26 | 8 | RGBA | yes | 1,060 | tEXt + tIME + pHYs + gAMA |
| Energy.png | 60 x 12 | 8 | RGB | no | 193 | tEXt + tIME + pHYs + gAMA |
| EnergyBack.png | 64 x 16 | 8 | RGBA | yes | 713 | tEXt + tIME + pHYs + gAMA |
| EnergyBackRed.png | 64 x 16 | 8 | RGBA | yes | 744 | tEXt + tIME + pHYs + gAMA |
| GoalIcon.png | 62 x 38 | 8 | RGBA | yes | 6,453 | tIME + pHYs + gAMA |
| Injury.png | 32 x 32 | 8 | RGBA | yes | 348 | tEXt + tIME + pHYs + gAMA |
| RadarPlayer.png | 16 x 8 | 8 | RGBA | yes | 423 | tIME + pHYs + gAMA |
| RedCard.png | 43 x 68 | 8 | RGBA | yes | 4,043 | tIME + pHYs + gAMA |
| SadFace.png | 26 x 26 | 8 | RGBA | yes | 1,065 | tEXt + tIME + pHYs + gAMA |
| SecondYellowCard.png | 49 x 75 | 8 | RGBA | yes | 4,741 | tIME + pHYs + gAMA |
| SickFace.png | 26 x 26 | 8 | RGBA | yes | 1,135 | tEXt + tIME + pHYs + gAMA |
| Speech.png | 256 x 128 | 8 | RGBA | yes | 6,979 | tEXt + tIME + pHYs + gAMA |
| Star.png | 52 x 52 | 8 | RGBA | yes | 2,147 | tIME + pHYs + gAMA |
| StopWatch.png | 35 x 42 | 8 | RGBA | yes | 3,222 | tEXt + tIME + pHYs + gAMA |
| SubOff.png | 39 x 28 | 8 | RGBA | yes | 1,060 | tIME + pHYs + gAMA |
| SubOnDown.png | 28 x 39 | 8 | RGBA | yes | 1,219 | tIME + pHYs + gAMA |
| SubOnUp.png | 28 x 39 | 8 | RGBA | yes | 1,124 | tIME + pHYs + gAMA |
| Substitution.png | 25 x 32 | 8 | RGBA | yes | 1,998 | tIME + pHYs + gAMA |
| TacticsPitch.png | 600 x 400 | 8 | RGBA | yes | 270,846 | tEXt + tIME + pHYs + gAMA |
| TacticsPitchSmall.png | 180 x 240 | 8 | RGBA | yes | 47,658 | tEXt + tIME + pHYs + gAMA |
| TiredFace.png | 26 x 26 | 8 | RGBA | yes | 1,043 | tEXt + tIME + pHYs + gAMA |
| Trophy.png | 28 x 30 | 8 | RGBA | yes | 1,835 | tIME + pHYs + gAMA |
| YellowCard.png | 43 x 68 | 8 | RGBA | yes | 4,711 | tIME + pHYs + gAMA |

#### `EngineMedia/Match/Pitch`  (56 files)

| File | W x H | Bits | Colour type | Alpha | Bytes | Extra PNG chunks |
|------|-------|------|-------------|-------|-------|------------------|
| Boss.png | 192 x 384 | 8 | Indexed / 22 col | no | 4,731 | tEXt + tIME + pHYs + gAMA + PLTE |
| Camera.png | 192 x 64 | 8 | RGB | no | 1,993 | tEXt + tIME + pHYs + gAMA |
| CameraMan.png | 192 x 128 | 8 | RGB | no | 6,662 | tEXt + tIME + pHYs + gAMA |
| Cones.png | 144 x 48 | 8 | RGBA | yes | 6,980 | tEXt + tIME + pHYs + gAMA |
| Dugout.png | 192 x 192 | 8 | RGB | no | 4,423 | tEXt + tIME + pHYs + gAMA |
| Dummies.png | 96 x 82 | 8 | RGBA | yes | 993 | tEXt + tIME + pHYs + gAMA |
| Fans.png | 384 x 640 | 8 | Indexed / 22 col | no | 9,242 | tEXt + tIME + pHYs + gAMA + PLTE |
| Flag.png | 44 x 64 | 8 | RGBA | yes | 1,196 | tEXt + tIME + pHYs + gAMA |
| Goal1.png | 238 x 106 | 4 | Indexed / 13 col | no | 584 | tEXt + tIME + pHYs + gAMA + PLTE |
| Goal1_Net.png | 220 x 58 | 4 | Indexed / 4 col | no | 351 | tEXt + tIME + pHYs + gAMA + PLTE |
| Goal1_Shadow.png | 272 x 91 | 8 | RGBA | yes | 2,887 | tEXt + tIME + pHYs + gAMA |
| Goal2.png | 240 x 108 | 4 | Indexed / 14 col | no | 665 | tEXt + tIME + pHYs + gAMA + PLTE |
| Goal2_Shadow.png | 272 x 93 | 8 | RGBA | yes | 3,148 | tEXt + tIME + pHYs + gAMA |
| Grass.png | 1024 x 256 | 8 | RGBA | yes | 379,438 | tEXt + tIME + pHYs + gAMA |
| Mow0.png | 450 x 600 | 4 | Indexed / 16 col | no | 15,059 | tEXt + tIME + pHYs + gAMA + PLTE |
| Mow1.png | 450 x 600 | 4 | Indexed / 16 col | no | 11,262 | tEXt + tIME + pHYs + gAMA + PLTE |
| Mows.png | 512 x 128 | 4 | Indexed / 8 col | no | 817 | tEXt + tIME + pHYs + gAMA + PLTE |
| NSG.png | 169 x 44 | 8 | RGBA | yes | 2,040 | tEXt + tIME + pHYs + gAMA |
| Patch.png | 128 x 64 | 8 | RGBA | yes | 11,728 | tEXt + tIME + pHYs + gAMA |
| Photographer.png | 480 x 336 | 8 | RGB | no | 26,195 | tEXt + tIME + pHYs + gAMA |
| Photographer2.png | 240 x 336 | 8 | RGB | no | 21,355 | tEXt + tIME + pHYs + gAMA |
| Pitch.png | 1808 x 2408 | 4 | Indexed / 3 col | no | 34,893 | tEXt + tIME + pHYs + gAMA + PLTE |
| Pitch1.png | 452 x 602 | 4 | Indexed / 3 col | no | 1,378 | tEXt + tIME + pHYs + gAMA + PLTE |
| Pitch1b.png | 452 x 602 | 4 | Indexed / 3 col | no | 1,380 | tEXt + tIME + pHYs + gAMA + PLTE |
| Pitch2.png | 452 x 602 | 4 | Indexed / 3 col | no | 2,147 | tEXt + tIME + pHYs + gAMA + PLTE |
| Pitch2b.png | 452 x 602 | 4 | Indexed / 3 col | no | 2,153 | tEXt + tIME + pHYs + gAMA + PLTE |
| Pitch3.png | 452 x 602 | 4 | Indexed / 3 col | no | 2,388 | tEXt + tIME + pHYs + gAMA + PLTE |
| Pitch4.png | 452 x 602 | 4 | Indexed / 3 col | no | 3,028 | tEXt + tIME + pHYs + gAMA + PLTE |
| Poles.png | 48 x 80 | 4 | Indexed / 5 col | no | 296 | tEXt + tIME + pHYs + gAMA + PLTE |
| Rain.png | 512 x 64 | 8 | RGBA | yes | 31,471 | tEXt + tIME + pHYs + gAMA |
| Snow.png | 15 x 15 | 8 | Grey | no | 261 | tIME + pHYs + gAMA |
| StadiumBottom.png | 580 x 772 | 8 | RGB | no | 96,547 | tIME + pHYs + gAMA |
| StadiumBottomG.png | 580 x 772 | 8 | RGBA | yes | 19,984 | tIME + pHYs + gAMA |
| StadiumBottomGrass.png | 580 x 772 | 8 | RGB | no | 167,300 | tIME + pHYs + gAMA |
| StadiumCornerBottom.png | 772 x 772 | 8 | RGB | no | 452,997 | tIME + pHYs + gAMA |
| StadiumCornerBottomG.png | 772 x 772 | 8 | RGBA | yes | 381,835 | tIME + pHYs + gAMA |
| StadiumCornerBottomGrass.png | 772 x 772 | 8 | RGB | no | 284,318 | tIME + pHYs + gAMA |
| StadiumCornerBottomGrass2.png | 772 x 772 | 8 | RGB | no | 642,636 | tIME + pHYs + gAMA |
| StadiumCornerTop.png | 772 x 772 | 8 | RGB | no | 644,407 | tIME + pHYs + gAMA |
| StadiumCornerTopG.png | 772 x 772 | 8 | RGBA | yes | 508,821 | tIME + pHYs + gAMA |
| StadiumCornerTopGrass.png | 772 x 772 | 8 | RGB | no | 581,932 | tIME + pHYs + gAMA |
| StadiumCornerTopGrass2.png | 772 x 772 | 8 | RGB | no | 604,670 | tIME + pHYs + gAMA |
| StadiumRoofBottom.png | 772 x 772 | 8 | RGB | no | 335,798 | tIME + pHYs + gAMA |
| StadiumRoofTop.png | 772 x 772 | 8 | RGB | no | 318,859 | tEXt + tIME + pHYs + gAMA |
| StadiumSide.png | 772 x 772 | 8 | RGB | no | 181,783 | tIME + pHYs + gAMA |
| StadiumSideG.png | 772 x 772 | 8 | RGBA | yes | 139,715 | tIME + pHYs + gAMA |
| StadiumSideGrass.png | 772 x 772 | 8 | RGB | no | 649,937 | tIME + pHYs + gAMA |
| StadiumTest.png | 2512 x 772 | 8 | RGB | no | 830,321 | tIME + pHYs + gAMA |
| StadiumTop.png | 580 x 772 | 8 | RGB | no | 69,882 | tIME + pHYs + gAMA |
| StadiumTopG.png | 580 x 772 | 8 | RGBA | yes | 56,079 | tIME + pHYs + gAMA |
| StadiumTopGrass.png | 580 x 772 | 8 | RGB | no | 412,485 | tIME + pHYs + gAMA |
| StadiumTunnel.png | 772 x 772 | 8 | RGB | no | 215,444 | tIME + pHYs + gAMA |
| StadiumTunnelBarrier.png | 772 x 772 | 8 | RGB | no | 6,943 | tIME + pHYs + gAMA |
| StadiumTunnelG.png | 772 x 772 | 8 | RGBA | yes | 163,540 | tIME + pHYs + gAMA |
| Target.png | 128 x 128 | 8 | RGBA | yes | 8,066 | tEXt + tIME + pHYs + gAMA |
| Zone.png | 96 x 192 | 8 | RGBA | yes | 1,965 | tEXt + tIME + pHYs + gAMA |

#### `EngineMedia/Match/Pitch/Ads`  (10 files)

| File | W x H | Bits | Colour type | Alpha | Bytes | Extra PNG chunks |
|------|-------|------|-------------|-------|-------|------------------|
| AdBoard.pspimage | - | - | - | - | 43,342 | Paint Shop Pro source (see 2.4) |
| AdBoard_1.png | 256 x 36 | 8 | RGBA | yes | 5,542 | tEXt + tIME + pHYs + gAMA |
| AdBoard_2.png | 256 x 36 | 8 | RGBA | yes | 13,354 | tEXt + tIME + pHYs + gAMA |
| AdBoard_3.png | 256 x 36 | 8 | RGBA | yes | 12,471 | tEXt + tIME + pHYs + gAMA |
| AdBoard_4.png | 256 x 36 | 8 | RGBA | yes | 5,542 | tEXt + tIME + pHYs + gAMA |
| AdBoard_5.png | 256 x 36 | 8 | RGBA | yes | 13,354 | tEXt + tIME + pHYs + gAMA |
| AdBoard_6.png | 256 x 36 | 8 | RGBA | yes | 12,471 | tEXt + tIME + pHYs + gAMA |
| AdBoard_7.png | 256 x 36 | 8 | RGBA | yes | 5,542 | tEXt + tIME + pHYs + gAMA |
| AdBoard_8.png | 256 x 36 | 8 | RGBA | yes | 13,354 | tEXt + tIME + pHYs + gAMA |
| AdBoard_9.png | 256 x 36 | 8 | RGBA | yes | 12,471 | tEXt + tIME + pHYs + gAMA |

#### `EngineMedia/Match/Player`  (22 files)

| File | W x H | Bits | Colour type | Alpha | Bytes | Extra PNG chunks |
|------|-------|------|-------------|-------|-------|------------------|
| ArrowGreen.png | 1680 x 61 | 8 | RGBA | yes | 8,947 | tIME + pHYs + gAMA |
| ArrowYellow.png | 1680 x 61 | 8 | RGBA | yes | 10,206 | tEXt + tIME + pHYs + gAMA |
| Highlight.png | 52 x 52 | 8 | RGBA | yes | 2,305 | tIME + pHYs + gAMA |
| Keeper.png | 2048 x 1536 | 8 | Indexed / 45 col | no | 83,049 | tEXt + tIME + pHYs + gAMA + PLTE |
| OffsideFlag.png | 16 x 15 | 8 | RGBA | yes | 723 | tEXt + tIME + pHYs + gAMA |
| Player_Chequered.png | 2048 x 1536 | 8 | Indexed / 27 col | no | 66,076 | tIME + pHYs + gAMA + PLTE |
| Player_DiagonalSplit.png | 2048 x 1536 | 8 | Indexed / 27 col | no | 64,900 | tIME + pHYs + gAMA + PLTE |
| Player_Hoop.png | 2048 x 1536 | 8 | Indexed / 25 col | no | 64,360 | tIME + pHYs + gAMA + PLTE |
| Player_Hoops.png | 2048 x 1536 | 8 | Indexed / 25 col | no | 65,388 | tIME + pHYs + gAMA + PLTE |
| Player_Hoopsb.png | 2048 x 1536 | 8 | Indexed / 25 col | no | 65,661 | tIME + pHYs + gAMA + PLTE |
| Player_Plain.png | 2048 x 1536 | 8 | Indexed / 24 col | no | 63,561 | tIME + pHYs + gAMA + PLTE |
| Player_Segments.png | 2048 x 1536 | 8 | Indexed / 27 col | no | 65,006 | tIME + pHYs + gAMA + PLTE |
| Player_SleeveR.png | 2048 x 1536 | 8 | Indexed / 27 col | no | 64,785 | tIME + pHYs + gAMA + PLTE |
| Player_Sleeves.png | 2048 x 1536 | 8 | Indexed / 27 col | no | 65,334 | tIME + pHYs + gAMA + PLTE |
| Player_Split.png | 2048 x 1536 | 8 | Indexed / 27 col | no | 64,671 | tIME + pHYs + gAMA + PLTE |
| Player_StripeC.png | 2048 x 1536 | 8 | Indexed / 25 col | no | 63,832 | tIME + pHYs + gAMA + PLTE |
| Player_StripeLR.png | 2048 x 1536 | 8 | Indexed / 25 col | no | 64,045 | tIME + pHYs + gAMA + PLTE |
| Player_StripeR.png | 2048 x 1536 | 8 | Indexed / 25 col | no | 64,079 | tIME + pHYs + gAMA + PLTE |
| Player_Stripes.png | 2048 x 1536 | 8 | Indexed / 27 col | no | 68,614 | tIME + pHYs + gAMA + PLTE |
| Player_Trim.png | 2048 x 1536 | 8 | Indexed / 25 col | no | 64,019 | tIME + pHYs + gAMA + PLTE |
| Player_V.png | 2048 x 1536 | 8 | Indexed / 25 col | no | 64,514 | tIME + pHYs + gAMA + PLTE |
| Speech.png | 24 x 24 | 8 | RGBA | yes | 1,582 | tEXt + tIME + pHYs + gAMA |

---

## 3. Audio

### 3.1 Global OGG facts

All 61 on-disk sound files are **Ogg Vorbis I** (page header `OggS`, identification packet
`0x01 "vorbis"`, Vorbis version 0). Verified properties:

| Property | Values found |
|----------|--------------|
| Sample rate | 44,100 Hz (59 files) and 48,000 Hz (2 files: `Match/Sounds/Bounce.ogg`, `GameMedia/Sounds/Click.ogg`) |
| Channels | mono (59 files); **stereo only for `Match/Sounds/Rain.ogg` and `GameMedia/Sounds/Phone.ogg`** |
| Nominal bitrate | 32,001 / 80,000 / 86,000 / 96,000 / 192,000 / 350,000 bps (VBR-ish; nominal only) |
| Total on-disk audio | 8,005,479 bytes |
| Longest file | `GameMedia/Sounds/BDay.ogg` - 234.89 s (~3 min 55 s), 2,045,536 bytes |
| Shortest file | `Match/Sounds/StopWatch.ogg` - 0.02 s |

The two 48 kHz files and the two stereo files are the only heterogeneity; a reconstruction that
resamples everything to 44.1 kHz mono would be audibly different for `Rain` and `Phone`, so keep the
originals.

### 3.2 Full audio catalogue

#### `EngineMedia/Match/Sounds`  (39 files)

| File | Bytes | Ch | Hz | Nominal bps | Samples | Length (s) |
|------|-------|----|----|-------------|---------|------------|
| Bird1.ogg | 22,867 | 1 | 44,100 | 96,000 | 99,072 | 2.25 |
| Bird2.ogg | 34,414 | 1 | 44,100 | 96,000 | 161,280 | 3.66 |
| Bird3.ogg | 25,346 | 1 | 44,100 | 96,000 | 122,112 | 2.77 |
| Bird4.ogg | 48,144 | 1 | 44,100 | 96,000 | 191,232 | 4.34 |
| BoozedUp.ogg | 12,562 | 1 | 44,100 | 80,000 | 46,230 | 1.05 |
| Bounce.ogg | 7,229 | 1 | 48,000 | 192,000 | 5,420 | 0.11 |
| ConeHit.ogg | 5,442 | 1 | 44,100 | 96,000 | 5,248 | 0.12 |
| ConeSplit.ogg | 6,109 | 1 | 44,100 | 96,000 | 9,058 | 0.21 |
| CrowdAmbience.ogg | 184,516 | 1 | 44,100 | 192,000 | 345,552 | 7.84 |
| CrowdBoo.ogg | 149,901 | 1 | 44,100 | 192,000 | 266,714 | 6.05 |
| CrowdBooShort.ogg | 22,357 | 1 | 44,100 | 80,000 | 98,658 | 2.24 |
| CrowdChant1.ogg | 351,271 | 1 | 44,100 | 192,000 | 635,426 | 14.41 |
| CrowdChant2.ogg | 584,938 | 1 | 44,100 | 192,000 | 1,071,606 | 24.3 |
| CrowdChant3.ogg | 980,030 | 1 | 44,100 | 192,000 | 1,784,860 | 40.47 |
| CrowdChant4.ogg | 291,722 | 1 | 44,100 | 192,000 | 536,382 | 12.16 |
| CrowdChant5.ogg | 573,433 | 1 | 44,100 | 192,000 | 1,065,494 | 24.16 |
| CrowdChant6.ogg | 378,012 | 1 | 44,100 | 192,000 | 695,079 | 15.76 |
| CrowdChant7.ogg | 453,092 | 1 | 44,100 | 192,000 | 809,187 | 18.35 |
| CrowdChant8.ogg | 722,791 | 1 | 44,100 | 192,000 | 1,319,228 | 29.91 |
| CrowdCheer.ogg | 26,420 | 1 | 44,100 | 80,000 | 121,360 | 2.75 |
| CrowdGoal.ogg | 290,589 | 1 | 44,100 | 192,000 | 520,320 | 11.8 |
| CrowdOh.ogg | 101,582 | 1 | 44,100 | 192,000 | 181,292 | 4.11 |
| Kick.ogg | 5,800 | 1 | 44,100 | 192,000 | 2,152 | 0.05 |
| Oof.ogg | 6,413 | 1 | 44,100 | 96,000 | 9,466 | 0.21 |
| PoleBoing.ogg | 6,984 | 1 | 44,100 | 80,000 | 20,825 | 0.47 |
| Post.ogg | 10,637 | 1 | 44,100 | 192,000 | 15,480 | 0.35 |
| Rain.ogg | 167,752 | 2 | 44,100 | 350,000 | 190,464 | 4.32 |
| Skill.ogg | 4,128 | 1 | 44,100 | 32,001 | 16,736 | 0.38 |
| Slide.ogg | 5,714 | 1 | 44,100 | 86,000 | 8,389 | 0.19 |
| StopWatch.ogg | 3,753 | 1 | 44,100 | 80,000 | 848 | 0.02 |
| StopWatchBeep.ogg | 7,388 | 1 | 44,100 | 80,000 | 16,646 | 0.38 |
| StopWatchOld.ogg | 7,182 | 1 | 44,100 | 80,000 | 16,646 | 0.38 |
| TrainingClap.ogg | 39,767 | 1 | 44,100 | 80,000 | 158,466 | 3.59 |
| TrainingError.ogg | 7,215 | 1 | 44,100 | 80,000 | 15,793 | 0.36 |
| TrainingOoh.ogg | 13,912 | 1 | 44,100 | 80,000 | 56,159 | 1.27 |
| TrainingReset.ogg | 4,279 | 1 | 44,100 | 80,000 | 3,861 | 0.09 |
| TrainingSuccess.ogg | 16,642 | 1 | 44,100 | 80,000 | 75,084 | 1.7 |
| Whistle.ogg | 5,466 | 1 | 44,100 | 96,000 | 7,676 | 0.17 |
| WhistleFinal.ogg | 14,164 | 1 | 44,100 | 192,000 | 58,805 | 1.33 |

#### `GameMedia/Sounds`  (12 files)

| File | Bytes | Ch | Hz | Nominal bps | Samples | Length (s) |
|------|-------|----|----|-------------|---------|------------|
| Achievement.ogg | 10,715 | 1 | 44,100 | 80,000 | 36,890 | 0.84 |
| BDay.ogg | 2,045,536 | 1 | 44,100 | 80,000 | 10,358,784 | 234.89 |
| Beep.ogg | 5,294 | 1 | 44,100 | 96,000 | 5,182 | 0.12 |
| Bus.ogg | 25,183 | 1 | 44,100 | 80,000 | 112,224 | 2.54 |
| Cash.ogg | 10,119 | 1 | 44,100 | 96,000 | 29,667 | 0.67 |
| Click.ogg | 5,732 | 1 | 48,000 | 192,000 | 1,880 | 0.04 |
| Mobile.ogg | 16,626 | 1 | 44,100 | 80,000 | 90,132 | 2.04 |
| Newspaper.ogg | 12,882 | 1 | 44,100 | 96,000 | 33,276 | 0.75 |
| Phone.ogg | 50,330 | 2 | 44,100 | 350,000 | 48,972 | 1.11 |
| Plane.ogg | 44,736 | 1 | 44,100 | 80,000 | 224,530 | 5.09 |
| Select.ogg | 6,141 | 1 | 44,100 | 192,000 | 3,216 | 0.07 |
| Signature.ogg | 14,718 | 1 | 44,100 | 80,000 | 50,733 | 1.15 |

#### `GameMedia/Sounds/Casino`  (10 files)

| File | Bytes | Ch | Hz | Nominal bps | Samples | Length (s) |
|------|-------|----|----|-------------|---------|------------|
| CardFlip.ogg | 7,887 | 1 | 44,100 | 80,000 | 20,440 | 0.46 |
| CrowdAmbience.ogg | 63,398 | 1 | 44,100 | 80,000 | 345,552 | 7.84 |
| FlashBulb.ogg | 5,629 | 1 | 44,100 | 80,000 | 10,692 | 0.24 |
| Gallop.ogg | 19,378 | 1 | 44,100 | 80,000 | 78,496 | 1.78 |
| RouletteHit.ogg | 5,038 | 1 | 44,100 | 96,000 | 3,500 | 0.08 |
| RouletteLand.ogg | 9,905 | 1 | 44,100 | 96,000 | 22,638 | 0.51 |
| RouletteSpin.ogg | 19,083 | 1 | 44,100 | 96,000 | 67,827 | 1.54 |
| SlotsArm.ogg | 12,076 | 1 | 44,100 | 96,000 | 28,032 | 0.64 |
| SlotsStop.ogg | 6,989 | 1 | 44,100 | 96,000 | 11,510 | 0.26 |
| SlotsWin.ogg | 8,121 | 1 | 44,100 | 96,000 | 17,737 | 0.4 |

### 3.3 Music (not on disk)

The six music tracks are **incbin'd inside `NSS5.exe`** under `Inc/Music/*.ogg` and do not appear in
the install folder. They are therefore not part of this catalogue; see the executable-layout document.
The 61 on-disk `.ogg` files are all SFX/ambience.

### 3.4 Stray audio artefacts

Two Sound Forge peak files were shipped by accident and are never opened by the game:

| File | Bytes |
|------|-------|
| `EngineMedia/Match/Sounds/StopWatchBeep.ogg.sfk` | 132 |
| `GameMedia/Sounds/Casino/Gallop.ogg.sfk` | 372 |

---

## 4. `.tac` - the tactics / formation format (REVERSE ENGINEERED)

### 4.1 Physical format

`EngineMedia/Tactics/` contains 13 files, each **exactly 105 bytes**. The raw bytes of
`3-4-3.tac` are:

```
30 0D 0A 31 0D 0A 30 0D 0A 31 0D 0A 30 0D 0A 31 0D 0A 30 0D 0A 30 0D 0A 30 0D 0A
30 0D 0A 30 0D 0A 30 0D 0A 30 0D 0A 30 0D 0A 31 0D 0A 30 0D 0A 31 0D 0A 30 0D 0A
31 0D 0A 30 0D 0A 31 0D 0A 30 0D 0A 30 0D 0A 30 0D 0A 30 0D 0A 30 0D 0A 30 0D 0A
30 0D 0A 30 0D 0A 31 0D 0A 30 0D 0A 31 0D 0A 30 0D 0A 31 0D 0A 30 0D 0A
```

i.e. **35 lines of a single ASCII `0` or `1`, each terminated with CRLF** (`0x0D 0x0A`).
35 × 3 = 105 bytes exactly; there is no header, no footer and no trailing blank line.

This is the classic BlitzMax `WriteLine`/`ReadLine` pattern: the writer emits `WriteLine(String(v))`
35 times and the reader does `For i = 0 Until 35 : grid[i] = Int(ReadLine(s))`.

Corroborating strings in `NSS5.exe`:

```
Loading Tactics:
Saving Tactics:
Cannot find tactics: 
Cannot save tactics: 
EngineMedia\Tactics\
EngineMedia\Tactics\4-4-2.tac
.tac
tactics
Tactics\
```

The presence of `Saving Tactics:` and `Cannot save tactics:` confirms the game **writes** this format
too (user-defined formations), so a reconstruction must round-trip it byte-identically.
Note the hard-coded default path `EngineMedia\Tactics\4-4-2.tac` - a file which **does not exist on
disk** (the shipped files are `4-4-2 A.tac` and `4-4-2 B.tac`). **UNCERTAIN:** whether this is a
fallback that would fail, a legacy path, or the name under which the user's current formation is
saved. Worth checking in the disassembly, because a naive reimplementation could crash here.

### 4.2 Deducing the encoding

Observations that constrain the format:

1. Every file has exactly **35** lines.
2. Every file has exactly **10** ones - never 11.
3. `35 = 7 × 5` and `35 = 5 × 7`; those are the only sensible factorisations.
4. The filenames are formation names whose digits sum to 10 (`4+4+2`, `4+3+3`, `3+5+2`, …) - i.e. the
   **outfield** players. The goalkeeper is not in the file.

Fact 2 + fact 4 is the key: **10 ones = 10 outfield players, one bit per grid cell, `1` = a player is
stationed in that cell. The goalkeeper is implicit and has no cell.** No line is a flag; all 35 are
grid cells.

Now the grid orientation. Try **7 columns × 5 rows, row-major, line index = `row × 7 + col`**, and
read the ones-per-row for `4-4-2 A.tac` (`10101010000000101010100000000010100`):

| Row | Lines | Bits | Ones |
|-----|-------|------|------|
| 0 | 0-6 | `1010101` | **4** |
| 1 | 7-13 | `0000000` | 0 |
| 2 | 14-20 | `1010101` | **4** |
| 3 | 21-27 | `0000000` | 0 |
| 4 | 28-34 | `0010100` | **2** |

4 - 4 - 2. Applying the same decode to all 13 files reproduces the filename of every single one. The
`Name check` column below is the raw per-band population; for the two layered variants (`3-5-2 A`,
`4-4-2 B`) the middle bands collapse to the filename when summed - `3-(1+3+1)-2 = 3-5-2` and
`4-(1+2+1)-2 = 4-4-2` - which is exactly what an `A`/`B` shape variant of the same nominal formation
should look like.

| Formation file | Row 0 (DEF) | Row 1 | Row 2 (MID) | Row 3 | Row 4 (ATT) | Players per band | Name check |
|---|---|---|---|---|---|---|---|
| `3-4-3.tac` | `0101010` | `0000000` | `1010101` | `0000000` | `0101010` | 3/0/4/0/3 | 3-4-3 |
| `3-5-2 A.tac` | `0101010` | `0001000` | `1001001` | `0001000` | `0010100` | 3/1/3/1/2 | 3-1-3-1-2 |
| `3-5-2 B.tac` | `0101010` | `0000000` | `1011101` | `0000000` | `0010100` | 3/0/5/0/2 | 3-5-2 |
| `4-1-4-1.tac` | `1010101` | `0001000` | `1010101` | `0000000` | `0001000` | 4/1/4/0/1 | 4-1-4-1 |
| `4-2-2-2.tac` | `1010101` | `0000000` | `0010100` | `1000001` | `0010100` | 4/0/2/2/2 | 4-2-2-2 |
| `4-2-3-1.tac` | `1010101` | `0010100` | `0000000` | `0101010` | `0001000` | 4/2/0/3/1 | 4-2-3-1 |
| `4-2-4.tac` | `1010101` | `0000000` | `0010100` | `0000000` | `1010101` | 4/0/2/0/4 | 4-2-4 |
| `4-3-3.tac` | `1010101` | `0000000` | `0101010` | `0000000` | `0101010` | 4/0/3/0/3 | 4-3-3 |
| `4-4-1-1.tac` | `1010101` | `0000000` | `1010101` | `0001000` | `0001000` | 4/0/4/1/1 | 4-4-1-1 |
| `4-4-2 A.tac` | `1010101` | `0000000` | `1010101` | `0000000` | `0010100` | 4/0/4/0/2 | 4-4-2 |
| `4-4-2 B.tac` | `1010101` | `0001000` | `1000001` | `0001000` | `0010100` | 4/1/2/1/2 | 4-1-2-1-2 |
| `4-5-1.tac` | `1010101` | `0000000` | `1011101` | `0000000` | `0001000` | 4/0/5/0/1 | 4-5-1 |
| `5-3-2.tac` | `1011101` | `0000000` | `0101010` | `0000000` | `0010100` | 5/0/3/0/2 | 5-3-2 |

```
Column index:      0  1  2  3  4  5  6      (0 = left touchline .. 6 = right touchline)

--- 3-4-3 ---
  row 4 ATT    .  O  .  O  .  O  .    (lines 28-34)
  row 3        .  .  .  .  .  .  .    (lines 21-27)
  row 2 MID    O  .  O  .  O  .  O    (lines 14-20)
  row 1        .  .  .  .  .  .  .    (lines 7-13)
  row 0 DEF    .  O  .  O  .  O  .    (lines 0-6)
  ---------------- own goal is below row 0 ----------------

--- 3-5-2 A ---
  row 4 ATT    .  .  O  .  O  .  .    (lines 28-34)
  row 3        .  .  .  O  .  .  .    (lines 21-27)
  row 2 MID    O  .  .  O  .  .  O    (lines 14-20)
  row 1        .  .  .  O  .  .  .    (lines 7-13)
  row 0 DEF    .  O  .  O  .  O  .    (lines 0-6)
  ---------------- own goal is below row 0 ----------------

--- 3-5-2 B ---
  row 4 ATT    .  .  O  .  O  .  .    (lines 28-34)
  row 3        .  .  .  .  .  .  .    (lines 21-27)
  row 2 MID    O  .  O  O  O  .  O    (lines 14-20)
  row 1        .  .  .  .  .  .  .    (lines 7-13)
  row 0 DEF    .  O  .  O  .  O  .    (lines 0-6)
  ---------------- own goal is below row 0 ----------------

--- 4-1-4-1 ---
  row 4 ATT    .  .  .  O  .  .  .    (lines 28-34)
  row 3        .  .  .  .  .  .  .    (lines 21-27)
  row 2 MID    O  .  O  .  O  .  O    (lines 14-20)
  row 1        .  .  .  O  .  .  .    (lines 7-13)
  row 0 DEF    O  .  O  .  O  .  O    (lines 0-6)
  ---------------- own goal is below row 0 ----------------

--- 4-2-2-2 ---
  row 4 ATT    .  .  O  .  O  .  .    (lines 28-34)
  row 3        O  .  .  .  .  .  O    (lines 21-27)
  row 2 MID    .  .  O  .  O  .  .    (lines 14-20)
  row 1        .  .  .  .  .  .  .    (lines 7-13)
  row 0 DEF    O  .  O  .  O  .  O    (lines 0-6)
  ---------------- own goal is below row 0 ----------------

--- 4-2-3-1 ---
  row 4 ATT    .  .  .  O  .  .  .    (lines 28-34)
  row 3        .  O  .  O  .  O  .    (lines 21-27)
  row 2 MID    .  .  .  .  .  .  .    (lines 14-20)
  row 1        .  .  O  .  O  .  .    (lines 7-13)
  row 0 DEF    O  .  O  .  O  .  O    (lines 0-6)
  ---------------- own goal is below row 0 ----------------

--- 4-2-4 ---
  row 4 ATT    O  .  O  .  O  .  O    (lines 28-34)
  row 3        .  .  .  .  .  .  .    (lines 21-27)
  row 2 MID    .  .  O  .  O  .  .    (lines 14-20)
  row 1        .  .  .  .  .  .  .    (lines 7-13)
  row 0 DEF    O  .  O  .  O  .  O    (lines 0-6)
  ---------------- own goal is below row 0 ----------------

--- 4-3-3 ---
  row 4 ATT    .  O  .  O  .  O  .    (lines 28-34)
  row 3        .  .  .  .  .  .  .    (lines 21-27)
  row 2 MID    .  O  .  O  .  O  .    (lines 14-20)
  row 1        .  .  .  .  .  .  .    (lines 7-13)
  row 0 DEF    O  .  O  .  O  .  O    (lines 0-6)
  ---------------- own goal is below row 0 ----------------

--- 4-4-1-1 ---
  row 4 ATT    .  .  .  O  .  .  .    (lines 28-34)
  row 3        .  .  .  O  .  .  .    (lines 21-27)
  row 2 MID    O  .  O  .  O  .  O    (lines 14-20)
  row 1        .  .  .  .  .  .  .    (lines 7-13)
  row 0 DEF    O  .  O  .  O  .  O    (lines 0-6)
  ---------------- own goal is below row 0 ----------------

--- 4-4-2 A ---
  row 4 ATT    .  .  O  .  O  .  .    (lines 28-34)
  row 3        .  .  .  .  .  .  .    (lines 21-27)
  row 2 MID    O  .  O  .  O  .  O    (lines 14-20)
  row 1        .  .  .  .  .  .  .    (lines 7-13)
  row 0 DEF    O  .  O  .  O  .  O    (lines 0-6)
  ---------------- own goal is below row 0 ----------------

--- 4-4-2 B ---
  row 4 ATT    .  .  O  .  O  .  .    (lines 28-34)
  row 3        .  .  .  O  .  .  .    (lines 21-27)
  row 2 MID    O  .  .  .  .  .  O    (lines 14-20)
  row 1        .  .  .  O  .  .  .    (lines 7-13)
  row 0 DEF    O  .  O  .  O  .  O    (lines 0-6)
  ---------------- own goal is below row 0 ----------------

--- 4-5-1 ---
  row 4 ATT    .  .  .  O  .  .  .    (lines 28-34)
  row 3        .  .  .  .  .  .  .    (lines 21-27)
  row 2 MID    O  .  O  O  O  .  O    (lines 14-20)
  row 1        .  .  .  .  .  .  .    (lines 7-13)
  row 0 DEF    O  .  O  .  O  .  O    (lines 0-6)
  ---------------- own goal is below row 0 ----------------

--- 5-3-2 ---
  row 4 ATT    .  .  O  .  O  .  .    (lines 28-34)
  row 3        .  .  .  .  .  .  .    (lines 21-27)
  row 2 MID    .  O  .  O  .  O  .    (lines 14-20)
  row 1        .  .  .  .  .  .  .    (lines 7-13)
  row 0 DEF    O  .  O  O  O  .  O    (lines 0-6)
  ---------------- own goal is below row 0 ----------------

```

### 4.3 Line-by-line difference matrix

For completeness, here is every line of every file side by side (line index 0-34 down the left,
formation across the top). Lines 7-13 and 21-27 are the "gap" bands that most flat formations leave
empty; lines 0-6, 14-20 and 28-34 carry the classic three-band shapes.

```
line 3-4-3  3-5-2A 3-5-2B 4-1-4-1 4-2-2-2 4-2-3-1 4-2-4  4-3-3  4-4-1-1 4-4-2A 4-4-2B 4-5-1  5-3-2
  0    0      0      0      1       1       1       1      1      1       1      1      1      1
  1    1      1      1      0       0       0       0      0      0       0      0      0      0
  2    0      0      0      1       1       1       1      1      1       1      1      1      1
  3    1      1      1      0       0       0       0      0      0       0      0      0      1
  4    0      0      0      1       1       1       1      1      1       1      1      1      1
  5    1      1      1      0       0       0       0      0      0       0      0      0      0
  6    0      0      0      1       1       1       1      1      1       1      1      1      1
  7    0      0      0      0       0       0       0      0      0       0      0      0      0
  8    0      0      0      0       0       0       0      0      0       0      0      0      0
  9    0      0      0      0       0       1       0      0      0       0      0      0      0
 10    0      1      0      1       0       0       0      0      0       0      1      0      0
 11    0      0      0      0       0       1       0      0      0       0      0      0      0
 12    0      0      0      0       0       0       0      0      0       0      0      0      0
 13    0      0      0      0       0       0       0      0      0       0      0      0      0
 14    1      1      1      1       0       0       0      0      1       1      1      1      0
 15    0      0      0      0       0       0       0      1      0       0      0      0      1
 16    1      0      1      1       1       0       1      0      1       1      0      1      0
 17    0      1      1      0       0       0       0      1      0       0      0      1      1
 18    1      0      1      1       1       0       1      0      1       1      0      1      0
 19    0      0      0      0       0       0       0      1      0       0      0      0      1
 20    1      1      1      1       0       0       0      0      1       1      1      1      0
 21    0      0      0      0       1       0       0      0      0       0      0      0      0
 22    0      0      0      0       0       1       0      0      0       0      0      0      0
 23    0      0      0      0       0       0       0      0      0       0      0      0      0
 24    0      1      0      0       0       1       0      0      1       0      1      0      0
 25    0      0      0      0       0       0       0      0      0       0      0      0      0
 26    0      0      0      0       0       1       0      0      0       0      0      0      0
 27    0      0      0      0       1       0       0      0      0       0      0      0      0
 28    0      0      0      0       0       0       1      0      0       0      0      0      0
 29    1      0      0      0       0       0       0      1      0       0      0      0      0
 30    0      1      1      0       1       0       1      0      0       1      1      0      1
 31    1      0      0      1       0       1       0      1      1       0      0      1      0
 32    0      1      1      0       1       0       1      0      0       1      1      0      1
 33    1      0      0      0       0       0       0      1      0       0      0      0      0
 34    0      0      0      0       0       0       1      0      0       0      0      0      0
```

Reading the rows in blocks of seven makes the column semantics obvious:

| Bit pattern in a band | Occupied columns | Football meaning |
|-----------------------|------------------|------------------|
| `0001000` | 3 | 1 central player (lone striker, DM, AM) |
| `0010100` | 2, 4 | 2 central players (strike pair, double pivot) |
| `0101010` | 1, 3, 5 | 3 evenly-spread players (back three, midfield three, front three) |
| `1010101` | 0, 2, 4, 6 | 4 across (flat back four, flat midfield four) |
| `1011101` | 0, 2, 3, 4, 6 | 5 across (back five with wing-backs, midfield five) |
| `1000001` | 0, 6 | 2 wide players only (the wingers of 4-2-2-2) |
| `1001001` | 0, 3, 6 | wing-back / centre / wing-back (3-5-2 A) |

So the seven columns are **evenly spaced lateral slots from one touchline to the other**, with
column 3 the exact centre. Widths pick columns symmetrically: 1 player → {3}; 2 → {2,4}; 3 → {1,3,5};
4 → {0,2,4,6}; 5 → {0,2,3,4,6}; 2 wide → {0,6}.

The five rows are **depth bands from the defensive third to the attacking third**. Row 0 is always the
defensive line (its population always equals the first digit of the filename) and row 4 the forward
line. Rows 1 and 3 are the holding-midfield and attacking-midfield bands used only by the "layered"
formations (4-1-4-1, 4-2-3-1, 4-2-2-2, 4-4-1-1, and the `B`/diamond variants).

The `A` / `B` suffixes are shape variants of the same nominal formation:

| Pair | A | B |
|------|---|---|
| `3-5-2` | 3 - **1** - 3 - **1** - 2 (midfield diamond with a wing-back either side) | 3 - **5** flat - 2 |
| `4-4-2` | 4 - **4** flat - 2 | 4 - **1** - 2 wide - **1** - 2 (midfield diamond) |

### 4.4 Confidence

**Confidence: CERTAIN (13/13 files decode to their own filename).**

The decode is over-determined: a 7 × 5 row-major grid with `1` = player is the only reading under
which *all thirteen* files independently reproduce the formation named in their own filename,
including the two `A`/`B` pairs which differ only in shape and not in the nominal 3-number split.
The probability of that happening by chance under a wrong grid interpretation is negligible.

What is **not** determined by the data:

- **UNCERTAIN:** whether column 0 is the left or the right touchline. Every shipped formation is
  laterally symmetric, so the files carry no information about handedness. Pick one and confirm
  against a screenshot of the in-game tactics screen.
- **UNCERTAIN:** whether row 0 is nearest the team's *own* goal or the opponent's. Row 0 always holds
  the defenders, so it is almost certainly the own-goal end when the team attacks "up" the screen,
  but the renderer's y-axis convention is not recoverable from the file.
- **UNCERTAIN:** the pixel/world coordinates each cell maps to on the pitch. That lives in the match
  engine, not in the `.tac` file. The in-game tactics screen draws onto
  `EngineMedia/Match/Other/TacticsPitch.png` (600 × 400 RGBA) with a small variant
  `TacticsPitchSmall.png`; a 7 × 5 grid over a 600 × 400 board gives cell centres at roughly
  x ∈ {43, 129, 214, 300, 386, 471, 557} and y ∈ {40, 120, 200, 280, 360} - **unverified arithmetic,
  offered only as a starting hypothesis.**

### 4.5 Suggested reconstruction data structure

```blitzmax
' 7 columns x 5 rows, row-major.  1 = an outfield player is stationed in that cell.
' The goalkeeper is implicit and is NOT stored.
Const TAC_COLS:Int = 7
Const TAC_ROWS:Int = 5
Const TAC_CELLS:Int = TAC_COLS * TAC_ROWS   ' 35
Const TAC_PLAYERS:Int = 10                  ' invariant: exactly 10 cells are set

Type TTactic
    Field Name:String                        ' file basename, e.g. "4-4-2 A"
    Field Cell:Int[TAC_CELLS]

    Method Load(path:String)
        Local s:TStream = ReadFile(path)
        For Local i:Int = 0 Until TAC_CELLS
            Cell[i] = Int(ReadLine(s))
        Next
        CloseFile s
    End Method

    Method Save(path:String)
        Local s:TStream = WriteFile(path)    ' must emit CRLF, 3 bytes per line, 105 total
        For Local i:Int = 0 Until TAC_CELLS
            WriteLine s, String(Cell[i])
        Next
        CloseFile s
    End Method
End Type
```

---

## 5. `.fmf` - the bitmap font format (REVERSE ENGINEERED)

### 5.1 Identification

`EngineMedia/Fonts/` contains two files:

| File | Bytes |
|------|-------|
| `MatchFontL.fmf` | 5,404,567 |
| `MatchFontM.fmf` | 641,692 |

The exe's UTF-16 string table contains, adjacent to each other:

```
Font Machine
1.5.1
Font Machine 1.5.1
Win32
SHADOW
BORDER
FACE
Unable to load the bitmapfont due to corrupted or unsuported file format
ERROR LOADING PNG
Can't draw text becouse the bitmapfont is null.
```

plus `Loading font: `, `Font loaded`, `ERROR! >>>>>>>>>>>>>> Font could not be loaded: `,
`WARNING! >>>>>>>>>>>> Cannot see font: `, and the two literal paths
`EngineMedia/Fonts/MatchFontL.fmf` / `EngineMedia/Fonts/MatchFontM.fmf`.

**`.fmf` = "Font Machine Font", produced by the BlitzMax community tool *Font Machine* v1.5.1.**
`SHADOW` / `BORDER` / `FACE` are the three renderable layers the tool supports.

### 5.2 Header

**There is no file header and no magic number.** Byte 0 is already the first record. The loader
detects corruption via per-layer sentinel integers (see below), which is exactly what the
"corrupted or unsuported file format" message reports on.

### 5.3 Structure

The file is a flat sequence of **layer records**, each self-describing. There is no index, no count,
and no offset table - the reader streams until EOF.

One layer record:

| Offset | Size | Type | Meaning |
|--------|------|------|---------|
| +0 | 4 | `int32` LE | **character code** (Unicode code point) |
| +4 | var | ASCII + `\n` | **layer name**: `SHADOW`, `BORDER` or `FACE` (`WriteLine`) |
| - | 4 | `int32` LE | **sentinel** (constant per layer, see table) |
| - | var | raw bytes | **a complete PNG file**, signature through `IEND` inclusive |
| - | var | ASCII + `\n` | `<LAYER>CHECK1` |
| - | 4 | `int32` LE | **sentinel again** (same value) |
| - | 4 | `int32` LE | `offsetX` |
| - | 4 | `int32` LE | `offsetY` |
| - | 4 | `int32` LE | `cellWidth` |
| - | 4 | `int32` LE | `cellHeight` |
| - | 4 | `int32` LE | `advance` |
| - | var | ASCII + `\n` | closing token (see table - note the typo for FACE) |

Line terminators inside the file are bare `\n` (`0x0A`), **not** CRLF. The PNG blob has to be found by
walking its chunk list, because its length is not stored anywhere in the `.fmf` container.

Per-layer constants (verified over all 2,720 layer records in the two files):

| Layer | Sentinel (dec) | Sentinel (hex LE bytes) | `CHECK1` token | Closing token |
|-------|----------------|--------------------------|----------------|---------------|
| `SHADOW` | 4577 | `E1 11 00 00` | `SHADOWCHECK1` | `SHADOWCHECK2` |
| `BORDER` | 9345 | `81 24 00 00` | `BORDERCHECK1` | `BORDERCHECK2` |
| `FACE` | 7816 | `88 1E 00 00` | `FACECHECK1` | **`FACECHEK2`** (misspelled in the original tool - must be reproduced verbatim) |

Layers appear in painter's order: `SHADOW`, then `BORDER`, then `FACE`, and the character code is
repeated at the head of *every* layer record, not once per glyph.

### 5.4 Validation

Both files parse to **exactly** their byte length with zero residue, which is the strongest possible
confirmation the structure is right:

| File | Records | Glyphs | Layers per glyph | Parser end offset / file size |
|------|---------|--------|------------------|-------------------------------|
| `MatchFontM.fmf` | 1,088 | 544 | `BORDER`, `FACE` | 641,692 / 641,692 |
| `MatchFontL.fmf` | 1,632 | 544 | `SHADOW`, `BORDER`, `FACE` | 5,404,567 / 5,404,567 |

Both fonts cover the **same 544 code points**. Every embedded PNG is 8-bit **RGBA** (colour type 6),
non-interlaced.

### 5.5 Character set

544 code points, in ascending order, in three runs:

| Run | Code points | Notes |
|-----|-------------|-------|
| ASCII subset | 32, 33, 34, 36-41, 43-46, 48-90, 97-122 | Note the **gaps**: no `#` (35), no `*` (42), no `/` (47), no `[\]^_` (91-96), no `{|}~` (123-126) |
| Latin-1 / CP1252 extras | 131, 138, 140, 142, 154, 156, 158, 159, 161, 162, 163, 165, 169, 191-255 | `ƒ Š Œ Ž š œ ž Ÿ ¡ ¢ £ ¥ ©` plus the full accented block `¿ À … ÿ` |
| Latin Extended | 256-639 contiguous | U+0100-U+027F: all of Latin Extended-A (256-383, U+0100-U+017F), all of Latin Extended-B (384-591, U+0180-U+024F) and the first half of IPA Extensions (592-639, U+0250-U+027F) |

That 256-639 run is contiguous with no gaps, so the tool was simply told "export U+0100…U+027F"
rather than given a hand-picked set. **UNCERTAIN:** whether the Cyrillic text seen in
`Names.csv` (`156_RussiaB`, code points U+0400-U+044F) is renderable by these fonts - U+0400 is
**above** the 639 ceiling, so match-engine text cannot draw Cyrillic player names. That is consistent
with the Cyrillic pool being used only in menus (which use a different, non-`.fmf` font path).

### 5.6 Metrics

The five integers after each `CHECK1` token behave as follows. `MatchFontM`, glyph `'A'` (code 65):

| Layer | PNG size | `offsetX` | `offsetY` | `cellWidth` | `cellHeight` | `advance` |
|-------|----------|-----------|-----------|-------------|--------------|-----------|
| `BORDER` | 37 × 51 | −1 | −1 | 45 | 51 | 0 |
| `FACE` | 35 × 49 | 0 | 0 | 43 | 49 | 29 |

`MatchFontL`, glyph `'A'`:

| Layer | PNG size | `offsetX` | `offsetY` | `cellWidth` | `cellHeight` | `advance` |
|-------|----------|-----------|-----------|-------------|--------------|-----------|
| `SHADOW` | 94 × 134 | −9 | −9 | 107 | 134 | 0 |
| `BORDER` | 77 × 116 | −3 | −3 | 89 | 116 | 0 |
| `FACE` | 71 × 110 | 0 | 0 | 83 | 110 | 52 |

Invariants verified across **all** glyphs in both files:

| Relation | Status |
|----------|--------|
| `FACE.offsetX = FACE.offsetY = 0` | 544/544 both files |
| `FACE.cellHeight` is a single constant per font (`MatchFontM` = 49, `MatchFontL` = 110) | 544/544 |
| `BORDER.offsetX = BORDER.offsetY = −K`, `BORDER.cell{W,H} = FACE.cell{W,H} + 2K` (`K` = 1 for M, 3 for L) | 544/544 |
| `SHADOW.offsetX = SHADOW.offsetY = −9`, `SHADOW.cell{W,H} = FACE.cell{W,H} + 24` | 544/544 (L only) |
| `advance = 0` for `SHADOW` and `BORDER`; only `FACE` carries a non-zero advance | 544/544 |
| `FACE.cellWidth − FACE.advance` is a constant (14 for `MatchFontM`, 31 for `MatchFontL`) for all glyphs **except** the space glyph (U+0020), where the difference is 1 | 543 + 1 |

So the draw rule is:

```
For each layer in order SHADOW, BORDER, FACE:
    DrawImage(layer.png, penX + layer.offsetX, penY + layer.offsetY)
penX :+ FACE.advance
```

Drawing all layers at the *same* pen position with their stored negative offsets is what produces the
1-pixel outline (M) or the 3-pixel outline + 9-pixel drop shadow (L). The shadow being offset by
(−9, −9) rather than (+9, +9) means it is a **glow/outer-spread**, not a directional drop shadow - 
its canvas is 24 px larger in each dimension, i.e. 12 px of spread on every side, drawn 9 px up-left
so the extra 3 px matches the border's own expansion.

Pixel-level checks on `MatchFontM` `'A'` (verified by decoding the embedded PNGs):

- `FACE` ink occupies columns 8-33 and rows 11-36; the fully opaque pixels are `#FAFAFA`.
- `BORDER` ink occupies columns 8-35 and rows 11-38; the fully opaque pixels are `#808080`.
- Translating the border into face coordinates via its (−1, −1) offset puts border ink at columns
  7-34 / rows 10-37 - **exactly one pixel outside the face on every side.** The outline model is
  confirmed.
- The near-white face and mid-grey border mean the game **tints these images at draw time**
  (`SetColor`) rather than shipping coloured glyphs. **UNCERTAIN:** the exact tint values used for
  each on-screen context.

The PNG width is *not* simply `cellWidth`. For every glyph checked, `pngWidth = lastInkColumn + 2`,
i.e. the tool trims fully-transparent columns off the **right** edge only (left is never trimmed - 
hence `offsetX = 0`). In a few `MatchFontL` glyphs the ink spills one pixel past `cellWidth`
(e.g. `'W'`: png 105 px wide, `cellWidth` 104). Use `advance` for layout and the PNG's own dimensions
for blitting; treat `cellWidth` as advisory.

**UNCERTAIN:** the precise semantics of `cellWidth`/`cellHeight`. They behave like "the untrimmed
canvas the tool rendered into", which is `advance + padding` with a per-font padding constant. Nothing
in the draw rule above needs them, so a reconstruction can store and re-emit them without
interpreting them.

### 5.7 Reconstruction notes

- The two fonts differ only in size (49 px vs 110 px face height) and in whether they carry a
  `SHADOW` layer. `MatchFontM` has none.
- Total embedded PNG payload in `MatchFontL.fmf` is 5,302,295 bytes of the 5,404,567-byte file
  (98.1 %); the container overhead is ~102 KB of tokens and integers.
- If regenerating `.fmf` files rather than shipping the originals, the **`FACECHEK2` typo must be
  preserved** or the original loader will reject the file.
- Loading 1,632 individual PNGs at startup is slow; the original almost certainly does exactly that
  (hence the `Loading font: ` / `Font loaded` progress strings). A reconstruction may want to build a
  texture atlas instead, but must keep the metrics identical.

---

## 6. Loose data files

### 6.1 `GameMedia/Data/Horse.ini` - 3,605 bytes

Despite the extension this is **not an INI file**: no sections, no `key=value`. It is a plain
CRLF-delimited list of racehorse names, one per line, used by the horse-racing / stable mini-game.

| Property | Value |
|----------|-------|
| Encoding | ASCII |
| Line terminator | CRLF (`0D 0A`) |
| Lines | 250 (249 names + 1 trailing empty line) |
| Distinct names | 248 - `Bunch Of Fives` appears **twice** (1-based lines 40 and 51) |
| Dirty rows | `Quality Assurance` has a trailing **TAB**; `Uncle Brian ` has a trailing **space** |

First and last five entries:

```
Simon Says
Nancy Boy
Jolly Bristols
I'll Be Beck
Urgent Message
...
Cry Baby
Pointy Pete
Big Bouncer
Hungry Horace
Lemon Pie
```

> **Reconstruction note:** trim trailing whitespace when reading, or `Quality Assurance\t` will render
> with a stray tab. Keep the duplicate - removing it would change the random-draw probabilities.
> **UNCERTAIN:** whether the game reads all 250 lines (and therefore can pick an empty name from the
> trailing blank line) or stops at EOF-minus-one. A defensive reader should skip empty lines.

Related art: `GameMedia/Images/Stable/` (13 PNGs: track furniture), `Stable/Horse/` (4 × 1024 × 80
indexed sprite sheets + `Shadow.png`), `Stable/Jockey/` (6 × 1024 × 80 indexed sheets). Four horse
sprite variants × six jockey silk variants gives the visual variety for a race field.

### 6.2 `GameMedia/Data/Achievements.csv` - 701 bytes

Tab-separated, CRLF, with a header row.

> **Gotcha:** this is the **only** data file in the game that carries a **UTF-8 BOM**
> (`EF BB BF` at offset 0). Every other `.csv`, `.txt`, `.ini` and `.tac` file is BOM-less. A naive
> reader will see the first header field as `id` rather than `id`. The original BlitzMax code
> almost certainly does not strip it either - which is fine, because it only ever reads the *numeric*
> columns by index, never by header name. Reproduce the BOM if you re-emit the file.

| Column | Type | Range | Meaning |
|--------|------|-------|---------|
| `id` | int | 1 … 100 | Achievement identifier |
| `sortindex` | int | 1 … 100 | Display order |

Complete content is the identity mapping - `id` equals `sortindex` for all 100 rows:

```
id	sortindex
1	1
2	2
3	3
...
100	100
```

**The file carries no text.** The human-readable achievement names live in
`GameMedia/Languages/Languages.csv` under the tag `CACHIEVEMENT_<id>`, verified:

| Tag | English text |
|-----|--------------|
| `CACHIEVEMENT_1` | Score a club goal |
| `CACHIEVEMENT_2` | Score a club hattrick |
| `CACHIEVEMENT_3` | Score 50 club goals |
| `CACHIEVEMENT_10` | Win 15 tackles in one match |
| `CACHIEVEMENT_50` | Get 100% relationship with girlfriend |
| `CACHIEVEMENT_99` | Play for 10 seasons |
| `CACHIEVEMENT_100` | Retire after 20 seasons |

`Languages.csv` contains **166** `CACHIEVEMENT*` tags in total: 100 × `CACHIEVEMENT_<n>` plus a
further 66 × `CACHIEVEMENTMOBILE_<n>` (unlock text carried over from the mobile edition; not indexed
by `Achievements.csv`).

**The unlock *conditions* are not in any data file** - they are hard-coded, reachable from the
`CheckAchievement:` routine named in the exe's debug-label strings.
**UNCERTAIN:** why the file exists at all when both columns are the identity. Most plausible reading:
`sortindex` was intended to let the display order be changed without renumbering `id`, and was simply
never diverged. A reconstruction must still read it, because the game presumably iterates this file
to know that there are exactly 100 achievements.

### 6.3 `GameMedia/Data/Names.csv` - 239,925 bytes

The per-nation name pools used to generate NPC footballers.

| Property | Value |
|----------|-------|
| Separator | TAB |
| Line terminator | CRLF |
| Encoding | **UTF-8, no BOM** (first bytes are `39 5F 41 72` = `9_Ar`) |
| Header rows | 1 |
| Data rows | **2,900** |
| Columns | **26** - every row has exactly 26 fields, padded with empty strings |

The header names only the **even** columns; each nation occupies a **pair** of adjacent columns
(`forename`, `surname`) and the odd column's header is blank. The numeric prefix is the nation ID
(matching `Nations.csv`).

| Col | Header | Nation | Nation ID | Field | Non-empty rows |
|-----|--------|--------|-----------|-------|----------------|
| 0 | `9_Argentina` | Argentina | 9 | forename | 135 |
| 1 | *(blank)* | Argentina | 9 | surname | 157 |
| 2 | `20_Belgium` | Belgium | 20 | forename | 168 |
| 3 | *(blank)* | Belgium | 20 | surname | 150 |
| 4 | `28_Brazil` | Brazil | 28 | forename | 1,795 |
| 5 | *(blank)* | Brazil | 28 | surname | 1,722 |
| 6 | `62_England` | England | 62 | forename | 319 |
| 7 | *(blank)* | England | 62 | surname | 924 |
| 8 | `75_Germany` | Germany | 75 | forename | 232 |
| 9 | *(blank)* | Germany | 75 | surname | **2,900** |
| 10 | `71_France` | France | 71 | forename | 337 |
| 11 | *(blank)* | France | 71 | surname | 703 |
| 12 | `95_Italy` | Italy | 95 | forename | 258 |
| 13 | *(blank)* | Italy | 95 | surname | 2,416 |
| 14 | `151_Portugal` | Portugal | 151 | forename | 171 |
| 15 | *(blank)* | Portugal | 151 | surname | 493 |
| 16 | `156_Russia` | Russia (Latin) | 156 | forename | 223 |
| 17 | *(blank)* | Russia (Latin) | 156 | surname | 1,991 |
| 18 | `164_Scotland` | Scotland | 164 | forename | 93 |
| 19 | *(blank)* | Scotland | 164 | surname | 772 |
| 20 | `175_Spain` | Spain | 175 | forename | 160 |
| 21 | *(blank)* | Spain | 175 | surname | 536 |
| 22 | `193_Turkey` | Turkey | 193 | forename | 560 |
| 23 | *(blank)* | Turkey | 193 | surname | 727 |
| 24 | `156_RussiaB` | Russia (Cyrillic) | 156 | forename | 141 |
| 25 | *(blank)* | Russia (Cyrillic) | 156 | surname | 1,985 |

Notes on the layout:

- The header row is `9_Argentina\t\t20_Belgium\t\t...\t156_RussiaB\t` - 13 labels, 26 fields, and it
  ends with a trailing TAB.
- **The columns are ragged.** The row count (2,900) is dictated by the longest single column
  (`75_Germany` surnames, 2,900 entries); every other column is padded with empty fields down to that
  length. A reader must **not** assume row `n` gives a matching forename/surname pair - it must
  collect each column into its own pool and draw from them independently. Rows near the end of the
  file are almost entirely empty except column 9.
- `156_RussiaB` is a **second** pool for the same nation ID 156, holding the Cyrillic-script versions
  (`Аарон` / `Абакумов`) of what columns 16-17 hold in Latin transliteration (`Aaron` / `Abakumov`).
  The first few rows line up 1:1 between the two pairs, so `RussiaB` looks like a script variant
  rather than an independent pool.
  **UNCERTAIN:** the selection rule. Most likely the Cyrillic pool is used when a Cyrillic UI language
  is active, but `Languages.csv` ships only `en, br, pt, de, es, fr, it, pl, tr, nl` - no Russian - 
  so the Cyrillic column may be dead data in this build.
- **13 nations have name pools; the game ships 210+ nation flags.** Every other nationality must fall
  back to one of these 13. **UNCERTAIN:** the fallback mapping (probably via a per-nation "name group"
  column in `Nations.csv` - check there).

Example rows (1st and 5th data rows, tabs shown as `|`, wrapped for legibility - each is a single
26-field line in the file):

```
Agustin | Acosta | Aaron | Adam | Abel | Abel | Aaron | Abbott | Abraham | Aach | Aaron | Abelin |
Achille | Abate | Abel | Abrantes | Abagor | Abakumov | Abraham | Abbot | Aarón | Abadía |
Abdul Baqi | Abacı | Аарон | Абакумов

Anastasio | Aguirre | Alex | Beckers | Abimael | Abreu | Addison | Adamson | Adolf | Aberbach |
Abeau | Aglukark | Agnolo | Abbate | Adriano | Afonso | Abdullah | Abramov | Ally | Adamson |
Adan | Abascal | Abdul Jamil | Açık | Авдей | Абрамов
```

Last three data rows (only the Germany-surname column still has content):

```
(24 empty fields) | Zwiener | (1 empty field)
(24 empty fields) | Zwinger | (1 empty field)
(24 empty fields) | Zwirner | (1 empty field)
```

### 6.4 `GameMedia/Data/venues*.txt`

Four tiny **comma-separated** files (unlike the tab-separated `.csv` files) giving international
tournament host schedules.

Every row is `<season>,<nationId>`. The nation IDs were resolved against `GameMedia/Data/Nations.csv`
(column 0 = `id`, column 1 = `name`) - these are not guesses:

| File | Bytes | Rows | Decoded |
|------|-------|------|---------|
| `venuesWC.txt` | 34 | 5 | `4,28` → Brazil · `8,156` → Russia · `12,153` → Qatar · `16,62` → England · `20,193` → Turkey |
| `venuesEuros.txt` | 35 | 5 | `2,150` → Poland · `6,71` → France · `10,95` → Italy · `14,133` → Netherlands · `18,31` → Bulgaria |
| `venuesACoN.txt` | 27 | 4 | `2,72` → Gabon · `4,139` → Nigeria · `6,128` → Morocco · `8,174` → South Africa |
| `venuesCopa.txt` | 6 | 1 | `6,28` → Brazil |

Note these are **comma**-separated, unlike every `.csv` in the game (which are tab-separated).
Terminator is CRLF; `venuesCopa.txt` is 6 bytes = `6,28\r\n`.

Cross-check with reality strongly supports "first column = season offset from game start":
World Cup 2014 = Brazil ✓, 2018 = Russia ✓, 2022 = Qatar ✓; Euro 2012 = Poland ✓, Euro 2016 =
France ✓; Africa Cup of Nations 2012 = Gabon ✓. The World Cup entries sit on seasons ≡ 0 (mod 4) and
the Euros on seasons ≡ 2 (mod 4), i.e. the two tournaments alternate every two seasons, exactly as in
real life. The entries beyond the real-world schedule (England, Turkey, Italy, Netherlands, Bulgaria,
Nigeria, Morocco, South Africa) are the designers' invented future hosts.

**UNCERTAIN:** the epoch (which real year season 0 corresponds to - probably 2010/11, the season NSS5
shipped in), whether the first column is an absolute season index or a modulo cycle position, and what
the game does once the list is exhausted (season 24+ for the WC). Also unconfirmed: why Copa América
has only a single row.

### 6.5 `Settings/Settings.txt` - 74 bytes

Plain `key=value`, one per line, LF or CRLF, written by the game.

```
saveloc=0
debug=0
opengl=0
fullnames=0
nettimeout=5
port=0
proxy=0
```

| Key | Shipped value | Meaning (inferred) |
|-----|---------------|--------------------|
| `saveloc` | 0 | Save-game location: 0 = install folder, 1 = user AppData. **UNCERTAIN** |
| `debug` | 0 | Enables the debug overlay / the 85 debug labels found in the exe |
| `opengl` | 0 | 0 = DirectX 7 driver, 1 = OpenGL. The exe contains both `D3D7Max2D` and `gldrawtextfont.bin` strings, so both BlitzMax Max2D backends are linked in |
| `fullnames` | 0 | Show full player names vs abbreviations |
| `nettimeout` | 5 | Seconds before a network request gives up |
| `port` | 0 | 0 = default |
| `proxy` | 0 | 0 = none |

**UNCERTAIN:** all of the semantics above are inferred from key names plus corroborating exe strings;
none were traced to their read sites.

---

## 7. Files shipped by accident

These are development leftovers. They are never referenced by any string in the exe and can be
omitted from a reconstruction (list them here so nobody wastes a day reverse-engineering them):

| File | Bytes | What it is |
|------|-------|------------|
| `EngineMedia/Match/Pitch/Thumbs.db` | 30,720 | Windows Explorer thumbnail cache |
| `EngineMedia/Match/Player/Thumbs.db` | 155,136 | Windows Explorer thumbnail cache |
| `EngineMedia/Match/Pitch/Ads/AdBoard.pspimage` | 43,342 | Paint Shop Pro layered source for the ad boards |
| `EngineMedia/Match/Sounds/StopWatchBeep.ogg.sfk` | 132 | Sound Forge waveform peak cache |
| `GameMedia/Sounds/Casino/Gallop.ogg.sfk` | 372 | Sound Forge waveform peak cache |
| `steamstub.lib` | 5,394 | MinGW import library - a build-time artefact, not needed at runtime |
| `EngineMedia/Match/Pitch/StadiumTest.png` | 8,247 | 772 × 772 RGB, named `Test`; **UNCERTAIN** whether it is actually loaded |
| `GameMedia/Images/Nations/NationIm_x209.png` | 1,745 | Byte-identical to `NationIm_45.png`; the leading `x` is the usual "disabled" convention |

---

## 8. Consolidated list of open questions

Everything in this document flagged **UNCERTAIN**, gathered for tracking:

| # | Question | Where it must be resolved |
|---|----------|---------------------------|
| 1 | Is the colour key `#08846B` set globally at startup or per-`LoadImage`? | Disassembly of the image loader |
| 2 | Palette-index → kit-colour-slot mapping for the indexed `Player_*.png` sheets | Disassembly of the kit-recolour routine |
| ~~3~~ | ~~Do `AdBoard_{1,4,7}` etc. differ in pixels?~~ **RESOLVED** - pixel hashes prove only 3 distinct images (§2.3) | - |
| 4 | Selection rule between the 1× and 2× background JPEGs | Disassembly / resolution-tier logic |
| 5 | Frame layout of `Match/Ball/Ball.png` (120 × 40) | Match-engine rendering code |
| 6 | Frame layout of `Match/Pitch/Mow*.png` | Match-engine rendering code |
| 7 | `.tac` handedness: is column 0 the left or right touchline? | Screenshot of the tactics screen |
| 8 | `.tac` depth direction: is row 0 the own-goal end? | Screenshot of the tactics screen |
| 9 | `.tac` grid cell → pitch coordinate mapping | Match engine |
| 10 | What is `EngineMedia\Tactics\4-4-2.tac` (hard-coded, does not exist on disk)? | Disassembly around `Loading Tactics:` |
| 11 | Exact semantics of `.fmf` `cellWidth` / `cellHeight` | Not needed for correct rendering; low priority |
| 12 | Runtime `SetColor` tints applied to the `.fmf` `FACE` / `BORDER` / `SHADOW` layers | Match-engine HUD code |
| 13 | Are the `.fmf` fonts ever asked to draw Cyrillic (U+0400+, beyond their 639 ceiling)? | Text-drawing code |
| 14 | When is the `156_RussiaB` Cyrillic name pool selected? Is it dead data? | Name-generation code |
| 15 | Fallback mapping from the ~210 nations to the 13 available name pools | `Nations.csv` schema document |
| 16 | Why does `Achievements.csv` exist if both columns are the identity map? | Disassembly around `CheckAchievement:` |
| 17 | `venues*.txt` first column: absolute season index or cycle position? What happens past the last row? | Competition-scheduling code |
| 18 | Exact semantics of every `Settings.txt` key | Disassembly of the settings reader |
| 19 | Does the `Horse.ini` reader skip the trailing blank line? | Stable mini-game code |
| 20 | Is `StadiumTest.png` loaded, or dead art? | String/xref search in the exe |

---

*End of document 05 - Asset Catalogue and File Formats.*
