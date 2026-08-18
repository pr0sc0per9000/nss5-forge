' TScreen_EditClubs.ButtonNextClub
' VA 0x0052e8f9   141 bytes   vtable slot 0x40   sig ()i
' byte-identical vs NSS5.exe (141/141, original length from Ghidra's inventory)
' ASSUMPTIONS: module Global 0x00c59a44 declared TList (master club list),
' module Global 0x00c653c4 declared TClub (the club being edited).
	Function ButtonNextClub:Int()
		'!Global g_clubs:TList
		'!Global g_editclub:TClub
		TScreen_EditClubs.UpdateClub()
		TClub.SortListBy(1,1)
		For Local c:TClub = EachIn g_clubs
			If c.id > g_editclub.id
				TScreen_EditClubs.SetUpScreen(c.id, "")
				Return 0
			End If
		Next
	End Function
