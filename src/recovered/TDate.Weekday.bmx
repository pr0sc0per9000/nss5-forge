' TDate.Weekday
' VA 0x00537014   22 bytes
' byte-identical vs NSS5.exe
' NOTE: parameter names are harness placeholders (a0, a1, ...); the
'       original source names are not recoverable from the binary.

	Function Weekday:Int(a0:Int)
		Return a0 Mod 7
	End Function
