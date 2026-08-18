' TPitch.YardsToMetres
' VA 0x004EA005, 18 bytes
' byte-identical vs NSS5.exe

	Function YardsToMetres:Float(y:Float)
		Return y * 0.9144
	End Function
