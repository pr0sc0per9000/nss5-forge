' TScreen_Options.ButtonBack
' VA 0x005216cf   40 bytes   vtable slot 0x8c   sig ()i
' byte-identical vs NSS5.exe (40/40, original length from Ghidra's inventory)
' Globals: g_prevscreen:String (0x00C63CEC). TOptions.LoadOptions resolved from class table
' TOptions+0x4c; TScreen.SetActive from TScreen+0x5c. Second argument is the empty
' string literal at 0x00C5D284, not Null.
	Function ButtonBack:Int()
		'!Global g_prevscreen:String
		TOptions.LoadOptions()
		TScreen.SetActive(g_prevscreen,"")
	End Function
