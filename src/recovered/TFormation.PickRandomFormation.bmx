' TFormation.PickRandomFormation
' VA 0x004d9c6f   21 bytes   vtable slot 0x74   sig ()i
' byte-identical vs NSS5.exe (21/21, original length from Ghidra's inventory, mode=reloc)
'
' KIND=Function -- static, no implicit Self.
' The original pushes 1 then 0x0B before calling _brl_random_Rand: that is BlitzMax's
' one-argument Rand(n), whose second parameter defaults to 1 and is pushed first.
	Function PickRandomFormation:Int()
		Return Rand(11)
	End Function
