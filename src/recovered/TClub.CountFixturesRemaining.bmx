' TClub.CountFixturesRemaining
' VA 0x004c1ba2   115 bytes   vtable slot 0x80   sig ()i
' byte-identical vs NSS5.exe (115/115, original length from Ghidra's inventory)
	Method CountFixturesRemaining:Int()
		Local n:Int = 0
		For Local f:TFixture = EachIn GetFixtureList(-1, 0)
			If f.result = 0 Then n = n + 1
		Next
		Return n
	End Method
