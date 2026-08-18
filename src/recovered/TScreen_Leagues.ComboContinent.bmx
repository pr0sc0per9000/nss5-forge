' TScreen_Leagues.ComboContinent
' VA 0x0054520A   235 bytes   vtable slot 0x3C   sig ()i   KIND=Function (static)
' byte-identical vs NSS5.exe (235/235, mode=reloc, reloc_masked=13)
'
' ASSUMPTIONS (module Global names are ours; declared types are load-bearing):
'   g_lg_combonation    = 0x00C66F34  TCombo  (slots 0x8C ClearItems / 0x90 AddItem)
'   g_lg_table1         = 0x00C66F20  TTable  (slot 0x9C ClearItems)
'   g_lg_table2         = 0x00C66F24  TTable  (slot 0x54 TGadget.Hide, inherited)
'   g_lg_table3         = 0x00C66F28  TTable
'   g_lg_combocontinent = 0x00C66F30  TCombo  (slot 0xC0 GetSelectedItemId)
' The trailing call goes through this Type's own class table + 0x40, so it is the bare
' sibling form ComboNation(), not TScreen_Leagues.ComboNation() (codegen-patterns 3d).

	Function ComboContinent:Int()
		'!Global g_lg_combonation:TCombo
		'!Global g_lg_combocontinent:TCombo
		'!Global g_lg_table1:TTable
		'!Global g_lg_table2:TTable
		'!Global g_lg_table3:TTable
		g_lg_combonation.ClearItems()
		g_lg_table1.ClearItems()
		g_lg_table3.Hide()
		g_lg_table2.Hide()
		For Local n:TNation = EachIn TNation.SelectListByContinent(g_lg_combocontinent.GetSelectedItemId())
			If n.HasLeagues()
				g_lg_combonation.AddItem(n.labelname,"BBBBBB","FFFFFF",n.id)
			EndIf
		Next
		ComboNation()
	End Function
