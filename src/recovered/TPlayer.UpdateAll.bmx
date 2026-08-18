' TPlayer.UpdateAll
' VA 0x004ee0b2   105 bytes   vtable slot 0x44   sig ()i
' byte-identical vs NSS5.exe (105/105, original length from Ghidra's inventory)
' assumes module global:  Global g_players:TList  (0x00c5de10)
' the two sibling Functions are reached through the absolute class-table slots
' TPlayer+0xd0 (CheckPlayerContactAll) and TPlayer+0x78 (UpdatePassPotentialAll)

	Function UpdateAll:Int()
		'!Global g_players:TList
		TPlayer.CheckPlayerContactAll()
		For Local p:TPlayer = EachIn g_players
			p.Update()
		Next
		TPlayer.UpdatePassPotentialAll()
	End Function
