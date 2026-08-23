' TPlayer.CheckKick
' VA 0x004f6c2b   2201 bytes   vtable slot 0xf4   sig ()i
' byte-identical vs NSS5.exe (2201/2201, original length from Ghidra's inventory, mode=reloc)
' Verified with harness.try_method under NSS5_NO_LEARN=1: status MATCH, first_diff None,
' reproduced twice from scratch. scripts/localise_diff.py: 0 gaps, 0 subs, 0 branch shifts,
' first_divergence None.
' Body-only format: statements only; parameters are a0, a1, ...
'
' HOW IT CLOSED (NSS5_WORKER=212). Entered at 2261/2201 (+60, 24 gaps, 0 subs,
' first_divergence ORIGINAL +86); left at MATCH. Eight edits, each measured with
' scripts/localise_diff.py before the next one was written.
'
' ONE RULE EXPLAINS ALL OF THEM, and it generalises past this function: bcc compiles a
' short-circuit And/Or chain as a SINGLE eax-reuse chain with one merge point per operator
' node, and it never stores the intermediate result. Every remaining defect in this body
' was the same thing -- source that had split one of the original's flat expressions into
' `Local flag = default / If cond Then flag = X / If flag ...`. Each materialise-then-branch
' step costs a `mov reg,0` for the default, a `mov reg,eax` for the store, and turns the
' term's own test from the chain form (`mov eax,<term> / cmp eax,0 / jcc`) into the solo
' form (`cmp <mem>,imm / jcc`) -- which is where the earlier header's "NG vs legacy backend
' collapses solo comparisons, not steerable from BlitzMax" conclusion came from. That
' conclusion was wrong. It is not a backend difference: write the whole condition as ONE
' expression and our bcc emits the original's bytes exactly.
'
' The edits, in the order applied and measured:
'   1. The dev-cheat gate. `If int161=2 And int01=1 And controller=1 And g_ball<>Null` plus
'      `Local n=KeyHit(8) / If n=0 / If int164 / n=JoyHit(5,0)` plus `If n<>0` plus the name
'      check, rewritten as ONE If. Proof from harness.disasm_original: the je at ORIGINAL
'      +86, the jne at +101 and the je at +111 ALL target 0x4f6ca8 (+125), which is a single
'      `cmp eax,0` merge -- KeyHit's result, JoyHit's result and the stale 0 left by a failed
'      earlier term all arrive in the same register at the same instruction.
'      2261 -> 2254, 24 -> 21 gaps, first_divergence +86 -> +490.
'   2. `If GoalScorer() And (kickbuttonhits And kickbuttondown = 0) And PlayerOnFeet()` as
'      one flat chain (was four nested Ifs, with PlayerOnFeet's result stored in a Local).
'      Proof: 0x004F6E15 and 0x004F6E23 both je 0x4f6e37, and 0x004F6E3A je 0x4f6e4a lands
'      on the `cmp eax,0` that reads PlayerOnFeet's return -- the call is the chain's fourth
'      term, not a separate statement. Delta ROSE, +53 -> +62, and that was correct: those
'      two gaps were a net -9, i.e. our build was SHORTER than the original there. Gaps
'      21 -> 19, first_divergence +490 -> +655. Absolute delta is not the objective.
'   3. `Local u5:Int = (joy.kickbuttonhits > int50 - 200) And (joy.kickbuttondown = 0)`,
'      replacing `Local u5=0 / If hits > int50-200 / u5 = (down = 0)`. The original at
'      0x004F700D..0x004F7041 has no zero-store for u5 and ends `mov edi,eax`. 19 -> 17 gaps.
'   4+5. The u9 gate, 0x004F708C..0x004F7154, is ONE expression with no n/n6/u9 Locals:
'      `u5 And newstar And CanCallForBall() And g_ball<>Null And (controlledby=Null Or
'      controlledby.teamid=teamid) And (GetPlayerNearestToXY(...)<>Self Or g_training_int03)
'      And (teaminpossession=teamid Or distancetoball>YardsToPixels(6.0))`.
'      NOTE, this is the important negative result of the pass: applying only the first half
'      (leaving u9 a Local) flipped Self from esi to ebx for the WHOLE function -- 49 subs,
'      first_divergence back to +9, exactly the interference-graph fragility earlier headers
'      warned about. It is real, but it is a symptom of a HALF-applied rewrite, not a floor.
'      Writing the whole expression at once put esi/edi/ebx back where the original has them
'      (Self=esi, u5=edi, GetMyTeam temp=ebx) and dropped subs to 1. 2245, 15 gaps,
'      first_divergence +1511.
'   6. The Slide gate: `If u5 And (g_ball = Null Or (g_ball <> Null And g_ball.z <
'      g_player_int33 And g_ball.passtoid <> Self.id))`. The redundant inner `<> Null` IS in
'      the original (0x004F722E) and must be kept; the earlier header had written it off as
'      a backend artifact. 2247, 11 gaps, first_divergence +1643.
'   7. The Jump/Dive/ElseIf/Else arms, four flat chains:
'        (u5 Or u2) And g_ball<>Null And z >= int33     And jumpspotgood -> DoAnimJump
'        (u5 Or u2) And g_ball<>Null And z >= int33*0.6 And jumpspotgood -> DoAnimDive
'        g_ball<>Null And z > int33*0.6 And z < int33*1.5 And distancetoball <
'                                        YardsToPixels(6.0)             -> DoAnimDive
'        u2 And g_ball<>Null And z >= int33 And jumpspotgood             -> DoAnimJump
'      The `u9 = u5 / If u5 = 0 Then u9 = u2` value-substitution that four earlier passes
'      treated as the hard core of this body is just `(u5 Or u2)`, written out twice. edi is
'      never mutated -- 0x004F72F8 re-reads it unchanged -- so the `If u5 = 0 Then u5 = u2`
'      the old source had in the Dive arm was wrong as well. 2223 -> 2213 -> 2201.
'   8. `If Self.PlayerOnFeet()` in place of `Local n:Int = Self.PlayerOnFeet() / If n <> 0`.
'      Byte-neutral once (1)-(7) had removed every other read of n, but it is the original's
'      actual shape (0x004F6EBA is `cmp eax,0` straight off the call, no store) so it is what
'      is written here.
'
' THE LAST BYTE was a parenthesisation, and it was visible only as a jump target once the
' lengths already agreed: at ORIGINAL +490 the original jumps to +524 (past BOTH remaining
' terms) where ours jumped to +501 (past one). bcc's And is left-associative and chains its
' merge points, so `A And B And C` cannot produce that; `A And (B And C)` can, because the
' inner group's merge and the outer And's merge land on the same address. Hence
' `GoalScorer() And (kickbuttonhits And kickbuttondown = 0) And PlayerOnFeet()`. The same
' `(kickbuttonhits And kickbuttondown = 0)` unit appears in the TapKick/HoldKick gate below,
' which is corroborating evidence for how the original author wrote it.
' Worth keeping: at equal length with zero subs, a branch_shifts count of 1 is not noise --
' it is a finding about expression structure, and localise_diff does not adjudicate it.
'
' FIELD / GLOBAL / SLOT MAPPING -- confirmed via extracted/decomp_annotated (annotate,
' CONFIDENCE=HIGH) cross-checked against extracted/object_model.json:
'   TPlayer fields: controller(24) x(76) y(80) newstar(8) teamid(20) id(16) direction(120)
'     facing(296) distancetoball(208,Float) kickpower(192,Float) kickdirection(196,Float)
'     jumpspotgood(220) joy(344,:TJoy).kickbuttonhits/kickbuttondown/activebutton.
'   TBall (g_ball): x(0x18) y(0x1c) z(0x20,Float) oldx(0x24) oldy(0x28) oldz(0x2c)
'     velocity(0x54) zvelocity(0x58) controlledby(0x70,:TPlayer) teaminpossession(0x60)
'     setpiecetaker(0x80,:TPlayer) passtoid(0x9c). Method slot 0x84 = NewController(:TPlayer).
'   TProfile (g_profile) field name(0x14).
'   TTeam slot 0x90 = GetPlayerNearestToXY(i,i,i,:TPlayer,i):TPlayer -- confirmed by
'     "add esp,0x18" after the call; the 5 real args read from the raw pushes at
'     0x004f70f1..0x004f7136 are (Int(ball.x), Int(ball.y), 1, Null, 0). Ghidra's printed
'     arg list at that site is NOT evidence (it merges adjacent pushes).
'   TTraining.CanCallForBall -- Function (static), class-table call, ()i, slot 0xa0.
'   TPitch.YardsToPixels(f)f -- class-table call, slot 0x6c; float args are raw immediates
'     (push 0x40c00000 = 6.0, push 0x41700000 = 15.0).
'   Global addresses, each read off an absolute displacement in harness.disasm_original of
'     THIS function (see CONTRIBUTING.md, "A byte match does not prove your Globals are
'     right" -- names are relocations and the oracle masks them):
'       g_engine_int161  0x00C6EF50   g_player_int01   0x00C5B1FC
'       g_player_int03   0x00C5B204   g_player_int04   0x00C5B250
'       g_player_int14   0x00C5D1AC   g_player_int33   0x00C5DE70
'       g_player_int50   0x00C6EFD4   g_player_float13 0x00C5DE7C
'       g_ball           0x00C5DEA4   g_training_int03 0x00C6CF90
'       g_engine_int164  0x00C6EFEC   g_profile        0x00C6F028
'     Null compares against 0x005C9C80 (the null-object singleton).
'   Float constants in .rdata, by dword address: 0x00C79D20=-1.0 (kickdirection sentinel),
'     0x00C79D24=50.0, 0x00C79D28=15.0, 0x00C79D2C=0.6, 0x00C79D30=0.6 (a SEPARATE slot with
'     the same value -- two distinct source occurrences, no CSE), 0x00C79D34=1.5,
'     0x00C79D38=-1.0 (the final reset; a third distinct occurrence).
'   Strings (harness.read_string): 0x00C740BC "Simon Read", 0x00C740DC "Si Read" -- the
'     "which developer gets the ball snapped to them" easter egg, gated by KeyHit(8) or
'     JoyHit(5,0) plus g_profile.name matching either spelling.
'
' STRUCTURAL RULES CONFIRMED HERE, reusable elsewhere:
'   - Bare truthiness as a chain term is written bare (`If Self.newstar`), never `<> 0`; an
'     explicit `<> 0` adds a setne+movzx the original does not have.
'   - Float relational comparisons put the INSTANCE-side operand first regardless of the
'     natural reading (`g_ball.z >= g_player_int33`, `Self.kickpower >= 50.0`), because the
'     original flds the instance float first and fxchs to restore source order. Getting it
'     backwards flips setae<->setbe and seta<->setb.
'   - `Self.joy.kickbuttonhits > g_player_int50 - 200`, not `g_player_int50 - 200 <
'     Self.joy.kickbuttonhits`: the original evaluates kickbuttonhits first, into edx.
'   - Solo relational conditions gating two different bodies are emitted NEGATED with the
'     arms swapped (codegen-patterns.md 21). Applied at 0x004F6E54 (controlledby), at
'     0x004F7365 (the u5 three-way), and as the De Morgan form of the kickpower Or-chain
'     (`If kickpower < 15.0 And int01 <> 7 And int01 <> 9 Then TapKick Else HoldKick`).
'!Global g_engine_int161:Int
'!Global g_player_int01:Int
'!Global g_player_int03:Int
'!Global g_player_int04:Int
'!Global g_player_int14:Int
'!Global g_player_int33:Int
'!Global g_player_int50:Int
'!Global g_player_float13:Float
'!Global g_ball:TBall
'!Global g_training_int03:Int
'!Global g_engine_int164:Int
'!Global g_profile:TProfile

		If g_engine_int161 = 2 And g_player_int01 = 1 And Self.controller = 1 And g_ball <> Null ..
				And (KeyHit(8) Or (g_engine_int164 And JoyHit(5, 0))) ..
				And (g_profile.name = "Simon Read" Or g_profile.name = "Si Read")
			g_ball.NewController(Self)
			g_ball.x = Self.x
			g_ball.y = Self.y
			g_ball.z = 0.0
			g_ball.oldx = Self.x
			g_ball.oldy = Self.y
			g_ball.oldz = 0.0
			g_ball.velocity = 0.0
			g_ball.zvelocity = 0.0
		EndIf
		If g_player_int03 = 0 Or g_player_int50 < g_player_int03 + 1000
			If Self.newstar And g_ball <> Null And g_ball.setpiecetaker <> Self And Self.joy.kickbuttonhits > g_player_int50 - 200
				Self.Call()
			EndIf
			Self.ResetKick()
			Return 0
		Else
			If Self.GoalScorer() And (Self.joy.kickbuttonhits And Self.joy.kickbuttondown = 0) And Self.PlayerOnFeet()
				If g_ball.controlledby <> Null
					g_ball.z = 0.0
					Self.HoldKick()
				Else
					If g_player_int04 = Self.teamid
						Self.DoAnimCelebrate(Self.facing)
					Else
						Self.DoAnimCommiserate(Self.facing)
					EndIf
				EndIf
			EndIf
			If Self.PlayerOnFeet()
				If g_ball <> Null And g_ball.controlledby = Self
					If Self.joy.kickbuttondown = 1
						Self.kickpower = Self.kickpower + g_player_float13
						If Self.kickdirection = -1.0
							Self.kickdirection = Self.direction
						EndIf
					EndIf
					If (Self.joy.kickbuttonhits And Self.joy.kickbuttondown = 0) Or (Self.kickpower >= 50.0) Or (g_player_int01 = 2 And Self.kickpower > 0.0)
						If Self.kickpower < 15.0 And g_player_int01 <> 7 And g_player_int01 <> 9
							Self.TapKick()
						Else
							Self.HoldKick()
						EndIf
					EndIf
				Else
					Local u5:Int = (Self.joy.kickbuttonhits > g_player_int50 - 200) And (Self.joy.kickbuttondown = 0)
					Local u2:Int = Self.joy.kickbuttondown
					If g_ball <> Null Or g_training_int03 = 4 Or g_training_int03 = 5
						If u5 And Self.newstar And TTraining.CanCallForBall() And g_ball <> Null ..
								And (g_ball.controlledby = Null Or g_ball.controlledby.teamid = Self.teamid) ..
								And (Self.GetMyTeam().GetPlayerNearestToXY(Int(g_ball.x), Int(g_ball.y), 1, Null, 0) <> Self Or g_training_int03) ..
								And (g_ball.teaminpossession = Self.teamid Or Self.distancetoball > TPitch.YardsToPixels(6.0))
							Self.Call()
						Else
							If g_player_int01 = 1 And Self.distancetoball <= TPitch.YardsToPixels(15.0)
								If g_player_int14 = 0 Or Self.controller = 0
									If u5 And (g_ball = Null Or (g_ball <> Null And g_ball.z < g_player_int33 And g_ball.passtoid <> Self.id))
										Self.DoAnimSlide()
									Else
										If (u5 Or u2) And g_ball <> Null And g_ball.z >= g_player_int33 And Self.jumpspotgood
											Self.DoAnimJump()
										Else
											If (u5 Or u2) And g_ball <> Null And g_ball.z >= g_player_int33 * 0.6 And Self.jumpspotgood
												Self.DoAnimDive()
											EndIf
										EndIf
									EndIf
								ElseIf u5
									If Self.joy.activebutton = 3
										Self.DoAnimSlide()
									Else
										If g_ball <> Null And g_ball.z > g_player_int33 * 0.6 And g_ball.z < g_player_int33 * 1.5 ..
												And Self.distancetoball < TPitch.YardsToPixels(6.0)
											Self.DoAnimDive()
										EndIf
									EndIf
								Else
									If u2 And g_ball <> Null And g_ball.z >= g_player_int33 And Self.jumpspotgood
										Self.DoAnimJump()
									EndIf
								EndIf
							EndIf
						EndIf
					ElseIf u5
						Self.Call()
					EndIf
					Self.kickdirection = -1.0
					Self.kickpower = 0.0
				EndIf
			EndIf
		EndIf
