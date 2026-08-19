' TEngine.SetUpSetPiece -- NOT VERIFIED candidate.
' VA 0x004d2f01   1788 bytes   vtable slot 0x70   sig (i,i,i,i)i
' VA 0x004D2F01   Ghidra-authoritative length 1788 bytes   class-table slot 0x70
' KIND=Function (static, no Self)   SIG=(i,i,i,i)i
'
' Verify:
'   NSS5_WORKER=<id> python -c "
'     import sys, io; sys.path.insert(0,'scripts'); import harness as H
'     from reverify import body_of
'     print(H.try_method('TEngine','SetUpSetPiece',
'       body_of(io.open('src/recovered_unverified/TEngine.SetUpSetPiece.bmx',
'         encoding='utf-8',errors='replace').read())))"
'
' STRUCTURAL FACTS (confirmed against harness.disasm_original, not Ghidra's decompile) --
'
' 1. THE DISPATCH IS ONE `Select g_matchstate` OVER ALL 12 VALUES 0..11, not an If-guarded
'    Select over a subset. Ghidra's decompile shows `if (matchstate!=1 && matchstate!=2) {
'    <dispatch> }`, which reads like a guard -- it is NOT. The real compare chain (read
'    directly off the bytes) tests, IN SOURCE ORDER: 1, 2, 3, 4, 5, 6, 7, 9, 10, 8, 0, 11.
'    Cases 1, 2, 8, 10, 0, 11 are EMPTY (no body at all -- a bare `Case N` with nothing under
'    it, falling straight to End Select).
'
' 2. TEAM SELECTION is `Local team:TTeam = Null` followed by `Select side` (side = a1, copied
'    once) with `Case 1: team=g_hometeam` / `Case 2: team=g_awayteam` -- NOT an If/ElseIf.
'    The tell: the ORIGINAL emits `mov eax,esi` (copy the tested value into eax) BEFORE every
'    `cmp eax,1`/`cmp eax,2` pair that tests `a1`/`side`, at FOUR separate sites (team select,
'    and the Case 4/5/7 counter increments). An `If side=1 ... ElseIf side=2` compiles that
'    same test as a direct `cmp esi,N` (no copy, 2 bytes shorter each time) in THIS compiler;
'    only `Select side ... Case 1 ... Case 2 ...` reproduces the copy-first shape, because
'    Select always evaluates its subject into a dedicated register once even when the subject
'    is already register-resident.
'
' 3. THE SOLO-RELATIONAL BRANCH-SWAP RULE applies to all THREE `ball.x >= 0.0` tests (Case 3's
'    throw-in x, Case 5's corner x, Case 6's goal-kick x). Ghidra prints `0.0 <= (float)ball.x`;
'    the ORIGINAL bytes are `setae` (>=) guarding two DIFFERENT branches. Reproducing `setae`
'    with branches {A,B} requires the NEGATED comparison with SWAPPED content:
'    `If ball.x < 0.0 Then B Else A`, not `If ball.x >= 0.0 Then A Else B`. The naive literal
'    or naive flip both produce `seta`/`setb`, neither of which is `setae`.
'
' 4. Case 6's compound guard is `ball.x > -g_engine_int103*0.75 And ball.x < g_engine_int103*
'    0.75` (both literally `ball.x` on the left, matching Ghidra's own printed order here).
'    No branch-swap applies (there is no Else; the swap rule excludes solo-condition-with-no-
'    Else and compound-And terms).
'
' 5. Case 5's negative-x corner offset is written `-g_pitchhalfwidth - 6`, NOT
'    `-6 - g_pitchhalfwidth` -- mathematically identical, but the ORIGINAL computes it as
'    `mov eax,[g_pitchhalfwidth] / neg eax / sub eax,6` (load-then-negate-then-subtract-
'    constant), while `-6 - g_pitchhalfwidth` compiles as load-immediate-then-subtract-memory,
'    one byte longer. Read the imm32-vs-[mem] operand of the first instruction to tell which
'    form a subtraction was written in.
'
' 6. Case 6's Y-offset is split into TWO STATEMENTS, not one expression:
'       py = g_pitchhalfheight * -team.GetShootingDirection()
'       py = Int(py + TPitch.YardsToPixels(5.5) * team.GetShootingDirection())
'    Writing it as one `Int(A + Yards(5.5)*B)` expression (mathematically identical) leaves
'    `team` in a register that does not survive the intervening YardsToPixels() CALL as
'    cheaply.
'
' 7. `TScreenMessage.ClearAll(0)` takes an explicit `0` argument -- Ghidra's decompile shows
'    an empty argument list (its call-arg-count heuristic fails on this indirect class-table
'    call), but the raw bytes are `push 0 / call [0xc6b274]`.
'
' 8. The g_matchstate=10 (shootout) branch needs an explicit `Return 0` after
'    `TEngine.DoShootOut()` -- without it, execution falls through to the shared tail
'    (CreateBall/SetUpSetPieceBall/...) via the function's single closing `Return 0`, which is
'    functionally harmless but costs the wrong bytes: the ORIGINAL jumps straight to the
'    epilogue with an explicit `mov eax,0` instead of falling through the Else block.
'
' 9. Case 4's `If g_training_int03 = 0 And TPitch.InsidePenaltyBox(px, py,
'    team.GetShootingDirection())` is a single short-circuit `And` condition, not an If/Then
'    with a separate `inbox` Local:
'        If g_training_int03 = 0 And TPitch.InsidePenaltyBox(px, py, team.GetShootingDirection())
'            TEngine.SetUpSetPiece(7, a1, 0, 0)
'            Return 0
'        End If
'    `And` inside an `If` condition short-circuits in this compiler (also visible at Case 6's
'    `ball.x > ... And ball.x < ...` guard). The SECOND term must be bare truthiness
'    (`InsidePenaltyBox(...)`), not an explicit `<> 0` comparison -- `<> 0` materializes the
'    call's return value (setne/movzx) where the ORIGINAL just does `cmp eax,0 / je` on the
'    raw return value.
'
' 10. The LogLine message is `"SetUpSetPiece: " + TEngine.GetStringMatchState() + " " + a1`
'     (the raw side parameter, not `what`). The `push esi` at the StringFromInt call site
'     pushes whatever ESI currently holds; ESI is loaded from a1's parameter slot in the
'     prologue and nothing between there and this call writes to it (not even the training
'     branch's `a1 = 1`, which stores through ESI directly), so the pushed value is a1's
'     current value, confirmed by tracing the argument forward through the concat chain to
'     `Select side`'s `mov eax, esi` a few lines later.
'
' KNOWN REMAINING GAPS (register-allocator/instruction-selection choices, not source defects;
' tried and ruled out: single-line vs separate `Local` declarations, declare-then-assign vs
' initializer, permuting declaration order, substituting `side` for `a1` at the recursive
' call -- none reproduce the ORIGINAL shape and the last two measure worse) --
'   - ORIGINAL +9..+30: the three parameter-to-Local prologue copies. ORIGINAL interleaves
'     load-then-immediately-store per parameter, always through eax; ours loads all three into
'     ecx/edx/eax before storing any. Net 0 bytes, but a real byte-level mismatch. The slot
'     each Local lands in is pinned to its parameter's stack position regardless of Local
'     declaration order, so this is not reachable by reordering the three `Local` statements.
'   - ORIGINAL +1694 (SetUpSetPieceBall's self argument): `push ebx` (ball, direct) vs ours
'     `mov eax,ebx` then `push eax` (+2 bytes). ORIGINAL's other register-resident receivers
'     (`team` in edi, at every CheckComManagement/GetShootingDirection/ResetCornerFormation
'     call site in this function, and `ball` itself at the earlier CheckForPlayerRatings call)
'     all go through a copy-to-eax-first step that ours also uses everywhere; this one call
'     site is the only place ORIGINAL skips it. No distinguishing source property found.
'
' ---- GLOBALS (addresses are fact; names are ours except where another verified file in this
'      tree already established a name for the same address, reused for consistency) ----
'   0x00C6CF90 g_training_int03:Int      0x00C5B1FC g_matchstate:Int (many verified files)
'   0x00C6CF7C g_Object802:TSound        0x00C6F090 g_Object859:TChannel (established:
'     TScreen_Interview.ButtonAddText.bmx, TScreen_Negotiate.Update.bmx)
'   0x00C5B368 g_Object51:TSound, 0x00C5B348 g_Object46:TChannel (established:
'     TPlayer.CheckKeeperSave.bmx -- "crowdoh" sound per TEngine.SetUp.bmx's sound-load list)
'   0x00C5B34C g_snd_whistle:TSound, 0x00C5B33C g_chan_whistle:TChannel (established:
'     TEngine.DoHalfEnds.bmx, TEngine.UpdateSetPieceReady.bmx, TTraining.StartChallenge.bmx --
'     "whistle" per TEngine.SetUp.bmx's sound-load list)
'   0x00C5B1C8 g_engine_font:TBitmapFont (established: TEngine.DoHalfEnds.bmx,
'     TEngine.UpdateSetPieceReady.bmx, TScreen_Interview.Fail.bmx)
'   0x00C5B1F8 g_engine_int17:Int = 1750 (established initialiser, TEngine.DoHalfEnds.bmx /
'     codegen-patterns.md 21.3)
'   0x00C5B218 g_hometeam:TTeam, 0x00C5B21C g_awayteam:TTeam (established:
'     TEngine.SkipMatchTime.bmx; globals_final.tsv's "TKit" guess for 0x00C5B218 is WRONG,
'     corrected project-wide already -- see TBall.CheckSideLines.bmx's note)
'   0x00C5B238 g_engine_int25:Int, 0x00C5B274/78/7C/80/84/88 g_engine_int33..38:Int (usage-
'     typed, globals_final.tsv, no better name established elsewhere)
'   0x00C5D634 g_pitchhalfwidth:Int, 0x00C5D638 g_pitchhalfheight:Int (established:
'     TBall.CheckSideLines.bmx)
'   0x00C5D64C g_engine_int103:Int, 0x00C5D658 g_player_int19:Int, 0x00C5D65C
'     g_engine_int104:Int (usage-typed, no better name established elsewhere)
'
' ---- OTHER RESOLVED CALLS/FIELDS (all confirmed via vtable_map.tsv / object_model.json,
'      not guessed) ----
'   TBall.CheckForPlayerRatings(:TPlayer)i slot 0xCC, called with Null (reproduced verbatim --
'     an ORIGINAL quirk, not tidied). TBall.CreateBall(i,i,i):TBall slot 0x38.
'   TBall.SetUpSetPieceBall(i,i,i)i slot 0x98. TBall.GetActiveBall():TBall slot 0x44.
'   TBall.x/y are Float fields at object offset +0x18/+0x1C (index 6/7 as `int*`).
'   TTeam.CheckComManagement()i slot 0x94, ResetCornerFormation()i slot 0x60,
'     GetShootingDirection()i slot 0x8C, GetSetPieceTakers(i,:TBall)i slot 0x88.
'     TTeam.id is the first user field, offset +8.
'   TPlayer.GetHumanPlayer():TPlayer slot 0x164 (static). TPlayer.calling:Int is the field at
'     object offset +0x114 (index 0x45 as `int*`) -- NOT a vtable slot; a genuine field,
'     confirmed via object_model.json (coincidental numeric overlap with an unrelated method
'     slot elsewhere in the corpus, ignore that overlap).
'   TPlayer.ResetKickAll()i slot 0xA8, ResetOffsideAll()i slot 0x220 (both static).
'   TPitch.InsidePenaltyBox(i,i,i)i slot 0x5C, YardsToPixels(f)f slot 0x6C.
'   TScreenMessage.Create(i,i,$,i,:TBitmapFont,:TImage,f,$)i slot 0x30, Count()i slot 0x34,
'     ClearAll(i)i slot 0x40.
'   TTraining.GetMatchState(*i,*i,*i)i slot 0xB0 (three Int Ptr out-params, called with
'     Varptr what/px/py).
'   TEngine.DoShootOut()i slot 0xEC, GetStringMatchState()$ slot 0xF4,
'     ForcePositionResetAll()i slot 0xE8 (all static, all self-recursive-sibling calls).
'   Message text keys, read with harness.read_string(): "Throw In" (3), "Free Kick" (4),
'     "Corner" (5), "Goal Kick" (6), "Penalty!" (7), "Penalties" (9). All routed through
'     `Lower(GetText(...))` except "Penalty!"/"Penalties" -- confirmed, both use the same
'     `Lower(GetText(...))` wrapper as the rest, no exception found.
'
' Body-only format below matches this project's harness.try_method() input convention;
' parameters are a0 (piece type / "what"), a1 (side: 1=home, 2=away -- mutable, forced to 1
' in training mode), a2 (x hint), a3 (y hint).

