' SetUpGraphics  -- module-level Function (no Type)
' VA 0x00506A5D   436 bytes   sig (i,i,i)i
' byte-identical vs NSS5.exe (436/436, original length from Ghidra's inventory, mode=reloc,
' reloc_masked=26), verified with NSS5_NO_LEARN=1.
'
' NAME IS OURS. Module-level Functions carry no BBDebugScope record, so the original name
' is unrecoverable, exactly like module Globals (codegen-patterns 7). Two callers:
'   GameMain (0x004BCCDB)              SetUpGraphics(g_opt_screen, g_opt_window, 1)  -- boot
'   TScreen_Options.ResetScreen (0x0052110D)  SetUpGraphics(g_opt_screen, g_opt_window, 0)
' (globals_final: 0x00C5D244/0x00C5D248, named g_opt_screen/g_opt_window in the already-
' verified TOptions.LoadOptions.bmx -- ini keys "screen" [0..99] and "window" [0..1]).
'
' WHAT IT DOES (this is the point of this pass: main-loop.md listed all three of these as
' unknown before this file was read at the disassembly level with scripts/disasm.py):
'   a0 = index into g_gfxmodes (the TList of TMyGfxModes built by TOptions.SetUp -- each
'        element just an int width/height pair, .w/.h, sorted ascending). This is the
'        selected resolution.
'   a1 = 0 -> Graphics(mode.w, mode.h, 32, 60, 0)   depth=32   -- FULLSCREEN
'        1 -> Graphics(mode.w, mode.h,  0, 60, 0)   depth=0    -- WINDOWED (BRL semantics:
'             depth=0 opens a window at the desktop's current depth; nonzero depth forces
'             fullscreen -- brl.mod/graphics.mod/graphics.bmx, Function Graphics()).
'             Confirmed by the caller side too: TScreen_Options.ButtonWindow sets this same
'             Global to 1 for gadget "options_reswindow" and 0 for "options_resfull".
'        anything else -> Graphics() is not called at all for this iteration.
'   a2 = boot-splash flag. GameMain passes 1 (draw it once at startup); ResetScreen (the
'        options-screen "apply resolution" path) passes 0 (never redraws it later).
'
'   RESOLUTION FALLBACK: after picking the mode (or skipping Graphics() if a1 was neither
'   0 nor 1), the chosen w/h is always written to g_engine_int162/g_engine_int163 (the
'   screen-width/height Globals read all over the corpus, e.g. TScreen.UpdateOffset.bmx).
'   If EITHER dimension is below 800x600, it is an unsupported/too-small mode: the game
'   logs "SetVirtualResolution(800, 600)" (LogLine -- the literal is read verbatim out of
'   NSS5.exe with harness.read_string, not guessed), forces the Globals back to 800x600,
'   and calls SetVirtualResolution(800.0, 600.0) so the game's 2D drawing coordinate space
'   stays 800x600 regardless of what the real display negotiated. This is the game's
'   fixed design resolution (TScreen.UpdateOffset's g_screen_int21/22 = 800/600).
'
'   Then unconditionally: SetBlend(3) (ALPHABLEND), SetColor(255,255,255), SetAlpha(1.0),
'   HideMouse(), TScreen.UpdateOffset() (recomputes the letterbox offset for the new
'   screen size), GCCollect().
'
'   Finally, only if a2 is true: draws the boot splash text "New Star Games 2019"
'   (literal read out of NSS5.exe) centred at x = g_engine_int162/2 - 70,
'   y = g_engine_int163 - 60, then Flip(-1) to present it. This is the very first thing
'   ever drawn to the screen, one frame before the language-picker screen takes over.
'
' ASSUMPTIONS
'  * g_gfxmodes:TList (0x00C60500) -- same Global as TOptions.SetUp/FindRes800600/LoadOptions,
'    holding TMyGfxModes objects (fields .w/.h at +8/+0xC, TMyGfxModes.Create.bmx).
'  * g_engine_int162:Int / g_engine_int163:Int (0x00C6EFE4/0x00C6EFE8) -- screen width/height,
'    same Globals and same names as TScreen.UpdateOffset.bmx.
'  * 0x005B1523 = _brl_graphics_Graphics (brl_functions_inferred.tsv). Default flags=0
'    confirmed against brl.mod/graphics.mod/graphics.bmx's own declaration.
'  * 0x00505B91 = LogLine, already-verified module Function (src/recovered_module).
'  * 0x005ADCFD = _brl_max2d_SetVirtualResolution, 0x005ADBEF = _brl_max2d_SetBlend,
'    0x005ADB6F = _brl_max2d_SetColor, 0x005ADC28 = _brl_max2d_SetAlpha,
'    0x005B4C4A = _brl_system_HideMouse, 0x005AD656 = _brl_max2d_DrawText,
'    0x005B141A = _brl_graphics_Flip (all extracted/brl_functions.tsv).
'  * 0x00C61C80 -> class table TScreen + 0x54 = TScreen.UpdateOffset()i (KIND=Function,
'    vtable_map.tsv), called the same statically-initialised-slot way as every boot call
'    documented in docs/game/engine/main-loop.md -- confirms that pattern generalises past
'    the eight calls already named there.
'  * 0x004A8980 = _bbGCCollect (runtime_helpers.tsv) -> GCCollect().
'  * String literals read verbatim with harness.read_string: 0x00C7BBDC =
'    "SetVirtualResolution(800, 600)", 0x00C7BC24 = "New Star Games 2019".
'
' CODEGEN NOTES
'  * The list walk is a plain `For ... EachIn g_gfxmodes` with a hand-kept counter `i`
'    incremented once per NON-NULL element (the EachIn idiom's own null-skip also skips
'    the increment for a failed downcast, codegen-patterns 10.6) -- not `i` from the loop
'    itself, since the original clearly maintains it as an ordinary Local (`add esi,1` at
'    a fixed point in the body, not part of the enumerator machinery).
'  * The a1 dispatch is a `Select a1 / Case 0 / Case 1 / End Select` with NO Default, not
'    an If/ElseIf -- codegen-patterns 10.2. Measured directly: the If/ElseIf spelling
'    (`mov eax,[a1] / cmp/jne / block0 / jmp-common / cmp/jne / block1`, falling through at
'    the end since block1 is last) came out 432/436, exactly 4 bytes short. `Select`'s shape
'    is different in a way that matters here even with no Default: it evaluates once, tests
'    BOTH cases back-to-back BEFORE either body (`cmp/je`, `cmp/je`, `jmp` no-match), and
'    gives EVERY Case body -- including the last one -- its OWN trailing `jmp` to the shared
'    exit (here, the statement after `End Select`) rather than letting the last body fall
'    through. That is where the 4 bytes are: 2 from the extra explicit no-match `jmp` the
'    dispatch block gets instead of relying on the second test's own fall-through, and 2
'    from Case 1's own trailing `jmp` that an If/ElseIf's last arm never emits.
'  * `If w < 800 Or h < 600` is the short-circuit Or form (setl/movzx, conditional skip of
'    the second test) -- codegen-patterns 3f.
'  * `If a2` is a bare Int truth test (`cmp dword [ebp+0x10],0 / je`), not `a2 <> 0`.
'  * width/2 in the splash-text x position is signed integer division by 2, emitted as the
'    standard cdq/and-1/add/sar rounding-adjusted shift, i.e. plain `w / 2` on Ints.
	Function SetUpGraphics:Int(a0:Int, a1:Int, a2:Int)
		'!Global g_gfxmodes:TList
		'!Global g_engine_int162:Int
		'!Global g_engine_int163:Int
		Local i:Int = 0
		For Local mode:TMyGfxModes = EachIn g_gfxmodes
			If i = a0
				Select a1
					Case 0
						Graphics(mode.w, mode.h, 32, 60, 0)
					Case 1
						Graphics(mode.w, mode.h, 0, 60, 0)
				End Select
				g_engine_int162 = mode.w
				g_engine_int163 = mode.h
				If g_engine_int162 < 800 Or g_engine_int163 < 600
					LogLine("SetVirtualResolution(800, 600)")
					g_engine_int162 = 800
					g_engine_int163 = 600
					SetVirtualResolution(800.0, 600.0)
				EndIf
			EndIf
			i :+ 1
		Next
		SetBlend(3)
		SetColor(255, 255, 255)
		SetAlpha(1.0)
		HideMouse()
		TScreen.UpdateOffset()
		GCCollect()
		If a2
			DrawText("New Star Games 2019", g_engine_int162 / 2 - 70, g_engine_int163 - 60)
			Flip(-1)
		EndIf
	End Function
