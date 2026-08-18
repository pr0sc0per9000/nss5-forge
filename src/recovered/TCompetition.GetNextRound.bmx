' TCompetition.GetNextRound
' VA 0x0050D71A   95 bytes   vtable slot 0xcc   sig ()i
' byte-identical vs NSS5.exe (95/95, original length from Ghidra's inventory)
' harness mode=reloc.

	Method GetNextRound:Int()
		For Local f:TFixture = EachIn lfixturelist
			If f.result = 0 Then Return f.round
		Next
		Return 0
	End Method
