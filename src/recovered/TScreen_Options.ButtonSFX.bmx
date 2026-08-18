' TScreen_Options.ButtonSFX
' VA 0x00520FFD   132 bytes   vtable slot 0x54   sig ()i
' byte-identical vs NSS5.exe (132/132, original length from Ghidra's inventory)
' Byte-for-byte twin of TScreen_Options.ButtonMusic (0x00520F79, also 132 bytes) with a
'   different Global and different literals -- SELECT, not If/ElseIf (codegen-patterns 10.2).
' PTR_FUN_00c621cc = TGadget classtable + 0x7c = TGadget.GetActiveGadgetName()$
' PTR_FUN_00c64064 = TScreen_Options classtable + 0x38 = TScreen_Options.RefreshButtons()
' 0x004bc88c = UpdateAudio (src/recovered_module/UpdateAudio.bmx)
' string literals read out of NSS5.exe with harness.read_string:
'   0x00c7f558 "options_sfxoff"  0x00c7f580 "options_sfxlow"  0x00c7f5a8 "options_sfxhigh"
' float constants read out of NSS5.exe: 0x00c80654 = 50.0, 0x00c80658 = 100.0 (0.0 is fldz)
' module Globals assumed by this body (names ours, types load-bearing):
'   Global g_options_sfxvol:Float   ' 0x00c5d220
	Function ButtonSFX:Int()
		'!Global g_options_sfxvol:Float = 100.0
		Local s:String = TGadget.GetActiveGadgetName()
		Select s
		Case "options_sfxoff"
			g_options_sfxvol = 0.0
		Case "options_sfxlow"
			g_options_sfxvol = 50.0
		Case "options_sfxhigh"
			g_options_sfxvol = 100.0
		End Select
		UpdateAudio()
		TScreen_Options.RefreshButtons()
	End Function
