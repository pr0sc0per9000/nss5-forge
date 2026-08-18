' TClub.SelectListByNationId
' VA 0x004c176e   116 bytes   vtable slot 0x70   sig (i):TList
' byte-identical vs NSS5.exe (116/116, original length from Ghidra's inventory)
' assumes module global:  Global g_Object60:TList  (0x00c59a44, the all-clubs list)
' CreateList() is load-bearing: 'New TList' emits push-classtable + bbObjectNew (8 bytes longer);
' the original calls _brl_linkedlist_CreateList at 0x005B40BF directly.
	Function SelectListByNationId:TList(a0:Int)
		'!Global g_Object60:TList
		Local l:TList = CreateList()
		For Local c:TClub = EachIn g_Object60
			If c.nationid = a0 Then l.AddLast(c)
		Next
		Return l
	End Function
