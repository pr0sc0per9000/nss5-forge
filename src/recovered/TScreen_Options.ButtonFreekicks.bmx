' TScreen_Options.ButtonFreekicks
' VA 0x005215d5   125 bytes   vtable slot 0x84   sig ()i
' byte-identical vs NSS5.exe (125/125, original length from Ghidra's inventory)
' assumption: module Global at 0x00c5d278 declared as g_optFreekicks:Int
' string literals read directly out of NSS5.exe's data section
	Function ButtonFreekicks:Int()
		'!Global g_optFreekicks:Int
		Select TGadget.GetActiveGadgetName()
			Case "options_reqfreekicksalways"
				g_optFreekicks=1
			Case "options_reqfreekickssometimes"
				g_optFreekicks=0
			Case "options_reqfreekicksnever"
				g_optFreekicks=-1
		End Select
		TScreen_Options.RefreshButtons()
	End Function
