' TScreen_Promotions.ButtonQuit
' VA 0x00533252   20 bytes   vtable slot 0x38   sig ()i
' byte-identical vs NSS5.exe (20/20, original length from Ghidra's inventory)
' assumption: the class-table pointer at 0x00c64e9c resolves to TScreen_EditMenu + slot 0x34
	Function ButtonQuit:Int()
		TScreen_EditMenu.SetUpScreen()
	End Function
