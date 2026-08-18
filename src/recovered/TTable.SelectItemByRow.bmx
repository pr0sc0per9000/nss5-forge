' TTable.SelectItemByRow
' VA 0x00517bb7   69 bytes   vtable slot 0xdc   sig (i)i
' byte-identical vs NSS5.exe

	Method SelectItemByRow:Int(a0:Int)
		If items.Count() < a0 Then a0 = items.Count()
		selecteditem = a0
		CheckTableOffset()
	End Method
