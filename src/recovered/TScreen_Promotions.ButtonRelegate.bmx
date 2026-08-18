' TScreen_Promotions.ButtonRelegate
' VA 0x0053348A   192 bytes
' byte-identical vs NSS5.exe (192/192, original length from Ghidra's inventory, mode=reloc)
' Driven through the oracle from scratch, with helper_map.record stubbed.
' Body-only format: statements only; parameters are a0, a1, ...
'!Global g_prom_nation:TNation
'!Global g_prom_table2:TTable
'!Global g_prom_combo:TCombo
'!Global g_prom_table1:TTable
If Not g_prom_nation Then Return 0
Local c:TClub = TClub.SelectById(Int(g_prom_table2.GetSelectedText(1)))
Local comp:TCompetition = TCompetition.SelectByBasedAndName(g_prom_nation.id, g_prom_combo.GetSelectedText())
If c <> Null And comp <> Null
	c.leagueid = comp.id
	SetUpScreen()
	g_prom_table1.SelectItemByText(c.name, 0)
End If
