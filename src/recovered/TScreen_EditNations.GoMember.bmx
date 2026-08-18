' TScreen_EditNations.GoMember
' VA 0x0052b289   76 bytes   vtable slot 0x4c   sig ()i
' byte-identical vs NSS5.exe (76/76, original length from Ghidra's inventory)
' ASSUMPTION: module Global 0x00c65090 declared TTable (slot 0xd8 = GetSelectedText(i)$).
' FUN_004a7130 is _bbStringToInt, i.e. the Int() around the String.
	Function GoMember:Int()
		'!Global g_table:TTable
		Local c:TClub = TClub.SelectById(Int(g_table.GetSelectedText(0)))
		If c <> Null Then TScreen_EditClubs.SetUpScreen(c.id, "")
	End Function
