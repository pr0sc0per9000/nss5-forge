' TCombo.SetAlph -- VA 0x005193DE, 41 bytes
' VA 0x005193de   41 bytes   vtable slot 0x70   sig (f)i
' byte-identical vs NSS5.exe (41/41, original length from Ghidra's inventory)
' byte-identical vs NSS5.exe
' Parameter names are not recoverable from the binary and do not affect codegen.
Method SetAlph:Int(a0:Float)
	alph = a0
	btn_head.SetAlph(a0)
End Method
