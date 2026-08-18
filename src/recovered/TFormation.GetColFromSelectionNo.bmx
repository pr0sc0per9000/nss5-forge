' TFormation.GetColFromSelectionNo
' VA 0x004d8b3c   73 bytes   vtable slot 0x54   sig (i)i
' byte-identical vs NSS5.exe
' The body is verified over the full 73-byte function (length from Ghidra's
'   inventory, mode=exact) and is byte-identical.

	Method GetColFromSelectionNo:Int(a0:Int)
		Local c:Int = 0
		For Local i:Int = 0 To 34
			If m_TacPos[i] = 1
				c = c + 1
				If c = a0 Then Return GetCol(i)
			End If
		Next
		Return -1
	End Method
