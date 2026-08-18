' TOptions.NewButtonPause
' VA 0x004E49E7   46 bytes   vtable slot 0x74   sig ()i
' byte-identical vs NSS5.exe (46/46, original length from Ghidra's inventory)
' Assumptions: module Globals 0x00c5d1f4 = g_ctrl_pause:Int[] and 0x00c5d1a8 = g_ctrl_player:Int
' (the same pair TOptions.NewButtonDown uses, different key array);
' class-table pointers 0x00c5d554 = TOptions.GetNewControl (slot 0x3c),
' 0x00c64204 = TScreen_Controls.RefreshButtons (slot 0x40).
	Function NewButtonPause()
		'!Global g_ctrl_pause:Int[]
		'!Global g_ctrl_player:Int
		g_ctrl_pause[g_ctrl_player] = TOptions.GetNewControl()
		TScreen_Controls.RefreshButtons()
	End Function
