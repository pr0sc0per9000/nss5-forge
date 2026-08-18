' TCompetition.IsThisCurrentCupRound
' VA 0x0050d872   188 bytes   vtable slot 0xd8   sig ()i
' byte-identical vs NSS5.exe (188/188, original length from Ghidra's inventory, mode=reloc)
' No Globals. TFixture field at +36 is `result`; slots 0x70/0x74 are GetHomeTeamId/GetAwayTeamId.
' Ghidra's nested do/while is one `For EachIn` with an early Return out of it.
	Method IsThisCurrentCupRound:Int()
		Local b:Int = True
		For Local f:TFixture = EachIn lfixturelist
			If f.result = 0 Then b = False
			If f.GetHomeTeamId() = 0 And f.GetAwayTeamId() = 0 Then Return 0
		Next
		If b Then Return 0
		Return 1
	End Method
