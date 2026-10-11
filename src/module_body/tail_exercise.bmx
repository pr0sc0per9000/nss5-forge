' ============================================================================
' EXERCISER TAIL -- an alternate module-body tail used ONLY by the automated
' smoke test. Selected with NSS5_TAIL=exercise; the normal build is unaffected.
'
' WHY THIS EXISTS
' Finding bugs by asking a human to click every button and paste the crash is
' slow, and it only ever finds the FIRST crash on whichever path they happened
' to take. This does the clicking.
'
' It works because of blitzmax-language-guide 11.1: in a `-d` build a Null field
' access throws a CATCHABLE TNullObjectException (release silently returns 0).
' So every screen activation, frame and button handler can be wrapped in
' Try/Catch, and one run reports EVERY failure instead of dying on the first.
'
' It drives the real boot sequence GameMain uses -- same calls, same order --
' and then, instead of entering the fixed-timestep loop, walks g_screens (the
' registry TScreen.SetActive itself searches) and for each screen:
'     SetActive -> Update -> Render        (does the screen come up and draw?)
'     then fires every gadget's fHit()     (does each button work?)
'
' Output is one line per check, written BEFORE the risky call as well as after,
' so if a handler kills the process outright (rather than throwing) the last
' line still names it.
'
' NOT A SUBSTITUTE FOR PLAYING IT. It cannot judge whether a screen looks right,
' and it fires handlers out of the order a player would, so some failures are
' artefacts of missing context rather than real bugs. It is a net, not a verdict.
' ============================================================================

' The boot below is src/module_body/tail.bmx's, statement for statement, up to its
' GameMain() call; this file then walks the screens instead of entering the game.

Global g_promotionplace_int05:String = ""         ' 0x00C6E950, the install root
Global g_replay_div:Int = 25                      ' 0x00C6F02C, the fixed timestep in ms
Global g_logstream:TStream                        ' 0x00C6EFF0
Global g_forgotpwurl:String = "http://www.newstarsoccer.com/forgottenpassword.php?msg=Enter your player name and click reset to change your password..."   ' 0x00C6EF10
Global g_version:String = "1.15"                  ' 0x00C6E900
Global g_col_highlight:String = "00FF00"          ' 0x00C6E91C
Global g_locale_lang:String = "en"                ' 0x00C5A33C
Global g_homeurl:String = "http://www.newstargames.com/"                       ' 0x00C6EA98
Global g_url_facebook:String = "http://www.facebook.com/pages/New-Star-Soccer/173805879330444"   ' 0x00C6EBE4
Global g_twitterurl:String = "http://twitter.com/newstargames"                 ' 0x00C6EC34
Global g_mobile_url:String = "http://www.newstargames.com/en/text/releases/Releases/item/200/Releases-New-Star-Soccer"   ' 0x00C6EB58

AppTitle = "New Star Soccer 5"                                                    ' +5552
Global g_userpath:String = Trim(ReadSettingString(g_promotionplace_int05 + "Settings/Settings.txt", "saveloc")).ToUpper()   ' +5585 #65
If Right(g_userpath, 1) <> "/" And Right(g_userpath, 1) <> "\"                  ' +5664
	g_userpath = g_userpath + "/"
EndIf
If g_userpath.length < 3                                                          ' +5801
	g_userpath = Fn_0059812E() + "/New Star Soccer 5/"                            ' BaH.Volumes GetUserDocumentsDir
EndIf
CreateDir(g_userpath, False)                                                      ' +5861
CreateDir(g_userpath + "Settings/", False)
CreateDir(g_userpath + "Save/", False)
CreateDir(g_userpath + "Replays/", False)
g_forgotpwurl.Replace(" ", "%20")                                                 ' +5967, result discarded
Global g_engine_int161:Int = Int(ReadSettingFloat(g_promotionplace_int05 + "Settings/Settings.txt", "debug", 0.0, 2.0))          ' +5991 #66
Global g_club_int07:Int = Int(ReadSettingFloat(g_promotionplace_int05 + "Settings/Settings.txt", "fullnames", 0.0, 1.0))         ' +6070 #67
Global g_misc_int62:Int = Int(ReadSettingFloat(g_promotionplace_int05 + "Settings/Settings.txt", "nettimeout", 3.0, 99.0))       ' +6149 #68
Global g_misc_int63:Int = Int(ReadSettingFloat(g_promotionplace_int05 + "Settings/Settings.txt", "port", 0.0, 100000000.0))      ' +6231 #69
Global g_misc_int64:String = ReadSettingString(g_promotionplace_int05 + "Settings/Settings.txt", "proxy")                       ' +6310 #70
Global g_pausedms:Int = MilliSecs()                                               ' +6371 #71
SeedRnd(g_pausedms)                                                               ' +6406
Global g_engine_int164:Int = JoyCount()                                           ' +6420 #72
If g_engine_int161                                                                ' +6455
	g_logstream = WriteFile(g_promotionplace_int05 + "log.txt")
