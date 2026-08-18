' TPlayer.pow
' VA 0x004F9CD1, 36 bytes
' byte-identical vs NSS5.exe
' The body is verified over the full 36-byte function (length from Ghidra's
'   inventory, mode=exact) and is byte-identical.

	Method pow:Int(n:Int, e:Int)
		Local r:Int = n
		For Local i:Int = 1 To e
			r = r * n
		Next
		Return r
	End Method
