' TCompetition.GetFixtureDate
' VA 0x0050d5b9   118 bytes   vtable slot 0xc0   sig (i):TMyDate
' byte-identical vs NSS5.exe (118/118, original length from Ghidra's inventory)
	Method GetFixtureDate:TMyDate(a0:Int)
		For Local f:TFixture = EachIn lfixturelist
			If f.round = a0 Then Return TMyDate.Create(f.sdate,1,1)
		Next
		Return Null
	End Method
