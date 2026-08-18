' THorse.CountHorsesOwned
' VA 0x0058B973   103 bytes   vtable slot 0x78   sig ()i
' byte-identical vs NSS5.exe (103/103, original length from Ghidra's inventory)
' ASSUMPTION: Global 0x00c6e294 declared :TList; loop element type THorse from class table 0x00c6e788
	Function CountHorsesOwned:Int()
		'!Global g_horses:TList
		Local c:Int = 0
		For Local h:THorse = EachIn g_horses
			If h.owned = 1 Then c = c + 1
		Next
		Return c
	End Function
