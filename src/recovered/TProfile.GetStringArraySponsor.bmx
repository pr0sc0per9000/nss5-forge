' TProfile.GetStringArraySponsor
' VA 0x0056B036   172 bytes
' byte-identical vs NSS5.exe (mode=reloc)
' parameter names are placeholders (a0, a1, ...); the original names are not recoverable

	Method GetStringArraySponsor:String[](a0:Int)
		Local nm:String = SponsorName(a0)
		Local am:String = FormatMoney(sponsor_amount[a0-1], 1)
		Local ex:String = "-"
		If sponsor_expires[a0-1] > 0
			ex = TMyDate.Create(sponsor_expires[a0-1],1,1).GetString("YYYY-WWWW")
		EndIf
		Return [nm, am, ex]
	End Method
