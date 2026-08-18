' TScreen_Controls.ButtonSimple
' VA 0x00523070   30 bytes   vtable slot 0x38   sig ()i
' byte-identical vs NSS5.exe (30/30, original length from Ghidra's inventory)
' Assumes module global 0x00C5D1AC is Int (globals_named.tsv g_player_int14).
' Class table 0x00C641C4 + 0x40 = RefreshButtons()i.
' Declared: Global g_player_int14:Int
	Function ButtonSimple:Int()
		'!Global g_player_int14:Int
		g_player_int14 = 0
		RefreshButtons()
	End Function
