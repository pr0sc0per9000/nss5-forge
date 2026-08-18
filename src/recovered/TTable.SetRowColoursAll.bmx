' TTable.SetRowColoursAll
' VA 0x00516614   129 bytes   vtable slot 0xa8   sig ($)i
' byte-identical vs NSS5.exe (129/129, original length from Ghidra's inventory)
' element type TRow from class table 0x00c62d6c; TRow+0x14 = bgcolour
	Method SetRowColoursAll:Int(a0:String)
		For Local r:TRow = EachIn items
			r.bgcolour = a0
		Next
	End Method
