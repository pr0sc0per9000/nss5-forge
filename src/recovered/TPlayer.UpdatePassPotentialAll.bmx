' TPlayer.UpdatePassPotentialAll
' VA 0x004EFB26   93 bytes   vtable slot 0x78   sig ()i
' byte-identical vs NSS5.exe (93/93, original length from Ghidra's inventory)
' Parameter names are not recoverable from the binary and do not affect codegen;
' they are emitted as a0, a1, ... exactly as the harness compiles them.
' ASSUMPTION: module Global at 0x00c5de10 declared TList (the player list).

	Function UpdatePassPotentialAll:Int()
		'!Global g_players:TList
		For Local p:TPlayer = EachIn g_players
			p.UpdatePassPotential()
		Next
	End Function
