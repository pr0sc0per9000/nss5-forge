' TCombo.SetAlph -- VA 0x005193DE, 41 bytes
' byte-identical vs NSS5.exe
' Parameter names are not recoverable from the binary and do not affect codegen.
Method SetAlph:Int(a0:Float)
	alph = a0
	btn_head.SetAlph(a0)
End Method
