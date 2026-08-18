' TScreen_Continents.ButtonQuit
' VA 0x0054791B   20 bytes   vtable slot 0x38   sig ()i
' byte-identical vs NSS5.exe (20/20, original length from Ghidra's inventory)
' harness mode=reloc: the static cross-Type call target was resolved to TScreen_GameMenu+0x34 on both sides.

	Function ButtonQuit:Int()
		TScreen_GameMenu.SetUpScreen()
	End Function