Function SetUpSetPiece:Int(a0:Int, a1:Int, a2:Int, a3:Int)
	'!Global g_training_int03:Int
	'!Global g_matchstate:Int
	'!Global g_Object802:TSound
	'!Global g_Object859:TChannel
	'!Global g_Object51:TSound
	'!Global g_Object46:TChannel
	'!Global g_snd_whistle:TSound
	'!Global g_chan_whistle:TChannel
	'!Global g_engine_font:TBitmapFont
	'!Global g_engine_int17:Int = 1750
	'!Global g_hometeam:TTeam
	'!Global g_awayteam:TTeam
	'!Global g_engine_int25:Int
	'!Global g_engine_int33:Int
	'!Global g_engine_int34:Int
	'!Global g_engine_int35:Int
	'!Global g_engine_int36:Int
	'!Global g_engine_int37:Int
	'!Global g_engine_int38:Int
	'!Global g_pitchhalfwidth:Int
	'!Global g_pitchhalfheight:Int
	'!Global g_engine_int103:Int
	'!Global g_player_int19:Int
	'!Global g_engine_int104:Int
	Local what:Int = a0
	Local px:Int = a2
	Local py:Int = a3
	If g_training_int03 <> 0
		a1 = 1
		TTraining.GetMatchState(Varptr what, Varptr px, Varptr py)
		If what = 1
			g_matchstate = 1
			Return 0
		End If
		PlaySound(g_Object802, g_Object859)
	End If
	If g_matchstate = 10
		PlaySound(g_Object51, g_Object46)
		TEngine.DoShootOut()
		Return 0
	Else
		If g_matchstate <> 0 And g_training_int03 = 0
			PlaySound(g_snd_whistle, g_chan_whistle)
		End If
		Local human:TPlayer = TPlayer.GetHumanPlayer()
		If human <> Null Then human.calling = 0
		g_matchstate = what
		LogLine("SetUpSetPiece: " + TEngine.GetStringMatchState() + " " + a1)
		Local team:TTeam = Null
		Local side:Int = a1
		Select side
			Case 1
				team = g_hometeam
			Case 2
				team = g_awayteam
		End Select
		Local ball:TBall = TBall.GetActiveBall()
		If ball <> Null
			ball.CheckForPlayerRatings(Null)
			Select g_matchstate
					Case 1
					Case 2
					Case 3
						team.CheckComManagement()
						TScreenMessage.Create(0, 0, Lower(GetText("Throw In")), g_engine_int17, g_engine_font, Null, 1.0, "FFFFFF")
						If ball.x < 0.0
							px = -g_pitchhalfwidth
						Else
							px = g_pitchhalfwidth
						End If
						py = Int(ball.y)
					Case 4
						team.CheckComManagement()
						Select side
							Case 1
								g_engine_int33 :+ 1
							Case 2
								g_engine_int34 :+ 1
						End Select
						If g_training_int03 = 0 And TPitch.InsidePenaltyBox(px, py, team.GetShootingDirection())
							TEngine.SetUpSetPiece(7, a1, 0, 0)
							Return 0
						End If
						If TScreenMessage.Count() = 0
							TScreenMessage.Create(0, 0, Lower(GetText("Free Kick")), g_engine_int17, g_engine_font, Null, 1.0, "FFFFFF")
						End If
					Case 5
						team.CheckComManagement()
						g_hometeam.ResetCornerFormation()
						g_awayteam.ResetCornerFormation()
						Select side
							Case 1
								g_engine_int35 :+ 1
							Case 2
								g_engine_int36 :+ 1
						End Select
						TScreenMessage.Create(0, 0, Lower(GetText("Corner")), Int(g_engine_int17 * 1.5), g_engine_font, Null, 1.0, "FFFFFF")
						If ball.x < 0.0
							px = -g_pitchhalfwidth - 6
						Else
							px = g_pitchhalfwidth + 6
						End If
						py = (g_pitchhalfheight - 3) * team.GetShootingDirection()
					Case 6
						team.CheckComManagement()
						If ball.x > -g_engine_int103 * 0.75 And ball.x < g_engine_int103 * 0.75
							PlaySound(g_Object51, g_Object46)
						End If
						TScreenMessage.Create(0, 0, Lower(GetText("Goal Kick")), g_engine_int17, g_engine_font, Null, 1.0, "FFFFFF")
						If ball.x < 0.0
							px = -g_engine_int104
						Else
							px = g_engine_int104
						End If
						py = g_pitchhalfheight * -team.GetShootingDirection()
						py = Int(py + TPitch.YardsToPixels(5.5) * team.GetShootingDirection())
					Case 7
						Select side
							Case 1
								g_engine_int37 :+ 1
							Case 2
								g_engine_int38 :+ 1
						End Select
						TScreenMessage.Create(0, 0, Lower(GetText("Penalty!")), g_engine_int17, g_engine_font, Null, 1.0, "FFFFFF")
						px = 0
						py = g_player_int19 * team.GetShootingDirection()
					Case 9
						If g_engine_int25 = 1
							TScreenMessage.Create(0, 0, Lower(GetText("Penalties")), g_engine_int17, g_engine_font, Null, 1.0, "FFFFFF")
						End If
						px = 0
						py = g_player_int19 * team.GetShootingDirection()
					Case 10
					Case 8
					Case 0
					Case 11
			End Select
		End If
		ball = TBall.CreateBall(px, py, 0)
		ball.SetUpSetPieceBall(px, py, team.id)
		team.GetSetPieceTakers(g_matchstate, ball)
		TPlayer.ResetKickAll()
		TPlayer.ResetOffsideAll()
		If g_training_int03 <> 0
			TScreenMessage.ClearAll(0)
			TEngine.ForcePositionResetAll()
		End If
	End If
	Return 0
End Function
