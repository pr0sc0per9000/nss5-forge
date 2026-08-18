' TProfile.GetPropertyCount
' VA 0x0056BF7C   50 bytes
' byte-identical vs NSS5.exe
' parameter names are placeholders (a0, a1, ...); the original names are not recoverable

	Method GetPropertyCount:Int()
		Local c:Int = 0
		For Local i:Int = 0 To 9
			If property[i] > 0 Then c = c + 1
		Next
		Return c
	End Method
