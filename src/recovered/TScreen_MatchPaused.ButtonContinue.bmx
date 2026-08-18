' TScreen_MatchPaused.ButtonContinue
' VA 0x0054AE19   61 bytes   vtable slot 0x38   sig ()i
' byte-identical vs NSS5.exe (61/61, original length from Ghidra's inventory)
' Assumptions: module Global 0x00c6764c = g_screen:TScreen (typed from its construction
' site in globals_final.tsv); field +0x10 of TScreen is bg:TImage, so 0x00c61714 is
' declared TImage. Class-table pointer 0x00c5bb30 = TEngine.PauseEngine (slot 0x100).
	Function ButtonContinue:Int()
		'!Global g_matchpaused_bg:TImage
		'!Global g_screen:TScreen
		g_screen.bg = g_matchpaused_bg
		TEngine.PauseEngine()
	End Function
