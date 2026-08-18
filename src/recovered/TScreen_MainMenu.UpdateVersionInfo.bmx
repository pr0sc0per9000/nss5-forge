' TScreen_MainMenu.UpdateVersionInfo
' VA 0x0051d97f   50 bytes   vtable slot 0x68   sig ()i
' byte-identical vs NSS5.exe (50/50, original length from Ghidra's inventory)
' assumes module global:  Global g_screen_mainmenu_int03:String
' assumes module global:  Global g_screen_mainmenu_int25:String
' globals 0x00c639fc / 0x00c6e900 are Strings, not Ints

	Function UpdateVersionInfo:Int()
		'!Global g_screen_mainmenu_int03:String
		'!Global g_screen_mainmenu_int25:String
		g_screen_mainmenu_int03 = g_screen_mainmenu_int25
	End Function
