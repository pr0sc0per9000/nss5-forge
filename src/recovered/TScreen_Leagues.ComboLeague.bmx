' TScreen_Leagues.ComboLeague
' VA 0x00545594   434 bytes  mode=reloc  byte-identical vs NSS5.exe
' KIND=Function, SIG ()i, slot 0x44
' ASSUMPTIONS
'   0x00C66F38 g_combo_league:TCombo  -- globals_final (construction); slot 0xC0 = GetSelectedItemId
'   0x00C66F3C g_combo_club:TCombo    -- globals_final (construction); 0x8C=ClearItems, 0x90=AddItem
'   0x00C66F5C g_leagues_comp:TCompetition -- globals_final (construction); .teampool
'                                        ([]:TTeamPool) at +0x6C, walked as an array EachIn
'   0x00C59A48 g_club_sortmode:Int    -- globals_final "Int (usage)"; the sort key TClub.Compare
'                                        reads.  Plain dword store of 2, no refcount traffic.
'   TTeamPool.list :TList at +0x8; TTableData.teamid at +0xC; TClub.labelname +0x1C, .id +0xC.
'   lst.Sort() with no arguments -- BRL's TList.Sort defaults are (True, CompareObjects),
'   which is exactly the `push 1 / push _brl_linkedlist_CompareObjects` the original emits.
'   Global names are ours; the originals are unrecoverable.
	Function ComboLeague:Int()
		'!Global g_combo_league:TCombo
		'!Global g_combo_club:TCombo
		'!Global g_leagues_comp:TCompetition
		'!Global g_club_sortmode:Int
		g_combo_club.ClearItems()
		g_leagues_comp = TCompetition.SelectById(g_combo_league.GetSelectedItemId())
		If g_leagues_comp <> Null
			Local lst:TList = CreateList()
			For Local tp:TTeamPool = EachIn g_leagues_comp.teampool
				For Local td:TTableData = EachIn tp.list
					Local c:TClub = TClub.SelectById(td.teamid)
					If c <> Null Then lst.AddLast(c)
				Next
			Next
			g_club_sortmode = 2
			lst.Sort()
			For Local c:TClub = EachIn lst
				g_combo_club.AddItem(c.labelname, "BBBBBB", "FFFFFF", c.id)
			Next
			TScreen_Leagues.SetUpLeagueTable()
			TScreen_Leagues.SetUpLeagueFixtures(1)
		End If
		TScreen_Leagues.RefreshComboColours()
		TScreen_Leagues.ButtonRound()
	End Function
