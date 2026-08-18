' TPlayer.GetDistanceToByLine
' VA 0x004fb1c0   110 bytes   vtable slot 0x170   sig (i)f
' byte-identical vs NSS5.exe (110/110, original length from Ghidra's inventory)
' global 0x00c5d638 assumed Int (g_player_int17 in globals_named.tsv, renamed here). Abs takes the Double overload.
' Parameter names are not recoverable from the binary; a0/a1/... as emitted by the harness.
	Method GetDistanceToByLine:Float(a0:Int)
		'!Global g_pitch_halflength:Int
		Local d:Int = 0
		Select a0
			Case 0
				d = g_pitch_halflength * -GetShootingDirection()
			Case 1
				d = g_pitch_halflength * GetShootingDirection()
		End Select
		Return Abs(d - y)
	End Method
