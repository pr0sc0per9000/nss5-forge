' TBall.UpdateAlpha
' VA 0x004c8695   138 bytes   vtable slot 0x58   sig ()i
' byte-identical vs NSS5.exe (138/138, original length from Ghidra's inventory)
' global 0x00c5b1fc assumed Int (g_player_int01). The "active" branch is the FIRST branch in source.
' Parameter names are not recoverable from the binary; a0/a1/... as emitted by the harness.
	Method UpdateAlpha:Int()
		'!Global g_matchstate:Int
		If active
			If alph < 1.0 Then alph :+ 0.025
		Else
			If alph > 0.0 Then alph :- 0.015
			If g_matchstate = 10 Or g_matchstate = 2 Then alph = 0
		EndIf
	End Method
