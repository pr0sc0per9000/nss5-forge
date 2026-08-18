' TScreen_TestTournaments.ButtonQuit
' VA 0x005391D4   20 bytes   vtable slot 0x58   sig ()i
' byte-identical vs NSS5.exe (20/20, original length from Ghidra's inventory)
' Parameter names are not recoverable from the binary and do not affect codegen;
' they are emitted as a0, a1, ... exactly as the harness compiles them.
' PTR_FUN_00c66404 resolves to class table TScreen_TestMenu + 0x34 = TScreen_TestMenu.SetUpScreen

	Function ButtonQuit:Int()
		TScreen_TestMenu.SetUpScreen()
	End Function
