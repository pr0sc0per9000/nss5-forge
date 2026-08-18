' TPlayer.DoKickingAI
' VA 0x004F22D6   1483 bytes   vtable slot 0x98   sig ()i   KIND=Method
'
' SOURCE: extracted/decomp/TPlayer.DoKickingAI@004f22d6.c, cross-checked against the
' symbol layer at extracted/decomp_annotated/TPlayer.DoKickingAI@004f22d6.c
' (CONFIDENCE=HIGH, every SYM line below independently reproduced by re-deriving from
' extracted/globals_final.tsv / object_model.json / sibling bodies).
'
' Module Globals used (name/type are load-bearing; verified against globals_final.tsv):
'   0x00C6CF90 g_training_int03:Int   usage/medium -- 0 = normal match AI, non-zero = a
'                                      training-drill id (TPanel_Controls.RenderTraining
'                                      etc. read the same values 1..10).
'   0x00C5B1FC g_player_int01:Int     verified/high (globals_final.tsv, hand-verified;
'                                      see globals_corrections.tsv). NOT g_matchstate --
'                                      that name resolves the SAME address but lost the
'                                      naming vote; TEngine.SetPiece's own byte-identical
'                                      `Select g_player_int01 / Case 2..7,9` uses the exact
'                                      same case set as this body's dispatch, which is why
'                                      TEngine.SetPiece() gates entry to that dispatch here.
'   0x00C5DEA4 g_player_tplayer02:TBall  verified/high (globals_final.tsv). The ball; NOT
'                                      g_ball -- that name resolves the same address but
'                                      lost the naming vote here. +0x80 = setpiecetaker:TPlayer
'                                      (object_model.json TBall field list).
'   0x00C6EFD4 g_player_int50:Int     verified/high (globals_final.tsv). NOT g_matchclock/
'                                      g_matchtime -- those names resolve the same address
'                                      but lost the naming vote; TPlayer.UpdateCalling (a
'                                      sibling) already uses g_player_int50 for this slot.
'   0x00C5D634 g_player_int16:Int     usage/medium (globals_final.tsv). NAME COLLISION: the
'                                      value held here is the pitch half-width in pixels
'                                      (confirmed by TPitch.Render/TPlayer.UpdatePassPotential
'                                      prose and by dozens of `Abs(Self.x) > g_player_int16 ..`
'                                      touchline-proximity checks across the corpus, exactly
'                                      the shape used below), NOT a per-player Int attribute.
'   0x00C5B210 g_engine_int20:Int     usage/medium (globals_final.tsv) -- the match-minute
'                                      counter; only `Mod 4` of it is read here, same idiom
'                                      as TTeam.GetSetPieceTakers' `g_engine_int20 Mod 4 = 1`.
'
' Class-table statics resolved (NOT Globals):
'   0x00C5BAA4 = TEngine class table +0x74 = SetPiece()i
'   0x00C5D998 = TPitch class table +0x6c = YardsToPixels(f)f
'   0x00C5D98C = TPitch class table +0x60 = InsideCrossZone(i,i,i)i (TBall.Kick /
'                TPlayer.TapKick both already use this exact `(Int(x), Int(y), dir)` shape)
' Module Functions resolved: Rand (0x0059F089 = _brl_random_Rand), Abs() on a Float compiles
'   to _bbFloatAbs (0x004A7FE0, matching TPlayer.DoCelebrations' note), Int() compiles to
'   _bbFloatToInt (0x005B9690), LogLine (0x00505B91). The Ghidra call list merges each of
'   these library calls' arguments with the pushes of the following call (spec 3f/3d) --
'   already unmerged below using the same idioms the cited siblings use.
' String literal: 0x00C79764 = "ComCross" (read directly out of NSS5.exe by annotate).
'
' Fields (object_model.json TPlayer): kickpower+0xc0(f), distancetogoal_opp+0xe8(i),
'   distancetogoal_own+0xec(i), distancetoopponent+0x108(f), x+0x4c(f), y+0x50(f),
'   keepercatchtime+0x90(i), selectionno+0xbc(i), joy+0x158(:TJoy). TJoy (object_model.json):
'   kickbuttondown+0x1c(i), kickbuttonhits+0x20(i). TBall: setpiecetaker+0x80(:TPlayer).
' Self slots (object_model.json TPlayer vtable): 0x9c=ShootAI()i, 0xa0=PassAI()i,
'   0x1c0=KeeperHoldingBall()i, 0x160=GetShootingDirection()i, 0x170=GetDistanceToByLine(i)f,
'   0xe4=CleanThrough()i, 0x188=GetOppKeeper():TPlayer.
'
' CODEGEN NOTES
'   * TOP-LEVEL SHAPE (byte-oracle fix, refine2 pass): the score report's first-difference
'     bytes showed the original testing `g_training_int03` with a SHORT `jz +0x73` into a
'     block only ~115 bytes away, while a flat `If g_training_int03 = 0 Then <big AI tree>
'     ElseIf selectionno<1 ... ElseIf training=9 ... Else PassAI EndIf` (the literal
'     decompiled shape, matching the PRE-fix body) compiles the huge first Then-branch
'     inline and needs a near `0F 85` jump instead -- wrong opcode, wrong operand, wrong
'     everything after it. Ghidra flattens `If A Then S Else Big` into the elseif chain it
'     prints; re-inverting to `If g_training_int03 <> 0 Then <small dispatch> Else <big AI
'     tree> EndIf` puts the small dispatch inline (short jumps) and defers the big tree to
'     the end, matching the oracle's `jz`. The same trick applies one level down: the
'     decompiled `else if (selectionno < 1) { keeper-button-force }` is written here as
'     `If Self.selectionno > 0 Then <training9/shoot-or-pass> Else <keeper-button-force>
'     EndIf` so the comparison keeps the oracle's `cmp X,0` (a literal `< 1` or `>= 1` would
'     compile against immediate 1, not 0) and the small keeper-button block is the deferred
'     (Else) side, mirroring the outer inversion. Purely a branch-layout/polarity change --
'     every condition, block, and side effect is the same as the flat elseif reading.
'   * `If Self.KeeperHoldingBall() And g_player_int50 < Self.keepercatchtime + 2500` has an
'     EMPTY Then-branch and a real Else holding the whole open-play decision tree -- this is
'     the same byte-measured idiom TPlayer.UpdateMovement already documents for a bare
'     `If Self.KeeperHoldingBall() ... Else ...` (`74 02 EB xx`, 2 bytes shorter than an
'     explicit `= 0`/`Not` spelling), extended here with the trailing `And` term.
'   * Every `And`-pair below reproduces the decompiled "compute cond1; only if cond1 true is
'     cond2 even evaluated" shape verbatim -- e.g. `TPitch.InsideCrossZone(...) And (...)`
'     only evaluates the parenthesised Or-chain when InsideCrossZone is true.
'   * Comparison operand order follows which sub-expression the original computes FIRST
'     (that sub-expression is written first in source, per the corpus-wide fxch-avoidance
'     pattern documented on TPlayer.DoTacklingAI/TPlayer.DoCelebrations): e.g. `Abs(Self.x)`
'     is computed before `g_player_int16 - TPitch.YardsToPixels(4.0)`, so it is written
'     `Abs(Self.x) > g_player_int16 - TPitch.YardsToPixels(4.0)`, not the reverse.
'   * `Select Rand(2,1) / Case 1 / Case 2` (no Default) reproduces the `iVar2 = Rand(2,1);
'     if(iVar2==1) ShootAI(); else if(iVar2==2) PassAI();` shape with a single Rand() call
'     whose result is used twice -- the exact idiom already established at
'     TEngine.SkipMatchTime line 161 (`Select Rand(2,1) / Case 1 / Case 2`).
'   * `TPitch.InsideCrossZone(Int(Self.x), Int(Self.y), Self.GetShootingDirection())` inlines
'     the direction call as the third argument (not a stored Local) because it is used only
'     once here -- matching TBall.Kick's inline `a0.GetShootingDirection()` rather than
'     TPlayer.TapKick's stored-Local spelling (which reuses `dir` several times).
'   * REFINEMENT (byte-diff-guided): disassembling the original directly at the training-mode
'     keeper-button-force guard (`If Self.KeeperHoldingBall() And ...keepercatchtime...`, the
'     ONLY one of this body's several KeeperHoldingBall()-And-chains with no Else at all) shows
'     the second term compiled as `cmp dword ptr [g_player_int50], eax; jge body; jmp skip` --
'     the global used DIRECTLY as the cmp's first (memory) operand, no register load, no
'     setcc/movzx. That is only reachable by writing the global FIRST: `g_player_int50 >=
'     Self.keepercatchtime + 500`, not the algebraically-equal `Self.keepercatchtime + 500 <=
'     g_player_int50` (which put the computed side first and made the byte-oracle build
'     materialise a boolean instead, 7 bytes longer). The sibling guard just below
'     (`g_player_int50 < Self.keepercatchtime + 2500`, the empty-Then/real-Else idiom) already
'     had the global written first and is unaffected by this pass.

