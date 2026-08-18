' TPlayer.CheckKeeperSave
' VA 0x004F698F   578 bytes   mode=reloc   byte-identical vs NSS5.exe
' KIND=Method, SIG ()i, class-table slot 0xec
' ASSUMPTIONS
'   0x00C5DEA4 g_ball:TBall  (globals_final row is typed TPlayer and is WRONG -- see
'     codegen-patterns 11.2; slots 0x84/0x94 and fields +0x54/+0x70/+0x74 are TBall's).
'   0x00C6CF90 g_training_int03:Int, 0x00C5DE84 g_player_float14:Float,
'   0x00C5DE88 g_player_float15:Float, 0x00C5DF18 g_player_arr28:Int[] (verified row).
'   0x00C5B368 g_Object51:TSound and 0x00C5B348 g_Object46:TChannel -- typed from
'     PlaySound(sound:TSound, channel:TChannel); globals_final only says "Object/low".
'   TBall slot 0x84 = NewController(:TPlayer), slot 0x94 = Parry(:TPlayer),
'     TPlayer slot 0x114 = BlockSave(), TPitch slot 0x6c = YardsToPixels(f)f.
'   Float constants 18.0 / 3.0 / 0.5 are immediates in this function's pool.
'   Dist2D and LogLine are the recovered module Functions (src/recovered_module).
' Body-only format: statements only; parameters are a0, a1, ...
'!Global g_ball:TBall
'!Global g_training_int03:Int
'!Global g_player_float14:Float
'!Global g_player_float15:Float
'!Global g_player_arr28:Int[]
'!Global g_Object46:TChannel
'!Global g_Object51:TSound
LogLine("CheckKeeperSave")
If Self.distancetogoal_own < TPitch.YardsToPixels(18.0) And (g_ball.velocity > 3.0 Or g_ball.controlledby <> Null) Then
	If g_training_int03 = 0 And g_ball <> Null And g_ball.lastkickedby <> Null And g_ball.lastkickedby.teamid <> Self.teamid Then
		PlaySound(g_Object51, g_Object46)
	End If
End If
If g_ball.controlledby <> Null Then
	BlockSave()
	Return 0
End If
If Self.currentanim = g_player_arr28 Then
	g_ball.NewController(Self)
ElseIf g_ball.velocity > g_player_float14 Then
	g_ball.Parry(Self)
Else
	If g_ball.lastkickedby <> Null And Dist2D(Self.x, Self.y, g_ball.lastkickedby.posxwhenkicked, g_ball.lastkickedby.posywhenkicked) < TPitch.YardsToPixels(g_player_float15) And g_ball.velocity > g_player_float14 * 0.5 Then
		g_ball.Parry(Self)
	Else
		g_ball.NewController(Self)
	End If
End If
Return 0
