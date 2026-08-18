' TMyVector.GetLength
' VA 0x004e2704   48 bytes   vtable slot 0x7c   sig ()d
' byte-identical vs NSS5.exe (48/48, original length from Ghidra's inventory)
' 0x004a1ef0 is bbSqr; source order X,Y,Z (the FPU prints in reverse)

	Method GetLength:Double()
		Return Sqr(X*X + Y*Y + Z*Z)
	End Method
