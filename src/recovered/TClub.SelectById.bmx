' TClub.SelectById
' VA 0x004c146c   102 bytes   vtable slot 0x60   sig (i):TClub
' byte-identical vs NSS5.exe (102/102, original length from Ghidra's inventory)
' ASSUMPTION: module Global at 0x00c59a44 declared TList (the master club list).
	Function SelectById:TClub(a0:Int)
		'!Global g_clubs:TList
		For Local c:TClub = EachIn g_clubs
			If c.id = a0 Then Return c
		Next
		Return Null
	End Function
