' TOptions.NewButtonKick
' VA 0x004e4922   59 bytes   vtable slot 0x64   sig ()i
' byte-identical vs NSS5.exe (59/59, original length from Ghidra's inventory)
' Globals: g_options_arr06:Int[] (0x00c5d1d4 -- plain dword store, so Int[] not Object[]),
'          g_options_int01:Int (0x00c5d1a8)
' Slots: 0x00c5d554 = TOptions+0x3c = GetNewControl (sibling Function, no Type. prefix)
'        0x00c64204 = TScreen_Controls+0x40 = RefreshButtons
	Function NewButtonKick:Int()
		'!Global g_options_arr06:Int[]
		'!Global g_options_int01:Int
		LogLine("NewButtonKick")
		g_options_arr06[g_options_int01] = GetNewControl()
		TScreen_Controls.RefreshButtons()
	End Function
