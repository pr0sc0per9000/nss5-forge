' TScreen_Competitions.ButtonEdit
' VA 0x0052FD51   57 bytes   vtable slot 0x3c   sig ()i
' byte-identical vs NSS5.exe (57/57, original length from Ghidra's inventory)
' ASSUMPTION: module Global at 0x00C65588 declared :TTable (slot 0xD8 = TTable.GetSelectedText). extracted/globals_named.tsv guesses :TPlayer for this address at low confidence -- that guess is wrong.
' Int($) is _bbStringToInt (0x004A7130). harness mode=reloc.

	Function ButtonEdit:Int()
		'!Global g_comptable:TTable
		TScreen_EditCompetition.SetUpScreen(Int(g_comptable.GetSelectedText(0)), "")
	End Function
