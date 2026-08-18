' TMyDate.AddWeeks
' VA 0x005373FA  26 bytes  vtable slot 0x40
' byte-identical vs NSS5.exe
' Parameter names are not recoverable from the binary and do not affect codegen;
' they are emitted as a0, a1, ... exactly as the harness compiles them.

	Method AddWeeks:Int(a0:Int)
		sdate:+a0*7
	End Method
