' TPlayer.PlayerDiving
' VA 0x004fca47   37 bytes   vtable slot 0x1b4   sig ()i
' byte-identical vs NSS5.exe (37/37, original length from Ghidra's inventory)
' assumes module global:  Global g_player_arr06:Int[]
' global 0x00c5dec0

	Method PlayerDiving:Int()
		'!Global g_player_arr06:Int[]
		If currentanim = g_player_arr06 Then Return True
		Return False
	End Method
