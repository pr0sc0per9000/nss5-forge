' TScreen_Difficulty.SetUpScreen
' VA 0x00525cf9   71 bytes   vtable slot 0x34   sig ()i
' byte-identical vs NSS5.exe (71/71, original length from Ghidra's inventory)
' ASSUMPTIONS: module Global 0x00c61700 declared TScreen (the screen currently shown --
' field +8 is TScreen.name), module Global 0x00c64504 declared String (the remembered
' "screen to go back to" name). Both string literals are masked data addresses, so their
' TEXT is not proven by the match, only that two String constants sit in those positions.
	Function SetUpScreen:Int()
		'!Global g_curscreen:TScreen
		'!Global g_prevscreen:String
		g_prevscreen = g_curscreen.name
		TScreen.SetActive("difficulty","")
	End Function
