' TMyVector.Create
' VA 0x004e21d2   40 bytes   vtable slot 0x30   sig (d,d,d):TMyVector
' byte-identical vs NSS5.exe (40/40, original length from Ghidra's inventory)
' local name not recoverable

	Function Create:TMyVector(a0:Double, a1:Double, a2:Double)
		Local v:TMyVector = New TMyVector
		v.X = a0
		v.Y = a1
		v.Z = a2
		Return v
	End Function
