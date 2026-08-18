' TCombo.GetSelectedItemId
' VA 0x00519259   137 bytes   vtable slot 0xc0   sig ()i
' byte-identical vs NSS5.exe (137/137, original length from Ghidra's inventory)
' EachIn downcast class table 0x00c62344 = TButton; b.name is the inherited TGadget
' field at +0x0c and Int(b.name) is _bbStringToInt (0x004A7130).
' The guard must be the early-return form "If selecteditem < 1 Then Return 0"
' (cmp [eax+0x68],1 / jge); the If selecteditem > 0 ... EndIf wrapper is 7 bytes short.
	Method GetSelectedItemId:Int()
		If selecteditem < 1 Then Return 0
		Local i:Int = 1
		For Local b:TButton = EachIn buttons
			If i = selecteditem Then Return Int(b.name)
			i = i + 1
		Next
		Return 0
	End Method
