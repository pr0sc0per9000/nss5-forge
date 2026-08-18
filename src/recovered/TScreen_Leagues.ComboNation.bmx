' TScreen_Leagues.ComboNation
' VA 0x005452F5   671 bytes   mode=reloc   byte-identical vs NSS5.exe
' KIND=Function, SIG ()i, class-table slot 0x40
' (671/671, original length from Ghidra's inventory; verified under NSS5_NO_LEARN=1)
'
' ASSUMPTIONS -- Global NAMES are ours, the declared TYPES are load-bearing.
'   0x00C66F38 g_lg_combo_league:TCombo   (already TCombo in TScreen_Leagues.ComboLeague)
'   0x00C66F34 g_lg_combonation:TCombo    -- slot 0xc0 GetSelectedItemId
'   0x00C66F20 g_lg_table1:TTable         -- slot 0x9c TTable.ClearItems
'   0x00C66F24 g_lg_table2:TTable         -- slot 0x54 TGadget.Hide (inherited)
'   0x00C66F28 g_lg_table3:TTable         -- slot 0x54 TGadget.Hide (inherited)
'   0x00C6099C g_competitions:TList       (declared TList by several banked bodies)
'   0x00C66F40 g_leagues_setupid:Int      (bare dword cmp, no refcount traffic)
'   0x00C6EF50 g_engine_int161:Int        (bare dword cmp)
'   TCompetition: locale +0x18, comptype +0x24, based +0x20, id +0x08, labelname +0x14,
'     lfixturelist:TList +0x60; slots 0xd4 AllFixturesPopulated, 0xd8 IsThisCurrentCupRound.
'   TNation.id is +0x0c.  TList slot 0x38 = BRL TList.IsEmpty.
' SHAPE NOTES
'   * the guard is one And/Or chain, NOT nested Ifs -- bcc lays every sub-test out with its
'     own `cmp eax,0` merge point, which is what the run of sete/movzx pairs is:
'         locale = 0 And (comptype = 0 Or comptype = 4 Or comptype = 1)
'                  And based = n.id And lfixturelist.IsEmpty() = 0
'     Written `IsEmpty() = 0` (sete), not `Not ...IsEmpty()`; the operand order of the Or
'     arm is 0 / 4 / 1, in that order, which is byte-observable.
'   * the inner dispatch is a Select with Cases 1, 0, 4 and NO Default -- three cmp/je back
'     to back followed by `E9 rel32`, the tell in codegen-patterns 10.2.
'   * ComboLeague is a sibling Function of this Type (class table +0x44), written unprefixed.
' Body-only format: statements only, parameters are a0, a1, ...
'!Global g_lg_combo_league:TCombo
'!Global g_lg_table1:TTable
'!Global g_lg_table2:TTable
'!Global g_lg_table3:TTable
'!Global g_lg_combonation:TCombo
'!Global g_competitions:TList
'!Global g_leagues_setupid:Int
'!Global g_engine_int161:Int
g_lg_combo_league.ClearItems()
g_lg_table1.ClearItems()
g_lg_table3.Hide()
g_lg_table2.Hide()
Local n:TNation = TNation.SelectById(g_lg_combonation.GetSelectedItemId())
If n <> Null
	For Local c:TCompetition = EachIn g_competitions
		If c.locale = 0 And (c.comptype = 0 Or c.comptype = 4 Or c.comptype = 1) And c.based = n.id And c.lfixturelist.IsEmpty() = 0
			Select c.comptype
				Case 1
					If c.IsThisCurrentCupRound() Or c.id = g_leagues_setupid Or g_engine_int161 = 2
						g_lg_combo_league.AddItem(c.labelname, "BBBBBB", "FFFFFF", c.id)
					EndIf
				Case 0
					If c.AllFixturesPopulated() Or g_engine_int161 = 2
						g_lg_combo_league.AddItem(c.labelname, "BBBBBB", "FFFFFF", c.id)
					EndIf
				Case 4
					If c.AllFixturesPopulated()
						g_lg_combo_league.AddItem(c.labelname, "BBBBBB", "FFFFFF", c.id)
					EndIf
			End Select
		Else
			If g_engine_int161 = 2 And c.locale = 0 And c.based = n.id
				g_lg_combo_league.AddItem(c.labelname, "BBBBBB", "FFFFFF", c.id)
			EndIf
		EndIf
	Next
EndIf
ComboLeague()
