' TTraining.UpdateTackling2
' VA 0x00580BCF   117 bytes   vtable slot 0x70   sig ()i
' byte-identical vs NSS5.exe (117/117, original length from Ghidra's inventory)
' Parameter names are not recoverable from the binary and do not affect codegen;
' they are emitted as a0, a1, ... exactly as the harness compiles them.
' ASSUMPTION: module Global at 0x00c6d568 declared TList (same global TPole.Clear removes from).
' c.alive is TTrainingObject.alive at +24, inherited by TCone.
' PTR_FUN_00c6d53c = TTraining + 0x98 = TTraining.Success.

	Function UpdateTackling2:Int()
		'!Global g_trainobs:TList
		Local n:Int = 0
		For Local c:TCone = EachIn g_trainobs
			If c.alive Then n = n + 1
		Next
		If n = 0 Then TTraining.Success()
	End Function
