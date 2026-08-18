' TCombo.GetSelectedColour
' VA 0x00519301   113 bytes   vtable slot 0xc8   sig ()$
' byte-identical vs NSS5.exe (113/113, original length from Ghidra's inventory)
' EachIn downcast class table 0x00c62344 = TButton; b.colour is the inherited
' TGadget field at +0x30. The fallback constant at 0x00c6fc58 is the string "000000".
	Method GetSelectedColour:String()
		Local i:Int = 1
		For Local b:TButton = EachIn buttons
			If i = selecteditem Then Return b.colour
			i = i + 1
		Next
		Return "000000"
	End Method
