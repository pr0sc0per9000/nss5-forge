' TScreen_Options.ButtonMatchSpeed
' VA 0x00520efc   125 bytes   vtable slot 0x4c   sig ()i
' byte-identical vs NSS5.exe (125/125, original length from Ghidra's inventory, mode=reloc)
' Assumptions: Global 0x00C5D234 declared Int (match-speed frame budget);
'   0x00C621CC = TGadget class table + 0x7C = TGadget.GetActiveGadgetName():$;
'   0x00C64064 = TScreen_Options class table + 0x38 = sibling Function RefreshButtons().
'   Select (not If/ElseIf): the ElseIf form is 121 bytes, 4 short -- see codegen-patterns 10.2.
'!Global g_options_matchspeed:Int
	Function ButtonMatchSpeed()
		Select TGadget.GetActiveGadgetName()
			Case "options_matchspeed1"
				g_options_matchspeed = 36
			Case "options_matchspeed2"
				g_options_matchspeed = 30
			Case "options_matchspeed3"
				g_options_matchspeed = 24
		End Select
		RefreshButtons()
	End Function
