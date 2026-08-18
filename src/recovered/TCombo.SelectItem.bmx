' TCombo.SelectItem
' VA 0x00518EF3   253 bytes   vtable slot 0xAC   sig (i)i
' byte-identical vs NSS5.exe (253/253, original length from Ghidra's inventory, mode=reloc)
' assumptions: 0x00505B91 is the recovered module Function LogLine; 0x004A7AC0 is
' _bbStringFromInt and 0x004A7C20 _bbStringConcat, i.e. the argument is "SelectItem:" + a0
' with the literal read out of .rdata at 0x00C7E120. 0x00C5D284 is the empty string.
' Slot 0x98 on Self is TCombo.ScrollDown; slot 0x64 on Self.btn_head is TGadget.SetText
' ($,$,i,i) (INHERITED -- TButton has no 0x64 of its own); TButton.txt is at +0x10.
' The zero guard is a real EARLY RETURN (`cmp [a0],0 / jne body / mov eax,0 / jmp end`).
' Written as an enclosing If-block the body is 247 bytes.
	Method SelectItem:Int(a0:Int)
		LogLine("SelectItem:" + a0)
		Self.itemoffset = 0
		Self.selecteditem = 0
		If a0 = 0 Then Return 0
		Local n:Int = 1
		For Local b:TButton = EachIn Self.buttons
			Self.ScrollDown()
			If n = a0
				Self.btn_head.SetText(b.txt, "", -1, -1)
				Return 0
			EndIf
			n = n + 1
		Next
		Self.itemoffset = 0
		Self.selecteditem = 0
	End Method
