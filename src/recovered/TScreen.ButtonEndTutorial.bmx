' TScreen.ButtonEndTutorial
' VA 0x00513562   55 bytes   vtable slot 0xc0   sig ()i
' byte-identical vs NSS5.exe (55/55, original length from Ghidra's inventory)
' assumes module globals:  Global g_profile:TProfile  (0x00c6f028)
'                          Global g_screen_state:Int  (0x00c61730)
' the TProfile typing of 0x00c6f028 is load-bearing: slot 0x158 is TProfile.ResetTutorial(i)i

	Function ButtonEndTutorial:Int()
		'!Global g_profile:TProfile
		'!Global g_screen_state:Int
		If g_profile <> Null Then g_profile.ResetTutorial(1)
		g_screen_state = 2
	End Function
