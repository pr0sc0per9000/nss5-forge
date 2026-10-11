' TScreen_MyContract.ComboContinent
' VA 0x00555D24   301 bytes
' byte-identical vs NSS5.exe (301/301, original length from Ghidra's inventory, mode=reloc)
' Driven through the oracle from scratch, with helper_map.record stubbed.
' Body-only format: statements only; parameters are a0, a1, ...
' NAMES CHANGED 2026-10-11 (byte-neutral): 0x00555D3A `a1a07dc600 mov eax,[0xc67da0]` and
' the six `a1a47dc600 mov eax,[0xc67da4]` at 0x00555D4E..0x00555E0C read this screen's own
' continent and nation combos, stored by TScreen_MyContract.CreateScreen at 0x00554968 /
' 0x005549CD as g_mc_cmb_continent / g_mc_cmb_nation. g_combo_continent / g_combo_nation
' are TScreen_Leagues' combos, 0x00C66F30 / 0x00C66F34.
'!Global g_mc_cmb_continent:TCombo
'!Global g_mc_cmb_nation:TCombo
'!Global g_nations:TList
LogLine("ComboContinent")
Local id:Int = g_mc_cmb_continent.GetSelectedItemId()
g_mc_cmb_nation.alive = 1
g_mc_cmb_nation.SetAlph(1.0)
If id = 0
	g_mc_cmb_nation.alive = 0
	g_mc_cmb_nation.SetAlph(0.5)
EndIf
TNation.SortListBy(2, 1)
g_mc_cmb_nation.ClearItems()
For Local n:TNation = EachIn g_nations
	If n.continent = id And n.HasLeagues()
		g_mc_cmb_nation.AddItem(n.labelshortname, "BBBBBB", "FFFFFF", n.id)
	EndIf
Next
ComboNation()
