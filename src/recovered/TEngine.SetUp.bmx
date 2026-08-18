' GLOBAL RENAMED (2026-08-15): g_mediapath -> g_iconpath in THIS file only.
' 0x00C6F170 is the GameMedia/Images/Icons/ root. The corpus uses the identifier
' g_mediapath for TWO different slots -- 0x00C6F170 here and in 8 other files, and
' 0x00C6E950 (the install root) in 9 OTHERS. One name, two slots, an exact 9/9 split,
' so no single value assigned to g_mediapath could ever be right at every call site:
' whichever way it went, half the asset paths resolved wrong and ~100 images failed to
' load. Per-body verification cannot catch this -- a Global reaches the compiled code
' only as an absolute address and the byte oracle masks those, so both spellings
' verify byte-perfectly. Renaming is byte-neutral; scripts/reverify.py confirms it.
' See scripts/unify_globals.py for the rest of this defect class.
' TEngine.SetUp
' VA 0x004cd9c3   3032 bytes   class-table slot 0x30   sig ()i   KIND=Function (static)
' byte-identical vs NSS5.exe (3032/3032, original length from Ghidra's inventory,
' mode=reloc, reloc_masked=325).  Re-verified with NSS5_NO_LEARN=1: still 3032/3032,
' so nothing here was masked by a name this probe taught the helper table.
'
' The match-engine boot routine: it loads the two match bitmap fonts, reads five
' Engine.ini settings, loads 18 overlay images, 8+5 crowd sounds, the radar sprite and
' the six scoreboard labels, then drives the loading bar through the SetUp of every
' other match subsystem.
'
' GLOBAL NAMES ARE OURS (module Globals carry no debug record).  Addresses are fact:
'   0x00C5B1C4 g_font_match_m:TBitmapFont     0x00C5B1C8 g_font_match_l:TBitmapFont
'     Both typed by construction site: `push 0x00C967C8; call bbObjectNew`, and
'     class_tables.tsv gives 0x00C967C8 = TBitmapFont.  Slot 0x44 on that Type is
'     Load(:Object,i) -- the `2` is the loader's second argument, not a string operand.
'   0x00C6E950 g_datapath:String   0x00C6F170 g_iconpath:String
'     (globals_final.tsv calls 0x00C6F170 an Int and is wrong -- it is pushed straight
'      into bbStringConcat here, the sixth independent contradiction of that row.)
'   0x00C5B2B4 g_replay_len:Int      0x00C5B20C g_game_second:Int
'   0x00C5B1EC g_limit_scroll_x:Int  0x00C5B1F0 g_limit_scroll_y1:Int
'   0x00C5B1F4 g_limit_scroll_y2:Int
'   Overlay images, in the original's load order (all :TImage, all LoadImageChecked):
'     0x00C5B2DC trophy  0x00C5B2E0 yellow  0x00C5B2E4 secondyellow  0x00C5B2E8 red
'     0x00C5B2EC injury  0x00C5B2F0 sub     0x00C5B2F4 subonup       0x00C5B2F8 subondown
'     0x00C5B2FC suboff  0x00C5B300 booze   0x00C5B304 unhappy       0x00C5B308 sick
'     0x00C5B30C tired   0x00C5B310 energyback  0x00C5B314 energybackred
'     0x00C5B318 energy  0x00C5B320 booze28     0x00C5B31C nrg28
'     0x00C5B2A4 radarplayer (LoadAnimImageChecked)
'   0x00C5B32C g_engine_labels:TLabel[]   0x00C5B330 g_lbl_time:TLabel
'   0x00C5B334 g_lbl_agg:TLabel
'   Sounds (:TSound):
'     0x00C5B34C whistle  0x00C5B350 whistlefinal  0x00C5B354 crowdambience
'     0x00C5B364 crowdgoal 0x00C5B368 crowdoh      0x00C5B36C crowdboo
'     0x00C5B370 crowdbooshort  0x00C5B374 crowdcheer
'     0x00C5B360 g_snd_chants:TSound[]   (indexed [i-1] for i = 1..8)
'
' Class-table slots resolved through class_tables.tsv / vtable_map.tsv:
'   0x00C634C0 = TLabel+0x88     CreateLabel ($,$,i,i,i,i,i,$,$,f,i,i,i,i,:TImage,i,i,i,i,$,f):TLabel
'   0x00C61CD8 = TScreen+0xAC    DoProgressBar (f,$,$,i)i
'   0x00C5D95C = TPitch+0x30     0x00C5BFEC = TFormation+0x30   0x00C5AECC = TBall+0x34
'   0x00C5F97C = TPlayer+0x30    0x00C601FC = TWeather+0x30     0x00C6AFBC = TParticle+0x34
'   0x00C5DB08 = TPitchMark+0x30 -- all SetUp ()i
' E8 targets: 0x004A8F20 bbObjectNew, 0x004A8590 GC free (inlined BBRELEASE, never written
'   in source), 0x004A7C20 bbStringConcat, 0x004A7AC0 bbStringFromInt, 0x005B9690
'   _bbFloatToInt (emitted implicitly for every Float->Int store), 0x005AE38D
'   MidHandleImage, and the recovered module Functions ReadSettingFloat (0x004BBFC1),
'   LoadImageChecked (0x004BC372), LoadSoundChecked (0x004BC564),
'   LoadAnimImageChecked (0x004BC664), GetText (0x004C5549).
'
' SHAPE NOTES -- each is byte-observable and was read off the disassembly, not assumed:
'   * The opening guard is an EARLY RETURN, not an enclosing If-block: `cmp [g],
'     bbNullObject / je body / mov eax,0 / jmp epilogue`.  The `je` skips the return, so
'     the tested condition is `<> Null` (the 12-byte compare form of section 10.3, not the
'     21-byte `If Not x` setne form).
'   * The sound and radar guards ARE the `If Not x` form (mov / cmp / setne / movzx /
'     cmp 0 / jne).  Both forms occur in this one function; they are not interchangeable.
'   * `sub esp,4` -- exactly ONE local dword slot, and it holds the 0.8 label scale at
'     [ebp-4] (`fld [0xC739A8] / fstp [ebp-4]`, emitted where the Local is declared).
'     The For counter lives in ebx with no stack slot.
'   * `cmp ebx,8 / jle` is `To 8`, not `Until 9`.
'   * The chant path is `"...CrowdChant" + i + ".ogg"`: bbStringFromInt, then
'     concat(prefix, digits), then concat(that, ".ogg") -- plain left-associative `+`,
'     NOT `:+` (section 16.1).
'   * Booze28 loads BEFORE NRG28 even though its Global sits at the HIGHER address
'     (0x00C5B320 vs 0x00C5B31C).  Reproduced, not tidied.
'   * Only the first thirteen overlay images get MidHandleImage; energy/energyback/
'     energybackred/booze28/nrg28 do not.
'   * String literals were recovered with harness.read_string -- the oracle masks a
'     literal's ADDRESS, so their contents are not certified by the MATCH.  0x00C5D284
'     and 0x005C7D40 are both zero-length BBStrings, i.e. "" (bcc picks a different empty
'     constant per argument slot; the source is "" either way).
'!Global g_font_match_m:TBitmapFont
'!Global g_font_match_l:TBitmapFont
'!Global g_datapath:String
'!Global g_iconpath:String
'!Global g_replay_len:Int
'!Global g_game_second:Int
'!Global g_limit_scroll_x:Int
'!Global g_limit_scroll_y1:Int
'!Global g_limit_scroll_y2:Int
'!Global g_img_trophy:TImage
'!Global g_img_yellow:TImage
'!Global g_img_secondyellow:TImage
'!Global g_img_red:TImage
'!Global g_img_injury:TImage
'!Global g_img_sub:TImage
'!Global g_img_subonup:TImage
'!Global g_img_subondown:TImage
'!Global g_img_suboff:TImage
'!Global g_img_booze:TImage
'!Global g_img_unhappy:TImage
'!Global g_img_sick:TImage
'!Global g_img_tired:TImage
'!Global g_img_energyback:TImage
'!Global g_img_energybackred:TImage
'!Global g_img_energy:TImage
'!Global g_img_nrg28:TImage
'!Global g_img_booze28:TImage
'!Global g_img_radarplayer:TImage
'!Global g_engine_labels:TLabel[]
'!Global g_lbl_time:TLabel
'!Global g_lbl_agg:TLabel
'!Global g_snd_whistle:TSound
'!Global g_snd_whistlefinal:TSound
'!Global g_snd_crowdambience:TSound
'!Global g_snd_chants:TSound[]
'!Global g_snd_crowdgoal:TSound
'!Global g_snd_crowdoh:TSound
'!Global g_snd_crowdboo:TSound
'!Global g_snd_crowdbooshort:TSound
'!Global g_snd_crowdcheer:TSound
	Function SetUp:Int()
		If g_font_match_m <> Null Then Return 0
		g_font_match_m = New TBitmapFont
		g_font_match_l = New TBitmapFont
		g_font_match_m.Load(g_datapath + "EngineMedia/Fonts/MatchFontM.fmf", 2)
		g_font_match_l.Load(g_datapath + "EngineMedia/Fonts/MatchFontL.fmf", 2)
		g_replay_len = ReadSettingFloat("incbin::Inc/Engine.ini", "replaylength", 0, 100000)
		g_game_second = ReadSettingFloat("incbin::Inc/Engine.ini", "gamesecond", 500, 100000)
		g_limit_scroll_x = ReadSettingFloat("incbin::Inc/Engine.ini", "limitscrollx", 0, 100)
		g_limit_scroll_y1 = ReadSettingFloat("incbin::Inc/Engine.ini", "limitscrolly1", 0, 100)
		g_limit_scroll_y2 = ReadSettingFloat("incbin::Inc/Engine.ini", "limitscrolly2", 0, 100)
		g_img_trophy = LoadImageChecked("EngineMedia/Match/Other/Trophy.png", -1)
		g_img_yellow = LoadImageChecked("EngineMedia/Match/Other/YellowCard.png", -1)
		g_img_secondyellow = LoadImageChecked("EngineMedia/Match/Other/SecondYellowCard.png", -1)
		g_img_red = LoadImageChecked("EngineMedia/Match/Other/RedCard.png", -1)
		g_img_injury = LoadImageChecked("EngineMedia/Match/Other/Injury.png", -1)
		g_img_sub = LoadImageChecked("EngineMedia/Match/Other/Substitution.png", -1)
		g_img_subonup = LoadImageChecked("EngineMedia/Match/Other/SubOnUp.png", -1)
		g_img_subondown = LoadImageChecked("EngineMedia/Match/Other/SubOnDown.png", -1)
		g_img_suboff = LoadImageChecked("EngineMedia/Match/Other/SubOff.png", -1)
		g_img_booze = LoadImageChecked("EngineMedia/Match/Other/BoozeFace.png", -1)
		g_img_unhappy = LoadImageChecked("EngineMedia/Match/Other/SadFace.png", -1)
		g_img_sick = LoadImageChecked("EngineMedia/Match/Other/SickFace.png", -1)
		g_img_tired = LoadImageChecked("EngineMedia/Match/Other/TiredFace.png", -1)
		g_img_energyback = LoadImageChecked("EngineMedia/Match/Other/EnergyBack.png", -1)
		g_img_energybackred = LoadImageChecked("EngineMedia/Match/Other/EnergyBackRed.png", -1)
		g_img_energy = LoadImageChecked("EngineMedia/Match/Other/Energy.png", -1)
		g_img_booze28 = LoadImageChecked(g_iconpath + "Booze28.png", -1)
		g_img_nrg28 = LoadImageChecked(g_iconpath + "NRG28.png", -1)
		MidHandleImage(g_img_trophy)
		MidHandleImage(g_img_yellow)
		MidHandleImage(g_img_secondyellow)
		MidHandleImage(g_img_red)
		MidHandleImage(g_img_injury)
		MidHandleImage(g_img_sub)
		MidHandleImage(g_img_subonup)
		MidHandleImage(g_img_subondown)
		MidHandleImage(g_img_suboff)
		MidHandleImage(g_img_booze)
		MidHandleImage(g_img_unhappy)
		MidHandleImage(g_img_sick)
		MidHandleImage(g_img_tired)
		If Not g_snd_whistle Then g_snd_whistle = LoadSoundChecked("EngineMedia/Match/Sounds/Whistle.ogg", 0)
		If Not g_snd_whistlefinal Then g_snd_whistlefinal = LoadSoundChecked("EngineMedia/Match/Sounds/WhistleFinal.ogg", 0)
		If Not g_snd_crowdambience Then g_snd_crowdambience = LoadSoundChecked("EngineMedia/Match/Sounds/CrowdAmbience.ogg", 1)
		For Local i:Int = 1 To 8
			If Not g_snd_chants[i - 1] Then g_snd_chants[i - 1] = LoadSoundChecked("EngineMedia/Match/Sounds/CrowdChant" + i + ".ogg", 0)
		Next
		If Not g_snd_crowdgoal Then g_snd_crowdgoal = LoadSoundChecked("EngineMedia/Match/Sounds/CrowdGoal.ogg", 0)
		If Not g_snd_crowdoh Then g_snd_crowdoh = LoadSoundChecked("EngineMedia/Match/Sounds/CrowdOh.ogg", 0)
		If Not g_snd_crowdboo Then g_snd_crowdboo = LoadSoundChecked("EngineMedia/Match/Sounds/CrowdBoo.ogg", 0)
		If Not g_snd_crowdbooshort Then g_snd_crowdbooshort = LoadSoundChecked("EngineMedia/Match/Sounds/CrowdBooShort.ogg", 0)
		If Not g_snd_crowdcheer Then g_snd_crowdcheer = LoadSoundChecked("EngineMedia/Match/Sounds/CrowdCheer.ogg", 0)
		If Not g_img_radarplayer Then g_img_radarplayer = LoadAnimImageChecked("EngineMedia/Match/Other/RadarPlayer.png", 8, 8, 0, 2, -1)
		MidHandleImage(g_img_radarplayer)
		Local sc:Float = 0.8
		g_engine_labels[0] = TLabel.CreateLabel("lbl_Scores0", "", 10, 10, 60, 26, 3, "FFFFFF", "FFFFFF", sc, 6, 1, 1, 1, Null, 1, 0, 0, 0, "", 0)
		g_engine_labels[1] = TLabel.CreateLabel("lbl_Scores1", "", 70, 10, 120, 26, 3, "c0c0c0", "FFFFFF", sc, 0, 1, 1, 1, Null, 1, 0, 0, 0, "", 0)
		g_engine_labels[2] = TLabel.CreateLabel("lbl_Scores2", "", 10, 36, 60, 26, 3, "FFFFFF", "FFFFFF", sc, 9, 1, 1, 1, Null, 1, 0, 0, 0, "", 0)
		g_engine_labels[3] = TLabel.CreateLabel("lbl_Scores3", "", 70, 36, 120, 26, 3, "c0c0c0", "FFFFFF", sc, 0, 1, 1, 1, Null, 1, 0, 0, 0, "", 0)
		g_lbl_time = TLabel.CreateLabel("lbl_Time", "", 190, 10, 70, 52, 3, "FFFFFF", "FFFFFF", sc, 5, 1, 1, 1, Null, 1, 0, 0, 0, "", 0)
		g_lbl_agg = TLabel.CreateLabel("lbl_Agg", "", 270, 10, 100, 52, 3, "888888", "FFFFFF", sc, 1, 1, 1, 1, g_img_trophy, 1, 0, 0, 0, "", 0)
		TScreen.DoProgressBar(10, GetText("Loading"), "00FF00", 0)
		TPitch.SetUp()
		TFormation.SetUp()
		TScreen.DoProgressBar(20, GetText("Loading"), "00FF00", 0)
		TBall.SetUp()
		TPlayer.SetUp()
		TScreen.DoProgressBar(40, GetText("Loading"), "00FF00", 0)
		TWeather.SetUp()
		TParticle.SetUp()
		TPitchMark.SetUp()
		TScreen.DoProgressBar(50, GetText("Loading"), "00FF00", 0)
	End Function
