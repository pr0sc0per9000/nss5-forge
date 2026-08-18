' TDate.GetMonth
' VA 0x005372A9   60 bytes
' byte-identical vs NSS5.exe
' NOTE: parameter names are harness placeholders (a0, a1, ...); the
'       original source names are not recoverable from the binary.

	Method GetMonth:Int()
		Local d:Int, m:Int, y:Int
		GetDate(Varptr d, Varptr m, Varptr y)
		Return m
	End Method
