' TScreen_MatchPaused.ButtonTactics
' VA 0x0054AE99   25 bytes   vtable slot 0x40   sig ()i
' byte-identical vs NSS5.exe (25/25, original length from Ghidra's inventory)
' harness mode=reloc: absolute addresses (data pointers, string/array constants, class tables)
'   differ by construction between probe and NSS5.exe; the emitted code is identical.

	Function ButtonTactics:Int()
		TScreen_Formation.SetUpScreen(0)
	End Function
