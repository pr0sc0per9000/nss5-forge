' TScreen_ContinentalComps.ButtonQuit
' VA 0x00533f08   20 bytes   vtable slot 0x38   sig ()i
' byte-identical vs NSS5.exe (20/20, original length from Ghidra's inventory)
' Class table 0x00C64E68 + 0x34 = TScreen_EditMenu.SetUpScreen()i (resolved via class_tables.tsv, not guessed).
	Function ButtonQuit:Int()
		TScreen_EditMenu.SetUpScreen()
	End Function
