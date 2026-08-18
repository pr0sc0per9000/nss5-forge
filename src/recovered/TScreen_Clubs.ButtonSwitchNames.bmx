' TScreen_Clubs.ButtonSwitchNames
' VA 0x0052cee2   39 bytes   vtable slot 0x50   sig ()i
' byte-identical vs NSS5.exe (39/39, original length from Ghidra's inventory)
' assumes module global:  Global g_screen_clubs_int02:Int
' global 0x00c6524c; SetUpScreen is TScreen_Clubs slot 0x34

	Function ButtonSwitchNames:Int()
		'!Global g_screen_clubs_int02:Int
		g_screen_clubs_int02 = Not g_screen_clubs_int02
		SetUpScreen()
	End Function
