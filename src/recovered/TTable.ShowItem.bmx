' TTable.ShowItem
' VA 0x00517cee   60 bytes   vtable slot 0xe8   sig (i)i
' byte-identical vs NSS5.exe

	Method ShowItem:Int(a0:Int)
		Local c:Int = items.Count()
		If a0 > c Then a0 = c
		itemoffset = 0
		If a0 > numdisplayitems Then itemoffset = a0 - numdisplayitems
	End Method
