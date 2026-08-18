' TPlayer.DoKeeperDiveAI
' VA 0x004F3592   2962 bytes   class-table slot 0xb8   sig ()i
' byte-identical vs NSS5.exe (2962/2962, original length from Ghidra's inventory,
' mode=reloc, reloc_masked=117, verified with NSS5_NO_LEARN=1)
'
' ASSUMPTIONS -- module Globals (names are ours; types are load-bearing)
'   0x00C5DEA4 g_ball:TBall            globals_final says TPlayer and is WRONG (11.2);
'                                      +0x50 ingoal, +0x74 lastkickedby, +0x78 lasttouchedby,
'                                      +0x70 controlledby, +0x98 curlamount, slot 0xa4 =
'                                      TBall.Crossing(f)i all resolve on TBall.
'   0x00C6EFD4 g_matchclock:Int        (verified row; same Global TPlayer.UpdateCalling uses)
'   0x00C5B1FC g_matchstate:Int        (verified row)
'   0x00C6F028 g_profile:TProfile      +0x120 = TProfile.captain:Int
'   0x00C6EFEC g_joyenabled:Int
'   0x00C5D1B4/BC/C4/CC g_opt_ctrlup / ctrldown / ctrlleft / ctrlright : Int[]
'                                      index 0 = keyboard scancode (+0x18), index 1 =
'                                      joystick button (+0x1C). Same four arrays and the
'                                      same Int[] typing as TOptions.LoadOptions.
'   0x00C5D634 g_pitch_halfw:Int  0x00C5D638 g_pitch_halfh:Int   (names from TPitch.IsOnPitch)
'   0x00C5D63C g_goal_halfw:Int        goal mouth spans [-(g+20), g+20] on the byline
'   0x00C5DE70 g_keeper_maxheight:Int  dive-height thresholds (half / full)
'   0x00C5A4D0 g_ball_friction:Float   0x00C5A4D4 g_ball_gravity:Float
'
' Types / slots used: TPlayer 0x160 GetShootingDirection, 0x174 GetMyTeam():TTeam,
'   0x1A0 PlayerOnFeet, 0x1C0 KeeperHoldingBall, 0xBC KeeperDive(:TInterceptPoint,i),
'   0xC0 KeeperCatchLow, 0xC4 KeeperCatchHigh, 0xC8 KeeperJump;
'   TTeam +0x18 controller:Int;  TInterceptPoint +0x10 intercept_AB, +0x18 intercept;
'   TPitch class-table 0x5C InsidePenaltyBox(i,i,i)i and 0x6C YardsToPixels(f)f.
'   AngleTo / WrapAngle / Dist2D / GetInterceptPoint / LogLine are the recovered module
'   Functions in src/recovered_module (0x0050639D / 0x00506184 / 0x00505DA2 / 0x00505E20 /
'   0x00505B91).
'
' LITERALS read out of NSS5.exe, not guessed: "Dive" (0x00C79804), "Catch" (0x00C79818).
' The function's float pool 0x00C797D8..0x00C79800 reads -0.5, 0.5, -0.5, 0.5, 1.0, 0.0,
' 90.0, 90.0, 90.0, 90.0, 0.5 -- one slot per literal occurrence, in source order, which is
' what fixes `power = 1.0` / `power = 0.0` and the four `+ 90.0`.
'
' CODEGEN NOTES (each one cost a byte before it was right)
'   * Comparison operand order is byte-observable (10.1). `bz > g_keeper_maxheight * 0.5`
'     emits fild/fmul/fld/fucompp/setbe; the equivalent `g_keeper_maxheight * 0.5 < bz`
'     inserts an `fxch st(1)` and is 2 bytes longer. Same for `dist >= YardsToPixels(0.75)`
'     against `YardsToPixels(0.75) <= dist`.
'   * `Local ip:TInterceptPoint` must be declared BEFORE `Local goaly:Int`. Declared after,
'     bcc gives goaly esi and ip ebx and has to emit `mov esi,ebx` after the imul (+2 bytes)
'     and every later use of the two registers is swapped. A bare object Local emits no
'     null-initialisation at all, so the declaration itself is free either way.
'   * ip is used by the Until expression and after the loop, so it cannot be declared
'     inside the Repeat body -- bcc rejects that with "Identifier 'ip' not found".
'   * The three `Select` statements are Selects, not If/ElseIf (10.2): the compare chain is
'     emitted back to back, the no-match path falls straight into `Default` (or, where there
'     is no Default, into a `jmp` past all the case bodies), and the last case body ends in
'     `EB 00`.
'   * `If Not g_ball` is the 21-byte setne/movzx form; `If g_ball.lastkickedby <> Null` is
'     the 12-byte cmp/je form (10.3). Both occur here.
'   * The joystick/analog split tests g_opt_ctrlleft[1] = -1 -- the LEFT binding decides the
'     mode for all four directions. That asymmetry is the original's; do not tidy it (16.8).
	Method DoKeeperDiveAI:Int()
		'!Global g_ball:TBall
		'!Global g_matchclock:Int
		'!Global g_matchstate:Int
		'!Global g_profile:TProfile
		'!Global g_joyenabled:Int
		'!Global g_opt_ctrlup:Int[]
		'!Global g_opt_ctrldown:Int[]
		'!Global g_opt_ctrlleft:Int[]
		'!Global g_opt_ctrlright:Int[]
		'!Global g_pitch_halfw:Int
		'!Global g_pitch_halfh:Int
		'!Global g_goal_halfw:Int
		'!Global g_keeper_maxheight:Int
		'!Global g_ball_friction:Float
		'!Global g_ball_gravity:Float
		If Not g_ball Then Return 0
		If g_ball.ingoal Then Return 0
		If Not Self.PlayerOnFeet() Then Return 0
		If g_ball.lastkickedby = Self And g_matchclock < g_ball.kicktime + 300 Then Return 0
		Local dir:Int = Self.GetShootingDirection()
		If Not TPitch.InsidePenaltyBox(Int(Self.x), Int(Self.y), -dir) Then Return 0
		If Self.KeeperHoldingBall() Then Return 0
		If g_matchstate <> 1 And g_matchstate <> 10 Then Return 0
		If g_matchstate = 10
			If Self.distancetoball < TPitch.YardsToPixels(8.0) And g_ball.ingoal = 0 And g_ball.lasttouchedby <> Self
				Local power:Float = Rnd(0, 1)
				Local divetype:Int = Rand(6, 1)
				If Self.GetMyTeam().controller = 1 And g_profile.captain
					Local up:Int = 0
					Local down:Int = 0
					Local lft:Int = 0
					Local rgt:Int = 0
					If g_joyenabled
						If g_opt_ctrlleft[1] = -1
							If JoyY(0) < -0.5 Then up = 1
							If JoyY(0) > 0.5 Then down = 1
							If JoyX(0) < -0.5 Then lft = 1
							If JoyX(0) > 0.5 Then rgt = 1
						Else
							If JoyDown(g_opt_ctrlup[1], 0) Then up = 1
							If JoyDown(g_opt_ctrldown[1], 0) Then down = 1
							If JoyDown(g_opt_ctrlleft[1], 0) Then lft = 1
							If JoyDown(g_opt_ctrlright[1], 0) Then rgt = 1
						End If
					End If
					If KeyDown(g_opt_ctrlup[0]) Then up = 1
					If KeyDown(g_opt_ctrldown[0]) Then down = 1
					If KeyDown(g_opt_ctrlleft[0]) Then lft = 1
					If KeyDown(g_opt_ctrlright[0]) Then rgt = 1
					If down Then divetype = 1
					If up Then divetype = 2
					If rgt
						power = 1.0
						divetype = 3
					End If
					If lft
						power = 0.0
						divetype = 3
					End If
				End If
				Select divetype
					Case 1
						Self.KeeperCatchHigh()
					Case 2
						Self.KeeperJump()
					Default
						Local ip:TInterceptPoint = New TInterceptPoint
						ip.intercept_AB = power
						Self.KeeperDive(ip, Rand(0, 2))
				End Select
			End If
			Return 0
		End If
		Local ang:Float = AngleTo(Self.x, g_pitch_halfh * -dir, g_ball.x, g_ball.y)
		If g_ball.lastkickedby <> Null
			ang = AngleTo(Self.x, g_pitch_halfh * -dir, g_ball.lastkickedby.kickx, g_ball.lastkickedby.kicky)
		End If
		WrapAngle(ang)
		Local yoff:Int = 0
		Select dir
			Case 1
				yoff = 10
			Case -1
				yoff = -10
		End Select
		Local gwidth:Float = TPitch.YardsToPixels(7.5)
		Local p1x:Float = Self.x + Cos(ang + 90.0) * gwidth
		Local p1y:Float = Self.y + yoff + Sin(ang + 90.0) * gwidth
		Local p2x:Float = Self.x - Cos(ang + 90.0) * gwidth
		Local p2y:Float = Self.y + yoff - Sin(ang + 90.0) * gwidth
		Local bx:Float = g_ball.x
		Local by:Float = g_ball.y
		Local bz:Float = g_ball.z
		Local bvel:Float = g_ball.velocity
		Local bzvel:Float = g_ball.zvelocity
		Local bdir:Float = g_ball.direction
		Local ip:TInterceptPoint
		Local goaly:Int = g_pitch_halfh * -Self.GetShootingDirection()
		Repeat
			bvel = bvel * g_ball_friction
			bx = bx + Cos(bdir) * bvel
			by = by + Sin(bdir) * bvel
			bzvel = bzvel - g_ball_gravity
			bz = bz + bzvel
			If Not g_ball.controlledby Then bdir = bdir + g_ball.curlamount
			ip = GetInterceptPoint(p1x, p1y, p2x, p2y, g_ball.x, g_ball.y, bx, by)
			If GetInterceptPoint(-g_pitch_halfw, goaly, -g_goal_halfw - 20, goaly, g_ball.x, g_ball.y, bx, by).intercept Then Return 0
			If GetInterceptPoint(g_goal_halfw + 20, goaly, g_pitch_halfw, goaly, g_ball.x, g_ball.y, bx, by).intercept Then Return 0
		Until bz <= 0 Or bvel <= 0 Or ip.intercept
		If ip.intercept
			Local dist:Float = Dist2D(Self.x, Self.y + yoff, bx, by)
			Local dtype:Int = 0
			If ip.intercept
				If bz > g_keeper_maxheight * 0.5 Then dtype = 1
				If bz > g_keeper_maxheight Then dtype = 2
			End If
			If TPitch.InsidePenaltyBox(Int(bx), Int(by), -dir) And Self.distancetoball < TPitch.YardsToPixels(3.0)
				If dist >= TPitch.YardsToPixels(0.75) And g_ball.Crossing(0) = 0 And (g_ball.velocity > 1.0 Or g_ball.controlledby <> Null)
					LogLine("Dive")
					Self.KeeperDive(ip, dtype)
					Return 0
				Else
					If dist < TPitch.YardsToPixels(2.5)
						LogLine("Catch")
						Select dtype
							Case 0
								If Self.distancetoball < TPitch.YardsToPixels(1.0) Then Self.KeeperCatchLow()
							Case 1
								If Self.distancetoball < TPitch.YardsToPixels(5.0) Then Self.KeeperCatchHigh()
							Case 2
								If Self.distancetoball < TPitch.YardsToPixels(6.0) Then Self.KeeperJump()
						End Select
						Return 0
					End If
				End If
			End If
		End If
		Return 0
	End Method
