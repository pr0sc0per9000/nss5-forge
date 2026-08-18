' TBall.Kick   (KIND=Method, SIG=(:TPlayer,f,f,i,i)i, SLOT=0x68)
' VA 0x004C91A2   2707 bytes   (Ghidra-authoritative)
' ORACLE: mode=reloc  matched=2707/2707  reloc_masked=142  STATUS=MATCH
' verified with NSS5_NO_LEARN=1 (no learned helper names contributed to the pass)
'
' PARAMETERS. a0:TPlayer the kicking player, a1:Float kick direction (degrees), a2:Float
'   kick power, a3:Int kick type (1 Pass / 2 Shoot / 3 Lob / 4 Head Pass / 5 Head Shoot /
'   6 Head Lob -- see TBall.GetStringKickType), a4:Int the pass target's player id (or <=0
'   for none).
'
' ASSUMPTIONS (module Globals -- names are ours, types are load-bearing)
'   g_snd_kick:TSound / g_chan_kick:TChannel   (0x00C5A518 / 0x00C5A510) -- the kick sound.
'   g_snd_alert2:TSound / g_chan_alert2:TChannel (0x00C5DF40 / 0x00C6F090) -- the
'     tired/unhappy on-screen-message sound (same pair TPlayer.UpdateMovement calls
'     g_snd_alert/g_chan_alert -- different addresses, not reused: this pair is TBall's own).
'   g_hometeam:TTeam (0x00C5B218) -- globals_final flags a CONFLICT (TKit=2;TTeam=1); it is
'     TTeam here exactly as codegen-patterns 11.2 / TPlayer.CheckOffside already established:
'     the code reads field +8 and compares it to TPlayer.teamid, an Int, and TTeam+8 is id:Int.
'   g_player_int01:Int (0x00C5B1FC) -- match-state code, Int project-wide.
'   g_training_int03:Int (0x00C6CF90).
'   g_profile:TProfile (0x00C6F028) -- same address TPlayer.UpdateMovement already names
'     g_profile. Field +0x15C is `energy:Float` (object_model.json), not "tiredness" --
'     TProfile has no field of that name at that offset.
'   g_img_tired:TImage (0x00C5B30C), g_img_unhappy:TImage (0x00C5B304) -- the CreateAlert
'     icon images, same role as UpdateMovement's g_img_drunk/g_img_stomach.
'   g_engine_int163:Int (0x00C6EFE8), g_player_int50:Int (0x00C6EFD4, "verified" in
'     globals_corrections), g_player_int16:Int / g_player_int17:Int (0x00C5D634 /
'     0x00C5D638, the pitch half-width / half-height -- same addresses TBall.CheckSideLines
'     already names g_pitchhalfwidth/g_pitchhalfheight), g_player_int33:Int (0x00C5DE70,
'     already established by TBall.UpdateMetaBall).
'   g_ball_float02/06/07/08/09/10/11/12/13:Float (0x00C5A4D0/E0/E4/E8/EC/F0/F4/F8/FC) --
'     the per-kick-type velocity/zvelocity multipliers.
'   g_ball_double01:Double (0x00C72720) -- the shot-angle threshold AngleDiff is compared
'     against before a shot is scored as "on target". The original data-section value
'     is 25.0, read directly from NSS5.exe. See codegen-patterns 21.1/21.3.
'   g_ball_int05:Int (0x00C5B244) -- stamped with g_player_int50 when match-state 9->10.
'   g_engine_int29:Int / g_engine_int30:Int (0x00C5B264 / 0x00C5B268) -- home/away
'     on-target shot counters.
'
' CLASS-TABLE SLOTS resolved via class_tables.tsv / vtable_map.tsv (all receiver-typed,
'   not module Globals -- guide 3f/11.4): TPlayer 0xac=ResetKick, 0x160=GetShootingDirection,
'   0x1b0=PlayerSliding, 0x1e0=DoAnimFall, 0x228=AddStat; TBall 0xc8=GetStringKickType (a
'   Type Function reached through Self's own class table -- guide 3d, no `Self.`/`TBall.`
'   needed, "Self." has no codegen effect either way); TPitch 0x60=InsideCrossZone,
'   0x6c=YardsToPixels; TPlayer static 0x168=GetPlayerById, 0x21c=UpdatePositionWhenKickedAll;
'   TEngine static 0x80=ResetClubLastChange (a real no-argument call -- FF15 through the
'   class table, not a game-code E8).
'
' MODULE FUNCTIONS (already recovered, called here): AngleDiff (src/recovered_module/
'   AngleDiff.bmx, 0x00506049) and GetInterceptPoint (src/recovered_module/
'   GetInterceptPoint.bmx, 0x00505E20) -- the shot-on-target check builds a
'   TInterceptPoint between the ball's shot trajectory and the goal-mouth line.
'
' STRING LITERALS -- read out of NSS5.exe with harness.read_string(), a MATCH does not
'   certify content: "Kick:" (0x00C72650), ": " (0x00C6F3DC), "matchmsg_Tired" (0x00C72670),
'   "matchmsg_Unhappy" (0x00C7269C), "666666" (0x00C6FC70), "FFFFFF" (0x00C5D680).
'
' SHAPE NOTES the oracle forced (do not "simplify" these back -- each costs real bytes):
'   * The opening log line is ONE expression `"Kick:" + GetStringKickType(a3) + ": " +
'     String(a2)`, not built through a Local. bcc evaluates the chain by pre-pushing the
'     later operands (String(a2) computed FIRST, then GetStringKickType(a3), then the two
'     concat literals) while still folding left-to-right -- reproduce the expression as
'     written, not the call order.
'   * The tired/unhappy gate is a single short-circuit chain
'     `If g_profile.energy < 30.0 And Rand(0,40) > g_profile.energy Then <tired> Else
'     <unhappy check>` -- NOT two nested Ifs with an intermediate flag Local. A flag Local
'     materialises an extra `mov reg,0` that the original does not spend (+5 bytes / two
'     sites) because the original's "false" case is simply the eax left over from the
'     short-circuit's own skip path.
'   * `TPitch.InsideCrossZone(...)` is used as a bare truth value in the Or/And guard, not
'     compared `<> 0` -- the explicit compare costs 9 extra bytes (guide 3f/10.3).
'   * `If Self.lastkickmatchstate = 7 ... a0.newstar ... a0.ihadashot = 1` is two NESTED
'     Ifs, not one `And`-chain -- both original jumps land on the same address, which a
'     2-term chain of simple field/constant compares also renders as nested `cmp;jne`
'     pairs with no intermediate `sete`/`movzx` (the eax-accumulator form guide 3f shows is
'     for longer chains / call results, not this).
'   * The Case-8/11/9/10/0 dispatch on g_player_int01 is a `Select` whose non-matching
'     path is an explicit `Default` clause (holding the whole shot-on-target block and the
'     trailing `g_player_int01 = 1`) -- not code written after `End Select`. bcc lays out
'     Select as [compares] + [Default body inline] + [the other Cases' bodies afterward,
'     each `jmp` back to the shared exit]; code after `End Select` behaves differently
'     (unconditional trailing code) and put the Case bodies in the wrong place, which also
'     shortened several of the compares' jumps from `0F 8x` (rel32) to `74/75` (rel8).
'   * `Self.z > 10.0 Then zvelocity=g_ball_float07 Else zvelocity*=0.5` and
'     `a2 > 100.0 Then ...` (both clamp sites) -- write the Local/field on the LEFT of `>`;
'     the mirror spelling with the literal on the left adds an `fxch st(1)` bcc does not
'     otherwise need (guide 10.1: operand order is byte-observable, read the cmp).
'   * The final pitch-clamp uses `-g_player_int16 + 3`, not `3 - g_player_int16` -- same
'     value, but `CONST - Global` compiles to `mov eax,CONST / sub eax,[g]` (6-byte sub)
'     while `-Global + CONST` compiles to `mov eax,[g] / neg eax / add eax,CONST` (one byte
'     shorter, and what the original does).
	Method Kick:Int(a0:TPlayer, a1:Float, a2:Float, a3:Int, a4:Int)
		'!Global g_snd_kick:TSound
		'!Global g_chan_kick:TChannel
		'!Global g_snd_alert2:TSound
		'!Global g_chan_alert2:TChannel
		'!Global g_hometeam:TTeam
		'!Global g_player_int01:Int
		'!Global g_training_int03:Int
		'!Global g_profile:TProfile
		'!Global g_img_tired:TImage
		'!Global g_img_unhappy:TImage
		'!Global g_engine_int163:Int
		'!Global g_player_int50:Int
		'!Global g_player_int16:Int
		'!Global g_player_int17:Int
		'!Global g_player_int33:Int
		'!Global g_ball_float02:Float
		'!Global g_ball_float06:Float
		'!Global g_ball_float07:Float
		'!Global g_ball_float08:Float
		'!Global g_ball_float09:Float
		'!Global g_ball_float10:Float
		'!Global g_ball_float11:Float
		'!Global g_ball_float12:Float
		'!Global g_ball_float13:Float
		'!Global g_ball_double01:Double = 25.0
		'!Global g_ball_int05:Int
		'!Global g_engine_int29:Int
		'!Global g_engine_int30:Int

		LogLine("Kick:" + GetStringKickType(a3) + ": " + String(a2))
		PlaySound(g_snd_kick, g_chan_kick)
		If a0.newstar And g_player_int01 = 1 And g_training_int03 = 0 And (a3 = 2 Or a3 = 3) And Rand(5) = 1
			If g_profile.energy < 30.0 And Rand(0, 40) > g_profile.energy
				a2 = a2 * 0.5
				a3 = 1
				Select Rand(2)
					Case 1
						a1 = a1 + Rand(20, 40)
					Case 2
						a1 = a1 - Rand(20, 40)
				End Select
				a0.DoAnimFall()
				a0.tiredness = g_player_int50
				TScreenMessage.CreateAlert(10, g_engine_int163 - 60, GetText("matchmsg_Tired"), 2500, "666666", "FFFFFF", g_img_tired, 3, 0, 0, 0, 1)
				PlaySound(g_snd_alert2, g_chan_alert2)
			Else
				If a0.happiness < Rand(70)
					a2 = a2 * 0.75
					a3 = 1
					Select Rand(2)
						Case 1
							a1 = a1 + Rand(10, 30)
						Case 2
							a1 = a1 - Rand(10, 30)
					End Select
					a0.unhappiness = g_player_int50
					TScreenMessage.CreateAlert(10, g_engine_int163 - 60, GetText("matchmsg_Unhappy"), 2500, "666666", "FFFFFF", g_img_unhappy, 3, 0, 0, 0, 1)
					PlaySound(g_snd_alert2, g_chan_alert2)
				EndIf
			EndIf
		EndIf
		a2 = a2 + 50.0
		If g_player_int01 = 5
			If a2 > 100.0 Then a2 = 130.0
		Else
			If a2 > 100.0 Then a2 = 100.0
		EndIf
		If Self.controlledby <> Null Then Self.controlledby.ResetKick()
		a0.kickx = Int(a0.x)
		a0.kicky = Int(a0.y)
		a0.lastkickdirection = a1
		Self.kicktime = g_player_int50
		Self.lastkickedby = a0
		Self.lasttouchedby = a0
		Self.teaminpossession = a0.teamid
		Self.controlledby = Null
		Self.passtoid = a4
		a0.icalledforball = 0
		If a4 > 0
			Local rp:TPlayer = TPlayer.GetPlayerById(Self.passtoid)
			Self.disttoreciever = Dist2D(Self.x, Self.y, rp.x, rp.y)
		EndIf
		Self.direction = a1
		Self.curlamount = 0
		Self.backpass = 1
		Self.slidekick = 0
		If a0.PlayerSliding()
			Self.backpass = 0
			Self.slidekick = 1
		EndIf
		Select a3
			Case 1
				Self.velocity = a2 * g_ball_float06
				Self.zvelocity = g_ball_float07
			Case 2
				Self.velocity = a2 * g_ball_float08
				Self.zvelocity = g_ball_float09
				If g_player_int01 = 7 Or g_player_int01 = 9
					Self.zvelocity = (g_ball_float09 * 1.4 / 50.0) * (a2 - 50.0)
				ElseIf g_player_int01 = 3
					Self.velocity = Self.velocity * 0.85
					Self.passtoid = -1
				Else
					If a0.distancetogoal_opp < TPitch.YardsToPixels(16.0)
						If Self.z > g_player_int33 * 0.3
							Self.z = g_player_int33 * 0.3
						EndIf
						If Self.z > 10.0
							Self.zvelocity = g_ball_float07
						Else
							Self.zvelocity = Self.zvelocity * 0.5
						EndIf
					EndIf
				EndIf
			Case 3
				Self.velocity = a2 * g_ball_float10
				Self.zvelocity = g_ball_float11
				If g_player_int01 = 3
					Self.velocity = Self.velocity * 0.85
					Self.passtoid = -1
				EndIf
				If g_player_int01 = 6
					Self.velocity = Self.velocity * 1.2
					Self.zvelocity = Self.zvelocity * 1.4
				EndIf
				If g_player_int01 = 5 Or (g_player_int01 = 1 And TPitch.InsideCrossZone(Int(Self.x), Int(Self.y), a0.GetShootingDirection()))
					Self.velocity = Self.velocity * 1.1
				EndIf
				If g_training_int03 = 0 And a0.distancetogoal_opp < TPitch.YardsToPixels(12.0)
					Self.zvelocity = Self.zvelocity * 0.5
				EndIf
			Case 4
				Self.velocity = a2 * g_ball_float12
				Self.zvelocity = g_ball_float13 * 0.2
				Self.backpass = 0
			Case 5
				Self.velocity = a2 * g_ball_float12
				Self.zvelocity = g_ball_float13 * 0.75
				Self.backpass = 0
			Case 6
				Self.velocity = a2 * g_ball_float12
				Self.zvelocity = g_ball_float13 * 1.0
				Self.backpass = 0
		End Select
		Self.lastkicktype = a3
		Self.lastkickmatchstate = g_player_int01
		TPlayer.UpdatePositionWhenKickedAll(Self.teaminpossession)
		TEngine.ResetClubLastChange()
		Select g_player_int01
			Case 8
			Case 11
			Case 9
				g_player_int01 = 10
				g_ball_int05 = g_player_int50
			Case 10
			Case 0
			Default
				If Self.lastkickmatchstate = 7
					If a0.newstar
						a0.ihadashot = 1
					EndIf
				EndIf
				If AngleDiff(Self.direction, a0.directiontogoal_opp, 1) < g_ball_double01 And a0.distancetogoal_opp < TPitch.YardsToPixels(50.0)
					Local spread:Float = Self.velocity * g_ball_float02 * 40.0
					Local ip:TInterceptPoint = GetInterceptPoint(Self.x, Self.y, Self.x + Cos(Self.direction) * spread, Self.y + Sin(Self.direction) * spread, -g_player_int16 * 0.5, g_player_int17 * a0.GetShootingDirection(), g_player_int16 * 0.5, g_player_int17 * a0.GetShootingDirection())
					If ip.intercept <> 0
						a0.AddStat(2, Self.direction, a0.distancetogoal_opp, 0, 0)
						If a0.newstar Then a0.ihadashot = 1
						If a0.teamid = g_hometeam.id
							g_engine_int29 = g_engine_int29 + 1
						Else
							g_engine_int30 = g_engine_int30 + 1
						EndIf
					EndIf
				EndIf
				g_player_int01 = 1
		End Select
		If g_player_int01 <> 8 And g_training_int03 = 0
			ClampFloat(Varptr Self.x, -g_player_int16 + 3, g_player_int16 - 3)
			ClampFloat(Varptr Self.y, -g_player_int17 + 3, g_player_int17 - 3)
		EndIf
	End Method
