' TScreen_EditMenu.ButtonContinents
' VA 0x0052814B   25 bytes   vtable slot 0x38   sig ()i
' byte-identical vs NSS5.exe (25/25, original length from Ghidra's inventory)
' PTR_FUN_00c65018 = TScreen_EditContinents+0x34 (SetUpScreen(i)i)
	Function ButtonContinents:Int()
		TScreen_EditContinents.SetUpScreen(1)
	End Function
