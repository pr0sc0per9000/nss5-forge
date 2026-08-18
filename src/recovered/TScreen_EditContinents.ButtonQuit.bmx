' TScreen_EditContinents.ButtonQuit
' VA 0x00528F7D   20 bytes   vtable slot 0x38   sig ()i
' byte-identical vs NSS5.exe (20/20, original length from Ghidra's inventory)
' Parameter names are not recoverable from the binary and do not affect codegen;
' they are emitted as a0, a1, ... exactly as the harness compiles them.
' PTR_FUN_00c64e9c resolves to class table TScreen_EditMenu + 0x34 = TScreen_EditMenu.SetUpScreen

	Function ButtonQuit:Int()
		TScreen_EditMenu.SetUpScreen()
	End Function
