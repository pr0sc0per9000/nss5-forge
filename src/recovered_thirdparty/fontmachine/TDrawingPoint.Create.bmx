' TDrawingPoint.Create
' VA 0x005929D7   34 bytes   vtable slot 0x30   sig (f,f):TDrawingPoint
' byte-identical vs NSS5.exe (34/34)
' THIRD-PARTY MODULE (fontmachine) -- this body must NOT be moved into src/recovered/.
' Parameter names are UNCERTAIN (not recoverable from the binary); a0.. as emitted

	Function Create:TDrawingPoint(a0:Float, a1:Float)
		Local p:TDrawingPoint = New TDrawingPoint
		p.X = a0
		p.Y = a1
		Return p
	End Function
