' TPlayer.DoCelebrations
' VA 0x004fd2da   760 bytes   vtable slot 0x1e8   sig ()i   KIND=Method
' byte-identical vs NSS5.exe (760/760, original length from Ghidra's inventory)
' ORACLE: mode=reloc  matched=760/760  STATUS=MATCH.  NSS5_NO_LEARN=1
' Disassembled directly (harness.disasm_original) rather than trusted from Ghidra's C,
' because several calls in the decompilation dropped their float argument
' (`(*(code *)PTR_FUN_00c5d998)()`); the raw bytes show every call site correctly.
'
' CODEGEN NOTE (why the source is shaped the way it is, all confirmed by binary diff):
'  * `Abs(Self.desy) >= 50.0` has no Else, so it is written as the negated early-return
'    `If Abs(Self.desy) < 50.0 Then Return 0` per codegen-patterns 21's solo-relational rule.
'  * `Self.y >= 0 Then Celebrate(3) Else Celebrate(2)` is a solo relational If/Else with two
'    distinct bodies, so per the SAME rule it is written negated-and-swapped:
'    `If Self.y < 0 Then Celebrate(2) Else Celebrate(3)`.
'  * `losby > 1 Or (losby > 0 And g_engine_int20 > 70)` guards the celebration-Select with an
'    EMPTY `Then` and the real body in `Else` -- the original's "je short / jmp short" pair
'    only comes out of bcc when written this way; `If Not(...) Then <body>` compiles to a
'    single negated jump and is 2 bytes short.
'  * The final `g_player_int50 > g_engine_int27+3000 And g_player_tplayer01.PlayerCelebrating()`
'    guard is two NESTED solo `If`s, not a compound `And` -- written as one `And` expression
'    bcc normalises the first term to an explicit 0/1 (extra `setg`/`movzx`, +14 bytes); as
'    nested Ifs each term branches directly off the flags, matching the original exactly.
'  * Every OTHER multi-term `And` in this body (the `winner<>Null And PlayerOnFeet() And
'    Dist2D(...)<...` guards) is a genuine flat short-circuit chain and needed the RAW call
'    result (no `<>0`) to avoid the same extra normalisation.
'
' WHAT IT DOES. Two independent branches keyed on match state: full-time whistle (state 11)
' triggers a winner/loser celebration when the player's desired-Y is far enough from centre;
' a goal (state 8) triggers celebration/commiseration logic for whichever team just conceded
' or scored, including a special extra flourish for the human player and a "teammate is
' celebrating nearby" pickup for AI players.
'
' ASSUMPTIONS -- module Global NAMES are ours (globals_final.tsv's generic names, reused for
' cross-file consistency), DECLARED TYPES are load-bearing:
'   0x00C5B1FC g_player_int01:Int      match state (11=full time, 8=goal). Same address as
'                                       g_matchstate in TBall.CheckSideLines.
'   0x00C5D634 g_player_int16:Int      1 write elsewhere in the corpus (globals_final.tsv) --
'                                       a genuine Global, not a literal (per 21.2's test).
'   0x00C5B250 g_player_int04:Int      team id of the team that just scored/conceded.
'   0x00C5B254 g_engine_int27:Int      a tick/frame timestamp of the triggering event.
'   0x00C6EFD4 g_player_int50:Int      current tick counter (same address used as
'                                       g_player_int50 in TPlayer.UpdateTeamMateId_Human).
'   0x00C5B210 g_engine_int20:Int      13 writes elsewhere (globals_final.tsv).
'   0x00C5B248 g_player_tplayer01:TPlayer   the human-controlled player (globals_final.tsv:
'                                       vtable-call slots 0x44/0x6c/0x8c/0x1ec prove TPlayer).
' `50.0` at 0x00C7A644 is read via `fld dword ptr [addr]` but is never STORED to anywhere in
' the corpus (absent from globals_final.tsv) -- per 21.2's test that makes it a LITERAL, not
' a Global; its value (50.0) was read directly out of the exe's data section.
' `5.0`/`3.5`/`3.0` are immediate stack-push arguments to TPitch.YardsToPixels, unambiguous.
'
' Static/class-table calls (already recovered): TEngine.GetWinningClub():TTeam (class-table
' TEngine+0xf8), TPitch.YardsToPixels(f)f (class-table TPitch+0x6c), Dist2D (module Function,
' 0x00505da2), Abs() on a Float compiles to a call to _bbFloatAbs (0x004a7fe0) rather than an
' inline fabs, matching every other Abs(Float) call site in the corpus.
' Self-methods (from object_model.json, TPlayer): PlayerOnFeet ()i +0x1a0, DoAnimCelebrate
' (i)i +0x1f0, DoAnimCommiserate (i)i +0x1f4, GetMyTeam ():TTeam +0x174, PlayerCelebrating ()i
' +0x1ec. TTeam.GetLosingBy ()i +0x98 (called on the GetMyTeam() result). Fields: x +0x4c,
' y +0x50, desx +0x7c, desy +0x80, teamid +0x14, facing +0x128 (all object_model.json TPlayer
' offsets). TTeam.id +8 (matches the g_playerteam.id usage already established in
' TBall.CheckSideLines).
'
' CODEGEN NOTE. The first branch's guard is a single flat 3-term
' `winner<>Null And Self.PlayerOnFeet()<>0 And Dist2D(...)<YardsToPixels(5.0)` -- confirmed
' by the disassembly reusing the stale `eax=0` from an earlier failed comparison as the input
' to the NEXT comparison rather than jumping past the whole block (the same short-circuit-AND
' tell documented in TPlayer.UpdateTeamMateId_Human). The `losby>1 Or (losby>0 And
' g_engine_int20>70)` guard is the same pattern one level down.
' The Mod-3 Select has no default case in source; remainders outside {0,1,2} (possible when
' g_engine_int20 is negative, since idiv truncates toward zero) simply fall out of the Select
' with no action, which is also what the ASM does (a bare jmp to the end on the "else" arm of
' the last `cmp/je`).
	Method DoCelebrations:Int()
		'!Global g_player_int01:Int
		'!Global g_player_int16:Int
		'!Global g_player_int04:Int
		'!Global g_engine_int27:Int
		'!Global g_player_int50:Int
		'!Global g_engine_int20:Int
		'!Global g_player_tplayer01:TPlayer
		Select g_player_int01
			Case 11
				If Abs(Self.desy) < 50.0 Then Return 0
				Local winner:TTeam = TEngine.GetWinningClub()
				If winner <> Null And Self.PlayerOnFeet() And Dist2D(Self.x, Self.y, Self.desx, Self.desy) < TPitch.YardsToPixels(5.0)
					If winner.id = Self.teamid
						Self.DoAnimCelebrate(5)
					ElseIf Self.desx > -g_player_int16
						Self.DoAnimCommiserate(Self.facing)
					EndIf
				EndIf
			Case 8
				If Self.PlayerOnFeet() <> 0
					If g_player_int04 = Self.teamid
						If Dist2D(Self.x, Self.y, Self.desx, Self.desy) < TPitch.YardsToPixels(3.5) And g_player_int50 > g_engine_int27 + 1500
							If g_player_tplayer01 = Self
								Local losby:Int = Self.GetMyTeam().GetLosingBy()
								If losby > 1 Or (losby > 0 And g_engine_int20 > 70)
								Else
									Select g_engine_int20 Mod 3
										Case 0
											If Self.y < 0
												Self.DoAnimCelebrate(2)
											Else
												Self.DoAnimCelebrate(3)
											EndIf
										Case 1
											Self.DoAnimCelebrate(0)
										Case 2
											Self.DoAnimCelebrate(1)
									End Select
								EndIf
							Else
								If g_player_int50 > g_engine_int27 + 3000
									If g_player_tplayer01.PlayerCelebrating()
										If Dist2D(Self.x, Self.y, g_player_tplayer01.x, g_player_tplayer01.y) < TPitch.YardsToPixels(3.0)
											Self.DoAnimCelebrate(5)
										EndIf
									EndIf
								EndIf
							EndIf
						EndIf
					Else
						Self.DoAnimCommiserate(Self.facing)
					EndIf
				EndIf
		End Select
		Return 0
	End Method
