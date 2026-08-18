' TPitch.ValidateOnPitch
' VA 0x004EA029   207 bytes   vtable slot 0x7c   sig (*f,*f)i
' byte-identical vs NSS5.exe (207/207, original length from Ghidra's inventory)
' mode 'reloc': absolute addresses masked, emitted code identical
' module global assumed: Global g_player_int16:Int
' module global assumed: Global g_player_int17:Int

	Function ValidateOnPitch:Int(a0:Float Ptr, a1:Float Ptr)
		'!Global g_player_int16:Int
		'!Global g_player_int17:Int
		If a0[0] < -g_player_int16 Then a0[0] = -g_player_int16
		If a0[0] > g_player_int16 Then a0[0] = g_player_int16
		If a1[0] < -g_player_int17 Then a1[0] = -g_player_int17
		If a1[0] > g_player_int17 Then a1[0] = g_player_int17
	End Function
