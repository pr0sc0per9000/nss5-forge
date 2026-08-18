' TScreen_MyContract.ComboDivision
' VA 0x00555FA2   271 bytes
' byte-identical vs NSS5.exe (271/271, original length from Ghidra's inventory, mode=reloc)
' Driven through the oracle from scratch, with helper_map.record stubbed.
' Body-only format: statements only; parameters are a0, a1, ...
'!Global g_combo_club:TCombo
'!Global g_combo_div:TCombo
Local id:Int = g_combo_club.GetSelectedItemId()
g_combo_div.alive = 1
g_combo_div.SetAlph(1.0)
If id = 0
	g_combo_div.alive = 0
	g_combo_div.SetAlph(0.5)
	Return 0
EndIf
Local l:TList = TClub.SelectListByLeagueId(id)
TClub.SortListBy(2, 1)
g_combo_div.ClearItems()
For Local c:TClub = EachIn l
	If c.leagueid = id
		g_combo_div.AddItem(c.labelshortname, "BBBBBB", "FFFFFF", c.id)
	EndIf
Next
ComboClub()
