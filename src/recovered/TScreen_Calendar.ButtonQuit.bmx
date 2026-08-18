' TScreen_Calendar.ButtonQuit
' VA 0x00536807   34 bytes   vtable slot 0x38   sig ()i
' byte-identical vs NSS5.exe (34/34, original length from Ghidra's inventory)
' Parameter names are not recoverable from the binary and do not affect codegen;
' they are emitted as a0, a1, ... exactly as the harness compiles them.
' ASSUMPTION: module Global at 0x00c65e30 declared String (the first argument is a LOAD
' from that address, not an address-of, so it is a variable and not a literal).
' &PTR_PTR_00c5d284 is bbEmptyString -> the "" literal.
' PTR_FUN_00c61c88 resolves to TScreen + 0x5c = TScreen.SetActive.

	Function ButtonQuit:Int()
		'!Global g_prevscreen:String
		TScreen.SetActive(g_prevscreen,"")
	End Function
