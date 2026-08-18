' TScreen_Language.ButtonLanguage
' VA 0x0051bfc9   206 bytes   vtable slot 0x38   sig ()i
' byte-identical vs NSS5.exe (206/206, original length from Ghidra's inventory)
' ASSUMPTIONS: module Global 0x00c5d290 declared String, NOT the Int globals_final.tsv
' claims -- it carries full retain/release traffic (FF 40 04 / FF 48 04 / bbGCFree).
' 0x00c639fc likewise String (assigned a literal), 0x00c638c4 Int, 0x00c63ce8 TScreen.
' Slots: TGadget+0x7c GetActiveGadgetName, TOptions+0x48 SaveOptions,
' TLocale+0x34 SetCurrentLanguage, TScreen+0x34 SetUpFonts, TScreen+0x58 ResetScreens,
' TScreen+0x5c SetActive($,$), TScreen_MainMenu+0x34 SetUpScreen,
' TScreen_Options+0x38 RefreshButtons, TScreen_MainMenu+0x68 UpdateVersionInfo.
' FUN_004a7c20 = _bbStringConcat, so the LogLine argument is a concatenation.
' All String literals are masked addresses; their VALUES are not proven.
'
' NOTE: the branch sense is load-bearing. bcc negates the source condition and jumps to
' the Else, so "If g <> 0" is what emits "cmp [g],0 / je <else>" with the SetActive block
' falling through. Written "If g = 0 Then SetUpScreen Else ..." the length is still 206
' but it diverges at byte 117 (jne + jmp instead of je).
' harness mode=reloc, 25 addresses masked.
	Function ButtonLanguage:Int()
		'!Global g_langname:String
		'!Global g_lang_int05:Int
		'!Global g_mainmenu_str:String
		'!Global g_screen:TScreen
		g_langname = TGadget.GetActiveGadgetName()
		LogLine("ButtonLanguage:" + g_langname)
		TOptions.SaveOptions()
		TLocale.SetCurrentLanguage(g_langname)
		TScreen.SetUpFonts(g_langname)
		TScreen.ResetScreens()
		If g_lang_int05 <> 0
			TScreen.SetActive(g_screen.name, "")
			TScreen_Options.RefreshButtons()
			g_mainmenu_str = "0"
			TScreen_MainMenu.UpdateVersionInfo()
		Else
			TScreen_MainMenu.SetUpScreen()
		End If
	End Function
