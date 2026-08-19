' TScreen_BootShop.CreateScreen
' VA 0x00543214   1892 bytes   mode=reloc   byte-identical vs NSS5.exe
' (1892/1892, original length from Ghidra's inventory, reloc_masked=178; verified with
'  NSS5_NO_LEARN=1, so no call operand was masked by a name this run taught the table)
' KIND=Function (static, no implicit Self), SIG ()i, class-table slot 0x30
'
' Builds the "Match Preparation" boot-shop screen: a shared-shaped title bar (own
' pan_title, NOT the cross-screen shared Global -- see below) holding a "Bank" caption,
' the player's cash label and a help button; a bottom pan_nav holding a "Play" button;
' and the main pan_ShopBoots grid of 10 boot cells, each with a buy button (the boot's own
' icon), three stat-bonus labels (Dribbling/Passing/Shooting), a price label and a usage
' progress bar. SetUpScreen (already recovered) runs every frame's refresh of this same
' grid and independently corroborates several of the widget names below
' (lbl_boots+i, prg_boots+i, btn_boots+i, g_screen_bootshop, g_lbl_bootmoney).
'
' Raw disassembly was used throughout, NOT Ghidra's decompiled C -- the merged pseudo-C
' argument lists here fold a callee's own pushed args together with the following call's
' pre-staged pushes (same trap flagged in TScreen_Shop.CreateScreen's header). Every
' CreatePanel/CreateLabel/CreateButton/CreateProgressBar argument below was recovered by
' walking the actual push/call/`add esp,N` sequence and reversing chronological push order
' into declared parameter order (param 1 is always the LAST push before the call).
'
' ASSUMPTIONS
'   Module Globals -- ADDRESSES are fact (globals_final.tsv), NAMES are ours except where
'   an earlier recovered file already established one:
'     0x00C66E20 g_screen_bootshop:TScreen  -- SAME Global TScreen_BootShop.SetUpScreen uses
'     0x00C66E2C g_bootshop_img_boots:TImage[]  -- ten boot icons, index 0..9, loaded once
'       and cached (globals_final.tsv types it "Object[]", usage-only; every element is the
'       direct return of LoadImageChecked, so TImage, same reasoning as Shop's TImage[]s).
'     0x00C66E30 g_bootshop_pan_title:TPanel  -- BootShop's OWN title bar, name "pan_title".
'       Not the cross-screen shared g_pan_title Global TScreen_Shop/TScreen_GameMenu reuse
'       (that one lives at a different address and is never referenced here) -- BootShop
'       calls CreatePanel again for its own, matching-named panel.
'     0x00C66E34 g_bootshop_pan_nav:TPanel  -- BootShop's own bottom bar, name "pan_nav".
'     0x00C66E38 g_bootshop_pan_boots:TPanel  -- the main grid panel, name "pan_ShopBoots".
'     0x00C66E3C g_lbl_bootmoney:TLabel  -- SAME Global TScreen_BootShop.SetUpScreen uses
'       (that file's header independently names this address; SetUpScreen's own
'       `g_lbl_bootmoney.SetText(FormatMoney(g_profile.bank, 0), ...)` is exactly the label
'       this body constructs with a blank placeholder text).
'     0x00C6EFDC g_screen_int21:Int / 0x00C6EFE0 g_screen_int22:Int -- the established
'       screen-width/height Globals already named in TScreen.UpdateOffset and others.
'     0x00C6F2EC g_helpicon:TImage / 0x00C6F274 g_playicon:TImage -- shared icon Globals
'       (globals_final.tsv types 0x00C6F2EC generically "Object", usage-only; used here as
'       a TImage CreateButton argument). Names are ours.
'   Class-table slots (class_tables.tsv / vtable_map.tsv / globals_classtable_slots.tsv):
'     0x00C61C64 TScreen+0x38     CreateScreen($,:TImage,()i,()i):TScreen
'     0x00C63294 TPanel+0x88      CreatePanel($,$,i,i,i,i,$,$,i,f,i,i,i):TPanel
'     0x00C623CC TButton+0x88     CreateButton($,$,i,i,i,i,i,i,$,$,:TImage,()i,f,i,$):TButton
'     0x00C634C0 TLabel+0x88      CreateLabel($,$,i,i,i,i,i,$,$,f,i,i,i,i,:TImage,i,i,i,i,$,f):TLabel
'     0x00C637A8 TProgressBar+0x88 CreateProgressBar($,$,i,i,i,i,i,$,$,$,f,i,:TImage):TProgressBar
'     slot 0x40 on a TScreen = AddGadget(:TGadget)i ; slot 0x74 on a TGadget = AddChild
'     0x00C61CDC = TScreen+0xB0 ButtonHelp()i, read as a VALUE (callback), not called --
'       written unqualified via `TScreen.ButtonHelp` (guide 3d: cross-Type static reference).
'     0x00C66EF8 = TScreen_BootShop+0x38 ButtonBuy()i ; 0x00C66EFC = TScreen_BootShop+0x3C
'       ButtonPlay()i -- this Type's OWN table, read as VALUES for the two callback
'       parameters, written unqualified as sibling Functions (already-recovered files).
'   Module Functions: GetText, LoadImageChecked, FormatMoney, SponsorAmount (all already in
'     src/recovered_module), and the boot-bonus lookup table at 0x00507DDD, sig (i,i)i,
'     called GetBootBonus(bootTier, statSelector) here -- VERIFIED in the corpus at
'     src/recovered_module/GetBootBonus.bmx, 592/592. statSelector is 2/4/6 for
'     dribbling/passing/shooting, matching TScreen_MatchPrep.SetUpScreen's own use of the
'     identical table.
'
' NOTES ON SHAPE
'   * ORIGINAL QUIRK, reproduced as found (law 3): the first of the three per-boot stat
'     labels is NAMED "lbl_tackling"+i at runtime (GetGadgetByName-visible) but its TEXT is
'     the DRIBBLING bonus ("Dribbling +" + GetBootBonus(i,2)). The widget's internal name
'     does not match what it displays. This is exactly as disassembled -- both the literal
'     name string (0x00C88108 'lbl_tackling') and the literal text string (0x00C866D0
'     'Dribbling') are distinct addresses, unambiguously paired by the push order.
'   * The x/y/w Locals (edi/[ebp-4]/[ebp-8]) are set ONCE before the grid panel is created
'     (x=10, y=70, w=144), then immediately advanced by `y :+ 50 / x :+ 10` right after the
'     panel is stored and BEFORE AddGadget -- the same "header row offset" idiom
'     TScreen_Shop.CreateScreen uses (`y :+ 40 / x :+ 10`) after each of its three panels.
'     Missing this pair of statements was the exact -7 byte / 2-instruction gap the first
'     candidate diverged on (localise_diff.py GAP 1/1, ORIGINAL +965).
'   * `w:Int = 144` (0x90) is NEVER reassigned inside the loop -- read directly by five of
'     the six per-cell widgets, and as `w - 1` (143) for the buy button only, matching
'     Shop's analogous `w - 2` for its buttons (a narrower box than its container).
'   * `Local a:Int = 420` is read into eax and pushed once for CreatePanel's own p12 slot --
'     loaded through a register rather than emitted as a bare `push 0x1A4` (unlike every
'     neighbouring pure-literal argument in the same call), the same materialise-a-Local
'     tell TScreen_Shop.CreateScreen's header documents for its own `Local a`.
'   * Every per-cell gadget is AddChild'ed inline as the call's own argument (no
'     intermediate Local, no separate retain/release pair) -- same pattern as Shop's
'     lbl_bank/lbl_cash and its own grid rows.
'   * String literals read out of NSS5.exe with harness.read_string: "bootshop", ".png",
'     "GameMedia\Images\Shop\Boots\Boots_", "Match Preparation", "pan_title", "Bank",
'     "lbl_bank", "888888", "lbl_cash", "btn_help", "pan_nav", "btn_play", "Boots",
'     "pan_ShopBoots", "FFFFFF", " +", "Dribbling", "lbl_tackling", "Passing",
'     "lbl_passing", "Shooting", "lbl_shooting", "lbl_boots", "DDDDDD", "prg_boots",
'     "btn_boots", "00FF00". The empty-string addresses (0x005C7D40, 0x00C5D284) both
'     decode as None from read_string, matching the corpus-wide convention that the helper
'     returns None for the shared empty-BBString constant, not that the read failed.
	Function CreateScreen:Int()
		'!Global g_screen_bootshop:TScreen
		'!Global g_bootshop_img_boots:TImage[]
		'!Global g_bootshop_pan_title:TPanel
		'!Global g_bootshop_pan_nav:TPanel
		'!Global g_bootshop_pan_boots:TPanel
		'!Global g_lbl_bootmoney:TLabel
		'!Global g_screen_int21:Int
		'!Global g_screen_int22:Int
		'!Global g_helpicon:TImage
		'!Global g_playicon:TImage
		g_screen_bootshop = TScreen.CreateScreen("bootshop", Null, Null, Null)
		If Not g_bootshop_img_boots[0]
			For Local i:Int = 1 To 10
				g_bootshop_img_boots[i - 1] = LoadImageChecked("GameMedia\Images\Shop\Boots\Boots_" + i + ".png", -1)
			Next
		End If
		g_bootshop_pan_title = TPanel.CreatePanel("pan_title", GetText("Match Preparation"), 0, 0, g_screen_int21, 60, "FFFFFF", "FFFFFF", 4, 1.0, 0, 0, 1)
		g_screen_bootshop.AddGadget(g_bootshop_pan_title)
		g_bootshop_pan_title.AddChild(TLabel.CreateLabel("lbl_bank", GetText("Bank"), g_screen_int21 - 180, 10, 120, 20, 2, "FFFFFF", "FFFFFF", 1.0, 2, 0, 1, 1, Null, 1, 0, 0, 0, "", 0))
		g_lbl_bootmoney = TLabel.CreateLabel("lbl_cash", "", g_screen_int21 - 180, 30, 120, 20, 2, "888888", "FFFFFF", 1.0, 3, 0, 1, 1, Null, 1, 0, 0, 0, "", 0)
		g_bootshop_pan_title.AddChild(g_lbl_bootmoney)
		g_bootshop_pan_title.AddChild(TButton.CreateButton("btn_help", "", g_screen_int21 - 50, 10, 40, 40, 1, 2, "FFFFFF", "FFFFFF", g_helpicon, TScreen.ButtonHelp, 1.0, 1, ""))
		g_bootshop_pan_nav = TPanel.CreatePanel("pan_nav", "", 0, g_screen_int22 - 60, g_screen_int21, 60, "FFFFFF", "FFFFFF", 3, 1.0, 0, 0, 0)
		g_bootshop_pan_nav.AddChild(TButton.CreateButton("btn_play", "", g_screen_int21 - 130, g_screen_int22 - 50, 120, 40, 1, 2, "FFFFFF", "FFFFFF", g_playicon, ButtonPlay, 1.0, 1, ""))
		g_screen_bootshop.AddGadget(g_bootshop_pan_nav)
		Local a:Int = 420
		Local x:Int = 10
		Local y:Int = 70
		Local w:Int = 144
		g_bootshop_pan_boots = TPanel.CreatePanel("pan_ShopBoots", GetText("Boots"), x, y, 780, 40, "FFFFFF", "FFFFFF", 3, 0.8, 1, a, 0)
		y :+ 50
		x :+ 10
		g_screen_bootshop.AddGadget(g_bootshop_pan_boots)
		For Local i:Int = 1 To 10
			g_bootshop_pan_boots.AddChild(TButton.CreateButton("btn_boots" + i, "", x, y, w - 1, 85, 1, 2, "FFFFFF", "FFFFFF", g_bootshop_img_boots[i - 1], ButtonBuy, 0.25, 2, ""))
			g_bootshop_pan_boots.AddChild(TLabel.CreateLabel("lbl_tackling" + i, GetText("Dribbling") + " +" + GetBootBonus(i, 2), x, y + 80, w, 25, 2, "FFFFFF", "FFFFFF", 1.0, 0, 0, 1, 1, Null, 1, 0, 0, 0, "", 0))
			g_bootshop_pan_boots.AddChild(TLabel.CreateLabel("lbl_passing" + i, GetText("Passing") + " +" + GetBootBonus(i, 4), x, y + 105, w, 25, 2, "FFFFFF", "FFFFFF", 1.0, 0, 0, 1, 1, Null, 1, 0, 0, 0, "", 0))
			g_bootshop_pan_boots.AddChild(TLabel.CreateLabel("lbl_shooting" + i, GetText("Shooting") + " +" + GetBootBonus(i, 6), x, y + 130, w, 25, 2, "FFFFFF", "FFFFFF", 1.0, 0, 0, 1, 1, Null, 1, 0, 0, 0, "", 0))
			g_bootshop_pan_boots.AddChild(TLabel.CreateLabel("lbl_boots" + i, FormatMoney(SponsorAmount(i), 1), x, y + 155, w, 40, 3, "888888", "FFFFFF", 1.0, 3, 0, 1, 1, Null, 1, 0, 0, 0, "", 0))
			g_bootshop_pan_boots.AddChild(TProgressBar.CreateProgressBar("prg_boots" + i, "", x, y + 155, w, 40, 2, "DDDDDD", "00FF00", "FFFFFF", 1.0, 3, Null))
			x :+ w + 10
			If i = 5
				x = 20
				y :+ 205
			End If
		Next
	End Function
