# From launch to first kick - the program's spine

> **Source:** `GameMain` @ 0x004bccdb (VERIFIED) · `SteamInit` @ 0x0058d86d (VERIFIED) · `TLocale.SetUp` @ 0x004c558f (VERIFIED) · `TOptions.SetUp` @ 0x004e27cb (VERIFIED) · `SetUpGraphics` @ 0x00506a5d (VERIFIED) · `StartMusic` @ 0x004bc874 (VERIFIED) · `PlayTrack` @ 0x004bcb98 (VERIFIED) · `TScreen.SetUp` @ 0x00510174 (VERIFIED) · `TEngine.SetUp` @ 0x004cd9c3 (VERIFIED) · `TScreen_Language.CreateScreen` @ 0x0051bc09 (VERIFIED) · `TScreen_Language.SetUpScreen` @ 0x0051bf6c (VERIFIED) · `TScreen.Update` @ 0x00511237 (VERIFIED) · `TScreen.Render` @ 0x00510dc5 (VERIFIED) · `TEngine.MatchLoop` @ 0x004cf671 (VERIFIED) · `ModuleBody` @ 0x004ba034 (READ)
> **Confidence:** HIGH
> **Last checked:** 2026-08-15

This is the one function everything else hangs off. Every other function in the game is
something this calls, directly or indirectly. Until now the project had it as raw bytes with
no source and no account of what it did - the "parts inventory with no assembly diagram"
problem. This is the diagram.

*Names marked "ours" are inventions: module-level code carries no reflection record, so the
original names are unrecoverable. The addresses are exact.*

## The whole thing

```
GameMain()                                    ; 0x004BCCDB, 484 bytes
    SteamInit()                               ; ours -- 0x0058D86D
    TLocale.SetUp()                           ; load Languages.csv
    TOptions.SetUp()                          ; load/create Settings/Options.ini, video modes
    SetUpGraphics(width, height, 1)           ; ours -- 0x00506A5D
    StartMusic()                              ; ours -- calls PlayTrack(1)
    TScreen.SetUp()
    TEngine.SetUp()
    TScreen_Language.CreateScreen()
    TScreen_Language.SetUpScreen(0)           ; <- the FIRST screen the player sees

    startTime = MilliSecs()
    lastFrame = MilliSecs() - startTime
    accumulator = 0                        ; * see "Before GameMain even starts" below --
                                            ;   unverified evidence says this may really be 25

    Repeat forever
        now          = MilliSecs() - startTime
        accumulator += now - lastFrame
        lastFrame    = now

        While accumulator >= 25                ; catch up on missed logic ticks
            TScreen.Update()
            accumulator -= 25
        Wend

        TScreen.Render(accumulator / 25.0)     ; draw once, interpolated

        If debugMode = 2 Then <draw the debug overlay>
    Forever
```

## The number that matters most: 25

**The game logic runs at a fixed 40 ticks per second.** The timestep lives at `0xC6F02C`,
is statically initialised to **25** milliseconds, and nothing ever writes to it - it is a
constant in all but name.

This is a textbook fixed-timestep loop with interpolated rendering, and it has three
consequences worth being explicit about, because a reimplementation that misses them will
feel wrong in ways that are very hard to trace back:

1. **Every physics and gameplay constant in this game is calibrated to a 25 ms tick.** Ball
   speeds, player acceleration, timers, animation counters - all of them are "per tick", not
   "per second" and not "per frame". Run the same numbers at 60 Hz and the whole game plays
   40% faster.
2. **Rendering is decoupled from logic.** `TScreen.Render` is called once per display frame
   and receives a fraction between 0 and 1 saying how far the world is between the last
   logic tick and the next one. Drawing at 144 fps does not make the game run faster; it
   makes it smoother.
3. **The loop catches up.** If the machine stalls, `TScreen.Update` runs several times in a
   row before the next draw. Logic never runs slow, it only ever runs *late*. There is no
   upper bound on the catch-up loop, which is the classic "spiral of death" shape - on a
   machine too slow to sustain 40 Hz it would keep falling further behind. Worth putting a
   cap on in any rebuild; the original has none.

## The startup order, and why each step is load-bearing

Everything here happens **before the player sees anything**, in exactly this order.

