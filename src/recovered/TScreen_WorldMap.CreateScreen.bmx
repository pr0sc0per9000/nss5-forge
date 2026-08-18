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
' TScreen_WorldMap.CreateScreen
' VA 0x0055987E   3183 bytes   mode=reloc   byte-identical vs NSS5.exe
' (3183/3183, original length from Ghidra's inventory, reloc_masked=312; re-verified with
'  NSS5_NO_LEARN=1 so no call operand was masked by a name this run taught the table)
' KIND=Function (static, no implicit Self), SIG ()i, class-table slot 0x30
'
' NEGATIVE CONTROLS (the two most maskable things in the body, both under NSS5_NO_LEARN=1)
'   swap TScreen_GameMenu.SetUpScreen <-> TScreen_MatchPrep.SetUpScreen -> MISMATCH 2238/3183
'   swap ButtonGame <-> ButtonFilm                                     -> MISMATCH 2238/3183
'   so the class-table slot calls are genuinely resolved, not blindly masked.
'
' ASSUMPTIONS
'   Module Globals (addresses are fact, NAMES are ours -- module Globals have no debug record).
'   Screen-owned block 0x00C683C8..0x00C68424, all typed from their construction site:
'     0x00C683C8 g_screen_worldmap:TScreen   (built by TScreen.CreateScreen)
'     0x00C683D0 g_img_arrow:TImage      0x00C683D4 g_img_blob:TImage
'     0x00C683D8 g_img_music:TImage      0x00C683DC g_img_console:TImage
'     0x00C683E0 g_img_tablet:TImage
'         (globals_final.tsv types these five only as "Object, usage"; TImage comes from
'          LoadImageChecked's return type and from their use as CreateButton's :TImage arg 11)
'     0x00C683E4 g_wm_pan_title:TPanel        0x00C683E8 g_wm_lbl_competition:TLabel
'     0x00C683EC g_wm_lbl_cash:TLabel         0x00C683F0 g_wm_pan_nav:TPanel
'     0x00C683F4 g_wm_lbl_fixture:TLabel      0x00C683F8 g_wm_pan_info:TPanel
'     0x00C683FC g_wm_lbl_team:TLabel         0x00C68400 g_wm_lbl_stadium:TLabel
'     0x00C68404 g_wm_lbl_stadcap1:TLabel     0x00C68408 g_wm_lbl_stadcap2:TLabel
'     0x00C6840C g_wm_pan_fixtures:TPanel     0x00C68410 g_wm_tbl_fixtures:TTable
'     0x00C68414 g_wm_pan_travel:TPanel       0x00C68418 g_wm_prg_energy:TProgressBar
'     0x00C6841C g_wm_btn_music:TButton       0x00C68420 g_wm_btn_game:TButton
'     0x00C68424 g_wm_btn_film:TButton
'         (note the three buttons are CREATED game, music, film but their Global slots run
'          music, game, film -- which is why the three closing AddChild calls look permuted.
'          Same quirk as TScreen_Home.CreateScreen's contract/finances/stats trio.)
'   Icons owned by other screens and only referenced here (names already established in the
'   corpus; only "is a TImage" is load-bearing, they are passed straight to CreateButton):
'     0x00C6F2EC g_img_helpicon:TImage   0x00C6F194 g_iconHome:TImage
'     0x00C6F274 g_img_play:TImage
'   0x00C6F170 -> g_iconpath:String
'         (globals_final.tsv calls this Int and is WRONG -- it is pushed straight into
'          bbStringConcat here, as in TScreen_Home / TScreen_Abilities.CreateScreen)
'   0x00C6EFDC -> g_screenwidth:Int      0x00C6EFE0 -> g_screenheight:Int
'         (bare dword reads, no refcount traffic -> Int, per section 10.7)
'   Class-table slots resolved through globals_final.tsv / vtable_map.tsv:
'     0x00C61C64 = TScreen+0x38       CreateScreen ($,:TImage,()i,()i):TScreen
'     0x00C61CDC = TScreen+0xB0       ButtonHelp ()i
'     0x00C63294 = TPanel+0x88        CreatePanel ($,$,i,i,i,i,$,$,i,f,i,i,i):TPanel
'     0x00C634C0 = TLabel+0x88        CreateLabel ($,$,i,i,i,i,i,$,$,f,i,i,i,i,:TImage,i,i,i,i,$,f):TLabel
'     0x00C623CC = TButton+0x88       CreateButton ($,$,i,i,i,i,i,i,$,$,:TImage,()i,f,i,$):TButton
'     0x00C62BAC = TTable+0x88        CreateTable ($,i,i,i,i,i,i,$,f,i,()i):TTable
'     0x00C637A8 = TProgressBar+0x88  CreateProgressBar ($,$,i,i,i,i,i,$,$,$,f,i,:TImage):TProgressBar
'     0x00C66910 = TScreen_GameMenu+0x34   SetUpScreen ()i
'     0x00C687A0 = TScreen_MatchPrep+0x34  SetUpScreen ()i
'     0x00C68560 = TScreen_WorldMap+0x38 = Draw ()i        (same Type -> bare name)
'     0x00C68564 = TScreen_WorldMap+0x3C = ButtonGame ()i  (same Type -> bare name)
'     0x00C68568 = TScreen_WorldMap+0x40 = ButtonMusic ()i (same Type -> bare name)
'     0x00C6856C = TScreen_WorldMap+0x44 = ButtonFilm ()i  (same Type -> bare name)
'     slot 0x40 on a TScreen = TScreen.AddGadget (:TGadget)i
'     slot 0x74 on a TPanel  = TGadget.AddChild (:TGadget)i    (inherited)
'     slot 0x90 on a TTable  = TTable.AddColumn (i,$,$,$,i)i
'   E8 targets: 0x004A7C20 bbStringConcat, 0x004A8590 GC free (inlined BBRELEASE, never
'   written in source), 0x004BC372 LoadImageChecked, 0x004C5549 GetText, 0x0050720B
'   FormatMoney, 0x005AE336 SetImageHandle, 0x005AE38D MidHandleImage.
'   0x005B95D0 is bcc's null-function stub -- a `Null` passed in a ()i parameter slot.
'
' NOTES ON SHAPE (each is byte-observable and was read off the disassembly, not guessed)
'   * Prologue is `sub esp,8` -- exactly TWO stack slots, so the source has FOUR Locals of
'     which two are register-allocated: x -> [ebp-4], y -> edi, w -> ebx, h -> [ebp-8].
'     All four are declared together at 0x00559DF2, two thirds of the way into the body,
'     and are then REASSIGNED (not redeclared) for the fixtures and travel blocks.
'   * The image guard is the `If Not x` form of section 10.3 (mov / cmp bbNullObject /
'     setne al / movzx / cmp 0 / jne, 21 bytes at 0x005598C3), not `If x = Null`.
'   * Three gadgets are never stored to a Global at all -- lbl_bank, btn_help, btn_quit and
'     btn_play are created straight inside the AddChild argument. The tell is the parent
'     being loaded into ebx BEFORE the argument pushes (`mov ebx,[g]` at 0x00559AF2 etc.)
'     rather than the create-then-refcount-then-store-then-AddChild sequence.
'   * `y :+ h + 10` emits `mov eax,[h] / add eax,0xa / add edi,eax`; `y :+ h` is the shorter
'     `add edi,[h]`; `x :+ w + 10` is `mov eax,ebx / add eax,0xa / add [ebp-4],eax`.
'     `w :- 20` is `sub ebx,0x14`. These are distinct byte sequences -- do not normalise them.
'   * pan_Travel's width is the literal expression `790 - x` (`mov eax,0x316 / sub eax,[x]`),
'     NOT g_screenwidth - x: 0x316 is an immediate, and every g_screenwidth read in this
'     body is a `mov eax,[0xc6efdc]`.
'   * pan_Travel also assigns `w = 385` before a call that does not use w -- w is only read
'     after the following `w :- 20`, by the progress bar. Reproduce the dead-looking store.
'   * The AddGadget for pan_info / pan_Travel comes AFTER the x/y/w/h advance statements,
'     and h is reassigned AFTER that AddGadget in the travel block. Statement order here
'     reads oddly and is load-bearing.
'   * The trailing `mov eax,0 / jmp +0` is bcc's implicit return for a ()i Function with no
'     explicit Return (section 6) -- there is no `Return 0` in the source.
'   * String literals were read out of NSS5.exe with harness.read_string at the exact address
'     each call site pushes -- the oracle masks a literal's ADDRESS, so their CONTENTS are
'     not certified by the MATCH. 0x00C5D284 and 0x005C7D40 are the two zero-length
'     BBStrings, i.e. "" (bcc picks a different empty-string constant depending on the
'     argument slot; the source is "" either way).
'!Global g_screen_worldmap:TScreen
'!Global g_img_arrow:TImage
'!Global g_img_blob:TImage
'!Global g_img_music:TImage
'!Global g_img_console:TImage
'!Global g_img_tablet:TImage
'!Global g_wm_pan_title:TPanel
'!Global g_wm_lbl_competition:TLabel
'!Global g_wm_lbl_cash:TLabel
'!Global g_wm_pan_nav:TPanel
'!Global g_wm_lbl_fixture:TLabel
'!Global g_wm_pan_info:TPanel
'!Global g_wm_lbl_team:TLabel
'!Global g_wm_lbl_stadium:TLabel
'!Global g_wm_lbl_stadcap1:TLabel
'!Global g_wm_lbl_stadcap2:TLabel
'!Global g_wm_pan_fixtures:TPanel
'!Global g_wm_tbl_fixtures:TTable
'!Global g_wm_pan_travel:TPanel
'!Global g_wm_prg_energy:TProgressBar
'!Global g_wm_btn_music:TButton
'!Global g_wm_btn_game:TButton
'!Global g_wm_btn_film:TButton
'!Global g_img_helpicon:TImage
'!Global g_iconHome:TImage
'!Global g_img_play:TImage
'!Global g_iconpath:String
'!Global g_screenwidth:Int
'!Global g_screenheight:Int
	Function CreateScreen()
		g_screen_worldmap = TScreen.CreateScreen("worldmap", Null, Draw, Null)
		If Not g_img_arrow
			g_img_arrow = LoadImageChecked("GameMedia/Images/Interface/Arrow.png", -1)
			SetImageHandle(g_img_arrow, 0, 9)
			g_img_blob = LoadImageChecked("GameMedia/Images/Interface/Blob.png", -1)
			MidHandleImage(g_img_blob)
			g_img_music = LoadImageChecked(g_iconpath + "MusicPlayer.png", -1)
			g_img_console = LoadImageChecked(g_iconpath + "Console.png", -1)
			g_img_tablet = LoadImageChecked(g_iconpath + "Tablet.png", -1)
		End If
		g_wm_pan_title = TPanel.CreatePanel("pan_title", "", 0, 0, g_screenwidth, 60, "FFFFFF", "FFFFFF", 4, 1.0, 0, 0, 1)
		g_screen_worldmap.AddGadget(g_wm_pan_title)
		g_wm_lbl_competition = TLabel.CreateLabel("lbl_Competition", "", 10, 10, 620, 40, 4, "888888", "FFFFFF", 1.0, 1, 0, 1, 1, Null, 1, 0, 0, 0, "", 0)
		g_wm_pan_title.AddChild(g_wm_lbl_competition)
		g_wm_pan_title.AddChild(TLabel.CreateLabel("lbl_bank", GetText("Bank"), g_screenwidth - 160, 10, 100, 20, 2, "FFFFFF", "FFFFFF", 1.0, 2, 0, 1, 1, Null, 1, 0, 0, 0, "", 0))
		g_wm_lbl_cash = TLabel.CreateLabel("lbl_cash", "", g_screenwidth - 160, 30, 100, 20, 2, "888888", "FFFFFF", 1.0, 3, 0, 1, 1, Null, 1, 0, 0, 0, "", 0)
		g_wm_pan_title.AddChild(g_wm_lbl_cash)
		g_wm_pan_title.AddChild(TButton.CreateButton("btn_help", "", g_screenwidth - 50, 10, 40, 40, 1, 2, "FFFFFF", "FFFFFF", g_img_helpicon, TScreen.ButtonHelp, 1.0, 1, ""))
		g_wm_pan_nav = TPanel.CreatePanel("pan_nav", "", 0, g_screenheight - 60, g_screenwidth, 60, "FFFFFF", "FFFFFF", 3, 1.0, 0, 0, 0)
		g_screen_worldmap.AddGadget(g_wm_pan_nav)
		g_wm_pan_nav.AddChild(TButton.CreateButton("btn_quit", "", 10, g_screenheight - 50, 120, 40, 1, 2, "FFFFFF", "FFFFFF", g_iconHome, TScreen_GameMenu.SetUpScreen, 1.0, 1, GetText("tt_Back")))
		g_wm_pan_nav.AddChild(TButton.CreateButton("btn_play", "", 670, g_screenheight - 50, 120, 40, 1, 2, "FFFFFF", "FFFFFF", g_img_play, TScreen_MatchPrep.SetUpScreen, 1.0, 1, GetText("tt_Proceed")))
		g_wm_lbl_fixture = TLabel.CreateLabel("lbl_Fixture", "", 140, g_screenheight - 50, 520, 40, 3, "888888", "FFFFFF", 1.0, 1, 0, 1, 1, Null, 1, 0, 0, 0, "", 0)
		g_wm_pan_nav.AddChild(g_wm_lbl_fixture)
		Local x:Int = 10
		Local y:Int = 70
		Local w:Int = 220
		Local h:Int = 30
		g_wm_pan_info = TPanel.CreatePanel("pan_info", GetText("Stadium"), x, y, w, h, "FFFFFF", "FFFFFF", 3, 0.8, 2, 140, 1)
		x :+ 10
		y :+ h + 10
		w :- 20
		h = 27
		g_screen_worldmap.AddGadget(g_wm_pan_info)
		g_wm_lbl_team = TLabel.CreateLabel("lbl_team", GetText("Home Team"), x, y, w, h, 2, "FFFFFF", "FFFFFF", 1.0, 2, 0, 1, 1, Null, 1, 0, 0, 0, "", 0)
		y :+ h
		g_wm_lbl_stadium = TLabel.CreateLabel("lbl_stadium", "", x, y, w, h, 2, "888888", "FFFFFF", 1.0, 3, 0, 1, 1, Null, 1, 0, 0, 0, "", 0)
		y :+ h + 10
		g_screen_worldmap.AddGadget(g_wm_lbl_team)
		g_screen_worldmap.AddGadget(g_wm_lbl_stadium)
		g_wm_lbl_stadcap1 = TLabel.CreateLabel("lbl_stadcap1", GetText("Capacity"), x, y, w, h, 2, "FFFFFF", "FFFFFF", 1.0, 2, 0, 1, 1, Null, 1, 0, 0, 0, "", 0)
		y :+ h
		g_wm_lbl_stadcap2 = TLabel.CreateLabel("lbl_stadcap2", "", x, y, w, h, 2, "888888", "FFFFFF", 1.0, 3, 0, 1, 1, Null, 1, 0, 0, 0, "", 0)
		y :+ h + 10
		g_screen_worldmap.AddGadget(g_wm_lbl_stadcap1)
		g_screen_worldmap.AddGadget(g_wm_lbl_stadcap2)
		x = 10
		y :+ 10
		w = 220
		h = 30
		g_wm_pan_fixtures = TPanel.CreatePanel("pan_fixtures", GetText("Fixtures"), x, y, w, h, "FFFFFF", "FFFFFF", 3, 0.8, 2, 250, 1)
		y :+ h
		g_screen_worldmap.AddGadget(g_wm_pan_fixtures)
		g_wm_tbl_fixtures = TTable.CreateTable("tbl_fixtures", x, y, 12, 0, 1, 2, "00FF00", 1.0, 0, Null)
		g_wm_tbl_fixtures.AddColumn(42, "", "000000", "EEEEEE", 1)
		g_wm_tbl_fixtures.AddColumn(67, GetText("Home Team"), "000000", "EEEEEE", 1)
		g_wm_tbl_fixtures.AddColumn(67, GetText("Away Team"), "000000", "EEEEEE", 1)
		g_wm_tbl_fixtures.AddColumn(41, "", "000000", "EEEEEE", 1)
		g_wm_pan_fixtures.AddChild(g_wm_tbl_fixtures)
		x = 405
		y = 390
		w = 385
		g_wm_pan_travel = TPanel.CreatePanel("pan_Travel", GetText("Travel Time"), x, y, 790 - x, h, "FFFFFF", "FFFFFF", 3, 0.8, 2, 110, 1)
		x :+ 10
		y :+ h + 10
		w :- 20
		g_screen_worldmap.AddGadget(g_wm_pan_travel)
		h = 40
		g_wm_prg_energy = TProgressBar.CreateProgressBar("prg_EnergyAfterTravelling", "", x, y, w, h, 3, "FFFFFF", "00FF00", "FFFFFF", 0.8, 1, Null)
		y :+ h + 10
		g_wm_pan_travel.AddChild(g_wm_prg_energy)
		w = 115
		g_wm_btn_game = TButton.CreateButton("btn_Game", FormatMoney(100, 0), x, y, w, h, 1, 3, "FFFFFF", "FFFFFF", g_img_console, ButtonGame, 1.0, 1, GetText("tt_BuyGames"))
		x :+ w + 10
		g_wm_btn_music = TButton.CreateButton("btn_Music", FormatMoney(250, 0), x, y, w, h, 1, 3, "FFFFFF", "FFFFFF", g_img_music, ButtonMusic, 1.0, 1, GetText("tt_BuyMusic"))
		x :+ w + 10
		g_wm_btn_film = TButton.CreateButton("btn_Film", FormatMoney(500, 0), x, y, w, h, 1, 3, "FFFFFF", "FFFFFF", g_img_tablet, ButtonFilm, 1.0, 1, GetText("tt_BuyMovies"))
		g_wm_pan_travel.AddChild(g_wm_btn_music)
		g_wm_pan_travel.AddChild(g_wm_btn_game)
		g_wm_pan_travel.AddChild(g_wm_btn_film)
	End Function
