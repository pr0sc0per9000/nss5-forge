' TCombo.CountItems -- VA 0x00519232, 24 bytes
' byte-identical vs NSS5.exe
' Parameter names are not recoverable from the binary and do not affect codegen.
Method CountItems:Int()
	Return buttons.Count()
End Method
