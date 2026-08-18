' TOptions.NewButtonKick2
' VA 0x004e495d   46 bytes   vtable slot 0x68   sig ()i
' byte-identical vs NSS5.exe (46/46, original length from Ghidra's inventory)
' PTR_FUN_00c5d554 = TOptions class table slot 0x3c = GetNewControl() (sibling Function, no prefix)
' PTR_FUN_00c64204 = TScreen_Controls class table slot 0x40 = RefreshButtons()
' Global: Global g_options_controls:Int[]
' Global: Global g_options_ctlidx:Int
	Function NewButtonKick2:Int()
		'!Global g_options_controls:Int[]
		'!Global g_options_ctlidx:Int
		g_options_controls[g_options_ctlidx] = GetNewControl()
		TScreen_Controls.RefreshButtons()
	End Function
