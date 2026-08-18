' TTeamPool.GetStringTeamPosition
' VA 0x005267e5   169 bytes   vtable slot 0x54   sig (i)$
' byte-identical vs NSS5.exe (169/169, original length from Ghidra's inventory, mode=reloc)
' slot 0x5C on Self is TTeamPool.SortTableBy(i); Self.list is the field at +0x08.
' the EachIn downcast class table is TTableData (0x00C64B80); teamid is at +0x0C.
' string literals: "position_" (0x00C82284), "None" (0x00C7CF74)
' FUN_004C5549 is the recovered module Function GetText.

	Method GetStringTeamPosition:String(a0:Int)
		SortTableBy(4)
		Local n:Int = 1
		For Local t:TTableData = EachIn Self.list
			If t.teamid = a0 Then
				If n < 33 Then Return GetText("position_" + n)
				Return String(n)
			EndIf
			n = n + 1
		Next
		Return "None"
	End Method
