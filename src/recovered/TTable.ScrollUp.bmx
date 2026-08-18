' TTable.ScrollUp
' VA 0x00516c9a   51 bytes   vtable slot 0xc0   sig ()i
' byte-identical vs NSS5.exe

	Method ScrollUp:Int()
		selecteditem = selecteditem - 1
		If selecteditem <= 0 Then
			itemoffset = itemoffset - 1
			selecteditem = 1
		EndIf
		If itemoffset < 0 Then itemoffset = 0
	End Method
