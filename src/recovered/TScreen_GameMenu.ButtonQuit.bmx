' TScreen_GameMenu.ButtonQuit
' VA 0x0053b39d   84 bytes   vtable slot 0x48   sig ()i
' byte-identical vs NSS5.exe (84/84, original length from Ghidra's inventory)
' assumption: module Global at 0x00c6f028 declared as g_profile:TProfile
	Function ButtonQuit:Int()
		'!Global g_profile:TProfile
		g_profile.SaveGame("")
		g_profile=New TProfile
		TScreen_MainMenu.SetUpScreen()
	End Function
