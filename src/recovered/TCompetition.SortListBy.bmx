' TCompetition.SortListBy
' VA 0x0050ea40   48 bytes   vtable slot 0x11c   sig (i,i)i
' byte-identical vs NSS5.exe (48/48, original length from Ghidra's inventory)
' assumes module globals: 0x00C609A0 typed Int (sort key), 0x00C6099C typed TList
' TList slot 0x88 = Sort(i,(:Object,:Object)i); FUN_005B3516 is _brl_linkedlist_CompareObjects,
' i.e. the default comparator, so the second argument is left defaulted.
	Function SortListBy:Int(a0:Int, a1:Int)
		'!Global g_compsortby:Int
		'!Global g_competitions:TList
		g_compsortby = a0
		g_competitions.Sort(a1)
	End Function
