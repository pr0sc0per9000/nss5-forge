' TTraining.UpdateShooting1
' VA 0x00580f4e   29 bytes   vtable slot 0x80   sig ()i
' byte-identical vs NSS5.exe (29/29, original length from Ghidra's inventory)
' Byte-for-byte the same construct as UpdateHeading1 (both 29 bytes).
' Declared: Global g_training_int21:Int
	Function UpdateShooting1:Int()
		' g_training_int21's original data-section value is -1 (read from NSS5.exe
		' at 0x00C6CFF8 -- codegen-patterns 21.1/21.3).
		'!Global g_training_int21:Int = -1
		If g_training_int21 = 0 Then Success()
	End Function
