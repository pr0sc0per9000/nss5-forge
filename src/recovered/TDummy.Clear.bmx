' TDummy.Clear
' VA 0x005836B9   32 bytes   vtable slot 0x44   sig ()i
' byte-identical vs NSS5.exe (32/32, original length from Ghidra's inventory)
' Assumption: module Global at 0x00c6d568 declared as g_dummies:TList (slot 0x74 = TList.Remove).
	Method Clear()
		'!Global g_dummies:TList
		g_dummies.Remove(Self)
	End Method
