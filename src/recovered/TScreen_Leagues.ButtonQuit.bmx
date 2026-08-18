' TScreen_Leagues.ButtonQuit
' VA 0x005451F6   20 bytes   vtable slot 0x38   sig ()i
' byte-identical vs NSS5.exe (20/20, original length from Ghidra's inventory)
' static cross-Type call resolved via class_tables.tsv: PTR_FUN_00c66910 = TScreen_GameMenu+0x34 (SetUpScreen)
	Function ButtonQuit:Int()
		TScreen_GameMenu.SetUpScreen()
	End Function
