' TScreen_MatchPaused.CreateScreen
' VA 0x0054A828   980 bytes   KIND=Function (static, no Self)   SIG ()i   class-table slot 0x30
' byte-identical vs NSS5.exe (980/980, original length from Ghidra's inventory, mode=reloc)
'
' Builds the in-match pause screen: title bar, help button, and a centred panel holding
' five stacked buttons (Continue/Replay/Formation/Options/SkipTime).
'
' Reconstructed from raw disassembly, not the Ghidra decompilation, which merges each
' call's argument pushes with the FOLLOWING call's (codegen-patterns.md CALL-annotation
' note). The five stacked buttons share one x, one w and one h, and a y that advances by
' h+10 each time -- confirmed directly against the original bytes:
'   - w starts at 300 (the panel's own width) and drops by 20 (:- 20) to become the
'     button width (280) for all five buttons -- ONE Local, reused, not two constants.
'   - h is a flat 50 throughout, INCLUDING inside the panel's own height formula
'     (h+10)*5+10 = 310 -- five stacked buttons of height h with 10px gaps, plus 10px
'     padding top/bottom. Reproduced as the formula, not the literal 310, because the
'     original computes it with the same two-operand imul/add sequence.
'   - x is centred via TWO separate "/2" divisions (g_screenwidth/2 and w/2, subtracted),
'     not one "(screenwidth-w)/2" -- byte-observably different from a single division.
'   - x and y each get a one-off "+10" bump right after the panel is created (x :+ 10,
'     y :+ 10), then y alone advances by h+10 per subsequent button; x and w never change
'     again.
' pan_title, btn_help, pan_paused, the Continue button and the Options button are
' AddGadget'd straight from the constructor call with no Local holding the widget itself
' (only the reloaded screen pointer needs a spill slot, since by then ebx already holds
' the y cursor); Replay/Tactics/SkipTime are each stored to their own Global first
' (matching the original's per-widget retain/release/store sequence) and AddGadget'd on
' the next line.
'
' Globals (names ours; addresses and TYPES are load-bearing):
'   0x00C6764C g_screen_matchpaused:TScreen   (construction site, this function)
'   0x00C6EFDC g_screenwidth:Int              shared Int Global (TScreen; "read-only int slot")
'   0x00C6F2EC g_icon_help:TImage             forced TImage by CreateButton's icon parameter
'                                              (globals_final.tsv: generic Object, low confidence,
'                                              shared with TScreen_GameMenu)
'   0x00C67650 g_screen_matchpaused_replay:TButton    (construction site, this function)
'   0x00C67654 g_screen_matchpaused_tactics:TButton   (construction site, this function)
'   0x00C67658 g_screen_matchpaused_skiptime:TButton  (construction site, this function)
'
' Class-table slots used: 0x00C61C64 TScreen+0x38 CreateScreen; 0x00C623CC TButton+0x88
'   CreateButton; 0x00C63294 TPanel+0x88 CreatePanel; TScreen+0x40 AddGadget (own slot,
'   NOT TGadget's inherited AddChild at +0x74); 0x00C61CDC TScreen+0xB0 ButtonHelp;
'   0x00C6778C/67790/67794/67798/6779C TScreen_MatchPaused+0x38/3C/40/44/48
'   ButtonContinue/ButtonReplay/ButtonTactics/ButtonOptions/ButtonSkipTime.
'
' Literals read from the exe with harness.read_string(): "matchpaused", "pan_title",
' "Paused", "btn_help", "pan_paused", "continue", "Continue", "replay", "Replay",
' "tactics", "Formation", "options", "Options", "skiptime", "Skip Time", "btn_SkipTime",
' "FFFFFF".
Function CreateScreen:Int()
	'!Global g_screen_matchpaused:TScreen
	'!Global g_screenwidth:Int
	'!Global g_icon_help:TImage
	'!Global g_screen_matchpaused_replay:TButton
	'!Global g_screen_matchpaused_tactics:TButton
	'!Global g_screen_matchpaused_skiptime:TButton

	g_screen_matchpaused = TScreen.CreateScreen("matchpaused", Null, Null, Null)
	g_screen_matchpaused.AddGadget(TPanel.CreatePanel("pan_title", GetText("Paused"), 0, 0, g_screenwidth, 60, "FFFFFF", "FFFFFF", 4, 1.0, 0, 0, 1))
	g_screen_matchpaused.AddGadget(TButton.CreateButton("btn_help", "", g_screenwidth - 50, 10, 40, 40, 1, 2, "FFFFFF", "FFFFFF", g_icon_help, TScreen.ButtonHelp, 1.0, 1, ""))

	Local w:Int = 300
	Local h:Int = 50
	Local x:Int = g_screenwidth / 2 - w / 2
	Local y:Int = 160
	g_screen_matchpaused.AddGadget(TPanel.CreatePanel("pan_paused", "", x, y, w, (h + 10) * 5 + 10, "FFFFFF", "FFFFFF", 3, 0.8, 1, 0, 0))
	x :+ 10
	y :+ 10
	w :- 20
	g_screen_matchpaused.AddGadget(TButton.CreateButton("continue", GetText("Continue"), x, y, w, h, 1, 4, "FFFFFF", "FFFFFF", Null, TScreen_MatchPaused.ButtonContinue, 1.0, 1, ""))
	y :+ h + 10
	g_screen_matchpaused_replay = TButton.CreateButton("replay", GetText("Replay"), x, y, w, h, 1, 4, "FFFFFF", "FFFFFF", Null, TScreen_MatchPaused.ButtonReplay, 1.0, 1, "")
	g_screen_matchpaused.AddGadget(g_screen_matchpaused_replay)
	y :+ h + 10
	g_screen_matchpaused_tactics = TButton.CreateButton("tactics", GetText("Formation"), x, y, w, h, 1, 4, "FFFFFF", "FFFFFF", Null, TScreen_MatchPaused.ButtonTactics, 1.0, 1, "")
	g_screen_matchpaused.AddGadget(g_screen_matchpaused_tactics)
	y :+ h + 10
	g_screen_matchpaused.AddGadget(TButton.CreateButton("options", GetText("Options"), x, y, w, h, 1, 4, "FFFFFF", "FFFFFF", Null, TScreen_MatchPaused.ButtonOptions, 1.0, 1, ""))
	y :+ h + 10
	g_screen_matchpaused_skiptime = TButton.CreateButton("skiptime", GetText("Skip Time"), x, y, w, h, 1, 4, "FFFFFF", "FFFFFF", Null, TScreen_MatchPaused.ButtonSkipTime, 1.0, 1, GetText("btn_SkipTime"))
	g_screen_matchpaused.AddGadget(g_screen_matchpaused_skiptime)
End Function
