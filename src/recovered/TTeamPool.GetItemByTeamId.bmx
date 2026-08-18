' TTeamPool.GetItemByTeamId
' VA 0x00526704   102 bytes   vtable slot 0x4c   sig (i):TTableData
' byte-identical vs NSS5.exe (102/102, original length from Ghidra's inventory)
' EachIn downcast class table 0x00c64b80 = TTableData.
	Method GetItemByTeamId:TTableData(a0:Int)
		For Local d:TTableData = EachIn list
			If d.teamid = a0 Then Return d
		Next
		Return Null
	End Method
