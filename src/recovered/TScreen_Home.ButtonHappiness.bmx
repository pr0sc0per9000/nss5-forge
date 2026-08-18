' TScreen_Home.ButtonHappiness
' VA 0x0053ce32   25 bytes   vtable slot 0x38   sig ()i
' byte-identical vs NSS5.exe (25/25, original length from Ghidra's inventory)
' Callee resolved via class table 0x00c66d04 -> TScreen_Relationships + slot 0x34.
	Function ButtonHappiness:Int()
		TScreen_Relationships.SetUpScreen(1)
	End Function
