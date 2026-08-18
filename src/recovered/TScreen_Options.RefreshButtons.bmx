' TScreen_Options.RefreshButtons
' VA 0x0051FC07   4272 bytes   mode=reloc   byte-identical vs NSS5.exe
' KIND=Function, SIG ()i, class-table slot 0x38
' Re-verified with NSS5_NO_LEARN=1 (no in-run helper-name learning): still 4272/4272.
'
' ASSUMPTIONS -- GLOBAL NAMES ARE OURS; every declared type below is load-bearing.
'   0x00C63CF4 g_flagimage:TImage           (holds LoadImageChecked/ResizeImage result)
'   0x00C63CF0 g_options_flagbutton:TButton (globals_final: construction site; slots 0x90
'                                            SetIcon and 0x70 SetAlph are TButtons own)
'   0x00C63CEC g_options_prevscreen:String  (same name/type as TScreen_Options.SetUpScreen)
'   0x00C61700 g_activescreen:TScreen       (same name/type as TScreen_Options.SetUpScreen;
'                                            .gadgetlist is TScreen field +0x0C :TList)
'   0x00C5D220 g_opt_sfxvol:Float           0x00C5D224 g_opt_musicvol:Float
'       (g_opt_musicvol is the same address as TOptions.SaveOptions/LoadOptions' g_opt_music
'        -- alias split. The original value is 100.0, and both aliases carry it.)
'   0x00C5D228 g_opt_difficulty:Int         0x00C5D22C g_opt_radar:Int
'   0x00C5D230 g_opt_matchlength:Int        0x00C5D234 g_opt_matchspeed:Int
'   0x00C5D248 g_opt_windowed:Int           0x00C5D24C g_opt_cam:Int
'   0x00C5D250 g_opt_matchfx:Int            0x00C5D254 g_opt_dist:Int
'   0x00C5D258 g_opt_tooltips:Int           0x00C5D26C g_opt_hlball:Int
'   0x00C5D270 g_opt_showenergy:Int         0x00C5D274 g_opt_currency:Int
'   0x00C5D278 g_opt_reqfreekicks:Int       0x00C5D27C g_opt_reqcorners:Int
'   0x00C5D294 g_opt_fixkick:Int            0x00C5D298 g_opt_bossfx:Int
'   0x00C6E91C g_col_highlight:String       (the selected-item colour; pushed as SetColours
'                                            first argument, so String, not Int)
'
' NOTES
'   * The 46-way dispatch is a Select with no Default (section 10.2): the original emits
'     all 46 _bbStringCompare tests back to back at 0x0051FD5F-0x00520185, every je
'     targeting a body past the last compare, then a jmp to the loop bottom for no match.
'   * The whole 46-case chain uses ONE subject load (mov ebx,[esi+0xC]) -- another Select
'     tell; an If/ElseIf chain would reload b.name before each compare.
'   * The float cases compare against 0.0 / 50.0 / 100.0 (read from 0x00C80598, 0x00C8059C,
'     0x00C805A0, 0x00C805A4).
'   * ResizeImage is 0x005064A2, recovered and verified 75/75; without it
'     the E8 at 0x0051FC9B is unnameable on the original side and the body sits at
'     first_diff=149 with every other byte already correct.
'   * All string literals were read out of NSS5.exe with harness.read_string; the oracle
'     masks their addresses and cannot certify their contents.
'!Global g_flagimage:TImage
'!Global g_options_flagbutton:TButton
'!Global g_options_prevscreen:String
'!Global g_activescreen:TScreen
'!Global g_opt_sfxvol:Float = 100.0
'!Global g_opt_musicvol:Float = 100.0
'!Global g_opt_difficulty:Int
'!Global g_opt_radar:Int
'!Global g_opt_matchlength:Int
'!Global g_opt_matchspeed:Int
'!Global g_opt_windowed:Int
'!Global g_opt_cam:Int
'!Global g_opt_matchfx:Int
'!Global g_opt_dist:Int
'!Global g_opt_tooltips:Int
'!Global g_opt_hlball:Int
'!Global g_opt_showenergy:Int
'!Global g_opt_currency:Int
'!Global g_opt_reqfreekicks:Int
'!Global g_opt_reqcorners:Int
'!Global g_opt_fixkick:Int
'!Global g_opt_bossfx:Int
'!Global g_col_highlight:String
g_flagimage = LoadImageChecked("GameMedia/Images/Nations/NationIm_" + Int(GetText("Tag_NationId")) + ".png", -1)
If g_flagimage <> Null
	TNation.ButtonizeFlag(g_flagimage, 0)
	g_flagimage = ResizeImage(g_flagimage, 36, 24)
	g_options_flagbutton.SetIcon(g_flagimage)
