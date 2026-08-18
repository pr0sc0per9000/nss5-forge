' TBase_Team.GetNextFixture
' VA 0x004bd1c1   156 bytes   vtable slot 0x34   sig (i):TFixture
' byte-identical vs NSS5.exe (156/156, original length from Ghidra's inventory)
' Self.<slot 0x30> = TBase_Team.GetFixtureList(i,i):TList, called as GetFixtureList(-1,a0).
	Method GetNextFixture:TFixture(a0:Int)
		For Local f:TFixture = EachIn GetFixtureList(-1,a0)
			If f.result = 0 And f.hometeam > 0 And f.awayteam > 0 Then Return f
		Next
		Return Null
	End Method
