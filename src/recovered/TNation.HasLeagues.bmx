' TNation.HasLeagues
' VA 0x004bf7a4   156 bytes   vtable slot 0x74   sig ()i
' byte-identical vs NSS5.exe (156/156, original length from Ghidra's inventory)
' ASSUMPTION: module Global at 0x00c6099c declared TList (the master competition list).
	Method HasLeagues:Int()
		'!Global g_comps:TList
		For Local c:TCompetition = EachIn g_comps
			If c.locale = 0 And c.based = id And c.duration > 1 Then Return 1
		Next
		Return 0
	End Method
