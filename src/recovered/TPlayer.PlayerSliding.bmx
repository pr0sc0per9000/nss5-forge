' TPlayer.PlayerSliding
' VA 0x004fca22   37 bytes   vtable slot 0x1b0   sig ()i
' byte-identical vs NSS5.exe (37/37, original length from Ghidra's inventory)
' assumes module global:  Global g_player_arr05:Int[]
' global 0x00c5debc (the sliding animation table)

	Method PlayerSliding:Int()
		'!Global g_player_arr05:Int[]
		If currentanim = g_player_arr05 Then Return True
		Return False
	End Method
