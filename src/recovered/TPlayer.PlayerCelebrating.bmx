' TPlayer.PlayerCelebrating
' VA 0x004fd5d2   122 bytes   vtable slot 0x1ec   sig ()i
' byte-identical vs NSS5.exe (122/122, original length from Ghidra's inventory)
' five module globals assumed Int[] (celebration anim tables at 0x00c5ded0..0x00c5dee0); names from globals_named.tsv.
' Parameter names are not recoverable from the binary; a0/a1/... as emitted by the harness.
	Method PlayerCelebrating:Int()
		'!Global g_player_arr10:Int[]
		'!Global g_player_arr11:Int[]
		'!Global g_player_arr12:Int[]
		'!Global g_player_arr13:Int[]
		'!Global g_player_arr14:Int[]
		If currentanim = g_player_arr10
			Return 1
		ElseIf currentanim = g_player_arr11
			Return 1
		ElseIf currentanim = g_player_arr12
			Return 1
		ElseIf currentanim = g_player_arr13
			Return 1
		ElseIf currentanim = g_player_arr14
			Return 1
		Else
			Return 0
		EndIf
	End Method
