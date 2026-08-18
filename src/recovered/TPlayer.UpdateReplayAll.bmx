' TPlayer.UpdateReplayAll
' VA 0x004FE532   108 bytes   vtable slot 0x208   sig (i)i
' byte-identical vs NSS5.exe (108/108, original length from Ghidra's inventory)
' ASSUMPTION: module Global at 0x00C5DE10 declared :TList.
' harness mode=reloc.

	Function UpdateReplayAll:Int(a0:Int)
		'!Global g_players:TList
		For Local p:TPlayer = EachIn g_players
			p.UpdateReplay(a0)
		Next
	End Function
