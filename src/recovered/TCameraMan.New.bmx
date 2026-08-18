' TCameraMan.New
' VA 0x004eb2a1   71 bytes   vtable slot 0x10   sig ()i
' byte-identical vs NSS5.exe (71/71, original length from Ghidra's inventory)
' ASSUMPTION: module Global at 0x00c5dca0 declared :TList (selects slot 0x44 = TList.AddLast).
' The zeroing of x/y/facing/rot and the classtable store are compiler-generated.
	Method New()
		'!Global g_cameraMen:TList
		g_cameraMen.AddLast(Self)
	End Method