| # | Step | What it does | If it fails |
|---|---|---|---|
| 1 | `SteamInit` | `OpenSteam(212780)` - the game's Steam AppID - and stores the result at `0xC6F3B8` | **Returns −1 → error dialog, log line, and the process exits.** The game will not start without Steam |
| 2 | `TLocale.SetUp` | Reads `GameMedia/Languages/Languages.csv`, builds the tag→text table | Hard exit. There is **no English fallback**; the file is mandatory |
| 3 | `TOptions.SetUp` | Enumerates video modes; creates `Settings/Options.ini` if absent | Error and terminate - a read-only install directory kills the game before the menu |
| 4 | `SetUpGraphics` | Picks the saved resolution out of the video-mode list, opens the window/display, and draws the "New Star Games 2019" boot splash | - |
| 5 | `StartMusic` | `PlayTrack(1)` - the menu music, one of the six OGGs embedded in the exe | - |
| 6 | `TScreen.SetUp` | Initialises the screen system | - |
| 7 | `TEngine.SetUp` | Initialises the match engine (3,032 bytes) - this runs at boot, not at kickoff | - |
| 8 | `TScreen_Language.CreateScreen` | Builds the language-picker screen | - |
| 9 | `TScreen_Language.SetUpScreen(0)` | **Shows it. This is the first screen in the game.** | - |

Two things here answer questions the project had open. The UI documentation listed "which
screen loads first" as unknown - it is the **language picker**, entered with argument 0. And
the match engine is set up *at boot*, not when a match starts.

The Steam dependency is the sharpest finding for a rebuild: **the retail game hard-exits if
Steam is unavailable.** A reimplementation should simply drop step 1, which also disposes of
the dead leaderboard call at the end of every save.

## The debug overlay

When the global at `0xC6EF50` (named `g_engine_int161` elsewhere in the corpus, e.g.
`TScreen_Leagues.ComboNation`) equals **2**, the loop draws a diagnostic overlay every frame,
before the flip, three lines of text at x=5 stepping down the screen by 10 pixels a line:

1. `y=5` - the GC's currently-allocated memory (`GCMemAlloced()`), run through `FormatMoney`
   so it prints with the game's normal currency grouping/formatting rather than a raw number.
2. `y=15` - the joypad's X axis (`JoyX(0)`), printed as a plain number.
3. `y=25` - the joypad's Y axis (`JoyY(0)`), likewise.

It also wires a developer hotkey, checked once per frame in the same block: holding **Left
Ctrl** and pressing **S** prints `"Value=" + <the current profile's contract value>` to the
game's log/console (`TProfile.GetValue()`). This is a separate hotkey from the "Simon Read"
name-gated ones mentioned below - it works for anyone once the overlay itself is on.

It is live code in the retail build, not stripped. Whatever sets `0xC6EF50` to 2 is a separate
question - see below.

## How the boot calls are spelled in source

The eight boot-sequence calls above are emitted as `call dword ptr [abs]`, not `call rel32`
 - e.g. `TScreen_Language.CreateScreen` is reached via `call dword ptr [0xC63980]`. This
looked like it might mean a module-level Global of function-pointer type, initialised
statically. It is not that: `CreateAllScreens` (@ 0x0051b986, VERIFIED - see
`docs/game/ui/screen-flow.md` §1.7), a 595-byte module Function that makes 53 structurally
identical calls of exactly this shape, settles it. Every one of those addresses sits inside
a *Type's class table* (`classtable_va + slot`, confirmed against
`extracted/class_tables.tsv` + `extracted/vtable_map.tsv`), and ordinary source for a static
cross-Type Function call - `TScreen_Language.CreateScreen()`, no different from calling a
static Function declared on your own Type (`docs/reference/codegen-patterns.md` 3d) - 
compiles to exactly this indirect call. The oracle already masks it on Type+slot identity
(codegen-patterns.md section 1, row 2), independent of whether the callee's own body is
separately verified. No Global, no new pragma: **confirmed directly on `GameMain` itself** - 
all eight of its listed boot/loop calls resolve to a Type's class table this way
(`TLocale`/`TOptions`/`TScreen`/`TEngine`/`TScreen_Language`, slots `0x30`/`0x34`/`0x68`/
`0x78`), and the whole 484-byte function matched on the first compile once written as plain
static calls (`src/recovered_module/GameMain.bmx`, mode=reloc, 484/484).

## How the display actually gets opened, and the 800x600 floor

