' TFixture.GetRandomGoal
' VA 0x004c4d29   174 bytes   vtable slot 0x5c   sig ()i
' byte-identical vs NSS5.exe (174/174, original length from Ghidra's inventory)
' Both loops are `To 10` (jle), and the pick test is `w[i] > r` -- Ghidra normalises the
' operand order to `r < w[i]`, which emits the other cmp direction.
	Function GetRandomGoal:Int()
		Local w:Int[] = New Int[11]
		w[0] = 1536
		w[1] = 1536
		w[2] = 1536
		w[3] = 1536
		w[4] = 256
		w[5] = 32
		w[6] = 8
		w[7] = 4
		w[8] = 2
		w[9] = 1
		w[10] = 1
		Local tot:Int = 0
		For Local i:Int = 0 To 10
			tot = tot + w[i]
		Next
		Local r:Int = Rand(1,tot)
		For Local i:Int = 0 To 10
			If w[i] > r Then Return i
			r = r - w[i]
		Next
		Return 0
	End Function
