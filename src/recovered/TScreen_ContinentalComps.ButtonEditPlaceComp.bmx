' TScreen_ContinentalComps.ButtonEditPlaceComp
' VA 0x00534275   98 bytes   vtable slot 0x4c   sig ()i
' byte-identical vs NSS5.exe (98/98, original length from Ghidra's inventory)
' assumptions: Global 0x00c65a48 declared TTable (globals_final: typed from its construction
'   site) -- load-bearing, it selects slot 0xd8 = TTable.GetSelectedText(i)$.
' FUN_004a7130 = _bbStringToInt, FUN_004a7ac0 = _bbStringFromInt, FUN_004a7c20 =
'   _bbStringConcat (runtime_helpers.tsv) -- i.e. the source is `"literal" + id`.
' FUN_00505b91 = the recovered module Function LogLine; 0x00c8492c = "ButtonEditPlaceComp:".
' 0x00c658d8 = TScreen_EditCompetition classtable+0x34 -> SetUpScreen(i,$)i;
' 0x00c837a4 = "continentalcomps".
	Function ButtonEditPlaceComp:Int()
		'!Global g_table:TTable
		Local id:Int = Int(g_table.GetSelectedText(0))
		LogLine("ButtonEditPlaceComp:" + id)
		If id <> 0
			TScreen_EditCompetition.SetUpScreen(id, "continentalcomps")
		EndIf
	End Function
