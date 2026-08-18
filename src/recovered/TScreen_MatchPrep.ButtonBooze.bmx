' TScreen_MatchPrep.ButtonBooze
' VA 0x0055EFFB   215 bytes
' byte-identical vs NSS5.exe (215/215, original length from Ghidra's inventory, mode=reloc)
' Driven through the oracle from scratch, with helper_map.record stubbed.
' Body-only format: statements only; parameters are a0, a1, ...
'!Global g_profile:TProfile            ' 0x00C6F028
If g_profile.bank < 100
	TScreen.DoMessage(GetText("CMESSAGE_NOTENOUGHCASH"), 0, 0)
Else
	If g_profile.booze > 0 Or g_profile.achievements[54] > 0 Or TScreen.DoMessage(GetText("CMESSAGE_BUYBOOZE"), 1, 0)
		g_profile.UpdateBank(-100)
		g_profile.booze = g_profile.booze + 50
		SetUpScreen()
		g_profile.CheckAchievement(55)
	End If
End If
