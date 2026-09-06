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
		' 0x00C65E30, the calendar's own saved screen name, measured at 0x0053680F
' `ff35305ec600 push dword ptr [0xc65e30]` into TScreen.SetActive;
' TScreen_Calendar.SetUpScreen names the slot g_calendar_prevname. g_prevscreen is
' TScreen_Options.ButtonBack's name for 0x00C63CEC, so quitting the calendar returned to
' whatever screen the options back-button had last stored.
'!Global g_calendar_prevname:String
		TScreen.SetActive(g_calendar_prevname,"")
	End Function
