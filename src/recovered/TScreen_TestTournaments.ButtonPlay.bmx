' TScreen_TestTournaments.ButtonPlay
' VA 0x005391E8   124 bytes
' byte-identical vs NSS5.exe (124/124, original length from Ghidra's inventory, mode=reloc)
' Driven through the oracle from scratch, with helper_map.record stubbed.
' Body-only format: statements only; parameters are a0, a1, ...
'!Global g_profile:TProfile
'!Global g_tt_int03:Int
Local y:Int = g_profile.date.GetYear()
If KeyDown(162)
	Repeat
		g_profile.Play(0)
	Until g_profile.date.GetYear() > y
	SetUpScreen()
Else
	g_profile.Play(g_tt_int03)
	SetUpScreen()
End If
