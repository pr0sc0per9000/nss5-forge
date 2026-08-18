' TScreen_NewPlayer.ButtonQuit
' VA 0x00524e46   65 bytes   vtable slot 0x60   sig ()i
' byte-identical vs NSS5.exe (65/65, original length from Ghidra's inventory)
' Assumes one module Global g_profile:TProfile (0x00c6f028); the class table passed to
' bbObjectNew is TProfile's (0x00c6a4c0), and 0x00c63ca0 = TScreen_MainMenu+0x34.
	Function ButtonQuit:Int()
		'!Global g_profile:TProfile
		g_profile = New TProfile
		TScreen_MainMenu.SetUpScreen()
	End Function
