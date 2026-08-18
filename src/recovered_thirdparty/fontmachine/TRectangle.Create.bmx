' TRectangle.Create
' VA 0x00592919   46 bytes   vtable slot 0x30   sig (f,f,f,f):TRectangle
' byte-identical vs NSS5.exe (46/46)
' THIRD-PARTY MODULE (fontmachine) -- this body must NOT be moved into src/recovered/.
' Parameter names are UNCERTAIN (not recoverable from the binary); a0.. as emitted

	Function Create:TRectangle(a0:Float, a1:Float, a2:Float, a3:Float)
		Local r:TRectangle = New TRectangle
		r.X = a0
		r.Y = a1
		r.Width = a2
		r.Height = a3
		Return r
	End Function
