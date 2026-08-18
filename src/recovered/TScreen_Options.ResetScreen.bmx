' TScreen_Options.ResetScreen
' VA 0x0052110d   174 bytes   class-table slot 0x5c   sig ()i   KIND=Function (static)
' byte-identical vs NSS5.exe (174/174, original length from Ghidra's inventory)
'
' The options screen's "apply resolution" path: reopen the display at the newly chosen
' size, then go back to whichever screen the player came from and refresh its chrome.
'
' THE BUILD DEPENDS ON SetUpGraphics. The single call to the module Function at 0x00506A5D
' cannot link until 0x00506A5D itself is recovered: rule 13.3 forbids stubbing a callee to
' make a caller link, so with SetUpGraphics missing the build fails on "Identifier
' 'SetUpGraphics' not found" even though the body is correct. With SetUpGraphics verified
' into src/recovered_module/SetUpGraphics.bmx (436/436), this body reaches MATCH unchanged.
' Worth remembering: a BUILD_FAIL on an unresolved identifier says nothing about whether the
' body is right.
'
' Globals, all pre-resolved and re-confirmed here:
'   g_screen_options_int01/02 @ 0x00C5D244/0x00C5D248 -- Int. The saved `screen` and
'     `window` values TOptions.LoadOptions reads from Settings/Options.ini; the SAME pair
'     GameMain passes to SetUpGraphics at boot (docs/game/engine/main-loop.md).
'   g_prevscreen @ 0x00C63CEC -- String, not Int. Confirmed against
'     src/recovered/TScreen_Options.ButtonBack.bmx, which passes the identical global to
'     the identical TScreen.SetActive($,$) call.
'   g_screen_mainmenu_int03 @ 0x00C639FC -- String. The literal assigned is the STRING "0",
'     not the integer 0; it compiles to the standard refcounted store idiom.
'   g_player_int01 @ 0x00C5B1FC -- Int (hand-verified, globals_corrections.tsv).
'
' The third argument to SetUpGraphics is 0 here and 1 at the GameMain boot call site --
' the only difference between "open the display for the first time" and "reopen it after
' the player changed resolution".
	Function ResetScreen:Int()
		'!Global g_screen_options_int01:Int
		'!Global g_screen_options_int02:Int
		'!Global g_prevscreen:String
		'!Global g_screen_mainmenu_int03:String
		'!Global g_player_int01:Int
		LogLine("ResetScreen")
		SetUpGraphics(g_screen_options_int01, g_screen_options_int02, 0)
		TScreen.SetActive(g_prevscreen, "")
		g_screen_mainmenu_int03 = "0"
		TScreen_MainMenu.UpdateVersionInfo()
		If g_prevscreen <> "mainmenu" And g_player_int01 = 0
			TScreen_GameMenu.UpdateTitlePanel()
			TScreen_GameMenu.UpdateNavPanel()
		EndIf
	End Function