`SetUpGraphics` (0x00506A5D, 436 bytes, `src/recovered_module/SetUpGraphics.bmx`,
byte-verified) is called twice: once from `GameMain` at boot with a third argument of `1`,
and once from `TScreen_Options.ResetScreen` (0x0052110D) - the options-screen "apply
resolution" path - with a third argument of `0`. Both calls pass the same two Globals,
`0xC5D244`/`0xC5D248`, which `TOptions.LoadOptions` (already verified) fills from the
**`screen`** and **`window`** keys of `Settings/Options.ini` (clamped `[0,99]` and `[0,1]`
respectively when read, and re-clamped against the mode count if `screen` is out of range).

* **`screen`** is an index into a sorted list of available resolutions (`TOptions.SetUp`
  builds this list at boot from `GraphicsModes()`, keeping only modes at least 600 px tall,
  or all of them if none qualify).
* **`window`** picks fullscreen vs windowed for that resolution: **0 = fullscreen** (opened
  at 32-bit colour depth), **1 = windowed** (opened at depth 0, which BlitzMax's `Graphics()`
  treats as "use the desktop's current depth" - passing any nonzero depth is what forces
  fullscreen). `TScreen_Options.ButtonWindow` confirms the mapping from the UI side: the
  "options_reswindow" gadget sets this Global to 1, "options_resfull" sets it to 0.

**The 800x600 floor.** Whatever resolution comes out of that (or even if neither 0 nor 1 was
passed and `Graphics()` was never called at all - the width/height Globals still get updated
from the picked mode), if either dimension is below 800x600 the game logs
`"SetVirtualResolution(800, 600)"`, forces its internal screen-size Globals back up to
800x600, and calls `SetVirtualResolution(800.0, 600.0)`. That keeps every 2D draw call's
coordinate space pinned at the game's fixed 800x600 design resolution regardless of what the
real display negotiated - this is the same 800x600 that `TScreen.UpdateOffset` centres the
letterboxed viewport against.

**The boot splash.** Only when the third argument is true (i.e. only from `GameMain`, never
from `ResetScreen`) does `SetUpGraphics` also draw the text "New Star Games 2019" - read
verbatim out of the exe, not a guess - centred on the freshly-opened screen and `Flip(-1)`
it to the display. This is the literal first pixel the game ever draws, one frame before the
language-picker screen (step 9 above) takes over.

Every call to `SetUpGraphics` also does a few housekeeping things unconditionally, regardless
of resolution or fullscreen/windowed: it turns on alpha blending, resets the draw colour to
plain white at full opacity, hides the mouse cursor, asks the screen system to recompute its
letterbox offset for the new size, and runs a garbage-collection pass. None of that is
resolution-specific - it is generic "the display just (re)opened" cleanup.

## Before GameMain even starts

