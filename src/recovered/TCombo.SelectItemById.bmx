' TCombo.SelectItemById
' VA 0x00518ff0   246 bytes   vtable slot 0xb0   sig (i)i
' byte-identical vs NSS5.exe (246/246, original length from Ghidra's inventory)
' The explicit `Return 0` in the If-true branch is load-bearing (mov eax,0 at 0x51902E);
' without it the body is 5 bytes short.
	Method SelectItemById:Int(a0:Int)
		Self.itemoffset = 0
		Self.selecteditem = 0
		If a0 = 0
			Self.btn_head.SetText(Self.txt,"",-1,-1)
			Return 0
		Else
			For Local b:TButton = EachIn Self.buttons
				Self.ScrollDown()
				If Int(b.name) = a0
					Self.btn_head.SetText(b.txt,"",-1,-1)
					Return 0
				EndIf
			Next
			Self.itemoffset = 0
			Self.selecteditem = 0
		EndIf
	End Method
