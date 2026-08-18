' TNation.SelectListByContinent
' VA 0x004BEE99   116 bytes   vtable slot 0x68   sig (i):TList
' byte-identical vs NSS5.exe (116/116, original length from Ghidra's inventory)
' Parameter names are not recoverable from the binary and do not affect codegen;
' they are emitted as a0, a1, ... exactly as the harness compiles them.
' ASSUMPTION: module Global at 0x00c596f0 declared TList (the nation list).
' FUN_005b40bf = _brl_linkedlist_CreateList.

	Function SelectListByContinent:TList(a0:Int)
		'!Global g_nations:TList
		Local l:TList = CreateList()
		For Local n:TNation = EachIn g_nations
			If n.continent = a0 Then l.AddLast(n)
		Next
		Return l
	End Function
