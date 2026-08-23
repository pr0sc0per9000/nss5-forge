' TTraining.TrainingSetPiece
' VA 0x00582ae9   106 bytes   vtable slot 0xbc   sig (:TPlayer)i
' byte-identical vs NSS5.exe (106/106, original length from Ghidra's inventory)
' parameter a0 is unused. Each empty Case must be SEPARATE ('Case 1,2' grouped is 8 bytes short). Global at 0x00c6cf90 assumed Int
	Function TrainingSetPiece:Int(a0:TPlayer)
		'!Global g_intraining:Int
		Select g_intraining
			Case 1
			Case 2
			Case 3
				Return 1
			Case 4
			Case 5
			Case 6
				Return 1
			Case 7
			Case 8
			Case 9
			Case 10
				Return 1
		End Select
		Return 0
	End Function
