' THorse.ResetRands
' VA 0x0058b4ea   113 bytes   vtable slot 0x70   sig ()i
' byte-identical vs NSS5.exe (113/113, original length from Ghidra's inventory)
' Assumption: module Global at 0x00c6e294 declared TList (name ours; declared type is
' load-bearing). 0x0059f089 is BRL _brl_random_Rand (byte-proven in brl_functions.tsv).
' Argument order Rand(1000,1) is the one that reproduces the bytes; Rand(1,1000) differs.
	Function ResetRands()
		'!Global g_allhorses:TList
		For Local h:THorse = EachIn g_allhorses
			h.randno = Rand(1000, 1)
		Next
	End Function
