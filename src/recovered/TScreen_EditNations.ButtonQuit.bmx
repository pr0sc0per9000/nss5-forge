' TScreen_EditNations.ButtonQuit
' VA 0x0052aed0   20 bytes   vtable slot 0x38   sig ()i
' byte-identical vs NSS5.exe (20/20, original length from Ghidra's inventory)
' Class table 0x00C64E9C = TScreen_EditMenu + 0x34 = SetUpScreen()i.
	Function ButtonQuit:Int()
		TScreen_EditMenu.SetUpScreen()
	End Function
