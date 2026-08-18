' TScreen_MatchPaused.ButtonSkipTime
' VA 0x0054AEC6   231 bytes   vtable slot 0x48   sig ()i   KIND=Function (static)
' byte-identical vs NSS5.exe (231/231, mode=reloc, reloc_masked=20)
'
' ASSUMPTIONS (module Global names are ours; declared types are load-bearing):
'   g_training_int03 = 0x00C6CF90  Int
'   g_hometeam       = 0x00C5B218  TTeam   (globals_final says TKit with a flagged
'                                           conflict; field 0x3C = TTeam.newstarselno
'                                           at the call site, so TTeam -- trust the code)
'   g_awayteam       = 0x00C5B21C  TTeam
'   g_bgimage        = 0x00C61714  TImage  (stored into TScreen.bg at +0x10)
'   g_curscreen      = 0x00C6764C  TScreen
'
' NOTE: Ghidra prints `if (DAT_00c6cf90 < 1)` with the skip-time branch first; the real
' `cmp dword [g],0 / jle` is `If g > 0` with the QUIT branch first (codegen-patterns 10.1).

	Function ButtonSkipTime:Int()
		'!Global g_training_int03:Int
		'!Global g_hometeam:TTeam
		'!Global g_awayteam:TTeam
		'!Global g_bgimage:TImage
		'!Global g_curscreen:TScreen
		If g_training_int03 > 0
			If TScreen.DoMessage(GetText("CMESSAGE_QUIT"),1,0)
				g_curscreen.bg = g_bgimage
				TEngine.SkipMatchTime()
			EndIf
		Else
			Local key:String = "CMESSAGE_SKIPTIMEEND"
			If g_hometeam.newstarselno = 11 Or g_awayteam.newstarselno = 11 Then key = "CMESSAGE_SKIPTIMESUB"
			If TScreen.DoMessage(GetText(key),1,0)
				g_curscreen.bg = g_bgimage
				TEngine.SkipMatchTime()
			EndIf
		EndIf
	End Function
