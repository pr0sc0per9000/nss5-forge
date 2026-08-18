' TPlayer.GetHumanPlayer
' VA 0x004faea3   92 bytes   vtable slot 0x164   sig ():TPlayer
' byte-identical vs NSS5.exe (92/92, original length from Ghidra's inventory)
' Assumes one module Global g_players:TList (0x00c5de10); the EachIn downcast class
' table is 0x00c5f94c = TPlayer.
	Function GetHumanPlayer:TPlayer()
		'!Global g_players:TList
		For Local p:TPlayer = EachIn g_players
			If p.newstar Then Return p
		Next
		Return Null
	End Function
