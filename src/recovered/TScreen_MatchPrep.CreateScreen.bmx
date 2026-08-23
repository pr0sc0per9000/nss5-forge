' TScreen_MatchPrep.CreateScreen
' VA 0x0055C09B   6249 bytes   vtable slot 0x30   sig ()i
' byte-identical vs NSS5.exe (6249/6249, mode=reloc, NSS5_NO_LEARN=1, four separate
' harness.try_method process launches, worker 275)
'
' === WHAT CLOSED IT (worker 275): wnum is THREE Locals in the original, not one. ===
' Prior passes had the statement order and expression shape already instruction-for-
' instruction correct (6208 bytes, delta -41, 82 gaps, delta_accounted COMPLETE) and were
' blocked on the register map: ours {y,h} in registers against the original's {y,wnum}.
' Reference counts y=82, h=50, x=36, w=29, wnum=28 are not a tie, so declaration order
' (18.2/18.3) could not reach it, and the six allocator knobs are refuted. The remaining
' lever was liveness, and the answer is that the single `wnum` we wrote is the union of
' three DISJOINT live ranges the original keeps as three separate Locals:
'   wnum  = 200  read by lbl_Selection and lbl_Status                 (Selection/Status row)
'   wnum2 = 265  read by pan_abilities and the 7 ability bars         (Abilities panel)
'   wnum3 = 160  read by the 6 Kit buttons, 6 Kit bars and prg_Energy (Kit Bag panel)
' Writing them as three Locals emits exactly the same bytes -- `Local wnum2:Int = 265` and
' `wnum = 265` both compile to one `mov reg,265` at that point -- and computes exactly the
' same values, because no generation is ever read before its own write. All three colour
' into the SAME register (edi), so no frame slot is consumed and `sub esp,0xc` is unchanged.
'
' MECHANISM, MEASURED (walloc_report instrumentation extended with a per-block live_in /
' live_out dump; block_count is literally 1 + #blocks where a value is live-in AND
' live-out, cgallocregs.cpp createGraph). Pass-1 numbers, before -> after:
'   name   usage      degree     block_count   round-1 cost       outcome
'   x       38        238->240    21           .00819 -> .00811   [ebp-0xc] -> [ebp-8]
'   y       65        238->240    21           .01401 -> .01388   ebx (unchanged)
'   h       50        240->242    23           .00984 -> .00975   edi -> [ebp-4]
'   w       29        221->223    18           .00736 -> .00729   [ebp-8] -> [ebp-0xc]
'   wnum    26 -> 3   219->23     18 -> 1      .00660 -> .13043   [ebp-0xc] -> edi
'   wnum2         9         101          7               .01273   edi
'   wnum3        14         111         12               .01051   edi
' h's block_count did NOT move (23 both sides); only the wnum family's did. That flips the
' round-1 cost ORDER from  wnum < w < x < h  to  w < x < h < wnum3 < wnum2 < y < wnum, so
' spill() picks w, then x, then h -- and selectRegs, popping in reverse, fails to colour
' h, x, w in that order, handing out [ebp-4], [ebp-8], [ebp-0xc]. That is the original's
' storage map exactly. The margin that decides it is wnum3 vs h, .01051 vs .00975 (7.8%),
' and it is set by wnum3's degree of 111: much above ~119 and wnum3 would have been
' spilled first and grown the frame.
'
' WHY OURS WAS 41 BYTES SHORT, in one sentence: h has 50 references and wnum 26, so keeping
' h in a register and spilling wnum buys about 24 references' worth of shorter encodings.
' The original makes the opposite trade and is longer for it.
'
' PER-REFERENCE EVIDENCE (the census the block-level argument rests on, and what earlier
' passes could not see because block_count was only ever read as a single number): the
' fused wnum is live-in AND live-out in blocks 22..27 and 31..41 -- 17 blocks, +1 = 18.
' `w` is live-in AND live-out in EXACTLY THE SAME 17 blocks, which is why the previous
' header's "wnum's block_count can never fall below w's 18" was true as stated and still
' not the end of the story: it is a fact about the FUSED variable, and the fusing was the
' defect. Split, the three parts are live-through 0, 6 and 11 blocks respectively.
'
' CORRECTION TO THE PREVIOUS HEADER. It stated: "Any source that SPLIT wnum into
' per-generation Locals would add a spilled node (allocLocal never reuses a slot) and grow
' the frame, so the split idea is DISPROVED without needing a build." That reasoning is
' wrong and the build disproves it. allocLocal never reusing a slot only bites values that
' FAIL TO COLOUR; three Locals with disjoint live ranges do not interfere, share one
' register, and consume no slot at all. Measured frame after the split: 3 slots,
' sub esp,0xc, identical to before and to the original. The conclusion drawn from that
' argument -- that the residual was a bcc 1.4x-vs-1.50 difference in how createGraph
' computes its inputs -- is withdrawn with it: shipped 1.50 reproduces the original
' exactly once the source is right.
'
' NEGATIVES FROM THIS PASS, worth keeping:
'  * Splitting `w` the same way is NOT wanted and was not done. w's three generations
'    (185/100/195) live in [ebp-0xc] in the original, i.e. w must stay spilled; raising its
'    cost by splitting would move it out of the victim set and break the map.
'  * The walloc census was re-measured a third time before any edit and reproduced
'    bit-for-bit (x 38/238/21, y 65/238/21, h 50/240/23, w 29/221/18, wnum 26/219/18).
'    The pre-edit numbers in this file were never in doubt; their interpretation was.
'  * This is not a near-tie case: costs at the pick point are separated by more than 7%
'    and the verdict reproduced on four independent process launches.
'
' PRIOR PASSES (kept -- the source-shape fixes below are what made the register map the
' ONLY remaining defect, and every one of them is still required):
'   1. `y :+ h + 10` sits BEFORE the AddGadget/AddChild of the gadget just stored, never
'      after (12 per-row statements; prg_Heading and prg_Energy correctly have none).
'   2. There is no `y = 130` before pan_abilities; the original reaches 130 by running
'      `y :+ h + 10` while h is still 50, after g_lbl_Status is stored and before its
'      AddGadget.
'   3. pan_abilities' x argument is plain `x`, with `x :+ 10` AFTER the panel, between
'      `y :+ h + 10` and AddGadget. Mirrors pan_health.
'   4. pan_abilities' width is `w + wnum2 + 20`, not the literal 385.
'   5. After AddGadget(pan_health) the order is `wnum3 = 160` THEN `w = 195`.
'   6. Local DECLARATION ORDER of the top five is x, y, h, w, wnum, confirmed from the
'      original's own init block at 0x0055C75B, not assumed.
'   7. pan_nav is not a stored Global; pan_health's width is `790 - x`.
' Build/verify: NSS5_NO_LEARN=1, harness.try_method('TScreen_MatchPrep','CreateScreen', body)
' with body = scripts/reverify.py:body_of() applied to this file.
'!Global g_screen_matchprep:TScreen
'!Global g_pan_abilities:TPanel
'!Global g_pan_health:TPanel
'!Global g_img_star:TImage
'!Global g_img_drugsboost:TImage
'!Global g_img_boozeboost:TImage
'!Global g_img_shinpadsboost:TImage
'!Global g_img_bootboost:TImage
'!Global g_img_painkiller:TImage
'!Global g_img_drugs28:TImage
'!Global g_img_nrg28:TImage
'!Global g_img_booze28:TImage
'!Global g_img_shinpads28:TImage
'!Global g_img_boot28:TImage
'!Global g_img_arrowr:TImage
'!Global g_img_eye:TImage
'!Global g_img_helpicon:TImage
'!Global g_img_backicon:TImage
'!Global g_img_playicon:TImage
'!Global g_mediapath:String
'!Global g_skinpath:String
'!Global g_screenwidth:Int
'!Global g_screenheight:Int
'!Global g_prg_pace:TProgressBar
'!Global g_prg_flair:TProgressBar
'!Global g_prg_tackling:TProgressBar
'!Global g_prg_dribbling:TProgressBar
'!Global g_prg_passing:TProgressBar
'!Global g_prg_shooting:TProgressBar
'!Global g_prg_heading:TProgressBar
'!Global g_btn_drugs:TButton
'!Global g_btn_booze:TButton
'!Global g_btn_shinpads:TButton
'!Global g_btn_boots:TButton
'!Global g_btn_injury:TButton
'!Global g_btn_nrg:TButton
'!Global g_prg_drugs:TProgressBar
'!Global g_prg_booze:TProgressBar
'!Global g_prg_shinpads:TProgressBar
'!Global g_prg_boots:TProgressBar
'!Global g_prg_injury:TProgressBar
'!Global g_prg_nrg:TProgressBar
'!Global g_prg_energy:TProgressBar
'!Global g_pan_title:TPanel
'!Global g_lbl_cash:TLabel
'!Global g_btn_play:TButton
'!Global g_lbl_Selection:TLabel
'!Global g_lbl_Status:TLabel
	Function CreateScreen()
		g_screen_matchprep = TScreen.CreateScreen("matchprep", Null, Null, Null)
		If Not g_img_star
			g_img_star = LoadImageChecked(g_skinpath + "GameMedia/Images/Interface/Star52.png", -1)
			g_img_drugs28 = LoadImageChecked(g_mediapath + "Drugs28.png", -1)
			g_img_drugsboost = LoadImageChecked(g_mediapath + "DrugsBoost.png", -1)
			g_img_nrg28 = LoadImageChecked(g_mediapath + "NRG28.png", -1)
			g_img_boozeboost = LoadImageChecked(g_mediapath + "BoozeBoost.png", -1)
			g_img_booze28 = LoadImageChecked(g_mediapath + "Booze28.png", -1)
			g_img_shinpadsboost = LoadImageChecked(g_mediapath + "ShinPadsBoost.png", -1)
			g_img_shinpads28 = LoadImageChecked(g_mediapath + "ShinPads28.png", -1)
			g_img_bootboost = LoadImageChecked(g_mediapath + "BootBoost.png", -1)
			g_img_boot28 = LoadImageChecked(g_mediapath + "Boot28.png", -1)
			g_img_painkiller = LoadImageChecked(g_mediapath + "PainKiller.png", -1)
			g_img_arrowr = LoadImageChecked(g_mediapath + "ArrowR.png", -1)
			g_img_eye = LoadImageChecked(g_mediapath + "Eye.png", -1)
		End If
		g_pan_title = TPanel.CreatePanel("pan_title", GetText("Match Preparation"), 0, 0, g_screenwidth, 60, "FFFFFF", "FFFFFF", 4, 1.0, 0, 0, 1)
		g_screen_matchprep.AddGadget(g_pan_title)
		g_pan_title.AddChild(TLabel.CreateLabel("lbl_bank", GetText("Bank"), g_screenwidth - 160, 10, 100, 20, 2, "FFFFFF", "FFFFFF", 1.0, 2, 0, 1, 1, Null, 1, 0, 0, 0, "", 0))
		g_lbl_cash = TLabel.CreateLabel("lbl_cash", "", g_screenwidth - 160, 30, 100, 20, 2, "888888", "FFFFFF", 1.0, 3, 0, 1, 1, Null, 1, 0, 0, 0, "", 0)
		g_pan_title.AddChild(g_lbl_cash)
		g_pan_title.AddChild(TButton.CreateButton("btn_help", "", g_screenwidth - 50, 10, 40, 40, 1, 2, "FFFFFF", "FFFFFF", g_img_helpicon, TScreen.ButtonHelp, 1.0, 1, ""))
		g_screen_matchprep.AddGadget(TPanel.CreatePanel("pan_nav", "", 0, g_screenheight - 60, g_screenwidth, 60, "FFFFFF", "FFFFFF", 3, 1.0, 0, 0, 0))
		g_screen_matchprep.AddGadget(TButton.CreateButton("btn_quit", "", 10, g_screenheight - 50, 120, 40, 1, 2, "FFFFFF", "FFFFFF", g_img_backicon, TScreen_WorldMap.SetUpScreen, 1.0, 1, GetText("tt_Back")))
		g_screen_matchprep.AddGadget(TButton.CreateButton("btn_skip", GetText("Skip Match"), 300, g_screenheight - 50, 200, 40, 1, 3, "FFFFFF", "FFFFFF", g_img_arrowr, TScreen_MatchPrep.ButtonSkipMatch, 1.0, 1, ""))
		g_btn_play = TButton.CreateButton("btn_play", "", g_screenwidth - 130, g_screenheight - 50, 120, 40, 1, 3, "FFFFFF", "FFFFFF", g_img_playicon, TScreen_MatchPrep.ButtonPlay, 1.0, 1, GetText("tt_Proceed"))
		g_screen_matchprep.AddGadget(g_btn_play)
		Local x:Int = 10
		Local y:Int = 70
		Local h:Int = 50
		Local w:Int = 185
		Local wnum:Int = 200
		g_screen_matchprep.AddGadget(TLabel.CreateLabel("lbl_Selection1", GetText("team_Selection"), x, y, w, h, 3, "FFFFFF", "FFFFFF", 1.0, 4, 1, 0, 1, Null, 1, 0, 0, 0, "", 0))
		g_lbl_Selection = TLabel.CreateLabel("lbl_Selection", "1st Team", x + w, y, wnum, h, 3, "888888", "FFFFFF", 1.0, 5, 1, 0, 1, Null, 1, 0, 0, 0, "", 0)
		g_screen_matchprep.AddGadget(g_lbl_Selection)
		g_screen_matchprep.AddGadget(TLabel.CreateLabel("lbl_Status1", GetText("Status"), 405, y, w, h, 3, "FFFFFF", "FFFFFF", 1.0, 4, 1, 0, 1, Null, 1, 0, 0, 0, "", 0))
		g_lbl_Status = TLabel.CreateLabel("lbl_Status", "", w + 405, y, wnum, h, 3, "888888", "FFFFFF", 1.0, 5, 1, 0, 1, Null, 1, 0, 0, 0, "", 0)
		y :+ h + 10
		g_screen_matchprep.AddGadget(g_lbl_Status)
		h = 40
		w = 100
		Local wnum2:Int = 265
		g_pan_abilities = TPanel.CreatePanel("pan_abilities", GetText("Abilities"), x, y, w + wnum2 + 20, h, "FFFFFF", "FFFFFF", 3, 0.8, 1, 360, 0)
		y :+ h + 10
		x :+ 10
		g_screen_matchprep.AddGadget(g_pan_abilities)
		g_pan_abilities.AddChild(TLabel.CreateLabel("lbl_Pace", GetText("Pace"), x, y, w, h, 3, "FFFFFF", "FFFFFF", 1.0, 4, 1, 0, 1, Null, 1, 0, 0, 0, "", 0))
		g_prg_pace = TProgressBar.CreateProgressBar("prg_Pace", "", x + w, y, wnum2, h, 3, "FFFFFF", SkillColour(1), "FFFFFF", 0.8, 5, g_img_star)
		y :+ h + 10
		g_pan_abilities.AddChild(g_prg_pace)
		g_pan_abilities.AddChild(TLabel.CreateLabel("lbl_Flair", GetText("Flair"), x, y, w, h, 3, "FFFFFF", "FFFFFF", 1.0, 4, 1, 0, 1, Null, 1, 0, 0, 0, "", 0))
		g_prg_flair = TProgressBar.CreateProgressBar("prg_Flair", "", x + w, y, wnum2, h, 3, "FFFFFF", SkillColour(7), "FFFFFF", 0.8, 5, g_img_star)
		y :+ h + 10
		g_pan_abilities.AddChild(g_prg_flair)
		g_pan_abilities.AddChild(TLabel.CreateLabel("lbl_Tackling", GetText("Tackling"), x, y, w, h, 3, "FFFFFF", "FFFFFF", 1.0, 4, 1, 0, 1, Null, 1, 0, 0, 0, "", 0))
		g_prg_tackling = TProgressBar.CreateProgressBar("prg_Tackling", "", x + w, y, wnum2, h, 3, "FFFFFF", SkillColour(3), "FFFFFF", 0.8, 5, g_img_star)
		y :+ h + 10
		g_pan_abilities.AddChild(g_prg_tackling)
		g_pan_abilities.AddChild(TLabel.CreateLabel("lbl_Dribbling", GetText("Dribbling"), x, y, w, h, 3, "FFFFFF", "FFFFFF", 1.0, 4, 1, 0, 1, Null, 1, 0, 0, 0, "", 0))
		g_prg_dribbling = TProgressBar.CreateProgressBar("prg_Dribbling", "", x + w, y, wnum2, h, 3, "FFFFFF", SkillColour(2), "FFFFFF", 0.8, 5, g_img_star)
		y :+ h + 10
		g_pan_abilities.AddChild(g_prg_dribbling)
		g_pan_abilities.AddChild(TLabel.CreateLabel("lbl_Passing", GetText("Passing"), x, y, w, h, 3, "FFFFFF", "FFFFFF", 1.0, 4, 1, 0, 1, Null, 1, 0, 0, 0, "", 0))
		g_prg_passing = TProgressBar.CreateProgressBar("prg_Passing", "", x + w, y, wnum2, h, 3, "FFFFFF", SkillColour(4), "FFFFFF", 0.8, 5, g_img_star)
		y :+ h + 10
		g_pan_abilities.AddChild(g_prg_passing)
		g_pan_abilities.AddChild(TLabel.CreateLabel("lbl_Shooting", GetText("Shooting"), x, y, w, h, 3, "FFFFFF", "FFFFFF", 1.0, 4, 1, 0, 1, Null, 1, 0, 0, 0, "", 0))
		g_prg_shooting = TProgressBar.CreateProgressBar("prg_Shooting", "", x + w, y, wnum2, h, 3, "FFFFFF", SkillColour(6), "FFFFFF", 0.8, 5, g_img_star)
		y :+ h + 10
		g_pan_abilities.AddChild(g_prg_shooting)
		g_pan_abilities.AddChild(TLabel.CreateLabel("lbl_Heading", GetText("Heading"), x, y, w, h, 3, "FFFFFF", "FFFFFF", 1.0, 4, 1, 0, 1, Null, 1, 0, 0, 0, "", 0))
		g_prg_heading = TProgressBar.CreateProgressBar("prg_Heading", "", x + w, y, wnum2, h, 3, "FFFFFF", SkillColour(5), "FFFFFF", 0.8, 5, g_img_star)
		g_pan_abilities.AddChild(g_prg_heading)
		x = 405
		y = 130
		g_pan_health = TPanel.CreatePanel("pan_health", GetText("Kit Bag"), x, y, 790 - x, h, "FFFFFF", "FFFFFF", 3, 0.8, 1, 360, 0)
		y :+ h + 10
		x :+ 10
		g_screen_matchprep.AddGadget(g_pan_health)
		Local wnum3:Int = 160
		w = 195
		g_btn_drugs = TButton.CreateButton("btn_Drugs", FormatMoney(1000, 0), x, y, wnum3, h, 1, 3, "FFFFFF", "FFFFFF", g_img_drugs28, TScreen_MatchPrep.ButtonDrugs, 1.0, 1, GetText("tt_BuyDrugs"))
		g_pan_health.AddChild(g_btn_drugs)
		g_prg_drugs = TProgressBar.CreateProgressBar("prg_Drugs", GetText("Enhancers"), x + wnum3 + 10, y, w, h, 3, "FFFFFF", "38FF24", "FFFFFF", 0.8, 1, Null)
		y :+ h + 10
		g_pan_health.AddChild(g_prg_drugs)
		g_btn_booze = TButton.CreateButton("btn_Booze", FormatMoney(100, 0), x, y, wnum3, h, 1, 3, "FFFFFF", "FFFFFF", g_img_booze28, TScreen_MatchPrep.ButtonBooze, 1.0, 1, GetText("tt_BuyBooze"))
		g_pan_health.AddChild(g_btn_booze)
		g_prg_booze = TProgressBar.CreateProgressBar("prg_Booze", GetText("Booze"), x + wnum3 + 10, y, w, h, 3, "FFFFFF", "FF9900", "FFFFFF", 0.8, 1, Null)
		y :+ h + 10
		g_pan_health.AddChild(g_prg_booze)
		g_btn_shinpads = TButton.CreateButton("btn_ShinPads", FormatMoney(500, 0), x, y, wnum3, h, 1, 3, "FFFFFF", "FFFFFF", g_img_shinpads28, TScreen_MatchPrep.ButtonShinPads, 1.0, 1, GetText("tt_BuyShinPads"))
		g_pan_health.AddChild(g_btn_shinpads)
		g_prg_shinpads = TProgressBar.CreateProgressBar("prg_ShinPads", "", x + wnum3 + 10, y, w, h, 3, "FFFFFF", "00FF00", "FFFFFF", 0.8, 1, Null)
		y :+ h + 10
		g_pan_health.AddChild(g_prg_shinpads)
		g_btn_boots = TButton.CreateButton("btn_Boots", "", x, y, wnum3, h, 1, 3, "FFFFFF", "FFFFFF", g_img_boot28, TScreen_BootShop.SetUpScreen, 1.0, 1, GetText("tt_BuyBoots"))
		g_pan_health.AddChild(g_btn_boots)
		g_prg_boots = TProgressBar.CreateProgressBar("prg_Boots", "", x + wnum3 + 10, y, w, h, 3, "FFFFFF", "00FF00", "FFFFFF", 0.8, 1, Null)
		y :+ h + 10
		g_pan_health.AddChild(g_prg_boots)
		g_btn_injury = TButton.CreateButton("btn_Injury", FormatMoney(0, 0), x, y, wnum3, h, 1, 3, "FFFFFF", "FFFFFF", g_img_painkiller, TScreen_MatchPrep.ButtonPainKillers, 1.0, 1, GetText("tt_BuyPainKillers"))
		g_pan_health.AddChild(g_btn_injury)
		g_prg_injury = TProgressBar.CreateProgressBar("prg_Injury", "", x + wnum3 + 10, y, w, h, 3, "FFFFFF", "FF0000", "FFFFFF", 0.8, 1, Null)
		y :+ h + 10
		g_pan_health.AddChild(g_prg_injury)
		g_btn_nrg = TButton.CreateButton("btn_NRG", FormatMoney(250, 0), x, y, wnum3, h, 1, 3, "FFFFFF", "FFFFFF", g_img_nrg28, TScreen_MatchPrep.ButtonNRG, 1.0, 1, GetText("tt_BuyNRG"))
		g_pan_health.AddChild(g_btn_nrg)
		g_prg_nrg = TProgressBar.CreateProgressBar("prg_NRG", "NRG", x + wnum3 + 10, y, w, h, 3, "FFFFFF", "38FF24", "FFFFFF", 0.8, 1, Null)
		y :+ h + 10
		g_pan_health.AddChild(g_prg_nrg)
		g_prg_energy = TProgressBar.CreateProgressBar("prg_Energy", "", x, y, wnum3 + w + 10, h, 3, "FFFFFF", "00FF00", "FFFFFF", 0.8, 1, Null)
		g_pan_health.AddChild(g_prg_energy)
		g_screen_matchprep.lHelp.AddLast(THelpBox.Create(g_prg_pace, 0, 0, 0, 0, GetText("CHELP_ABILITIES"), 1, 2))
		g_screen_matchprep.lHelp.AddLast(THelpBox.Create(g_btn_drugs, 0, 0, 0, 0, GetText("CHELP_ENHANCERS"), 1, 2))
		g_screen_matchprep.lHelp.AddLast(THelpBox.Create(g_btn_booze, 0, 0, 0, 0, GetText("CHELP_BOOZE"), 1, 2))
		g_screen_matchprep.lHelp.AddLast(THelpBox.Create(g_btn_shinpads, 0, 0, 0, 0, GetText("CHELP_SHINPADS"), 1, 2))
		g_screen_matchprep.lHelp.AddLast(THelpBox.Create(g_btn_boots, 0, 0, 0, 0, GetText("CHELP_BOOTS"), 2, 2))
		g_screen_matchprep.lHelp.AddLast(THelpBox.Create(g_btn_injury, 0, 0, 0, 0, GetText("CHELP_PAINKILLERS"), 2, 2))
		g_screen_matchprep.lHelp.AddLast(THelpBox.Create(g_btn_nrg, 0, 0, 0, 0, GetText("CHELP_NRG"), 2, 2))
		g_screen_matchprep.lHelp.AddLast(THelpBox.Create(g_screen_matchprep.GetGadgetByName("btn_skip"), 0, 0, 0, 0, GetText("CHELP_SKIPMATCH"), 2, 2))
	End Function