EndIf
g_options_flagbutton.SetAlph(1.0)
If g_options_prevscreen <> "mainmenu" Then g_options_flagbutton.SetAlph(0.5)
For Local b:TButton = EachIn g_activescreen.gadgetlist
	Select b.name
	Case "options_difficultyeasy"
		b.SetColour("FFFFFF", "FFFFFF")
		If g_opt_difficulty = 1 Then b.SetColour(g_col_highlight, "FFFFFF")
	Case "options_difficultynormal"
		b.SetColour("FFFFFF", "FFFFFF")
		If g_opt_difficulty = 2 Then b.SetColour(g_col_highlight, "FFFFFF")
	Case "options_difficultyhard"
		b.SetColour("FFFFFF", "FFFFFF")
		If g_opt_difficulty = 3 Then b.SetColour(g_col_highlight, "FFFFFF")
	Case "options_radaroff"
		b.SetColour("FFFFFF", "FFFFFF")
		If g_opt_radar = 0 Then b.SetColour(g_col_highlight, "FFFFFF")
	Case "options_radarsmall"
		b.SetColour("FFFFFF", "FFFFFF")
		If g_opt_radar = 1 Then b.SetColour(g_col_highlight, "FFFFFF")
	Case "options_radarlarge"
		b.SetColour("FFFFFF", "FFFFFF")
		If g_opt_radar = 2 Then b.SetColour(g_col_highlight, "FFFFFF")
	Case "options_matchlength3"
		b.SetColour("FFFFFF", "FFFFFF")
		If g_opt_matchlength = 3 Then b.SetColour(g_col_highlight, "FFFFFF")
	Case "options_matchlength5"
		b.SetColour("FFFFFF", "FFFFFF")
		If g_opt_matchlength = 5 Then b.SetColour(g_col_highlight, "FFFFFF")
	Case "options_matchlength7"
		b.SetColour("FFFFFF", "FFFFFF")
		If g_opt_matchlength = 7 Then b.SetColour(g_col_highlight, "FFFFFF")
	Case "options_matchspeed1"
		b.SetColour("FFFFFF", "FFFFFF")
		If g_opt_matchspeed = 36 Then b.SetColour(g_col_highlight, "FFFFFF")
	Case "options_matchspeed2"
		b.SetColour("FFFFFF", "FFFFFF")
		If g_opt_matchspeed = 30 Then b.SetColour(g_col_highlight, "FFFFFF")
	Case "options_matchspeed3"
		b.SetColour("FFFFFF", "FFFFFF")
		If g_opt_matchspeed = 24 Then b.SetColour(g_col_highlight, "FFFFFF")
	Case "options_musicoff"
		b.SetColour("FFFFFF", "FFFFFF")
		If g_opt_musicvol = 0.0 Then b.SetColour(g_col_highlight, "FFFFFF")
	Case "options_musiclow"
		b.SetColour("FFFFFF", "FFFFFF")
		If g_opt_musicvol = 50.0 Then b.SetColour(g_col_highlight, "FFFFFF")
	Case "options_musichigh"
		b.SetColour("FFFFFF", "FFFFFF")
		If g_opt_musicvol = 100.0 Then b.SetColour(g_col_highlight, "FFFFFF")
	Case "options_sfxoff"
		b.SetColour("FFFFFF", "FFFFFF")
		If g_opt_sfxvol = 0.0 Then b.SetColour(g_col_highlight, "FFFFFF")
	Case "options_sfxlow"
		b.SetColour("FFFFFF", "FFFFFF")
		If g_opt_sfxvol = 50.0 Then b.SetColour(g_col_highlight, "FFFFFF")
	Case "options_sfxhigh"
		b.SetColour("FFFFFF", "FFFFFF")
		If g_opt_sfxvol = 100.0 Then b.SetColour(g_col_highlight, "FFFFFF")
	Case "options_reswindow"
		b.SetColour("FFFFFF", "FFFFFF")
		If g_opt_windowed = 1 Then b.SetColour(g_col_highlight, "FFFFFF")
	Case "options_resfull"
		b.SetColour("FFFFFF", "FFFFFF")
		If g_opt_windowed = 0 Then b.SetColour(g_col_highlight, "FFFFFF")
	Case "options_camball"
		b.SetColour("FFFFFF", "FFFFFF")
		If g_opt_cam = 0 Then b.SetColour(g_col_highlight, "FFFFFF")
	Case "options_camplayer"
		b.SetColour("FFFFFF", "FFFFFF")
		If g_opt_cam = 1 Then b.SetColour(g_col_highlight, "FFFFFF")
	Case "options_camzoom"
		b.SetColour("FFFFFF", "FFFFFF")
		If g_opt_cam = 2
			b.SetColour(g_col_highlight, "FFFFFF")
			b.SetText(GetText("zoom_Near"), "", -1, -1)
		EndIf
		If g_opt_cam = 3
			b.SetColour(g_col_highlight, "FFFFFF")
			b.SetText(GetText("zoom_Far"), "", -1, -1)
		EndIf
	Case "options_matchfxoff"
		b.SetColour("FFFFFF", "FFFFFF")
		If g_opt_matchfx = 0 Then b.SetColour(g_col_highlight, "FFFFFF")
	Case "options_matchfxon"
		b.SetColour("FFFFFF", "FFFFFF")
		If g_opt_matchfx = 1 Then b.SetColour(g_col_highlight, "FFFFFF")
	Case "options_bossoff"
		b.SetColour("FFFFFF", "FFFFFF")
		If g_opt_bossfx = 1 Then b.SetColour(g_col_highlight, "FFFFFF")
	Case "options_bosson"
		b.SetColour("FFFFFF", "FFFFFF")
		If g_opt_bossfx = 0 Then b.SetColour(g_col_highlight, "FFFFFF")
	Case "options_distyards"
		b.SetColour("FFFFFF", "FFFFFF")
		If g_opt_dist = 0 Then b.SetColour(g_col_highlight, "FFFFFF")
	Case "options_distmetres"
		b.SetColour("FFFFFF", "FFFFFF")
		If g_opt_dist = 1 Then b.SetColour(g_col_highlight, "FFFFFF")
	Case "options_tooltipsoff"
		b.SetColour("FFFFFF", "FFFFFF")
		If g_opt_tooltips = 0 Then b.SetColour(g_col_highlight, "FFFFFF")
	Case "options_tooltipson"
		b.SetColour("FFFFFF", "FFFFFF")
		If g_opt_tooltips = 1 Then b.SetColour(g_col_highlight, "FFFFFF")
	Case "options_highlightballoff"
		b.SetColour("FFFFFF", "FFFFFF")
		If g_opt_hlball = 0 Then b.SetColour(g_col_highlight, "FFFFFF")
	Case "options_highlightballon"
		b.SetColour("FFFFFF", "FFFFFF")
		If g_opt_hlball = 1 Then b.SetColour(g_col_highlight, "FFFFFF")
	Case "options_showenergyoff"
		b.SetColour("FFFFFF", "FFFFFF")
		If g_opt_showenergy = 0 Then b.SetColour(g_col_highlight, "FFFFFF")
	Case "options_showenergyon"
		b.SetColour("FFFFFF", "FFFFFF")
		If g_opt_showenergy = 1 Then b.SetColour(g_col_highlight, "FFFFFF")
	Case "options_currencyUSD"
		b.SetColour("FFFFFF", "FFFFFF")
		If g_opt_currency = 1 Then b.SetColour(g_col_highlight, "FFFFFF")
	Case "options_currencyGBP"
		b.SetColour("FFFFFF", "FFFFFF")
		If g_opt_currency = 2 Then b.SetColour(g_col_highlight, "FFFFFF")
	Case "options_currencyEUR"
		b.SetColour("FFFFFF", "FFFFFF")
		If g_opt_currency = 3 Then b.SetColour(g_col_highlight, "FFFFFF")
	Case "options_reqfreekicksalways"
		b.SetColour("FFFFFF", "FFFFFF")
		If g_opt_reqfreekicks = 1 Then b.SetColour(g_col_highlight, "FFFFFF")
	Case "options_reqfreekickssometimes"
		b.SetColour("FFFFFF", "FFFFFF")
		If g_opt_reqfreekicks = 0 Then b.SetColour(g_col_highlight, "FFFFFF")
	Case "options_reqfreekicksnever"
		b.SetColour("FFFFFF", "FFFFFF")
		If g_opt_reqfreekicks = -1 Then b.SetColour(g_col_highlight, "FFFFFF")
	Case "options_reqcornersalways"
		b.SetColour("FFFFFF", "FFFFFF")
		If g_opt_reqcorners = 1 Then b.SetColour(g_col_highlight, "FFFFFF")
	Case "options_reqcornerssometimes"
		b.SetColour("FFFFFF", "FFFFFF")
		If g_opt_reqcorners = 0 Then b.SetColour(g_col_highlight, "FFFFFF")
	Case "options_reqcornersnever"
		b.SetColour("FFFFFF", "FFFFFF")
		If g_opt_reqcorners = -1 Then b.SetColour(g_col_highlight, "FFFFFF")
	Case "options_fixkickon"
		b.SetColour("FFFFFF", "FFFFFF")
		If g_opt_fixkick = 1 Then b.SetColour(g_col_highlight, "FFFFFF")
	Case "options_fixkickoff"
		b.SetColour("FFFFFF", "FFFFFF")
		If g_opt_fixkick = 0 Then b.SetColour(g_col_highlight, "FFFFFF")
	End Select
Next
