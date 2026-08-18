' TNation.SortListBy
' VA 0x004bfab1   151 bytes   vtable slot 0x78   sig (i,i)i
' byte-identical vs NSS5.exe (151/151, original length from Ghidra's inventory)
' assumptions: module Global at 0x00c596f0 declared as g_nations:TList
'              module Global at 0x00c596f4 declared as g_natsortby:Int
' the FUN_005b3516 pushed at the Sort call site is BRL _brl_linkedlist_CompareObjects,
' i.e. Sort's DEFAULT comparator -- the source passes only the ascending flag
	Function SortListBy:Int(a0:Int,a1:Int)
		'!Global g_natsortby:Int
		'!Global g_nations:TList
		g_natsortby=a0
		If a0=5 Then
			For Local n:TNation=EachIn g_nations
				n.randno=Rand(9999,1)
			Next
		EndIf
		g_nations.Sort(a1)
	End Function
