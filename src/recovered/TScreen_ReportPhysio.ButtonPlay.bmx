' TScreen_ReportPhysio.ButtonPlay
' VA 0x0056185B   79 bytes   vtable slot 0x38   sig ()i
' byte-identical vs NSS5.exe (79/79, original length from Ghidra's inventory, mode=reloc)
' Assumptions: Global 0x00C6F028:TProfile (globals_final, construction, high confidence),
' 0x00C68A14:TButton, 0x00C6675C typed TImage (untyped in globals_final; TButton.SetIcon
' at slot 0x90 takes :TImage). `*(int*)(bossreport + 8)` is the BBString length word, so
' the test is bossreport.length. Ghidra prints the branches the other way round; the
' original tests <> 0 first (je to the else body).
	Function ButtonPlay:Int()
		'!Global g_profile:TProfile
		'!Global g_physio_btn:TButton
		'!Global g_physio_icon:TImage
		If g_profile.bossreport.length <> 0
			TScreen_ReportBoss.SetUpScreen()
			g_physio_btn.SetIcon(g_physio_icon)
		Else
			TScreen_GameMenu.SetUpScreen()
			g_profile.NextPlayButton()
		EndIf
	End Function
