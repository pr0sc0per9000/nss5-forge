' TProfile.GetRentCosts
' VA 0x0056AE99   41 bytes
' byte-identical vs NSS5.exe
' parameter names are placeholders (a0, a1, ...); the original names are not recoverable

	Method GetRentCosts:Int()
		If GetPropertyCosts() = 0 Then Return 250
		Return 0
	End Method
