' TScreen_Continents.ComboCompetition
' VA 0x00547C90   557 bytes   mode=reloc   byte-identical vs NSS5.exe
' KIND=Function, SIG ()i, slot 0x44
' ASSUMPTIONS
'  * Globals (names ours; only the declared TYPE is load-bearing):
'      0x00C671E4 g_combo_group:TCombo            0x00C671E8 g_combo_competition:TCombo
'      0x00C671EC g_continents_int03:Int          0x00C67208 g_continents_int05:Int
'      0x00C67220 g_continents_competition:TCompetition
'      0x00C67224 g_continents_mode:Int
'      0x00C59310 g_continents_sortmode:Int       0x00C59A48 g_club_sortmode:Int
'      0x00C596F4 g_nation_sortby:Int
'        The nation/competition sort-key selector TNation.Compare reads. Measured, the
'        store below is 0x00547E13 `c705f496c50002000000 mov dword ptr [0xc596f4],2`.
'        g_nation_sortmode is TClub.GetFixtureList's and TNation.GetFixtureList's name
'        for 0x00C59E44, the FIXTURE sort key TFixture.Compare reads and those two
'        bodies set to 17, so one variable carried both keys and each subsystem's sort
'        order was decided by whichever ran last.
'    The three "sortmode" Globals are the Compare-mode selectors the following
'    TList.Sort() reads; all three are plain dword stores of 2 (no refcount) = Int.
'  * The club/nation branch is a SELECT, not If/ElseIf: at 0x00547D9E the subject is
'    loaded once and `cmp 0/je`, `cmp 1/je`, `jmp` sit back to back (guide 10.2).
'    As If/ElseIf the body is 553 bytes, 4 short.
'  * `lst.Sort()` emits both defaults (push CompareObjects, push 1) at the call site.
'  * The three sibling statics are called through this Type's own class table, so they
'    are written unprefixed (guide 3d).
'  * TCombo.AddItem($,$,$,i) receives (labelname, "BBBBBB", "FFFFFF", id); both literals
'    read out of NSS5.exe.

'!Global g_combo_group:TCombo
'!Global g_combo_competition:TCombo
'!Global g_continents_int03:Int
'!Global g_continents_int05:Int
'!Global g_continents_competition:TCompetition
'!Global g_continents_mode:Int
'!Global g_continents_sortmode:Int
'!Global g_nation_sortby:Int
'!Global g_club_sortmode:Int

Function ComboCompetition:Int()
	g_combo_competition.ClearItems()
	g_continents_int05 = 1
	g_continents_int03 = 0
	If g_combo_group.GetSelectedItemId() > 0
		g_continents_competition = TCompetition.SelectById(g_combo_group.GetSelectedItemId())
		If g_continents_competition <> Null
			Local lst:TList = CreateList()
			For Local tp:TTeamPool = EachIn g_continents_competition.teampool
				For Local td:TTableData = EachIn tp.list
					Local t:TBase_Team = Null
					Select g_continents_mode
						Case 0
							t = TClub.SelectById(td.teamid)
						Case 1
							t = TNation.SelectById(td.teamid)
					End Select
					If t <> Null Then lst.AddLast(t)
				Next
			Next
			g_continents_sortmode = 2
			g_club_sortmode = 2
			g_nation_sortby = 2
			lst.Sort()
			For Local t:TBase_Team = EachIn lst
				g_combo_competition.AddItem(t.labelname, "BBBBBB", "FFFFFF", t.id)
			Next
			SetUpLeagueTable()
			SetUpFixturesTable(1)
		End If
	End If
	RefreshComboColours()
	ButtonGroup()
End Function
