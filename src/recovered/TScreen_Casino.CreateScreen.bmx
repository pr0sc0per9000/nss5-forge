' TScreen_Casino.CreateScreen
' VA 0x005737EB   2354 bytes   KIND=Function (static, no Self)   SIG ()i   class-table slot 0x30
' byte-identical vs NSS5.exe (2354/2354, original length from Ghidra's inventory, mode=reloc)
'
' Gadget-construction body: builds the casino hub screen (chip/button image cache, the
' three casino-game buttons, and the seven stake buttons), reconstructed directly from the
' disassembly rather than the Ghidra decompilation (which merges adjacent calls' argument
' lists -- codegen-patterns.md section on CALL annotations). x/y/w/h below are the exact
' four Locals the allocator keeps: x=edi, y=ebx (registers), w=[ebp-8], h=[ebp-4] (spilled).
' Their re-seed/increment statements, and which of them a given CreatePanel/CreateButton
' call actually reads, are transcribed instruction-for-instruction; several are asymmetric
' quirks of the original and are reproduced as found, not tidied:
'   - the x/y bump before "pan_casino" is Y-then-X; the bump before "pan_stake" is
'     X-then-Y-then-W. Different order, not a typo.
'   - "pan_casino" is created with LITERAL w=760,h=30 (not the w/h Locals, which hold
'     240/170 for the buttons at that point).
'   - "pan_stake" is created with w = the Local (200, coincides with the literal) but a
'     LITERAL h=30 (not the Local, which holds 50 for the stake buttons).
'   - only btn_stake1 gets a non-default col1 (g_colour_sel, its highlight/selected
'     colour); stake buttons 2-7 use plain "FFFFFF","FFFFFF" (confirmed by direct
'     disassembly comparison of all seven CreateButton call sites).
'   - stake6's FormatMoney call correctly uses 2500 here; UpdateStakeCurrency.bmx has an
'     ORIGINAL BUG using 250 for the same button -- the two functions differ and both are
'     faithful to their own bytes.
'   - "pan_stake" is built and its 7 buttons are AddChild'd to it, but pan_stake itself is
'     never AddGadget'd to the screen anywhere in this function (confirmed: g_casino_screen
'     is referenced exactly 6 times total, none of them for pan_stake) -- reproduced as is.
'   - the "Leave Casino" button's internal gadget name is literally "btn_play" (read via
'     harness.read_string), not "btn_quit"/"btn_leave" -- almost certainly copy-pasted from
'     TScreen_Slots.CreateScreen's real Play button and never renamed. Reproduced faithfully.
'
' TScreen.CreateScreen's two Int() callback parameters are passed literal Null, which bcc
' compiles to the "null function" trampoline sentinel 0x005B95D0 (NOT the object-null
' 0x005C9C80 used for the TImage bg parameter) -- both forms confirmed by direct bytes.
'
' Globals (names ours except where noted; addresses and TYPES are load-bearing):
'   0x00C6B830 g_casino_screen:TScreen        (construction site, this function)
'   0x00C6B840 g_casino_chipimages:TImage[]   established by TScreen_Casino.GetChipImage.bmx
'   0x00C6B844 g_casino_imgBlackJack:TImage
'   0x00C6B848 g_casino_imgRoulette:TImage
'   0x00C6B84C g_casino_imgSlots:TImage
'   0x00C6B850 g_casino_sndError:TSound       (LoadSoundChecked return; TrainingError.ogg
'                                              reused here, presumably for an invalid-stake
'                                              or insufficient-funds cue)
'   0x00C6B854 g_casino_pantitle:TPanel       ("pan_casino" -- title bar + 3 game buttons)
'   0x00C6B858 g_casino_panel:TPanel          established by TScreen_Casino.SetStake.bmx
'                                              ("pan_stake" -- holds the 7 stake buttons)
'   0x00C6B860.. g_casino_stake50..5000:TButton   established by
'                TScreen_Casino.UpdateStakeCurrency.bmx (7 Globals, one per stake amount)
'   0x00C66768 g_pan_stable:TPanel            established by TScreen_Slots.CreateScreen.bmx
'                                              (shared panel, same address/type there)
'   0x00C6EFDC g_screenwidth:Int, 0x00C6EFE0 g_screenheight:Int   established elsewhere
'   0x00C6E91C g_colour_sel:String            established by TScreen_Casino.SetStake.bmx
'                                              (confirmed String here too: pushed with no
'                                              conversion into CreateButton's col1 String
'                                              parameter, exactly as SetStake's SetColour
'                                              call uses it -- globals_final.tsv's "Int" is
'                                              wrong, see codegen-patterns 10.7/11.2)
'   0x00C6F254 g_icon_home:TImage             (GUESS name; forced TImage by CreateButton's
'                                              icon parameter; low-confidence in
'                                              globals_final.tsv, no other call site found)
'
' Class-table slots used: 0x00C61C64 TScreen+0x38 CreateScreen; 0x00C623CC TButton+0x88
'   CreateButton; 0x00C63294 TPanel+0x88 CreatePanel; TGadget+0x74 AddChild (inherited by
'   TPanel -- NOT TScreen's own AddGadget at +0x40, a different slot); 0x00C66A60
'   TScreen_Home+0x34 SetUpScreen; 0x00C6BA28/30/34/38 TScreen_Casino SetStake/
'   ButtonBlackJack/ButtonRoulette/ButtonSlots; 0x00C6BCA0/C6C318/C6C63C TRoulette/
'   TBlackJack/TSlotMachine +0x30 SetUp().
'
' Literals read from the exe with harness.read_string(): "casino", the 7 "Chip_*.png" /
' 3 "btn_*.png" asset paths, "EngineMedia/Match/Sounds/TrainingError.ogg", "pan_nav",
' "btn_play", "tt_LeaveCasino", "Casino", "pan_casino", "tt_BlackJack", "btn_blackjack",
' "tt_Roulette", "btn_roulette", "tt_Slots", "btn_slots", "casino_Stake", "pan_stake",
' "btn_stake1".."btn_stake7", "FFFFFF".
	Function CreateScreen:Int()
		'!Global g_casino_screen:TScreen
		'!Global g_casino_chipimages:TImage[]
		'!Global g_casino_imgBlackJack:TImage
		'!Global g_casino_imgRoulette:TImage
		'!Global g_casino_imgSlots:TImage
		'!Global g_casino_sndError:TSound
		'!Global g_pan_stable:TPanel
		'!Global g_screenwidth:Int
		'!Global g_screenheight:Int
		'!Global g_icon_home:TImage
		'!Global g_casino_pantitle:TPanel
		'!Global g_casino_panel:TPanel
		'!Global g_colour_sel:String
		'!Global g_casino_stake50:TButton
		'!Global g_casino_stake100:TButton
		'!Global g_casino_stake250:TButton
		'!Global g_casino_stake500:TButton
		'!Global g_casino_stake1000:TButton
		'!Global g_casino_stake2500:TButton
		'!Global g_casino_stake5000:TButton

		g_casino_screen = TScreen.CreateScreen("casino", Null, Null, Null)

		If Not g_casino_chipimages[0]
			g_casino_chipimages[0] = LoadImageChecked("GameMedia/Images/Casino/Chip_50.png", -1)
			g_casino_chipimages[1] = LoadImageChecked("GameMedia/Images/Casino/Chip_100.png", -1)
			g_casino_chipimages[2] = LoadImageChecked("GameMedia/Images/Casino/Chip_250.png", -1)
			g_casino_chipimages[3] = LoadImageChecked("GameMedia/Images/Casino/Chip_500.png", -1)
			g_casino_chipimages[4] = LoadImageChecked("GameMedia/Images/Casino/Chip_1000.png", -1)
			g_casino_chipimages[5] = LoadImageChecked("GameMedia/Images/Casino/Chip_2500.png", -1)
			g_casino_chipimages[6] = LoadImageChecked("GameMedia/Images/Casino/Chip_5000.png", -1)
			g_casino_imgBlackJack = LoadImageChecked("GameMedia/Images/Casino/btn_BlackJack.png", -1)
			g_casino_imgRoulette = LoadImageChecked("GameMedia/Images/Casino/btn_Roulette.png", -1)
			g_casino_imgSlots = LoadImageChecked("GameMedia/Images/Casino/btn_Slots.png", -1)
			g_casino_sndError = LoadSoundChecked("EngineMedia/Match/Sounds/TrainingError.ogg", 0)
		EndIf

		g_casino_screen.AddGadget(g_pan_stable)
		g_casino_screen.AddGadget(TPanel.CreatePanel("pan_nav", "", 0, g_screenheight - 60, g_screenwidth, 60, "FFFFFF", "FFFFFF", 3, 1.0, 0, 0, 0))
		g_casino_screen.AddGadget(TButton.CreateButton("btn_play", "", g_screenwidth - 130, g_screenheight - 50, 120, 40, 1, 2, "FFFFFF", "FFFFFF", g_icon_home, TScreen_Home.SetUpScreen, 1.0, 1, GetText("tt_LeaveCasino")))

		Local x:Int = 20
		Local y:Int = 200
		Local w:Int = 240
		Local h:Int = 170
		g_casino_pantitle = TPanel.CreatePanel("pan_casino", GetText("Casino"), x, y, 760, 30, "FFFFFF", "FFFFFF", 3, 0.8, 1, 190, 0)
		y :+ 40
		x :+ 10
		g_casino_screen.AddGadget(g_casino_pantitle)
		g_casino_pantitle.AddChild(TButton.CreateButton("btn_blackjack", "", x, y, w, h, 1, 3, "FFFFFF", "FFFFFF", g_casino_imgBlackJack, TScreen_Casino.ButtonBlackJack, 1.0, 1, GetText("tt_BlackJack")))
		x :+ w + 10
		g_casino_pantitle.AddChild(TButton.CreateButton("btn_roulette", "", x, y, w, h, 1, 3, "FFFFFF", "FFFFFF", g_casino_imgRoulette, TScreen_Casino.ButtonRoulette, 1.0, 1, GetText("tt_Roulette")))
		x :+ w + 10
		g_casino_pantitle.AddChild(TButton.CreateButton("btn_slots", "", x, y, w, h, 1, 3, "FFFFFF", "FFFFFF", g_casino_imgSlots, TScreen_Casino.ButtonSlots, 1.0, 1, GetText("tt_Slots")))

		TRoulette.SetUp()
		TBlackJack.SetUp()
		TSlotMachine.SetUp()

		x = 10
		y = 70
		w = 200
		h = 50
		g_casino_panel = TPanel.CreatePanel("pan_stake", GetText("casino_Stake"), x, y, w, 30, "FFFFFF", "FFFFFF", 3, 0.8, 1, 430, 0)
		x :+ 10
		y :+ 40
		w :- 20
		g_casino_stake50 = TButton.CreateButton("btn_stake1", FormatMoney(50, 0), x, y, w, h, 1, 3, g_colour_sel, "FFFFFF", g_casino_chipimages[0], TScreen_Casino.SetStake, 1.0, 1, "")
		y :+ h + 10
		g_casino_stake100 = TButton.CreateButton("btn_stake2", FormatMoney(100, 0), x, y, w, h, 1, 3, "FFFFFF", "FFFFFF", g_casino_chipimages[1], TScreen_Casino.SetStake, 1.0, 1, "")
		y :+ h + 10
		g_casino_stake250 = TButton.CreateButton("btn_stake3", FormatMoney(250, 0), x, y, w, h, 1, 3, "FFFFFF", "FFFFFF", g_casino_chipimages[2], TScreen_Casino.SetStake, 1.0, 1, "")
		y :+ h + 10
		g_casino_stake500 = TButton.CreateButton("btn_stake4", FormatMoney(500, 0), x, y, w, h, 1, 3, "FFFFFF", "FFFFFF", g_casino_chipimages[3], TScreen_Casino.SetStake, 1.0, 1, "")
		y :+ h + 10
		g_casino_stake1000 = TButton.CreateButton("btn_stake5", FormatMoney(1000, 0), x, y, w, h, 1, 3, "FFFFFF", "FFFFFF", g_casino_chipimages[4], TScreen_Casino.SetStake, 1.0, 1, "")
		y :+ h + 10
		g_casino_stake2500 = TButton.CreateButton("btn_stake6", FormatMoney(2500, 0), x, y, w, h, 1, 3, "FFFFFF", "FFFFFF", g_casino_chipimages[5], TScreen_Casino.SetStake, 1.0, 1, "")
		y :+ h + 10
		g_casino_stake5000 = TButton.CreateButton("btn_stake7", FormatMoney(5000, 0), x, y, w, h, 1, 3, "FFFFFF", "FFFFFF", g_casino_chipimages[6], TScreen_Casino.SetStake, 1.0, 1, "")

		g_casino_panel.AddChild(g_casino_stake50)
		g_casino_panel.AddChild(g_casino_stake100)
		g_casino_panel.AddChild(g_casino_stake250)
		g_casino_panel.AddChild(g_casino_stake500)
		g_casino_panel.AddChild(g_casino_stake1000)
		g_casino_panel.AddChild(g_casino_stake2500)
		g_casino_panel.AddChild(g_casino_stake5000)
	End Function
