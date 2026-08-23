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

Print "[boot] module body entered (EXERCISE tail)"

g_dataDir = AppDir + "/"
' CASE DIRECTION CORRECTED 2026-08-22: module-body offset +5632 calls the brl.retro
' Trim wrapper (0x0059C8E8) and +5641 calls 0x004A7410, which is _bbStringToUpper,
' not the _brl_retro_Lower the learned helper table used to name it. See
' docs/reference/codegen-patterns.md 15.6.
g_savedir = Trim(ReadSettingString(g_dataDir + "Settings/Settings.txt", "saveloc")).ToUpper()
If Right(g_savedir, 1) <> "/" And Right(g_savedir, 1) <> "\"
	g_savedir = g_savedir + "/"
EndIf
If g_savedir.length < 3
	g_savedir = CurrentDir() + "/New Star Soccer 5/"
EndIf
' INSTALL prefix (0x00C6E950), not the save root -- see the long note in tail.bmx.
' TLocale.SetUp reads this slot for GameMedia/Languages/Languages.csv and hard-exits if
' the file is missing, which is what stopped the first exerciser run after two lines.
g_pathPrefix = g_dataDir
CreateDir(g_savedir, False)
CreateDir(g_savedir + "Settings/", False)
CreateDir(g_savedir + "Save/", False)
CreateDir(g_savedir + "Replays/", False)

g_engine_int161 = Int(ReadSettingFloat(g_dataDir + "Settings/Settings.txt", "debug", 0.0, 2.0))
g_club_int07    = Int(ReadSettingFloat(g_dataDir + "Settings/Settings.txt", "fullnames", 0.0, 1.0))
g_misc_int62    = Int(ReadSettingFloat(g_dataDir + "Settings/Settings.txt", "nettimeout", 3.0, 99.0))
g_misc_int63    = Int(ReadSettingFloat(g_dataDir + "Settings/Settings.txt", "port", 0.0, 100000000.0))
g_misc_int64    = ReadSettingString(g_dataDir + "Settings/Settings.txt", "proxy")

g_screen_int20 = MilliSecs()
SeedRnd(g_screen_int20)
g_engine_int164 = JoyCount()

g_timestepMs = 25
g_profile = New TProfile
g_engine_int167 = g_timestepMs

' Driver selection identical to the normal tail. An earlier version forced
' GLMax2DDriver here "to be safe" and that was a mistake: it made the harness run
' on a different graphics driver from the real game, so failures it reported were
' not necessarily failures the player would see. A test rig that does not match
' the thing under test reports its own bugs.
' The one deliberate difference is WINDOWED, enforced at the SetUpGraphics call
' below rather than here -- an unattended fullscreen mode switch leaves the
' desktop at 800x600 if the run dies, which is the display corruption already
' reported from the Options confirm button.
If ReadSettingFloat(g_dataDir + "Settings/Settings.txt", "opengl", 0.0, 1.0) = 1.0
	SetGraphicsDriver(GLMax2DDriver(), 2)
Else
	If D3D9Max2DDriver() = Null
		SetGraphicsDriver(D3D7Max2DDriver(), 2)
	EndIf
EndIf
If Not SetAudioDriver("OpenAL") Then SetAudioDriver("FreeAudio")

g_Object857 = AllocChannel()
g_musicchannel = AllocChannel()
g_Object859 = AllocChannel()
g_Object860 = LoadSoundChecked("GameMedia/Sounds/Cash.ogg", 0)
g_Object861 = LoadSoundChecked("GameMedia/Sounds/Achievement.ogg", 0)

SetMaskColor(8, 132, 107)
AutoMidHandle(False)

g_screen_achievements_int03 = g_dataDir + "GameMedia/Images/Icons/"
g_Object862 = LoadImageChecked(g_screen_achievements_int03 + "ArrowL.png", -1)
g_Object863 = LoadImageChecked(g_screen_achievements_int03 + "ArrowR.png", -1)
g_Object864 = LoadImageChecked(g_screen_achievements_int03 + "ArrowU.png", -1)
g_Object865 = LoadImageChecked(g_screen_achievements_int03 + "ArrowD_Red.png", -1)
g_Object866 = LoadImageChecked(g_screen_achievements_int03 + "Refresh.png", -1)
g_Object867 = LoadImageChecked(g_screen_achievements_int03 + "Cross.png", -1)
g_Object868 = LoadImageChecked(g_screen_achievements_int03 + "Tick.png", -1)
g_Object869 = LoadImageChecked(g_screen_achievements_int03 + "CrossSmall.png", -1)
g_Object870 = LoadImageChecked(g_screen_achievements_int03 + "TickSmall.png", -1)
g_Object871 = LoadImageChecked(g_screen_achievements_int03 + "Help.png", -1)
g_Object872 = LoadImageChecked("GameMedia\Images\Interface\MessageBg.png", -1)
g_Object873 = LoadImageChecked("GameMedia\Images\Interface\MessageLine.png", 1)

g_col_highlight = "00FF00"
g_col_key = "00FF00"
g_opt_refresh = TScreen_Options.RefreshButtons

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
