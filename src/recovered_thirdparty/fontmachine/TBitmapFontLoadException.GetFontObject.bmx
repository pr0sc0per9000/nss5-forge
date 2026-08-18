' TBitmapFontLoadException.GetFontObject
' VA 0x00592382   21 bytes   vtable slot 0x30
' code-identical vs NSS5.exe (NOT byte-identical: the E8 rel32 displacement is layout-dependent)
' All 21 bytes match except the call displacement; probe target verified == TDrawTextException.GetFontObject, original target 0x00592319 == TDrawTextException.GetFontObject.
' Parameter names are UNCERTAIN (not recoverable from the binary); a0.. as emitted

	Method GetFontObject:TBitmapFont()
		Return Super.GetFontObject()
	End Method
