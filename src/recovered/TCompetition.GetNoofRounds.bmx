' TCompetition.GetNoofRounds
' VA 0x0050D62F   102 bytes   vtable slot 0xc4   sig ()i
' byte-identical vs NSS5.exe (102/102, original length from Ghidra's inventory)
' Operand order is load-bearing: `If n < f.round` builds to the same 102 bytes but
' differs at offset 67 (the cmp operands are swapped). `f.round > n` is the original.
' The null guard before the field read is bcc's implicit EachIn downcast check, not source.
	Method GetNoofRounds()
		Local n:Int = 0
		For Local f:TFixture = EachIn lfixturelist
			If f.round > n Then n = f.round
		Next
		Return n
	End Method
