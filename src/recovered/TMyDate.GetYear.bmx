' TMyDate.GetYear
' VA 0x005374E7  29 bytes  vtable slot 0x54
' byte-identical vs NSS5.exe
' Parameter names are not recoverable from the binary and do not affect codegen;
' they are emitted as a0, a1, ... exactly as the harness compiles them.

	Method GetYear:Int()
		Return (sdate-1)/364+1
	End Method
