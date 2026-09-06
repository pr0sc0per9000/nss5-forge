' TScreen_Controls.CreateScreen
' VA 0x0052187E   6091 bytes   mode=reloc   byte-identical vs NSS5.exe
' KIND=Function (static, no implicit Self), SIG ()i, class-table slot 0x30
' (6091/6091, original length from Ghidra's inventory, reloc_masked=526)
'
' ASSUMPTIONS
'   Global names are ours; module Globals carry no debug record.  Declared types below.
'     0x00C640C8 g_img_joy1:TImage      0x00C640CC g_img_joy2:TImage
'     0x00C640D0 g_img_keys:TImage      0x00C640C4 g_screen_controls:TScreen
'     0x00C640D4 g_pan_simple:TPanel    0x00C640D8 g_pan_advanced:TPanel
'     0x00C6EFDC g_screenwidth:Int      0x00C6EFE0 g_screenheight:Int
'     0x00C6F254 g_img_back:TImage      0x00C6F274 g_img_play:TImage
'       0x00C6F274 is the corpus-wide accept/proceed icon: ten other bodies name it
'       g_img_play, including TScreen_Options.CreateScreen, which builds the identically
'       named "tick" button on the sibling screen with it. Spelled g_img_tick here it
'       collided with TScreen_Stable.RefreshRunners' name for 0x00C6DEAC, so neither
'       spelling could be merged onto a writer and this button's icon stayed Null.
'     0x00C6E91C g_col_key:String  -- globals_final.tsv calls this Int; it is pushed in a
'                `$` parameter slot of CreateButton/CreateLabel, so per codegen-patterns
'                11.2 the code wins over the table.  It is the highlight colour used for
'                the three kick rows and every control-name label.
'   Class-table slots resolved via class_tables.tsv / vtable_map.tsv:
'     0x00C61C64 = TScreen+0x38  CreateScreen($,:TImage,()i,()i):TScreen
'     0x00C623CC = TButton+0x88  CreateButton($,$,i,i,i,i,i,i,$,$,:TImage,()i,f,i,$):TButton
'     0x00C63294 = TPanel+0x88   CreatePanel($,$,i,i,i,i,$,$,i,f,i,i,i):TPanel
'     0x00C634C0 = TLabel+0x88   CreateLabel($,$,i,i,i,i,i,$,$,f,i,i,i,i,:TImage,i,i,i,i,$,f):TLabel
'     slot 0x40 on TScreen = TScreen.AddGadget(:TGadget)i
'     slot 0x74 on TPanel  = TGadget.AddChild(:TGadget)i   (inherited)
'     0x00C641FC/0x00C64200/0x00C64208/0x00C6420C/0x00C64210 = TScreen_Controls slots
'       0x38/0x3c/0x44/0x48/0x4c = ButtonSimple/ButtonAdvanced/ButtonBack/ButtonTick/
'       ButtonControls -- same Type, so they are written as bare names.
'     0x00C5D56C..0x00C5D590 = TOptions slots 0x54..0x78 = NewButtonUp/Down/Left/Right/
'       Kick/Kick2/Kick3/Pause/Replay.
'   FUN_004C5549 = GetText (ONE argument -- Ghidra merges its single push with the
'     following CreateButton/CreateLabel pushes).  FUN_004BC372 = LoadImageChecked.
'     FUN_004A7410 = _brl_retro_Lower = Lower().  FUN_005B95D0 (the empty function) in an
'     ()i argument slot is source-level Null.
'   Both 0x00C5D284 and 0x005C7D40 are zero-length BBStrings, i.e. "" -- read out of the
'     exe, not assumed.  All other literals via harness.read_string.
'
' NOTES ON SHAPE (each of these is worth several hundred bytes)
'   * The opening image test is `If Not g_img_joy1` (setne/movzx/cmp/jne -- pattern 10.3),
'     not `If g_img_joy1 = Null`.
'   * The six Locals are REUSED, not redeclared.  After the keyboard rows the same w/h/x1/y
'     slots are reassigned for the scheme buttons and again for each panel.  Because the
'     original's frame is 0xC8 bytes, x1/x2/gap live below -128 and every access is a
'     disp32 encoding; a version that declares fresh Locals gets a 0x5C frame, disp8
'     accesses, and comes out 499 bytes short.
'   * Second-column geometry is always derived, never literal: `x1 + w`, `w * 2 - 20`,
'     `x1 + 100`, `w - 100`, `h * 2`.  bcc does no constant folding across variables, so
'     writing the folded literal changes the bytes.
'   * The label rows advance y by `h + 10` between blocks and by `h` inside a
'     two-column pair; the Advanced panel uses `h + 10` throughout.
'!Global g_img_joy1:TImage
'!Global g_img_joy2:TImage
'!Global g_img_keys:TImage
'!Global g_screen_controls:TScreen
'!Global g_pan_simple:TPanel
'!Global g_pan_advanced:TPanel
'!Global g_screenwidth:Int
'!Global g_screenheight:Int
'!Global g_col_key:String
'!Global g_img_back:TImage
'!Global g_img_play:TImage
' CASE DIRECTION CORRECTED 2026-08-22: 9 call sites -> .ToUpper().
' extracted/runtime_helpers.tsv named 0x004A7410 `_brl_retro_Lower` and 0x004A74E0
' `_brl_retro_Upper`. Both were wrong and neither address is a brl.retro wrapper:
' 0x004A7410 is `_bbStringToUpper` and 0x004A74E0 is `_bbStringToLower`. NSS5.exe's
' own 21-byte retro wrappers at 0x0059C8FD (Lower) and 0x0059C912 (Upper) CALL those
' two addresses, and a wrapper cannot be the function it calls. The wrong row masked
' by name, so this body certified with the case conversion running backwards. Full
' derivation and the discriminating 3x4 matrix: docs/reference/codegen-patterns.md
' 15.6. Re-verified under NSS5_NO_LEARN=1 on worker trees 380 and 380b.
	Function CreateScreen()
		If Not g_img_joy1
			g_img_joy1 = LoadImageChecked("GameMedia/Images/Interface/Joystick.png", -1)
			g_img_joy2 = LoadImageChecked("GameMedia/Images/Interface/Joystick2.png", -1)
			g_img_keys = LoadImageChecked("GameMedia/Images/Interface/Keys.png", -1)
		EndIf
		g_screen_controls = TScreen.CreateScreen("controls", Null, Null, Null)
		g_screen_controls.AddGadget(TButton.CreateButton("pan_title", GetText("Edit Controls"), 0, 0, 800, 60, 0, 4, "EEEEEE", "FFFFFF", Null, Null, 1.0, 0, ""))
		g_screen_controls.AddGadget(TPanel.CreatePanel("navpanel", "", 0, g_screenheight - 60, g_screenwidth, 60, "FFFFFF", "FFFFFF", 3, 1.0, 0, 0, 0))
		g_screen_controls.AddGadget(TButton.CreateButton("back", "", 10, g_screenheight - 50, 120, 40, 1, 2, "FFFFFF", "FFFFFF", g_img_back, ButtonBack, 1.0, 1, ""))
		g_screen_controls.AddGadget(TButton.CreateButton("tick", "", 670, g_screenheight - 50, 120, 40, 1, 2, "FFFFFF", "FFFFFF", g_img_play, ButtonTick, 1.0, 1, ""))
		g_screen_controls.AddGadget(TPanel.CreatePanel("pan_Controls", "", 10, 70, 290, 460, "FFFFFF", "FFFFFF", 3, 0.8, 1, 0, 0))
		Local w:Int = 130
		Local h:Int = 30
		Local x1:Int = 20
		Local x2:Int = 160
		Local y:Int = 80
		Local gap:Int = 10
		g_screen_controls.AddGadget(TButton.CreateButton("lbl_scheme", GetText("Controls"), x1, y, w, h * 2, 0, 2, "888888", "FFFFFF", Null, Null, 1.0, 1, ""))
		g_screen_controls.AddGadget(TButton.CreateButton("btn_joy", "", x2, y, w, h * 2, 1, 2, "FFFFFF", "FFFFFF", Null, ButtonControls, 1.0, 1, ""))
		y :+ h * 2 + gap
		g_screen_controls.AddGadget(TButton.CreateButton("lbl_up", GetText("Up"), x1, y, w, h, 0, 2, "888888", "FFFFFF", Null, Null, 1.0, 1, ""))
		g_screen_controls.AddGadget(TButton.CreateButton("btn_up", "", x2, y, w, h, 1, 2, "FFFFFF", "FFFFFF", Null, TOptions.NewButtonUp, 1.0, 1, ""))
		y :+ h + gap
		g_screen_controls.AddGadget(TButton.CreateButton("lbl_down", GetText("Down"), x1, y, w, h, 0, 2, "888888", "FFFFFF", Null, Null, 1.0, 1, ""))
		g_screen_controls.AddGadget(TButton.CreateButton("btn_down", "", x2, y, w, h, 1, 2, "FFFFFF", "FFFFFF", Null, TOptions.NewButtonDown, 1.0, 1, ""))
		y :+ h + gap
		g_screen_controls.AddGadget(TButton.CreateButton("lbl_left", GetText("Left"), x1, y, w, h, 0, 2, "888888", "FFFFFF", Null, Null, 1.0, 1, ""))
		g_screen_controls.AddGadget(TButton.CreateButton("btn_left", "", x2, y, w, h, 1, 2, "FFFFFF", "FFFFFF", Null, TOptions.NewButtonLeft, 1.0, 1, ""))
		y :+ h + gap
		g_screen_controls.AddGadget(TButton.CreateButton("lbl_right", GetText("Right"), x1, y, w, h, 0, 2, "888888", "FFFFFF", Null, Null, 1.0, 1, ""))
		g_screen_controls.AddGadget(TButton.CreateButton("btn_right", "", x2, y, w, h, 1, 2, "FFFFFF", "FFFFFF", Null, TOptions.NewButtonRight, 1.0, 1, ""))
		y :+ h + gap
		g_screen_controls.AddGadget(TButton.CreateButton("lbl_kick", GetText("Kick"), x1, y, w, h, 0, 2, g_col_key, "FFFFFF", Null, Null, 1.0, 1, ""))
		g_screen_controls.AddGadget(TButton.CreateButton("btn_kick", "", x2, y, w, h, 1, 2, "FFFFFF", "FFFFFF", Null, TOptions.NewButtonKick, 1.0, 1, ""))
		y :+ h + gap
		g_screen_controls.AddGadget(TButton.CreateButton("lbl_kick2", GetText("Kick"), x1, y, w, h, 0, 2, g_col_key, "FFFFFF", Null, Null, 1.0, 1, ""))
		g_screen_controls.AddGadget(TButton.CreateButton("btn_kick2", "", x2, y, w, h, 1, 2, "FFFFFF", "FFFFFF", Null, TOptions.NewButtonKick2, 1.0, 1, ""))
		y :+ h + gap
		g_screen_controls.AddGadget(TButton.CreateButton("lbl_kick3", GetText("Kick"), x1, y, w, h, 0, 2, g_col_key, "FFFFFF", Null, Null, 1.0, 1, ""))
		g_screen_controls.AddGadget(TButton.CreateButton("btn_kick3", "", x2, y, w, h, 1, 2, "FFFFFF", "FFFFFF", Null, TOptions.NewButtonKick3, 1.0, 1, ""))
		y :+ h + gap
		g_screen_controls.AddGadget(TButton.CreateButton("lbl_pause", GetText("Pause"), x1, y, w, h, 0, 2, "888888", "FFFFFF", Null, Null, 1.0, 1, ""))
		g_screen_controls.AddGadget(TButton.CreateButton("btn_pause", "", x2, y, w, h, 1, 2, "FFFFFF", "FFFFFF", Null, TOptions.NewButtonPause, 1.0, 1, ""))
		y :+ h + gap
		g_screen_controls.AddGadget(TButton.CreateButton("lbl_replay", GetText("Replay"), x1, y, w, h, 0, 2, "888888", "FFFFFF", Null, Null, 1.0, 1, ""))
		g_screen_controls.AddGadget(TButton.CreateButton("btn_replay", "", x2, y, w, h, 1, 2, "FFFFFF", "FFFFFF", Null, TOptions.NewButtonReplay, 1.0, 1, ""))
		y = 70
		x1 = 310
		w = 240
		g_screen_controls.AddGadget(TButton.CreateButton("btn_scheme1", GetText("Simple"), x1, y, w, h * 2, 1, 3, "FFFFFF", "FFFFFF", Null, ButtonSimple, 1.0, 4, ""))
		g_screen_controls.AddGadget(TButton.CreateButton("btn_scheme2", GetText("Advanced"), x1 + w, y, w, h * 2, 1, 3, "FFFFFF", "FFFFFF", Null, ButtonAdvanced, 1.0, 5, ""))
		y = 140
		h = 37
		g_pan_simple = TPanel.CreatePanel("pan_Simple", GetText("Simple Controls"), x1, y, w * 2, 32, "FFFFFF", "FFFFFF", 3, 0.8, 1, 358, 0)
		x1 :+ 10
		y :+ 40
		w = w * 2 - 20
		g_pan_simple.AddChild(TLabel.CreateLabel("simple1", GetText("simple_Description"), x1, y, w, h, 2, "AAAAAA", "FFFFFF", 1.0, 1, 0, 1, 1, Null, 1, 0, 0, 0, "", 0))
		y :+ h + 10
		g_pan_simple.AddChild(TLabel.CreateLabel("simple2", GetText("controls_Shoot").ToUpper(), x1, y, 100, h, 2, g_col_key, "FFFFFF", 1.0, 6, 0, 1, 1, Null, 1, 0, 0, 0, "", 0))
		g_pan_simple.AddChild(TLabel.CreateLabel("simple3", GetText("simple_ShootDesc"), x1 + 100, y, w - 100, h, 2, "EEEEEE", "FFFFFF", 1.0, 7, 0, 1, 1, Null, 1, 0, 0, 0, "", 0))
		y :+ h
		g_pan_simple.AddChild(TLabel.CreateLabel("simple4", GetText("simple_ShootTip"), x1, y, w, h, 2, "AAAAAA", "FFFFFF", 1.0, 3, 0, 1, 1, Null, 1, 0, 0, 0, "", 0))
		y :+ h + 10
		g_pan_simple.AddChild(TLabel.CreateLabel("simple5", GetText("controls_Pass").ToUpper(), x1, y, 100, h, 2, g_col_key, "FFFFFF", 1.0, 6, 0, 1, 1, Null, 1, 0, 0, 0, "", 0))
		g_pan_simple.AddChild(TLabel.CreateLabel("simple6", GetText("simple_PassDesc"), x1 + 100, y, w - 100, h, 2, "EEEEEE", "FFFFFF", 1.0, 7, 0, 1, 1, Null, 1, 0, 0, 0, "", 0))
		y :+ h
		g_pan_simple.AddChild(TLabel.CreateLabel("simple7", GetText("simple_PassTip"), x1, y, w, h, 2, "AAAAAA", "FFFFFF", 1.0, 3, 0, 1, 1, Null, 1, 0, 0, 0, "", 0))
		y :+ h + 10
		g_pan_simple.AddChild(TLabel.CreateLabel("simple8", GetText("controls_SlideTackle").ToUpper(), x1, y, 100, h, 2, g_col_key, "FFFFFF", 1.0, 4, 0, 1, 1, Null, 1, 0, 0, 0, "", 0))
		g_pan_simple.AddChild(TLabel.CreateLabel("simple9", GetText("simple_SlideDesc"), x1 + 100, y, w - 100, h, 2, "EEEEEE", "FFFFFF", 1.0, 5, 0, 1, 1, Null, 1, 0, 0, 0, "", 0))
		y :+ h + 10
		g_pan_simple.AddChild(TLabel.CreateLabel("simple10", GetText("controls_Call").ToUpper(), x1, y, 100, h, 2, g_col_key, "FFFFFF", 1.0, 6, 0, 1, 1, Null, 1, 0, 0, 0, "", 0))
		g_pan_simple.AddChild(TLabel.CreateLabel("simple11", GetText("simple_CallDesc"), x1 + 100, y, w - 100, h, 2, "EEEEEE", "FFFFFF", 1.0, 7, 0, 1, 1, Null, 1, 0, 0, 0, "", 0))
		y :+ h
		g_pan_simple.AddChild(TLabel.CreateLabel("simple12", GetText("simple_CallTip"), x1, y, w, h, 2, "AAAAAA", "FFFFFF", 1.0, 3, 0, 1, 1, Null, 1, 0, 0, 0, "", 0))
		g_screen_controls.AddGadget(g_pan_simple)
		x1 = 310
		y = 140
		w = 240
		h = 37
		g_pan_advanced = TPanel.CreatePanel("pan_Advanced", GetText("Advanced Controls"), x1, y, w * 2, 32, "FFFFFF", "FFFFFF", 3, 0.8, 1, 358, 0)
		x1 :+ 10
		y :+ 40
		w = w * 2 - 20
		g_pan_advanced.AddChild(TLabel.CreateLabel("advanced1", GetText("advanced_Description"), x1, y, w, h, 2, "AAAAAA", "FFFFFF", 1.0, 1, 0, 1, 1, Null, 1, 0, 0, 0, "", 0))
		y :+ h + 10
		g_pan_advanced.AddChild(TLabel.CreateLabel("advanced2", GetText("controls_Shoot").ToUpper(), x1, y, 100, h, 2, g_col_key, "FFFFFF", 1.0, 4, 0, 1, 1, Null, 1, 0, 0, 0, "", 0))
		g_pan_advanced.AddChild(TLabel.CreateLabel("advanced3", GetText("advanced_ShootDesc"), x1 + 100, y, w - 100, h, 2, "EEEEEE", "FFFFFF", 1.0, 5, 0, 1, 1, Null, 1, 0, 0, 0, "", 0))
		y :+ h + 10
		g_pan_advanced.AddChild(TLabel.CreateLabel("advanced4", GetText("controls_Pass").ToUpper(), x1, y, 100, h, 2, g_col_key, "FFFFFF", 1.0, 4, 0, 1, 1, Null, 1, 0, 0, 0, "", 0))
		g_pan_advanced.AddChild(TLabel.CreateLabel("advanced5", GetText("advanced_PassDesc"), x1 + 100, y, w - 100, h, 2, "EEEEEE", "FFFFFF", 1.0, 5, 0, 1, 1, Null, 1, 0, 0, 0, "", 0))
		y :+ h + 10
		g_pan_advanced.AddChild(TLabel.CreateLabel("advanced6", GetText("controls_Lob").ToUpper(), x1, y, 100, h, 2, g_col_key, "FFFFFF", 1.0, 4, 0, 1, 1, Null, 1, 0, 0, 0, "", 0))
		g_pan_advanced.AddChild(TLabel.CreateLabel("advanced7", GetText("advanced_LobDesc"), x1 + 100, y, w - 100, h, 2, "EEEEEE", "FFFFFF", 1.0, 5, 0, 1, 1, Null, 1, 0, 0, 0, "", 0))
		y :+ h + 10
		g_pan_advanced.AddChild(TLabel.CreateLabel("advanced8", GetText("controls_SlideTackle").ToUpper(), x1, y, 100, h, 2, g_col_key, "FFFFFF", 1.0, 4, 0, 1, 1, Null, 1, 0, 0, 0, "", 0))
		g_pan_advanced.AddChild(TLabel.CreateLabel("advanced9", GetText("advanced_SlideDesc"), x1 + 100, y, w - 100, h, 2, "EEEEEE", "FFFFFF", 1.0, 5, 0, 1, 1, Null, 1, 0, 0, 0, "", 0))
		y :+ h + 10
		g_pan_advanced.AddChild(TLabel.CreateLabel("advanced10", GetText("controls_Call").ToUpper(), x1, y, 100, h, 2, g_col_key, "FFFFFF", 1.0, 4, 0, 1, 1, Null, 1, 0, 0, 0, "", 0))
		g_pan_advanced.AddChild(TLabel.CreateLabel("advanced11", GetText("advanced_CallDesc"), x1 + 100, y, w - 100, h, 2, "EEEEEE", "FFFFFF", 1.0, 5, 0, 1, 1, Null, 1, 0, 0, 0, "", 0))
		y :+ h + 10
		g_pan_advanced.AddChild(TLabel.CreateLabel("advanced12", GetText("advanced_Tip"), x1, y, w, 56, 2, "AAAAAA", "FFFFFF", 1.0, 1, 0, 1, 1, Null, 1, 0, 0, 0, "", 0))
		g_screen_controls.AddGadget(g_pan_advanced)
	End Function
