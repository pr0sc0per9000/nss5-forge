' TOptions.SaveOptions
' VA 0x004E32E1   2060 bytes   mode=reloc   byte-identical vs NSS5.exe
' KIND=Function, SIG ()i, class-table slot 0x48
' Verified 2060/2060 (reloc_masked=259) and re-verified with NSS5_NO_LEARN=1 -- nothing was
' masked by a helper name this probe taught the table (codegen-patterns 13.1).
'
' The Save/Load twin (codegen-patterns 16.4): TOptions.LoadOptions (already verified)
' supplied every Global's name and type and the field order below is identical to it,
' key-for-key. TOptions.WriteNewOptionsIni (already verified) supplied the WriteFile /
' WriteLine / CloseStream shape and confirmed the 21-byte "If Not s Then Return 0" guard
' form (codegen-patterns 10.3).
'
' Every string literal below was read out of NSS5.exe with harness.read_string at the
' address the ORIGINAL pushes at the same code offset -- the oracle masks a literal's
' ADDRESS, not its content, so a MATCH never certifies text on its own (codegen-patterns
' 13.2). All 49 "key=" prefixes plus "SaveOptions" and "Settings/Options.ini" were read this
' way, and every one matches LoadOptions' key spelling exactly.
'
' g_opt_soundfx/g_opt_matchscale/g_opt_replayscale original data-section values
' are 100.0/1.0/2.0 (0x00C5D220/0x00C5D238/0x00C5D23C), read directly from NSS5.exe. See
' codegen-patterns 21.1/21.3.
'
' matchscale / replayscale route through FormatDecimals(f,i)$ (already-recovered module
' Function at 0x0050640c, src/recovered_module/FormatDecimals.bmx) with a literal places
' argument of 2 -- NOT a plain Int() coercion like every other numeric field. soundfx and
' music DO go through Int() (fld/fstp qword/call _bbFloatToInt at 0x005B9690, the same
' Double-widening shape codegen-patterns 3a documents for Int(x)).
'
' g_optroot here is the SAME Global as g_userpath in TOptions.WriteNewOptionsIni
' (0x00C6E9A8) -- named to match its LoadOptions twin instead, since the two files
' disagree and neither name is recoverable (module Globals carry no debug record).
'
' ASSUMPTIONS (all Globals -- names are ours, types are load-bearing; carried over
' unchanged from TOptions.LoadOptions, which established each one):
' ASSUMPTION 0x00C6E9A8 g_optroot:String
' ASSUMPTION 0x00C5D1A8 g_opt_ctrlidx:Int
' ASSUMPTION 0x00C5D1AC g_opt_scheme:Int
' ASSUMPTION 0x00C5D1B4 g_opt_ctrlup:Int[]       -- Int[] not Object[]: plain dword loads,
' ASSUMPTION 0x00C5D1BC g_opt_ctrldown:Int[]        no refcount traffic. Index 0 = keyboard
' ASSUMPTION 0x00C5D1C4 g_opt_ctrlleft:Int[]         (+0x18), index 1 = joystick (+0x1C);
' ASSUMPTION 0x00C5D1CC g_opt_ctrlright:Int[]        BBArray data starts at +0x18
' ASSUMPTION 0x00C5D1D4 g_opt_ctrlbutton:Int[]       (codegen-patterns 11.1).
' ASSUMPTION 0x00C5D1DC g_opt_ctrlbutton2:Int[]
' ASSUMPTION 0x00C5D1E4 g_opt_ctrlbutton3:Int[]
' ASSUMPTION 0x00C5D1EC g_opt_ctrlbutton4:Int[]
' ASSUMPTION 0x00C5D1F4 g_opt_ctrlpause:Int[]
' ASSUMPTION 0x00C5D1FC g_opt_ctrlreplay:Int[]
' ASSUMPTION 0x00C5D220 g_opt_soundfx:Float
' ASSUMPTION 0x00C5D224 g_opt_music:Float  (same address as TScreen_Options.RefreshButtons'
'   g_opt_musicvol -- alias split; the original data-section value is 100.0, not 0,
'   both aliases now carry the initialiser, codegen-patterns 21.1/21.3)
' ASSUMPTION 0x00C5D228 g_opt_difficulty:Int
' ASSUMPTION 0x00C5D22C g_opt_radar:Int
' ASSUMPTION 0x00C5D230 g_opt_matchlength:Int
' ASSUMPTION 0x00C5D238 g_opt_matchscale:Float
' ASSUMPTION 0x00C5D23C g_opt_replayscale:Float
' ASSUMPTION 0x00C5D240 g_opt_displayinitials:Int
' ASSUMPTION 0x00C5D244 g_opt_screen:Int
' ASSUMPTION 0x00C5D248 g_opt_window:Int
' ASSUMPTION 0x00C5D24C g_opt_playercam:Int
' ASSUMPTION 0x00C5D250 g_opt_matchfx:Int
' ASSUMPTION 0x00C5D254 g_opt_distance:Int
' ASSUMPTION 0x00C5D258 g_opt_lbfindme:Int
' ASSUMPTION 0x00C5D25C g_opt_lbmyage:Int
' ASSUMPTION 0x00C5D260 g_opt_lbmyclub:Int
' ASSUMPTION 0x00C5D264 g_opt_lbmynation:Int
' ASSUMPTION 0x00C5D234 g_opt_matchspeed:Int
' ASSUMPTION 0x00C5D268 g_opt_tooltips:Int
' ASSUMPTION 0x00C5D26C g_opt_highlightball:Int
' ASSUMPTION 0x00C5D270 g_opt_showenergy:Int
' ASSUMPTION 0x00C5D274 g_opt_currency:Int
' ASSUMPTION 0x00C5D278 g_opt_reqfreekicks:Int
' ASSUMPTION 0x00C5D27C g_opt_reqcorners:Int
' ASSUMPTION 0x00C5D280 g_opt_lbview:Int
' ASSUMPTION 0x00C5D290 g_opt_language:String    -- full retain/release traffic, so a
'   reference, matching LoadOptions.
' ASSUMPTION 0x00C5D294 g_opt_fixkick:Int
' ASSUMPTION 0x00C5D298 g_opt_bossoff:Int
'
' ASSUMPTION: 0x004A7AC0 is _bbStringFromInt (runtime_helpers.tsv). 0x004A7C20 is
'   _bbStringConcat. 0x005B65FC resolved as _brl_filesystem_WriteFile, 0x005B8307 as
'   _brl_stream_WriteLine and 0x005B812B as _brl_stream_CloseStream (all alias sets in
'   brl_functions.tsv; TStream is the only reading that fits, matching WriteNewOptionsIni).
'   0x005B9690 is _bbFloatToInt (bcc's emission for Int(floatExpr), codegen-patterns 3a).
'   0x00505B91 is LogLine, 0x0050640C is FormatDecimals -- both recovered module Functions.
	Function SaveOptions:Int()
		'!Global g_optroot:String
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
		'!Global g_opt_matchscale:Float = 1.0
		'!Global g_opt_replayscale:Float = 2.0
		'!Global g_opt_displayinitials:Int
		'!Global g_opt_screen:Int
		'!Global g_opt_window:Int
		'!Global g_opt_playercam:Int
		'!Global g_opt_matchfx:Int
		'!Global g_opt_distance:Int
		'!Global g_opt_lbfindme:Int
		'!Global g_opt_lbmyage:Int
		'!Global g_opt_lbmyclub:Int
		'!Global g_opt_lbmynation:Int
		'!Global g_opt_matchspeed:Int
		'!Global g_opt_tooltips:Int
		'!Global g_opt_highlightball:Int
		'!Global g_opt_showenergy:Int
		'!Global g_opt_currency:Int
		'!Global g_opt_reqfreekicks:Int
		'!Global g_opt_reqcorners:Int
		'!Global g_opt_lbview:Int
		'!Global g_opt_language:String
		'!Global g_opt_fixkick:Int
		'!Global g_opt_bossoff:Int
		LogLine("SaveOptions")
		Local s:TStream = WriteFile(g_optroot + "Settings/Options.ini")
		If Not s Then Return 0
		WriteLine(s, "j_Control=" + g_opt_ctrlidx)
		WriteLine(s, "j_Scheme=" + g_opt_scheme)
		WriteLine(s, "k_Up=" + g_opt_ctrlup[0])
		WriteLine(s, "k_Down=" + g_opt_ctrldown[0])
		WriteLine(s, "k_Left=" + g_opt_ctrlleft[0])
		WriteLine(s, "k_Right=" + g_opt_ctrlright[0])
		WriteLine(s, "k_Button=" + g_opt_ctrlbutton[0])
		WriteLine(s, "k_Button2=" + g_opt_ctrlbutton2[0])
		WriteLine(s, "k_Button3=" + g_opt_ctrlbutton3[0])
		WriteLine(s, "k_Button4=" + g_opt_ctrlbutton4[0])
		WriteLine(s, "k_Pause=" + g_opt_ctrlpause[0])
		WriteLine(s, "k_Replay=" + g_opt_ctrlreplay[0])
		WriteLine(s, "j_Up=" + g_opt_ctrlup[1])
		WriteLine(s, "j_Down=" + g_opt_ctrldown[1])
		WriteLine(s, "j_Left=" + g_opt_ctrlleft[1])
		WriteLine(s, "j_Right=" + g_opt_ctrlright[1])
		WriteLine(s, "j_Button=" + g_opt_ctrlbutton[1])
		WriteLine(s, "j_Button2=" + g_opt_ctrlbutton2[1])
		WriteLine(s, "j_Button3=" + g_opt_ctrlbutton3[1])
		WriteLine(s, "j_Button4=" + g_opt_ctrlbutton4[1])
		WriteLine(s, "j_Pause=" + g_opt_ctrlpause[1])
		WriteLine(s, "j_Replay=" + g_opt_ctrlreplay[1])
		WriteLine(s, "soundfx=" + Int(g_opt_soundfx))
		WriteLine(s, "music=" + Int(g_opt_music))
		WriteLine(s, "difficulty=" + g_opt_difficulty)
		WriteLine(s, "radar=" + g_opt_radar)
		WriteLine(s, "matchlength=" + g_opt_matchlength)
		WriteLine(s, "matchscale=" + FormatDecimals(g_opt_matchscale, 2))
		WriteLine(s, "replayscale=" + FormatDecimals(g_opt_replayscale, 2))
		WriteLine(s, "displayinitials=" + g_opt_displayinitials)
		WriteLine(s, "screen=" + g_opt_screen)
		WriteLine(s, "window=" + g_opt_window)
		WriteLine(s, "playercam=" + g_opt_playercam)
		WriteLine(s, "matchfx=" + g_opt_matchfx)
		WriteLine(s, "distance=" + g_opt_distance)
		WriteLine(s, "leaderboardfindme=" + g_opt_lbfindme)
		WriteLine(s, "leaderboardmyage=" + g_opt_lbmyage)
		WriteLine(s, "leaderboardmyclub=" + g_opt_lbmyclub)
		WriteLine(s, "leaderboardmynation=" + g_opt_lbmynation)
		WriteLine(s, "matchspeed=" + g_opt_matchspeed)
		WriteLine(s, "tooltips=" + g_opt_tooltips)
		WriteLine(s, "highlightball=" + g_opt_highlightball)
		WriteLine(s, "showenergy=" + g_opt_showenergy)
		WriteLine(s, "currency=" + g_opt_currency)
		WriteLine(s, "requestfreekicks=" + g_opt_reqfreekicks)
		WriteLine(s, "requestcorners=" + g_opt_reqcorners)
		WriteLine(s, "leaderboardview=" + g_opt_lbview)
		WriteLine(s, "language=" + g_opt_language)
		WriteLine(s, "fixkick=" + g_opt_fixkick)
		WriteLine(s, "bossoff=" + g_opt_bossoff)
		CloseStream(s)
	End Function
