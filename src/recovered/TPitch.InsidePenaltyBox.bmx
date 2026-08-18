' TPitch.InsidePenaltyBox
' VA 0x004E9E5E   212 bytes   vtable slot 0x5c   sig (i,i,i)i
' byte-identical vs NSS5.exe (212/212, original length from Ghidra's inventory)
' mode 'reloc': absolute addresses masked, emitted code identical
' module global assumed: Global g_engine_int103:Int
' module global assumed: Global g_player_int17:Int
' module global assumed: Global g_pitch_int11:Int

	Function InsidePenaltyBox:Int(a0:Int, a1:Int, a2:Int)
		'!Global g_engine_int103:Int
		'!Global g_player_int17:Int
		'!Global g_pitch_int11:Int
		If a0 < -g_engine_int103 Or a0 > g_engine_int103 Then Return 0
		If a1 < -g_player_int17 Or a1 > g_player_int17 Then Return 0
		If a1 > -g_pitch_int11 And a1 < g_pitch_int11 Then Return 0
		Select a2
			Case -1
				If a1 < 0 Then Return 1
			Case 0
				Return 1
			Case 1
				If a1 > 0 Then Return 1
		End Select
		Return 0
	End Function
