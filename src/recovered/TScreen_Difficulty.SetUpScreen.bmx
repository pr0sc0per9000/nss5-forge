' TScreen_Difficulty.SetUpScreen
' VA 0x00525cf9   71 bytes   vtable slot 0x34   sig ()i
' byte-identical vs NSS5.exe (71/71, original length from Ghidra's inventory)
' ASSUMPTIONS: module Global 0x00c61700 g_curscreen declared TScreen (the screen currently
' shown -- field +8 is TScreen.name), module Global 0x00c64504 g_diffname declared String
' (the remembered "screen to go back to" name). Both string literals are masked data
' addresses, so their TEXT is not proven by the match, only that two String constants sit
' in those positions.
'
' The remembered name is spelled g_diffname because that is the name 0x00C64504 resolves
' to. 0x00525D1B is `mov dword ptr [0xc64504], ebx`, and TScreen_Difficulty.ButtonEasy,
' ButtonNormal and ButtonHard each read the same slot at their own 0x00525D58 to pass it
' to SetActive. g_prevscreen is CERTAIN at 0x00C63CEC, a different slot belonging to the
' Options screen, so under that spelling assemble.py emits a second Global and this store
' never reaches the three readers. They then call SetActive on an empty String and the
' difficulty buttons do nothing. The body byte-matches either way, because a Global
' reference is a relocation the oracle masks.
	Function SetUpScreen:Int()
		'!Global g_curscreen:TScreen
		'!Global g_diffname:String
		g_diffname = g_curscreen.name
		TScreen.SetActive("difficulty","")
	End Function
