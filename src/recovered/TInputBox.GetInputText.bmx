' TInputBox.GetInputText
' VA 0x00515eff   55 bytes   vtable slot 0x90   sig ()i
' byte-identical vs NSS5.exe (55/55, original length from Ghidra's inventory)
' Globals: g_screen_int03:Int (0x00c6173c), g_Object108:Object (0x00c61cf8, downcast to TInputBox at the use site)
	Function GetInputText:Int()
		'!Global g_screen_int03:Int
		'!Global g_Object108:Object
		g_screen_int03 = 0
		TInputBox(g_Object108).gettinginput = 1
		FlushAllInput()
	End Function
