' TTraining.Render
' VA 0x005811C6   36 bytes   vtable slot 0x88   sig ()i
' byte-identical vs NSS5.exe (36/36, original length from Ghidra's inventory)
' Assumptions: module Global at 0x00c6cf90 declared g_training_state:Int (globals_named: g_training_int03);
' class-table pointer 0x00c6d6ac = TTrainingObject+0x34 = TTrainingObject.RenderAll.
	Function Render()
		'!Global g_training_state:Int
		If g_training_state = 0 Then Return 0
		TTrainingObject.RenderAll()
	End Function
