' TCompetition.AllFixturesPopulated
' VA 0x0050d7da   152 bytes   vtable slot 0x110   sig ()i
' byte-identical vs NSS5.exe (152/152, original length from Ghidra's inventory)
	Method AllFixturesPopulated()
		For Local f:TFixture = EachIn lfixturelist
			If f.GetHomeTeamId() = 0 And f.GetAwayTeamId() = 0 Then Return 0
		Next
		Return 1
	End Method
