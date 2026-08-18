' TScreen_Pairs.SetUpScreen
' VA 0x00578F5E   247 bytes
' byte-identical vs NSS5.exe (247/247, original length from Ghidra's inventory, mode=reloc)
' Driven through the oracle from scratch, with helper_map.record stubbed.
' Body-only format: statements only; parameters are a0, a1, ...
'!Global g_profile:TProfile
'!Global g_pairs_mode:Int              ' 0x00C6C828
'!Global g_pairs_int03:Int             ' 0x00C6C82C
'!Global g_pairs_int04:Int             ' 0x00C6C830
'!Global g_pairs_int05:Int             ' 0x00C6C834
'!Global g_screen_prev:Int             ' 0x00C6EFD4
'!Global g_screen_w:Int                ' 0x00C6EFE4
'!Global g_screen_h:Int                ' 0x00C6EFE8
'!Global g_font_main:TBitmapFont       ' 0x00C5B1C8
TScreen.SetActive("pairs", "")
g_pairs_mode = a0
g_profile.UpdateEnergy(-20.0)
TScreen_GameMenu.UpdateTitlePanel()
ResetButtonPositions()
TPair_Icon.SetUp(g_pairs_mode)
g_pairs_int03 = -2
g_pairs_int04 = 0
g_pairs_int05 = g_screen_prev
UpdateFaces()
TScreenMessage.Create(g_screen_w / 2, g_screen_h / 2, GetText("Find a pair!"), 1500, g_font_main, Null, 1.0, "FFFFFF")
If g_profile.helppages[15] = 0
	TScreen.Tutorial()
	g_profile.helppages[15] = 1
End If
