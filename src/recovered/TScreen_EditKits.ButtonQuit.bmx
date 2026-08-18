' TScreen_EditKits.ButtonQuit
' VA 0x0053536C   107 bytes   vtable slot 0x38   sig ()i
' byte-identical vs NSS5.exe (107/107, original length from Ghidra's inventory, mode=reloc)
' Assumptions:
'   module Global at 0x00C65C70 declared TBase_Team. globals_final.tsv only had it as
'   `Object` (init=bbNullObject, no call-site typing), but the body downcasts it to both
'   TNation and TClub -- which per class_tables.tsv both Extend TBase_Team -- and then
'   reads +0x0C directly off the Global without a downcast. TBase_Team.id is at +0x0C.
'   That direct field read is what proves the static type is TBase_Team, not Object.
'   PTR_FUN_00C6520C = TScreen_EditNations classtable(0x00C651D8) + 0x34 -> SetUpScreen (i)i
'   PTR_FUN_00C65558 = TScreen_EditClubs  classtable(0x00C65524) + 0x34 -> SetUpScreen (i,$)i
'   Shape is ElseIf, not a nested If: one shared exit label at 0x5353CC.

	Function ButtonQuit:Int()
		'!Global g_edit_selected:TBase_Team
		If TNation(g_edit_selected) <> Null
			TScreen_EditNations.SetUpScreen(g_edit_selected.id)
		ElseIf TClub(g_edit_selected) <> Null
			TScreen_EditClubs.SetUpScreen(g_edit_selected.id, "")
		End If
	End Function
