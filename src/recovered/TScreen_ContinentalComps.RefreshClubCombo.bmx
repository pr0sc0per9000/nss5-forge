' TScreen_ContinentalComps.RefreshClubCombo
' VA 0x005343CD   399 bytes   mode=reloc
' byte-identical vs NSS5.exe
' Verified through the oracle from scratch with helper_map.record stubbed; MATCH over
' the full Ghidra-authoritative length, every byte.
' Body-only format: statements only, parameters are a0, a1, ...
'!Global g_cc_combo:TCombo
'!Global g_cc_table:TTable
'!Global g_clubs:TList
LogLine("RefreshClubCombo")
g_cc_combo.ClearItems()
Local c:TCompetition = TCompetition.SelectById(Int(g_cc_table.GetSelectedText(0)))
If c <> Null
	Local n:TNation = TNation.SelectById(c.based)
	If n <> Null
		g_cc_combo.btn_head.SetText(n.name, "", -1, -1)
	Else
		g_cc_combo.btn_head.SetText(GetText("Select Club"), "", -1, -1)
	EndIf
	For Local cl:TClub = EachIn g_clubs
		If c.comptype = 0
			If cl.leagueid = c.id
				g_cc_combo.AddItem(cl.name, "BBBBBB", "FFFFFF", cl.id)
			EndIf
		Else
			If c.comptype = 1 Or c.comptype = 4
				If cl.nationid = c.based
					g_cc_combo.AddItem(cl.name, "BBBBBB", "FFFFFF", cl.id)
				EndIf
			EndIf
		EndIf
	Next
EndIf
