' TTrainingLine.Clear
' VA 0x0058404d   32 bytes   vtable slot 0x44   sig ()i
' byte-identical vs NSS5.exe (32/32, original length from Ghidra's inventory)
' assumption: module Global at 0x00c6d568 declared as g_traininglines:TList
'             (the call is slot 0x74 = TList.Remove(:Object)i)
	Method Clear:Int()
		'!Global g_traininglines:TList
		g_traininglines.Remove(Self)
	End Method
