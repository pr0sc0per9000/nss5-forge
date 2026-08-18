' TCombo.ScrollDown -- VA 0x00518954, 100 bytes
' byte-identical vs NSS5.exe
' Parameter names are not recoverable from the binary and do not affect codegen.
Method ScrollDown:Int()
	Local noofitems:Int = buttons.Count()
	Local noofdisplayitems:Int = GetNoofDisplayItems()
	selecteditem = selecteditem + 1
	If selecteditem > noofitems Then selecteditem = noofitems
	If noofitems > noofdisplayitems And selecteditem - itemoffset > noofdisplayitems - 2 Then itemoffset = itemoffset + 1
End Method
