' TScreen_MatchPrep.ButtonNRG
' VA 0x0055ED85   329 bytes   vtable slot 0x3c
' byte-identical vs NSS5.exe (329/329, original length from Ghidra's inventory, mode=reloc)
'
' TProfile.sponsor_expires and .achievements are Int[]; [+0x1c] is element 1 and [+0xec]
' is element 53.
' First test is a short-circuit `And`, the ElseIf is a four-deep short-circuit `Or` chain
' terminating in the DoMessage call.
	Function ButtonNRG:Int()
		'!Global g_profile:TProfile
		If g_profile.sponsor_expires[1] = 0 And g_profile.bank < 250
			TScreen.DoMessage(GetText("CMESSAGE_NOTENOUGHCASH"), 0, 0)
		ElseIf g_profile.sponsor_expires[1] > 0 Or g_profile.NRG > 0 Or g_profile.selectedformatch < 0 Or g_profile.achievements[53] > 0 Or TScreen.DoMessage(GetText("CMESSAGE_BUYNRG"), 1, 0)
			If g_profile.sponsor_expires[1] = 0 Then g_profile.UpdateBank(-250)
			g_profile.NRG = g_profile.NRG + 50
			TScreen_MatchPrep.SetUpScreen()
			g_profile.CheckAchievement(54)
		EndIf
	End Function
