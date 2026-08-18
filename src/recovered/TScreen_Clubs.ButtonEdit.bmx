' TScreen_Clubs.ButtonEdit
' VA 0x0052CE0C   57 bytes   vtable slot 0x44   sig ()i
' byte-identical vs NSS5.exe (57/57, original length from Ghidra's inventory, mode=reloc)
' Assumptions:
'   module Global at 0x00C65240 declared TTable. globals_final calls it TButton with a
'   TButton/TTable construction conflict; slot 0xD8 is TTable.GetSelectedText(i)$, which
'   TButton does not have, so TTable is the type the call site needs.
'   0x004A7130 = _bbStringToInt -> the Int(...) wrapper.
'   PTR_FUN_00C65558 = TScreen_EditClubs classtable(0x00C65524) + 0x34 -> SetUpScreen(i,$)i.
'   Ghidra attributes the trailing "" push to GetSelectedText; it is really SetUpScreen's
'   second argument -- GetSelectedText takes one Int.

	Function ButtonEdit:Int()
		'!Global g_clubs_table:TTable
		TScreen_EditClubs.SetUpScreen(Int(g_clubs_table.GetSelectedText(0)), "")
	End Function
