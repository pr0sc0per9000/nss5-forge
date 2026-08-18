' TPlayer.PlayerFalling
' VA 0x004fca6c   37 bytes   vtable slot 0x1b8   sig ()i
' byte-identical vs NSS5.exe (37/37, original length from Ghidra's inventory)
' assumes module global:  Global g_player_arr07:Int[]
' global 0x00c5dec4

	Method PlayerFalling:Int()
		'!Global g_player_arr07:Int[]
		If currentanim = g_player_arr07 Then Return True
		Return False
	End Method
