' TCompetition.AllFixturesPlayed
' VA 0x0050D779   97 bytes   vtable slot 0xd0   sig ()i
' byte-identical vs NSS5.exe (97/97, original length from Ghidra's inventory)
' The `cmp eax,bbNullObject / je` before the field test is bcc's own guard on the
' EachIn downcast -- it is NOT an `If f <> Null` in the source. Writing one explicitly
' costs 31 extra bytes (the And forces both operands to be materialised with setcc).
	Method AllFixturesPlayed()
		For Local f:TFixture = EachIn lfixturelist
			If f.result = 0 Then Return 0
		Next
		Return 1
	End Method
