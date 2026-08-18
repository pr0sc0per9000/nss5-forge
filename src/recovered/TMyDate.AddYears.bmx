' TMyDate.AddYears
' VA 0x00537414  33 bytes  vtable slot 0x44
' byte-identical vs NSS5.exe
' Parameter names are not recoverable from the binary and do not affect codegen;
' they are emitted as a0, a1, ... exactly as the harness compiles them.

	Method AddYears:Int(a0:Int)
		AddWeeks(a0*52)
	End Method
