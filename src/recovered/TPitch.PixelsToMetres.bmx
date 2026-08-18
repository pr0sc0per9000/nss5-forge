' TPitch.PixelsToMetres
' VA 0x004E9FC3, 24 bytes
' byte-identical vs NSS5.exe

	Function PixelsToMetres:Float(p:Float)
		Return p / 10.0 * 0.9144
	End Function
