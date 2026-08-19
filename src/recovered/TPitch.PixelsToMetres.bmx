' TPitch.PixelsToMetres
' VA 0x004e9fc3   24 bytes   vtable slot 0x68   sig (f)f
' byte-identical vs NSS5.exe (24/24, original length from Ghidra's inventory)
' VA 0x004E9FC3, 24 bytes
' byte-identical vs NSS5.exe

	Function PixelsToMetres:Float(p:Float)
		Return p / 10.0 * 0.9144
	End Function
