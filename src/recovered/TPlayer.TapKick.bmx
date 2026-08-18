' TPlayer.TapKick
' VA 0x004f7528   1889 bytes   vtable slot 0xfc   sig ()i
' byte-identical vs NSS5.exe (1889/1889, original length from Ghidra's inventory). harness
' mode=reloc, 69 masked (class-table slot calls, E8 to named helpers/methods, absolute
' data addresses -- each positively resolved on both sides per codegen-patterns.md section 1).
'
' Chooses how the player taps/kicks the ball to a teammate: an early dispatch to
' TapKickAdvanced() for AI-controlled newstars, then either an immediate self-pass
' (training mode, own player selected), a Shot/Cross decision when near the opponent's
' goal or in the crossing zone, or a pass-power/direction calculation (explicit call
' request from a teammate, AI-chosen pass, or joystick-driven), finishing with a random
' power/direction jitter for newstar-controlled players and a call into TBall.Kick.
'
' SPILL-SLOT ORDER. It is easy to land this body LENGTH-EXACT (1889/1889) with 16 real
' byte differences, all single displacement bytes inside fld/fstp [ebp-N] operands -- a
' codegen-patterns.md section 22 spill-slot-ORDER mismatch, not a logic error. 8 short-
' lived Float "reload" temporaries (each: reload a field/call result as Float, compare
' against a TPitch.YardsToPixels(...) call result, dead immediately after) all correctly
' fail to colour into a register in BOTH builds; the disagreement was only which stack
' slot each one landed in. Writing the FIRST TWO (Cross's d1/d2, "< YardsToPixels(10)"
' and "< YardsToPixels(12)") as explicitly-named `Local d1:Float` / `Local d2:Float`,
' while the other 6 sites are bare field-vs-call comparisons with no named Local at all,
' is the whole defect: bcc's allocator orders the 6 anonymous temps by their physical
' emission order correctly, but the 2 EXPLICITLY-DECLARED Locals are displaced to the END
' of that group (a clean rotation, not a shuffle) instead of staying first. So the
' Cross-block d1/d2 comparisons are written as bare inline expressions --
' `If Dist2D(...) < TPitch.YardsToPixels(10.0)` -- matching the style of the other 6
' sites, with NO explicit `Local` wrapping the reload. That alone accounts for those 16
' bytes.
' Lesson for the corpus: a short-lived Float compared once and never reused should be
' written as a bare expression, not hoisted into a named Local, when siblings in the same
' spill group are already bare -- naming it changes which allocator list it competes on.
'
' STRING LITERALS (confirmed with harness.read_string() against NSS5.exe, not assumed from
' the decompiler): "TapKick" @0x00C79D3C, "Cross" @0x00C72880, "Shot" @0x00C79D58,
' "Requested pass" @0x00C79D78, "AI pass" @0x00C79DA0.
'
' FLOAT CONSTANTS (read directly out of the masked .rdata addresses, per codegen-patterns.md
' section 21's "masked != unknowable" -- a MATCH alone does not certify a masked constant's
' VALUE): YardsToPixels args 10.0/12.0/30.0/25.0/40.0/28.0/7.5/25.0 are immediate x87 pushes,
' not masked, and therefore already exact-byte-verified by the MATCH itself. The three
' memory-operand constants ARE masked and were read directly: 0x00C79D6C=30.0 (Shot
' kickpower), 0x00C79D70=0.1 (nearBall kickpower multiplier), 0x00C79D74=40.0 (Shot-else
' kickpower). Also masked and read: 0x00C79DBC=0.5 (joy.force threshold),
' 0x00C79DC0=1.5 and 0x00C79DC4=1.5 (newstar jitter multipliers on Self.passing).
'
' FIELD OFFSETS cross-checked against extracted/object_model.json's TPlayer/TJoy member
' lists (all agree): newstar=8, controller=0x18, x=0x4c, y=0x50, selectionno=0xbc,
' kickpower=0xc0, kickdirection=0xc4, distancetogoal_opp=0xe8, teammateid=0xf0,
' directiontoteammate=0xf8, distancetoteammate=0xfc, calling=0x114, joy=0x158, passing=0x170,
' TPlayer.id=0x10, TJoy.force=0x10, TJoy.direction=0x14.
'
' CLASS-TABLE SLOTS used: TPlayer 0x100=TapKickAdvanced, 0x160=GetShootingDirection,
' 0x168(static)=GetPlayerById, 0x174=GetMyTeam, 0x1e4=DoAnimKick; TTeam
' 0x90=GetPlayerNearestToXY; TPitch 0x60=InsideCrossZone, 0x6c=YardsToPixels; TBall
' 0x68=Kick. MODULE FUNCTIONS: Dist2D, AngleTo (both already recovered elsewhere).
'
' ASSUMPTIONS (module Globals -- names are ours, types are load-bearing):
' g_player_int14:Int (0x00C5D1AC, AI/auto-play toggle, compared to
' 1), g_player_int01:Int (0x00C5B1FC, match state), g_training_int03:Int (0x00C6CF90,
' training mode), g_player_int19:Int (0x00C5D658, shooting-direction multiplier),
' g_player_float18/19/20/21:Float (0x00C5DE94/98/9C/A0, pass-power multipliers),
' g_player_tplayer02:TBall (0x00C5DEA4, the match ball).
	Method TapKick:Int()
		'!Global g_player_int14:Int
		'!Global g_player_int01:Int
		'!Global g_training_int03:Int
		'!Global g_player_int19:Int
		'!Global g_player_float18:Float
		'!Global g_player_float19:Float
		'!Global g_player_float20:Float
		'!Global g_player_float21:Float
		'!Global g_player_tplayer02:TBall

		If Self.newstar And g_player_int14 = 1
			Self.TapKickAdvanced()
			Return 0
		EndIf

		LogLine("TapKick")
		Local kicktype:Int = 1
		Self.kickdirection = Self.directiontoteammate
		Self.kickpower = Self.distancetoteammate * g_player_float20
		Local mate:TPlayer = TPlayer.GetPlayerById(Self.teammateid)
		Local dir:Int = Self.GetShootingDirection()
		Local incrosszone:Int = TPitch.InsideCrossZone(Int(Self.x), Int(Self.y), dir)
		If g_player_int01 = 3 Then incrosszone = 0

		If g_training_int03 And Self.selectionno = 0
			Self.kickpower = 1.0
			Self.kickdirection = Rand(80, 110)
			kicktype = 3
		Else
			Local canShoot:Int = Not(mate <> Null) Or (Self.controller = 0 And g_player_int01 <> 5 And incrosszone And mate.newstar = 0)
			If canShoot
				If incrosszone
					incrosszone = g_player_int01 = 1
				EndIf
				If incrosszone
					LogLine("Cross")
					kicktype = 3
					Local team:TTeam = Self.GetMyTeam()
					Local target:TPlayer = team.GetPlayerNearestToXY(0, g_player_int19 * Self.GetShootingDirection(), 0, Null, 0)
					Self.teammateid = target.id
					If Dist2D(Self.x, Self.y, target.x, target.y) < TPitch.YardsToPixels(10.0)
						kicktype = 3
						Self.kickdirection = AngleTo(Self.x, Self.y, target.x, target.y)
					Else
						If Dist2D(target.x, target.y, 0, g_player_int19 * Self.GetShootingDirection()) < TPitch.YardsToPixels(12.0)
							Self.kickdirection = AngleTo(Self.x, Self.y, target.x, target.y)
						Else
							Self.kickdirection = AngleTo(Self.x, Self.y, 0, g_player_int19 * Self.GetShootingDirection())
						EndIf
					EndIf
					Self.kickpower = Self.distancetoteammate * g_player_float21
				Else
					LogLine("Shot")
					Self.kickdirection = Self.joy.direction
					Self.kickpower = 30.0
					kicktype = 1
					Local nearBall:Int = g_player_tplayer02 <> Null And g_player_tplayer02.setpiecetaker = Self
					If nearBall
						kicktype = 3
						Self.kickpower = Self.distancetogoal_opp * 0.1
					Else
						If Self.distancetogoal_opp < TPitch.YardsToPixels(30.0)
							Self.kickpower = 40.0
							kicktype = 2
						EndIf
					EndIf
				EndIf
			Else
				If Self.controller = 0
					If mate.newstar And mate.calling And mate.calltype > 0 And g_player_int14 = 1 And g_player_int01 <> 2
						LogLine("Requested pass")
						Select mate.calltype
							Case 1
								kicktype = 2
								Self.kickpower = Self.distancetoteammate * g_player_float18
							Case 3
								kicktype = 3
								Self.kickpower = Self.distancetoteammate * g_player_float19
								If Self.distancetoteammate > TPitch.YardsToPixels(25.0)
									Self.kickpower = Self.distancetoteammate * g_player_float20
								EndIf
							Case 2
								kicktype = 1
								Self.kickpower = Self.distancetoteammate * g_player_float20
						End Select
					Else
						LogLine("AI pass")
						If Self.distancetoteammate > TPitch.YardsToPixels(40.0)
							kicktype = 3
							Self.kickpower = Self.distancetoteammate * g_player_float19
						ElseIf Self.distancetoteammate > TPitch.YardsToPixels(28.0)
							kicktype = 3
							Self.kickpower = Self.distancetoteammate * g_player_float19
						Else
							kicktype = 1
							Self.kickpower = Self.distancetoteammate * g_player_float20
						EndIf
					EndIf
				Else
					Local farAndWeak:Int = Self.joy.force < 0.5 And Self.distancetoteammate > TPitch.YardsToPixels(7.5)
					If farAndWeak
						kicktype = 3
						Self.kickpower = Self.distancetoteammate * g_player_float19
						If Self.distancetoteammate > TPitch.YardsToPixels(25.0)
							Self.kickpower = Self.distancetoteammate * g_player_float20
						EndIf
					EndIf
				EndIf
				If Self.newstar <> 0
					Local kp:Float = Self.kickpower
					kp = kp - Rand(Int(Self.passing), 1)
					Self.kickpower = kp
					Local kd:Float = Self.kickdirection
					kd = kd + Rand(Int(-Self.passing * 1.5), Int(Self.passing * 1.5))
					Self.kickdirection = kd
				EndIf
			EndIf
		EndIf

		If g_player_int01 = 2 Then kicktype = 1
		If g_training_int03 = 4 Then kicktype = 1
		Self.DoAnimKick(Int(Self.kickpower))
		g_player_tplayer02.Kick(Self, Self.kickdirection, Self.kickpower, kicktype, Self.teammateid)
		Return 0
	End Method
