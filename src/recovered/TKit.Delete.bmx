' TKit.Delete
' VA 0x004da6e0   100 bytes   vtable slot 0x14   sig ()i
' byte-identical vs NSS5.exe (100/100, original length from Ghidra's inventory)
' the explicit 'pixmap = Null' is the only user statement; the three field releases after it are bcc's implicit destructor tail
	Method Delete()
		pixmap = Null
	End Method
