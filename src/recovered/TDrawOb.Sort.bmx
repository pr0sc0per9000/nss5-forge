' TDrawOb.Sort
' VA 0x004cd83d   66 bytes   vtable slot 0x3c   sig ()i
' byte-identical vs NSS5.exe (66/66, original length from Ghidra's inventory)
' assumes module global at 0x00C5AF6C typed TList
' The null test materialises (setne/movzx/cmp) -- that is object truthiness under `Not`,
' not `= Null` / `<> Null`, which bcc folds into a direct `cmp [mem], imm`.
' TList slot 0x88 = Sort(); FUN_005B3516 is _brl_linkedlist_CompareObjects (the default).
	Function Sort:Int()
		'!Global g_drawobs:TList
		If Not g_drawobs Then Return 0
		g_drawobs.Sort()
	End Function
