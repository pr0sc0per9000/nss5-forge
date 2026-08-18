' TScreen_Clubs.ButtonQuit
' VA 0x0052cde3   41 bytes   vtable slot 0x40   sig ()i
' byte-identical vs NSS5.exe (41/41, original length from Ghidra's inventory)
' Assumption: 0x005b4721 is BRL _brl_polledinput_KeyDown (byte-proven in brl_functions.tsv).
' 83 is the raw key code as it appears in the original (KEY_S).
	Function ButtonQuit()
		TScreen_EditMenu.SetUpScreen()
		If KeyDown(83) Then TClub.AverageOutStrengthAll()
	End Function
