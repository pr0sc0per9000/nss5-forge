' TScreen_Options.ButtonMusic
' VA 0x00520f79   132 bytes   vtable slot 0x50   sig ()i
' byte-identical vs NSS5.exe (132/132, original length from Ghidra's inventory)
' SELECT, not If/ElseIf -- the three _bbStringCompare tests are emitted back to back and
'   the three bodies follow after them (codegen-patterns 10.2). Same shape as ButtonRadar.
' PTR_FUN_00c621cc = TGadget classtable + 0x7c = TGadget.GetActiveGadgetName()$
' PTR_FUN_00c64064 = TScreen_Options classtable + 0x38 = TScreen_Options.RefreshButtons()
' 0x004bc88c = UpdateAudio (src/recovered_module/UpdateAudio.bmx)
' string literals read out of NSS5.exe with harness.read_string:
'   0x00c7f44c "options_musicoff"  0x00c7f498 "options_musiclow"  0x00c7f4e8 "options_musichigh"
' float constants read out of NSS5.exe: 0x00c8064c = 50.0, 0x00c80650 = 100.0 (0.0 is fldz)
' module Globals assumed by this body (names ours, types load-bearing):
'   Global g_options_musicvol:Float   ' 0x00c5d224
	Function ButtonMusic:Int()
		'!Global g_options_musicvol:Float
		Local s:String = TGadget.GetActiveGadgetName()
		Select s
		Case "options_musicoff"
			g_options_musicvol = 0.0
		Case "options_musiclow"
			g_options_musicvol = 50.0
		Case "options_musichigh"
			g_options_musicvol = 100.0
		End Select
		UpdateAudio()
		TScreen_Options.RefreshButtons()
	End Function
