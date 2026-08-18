' TProfile.GetStableSize
' VA 0x0056B974   23 bytes
' byte-identical vs NSS5.exe
' parameter names are placeholders (a0, a1, ...); the original names are not recoverable

	Method GetStableSize:Int()
		Return property[4] * 2
	End Method
