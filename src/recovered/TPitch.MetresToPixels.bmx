' TPitch.MetresToPixels
' VA 0x004e9fed   24 bytes   vtable slot 0x70   sig (f)f
' byte-identical vs NSS5.exe (24/24, original length from Ghidra's inventory)
' VA 0x004E9FED, 24 bytes
' byte-identical vs NSS5.exe

	Function MetresToPixels:Float(m:Float)
		Return m * 1.0936133 * 10.0
	End Function
