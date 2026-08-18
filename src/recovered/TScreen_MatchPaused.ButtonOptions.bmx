' TScreen_MatchPaused.ButtonOptions
' VA 0x0054aeb2   20 bytes   vtable slot 0x44   sig ()i
' byte-identical vs NSS5.exe (20/20, original length from Ghidra's inventory)
' assumption: the class-table pointer at 0x00c64060 resolves to TScreen_Options + slot 0x34
	Function ButtonOptions:Int()
		TScreen_Options.SetUpScreen()
	End Function
