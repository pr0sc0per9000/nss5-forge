' TCombo.ScrollUp -- VA 0x005188D4, 128 bytes
' byte-identical vs NSS5.exe
' Parameter names are not recoverable from the binary and do not affect codegen.
Method ScrollUp:Int()
	Local noofitems:Int = buttons.Count()
	Local noofdisplayitems:Int = GetNoofDisplayItems()
	selecteditem = selecteditem - 1
	If selecteditem < 1
		selecteditem = 0
		Deactivate()
		Return 0
	EndIf
	If selecteditem > noofitems Then selecteditem = noofitems
	If noofitems > noofdisplayitems And selecteditem - itemoffset < 1 Then itemoffset = itemoffset - 1
End Method
