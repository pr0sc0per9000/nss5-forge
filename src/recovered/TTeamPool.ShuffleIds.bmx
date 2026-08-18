' TTeamPool.ShuffleIds
' VA 0x0052688e   131 bytes   vtable slot 0x58   sig ()i
' byte-identical vs NSS5.exe (131/131, original length from Ghidra's inventory)
' No global assumptions: everything resolves through Self.list and TTeamPool's own vtable.
	Method ShuffleIds()
		SortTableBy(5)
		Local i:Int = 1
		For Local td:TTableData = EachIn list
			td.id = i
			i = i + 1
		Next
		SortTableBy(1)
	End Method
