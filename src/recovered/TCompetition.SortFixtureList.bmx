' TCompetition.SortFixtureList
' VA 0x0050ea0f   49 bytes   vtable slot 0x118   sig ()i
' byte-identical vs NSS5.exe (49/49, original length from Ghidra's inventory)
' Assumes one module Global g_sortmode:Int (0x00c59e44); original name unrecoverable.
' lfixturelist.Sort() with no arguments emits the defaults True and
' brl.linkedlist.CompareObjects (0x005B3516), matching the original.
	Method SortFixtureList:Int()
		'!Global g_sortmode:Int
		g_sortmode = 17
		lfixturelist.Sort()
	End Method
