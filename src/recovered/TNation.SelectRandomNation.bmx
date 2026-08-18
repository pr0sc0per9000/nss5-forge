' TNation.SelectRandomNation
' VA 0x004bed1a   236 bytes   vtable slot 0x?   sig (i):TNation
' byte-identical vs NSS5.exe (236/236, original length from Ghidra's inventory, mode=reloc)
' Assumptions: 0x00C596F0 declared TList (globals_final.tsv says bare Object; slots 0x88 Sort
'   and 0x8C ObjectEnumerator fix it); 0x00C596F4 declared Int -- it is set to 5 immediately
'   before the Sort, so it is the sort-key selector TNation.Compare reads.
'   randno at +0x8 and strength at +0x24 are INHERITED from TBase_Team, not TNation's own.
'   FUN_005B3516 = _brl_linkedlist_CompareObjects; FUN_0059F089 = Rand;
'   FUN_00505B91 = recovered module Function LogLine.
'!Global g_nationlist:TList
'!Global g_nation_sortby:Int
	Function SelectRandomNation:TNation(a0:Int)
		For Local n:TNation = EachIn g_nationlist
			n.randno = Rand(9999, 1)
		Next
		g_nation_sortby = 5
		g_nationlist.Sort(1, CompareObjects)
		For Local n:TNation = EachIn g_nationlist
			If n.strength > a0 Then Return n
		Next
		LogLine("No nation found!")
		Return Null
	End Function
