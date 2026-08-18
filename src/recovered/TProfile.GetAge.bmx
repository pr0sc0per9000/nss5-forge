' TProfile.GetAge
' VA 0x00569CFE   27 bytes
' byte-identical vs NSS5.exe
' parameter names are placeholders (a0, a1, ...); the original names are not recoverable

	Method GetAge:Int()
		Return date.GetYear() + 15
	End Method
