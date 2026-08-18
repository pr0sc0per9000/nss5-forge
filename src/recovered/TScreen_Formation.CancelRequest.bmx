' TScreen_Formation.CancelRequest
' VA 0x0054cd28   30 bytes   vtable slot 0x4c   sig ()i
' byte-identical vs NSS5.exe (30/30, original length from Ghidra's inventory)
' Assumes module global 0x00C677DC is Int (globals_named.tsv g_screen_formation_int06).
' Class table 0x00C67944 + 0x3C = RefreshButtons()i.
' Declared: Global g_screen_formation_int06:Int
	Function CancelRequest:Int()
		'!Global g_screen_formation_int06:Int
		g_screen_formation_int06 = 0
		RefreshButtons()
	End Function
