' TDate.SetDate
' VA 0x005368B1   149 bytes
' byte-identical vs NSS5.exe
' NOTE: parameter names are harness placeholders (a0, a1, ...); the
'       original source names are not recoverable from the binary.
' The body is verified over the full 149-byte function (length from Ghidra's
'   inventory, mode=exact) and is byte-identical.

	Method SetDate:Int(a0:Int, a1:Int, a2:Int)
		Local a:Int = (14 - a1) / 12
		Local y:Int = a2 + 4800 - a
		Local m:Int = a1 + 12 * a - 3
		gDate = a0 + (m * 153 + 2) / 5 + y * 365 + y / 4 - y / 100 + y / 400 - 32045
		Return gDate
	End Method
