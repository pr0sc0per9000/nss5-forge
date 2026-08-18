' TPlayer.GetPlayerById
' VA 0x004faeff   130 bytes   vtable slot 0x168   sig (i):TPlayer
' byte-identical vs NSS5.exe (130/130, original length from Ghidra's inventory)
' assumes module global at 0x00C5DE10 typed TList; downcast class table 0x00C5F94C
' is TPlayer + 0x00, so the loop variable is TPlayer. Field [4] = +0x10 = id.
	Function GetPlayerById:TPlayer(a0:Int)
		'!Global g_players:TList
		If Not g_players Then Return Null
		For Local p:TPlayer = EachIn g_players
			If p.id = a0 Then Return p
		Next
		Return Null
	End Function
