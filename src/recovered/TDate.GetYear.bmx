' TDate.GetYear
' VA 0x005372E5   60 bytes
' byte-identical vs NSS5.exe
' NOTE: parameter names are harness placeholders (a0, a1, ...); the
'       original source names are not recoverable from the binary.

	Method GetYear:Int()
		Local d:Int, m:Int, y:Int
		GetDate(Varptr d, Varptr m, Varptr y)
		Return y
	End Method
