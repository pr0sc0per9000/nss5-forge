' TPlayer.RenderAll
' VA 0x004ee2e0   96 bytes   vtable slot 0x4c   sig (f)i
' byte-identical vs NSS5.exe (96/96, original length from Ghidra's inventory)
' Assumption: module Global at 0x00c5de10 declared TList (name ours; declared type is
' load-bearing). Loop variable type TPlayer proved by the downcast class table 0x00c5f94c.
	Function RenderAll(a0:Float)
		'!Global g_players:TList
		For Local p:TPlayer = EachIn g_players
			p.Render(a0)
		Next
	End Function
