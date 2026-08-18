' TScreen_EditNations.ComboNation
' VA 0x0052B24D   60 bytes   vtable slot 0x48   sig ()i
' byte-identical vs NSS5.exe (60/60, original length from Ghidra's inventory)
' Parameter names are not recoverable from the binary and do not affect codegen;
' they are emitted as a0, a1, ... exactly as the harness compiles them.
' ASSUMPTION: module Global at 0x00c6503c declared TCombo (slot 0xc0 = TCombo.GetSelectedItemId).
' PTR_FUN_00c59a20 = TNation + 0x58 = TNation.SelectById;
' PTR_FUN_00c6520c = TScreen_EditNations + 0x34 = TScreen_EditNations.SetUpScreen.

	Function ComboNation:Int()
		'!Global g_cmbNation:TCombo
		Local n:TNation = TNation.SelectById(g_cmbNation.GetSelectedItemId())
		If n Then TScreen_EditNations.SetUpScreen(n.id)
	End Function
