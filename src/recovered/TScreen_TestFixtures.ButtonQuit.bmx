' TScreen_TestFixtures.ButtonQuit
' VA 0x00539a6a   20 bytes   vtable slot 0x3c   sig ()i
' byte-identical vs NSS5.exe (20/20, original length from Ghidra's inventory)
' Class table 0x00C66404 = TScreen_TestMenu + 0x34 = SetUpScreen()i.
	Function ButtonQuit:Int()
		TScreen_TestMenu.SetUpScreen()
	End Function
