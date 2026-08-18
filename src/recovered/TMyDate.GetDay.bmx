' TMyDate.GetDay
' VA 0x0053749B  35 bytes  vtable slot 0x4c
' byte-identical vs NSS5.exe
' Parameter names are not recoverable from the binary and do not affect codegen;
' they are emitted as a0, a1, ... exactly as the harness compiles them.

	Method GetDay:Int()
		Local d:Int=sdate Mod 7
		If d=0 Then d=7
		Return d
	End Method
