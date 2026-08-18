' TScreen_Options.ButtonWindow
' VA 0x00521081   140 bytes   vtable slot 0x58   sig ()i
' byte-identical vs NSS5.exe (140/140, original length from Ghidra's inventory), harness mode=reloc
' Assumptions:
'   * 0x00C621CC -> class table TGadget + 0x7C = TGadget.GetActiveGadgetName()$
'   * 0x00C61CC0 -> TScreen + 0x94 = TScreen.DoMessage($,i,i)i
'   * 0x00C64064 -> TScreen_Options + 0x38 = TScreen_Options.RefreshButtons()i
'   * 0x00C5D248 : Int, 0x00C63D08 : Int (module Globals, names ours)
'   * literals 0x00C7F14C='options_reswindow', 0x00C7F1B0='options_resfull',
'     0x00C8065C='CMESSAGE_CHANGERESOLUTION'.
' SHAPE (measured): the first construct is a Select on the String, not If/ElseIf -- the
'   subject is evaluated once into EBX and each Case is `bbStringCompare / cmp eax,0 / je
'   body` with a trailing `jmp end`. The If/ElseIf spelling is 136 bytes.
	'!Global g_opt_res:Int
	'!Global g_opt_msgshown:Int
	Function ButtonWindow:Int()
		Select TGadget.GetActiveGadgetName()
			Case "options_reswindow"
				g_opt_res = 1
			Case "options_resfull"
				g_opt_res = 0
		End Select
		If g_opt_msgshown = 0
			TScreen.DoMessage(GetText("CMESSAGE_CHANGERESOLUTION"), 0, 0)
			g_opt_msgshown = 1
		EndIf
		TScreen_Options.RefreshButtons()
	End Function
