' TScreen.ButtonHelp
' VA 0x00513283   25 bytes   vtable slot 0xb0   sig ()i
' byte-identical vs NSS5.exe (25/25, original length from Ghidra's inventory)
' Indirect call through TScreen's class table at 0x00C61CE4 = slot 0xB8 = DoHelp(i)i.
	Function ButtonHelp:Int()
		DoHelp(0)
	End Function
