' TScreen_MatchPrep.CreateScreen -- CANDIDATE, built on an earlier candidate.
' VA 0x0055c09b   6249 bytes   vtable slot 0x30   sig ()i
' NOT VERIFIED -- NOT A MATCH. VA 0x0055C09B. orig_len 6249.
' THIS BODY: our_len 6205, delta -44, 95 length-changing gaps. localise_diff.py reports
' "delta accounted for by gaps: -44 of -44 -> COMPLETE" (no tooling noise).
' Numerically FARTHER from zero than the earlier candidate's -21, but that -21 concealed
' THREE distinct, now-fixed, real defects; every one of the 95 remaining gaps is the
' SAME single unresolved defect (see below), uniform across all 13 gadget rows -- i.e. this
' candidate is semantically cleaner even though |delta| grew. Do not revert to the -21 form
' without re-introducing those 3 known bugs.
' Fixes applied (all independently confirmed by gaps fully DISAPPEARING from the diff, not
' just shrinking):
'   1. pan_nav is NOT a stored Global -- inlined as
'      g_screen_matchprep.AddGadget(TPanel.CreatePanel("pan_nav", ...)). Closed gaps at
'      orig+1311/1378/1379 (a -6/+25/+15 cluster) completely.
'   2. pan_health's width is computed as `790 - x` (x=405 there -> 385), not the literal 385.
'      Closed the -13 gap at orig+3973 down to the same small residual every other row shows.
'   3. Statement order after pan_health's CreatePanel is `y :+ h + 10` THEN `x :+ 10` THEN
'      AddGadget(pan_health) -- not AddGadget first. Mirrors the pan_abilities section (its
'      `y :+ h + 10` already sits before its AddGadget). Closed the -12 gap at orig+4044.
' REMAINING (not fixed, not chased further -- this is codegen-patterns.md section 18's
' register-liveness problem, independently reconfirmed on THIS candidate): our register set
' for the row Locals is {y=ebx, h}, the original's is {y=ebx, wnum} (section 18.3's diagnosis
' for a *different*, lost earlier candidate -- this pass shows the SAME {y,h} vs {y,wnum}
' split holds for a differently-shaped candidate too, so it is not an artifact of one
' Local declaration order). Confirmed by direct disassembly: in a CreateLabel call, original
' pushes h and w from STACK slots and only y from ebx; our code pushes h from a register
' (edi) too. Per section 18.2 this cannot be fixed by reordering Local declarations --
' reference counts (h roughly 50, wnum roughly 28) are not a tie -- the fix requires making
' wnum's *liveness* (block_count/degree) beat h's, which needs an instrumented bcc or a
' targeted probe isolating that one allocator decision. Manifests as a repeating -7/-8/+7/-5/
' +5/-3/+3/-2/+1 byte cluster once per gadget row (14 occurrences, ability + Kit Bag rows) plus
' two small non-repeating residues near the first ability row (orig+2035..2340) and the
' function tail (orig+5660) not yet individually explained.
' Independently re-derived from extracted/decomp_annotated/TScreen_MatchPrep.CreateScreen@0055c09b.c
' (Ghidra call-merge artifacts unwound by hand -- GetText/FormatMoney calls merge their args
' with the FOLLOWING CreateXxx call's pushes; see that file's own header for the general rule)
' plus the Local-storage-map facts already proven earlier. Build/verify with:
'   NSS5_NO_LEARN=1, harness.try_method('TScreen_MatchPrep','CreateScreen', body)
'   (body = this file with the '!Global pragmas and the interior of Function..End Function --
'   see scripts/reverify.py:body_of() which does this extraction automatically)
' DO NOT COPY TO src/recovered/ -- it is not byte-identical.
' === MEASUREMENT PASS === NO BYTE CHANGE. Body is byte-identical to the state above (still
' MISMATCH, our_len 6205, delta -44, 95 gaps -- reconfirmed with a fresh harness run). Its only
' contribution is REPLACING SPECULATION WITH MEASUREMENT: it points the instrumented
' allocator-dump bcc.exe (`tools/bmx-workers/<id>/bin/bcc.exe`, the same technique used on
' TFormation.GetPlayerXY) at THIS function.
' Recipe: point NSS5_WORKER at that tree, harness.build_source() this body, then
' `harness.BMK makeapp -r -t console <probe.bmx>` inside `harness.BuildLock()` (~1 log per
' worker-tree build; captures stdout+stderr, ~4.7MB across the whole probe program). Grep the
' log for `;--- NSS5GRAPH fn=__bb_TScreen_MatchPrep_CreateScreen ---;` (appears twice: pass 1 =
' optimistic-coloring worklist, pass 2 = after pass-1 spills are materialised as fresh nodes).
'
' THE NUMBERS, for section 18.3's `h` vs `wnum` question specifically:
'   node id=76: usage=49 degree=234 block_count=21 cost=0.00997  -- NOT in the final `Spilled:`
'     trace (pass 2 flags it `Spilling: 76` again but selectRegs() still colours it) --
'     i.e. THIS NODE KEEPS A REGISTER, matching our wrong {y,h} output.
'   node id=77: usage=28 degree=220 block_count=18 cost=0.00707  -- IS in the `Spilled:` trace
'     (pass 1, alongside ids 74 and 78) -- i.e. THIS NODE IS SPILLED, also matching our output.
' id=76's usage (49) and id=77's usage (28) match section 18.3's `h`~50 / `wnum`=28 reference
' counts closely enough (76 within 1, 77 EXACT), and their pass1/pass2 spill status matches our
' own observed {y,h} register set exactly (h kept, wnum spilled) -- UNCERTAIN but well-evidenced:
' id=76 IS h, id=77 IS wnum. (ids 74=38 and 78=25 are plausibly `x`=36 and `w`=29 respectively --
' both ARE spilled in our build, and since section 18.3 only ever named `{y,wnum}` as the
' original's register set -- not x or w -- their spilled status is presumably ALREADY CORRECT
' and not part of the discrepancy; not independently confirmed this pass.) No node anywhere in
' the whole-function dump has usage near `y`'s ~82 -- `y` is reassigned by `y :+ h + 10` at
' every row and is therefore almost certainly split into ~13 short-lived per-row nodes rather
' than one continuous range, unlike h/w/wnum/x which are each set once and read repeatedly.
'
' WHAT THIS MAKES ACTIONABLE: cost = usage / (degree * block_count). usage is fixed by
' semantics (cannot add/remove real references without changing behaviour). For wnum's cost to
' overtake h's: 28 / (220 * new_wnum_db) > 49 / (234*21=4914)  =>  new_wnum_db < 2808. Current
' wnum degree*block_count = 220*18 = 3960 -- needs to drop by at least ~29%. Per codegen-
' patterns.md 22.3 the lever is BLOCK_COUNT via statement placement (shrinking the span between
' wnum's definition and its last use), not Local reordering (already ruled out, 18.3) and not
' reference count (usage is fixed). NOT ATTEMPTED this pass for lack of remaining time: split
' wnum's single continuous live range (currently spanning all 7 ability rows, block_count=18)
' into two shorter generations, OR otherwise shrink the block distance between its def and its
' final read, then re-verify with the FAST oracle (harness.try_method) -- the slow instrumented
' rebuild is only needed to re-read the new node costs, not to test whether a byte match lands.
'
' === RE-CHECK PASS === NO CHANGE. Re-verified this pass's diagnosis from
' scratch by disassembling both src/assembled/nss5_assembled.exe (our_va 0x005AB13D) and
' NSS5.exe (orig_va 0x0055C09B) directly and diffing the normalized instruction streams
' (mnemonic + operand shape, literal/address immediates masked out so only real structural
' differences show). Two findings:
'   1. status/score's "FIRST DIFFERENCE: byte 10" is NOT a real defect -- it is the call
'      TScreen.CreateScreen("matchprep", Null, Null, Null) at the very top of the function,
'      byte-for-byte the same instruction shape (same push count, same call-target slot) as
'      the original; only the pushed immediates (string/global/import addresses) differ, which
'      is unavoidable address-layout drift from the rest of the project not yet being 100%
'      byte-reconstructed. That is true of nearly every one of the ~4800 "different" bytes:
'      same opcodes, different absolute addresses. Confirmed by full-function instruction
'      diff: aside from the h/wnum pattern below, ORIG and OURS normalize to IDENTICAL
'      instruction sequences end to end, including the whole function tail (`equal`
'      continuously from instruction #1689 of 1882 to the end) -- the "function tail
'      (orig+5660) not yet individually explained" residue noted above is just the last edge
'      of the same repeating pattern, not a separate defect.
'   2. Confirmed the {y,h} vs {y,wnum} register claim by hand at its very first occurrence
'      (the lbl_Selection/lbl_Status pair, wnum=200, orig off 1728): ORIG spills
'      {x->[ebp-8], h->[ebp-4], w->[ebp-0xc]} and keeps {y->ebx, wnum->edi} in registers;
'      OURS spills {x->[ebp-4], w->[ebp-8], wnum->[ebp-0xc]} and keeps {y->ebx, h->edi}. Every
'      one of the 95 gaps decomposes into exactly this swap, repeated once per row (summed
'      byte delta over all gaps = -44, matching status/score exactly -- confirmed
'      programmatically, not just by inspection).
' Did not attempt the wnum-live-range-split experiment: this file cannot run
' scripts/assemble.py per the task rules, so there is no way to build-and-rescore it this pass,
' and three earlier dedicated passes with actual instrumented-allocator data already concluded it
' needs an iterate-and-remeasure loop, not a single blind edit. Per rule 4, a guess that cannot
' be verified and might regress a body this well-characterized is worse than leaving it alone.
' Body is UNCHANGED this pass.
' === WALLOC MEASUREMENT PASS === NO BYTE CHANGE. This pass has an actual instrumented-bcc
' readout tool (walloc_report.py) rather than an ad hoc trace, and uses it to test the
' iterate-and-remeasure loop the prior pass declined to attempt without tooling. Findings:
' 1. Tool self-check reproduces this file's own numbers exactly: h regid=76 usage=49 degree=234
'    block_count=21 (kept, edi); wnum regid=78 usage=25 degree=218 block_count=18 cost=0.00637105
'    (spilled, [ebp-12], and the global-minimum-cost node -- picked as spill victim first, before
'    x/w/y/h are even considered). h's own decisive comparison happens later, in pass 2, once
'    most of the graph has simplified away: usage=49 degree=35 block_count=21 cost=0.0666667.
' 2. block_count is a real, reachable, measurable lever here, not just a formula on paper.
'    Reordering the purely-literal reassignments between two calls that neither reads nor
'    writes wnum (x :+ 10 / h = 40 / w = 100 / y = 130, all sitting inside one call-free zone)
'    changes nothing -- identical usage/degree/block_count/cost to the eleventh decimal place,
'    confirmed by direct rebuild. Moving wnum's OWN assignment (wnum = 265) to sit immediately
'    before its first read instead of three calls earlier (CreatePanel/AddGadget/AddChild, none
'    of which touch wnum) DOES move the numbers: block_count 18 -> 17, degree 218 -> 205, cost
'    0.00637105 -> 0.0071736, about +12%. This is the only squeeze available anywhere in the
'    function: wnum's other two generations already sit zero or one statement from their first
'    read (the initial Local block's first use is one call later at lbl_Selection1; the Kit Bag
'    generation's wnum = 160 already sits directly before its first read), and h itself has no
'    slack to widen in the other direction -- it is a call argument on nearly every one of the
'    ~21 blocks it survives, i.e. already live almost everywhere between its own first and last
'    use, with no gap left to stretch.
' 3. Rebuilding the candidate with that one squeeze applied and reading the trace again shows
'    the allocator's actual OUTCOME for wnum is unchanged: still spilled to [ebp-12]. The
'    reachable range shrink is real but roughly an order of magnitude short: wnum's maximum
'    reachable cost (~0.0072) sits far below h's competing cost (0.0667), and no further legal,
'    semantics-preserving reordering exists in this body to close that gap without reordering
'    calls themselves, which would perturb the AddChild/AddGadget sequence already confirmed
'    byte-matching elsewhere in this function for no compensating gain.
' CONCLUSION: the h/wnum register-allocation tie is UNREACHABLE via statement placement under
' this toolchain for this body. Every remaining def-to-first-use and last-use-to-redef gap for
' both contested Locals is already at its structural minimum, fixed by the row layout's already-
' verified call order. Body is UNCHANGED this pass -- the one legal edit found does not flip the
' allocator's decision and is not applied.
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
		g_screen_matchprep.AddGadget(g_lbl_Status)
		x :+ 10
		h = 40
		w = 100
		wnum = 265
		y = 130
		g_pan_abilities = TPanel.CreatePanel("pan_abilities", GetText("Abilities"), x - 10, y, 385, h, "FFFFFF", "FFFFFF", 3, 0.8, 1, 360, 0)
		y :+ h + 10
		g_screen_matchprep.AddGadget(g_pan_abilities)
		g_pan_abilities.AddChild(TLabel.CreateLabel("lbl_Pace", GetText("Pace"), x, y, w, h, 3, "FFFFFF", "FFFFFF", 1.0, 4, 1, 0, 1, Null, 1, 0, 0, 0, "", 0))
		g_prg_pace = TProgressBar.CreateProgressBar("prg_Pace", "", x + w, y, wnum, h, 3, "FFFFFF", SkillColour(1), "FFFFFF", 0.8, 5, g_img_star)
		g_pan_abilities.AddChild(g_prg_pace)
		y :+ h + 10
		g_pan_abilities.AddChild(TLabel.CreateLabel("lbl_Flair", GetText("Flair"), x, y, w, h, 3, "FFFFFF", "FFFFFF", 1.0, 4, 1, 0, 1, Null, 1, 0, 0, 0, "", 0))
		g_prg_flair = TProgressBar.CreateProgressBar("prg_Flair", "", x + w, y, wnum, h, 3, "FFFFFF", SkillColour(7), "FFFFFF", 0.8, 5, g_img_star)
		g_pan_abilities.AddChild(g_prg_flair)
		y :+ h + 10
		g_pan_abilities.AddChild(TLabel.CreateLabel("lbl_Tackling", GetText("Tackling"), x, y, w, h, 3, "FFFFFF", "FFFFFF", 1.0, 4, 1, 0, 1, Null, 1, 0, 0, 0, "", 0))
		g_prg_tackling = TProgressBar.CreateProgressBar("prg_Tackling", "", x + w, y, wnum, h, 3, "FFFFFF", SkillColour(3), "FFFFFF", 0.8, 5, g_img_star)
		g_pan_abilities.AddChild(g_prg_tackling)
		y :+ h + 10
		g_pan_abilities.AddChild(TLabel.CreateLabel("lbl_Dribbling", GetText("Dribbling"), x, y, w, h, 3, "FFFFFF", "FFFFFF", 1.0, 4, 1, 0, 1, Null, 1, 0, 0, 0, "", 0))
		g_prg_dribbling = TProgressBar.CreateProgressBar("prg_Dribbling", "", x + w, y, wnum, h, 3, "FFFFFF", SkillColour(2), "FFFFFF", 0.8, 5, g_img_star)
		g_pan_abilities.AddChild(g_prg_dribbling)
		y :+ h + 10
		g_pan_abilities.AddChild(TLabel.CreateLabel("lbl_Passing", GetText("Passing"), x, y, w, h, 3, "FFFFFF", "FFFFFF", 1.0, 4, 1, 0, 1, Null, 1, 0, 0, 0, "", 0))
		g_prg_passing = TProgressBar.CreateProgressBar("prg_Passing", "", x + w, y, wnum, h, 3, "FFFFFF", SkillColour(4), "FFFFFF", 0.8, 5, g_img_star)
		g_pan_abilities.AddChild(g_prg_passing)
		y :+ h + 10
		g_pan_abilities.AddChild(TLabel.CreateLabel("lbl_Shooting", GetText("Shooting"), x, y, w, h, 3, "FFFFFF", "FFFFFF", 1.0, 4, 1, 0, 1, Null, 1, 0, 0, 0, "", 0))
		g_prg_shooting = TProgressBar.CreateProgressBar("prg_Shooting", "", x + w, y, wnum, h, 3, "FFFFFF", SkillColour(6), "FFFFFF", 0.8, 5, g_img_star)
		g_pan_abilities.AddChild(g_prg_shooting)
		y :+ h + 10
		g_pan_abilities.AddChild(TLabel.CreateLabel("lbl_Heading", GetText("Heading"), x, y, w, h, 3, "FFFFFF", "FFFFFF", 1.0, 4, 1, 0, 1, Null, 1, 0, 0, 0, "", 0))
		g_prg_heading = TProgressBar.CreateProgressBar("prg_Heading", "", x + w, y, wnum, h, 3, "FFFFFF", SkillColour(5), "FFFFFF", 0.8, 5, g_img_star)
		g_pan_abilities.AddChild(g_prg_heading)
		x = 405
		y = 130
		g_pan_health = TPanel.CreatePanel("pan_health", GetText("Kit Bag"), x, y, 790 - x, h, "FFFFFF", "FFFFFF", 3, 0.8, 1, 360, 0)
		y :+ h + 10
		x :+ 10
		g_screen_matchprep.AddGadget(g_pan_health)
		w = 195
		wnum = 160
		g_btn_drugs = TButton.CreateButton("btn_Drugs", FormatMoney(1000, 0), x, y, wnum, h, 1, 3, "FFFFFF", "FFFFFF", g_img_drugs28, TScreen_MatchPrep.ButtonDrugs, 1.0, 1, GetText("tt_BuyDrugs"))
		g_pan_health.AddChild(g_btn_drugs)
		g_prg_drugs = TProgressBar.CreateProgressBar("prg_Drugs", GetText("Enhancers"), x + wnum + 10, y, w, h, 3, "FFFFFF", "38FF24", "FFFFFF", 0.8, 1, Null)
		g_pan_health.AddChild(g_prg_drugs)
		y :+ h + 10
		g_btn_booze = TButton.CreateButton("btn_Booze", FormatMoney(100, 0), x, y, wnum, h, 1, 3, "FFFFFF", "FFFFFF", g_img_booze28, TScreen_MatchPrep.ButtonBooze, 1.0, 1, GetText("tt_BuyBooze"))
		g_pan_health.AddChild(g_btn_booze)
		g_prg_booze = TProgressBar.CreateProgressBar("prg_Booze", GetText("Booze"), x + wnum + 10, y, w, h, 3, "FFFFFF", "FF9900", "FFFFFF", 0.8, 1, Null)
		g_pan_health.AddChild(g_prg_booze)
		y :+ h + 10
		g_btn_shinpads = TButton.CreateButton("btn_ShinPads", FormatMoney(500, 0), x, y, wnum, h, 1, 3, "FFFFFF", "FFFFFF", g_img_shinpads28, TScreen_MatchPrep.ButtonShinPads, 1.0, 1, GetText("tt_BuyShinPads"))
		g_pan_health.AddChild(g_btn_shinpads)
		g_prg_shinpads = TProgressBar.CreateProgressBar("prg_ShinPads", "", x + wnum + 10, y, w, h, 3, "FFFFFF", "00FF00", "FFFFFF", 0.8, 1, Null)
		g_pan_health.AddChild(g_prg_shinpads)
		y :+ h + 10
		g_btn_boots = TButton.CreateButton("btn_Boots", "", x, y, wnum, h, 1, 3, "FFFFFF", "FFFFFF", g_img_boot28, TScreen_BootShop.SetUpScreen, 1.0, 1, GetText("tt_BuyBoots"))
		g_pan_health.AddChild(g_btn_boots)
		g_prg_boots = TProgressBar.CreateProgressBar("prg_Boots", "", x + wnum + 10, y, w, h, 3, "FFFFFF", "00FF00", "FFFFFF", 0.8, 1, Null)
		g_pan_health.AddChild(g_prg_boots)
		y :+ h + 10
		g_btn_injury = TButton.CreateButton("btn_Injury", FormatMoney(0, 0), x, y, wnum, h, 1, 3, "FFFFFF", "FFFFFF", g_img_painkiller, TScreen_MatchPrep.ButtonPainKillers, 1.0, 1, GetText("tt_BuyPainKillers"))
		g_pan_health.AddChild(g_btn_injury)
		g_prg_injury = TProgressBar.CreateProgressBar("prg_Injury", "", x + wnum + 10, y, w, h, 3, "FFFFFF", "FF0000", "FFFFFF", 0.8, 1, Null)
		g_pan_health.AddChild(g_prg_injury)
		y :+ h + 10
		g_btn_nrg = TButton.CreateButton("btn_NRG", FormatMoney(250, 0), x, y, wnum, h, 1, 3, "FFFFFF", "FFFFFF", g_img_nrg28, TScreen_MatchPrep.ButtonNRG, 1.0, 1, GetText("tt_BuyNRG"))
		g_pan_health.AddChild(g_btn_nrg)
		g_prg_nrg = TProgressBar.CreateProgressBar("prg_NRG", "NRG", x + wnum + 10, y, w, h, 3, "FFFFFF", "38FF24", "FFFFFF", 0.8, 1, Null)
		g_pan_health.AddChild(g_prg_nrg)
		y :+ h + 10
		g_prg_energy = TProgressBar.CreateProgressBar("prg_Energy", "", x, y, wnum + w + 10, h, 3, "FFFFFF", "00FF00", "FFFFFF", 0.8, 1, Null)
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
