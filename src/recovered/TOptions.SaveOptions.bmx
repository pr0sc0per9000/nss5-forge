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
' ASSUMPTION 0x00C5D25C g_opt_lbfindme:Int
' ASSUMPTION 0x00C5D260 g_opt_lbmyage:Int
' ASSUMPTION 0x00C5D264 g_opt_lbmyclub:Int
' ASSUMPTION 0x00C5D268 g_opt_lbmynation:Int
' ASSUMPTION 0x00C5D234 g_opt_matchspeed:Int
' ASSUMPTION 0x00C5D258 g_opt_tooltips:Int
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
' CORRECTION (comment only -- no statement changed, body re-verified byte-identical).
' The six ASSUMPTION lines from g_opt_lbfindme to g_opt_tooltips were off by one slot
' across a consecutive run: the run they name is 0x00C5D258/25C/260/264 for the four
' leaderboard flags with tooltips pushed out to 0x00C5D268. That is what you get by
' zipping the WriteLine order against the ADDRESSES IN ASCENDING ORDER: matchspeed sits
' out of sequence at 0x00C5D234, and skipping over it shifts every later name by a slot
' (the failure mode addr_oracle's ordered pairing is documented to have, and the reason
' its self-reported accuracy is 83.4%).
' PINNED FROM THE BINARY, not from order. Each WriteLine loads its Global and THEN pushes
' its `key=` literal, so the two are adjacent and the pairing is read off, not inferred
' (literal text via harness.read_string at the address the original pushes):
'   0x004E3881 push [0xc5d254] / 0x004E3890 push 0xC76BB0 'distance='
'   0x004E38A7 push [0xc5d25c] / 0x004E38B6 push 0xC76BD0 'leaderboardfindme='
'   0x004E38CD push [0xc5d260] / 0x004E38DC push 0xC76C00 'leaderboardmyage='
'   0x004E38F3 push [0xc5d264] / 0x004E3902 push 0xC76C30 'leaderboardmyclub='
'   0x004E3919 push [0xc5d268] / 0x004E3928 push 0xC76C60 'leaderboardmynation='
'   0x004E393F push [0xc5d234] / 0x004E394E push 0xC76C94 'matchspeed='
'   0x004E3965 push [0xc5d258] / 0x004E3974 push 0xC76CB8 'tooltips='
'   0x004E398B push [0xc5d26c] / 0x004E399A push 0xC76CD8 'highlightball='
' TOptions.LoadOptions agrees key-for-key -- it pushes the key first and stores the result
' after, giving 'leaderboardfindme' -> 0x004E4436 mov [0xc5d25c],eax, 'leaderboardmyage'
' -> 0x004E4471 [0xc5d260], 'leaderboardmyclub' -> 0x004E44AC [0xc5d264],
' 'leaderboardmynation' -> 0x004E44E7 [0xc5d268], 'matchspeed' -> 0x004E4522 [0xc5d234],
' 'tooltips' -> 0x004E45A0 [0xc5d258]. So SAVE AND LOAD NEVER DISAGREED IN THE BINARY;
' only this comment block did.
' NOTHING BEHAVIOURAL WAS WRONG, and the Options round-trip was never broken by this.
' A Global's identity in the assembled program is its NAME: both functions spell each key
' with the same name, so each key is one variable end to end. The bad addresses here never
' became a merge either -- build_alias_map.py refused all four edges they implied and they
' sit in extracted/global_alias_map_skipped.tsv:10-13 as `AMBIGUOUS: name maps to 2
' addresses`. Had they been applied, g_opt_lbfindme/lbmyage/lbmyclub/lbmynation would have
' collapsed into ONE variable and all four leaderboard flags would share a value.
' What the bad addresses DID cost: global_address_map.tsv:1528-1531 report those four names
' AMBIGUOUS instead of pinning them, and 0x00C5D258 needed the hand row at
' global_alias_overrides.tsv:270 to reach g_opt_tooltips. Cross-check on 0x00C5D258: a dword
' search of the whole `code` section finds it in TScreen.Draw, TScreen.DoHelp,
' TGadget.UpdateToolTip, TScreen_Options.RefreshButtons (+3300/+3357) and
' TScreen_Options.ButtonToolTips (+68/+80, the two `= 1` / `= 0` stores) -- every one of
' them the tooltips flag, none of them a leaderboard flag. 0x00C5D25C/260/264/268 are
' touched by these two functions and by nothing else in the executable.
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
