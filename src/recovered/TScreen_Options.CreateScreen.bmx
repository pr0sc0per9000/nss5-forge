' TScreen_Options.CreateScreen
' VA 0x0051DA51   8290 bytes   mode=reloc   byte-identical vs NSS5.exe
' KIND=Function, SIG ()i, class-table slot 0x30
' Re-verified with NSS5_NO_LEARN=1 (no in-run helper-name learning): still 8290/8290.
'
' ASSUMPTIONS -- GLOBAL NAMES ARE OURS; every declared type below is load-bearing
' because it selects the vtable slot for every call made through it.
'   0x00C63CE8 g_screen_options:TScreen      (construction site = TScreen.CreateScreen;
'                                             slot 0x40 = TScreen.AddGadget(:TGadget))
'   0x00C63CF0 g_options_flagbutton:TButton  (same VA + type as TScreen_Options.RefreshButtons)
'   0x00C63CF8 g_options_rescombo:TCombo     (same name/type as TScreen_Options.ComboRes;
'                                             slot 0x90 = TCombo.AddItem($,$,$,i))
'   0x00C63D0C g_options_inputbox:TInputBox  (same name/type as TScreen_Options.SetUpScreen)
'   0x00C60500 g_gfxmodes:TList              (same name/type as TOptions.FindRes800600;
'                                             slot 0x8C = TList.ObjectEnumerator)
'   0x00C6EFDC g_screenwidth:Int   0x00C6EFE0 g_screenheight:Int  (bare dword reads,
'                                             no refcount traffic -> Int)
'   0x00C6F254 g_img_back:TImage   0x00C6F274 g_img_play:TImage   (passed in
'                                             TButton.CreateButton's :TImage slot)
'   TMyGfxModes fields: w at +8, h at +0xC  ([ebx+8] / [ebx+0xc] in the EachIn body).
'
' TWO DISTINCT EMPTY STRINGS, resolved structurally (the oracle masks both addresses):
'   the original pushes a bcc data literal (refs=0x7FFFFFFF) at exactly 3 sites and the
'   C-runtime bbEmptyString in .data (refs=0x40000000) at exactly 73. Our "" emits the
'   literal and our Null-in-a-String-position emits bbEmptyString, and with the spelling
'   below the two site sets land on the SAME 3 / SAME 73 body offsets as the original.
'   So the 3 navpanel/back/tick text arguments are "" and every trailing tip argument
'   is Null. (Null is one spelling that produces bbEmptyString; an omitted optional
'   $ parameter is an untested alternative that would emit the same object.)
'
' All 21 float multipliers are 1.5; 0.8 is the panel alpha; 1.0 the button alpha.
' Every string literal was read out of NSS5.exe with harness.read_string.
'!Global g_screen_options:TScreen
'!Global g_options_flagbutton:TButton
'!Global g_options_rescombo:TCombo
'!Global g_options_inputbox:TInputBox
'!Global g_screenwidth:Int
'!Global g_screenheight:Int
'!Global g_img_back:TImage
'!Global g_img_play:TImage
'!Global g_gfxmodes:TList
		g_screen_options = TScreen.CreateScreen("options", Null, Null, Null)
		g_screen_options.AddGadget(TButton.CreateButton("pan_title", GetText("Options"), 0, 0, 800, 60, 0, 4, "FFFFFF", "FFFFFF", Null, Null, 1.0, 0, Null))
		g_screen_options.AddGadget(TPanel.CreatePanel("navpanel", "", 0, g_screenheight - 60, g_screenwidth, 60, "FFFFFF", "FFFFFF", 3, 1.0, 0, 0, 0))
		g_screen_options.AddGadget(TButton.CreateButton("back", "", 10, g_screenheight - 50, 120, 40, 1, 2, "FFFFFF", "FFFFFF", g_img_back, ButtonBack, 1.0, 1, Null))
		g_screen_options.AddGadget(TButton.CreateButton("tick", "", 670, g_screenheight - 50, 120, 40, 1, 2, "FFFFFF", "FFFFFF", g_img_play, ButtonTick, 1.0, 1, Null))
		g_screen_options.AddGadget(TPanel.CreatePanel("pan_options", GetText("Game Options"), 10, 70, 385, 30, "FFFFFF", "FFFFFF", 3, 0.8, 2, 430, 0))
		Local w:Int = 80
		Local h:Int = 28
		Local x1:Int = 20
		Local x2:Int = x1 + w + 40
		Local x3:Int = x2 + w
		Local x4:Int = x3 + w
		Local y:Int = 110
		Local gap:Int = 10
		g_screen_options.AddGadget(TButton.CreateButton("options_lang", GetText("settings_Language"), x1, y, w + 30, h, 0, 2, "888888", "FFFFFF", Null, Null, 1.0, 1, Null))
		g_options_flagbutton = TButton.CreateButton("options_langim", GetText("settings_ChangeLanguage"), x2, y, w * 3, h, 1, 2, "FFFFFF", "FFFFFF", Null, ButtonLanguage, 1.0, 1, Null)
		g_screen_options.AddGadget(g_options_flagbutton)
		y :+ h + gap
		g_screen_options.AddGadget(TButton.CreateButton("options_res", GetText("settings_Screen"), x1, y, w + 30, h, 0, 2, "888888", "FFFFFF", Null, Null, 1.0, 1, Null))
		g_screen_options.AddGadget(TButton.CreateButton("options_reswindow", GetText("settings_Window"), x3, y, w, h, 1, 2, "FFFFFF", "FFFFFF", Null, ButtonWindow, 1.0, 4, Null))
		g_screen_options.AddGadget(TButton.CreateButton("options_resfull", GetText("settings_FullScreen"), x4, y, w, h, 1, 2, "FFFFFF", "FFFFFF", Null, ButtonWindow, 1.0, 5, Null))
		g_options_rescombo = TCombo.CreateCombo("cmb_resolution", GetText("settings_tlaResolution"), x2, y, w - 10, h, 1, 2, "FFFFFF", "FFFFFF", 1.0, ComboRes, 1)
		For Local m:TMyGfxModes = EachIn g_gfxmodes
			Local s:String = m.w + " x " + m.h
			g_options_rescombo.AddItem(s, "BBBBBB", "FFFFFF", 0)
		Next
		g_screen_options.AddGadget(g_options_rescombo)
		y :+ h + gap
		g_screen_options.AddGadget(TButton.CreateButton("options_difficulty", GetText("Difficulty"), x1, y, w + 30, h, 0, 2, "888888", "FFFFFF", Null, Null, 1.0, 1, Null))
		g_screen_options.AddGadget(TButton.CreateButton("options_difficultyeasy", GetText("difficulty_Easy"), x2, y, w, h, 1, 2, "FFFFFF", "FFFFFF", Null, ButtonDifficulty, 1.0, 4, Null))
		g_screen_options.AddGadget(TButton.CreateButton("options_difficultynormal", GetText("difficulty_Normal"), x3, y, w, h, 1, 2, "FFFFFF", "FFFFFF", Null, ButtonDifficulty, 1.0, 0, Null))
		g_screen_options.AddGadget(TButton.CreateButton("options_difficultyhard", GetText("difficulty_Hard"), x4, y, w, h, 1, 2, "FFFFFF", "FFFFFF", Null, ButtonDifficulty, 1.0, 5, Null))
		y :+ h + gap
		g_screen_options.AddGadget(TButton.CreateButton("options_music", GetText("Music"), x1, y, w + 30, h, 0, 2, "888888", "FFFFFF", Null, Null, 1.0, 1, Null))
		g_screen_options.AddGadget(TButton.CreateButton("options_musicoff", GetText("volume_Off"), x2, y, w, h, 1, 2, "FFFFFF", "FFFFFF", Null, ButtonMusic, 1.0, 4, Null))
		g_screen_options.AddGadget(TButton.CreateButton("options_musiclow", GetText("volume_Low"), x3, y, w, h, 1, 2, "FFFFFF", "FFFFFF", Null, ButtonMusic, 1.0, 0, Null))
		g_screen_options.AddGadget(TButton.CreateButton("options_musichigh", GetText("volume_High"), x4, y, w, h, 1, 2, "FFFFFF", "FFFFFF", Null, ButtonMusic, 1.0, 5, Null))
		y :+ h + gap
		g_screen_options.AddGadget(TButton.CreateButton("options_sfx", GetText("Sound FX"), x1, y, w + 30, h, 0, 2, "888888", "FFFFFF", Null, Null, 1.0, 1, Null))
		g_screen_options.AddGadget(TButton.CreateButton("options_sfxoff", GetText("volume_Off"), x2, y, w, h, 1, 2, "FFFFFF", "FFFFFF", Null, ButtonSFX, 1.0, 4, Null))
		g_screen_options.AddGadget(TButton.CreateButton("options_sfxlow", GetText("volume_Low"), x3, y, w, h, 1, 2, "FFFFFF", "FFFFFF", Null, ButtonSFX, 1.0, 0, Null))
		g_screen_options.AddGadget(TButton.CreateButton("options_sfxhigh", GetText("volume_High"), x4, y, w, h, 1, 2, "FFFFFF", "FFFFFF", Null, ButtonSFX, 1.0, 5, Null))
		y :+ h + gap
		g_screen_options.AddGadget(TButton.CreateButton("options_tooltips", GetText("tt_ButtonTips"), x1, y, w + 30, h, 0, 2, "888888", "FFFFFF", Null, Null, 1.0, 1, Null))
		g_screen_options.AddGadget(TButton.CreateButton("options_tooltipson", GetText("On"), x2, y, Int(w * 1.5), h, 1, 2, "FFFFFF", "FFFFFF", Null, ButtonToolTips, 1.0, 4, Null))
		g_screen_options.AddGadget(TButton.CreateButton("options_tooltipsoff", GetText("Off"), Int(x2 + w * 1.5), y, Int(w * 1.5), h, 1, 2, "FFFFFF", "FFFFFF", Null, ButtonToolTips, 1.0, 5, Null))
		y :+ h + gap
		g_screen_options.AddGadget(TButton.CreateButton("options_dist", GetText("Distance"), x1, y, w + 30, h, 0, 2, "888888", "FFFFFF", Null, Null, 1.0, 1, Null))
		g_screen_options.AddGadget(TButton.CreateButton("options_distyards", GetText("Yards"), x2, y, Int(w * 1.5), h, 1, 2, "FFFFFF", "FFFFFF", Null, ButtonDistance, 1.0, 4, Null))
		g_screen_options.AddGadget(TButton.CreateButton("options_distmetres", GetText("Metres"), Int(x2 + w * 1.5), y, Int(w * 1.5), h, 1, 2, "FFFFFF", "FFFFFF", Null, ButtonDistance, 1.0, 5, Null))
		y :+ h + gap
		g_screen_options.AddGadget(TButton.CreateButton("options_currency", GetText("Currency"), x1, y, w + 30, h, 0, 2, "888888", "FFFFFF", Null, Null, 1.0, 1, Null))
		g_screen_options.AddGadget(TButton.CreateButton("options_currencyUSD", "$ USD", x2, y, w, h, 1, 2, "FFFFFF", "FFFFFF", Null, ButtonCurrency, 1.0, 4, Null))
		g_screen_options.AddGadget(TButton.CreateButton("options_currencyGBP", "£ GBP", x3, y, w, h, 1, 2, "FFFFFF", "FFFFFF", Null, ButtonCurrency, 1.0, 0, Null))
		g_screen_options.AddGadget(TButton.CreateButton("options_currencyEUR", "€ EUR", x4, y, w, h, 1, 2, "FFFFFF", "FFFFFF", Null, ButtonCurrency, 1.0, 5, Null))
		y :+ h + gap
		g_screen_options.AddGadget(TButton.CreateButton("options_savename", GetText("Save Name"), x1, y, w + 30, h, 0, 2, "888888", "FFFFFF", Null, Null, 1.0, 1, Null))
		g_options_inputbox = TInputBox.CreateInputBox("inp_SaveName", x2, y, w * 3, h, 1, 2, "FFFFFF", "000000", 16, 1.0, Null, 0, Null)
		g_screen_options.AddGadget(g_options_inputbox)
		gap = 5
		y = 110
		x1 = 415
		x2 = x1 + w + 40
		x3 = x2 + w
		x4 = x3 + w
		g_screen_options.AddGadget(TPanel.CreatePanel("pan_matchoptions", GetText("Match Options"), 405, 70, 385, 30, "FFFFFF", "FFFFFF", 3, 0.8, 2, 430, 0))
		g_screen_options.AddGadget(TButton.CreateButton("options_controls", GetText("Controls"), x1, y, w + 30, h, 0, 2, "888888", "FFFFFF", Null, Null, 1.0, 1, Null))
		g_screen_options.AddGadget(TButton.CreateButton("options_editcontrols", GetText("Edit Controls"), x2, y, w * 3, h, 1, 3, "FFFFFF", "FFFFFF", Null, TScreen_Controls.SetUpScreen, 1.0, 1, Null))
		y :+ h + gap
		g_screen_options.AddGadget(TButton.CreateButton("options_matchlength", GetText("Match Length"), x1, y, w + 30, h, 0, 2, "888888", "FFFFFF", Null, Null, 1.0, 1, Null))
		g_screen_options.AddGadget(TButton.CreateButton("options_matchlength3", "3 " + GetText("tla_Minutes"), x2, y, w, h, 1, 2, "FFFFFF", "FFFFFF", Null, ButtonMatchLength, 1.0, 4, Null))
		g_screen_options.AddGadget(TButton.CreateButton("options_matchlength5", "5 " + GetText("tla_Minutes"), x3, y, w, h, 1, 2, "FFFFFF", "FFFFFF", Null, ButtonMatchLength, 1.0, 0, Null))
		g_screen_options.AddGadget(TButton.CreateButton("options_matchlength7", "7 " + GetText("tla_Minutes"), x4, y, w, h, 1, 2, "FFFFFF", "FFFFFF", Null, ButtonMatchLength, 1.0, 5, Null))
		y :+ h + gap
		g_screen_options.AddGadget(TButton.CreateButton("options_matchspeed", GetText("Game Speed"), x1, y, w + 30, h, 0, 2, "888888", "FFFFFF", Null, Null, 1.0, 1, Null))
		g_screen_options.AddGadget(TButton.CreateButton("options_matchspeed1", GetText("gamespeed_Slow"), x2, y, w, h, 1, 2, "FFFFFF", "FFFFFF", Null, ButtonMatchSpeed, 1.0, 4, Null))
		g_screen_options.AddGadget(TButton.CreateButton("options_matchspeed2", GetText("gamespeed_Normal"), x3, y, w, h, 1, 2, "FFFFFF", "FFFFFF", Null, ButtonMatchSpeed, 1.0, 0, Null))
		g_screen_options.AddGadget(TButton.CreateButton("options_matchspeed3", GetText("gamespeed_Fast"), x4, y, w, h, 1, 2, "FFFFFF", "FFFFFF", Null, ButtonMatchSpeed, 1.0, 5, Null))
		y :+ h + gap
		g_screen_options.AddGadget(TButton.CreateButton("options_radar", GetText("Radar"), x1, y, w + 30, h, 0, 2, "888888", "FFFFFF", Null, Null, 1.0, 1, Null))
		g_screen_options.AddGadget(TButton.CreateButton("options_radaroff", GetText("Off"), x2, y, w, h, 1, 2, "FFFFFF", "FFFFFF", Null, ButtonRadar, 1.0, 4, Null))
		g_screen_options.AddGadget(TButton.CreateButton("options_radarsmall", GetText("Small"), x3, y, w, h, 1, 2, "FFFFFF", "FFFFFF", Null, ButtonRadar, 1.0, 0, Null))
		g_screen_options.AddGadget(TButton.CreateButton("options_radarlarge", GetText("Large"), x4, y, w, h, 1, 2, "FFFFFF", "FFFFFF", Null, ButtonRadar, 1.0, 5, Null))
		y :+ h + gap
		g_screen_options.AddGadget(TButton.CreateButton("options_cam", GetText("Player Cam"), x1, y, w + 30, h, 0, 2, "888888", "FFFFFF", Null, Null, 1.0, 1, Null))
		g_screen_options.AddGadget(TButton.CreateButton("options_camball", GetText("Ball"), x2, y, w, h, 1, 2, "FFFFFF", "FFFFFF", Null, ButtonCam, 1.0, 4, Null))
		g_screen_options.AddGadget(TButton.CreateButton("options_camplayer", GetText("Player"), x3, y, w, h, 1, 2, "FFFFFF", "FFFFFF", Null, ButtonCam, 1.0, 0, Null))
		g_screen_options.AddGadget(TButton.CreateButton("options_camzoom", GetText("Zoom"), x4, y, w, h, 1, 2, "FFFFFF", "FFFFFF", Null, ButtonCam, 1.0, 5, Null))
		y :+ h + gap
		g_screen_options.AddGadget(TButton.CreateButton("options_matchfx", GetText("Match FX"), x1, y, w + 30, h, 0, 2, "888888", "FFFFFF", Null, Null, 1.0, 1, Null))
		g_screen_options.AddGadget(TButton.CreateButton("options_matchfxon", GetText("On"), x2, y, Int(w * 1.5), h, 1, 2, "FFFFFF", "FFFFFF", Null, ButtonMatchFx, 1.0, 4, Null))
		g_screen_options.AddGadget(TButton.CreateButton("options_matchfxoff", GetText("Off"), Int(x2 + w * 1.5), y, Int(w * 1.5), h, 1, 2, "FFFFFF", "FFFFFF", Null, ButtonMatchFx, 1.0, 5, Null))
		y :+ h + gap
		g_screen_options.AddGadget(TButton.CreateButton("options_bossfx", GetText("settings_BossShouts"), x1, y, w + 30, h, 0, 2, "888888", "FFFFFF", Null, Null, 1.0, 1, Null))
		g_screen_options.AddGadget(TButton.CreateButton("options_bosson", GetText("On"), x2, y, Int(w * 1.5), h, 1, 2, "FFFFFF", "FFFFFF", Null, ButtonBossFx, 1.0, 4, Null))
		g_screen_options.AddGadget(TButton.CreateButton("options_bossoff", GetText("Off"), Int(x2 + w * 1.5), y, Int(w * 1.5), h, 1, 2, "FFFFFF", "FFFFFF", Null, ButtonBossFx, 1.0, 5, Null))
		y :+ h + gap
		g_screen_options.AddGadget(TButton.CreateButton("options_highlightball", GetText("Highlight Ball"), x1, y, w + 30, h, 0, 2, "888888", "FFFFFF", Null, Null, 1.0, 1, Null))
		g_screen_options.AddGadget(TButton.CreateButton("options_highlightballon", GetText("On"), x2, y, Int(w * 1.5), h, 1, 2, "FFFFFF", "FFFFFF", Null, ButtonHighlightBall, 1.0, 4, Null))
		g_screen_options.AddGadget(TButton.CreateButton("options_highlightballoff", GetText("Off"), Int(x2 + w * 1.5), y, Int(w * 1.5), h, 1, 2, "FFFFFF", "FFFFFF", Null, ButtonHighlightBall, 1.0, 5, Null))
		y :+ h + gap
		g_screen_options.AddGadget(TButton.CreateButton("options_showenergy", GetText("Show Energy"), x1, y, w + 30, h, 0, 2, "888888", "FFFFFF", Null, Null, 1.0, 1, Null))
		g_screen_options.AddGadget(TButton.CreateButton("options_showenergyon", GetText("On"), x2, y, Int(w * 1.5), h, 1, 2, "FFFFFF", "FFFFFF", Null, ButtonShowEnergy, 1.0, 4, Null))
		g_screen_options.AddGadget(TButton.CreateButton("options_showenergyoff", GetText("Off"), Int(x2 + w * 1.5), y, Int(w * 1.5), h, 1, 2, "FFFFFF", "FFFFFF", Null, ButtonShowEnergy, 1.0, 5, Null))
		y :+ h + gap
		g_screen_options.AddGadget(TButton.CreateButton("options_fixkick", GetText("Lock Kicking Direction"), x1, y, w + 30, h, 0, 2, "888888", "FFFFFF", Null, Null, 1.0, 1, Null))
		g_screen_options.AddGadget(TButton.CreateButton("options_fixkickon", GetText("On"), x2, y, Int(w * 1.5), h, 1, 2, "FFFFFF", "FFFFFF", Null, ButtonFixKick, 1.0, 4, Null))
		g_screen_options.AddGadget(TButton.CreateButton("options_fixkickoff", GetText("Off"), Int(x2 + w * 1.5), y, Int(w * 1.5), h, 1, 2, "FFFFFF", "FFFFFF", Null, ButtonFixKick, 1.0, 5, Null))
		y :+ h + gap
		g_screen_options.AddGadget(TButton.CreateButton("options_reqfreekicks", GetText("request_Freekicks"), x1, y, w + 30, h, 0, 2, "888888", "FFFFFF", Null, Null, 1.0, 1, Null))
		g_screen_options.AddGadget(TButton.CreateButton("options_reqfreekicksalways", GetText("request_Always"), x2, y, w, h, 1, 2, "FFFFFF", "FFFFFF", Null, ButtonFreekicks, 1.0, 4, Null))
		g_screen_options.AddGadget(TButton.CreateButton("options_reqfreekickssometimes", GetText("request_Sometimes"), x3, y, w, h, 1, 2, "FFFFFF", "FFFFFF", Null, ButtonFreekicks, 1.0, 0, Null))
		g_screen_options.AddGadget(TButton.CreateButton("options_reqfreekicksnever", GetText("request_Never"), x4, y, w, h, 1, 2, "FFFFFF", "FFFFFF", Null, ButtonFreekicks, 1.0, 5, Null))
		y :+ h + gap
		g_screen_options.AddGadget(TButton.CreateButton("options_reqcorners", GetText("request_Corners"), x1, y, w + 30, h, 0, 2, "888888", "FFFFFF", Null, Null, 1.0, 1, Null))
		g_screen_options.AddGadget(TButton.CreateButton("options_reqcornersalways", GetText("request_Always"), x2, y, w, h, 1, 2, "FFFFFF", "FFFFFF", Null, ButtonCorners, 1.0, 4, Null))
		g_screen_options.AddGadget(TButton.CreateButton("options_reqcornerssometimes", GetText("request_Sometimes"), x3, y, w, h, 1, 2, "FFFFFF", "FFFFFF", Null, ButtonCorners, 1.0, 0, Null))
		g_screen_options.AddGadget(TButton.CreateButton("options_reqcornersnever", GetText("request_Never"), x4, y, w, h, 1, 2, "FFFFFF", "FFFFFF", Null, ButtonCorners, 1.0, 5, Null))
