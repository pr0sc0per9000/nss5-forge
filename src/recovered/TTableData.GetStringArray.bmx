' TTableData.GetStringArray
' VA 0x00526F4F   315 bytes   vtable slot 0x3c   sig (i,i)[]$
' byte-identical vs NSS5.exe (315/315, original length from Ghidra's inventory)
' The 5-element branch is emitted FIRST: the original's 'cmp eax,0' is followed
' by a SHORT 'je' into the 10-element block, so the written condition is
' 'a1 <> 0', not 'a1 = 0' with the arms swapped.
	Method GetStringArray:String[](a0:Int, a1:Int)
		If a1 <> 0
			Return [String(a0), teamname, String(played), String(goalsf - goalsa), String(points)]
		Else
			Return [String(a0), teamname, String(played), String(won), String(drawn), String(lost), String(goalsf), String(goalsa), String(goalsf - goalsa), String(points)]
		EndIf
	End Method
