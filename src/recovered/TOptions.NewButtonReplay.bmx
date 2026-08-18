' TOptions.NewButtonReplay
' VA 0x004e4a15   46 bytes   vtable slot 0x78   sig ()i
' byte-identical vs NSS5.exe (46/46, original length from Ghidra's inventory)
' assumes: array Global is Int[]; index Global Int; GetNewControl is TOptions' own sibling Function (slot 0x3c); TScreen_Controls.RefreshButtons slot 0x40
	Function NewButtonReplay:Int()
		'!Global g_options_controls:Int[]
		'!Global g_options_controlidx:Int
		g_options_controls[g_options_controlidx] = GetNewControl()
		TScreen_Controls.RefreshButtons()
	End Function
