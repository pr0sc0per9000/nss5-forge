' TScreen_Casino.ButtonSlots
' VA 0x005744e2   20 bytes   vtable slot 0x4c   sig ()i
' byte-identical vs NSS5.exe (20/20, original length from Ghidra's inventory)
' PTR_FUN_00c6c544 resolved via class_tables.tsv to TScreen_Slots + slot 0x34 = SetUpScreen()
	Function ButtonSlots()
		TScreen_Slots.SetUpScreen()
	End Function
