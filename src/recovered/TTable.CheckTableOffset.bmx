' TTable.CheckTableOffset
' VA 0x00517ca9   69 bytes   vtable slot 0xe4   sig ()i
' byte-identical vs NSS5.exe

	Method CheckTableOffset:Int()
		Local c:Int = items.Count()
		If selecteditem > c Then selecteditem = c
		itemoffset = 0
		If selecteditem > numdisplayitems Then
			itemoffset = selecteditem - numdisplayitems
			selecteditem = numdisplayitems
		EndIf
	End Method
