' TMyBankStream.Create
' VA 0x00508260   56 bytes   vtable slot 0xa4   sig (:TBank):TMyBankStream
' byte-identical vs NSS5.exe (56/56, original length from Ghidra's inventory)
' _bank is the inherited TBankStream field at +0xc.
	Function Create:TMyBankStream(a0:TBank)
		Local s:TMyBankStream = New TMyBankStream
		s._bank = a0
		Return s
	End Function
