' TDate.GetDayOfTheMonth
' VA 0x0053726D   60 bytes
' byte-identical vs NSS5.exe
' NOTE: parameter names are harness placeholders (a0, a1, ...); the
'       original source names are not recoverable from the binary.

	Method GetDayOfTheMonth:Int()
		Local d:Int, m:Int, y:Int
		GetDate(Varptr d, Varptr m, Varptr y)
		Return d
	End Method
