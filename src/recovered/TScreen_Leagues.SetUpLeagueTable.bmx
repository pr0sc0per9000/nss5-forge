' TScreen_Leagues.SetUpLeagueTable
' VA 0x005459FF   606 bytes   mode=reloc   byte-identical vs NSS5.exe
' KIND=Function, SIG ()i, class-table slot 0x4c
' ASSUMPTIONS
'   0x00C66F20 g_screen_leagues_table:TTable, 0x00C66F5C g_screen_leagues_comp:TCompetition,
'   0x00C66F3C g_Object467:TCombo, 0x00C6F028 g_contractoffer_tprofile:TProfile
'     (all four typed from construction sites in globals_final).
'   TCompetition.teampool = +0x6c ([]:TTeamPool), comptype = +0x24; TTeamPool.list = +0x8;
'     TTable.selecteditem = +0x70; TProfile.myclub = +0x1d0; TClub inherits TBase_Team so
'     tla/labelname/labelshortname are +0x18/+0x1c/+0x20.
'   Slots: TTable 0x9c ClearItems, 0x94 AddItem([]$,$,$), 0xe0 SelectItemByText($,i);
'     TTeamPool 0x5c SortTableBy(i); TTableData 0x3c GetStringArray(i,i)[]$;
'     TCompetition 0xec PaintPromotionPlaces(:TTable); TCombo 0xc0 GetSelectedItemId.
'   The guard is `comp <> Null And comp.teampool` -- a BARE array truth test, which lowers
'     to the BBArray `size` field at +0x10 (codegen-patterns 11.1); `.Length` would read +0x14.
'   The comptype dispatch is a Select WITH a Default: the original loads comptype into eax
'     once and emits both compares back to back. As If/ElseIf it is 608 bytes, not 606.
' Body-only format: statements only; parameters are a0, a1, ...
'!Global g_screen_leagues_table:TTable
'!Global g_Object467:TCombo
'!Global g_screen_leagues_comp:TCompetition
'!Global g_contractoffer_tprofile:TProfile
g_screen_leagues_table.ClearItems()
If g_screen_leagues_comp <> Null And g_screen_leagues_comp.teampool Then
	Select g_screen_leagues_comp.comptype
		Case 2
			g_screen_leagues_comp.teampool[0].SortTableBy(16)
		Case 3
			g_screen_leagues_comp.teampool[0].SortTableBy(16)
		Default
			g_screen_leagues_comp.teampool[0].SortTableBy(4)
	End Select
	Local row:Int = 1
	For Local td:TTableData = EachIn g_screen_leagues_comp.teampool[0].list
		g_screen_leagues_table.AddItem(td.GetStringArray(row, 0), "", "")
		row = row + 1
	Next
	g_screen_leagues_comp.PaintPromotionPlaces(g_screen_leagues_table)
	g_screen_leagues_table.SelectItemByText(g_contractoffer_tprofile.myclub.labelshortname, 1)
	If g_screen_leagues_table.selecteditem = -1 Then
		g_screen_leagues_table.SelectItemByText(g_contractoffer_tprofile.myclub.labelname, 1)
	End If
	If g_screen_leagues_table.selecteditem = -1 Then
		g_screen_leagues_table.SelectItemByText(g_contractoffer_tprofile.myclub.tla, 1)
	End If
	Local c:TClub = TClub.SelectById(g_Object467.GetSelectedItemId())
	If c <> Null And c <> g_contractoffer_tprofile.myclub Then
		g_screen_leagues_table.SelectItemByText(c.labelshortname, 1)
		If g_screen_leagues_table.selecteditem = -1 Then
			g_screen_leagues_table.SelectItemByText(c.labelname, 1)
		End If
		If g_screen_leagues_table.selecteditem = -1 Then
			g_screen_leagues_table.SelectItemByText(c.tla, 1)
		End If
	End If
End If
Return 0
