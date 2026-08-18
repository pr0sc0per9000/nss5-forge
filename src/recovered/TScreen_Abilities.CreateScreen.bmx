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
' TScreen_Abilities.CreateScreen
' VA 0x0053CE7B   6641 bytes   mode=reloc   byte-identical vs NSS5.exe
' (6641/6641, original length from Ghidra's inventory, reloc_masked=593)
' KIND=Function (static, no implicit Self), SIG ()i, class-table slot 0x30
'
' ASSUMPTIONS
'   Module Globals (addresses are fact, NAMES are ours -- module Globals have no debug record):
'     0x00C66A68 -> g_screen_abilities:TScreen     (construction site = TScreen.CreateScreen)
'     0x00C66A6C -> g_img_training:TImage          (assigned from LoadImageChecked; globals_final
'                                                   says only "Object, no call-site typing")
'     0x00C66A70 -> g_img_star:TImage              (same; assigned from LoadImageChecked)
'     0x00C66A74 -> g_pan_abilities:TPanel         0x00C66A98 -> g_pan_levels:TPanel
'     0x00C66768 -> g_pan_stable:TPanel            0x00C667B0 -> g_pan_money:TPanel
'                   (both are panels built by OTHER screens and re-added here; the names are
'                    guesses at their role, the Type TPanel is from their construction sites)
'     0x00C6F170 -> g_iconpath:String   0x00C6E950 -> g_skinpath:String
'                   (0x00C6F170 is listed Int in globals_final.tsv and is WRONG: it is pushed
'                    straight into bbStringConcat here.  0x00C6E950 is hand-verified String.)
'     TProgressBar Globals, all typed by construction site (1 site each):
'       0x00C66A78 pace   0x00C66A7C dribbling  0x00C66A80 tackling  0x00C66A84 passing
'       0x00C66A88 shooting 0x00C66A8C heading  0x00C66A90 flair     0x00C66A94 skills
'       0x00C66A9C longshots 0x00C66AA0 finishing 0x00C66AA4 crossing 0x00C66AA8 freekicks
'       0x00C66AAC corners 0x00C66AB0 penalties 0x00C66AB4 positioning
'       0x00C66AB8 shortpassing 0x00C66ABC longpassing 0x00C66AC0 aggression
'   Class-table slots resolved through globals_final.tsv / vtable_map.tsv:
'     0x00C61C64 = TScreen+0x38      CreateScreen ($,:TImage,()i,()i):TScreen
'     0x00C63294 = TPanel+0x88       CreatePanel ($,$,i,i,i,i,$,$,i,f,i,i,i):TPanel
'     0x00C634C0 = TLabel+0x88       CreateLabel ($,$,i,i,i,i,i,$,$,f,i,i,i,i,:TImage,i,i,i,i,$,f):TLabel
'     0x00C637A8 = TProgressBar+0x88 CreateProgressBar ($,$,i,i,i,i,i,$,$,$,f,i,:TImage):TProgressBar
'     0x00C623CC = TButton+0x88      CreateButton ($,$,i,i,i,i,i,i,$,$,:TImage,()i,f,i,$):TButton
'     0x00C638BC = THelpBox+0x30     Create (:TGadget,i,i,i,i,$,i,i):THelpBox
'     0x00C66B7C = TScreen_Abilities+0x38 = ButtonTraining ()i  (same Type -> bare name)
'     slot 0x40 on a TScreen = TScreen.AddGadget (:TGadget)i
'     slot 0x74 on a TPanel  = TGadget.AddChild (:TGadget)i   (inherited)
'     slot 0x90 on a TScreen = TScreen.GetGadgetByName ($):TGadget
'     slot 0x44 on TScreen.lHelp (field +0x1c, :TList) = TList.AddLast (:Object)
'   E8 targets: 0x004A7C20 bbStringConcat, 0x004A8590 GC free (inlined BBRELEASE, never
'   written in source), 0x004BC372 LoadImageChecked, 0x004C5549 GetText, 0x005B9690
'   _bbFloatToInt (emitted implicitly for every Float->Int argument),
'   0x00507DCF SkillColour (src/recovered_module/SkillColour.bmx).
'
' NOTES ON SHAPE (each of these is byte-observable and was read off the disassembly)
'   * The image guard is the `If Not x` form of section 10.3 (mov/cmp/setne/movzx/cmp/jne,
'     21 bytes), not `If x = Null`.
'   * Six Locals, in the original's initialisation order: x, y, wnum, h, w, wbar.  y and h
'     are Float and every use as an Int argument goes through _bbFloatToInt implicitly --
'     no explicit Int() appears in the source.
'   * `y :+ 40.0` emits `fld y / fadd const / fstp y`, but `y :+ h + 10` emits
'     `fld h / fadd 10 / fld y / faddp / fstp y` -- the RHS is evaluated first when it is
'     not a bare constant.  Both forms occur here and they are NOT interchangeable.
'   * The argument-3 arithmetic is written in the original's exact left-to-right order
'     (`x + w + wbar + 20 + wnum`); reordering changes the add sequence.
'   * Statement order inside a row is create-assign / advance y / add-to-parent, which is
'     what the bytes show even though it reads oddly.
'   * The y step after the Shooting row is `h + 12`, not `h + 10` like every other row.
'   * The abilities section reuses `h` for the Skills summary row (h = 50.0); the levels
'     section reassigns x, y, w, h and introduces one more Local (style = 1).
'   * String literals were read out of NSS5.exe with harness.read_string -- the oracle masks
'     a literal's ADDRESS, so their contents are not certified by the MATCH.  Both 0x00C5D284
'     and 0x005C7D40 are zero-length BBStrings, i.e. "" (bcc picks a different empty-string
'     constant depending on the argument slot; source is "" either way).
'!Global g_screen_abilities:TScreen
'!Global g_img_training:TImage
'!Global g_img_star:TImage
'!Global g_pan_abilities:TPanel
'!Global g_pan_levels:TPanel
'!Global g_pan_stable:TPanel
'!Global g_pan_money:TPanel
'!Global g_iconpath:String
'!Global g_skinpath:String
'!Global g_prg_pace:TProgressBar
'!Global g_prg_dribbling:TProgressBar
'!Global g_prg_tackling:TProgressBar
'!Global g_prg_passing:TProgressBar
'!Global g_prg_shooting:TProgressBar
'!Global g_prg_heading:TProgressBar
'!Global g_prg_flair:TProgressBar
'!Global g_prg_skills:TProgressBar
'!Global g_prg_longshots:TProgressBar
'!Global g_prg_finishing:TProgressBar
'!Global g_prg_crossing:TProgressBar
'!Global g_prg_freekicks:TProgressBar
'!Global g_prg_corners:TProgressBar
'!Global g_prg_penalties:TProgressBar
'!Global g_prg_positioning:TProgressBar
'!Global g_prg_shortpassing:TProgressBar
'!Global g_prg_longpassing:TProgressBar
'!Global g_prg_aggression:TProgressBar
	Function CreateScreen()
		g_screen_abilities = TScreen.CreateScreen("abilities", Null, Null, Null)
		If Not g_img_training
			g_img_training = LoadImageChecked(g_iconpath + "Training.png", -1)
			g_img_star = LoadImageChecked(g_skinpath + "GameMedia/Images/Interface/Star52.png", -1)
		End If
		g_screen_abilities.AddGadget(g_pan_stable)
		g_screen_abilities.AddGadget(g_pan_money)
		Local x:Int = 10
		Local y:Float = 70.0
		Local wnum:Int = 50
		Local h:Float = 41.0
		Local w:Int = 120
		Local wbar:Int = 300
		g_pan_abilities = TPanel.CreatePanel("pan_abilities", GetText("Abilities"), x, y, 560, 30, "FFFFFF", "FFFFFF", 3, 0.8, 1, 430, 0)
		y :+ 40.0
		x :+ 10
		g_screen_abilities.AddGadget(g_pan_abilities)
		g_pan_abilities.AddChild(TLabel.CreateLabel("lbl_Pace", GetText("Pace"), x, y, w, h, 3, "FFFFFF", "FFFFFF", 1.0, 4, 1, 0, 1, Null, 1, 0, 0, 0, "", 0))
		g_prg_pace = TProgressBar.CreateProgressBar("prg_Pace", "", x + w, y, wbar, h, 3, "FFFFFF", SkillColour(1), "FFFFFF", 0.8, 5, g_img_star)
		g_pan_abilities.AddChild(g_prg_pace)
		g_pan_abilities.AddChild(TLabel.CreateLabel("lbl_PaceNum", "0", x + w + wbar + 10, y, wnum, h, 3, "888888", "FFFFFF", 1.0, 1, 0, 0, 1, Null, 1, 0, 0, 0, "", 0))
		g_pan_abilities.AddChild(TButton.CreateButton("btn_Pace", "", x + w + wbar + 20 + wnum, y, wnum, h, 1, 2, "FFFFFF", "FFFFFF", g_img_training, ButtonTraining, 1.0, 1, GetText("tt_PaceTraining")))
		y :+ h + 10
		g_pan_abilities.AddChild(TLabel.CreateLabel("lbl_Flair", GetText("Flair"), x, y, w, h, 3, "FFFFFF", "FFFFFF", 1.0, 4, 1, 0, 1, Null, 1, 0, 0, 0, "", 0))
		g_prg_flair = TProgressBar.CreateProgressBar("prg_Flair", "", x + w, y, wbar, h, 3, "FFFFFF", SkillColour(7), "FFFFFF", 0.8, 5, g_img_star)
		g_pan_abilities.AddChild(g_prg_flair)
		g_pan_abilities.AddChild(TLabel.CreateLabel("lbl_FlairNum", "0", x + w + wbar + 10, y, wnum, h, 3, "888888", "FFFFFF", 1.0, 1, 0, 0, 1, Null, 1, 0, 0, 0, "", 0))
		g_pan_abilities.AddChild(TButton.CreateButton("btn_Flair", "", x + w + wbar + 20 + wnum, y, wnum, h, 1, 2, "FFFFFF", "FFFFFF", g_img_training, ButtonTraining, 1.0, 1, GetText("tt_FlairTraining")))
		y :+ h + 10
		g_pan_abilities.AddChild(TLabel.CreateLabel("lbl_Tackling", GetText("Tackling"), x, y, w, h, 3, "FFFFFF", "FFFFFF", 1.0, 4, 1, 0, 1, Null, 1, 0, 0, 0, "", 0))
		g_prg_tackling = TProgressBar.CreateProgressBar("prg_Tackling", "", x + w, y, wbar, h, 3, "FFFFFF", SkillColour(3), "FFFFFF", 0.8, 5, g_img_star)
		g_pan_abilities.AddChild(g_prg_tackling)
		g_pan_abilities.AddChild(TLabel.CreateLabel("lbl_TacklingNum", "0", x + w + wbar + 10, y, wnum, h, 3, "888888", "FFFFFF", 1.0, 1, 0, 0, 1, Null, 1, 0, 0, 0, "", 0))
		g_pan_abilities.AddChild(TButton.CreateButton("btn_Tackling", "", x + w + wbar + 20 + wnum, y, wnum, h, 1, 2, "FFFFFF", "FFFFFF", g_img_training, ButtonTraining, 1.0, 1, GetText("tt_TacklingTraining")))
		y :+ h + 10
		g_pan_abilities.AddChild(TLabel.CreateLabel("lbl_Dribbling", GetText("Dribbling"), x, y, w, h, 3, "FFFFFF", "FFFFFF", 1.0, 4, 1, 0, 1, Null, 1, 0, 0, 0, "", 0))
		g_prg_dribbling = TProgressBar.CreateProgressBar("prg_Dribbling", "", x + w, y, wbar, h, 3, "FFFFFF", SkillColour(2), "FFFFFF", 0.8, 5, g_img_star)
		g_pan_abilities.AddChild(g_prg_dribbling)
		g_pan_abilities.AddChild(TLabel.CreateLabel("lbl_DribblingNum", "0", x + w + wbar + 10, y, wnum, h, 3, "888888", "FFFFFF", 1.0, 1, 0, 0, 1, Null, 1, 0, 0, 0, "", 0))
		g_pan_abilities.AddChild(TButton.CreateButton("btn_Dribbling", "", x + w + wbar + 20 + wnum, y, wnum, h, 1, 2, "FFFFFF", "FFFFFF", g_img_training, ButtonTraining, 1.0, 1, GetText("tt_DribblingTraining")))
		y :+ h + 10
		g_pan_abilities.AddChild(TLabel.CreateLabel("lbl_Passing", GetText("Passing"), x, y, w, h, 3, "FFFFFF", "FFFFFF", 1.0, 4, 1, 0, 1, Null, 1, 0, 0, 0, "", 0))
		g_prg_passing = TProgressBar.CreateProgressBar("prg_Passing", "", x + w, y, wbar, h, 3, "FFFFFF", SkillColour(4), "FFFFFF", 0.8, 5, g_img_star)
		g_pan_abilities.AddChild(g_prg_passing)
		g_pan_abilities.AddChild(TLabel.CreateLabel("lbl_PassingNum", "0", x + w + wbar + 10, y, wnum, h, 3, "888888", "FFFFFF", 1.0, 1, 0, 0, 1, Null, 1, 0, 0, 0, "", 0))
		g_pan_abilities.AddChild(TButton.CreateButton("btn_Passing", "", x + w + wbar + 20 + wnum, y, wnum, h, 1, 2, "FFFFFF", "FFFFFF", g_img_training, ButtonTraining, 1.0, 1, GetText("tt_PassingTraining")))
		y :+ h + 10
		g_pan_abilities.AddChild(TLabel.CreateLabel("lbl_Shooting", GetText("Shooting"), x, y, w, h, 3, "FFFFFF", "FFFFFF", 1.0, 4, 1, 0, 1, Null, 1, 0, 0, 0, "", 0))
		g_prg_shooting = TProgressBar.CreateProgressBar("prg_Shooting", "", x + w, y, wbar, h, 3, "FFFFFF", SkillColour(6), "FFFFFF", 0.8, 5, g_img_star)
		g_pan_abilities.AddChild(g_prg_shooting)
		g_pan_abilities.AddChild(TLabel.CreateLabel("lbl_ShootingNum", "0", x + w + wbar + 10, y, wnum, h, 3, "888888", "FFFFFF", 1.0, 1, 0, 0, 1, Null, 1, 0, 0, 0, "", 0))
		g_pan_abilities.AddChild(TButton.CreateButton("btn_Shooting", "", x + w + wbar + 20 + wnum, y, wnum, h, 1, 2, "FFFFFF", "FFFFFF", g_img_training, ButtonTraining, 1.0, 1, GetText("tt_ShootingTraining")))
		y :+ h + 12
		g_pan_abilities.AddChild(TLabel.CreateLabel("lbl_Heading", GetText("Heading"), x, y, w, h, 3, "FFFFFF", "FFFFFF", 1.0, 4, 1, 0, 1, Null, 1, 0, 0, 0, "", 0))
		g_prg_heading = TProgressBar.CreateProgressBar("prg_Heading", "", x + w, y, wbar, h, 3, "FFFFFF", SkillColour(5), "FFFFFF", 0.8, 5, g_img_star)
		g_pan_abilities.AddChild(g_prg_heading)
		g_pan_abilities.AddChild(TLabel.CreateLabel("lbl_HeadingNum", "0", x + w + wbar + 10, y, wnum, h, 3, "888888", "FFFFFF", 1.0, 1, 0, 0, 1, Null, 1, 0, 0, 0, "", 0))
		g_pan_abilities.AddChild(TButton.CreateButton("btn_Heading", "", x + w + wbar + 20 + wnum, y, wnum, h, 1, 2, "FFFFFF", "FFFFFF", g_img_training, ButtonTraining, 1.0, 1, GetText("tt_HeadingTraining")))
		y :+ h + 10
		h = 50.0
		g_pan_abilities.AddChild(TLabel.CreateLabel("lbl_Skills", GetText("Skills"), x, y + 1, w, h, 3, "FFFFFF", "FFFFFF", 1.0, 4, 1, 0, 1, Null, 1, 0, 0, 0, "", 0))
		g_prg_skills = TProgressBar.CreateProgressBar("prg_Skills", "", x + w, y + 1, wbar + wnum + wnum + 20, h, 3, "FFFFFF", "00FF00", "FFFFFF", 0.8, 5, Null)
		g_pan_abilities.AddChild(g_prg_skills)
		x = 580
		y = 70.0
		w = 190
		h = 32.25
		Local style:Int = 1
		g_pan_levels = TPanel.CreatePanel("pan_Levels", GetText("Ratings"), x, y, 210, 30, "FFFFFF", "FFFFFF", 3, 0.8, 1, 430, 0)
		y :+ 40.0
		x :+ 10
		g_screen_abilities.AddGadget(g_pan_levels)
		g_prg_positioning = TProgressBar.CreateProgressBar("prg_Positioning", GetText("Positioning"), x, y, w, h, 2, "FFFFFF", "00FF00", "FFFFFF", 0.8, style, Null)
		y :+ h + 10
		g_pan_levels.AddChild(g_prg_positioning)
		g_prg_shortpassing = TProgressBar.CreateProgressBar("prg_ShortPassing", GetText("Short Passing"), x, y, w, h, 2, "FFFFFF", "00FF00", "FFFFFF", 0.8, style, Null)
		y :+ h + 10
		g_pan_levels.AddChild(g_prg_shortpassing)
		g_prg_longpassing = TProgressBar.CreateProgressBar("prg_LongPassing", GetText("Long Passing"), x, y, w, h, 2, "FFFFFF", "00FF00", "FFFFFF", 0.8, style, Null)
		y :+ h + 10
		g_pan_levels.AddChild(g_prg_longpassing)
		g_prg_finishing = TProgressBar.CreateProgressBar("prg_Finishing", GetText("Finishing"), x, y, w, h, 2, "FFFFFF", "00FF00", "FFFFFF", 0.8, style, Null)
		y :+ h + 10
		g_pan_levels.AddChild(g_prg_finishing)
		g_prg_longshots = TProgressBar.CreateProgressBar("prg_LongShots", GetText("Long Shots"), x, y, w, h, 2, "FFFFFF", "00FF00", "FFFFFF", 0.8, style, Null)
		y :+ h + 10
		g_pan_levels.AddChild(g_prg_longshots)
		g_prg_crossing = TProgressBar.CreateProgressBar("prg_Crossing", GetText("Crossing"), x, y, w, h, 2, "FFFFFF", "00FF00", "FFFFFF", 0.8, style, Null)
		y :+ h + 10
		g_pan_levels.AddChild(g_prg_crossing)
		g_prg_freekicks = TProgressBar.CreateProgressBar("prg_FreeKicks", GetText("Free Kicks"), x, y, w, h, 2, "FFFFFF", "00FF00", "FFFFFF", 0.8, style, Null)
		y :+ h + 10
		g_pan_levels.AddChild(g_prg_freekicks)
		g_prg_corners = TProgressBar.CreateProgressBar("prg_Corners", GetText("Corners"), x, y, w, h, 2, "FFFFFF", "00FF00", "FFFFFF", 0.8, style, Null)
		y :+ h + 10
		g_pan_levels.AddChild(g_prg_corners)
		g_prg_penalties = TProgressBar.CreateProgressBar("prg_Penalties", GetText("Penalties"), x, y, w, h, 2, "FFFFFF", "00FF00", "FFFFFF", 0.8, style, Null)
		y :+ h + 10
		g_pan_levels.AddChild(g_prg_penalties)
		g_prg_aggression = TProgressBar.CreateProgressBar("prg_Aggression", GetText("Aggression"), x, y, w, h, 2, "FFFFFF", "00FF00", "FFFFFF", 0.8, style, Null)
		y :+ h + 10
		g_pan_levels.AddChild(g_prg_aggression)
		g_screen_abilities.lHelp.AddLast(THelpBox.Create(g_screen_abilities.GetGadgetByName("btn_Dribbling"), 0, 0, 0, 0, GetText("CHELP_TRAININGBUTTONS"), 2, 2))
		g_screen_abilities.lHelp.AddLast(THelpBox.Create(g_screen_abilities.GetGadgetByName("prg_Finishing"), 0, 0, 0, 0, GetText("CHELP_PLAYERRATINGS"), 2, 2))
	End Function
