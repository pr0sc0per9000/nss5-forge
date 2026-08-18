' TTeamPool.GetTeamPosition
' VA 0x0052676A   123 bytes   vtable slot 0x50   sig (i)i
' byte-identical vs NSS5.exe (123/123, original length from Ghidra's inventory)
' harness mode=reloc: absolute addresses (data pointers, string/array constants, class tables)
'   differ by construction between probe and NSS5.exe; the emitted code is identical.

	Method GetTeamPosition:Int(a0:Int)
		SortTableBy(4)
		Local p:Int = 1
		For Local td:TTableData = EachIn list
			If td.teamid = a0 Then Return p
			p = p + 1
		Next
		Return 0
	End Method
