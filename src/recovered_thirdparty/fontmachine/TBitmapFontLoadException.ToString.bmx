' TBitmapFontLoadException.ToString
' VA 0x0059236D   21 bytes   vtable slot 0x18
' code-identical vs NSS5.exe (NOT byte-identical: the E8 rel32 displacement is layout-dependent)
' All 21 bytes match except the call displacement; probe target verified == TDrawTextException.ToString, original target 0x005922E6 == TDrawTextException.ToString.
' Parameter names are UNCERTAIN (not recoverable from the binary); a0.. as emitted

	Method ToString:String()
		Return Super.ToString()
	End Method
