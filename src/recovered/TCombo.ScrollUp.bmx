' TCombo.ScrollUp -- VA 0x005188D4, 128 bytes
' VA 0x005188d4   128 bytes   vtable slot 0x94   sig ()i
' byte-identical vs NSS5.exe (128/128, original length from Ghidra's inventory)
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
