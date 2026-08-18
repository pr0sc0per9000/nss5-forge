' TClub.CountTeamsInDivision
' VA 0x004c17e2   105 bytes   vtable slot 0x74   sig (i)i
' byte-identical vs NSS5.exe (105/105, original length from Ghidra's inventory)
' ASSUMPTION: module Global at 0x00c59a44 declared TList (the master club list).
	Function CountTeamsInDivision:Int(a0:Int)
		'!Global g_clubs:TList
		Local n:Int = 0
		For Local c:TClub = EachIn g_clubs
			If c.leagueid = a0 Then n = n + 1
		Next
		Return n
	End Function
