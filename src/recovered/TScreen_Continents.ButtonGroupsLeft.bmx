' TScreen_Continents.ButtonGroupsLeft
' VA 0x00548F87   123 bytes   vtable slot 0x6c   sig ()i
' byte-identical vs NSS5.exe (123/123, original length from Ghidra's inventory)
' Parameter names are not recoverable from the binary and do not affect codegen;
' they are emitted as a0, a1, ... exactly as the harness compiles them.
' ASSUMPTIONS: Globals 0x00c671ec:Int, 0x00c671e4:TCombo, 0x00c67220:TCompetition, 0x00c67208:Int.
' PTR_FUN_00c6160c = TCompetition + 0x4c = TCompetition.SelectById;
' PTR_FUN_00c67498 = TScreen_Continents.SetUpLeagueTable; PTR_FUN_00c67480 = ...SetUpFixturesTable.

	Function ButtonGroupsLeft:Int()
		'!Global g_grouppage:Int
		'!Global g_cmbGroups:TCombo
		'!Global g_curcomp:TCompetition
		'!Global g_contid:Int
		g_grouppage :- 1
		If g_cmbGroups.GetSelectedItemId() > 0 Then g_curcomp = TCompetition.SelectById(g_cmbGroups.GetSelectedItemId())
		TScreen_Continents.SetUpLeagueTable()
		TScreen_Continents.SetUpFixturesTable(g_contid)
	End Function
