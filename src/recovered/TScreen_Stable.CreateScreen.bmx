' TScreen_Stable.CreateScreen  -- KIND=Function (static, no implicit Self)
' VA 0x005866A6   4840 bytes   mode=reloc   byte-identical vs NSS5.exe
' KIND=Function, SIG ()i, class-table slot 0x30
' Verified 4840/4840 (original length from Ghidra's inventory), reloc_masked=473, and
' re-verified MATCH under NSS5_NO_LEARN=1 (learned_helpers=None), so no call operand was
' masked by a name this body taught the table.
'
' ASSUMPTIONS
'   Every Global name below is OURS (module Globals have no debug record). The declared
'   TYPE is load-bearing -- it selects the vtable slot for calls made through it.
'     0x00C6DF20 g_stable_sndFlash:TSound        <- LoadSoundChecked construction site
'     0x00C6DF24 g_stable_sndGallop:TSound       <- LoadSoundChecked construction site
'     0x00C6DEA4 g_stable_imgStable:TImage       <- LoadImageChecked construction site
'     0x00C6DEA8 g_stable_imgPlayRace:TImage     <- LoadImageChecked construction site
'     0x00C6DEAC g_stable_imgStar:TImage         <- LoadImageChecked construction site
'     0x00C6DF30 g_stable_imgBg:TImage           <- brl.max2d LoadImage construction site
'     0x00C6DF34 g_stable_imgGrass:TImage        <- LoadImage construction site
'     0x00C6DF44 g_stable_imgPost:TImage[]       <- 7 slots written [0..6]; BBArray data +0x18
'     0x00C6DF38 g_stable_imgRailing:TImage      <- LoadImage construction site
'     0x00C6DF48 g_stable_imgFinishLine:TImage   <- LoadImage construction site
'     0x00C6DEA0 g_screen_stable:TScreen         <- TScreen.CreateScreen construction site
'     0x00C66768 g_pan_title:TPanel              <- globals_final.tsv, construction-typed;
'                     only READ here. TScreen_GameMenu.CreateScreen builds it as
'                     TPanel.CreatePanel("pan_title", ...) and fourteen other screens
'                     read the same slot. g_pan_money is the corpus's name for the
'                     NEIGHBOURING slot 0x00C667B0, the nav panel TScreen_GameMenu
'                     builds as "pan_nav", so spelling this one g_pan_money put two
'                     slots on one emitted variable and this AddGadget attached the
'                     nav panel to the stable screen instead of the title bar. The
'                     original touches 0x00C66768 here and never 0x00C667B0.
'     0x00C6DEB0 g_stable_panNav:TPanel          <- TPanel.CreatePanel construction site
'     0x00C6DEB4 g_stable_btnHome:TButton        <- TButton.CreateButton construction site
'     0x00C6DEB8 g_stable_btnStable:TButton      <- ditto
'     0x00C6DEBC g_stable_btnStartRace:TButton   <- ditto
'     0x00C6DEC0 g_stable_panOwned:TPanel        <- CreatePanel construction site
'     0x00C6DEC8 g_stable_tblOwned:TTable        <- CreateTable construction site.
'                     globals_final.tsv flags a TLabel/TTable CONFLICT here; the class-table
'                     pointer at the construction site is TTable+0x88 = CreateTable, and
'                     slot 0x90 = TTable.AddColumn(i,$,$,$,i) is used on it five times.
'     0x00C6DECC/D0/D4 g_stable_btnSellHorse / btnTreatHorse / btnRaceHorse : TButton
'     0x00C6DED8 g_stable_panBuyHorse:TPanel     <- CreatePanel construction site
'     0x00C6DEDC g_stable_tblBuyHorse:TTable     <- CreateTable construction site
'     0x00C6DEE0 g_stable_btnBuyHorse:TButton    <- CreateButton construction site
'     0x00C6DEE4 g_stable_panRace:TPanel         <- CreatePanel construction site
'     0x00C6DEE8 g_stable_panStake:TPanel        <- CreatePanel construction site
'     0x00C6DEF4 g_stable_lblOdds:TLabel[]       <- CreateLabel results, 6 slots [0..5]
'     0x00C6DF04 g_stable_btnHorse:TButton[]     <- CreateButton results, 6 slots [0..5]
'     0x00C6E950 g_path:String        the shared asset-path prefix (same Global as
'                     TPair_Icon.CreateAll / TSlotMachine.SetUp); its load-time value is
'                     the module empty string 0x00C5D284
'     0x00C6F170 g_iconPath:String    the button-icon path prefix (load-time value
'                     0x005C7D40); globals_final.tsv calls it Int -- it is a String,
'                     it is the left operand of _bbStringConcat three times here
'     0x00C6EFDC g_screenWidth:Int    bare dword read, no refcount traffic
'     0x00C6EFE0 g_screenHeight:Int   bare dword read, no refcount traffic
'     0x00C6F194 g_iconHome:TImage    passed in CreateButton's :TImage slot
'     0x00C6E91C g_colourSelected:String   load-time value 0x00C6E904 = "00FF00"; used as
'                     btn_stake1's colour where the other six stake buttons pass "FFFFFF"
'
'   Class-table slots resolved through class_tables.tsv / vtable_map.tsv:
'     0x00C61C64 = TScreen+0x38 = CreateScreen ($,:TImage,()i,()i):TScreen
'     0x00C623CC = TButton+0x88 = CreateButton ($,$,i,i,i,i,i,i,$,$,:TImage,()i,f,i,$)
'     0x00C63294 = TPanel+0x88  = CreatePanel  ($,$,i,i,i,i,$,$,i,f,i,i,i)
'     0x00C634C0 = TLabel+0x88  = CreateLabel  ($,$,i,i,i,i,i,$,$,f,i,i,i,i,:TImage,i,i,i,i,$,f)
'     0x00C62BAC = TTable+0x88  = CreateTable  ($,i,i,i,i,i,i,$,f,i,()i)
'     0x00C6E7FC = THorse+0x74  = GetHorseColour (i)$
'     slot 0x40 on a TScreen  = TScreen.AddGadget (:TGadget)i
'     slot 0x74 on a TPanel   = TGadget.AddChild  (:TGadget)i   (inherited)
'     slot 0x90 on a TTable   = TTable.AddColumn  (i,$,$,$,i)i
'     0x00C6E24C/50/54/5C/60/70/74/88/8C/90 = TScreen_Stable+0x44/48/4C/54/58/68/74/80/84/88
'       = ButtonQuit / ButtonStable / ButtonRace / SetStake / ButtonHorse / Draw /
'         ButtonBuyHorse / ButtonSellHorse / ButtonTreatHorse / ButtonRaceHorse.
'       Same Type -> bare names, no `TScreen_Stable.` prefix.
'
'   Module Functions called (all already recovered, in src/recovered_module/):
'     GetText 0x004C5549, FormatMoney 0x0050720B, LoadImageChecked 0x004BC372,
'     LoadSoundChecked 0x004BC564.  NOTE both loader files carry a "NOT CERTIFIED"
'     banner of their own; that is inherited context, not a claim made here.
'
'   BRL: 0x005AE256 = LoadImage, 0x005AE336 = SetImageHandle.
'
'   String literals were all read out of the exe with harness.read_string -- the oracle
'   masks a literal's ADDRESS, so their CONTENTS are not covered by the MATCH.
'
'   UNRESOLVED, and not decidable by the oracle: the original uses TWO distinct empty
'   BBStrings -- 0x005C7D40 and 0x00C5D284 (the latter is [class,refs=0x7FFFFFFF,len=0],
'   a textbook immortal ""). Both appear as ordinary `$` arguments in this function, e.g.
'   btn_StableHome's caption is 0x005C7D40 while btn_StartRace's is 0x00C5D284. Both are
'   written `""` here; whatever source-level distinction produced two objects (most likely
'   an omitted optional parameter vs. an explicit literal) is unrecovered. Address masking
'   makes the two indistinguishable to a MATCH, so this cannot be settled with the oracle.
'
' SHAPE NOTES (each cost a byte-observable decision)
'   * The asset guard is `If Not g` -- cmp/setne/movzx/cmp/jne, the 21-byte form of §10.3,
'     not the 12-byte `If g = Null`.
'   * Both For loops are `To 6` (cmp ebx,6 / jle), not `Until 7`.
'   * The layout numbers are Locals, not literals: bcc does no constant hoisting, so the
'     original's `push [ebp-8]` proves a Local. h is REUSED across three groups (40 for the
'     nav bar, 60 in the race loop, 50 for the stake column) rather than redeclared.
'   * Row advance is `y :+ h + 10` (mov eax,[h] / add eax,0xa / add edi,eax), never the
'     folded constant -- folding it costs 2 bytes per row.
'   * In the race loop the columns are `x`, `x + cw`, `x + cw + cw` -- recomputed each time,
'     because bcc does no CSE.
'   * pan_stake is created, then x/y/w are adjusted, and ONLY THEN is it AddGadget-ed. That
'     ordering is in the bytes (0x005876A5..0x005876C7); it is not a tidy-up opportunity.
'   * lbl_Horse's caption argument is the loop counter passed straight into a `$` parameter
'     (bcc emits _bbStringFromInt for it).
'   * `Null` in a `()i` parameter lowers to the empty function 0x005B95D0; `Null` in a
'     `:TImage` parameter lowers to bbNullObject 0x005C9C80. Both are written `Null`.
'!Global g_stable_sndFlash:TSound
'!Global g_stable_sndGallop:TSound
'!Global g_stable_imgStable:TImage
'!Global g_stable_imgPlayRace:TImage
'!Global g_stable_imgStar:TImage
'!Global g_stable_imgBg:TImage
'!Global g_stable_imgGrass:TImage
'!Global g_stable_imgPost:TImage[]
'!Global g_stable_imgRailing:TImage
'!Global g_stable_imgFinishLine:TImage
'!Global g_screen_stable:TScreen
'!Global g_pan_title:TPanel
'!Global g_stable_panNav:TPanel
'!Global g_stable_btnHome:TButton
'!Global g_stable_btnStable:TButton
'!Global g_stable_btnStartRace:TButton
'!Global g_stable_panOwned:TPanel
'!Global g_stable_tblOwned:TTable
'!Global g_stable_btnSellHorse:TButton
'!Global g_stable_btnTreatHorse:TButton
'!Global g_stable_btnRaceHorse:TButton
'!Global g_stable_panBuyHorse:TPanel
'!Global g_stable_tblBuyHorse:TTable
'!Global g_stable_btnBuyHorse:TButton
'!Global g_stable_panRace:TPanel
'!Global g_stable_panStake:TPanel
'!Global g_stable_lblOdds:TLabel[]
'!Global g_stable_btnHorse:TButton[]
'!Global g_path:String
'!Global g_iconPath:String
'!Global g_screenWidth:Int
'!Global g_screenHeight:Int
'!Global g_iconHome:TImage
'!Global g_colourSelected:String
	Function CreateScreen()
		If Not g_stable_sndFlash
			g_stable_sndFlash = LoadSoundChecked(g_path + "GameMedia/Sounds/Casino/FlashBulb.ogg", 0)
			g_stable_sndGallop = LoadSoundChecked(g_path + "GameMedia/Sounds/Casino/Gallop.ogg", 1)
			g_stable_imgStable = LoadImageChecked(g_iconPath + "Stable.png", -1)
			g_stable_imgPlayRace = LoadImageChecked(g_iconPath + "PlayRace.png", -1)
			g_stable_imgStar = LoadImageChecked(g_iconPath + "Star.png", -1)
			g_stable_imgBg = LoadImage(g_path + "GameMedia/Images/Stable/Bg.png")
			g_stable_imgGrass = LoadImage(g_path + "GameMedia/Images/Stable/Grass.png")
			g_stable_imgPost[0] = LoadImage(g_path + "GameMedia/Images/Stable/FinishPost.png")
			SetImageHandle(g_stable_imgPost[0], 37, 140)
			g_stable_imgPost[1] = LoadImage(g_path + "GameMedia/Images/Stable/Post_1.png")
			g_stable_imgPost[2] = LoadImage(g_path + "GameMedia/Images/Stable/Post_2.png")
			g_stable_imgPost[3] = LoadImage(g_path + "GameMedia/Images/Stable/Post_3.png")
			g_stable_imgPost[4] = LoadImage(g_path + "GameMedia/Images/Stable/Post_4.png")
			g_stable_imgPost[5] = LoadImage(g_path + "GameMedia/Images/Stable/Post_5.png")
			g_stable_imgPost[6] = LoadImage(g_path + "GameMedia/Images/Stable/Post_6.png")
			g_stable_imgRailing = LoadImage(g_path + "GameMedia/Images/Stable/Railing_01.png")
			For Local i:Int = 1 To 6
				SetImageHandle(g_stable_imgPost[i], 12, 63)
			Next
			g_stable_imgFinishLine = LoadImage(g_path + "GameMedia/Images/Stable/FinishLine.png")
		EndIf
		g_screen_stable = TScreen.CreateScreen("stable", Null, Draw, Update)
		g_screen_stable.AddGadget(g_pan_title)
		g_stable_panNav = TPanel.CreatePanel("pan_nav", "", 0, g_screenHeight - 60, g_screenWidth, 60, "FFFFFF", "FFFFFF", 3, 1.0, 0, 0, 0)
		g_screen_stable.AddGadget(g_stable_panNav)
		Local h:Int = 40
		g_stable_btnHome = TButton.CreateButton("btn_StableHome", "", 10, g_screenHeight - 50, 100, h, 1, 2, "FFFFFF", "FFFFFF", g_iconHome, ButtonQuit, 1.0, 1, "")
		g_stable_btnStable = TButton.CreateButton("btn_StableStable", GetText("My Stable"), 520, g_screenHeight - 50, 140, h, 1, 3, "FFFFFF", "FFFFFF", g_stable_imgStable, ButtonStable, 1.0, 1, "")
		g_stable_btnStartRace = TButton.CreateButton("btn_StartRace", "", 670, g_screenHeight - 50, 120, h, 1, 2, "FFFFFF", "FFFFFF", g_stable_imgPlayRace, ButtonRace, 1.0, 1, GetText("tt_StartRace"))
		g_stable_panNav.AddChild(g_stable_btnHome)
		g_stable_panNav.AddChild(g_stable_btnStable)
		g_stable_panNav.AddChild(g_stable_btnStartRace)
		g_stable_panOwned = TPanel.CreatePanel("pan_Owned", GetText("My Stable"), 405, 70, 385, 30, "FFFFFF", "FFFFFF", 3, 0.8, 1, 430, 0)
		g_screen_stable.AddGadget(g_stable_panOwned)
		g_stable_panOwned.AddChild(TLabel.CreateLabel("lbl_Stable", GetText("Stable Size"), 415, 110, 225, 40, 3, "888888", "FFFFFF", 1.0, 4, 1, 0, 1, Null, 1, 0, 0, 0, "", 0))
		g_stable_panOwned.AddChild(TLabel.CreateLabel("lbl_StableSize", "0", 640, 110, 140, 40, 3, "FFFFFF", "FFFFFF", 1.0, 5, 1, 0, 1, Null, 1, 0, 0, 0, "", 0))
		g_stable_tblOwned = TTable.CreateTable("tbl_Owned", 405, 160, 10, 0, 1, 2, "00FF00", 1.0, 1, Null)
		g_stable_tblOwned.AddColumn(141, GetText("Name"), "000000", "FFFFFF", 2)
		g_stable_tblOwned.AddColumn(50, GetText("Energy"), "000000", "EEEEEE", 1)
		g_stable_tblOwned.AddColumn(50, GetText("Health"), "000000", "DDDDDD", 1)
		g_stable_tblOwned.AddColumn(70, GetText("Form"), "000000", "EEEEEE", 1)
		g_stable_tblOwned.AddColumn(70, GetText("Prizes"), "000000", "DDDDDD", 1)
		g_stable_panOwned.AddChild(g_stable_tblOwned)
		g_stable_btnSellHorse = TButton.CreateButton("btn_SellHorse", GetText("Sell Horse"), 415, 410, 365, 30, 1, 3, "FFFFFF", "FFFFFF", Null, ButtonSellHorse, 1.0, 1, "")
		g_stable_btnTreatHorse = TButton.CreateButton("btn_TreatHorse", GetText("Treat Horse"), 415, 450, 365, 30, 1, 3, "FFFFFF", "FFFFFF", Null, ButtonTreatHorse, 1.0, 1, "")
		g_stable_btnRaceHorse = TButton.CreateButton("btn_RaceHorse", GetText("Race Horse"), 415, 490, 365, 30, 1, 3, "FFFFFF", "FFFFFF", Null, ButtonRaceHorse, 1.0, 1, "")
		g_stable_panOwned.AddChild(g_stable_btnSellHorse)
		g_stable_panOwned.AddChild(g_stable_btnTreatHorse)
		g_stable_panOwned.AddChild(g_stable_btnRaceHorse)
		g_stable_panBuyHorse = TPanel.CreatePanel("pan_BuyHorse", GetText("Horses For Sale"), 10, 70, 385, 30, "FFFFFF", "FFFFFF", 3, 0.8, 1, 430, 0)
		g_screen_stable.AddGadget(g_stable_panBuyHorse)
		g_stable_tblBuyHorse = TTable.CreateTable("tbl_BuyHorse", 10, 100, 18, 0, 1, 2, "00FF00", 1.0, 1, Null)
		g_stable_tblBuyHorse.AddColumn(141, GetText("Name"), "000000", "FFFFFF", 2)
		g_stable_tblBuyHorse.AddColumn(50, GetText("Health"), "000000", "EEEEEE", 1)
		g_stable_tblBuyHorse.AddColumn(70, GetText("Form"), "000000", "DDDDDD", 1)
		g_stable_tblBuyHorse.AddColumn(60, GetText("Prizes"), "000000", "EEEEEE", 1)
		g_stable_tblBuyHorse.AddColumn(60, GetText("Value"), "000000", "DDDDDD", 1)
		g_stable_panBuyHorse.AddChild(g_stable_tblBuyHorse)
		g_stable_btnBuyHorse = TButton.CreateButton("btn_BuyHorse", GetText("Buy Horse"), 20, 490, 365, 30, 1, 3, "FFFFFF", "FFFFFF", Null, ButtonBuyHorse, 1.0, 1, "")
		g_stable_panBuyHorse.AddChild(g_stable_btnBuyHorse)
		g_stable_panRace = TPanel.CreatePanel("pan_Race", GetText("Race"), 220, 70, 570, 30, "FFFFFF", "FFFFFF", 3, 0.8, 1, 430, 0)
		g_screen_stable.AddGadget(g_stable_panRace)
		Local x:Int = 230
		Local y:Int = 110
		Local cw:Int = 95
		Local w:Int = 360
		h = 60
		For Local i:Int = 1 To 6
			g_stable_panRace.AddChild(TLabel.CreateLabel("lbl_Horse" + i, i, x, y, cw, h, 4, THorse.GetHorseColour(i), "FFFFFF", 1.0, 4, 1, 0, 1, Null, 1, 0, 0, 0, "", 0))
			g_stable_lblOdds[i - 1] = TLabel.CreateLabel("lbl_Odds" + i, "", x + cw, y, cw, h, 3, "AAAAAA", "FFFFFF", 1.0, 0, 1, 0, 1, Null, 1, 0, 0, 0, "", 0)
			g_stable_btnHorse[i - 1] = TButton.CreateButton("btn_Horse" + i, "Horse " + i, x + cw + cw, y, w, h - 1, 1, 3, "FFFFFF", THorse.GetHorseColour(i), Null, ButtonHorse, 1.0, 5, "")
			y :+ h + 10
			g_stable_panRace.AddChild(g_stable_lblOdds[i - 1])
			g_stable_panRace.AddChild(g_stable_btnHorse[i - 1])
		Next
		x = 10
		y = 70
		w = 200
		h = 50
		g_stable_panStake = TPanel.CreatePanel("pan_stake", GetText("casino_Stake"), x, y, w, 30, "FFFFFF", "FFFFFF", 3, 0.8, 1, 430, 0)
		x :+ 10
		y :+ 40
		w :- 20
		g_screen_stable.AddGadget(g_stable_panStake)
		g_stable_panStake.AddChild(TButton.CreateButton("btn_stake1", FormatMoney(50, 0), x, y, w, h, 1, 3, g_colourSelected, "FFFFFF", Null, SetStake, 1.0, 1, ""))
		y :+ h + 10
		g_stable_panStake.AddChild(TButton.CreateButton("btn_stake2", FormatMoney(100, 0), x, y, w, h, 1, 3, "FFFFFF", "FFFFFF", Null, SetStake, 1.0, 1, ""))
		y :+ h + 10
		g_stable_panStake.AddChild(TButton.CreateButton("btn_stake3", FormatMoney(250, 0), x, y, w, h, 1, 3, "FFFFFF", "FFFFFF", Null, SetStake, 1.0, 1, ""))
		y :+ h + 10
		g_stable_panStake.AddChild(TButton.CreateButton("btn_stake4", FormatMoney(500, 0), x, y, w, h, 1, 3, "FFFFFF", "FFFFFF", Null, SetStake, 1.0, 1, ""))
		y :+ h + 10
		g_stable_panStake.AddChild(TButton.CreateButton("btn_stake5", FormatMoney(1000, 0), x, y, w, h, 1, 3, "FFFFFF", "FFFFFF", Null, SetStake, 1.0, 1, ""))
		y :+ h + 10
		g_stable_panStake.AddChild(TButton.CreateButton("btn_stake6", FormatMoney(2500, 0), x, y, w, h, 1, 3, "FFFFFF", "FFFFFF", Null, SetStake, 1.0, 1, ""))
		y :+ h + 10
		g_stable_panStake.AddChild(TButton.CreateButton("btn_stake7", FormatMoney(5000, 0), x, y, w, h, 1, 3, "FFFFFF", "FFFFFF", Null, SetStake, 1.0, 1, ""))
	End Function