EndIf
LogLine("Debug=" + g_engine_int161)                                               ' +6522
Global g_profile:TProfile = New TProfile                                          ' +6559 #73
Global g_frameaccum:Int = g_replay_div                                            ' +6605 #74, one full tick
LogLine(GetGraphicsDriver().ToString())                                           ' +6640
If ReadSettingFloat(g_promotionplace_int05 + "Settings/Settings.txt", "opengl", 0.0, 1.0) = 1.0    ' +6663
	SetGraphicsDriver(GLMax2DDriver(), 2)
Else
	If Not D3D9Max2DDriver()                                                      ' +6741
		SetGraphicsDriver(D3D7Max2DDriver(), 2)
	EndIf
EndIf
EnableOpenALAudio()                                                               ' +6778
If Not SetAudioDriver("OpenAL")                                                   ' +6783
	SetAudioDriver("FreeAudio")
	LogLine("FreeAudio")
EndIf
Global g_object857:TChannel = AllocChannel()                                      ' +6827 #75
Global g_musicchannel:TChannel = AllocChannel()                                   ' +6865 #76
Global g_object859:TChannel = AllocChannel()                                      ' +6903 #77
Global g_object860:TSound = LoadSoundChecked("GameMedia/Sounds/Cash.ogg", 0)       ' +6941 #78
Global g_object861:TSound = LoadSoundChecked("GameMedia/Sounds/Achievement.ogg", 0)    ' +6989 #79
Global g_tracks:TSound[6]                                                         ' +7037 #80
SetMaskColor(8, 132, 107)                                                         ' +7085
AutoMidHandle(False)                                                              ' +7102
Global g_iconpath:String = g_promotionplace_int05 + "GameMedia/Images/Icons/"     ' +7112 #81
Global g_object862:TImage = LoadImageChecked(g_iconpath + "ArrowL.png", -1)       ' +7164 #82
Global g_object863:TImage = LoadImageChecked(g_iconpath + "ArrowR.png", -1)       ' #83
Global g_object864:TImage = LoadImageChecked(g_iconpath + "ArrowU.png", -1)       ' #84
Global g_object865:TImage = LoadImageChecked(g_iconpath + "ArrowD_Red.png", -1)   ' #85
Global g_object866:TImage = LoadImageChecked(g_iconpath + "Refresh.png", -1)      ' #86
Global g_object867:TImage = LoadImageChecked(g_iconpath + "Cross.png", -1)        ' #87
Global g_object868:TImage = LoadImageChecked(g_iconpath + "Tick.png", -1)         ' #88
Global g_object869:TImage = LoadImageChecked(g_iconpath + "CrossSmall.png", -1)   ' #89
Global g_object870:TImage = LoadImageChecked(g_iconpath + "TickSmall.png", -1)    ' #90
Global g_object871:TImage = LoadImageChecked(g_iconpath + "Help.png", -1)         ' #91
Global g_object872:TImage = LoadImageChecked("GameMedia\Images\Interface\MessageBg.png", -1)    ' +7794 #92
Global g_object873:TImage = LoadImageChecked("GameMedia\Images\Interface\MessageLine.png", 1)   ' +7842 #93

' ---- boot, exactly as GameMain does, minus the loop -----------------------------
' Each boot step is individually guarded. An unguarded one ends the whole sweep and we
' learn about exactly one bug per run, which is the back-and-forth this harness exists to
' avoid. TLocale.SetUp and TOptions.SetUp are the two that can legitimately call End
' rather than throw (missing language file / unwritable options file), so those still stop
' it -- but they print first, so the last line names them.
Print "[ex] TLocale.SetUp"
TLocale.SetUp()
Print "[ex] TOptions.SetUp"
TOptions.SetUp()
Print "[ex] SetUpGraphics"
Try
	SetUpGraphics(g_opt_screen, 1, 0)      ' a1=1 -> WINDOWED, a2=0 -> no splash
Catch ex:Object
	Print "[EX-FAIL] SetUpGraphics :: " + ex.ToString()
End Try
' StartMusic was omitted from an earlier version of this harness and that mattered:
' it is PlayTrack(1) -> UpdateAudio(), which is what loads the six incbin'd music
' tracks into g_tracks and allocates the music channel. GameMain calls it between
' SetUpGraphics and TScreen.SetUp, so skipping it left later boot steps running
' against state the real game always has.
Print "[ex] StartMusic (then silenced)"
Try
	StartMusic()
	' SILENCE IT. This harness runs unattended on the user's desktop; leaving the
	' title music playing under a black window is just noise. PlayTrack(0) takes the
	' `a0 = 0` branch and stops the channel, so the load path in UpdateAudio still
	' runs (which is why StartMusic is called at all) but nothing is audible.
	PlayTrack(0)
Catch ex:Object
	Print "[EX-FAIL] StartMusic :: " + ex.ToString()
End Try
Print "[ex] TScreen.SetUp"
Try
	TScreen.SetUp()
Catch ex:Object
	Print "[EX-FAIL] TScreen.SetUp :: " + ex.ToString()
