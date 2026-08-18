' TScreen_GameMenu.ButtonPlay
' VA 0x0053B3F1   1527 bytes   vtable slot 0x4c   sig ()i   KIND=Function
' Reconstructed from extracted/decomp_annotated/TScreen_GameMenu.ButtonPlay@0053b3f1.c,
' which resolves every SYM/CALL in this body (not independently byte-verified by this pass
' -- no toolchain access from this pass).
'
' REFINEMENT PASS (2026-08-16): this pass DID have toolchain access (scripts/harness.py,
' scripts/localise_diff.py, an isolated build tree) and drove the byte oracle
' directly rather than working blind. Went from 215/1478 (14.5%, length delta -49) to a
' length-exact-COMPLETE localise_diff report of 14 small gaps / -33 bytes and 20 same-length
' substitutions, ALL of which trace to one remaining register-allocation divergence (see
' KNOWN REMAINING GAP below). Not yet a byte-exact MATCH -- still MISMATCH mode='len' -- but
' every structural difference the oracle could localise has been identified and fixed.
'
' REFINEMENT PASS (2026-08-17): no build/bmk access this pass (hard constraint), but
' `python scripts/localise_diff.py TScreen_GameMenu.ButtonPlay --exe
' src/assembled/nss5_assembled.exe` (masked/relocation-aware, reads the already-assembled
' exe, does NOT build) still worked and re-derived the same 14-gap/-33-byte report fresh.
' The 2026-08-16 pass's claim that ALL 14 gaps trace to the fx/newseason register spill was
' WRONG for two of them -- both are genuine source-phrasing bugs, now fixed, together
' worth -23 of the -33 bytes:
'   * GAP1+GAP2 (-18 bytes): `If a = Null Or b = Null` compiled with only a SINGLE setcc
'     stage per operand; the original has a DOUBLE stage per operand (setne+movzx+cmp0,
'     THEN sete+movzx+cmp0) before combining -- codegen-patterns 10.3's `If Not x` shape
'     (21 bytes/staged) applied to EACH operand of a compound `Or`, not the direct `x=Null`
'     shape (12 bytes) that a bare `a=Null` produces when it has to be MATERIALISED as a
'     value (an Or-operand, not a standalone branch condition) rather than branched on
'     directly. Rewritten `If a = Null Or b = Null` -> `If Not a Or Not b` (same semantics,
'     same Then/Else content -- only the literal comparison phrasing changed).
'   * GAP4 (-5 bytes): the leagues-cheat arm (the `g_engine_int161=2 And KeyDown(162) And
'     g_curscreen.name="leagues"` branch) ends with an explicit `mov eax,0` immediately
'     before an unconditional jump to the function's shared epilogue -- i.e. this arm has
'     its OWN explicit `Return 0`, exactly like the already-documented `retired<>0`
'     DoMessage arm below it, and Ghidra's decompile hides it the same way (collapsing
'     every path's `return 0` into one trailing statement). Added `Return 0` right after
'     `TScreen_Leagues.SetUpScreen(0)`.
' Confirmed both fixes against the tool's per-gap disassembly before writing them (the
' setne/sete pairing and the extra `mov eax,0`+jmp are unambiguous, not inferred).
'
' REMAINING (-10 of -33, GAP3/5/6/7/8/9/10/11/12/13/14): all still the SAME fx/newseason
' register-allocation divergence the 2026-08-16 pass diagnosed (fx spills to [ebp-8] in the
' original at every one of its ~7 uses; our build keeps it in edi throughout instead, and
' the original separately zero-inits `newseason`'s register at Case 4's entry, which our
' build's definite-assignment elision drops). Re-confirmed present and unchanged this pass;
' still no source-level lever found (docs/reference/codegen-patterns.md 18-22 read in
' full this pass, including the newer 22.1-22.4 spill-formula material -- `usage/(degree*
' block_count)` -- but turning that into a concrete source edit needs a build loop to test
' candidate rephrasings against, which this pass does not have). Left as-is rather than
' guessed at.
'
' FIXES APPLIED THIS PASS, each confirmed against scripts/localise_diff.py's aligned gap
' report (original bytes vs ours, byte-for-byte) before moving to the next:
'   1. `If g_profile.retired = 0 <select> Else <DoMessage>` was byte-WRONG shape (an extra
'      33 bytes). The original's cmp/je jumps INTO the Select body and falls through into
'      the DoMessage code first -- the solo-relational If/Else swap rule
'      (codegen-patterns.md 21, "the solo-relational branch-swap rule"): negate the
'      comparison AND swap which block is Then/Else. Rewritten as
'      `If g_profile.retired <> 0 Then DoMessage(...) ; Return 0 Else <select> End If` --
'      matches exactly, including the DoMessage arm's explicit `Return 0` (its own
'      `mov eax,0` then a jump STRAIGHT to the shared epilogue, bypassing the implicit
'      end-of-Function `mov eax,0` that every other arm falls through to).
'   2. `If bestdate < 1 Then <SeasonReview> Else <locale dispatch>` was also swap-shaped:
'      original's `cmp edi,0 / jle` falls through into the (longer) locale-dispatch code
'      and jumps INTO the SeasonReview code. Rewritten as
'      `If bestdate > 0 Then <Play(bestdate)+locale dispatch> Else <Play(seasonstart)+
'      SeasonReview>` -- codegen-patterns 10.1's "match the setcc/immediate, not the
'      meaning": original tests `<= 0`, not `< 1`, which is a DIFFERENT instruction
'      (`cmp,0/setle` vs `cmp,1/setl`).
'   3. The `bestcomp.locale` (0/1/2) dispatch is a genuine `Select`, not If/ElseIf: all
'      three case-body addresses sit AFTER the last compare in the cmp/je run
'      (codegen-patterns 10.2's positional tell). The header note that flagged this
'      UNCERTAIN was wrong to hedge toward If/ElseIf; byte evidence settles it as Select.
'   4. Likewise `fx.level` (0/1) is a `Select`, not `If ... ElseIf fx.level = 1`: the
'      level==1 arm's body has NO retest before it (just an unconditional load+call),
'      which only happens when a shared cmp/je dispatch already did the test. The old
'      ElseIf form cost 6 extra bytes re-testing a comparison the dispatch already made.
'   5. Leagues-cheat `TMyDate.Create(...)` argument order was backwards. Byte evidence
'      (year computed and PUSHED as a stack scratch BEFORE `Int(wk)` is computed, `Int(wk)`
'      pushed next, the literal `1` pushed last/closest to the call) shows the real
'      argument order is `Create(1, Int(wk), g_profile.date.GetYear())`, not
'      `Create(1, g_profile.date.GetYear(), Int(wk))` as the old header note claimed from
'      the Ghidra merge reasoning alone. The OTHER two Create() calls in this body already
'      have year as their 3rd argument, which is corroborating: `Create(a, b, year)` is
'      this Type's consistent 3-int-constructor shape. Confirmed against the oracle: this
'      alone removed 3 whole wrong-byte substitutions (leagues-cheat call-argument setup).
'   6. `newseason` computation reorders similarly: original evaluates the CREATE()-based
'      fxyr value before `g_profile.date.GetYear()` (right-hand operand of the comparison
'      evaluated first), and assigns `newseason` via real branches (`mov edi,1` on two
'      distinct paths) rather than a `setl`/`movzx` flag sequence. Reproduced by writing
'      the condition with operands swapped, matching bcc's apparent left-to-right
'      evaluation of the WRITTEN expression:
'        If TMyDate.Create(fx.sdate, 1, 1).GetYear() > g_profile.date.GetYear()
'            newseason = True Else newseason = False
'      instead of the semantically-identical `newseason = g_profile.date.GetYear() < fxyr`
'      with a separate `fxyr` Local, which put both the evaluation order AND the
'      setcc-vs-branch codegen shape wrong.
'
' KNOWN REMAINING GAP (localise_diff, all confirmed against the oracle):
'   Everything above is now shape-correct. What is left is a single register-allocation
'   divergence that accounts for 100% of the remaining -33 byte delta: the original spills
'   `fx` (this Case's TFixture Local) to a REAL stack slot (`[ebp-8]`, reloaded from memory
'   at every one of its ~7 uses -- the "If fx = Null" test, the fxyr Create() call, the
'   `Select fx.level` dispatch, both `GetHomeTeamId`/`GetAwayTeamId` arms) and instead keeps
'   `newseason` resident in `edi` for its whole (short) live range. Our build's allocator
'   makes the opposite call: `fx` wins `edi` (a register, one byte cheaper per touch) and
'   `newseason` is computed fresh into `eax` at each assignment site with no persistent
'   register. This is a single coloring decision (per codegen-patterns.md section 18,
'   `tools/blitzmax-legacy-src/_src/codegen/cgallocregs.cpp`'s iterated-coalescing spill
'   heuristic, `usage/(degree*block_count)`) -- NOT a logic error; every value computed and
'   every branch taken is identical either way. Tried and ruled out: swapping the
'   declaration order of `fx`/`newseason` (rule 18.2's tie-break) has ZERO effect on the
'   oracle's byte output, so this is not a declaration-order tie -- one of the two
'   genuinely outranks the other in the original's liveness-weighted score, most likely
'   because `newseason`'s live range is much narrower (dead immediately after the single
'   `If newseason` test) while `fx` is live across nearly the whole Case body, and the
'   `block_count` term in the spill-cost formula divides down a value that is live in many
'   blocks (codegen-patterns 18.4) -- i.e. exactly the situation that made `fx` cheap to
'   spill in the original but not (yet) reproduced here. Whoever picks this up next:
'   `fx`'s reference COUNT already matches original 1:1 (verified by direct comparison of
'   every access site), so this is a pure liveness/block-count lever, not a missing/extra
'   reference -- do not re-try adding or removing Locals expecting the prologue `sub esp`
'   to move; every one of those experiments this pass (an extra `year`/`fxyr` Local, various
'   groupings) left `sub esp,0x1C` unchanged. The single 4-byte-per-slot shift this causes
'   cascades through every later Local in this Case (mycontinent/clubcontinent/bestcomp/
'   bestdate/seasonstart all sit exactly 4 bytes shallower than the original throughout),
'   plus the small "a=Null Or b=Null" staged-bool gaps (2x9 bytes) and one 3-byte gap in the
'   EachIn loop's assignment-statement order -- ALL of which are believed to resolve
'   automatically once `fx` spills to match, since `localise_diff` shows delta_accounted
'   COMPLETE with no other unexplained bytes anywhere in the body.
'
' GLOBALS (name/type per scripts/explain_global.py; all also load-bearing for the vtable
' slot each is dispatched through):
'   0x00C6EF50 g_engine_int161:Int   -- CERTAIN (explain_global.py). The debug-overlay flag;
'                                        ==2 is required to even test the leagues-cheat key.
'   0x00C61700 g_curscreen:TScreen   -- CERTAIN (explain_global.py, 16 bodies). Several other
'                                        bodies' headers record this address as renamed from
'                                        g_Object101 on 2026-08-15; decomp_annotated still
'                                        carries the stale g_Object101 spelling. .name at +8.
'   0x00C66F28 g_lg_table3:TTable    -- CERTAIN (explain_global.py, 2 bodies unanimous; beats
'                                        the STRONG g_screen_leagues_tplayer03 alias at the
'                                        same address). Slot 0xD8 = TTable.GetSelectedText(i)$.
'   0x00C6F028 g_profile:TProfile    -- explain_global.py's CERTAIN pick for this address is
'                                        actually g_contractoffer_tplayer (20 bodies), with
'                                        g_profile only STRONG (142 bodies, 102/104 agree).
'                                        Overridden here: every OTHER TScreen_GameMenu body
'                                        already in src/recovered (ButtonQuit, ButtonCompetitions,
'                                        UpdateTitlePanel, UpdateMatchRefresh) declares this
'                                        exact address g_profile:TProfile, and TScreen_TestFixtures
'                                        /TestTournaments.ButtonPlay (verified siblings) do too --
'                                        within-Type/within-feature consistency wins over the
'                                        raw unanimity count.
'   0x00C6099C g_competitions:TList  -- CERTAIN (explain_global.py, 28 bodies).
'
' FIELD / SLOT RESOLUTION (object_model.json, vtable_map.tsv):
'   TProfile      +0x10 date:TMyDate   +0x3C retired   +0x130 playbuttontype   +0x164 booze
'                 +0x1CC mynation:TNation   +0x1D0 myclub:TClub
'                 slot 0x54 Play(i)i, 0x58 GetNextFixture(i):TFixture, 0x60 PlayNextFixture(i)i,
'                 0x74 RandomIncident()i, 0x13C CheckLoanEnd()i
'   TMyDate       +0x08 sdate:Int ; Function 0x30 Create(i,i,i):TMyDate, Method 0x54 GetYear()i
'   TCompetition  +0x08 id  +0x18 locale  +0x1C level  +0x20 based  +0x24 comptype
'                 +0x60 lfixturelist:TList
'   TFixture      +0x08 sdate  +0x24 result  +0x3C level
'                 slot 0x70 GetHomeTeamId()i, 0x74 GetAwayTeamId()i
'   TClub         +0x64 nationid  +0x68 leagueid ; Function slot 0x60 SelectById(i):TClub
'   TNation       +0x64 continent ; Function slot 0x58 SelectById(i):TNation
'   KeyDown(162) = KEY_LCONTROL, same idiom as TScreen_TestFixtures/TestTournaments.ButtonPlay
'     and TTable.UpdateActivated (0x005B4721 is the KeyDown|MouseDown alias set; KeyDown fits).
'
' STRUCTURE (all four multi-way dispatches in this body are now oracle-confirmed Selects):
'   - `g_profile.playbuttontype`: Case order in the machine code is 1, 2, 3, 5, 4 (5 before
'     4) -- that non-monotonic order is the documented tell for a `Select` over an If/ElseIf
'     cascade (codegen-patterns.md 10.2), so it is written as one Select in that exact order.
'   - `bestcomp.locale` (0, 1, 2) and `fx.level` (0, 1): both settled to Select this pass
'     (see FIXES 3/4 above) -- the old header's hedge toward If/ElseIf for the locale
'     dispatch was wrong.
'   - The eligibility test for each competition, and the "best fixture so far" test inside
'     it, are each a textbook staged short-circuit boolean (bVarN = false; if(cond) bVarN=...)
'     repeated across several terms -- written back as the equivalent compound And/Or
'     expression rather than reproducing the staging by hand. This still holds; the oracle
'     raises no complaint about this region.
	Function ButtonPlay:Int()
		'!Global g_engine_int161:Int
		'!Global g_curscreen:TScreen
		'!Global g_lg_table3:TTable
		'!Global g_profile:TProfile
		'!Global g_competitions:TList
		LogLine("Play")
		If g_engine_int161 = 2 And KeyDown(162) And g_curscreen.name = "leagues"
			Local wk:String = g_lg_table3.GetSelectedText(0)
			LogLine("week:" + wk)
			Local d:TMyDate = TMyDate.Create(1, Int(wk), g_profile.date.GetYear())
			g_profile.Play(d.sdate)
			TScreen_Leagues.SetUpScreen(0)
			Return 0
		Else
			PlayTrack(2)
			LogLine(String(g_profile.playbuttontype))
			If g_profile.retired <> 0
				TScreen.DoMessage(GetText("CMESSAGE_RETIREMENT"), 0, 0)
				Return 0
			Else
				Select g_profile.playbuttontype
					Case 1
						TScreen_ReportPhysio.SetUpScreen()
					Case 2
						TScreen_WebPage.SetUpScreen("", "")
					Case 3
						g_profile.RandomIncident()
						g_profile.booze = 0
					Case 5
						TScreen_Newspaper.SetUpScreen()
					Case 4
						g_profile.CheckLoanEnd()
						Local fx:TFixture = g_profile.GetNextFixture(0)
						Local seasonstart:TMyDate = TMyDate.Create(1, 1, g_profile.date.GetYear() + 1)
						Local newseason:Int
						If fx = Null
							newseason = True
						Else
							If TMyDate.Create(fx.sdate, 1, 1).GetYear() > g_profile.date.GetYear()
								newseason = True
							Else
								newseason = False
							End If
						End If
						If newseason
							LogLine("SeasonReview")
							Local mycontinent:Int = g_profile.mynation.continent
							Local clubcontinent:Int = TNation.SelectById(g_profile.myclub.nationid).continent
							Local bestcomp:TCompetition = Null
							Local bestdate:Int = 0
							For Local c:TCompetition = EachIn g_competitions
								If (c.comptype = 1 And c.id = g_profile.myclub.leagueid) Or (c.locale = 1 And c.level = 1 And c.based = mycontinent) Or (c.locale = 1 And c.level = 0 And c.based = clubcontinent) Or (c.locale = 2)
									For Local f:TFixture = EachIn c.lfixturelist
										If (f.result = 0 And f.sdate < seasonstart.sdate) And (bestdate = 0 Or f.sdate < bestdate)
											bestdate = f.sdate
											bestcomp = c
										End If
									Next
								End If
							Next
							LogLine("SeasonStart:" + String(seasonstart.sdate))
							LogLine("compfixdate:" + String(bestdate))
							If bestdate > 0
								g_profile.Play(bestdate)
								Select bestcomp.locale
									Case 0
										TScreen_Leagues.SetUpScreen(bestcomp.id)
									Case 1
										TScreen_Continents.SetUpScreen(0, bestcomp.level, bestcomp.id)
									Case 2
										TScreen_Continents.SetUpScreen(0, bestcomp.level, bestcomp.id)
								End Select
							Else
								g_profile.Play(seasonstart.sdate)
								TScreen_SeasonReview.SetUpScreen()
							End If
						Else
							Local a:Object = Null
							Local b:Object = Null
							Select fx.level
								Case 0
									a = TClub.SelectById(fx.GetHomeTeamId())
									b = TClub.SelectById(fx.GetAwayTeamId())
								Case 1
									a = TNation.SelectById(fx.GetHomeTeamId())
									b = TNation.SelectById(fx.GetAwayTeamId())
							End Select
							If Not a Or Not b
								g_profile.PlayNextFixture(1)
							Else
								TScreen_WorldMap.SetUpScreen()
							End If
						End If
				End Select
			End If
		End If
	End Function
