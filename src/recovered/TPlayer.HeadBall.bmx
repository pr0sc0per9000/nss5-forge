' TPlayer.HeadBall
' VA 0x004F8A6A   1267 bytes   vtable slot 0x118   sig ()i   KIND=Method
' byte-identical vs NSS5.exe (1267/1267, original length from Ghidra's inventory, mode=reloc)
'
' Globals: g_player_int14/int17/int18/int33:Int, g_player_tplayer02:TBall (the active ball
'   -- established convention, see TPlayer.ChaseBall.bmx / TBall.Kick.bmx / TPlayer.AddStat.bmx).
' Fields (TPlayer): newstar +0x08, controller +0x18, x +0x4C, y +0x50, kickpower +0xC0,
'   kickdirection +0xC4, directiontogoal_opp +0xE0, distancetogoal_opp +0xE8,
'   distancetogoal_own +0xEC, teammateid +0xF0, directiontoteammate +0xF8,
'   distancetoteammate +0xFC, joy:TJoy +0x158 (joy.direction at TJoy+0x14), heading +0x174.
' TBall fields: z at +0x20 (ball height). TBall slots: NewController(:TPlayer) 0x84,
'   Deflect(:TPlayer) 0x90, Kick(:TPlayer,f,f,i,i) 0x68. TPlayer's own slots:
'   GetShootingDirection() 0x160, AddStat(i,f,f,f,f) 0x228, HeadBallAdvanced() 0x11c.
' TPitch.YardsToPixels(f)f is a cross-Type static call (class-table slot 0x6c).
' FUN_004A7FE0 = _bbFloatAbs -> Abs(). Module fn AngleTo (0x0050639D, already recovered).
'
' Shape notes (all confirmed by byte match, not guessed):
'  - Outer `ball.z >= int33*0.6` guards two DISTINCT branches (headbutt vs Deflect) and is a
'    SOLO relational condition -- codegen-patterns 21's negate+swap rule applies: written
'    source is the NEGATION with swapped Then/Else (`If ball.z < threshold Then Deflect
'    Else <main>`), which is what reproduces the original's `setae` test.
'  - `Deflect(Self)` needs its own explicit `Return 0` (it is an early return out of the
'    Then-arm, not a full parallel Else-content).
'  - `Self.newstar And g_player_int14 = 1` -- `newstar` is a BARE truth test (compiles to a
'    plain `cmp eax,0/je`), not `Self.newstar <> 0` (which emits an extra setne/movzx and is
'    2 bytes short). `Self.HeadBallAdvanced(); Return 0` follows as an early return, no Else.
'  - `Self.teammateid = 0 Or ...` (controller=0 branch) -- NOT `<> 0`; verified against
'    `sete`/`setne` byte content.
'  - The `distancetogoal_opp >= Yards(8.0)` gate (controller=0, uVar5=6 sub-branch) is ALSO
'    a solo-relational If/Else with distinct content and needs the same negate+swap:
'    `If distancetogoal_opp < Yards(8.0) Then <uVar5=4 case> Else <uVar5=6 continuation>`.
'  - The two `Rand(Int(-heading*1.5), Int(heading*1.5))` calls (teammateid<>0/controller
'    branch, and the final kickdirection nudge) need the NEGATED term written FIRST in
'    source. bcc computes a static call's scalar arguments in the order WRITTEN (unlike
'    push order, which is right-to-left) -- writing the positive term first put the `fchs`
'    on the wrong operand and cost 2 bytes at each of the two sites.
'  - `Self.kickdirection = Self.directiontoteammate` / `Self.kickpower =
'    Self.distancetoteammate * 0.06` are plain Int->Float / Float assignments; Ghidra's
'    `(int)(float)` cast noise on the first is decompiler artifact, not real casts (both
'    fields are genuinely Float per object_model.json).
	'!Global g_player_int14:Int
	'!Global g_player_int17:Int
	'!Global g_player_int18:Int
	'!Global g_player_int33:Int
	'!Global g_ball:TBall
	If g_ball.z < g_player_int33 * 0.6
		g_ball.Deflect(Self)
		Return 0
	Else
		If Self.newstar And g_player_int14 = 1
			Self.HeadBallAdvanced()
			Return 0
		EndIf
		LogLine("HeadBall")
		g_ball.NewController(Self)
		Self.kickdirection = Self.directiontoteammate
		Self.kickpower = Self.distancetoteammate * 0.06
		Local uVar5:Int = 4
		If Self.controller = 0
			If Self.teammateid = 0 Or Self.distancetogoal_own < TPitch.YardsToPixels(30.0) Or Self.distancetogoal_opp < TPitch.YardsToPixels(18.0)
				Self.kickdirection = Self.directiontogoal_opp + Rand(-20, 20)
				Self.kickpower = 50.0
				uVar5 = 6
				If Self.distancetogoal_opp < TPitch.YardsToPixels(8.0)
					uVar5 = 4
					Self.kickdirection = AngleTo(Self.x, Self.y, Self.x, g_player_int17 * Self.GetShootingDirection()) + Rand(-10, 10)
				Else
					If Self.distancetogoal_opp < TPitch.YardsToPixels(18.0) And Abs(Self.x) < g_player_int18
						uVar5 = 5
						Self.kickdirection = AngleTo(Self.x, Self.y, Self.x, g_player_int17 * Self.GetShootingDirection()) + Rand(-10, 10)
					EndIf
				EndIf
			EndIf
		Else
			If Self.teammateid = 0 Or Self.distancetogoal_own < TPitch.YardsToPixels(30.0)
				Self.kickdirection = Self.joy.direction
				Self.kickpower = 50.0
				uVar5 = 4
				If Self.distancetogoal_opp < TPitch.YardsToPixels(18.0)
					uVar5 = 5
					Self.kickdirection = AngleTo(Self.x, Self.y, Self.x, g_player_int17 * Self.GetShootingDirection()) + Rand(Int(-Self.heading * 1.5), Int(Self.heading * 1.5))
				EndIf
			EndIf
		EndIf
		Self.kickpower = Self.kickpower - Rand(Int(Self.heading * 1.5), 1)
		Self.kickdirection = Self.kickdirection + Rand(Int(-Self.heading * 1.5), Int(Self.heading * 1.5))
		g_ball.Kick(Self, Self.kickdirection, Self.kickpower, uVar5, Self.teammateid)
		Self.AddStat(6, 0, 0, 0, 0)
	EndIf
