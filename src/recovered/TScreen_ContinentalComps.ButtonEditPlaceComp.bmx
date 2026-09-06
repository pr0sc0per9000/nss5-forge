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
		' 0x00C65A48, this screen's places table, measured at 0x00534279
' `a1485ac600 mov eax,[0xc65a48]`; TScreen_ContinentalComps.CreateScreen builds it as
' g_cc_tableplaces. g_table is TScreen_EditNations.CreateScreen's name for 0x00C65038.
'!Global g_cc_tableplaces:TTable
		Local id:Int = Int(g_cc_tableplaces.GetSelectedText(0))
		LogLine("ButtonEditPlaceComp:" + id)
		If id <> 0
			TScreen_EditCompetition.SetUpScreen(id, "continentalcomps")
		EndIf
	End Function
