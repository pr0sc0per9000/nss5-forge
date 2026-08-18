' TScreen_Promotions.SetUpScreen
' VA 0x00532EE9   873 bytes   class-table slot 0x34   sig ()i
' byte-identical vs NSS5.exe (873/873, original length from Ghidra's inventory, mode=reloc)
'
' Populates the nation combo the first time (CountItems()=0), then -- once a nation is
' selected -- rebuilds both promotion/relegation team tables from the two competition
' combos, and stamps each table's heading with its item count.
'
' GLOBAL NAMES ARE OURS. 0x00C596F0 g_nations:TList (same address as TNation.SelectById),
' 0x00C59A44 g_clubs:TList (same as TClub.SelectById), 0x00C658F8 g_pr_nation:TNation (the
' selected nation), 0x00C658FC g_pr_combo_nation:TCombo, 0x00C65900/0x00C65904
' g_pr_combo_comp1/comp2:TCombo (the two competition-picker combos), 0x00C65908/0x00C6590C
' g_screen_promotions_tplayer01/02:TTable (the two team tables).
'
' SHAPE NOTES
'   * `If Not g_pr_nation` is a GUARD CLAUSE (`Then Return 0`, no Else) -- writing it as
'     `If g_pr_nation <> Null Then <rest> EndIf` compiles to the SHORT 12-byte direct
'     Null-compare (codegen-patterns 10.3) instead of the 21-byte setne/movzx boolean form
'     the original uses; the guard-clause form is 15 bytes longer and closes the gap
'     exactly (873 vs 858 without it).
'   * `n.HasLeagues()` (TNation slot 0x74) gates which nations reach the combo.
'   * `TCompetition.SelectByBasedAndName(basedId, name)` is looked up by the SELECTED
'     nation's id as the "based" argument, once per competition combo.
'   * `TClub.SortListBy(2,1)` runs once, before the club list is walked, not per-club.
'   * Table rows are `[c.shortname, String(c.id)]` with two EMPTY colour strings, matching
'     the literal `""` operand (SYM 0x005c7d40) at both AddItem call sites.
'   * Column-heading idiom `GetText("Teams") + " (" + String(t.CountItems()) + ")"` is the
'     same one already verified in TScreen_ContinentalComps.RefreshQualifiers /
'     .SetUpScreen.
' Body-only format: statements only, parameters are a0, a1, ...
'!Global g_nations:TList
'!Global g_clubs:TList
'!Global g_pr_combo_nation:TCombo
'!Global g_pr_combo_comp1:TCombo
'!Global g_pr_combo_comp2:TCombo
'!Global g_pr_nation:TNation
'!Global g_screen_promotions_tplayer01:TTable
'!Global g_screen_promotions_tplayer02:TTable
TScreen.SetActive("promotions", "")
If g_pr_combo_nation.CountItems() = 0
	g_pr_combo_nation.ClearItems()
	For Local n:TNation = EachIn g_nations
		If n.HasLeagues()
			g_pr_combo_nation.AddItem(n.name, "FFFFFF", "FFFFFF", n.id)
		EndIf
	Next
EndIf
If Not g_pr_nation Then Return 0
g_screen_promotions_tplayer01.ClearItems()
g_screen_promotions_tplayer02.ClearItems()
Local comp1:TCompetition = TCompetition.SelectByBasedAndName(g_pr_nation.id, g_pr_combo_comp1.GetSelectedText())
Local comp2:TCompetition = TCompetition.SelectByBasedAndName(g_pr_nation.id, g_pr_combo_comp2.GetSelectedText())
TClub.SortListBy(2,1)
For Local c:TClub = EachIn g_clubs
	If comp1 <> Null And c.leagueid = comp1.id
		g_screen_promotions_tplayer01.AddItem([c.shortname, String(c.id)], "", "")
	EndIf
	If comp2 <> Null And c.leagueid = comp2.id
		g_screen_promotions_tplayer02.AddItem([c.shortname, String(c.id)], "", "")
	EndIf
Next
g_screen_promotions_tplayer01.SetColumnHeading(0, GetText("Teams") + " (" + String(g_screen_promotions_tplayer01.CountItems()) + ")")
g_screen_promotions_tplayer02.SetColumnHeading(0, GetText("Teams") + " (" + String(g_screen_promotions_tplayer02.CountItems()) + ")")
Return 0
