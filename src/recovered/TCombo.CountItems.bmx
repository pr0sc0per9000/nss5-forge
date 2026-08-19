' TCombo.CountItems -- VA 0x00519232, 24 bytes
' VA 0x00519232   24 bytes   vtable slot 0xb8   sig ()i
' byte-identical vs NSS5.exe (24/24, original length from Ghidra's inventory)
' byte-identical vs NSS5.exe
' Parameter names are not recoverable from the binary and do not affect codegen.
Method CountItems:Int()
	Return buttons.Count()
End Method
