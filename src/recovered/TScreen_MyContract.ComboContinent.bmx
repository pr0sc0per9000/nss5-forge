' TScreen_MyContract.ComboContinent
' VA 0x00555D24   301 bytes
' byte-identical vs NSS5.exe (301/301, original length from Ghidra's inventory, mode=reloc)
' Driven through the oracle from scratch, with helper_map.record stubbed.
' Body-only format: statements only; parameters are a0, a1, ...
'!Global g_combo_continent:TCombo
'!Global g_combo_nation:TCombo
'!Global g_nations:TList
LogLine("ComboContinent")
Local id:Int = g_combo_continent.GetSelectedItemId()
g_combo_nation.alive = 1
g_combo_nation.SetAlph(1.0)
If id = 0
	g_combo_nation.alive = 0
	g_combo_nation.SetAlph(0.5)
EndIf
TNation.SortListBy(2, 1)
g_combo_nation.ClearItems()
For Local n:TNation = EachIn g_nations
	If n.continent = id And n.HasLeagues()
		g_combo_nation.AddItem(n.labelshortname, "BBBBBB", "FFFFFF", n.id)
	EndIf
Next
ComboNation()
