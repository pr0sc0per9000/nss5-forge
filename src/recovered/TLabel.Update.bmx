' TLabel.Update
' VA 0x00519B8C   75 bytes
' byte-identical vs NSS5.exe
' parameter names are placeholders (a0, a1, ...); the original names are not recoverable

	Method Update:Int()
		If hidden Then Return 0
		scrollx = scrollx + scrolltext
		If scrollx < x - txtw Then scrollx = x + w
	End Method
