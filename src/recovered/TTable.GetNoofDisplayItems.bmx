' TTable.GetNoofDisplayItems
' VA 0x00517d42   37 bytes   vtable slot 0xf0   sig ()i
' byte-identical vs NSS5.exe

	Method GetNoofDisplayItems:Int()
		Local c:Int = items.Count()
		Local r:Int = numdisplayitems
		If r > c Then r = c
		Return r
	End Method
