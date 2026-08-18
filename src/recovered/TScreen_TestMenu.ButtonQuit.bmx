' TScreen_TestMenu.ButtonQuit
' VA 0x00537BD5   20 bytes   vtable slot 0x38   sig ()i
' byte-identical vs NSS5.exe (20/20, original length from Ghidra's inventory)
' Assumption: the class-table pointer at 0x00c64e9c resolves to TScreen_EditMenu+0x34 = TScreen_EditMenu.SetUpScreen.
	Function ButtonQuit()
		TScreen_EditMenu.SetUpScreen()
	End Function
