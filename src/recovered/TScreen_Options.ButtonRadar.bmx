' TScreen_Options.ButtonRadar
' VA 0x00520daa   125 bytes   vtable slot 0x44   sig ()i
' byte-identical vs NSS5.exe (125/125, original length from Ghidra's inventory)
' harness mode=reloc.
' This is a SELECT, not an If/ElseIf chain: all three bbStringCompare tests are emitted
'   first and the three bodies follow after them, each ending in jmp END. An If/ElseIf
'   chain comes out at 121 bytes.
' PTR_FUN_00c621cc = TGadget classtable + 0x7c = TGadget.GetActiveGadgetName()$
' PTR_FUN_00c64064 = TScreen_Options classtable + 0x38 = TScreen_Options.RefreshButtons()
' string constants: 0x00c7fd00 "options_radaroff", 0x00c7fd44 "options_radarsmall",
'   0x00c7fd8c "options_radarlarge"
' module Globals assumed by this body (names ours, types load-bearing):
'   Global g_options_int02:Int     ' 0x00c5d22c
	Function ButtonRadar:Int()
		'!Global g_options_int02:Int
		Local s:String = TGadget.GetActiveGadgetName()
		Select s
		Case "options_radaroff"
			g_options_int02 = 0
		Case "options_radarsmall"
			g_options_int02 = 1
		Case "options_radarlarge"
			g_options_int02 = 2
		End Select
		TScreen_Options.RefreshButtons()
	End Function
