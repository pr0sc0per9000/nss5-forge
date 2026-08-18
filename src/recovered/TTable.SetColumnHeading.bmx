' TTable.SetColumnHeading
' VA 0x00516513   146 bytes   vtable slot 0xa0   sig (i,$)i
' byte-identical vs NSS5.exe (146/146, original length from Ghidra's inventory)
' harness mode=reloc.

	Method SetColumnHeading:Int(a0:Int, a1:String)
		Local n:Int = 0
		For Local c:TColumn = EachIn columns
			If n = a0 Then c.heading = a1
			n = n + 1
		Next
	End Method
