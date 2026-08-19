' TBall.CheckForPlayerRatings -- VA 0x004CC644, 2867 bytes, not yet byte-identical.
' VA 0x004cc644   2867 bytes   vtable slot 0xcc   sig (:TPlayer)i
'
' STATE: same length as the original (2867/2867). Six single-byte substitutions remain,
' all inside the float staging slots ([ebp-0x14]/[ebp-0x18]/[ebp-0x1c]) that hold a
' Dist2D() result across the following YardsToPixels()/comparison call, at ORIGINAL
' +1893/+1910 (BADVISION), +2134/+2151 (GOODLONGPASS), +2751/+2768 (the a0=Null block's
' tail Crossing check). The original assigns these three call sites' spill slots in the
' order -0x18, -0x1c, -0x14; source order gives the natural -0x14, -0x18, -0x1c. Direct
' instrumentation of the legacy compiler (tools/blitzmax-legacy-src, rebuilt with trace
' prints added to cgallocregs.cpp's spill()/createGraph(), worker-tree only, restored
' afterward) shows the six Dist2D-result virtual registers in this function are an exact
' tie on every allocator cost metric (usage=2, degree=7, block_count=1); the tie-break
' follows register id order, which follows AST visit order, which follows source order
' under IfStm::eval()'s unconditional Then-before-Else walk (stm.cpp:277-298, read
' directly, not inferred). Under the control-flow shape confirmed below (the a0=Null
' block is the physical Else arm of the a0<>Null dispatch), the original's ordering is not
' reachable by moving a statement in this function's text: closing this gap needs a rule
' change inside the allocator's tie-break, not a rewrite here.
'
' scripts/workflow/walloc_report.py corroborates the same numbers from a separate,
' reusable instrumented build: every one of the seven anonymous float-staging temporaries
' this function spills to a stack slot carries an identical cost profile at the spill-pick
' point (usage=2, degree=7, block_count=1, cost=0.285714), including the three whose slots
' disagree with NSS5.exe. Ten independent fresh builds (four through localise_diff.py, six
' through a direct harness.try_method call, each spawning its own bcc.exe process) land on
' the identical slot assignment and the identical six-byte diff every time. This tie does
' not show the run-to-run non-determinism walloc_report.py documents for
' TProfile.UpdateFinances's shirt/rent/prop case (a genuine near-tie that flips between
' process launches), so re-running the build is not a route to a match here either: the
' allocator resolves this exact tie the same way on every launch, and that way is not the
' original's way.
'
' Verify with `NSS5_WORKER=<n> NSS5_NO_LEARN=1 python scripts/localise_diff.py
' TBall.CheckForPlayerRatings src/recovered_unverified/TBall.CheckForPlayerRatings.bmx`;
' it reports exactly these six same-length subs and nothing else -- delta +0, no
' length-changing gaps. The raw harness oracle's `matched` count reads well below
' orig_len even so: it counts literal byte equality with no allowance for legitimate
' relocation differences (call targets, Global addresses) between a fresh probe build and
' NSS5.exe, so on its own it is not a percentage worth quoting; localise_diff.py's
' gap/sub accounting is the number that reflects this body's actual state.
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
' jumps clear past the whole nested If instead. That is a real control-flow difference,
' not a spill-order one, but it does not change the function's total length, and
' localise_diff.py's tolerant alignment reports a wrong branch target only as a harmless
' "branch displacement shift", never as a gap or a sub -- so this defect does not show up
' in that tool's output at all and has to be read from a raw disassembly diff instead.
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
									If Dist2D(p.kickx, p.kicky, a0.x, a0.y) > TPitch.YardsToPixels(15.0)
										p.AddPlayerRating(6, -2, "CBOSSSHOUT_BADVISION" + Rand(4))
									Else
										p.AddPlayerRating(5, -3, "CBOSSSHOUT_BADVISION" + Rand(4))
									EndIf
								EndIf
							Else
								If Self.slidekick = 0 And Self.posthit = 0
									If Dist2D(p.kickx, p.kicky, a0.x, a0.y) > TPitch.YardsToPixels(15.0) And a0.distancetogoal_opp < a0.distancetogoal_own
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
