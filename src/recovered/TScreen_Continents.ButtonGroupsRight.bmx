' TScreen_Continents.ButtonGroupsRight
' VA 0x0054918b   123 bytes   vtable slot 0x74   sig ()i
' byte-identical vs NSS5.exe (123/123, original length from Ghidra's inventory)
' 0x00C671E4 : TCombo (construction) -- slot 0xC0 = GetSelectedItemId()
' 0x00C67220 : TCompetition (construction, 9 sites)
' GetSelectedItemId is called twice -- bcc does no CSE, the original does too
' Global: Global g_cont_grp:Int
' Global: Global g_cont_combo:TCombo
' Global: Global g_cont_comp:TCompetition
' Global: Global g_cont_selfix:Int
	Function ButtonGroupsRight:Int()
		'!Global g_cont_grp:Int
		'!Global g_cont_combo:TCombo
		'!Global g_cont_comp:TCompetition
		'!Global g_cont_selfix:Int
		g_cont_grp :+ 1
		If g_cont_combo.GetSelectedItemId() > 0
			g_cont_comp = TCompetition.SelectById(g_cont_combo.GetSelectedItemId())
		EndIf
		SetUpLeagueTable()
		SetUpFixturesTable(g_cont_selfix)
	End Function
