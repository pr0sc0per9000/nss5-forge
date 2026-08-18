' TPitch.IsOnPitch
' VA 0x004e9df2   108 bytes   vtable slot 0x58   sig (i,i)i
' byte-identical vs NSS5.exe (108/108, original length from Ghidra's inventory)
' two module Globals assumed Int at 0x00c5d634 / 0x00c5d638; names invented
	Function IsOnPitch:Int(a0:Int, a1:Int)
		'!Global g_pitch_halfw:Int
		'!Global g_pitch_halfh:Int
		If a0 < -g_pitch_halfw Or a0 > g_pitch_halfw
			Return 0
		ElseIf a1 < -g_pitch_halfh Or a1 > g_pitch_halfh
			Return 0
		Else
			Return 1
		EndIf
	End Function
