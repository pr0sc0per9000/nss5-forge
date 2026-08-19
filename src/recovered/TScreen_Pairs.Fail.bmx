' Every string literal in this file was read out of NSS5.exe with
' harness.read_string and checked against the address the ORIGINAL pushes at the
' same code offset. The oracle masks a literal's ADDRESS, so a MATCH on its own does
' not certify the text -- see docs/reference/codegen-patterns.md 13.2.
' TScreen_Pairs.Fail
' VA 0x005797C8   122 bytes   vtable slot 0x58   sig ()i
' byte-identical vs NSS5.exe (122/122, original length from Ghidra's inventory, mode=reloc)
' module Globals assumed (names ours, types load-bearing):
'   0x00C6B850 : TSound        0x00C6F090 : TChannel   (PlaySound's two arguments)
'   0x00C5B1C8 : TBitmapFont   (globals_final: construction-typed, confidence medium)
'   0x00C6EFE4 : Int           0x00C6EFE8 : Int        (screen width / height; the
'                `cdq / and edx,1 / add / sar 1` sequence is Int division by 2)
' resolved call targets:
'   0x0059B25E = _brl_audio_PlaySound
'   0x004C5549 = the recovered module Function GetText
'   PTR_FUN_00C6B264 = TScreenMessage classtable(0x00C6B234) + 0x30
'                      -> TScreenMessage.Create (i,i,$,i,:TBitmapFont,:TImage,f,$)i
'                      Ghidra splits this call's argument list across the GetText call;
'                      the pushes 0x3E8 / font / Null / 1.0 / "" are Create's, not GetText's.
'   PTR_FUN_00C66D04 = TScreen_Relationships classtable(0x00C66CD0) + 0x34 -> SetUpScreen(i)i
' Literal TEXT is unrecoverable (addresses only, relocation-masked).
' HARNESS NOTE: needs harness.MODULE_TYPES patched with TSound/TChannel -> BRL.Audio,
'   otherwise the local placeholder Types shadow BRL's and the probe will not build.

	Function Fail:Int()
		'!Global g_sound_fail:TSound
		'!Global g_channel_sfx:TChannel
		'!Global g_font_main:TBitmapFont
		'!Global g_screen_w:Int
		'!Global g_screen_h:Int
		PlaySound(g_sound_fail, g_channel_sfx)
		TScreenMessage.Create(g_screen_w / 2, g_screen_h / 2, GetText("Fail!"), 1000, g_font_main, Null, 1.0, "FFFFFF")
		TScreen_Relationships.SetUpScreen(1)
	End Function
