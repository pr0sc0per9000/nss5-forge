' TPitch.InsideCrossZone
' VA 0x004e9f32   127 bytes   vtable slot 0x60   sig (i,i,i)i
' byte-identical vs NSS5.exe (127/127, original length from Ghidra's inventory)
' globals 0x00c5d64c / 0x00c5d650 assumed Int. The final "return 0" is bcc's implicit return, not a written statement.
' Parameter names are not recoverable from the binary; a0/a1/... as emitted by the harness.
	Function InsideCrossZone:Int(a0:Int, a1:Int, a2:Int)
		'!Global g_crosszone_x:Int
		'!Global g_crosszone_y:Int
		If Abs(a0) < g_crosszone_x Then Return 0
		If Abs(a1) < g_crosszone_y Then Return 0
		Select a2
			Case -1
				If a1 < 0 Then Return 1
			Case 0
				Return 1
			Case 1
				If a1 > 0 Then Return 1
		End Select
	End Function
