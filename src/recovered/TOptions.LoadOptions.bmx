' TOptions.LoadOptions
' VA 0x004e3aed   3308 bytes   mode=reloc   byte-identical vs NSS5.exe
' KIND=Function, SIG ()i, class-table slot 0x4c
' Verified 3308/3308 (reloc_masked=367) and re-verified with NSS5_NO_LEARN=1 -- nothing was
' masked by a helper name this probe taught the table (codegen-patterns 13.1).
'
' Every string literal below was read out of NSS5.exe with harness.read_string at the address
' the ORIGINAL pushes at the same code offset. The oracle masks a literal's ADDRESS, so the
' MATCH does not certify the text -- these were read, not guessed (codegen-patterns 13.2).
'
' The clamp bounds are FLOAT constants read off the pushes, not guesses. Note the key-binding
' range is +/-9999 (0x461C3C00 / 0xC61C3C00), NOT +/-10000 -- that one byte was the only
' error in the first draft, which was otherwise 3308/3308 in length.
' Other constants: 0x42C80000=100, 0x42C60000=99, 0x41F00000=30, 0x40E00000=7, 0x40800000=4,
' 0x40400000=3, 0x40000000=2, 0x3F800000=1, 0xBF800000=-1.
'
' g_opt_soundfx/g_opt_matchscale/g_opt_replayscale original data-section values
' are 100.0/1.0/2.0 (0x00C5D220/0x00C5D238/0x00C5D23C), read directly from NSS5.exe --
' same addresses as TWeather.UpdateRain's g_options_sfxvol, TEngine.SetUpReplay.bmx's
' g_engine_zoomdefault and TEngine.StartReplay.bmx's g_optionsFloat respectively. See
' codegen-patterns 21.1/21.3.
'
' ASSUMPTIONS (all Globals -- names are ours, types are load-bearing):
' ASSUMPTION 0x00C6E9A8 g_optroot:String     -- path prefix, concatenated with the .ini name
' ASSUMPTION 0x00C6EFEC g_joycount:Int       -- receives JoyCount()
' ASSUMPTION 0x00C5D1A8 g_opt_ctrlidx:Int    -- control-set index; TOptions.NewButtonUp agrees
' ASSUMPTION 0x00C5D1AC g_opt_scheme:Int
' ASSUMPTION 0x00C5D1B4 g_opt_ctrlup:Int[]   -- Int[] not Object[]: plain dword store, no GC
' ASSUMPTION 0x00C5D1BC g_opt_ctrldown:Int[]     write barrier. Index 0 = keyboard (+0x18),
' ASSUMPTION 0x00C5D1C4 g_opt_ctrlleft:Int[]     index 1 = joystick (+0x1C); BBArray data
' ASSUMPTION 0x00C5D1CC g_opt_ctrlright:Int[]    starts at +0x18 (codegen-patterns 11.1).
' ASSUMPTION 0x00C5D1D4 g_opt_ctrlbutton:Int[]
' ASSUMPTION 0x00C5D1DC g_opt_ctrlbutton2:Int[]
' ASSUMPTION 0x00C5D1E4 g_opt_ctrlbutton3:Int[]
' ASSUMPTION 0x00C5D1EC g_opt_ctrlbutton4:Int[]
' ASSUMPTION 0x00C5D1F4 g_opt_ctrlpause:Int[]
' ASSUMPTION 0x00C5D1FC g_opt_ctrlreplay:Int[]
' ASSUMPTION 0x00C5D220 g_opt_soundfx:Float   -- fstp dword, no bbFloatToInt
' ASSUMPTION 0x00C5D224 g_opt_music:Float  (same address as TScreen_Options.RefreshButtons'
'   g_opt_musicvol -- alias split; the original data-section value is 100.0, not 0,
'   both aliases now carry the initialiser, codegen-patterns 21.1/21.3)
' ASSUMPTION 0x00C5D228 g_opt_difficulty:Int
' ASSUMPTION 0x00C5D22C g_opt_radar:Int
' ASSUMPTION 0x00C5D230 g_opt_matchlength:Int
' ASSUMPTION 0x00C5D234 g_opt_matchspeed:Int
' ASSUMPTION 0x00C5D238 g_opt_matchscale:Float
' ASSUMPTION 0x00C5D23C g_opt_replayscale:Float
' ASSUMPTION 0x00C5D240 g_opt_displayinitials:Int
' ASSUMPTION 0x00C5D244 g_opt_screen:Int
' ASSUMPTION 0x00C5D248 g_opt_window:Int
' ASSUMPTION 0x00C5D24C g_opt_playercam:Int
' ASSUMPTION 0x00C5D250 g_opt_matchfx:Int
' ASSUMPTION 0x00C5D254 g_opt_distance:Int
' ASSUMPTION 0x00C5D258 g_opt_tooltips:Int
' ASSUMPTION 0x00C5D25C g_opt_lbfindme:Int
' ASSUMPTION 0x00C5D260 g_opt_lbmyage:Int
' ASSUMPTION 0x00C5D264 g_opt_lbmyclub:Int
' ASSUMPTION 0x00C5D268 g_opt_lbmynation:Int
' ASSUMPTION 0x00C5D26C g_opt_highlightball:Int
' ASSUMPTION 0x00C5D270 g_opt_showenergy:Int
' ASSUMPTION 0x00C5D274 g_opt_currency:Int
' ASSUMPTION 0x00C5D278 g_opt_reqfreekicks:Int
' ASSUMPTION 0x00C5D27C g_opt_reqcorners:Int
' ASSUMPTION 0x00C5D280 g_opt_lbview:Int
' ASSUMPTION 0x00C5D290 g_opt_language:String -- full retain/release traffic, so a reference
' ASSUMPTION 0x00C5D294 g_opt_fixkick:Int
' ASSUMPTION 0x00C5D298 g_opt_bossoff:Int
' ASSUMPTION 0x00C60500 g_gfxmodes:TList     -- called at slot 0x70 = TList.Count()i; the same
'   Global is walked with ObjectEnumerator in the already-verified TOptions.FindRes800600.
'
' ASSUMPTION: 0x00438290 is JoyCount (runtime_helpers.tsv, single witness).
' ASSUMPTION: 0x004BBFC1 ReadSettingFloat($,$,f,f)f, 0x004BC1D1 ReadSettingString($,$)$,
'   0x004BC88C UpdateAudio()i, 0x00505B91 LogLine($)i -- all recovered module Functions.
' 0x00C5D568 = TOptions+0x50 = FindRes800600, a sibling Function, so no Type. prefix.
'
' The two validation guards are short-circuit And chains (setne/movzx/cmp 0/je), NOT Selects:
' matchlength is forced to 3 unless it is 3/5/7, matchspeed to 30 unless it is 36/30/24.
' The j_Control read is genuinely dead -- its value is overwritten immediately by the
' joystick-presence If/Else. That is what the original does; it is not a transcription slip.

	Function LoadOptions:Int()
		'!Global g_optroot:String
		'!Global g_joycount:Int
		'!Global g_opt_ctrlidx:Int
		'!Global g_opt_scheme:Int
		'!Global g_opt_ctrlup:Int[]
		'!Global g_opt_ctrldown:Int[]
		'!Global g_opt_ctrlleft:Int[]
		'!Global g_opt_ctrlright:Int[]
		'!Global g_opt_ctrlbutton:Int[]
		'!Global g_opt_ctrlbutton2:Int[]
		'!Global g_opt_ctrlbutton3:Int[]
		'!Global g_opt_ctrlbutton4:Int[]
		'!Global g_opt_ctrlpause:Int[]
		'!Global g_opt_ctrlreplay:Int[]
		'!Global g_opt_soundfx:Float = 100.0
		'!Global g_opt_music:Float = 100.0
		'!Global g_opt_difficulty:Int
		'!Global g_opt_radar:Int
		'!Global g_opt_matchlength:Int
		'!Global g_opt_matchspeed:Int
		'!Global g_opt_matchscale:Float = 1.0
		'!Global g_opt_replayscale:Float = 2.0
		'!Global g_opt_displayinitials:Int
		'!Global g_opt_screen:Int
		'!Global g_opt_window:Int
		'!Global g_opt_playercam:Int
		'!Global g_opt_matchfx:Int
		'!Global g_opt_distance:Int
		'!Global g_opt_tooltips:Int
		'!Global g_opt_lbfindme:Int
		'!Global g_opt_lbmyage:Int
		'!Global g_opt_lbmyclub:Int
		'!Global g_opt_lbmynation:Int
		'!Global g_opt_highlightball:Int
		'!Global g_opt_showenergy:Int
		'!Global g_opt_currency:Int
		'!Global g_opt_reqfreekicks:Int
		'!Global g_opt_reqcorners:Int
		'!Global g_opt_lbview:Int
		'!Global g_opt_language:String
		'!Global g_opt_fixkick:Int
		'!Global g_opt_bossoff:Int
		'!Global g_gfxmodes:TList
		LogLine("LoadOptions")
		g_joycount = JoyCount()
		g_opt_ctrlidx = Int(ReadSettingFloat(g_optroot + "Settings/Options.ini", "j_Control", 0, 1))
		If g_joycount < 1
			g_opt_ctrlidx = 0
		Else
			g_opt_ctrlidx = 1
		End If
		g_opt_scheme = Int(ReadSettingFloat(g_optroot + "Settings/Options.ini", "j_Scheme", 0, 1))
		g_opt_ctrlup[0] = Int(ReadSettingFloat(g_optroot + "Settings/Options.ini", "k_Up", -9999, 9999))
		g_opt_ctrldown[0] = Int(ReadSettingFloat(g_optroot + "Settings/Options.ini", "k_Down", -9999, 9999))
		g_opt_ctrlleft[0] = Int(ReadSettingFloat(g_optroot + "Settings/Options.ini", "k_Left", -9999, 9999))
		g_opt_ctrlright[0] = Int(ReadSettingFloat(g_optroot + "Settings/Options.ini", "k_Right", -9999, 9999))
		g_opt_ctrlbutton[0] = Int(ReadSettingFloat(g_optroot + "Settings/Options.ini", "k_Button", -9999, 9999))
		g_opt_ctrlbutton2[0] = Int(ReadSettingFloat(g_optroot + "Settings/Options.ini", "k_Button2", -9999, 9999))
		g_opt_ctrlbutton3[0] = Int(ReadSettingFloat(g_optroot + "Settings/Options.ini", "k_Button3", -9999, 9999))
		g_opt_ctrlbutton4[0] = Int(ReadSettingFloat(g_optroot + "Settings/Options.ini", "k_Button4", -9999, 9999))
		g_opt_ctrlpause[0] = Int(ReadSettingFloat(g_optroot + "Settings/Options.ini", "k_Pause", -9999, 9999))
		g_opt_ctrlreplay[0] = Int(ReadSettingFloat(g_optroot + "Settings/Options.ini", "k_Replay", -9999, 9999))
		g_opt_ctrlup[1] = Int(ReadSettingFloat(g_optroot + "Settings/Options.ini", "j_Up", -9999, 9999))
		g_opt_ctrldown[1] = Int(ReadSettingFloat(g_optroot + "Settings/Options.ini", "j_Down", -9999, 9999))
		g_opt_ctrlleft[1] = Int(ReadSettingFloat(g_optroot + "Settings/Options.ini", "j_Left", -9999, 9999))
		g_opt_ctrlright[1] = Int(ReadSettingFloat(g_optroot + "Settings/Options.ini", "j_Right", -9999, 9999))
		g_opt_ctrlbutton[1] = Int(ReadSettingFloat(g_optroot + "Settings/Options.ini", "j_Button", -9999, 9999))
		g_opt_ctrlbutton2[1] = Int(ReadSettingFloat(g_optroot + "Settings/Options.ini", "j_Button2", -9999, 9999))
		g_opt_ctrlbutton3[1] = Int(ReadSettingFloat(g_optroot + "Settings/Options.ini", "j_Button3", -9999, 9999))
		g_opt_ctrlbutton4[1] = Int(ReadSettingFloat(g_optroot + "Settings/Options.ini", "j_Button4", -9999, 9999))
		g_opt_ctrlpause[1] = Int(ReadSettingFloat(g_optroot + "Settings/Options.ini", "j_Pause", -9999, 9999))
		g_opt_ctrlreplay[1] = Int(ReadSettingFloat(g_optroot + "Settings/Options.ini", "j_Replay", -9999, 9999))
		g_opt_soundfx = ReadSettingFloat(g_optroot + "Settings/Options.ini", "soundfx", 0, 100)
		g_opt_music = ReadSettingFloat(g_optroot + "Settings/Options.ini", "music", 0, 100)
		g_opt_difficulty = Int(ReadSettingFloat(g_optroot + "Settings/Options.ini", "difficulty", 1, 3))
		g_opt_radar = Int(ReadSettingFloat(g_optroot + "Settings/Options.ini", "radar", 0, 2))
		g_opt_matchlength = Int(ReadSettingFloat(g_optroot + "Settings/Options.ini", "matchlength", 3, 7))
		If g_opt_matchlength <> 3 And g_opt_matchlength <> 5 And g_opt_matchlength <> 7
			g_opt_matchlength = 3
		End If
		g_opt_matchscale = ReadSettingFloat(g_optroot + "Settings/Options.ini", "matchscale", 1, 3)
		g_opt_replayscale = ReadSettingFloat(g_optroot + "Settings/Options.ini", "replayscale", 1, 3)
		g_opt_displayinitials = Int(ReadSettingFloat(g_optroot + "Settings/Options.ini", "displayinitials", 0, 1))
		g_opt_screen = Int(ReadSettingFloat(g_optroot + "Settings/Options.ini", "screen", 0, 99))
		If g_opt_screen >= g_gfxmodes.Count()
			g_opt_screen = FindRes800600()
		End If
		g_opt_window = Int(ReadSettingFloat(g_optroot + "Settings/Options.ini", "window", 0, 1))
		g_opt_playercam = Int(ReadSettingFloat(g_optroot + "Settings/Options.ini", "playercam", 0, 3))
		g_opt_matchfx = Int(ReadSettingFloat(g_optroot + "Settings/Options.ini", "matchfx", 0, 1))
		g_opt_distance = Int(ReadSettingFloat(g_optroot + "Settings/Options.ini", "distance", 0, 1))
		g_opt_lbfindme = Int(ReadSettingFloat(g_optroot + "Settings/Options.ini", "leaderboardfindme", 0, 1))
		g_opt_lbmyage = Int(ReadSettingFloat(g_optroot + "Settings/Options.ini", "leaderboardmyage", 0, 1))
		g_opt_lbmyclub = Int(ReadSettingFloat(g_optroot + "Settings/Options.ini", "leaderboardmyclub", 0, 1))
		g_opt_lbmynation = Int(ReadSettingFloat(g_optroot + "Settings/Options.ini", "leaderboardmynation", 0, 1))
		g_opt_matchspeed = Int(ReadSettingFloat(g_optroot + "Settings/Options.ini", "matchspeed", 0, 30))
		If g_opt_matchspeed <> 36 And g_opt_matchspeed <> 30 And g_opt_matchspeed <> 24
			g_opt_matchspeed = 30
		End If
		g_opt_tooltips = Int(ReadSettingFloat(g_optroot + "Settings/Options.ini", "tooltips", 0, 1))
		g_opt_highlightball = Int(ReadSettingFloat(g_optroot + "Settings/Options.ini", "highlightball", 0, 1))
		g_opt_showenergy = Int(ReadSettingFloat(g_optroot + "Settings/Options.ini", "showenergy", 0, 1))
		g_opt_currency = Int(ReadSettingFloat(g_optroot + "Settings/Options.ini", "currency", 1, 3))
		g_opt_reqfreekicks = Int(ReadSettingFloat(g_optroot + "Settings/Options.ini", "requestfreekicks", -1, 1))
		g_opt_reqcorners = Int(ReadSettingFloat(g_optroot + "Settings/Options.ini", "requestcorners", -1, 1))
		g_opt_lbview = Int(ReadSettingFloat(g_optroot + "Settings/Options.ini", "leaderboardview", 1, 4))
		g_opt_language = ReadSettingString(g_optroot + "Settings/Options.ini", "language")
		g_opt_fixkick = Int(ReadSettingFloat(g_optroot + "Settings/Options.ini", "fixkick", 0, 1))
		g_opt_bossoff = Int(ReadSettingFloat(g_optroot + "Settings/Options.ini", "bossoff", 0, 1))
		UpdateAudio()
	End Function
