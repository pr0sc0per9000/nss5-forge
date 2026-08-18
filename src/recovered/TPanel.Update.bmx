' TPanel.Update
' VA 0x005196A3   30 bytes
' byte-identical vs NSS5.exe
' NOTE: parameter names are harness placeholders (a0, a1, ...); the
'       original source names are not recoverable from the binary.

	Method Update:Int()
		If alive = 0 Then Return 0
	End Method
