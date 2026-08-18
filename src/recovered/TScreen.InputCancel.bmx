' TScreen.InputCancel
' VA 0x00512db8   49 bytes   vtable slot 0xa8   sig ()i
' byte-identical vs NSS5.exe (49/49, original length from Ghidra's inventory)
' assumes module global:  Global g_screen_int02:String
' global 0x00c61734 is a String, not an Int as globals_named.tsv guessed

	Function InputCancel:Int()
		'!Global g_screen_int02:String
		g_screen_int02 = "cancel"
	End Function
