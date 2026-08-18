' TScreen_TestTournaments.SetUpScreen
' VA 0x00538756   770 bytes   vtable slot 0x34   sig ()i   KIND=Function
' byte-identical vs NSS5.exe (770/770, original length from Ghidra's inventory, mode=reloc,
' reloc_masked=51), verified with NSS5_NO_LEARN=1.
'
' GLOBAL TYPES ARE ASSUMPTIONS (names are ours):
'   0x00C66418 g_tt_lbl_date:TButton  -- only slot 0x64 (TGadget.SetText) is used on it, so
'     this file's own bytes are unaffected by the type spelling. The type is TButton, not
'     TLabel, per TScreen_TestTournaments.CreateScreen.bmx's header: that file's own
'     construction site for 0x00C66418 is unambiguous (`TButton.CreateButton("date","",...)`),
'     and TButton and TLabel are sibling Extends TGadget Types, never convertible -- which
'     resolves the cross-file Global-type conflict flagged there.
'   0x00C66410 g_tt_tbl_teams:TTable  -- globals_final.tsv says TButton; WRONG, slots 0x9c
'                                        (ClearItems) and 0x94 (AddItem) are TTable's
'   0x00C66414 g_tt_tbl_fixtures:TTable
'   0x00C66450 g_tt_cmb_comp:TCombo   0x00C66454 g_tt_comp:TCompetition
'   0x00C66428 g_tt_group:Int  0x00C66440 g_tt_round:Int  0x00C66458 g_tt_sdate:Int
'   0x00C6F028 g_profile:TProfile
'
' The comptype dispatch is a Select, not If/ElseIf: both Case compares are emitted back to
' back at 0x0053887C/0x00538881 with their targets past the last compare (guide 10.2).

'!Global g_tt_lbl_date:TButton
'!Global g_tt_tbl_teams:TTable
'!Global g_tt_tbl_fixtures:TTable
'!Global g_tt_cmb_comp:TCombo
'!Global g_tt_comp:TCompetition
'!Global g_tt_group:Int
'!Global g_tt_round:Int
'!Global g_tt_sdate:Int
'!Global g_profile:TProfile
TScreen.SetActive("tournaments", "")
g_tt_lbl_date.SetText(g_profile.date.GetString("YY-WW-DDD"), "", -1, -1)
g_tt_tbl_teams.ClearItems()
g_tt_tbl_fixtures.ClearItems()
g_tt_sdate = 0
If g_tt_cmb_comp.GetSelectedItem() > 0
	g_tt_comp = TCompetition.SelectById(g_tt_cmb_comp.GetSelectedItemId())
	TScreen_TestTournaments.CheckRounds()
	TScreen_TestTournaments.CheckGroups()
	If g_tt_comp <> Null
		If g_tt_comp.teampool And g_tt_comp.teampool[g_tt_group-1] <> Null
			Select g_tt_comp.comptype
			Case 2
				g_tt_comp.teampool[g_tt_group-1].SortTableBy(16)
			Case 3
				g_tt_comp.teampool[g_tt_group-1].SortTableBy(16)
			Default
				g_tt_comp.teampool[g_tt_group-1].SortTableBy(4)
			End Select
			Local i:Int = 1
			For Local td:TTableData = EachIn g_tt_comp.teampool[g_tt_group-1].list
				g_tt_tbl_teams.AddItem(td.GetStringArray(i, 0), "", "")
				i :+ 1
			Next
		End If
		For Local fx:TFixture = EachIn g_tt_comp.lfixturelist
			If fx.round = g_tt_round And (fx.groupno = g_tt_group Or g_tt_group = 0)
				g_tt_tbl_fixtures.AddItem(fx.GetStringArray(g_tt_comp.groups > 1), "", "")
				g_tt_sdate = fx.sdate
			End If
		Next
	End If
End If
