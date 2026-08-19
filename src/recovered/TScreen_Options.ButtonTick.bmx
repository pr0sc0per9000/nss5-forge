' TScreen_Options.ButtonTick
' VA 0x005216F7   304 bytes   mode=reloc
' Driven through the oracle from scratch with helper_map.record stubbed; MATCH over the
' full Ghidra-authoritative length, every byte.
' Body-only format: statements only, parameters are a0, a1, ...
' byte-identical vs NSS5.exe
'!Global g_opt_a:Int      ' 0x00C5D244
'!Global g_opt_b:Int      ' 0x00C63CFC
'!Global g_opt_c:Int      ' 0x00C5D248
'!Global g_opt_d:Int      ' 0x00C63D00
'!Global g_opt_e:Int      ' 0x00C5D274
'!Global g_opt_f:Int      ' 0x00C63D04
'!Global g_screenname:String   ' 0x00C63CEC
'!Global g_player_int01:Int    ' 0x00C5B1FC
'!Global g_inputbox:TInputBox  ' 0x00C63D0C
'!Global g_savename:String     ' 0x00C68BC8
'!Global g_profile:TProfile    ' 0x00C6F028
If g_opt_a <> g_opt_b Or g_opt_c <> g_opt_d
	ResetScreen()
End If
If g_opt_e <> g_opt_f
	TScreen_Shop.CreateScreen()
	TScreen_BootShop.CreateScreen()
	TScreen_WorldMap.CreateScreen()
	TScreen_MatchPrep.CreateScreen()
	TScreen_Casino.UpdateStakeCurrency()
	If g_screenname <> "mainmenu" And g_player_int01 = 0
		TScreen_GameMenu.UpdateTitlePanel()
		TScreen_GameMenu.UpdateNavPanel()
	End If
End If
TOptions.SaveOptions()
Local s:String = g_inputbox.GetText()
If s <> "" And s + ".sav" <> g_savename
	g_profile.SaveGame(s)
End If
TScreen.SetActive(g_screenname, "")
