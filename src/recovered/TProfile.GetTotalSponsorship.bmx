' TProfile.GetTotalSponsorship
' VA 0x0056B00A   44 bytes
' byte-identical vs NSS5.exe
' parameter names are placeholders (a0, a1, ...); the original names are not recoverable

	Method GetTotalSponsorship:Int()
		Local total:Int = 0
		For Local i:Int = 0 To 8
			total = total + sponsor_amount[i]
		Next
		Return total
	End Method
