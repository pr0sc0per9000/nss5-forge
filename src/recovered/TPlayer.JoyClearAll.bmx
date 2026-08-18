' TPlayer.JoyClearAll
' VA 0x004f2e8a   99 bytes   vtable slot 0xb0   sig ()i
' byte-identical vs NSS5.exe (99/99, original length from Ghidra's inventory)
' assumption: module Global at 0x00c5de10 declared as g_players:TList
	Function JoyClearAll:Int()
		'!Global g_players:TList
		For Local p:TPlayer=EachIn g_players
			p.joy.Clear()
		Next
	End Function
