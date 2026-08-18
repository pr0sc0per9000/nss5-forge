' TCompetition.GetPrevRound
' VA 0x0050d695   133 bytes   vtable slot 0xf8   sig ()i
' byte-identical vs NSS5.exe (133/133, original length from Ghidra's inventory)
' Operand order in the second conjunct is load-bearing: `f.round > r` matches,
' `r < f.round` comes out 2 bytes short.
	Method GetPrevRound()
		Local r:Int = 0
		For Local f:TFixture = EachIn lfixturelist
			If f.result = 1 And f.round > r Then r = f.round
		Next
		Return r
	End Method
