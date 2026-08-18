' TTraining.UpdateHeading1
' VA 0x00580e6d   29 bytes   vtable slot 0x78   sig ()i
' byte-identical vs NSS5.exe (29/29, original length from Ghidra's inventory)
' Assumes module global 0x00C6CFF8 is Int (globals_named.tsv g_training_int21).
' Class table 0x00C6D4A4 + 0x98 = Success()i.
' Declared: Global g_training_int21:Int
	Function UpdateHeading1:Int()
		'!Global g_training_int21:Int
		If g_training_int21 = 0 Then Success()
	End Function
