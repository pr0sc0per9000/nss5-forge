' TScreen_Promotions.ButtonPromote
' VA 0x005333CA   192 bytes   vtable slot 0x40   sig ()i   KIND=Function (static)
' byte-identical vs NSS5.exe (192/192, original length from Ghidra's inventory, mode=reloc)
' assumptions: Globals 0x00C658F8=TNation, 0x00C65904=TCombo, 0x00C65908 / 0x00C6590C=TTable
' (all four typed by construction site in globals_final.tsv). The three class-table pointers
' resolve to 0x00C59E0C = TClub+0x60 = TClub.SelectById(i):TClub,
' 0x00C61610 = TCompetition+0x50 = TCompetition.SelectByBasedAndName(i,$),
' 0x00C65A08 = TScreen_Promotions+0x34 = SetUpScreen (own Type -> no prefix).
' 0x004A7130 is _bbStringToInt, i.e. the Int(...) wrapping GetSelectedText.
	Function ButtonPromote:Int()
		'!Global g_promo_nation:TNation
		'!Global g_promo_combo:TCombo
		'!Global g_promo_table1:TTable
		'!Global g_promo_table2:TTable
		If Not g_promo_nation Then Return 0
		Local c:TClub = TClub.SelectById(Int(g_promo_table1.GetSelectedText(1)))
		Local comp:TCompetition = TCompetition.SelectByBasedAndName(g_promo_nation.id, g_promo_combo.GetSelectedText())
		If c <> Null And comp <> Null
			c.leagueid = comp.id
			SetUpScreen()
			g_promo_table2.SelectItemByText(c.name, 0)
		EndIf
	End Function
