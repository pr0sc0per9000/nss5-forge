' TScreen_MatchPrep.ButtonDrugs
' VA 0x0055ECDD   168 bytes   vtable slot 0x38
' byte-identical vs NSS5.exe (168/168, original length from Ghidra's inventory, mode=reloc)
'
' g_profile:TProfile is the Global at 0x00C6F028.
' The ElseIf test is a short-circuit Or whose right operand is the DoMessage call itself:
' `setg / movzx / cmp eax,0 / jne` skips the call and the shared eax is then tested once.
' DoMessage's two trailing Int arguments are pushed explicitly (0,0 and 1,0).
	Function ButtonDrugs:Int()
		'!Global g_profile:TProfile
		If g_profile.bank < 1000
			TScreen.DoMessage(GetText("CMESSAGE_NOTENOUGHCASH"), 0, 0)
		ElseIf g_profile.drugs > 0 Or TScreen.DoMessage(GetText("CMESSAGE_BUYDRUGS"), 1, 0)
			g_profile.UpdateBank(-1000)
			g_profile.drugs = g_profile.drugs + 50
			TScreen_MatchPrep.SetUpScreen()
		EndIf
	End Function
