' TMyVector.Copy2Vec
' VA 0x004e26a3   52 bytes   vtable slot 0x6c   sig ():TMyVector
' byte-identical vs NSS5.exe (52/52, original length from Ghidra's inventory)
' the explicit Null guard is required -- it is in the original code

	Method Copy2Vec:TMyVector()
		Local v:TMyVector = New TMyVector
		If v <> Null
			v.X = X
			v.Y = Y
			v.Z = Z
		EndIf
		Return v
	End Method
