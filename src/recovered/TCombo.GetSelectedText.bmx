' TCombo.GetSelectedText
' VA 0x005192e2   31 bytes   vtable slot 0xc4   sig ()$
' byte-identical vs NSS5.exe (31/31, original length from Ghidra's inventory)
' Fields from object_model.json: TCombo.selecteditem @0x68, TCombo.btn_head @0x5C
' (:TButton), TGadget.txt @0x10 ($) inherited by TButton.
	Method GetSelectedText:String()
		If selecteditem < 1
			Return ""
		Else
			Return btn_head.txt
		EndIf
	End Method
