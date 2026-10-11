' TScreen_Continents.ButtonGroupsFirst
' VA 0x00548F09   126 bytes   vtable slot 0x68   sig ()i
' byte-identical vs NSS5.exe (126/126, original length from Ghidra's inventory)
' Parameter names are not recoverable from the binary and do not affect codegen;
' they are emitted as a0, a1, ... exactly as the harness compiles them.
' Same globals and call targets as ButtonGroupsLeft; only the first statement differs.

' NAME CHANGED 2026-10-11 (byte-neutral): 0x00548F4D `a12072c600` and
' 0x00548F60 `891d2072c600` read and store 0x00C67220, this screen's competition
' (g_continents_comp, which ButtonGroupsRight/Last spell g_cont_comp). g_curcomp is
' TScreen_EditCompetition's competition, 0x00C65720.
	Function ButtonGroupsFirst:Int()
		'!Global g_grouppage:Int
		'!Global g_cmbGroups:TCombo
		'!Global g_continents_comp:TCompetition
		'!Global g_contid:Int
		g_grouppage = 0
		If g_cmbGroups.GetSelectedItemId() > 0 Then g_continents_comp = TCompetition.SelectById(g_cmbGroups.GetSelectedItemId())
		TScreen_Continents.SetUpLeagueTable()
		TScreen_Continents.SetUpFixturesTable(g_contid)
	End Function
