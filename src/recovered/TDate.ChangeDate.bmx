' TDate.ChangeDate
' VA 0x00536F6E   143 bytes
' byte-identical vs NSS5.exe
' NOTE: parameter names are harness placeholders (a0, a1, ...); the
'       original source names are not recoverable from the binary.

	Method ChangeDate:Int(a0:Int, a1:Int, a2:Int)
		Local d:Int, m:Int, y:Int
		GetDate(Varptr d, Varptr m, Varptr y)
		m :+ a1
		y :+ a2
		m :- 1
		y :+ m / 12
		m = m Mod 12 + 1
		d :+ a0
		SetDate(d, m, y)
	End Method
