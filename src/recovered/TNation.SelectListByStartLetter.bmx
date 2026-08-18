' TNation.SelectListByStartLetter
' VA 0x004BEE06   147 bytes   vtable slot 0x64   sig ($):TList
' byte-identical vs NSS5.exe (147/147, original length from Ghidra's inventory)
' ASSUMPTION: module Global at 0x00c596f0 declared :TList (the declared type is load-bearing)
' FUN_005b40bf = _brl_linkedlist_CreateList (brl_functions_inferred.tsv), FUN_0059c843 = _brl_retro_Left
' element type TNation from class table 0x00c599c8; name is TBase_Team+0x10 (inherited)
	Function SelectListByStartLetter:TList(a0:String)
		'!Global g_nations:TList
		Local l:TList = CreateList()
		For Local n:TNation = EachIn g_nations
			If Left(n.name,1) = a0 Then l.AddLast(n)
		Next
		Return l
	End Function
