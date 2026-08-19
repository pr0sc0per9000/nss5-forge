' TPlayer.UpdateFundamentals
' VA 0x004EF0F2   1060 bytes   vtable slot 0x64   sig ()i
' byte-identical vs NSS5.exe (1060/1060, original length from Ghidra's inventory, mode=reloc)
' assumptions: TBall fields from object_model.json (x/y+0x18/0x1c, metax/metay+0x30/0x34,
' jumpx/jumpy+0x38/0x3c, divex/divey+0x40/0x44, z+0x20); TBall.CanSeePlayer(:TPlayer):Int at
' slot 0xc4. g_player_tplayer02:TBall, g_player_int17/int01/int32/int33:Int are Globals
' already used elsewhere in the corpus under these names (refcount-free plain movs). The
' jumpspotgood tests are short-circuit `And` chains, not sequential bool-reset statements --
' the disassembly has no "reset to False then branch" shape, just a straight cmp/je cascade.
' Two solo-relational operand-order flips were required (10.1): `Self.distancetoball > 1.0`
' (not `1.0 < ...`) and `g_player_tplayer02.z > Float(g_player_int33) [* 0.5]` (not the
' int33 term first) -- both proven by which operand the original's x87 code loads first.
	Method UpdateFundamentals:Int()
		'!Global g_player_int17:Int
		'!Global g_player_int01:Int
		'!Global g_player_int32:Int
		'!Global g_player_int33:Int
		'!Global g_ball:TBall
		Self.directiontogoal_own = Int(AngleTo(Self.x, Self.y, 0, Float(g_player_int17 * -Self.GetShootingDirection())))
		Self.distancetogoal_own = Int(Dist2D(Self.x, Self.y, 0, Float(g_player_int17 * -Self.GetShootingDirection())))
		Self.directiontogoal_opp = Int(AngleTo(Self.x, Self.y, 0, Float(g_player_int17 * Self.GetShootingDirection())))
		Self.distancetogoal_opp = Int(Dist2D(Self.x, Self.y, 0, Float(g_player_int17 * Self.GetShootingDirection())))
		If g_ball <> Null Then
			Self.distancetoball = Dist2D(Self.x, Self.y, g_ball.x, g_ball.y)
			If Self.distancetoball > 1.0 Then
				Self.directiontoball = Int(AngleTo(Self.x, Self.y, g_ball.x, g_ball.y))
			EndIf
			Self.distancetometaball = Dist2D(Self.x, Self.y, g_ball.metax, g_ball.metay)
			Self.directiontometaball = Int(AngleTo(Self.x, Self.y, g_ball.metax, g_ball.metay))
			Self.goalside = 0
			If Self.distancetogoal_own < Dist2D(g_ball.x, g_ball.y, 0, Float(g_player_int17 * -Self.GetShootingDirection())) Then
				Self.goalside = 1
			EndIf
			Self.jumpspotgood = 0
			If g_ball.jumpx <> 0.0 And Self.distancetoball < Float(g_player_int32 Shl 1) And Dist2D(Self.x, Self.y, g_ball.jumpx, g_ball.jumpy) < g_player_int32 And g_ball.z > Float(g_player_int33) Then
				Self.jumpspotgood = 1
			Else
				If g_ball.divex <> 0.0 And Self.distancetoball < Float(g_player_int32 Shl 1) And Dist2D(Self.x, Self.y, g_ball.divex, g_ball.divey) < g_player_int32 And g_ball.z > Float(g_player_int33) * 0.5 Then
					Self.jumpspotgood = 1
				EndIf
			EndIf
			Self.passison = g_ball.CanSeePlayer(Self)
		EndIf
		If g_player_int01 <> 8 Then
			Self.bonus = 0
		EndIf
		Self.UpdateOpponent()
		Return 0
	End Method
