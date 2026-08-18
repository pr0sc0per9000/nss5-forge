' TScreen.ClearAll
' VA 0x00510540   140 bytes   vtable slot 0x3c   sig ()i
' byte-identical vs NSS5.exe (140/140, original length from Ghidra's inventory)
' Assumptions: module Global at 0x00c61700 declared TScreen, 0x00c616fc declared TList
' (names ours; the declared types are load-bearing -- they select slot 0x44 TScreen.Clear
' and slot 0x34 TList.Clear respectively).
	Function ClearAll()
		'!Global g_activescreen:TScreen
		'!Global g_screens:TList
		g_activescreen = Null
		For Local s:TScreen = EachIn g_screens
			s.Clear()
		Next
		g_screens.Clear()
	End Function
