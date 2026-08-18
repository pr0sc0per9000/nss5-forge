' TWeather.UpdateReplayRain
' VA 0x00505303   138 bytes   vtable slot 0x44   sig (f,i)i
' byte-identical vs NSS5.exe (138/138, original length from Ghidra's inventory, mode=reloc)
' Globals: 0x00C7BABC g_wx_frame:Int, 0x00C600E4 g_wx_alpha:Float, 0x00C600DC g_wx_last:Int,
'          0x00C600E0 g_wx_idx:Int, 0x00C6EFD4 g_ticks:Int (globals_final says TScreen with a
'          flagged conflict -- it is an Int, cf. guide 10.7), 0x00C600D4 g_rainchan:TChannel
'          (TChannel slot 0x38 = SetVolume, corroborated by UpdateRain using 0x48 = Playing).
' 0x00505F90 is the recovered module Function ClampFloat.
' Operand order matters: `g_ticks > g_wx_last + 70` emits `cmp [g_ticks],eax / jle`;
' the reversed spelling emits `cmp eax,[g_ticks] / jge` and mismatches at byte 45.
	Function UpdateReplayRain:Int(a0:Float, a1:Int)
		'!Global g_wx_frame:Int
		'!Global g_wx_alpha:Float
		'!Global g_ticks:Int
		'!Global g_wx_last:Int
		'!Global g_wx_idx:Int
		'!Global g_rainchan:TChannel
		If a1 = g_wx_frame Then Return 0
		g_wx_frame = a1
		g_wx_alpha = a0
		If g_ticks > g_wx_last + 70
			g_wx_last = g_ticks
			g_wx_idx = g_wx_idx - 1
			If g_wx_idx < 0 Then g_wx_idx = 7
		End If
		ClampFloat(Varptr g_wx_alpha, 0, 0.35)
		g_rainchan.SetVolume(0)
	End Function
