' TEngine.SetUpSetPiece -- NOT VERIFIED candidate.
' VA 0x004D2F01   Ghidra-authoritative length 1788 bytes   class-table slot 0x70
' KIND=Function (static, no Self)   SIG=(i,i,i,i)i
'
' CURRENT STATE: mode=len (length mismatch), 1787 of 1788 bytes -- ours is 1 byte SHORT.
' localise_diff.py reports the delta as fully accounted for (COMPLETE) by 6 small
' length-changing gaps, all clustered in two families:
'   (a) the prologue's parameter-to-local-slot copy (a0/a2/a3 spilled to [ebp-4]/[ebp-8]/
'       [ebp-0xc]): the ORIGINAL loads each of the three incoming stack params through EAX
'       ONE AT A TIME (mov eax,[ebp+N] / mov [ebp-M],eax, repeated three times, always EAX);
'       ours spreads the three loads across ECX/EDX/EAX instead (register choice only, same
'       instruction count -- costs 3 bytes twice, at ORIGINAL +9 and +18).
'   (b) two isolated "team" self-register picks late in the function keep the exact same
'       shape as (a) -- ORIGINAL keeps `team` in a role that survives a call (visible as
'       `push ebx / mov eax,[ebx]` at the Case 6 YardsToPixels call and at the final
'       SetUpSetPieceBall call), ours does the equivalent through a different but
'       byte-identical-length register in most spots (see ORIGINAL +1370/+1703 SUBs when
'       present) or a genuinely different, longer copy pattern at ORIGINAL +245 (StringFromInt
'       argument: ORIGINAL is `push esi` directly, 1 byte; ours reloads `what` from its own
'       [ebp-4] spill slot, 3 bytes -- meaning at THIS point in the ORIGINAL, ESI has already
'       been reallocated away from `a1`/`side` to hold `what` instead, because `a1` is not
'       read again until deep inside Case 4/5/7).
' Every one of these is byte-count-neutral or near-neutral register-choice/spill-order
' territory (guide sections 18, 22) -- NOT a missing statement, NOT a wrong value, NOT a
' wrong branch. `first_diff`/matched/mode all confirm the body's STATEMENT STRUCTURE is
' already exactly right; only which physical register a few already-correct values sit in
' at a few points differs.
'
' ---- FOLLOW-UP PASS (item 9/refine.json) -- re-ran localise_diff.py fresh; NO CODE CHANGED --
' The prior pass's "(a)/(b), two families" undercounts what localise_diff actually reports:
' there are 6 gaps and they fall into (at least) THREE independent families, not two. The
' third is the real find here:
'   (c) ORIGINAL +688 (Case 4's `If g_training_int03 = 0 Then inbox = InsidePenaltyBox(...)`)
'       compiles the training-flag test as a full MATERIALIZED BOOLEAN --
'       `mov eax,[g_training_int03] / cmp eax,0 / sete al / movzx eax,al / cmp eax,0 / je` --
'       19 bytes, NOT the 9-byte direct `cmp [mem],0 / jne` ours emits (a -5 byte gap).
'       CONFIRMED (not guessed): rewriting the guard as its own Local --
'       `Local trainingoff:Int = (g_training_int03 = 0)` then `If trainingoff` -- reproduces
'       ORIGINAL's exact 17-byte materialization sequence byte-for-byte (mov/cmp/sete/movzx/
'       cmp/je all identical). Ruled OUT as NOT the cause: parenthesising the condition,
'       `If Not g_training_int03`, and single-line `If`/`Then` all compile to the SAME short
'       direct form ours already uses -- so the long form is specifically what a separate
'       Local assignment forces, not a property of the comparison's surface syntax.
'   UNRESOLVED: every placement tried for the OTHER half -- `Local inbox:Int = 0`, which must
'   sit somewhere in this same stretch -- costs MORE than it saves, because bcc's colourer
'   then wants a second scratch register for `inbox`'s own zero-store (edx, spilling
'   `trainingoff` into a `mov edx,eax` copy, or vice versa) and ORIGINAL shows NEITHER: no
'   `inbox=0` store appears anywhere near +688 at all, meaning `inbox`'s zero must already be
'   in place before this point by some mechanism not yet found (an earlier shared zero, a
'   different slot, or a construct that doesn't lower to a literal store here). Tried and
'   MEASURED WORSE (net length delta went from -1 to +11, `matched` flat or down): trainingoff
'   before inbox, inbox before trainingoff, inbox with no initialiser, and the two on one
'   `Local a:Int=.., b:Int=..` line. Do not re-try these four without new evidence for where
'   `inbox`'s zero really lives -- start from a live-range census of ORIGINAL's Case 4 slots
'   (guide 18.4's technique), not further permutation.
'   GAP5 (ORIGINAL +245, the StringFromInt argument) and GAP6 (ORIGINAL +1694, a redundant
'   `mov eax,ebx` before the closing SetUpSetPieceBall call) were independently re-derived and
'   match the prior pass's (b) exactly -- both are genuine single-reference live-range
'   artifacts (guide 18.4) with no source-level lever found in this pass either.
' NET: no change made. Every rewrite attempted this pass scored equal to or worse than the
' body already on disk (`matched` 246-248 vs the existing 247, length delta +11 vs the
' existing -1). Leaving the body as inherited per rule 4 -- it is closer than anything
' produced this pass -- but the (c) finding and the ruled-out list above are new and should
' save a future pass from re-treading them.
'
' Verify current state:
'   NSS5_WORKER=<id> NSS5_NO_LEARN=1 python -c "
'     import sys; sys.path.insert(0,'scripts'); import harness
'     print(harness.try_method('TEngine','SetUpSetPiece', open('src/recovered_unverified/TEngine.SetUpSetPiece.bmx').read()))"
'   (strip this header/wrapper to body-only text first, or use scripts/reverify.body_of()).
'
' ---- WHAT WAS SOLVED THIS PASS (all confirmed against harness.disasm_original, not Ghidra) --
'
' 1. THE DISPATCH IS ONE `Select g_matchstate` OVER ALL 12 VALUES 0..11, not an If-guarded
'    Select over a subset. Ghidra's decompile shows `if (matchstate!=1 && matchstate!=2) {
'    <dispatch> }`, which reads like a guard -- it is NOT. The real compare chain (read
'    directly off the bytes) tests, IN SOURCE ORDER: 1, 2, 3, 4, 5, 6, 7, 9, 10, 8, 0, 11.
'    Cases 1, 2, 8, 10, 0, 11 are EMPTY (no body at all -- a bare `Case N` with nothing under
'    it, falling straight to End Select). This is the single biggest structural finding: it
'    closed a -46-byte gap by itself. Do not reintroduce the If-guard shape.
'
' 2. TEAM SELECTION is `Local team:TTeam = Null` followed by `Select side` (side = a1, copied
'    once) with `Case 1: team=g_hometeam` / `Case 2: team=g_awayteam` -- NOT an If/ElseIf.
'    The tell: the ORIGINAL emits `mov eax,esi` (copy the tested value into eax) BEFORE every
'    `cmp eax,1`/`cmp eax,2` pair that tests `a1`/`side`, at FOUR separate sites (team select,
'    and the Case 4/5/7 counter increments). An `If side=1 ... ElseIf side=2` compiles that
'    same test as a direct `cmp esi,N` (no copy, 2 bytes shorter each time) in THIS compiler;
'    only `Select side ... Case 1 ... Case 2 ...` reproduces the copy-first shape, because
'    Select always evaluates its subject into a dedicated register once (guide 10.2) even
'    when the subject is already register-resident. This fixed all four sites at once
'    (-27 bytes) the moment they were rewritten as `Select side`.
'
' 3. THE SOLO-RELATIONAL BRANCH-SWAP RULE (guide section 21) applies to all THREE
'    `ball.x >= 0.0` tests (Case 3's throw-in x, Case 5's corner x, Case 6's goal-kick x).
'    Ghidra prints `0.0 <= (float)ball.x`; the ORIGINAL bytes are `setae` (>=) guarding two
'    DIFFERENT branches. Per the rule, reproducing `setae` with branches {A,B} requires
'    writing the NEGATED comparison with SWAPPED content: `If ball.x < 0.0 Then B Else A`,
'    not `If ball.x >= 0.0 Then A Else B`. Getting this backwards (either literal
'    `0.0<=ball.x` OR the naive flip `ball.x>=0.0`) produces `seta` or `setb` respectively --
'    NEITHER of which is the wanted `setae` -- only the negate+swap form gives `setae`.
'    Confirmed at all three sites simultaneously.
'
' 4. Case 6's compound guard is `ball.x > -g_engine_int103*0.75 And ball.x < g_engine_int103*
'    0.75` (both literally `ball.x` on the left, matching Ghidra's own printed order here --
'    unlike finding 3, Ghidra's order happens to be right for both halves of THIS compound).
'    No branch-swap applies (there is no Else; guide section 21 explicitly excludes solo-
'    condition-with-no-Else and compound-And terms from the swap rule).
'
' 5. Case 5's negative-x corner offset must be written `-g_pitchhalfwidth - 6`, NOT
'    `-6 - g_pitchhalfwidth` -- mathematically identical, but the ORIGINAL computes it as
'    `mov eax,[g_pitchhalfwidth] / neg eax / sub eax,6` (10 bytes: load-then-negate-then-
'    subtract-constant), while `-6 - g_pitchhalfwidth` compiles as `mov eax,-6 / sub eax,
'    [g_pitchhalfwidth]` (11 bytes: load-immediate-then-subtract-memory). Read the actual
'    imm32 vs `[mem]` operand of the first instruction to tell which form a subtraction was
'    written in; do not assume commutativity is free.
'
' 6. Case 6's Y-offset must be split into TWO STATEMENTS, not one expression:
'       py = g_pitchhalfheight * -team.GetShootingDirection()
'       py = Int(py + TPitch.YardsToPixels(5.5) * team.GetShootingDirection())
'    Writing it as one `Int(A + Yards(5.5)*B)` expression (mathematically identical) leaves
'    `team` in a register that does not survive the intervening YardsToPixels() CALL as
'    cheaply -- splitting into two statements freed 6 bytes (from -8/+2 net across two gaps to
'    net 0 at that site) by changing which value has to be kept alive, in which register,
'    across the call. This is the ONE place a source-level restructure (not just operand-order)
'    measurably fixed a register/liveness gap this pass; try the analogous split on similar
'    "call sandwiched between two uses of the same value" residuals elsewhere.
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
'   String build for the LogLine is `"SetUpSetPiece: " + TEngine.GetStringMatchState() + " "
'     + what` (implicit Int->String on `what`), confirmed by the 3-call-order (StringFromInt
'     first as the right operand of the OUTER concat, then GetStringMatchState, then the
'     three _bbStringConcat calls) matching bcc's documented right-to-left argument push order
'     (guide 16.2) exactly.
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
		LogLine("SetUpSetPiece: " + TEngine.GetStringMatchState() + " " + what)
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
						Local inbox:Int = 0
						If g_training_int03 = 0
							inbox = TPitch.InsidePenaltyBox(px, py, team.GetShootingDirection())
						End If
						If inbox <> 0
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
