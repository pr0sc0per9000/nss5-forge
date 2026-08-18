' TScreen_TestTournaments.ComboCompetition
' VA 0x00538ec9   43 bytes   vtable slot 0x44   sig ()i
' byte-identical vs NSS5.exe (43/43, original length from Ghidra's inventory, mode=reloc)
' assumes module Global (name ours, type load-bearing): Global g_tt_refresh:Int (0x00C66440)
' PTR_FUN_00C665D8 = TScreen_TestTournaments class table + 0x34 -> sibling Function
'   SetUpScreen(), so it is written unqualified.
' LogLine's literal is this function's own name (the trace-logger convention).
'!Global g_tt_refresh:Int

	Function ComboCompetition:Int()
		LogLine("ComboCompetition")
		g_tt_refresh = 1
		SetUpScreen()
	End Function
