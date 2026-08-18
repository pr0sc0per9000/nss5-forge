' TProfile.GetHappiness
' VA 0x0056ADD8   110 bytes   vtable slot 0xc4   sig ()i
' byte-identical vs NSS5.exe (110/110, original length from Ghidra's inventory)
' slot 0xf8 = TProfile.GetFame ()f, so the whole sum is evaluated on the x87 stack and Int() emits _bbFloatToInt
	Method GetHappiness:Int()
		Return Int(relationboss+relationteam+relationfans+relationfriends+relationgirlfriend*2+relationsponsors+GetFame())/8
	End Method
