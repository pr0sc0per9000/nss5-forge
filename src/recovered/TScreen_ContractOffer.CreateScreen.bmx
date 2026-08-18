' TScreen_ContractOffer.CreateScreen
' VA 0x005522A8   5396 bytes   mode=reloc   byte-identical vs NSS5.exe
' KIND=Function (static, NO implicit Self), SIG ()i, class-table slot 0x30
' 5396/5396, original length from Ghidra's inventory, reloc_masked=474.
' Re-verified with NSS5_NO_LEARN=1 (still MATCH, so no helper name was learned in-run).
'
' ASSUMPTIONS
'   Module Globals -- NAMES ARE OURS; the declared TYPE selects the vtable slot and is a
'   real claim.  Numbering follows globals_final.tsv's g_ObjectNNN and the naming already
'   used by TScreen_ContractOffer.SetUpScreen (g_co_screen / g_co_snd / g_co_btn5xx).
'     0x00C67B14 g_co_screen:TScreen        (construction site = TScreen.CreateScreen)
'     0x00C67B18 g_co_snd:TSound            (return type of LoadSoundChecked; SetUpScreen
'                                            passes it as arg1 of PlaySound)
'     0x00C67B1C g_co_pan536:TPanel         title panel
'     0x00C67B20 g_co_btn537:TButton        help button
'     0x00C67B24 g_co_pan538:TPanel         "Current Contract" panel
'     0x00C67B28/2C/30 g_co_lbl539/540/541:TLabel   team / nation / league (current)
'     0x00C67B34 g_co_prg542:TProgressBar   boss rating (current)
'     0x00C67B38 g_co_lbl543:TLabel  wage value      0x00C67B3C g_co_lbl544  expires value
'     0x00C67B40 g_co_lbl545  goal value             0x00C67B44 g_co_lbl546  assist value
'     0x00C67B48 g_co_lbl547  clean-sheet value
'     0x00C67B4C g_co_btn548:TButton  btn_Renew      0x00C67B50 g_co_btn549  reject
'     0x00C67B54 g_co_pan550:TPanel         "New Contract" panel
'     0x00C67B58/5C/60 g_co_lbl551/552/553:TLabel   team / nation / league (new)
'     0x00C67B64 g_co_prg554:TProgressBar   boss rating (new)
'     0x00C67B68/6C/70/74 g_co_lbl555/556/557/558   wage/goal/assist/clean values (new)
'     0x00C67B78 g_co_lbl559  signing-fee value      0x00C67B7C g_co_lbl560  length value
'     0x00C67B80 g_co_btn561:TButton  negotiate
'     0x00C6EFDC g_screenwidth:Int   0x00C6EFE0 g_screenheight:Int  (bare dword reads)
'     0x00C6F230 g_img_866:TImage    negotiate/renew icon
'     0x00C6F254 g_img_867:TImage    reject icon
'     0x00C6F274 g_img_play:TImage   accept icon (name already established elsewhere;
'                                    globals_corrections.tsv types it TImage, verified)
'     0x00C6F2EC g_img_871:TImage    help icon
'   All four are passed in the `:TImage` slot of TButton.CreateButton, which is what types
'   them; globals_final lists 866/867/871 as bare Object.
'
'   Class-table slots (all resolved through class_tables.tsv + vtable_map.tsv):
'     [0x00C61C64] TScreen+0x38       CreateScreen ($,:TImage,()i,()i):TScreen
'     [0x00C61CDC] TScreen+0xB0       ButtonHelp ()i   -- TScreen's table, not ours, so it
'                                     is written WITH the Type prefix
'     [0x00C63294] TPanel+0x88        CreatePanel ($,$,i,i,i,i,$,$,i,f,i,i,i):TPanel
'     [0x00C623CC] TButton+0x88       CreateButton ($,$,i,i,i,i,i,i,$,$,:TImage,()i,f,i,$)
'     [0x00C634C0] TLabel+0x88        CreateLabel ($,$,i,i,i,i,i,$,$,f,i,i,i,i,:TImage,
'                                                  i,i,i,i,$,f):TLabel   -- 21 args
'     [0x00C637A8] TProgressBar+0x88  CreateProgressBar ($,$,i,i,i,i,i,$,$,$,f,i,:TImage)
'     [0x00C638BC] THelpBox+0x30      Create (:TGadget,i,i,i,i,$,i,i):THelpBox
'     [0x00C67D70/74/78] TScreen_ContractOffer+0x4C/0x50/0x54 = ButtonReject /
'         ButtonNegotiate / ButtonAccept -- siblings of THIS Type, so NO Type prefix
'     [0x00C6803C] TScreen_MyContract+0x64 = ButtonRenewContract ()i -- other Type, prefixed
'     TScreen slot 0x40 = AddGadget(:TGadget)i ; TGadget slot 0x74 = AddChild(:TGadget)i
'     (TPanel has no 0x74 of its own -- inherited from TGadget)
'     TList slot 0x44 = AddLast ; TScreen field +0x1C = lHelp:TList
'   BRL / module Functions: 0x004C5549 GetText (ONE argument -- `add esp,4`; Ghidra merges
'   the following gadget-factory pushes into its arg list), 0x004BC564 LoadSoundChecked.
'   FUN_005B95D0 in a `()i` slot is source-level Null; 0x005C9C80 is bbNullObject.
'
' LITERALS were read out of the exe with harness.read_string -- a MATCH masks the literal's
' ADDRESS, so their contents are NOT certified by the oracle.  0x005C7D40 and 0x00C5D284
' are both the empty string.  0x00C5D680 "FFFFFF", 0x00C73A70 "888888", 0x00C6E904 "00FF00".
'
' SHAPE NOTES (these are what the bytes actually force, against Ghidra's rendering)
'   * The sound guard is `If Not g_co_snd`, not `If g_co_snd = Null`: the emission is
'     cmp/setne al/movzx/cmp 0/jne (codegen-patterns 10.3), 21 bytes with inverted sense.
'   * Ghidra constant-propagates the four layout Locals and prints folded literals
'     (0x14, 0x78, 0xAA ...).  The disassembly shows real slots: x=[ebp-8], y=ebx,
'     w=edi, h=[ebp-4].  Every row advance is `mov eax,[ebp-4] / add eax,N / add ebx,eax`,
'     i.e. `y :+ h + N` -- writing the folded constant instead would change the bytes.
'   * `h` is set ONCE (30) and deliberately NOT reset for the New-Contract column; only
'     x, y and w are re-initialised there.
'   * `w / 2` is emitted twice in every value row (once for the width, once inside
'     `x + w / 2`) because bcc does no CSE -- that is the source, not a missed Local.
	'!Global g_co_screen:TScreen
	'!Global g_co_snd:TSound
	'!Global g_co_pan536:TPanel
	'!Global g_co_btn537:TButton
	'!Global g_co_pan538:TPanel
	'!Global g_co_lbl539:TLabel
	'!Global g_co_lbl540:TLabel
	'!Global g_co_lbl541:TLabel
	'!Global g_co_prg542:TProgressBar
	'!Global g_co_lbl543:TLabel
	'!Global g_co_lbl544:TLabel
	'!Global g_co_lbl545:TLabel
	'!Global g_co_lbl546:TLabel
	'!Global g_co_lbl547:TLabel
	'!Global g_co_btn548:TButton
	'!Global g_co_btn549:TButton
	'!Global g_co_pan550:TPanel
	'!Global g_co_lbl551:TLabel
	'!Global g_co_lbl552:TLabel
	'!Global g_co_lbl553:TLabel
	'!Global g_co_prg554:TProgressBar
	'!Global g_co_lbl555:TLabel
	'!Global g_co_lbl556:TLabel
	'!Global g_co_lbl557:TLabel
	'!Global g_co_lbl558:TLabel
	'!Global g_co_lbl559:TLabel
	'!Global g_co_lbl560:TLabel
	'!Global g_co_btn561:TButton
	'!Global g_screenwidth:Int
	'!Global g_screenheight:Int
	'!Global g_img_866:TImage
	'!Global g_img_867:TImage
	'!Global g_img_play:TImage
	'!Global g_img_871:TImage
	Function CreateScreen()
		g_co_screen = TScreen.CreateScreen("contractoffer", Null, Null, Null)
		If Not g_co_snd
			g_co_snd = LoadSoundChecked("GameMedia/Sounds/Phone.ogg", 0)
		EndIf
		g_co_pan536 = TPanel.CreatePanel("pan_title", GetText("Contract Offer"), 0, 0, g_screenwidth, 60, "FFFFFF", "FFFFFF", 4, 1.0, 0, 0, 1)
		g_co_screen.AddGadget(g_co_pan536)
		g_co_btn537 = TButton.CreateButton("btn_help", "", g_screenwidth - 50, 10, 40, 40, 1, 2, "FFFFFF", "FFFFFF", g_img_871, TScreen.ButtonHelp, 1.0, 1, "")
		g_co_pan536.AddChild(g_co_btn537)
		g_co_screen.AddGadget(TPanel.CreatePanel("navpanel", "", 0, g_screenheight - 60, g_screenwidth, 60, "FFFFFF", "FFFFFF", 3, 1.0, 0, 0, 0))
		g_co_btn549 = TButton.CreateButton("reject", GetText("transfer_Consider"), 10, g_screenheight - 50, 180, 40, 1, 3, "FFFFFF", "FFFFFF", g_img_867, ButtonReject, 1.0, 1, "")
		g_co_screen.AddGadget(g_co_btn549)
		g_co_screen.AddGadget(TButton.CreateButton("accept", GetText("transfer_Accept"), 610, g_screenheight - 50, 180, 40, 1, 3, "FFFFFF", "FFFFFF", g_img_play, ButtonAccept, 1.0, 1, ""))
		g_co_btn561 = TButton.CreateButton("negotiate", GetText("transfer_Negotiate"), g_screenwidth / 2 - 90, g_screenheight - 50, 180, 40, 1, 3, "FFFFFF", "FFFFFF", g_img_866, ButtonNegotiate, 1.0, 1, "")
		g_co_screen.AddGadget(g_co_btn561)
		Local x:Int = 10
		Local y:Int = 70
		Local w:Int = g_screenwidth / 2 - 15
		Local h:Int = 30
		g_co_pan538 = TPanel.CreatePanel("pan_ContractCurrent", GetText("Current Contract"), x, y, w, 40, "FFFFFF", "FFFFFF", 3, 0.8, 1, 420, 0)
		y :+ 50
		x :+ 10
		w :- 20
		g_co_screen.AddGadget(g_co_pan538)
		g_co_lbl539 = TLabel.CreateLabel("lbl_TeamCurrent", "", x, y, w, h + 10, 3, "888888", "FFFFFF", 1.0, 1, 0, 1, 1, Null, 1, 0, 0, 0, "", 0)
		y :+ h + 20
		g_co_lbl540 = TLabel.CreateLabel("lbl_NationCurrent", "", x, y, w, h - 2, 3, "888888", "FFFFFF", 1.0, 1, 0, 1, 1, Null, 1, 0, 0, 0, "", 0)
		y :+ h + 1
		g_co_lbl541 = TLabel.CreateLabel("lbl_LeagueCurrent", "", x, y, w, h - 2, 3, "888888", "FFFFFF", 1.0, 1, 0, 1, 1, Null, 1, 0, 0, 0, "", 0)
		y :+ h + 1
		g_co_prg542 = TProgressBar.CreateProgressBar("prg_BossCurrent", GetText("Boss"), x, y, w, h - 2, 2, "FFFFFF", "00FF00", "FFFFFF", 0.8, 1, Null)
		y :+ h + 8
		g_co_pan538.AddChild(g_co_lbl539)
		g_co_pan538.AddChild(g_co_lbl540)
		g_co_pan538.AddChild(g_co_lbl541)
		g_co_pan538.AddChild(g_co_prg542)
		g_co_pan538.AddChild(TLabel.CreateLabel("lbl_WageCurrent1", GetText("Wage"), x, y, w / 2, h, 3, "FFFFFF", "FFFFFF", 1.0, 4, 0, 1, 2, Null, 1, 0, 0, 0, "", 0))
		g_co_lbl543 = TLabel.CreateLabel("lbl_WageCurrent2", "", x + w / 2, y, w / 2, h, 3, "888888", "FFFFFF", 1.0, 5, 0, 1, 1, Null, 1, 0, 0, 0, "", 0)
		y :+ h + 10
		g_co_pan538.AddChild(g_co_lbl543)
		g_co_pan538.AddChild(TLabel.CreateLabel("lbl_GoalCurrent1", GetText("Goal Bonus"), x, y, w / 2, h, 3, "FFFFFF", "FFFFFF", 1.0, 4, 0, 1, 2, Null, 1, 0, 0, 0, "", 0))
		g_co_lbl545 = TLabel.CreateLabel("lbl_GoalCurrent2", "", x + w / 2, y, w / 2, h, 3, "888888", "FFFFFF", 1.0, 5, 0, 1, 1, Null, 1, 0, 0, 0, "", 0)
		y :+ h + 10
		g_co_pan538.AddChild(g_co_lbl545)
		g_co_pan538.AddChild(TLabel.CreateLabel("lbl_AssistCurrent1", GetText("Assist Bonus"), x, y, w / 2, h, 3, "FFFFFF", "FFFFFF", 1.0, 4, 0, 1, 2, Null, 1, 0, 0, 0, "", 0))
		g_co_lbl546 = TLabel.CreateLabel("lbl_AssistCurrent2", "", x + w / 2, y, w / 2, h, 3, "888888", "FFFFFF", 1.0, 5, 0, 1, 1, Null, 1, 0, 0, 0, "", 0)
		y :+ h + 10
		g_co_pan538.AddChild(g_co_lbl546)
		g_co_pan538.AddChild(TLabel.CreateLabel("lbl_CleanCurrent1", GetText("Clean Sheet Bonus"), x, y, w / 2, h, 3, "FFFFFF", "FFFFFF", 1.0, 4, 0, 1, 2, Null, 1, 0, 0, 0, "", 0))
		g_co_lbl547 = TLabel.CreateLabel("lbl_CleanCurrent2", "", x + w / 2, y, w / 2, h, 3, "888888", "FFFFFF", 1.0, 5, 0, 1, 1, Null, 1, 0, 0, 0, "", 0)
		y :+ h + 10
		g_co_pan538.AddChild(g_co_lbl547)
		g_co_pan538.AddChild(TLabel.CreateLabel("lbl_LengthCurrent1", GetText("Expires"), x, y, w / 2, h, 3, "FFFFFF", "FFFFFF", 1.0, 4, 0, 1, 2, Null, 1, 0, 0, 0, "", 0))
		g_co_lbl544 = TLabel.CreateLabel("lbl_LengthCurrent2", "", x + w / 2, y, w / 2, h, 3, "888888", "FFFFFF", 1.0, 5, 0, 1, 1, Null, 1, 0, 0, 0, "", 0)
		y :+ h + 10
		g_co_pan538.AddChild(g_co_lbl544)
		g_co_btn548 = TButton.CreateButton("btn_Renew", GetText("Renew Contract"), x, y, w, h * 2 - 10, 1, 3, "FFFFFF", "FFFFFF", g_img_866, TScreen_MyContract.ButtonRenewContract, 1.0, 1, "")
		g_co_pan538.AddChild(g_co_btn548)
		x = g_screenwidth / 2 + 5
		y = 70
		w = g_screenwidth / 2 - 15
		g_co_pan550 = TPanel.CreatePanel("pan_ContractNew", GetText("New Contract"), x, y, w, 40, "FFFFFF", "FFFFFF", 3, 0.8, 1, 420, 0)
		y :+ 50
		x :+ 10
		w :- 20
		g_co_screen.AddGadget(g_co_pan550)
		g_co_lbl551 = TLabel.CreateLabel("lbl_TeamNew", "", x, y, w, h + 10, 3, "888888", "FFFFFF", 1.0, 1, 0, 1, 1, Null, 1, 0, 0, 0, "", 0)
		y :+ h + 20
		g_co_lbl552 = TLabel.CreateLabel("lbl_NationNew", "", x, y, w, h - 2, 3, "888888", "FFFFFF", 1.0, 1, 1, 1, 1, Null, 1, 0, 0, 0, "", 0)
		y :+ h + 1
		g_co_lbl553 = TLabel.CreateLabel("lbl_LeagueNew", "", x, y, w, h - 2, 3, "888888", "FFFFFF", 1.0, 1, 1, 1, 1, Null, 1, 0, 0, 0, "", 0)
		y :+ h + 1
		g_co_prg554 = TProgressBar.CreateProgressBar("prg_BossNew", GetText("Boss"), x, y, w, h - 2, 2, "FFFFFF", "00FF00", "FFFFFF", 0.8, 1, Null)
		y :+ h + 8
		g_co_pan550.AddChild(g_co_lbl551)
		g_co_pan550.AddChild(g_co_lbl552)
		g_co_pan550.AddChild(g_co_lbl553)
		g_co_pan550.AddChild(g_co_prg554)
		g_co_pan550.AddChild(TLabel.CreateLabel("lbl_WageNew1", GetText("Wage"), x, y, w / 2, h, 3, "FFFFFF", "FFFFFF", 1.0, 4, 0, 1, 2, Null, 1, 0, 0, 0, "", 0))
		g_co_lbl555 = TLabel.CreateLabel("lbl_WageNew2", "", x + w / 2, y, w / 2, h, 3, "888888", "FFFFFF", 1.0, 5, 0, 1, 1, Null, 1, 0, 0, 0, "", 0)
		y :+ h + 10
		g_co_pan550.AddChild(g_co_lbl555)
		g_co_pan550.AddChild(TLabel.CreateLabel("lbl_GoalNew1", GetText("Goal Bonus"), x, y, w / 2, h, 3, "FFFFFF", "FFFFFF", 1.0, 4, 0, 1, 2, Null, 1, 0, 0, 0, "", 0))
		g_co_lbl556 = TLabel.CreateLabel("lbl_GoalNew2", "", x + w / 2, y, w / 2, h, 3, "888888", "FFFFFF", 1.0, 5, 0, 1, 1, Null, 1, 0, 0, 0, "", 0)
		y :+ h + 10
		g_co_pan550.AddChild(g_co_lbl556)
		g_co_pan550.AddChild(TLabel.CreateLabel("lbl_AssistNew1", GetText("Assist Bonus"), x, y, w / 2, h, 3, "FFFFFF", "FFFFFF", 1.0, 4, 0, 1, 2, Null, 1, 0, 0, 0, "", 0))
		g_co_lbl557 = TLabel.CreateLabel("lbl_AssistNew2", "", x + w / 2, y, w / 2, h, 3, "888888", "FFFFFF", 1.0, 5, 0, 1, 1, Null, 1, 0, 0, 0, "", 0)
		y :+ h + 10
		g_co_pan550.AddChild(g_co_lbl557)
		g_co_pan550.AddChild(TLabel.CreateLabel("lbl_CleanNew1", GetText("Clean Sheet Bonus"), x, y, w / 2, h, 3, "FFFFFF", "FFFFFF", 1.0, 4, 0, 1, 2, Null, 1, 0, 0, 0, "", 0))
		g_co_lbl558 = TLabel.CreateLabel("lbl_CleanNew2", "", x + w / 2, y, w / 2, h, 3, "888888", "FFFFFF", 1.0, 5, 0, 1, 1, Null, 1, 0, 0, 0, "", 0)
		y :+ h + 10
		g_co_pan550.AddChild(g_co_lbl558)
		g_co_pan550.AddChild(TLabel.CreateLabel("lbl_LengthNew1", GetText("Length"), x, y, w / 2, h, 3, "FFFFFF", "FFFFFF", 1.0, 4, 0, 1, 2, Null, 1, 0, 0, 0, "", 0))
		g_co_lbl560 = TLabel.CreateLabel("lbl_LengthNew2", "", x + w / 2, y, w / 2, h, 3, "888888", "FFFFFF", 1.0, 5, 0, 1, 1, Null, 1, 0, 0, 0, "", 0)
		y :+ h + 10
		g_co_pan550.AddChild(g_co_lbl560)
		g_co_pan550.AddChild(TLabel.CreateLabel("lbl_SigningFeeNew1", GetText("Signing Fee"), x, y, w / 2, h * 2 - 10, 3, "FFFFFF", "FFFFFF", 1.0, 4, 0, 1, 2, Null, 1, 0, 0, 0, "", 0))
		g_co_lbl559 = TLabel.CreateLabel("lbl_SigningFeeNew2", "", x + w / 2, y, w / 2, h * 2 - 10, 3, "888888", "FFFFFF", 1.0, 5, 0, 1, 1, Null, 1, 0, 0, 0, "", 0)
		g_co_pan550.AddChild(g_co_lbl559)
		g_co_screen.lHelp.AddLast(THelpBox.Create(g_co_prg542, 0, 0, 0, 0, GetText("CHELP_CONTRACTBOSS1"), 1, 2))
		g_co_screen.lHelp.AddLast(THelpBox.Create(g_co_prg554, 0, 0, 0, 0, GetText("CHELP_CONTRACTBOSS2"), 1, 2))
		g_co_screen.lHelp.AddLast(THelpBox.Create(g_co_btn561, 0, 0, 0, 0, GetText("CHELP_CONTRACTNEGOTIATE"), 2, 2))
	End Function
