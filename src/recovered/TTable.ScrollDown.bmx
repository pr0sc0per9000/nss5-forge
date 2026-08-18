' TTable.ScrollDown
' VA 0x00516ccd   85 bytes   vtable slot 0xc4   sig ()i
' byte-identical vs NSS5.exe

	Method ScrollDown:Int()
		Local c:Int = items.Count()
		Local n:Int = GetNoofDisplayItems()
		selecteditem = selecteditem + 1
		If selecteditem > c Then selecteditem = c
		If selecteditem > n Then
			itemoffset = itemoffset + 1
			selecteditem = n
		EndIf
		If itemoffset > c - n Then itemoffset = c - n
	End Method
