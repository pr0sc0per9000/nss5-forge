' TEngine.SetUpSetPiece -- VERIFIED byte-identical vs NSS5.exe.
' VA 0x004d2f01   1788 bytes   vtable slot 0x70   sig (i,i,i,i)i
' KIND=Function (static, no Self)   SIG=(i,i,i,i)i
' Oracle: harness.try_method under NSS5_NO_LEARN=1 -> MATCH, mode=reloc, 1788/1788,
' first_diff=None, reloc_masked=124. Reproduced 4/4 runs on worker 226.
'
' Verify:
'   NSS5_WORKER=<id> NSS5_NO_LEARN=1 python -c "
'     import sys, io; sys.path.insert(0,'scripts'); import harness as H
'     from reverify import body_of
'     print(H.try_method('TEngine','SetUpSetPiece',
'       body_of(io.open('src/recovered/TEngine.SetUpSetPiece.bmx',
'         encoding='utf-8',errors='replace').read())))"
'
' ============================================================================
' HOW THE LAST 8 BYTES CLOSED (liveness pass, worker 226). The previous header called both
' residuals "register-allocator/instruction-selection choices, not source defects", and
' specifically claimed the prologue was "not reachable by reordering the three Local
' statements". The first half of that was right and the second half was the trap: the lever
' was never DECLARATION ORDER, it was whether those three Locals existed at all. Both
' residuals turned out to be source-reachable. Neither needed a compiler change.
'
' DEFECT 1 (ORIGINAL +9..+29, the prologue parameter copies -- net 0 bytes, 3 gaps).
'   ORIGINAL interleaves load-then-store per parameter, always through eax; ours loaded all
'   four parameters into ecx/esi/edx/eax first and only then stored three of them. Read out
'   of bcc's own source rather than guessed at:
'     * cgframe_x86.cpp CGFrame_X86::genFun() emits `genMov(argreg, mem(ebp,arg_sz+8))` for
'       EVERY argument, at entry, in argument order, before any statement runs. So four
'       contiguous entry loads is the only shape a fully coloured argument set can produce,
'       and a store can never appear between two of them.
'     * cgframe.cpp CGEscFinder forces any tmp whose address is taken (a `lea`) into a stack
'       slot via allocLocal BEFORE the allocator runs. `Varptr x` compiles to `lea(x)` --
'       exp.cpp IntrinsicExp::_eval, T_VARPTR.
'     * cgframe_x86.cpp genMov() opens with `if( lhs->equals(rhs) ) return;`.
'   Put together: if Varptr is applied to the PARAMETER itself, that parameter's own tmp is
'   the escaping one, so genFun's entry `genMov` becomes mem<-mem and expands to
'   `mov eax,[ebp+N] / mov [ebp-M],eax` -- one load/store pair per address-taken parameter,
'   emitted at entry, in parameter order, with the non-escaping parameter's plain register
'   load sitting between them. That is EXACTLY the ORIGINAL's +9..+29.
'   So the ORIGINAL has NO `Local what/px/py` at all: its parameters are named
'   what/side/px/py and `Varptr` is taken of the parameters directly. `side = 1` in the
'   training branch is a write to the PARAMETER, hence `mov esi,1`, which is why the LogLine
'   `push esi` and the Case 4 recursion's `push esi` both carry the updated value.
'   The harness forces parameter names to a0..a3 (harness.py emit_type builds the arglist as
'   "a%d:%s"), so this file spells it `Varptr a0, Varptr a2, Varptr a3` and uses a0/a2/a3
'   where the ORIGINAL wrote what/px/py. Names never reach the bytes.
'   Measured effect of this change alone: gaps 4 -> 1, first divergence +9 -> +1694, length
'   unchanged at 1790.
'
' DEFECT 2 (ORIGINAL +1694, our extra `mov eax,ebx`, +2 bytes). A COALESCING outcome, not a
'   spill outcome. val.cpp Val::find() emits `mov(cg, cg_exp)` for every virtual method call
'   whose Val mentions both `@self` and `@type` (n_self+n_type>1) -- i.e. every ordinary
'   `obj.Method()`. That receiver copy is present at every call site in the ORIGINAL too
'   (`mov eax,edi` before each team call, `mov ebx,edi` before the Case 6 one, `mov eax,ebx`
'   before CheckForPlayerRatings). The one place the ORIGINAL has no copy is
'   SetUpSetPieceBall, because there the copy was COALESCED into the receiver's own register
'   (cgallocregs.cpp canCoalesce(), Briggs: merge iff the combined node has fewer than 6
'   significant-degree neighbours).
'   Our `ball` was one variable doing two jobs -- the GetActiveBall result inspected in the
'   `Select`, then reassigned to the CreateBall result -- so its live range spanned the whole
'   Select and its degree was too high for Briggs to merge the receiver copy. Splitting the
'   second job into its own Local (`newball`, defined and dead inside a single basic block)
'   drops the coalesce candidate's neighbourhood far enough that the merge succeeds and the
'   copy disappears. This is a live-range change, not a rename: the two values never overlap,
'   so both still land in ebx and no other byte moves.
'
' MEASURED ALLOCATOR NUMBERS (scripts/workflow/walloc_report.py --worker walloc226, run on
' the MATCHing body; usage/degree/block_count are bcc's own, read at the decision point):
'   human    regid 18  usage 3   degree 2   block_count 1   -> eax
'   team     regid 19  usage 15  degree 79  block_count 65  -> edi
'   side     regid 20  usage 5   degree 18  block_count 13  -> esi
'   ball     regid 22  usage 9   degree 35  block_count 19  -> ebx
'   newball  regid 42  usage 3   degree 7   block_count 1   -> ebx
'   172 unnamed nodes: 31 coalesced, 139 register, 2 spilled ([ebp-0x14], [ebp-0x10]).
'   Frame 0x18 = 12 (a0/a2/a3 forced to [ebp-4]/[ebp-8]/[ebp-0xc] by Varptr, before the
'   allocator runs) + 8 (the two spilled unnamed nodes) + 4 (fixFp internal scratch).
'   The same run BEFORE the two fixes, for contrast: `ball` usage 12 degree 37 bc 19;
'   what/px/py present as named forced-mem Locals at the same three slots; 29 coalesced
'   instead of 31. The coalesce count moving 29 -> 31 is the direct confirmation that
'   Defect 2's fix did what it was predicted to do rather than closing the bytes by luck.
'   NOTE FOR THE NEXT BODY: the SPILL COST formula was not the lever anywhere here. The
'   frame size, the spill set and every slot were already correct before either change --
'   this body was never sitting on a spill tie. block_count mattered only through
'   `newball`'s bc=1 feeding the COALESCE test. "Diagnosed to the allocator" is worth
'   re-deriving before it is believed: half of this one was emission order (genFun), which
'   the allocator never touches at all.
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
' 2. TEAM SELECTION is `Local team:TTeam = Null` followed by `Select side` (side = the second
'    parameter) with `Case 1: team=g_hometeam` / `Case 2: team=g_awayteam` -- NOT an
'    If/ElseIf. The tell: the ORIGINAL emits `mov eax,esi` (copy the tested value into eax)
'    BEFORE every `cmp eax,1`/`cmp eax,2` pair, at FOUR separate sites (team select, and the
'    Case 4/5/7 counter increments). An `If side=1 ... ElseIf side=2` compiles that same test
'    as a direct `cmp esi,N` (no copy, 2 bytes shorter each time) in THIS compiler; only
'    `Select side ... Case 1 ... Case 2 ...` reproduces the copy-first shape, because Select
'    always evaluates its subject into a dedicated register once even when the subject is
'    already register-resident.
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
'    cheaply. (The ORIGINAL's `mov ebx,edi` at 0x004D343C is Val::find's receiver copy for the
'    second GetShootingDirection, hoisted into a callee-saved register precisely because it
'    has to live across that call -- the same mechanism as DEFECT 2 above, resolved the other
'    way because here the copy genuinely does interfere with `team`.)
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
'    with a separate `inbox` Local. `And` inside an `If` condition short-circuits in this
'    compiler (also visible at Case 6's `ball.x > ... And ball.x < ...` guard). The SECOND
'    term must be bare truthiness (`InsidePenaltyBox(...)`), not an explicit `<> 0`
'    comparison -- `<> 0` materializes the call's return value (setne/movzx) where the
'    ORIGINAL just does `cmp eax,0 / je` on the raw return value.
'
' 10. The LogLine message is `"SetUpSetPiece: " + TEngine.GetStringMatchState() + " " + side`
'     -- the second parameter, whose CURRENT value is pushed (`push esi`). In training mode
'     that value is 1, because the training branch assigns to the parameter itself.
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
'   TTraining.GetMatchState(*i,*i,*i)i slot 0xB0 (three Int Ptr out-params, called with Varptr
'     on the PARAMETERS a0/a2/a3 -- see DEFECT 1; that is what puts them at
'     [ebp-4]/[ebp-8]/[ebp-0xc] and produces the ORIGINAL's prologue shape).
'   TEngine.DoShootOut()i slot 0xEC, GetStringMatchState()$ slot 0xF4,
'     ForcePositionResetAll()i slot 0xE8 (all static, all self-recursive-sibling calls).
'   Message text keys, read with harness.read_string(): "Throw In" (3), "Free Kick" (4),
'     "Corner" (5), "Goal Kick" (6), "Penalty!" (7), "Penalties" (9). All routed through
'     `Lower(GetText(...))`.
'
' Body-only format below matches this project's harness.try_method() input convention. The
' four parameters are the ORIGINAL's what (piece type), side (1=home, 2=away; mutable, forced
' to 1 in training mode), px and py (x/y hints). a0/a2/a3 have their address taken; a1 (side)
' does not, which is why it alone keeps a register (esi).

' CASE DIRECTION CORRECTED 2026-08-22: 6 call sites -> .ToUpper().
' extracted/runtime_helpers.tsv named 0x004A7410 `_brl_retro_Lower` and 0x004A74E0
' `_brl_retro_Upper`. Both were wrong and neither address is a brl.retro wrapper:
' 0x004A7410 is `_bbStringToUpper` and 0x004A74E0 is `_bbStringToLower`. NSS5.exe's
' own 21-byte retro wrappers at 0x0059C8FD (Lower) and 0x0059C912 (Upper) CALL those
' two addresses, and a wrapper cannot be the function it calls. The wrong row masked
' by name, so this body certified with the case conversion running backwards. Full
' derivation and the discriminating 3x4 matrix: docs/reference/codegen-patterns.md
' 15.6. Re-verified under NSS5_NO_LEARN=1 on worker trees 380 and 380b.
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
	If g_training_int03 <> 0
		a1 = 1
		TTraining.GetMatchState(Varptr a0, Varptr a2, Varptr a3)
		If a0 = 1
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
		g_matchstate = a0
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
						TScreenMessage.Create(0, 0, GetText("Throw In").ToUpper(), g_engine_int17, g_engine_font, Null, 1.0, "FFFFFF")
						If ball.x < 0.0
							a2 = -g_pitchhalfwidth
						Else
							a2 = g_pitchhalfwidth
						End If
						a3 = Int(ball.y)
					Case 4
						team.CheckComManagement()
						Select side
							Case 1
								g_engine_int33 :+ 1
							Case 2
								g_engine_int34 :+ 1
						End Select
						If g_training_int03 = 0 And TPitch.InsidePenaltyBox(a2, a3, team.GetShootingDirection())
							TEngine.SetUpSetPiece(7, a1, 0, 0)
							Return 0
						End If
						If TScreenMessage.Count() = 0
							TScreenMessage.Create(0, 0, GetText("Free Kick").ToUpper(), g_engine_int17, g_engine_font, Null, 1.0, "FFFFFF")
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
						TScreenMessage.Create(0, 0, GetText("Corner").ToUpper(), Int(g_engine_int17 * 1.5), g_engine_font, Null, 1.0, "FFFFFF")
						If ball.x < 0.0
							a2 = -g_pitchhalfwidth - 6
						Else
							a2 = g_pitchhalfwidth + 6
						End If
						a3 = (g_pitchhalfheight - 3) * team.GetShootingDirection()
					Case 6
						team.CheckComManagement()
						If ball.x > -g_engine_int103 * 0.75 And ball.x < g_engine_int103 * 0.75
							PlaySound(g_Object51, g_Object46)
						End If
						TScreenMessage.Create(0, 0, GetText("Goal Kick").ToUpper(), g_engine_int17, g_engine_font, Null, 1.0, "FFFFFF")
						If ball.x < 0.0
							a2 = -g_engine_int104
						Else
							a2 = g_engine_int104
						End If
						a3 = g_pitchhalfheight * -team.GetShootingDirection()
						a3 = Int(a3 + TPitch.YardsToPixels(5.5) * team.GetShootingDirection())
					Case 7
						Select side
							Case 1
								g_engine_int37 :+ 1
							Case 2
								g_engine_int38 :+ 1
						End Select
						TScreenMessage.Create(0, 0, GetText("Penalty!").ToUpper(), g_engine_int17, g_engine_font, Null, 1.0, "FFFFFF")
						a2 = 0
						a3 = g_player_int19 * team.GetShootingDirection()
					Case 9
						If g_engine_int25 = 1
							TScreenMessage.Create(0, 0, GetText("Penalties").ToUpper(), g_engine_int17, g_engine_font, Null, 1.0, "FFFFFF")
						End If
						a2 = 0
						a3 = g_player_int19 * team.GetShootingDirection()
					Case 10
					Case 8
					Case 0
					Case 11
			End Select
		End If
		Local newball:TBall = TBall.CreateBall(a2, a3, 0)
		newball.SetUpSetPieceBall(a2, a3, team.id)
		team.GetSetPieceTakers(g_matchstate, newball)
		TPlayer.ResetKickAll()
		TPlayer.ResetOffsideAll()
		If g_training_int03 <> 0
			TScreenMessage.ClearAll(0)
			TEngine.ForcePositionResetAll()
		End If
	End If
	Return 0
End Function
