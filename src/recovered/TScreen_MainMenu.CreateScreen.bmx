' TScreen_MainMenu.CreateScreen
' VA 0x0051C0C7   3235 bytes   mode=reloc   byte-identical vs NSS5.exe
' KIND=Function (static, no implicit Self), SIG ()i, class-table slot 0x30
' Verified 3235/3235 (original length from Ghidra's inventory), reloc_masked=325, and
' re-verified MATCH under NSS5_NO_LEARN=1 (learned_helpers=None), so no call operand was
' masked by a name this body taught the helper table.
'
' ASSUMPTIONS
'   Module Globals: the ADDRESSES are fact, the NAMES are ours (module Globals have no
'   debug record). The declared TYPE is load-bearing -- it selects the vtable slot for
'   every call made through it.
'     0x00C6398C g_mainmenu_screen:TScreen      <- TScreen.CreateScreen construction site
'     0x00C63994 g_mainmenu_imgStar:TImage      <- LoadImageChecked("...Star.png")
'     0x00C63998 g_mainmenu_imgReplays:TImage   <- LoadImageChecked("...Replays.png")
'     0x00C639A4 g_mainmenu_imgArrow:TImage     <- LoadImageChecked("...ArrowD.png")
'     0x00C6399C g_mainmenu_imgBoot:TImage      <- LoadImageChecked("...Boot22.png")
'     0x00C639A0 g_mainmenu_imgOptions:TImage   <- LoadImageChecked("...Options.png")
'     0x00C639A8 g_mainmenu_imgOffline:TImage   <- LoadImageChecked("...Offline.png")
'     0x00C639B4 g_mainmenu_imgHome:TImage      <- LoadImageChecked("...Home20.png")
'     0x00C639B8 g_mainmenu_imgFacebook:TImage  <- LoadImageChecked("...Facebook.png")
'     0x00C639BC g_mainmenu_imgTwitter:TImage   <- LoadImageChecked("...Twitter.png")
'     0x00C639C0 g_mainmenu_imgMobile:TImage    <- LoadImageChecked("...Mobile.png")
'     0x00C639AC g_mainmenu_panBack:TPanel      <- TPanel.CreatePanel construction site;
'                     its Float field +0x24 (TGadget.y) is read three times here
'     0x00C639B0 g_mainmenu_panSocial:TPanel    <- CreatePanel construction site
'     0x00C639D8 g_mainmenu_panLoadGame:TPanel  <- CreatePanel construction site
'     0x00C639E0 g_mainmenu_panLoadReplay:TPanel<- CreatePanel construction site
'     0x00C639DC g_mainmenu_tblLoadGame:TTable  <- CreateTable construction site
'                     (globals_final.tsv names this g_screen_mainmenu_tplayer01; slot 0x90
'                      = TTable.AddColumn is used on it twice, so TTable is right)
'     0x00C639E4 g_mainmenu_tblLoadReplay:TTable<- CreateTable construction site
'     0x00C639E8 g_mainmenu_lblVersion:TLabel   <- TLabel.CreateLabel construction site
'     0x00C639C4 g_mainmenu_btnHome:TButton     <- CreateButton construction site
'     0x00C639CC g_mainmenu_btnFacebook:TButton <- ditto
'     0x00C639C8 g_mainmenu_btnTwitter:TButton  <- ditto
'     0x00C639D0 g_mainmenu_btnMobile:TButton   <- ditto
'                     NOTE the store order is Home/Facebook/Twitter/Mobile ->
'                     C4/CC/C8/D0 -- Twitter and Facebook are NOT in address order.
'     0x00C6F254 g_imgQuit:TImage    only READ here, passed in CreateButton's :TImage slot
'     0x00C6F170 g_iconPath:String   the button-icon path prefix; globals_final.tsv calls
'                     it Int -- it is a String, it is the LEFT operand of _bbStringConcat
'                     ten times in this function (same Global as TScreen_Stable's)
'     0x00C6E900 g_version:String    right operand of _bbStringConcat with "v";
'                     globals_final.tsv calls it Int, which is wrong for the same reason
'     0x00C6EFE0 g_screenHeight:Int  bare dword read, no refcount traffic
'
'   Class-table slots resolved through class_tables.tsv / vtable_map.tsv:
'     0x00C61C64 = TScreen+0x38 = CreateScreen ($,:TImage,()i,()i):TScreen
'     0x00C623CC = TButton+0x88 = CreateButton ($,$,i,i,i,i,i,i,$,$,:TImage,()i,f,i,$)
'     0x00C63294 = TPanel+0x88  = CreatePanel  ($,$,i,i,i,i,$,$,i,f,i,i,i)
'     0x00C634C0 = TLabel+0x88  = CreateLabel  ($,$,i,i,i,i,i,$,$,f,i,i,i,i,:TImage,i,i,i,i,$,f)
'     0x00C62BAC = TTable+0x88  = CreateTable  ($,i,i,i,i,i,i,$,f,i,()i)
'     0x00C64060 = TScreen_Options+0x34 = SetUpScreen ()i  (cross-Type -> qualified name)
'     slot 0x40 on a TScreen = TScreen.AddGadget (:TGadget)i
'     slot 0x74 on a TPanel  = TGadget.AddChild  (:TGadget)i   (inherited)
'     slot 0x54 on a TPanel  = TGadget.Hide      ()i          (inherited)
'     slot 0x90 on a TTable  = TTable.AddColumn  (i,$,$,$,i)i
'     0x00C63CA4/A8/AC/B0/B4/BC/C0/C4/CC/D0/D8/DC/E0/E4 = TScreen_MainMenu+0x38/3C/40/44/
'       48/50/54/58/60/64/6C/70/74/78 = LoadCredits / Update / ButtonQuit / NewGame /
'       ButtonLoadGame / ButtonLoadSaveFile / ButtonDeleteSaveFile / ButtonReplays /
'       ButtonLoadReplayFile / ButtonDeleteReplayFile / ButtonHome / ButtonFacebook /
'       ButtonTwitter / ButtonMobile.  Same Type -> bare names, no `TScreen_MainMenu.`.
'
'   Module Functions called (both already recovered, in src/recovered_module/):
'     GetText 0x004C5549, LoadImageChecked 0x004BC372.
'   Runtime: 0x004A7C20 _bbStringConcat, 0x004A8590 GC free (inlined BBRELEASE, never
'   written in source), 0x005B9690 _bbFloatToInt (emitted implicitly for every Float->Int
'   assignment), 0x005B95D0 = the empty function that `Null` lowers to in a `()i` slot.
'
'   String literals were all read out of NSS5.exe with harness.read_string -- the oracle
'   masks a literal's ADDRESS, so their CONTENTS are not certified by the MATCH.  Both
'   0x005C7D40 and 0x00C5D284 are zero-length BBStrings, i.e. ""; bcc picks a different
'   empty-string constant per argument slot and the source is "" either way.
'
' SHAPE NOTES (each is byte-observable and was read off the disassembly)
'   * The asset guard is `If Not g_mainmenu_imgStar` -- mov/cmp/setne/movzx/cmp/jne, the
'     21-byte form of section 10.3, not the 12-byte `If g = Null`.  All TEN loads sit
'     inside it: the jne target is 0x0051C388 and the last store ends exactly there.
'     (The annotated decompilation prints the Mobile.png store outside the block; that is
'      a decompiler artifact, the bytes put it inside.)
'   * Four Locals -- x, y, w, h -- declared once and REASSIGNED per section.  bcc gives
'     x and h stack slots ([ebp-8], [ebp-4]) and y and w registers (edi, ebx); esi is a
'     compiler temp holding the AddGadget/AddChild receiver, not a Local.
'   * `w / 2` for the version label is the signed-divide idiom cdq/and edx,1/add/sar 1.
'   * backpanel's height is `(h + 10) * 5 + 10` -- add 0xa / imul 5 / add 0xa, written out
'     rather than folded to 260, because bcc does no constant folding across a Local.
'   * The two `CreatePanel` calls for the load panels pass LITERAL 30 in the height slot
'     and LITERAL 230 in argument 12, even though w and h hold exactly those values in
'     registers at that moment -- the bytes are `push 0x1e` / `push 0xe6`, not `push ebx`
'     / `push [ebp-4]`.  Substituting the Locals changes the encoding.
'   * `y :+ 30` happens BETWEEN creating a load panel and AddGadget-ing it (0x0051C730),
'     and `x :+ 5 / y :+ 5` happen between creating pan_Social and adding it.  That
'     ordering is in the bytes; it is not a tidy-up opportunity.
'   * The button-row step is `y :+ h + 10` (mov eax,[h] / add 0xa / add edi,eax) and the
'     load-panel button step is `x :+ w + 10` (mov eax,ebx / add 0xa / add [x],eax).
'     Folding either to a constant costs 2 bytes.
'   * pan_Social's y is `g_mainmenu_panBack.y + 10.0` -- fld [eax+0x24] / fadd 10.0 /
'     _bbFloatToInt.  The other two are the bare field, no addition.
'   * `LoadCredits()` is a sibling Function reached through this Type's own class table
'     (0x00C63CA4), so it is written bare with no `TScreen_MainMenu.` prefix.
'!Global g_mainmenu_screen:TScreen
'!Global g_mainmenu_imgStar:TImage
'!Global g_mainmenu_imgReplays:TImage
'!Global g_mainmenu_imgArrow:TImage
'!Global g_mainmenu_imgBoot:TImage
'!Global g_mainmenu_imgOptions:TImage
'!Global g_mainmenu_imgOffline:TImage
'!Global g_mainmenu_imgHome:TImage
'!Global g_mainmenu_imgFacebook:TImage
'!Global g_mainmenu_imgTwitter:TImage
'!Global g_mainmenu_imgMobile:TImage
'!Global g_mainmenu_panBack:TPanel
'!Global g_mainmenu_panSocial:TPanel
'!Global g_mainmenu_panLoadGame:TPanel
'!Global g_mainmenu_panLoadReplay:TPanel
'!Global g_mainmenu_tblLoadGame:TTable
'!Global g_mainmenu_tblLoadReplay:TTable
'!Global g_mainmenu_lblVersion:TLabel
'!Global g_mainmenu_btnHome:TButton
'!Global g_mainmenu_btnFacebook:TButton
'!Global g_mainmenu_btnTwitter:TButton
'!Global g_mainmenu_btnMobile:TButton
'!Global g_imgQuit:TImage
'!Global g_iconPath:String
'!Global g_version:String
'!Global g_screenHeight:Int
	Function CreateScreen()
		g_mainmenu_screen = TScreen.CreateScreen("mainmenu", LoadImageChecked("GameMedia/Images/Backgrounds/MyBg.png", -1), Null, Update)
		If Not g_mainmenu_imgStar
			g_mainmenu_imgStar = LoadImageChecked(g_iconPath + "Star.png", -1)
			g_mainmenu_imgReplays = LoadImageChecked(g_iconPath + "Replays.png", -1)
			g_mainmenu_imgArrow = LoadImageChecked(g_iconPath + "ArrowD.png", -1)
			g_mainmenu_imgBoot = LoadImageChecked(g_iconPath + "Boot22.png", -1)
			g_mainmenu_imgOptions = LoadImageChecked(g_iconPath + "Options.png", -1)
			g_mainmenu_imgOffline = LoadImageChecked(g_iconPath + "Offline.png", -1)
			g_mainmenu_imgHome = LoadImageChecked(g_iconPath + "Home20.png", -1)
			g_mainmenu_imgFacebook = LoadImageChecked(g_iconPath + "Facebook.png", -1)
			g_mainmenu_imgTwitter = LoadImageChecked(g_iconPath + "Twitter.png", -1)
			g_mainmenu_imgMobile = LoadImageChecked(g_iconPath + "Mobile.png", -1)
		EndIf
		Local x:Int = 10
		Local y:Int = g_screenHeight - 50
		Local w:Int = 253
		Local h:Int = 40
		g_mainmenu_lblVersion = TLabel.CreateLabel("lbl_myversion", "v" + g_version, x, y, w / 2, h, 3, "888888", "FFFFFF", 1.0, 1, 0, 1, 1, Null, 1, 0, 0, 0, "", 0)
		g_mainmenu_screen.AddGadget(g_mainmenu_lblVersion)
		x = 285
		y = 250
		w = 230
		h = 40
		g_mainmenu_panBack = TPanel.CreatePanel("backpanel", "", x, y, w, (h + 10) * 5 + 10, "FFFFFF", "FFFFFF", 3, 0.8, 1, 0, 0)
		g_mainmenu_screen.AddGadget(g_mainmenu_panBack)
		x :+ 10
		y :+ 10
		w :- 20
		g_mainmenu_screen.AddGadget(TButton.CreateButton("mainmenu_newgame", GetText("New Career"), x, y, w, h, 1, 3, "FFFFFF", "FFFFFF", g_mainmenu_imgStar, NewGame, 1.0, 1, ""))
		y :+ h + 10
		g_mainmenu_screen.AddGadget(TButton.CreateButton("mainmenu_loadgame", GetText("Load Career"), x, y, w, h, 1, 3, "FFFFFF", "FFFFFF", g_mainmenu_imgBoot, ButtonLoadGame, 1.0, 1, ""))
		y :+ h + 10
		g_mainmenu_screen.AddGadget(TButton.CreateButton("mainmenu_replays", GetText("Replays"), x, y, w, h, 1, 3, "FFFFFF", "FFFFFF", g_mainmenu_imgReplays, ButtonReplays, 1.0, 1, ""))
		y :+ h + 10
		g_mainmenu_screen.AddGadget(TButton.CreateButton("mainmenu_options", GetText("Options"), x, y, w, h, 1, 3, "FFFFFF", "FFFFFF", g_mainmenu_imgOptions, TScreen_Options.SetUpScreen, 1.0, 1, ""))
		y :+ h + 10
		g_mainmenu_screen.AddGadget(TButton.CreateButton("quit", GetText("Quit"), x, y, w, h, 1, 3, "FFFFFF", "FFFFFF", g_imgQuit, ButtonQuit, 1.0, 1, ""))
		x = 536
		y = g_mainmenu_panBack.y
		w = 230
		h = 30
		g_mainmenu_panLoadGame = TPanel.CreatePanel("pan_loadgame", GetText("Load Game"), x, y, w, 30, "FFFFFF", "FFFFFF", 3, 0.8, 1, 230, 0)
		y :+ 30
		g_mainmenu_screen.AddGadget(g_mainmenu_panLoadGame)
		g_mainmenu_tblLoadGame = TTable.CreateTable("tbl_LoadGame", x, y, 9, 0, 1, 2, "00FF00", 1.0, 0, Null)
		g_mainmenu_tblLoadGame.AddColumn(140, GetText("Save File"), "000000", "EEEEEE", 1)
		g_mainmenu_tblLoadGame.AddColumn(89, GetText("Date"), "000000", "DDDDDD", 1)
		g_mainmenu_panLoadGame.AddChild(g_mainmenu_tblLoadGame)
		x :+ 10
		y :+ 190
		w = 100
		g_mainmenu_panLoadGame.AddChild(TButton.CreateButton("btn_LoadGame", GetText("Load"), x, y, w, h, 1, 3, "FFFFFF", "FFFFFF", Null, ButtonLoadSaveFile, 1.0, 1, ""))
		x :+ w + 10
		g_mainmenu_panLoadGame.AddChild(TButton.CreateButton("btn_DeleteGame", GetText("Delete"), x, y, w, h, 1, 3, "FFFFFF", "FFFFFF", Null, ButtonDeleteSaveFile, 1.0, 1, ""))
		g_mainmenu_panLoadGame.Hide()
		x = 536
		y = g_mainmenu_panBack.y
		w = 230
		h = 30
		g_mainmenu_panLoadReplay = TPanel.CreatePanel("pan_LoadReplay", GetText("Load Replay"), x, y, w, 30, "FFFFFF", "FFFFFF", 3, 0.8, 1, 230, 0)
		y :+ 30
		g_mainmenu_screen.AddGadget(g_mainmenu_panLoadReplay)
		g_mainmenu_tblLoadReplay = TTable.CreateTable("tbl_LoadReplay", x, y, 9, 0, 1, 2, "00FF00", 1.0, 0, Null)
		g_mainmenu_tblLoadReplay.AddColumn(230, GetText("Replay File"), "000000", "EEEEEE", 1)
		g_mainmenu_panLoadReplay.AddChild(g_mainmenu_tblLoadReplay)
		x :+ 10
		y :+ 190
		w = 100
		g_mainmenu_panLoadReplay.AddChild(TButton.CreateButton("btn_LoadReplay", GetText("Load"), x, y, w, h, 1, 3, "FFFFFF", "FFFFFF", Null, ButtonLoadReplayFile, 1.0, 1, ""))
		x :+ w + 10
		g_mainmenu_panLoadReplay.AddChild(TButton.CreateButton("btn_DeleteReplay", GetText("Delete"), x, y, w, h, 1, 3, "FFFFFF", "FFFFFF", Null, ButtonDeleteReplayFile, 1.0, 1, ""))
		g_mainmenu_panLoadReplay.Hide()
		x = 246
		y = g_mainmenu_panBack.y + 10.0
		g_mainmenu_panSocial = TPanel.CreatePanel("pan_Social", "", x, y, 39, 145, "707070", "FFFFFF", 3, 1.0, 4, 0, 0)
		x :+ 5
		y :+ 5
		g_mainmenu_screen.AddGadget(g_mainmenu_panSocial)
		g_mainmenu_btnHome = TButton.CreateButton("btn_Home", "", x, y, 28, 28, 1, 2, "FFFFFF", "FFFFFF", g_mainmenu_imgHome, ButtonHome, 1.0, 1, "NewStarSoccer.com")
		y :+ 35
		g_mainmenu_btnFacebook = TButton.CreateButton("btn_Facebook", "", x, y, 28, 28, 1, 2, "FFFFFF", "FFFFFF", g_mainmenu_imgFacebook, ButtonFacebook, 1.0, 1, GetText("tt_Facebook"))
		y :+ 35
		g_mainmenu_btnTwitter = TButton.CreateButton("btn_Twitter", "", x, y, 28, 28, 1, 2, "FFFFFF", "FFFFFF", g_mainmenu_imgTwitter, ButtonTwitter, 1.0, 1, GetText("tt_Twitter"))
		y :+ 35
		g_mainmenu_btnMobile = TButton.CreateButton("btn_Mobile", "", x, y, 28, 28, 1, 2, "FFFFFF", "FFFFFF", g_mainmenu_imgMobile, ButtonMobile, 1.0, 1, "NSS Mobile")
		g_mainmenu_panSocial.AddChild(g_mainmenu_btnHome)
		g_mainmenu_panSocial.AddChild(g_mainmenu_btnFacebook)
		g_mainmenu_panSocial.AddChild(g_mainmenu_btnTwitter)
		g_mainmenu_panSocial.AddChild(g_mainmenu_btnMobile)
		LoadCredits()
	End Function
