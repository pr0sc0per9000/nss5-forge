' TPlayer.UpdateJoyAI
' VA 0x004F1D08   986 bytes   vtable slot 0x90   sig ()i
' byte-identical vs NSS5.exe (986/986, original length from Ghidra's inventory, mode=reloc)
'
' Drives the AI-controlled joystick for a non-human player: aims Self.joy at either a fixed
' set-piece direction or the player's desired position, sets its force, converts direction+
' force into an (axis_x,axis_y) vector, then picks one AI sub-behaviour to run for this tick
' (celebrate, kick, keeper-dive, head, tackle) gated behind "not diving/sliding and part of
' the active selection".
'
' Fields used (TPlayer): joy:TJoy (+0x158), x/y (+0x4c/+0x50), desx/desy (+0x7c/+0x80,
' both Float), selectionno (+0xbc), jumpspotgood (+0xdc), directiontogoal_opp (+0xe0),
' teamid (+0x14). TJoy: axis_x/axis_y (+8/+0xc), force (+0x10), direction (+0x14).
' TBall: active (+0xc), controlledby:TPlayer (+0x70). TPlayer.teamid read off
' g_match_ball.controlledby to compare against Self.teamid.
'
' Globals (construction-site/usage typed):
'   g_player_int01:Int (0x00C5B1FC) -- the AI "play situation" enum tested against
'     2/3/4/5/6/7/8/9/11 across this function and TTraining.Fail (which stores the literal
'     11); NOT TPlayer as globals_final.tsv guesses (single-witness, see
'     globals_corrections.tsv).
'   g_player_int17:Int (0x00C5D638) -- multiplied by GetShootingDirection() to derive desy;
'     name established by TPlayer.UpdateMovement.bmx.
'   g_match_ball:TBall (0x00C5DEA4) -- "the ball", name established across the TPlayer/TBall
'     corpus (globals_corrections.tsv).
'   g_engine_tball:TBall (0x00C5B22C) -- ALSO the ball, a second Global pointing at the same
'     kind of object; +0xC is read and compared to 1, which is TBall.active (TPlayer+0xC is
'     imgPlayer:TImage, ruled out the same way TPlayer.UpdateMovement.bmx documents for this
'     exact address). Kept as a separate Global from g_match_ball because nothing here proves
'     they are the same instance.
'
' Module Functions called: AngleTo(f,f,f,f) [src/recovered_module/AngleTo.bmx],
' Dist2D(f,f,f,f) [src/recovered_module/Dist2D.bmx, table in codegen-patterns.md section 7].
' Static Type calls: TEngine.SetPiece() (classtable+slot, 0x00C5BAA4 = TEngine+0x74),
' TPitch.YardsToPixels(1.0) (classtable+slot, 0x00C5D998 = TPitch+0x6C).
'
' CODEGEN NOTES (measured against the byte count):
'   * The Select on g_player_int01 duplicates its Case bodies verbatim rather than grouping
'     values on one Case line (`Case 2` and `Case 3` are byte-identical blocks with their OWN
'     targets, likewise `Case 4/5/6/7/9`) -- comma-grouping would share one jump target and
'     come out shorter. Reproduced as five/two separate Case blocks, not tidied (law 3).
'   * `TEngine.SetPiece()` TRUE takes the Select branch; FALSE takes the PlayerDiving/
'     PlayerSliding + Dist2D branch -- easy to get backwards from the `je` alone.
'   * `Self.PlayerDiving() Or Self.PlayerSliding()` is short-circuit: PlayerSliding() is only
'     called when PlayerDiving() returned 0.
'   * The 4-term guard `g_match_ball<>Null And PlayerDiving()=0 And PlayerSliding()=0 And
'     selectionno<11` and the inner `g_player_int01=8 Or (g_player_int01=11 And
'     g_engine_tball.active<>1)` are both short-circuit chains built by reusing eax as an
'     accumulator -- confirmed by walking every cmp/je, not inferred from Ghidra's C.
'   * axis_x/axis_y MUST be written `Cos(direction) * force` / `Sin(direction) * force`, NOT
'     `force * Cos(direction)`. bcc evaluates left-to-right and only spills a value across a
'     call when it is the LEFT operand; the original loads direction, calls Cos/Sin, THEN
'     loads force and multiplies -- force loaded AFTER the call means force was the RIGHT
'     operand (same tell as TPlayer.UpdateMovement.bmx's "AngleDiff(...) * 0.25" note). Got
'     this backwards on the first attempt: 1010 bytes instead of 986, extra fld/fstp pair
'     spilling force to a stack temp across the trig call.
'   * Every early exit is an explicit `Return 0` (the `()i` rule: `()i` legacy default plus a
'     bare mid-function `Return` are both illegal/impossible under SuperStrict, and the
'     original spells "mov eax,0" at every one of the seven exit points, including the final
'     fallthrough).

	Method UpdateJoyAI:Int()
		'!Global g_player_int01:Int
		'!Global g_player_int17:Int
		'!Global g_match_ball:TBall
		'!Global g_engine_tball:TBall

		Self.joy.Clear()
		If TEngine.SetPiece()
			Select g_player_int01
				Case 2
					Self.joy.direction = AngleTo(Self.x, Self.y, 0, Self.y)
				Case 3
					Self.joy.direction = AngleTo(Self.x, Self.y, 0, Self.y)
				Case 4
					Self.joy.direction = Float(Self.directiontogoal_opp)
				Case 5
					Self.joy.direction = Float(Self.directiontogoal_opp)
				Case 6
					Self.joy.direction = Float(Self.directiontogoal_opp)
				Case 7
					Self.joy.direction = Float(Self.directiontogoal_opp)
				Case 9
					Self.joy.direction = Float(Self.directiontogoal_opp)
			End Select
			Self.joy.force = 1.0
		Else
			If Self.PlayerDiving() Or Self.PlayerSliding()
				Self.desx = 0.0
				Self.desy = Float(g_player_int17 * Self.GetShootingDirection())
			EndIf
			Self.joy.direction = AngleTo(Self.x, Self.y, Self.desx, Self.desy)
			Self.joy.force = 0.0
			If Dist2D(Self.x, Self.y, Self.desx, Self.desy) > TPitch.YardsToPixels(1.0)
				Self.joy.force = 1.0
			EndIf
		EndIf
		Self.joy.axis_x = Cos(Self.joy.direction) * Self.joy.force
		Self.joy.axis_y = Sin(Self.joy.direction) * Self.joy.force
		If g_match_ball <> Null And Self.PlayerDiving() = 0 And Self.PlayerSliding() = 0 And Self.selectionno < 11
			If g_player_int01 = 8 Or (g_player_int01 = 11 And g_engine_tball.active <> 1)
				Self.DoCelebrations()
				Return 0
			EndIf
			If Self.selectionno = 0
				If g_match_ball.controlledby = Self
					Self.DoKickingAI()
					Return 0
				EndIf
				If Self.BackPass() = 0
					Self.DoKeeperDiveAI()
					Return 0
				EndIf
			EndIf
			If g_match_ball.controlledby = Null And Self.jumpspotgood
				Self.DoHeadingAI()
				Return 0
			EndIf
			If g_match_ball.controlledby = Self
				Self.DoKickingAI()
				Return 0
			EndIf
			If g_match_ball.controlledby <> Null And g_match_ball.controlledby.teamid <> Self.teamid
				Self.DoTacklingAI()
				Return 0
			EndIf
		EndIf
		Return 0
	End Method
