' TOptions.NewButtonLeft
' VA 0x004e48c6   46 bytes   vtable slot 0x5c   sig ()i
' byte-identical vs NSS5.exe (46/46, original length from Ghidra's inventory)
' assumes module globals:  Global g_opt_ctrlleft:Int[]  (0x00c5d1c4)
'                          Global g_opt_ctrlidx:Int     (0x00c5d1a8, shared with NewButtonUp)
' Int[] rather than Object[] is load-bearing: the store is a bare dword move

	Function NewButtonLeft:Int()
		'!Global g_opt_ctrlleft:Int[]
		'!Global g_opt_ctrlidx:Int
		g_opt_ctrlleft[g_opt_ctrlidx] = TOptions.GetNewControl()
		TScreen_Controls.RefreshButtons()
	End Function
