' TTable.SetRowColour
' VA 0x00516695   147 bytes   vtable slot 0xAC   sig (i,$)i
' byte-identical vs NSS5.exe (147/147, original length from Ghidra's inventory, mode=reloc)
' assumptions: the enumerator triple (TList.ObjectEnumerator 0x8C / HasNext 0x30 /
' NextObject 0x34) plus bbObjectDowncast against the TRow class table is a For..EachIn.
' TRow.bgcolour is +0x14 by reflection. The `Return 0` inside the loop is what produces
' the original's break-out-and-fall-into-the-epilogue shape.
	Method SetRowColour:Int(a0:Int, a1:String)
		Local n:Int = 1
		For Local r:TRow = EachIn items
			If n = a0
				r.bgcolour = a1
				Return 0
			EndIf
			n = n + 1
		Next
	End Method
