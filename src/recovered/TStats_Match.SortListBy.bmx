' TStats_Match.SortListBy
' VA 0x0056e2af   47 bytes   vtable slot 0x44   sig (i)i
' byte-identical vs NSS5.exe (47/47, original length from Ghidra's inventory)
' ASSUMPTION: module Global at 0x00c6a8a4 declared as Int (name ours; the original
' name is unrecoverable). It is the sort key TStat.Compare reads.
' list.Sort() with no arguments reproduces the pushed defaults (True, CompareObjects).
	Method SortListBy:Int(a0:Int)
		'!Global g_stats_sortby:Int
		g_stats_sortby = a0
		list.Sort()
	End Method
