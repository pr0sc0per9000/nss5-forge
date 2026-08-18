' TScreenMessage.RemoveFirst
' VA 0x005707a3   121 bytes   vtable slot 0x4c   sig ()i
' byte-identical vs NSS5.exe (121/121, original length from Ghidra's inventory)
' Assumptions: module Global at 0x00c6afdc declared TList, 0x00c6efd4 declared Int
' (names ours; the declared types are load-bearing).
	Function RemoveFirst()
		'!Global g_messages:TList
		'!Global g_msgtop:Int
		g_messages.RemoveFirst()
		Local y:Int = g_msgtop
		For Local m:TScreenMessage = EachIn g_messages
			m.starttime = y
			y = y + m.delaytime
			m.finishtime = y
		Next
	End Function
