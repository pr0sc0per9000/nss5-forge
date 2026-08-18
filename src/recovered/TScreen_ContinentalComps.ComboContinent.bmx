' TScreen_ContinentalComps.ComboContinent
' VA 0x00533F1C   336 bytes   vtable slot 0x3C   sig ()i   KIND=Function (static)
' byte-identical vs NSS5.exe (336/336, mode=reloc, reloc_masked=22)
'
' ASSUMPTIONS (module Global names are ours; declared types are load-bearing):
'   g_cc_continent      = 0x00C65A20  TContinent
'   g_cc_combocontinent = 0x00C65A28  TCombo
'   g_cc_combocomp      = 0x00C65A2C  TCombo
'   g_complist          = 0x00C6099C  TList
' The item text is _bbStringFromInt(c.id) then two _bbStringConcat, with the " " literal
' at 0x00C6EF28 -- i.e. String(c.id) + " " + c.name.

	Function ComboContinent:Int()
		'!Global g_cc_continent:TContinent
		'!Global g_cc_combocontinent:TCombo
		'!Global g_cc_combocomp:TCombo
		'!Global g_complist:TList
		g_cc_continent = TContinent.SelectById(g_cc_combocontinent.GetSelectedItemId())
		g_cc_combocomp.ClearItems()
		If g_cc_continent <> Null
			TCompetition.SortListBy(26,1)
			For Local c:TCompetition = EachIn g_complist
				If c.level = 0 And c.locale = 1 And c.based = g_cc_continent.id
					g_cc_combocomp.AddItem(String(c.id)+" "+c.name,"BBBBBB","FFFFFF",c.id)
				EndIf
			Next
			ComboComp()
		EndIf
	End Function
