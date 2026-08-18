' TTraining.IsPlayerNeededForTraining
' VA 0x0057C603   207 bytes   vtable slot 0x34   sig (i,i)i
' byte-identical vs NSS5.exe (207/207, original length from Ghidra's inventory)
' mode 'reloc': absolute addresses masked, emitted code identical
' module global assumed: Global g_training_int03:Int
' module global assumed: Global g_training_int17:Int

	Function IsPlayerNeededForTraining:Int(a0:Int, a1:Int)
		'!Global g_training_int03:Int
		'!Global g_training_int17:Int
		If g_training_int03 = 0 Then Return 1
		If g_training_int03 = 4 And a0 = 0 Then Return 0
		If a1 = 1
			Select g_training_int17
				Case 2
					If a0 = 0 Or a0 = 2 Then Return 1
				Case 3
					If a0 = 0 Or a0 = 2 Or a0 = 3 Then Return 1
				Default
					If a0 < g_training_int17 Then Return 1
			End Select
		EndIf
		Return 0
	End Function
