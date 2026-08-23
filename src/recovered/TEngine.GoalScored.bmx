' TEngine.GoalScored
' VA 0x004D39D6   1713 bytes  mode=reloc  byte-identical vs NSS5.exe (1713/1713, 119 reloc
'   operands masked; MATCH reproduced 4/4 under NSS5_NO_LEARN=1)
' KIND=Function (STATIC method on TEngine), SIG (:TBall)i, class-table slot 0x84
'
' CLOSED by the liveness / statement-placement pass. It had been parked at +67 bytes over 29
' gaps with its own header calling the residual a register-allocator decision that source
' could not reach. That diagnosis was wrong: BOTH remaining defects were ordinary source
' shape. The two fixes, and the instrumented-allocator numbers that prove the first one, are
' in RESOLVED at the bottom of this header. The structural analysis for the Select
' dispatches, the guard clause, the branch-swapped y-sign gate and the inlined Kick call was
' re-derived from the original disassembly and is unchanged:
'
' TWO SITES NEED NON-OBVIOUS SHAPES, both verified directly against the disassembly, not
' just cited. The outer training-mode gate is a GUARD CLAUSE (docs/reference/codegen-
' patterns.md section 3f), not an If/Else -- item 1 below. The y-sign scoring-end gate is
' a genuine two-way `If cond Then A Else B` whose arms bcc emits as the LOGICAL NEGATION of
' the written comparison with the Then/Else CONTENT SWAPPED -- docs/reference/codegen-
' patterns.md section 21, "the solo-relational If/Else branch-swap rule" -- item 2 below.
' Every OTHER `If` in this body is single-branch (no `Else` at all) or an `ElseIf` cascade,
' both exempt from the branch-swap rule; see the paragraph after item 2 for the full list:
'   1. Outer training-mode gate. Original bytes at 0x0019: `cmp [g_training_int03],0` /
'      `je 0x4d3a0c` (SHORT jump, +0x14). The je TARGET (0x4d3a0c) is `g_engine_int27 =
'      g_player_int50`, i.e. the START of the big match-goal block; the FALLTHROUGH (when
'      g_training_int03<>0) is `push edi / call [TTraining.GoalScored] / mov eax,0 / jmp
'      epilogue` -- 20 bytes, exactly matching the je's +0x14 displacement. This is
'      docs/reference/codegen-patterns.md section 3f's guard-pattern shape verbatim
'      (`cmp [g],0 / jne body / mov eax,0 / jmp end` is an early return, not an If-block):
'      the delegate call plus its own `mov eax,0` sits physically first as the fallthrough
'      arm, with the big match-goal block as the jump target and NO shared Else scope
'      between them. Written as `If g_training_int03 <> 0 Then TTraining.GoalScored(a0) ;
'      Return 0 ; EndIf` followed by the big block unconditionally (not nested in an Else),
'      bcc emits exactly this shape: the delegate's own `mov eax,0` right after its call,
'      and the big block starting fresh at the guard's jump target with a0 (edi) needed on
'      every path out of the entry block, so bcc caches a0 in a callee-saved register at
'      entry -- the `mov edi,[ebp+8]` immediately after the prologue that the original has.
'   2. The y-sign scoring-end gate. Original bytes 0x01A0-0x01B5: `fld [edi+0x1c]` (a0.y) /
'      `fldz` / `fxch` / `fucompp` / `fnstsw` / `sahf` / `setae al` (setae = a0.y >= 0.0) /
'      `cmp eax,0` / `jne 0x4d3c6f`. jne fires (jumps) when the setae flag is TRUE, i.e. when
'      a0.y >= 0.0 -- and the jump TARGET (offset 0x299) is the Select block whose Case 1
'      credits score2/away, which is exactly the y>=0 case's content. The FALLTHROUGH
'      (offset 0x1BB, taken when a0.y < 0.0) is the Select block whose Case 1 credits
'      score1/home -- the y<0 case's content. So the y<0 arm is physically first/fallthrough,
'      the y>=0 arm is the jump target -- again the negated-and-swapped shape codegen-
'      patterns.md section 21 describes verbatim for a solo `>=`/setae guard: "the source
'      must read `If x < y Then F Else T`, not `If x >= y Then T Else F`." Fix: written as
'      `If a0.y < 0.0 Then <y<0 Select, Case1=score1/home> Else <y>=0 Select,
'      Case1=score2/away> EndIf`.
'   Every OTHER `If` in this body is either single-branch (no `Else` at all -- the three
'   short-circuit `And` gates in the tail, the two newstar/StarShower guards, the
'   a0.controlledby guard, a0.lasttouchedby guard) or an `ElseIf` cascade (the g_matchstate=10 gate --
'   verified NOT swapped, original's `cmp [g_matchstate],0xa / jne <normal-goal-code>` already
'   matches straight `If g_matchstate = 10 Then <shootout> Else <normal> EndIf` with no
'   inversion needed; and the closing hometeam/awayteam credit `If...ElseIf...EndIf`, also
'   confirmed unswapped against the tail bytes at 0x0673-0x06A8). Section 21's own text warns
'   this is a per-site rule, not a blanket one -- both `=`/`<>` two-way ifs in this body were
'   checked individually against the disassembly rather than assumed.
'
' ASSIST-BLOCK LOCALS (unchanged from the prior draft, independently re-confirmed against
' dis7.py): `assistkx`/`assistky` are `:Int`, not `:Float`. Bytes 0x0537/0x0540 load
' a0.assistedby.kickx/.kicky with a plain `mov` into esi/ebx (never `fld`), and every one of
' the three later uses (AngleTo at 0x0580/0x0574, the inlined Dist2D at 0x05D1/0x05C5, AddStat
' at 0x05F4/0x05E8) re-does its OWN int-to-float `fild` from the SAME two registers through
' the shared scratch stack slot at [ebp-8] -- a plain Int Local promoted at each Float-
' parameter call site, matching `Local assistkx:Int = a0.assistedby.kickx` /
' `Local assistky:Int = a0.assistedby.kicky`, not a cached Float (which would `fld` from its
' OWN dedicated slot instead of re-`fild`-ing from [ebp-8] every time). The single stack slot
' at [ebp-8] is a compiler scratch spill reused throughout the WHOLE function for every
' int-to-float call-argument conversion -- not a named source Local by itself; frame size
' `sub esp,8` covers exactly this slot plus [ebp-4] (assistang's own float spill, see next).
' `assistdist` IS a separate `Local assistdist:Float`. The prior header claimed the exact
' opposite, and that claim was the whole blocker -- see RESOLVED. It costs zero bytes because
' a Float Local that is not live across a call keeps an x87 register (codegen-patterns 6):
' walloc_report confirms assistdist ends in fp0 with NO stack slot, so the frame stays
' `sub esp,8` and the argument push is still the bare `sub esp,4 / fstp [esp]` at 0x0603 that
' the original has. The FPU-stack-passthrough bytes therefore do NOT discriminate between a
' Local and an inline call, which is what the prior reading assumed they did.
' `assistang`, by contrast, DOES get a stack slot ([ebp-4], `fstp dword`
' at 0x0594, reloaded once via `push [ebp-4]` at 0x0606) because Dist2D's own call at 0x05DD
' would otherwise clobber AngleTo's still-pending FPU result -- matching
' `Local assistang:Float = AngleTo(...)` used later, not inlined.
' The Kick call (a0.controlledby <> Null guard) is ONE nested expression, not three Locals:
' Kick's trailing literal args (teammateid=0, kicktype=1, power=50.0) are pushed FIRST, at
' 0x00F3-0x00F7, before g_goalline is even loaded -- cdecl right-to-left argument evaluation,
' only possible if `angle` is written in place as `AngleTo(...)`, not read back from a Local.
' This also explains why esi is needed there at all: evaluating `a0.Kick(...)` while its own
' 2nd argument still has GetShootingDirection()/AngleTo() left to run forces the receiver
' (a0, resident in edi) to be re-parked in esi (`mov esi,edi` at 0x00EE) to survive those
' nested calls.
'
' Body-only format: statements only; parameter is a0:TBall (the ball that entered the net).
'
' FIELD OFFSETS BOUND (object_model.json, all confirmed against sibling recovered bodies):
'   TBall     +0x18 x, +0x1c y, +0x70 controlledby:TPlayer, +0x74 lastkickedby:TPlayer,
'             +0x78 lasttouchedby:TPlayer, +0x7c assistedby:TPlayer, slot 0x68 Kick(:TPlayer,f,f,i,i)i.
'   TPlayer   +0x8 newstar, +0x14 teamid, +0x4c x, +0x50 y, +0x94 kickx, +0x98 kicky,
'             +0x9c receivex, +0xa0 receivey, +0xbc selectionno, +0xe0 directiontogoal_opp,
'             +0xe8 distancetogoal_opp, +0x158 joy:TJoy, slot 0x160 GetShootingDirection()i,
'             slot 0x228 AddStat(i,f,f,f,f)i.
'   TJoy      +0x18 kickenabled.
'   TFixture  +0x2c score1, +0x30 score2, +0x34 penscore1, +0x38 penscore2.
'   TTeam/TBase_Team +0x8 id.
'
' CALL TARGETS RESOLVED. These are class-table interiors reached through a data pointer
' (extracted/globals_final.tsv marks each "NOT A GLOBAL: class-table interior"), the same
' shape as every other cross-Type static dispatch already in this corpus:
'   0x00C5BB1C = TEngine+0xEC        = DoShootOut()i          (confirmed by TEngine.UpdateMatchTime.bmx's
'                header: "0x00C5BB1C = TEngine + 0xEC = DoShootOut();")
'   0x00C6B264 = TScreenMessage+0x30 = Create(i,i,$,i,:TBitmapFont,:TImage,f,$)i
'   0x00C6AFC0 = TParticle+0x38      = StarShower(i,i,$,$)i
'   0x00C6D550 = TTraining+0xAC      = GoalScored(:TBall)i  (the training-mode twin of this body --
'                extracted/decomp/TTraining.GoalScored@005823d6.c, identical (:TBall)i signature,
'                param_1 there is the SAME TBall, not a Self)
' Module Functions/helpers (already established elsewhere in this corpus):
'   FUN_00505b91 = LogLine($)                    FUN_0059b25e = PlaySound(:TSound,:TChannel)i
'   FUN_0050639d = AngleTo(f,f,f,f)f              FUN_00505da2 = Dist2D(f,f,f,f)f
'   FUN_004c5549 = GetText($)$                    FUN_004a7410 = Lower($)$
'   FUN_005b9690 = Int(d) (_bbFloatToInt)          TPlayer slot 0x160 = GetShootingDirection()i
'
' Ghidra MERGES a call's pushed args into the textually-nearest PRECEDING call when cdecl
' evaluates/pushes right-to-left and one operand needs no call of its own -- the same artefact
' documented in TPlayer.HeadBallAdvanced.bmx (FUN_005b9690) and TPlayer.RedCard.bmx
' (FUN_004c5549 / PTR_FUN_00c6b264, VERIFIED byte-identical). Two sites here show it:
'   * `(**+0x160)(controlledby,0x42480000,1,0)` -- GetShootingDirection()i takes NO args
'     (object_model.json). The trailing (50.0, 1, 0) are really TBall.Kick's own missing
'     power/kicktype/teammateid: slot 0x68 three lines later shows only 2 of Kick's 5 args.
'   * `FUN_004c5549(&PTR_PTR_00c741fc,&PTR_PTR_00c6e904)` -- GetText($) takes ONE arg
'     (0xC741FC="Goal!"); 0xC6E904="00FF00" is StarShower's own trailing colour argument,
'     evaluated first because it is the LAST-declared parameter (right-to-left order) and
'     needs no call of its own to produce its value.
' String literals read directly with harness.read_string() (not guessed): 0xC741DC="GoalScored"
' 0xC741FC="Goal!" 0xC74214="Assist" 0xC73F6C="990099" 0xC5D680="FFFFFF" 0xC6E904="00FF00" --
' the three hex triples are exactly the shape of the raw colour-string literals already
' established at TScreenMessage.Create/StarShower call sites elsewhere (TPlayer.RedCard.bmx,
' TEngine.DoHalfEnds.bmx), which is what confirms they are colours, not GetText() keys.
'
' GLOBALS -- resolved with scripts/explain_global.py. Where it reports several competing
' names for one slot (this corpus's known name-unification gap) the CERTAIN/majority name is
' used; where it reports ZERO names (a slot only this body writes) the best-evidenced name
' from sibling TEngine bodies is kept and flagged below:
'   0x00C5B254 g_engine_int27:Int -- explain_global.py resolves 0 names AT THIS ADDRESS (no
'     write site existed before this body -- exactly the "dead Global" this file revives).
'     By NAME "g_engine_int27" is the only real candidate (globals_final.tsv: "4 writes" =
'     TEngine.DoHalfEnds.bmx x2 + TEngine.DoShootOut.bmx x1 + this body's x1). The
'     `g_engine_int27 = g_player_int50` shape here is byte-identical to both those bodies.
'   0x00C5B364 g_snd_crowd:TSound / 0x00C5B348 g_chan_crowd:TChannel -- explain_global.py
'     resolves 0 names by address; the single-body AMBIGUOUS-tier guess from
'     TEngine.DoHalfEnds.bmx is the only candidate anywhere in the corpus for this exact
'     PlaySound(...) address pair and is reused verbatim (same sibling Type, same call shape).
'   0x00C5D638 g_goalline:Int -- explain_global.py shows this slot genuinely contested
'     (g_goalline / g_pitch_halfh / g_player_int17 / g_walldist all reported CERTAIN by
'     different bodies -- a pre-existing corpus conflict this file cannot settle). Kept as
'     g_goalline for the semantic fit: `(goalline+100) * GetShootingDirection()` is a target Y
'     just behind whichever goal the controlling player is shooting at, immediately fed into
'     AngleTo(ball.x, ball.y, 0, thatY) to aim a clearance/restart kick.
'   0x00C5B24C g_engine_int26:Int -- AMBIGUOUS (g_engine_int26: 3 bodies vs 2 singleton
'     guesses); majority name kept. Never read back by this body.
' Uncontested CERTAIN/STRONG picks used as explain_global.py reports them:
'   g_training_int03(0x00C6CF90) g_player_int50(0x00C6EFD4) g_matchstate(0x00C5B1FC)
'   g_engine_int25(0x00C5B238) g_fixture(0x00C5B22C) g_hometeam(0x00C5B218)
'   g_awayteam(0x00C5B21C) g_player_int04(0x00C5B250) g_player_tplayer01(0x00C5B248)
'   g_engine_int31(0x00C5B26C) g_engine_int32(0x00C5B270) g_engine_int18(0x00C5B208).
'   g_engine_arr01:Int[](0x00C5B240) matches the TEngine.SetUpMatch.bmx correction (a
'     literal-0/1 store with no refcount traffic -- Int[], not Object[]).
'   g_engine_font(0x00C5B1C8) / g_engine_int17(0x00C5B1F8, =1750) match the
'     TScreenMessage.Create idiom already established identically in TEngine.DoHalfEnds.bmx /
'     TEngine.UpdateSetPieceReady.bmx / TEngine.SetUpSetPiece.bmx (4 TEngine-family bodies,
'     all forced, all agree) -- kept over explain_global.py's lone single-body "g_font2"
'     guess at 0x00C5B1C8, which comes from an unrelated Type and would break consistency
'     with this Type's own established convention.
'
' WHAT IT DOES. If a training session is running, delegates entirely to
' TTraining.GoalScored(a0) and does nothing else. Otherwise: during a penalty shootout
' (g_matchstate=10) updates the shootout penalty score and marks this attempt's result in
' the shootout array, then hands off to DoShootOut() to continue the sequence. Otherwise this
' is a normal match goal: if the ball still has a controller, kicks it away first (toward
' whichever goal that player is attacking); plays the crowd-goal sound and a "Goal!" banner;
' sets g_matchstate=8 (goal-celebration state); and credits whichever team's end the ball
' crossed -- the scoring end depends on BOTH the ball's Y sign and which half/period
' g_engine_int18 is in, since ends swap every half (an ORIGINAL, deliberately preserved,
' four-way Select per side rather than a single parity test). Finally, if the ball has a
' lasttouchedby, that player becomes g_player_tplayer01 (read afterwards by
' TPlayer.DoCelebrations.bmx to single out the scorer for the big celebration animation) --
' or lastkickedby instead, if lastkickedby differs and lasttouchedby is not carded/subbed.
' When this was not a shootout goal and that player's team matches the credited scoring team:
' records the scorer's goal stat (AddStat 5), fires a green TParticle.StarShower at the
' scorer's position if they are the human ("newstar") player, credits a same-team assist
' (AddStat 4) with its own magenta StarShower for a human assister, and bumps the matching
' per-team goal counter (g_engine_int31 home / g_engine_int32 away).
'
' RESOLVED -- what the two defects actually were, with the measurements.
'
' DEFECT 1 accounted for all +67 bytes: 19 same-shape "+3, one extra `mov eax,[ebp+8]`" gaps
' plus the missing `mov edi,[ebp+8]` at +9. The parameter `a0` was not register-allocated.
' `a0` is not a Local, so it never appears by name in any tool: in bcc a parameter is an
' ordinary CG temporary (`FunBlock::resolve` does `cg_fun->args.push_back(tmp(...))`) and
' `CGFrame_X86::genFun` emits one `mov <argreg>,[ebp+8]` at entry, which is exactly the
' original's `mov edi,[ebp+8]` at +9. When that temporary fails to colour,
' `CGFrame_X86::allocSpill` hands it back its own ARGUMENT slot [ebp+8] instead of a frame
' slot, so the spill consumes no frame bytes -- codegen-patterns 22.4's `sub esp,N` clue is
' silent on it -- and every later reference becomes a fresh reload.
'
' Instrumented-allocator numbers (scripts/workflow/walloc_report.py; cost =
' usage/(degree*block_count), exactly as cgallocregs.cpp spill() computes it). `a0` is
' regid 15, unnamed because arguments do not go through LocalDeclStm:
'
'                       usage  degree(graph)  degree(at pick)  block_count  cost       outcome
'   a0 BEFORE (broken)    28        134             7              58       0.0689655  UNCOLORED -> REALSPILL -> [ebp+8]
'   a0 AFTER  (matches)   28        139             6              58       0.0804598  colour 5 = edi
'   assistkx               4         16             6               1       0.666667   esi
'   assistky               4         15             6               1       0.666667   ebx
'   assistang :Float       2         15             7               1       0.285714   PICKED -> [ebp-4]  (correct; original spills it too)
'   assistdist :Float      2          3             -               1       -          fp0, no stack slot
'
' READ THOSE NUMBERS CAREFULLY, because they refute the hypothesis this pass started from.
' `block_count` did NOT move: 58 before, 58 after. `usage` did not move either (28 both
' ways), and `degree` went UP. `a0` is STILL the lowest-cost node in bank 0 after the fix and
' is still PICKED by spill() in both passes -- it simply gets coloured anyway, because
' cgAllocRegs is optimistic. So this body was never a usage/(degree*block_count) RANKING
' problem, and no amount of moving `a0`'s references could have fixed it: at block_count 58
' and degree 7 it would have needed usage > 232 to outrank assistkx at 0.5714.
'
' What actually changed is PEAK CALLEE-SAVED PRESSURE AT ONE CALL. Only ebx/esi/edi survive a
' call, so at most three values can be live across one. Across the Dist2D call the original
' has exactly three: a0, assistkx, assistky. We had four, because `Dist2D(...)` was written
' INLINE as AddStat's 3rd argument. bcc's `genJsr` (cgframe_x86.cpp, the non-macos path)
' pushes arguments right-to-left and generates a nested call at its own turn in that order,
' and the front end must materialise a virtual call's receiver into a temporary BEFORE the
' jsr statement (it is needed twice: once as the pushed `self`, once as the vtable base). So
' writing Dist2D inline put `a0.assistedby`, the AddStat receiver, live ACROSS the Dist2D
' call in a callee-saved register, and `a0` lost the resulting four-into-three contest.
' Hoisting Dist2D into `Local assistdist:Float` makes it its own statement, so the receiver
' temporary is materialised after that call has returned and needs no callee-saved register
' at all. The original's `mov eax,[edi+0x7c]` at 0x05E5, sitting between `add esp,0x10` and
' the AddStat arg pushes, IS that front-end receiver temporary, and its position is the tell:
' our build emitted the same instruction 30 bytes earlier, before the Dist2D argument pushes.
'
' The general lesson, worth more than this body: an inline nested call inside an argument
' list extends the ENCLOSING call's receiver live range across it. That is a
' statement-placement lever on DEGREE at the pressure point, not on block_count.
'
' DEFECT 2 was net zero bytes over 4 gaps, and only visible once defect 1 was gone. Four
' conditions in the tail had been written as `Local flag:Int = False` + `If a Then flag = (b)`
' + `If flag Then ...`. That emits a `mov eax,0` initialiser and branches directly on the
' first comparison. The original instead materialises each term as a boolean (`setne`/`sete`
' plus `movzx eax,al`) and tests it with `cmp eax,0 / je`, the je landing on the shared
' `cmp eax,0` -- the short-circuit shape of a plain `And` chain, which BlitzMax's `And`
' already is and which the original binary demonstrably short-circuits. Rewritten as three
' `And` gates, one of them a three-term chain. Operand order was taken from the original
' rather than guessed: 0x03B0 is `mov eax,[edi+0x74] / cmp eax,[edi+0x78]`, so lastkickedby
' is the left operand of the first term.
'
' STILL OPEN, and not settled by this match: 0x00C5D638 is named g_goalline here, and
' explain_global.py reports that slot genuinely contested (g_goalline / g_pitch_halfh /
' g_player_int17 / g_walldist). A Global reference is a relocation and is masked by the
' oracle, so a MATCH is not evidence for the name. See CONTRIBUTING, "A byte match does not
' prove your Globals are right".
'!Global g_training_int03:Int
'!Global g_engine_int27:Int
'!Global g_player_int50:Int
'!Global g_matchstate:Int
'!Global g_snd_crowd:TSound
'!Global g_chan_crowd:TChannel
'!Global g_engine_int25:Int
'!Global g_fixture:TFixture
'!Global g_engine_arr01:Int[]
'!Global g_goalline:Int
'!Global g_engine_int17:Int = 1750
'!Global g_engine_font:TBitmapFont
'!Global g_engine_int18:Int
'!Global g_hometeam:TTeam
'!Global g_awayteam:TTeam
'!Global g_engine_int26:Int
'!Global g_player_int04:Int
'!Global g_player_tplayer01:TPlayer
'!Global g_engine_int31:Int
'!Global g_engine_int32:Int
' CASE DIRECTION CORRECTED 2026-08-22: 3 call sites -> .ToUpper().
' extracted/runtime_helpers.tsv named 0x004A7410 `_brl_retro_Lower` and 0x004A74E0
' `_brl_retro_Upper`. Both were wrong and neither address is a brl.retro wrapper:
' 0x004A7410 is `_bbStringToUpper` and 0x004A74E0 is `_bbStringToLower`. NSS5.exe's
' own 21-byte retro wrappers at 0x0059C8FD (Lower) and 0x0059C912 (Upper) CALL those
' two addresses, and a wrapper cannot be the function it calls. The wrong row masked
' by name, so this body certified with the case conversion running backwards. Full
' derivation and the discriminating 3x4 matrix: docs/reference/codegen-patterns.md
' 15.6. Re-verified under NSS5_NO_LEARN=1 on worker trees 380 and 380b.
LogLine("GoalScored")
If g_training_int03 <> 0 Then
	TTraining.GoalScored(a0)
	Return 0
