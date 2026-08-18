' TScreen_Roulette.CreateScreen
' VA 0x005745D7   2200 bytes   KIND=Function (static, no Self)   SIG ()i   class-table slot 0x30
' byte-identical vs NSS5.exe (2200/2200, original length from Ghidra's inventory, mode=reloc)
'
' Gadget-construction body for the roulette table screen: background image cache, the
' "pan_roulette" title panel, six result labels (odd/even/red/black/1to18/19to36) plus two
' running-total labels, seven bet buttons (six stakes + Clear), the shared nav bar, and the
' Back/Play buttons. Same family as TScreen_Casino.CreateScreen / TScreen_Slots.CreateScreen
' (docs/reference/codegen-patterns.md sections 12.2 and the CreateScreen family note),
' reconstructed directly from harness.disasm_original -- Ghidra's decompilation merges the
' "GetText" calls' argument lists with the following CreateLabel/CreatePanel call's own
' pushes (its header literally warns "GHIDRA'S PRINTED ARGUMENT LIST IS NOT EVIDENCE"), so
' every push was walked by hand and cross-checked against the decompiled C.
'
' x/y/w/h are the four Locals bcc keeps: x=edi, y=esi, w=[ebp-4] (register allocator spills
' w -- its reference count is lower than x/y/h's, see codegen-patterns.md section 18), h=ebx.
' Quirks reproduced as found, not tidied:
'   - "pan_roulette" is created with LITERAL w=280,h=30 (not the w/h Locals, which are
'     declared immediately before this call but hold 90/50 -- used only by the labels and
'     buttons that follow). x/y ARE the Locals (510, 70) for this one call.
'   - the x/y bump after "pan_roulette" is X-then-Y (`x :+ 10` then `y :+ 40`) -- the
'     opposite order from TScreen_Casino.CreateScreen's "pan_casino" (Y-then-X). Checked by
'     direct disassembly, not assumed.
'   - "lbl_total1" and "lbl_total2" both use a LITERAL height of 25 (not the h Local, still
'     50 at that point) -- and lbl_total2's Y is `y + 25` (an inline expression, y itself is
'     never incremented between the two totals) rather than a fresh `y :+ h + 10` step.
'   - AFTER lbl_total2, x is bumped by the OLD w (90) plus 10, then y is reset to a fixed 110
'     and w is reset to a fixed 160 -- three separate statements, not one combined update.
'   - h (ebx, still 50 the whole function) is never reset; every label/button box height
'     that isn't one of the two literal-25 totals uses it unchanged.
'   - all six result labels and all seven buttons are AddChild'd onto g_roulette_pantitle,
'     never AddGadget'd onto the screen directly (only pan_roulette itself, the shared
'     stable panel, the nav panel and the Back/Play buttons are AddGadget'd).
'   - the Back button (icon g_iconBack, callback TScreen_Casino.SetUpScreen, tooltip
'     "tt_Back") and Play button (icon g_img_play, callback ButtonPlay, tooltip "tt_Play")
'     both use w=120,h=40 -- NOT the w/h Locals, which have already been reassigned to
'     160/50 by this point; these are fresh literals, positioned via g_screenwidth/
'     g_screenheight arithmetic instead of x/y.
'   - TScreen.CreateScreen's two callback args are Draw-then-Update (TRoulette.Draw,
'     TRoulette.Update), matching TScreen_Slots.CreateScreen's convention, confirmed by push
'     order (last-pushed = last-declared param).
'   - PlaceBet, ClearBets and ButtonPlay are TScreen_Roulette's own Functions, called
'     unqualified (bare) as callback values -- same "own Type -> no prefix" rule as
'     TScreen_Slots.CreateScreen's ButtonPlay reference (codegen-patterns.md section 3d).
'
' Globals (names ours except where the address is independently corroborated elsewhere;
' addresses and TYPES are load-bearing):
'   0x00C6E950 g_datapath:String            established by TScreen_Slots.CreateScreen.bmx
'   0x00C6BA4C g_roulette_imgBg:TImage      LoadImageChecked return, image cache guard
'   0x00C6BA48 g_roulette_screen:TScreen    construction site, this function
'   0x00C66768 g_pan_stable:TPanel          shared panel, same address/type as
'                                            TScreen_Slots/Casino.CreateScreen.bmx
'   0x00C6BA50 g_roulette_pantitle:TPanel   ("pan_roulette") -- SAME address as
'                                            TScreen_Roulette.SetUpScreen.bmx's g_rl1:TGadget
'                                            (that file calls .Show() on it via the inherited
'                                            TGadget slot; TPanel IS a TGadget, corroborating)
'   0x00C6BA54 g_roulette_btnQuit:TButton   SAME address as SetUpScreen.bmx's g_rl2:TGadget
'   0x00C6BA58 g_roulette_btnPlay:TButton   SAME address as SetUpScreen.bmx's g_rl3:TGadget
'   0x00C6EFDC g_screenwidth:Int, 0x00C6EFE0 g_screenheight:Int   established elsewhere
'                                            (bare dword pushes, no refcount traffic -> Int)
'   0x00C6F194 g_iconBack:TImage            SAME address/type as TScreen_Slots.CreateScreen's
'                                            "Back" button icon; confirmed by the identical
'                                            call shape (icon, TScreen_Casino.SetUpScreen
'                                            callback, "tt_Back" tooltip)
'   0x00C6F274 g_img_play:TImage            hand-verified TImage in globals_corrections.tsv;
'                                            "g_img_play" is the name already established at
'                                            this address across TScreen_ContractOffer/
'                                            ReportBoss/Newspaper/ReportPhysio.CreateScreen
'
' Class-table slots used: 0x00C61C64 TScreen+0x38 CreateScreen; 0x00C623CC TButton+0x88
'   CreateButton; 0x00C63294 TPanel+0x88 CreatePanel; 0x00C634C0 TLabel+0x88 CreateLabel;
'   TGadget+0x74 AddChild (inherited by TPanel); TScreen+0x40 AddGadget; 0x00C6BA24
'   TScreen_Casino+0x38 SetUpScreen; 0x00C6BB9C/BBA0/BBA8 TScreen_Roulette's own
'   ButtonPlay/PlaceBet/ClearBets; 0x00C6BCA8/BCAC TRoulette+0x38/0x3C Update/Draw.
'
' Literals read from the exe with harness.read_string(), all confirmed exact:
'   "GameMedia/Images/Casino/Roulette/bg.png", "roulette", "Roulette", "pan_roulette",
'   "lbl_odd".."lbl_19to36", "lbl_total1", "lbl_total2", "roulette_Odd".."roulette_19to36",
'   "btn_odd".."btn_19to36", "Clear Bets", "btn_clear", "Total", "tt_Play", "tt_Back",
'   "btn_quit", "btn_play", "navpanel", "FFFFFF", "FF0000", "666666", "888888", "0", "".

	Function CreateScreen:Int()
		'!Global g_datapath:String
		'!Global g_roulette_imgBg:TImage
		'!Global g_roulette_screen:TScreen
		'!Global g_pan_stable:TPanel
		'!Global g_roulette_pantitle:TPanel
		'!Global g_roulette_btnQuit:TButton
		'!Global g_roulette_btnPlay:TButton
		'!Global g_screenwidth:Int
		'!Global g_screenheight:Int
		'!Global g_iconBack:TImage
		'!Global g_img_play:TImage

		If Not g_roulette_imgBg
			g_roulette_imgBg = LoadImageChecked(g_datapath + "GameMedia/Images/Casino/Roulette/bg.png", -1)
		EndIf
		g_roulette_screen = TScreen.CreateScreen("roulette", g_roulette_imgBg, TRoulette.Draw, TRoulette.Update)
		g_roulette_screen.AddGadget(g_pan_stable)

		Local x:Int = 510
		Local y:Int = 70
		Local w:Int = 90
		Local h:Int = 50
		g_roulette_pantitle = TPanel.CreatePanel("pan_roulette", GetText("Roulette"), x, y, 280, 30, "FFFFFF", "FFFFFF", 3, 0.8, 1, 430, 0)
		x :+ 10
		y :+ 40
		g_roulette_screen.AddGadget(g_roulette_pantitle)

		g_roulette_pantitle.AddChild(TLabel.CreateLabel("lbl_odd", "0", x, y, w, h, 3, "FFFFFF", "FFFFFF", 1.0, 1, 0, 1, 1, Null, 1, 0, 0, 0, "", 0))
		y :+ h + 10
		g_roulette_pantitle.AddChild(TLabel.CreateLabel("lbl_even", "0", x, y, w, h, 3, "FFFFFF", "FFFFFF", 1.0, 1, 0, 1, 1, Null, 1, 0, 0, 0, "", 0))
		y :+ h + 10
		g_roulette_pantitle.AddChild(TLabel.CreateLabel("lbl_red", "0", x, y, w, h, 3, "FF0000", "FFFFFF", 1.0, 1, 0, 1, 1, Null, 1, 0, 0, 0, "", 0))
		y :+ h + 10
		g_roulette_pantitle.AddChild(TLabel.CreateLabel("lbl_black", "0", x, y, w, h, 3, "666666", "FFFFFF", 1.0, 1, 0, 1, 1, Null, 1, 0, 0, 0, "", 0))
		y :+ h + 10
		g_roulette_pantitle.AddChild(TLabel.CreateLabel("lbl_1to18", "0", x, y, w, h, 3, "FFFFFF", "FFFFFF", 1.0, 1, 0, 1, 1, Null, 1, 0, 0, 0, "", 0))
		y :+ h + 10
		g_roulette_pantitle.AddChild(TLabel.CreateLabel("lbl_19to36", "0", x, y, w, h, 3, "FFFFFF", "FFFFFF", 1.0, 1, 0, 1, 1, Null, 1, 0, 0, 0, "", 0))
		y :+ h + 10
		g_roulette_pantitle.AddChild(TLabel.CreateLabel("lbl_total1", GetText("Total"), x, y, w, 25, 2, "888888", "FFFFFF", 1.0, 2, 0, 1, 1, Null, 1, 0, 0, 0, "", 0))
		g_roulette_pantitle.AddChild(TLabel.CreateLabel("lbl_total2", "0", x, y + 25, w, 25, 2, "FFFFFF", "FFFFFF", 1.0, 3, 0, 1, 1, Null, 1, 0, 0, 0, "", 0))

		x :+ w + 10
		y = 110
		w = 160

		g_roulette_pantitle.AddChild(TButton.CreateButton("btn_odd", GetText("roulette_Odd"), x, y, w, h, 1, 3, "FFFFFF", "FFFFFF", Null, PlaceBet, 1.0, 1, ""))
		y :+ h + 10
		g_roulette_pantitle.AddChild(TButton.CreateButton("btn_even", GetText("roulette_Even"), x, y, w, h, 1, 3, "FFFFFF", "FFFFFF", Null, PlaceBet, 1.0, 1, ""))
		y :+ h + 10
		g_roulette_pantitle.AddChild(TButton.CreateButton("btn_red", GetText("roulette_Red"), x, y, w, h, 1, 3, "FFFFFF", "FFFFFF", Null, PlaceBet, 1.0, 1, ""))
		y :+ h + 10
		g_roulette_pantitle.AddChild(TButton.CreateButton("btn_black", GetText("roulette_Black"), x, y, w, h, 1, 3, "FFFFFF", "FFFFFF", Null, PlaceBet, 1.0, 1, ""))
		y :+ h + 10
		g_roulette_pantitle.AddChild(TButton.CreateButton("btn_1to18", GetText("roulette_1to18"), x, y, w, h, 1, 3, "FFFFFF", "FFFFFF", Null, PlaceBet, 1.0, 1, ""))
		y :+ h + 10
		g_roulette_pantitle.AddChild(TButton.CreateButton("btn_19to36", GetText("roulette_19to36"), x, y, w, h, 1, 3, "FFFFFF", "FFFFFF", Null, PlaceBet, 1.0, 1, ""))
		y :+ h + 10
		g_roulette_pantitle.AddChild(TButton.CreateButton("btn_clear", GetText("Clear Bets"), x, y, w, h, 1, 3, "FFFFFF", "FFFFFF", Null, ClearBets, 1.0, 1, ""))

		g_roulette_screen.AddGadget(TPanel.CreatePanel("navpanel", "", 0, g_screenheight - 60, g_screenwidth, 60, "FFFFFF", "FFFFFF", 3, 1.0, 0, 0, 0))
		g_roulette_btnQuit = TButton.CreateButton("btn_quit", "", 10, g_screenheight - 50, 120, 40, 1, 2, "FFFFFF", "FFFFFF", g_iconBack, TScreen_Casino.SetUpScreen, 1.0, 1, GetText("tt_Back"))
		g_roulette_btnPlay = TButton.CreateButton("btn_play", "", g_screenwidth - 130, g_screenheight - 50, 120, 40, 1, 2, "FFFFFF", "FFFFFF", g_img_play, ButtonPlay, 1.0, 1, GetText("tt_Play"))
		g_roulette_screen.AddGadget(g_roulette_btnQuit)
		g_roulette_screen.AddGadget(g_roulette_btnPlay)
	End Function
