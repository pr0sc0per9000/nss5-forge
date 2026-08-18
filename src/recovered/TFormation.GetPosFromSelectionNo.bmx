' TFormation.GetPosFromSelectionNo
' VA 0x004d96d7   133 bytes   vtable slot 0x5c   sig (i)i
' byte-identical vs NSS5.exe

	Method GetPosFromSelectionNo:Int(a0:Int)
		If a0 = 0 Then Return 0
		Local c:Int = 0
		For Local i:Int = 0 To 34
			If m_TacPos[i] = 1
				c = c + 1
				If c = a0
					If i < 7 Then Return 1
					If i < 14 Then Return 2
					If i < 21 Then Return 3
					If i < 28 Then Return 4
					If i < 35 Then Return 5
				End If
			End If
		Next
		Return -1
	End Method
