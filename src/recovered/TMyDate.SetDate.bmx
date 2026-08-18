' TMyDate.SetDate
' VA 0x005373AF  52 bytes  vtable slot 0x38
' byte-identical vs NSS5.exe
' Parameter names are not recoverable from the binary and do not affect codegen;
' they are emitted as a0, a1, ... exactly as the harness compiles them.

	Method SetDate:Int(a0:Int, a1:Int, a2:Int)
		sdate=(a2-1)*364
		sdate:+(a1-1)*7
		sdate:+a0
	End Method
