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
'
' GLOBALS RENAMED (2026-08-23): g_lbl_cash -> g_label_bank and g_prg_achievements ->
' g_bar_energy, in THIS file only. Same defect class as the g_iconpath rename above: one
' identifier covering two distinct slots. Both cost this screen a readout.
'   g_lbl_cash was 0x00C66788 here and TScreen_MatchPrep.CreateScreen's own money label
'   (0x00C685BC) there. TScreen_MatchPrep.CreateScreen runs later in CreateAllScreens, so
'   the merged variable ended up pointing at Match Preparation's label and
'   UpdateTitlePanel's SetText landed on it. The title bar's Bank caption drew with
'   nothing under it while Match Preparation showed the balance -- through a Global it was
'   never meant to share. 0x00C66788's two readers, UpdateTitlePanel and UpdateMatchRefresh,
'   both call the slot g_label_bank, so that is the name kept.
'   g_prg_achievements was 0x00C66790 here (the title bar's energy bar) and 0x00C669A8 in
'   TScreen_Home.CreateScreen / TScreen_Home.SetUpScreen (the Home screen's achievements
'   bar). Home is created after this screen, so every UpdateTitlePanel energy write went to
'   the achievements bar and the title bar's own bar kept the value
'   TProgressBar.CreateProgressBar leaves behind, SetPercent(1.0, 1). TProgressBar.Draw
'   fills an empty caption with Int(livepercent) + "%", which is where the title bar's
'   "1%" energy readout came from -- a factory default rendered as a measurement.
'   0x00C66790's two readers already call it g_bar_energy.
' Both renames are byte-neutral: a module Global reaches the compiled code only as an
' absolute address, which the oracle masks. scripts/reverify.py confirms it.
' TScreen_GameMenu.CreateScreen
' VA 0x00539BE4   3779 bytes   mode=reloc   byte-identical vs NSS5.exe
' (3779/3779, original length from Ghidra's inventory, reloc_masked=396; re-verified with
'  NSS5_NO_LEARN=1, so no call operand was masked by a name this run taught the table)
' KIND=Function (static, no implicit Self), SIG ()i, class-table slot 0x30
'
' ASSUMPTIONS
'   Module Globals -- the ADDRESSES are fact, the NAMES are ours (module Globals carry no
'   debug record).  The declared TYPE is load-bearing: it picks the dispatch slot.
'     0x00C66724 g_screen_gamemenu:TScreen   (construction site = TScreen.CreateScreen)
'     0x00C66728 g_img_options:TImage        0x00C6672C g_img_home:TImage
'     0x00C66730 g_gamemenu_imgboot:TImage           0x00C66734 g_gamemenu_imgrelationships:TImage
'     0x00C66738 g_gamemenu_imgmoney:TImage          0x00C6673C g_img_casino:TImage
'     0x00C66740 g_img_trophy:TImage         0x00C66744 g_img_playball:TImage
'     0x00C66748 g_img_playrelations:TImage  0x00C6674C g_img_playnewspaper:TImage
'     0x00C66750 g_img_playcup:TImage        0x00C66754 g_img_playweb:TImage
'     0x00C66758 g_img_playphysio:TImage     0x00C6675C g_img_playboss:TImage
'     0x00C66760 g_img_playcoach:TImage      0x00C66764 g_img_world:TImage
'       (all sixteen assigned from LoadImageChecked; globals_final.tsv types most of them
'        only as "Object, usage".  0x00C6675C is the one it already had as TImage.)
'     0x00C66768 g_pan_title:TPanel          0x00C667B0 g_pan_nav:TPanel
'       (the SAME two Globals appear in TScreen_Abilities.CreateScreen under the guessed
'        names g_pan_stable / g_pan_money -- they are this screen's title and nav bars,
'        re-added by other screens.  Type TPanel is from the construction site here.)
'     0x00C6676C g_btn_help:TButton          0x00C66770 g_btn_options:TButton
'     0x00C66774 g_btn_quit:TButton          0x00C66798 g_btn_play:TButton
'     0x00C6679C g_btn_home:TButton          0x00C667A0 g_btn_competitions:TButton
'     0x00C667A4 g_btn_training:TButton      0x00C667A8 g_btn_relationships:TButton
'     0x00C667AC g_btn_shop:TButton
'     0x00C66778 g_lbl_title:TLabel          0x00C6677C g_lbl_name:TLabel
'     0x00C66780 g_lbl_year:TLabel           0x00C66784 g_lbl_week:TLabel
'     0x00C66788 g_label_bank:TLabel         0x00C6678C g_lbl_energy:TLabel
'     0x00C66794 g_lbl_nextopp2:TLabel
'     0x00C66790 g_bar_energy:TProgressBar
'       (0x00C66788 and 0x00C66790 carry the names their two readers already use, per the
'        rename note at the top of this file.  The gadget NAME strings the pair are built
'        with, "lbl_cash" and "prg_Achievements", are the original's own and stay as they are.)
'     0x00C6EFDC g_screenwidth:Int           0x00C6EFE0 g_screenheight:Int
'     0x00C6F170 g_iconpath:String -- globals_final.tsv calls this Int and is WRONG: it is
'       pushed straight into bbStringConcat sixteen times here (same call as
'       TScreen_Abilities.CreateScreen, which reached the same conclusion independently).
'     0x00C6F2EC g_img_helpicon:TImage  (image of the "help" button)
'     0x00C6F254 g_img_back:TImage      (image of the "quit" button; named g_img_back in
'       TScreen_Controls.CreateScreen, which is the only other verified user)
'   Class-table slots, resolved via class_tables.tsv / vtable_map.tsv:
'     0x00C61C64 = TScreen+0x38       CreateScreen($,:TImage,()i,()i):TScreen
'     0x00C61CDC = TScreen+0xB0       ButtonHelp()i  -- TScreen's OWN table, so the source
'                                     must qualify it `TScreen.ButtonHelp`, not bare
'     0x00C63294 = TPanel+0x88        CreatePanel($,$,i,i,i,i,$,$,i,f,i,i,i):TPanel
'     0x00C634C0 = TLabel+0x88        CreateLabel($,$,i,i,i,i,i,$,$,f,i,i,i,i,:TImage,i,i,i,i,$,f):TLabel
'     0x00C637A8 = TProgressBar+0x88  CreateProgressBar($,$,i,i,i,i,i,$,$,$,f,i,:TImage):TProgressBar
'     0x00C623CC = TButton+0x88       CreateButton($,$,i,i,i,i,i,i,$,$,:TImage,()i,f,i,$):TButton
'     0x00C64060 = TScreen_Options+0x34 SetUpScreen()i
'     0x00C66A60 = TScreen_Home+0x34    SetUpScreen()i
'     0x00C66B78 = TScreen_Abilities+0x34 SetUpScreen()i
'     0x00C66E14 = TScreen_Shop+0x34    SetUpScreen()i
'     0x00C66920/0x00C66924/0x00C66928/0x00C6692C = TScreen_GameMenu+0x44/0x48/0x4C/0x50 =
'       ButtonCompetitions / ButtonQuit / ButtonPlay / ButtonRelationships -- this Type's
'       OWN table, so they are written as bare names with no `Type.` prefix
'     slot 0x40 on a TScreen = TScreen.AddGadget(:TGadget)i
'     slot 0x74 on a TPanel  = TGadget.AddChild(:TGadget)i  (inherited)
'   E8 targets: 0x004A7C20 _bbStringConcat (the `+` in every path expression),
'     0x004A8590 the GC free of the inlined BBRELEASE (never written in source),
'     0x004BC372 LoadImageChecked, 0x004C5549 GetText -- both recovered module Functions.
'   0x005B95D0 in an ()i argument slot is source-level Null; 0x005C9C80 is bbNullObject.
'
' NOTES ON SHAPE (each was read off the disassembly, not guessed)
'   * The image guard is the `If Not g_img_options` form of section 10.3
'     (mov / cmp bbNullObject / setne / movzx / cmp 0 / jne), not `If ... = Null`.
'   * FOUR Int Locals, in the original's declaration order: x, y, w, then h much later.
'     The frame is only `sub esp,8`: x lives in EBX and h in EDI, y and w in [ebp-4]/[ebp-8].
'     y and w are REASSIGNED for the nav bar (`y = g_screenheight - 50`, `w = 60`), not
'     redeclared -- redeclaring them would grow the frame.  h is genuinely new at that point.
'   * The x advance differs per row and is byte-observable: `x :+ w + 10` emits
'     mov eax,[w] / add eax,10 / add ebx,eax, whereas `x :+ 310` after lbl_name emits a
'     single `add ebx,0x136`.  The five nav buttons advance by `x :+ w + 1`.
'   * `g_screenwidth - 130 - 235` is TWO `sub eax` instructions.  Ghidra folds it to
'     -0x16D; writing the folded constant is 10 bytes short (measured as a negative control).
'   * lbl_bank and lbl_nextopp1 are NOT stored in a Global -- they are built inline as the
'     argument of AddChild, which is why the parent is loaded into a register BEFORE the
'     argument pushes and there is no retain/release pair around them.
'   * Per-row statement order is create-and-assign / advance x / add-to-parent, which reads
'     oddly but is what the bytes show.
'   * String literals were read out of NSS5.exe with harness.read_string; the oracle masks a
'     literal's ADDRESS, so their CONTENTS are not certified by the MATCH.  0x00C5D284 and
'     0x005C7D40 are both zero-length BBStrings, i.e. "" (bcc picks a different empty-string
'     constant depending on the argument slot; the source is "" either way).
'!Global g_screen_gamemenu:TScreen
'!Global g_img_options:TImage
'!Global g_img_home:TImage
'!Global g_gamemenu_imgboot:TImage
'!Global g_gamemenu_imgrelationships:TImage
'!Global g_gamemenu_imgmoney:TImage
'!Global g_img_casino:TImage
'!Global g_img_trophy:TImage
'!Global g_img_playball:TImage
'!Global g_img_playrelations:TImage
'!Global g_img_playnewspaper:TImage
'!Global g_img_playcup:TImage
'!Global g_img_playweb:TImage
'!Global g_img_playphysio:TImage
'!Global g_img_playboss:TImage
'!Global g_img_playcoach:TImage
'!Global g_img_world:TImage
'!Global g_pan_title:TPanel
'!Global g_btn_help:TButton
'!Global g_btn_options:TButton
'!Global g_btn_quit:TButton
'!Global g_lbl_title:TLabel
'!Global g_lbl_name:TLabel
'!Global g_lbl_year:TLabel
'!Global g_lbl_week:TLabel
'!Global g_label_bank:TLabel
'!Global g_lbl_energy:TLabel
'!Global g_bar_energy:TProgressBar
'!Global g_lbl_nextopp2:TLabel
'!Global g_btn_play:TButton
'!Global g_btn_home:TButton
'!Global g_btn_competitions:TButton
'!Global g_btn_training:TButton
'!Global g_btn_relationships:TButton
'!Global g_btn_shop:TButton
'!Global g_pan_nav:TPanel
'!Global g_screenwidth:Int
'!Global g_screenheight:Int
'!Global g_iconpath:String
'!Global g_img_back:TImage
'!Global g_img_helpicon:TImage
	Function CreateScreen()
		g_screen_gamemenu = TScreen.CreateScreen("gamemenu", Null, Null, Null)
		If Not g_img_options
			g_img_options = LoadImageChecked(g_iconpath + "Options.png", -1)
			g_img_home = LoadImageChecked(g_iconpath + "Home.png", -1)
			g_gamemenu_imgboot = LoadImageChecked(g_iconpath + "Boot22.png", -1)
			g_gamemenu_imgrelationships = LoadImageChecked(g_iconpath + "Relationships.png", -1)
			g_gamemenu_imgmoney = LoadImageChecked(g_iconpath + "Money.png", -1)
			g_img_casino = LoadImageChecked(g_iconpath + "Casino.png", -1)
			g_img_trophy = LoadImageChecked(g_iconpath + "Trophy.png", -1)
			g_img_playball = LoadImageChecked(g_iconpath + "PlayBall.png", -1)
			g_img_playrelations = LoadImageChecked(g_iconpath + "PlayRelations.png", -1)
			g_img_playnewspaper = LoadImageChecked(g_iconpath + "PlayNewspaper.png", -1)
			g_img_playcup = LoadImageChecked(g_iconpath + "PlayCup.png", -1)
			g_img_playweb = LoadImageChecked(g_iconpath + "PlayWeb.png", -1)
			g_img_playphysio = LoadImageChecked(g_iconpath + "PlayPhysio.png", -1)
			g_img_playboss = LoadImageChecked(g_iconpath + "PlayBoss.png", -1)
			g_img_playcoach = LoadImageChecked(g_iconpath + "PlayCoach.png", -1)
			g_img_world = LoadImageChecked(g_iconpath + "World14.png", -1)
		End If
		g_pan_title = TPanel.CreatePanel("pan_title", "", 0, 0, g_screenwidth, 60, "FFFFFF", "FFFFFF", 3, 1.0, 0, 0, 1)
		g_screen_gamemenu.AddGadget(g_pan_title)
		Local x:Int = 10
		Local y:Int = 10
		Local w:Int = 100
		g_lbl_title = TLabel.CreateLabel("lbl_title", "NSS5", x, y, w, 40, 3, "888888", "FFFFFF", 1.0, 1, 0, 1, 1, Null, 1, 0, 0, 0, "", 0)
		x :+ w + 10
		g_pan_title.AddChild(g_lbl_title)
		g_lbl_name = TLabel.CreateLabel("lbl_name", "", x, y, 300, 40, 3, "888888", "FFFFFF", 1.0, 1, 0, 1, 1, Null, 1, 0, 0, 0, "", 0)
		x :+ 310
		g_pan_title.AddChild(g_lbl_name)
		g_pan_title.AddChild(TLabel.CreateLabel("lbl_bank", GetText("Bank"), x, y, w, 20, 2, "FFFFFF", "FFFFFF", 1.0, 2, 0, 1, 1, Null, 1, 0, 0, 0, "", 0))
		g_label_bank = TLabel.CreateLabel("lbl_cash", "", x, y + 20, w, 20, 2, "888888", "FFFFFF", 1.0, 3, 0, 1, 1, Null, 1, 0, 0, 0, "", 0)
		x :+ w + 10
		g_pan_title.AddChild(g_label_bank)
		g_lbl_energy = TLabel.CreateLabel("lbl_energy", GetText("Energy"), x, y, w, 20, 2, "FFFFFF", "FFFFFF", 1.0, 2, 0, 1, 1, Null, 1, 0, 0, 0, "", 0)
		g_bar_energy = TProgressBar.CreateProgressBar("prg_Achievements", "", x, y + 20, w, 20, 1, "888888", "00FF00", "FFFFFF", 0.8, 3, Null)
		g_pan_title.AddChild(g_lbl_energy)
		g_pan_title.AddChild(g_bar_energy)
		g_btn_options = TButton.CreateButton("options", "", g_screenwidth - 150, 10, 40, 40, 1, 2, "FFFFFF", "FFFFFF", g_img_options, TScreen_Options.SetUpScreen, 1.0, 1, GetText("tt_Options"))
		g_btn_help = TButton.CreateButton("help", "", g_screenwidth - 100, 10, 40, 40, 1, 2, "FFFFFF", "FFFFFF", g_img_helpicon, TScreen.ButtonHelp, 1.0, 1, GetText("tt_Help"))
		g_btn_quit = TButton.CreateButton("quit", "", g_screenwidth - 50, 10, 40, 40, 1, 2, "FFFFFF", "FFFFFF", g_img_back, ButtonQuit, 1.0, 1, GetText("tt_SaveQuit"))
		g_pan_title.AddChild(g_btn_help)
		g_pan_title.AddChild(g_btn_options)
		g_pan_title.AddChild(g_btn_quit)
		g_pan_nav = TPanel.CreatePanel("pan_nav", "", 0, g_screenheight - 60, g_screenwidth, 60, "FFFFFF", "FFFFFF", 3, 1.0, 0, 0, 0)
		g_screen_gamemenu.AddGadget(g_pan_nav)
		x = 10
		y = g_screenheight - 50
		g_lbl_year = TLabel.CreateLabel("lbl_year", "", x, y, w, 20, 2, "FFFFFF", "FFFFFF", 1.0, 2, 0, 1, 1, Null, 1, 0, 0, 0, "", 0)
		g_lbl_week = TLabel.CreateLabel("lbl_week", "", x, y + 20, w, 20, 2, "888888", "FFFFFF", 1.0, 3, 0, 1, 1, Null, 1, 0, 0, 0, "", 0)
		x :+ w + 10
		g_pan_nav.AddChild(g_lbl_year)
		g_pan_nav.AddChild(g_lbl_week)
		w = 60
		Local h:Int = 40
		g_btn_home = TButton.CreateButton("btn_home", "", x, y, w, h, 1, 3, "FFFFFF", "FFFFFF", g_img_home, TScreen_Home.SetUpScreen, 1.0, 4, GetText("tt_Home"))
		x :+ w + 1
		g_btn_competitions = TButton.CreateButton("btn_competitions", "", x, y, w, h, 1, 3, "FFFFFF", "FFFFFF", g_img_trophy, ButtonCompetitions, 1.0, 0, GetText("tt_Competitions"))
		x :+ w + 1
		g_btn_training = TButton.CreateButton("btn_training", "", x, y, w, h, 1, 3, "FFFFFF", "FFFFFF", g_gamemenu_imgboot, TScreen_Abilities.SetUpScreen, 1.0, 0, GetText("tt_Training"))
		x :+ w + 1
		g_btn_relationships = TButton.CreateButton("btn_relationships", "", x, y, w, h, 1, 3, "FFFFFF", "FFFFFF", g_gamemenu_imgrelationships, ButtonRelationships, 1.0, 0, GetText("tt_Happiness"))
		x :+ w + 1
		g_btn_shop = TButton.CreateButton("btn_shop", "", x, y, w, h, 1, 3, "FFFFFF", "FFFFFF", g_gamemenu_imgmoney, TScreen_Shop.SetUpScreen, 1.0, 5, GetText("tt_Shop"))
		g_pan_nav.AddChild(g_btn_home)
		g_pan_nav.AddChild(g_btn_competitions)
		g_pan_nav.AddChild(g_btn_training)
		g_pan_nav.AddChild(g_btn_relationships)
		g_pan_nav.AddChild(g_btn_shop)
		g_pan_nav.AddChild(TLabel.CreateLabel("lbl_nextopp1", GetText("Next Opponent"), g_screenwidth - 130 - 235, g_screenheight - 50, 225, 20, 2, "FFFFFF", "FFFFFF", 1.0, 2, 0, 1, 1, Null, 1, 0, 0, 0, "", 0))
		g_lbl_nextopp2 = TLabel.CreateLabel("lbl_nextopp2", "", g_screenwidth - 130 - 235, g_screenheight - 30, 225, 20, 2, "888888", "FFFFFF", 1.0, 3, 0, 1, 1, Null, 1, 0, 0, 0, "", 0)
		g_pan_nav.AddChild(g_lbl_nextopp2)
		g_btn_play = TButton.CreateButton("btn_play", "", g_screenwidth - 130, g_screenheight - 50, 120, 40, 1, 2, "FFFFFF", "FFFFFF", g_img_playball, ButtonPlay, 1.0, 1, GetText("tt_PlayButton"))
		g_pan_nav.AddChild(g_btn_play)
	End Function
