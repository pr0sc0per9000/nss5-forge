' TPlayer.UpdateCalling
' VA 0x004ef0a6   76 bytes   vtable slot 0x60   sig ()i
' byte-identical vs NSS5.exe (76/76, original length from Ghidra's inventory)
' assumes module global:  Global g_player_int50:Int
' global 0x00c6efd4 (match clock); both early returns are required

	Method UpdateCalling:Int()
		'!Global g_player_int50:Int
		If controller <> 1
			calling = 0
			Return 0
		EndIf
		If g_player_int50 > calling + 2000
			calling = 0
			Return 0
		EndIf
	End Method
