' TScreen_Promotions.ComboNation
' VA 0x00533266   356 bytes   vtable slot 0x3c   sig ()i   KIND=Function
' byte-identical vs NSS5.exe (356/356, original length from Ghidra's inventory)
'
' GLOBAL NAMES ARE OURS; the DECLARED TYPES are load-bearing (they pick the vtable slot).
' `call [0x00C65A08]` is TScreen_Promotions + 0x34, i.e. this Type's own SetUpScreen.
' Written unqualified (`SetUpScreen()`) it emits the absolute class-table call, which is
' right here because ComboNation is a KIND=Function (no Self to dispatch through).
'!Global g_prom_nation:TNation
'!Global g_prom_combonation:TCombo
'!Global g_prom_combo1:TCombo
'!Global g_prom_combo2:TCombo
'!Global g_allcompetitions:TList
	Function ComboNation:Int()
		g_prom_nation = TNation.SelectById(g_prom_combonation.GetSelectedItemId())
		g_prom_combo1.ClearItems()
		g_prom_combo2.ClearItems()
		If g_prom_nation <> Null
			For Local c:TCompetition = EachIn g_allcompetitions
				If c.level = 0 And c.locale = 0 And c.comptype = 0 And c.based = g_prom_nation.id
					g_prom_combo1.AddItem(c.name, "BBBBBB", "FFFFFF", 0)
					g_prom_combo2.AddItem(c.name, "BBBBBB", "FFFFFF", 0)
				EndIf
			Next
			SetUpScreen()
		EndIf
	End Function
