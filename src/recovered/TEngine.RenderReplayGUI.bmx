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
	Function RenderReplayGUI:Int()
		'!Global g_engine_replaytimer:Int
		'!Global g_engine_gfxw:Int
		'!Global g_engine_showcontrols:Int
		'!Global g_engine_gfxh:Int
		If g_engine_replaytimer Mod 2000 < 1000
			TEngine.DrawMyText(Lower(GetText("Replay")), g_engine_gfxw-20, 0, 2, 0, 0.5, 1.0, "FFFFFF", 1)
		EndIf
		If g_engine_showcontrols <> 0
			TPanel_Controls.RenderReplay(g_engine_gfxw-154, g_engine_gfxh-214)
		EndIf
	End Function
