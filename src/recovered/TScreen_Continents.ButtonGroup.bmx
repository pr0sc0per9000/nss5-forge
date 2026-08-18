' TScreen_Continents.ButtonGroup
' VA 0x00549002   393 bytes   mode=reloc   byte-identical vs NSS5.exe
' KIND=Function, SIG ()i, class-table slot 0x70
' ASSUMPTIONS
'   0x00C67220 g_continents_comp:TCompetition -- globals_final (construction).
'     .comptype +0x24, .teampool +0x6c ([]:TTeamPool), slots 0xc8/0xcc = GetPrevRound /
'     GetNextRound, all from object_model.json / vtable_map.tsv.
'   0x00C671E8 g_continents_combo:TCombo -- globals_final (construction); slot 0xc0 =
'     TCombo.GetSelectedItemId()i.
'   0x00C671EC g_continents_selrow:Int, 0x00C67224 g_continents_mode:Int,
'   0x00C67204 g_continents_fixmode:Int -- globals_final "Int (usage)"; each is a bare
'     dword store/compare with no refcount traffic.
'   0x00C6F028 g_profile:TProfile -- .clubid +0x20, .nationid +0x1c.
'   Downcast class table 0x00C64B80 = TTableData; TTeamPool.list (+0x8) is its TList.
'   Global names are ours; the originals are unrecoverable.
'   `If g_continents_comp.teampool` is the BARE array truth test (`cmp [eax+0x10],0`,
'   codegen-patterns 11.1) -- `.Length` would compare +0x14 instead.
	Function ButtonGroup:Int()
		'!Global g_continents_comp:TCompetition
		'!Global g_continents_selrow:Int
		'!Global g_continents_combo:TCombo
		'!Global g_continents_mode:Int
		'!Global g_continents_fixmode:Int
		'!Global g_profile:TProfile
		If g_continents_comp <> Null And g_continents_comp.comptype <> 1
			If g_continents_comp.teampool
				g_continents_selrow = 0
				Local sel:Int = g_continents_combo.GetSelectedItemId()
				Select g_continents_mode
					Case 0
						If sel < 1 Then sel = g_profile.clubid
					Case 1
						If sel < 1 Then sel = g_profile.nationid
				End Select
				Local i:Int = 0
				For Local tp:TTeamPool = EachIn g_continents_comp.teampool
					For Local td:TTableData = EachIn tp.list
						If td.teamid = sel Then g_continents_selrow = i
					Next
					i :+ 1
				Next
			End If
			SetUpLeagueTable()
			If g_continents_fixmode
				SetUpFixturesTable(g_continents_comp.GetPrevRound())
			Else
				SetUpFixturesTable(g_continents_comp.GetNextRound())
			End If
		End If
	End Function
