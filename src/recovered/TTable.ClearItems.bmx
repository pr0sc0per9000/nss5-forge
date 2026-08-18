' TTable.ClearItems
' VA 0x005164ed   38 bytes   vtable slot 0x9c   sig ()i
' byte-identical vs NSS5.exe

	Method ClearItems:Int()
		items.Clear()
		selecteditem = 0
	End Method
