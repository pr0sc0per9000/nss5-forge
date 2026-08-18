' TCone.Clear
' VA 0x00583234   32 bytes   vtable slot 0x44   sig ()i
' byte-identical vs NSS5.exe (32/32, original length from Ghidra's inventory)
' Assumption: module Global at 0x00c6d568 declared TList (name ours; the declared type is
' load-bearing -- it selects slot 0x74 = TList.Remove(:Object)).
	Method Clear()
		'!Global g_cones:TList
		g_cones.Remove(Self)
	End Method
