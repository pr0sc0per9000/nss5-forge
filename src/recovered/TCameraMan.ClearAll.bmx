' TCameraMan.ClearAll
' VA 0x004EBC98   28 bytes   vtable slot 0x4c   sig ()i
' byte-identical vs NSS5.exe (28/28, original length from Ghidra's inventory)
' ASSUMPTION: module Global at 0x00C5DCA0 declared :TList (its slot 0x34 = TList.Clear is load-bearing).
' harness mode=reloc.

	Function ClearAll:Int()
		'!Global g_cameraman_list:TList
		g_cameraman_list.Clear()
	End Function
