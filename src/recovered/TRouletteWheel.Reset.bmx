' TRouletteWheel.Reset
' VA 0x00575b6e   77 bytes   vtable slot 0x34   sig ()i
' byte-identical vs NSS5.exe (77/77, original length from Ghidra's inventory)
' relies on BRL name _brl_random_Rnd at 0x0059f048
' the three constants are read straight out of NSS5.exe's double pool at
' 0x00c90ae8 = 4.0, 0x00c90af8 = 0.1, 0x00c90af0 = 1.1 (the latter two are
' float-rounded, so they were written as Float literals in the original)

	Method Reset:Int()
		Self.fSpeed = 4.0 + Rnd(0.1, 1.1)
	End Method
