' TEngine.RenderReplayGUI
' VA 0x004D5410   153 bytes   vtable slot 0xB4   sig ()i
' byte-identical vs NSS5.exe (153/153, original length from Ghidra's inventory, mode=reloc)
' assumptions: Globals 0x00C6EFD4 Int (a millisecond timer -- globals_final.tsv lists it as
' TScreen with a flagged construction-site CONFLICT, but it is used here as the left operand
' of Mod, so it is an Int; cf. codegen-patterns 10.7), 0x00C6EFE4/0x00C6EFE8 Int (graphics
' width/height), 0x00C5B2D0 Int (controls-overlay flag).
' PTR_FUN_00C5BB34 resolves to TEngine class table + slot 0x104 = TEngine.DrawMyText
' ($,f,f,i,i,f,f,$,i)i -- same Type. It was VERIFIED with the explicit TEngine. prefix
' (the probe compiles the body as a module Function); inside Type TEngine the bare name
' emits the same static call.
' PTR_FUN_00C6DE90 resolves to TPanel_Controls class table + slot 0x38 =
' TPanel_Controls.RenderReplay(i,i) -- different Type, so prefixed.
' 0x004A7410 is _brl_retro_Lower; 0x004C5549 is the recovered module Function GetText.
' "Replay" / "FFFFFF" read out of .rdata at 0x00C70E90 / 0x00C5D680.
' CASE DIRECTION CORRECTED 2026-08-22: 1 call site -> .ToUpper().
' extracted/runtime_helpers.tsv named 0x004A7410 `_brl_retro_Lower` and 0x004A74E0
' `_brl_retro_Upper`. Both were wrong and neither address is a brl.retro wrapper:
' 0x004A7410 is `_bbStringToUpper` and 0x004A74E0 is `_bbStringToLower`. NSS5.exe's
' own 21-byte retro wrappers at 0x0059C8FD (Lower) and 0x0059C912 (Upper) CALL those
' two addresses, and a wrapper cannot be the function it calls. The wrong row masked
' by name, so this body certified with the case conversion running backwards. Full
' derivation and the discriminating 3x4 matrix: docs/reference/codegen-patterns.md
' 15.6. Re-verified under NSS5_NO_LEARN=1 on worker trees 380 and 380b.
	Function RenderReplayGUI:Int()
		'!Global g_engine_replaytimer:Int
		'!Global g_engine_gfxw:Int
		'!Global g_engine_showcontrols:Int
		'!Global g_engine_gfxh:Int
		If g_engine_replaytimer Mod 2000 < 1000
			TEngine.DrawMyText(GetText("Replay").ToUpper(), g_engine_gfxw-20, 0, 2, 0, 0.5, 1.0, "FFFFFF", 1)
		EndIf
		If g_engine_showcontrols <> 0
			TPanel_Controls.RenderReplay(g_engine_gfxw-154, g_engine_gfxh-214)
		EndIf
	End Function
