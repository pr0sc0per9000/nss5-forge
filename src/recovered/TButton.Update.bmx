' TButton.Update
' VA 0x00515132   131 bytes   vtable slot 0x34   sig ()i
' byte-identical vs NSS5.exe (131/131, original length from Ghidra's inventory)
' the two trailing guards produce dead "mov eax,0 / jmp" pairs in the original and are required for the byte match.
' Parameter names are not recoverable from the binary; a0/a1/... as emitted by the harness.
	Method Update:Int()
		If desx <> x Then x = x + (desx - x) * 0.1
		If desy <> y Then y = y + (desy - y) * 0.1
		If hidden Then Return 0
		If Not alive Then Return 0
	End Method
