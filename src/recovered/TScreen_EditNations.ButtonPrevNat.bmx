' TScreen_EditNations.ButtonPrevNat
' VA 0x0052aee4   136 bytes   vtable slot 0x48   sig ()i
' byte-identical vs NSS5.exe (136/136, original length from Ghidra's inventory)
' ASSUMPTIONS: module Global at 0x00c596f0 declared :TList, module Global at 0x00c65034
' declared :TNation. PTR_FUN_00c6521c = TScreen_EditNations + 0x44 = UpdateNat;
' PTR_FUN_00c59a40 = TNation + 0x78 = SortListBy(i,i); PTR_FUN_00c6520c = +0x34 = SetUpScreen(i).
' `Return 0` (not `Exit`, not a bare `Return`) is what reproduces the tail.
	Function ButtonPrevNat()
		'!Global g_nations:TList
		'!Global g_curNation:TNation
		TScreen_EditNations.UpdateNat()
		TNation.SortListBy(1,0)
		For Local n:TNation = EachIn g_nations
			If n.id < g_curNation.id
				TScreen_EditNations.SetUpScreen(n.id)
				Return 0
			EndIf
		Next
	End Function
