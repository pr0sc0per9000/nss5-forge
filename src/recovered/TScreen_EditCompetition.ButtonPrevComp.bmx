' TScreen_EditCompetition.ButtonPrevComp
' VA 0x005323F2   141 bytes   vtable slot 0x44   sig ()i
' byte-identical vs NSS5.exe (141/141, original length from Ghidra's inventory, mode=reloc)
' module Globals assumed (names ours, types load-bearing):
'   0x00C6099C : TList         (enumerated; globals_final had it only as untyped Object)
'   0x00C65720 : TCompetition  (globals_final construction-typed with a TScreen/TCompetition
'                CONFLICT; .id at +8 and the comparison against a TCompetition's id settle it)
' resolved call targets:
'   PTR_FUN_00C658F0 = TScreen_EditCompetition classtable(0x00C658A4) + 0x4C -> UpdateComp()i
'   PTR_FUN_00C616DC = TCompetition classtable(0x00C615C0) + 0x11C -> SortListBy(i,i)i
'   PTR_FUN_00C658D8 = TScreen_EditCompetition classtable + 0x34 -> SetUpScreen(i,$)i
'   0x00C615C0 is TCompetition's class table -> the EachIn downcast target.
' The hit path is an explicit Return inside the loop, not Exit: the HasNext=0 path returns
' without calling SetUpScreen, so the two exits cannot share a label.

	Function ButtonPrevComp:Int()
		'!Global g_complist:TList
		'!Global g_sel_comp:TCompetition
		TScreen_EditCompetition.UpdateComp()
		TCompetition.SortListBy(1, 0)
		For Local c:TCompetition = EachIn g_complist
			If c.id < g_sel_comp.id
				TScreen_EditCompetition.SetUpScreen(c.id, "")
				Return 0
			End If
		Next
	End Function
