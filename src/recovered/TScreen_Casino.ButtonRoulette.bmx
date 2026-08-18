' TScreen_Casino.ButtonRoulette
' VA 0x005744c9   25 bytes   vtable slot 0x48   sig ()i
' byte-identical vs NSS5.exe (25/25, original length from Ghidra's inventory)
' no assumptions: the class-table slot 0x00c6bb98 resolves to TScreen_Roulette.SetUpScreen

	Function ButtonRoulette:Int()
		TScreen_Roulette.SetUpScreen(1)
	End Function
