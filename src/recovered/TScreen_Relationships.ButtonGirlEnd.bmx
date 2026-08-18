' TScreen_Relationships.ButtonGirlEnd
' VA 0x00540C58   201 bytes
' byte-identical vs NSS5.exe (201/201, original length from Ghidra's inventory, mode=reloc)
' Driven through the oracle from scratch, with helper_map.record stubbed.
' Body-only format: statements only; parameters are a0, a1, ...
'!Global g_profile:TProfile
'!Global g_rel_screen:TScreen
SetUpScreen(1)
If g_profile.relationgirlfriend = 0
	TScreen.DoMessage(GetText("CMESSAGE_NOGIRLFRIEND"), 0, 0)
Else
	If TScreen.DoMessage(GetText("CMESSAGE_GIRLFRIENDEND"), 1, 0)
		g_profile.relationgirlfriend = 0
		SetUpScreen(1)
		TScreen_WebPage.SetUpScreen(g_rel_screen.name, g_profile.DoNews(GetText("CNEWS_GIRLFRIENDDUMPED"), g_profile.myclub, Null, 0, 0))
	EndIf
EndIf
