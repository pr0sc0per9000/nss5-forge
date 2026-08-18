' TPlayer.UpdateMovement
' VA 0x004F0468   4137 bytes   vtable slot 0x80   sig ()i
' byte-identical vs NSS5.exe (4137/4137, original length from Ghidra's inventory,
' mode=reloc, reloc_masked=187), verified with NSS5_NO_LEARN=1, learned_helpers=None.
'
' DEPENDENCIES. All 1253 instructions decode, but two E8 operands -- both the same call
' to the module Function at 0x00506049 -- only resolve once that function is recovered
' (src/recovered_module/AngleDiff.bmx, 284/284) together with its own leaf callee
' (src/recovered_module/Cross2D.bmx, 31/31, reloc_masked=0). Those name the original side
' of both operands and close the body at full length. Nothing here was learned from this
' body: AngleDiff was matched on its own first, and Cross2D before it with no masking at
' all, so neither name can have come from the call sites it now masks.
'
' ASSUMPTIONS (module Global types are load-bearing -- they pick the dispatch slot):
'   g_match_ball:TBall (0x00C5DEA4)      g_engine_tball:TBall (0x00C5B22C, +0xC=active)
'   g_profile:TProfile (0x00C6F028)      g_player_tplayer01:TPlayer (0x00C5B248)
'   g_player_arr13:Int[] (0x00C5DEDC)    g_img_drunk/g_img_stomach:TImage (0x00C5B320/31C)
'   g_snd_alert:TSound (0x00C5DF3C)      g_chan_alert:TChannel (0x00C6F090)
'   Ints: g_options_int19 C5D294, g_player_int01 C5B1FC, g_player_int15 C5D228,
'         g_player_int16/17/18 C5D634/638/63C, g_pitch_int10 C5D648,
'         g_player_int50 C6EFD4, g_engine_int20 C5B210, g_engine_int163 C6EFE8,
'         g_training_int03 C6CF90
'   Floats: g_player_float03/05/06/09/10/17 C5DE48/50/54/60/64/90, g_ball_float03 C5A4D4
' 0x00C5B22C is TBall, not the TPlayer globals_final.tsv claims: it is read as [eax+0xC]
' and compared with 1, and TPlayer+0xC is imgPlayer:TImage while TBall+0xC is active:Int.
' 0x00C5DEDC is Int[], not Object[]: it is compared with TPlayer.currentanim, whose
' reflected type is []i.
' All string literals read out of NSS5.exe with harness.read_string(): "matchmsg_Drunk",
' "matchmsg_Stomach", "666666", "FFFFFF", "Team", "FF00FF", "+". Float constants likewise:
' 0x00C79648 is a Double 0.25 (fld qword), 0x00C796F0 and 0x00C796F4 are both 10.5.
'
' CODEGEN NOTES worth keeping (all measured against the byte count):
'   * `If Self.KeeperHoldingBall()` with an EMPTY Then-branch and a real Else. The
'     `74 02 EB xx` is the je stepping over the empty branch's own jmp; `If x = 0` and
'     `If Not x` both give a 2-byte jne and come out 2 bytes short.
'   * `AngleDiff(...) * 0.25` and `Cos(dir) * speed`, never the operands the other way
'     round -- bcc evaluates left to right and spills the left operand across the call,
'     so a constant loaded AFTER the call means the call was the left operand.
'   * `-g_player_int17 + 5` (neg/add, 10 bytes), not `5 - g_player_int17` (11).
'   * AddStat takes SIX arguments, per the `add esp,0x1c` and the reflected (i,i,i,i,f,i)i;
'     Ghidra prints _bbFloatToInt swallowing the following call's pushes.
' g_options_int19's original data-section value is 1 (read from NSS5.exe at
' 0x00C5D294 -- codegen-patterns 21.1/21.3).
'!Global g_options_int19:Int = 1
'!Global g_player_int01:Int
'!Global g_engine_tball:TBall
'!Global g_player_int50:Int
'!Global g_match_ball:TBall
'!Global g_training_int03:Int
'!Global g_player_int15:Int
'!Global g_player_float10:Float
'!Global g_player_float09:Float
'!Global g_player_float03:Float
'!Global g_profile:TProfile
'!Global g_player_arr13:Int[]
'!Global g_player_float05:Float
'!Global g_player_float06:Float
'!Global g_engine_int20:Int
'!Global g_player_float17:Float
'!Global g_img_drunk:TImage
'!Global g_img_stomach:TImage
'!Global g_engine_int163:Int
'!Global g_snd_alert:TSound
'!Global g_chan_alert:TChannel
'!Global g_player_int16:Int
'!Global g_player_int17:Int
'!Global g_player_int18:Int
'!Global g_ball_float03:Float
'!Global g_pitch_int10:Int
'!Global g_player_tplayer01:TPlayer
Self.oldx = Self.x
Self.oldy = Self.y
Self.oldz = Self.z
Local olddir:Float = Self.direction
Local dir:Int = Int(Self.joy.direction)
If Self.kickdirection <> -1.0
	If g_options_int19 Or TEngine.SetPiece()
		dir = Int(Self.kickdirection)
	Else
		Self.kickdirection = Self.kickdirection + AngleDiff(Self.kickdirection, Self.joy.direction, 0) * 0.25:Double
	EndIf
EndIf
Local force:Float = Self.joy.force
If Self.ForceControlCPU()
	dir = Int(AngleTo(Self.x, Self.y, Self.desx, Self.desy))
	Local t1:Float = 1.0
	Local t2:Float = 1.0
	t2 :/ Dist2D(Self.x, Self.y, Self.desx, Self.desy)
	t1 :- t2 * 3.0
	force = t1
	If g_player_int01 = 2 And Self.x < -g_player_int16 - 40 And Self.selectionno < 11
		dir = 0
		force = 1.0
	EndIf
	If g_player_int01 = 8 Or (g_player_int01 = 11 And g_engine_tball.active <> 1)
		Self.DoCelebrations()
	EndIf
EndIf
Local timerunning:Float = g_player_int50 - Self.runtime
Local pace:Float = Self.pace
Local turnlimit:Int = 35
If g_match_ball <> Null And g_match_ball.controlledby = Self
	pace = Self.dribbling
	turnlimit = 20
EndIf
If Self.selectionno = 0
	If g_training_int03
		pace = pace * 0.65
	EndIf
Else
	If Self.GetMyTeam().controller = 0
		Select g_player_int15
		Case 1
			pace = pace * 0.825
		Case 2
			pace = pace * 0.925
		Case 3
		End Select
	EndIf
EndIf
Local xhit:Int
Local speed:Float = pace * g_player_float10
If Self.KeeperHoldingBall()
Else
	If AngleDiff(olddir, dir, 1) < turnlimit
		If timerunning > 500.0
			speed = pace * g_player_float09
		EndIf
		If timerunning > 1500.0
			speed = pace
		EndIf
	Else
		Self.runtime = g_player_int50
	EndIf
EndIf
If (TEngine.SetPiece() Or g_player_int01 = 0) And Dist2D(Self.x, Self.y, Self.desx, Self.desy) > TPitch.YardsToPixels(2.0)
	speed = g_player_float03
EndIf
If g_player_int50 < Self.boozedup + 2500
	speed = speed * 0.5
ElseIf g_player_int50 < Self.nrgsickness + 5000
	speed = speed * 0.5
ElseIf g_profile.energy < 5.0
	speed = speed * 0.85
ElseIf g_profile.energy < 10.0
	speed = speed * 0.9
ElseIf g_profile.energy < 15.0
	speed = speed * 0.95
EndIf
If Self.currentanim = g_player_arr13
	Self.xvel = Self.xvel + g_player_float03 * 0.5
	Self.xvel = Self.xvel * g_player_float05
	Self.yvel = Self.yvel * g_player_float05
Else
	If Self.PlayerOnFeet() = 0
		Self.xvel = Self.xvel * g_player_float06
		Self.yvel = Self.yvel * g_player_float06
	Else
		If force > 0.2
			Self.xvel = Self.xvel + Cos(dir) * speed
			Self.yvel = Self.yvel + Sin(dir) * speed
		EndIf
		Self.xvel = Self.xvel * g_player_float05
		Self.yvel = Self.yvel * g_player_float05
	EndIf
EndIf
If TTraining.PlayerCanMove(Self)
	Self.speed = Sqr(Self.xvel * Self.xvel + Self.yvel * Self.yvel)
	Self.x = Self.x + Self.xvel
	Self.y = Self.y + Self.yvel
EndIf
If Self.newstar And g_player_int01 = 1 And Self.selectionno < 11
	Local distmoved:Float = Dist2D(Self.oldx, Self.oldy, Self.x, Self.y)
	Self.matchstats.AddStat(1, g_engine_int20, Int(Self.x), Int(Self.y), Self.direction, Int(distmoved))
	g_profile.energy = g_profile.energy - distmoved * g_player_float17
	If g_profile.energy < 0.0
		g_profile.energy = 0.0
	EndIf
	If Self.PlayerOnFeet() And g_match_ball <> Null And g_training_int03 = 0
		If Rand(7500, 1) = 1 And ((g_profile.booze > 0 And Self.boozecount = 0) Or (g_profile.booze > 50 And Self.boozecount = 1))
			Self.boozedup = g_player_int50
			Self.boozecount :+ 1
			Self.DoAnimFall()
			TScreenMessage.CreateAlert(10, g_engine_int163 - 60, GetText("matchmsg_Drunk"), 2500, "666666", "FFFFFF", g_img_drunk, 3, 0, 0, 0, 1)
			PlaySound(g_snd_alert, g_chan_alert)
		Else
			If Rand(7500, 1) = 1 And ((g_profile.NRG > 0 And Self.nrgcount = 0) Or (g_profile.NRG > 50 And Self.nrgcount = 1))
				Self.nrgsickness = g_player_int50
				Self.nrgcount :+ 1
				TScreenMessage.CreateAlert(10, g_engine_int163 - 60, GetText("matchmsg_Stomach"), 2500, "666666", "FFFFFF", g_img_stomach, 3, 0, 0, 0, 1)
				PlaySound(g_snd_alert, g_chan_alert)
			EndIf
		EndIf
	EndIf
EndIf
If Self.selectionno = 0
	If g_player_int01 = 1
		ClampFloat(Varptr Self.y, -g_player_int17 + 5, g_player_int17 - 5)
	EndIf
	If Self.KeeperHoldingBall() And TPitch.InsidePenaltyBox(Int(Self.x), Int(Self.y), -Self.GetShootingDirection()) = 0
		g_match_ball.backpass = 1
	EndIf
EndIf
Self.zvel = Self.zvel - g_ball_float03
Self.z = Self.z + Self.zvel
If Self.z < 0.0
	Self.z = 0.0
EndIf
Self.metax = Self.x + Self.xvel * Self.speed * 10.5
Self.metay = Self.y + Self.yvel * Self.speed * 10.5
If Self.speed > 0.0
	Self.direction = ATan2(Self.yvel, Self.xvel)
EndIf
If TEngine.SetPiece() And g_match_ball <> Null And g_match_ball.controlledby = Self
	Self.direction = Self.joy.direction
EndIf
If TTraining.TrainingSetPiece(Self) And Self.KeeperHoldingBall() = 0
	Self.direction = Self.joy.direction
EndIf
If Self.matchstats.reds = 0 And Self.selectionno < 11
	If g_player_int01 <> 2 And g_player_int01 <> 0 And g_player_int01 <> 11
		Local limx:Int = Int(g_player_int16 + TPitch.YardsToPixels(9.0))
		Local limy:Int = Int(g_player_int17 + TPitch.YardsToPixels(5.0))
		ClampFloat(Varptr Self.x, -limx, limx)
		ClampFloat(Varptr Self.y, -limy, limy)
		If g_player_int01 = 8
			Local hy:Float = g_player_int17
			Local hy2:Float = hy + g_pitch_int10
			Local hx:Float = g_player_int18
			Local xhit:Int = 0
			Local yhit:Int = 0
			If Self.y > 0.0
				Local i1:TInterceptPoint = GetInterceptPoint(Self.oldx, Self.oldy, Self.x, Self.y, -hx, hy, -hx, hy2 + 10.0)
				Local i2:TInterceptPoint = GetInterceptPoint(Self.oldx, Self.oldy, Self.x, Self.y, hx, hy, hx, hy2 + 10.0)
				Local i3:TInterceptPoint = GetInterceptPoint(Self.oldx, Self.oldy, Self.x, Self.y, -hx - 10.0, hy2, hx + 10.0, hy2)
				If i1.intercept
					Self.x = Self.oldx
					xhit = 1
				ElseIf i2.intercept
					Self.x = Self.oldx
					xhit = 1
				EndIf
				If i3.intercept
					Self.y = Self.oldy
					yhit = 1
				EndIf
			Else
				Local j1:TInterceptPoint = GetInterceptPoint(Self.oldx, Self.oldy, Self.x, Self.y, -hx, -hy, -hx, -hy2 - 10.0)
				Local j2:TInterceptPoint = GetInterceptPoint(Self.oldx, Self.oldy, Self.x, Self.y, hx, -hy, hx, -hy2 - 10.0)
				Local j3:TInterceptPoint = GetInterceptPoint(Self.oldx, Self.oldy, Self.x, Self.y, -hx - 10.0, -hy2, hx + 10.0, -hy2)
				If j1.intercept
					Self.x = Self.oldx
					xhit = 1
				ElseIf j2.intercept
					Self.x = Self.oldx
					xhit = 1
				EndIf
				If j3.intercept
					Self.y = Self.oldy
					yhit = 1
				EndIf
			EndIf
			If xhit Or yhit
				If xhit
					Self.xvel = Self.xvel * -1.0
				EndIf
				If yhit
					Self.yvel = Self.yvel * -1.0
				EndIf
				Self.direction = ATan2(Self.yvel, Self.xvel)
			EndIf
		EndIf
	EndIf
EndIf
If Self.newstar And g_player_int01 = 8 And Self.bonus = 0 And g_player_tplayer01 <> Null And g_player_tplayer01 = Self
	If g_match_ball.controlledby = Self And Dist2D(Self.x, Self.y, 0, 0) < TPitch.YardsToPixels(10.0)
		Self.bonus = 1
		TParticle.StarShower(Int(Self.x), Int(Self.y), "+" + Lower(GetText("Team")), "FF00FF")
		g_profile.CheckAchievement(39)
		Select g_profile.position
		Case 3
			g_profile.UpdateRelationship(2, 4)
			g_profile.coachrep_team = g_profile.coachrep_team + 4
		Case 4
			g_profile.UpdateRelationship(2, 3)
			g_profile.coachrep_team = g_profile.coachrep_team + 3
		Case 5
			g_profile.UpdateRelationship(2, 2)
			g_profile.coachrep_team = g_profile.coachrep_team + 2
		Default
			g_profile.UpdateRelationship(2, 5)
			g_profile.coachrep_team = g_profile.coachrep_team + 5
		End Select
	EndIf
EndIf
