' TKit.ColorInt
' VA 0x004DBFE2   65 bytes
' byte-identical vs NSS5.exe
' NOTE: parameter names are harness placeholders (a0, a1, ...); the
'       original source names are not recoverable from the binary.

	Function ColorInt:Int(a0:Int, a1:Int, a2:Int, a3:Int)
		Local col:Int = a2 + a1 * 256 + a0 * 65536 + (a3 Mod 128) * 16777216
		If a3 > 128 Then col = col - $80000000
		Return col
	End Function
