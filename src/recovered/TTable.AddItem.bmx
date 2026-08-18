' TTable.AddItem
' VA 0x005163B7   164 bytes   vtable slot 0x94   sig ([]$,$,$)i
' byte-identical vs NSS5.exe (164/164, original length from Ghidra's inventory, mode=reloc)
' Assumptions: 0x00C62D6C is the TRow class table (so FUN_004A8F20 = _bbObjectNew builds a
' TRow), fields TRow.fields@+8, TRow.txtcolour@+0x10, TRow.bgcolour@+0x14;
' TTable.items@+0x60 is a TList and slot 0x44 on it is BRL.LinkedList AddLast.
	Method AddItem:Int(a0:String[], a1:String, a2:String)
		Local r:TRow = New TRow
		r.fields = a0
		r.txtcolour = a1
		r.bgcolour = a2
		items.AddLast(r)
		If selecteditem = 0
			selecteditem = 1
			itemoffset = 0
		EndIf
	End Method
