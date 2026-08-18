' TPitch.MetresToPixels
' VA 0x004E9FED, 24 bytes
' byte-identical vs NSS5.exe

	Function MetresToPixels:Float(m:Float)
		Return m * 1.0936133 * 10.0
	End Function
