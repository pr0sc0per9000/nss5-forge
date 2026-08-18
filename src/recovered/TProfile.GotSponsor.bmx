' TProfile.GotSponsor
' VA 0x0056BFAE   52 bytes
' byte-identical vs NSS5.exe
' parameter names are placeholders (a0, a1, ...); the original names are not recoverable

	Method GotSponsor:Int()
		For Local i:Int = 0 To 8
			If sponsor_amount[i] > 0 Then Return 1
		Next
		Return 0
	End Method
