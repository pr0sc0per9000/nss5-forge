' TOptions.NewButtonKick3
' VA 0x004E498B   46 bytes   vtable slot 0x6c   sig ()i
' byte-identical vs NSS5.exe (46/46, original length from Ghidra's inventory)
' harness mode=reloc: absolute addresses (data pointers, string/array constants, class tables)
'   differ by construction between probe and NSS5.exe; the emitted code is identical.
' module Globals assumed (names ours, types load-bearing):
'   Global g_ctl:Int[]   (0x00C5D1E4, array data starts at +0x18)
'   Global g_idx:Int     (0x00C5D1A8)

	Function NewButtonKick3:Int()
		'!Global g_ctl:Int[]
		'!Global g_idx:Int
		g_ctl[g_idx] = TOptions.GetNewControl()
		TScreen_Controls.RefreshButtons()
	End Function
