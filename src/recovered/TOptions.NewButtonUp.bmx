' TOptions.NewButtonUp
' VA 0x004e486a   46 bytes   vtable slot 0x54   sig ()i
' byte-identical vs NSS5.exe (46/46, original length from Ghidra's inventory)
' assumes module globals:  Global g_opt_ctrlup:Int[]  (0x00c5d1b4)
'                          Global g_opt_ctrlidx:Int   (0x00c5d1a8)
' Int[] (not Object[]) is load-bearing -- the store is a plain dword move with no GC write barrier

	Function NewButtonUp:Int()
		'!Global g_opt_ctrlup:Int[]
		'!Global g_opt_ctrlidx:Int
		g_opt_ctrlup[g_opt_ctrlidx] = TOptions.GetNewControl()
		TScreen_Controls.RefreshButtons()
	End Function
