' TScreen_Continents.ComboContinent
' VA 0x00547A20   624 bytes   mode=reloc   byte-identical vs NSS5.exe
' KIND=Function, SIG ()i, slot 0x40
' ASSUMPTIONS
'  * Globals (names ours; only the declared TYPE is load-bearing):
'      0x00C671E4 g_combo_group:TCombo      0x00C671E0 g_continents_cmbContinent:TCombo
'      0x00C671CC g_table_league:TTable     0x00C671D4 g_table_02:TTable
'      0x00C671D8 g_table_03:TTable         0x00C67204 g_continents_int04:Int
'      0x00C67224 g_continents_mode:Int     0x00C6F028 g_profile:TProfile
'      0x00C6099C g_competitions:TList
'  * TTable slot 0x54 is INHERITED from TGadget = Hide() (vtable_map lists no 0x54
'    of TTable's own; walk the Extends chain, guide 3f).
'  * `Local yr` holds `GetYear() + 6` -- the `add eax,6` at 0x00547A78 happens before
'    the store, so the +6 is part of the Local, not of the later comparison.
'  * comptype is a SELECT (cmp 1/je, cmp 0/je, cmp 4/je, jmp at 0x00547B5E), and Cases
'    0 and 4 carry duplicate bodies. Reproduced as written, not folded (guide 16.8).
'  * ComboCompetition() is a sibling static through this Type's own class table.

'!Global g_combo_group:TCombo
' 0x00C671E0 is this screen's continent combo; TScreen_Continents.CreateScreen builds it
' and names it g_continents_cmbContinent. g_combo_continent is TScreen_Leagues' name for
' 0x00C66F30, so the two screens' combos shared one emitted variable.
'!Global g_continents_cmbContinent:TCombo
'!Global g_table_league:TTable
'!Global g_table_02:TTable
'!Global g_table_03:TTable
'!Global g_continents_int04:Int
'!Global g_continents_mode:Int
'!Global g_profile:TProfile
'!Global g_competitions:TList

Function ComboContinent:Int()
	g_combo_group.ClearItems()
	g_table_league.ClearItems()
	g_table_03.Hide()
	g_table_02.Hide()
	Local yr:Int = g_profile.date.GetYear() + 6
	Local contid:Int = g_continents_cmbContinent.GetSelectedItemId()
	TCompetition.SortListBy(26, 1)
	For Local c:TCompetition = EachIn g_competitions
		If c.level = g_continents_mode And c.startyear < yr And c.lfixturelist.IsEmpty() = 0
			If (c.locale = 1 And c.based = contid) Or c.locale = 2
				Select c.comptype
					Case 1
						If c.IsThisCurrentCupRound() Or c.id = g_continents_int04 Or c.AllFixturesPlayed()
							g_combo_group.AddItem(c.labelname, "BBBBBB", "FFFFFF", c.id)
						End If
					Case 0
						If c.AllFixturesPopulated() Or c.AllFixturesPlayed()
							g_combo_group.AddItem(c.labelname, "BBBBBB", "FFFFFF", c.id)
						End If
					Case 4
						If c.AllFixturesPopulated() Or c.AllFixturesPlayed()
							g_combo_group.AddItem(c.labelname, "BBBBBB", "FFFFFF", c.id)
						End If
				End Select
			End If
		End If
	Next
	ComboCompetition()
End Function
