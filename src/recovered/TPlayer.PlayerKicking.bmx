' TPlayer.PlayerKicking
' VA 0x004fca91   37 bytes   vtable slot 0x1bc   sig ()i
' byte-identical vs NSS5.exe (37/37, original length from Ghidra's inventory)
' assumes module global:  Global g_player_arr03:Int[]
' global 0x00c5deb4

	Method PlayerKicking:Int()
		'!Global g_player_arr03:Int[]
		If currentanim = g_player_arr03 Then Return True
		Return False
	End Method
