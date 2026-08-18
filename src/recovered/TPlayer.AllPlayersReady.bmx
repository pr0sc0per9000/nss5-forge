' TPlayer.AllPlayersReady
' VA 0x004FAB77   108 bytes   vtable slot 0x154   sig ()i
' byte-identical vs NSS5.exe (108/108, original length from Ghidra's inventory)
' ASSUMPTION: Global 0x00c5de10 declared :TList; element type TPlayer from class table 0x00c5f94c; slot 0x158 = TPlayer.PlayerReady
	Function AllPlayersReady:Int()
		'!Global g_players:TList
		For Local p:TPlayer = EachIn g_players
			If p.PlayerReady() = 0 Then Return 0
		Next
		Return 1
	End Function
