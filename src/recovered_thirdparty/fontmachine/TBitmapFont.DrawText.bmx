' TBitmapFont.DrawText
' VA 0x00590808   58 bytes   vtable slot 0x4C
' byte-identical vs NSS5.exe
' Parameter names are UNCERTAIN (not recoverable from the binary); a0.. as emitted

	Method DrawText:Int(a0:String, a1:Float, a2:Float, a3:Int)
		PrivateData.DrawTextLine(a0, a1, a2, a3, Self)
	End Method
