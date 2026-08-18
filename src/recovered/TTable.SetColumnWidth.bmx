' TTable.SetColumnWidth
' VA 0x005165a5   111 bytes   vtable slot 0xa4   sig (i,i)i
' byte-identical vs NSS5.exe (111/111, original length from Ghidra's inventory)
' No assumptions: Self.columns is TTable+0x5c (:TList), TColumn.w is +0x8.
	Method SetColumnWidth:Int(a0:Int, a1:Int)
		Local n:Int = 0
		For Local c:TColumn = EachIn columns
			If n = a0 Then c.w = a1
			n = n + 1
		Next
	End Method
