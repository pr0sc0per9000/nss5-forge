' TTable.SetItemIcons
' VA 0x0051645b   146 bytes   vtable slot 0x98   sig (i,[]:TImage)i
' byte-identical vs NSS5.exe (146/146, original length from Ghidra's inventory, mode=reloc)
' assumptions: TTable field +0x60 = items:TList; downcast class table 0x00c62d6c = TRow;
'              TRow field +0xc = icons:TImage[].
' The counter is incremented inside the loop body, i.e. after the EachIn downcast, which
' is where bcc puts it anyway.
	Method SetItemIcons:Int(a0:Int, a1:TImage[])
		Local n:Int = 1
		For Local r:TRow = EachIn Self.items
			If n = a0 Then r.icons = a1
			n :+ 1
		Next
	End Method
