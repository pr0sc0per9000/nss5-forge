' TBitmapFont.GetFontHeight
' VA 0x00590C4B   52 bytes   vtable slot 0x58
' byte-identical vs NSS5.exe
' mode=reloc: 1 masked slot is the &bbNullObject pointer. Index 32 = Asc(" "); UNCERTAIN whether the source wrote 32 or a char constant (same codegen).
' Parameter names are UNCERTAIN (not recoverable from the binary); a0.. as emitted

	Method GetFontHeight:Int()
		If PrivateData.Face[32] = Null Then Return 0
		Return PrivateData.Face[32].DrawHeight
	End Method
