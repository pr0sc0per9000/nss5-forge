' TOptions.NewButtonKick4
' VA 0x004E49B9   46 bytes   vtable slot 0x70   sig ()i
' byte-identical vs NSS5.exe (46/46, original length from Ghidra's inventory)
' Parameter names are not recoverable from the binary and do not affect codegen;
' they are emitted as a0, a1, ... exactly as the harness compiles them.
' ASSUMPTIONS: Global 0x00c5d1ec declared Int[] (array data at +0x18), Global 0x00c5d1a8 declared Int.
' PTR_FUN_00c5d554 = TOptions + 0x3c = TOptions.GetNewControl;
' PTR_FUN_00c64204 = TScreen_Controls + 0x40 = TScreen_Controls.RefreshButtons.

	Function NewButtonKick4:Int()
		'!Global g_btnkick4:Int[]
		'!Global g_ctrlset:Int
		g_btnkick4[g_ctrlset]=TOptions.GetNewControl()
		TScreen_Controls.RefreshButtons()
	End Function
