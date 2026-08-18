' TFormation.GetSideFromSelectionNo
' VA 0x004d975c   250 bytes   vtable slot 0x60   sig (i)i
' byte-identical vs NSS5.exe
' The body is verified over the full 250-byte function (length from Ghidra's
'   inventory, mode=exact) and is byte-identical.

	Method GetSideFromSelectionNo:Int(a0:Int)
		Local c:Int = 0
		For Local i:Int = 0 To 34
			If m_TacPos[i] = 1
				c = c + 1
				If c = a0
					If i Mod 7 = 0 Then Return 0
					If i Mod 7 = 1 Then Return 0
					If i Mod 7 = 2 Then Return 1
					If i Mod 7 = 3 Then Return 1
					If i Mod 7 = 4 Then Return 1
					If i Mod 7 = 5 Then Return 2
					If i Mod 7 = 6 Then Return 2
				End If
			End If
		Next
		Return 1
	End Method
