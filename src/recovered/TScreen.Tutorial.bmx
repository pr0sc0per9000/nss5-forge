' TScreen.Tutorial
' VA 0x0051329c   25 bytes   vtable slot 0xb4   sig ()i
' byte-identical vs NSS5.exe (25/25, original length from Ghidra's inventory)
' Indirect call through TScreen's class table at 0x00C61CE4 = slot 0xB8 = DoHelp(i)i.
	Function Tutorial:Int()
		DoHelp(1)
	End Function