End Try
' SELECT A LANGUAGE. The real boot reaches this via the language-picker screen, which is
' the first thing GameMain shows; every GetText() before that point dereferences Null.
' Traced from the sweep's own stack trace:
'     TEngine.SetUp -> TScreen.DoProgressBar(10, GetText("Loading"), ...) -> GetText
'     -> TLocale.GetLocaleText:
'        String(TMap(g_locale_maps.ValueForKey(g_locale_lang)).ValueForKey(a0))
' With g_locale_lang unset, ValueForKey returns Null, TMap(Null) is Null, and the second
' ValueForKey faults. A harness omission, not a game bug -- but worth recording, because
' three of the sweep's failures were this one missing call cascading.
Print "[ex] TLocale.SetCurrentLanguage(en)"
Try
	TLocale.SetCurrentLanguage("en")
Catch ex:Object
	Print "[EX-FAIL] SetCurrentLanguage :: " + ex.ToString()
End Try

Print "[ex] TEngine.SetUp"
Try
	TEngine.SetUp()
Catch ex:Object
	Print "[EX-FAIL] TEngine.SetUp :: " + ex.ToString()
End Try

' A profile with world data loaded, so screens that read clubs/nations have
' something to read. Without this most in-career screens fail for a reason that
' says nothing about their own correctness.
Print "[ex] TProfile.SetUp (world data)"
Try
	TProfile.SetUp()
Catch ex:Object
	Print "[EX-FAIL] TProfile.SetUp :: " + ex.ToString()
End Try

Print "[ex] CreateAllScreens"
Try
	CreateAllScreens()
Catch ex:Object
	Print "[EX-FAIL] CreateAllScreens :: " + ex.ToString()
End Try

' ---- walk every screen ----------------------------------------------------------
Global ex_screens:Int = 0
Global ex_screenfail:Int = 0
Global ex_buttons:Int = 0
Global ex_buttonfail:Int = 0

Print "[ex] ==== SCREEN SWEEP ===="
For Local s:TScreen = EachIn g_screens
	Local nm:String = s.name
	ex_screens :+ 1
	Print "[ex] screen=" + nm
	Try
		TScreen.SetActive(nm, "")
		TScreen.Update()
		TScreen.Render(0.0)
		Flip(0)
	Catch ex:Object
		ex_screenfail :+ 1
		Print "[EX-FAIL] screen " + nm + " :: " + ex.ToString()
	End Try
Next

Print "[ex] ==== BUTTON SWEEP ===="
For Local s:TScreen = EachIn g_screens
	Local nm:String = s.name
	' Re-activate before each screen's buttons: a handler fired earlier will have
	' navigated away, and firing a button on an inactive screen tests nothing.
	Try
		TScreen.SetActive(nm, "")
	Catch ex:Object
		Print "[EX-FAIL] reactivate " + nm + " :: " + ex.ToString()
		Continue
	End Try

	For Local g:TGadget = EachIn s.GetGadgetList()
		If Not g Then Continue
		If Not g.fHit Then Continue
		Local gn:String = g.name
		' `End` is a real handler on some quit buttons (TScreen_MainMenu.ButtonQuit is
		' literally `End`), and calling it would terminate this run and lose every
		' result after it. Skipped by name, and reported so the skip is visible.
		Local lgn:String = Lower(gn)
		' `End` is a real handler on some quit buttons (TScreen_MainMenu.ButtonQuit is
		' literally `End`), and calling it terminates this run and loses every result
		' after it.
		If lgn.Contains("quit") Or lgn.Contains("exit")
			Print "[ex]   skip " + nm + "/" + gn + " (quit handler may call End)"
			Continue
		EndIf
		' World-loading and match-entry handlers. These re-run TProfile.SetUp (every CSV
		' in the game) behind a progress bar, or start a match. Measured: the sweep sat on
		' mainmenu_newgame indefinitely and covered ONE button in the time it takes to
		' cover all the rest. They are also the paths already exercised by hand, so the
		' coverage lost here is small and the coverage gained is 49 screens.
		' "lang"/"langim" is the Change Language button: its handler tears down and rebuilds
		' every screen in the game (TScreen.ResetScreens -> CreateAllScreens), which the
		' sweep then walks again. Measured: it stalled the run at exactly that click.
		If lgn.Contains("newgame") Or lgn.Contains("loadgame") Or lgn.Contains("loadsave") ..
		   Or lgn.Contains("continue") Or lgn.Contains("play") Or lgn.Contains("replay") ..
		   Or lgn.Contains("lang")
			Print "[ex]   skip " + nm + "/" + gn + " (long world-load / match entry)"
			Continue
		EndIf
		ex_buttons :+ 1
		Print "[ex]   click " + nm + "/" + gn
		Try
			g.fHit()
		Catch ex:Object
			ex_buttonfail :+ 1
			Print "[EX-FAIL] click " + nm + "/" + gn + " :: " + ex.ToString()
		End Try
		' A handler may have navigated; restore so the next gadget is fired in context.
		Try
			TScreen.SetActive(nm, "")
		Catch ex:Object
		End Try
	Next
Next

Print "[ex] ==== SUMMARY ===="
Print "[ex] screens swept : " + ex_screens + "   failed: " + ex_screenfail
Print "[ex] buttons fired : " + ex_buttons + "   failed: " + ex_buttonfail
Print "[ex] DONE"
End
