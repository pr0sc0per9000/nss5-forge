' TScreen_EditContinents.GoMember
' VA 0x0052913B   71 bytes   vtable slot 0x48   sig ()i
' byte-identical vs NSS5.exe (71/71, original length from Ghidra's inventory)
' Assumption: module Global at 0x00c64ef4 declared g_ec_table:TTable (slot 0xd8 = TTable.GetSelectedText).
' Class-table pointers: 0x00c59a20 = TNation.SelectById, 0x00c6520c = TScreen_EditNations.SetUpScreen.
	Function GoMember()
		'!Global g_ec_table:TTable
		Local n:TNation = TNation.SelectById(Int(g_ec_table.GetSelectedText(0)))
		If n <> Null Then TScreen_EditNations.SetUpScreen(n.id)
	End Function
