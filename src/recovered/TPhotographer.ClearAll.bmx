' TPhotographer.ClearAll
' VA 0x004EB285   28 bytes   vtable slot 0x44   sig ()i
' byte-identical vs NSS5.exe (28/28, original length from Ghidra's inventory)
' ASSUMPTION: module Global at 0x00c5db1c declared :TList (slot 0x34 = TList.Clear); the declared type is load-bearing
	Function ClearAll:Int()
		'!Global g_photographers:TList
		g_photographers.Clear()
	End Function
