' TPlayer.ResetKickAll
' VA 0x004F2DD7   96 bytes   vtable slot 0xa8   sig ()i
' byte-identical vs NSS5.exe (96/96, original length from Ghidra's inventory)
' Parameter names are not recoverable from the binary and do not affect codegen;
' they are emitted as a0, a1, ... exactly as the harness compiles them.
' ASSUMPTION: module Global at 0x00c5de10 declared TList (the player list).

	Function ResetKickAll:Int()
		'!Global g_players:TList
		For Local p:TPlayer = EachIn g_players
			p.ResetKick()
		Next
	End Function
