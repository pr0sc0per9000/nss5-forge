' TTrainingZone.Clear
' VA 0x00583dd9   32 bytes   vtable slot 0x44   sig ()i
' byte-identical vs NSS5.exe (32/32, original length from Ghidra's inventory)
' assumes module global at 0x00C6D568 typed TList (slot 0x74 = TList.Remove(:Object)i)
	Method Clear:Int()
		'!Global g_zonelist:TList
		g_zonelist.Remove(Self)
	End Method
