' TScreen.ButtonHelpOk
' VA 0x0051353d   37 bytes   vtable slot 0x4c   sig ()i
' byte-identical vs NSS5.exe (37/37, original length from Ghidra's inventory, mode=reloc)
'
' KIND=Function -- static, no implicit Self.
' Calls the recovered module Function LogLine (0x00505B91) with the string literal
' "ButtonHelpOk" -- its own name. LogLine is a function-entry trace logger, which is why
' 47 functions call it. The Global at 0x00C61730 is an Int; the name is ours.
	Function ButtonHelpOk:Int()
		'!Global g_screen_helpok:Int
		LogLine("ButtonHelpOk")
		g_screen_helpok = 1
	End Function