EndIf
g_engine_int27 = g_player_int50
If g_matchstate = 10 Then
	PlaySound(g_snd_crowd, g_chan_crowd)
	Local side:Int = 0
	Select g_engine_int25 Mod 2
		Case 0
			side = 2
		Case 1
			side = 1
	End Select
	Select side
		Case 1
			g_fixture.penscore1 :+ 1
		Case 2
			g_fixture.penscore2 :+ 1
	End Select
	g_engine_arr01[g_engine_int25] = 1
	TEngine.DoShootOut()
Else
	If a0.controlledby <> Null Then
		a0.Kick(a0.controlledby, AngleTo(a0.x, a0.y, 0, Float((g_goalline + 100) * a0.controlledby.GetShootingDirection())), 50.0, 1, 0)
	EndIf
	PlaySound(g_snd_crowd, g_chan_crowd)
	TScreenMessage.Create(0, 0, GetText("Goal!").ToUpper(), g_engine_int17, g_engine_font, Null, 1.0, "FFFFFF")
	g_matchstate = 8
	If a0.y < 0.0 Then
		Select g_engine_int18
			Case 1
				g_fixture.score1 :+ 1
				g_engine_int26 = 1
				g_player_int04 = g_hometeam.id
			Case 2
				g_fixture.score2 :+ 1
				g_engine_int26 = 2
				g_player_int04 = g_awayteam.id
			Case 3
				g_fixture.score1 :+ 1
				g_engine_int26 = 1
				g_player_int04 = g_hometeam.id
			Case 4
				g_fixture.score2 :+ 1
				g_engine_int26 = 2
				g_player_int04 = g_awayteam.id
		End Select
	Else
		Select g_engine_int18
			Case 1
				g_fixture.score2 :+ 1
				g_engine_int26 = 2
				g_player_int04 = g_awayteam.id
			Case 2
				g_fixture.score1 :+ 1
				g_engine_int26 = 1
				g_player_int04 = g_hometeam.id
			Case 3
				g_fixture.score2 :+ 1
				g_engine_int26 = 2
				g_player_int04 = g_awayteam.id
			Case 4
				g_fixture.score1 :+ 1
				g_engine_int26 = 1
				g_player_int04 = g_hometeam.id
		End Select
	EndIf
