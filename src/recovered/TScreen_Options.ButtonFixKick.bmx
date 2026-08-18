' TScreen_Options.ButtonFixKick
' VA 0x00521827   39 bytes   vtable slot 0x94   sig ()i
' byte-identical vs NSS5.exe (39/39, original length from Ghidra's inventory)
' assumes module global:  Global g_options_int19:Int
' global 0x00c5d294; RefreshButtons is TScreen_Options slot 0x38

	Function ButtonFixKick:Int()
		'!Global g_options_int19:Int
		g_options_int19 = Not g_options_int19
		RefreshButtons()
	End Function
