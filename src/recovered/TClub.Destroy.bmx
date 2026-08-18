' TClub.Destroy
' VA 0x004BFE82   32 bytes   vtable slot 0x44   sig ()i
' byte-identical vs NSS5.exe (32/32, original length from Ghidra's inventory)
' Assumption: module Global at 0x00c59a44 declared as g_clubs:TList (slot 0x74 = TList.Remove).
	Method Destroy()
		'!Global g_clubs:TList
		g_clubs.Remove(Self)
	End Method
