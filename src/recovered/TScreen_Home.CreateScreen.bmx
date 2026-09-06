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
' GLOBALS RENAMED (2026-08-23): seven more slots, same defect class, in THIS file only.
'   0x00C66934 g_img_home_relationships   0x00C66938 g_img_home_boot
'   0x00C6693C g_img_home_money           0x00C66940 g_img_home_star
'   0x00C66990 g_prg_home_skills          0x00C66998 g_pan_home_lifestyle
'   0x00C669A8 g_prg_home_achievements
' Each was spelled with a name another screen uses for a DIFFERENT slot. Evidence and
' the two player-visible failures are under THE SEVEN NAME COLLISIONS below.
' TScreen_Home.CreateScreen
' VA 0x0053BA31   4273 bytes   mode=reloc   byte-identical vs NSS5.exe
' (4273/4273, original length from Ghidra's inventory, reloc_masked=412; re-verified with
'  NSS5_NO_LEARN=1 so no call operand was masked by a name this run taught the table)
' KIND=Function (static, no implicit Self), SIG ()i, class-table slot 0x30
'
' THE SEVEN NAME COLLISIONS (2026-08-23)
' Each of the seven was spelled with a name another screen uses for a DIFFERENT slot, so
' the assembler emitted one variable where NSS5.exe has two and the two screens shared
' storage. Two of the seven were visible on the home screen of a new career:
'   * g_img_relationships. TScreen_GameMenu.CreateScreen calls 0x00C66734 by that name and
'     runs first, so by the time this Function's `If Not g_img_relationships` guard is
'     reached the shared variable is already loaded and the guard skips the WHOLE icon
'     block. All eight home icons stayed Null, btn_Achievements was built with a Null
'     :TImage and drew nothing. btn_Skills, btn_Happiness and btn_Lifestyle still drew
'     because boot/relationships/money are shared with the game-menu slots the guard had
'     just filled, which is why only the star was missing and the defect read as an
'     image-loading problem rather than a naming one. The state dump of the run in
'     status/debugruns/20260823-202801 names the four Home-only icons as the tell: contract,
'     finances, shirt and star52 were all Null while boot, money and relationships were not.
'   * g_prg_achievements. TScreen_GameMenu.CreateScreen calls 0x00C66790 by that name, and
'     extracted/global_alias_overrides.tsv merges g_bar_energy onto it, so the ENERGY gauge
'     updater TScreen_GameMenu.UpdateTitlePanel drove this screen's achievements bar:
'     SetPercent(g_profile.energy) plus SetText(Int(energy) + "%") painted a literal 100%
'     over a stat that was 0. Home's CreateScreen runs after the game menu's, so the shared
'     variable ended up holding THIS bar and the real energy gauge stopped updating.
'   The other five are the same fault without a symptom yet: g_img_boot and g_img_money are
'   the game menu's 22-pixel icons standing in for this screen's 28-pixel ones, g_img_star
'   is TScreen_Abilities' Star52.png, g_prg_skills is TScreen_Abilities' prg_Skills (which
'   is created later, so this screen's skills bar kept CreateProgressBar's 1.0 default and
'   reported 1% no matter what the player's rating was), and g_pan_home_lifestyle is
'   TScreen_Finances' 0x00C6815C.
' Renaming is byte-neutral for the same reason the g_mediapath note gives above: a Global
' reaches the compiled code only as an absolute address, which the oracle masks.
' scripts/workflow/find_name_collisions.py lists the rest of this defect class.
'
' ASSUMPTIONS
'   Module Globals (addresses are fact, NAMES are ours -- module Globals have no debug record).
'   Every one below is typed from its construction site in globals_final.tsv unless noted:
'     0x00C66930 -> g_screen_home:TScreen        (construction site = TScreen.CreateScreen)
'     0x00C66934 -> g_img_home_relationships:TImage   0x00C66938 -> g_img_home_boot:TImage
'     0x00C6693C -> g_img_home_money:TImage           0x00C66940 -> g_img_home_star:TImage
'     0x00C66944 -> g_img_shirt:TImage           0x00C66948 -> g_img_finances:TImage
'     0x00C6694C -> g_img_contract:TImage        0x00C66950 -> g_img_star52:TImage
'         (globals_final.tsv types these eight only as "Object, usage"; TImage is from the
'          LoadImageChecked return type and from their use as CreateButton's :TImage arg 11)
'     0x00C66954 -> g_pan_profile:TPanel
'     0x00C66958 g_lbl_teamcurrent1  0x00C6695C g_lbl_teamcurrent2  0x00C66960 g_lbl_rating1
'     0x00C66964 g_lbl_rating2       0x00C66968 g_lbl_value1        0x00C6696C g_lbl_value2
'         (all :TLabel)
'     0x00C66970 -> g_prg_fame:TProgressBar
'     0x00C66974 g_btn_stats  0x00C66978 g_btn_contract  0x00C6697C g_btn_finances (:TButton)
'         (note the creation order is contract, finances, stats -- the Global slots are NOT
'          in creation order, which is why the three AddChild calls look permuted)
'     0x00C66980 g_pan_happiness:TPanel   0x00C66984 g_prg_happiness:TProgressBar
'     0x00C66988 g_btn_happiness:TButton  0x00C6698C g_pan_skills:TPanel
'     0x00C66990 g_prg_home_skills:TProgressBar 0x00C66994 g_btn_skills:TButton
'     0x00C66998 g_pan_home_lifestyle:TPanel   0x00C6699C g_prg_lifestyle:TProgressBar
'     0x00C669A0 g_btn_lifestyle:TButton  0x00C669A4 g_pan_achievements:TPanel
'     0x00C669A8 g_prg_home_achievements:TProgressBar 0x00C669AC g_btn_achievements:TButton
'   Gadgets built by OTHER screens and only referenced here (Types from construction sites;
'   the names are guesses at their role):
'     0x00C66768 g_pan_stable:TPanel   0x00C667B0 g_pan_money:TPanel
'         (the same two Globals TScreen_Abilities.CreateScreen re-adds -- names kept identical)
'     0x00C66788 g_lbl_bank:TLabel     0x00C66790 g_prg_energy:TProgressBar
'     0x00C66798 g_btn_play:TButton    0x00C667A4 g_btn_main:TButton
'     0x00C6676C g_btn_help:TButton    0x00C66770 g_btn_options:TButton
'     0x00C66774 g_btn_quit:TButton
'         (these seven are used only as THelpBox.Create's :TGadget arg 1, so only the fact
'          that they are TGadget subclasses is load-bearing here)
'   0x00C6F170 -> g_iconpath:String   0x00C6E950 -> g_skinpath:String
'         (0x00C6F170 is listed Int in globals_final.tsv and is WRONG -- it is pushed straight
'          into bbStringConcat here, exactly as in TScreen_Abilities.CreateScreen)
'   0x00C6EFDC -> g_screenw:Int        0x00C6EFE0 -> g_screenh:Int
'   Class-table slots resolved through globals_final.tsv / vtable_map.tsv:
'     0x00C61C64 = TScreen+0x38      CreateScreen ($,:TImage,()i,()i):TScreen
'     0x00C63294 = TPanel+0x88       CreatePanel ($,$,i,i,i,i,$,$,i,f,i,i,i):TPanel
'     0x00C634C0 = TLabel+0x88       CreateLabel ($,$,i,i,i,i,i,$,$,f,i,i,i,i,:TImage,i,i,i,i,$,f):TLabel
'     0x00C637A8 = TProgressBar+0x88 CreateProgressBar ($,$,i,i,i,i,i,$,$,$,f,i,:TImage):TProgressBar
'     0x00C623CC = TButton+0x88      CreateButton ($,$,i,i,i,i,i,i,$,$,:TImage,()i,f,i,$):TButton
'     0x00C638BC = THelpBox+0x30     Create (:TGadget,i,i,i,i,$,i,i):THelpBox
'     0x00C66A64 = TScreen_Home+0x38 = ButtonHappiness ()i   (same Type -> bare name)
'     0x00C66B78 = TScreen_Abilities+0x34    SetUpScreen ()i
'     0x00C66E14 = TScreen_Shop+0x34         SetUpScreen ()i
'     0x00C67AFC = TScreen_Stats+0x34        SetUpScreen ()i
'     0x00C6800C = TScreen_MyContract+0x34   SetUpScreen ()i
'     0x00C68224 = TScreen_Finances+0x34     SetUpScreen ()i
'     0x00C683C4 = TScreen_Achievements+0x34 SetUpScreen ()i
'     slot 0x40 on a TScreen = TScreen.AddGadget (:TGadget)i
'     slot 0x74 on a TPanel  = TGadget.AddChild (:TGadget)i   (inherited)
'     slot 0x44 on TScreen.lHelp (field +0x1c, :TList) = TList.AddLast (:Object)
'   E8 targets: 0x004A7C20 bbStringConcat, 0x004A8590 GC free (inlined BBRELEASE, never
'   written in source), 0x004BC372 LoadImageChecked, 0x004C5549 GetText, 0x005B9690
'   _bbFloatToInt (emitted implicitly for the one Float->Int argument, prg_Fame's width).
'
' NOTES ON SHAPE (each is byte-observable and was read off the disassembly, not guessed)
'   * The image guard is the `If Not x` form of section 10.3 (mov / cmp bbNullObject /
'     setne al / movzx / cmp 0 / jne, 21 bytes at 0x0053BA75), not `If x = Null`.
'   * Six Locals.  bcc register-allocates x -> ebx and y -> edi and spills the rest:
'     w -> [ebp-4], h -> [ebp-8], wcol -> [ebp-0xC], wbar -> [ebp-0x10].  [ebp-0x14] is the
'     compiler's own Int->Float scratch for the single `fild` and is not a source Local.
'   * w / h / wcol are REASSIGNED for the lower half of the screen rather than redeclared --
'     the stores at 0x0053C351/0x0053C354/0x0053C35B go to the same three slots.
'   * `wcol / 2` is written out at every use.  bcc does no CSE, so each one re-emits the
'     cdq / and edx,1 / add / sar signed-divide-by-2 idiom; hoisting it into a Local would
'     shorten the function.
'   * prg_Fame's width argument is the only float expression: `10 + wcol * 1.5` emits
'     fld [10.0] / fild wcol / fmul [1.5] / faddp, i.e. the LEFT operand is pushed first.
'     Writing `wcol * 1.5 + 10` would have to emit fild/fmul/fadd-immediate instead.
'     No explicit Int() appears -- bcc inserts _bbFloatToInt for the Int parameter.
'   * `y :+ 45` / `x :+ 10` emit `add edi,0x2d` / `add ebx,0xa`; `y :+ h + 10` evaluates the
'     RHS first (`mov eax,[h] / add eax,0xa / add edi,eax`).  `y :- 40` is `sub edi,0x28`.
'   * Statement order inside a row is create-and-assign-to-Global, then advance x/y, then the
'     AddChild/AddGadget calls -- that is what the bytes show even though it reads oddly.
'   * String literals were read out of NSS5.exe with harness.read_string -- the oracle masks a
'     literal's ADDRESS, so their contents are not certified by the MATCH.  All 56 distinct
'     literals below were read at the exact address each call site pushes.  0x00C5D284 and
'     0x005C7D40 are the two zero-length BBStrings, i.e. "" (bcc picks a different empty-string
'     constant depending on the argument slot; the source is "" either way).
'!Global g_screen_home:TScreen
'!Global g_img_home_relationships:TImage
'!Global g_img_home_boot:TImage
'!Global g_img_home_money:TImage
'!Global g_img_home_star:TImage
'!Global g_img_shirt:TImage
'!Global g_img_finances:TImage
'!Global g_img_contract:TImage
'!Global g_img_star52:TImage
'!Global g_pan_profile:TPanel
'!Global g_lbl_teamcurrent1:TLabel
'!Global g_lbl_teamcurrent2:TLabel
'!Global g_lbl_rating1:TLabel
'!Global g_lbl_rating2:TLabel
'!Global g_lbl_value1:TLabel
'!Global g_lbl_value2:TLabel
'!Global g_prg_fame:TProgressBar
'!Global g_btn_stats:TButton
'!Global g_btn_contract:TButton
'!Global g_btn_finances:TButton
'!Global g_pan_happiness:TPanel
'!Global g_prg_happiness:TProgressBar
'!Global g_btn_happiness:TButton
'!Global g_pan_skills:TPanel
'!Global g_prg_home_skills:TProgressBar
'!Global g_btn_skills:TButton
'!Global g_pan_home_lifestyle:TPanel
'!Global g_prg_lifestyle:TProgressBar
'!Global g_btn_lifestyle:TButton
'!Global g_pan_achievements:TPanel
'!Global g_prg_home_achievements:TProgressBar
'!Global g_btn_achievements:TButton
'!Global g_pan_stable:TPanel
'!Global g_pan_money:TPanel
'!Global g_lbl_bank:TLabel
'!Global g_prg_energy:TProgressBar
'!Global g_btn_play:TButton
'!Global g_btn_main:TButton
'!Global g_btn_help:TButton
'!Global g_btn_options:TButton
'!Global g_btn_quit:TButton
'!Global g_iconpath:String
'!Global g_skinpath:String
'!Global g_screenw:Int
'!Global g_screenh:Int
	Function CreateScreen()
		g_screen_home = TScreen.CreateScreen("home", Null, Null, Null)
		If Not g_img_home_relationships
			g_img_home_relationships = LoadImageChecked(g_iconpath + "Relationships.png", -1)
			g_img_home_boot = LoadImageChecked(g_iconpath + "Boot28.png", -1)
			g_img_home_money = LoadImageChecked(g_iconpath + "Money.png", -1)
			g_img_home_star = LoadImageChecked(g_iconpath + "Star.png", -1)
			g_img_shirt = LoadImageChecked(g_iconpath + "Shirt.png", -1)
			g_img_finances = LoadImageChecked(g_iconpath + "Finances.png", -1)
			g_img_contract = LoadImageChecked(g_iconpath + "Contract.png", -1)
			g_img_star52 = LoadImageChecked(g_skinpath + "GameMedia/Images/Interface/Star52.png", -1)
		End If
		g_screen_home.AddGadget(g_pan_stable)
		g_screen_home.AddGadget(g_pan_money)
		Local w:Int = g_screenw - 20
		Local x:Int = 10
		Local y:Int = 70
		Local wcol:Int = (g_screenw - 60) / 3
		Local h:Int = 55
		g_pan_profile = TPanel.CreatePanel("pan_profile", GetText("Profile"), x, y, w, 35, "FFFFFF", "FFFFFF", 3, 0.8, 1, 205, 0)
		y :+ 45
		x :+ 10
		g_screen_home.AddGadget(g_pan_profile)
		g_lbl_teamcurrent1 = TLabel.CreateLabel("lbl_TeamCurrent1", GetText("Club"), x, y, wcol + 5, h, 3, "FFFFFF", "FFFFFF", 1.0, 4, 0, 1, 1, Null, 1, 0, 0, 0, "", 0)
		g_lbl_teamcurrent2 = TLabel.CreateLabel("lbl_TeamCurrent2", "", x + wcol + 5, y, wcol + 5, h, 3, "888888", "FFFFFF", 1.0, 5, 0, 1, 1, Null, 1, 0, 0, 0, "", 0)
		y :+ h + 10
		g_lbl_rating1 = TLabel.CreateLabel("lbl_Rating1", GetText("Rating"), x, y, wcol / 2, h, 3, "FFFFFF", "FFFFFF", 1.0, 4, 0, 1, 1, Null, 1, 0, 0, 0, "", 0)
		x :+ wcol / 2
		g_lbl_rating2 = TLabel.CreateLabel("lbl_Rating2", "", x, y, wcol / 2, h, 3, "888888", "FFFFFF", 1.0, 5, 0, 1, 1, Null, 1, 0, 0, 0, "", 0)
		x :+ wcol / 2 + 10
		g_lbl_value1 = TLabel.CreateLabel("lbl_Value1", GetText("Value"), x, y, wcol / 2, h, 3, "FFFFFF", "FFFFFF", 1.0, 4, 0, 1, 1, Null, 1, 0, 0, 0, "", 0)
		x :+ wcol / 2
		g_lbl_value2 = TLabel.CreateLabel("lbl_Value2", "", x, y, wcol / 2, h, 3, "888888", "FFFFFF", 1.0, 5, 0, 1, 1, Null, 1, 0, 0, 0, "", 0)
		y :+ h + 10
		g_pan_profile.AddChild(g_lbl_teamcurrent1)
		g_pan_profile.AddChild(g_lbl_teamcurrent2)
		g_pan_profile.AddChild(g_lbl_rating1)
		g_pan_profile.AddChild(g_lbl_rating2)
		g_pan_profile.AddChild(g_lbl_value1)
		g_pan_profile.AddChild(g_lbl_value2)
		x = 20
		g_pan_profile.AddChild(TLabel.CreateLabel("lbl_Fame", GetText("Fame"), x, y, wcol / 2, h, 3, "FFFFFF", "FFFFFF", 1.0, 4, 1, 0, 1, Null, 1, 0, 0, 0, "", 0))
		g_prg_fame = TProgressBar.CreateProgressBar("prg_Fame", "", x + wcol / 2, y, 10 + wcol * 1.5, h, 3, "FFFFFF", "FFFFFF", "FFFFFF", 0.8, 5, g_img_star52)
		g_pan_profile.AddChild(g_prg_fame)
		x = g_screenw - wcol - 20
		y = 115
		g_btn_contract = TButton.CreateButton("btn_Contract", GetText("My Contract"), x, y, wcol, h, 1, 3, "FFFFFF", "FFFFFF", g_img_contract, TScreen_MyContract.SetUpScreen, 1.0, 1, "")
		y :+ h + 10
		g_btn_finances = TButton.CreateButton("btn_Finances", GetText("My Finances"), x, y, wcol, h, 1, 3, "FFFFFF", "FFFFFF", g_img_finances, TScreen_Finances.SetUpScreen, 1.0, 1, "")
		y :+ h + 10
		g_btn_stats = TButton.CreateButton("btn_Stats", GetText("My Stats"), x, y, wcol, h, 1, 3, "FFFFFF", "FFFFFF", g_img_shirt, TScreen_Stats.SetUpScreen, 1.0, 1, "")
		g_pan_profile.AddChild(g_btn_stats)
		g_pan_profile.AddChild(g_btn_finances)
		g_pan_profile.AddChild(g_btn_contract)
		w = (g_screenw - 30) / 2
		wcol = 50
		h = 50
		x = 10
		y = g_screenh / 2 + 20
		Local wbar:Int = w - wcol - 30
		g_pan_happiness = TPanel.CreatePanel("pan_happiness", GetText("Happiness"), x, y, w, 30, "FFFFFF", "FFFFFF", 3, 0.8, 1, 70, 0)
		y :+ 40
		x :+ 10
		g_screen_home.AddGadget(g_pan_happiness)
		g_prg_happiness = TProgressBar.CreateProgressBar("prg_Happiness", "", x, y, wbar, h, 3, "FFFFFF", "00FF00", "FFFFFF", 0.8, 1, Null)
		g_btn_happiness = TButton.CreateButton("btn_Happiness", "", x + wbar + 10, y, wcol, h, 1, 2, "FFFFFF", "FFFFFF", g_img_home_relationships, ButtonHappiness, 1.0, 1, GetText("tt_Happiness"))
		g_pan_happiness.AddChild(g_prg_happiness)
		g_pan_happiness.AddChild(g_btn_happiness)
		x = g_screenw / 2 + 5
		y :- 40
		g_pan_skills = TPanel.CreatePanel("pan_skills", GetText("Skills"), x, y, w, 30, "FFFFFF", "FFFFFF", 3, 0.8, 1, 70, 0)
		y :+ 40
		x :+ 10
		g_screen_home.AddGadget(g_pan_skills)
		g_prg_home_skills = TProgressBar.CreateProgressBar("prg_Skills", "", x, y, wbar, h, 3, "FFFFFF", "00FF00", "FFFFFF", 0.8, 1, Null)
		g_btn_skills = TButton.CreateButton("btn_Skills", "", x + wbar + 10, y, wcol, h, 1, 2, "FFFFFF", "FFFFFF", g_img_home_boot, TScreen_Abilities.SetUpScreen, 1.0, 1, GetText("tt_Training"))
		g_pan_skills.AddChild(g_prg_home_skills)
		g_pan_skills.AddChild(g_btn_skills)
		x = 10
		y :+ 70
		g_pan_home_lifestyle = TPanel.CreatePanel("pan_Lifestyle", GetText("Lifestyle"), x, y, w, 30, "FFFFFF", "FFFFFF", 3, 0.8, 1, 70, 0)
		y :+ 40
		x :+ 10
		g_screen_home.AddGadget(g_pan_home_lifestyle)
		g_prg_lifestyle = TProgressBar.CreateProgressBar("prg_Lifestyle", "", x, y, wbar, h, 3, "FFFFFF", "00FF00", "FFFFFF", 0.8, 1, Null)
		g_btn_lifestyle = TButton.CreateButton("btn_Lifestyle", "", x + wbar + 10, y, wcol, h, 1, 2, "FFFFFF", "FFFFFF", g_img_home_money, TScreen_Shop.SetUpScreen, 1.0, 1, GetText("tt_Shop"))
		g_pan_home_lifestyle.AddChild(g_prg_lifestyle)
		g_pan_home_lifestyle.AddChild(g_btn_lifestyle)
		x = g_screenw / 2 + 5
		y :- 40
		g_pan_achievements = TPanel.CreatePanel("pan_Achievements", GetText("Achievements"), x, y, w, 30, "FFFFFF", "FFFFFF", 3, 0.8, 1, 70, 0)
		y :+ 40
		x :+ 10
		g_screen_home.AddGadget(g_pan_achievements)
		g_prg_home_achievements = TProgressBar.CreateProgressBar("prg_Achievements", "", x, y, wbar, h, 3, "FFFFFF", "00FF00", "FFFFFF", 0.8, 1, Null)
		g_btn_achievements = TButton.CreateButton("btn_Achievements", "", x + wbar + 10, y, wcol, h, 1, 2, "FFFFFF", "FFFFFF", g_img_home_star, TScreen_Achievements.SetUpScreen, 1.0, 1, GetText("tt_Achievements"))
		g_pan_achievements.AddChild(g_prg_home_achievements)
		g_pan_achievements.AddChild(g_btn_achievements)
		g_screen_home.lHelp.AddLast(THelpBox.Create(g_lbl_bank, 0, 0, 0, 0, GetText("CHELP_BANK"), 1, 2))
		g_screen_home.lHelp.AddLast(THelpBox.Create(g_prg_energy, 0, 0, 0, 0, GetText("CHELP_ENERGY"), 1, 2))
		g_screen_home.lHelp.AddLast(THelpBox.Create(g_btn_main, 0, 0, 0, 0, GetText("CHELP_MAINBUTTONS"), 2, 2))
		g_screen_home.lHelp.AddLast(THelpBox.Create(g_btn_play, 0, 0, 0, 0, GetText("CHELP_PLAYBUTTON"), 2, 2))
		g_screen_home.lHelp.AddLast(THelpBox.Create(g_btn_options, 0, 0, 0, 0, GetText("CHELP_OPTIONSBUTTON"), 1, 2))
		g_screen_home.lHelp.AddLast(THelpBox.Create(g_btn_help, 0, 0, 0, 0, GetText("CHELP_HELPBUTTON"), 1, 2))
		g_screen_home.lHelp.AddLast(THelpBox.Create(g_btn_quit, 0, 0, 0, 0, GetText("CHELP_QUITBUTTON"), 1, 2))
	End Function
