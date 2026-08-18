' TScreen_Kits.ButtonChangeKits
' VA 0x00549d89   46 bytes   vtable slot 0x38   sig ()i
' byte-identical vs NSS5.exe (46/46, original length from Ghidra's inventory)
' assumes module global:  Global g_screen_kits_int05:Int
' global 0x00c674c4 named from globals_named.tsv; RefreshKits is TScreen_Kits vtable slot 0x3c

	Function ButtonChangeKits:Int()
		'!Global g_screen_kits_int05:Int
		g_screen_kits_int05 = g_screen_kits_int05 + 1
		If g_screen_kits_int05 > 3 Then g_screen_kits_int05 = 0
		RefreshKits()
	End Function
