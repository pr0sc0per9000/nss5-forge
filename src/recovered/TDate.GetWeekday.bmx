' TDate.GetWeekday
' VA 0x00536FFD   23 bytes
' byte-identical vs NSS5.exe
' NOTE: parameter names are harness placeholders (a0, a1, ...); the
'       original source names are not recoverable from the binary.

	Method GetWeekday:Int()
		Return Weekday(gDate)
	End Method
