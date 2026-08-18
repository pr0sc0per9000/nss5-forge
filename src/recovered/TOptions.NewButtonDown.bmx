' TOptions.NewButtonDown
' VA 0x004E4898   46 bytes   vtable slot 0x58   sig ()i
' byte-identical vs NSS5.exe (46/46, original length from Ghidra's inventory)
' Assumptions: module Globals 0x00c5d1bc = g_ctrl_down:Int[] and 0x00c5d1a8 = g_ctrl_player:Int;
' class-table pointers 0x00c5d554 = TOptions.GetNewControl, 0x00c64204 = TScreen_Controls.RefreshButtons.
	Function NewButtonDown()
		'!Global g_ctrl_down:Int[]
		'!Global g_ctrl_player:Int
		g_ctrl_down[g_ctrl_player] = TOptions.GetNewControl()
		TScreen_Controls.RefreshButtons()
	End Function
