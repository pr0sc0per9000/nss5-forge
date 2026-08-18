' TDrawTextException.GetFontObject
' VA 0x00592319, 18 bytes
' byte-identical vs NSS5.exe

	Method GetFontObject:TBitmapFont()
		Return PrivateData.Offending
	End Method
