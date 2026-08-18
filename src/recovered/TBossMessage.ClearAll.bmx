' TBossMessage.ClearAll
' VA 0x00570ea8   69 bytes   vtable slot 0x40   sig ()i
' byte-identical vs NSS5.exe (69/69, original length from Ghidra's inventory)
' harness mode=reloc.
' The guard is an EARLY RETURN, not an If-block: the object is materialised as a
'   boolean (cmp/setne/movzx/cmp eax,0/jne) which is what `If Not <object>` emits.
'   `If g <> Null` instead emits cmp [mem],imm / je and lands at 53 bytes.
' The LogLine literal really is "TScreenMessage.ClearAll" in the image at 0x00c8f58c
'   -- a copy/paste in the original source, kept because it is load-bearing.
' slot 0x34 on the Global = TList.Clear().
' module Globals assumed by this body (names ours, types load-bearing):
'   Global g_bossmsg_list:TList     ' 0x00c6b284
	Function ClearAll:Int()
		'!Global g_bossmsg_list:TList
		If Not g_bossmsg_list Then Return 0
		LogLine("TScreenMessage.ClearAll")
		g_bossmsg_list.Clear()
	End Function
