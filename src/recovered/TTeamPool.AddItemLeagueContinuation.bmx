' TTeamPool.AddItemLeagueContinuation
' VA 0x00526609   55 bytes   vtable slot 0x3c   sig (:TTableData)i
' byte-identical vs NSS5.exe

	Method AddItemLeagueContinuation:Int(a0:TTableData)
		a0.id = list.Count() + 1
		list.AddLast(a0)
	End Method