'!Global g_training_int03:Int
'!Global g_player_int01:Int
'!Global g_player_tplayer02:TBall
'!Global g_player_int50:Int
'!Global g_player_int16:Int
'!Global g_engine_int20:Int

Self.kickpower = 0
If g_training_int03 <> 0
	If Self.selectionno > 0
		If g_training_int03 = 9
			Self.ShootAI()
		Else
			Self.PassAI()
		EndIf
	Else
		If Self.KeeperHoldingBall() And g_player_int50 >= Self.keepercatchtime + 500
			Self.joy.kickbuttonhits = 1
			Self.joy.kickbuttondown = 0
		EndIf
	EndIf
Else
	If TEngine.SetPiece() And g_player_tplayer02.setpiecetaker = Self
		Select g_player_int01
			Case 2
				Self.PassAI()
			Case 3
				If Rand(10,1) = 1
					Self.ShootAI()
				Else
					Self.PassAI()
				EndIf
			Case 4
				If Self.distancetogoal_opp > TPitch.YardsToPixels(35.0) And Self.distancetogoal_opp < TPitch.YardsToPixels(60.0)
					If Rand(10,1) = 1
						Self.ShootAI()
					Else
						Self.PassAI()
					EndIf
				Else
					Select Rand(2,1)
						Case 1
							Self.ShootAI()
						Case 2
							Self.PassAI()
					End Select
				EndIf
			Case 5
				Select Rand(2,1)
					Case 1
						Self.ShootAI()
					Case 2
						Self.PassAI()
				End Select
			Case 6
				Self.ShootAI()
			Case 7
				Self.ShootAI()
			Case 9
				Self.ShootAI()
		End Select
	Else
		If Self.KeeperHoldingBall() And g_player_int50 < Self.keepercatchtime + 2500
		Else
			If Self.distancetogoal_own >= TPitch.YardsToPixels(20.0)
				If Self.distancetogoal_own < TPitch.YardsToPixels(35.0) And Self.distancetoopponent < TPitch.YardsToPixels(10.0)
					Self.ShootAI()
				Else
					If TPitch.InsideCrossZone(Int(Self.x), Int(Self.y), Self.GetShootingDirection()) And (Abs(Self.x) > g_player_int16 - TPitch.YardsToPixels(4.0) Or Self.GetDistanceToByLine(1) < TPitch.YardsToPixels(3.0) Or Self.distancetoopponent < TPitch.YardsToPixels(10.0))
						LogLine("ComCross")
						Self.ShootAI()
					Else
						If Self.CleanThrough() And Self.distancetogoal_opp < TPitch.YardsToPixels(18.0)
							Self.ShootAI()
						Else
							If Self.distancetogoal_opp >= TPitch.YardsToPixels(35.0) Or g_engine_int20 Mod 4 <> 0
								If Self.distancetogoal_opp >= TPitch.YardsToPixels(22.5)
									If Self.distancetogoal_opp < TPitch.YardsToPixels(40.0) And Self.GetOppKeeper().distancetogoal_own > TPitch.YardsToPixels(8.0)
										Self.ShootAI()
									Else
										Self.PassAI()
									EndIf
								Else
									Self.ShootAI()
								EndIf
							Else
								Self.ShootAI()
							EndIf
						EndIf
					EndIf
				EndIf
			Else
				Self.ShootAI()
			EndIf
		EndIf
	EndIf
EndIf