EndIf
If a0.lasttouchedby <> Null Then
	g_player_tplayer01 = a0.lasttouchedby
	g_player_tplayer01.joy.kickenabled = 0
	If a0.lastkickedby <> a0.lasttouchedby And a0.lasttouchedby.selectionno = 0 Then
		g_player_tplayer01 = a0.lastkickedby
	EndIf
	If g_matchstate <> 10 And g_player_tplayer01.teamid = g_player_int04 Then
		a0.lastkickedby.AddStat(5, g_player_tplayer01.directiontogoal_opp, g_player_tplayer01.distancetogoal_opp, g_player_tplayer01.kickx, g_player_tplayer01.kicky)
		If a0.lastkickedby.newstar <> 0 Then
			TParticle.StarShower(Int(a0.lastkickedby.x), Int(a0.lastkickedby.y), GetText("Goal!").ToUpper(), "00FF00")
		EndIf
		If a0.assistedby <> Null And a0.assistedby <> g_player_tplayer01 And a0.assistedby.teamid = g_player_tplayer01.teamid Then
			Local assistkx:Int = a0.assistedby.kickx
			Local assistky:Int = a0.assistedby.kicky
			Local assistang:Float = AngleTo(assistkx, assistky, g_player_tplayer01.receivex, g_player_tplayer01.receivey)
			Local assistdist:Float = Dist2D(assistkx, assistky, g_player_tplayer01.receivex, g_player_tplayer01.receivey)
			a0.assistedby.AddStat(4, assistang, assistdist, assistkx, assistky)
			If a0.assistedby.newstar <> 0 Then
				TParticle.StarShower(Int(g_player_tplayer01.x), Int(g_player_tplayer01.y), GetText("Assist").ToUpper(), "990099")
			EndIf
		EndIf
		If a0.lastkickedby.teamid = g_hometeam.id Then
			g_engine_int31 :+ 1
		ElseIf a0.lastkickedby.teamid = g_awayteam.id Then
			g_engine_int32 :+ 1
		EndIf
	EndIf
EndIf
