' TScreen_Controls.ButtonAdvanced
' VA 0x0052308e   30 bytes   vtable slot 0x3c   sig ()i
' byte-identical vs NSS5.exe (30/30, original length from Ghidra's inventory)
' Assumes module global 0x00C5D1AC is Int (globals_named.tsv g_player_int14).
' Declared: Global g_player_int14:Int
	Function ButtonAdvanced:Int()
		'!Global g_player_int14:Int
		g_player_int14 = 1
		RefreshButtons()
	End Function
