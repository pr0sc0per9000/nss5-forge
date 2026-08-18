' TScreenMessage.Count
' VA 0x0056ff47   51 bytes   vtable slot 0x34   sig ()i
' byte-identical vs NSS5.exe (51/51, original length from Ghidra's inventory)
' ASSUMPTION: module Global at 0x00c6afdc declared :TList (type is load-bearing -- selects
' slot 0x70 = TList.Count). `If Not <obj>` is the form that materialises the boolean
' (setne/movzx/cmp); `= Null` / `<> Null` both peephole to a direct cmp and come out 9 short.
	Function Count()
		'!Global g_screenMessages:TList
		If Not g_screenMessages Then Return 0
		Return g_screenMessages.Count()
	End Function
