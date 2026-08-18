' TScreen_TestTournaments.ComboLevel
' VA 0x00538A58   222 bytes
' byte-identical vs NSS5.exe (222/222, original length from Ghidra's inventory, mode=reloc)
' Driven through the oracle from scratch, with helper_map.record stubbed.
' Body-only format: statements only; parameters are a0, a1, ...
'!Global g_tt_combo319:TCombo
'!Global g_tt_combo320:TCombo
LogLine("ComboLevel")
g_tt_combo320.ClearItems()
Select g_tt_combo319.GetSelectedItem()
Case 1
	g_tt_combo320.AddItem("Nation","BBBBBB","FFFFFF",0)
	g_tt_combo320.AddItem("Continent","BBBBBB","FFFFFF",0)
Case 2
	g_tt_combo320.AddItem("Continent","BBBBBB","FFFFFF",0)
	g_tt_combo320.AddItem("World","BBBBBB","FFFFFF",0)
End Select
ComboLocale()
