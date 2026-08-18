' TScreen_MainMenu.ButtonQuit
' VA 0x0051d010   19 bytes   vtable slot 0x40   sig ()i
' byte-identical vs NSS5.exe (19/19, original length from Ghidra's inventory)
' No assumptions: the single call is bbEnd, which is what 'End' emits.
	Function ButtonQuit:Int()
		End
	End Function
