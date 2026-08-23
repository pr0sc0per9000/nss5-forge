' TBall.CheckForPlayerRatings -- VA 0x004CC644, 2867 bytes. BYTE-IDENTICAL vs NSS5.exe.
' VA 0x004cc644   2867 bytes   vtable slot 0xcc   sig (:TPlayer)i
'
' STATE: MATCH, mode=reloc, 2867/2867, first_diff=None, under NSS5_NO_LEARN=1, on 8
' consecutive fresh builds each spawning its own bcc.exe process. localise_diff.py reports
' CLEAN -- 0 gaps, 0 subs, 0 branch_shifts, delta +0.
'
' WHAT CLOSED IT, AND WHY THE PREVIOUS DIAGNOSIS WAS WRONG
' =======================================================
' The residual was six bytes: three Dist2D() results that must survive the following
' TPitch.YardsToPixels() call get spilled to stack slots, and three of them landed in the
' wrong slots. The fix is two lines of source -- naming two of those results:
'
'     Local d5:Float = Dist2D(p.kickx, p.kicky, a0.x, a0.y)   ' BADVISION site
'     Local d6:Float = Dist2D(p.kickx, p.kicky, a0.x, a0.y)   ' GOODLONGPASS site
'
' declared IN PLACE -- exactly where the inline expression already sat, inside the same
' guard, with no statement moved and no hoisting. Not one emitted instruction changes;
' only the three spill-slot displacements do, and they change to the original's.
'
' The mechanism is NOT the one this file's previous header asserted, and not the one
' codegen-patterns.md section 22.3 nominates either. It is the allocator's SPILL WORKLIST
' TIER. In cgallocregs.cpp's makeWorkList a node that is move-related goes to _coalesce,
' not to _spill; it only reaches _spill later, via freeze(). Node::insert() appends at the
' TAIL. So a move-related value enters the _spill list AFTER every non-move-related one,
' and since spill() scans that list head-to-tail taking the first minimum (`cost<min`,
' strict), a move-related value is picked LATER on an exact cost tie. Writing
' `Local d:Float = <expr>` creates the move that makes the node move-related. That is a
' source-level lever on spill ORDER that costs zero emitted bytes, and it is not
' declaration order, not reference count, and not block_count.
'
' THE PREVIOUS HEADER'S CLAIM -- "the tie-break follows register id order, which follows
' AST visit order, which follows source order" -- IS FALSE IN BOTH HALVES, measured:
'  * Register ids DESCEND with source position for these anonymous temps: the first
'    staging temp in the text has regid 292 and the last has regid 78.
'  * Naming a temp gives it a LOW regid (53 and 57 here, below all seven anonymous ones)
'    and yet moves it LATER in the pick order, not earlier. Id order is not the tie-break.
' The conclusion drawn from it -- "closing this gap needs a rule change inside the
' allocator's tie-break, not a rewrite here" -- was wrong. A rewrite here closed it.
'
' MEASURED ALLOCATOR NUMBERS (scripts/workflow/walloc_report.py, instrumented bcc)
' ==============================================================================
' All seven float-staging temporaries in this function are an EXACT tie at the spill-pick
' point, before and after the fix:
'
'     usage = 2.0    degree = 8 at createGraph / 7 at the pick point    block_count = 1
'     cost  = usage / (degree * block_count) = 2/7 = 0.285714
'
' Per site (offset from function start, the same on both sides), with the regid the
' pre-fix build gave it:
'
'   site off    what                                   regid  ORIG   pre-fix  now
'   1    +190   distancetoopponent > Y2P(10) GOODPOSN   292   -0x04   -0x04   -0x04
'   2    +922   Dist2D > Y2P(15)  GOODCORNER            240   -0x08   -0x08   -0x08
'   3    +1141  Dist2D > Y2P(15)  GOODFREEKICK          220   -0x0c   -0x0c   -0x0c
'   4    +1574  Dist2D > Y2P(20)  GOODCROSS             191   -0x10   -0x10   -0x10
'   5    +1893  Dist2D > Y2P(15)  BADVISION    -> d5    157   -0x18   -0x14   -0x18
'   6    +2134  Dist2D > Y2P(15)  GOODLONGPASS -> d6    140   -0x1c   -0x18   -0x1c
'   7    +2751  Dist2D > Y2P(20)  a0=Null tail Crossing  78   -0x14   -0x1c   -0x14
'
' [ebp-0x20] is a separate shared int->float conversion scratch (mov [ebp-0x20],eax /
' fild [ebp-0x20]), not a spill slot, in both images. Frame is `sub esp,0x20` on both.
' There is no independent defect at site 7: it took -0x14 by itself once sites 5 and 6
' were pulled ahead of it in the pick order.
'
' SLOT DEPTH DIRECTION -- codegen-patterns.md section 22.2 HAS THIS BACKWARDS
' =========================================================================
' Section 22.2 says "[ebp-4] went to the FIRST value spilled". Measured here, in both a
' matching and a non-matching build: [ebp-4] goes to the LAST value spilled and the
' DEEPEST slot to the first. The chain is spill() -> selectNode() pushes onto _selected ->
' assignColors pops _selected LIFO -> failures are APPENDED to _spilled -> the loop at
' cgallocregs.cpp:585 walks _spilled head-to-tail calling allocLocal (`local_sz += n`). So
' the first value spilled is pushed first, popped last, appended last, and gets the
' deepest slot. Anyone reasoning from section 22.2's stated direction inverts every
' conclusion that follows.
'
' LIVENESS WAS TESTED DIRECTLY AND IS NOT THE LEVER HERE
' =====================================================
' block_count is real, movable and measurable in this body -- it is just not what was
' wrong. Two controlled probes, predictions registered before each build:
'  * Hoisting the GOODLONGPASS Dist2D into a Local ABOVE its `slidekick=0 And posthit=0`
'    guard: predicted block_count 1 -> 3 and cost -> ~0.095; measured EXACTLY
'    block_count=3, cost=0.0952381, picked first, took the deepest slot. Byte cost: two
'    length-changing gaps of 44 bytes. Not the original's source.
'  * Also hoisting the BADVISION Dist2D above its five-conjunct guard: predicted a
'    strictly lower cost than the first; measured block_count=9, cost=0.031746, picked
'    first. This is what established that the original needed sites 6 and 5 picked in
'    THAT order, not merely both cheaper than the rest.
' Every way of moving block_count also moves the emitted instruction stream, and this body
' was already instruction-identical to the original (0 gaps, 0 branch_shifts) before the
' fix, so no such change could be the answer. The winning change deliberately did NOT move
' block_count -- measured 1 before and 1 after, cost 0.285714 before and after.
' If another body has this shape: try NAMING the temporary before moving statements.
'
' WARNING -- walloc_report.py MISPREDICTED THIS BODY'S SLOTS
' =========================================================
' The instrumented from-source bcc that walloc_report.py drives put the two named locals
' at [ebp-8] and [ebp-4] (picked last of the seven). The shipped bcc.exe the harness
' builds with puts them at [ebp-0x18] and [ebp-0x1c] (picked third and second), which is
' the original's map and is what MATCHes. Both are self-consistent and reproducible under
' their own binary. This is the cross-process instability walloc_report.py's own header
' documents for near-ties, now seen on an EXACT tie and between two different bcc
' binaries. So: walloc_report.py's usage/degree/block_count/cost ARE the compiler's own
' numbers and are trustworthy; its FINAL SLOT and PICK ORDER are not, whenever the costs
' are tied. Confirm slots against the shipped compiler with harness.try_method /
' localise_diff, always.
'
' Verify with `NSS5_WORKER=<n> NSS5_NO_LEARN=1 python scripts/localise_diff.py
' TBall.CheckForPlayerRatings src/recovered/TBall.CheckForPlayerRatings.bmx` -> CLEAN.
'
' The GOODINTERCEPTION guard is one flat And-chain:
'     If lastkickedby.teamid <> p.teamid And (lasttouchedby = lastkickedby Or
'        lasttouchedby = p) And a0.PlayerSliding() = 0
'         p.AddPlayerRating(4, 2, "CBOSSSHOUT_GOODINTERCEPTION" + Rand(4))
'     EndIf
' not a three-term guard feeding a separate `Local slide` tested by its own `If`. Splitting
' PlayerSliding()'s test into a standalone Local changes which code the guard's early-exit
' jump lands on: as one And-chain, a false first/second term jumps into the shared tail
' that also ends the PlayerSliding() term's own evaluation (same `cmp eax,0 / je` the
' fourth term falls into); as a separate `Local slide` + `If slide`, the guard's early-exit
' jumps clear past the whole nested If instead.
'
' PROVEN, verify with localise_diff.py rather than re-deriving:
'  * Outer guard is four separate early returns (`If g_player_int01<>1 Then Return 0`,
'    `If g_bossmessages.Count()<>0 Then Return 0`, `Local p:TPlayer=TPlayer.GetHumanPlayer()`,
'    `If Not p Then Return 0`, `If Not lastkickedby Then Return 0`), not a wrapping And-chain.
'  * Top-level dispatch is `If a0=p ... ElseIf a0<>Null ... Else <a0=Null block> EndIf`; the
'    a0=Null block is physically last, falling straight into `p.icalledforball=0 /
'    p.ihadashot=0` with no trailing jmp.
'  * The teamid dispatch inside the a0<>p arm is a plain 3-way `If <crossing-eligible> ...
'    ElseIf a0.teamid<>p.teamid ... Else ...`; both arms independently re-test
'    `slidekick=0 And posthit=0` as their own first conjunct, not a shared hoisted guard.
'  * Six places in this function have If/Else arms physically swapped relative to Ghidra's
'    decompile text (Ghidra normalises polarity): `sel<>0` (PENALTYBOX/GOODEFFORT) vs
'    `sel=0` (BIGDISPATCH); the a0=Null block's `lastkickedby.ihadashot<>0` split;
'    BIGDISPATCH's own ihadashot split; three `InsidePenaltyBox(...)<>0` splits
'    (GOODEFFORT's PENALTYBOX-arm, the a0=Null ihadashot-arm, BIGDISPATCH's tail). Pattern:
'    wherever Ghidra prints `if (X = 0) { A } else { B }` with B a LogLine/EXPLETIVE-style
'    tail case, true source is `If X <> 0 Then B Else A`.
'  * Bare truth tests, not `<> 0`, for three guard-opening conditions that are the first
'    term of a fresh (non-ElseIf) `If`: `p.icalledforball`, both `Self.Crossing(0)`
'    occurrences at the head of their And chains.
'  * BADFREEKICK's two textually-identical arms are gated `ElseIf p.ihadashot <> 0`.
'  * All AddPlayerRating (shoutid,delta) pairs and string-literal keys:
'    GOODPOSITIONING(4,2), GOODINTERCEPTION(4,2), GENERICBAD(4,0,Rand(5)), BADCALL(4,-1),
'    GOODCORNER(2,5)/BADCORNER(2,-1), GOODFREEKICK(1,3)/BADFREEKICK(1,-1),
'    GOODCROSS(3,3)/(3,-1,"") empty-string call (two sites), GOODLONGPASS(6,3)/GOODPASS(5,3),
'    BADVISION(6,-2)/(5,-3) [Then=6,-2 when Dist2D>15, Else=5,-3], BADLONGSHOT(8,-3)
'    [BIGDISPATCH tail] / (8,-5) [a0=Null block, credited to lastkickedby not p, an
'    original quirk preserved as written], BADFINISHING(9,-1)/(9,-1)/(9,-2),
'    EXPLETIVE(10,-5), GOODEFFORT(8,1).
'  * Field offsets: TBall lastkicktype+104, lastkickmatchstate+108, controlledby+112,
'    lastkickedby+116, lasttouchedby+120, slidekick+140, posthit+144. TPlayer teamid+20,
'    x+76, y+80, kickx+148, kicky+152, selectionno+188, distancetogoal_opp+232,
'    distancetogoal_own+236, distancetoopponent+264, icalledforball+288, ihadashot+292.
'  * Vtable slots: TList.Count=0x70, TPlayer.AddPlayerRating=0x234 (i,i,$)i,
'    TPlayer.PlayerSliding=0x1B0 ()i, TBall.Crossing=0xA4 (f)i.
'  * Globals: g_bossmessages:TList at 0x00C6B284, g_player_int01:Int at 0x00C5B1FC.
'  * Comparison operand order (x87): every `Dist2D(...) > YardsToPixels(N)` has Dist2D on
'    the left EXCEPT GOODPOSITIONING (`p.distancetoopponent > YardsToPixels(10.0)`).

	Method CheckForPlayerRatings:Int(a0:TPlayer)
		'!Global g_player_int01:Int
		'!Global g_bossmessages:TList

		If g_player_int01 <> 1 Then Return 0
		If g_bossmessages.Count() <> 0 Then Return 0
		Local p:TPlayer = TPlayer.GetHumanPlayer()
		If Not p Then Return 0
		If Not lastkickedby Then Return 0
		If a0 = p
			If lastkickedby <> a0
				If lastkickmatchstate = 1 And p.distancetogoal_opp < p.distancetogoal_own And p.distancetoopponent > TPitch.YardsToPixels(10.0)
					p.AddPlayerRating(4, 2, "CBOSSSHOUT_GOODPOSITIONING" + Rand(4))
				Else
					If lastkickedby.teamid <> p.teamid And (lasttouchedby = lastkickedby Or lasttouchedby = p) And a0.PlayerSliding() = 0
						p.AddPlayerRating(4, 2, "CBOSSSHOUT_GOODINTERCEPTION" + Rand(4))
					EndIf
				EndIf
			EndIf
		ElseIf a0 <> Null
			If controlledby = p
				p.AddPlayerRating(4, 0, "CBOSS_GENERICBAD" + Rand(5))
			Else
				If p.icalledforball And a0.teamid <> p.teamid
					p.AddPlayerRating(4, -1, "CBOSSSHOUT_BADCALL" + Rand(4))
				ElseIf lastkickedby = p And lasttouchedby = p
					Local sel:Int = a0.selectionno = 0
					If sel Then sel = p.ihadashot
					If sel <> 0
						If TPitch.InsidePenaltyBox(p.kickx, p.kicky, 0) <> 0
							If lastkickmatchstate = 7
								p.AddPlayerRating(10, -5, "CBOSSSHOUT_EXPLETIVE" + Rand(4))
							Else
								p.AddPlayerRating(9, -1, "CBOSSSHOUT_BADFINISHING" + Rand(4))
							EndIf
						Else
							p.AddPlayerRating(8, 1, "CBOSSSHOUT_GOODEFFORT" + Rand(4))
						EndIf
					Else
						If lastkickmatchstate = 5
							If a0.teamid = p.teamid
								If Dist2D(p.kickx, p.kicky, a0.x, a0.y) > TPitch.YardsToPixels(15.0)
									p.AddPlayerRating(2, 5, "CBOSSSHOUT_GOODCORNER" + Rand(4))
								EndIf
							Else
								p.AddPlayerRating(2, -1, "CBOSSSHOUT_BADCORNER" + Rand(4))
							EndIf
						ElseIf lastkickmatchstate = 4
							If a0.teamid = p.teamid
								If Dist2D(p.kickx, p.kicky, a0.x, a0.y) > TPitch.YardsToPixels(15.0)
									p.AddPlayerRating(1, 3, "CBOSSSHOUT_GOODFREEKICK" + Rand(4))
								EndIf
							ElseIf p.ihadashot <> 0
								p.AddPlayerRating(1, -1, "CBOSSSHOUT_BADFREEKICK" + Rand(4))
							Else
								p.AddPlayerRating(1, -1, "CBOSSSHOUT_BADFREEKICK" + Rand(4))
							EndIf
						ElseIf p.ihadashot <> 0
							If TPitch.InsidePenaltyBox(p.kickx, p.kicky, 0) <> 0
								p.AddPlayerRating(9, -1, "CBOSSSHOUT_BADFINISHING" + Rand(4))
							Else
								p.AddPlayerRating(8, -3, "CBOSSSHOUT_BADLONGSHOT" + Rand(4))
							EndIf
						Else
							If Self.Crossing(0) And Dist2D(p.kickx, p.kicky, a0.x, a0.y) > TPitch.YardsToPixels(20.0) And a0.distancetogoal_opp < a0.distancetogoal_own
								If a0.teamid = p.teamid
									p.AddPlayerRating(3, 3, "CBOSSSHOUT_GOODCROSS" + Rand(4))
								Else
									p.AddPlayerRating(3, -1, "")
								EndIf
							ElseIf a0.teamid <> p.teamid
								If Self.slidekick = 0 And Self.posthit = 0 And Self.lastkicktype <> 4 And Self.lastkicktype <> 5 And Not Self.Crossing(0)
									' Named, not inlined: the name is what puts this value in the allocator's
									' move-related worklist tier and fixes its spill slot. See header.
									Local d5:Float = Dist2D(p.kickx, p.kicky, a0.x, a0.y)
									If d5 > TPitch.YardsToPixels(15.0)
										p.AddPlayerRating(6, -2, "CBOSSSHOUT_BADVISION" + Rand(4))
									Else
										p.AddPlayerRating(5, -3, "CBOSSSHOUT_BADVISION" + Rand(4))
									EndIf
								EndIf
							Else
								If Self.slidekick = 0 And Self.posthit = 0
									' Named for the same reason as d5 above.
									Local d6:Float = Dist2D(p.kickx, p.kicky, a0.x, a0.y)
									If d6 > TPitch.YardsToPixels(15.0) And a0.distancetogoal_opp < a0.distancetogoal_own
										p.AddPlayerRating(6, 3, "CBOSSSHOUT_GOODLONGPASS" + Rand(4))
									Else
										p.AddPlayerRating(5, 3, "CBOSSSHOUT_GOODPASS" + Rand(4))
									EndIf
								EndIf
							EndIf
						EndIf
					EndIf
				EndIf
			EndIf
		Else
			If lastkickedby.newstar <> 0
				LogLine("Player kicked ball out of play")
				If lastkickedby.ihadashot <> 0
					If TPitch.InsidePenaltyBox(lastkickedby.kickx, lastkickedby.kicky, 0) <> 0
						If lastkickmatchstate = 7
							p.AddPlayerRating(10, -5, "CBOSSSHOUT_EXPLETIVE" + Rand(4))
						Else
							p.AddPlayerRating(9, -2, "CBOSSSHOUT_BADFINISHING" + Rand(4))
						EndIf
					Else
						lastkickedby.AddPlayerRating(8, -5, "CBOSSSHOUT_BADLONGSHOT" + Rand(4))
					EndIf
				Else
					If lastkickmatchstate = 5
						p.AddPlayerRating(2, -1, "CBOSSSHOUT_BADCORNER" + Rand(4))
					ElseIf lastkickmatchstate = 4
						p.AddPlayerRating(1, -1, "CBOSSSHOUT_BADFREEKICK" + Rand(4))
					Else
						If Self.Crossing(0) And Dist2D(p.kickx, p.kicky, a0.x, a0.y) > TPitch.YardsToPixels(20.0) And p.distancetogoal_opp < p.distancetogoal_own
							p.AddPlayerRating(3, -1, "")
						EndIf
					EndIf
				EndIf
			EndIf
		EndIf
		p.icalledforball = 0
		p.ihadashot = 0
	End Method
