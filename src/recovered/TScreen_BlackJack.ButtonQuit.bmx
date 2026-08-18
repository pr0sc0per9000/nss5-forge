' TScreen_BlackJack.ButtonQuit
' VA 0x00576969   39 bytes   vtable slot 0x3c   sig ()i
' byte-identical vs NSS5.exe (39/39, original length from Ghidra's inventory, mode=reloc)
' assumptions: PTR_FUN_00c6c320 = TBlackJack classtable(0x00c6c2e8)+0x38 = TBlackJack.Reset;
'              PTR_FUN_00c6ba24 = TScreen_Casino classtable(0x00c6b9ec)+0x38 = TScreen_Casino.SetUpScreen;
'              FUN_00505b91 = recovered module Function LogLine, literal 0x00c90dc4 = "ButtonQuit"
	Function ButtonQuit:Int()
		LogLine("ButtonQuit")
		TBlackJack.Reset()
		TScreen_Casino.SetUpScreen()
	End Function
