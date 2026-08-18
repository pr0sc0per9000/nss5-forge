' TScreen_WebPage.ButtonPlay
' VA 0x00561337   147 bytes   vtable slot 0x38   sig ()i
' byte-identical vs NSS5.exe (147/147, original length from Ghidra's inventory)
' Assumptions: module Globals 0x00c68900 = g_webpage_url:String (globals_final guesses Int;
' it is read at +8, which is BBString.length, so String is forced), 0x00c6f028 =
' g_profile:TProfile, 0x00c66b80 = g_screen_relationships:TScreen (typed from its
' construction site). Class-table pointers: 0x00c66910 = TScreen_GameMenu.SetUpScreen,
' 0x00c66d04 = TScreen_Relationships.SetUpScreen(i), 0x00c61c88 = TScreen.SetActive($,$).
' TProfile.webheadline is field +0x50; TProfile slot 0x6c = NextPlayButton.
	Function ButtonPlay:Int()
		'!Global g_webpage_url:String
		'!Global g_profile:TProfile
		'!Global g_screen_relationships:TScreen
		If g_webpage_url.length <> 0
			If g_webpage_url = g_screen_relationships.name
				TScreen_Relationships.SetUpScreen(0)
			Else
				TScreen.SetActive(g_webpage_url, "")
			End If
		Else
			g_profile.webheadline = ""
			TScreen_GameMenu.SetUpScreen()
			g_profile.NextPlayButton()
		End If
	End Function
