' TProgressBar.SetOldPercent
' VA 0x0051AC05   56 bytes   vtable slot 0x90   sig (f,i)i
' byte-identical vs NSS5.exe (56/56, original length from Ghidra's inventory, mode=reloc)
' assumptions: FUN_00505F90 is the recovered module Function ClampFloat (Float Ptr, Float,
' Float); the original almost certainly declared a Var parameter, which compiles the same.
' Field offsets from reflection: oldpercent +0x74, oldfillalpha +0x7C, oldfillfade +0x80.
	Method SetOldPercent:Int(a0:Float, a1:Int)
		oldpercent = a0
		oldfillfade = a1
		oldfillalpha = 1.0
		ClampFloat(Varptr oldpercent, 0, 100)
	End Method
