' TScreen_Casino.ButtonBlackJack
' VA 0x005744b5   20 bytes   vtable slot 0x44   sig ()i
' byte-identical vs NSS5.exe (20/20, original length from Ghidra's inventory)
' Class table 0x00C6C118 + 0x34 = TScreen_BlackJack.SetUpScreen()i.
	Function ButtonBlackJack:Int()
		TScreen_BlackJack.SetUpScreen()
	End Function
