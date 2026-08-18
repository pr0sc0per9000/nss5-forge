' TDate.SetJulian
' VA 0x005369A4   23 bytes
' byte-identical vs NSS5.exe
' NOTE: parameter names are harness placeholders (a0, a1, ...); the
'       original source names are not recoverable from the binary.

	Method SetJulian:Int(a0:Int)
		gDate = a0
	End Method
