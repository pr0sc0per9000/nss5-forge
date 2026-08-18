' TScreen_EditMenu.ButtonNations
' VA 0x00528164   25 bytes   vtable slot 0x3c   sig ()i
' byte-identical vs NSS5.exe (25/25, original length from Ghidra's inventory)
' no assumptions: PTR_FUN_00C6520C resolves to TScreen_EditNations class table + slot 0x34 = SetUpScreen(i)i
	Function ButtonNations()
		TScreen_EditNations.SetUpScreen(1)
	End Function