`GameMain` is not the very first code the game runs. It is called from the tail end of a much
bigger block - the module's own start-up code, which BlitzMax runs once, automatically, before
any of the game's own functions are reachable at all. Most of that block is mechanical
housekeeping (registering the game's 135 Types and unpacking data baked into the .exe); the
last 2,384 bytes of it are genuine hand-written start-up logic, and all of it has been read
step by step.

**Treat this section as read-but-not-proven.** Every step below was worked out by reading the
disassembly directly and cross-checking call targets against known code, but there is currently
no tool that can run a slice of top-level start-up code through the byte-for-byte checker the
way a single function can be checked.
So none of it can be marked VERIFIED yet, unlike everything above this section.

In order:

1. **The save folder is created.** The game reads a `saveloc` setting out of
   `Settings/Settings.txt` - in the game's own install folder, not the save folder - for where
   to put player data. If that setting is missing or too short to be a real path, it falls back
   to `<the current working directory>/New Star Soccer 5/`. Either way, it then creates four
   folders if they don't already exist: the save folder itself, plus `Settings/`, `Save/`, and
   `Replays/` inside it.
2. **A call whose result is thrown away.** Something is run through a "replace spaces with
   `%20`" call (URL-encoding), and the result is never used anywhere afterwards. This might be
   dead code left over from a removed feature, or it might store its result somewhere this
   reading did not catch. Genuinely unresolved - flagged rather than guessed.
3. **Five more settings are read** from the same `Settings.txt`: `debug` (clamped to 0-2),
   `fullnames` (0-1), `nettimeout` (3-99), `port` (0-100,000,000), and `proxy` (free text, no
   limit). Worth knowing if this file ever needs a new setting added the same way: a *missing*
   key does not get a sensible default of its own - it reads as 0 and then gets forced up into
   the allowed range. So a missing `nettimeout` silently becomes `3`, the bottom of its range,
   not a number chosen to mean "not set".
4. **Boot bookkeeping.** The current time is recorded (the same "boot time" referenced
   elsewhere in this document), the random number generator is seeded from it, and the number
   of connected joysticks is counted and stored.
5. **The debug log file.** If `debug` (just read above) is nonzero, `log.txt` is opened for
   writing in the install folder. It is only closed right at the very end of this start-up
   code - which in practice means it stays open for the whole session, because `GameMain`'s
   loop never returns during normal play.
6. **A spare player profile is allocated** and kept in a Global. Nothing in this stretch of
   code uses it yet; it is almost certainly a scratch object for negotiating contract offers
   later on.
7. **A possible correction to the accumulator story above - unverified, flagged not asserted.**
   The timing accumulator (the same Global the fixed-timestep section calls `accumulator`)
   appears to be set, once, to the value of the 25 ms timestep itself, not to zero. If that
   reading holds up, the very first pass through `GameMain`'s loop runs one full logic update
   *before* it ever draws a frame, instead of drawing first and catching up from nothing. It
   would not change anything about how the loop behaves afterwards - it only affects the first
   few milliseconds of a session. Worth checking against a running copy of the game before
   relying on it.
8. **The graphics driver is chosen.** The active driver's name is written to the log, then the
   game checks an `opengl` setting from the same `Settings.txt`. If it is `1`, OpenGL is
   selected directly. Otherwise the game tries Direct3D 9 first and only falls back to the
   older Direct3D 7 if that fails to start up - a "best available" cascade, not a fixed choice.
9. **Sound and images are pre-loaded.** Three audio channels are allocated up front, two sound
   effects (a cash sound and an achievement sound) and eleven UI images (arrow icons, a refresh
   icon, tick/cross icons, a help icon, and a couple of message-box background images) are
   loaded before anything else happens, and a colour-key transparency mask is set.
10. **Finally, `GameMain()` is called.** This is the function the rest of this document is
    about. Under normal play it never returns - the last two lines of the module's own
    start-up code (closing the debug log if one was opened) only run if `GameMain`'s infinite
    loop is somehow broken out of, which does not happen in the retail game.

## What we do not know yet

* **What sets `0xC6EF50` to 2** - the debug-overlay trigger. There is a known developer
  name-check elsewhere in the game (two hotkeys that only work if the player is named
  "Simon Read"), so this may be gated the same way. Not answered.
* **The module body's 2,384-byte start-up program is now read, but not yet byte-verified.**
  The "Before GameMain even starts" section above accounts for every statement in it, but
  there is still no tool that can check a slice of
  top-level start-up code against the original exe the way a single function can be checked, so
  none of it carries the same certainty as the rest of this document. Two specific details inside it remain genuinely open even at
  this read-only level: what the discarded "replace spaces with `%20`" call (step 2 above) was
  for, and whether the accumulator really does start at 25 instead of 0 (step 7 above).
* **There is no cap on the catch-up loop** - stated above as a fact about the original; what
  the original actually does on a machine that cannot sustain 40 Hz has never been observed,
  only reasoned about.

## Worth preserving exactly

The accumulator is integer milliseconds, and the interpolation fraction is computed as
`accumulator / 25` in **floating point after the loop has already subtracted** - so it is
always in `[0, 1)`. Rewriting the loop to use floating-point seconds throughout is the
obvious "cleanup" and it will change behaviour: integer millisecond accumulation quietly
drops sub-millisecond remainder every frame, and the game's feel is calibrated against that
drift. Copy the integer arithmetic deliberately.

One more thing worth flagging rather than nailing down: unverified reading of the module's own
start-up code (see "Before GameMain even starts" above) suggests the accumulator's very first
value might be 25, not 0 - i.e. the game may take one logic step before it draws its first ever
frame. If a rebuild's very first frame looks one tick ahead of the original, or vice versa, this
is the likely explanation, not necessarily a bug in the rebuild.

*Jargon note: a "tick" is one step of the game's logic - the world moving forward by one
25 ms slice. A "frame" is one picture drawn on screen. This game separates the two: it
always takes 25 ms steps no matter how fast or slow your computer draws pictures.*
