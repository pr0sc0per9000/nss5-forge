' TPlayer.ShootAI
' VA 0x004F28A1   906 bytes   vtable slot 0x9c   sig ()i
' byte-identical vs NSS5.exe (906/906, original length from Ghidra's inventory, mode=reloc)
'
' Picks the shot direction/power for the AI-controlled kick. g_player_int01 is the current
' set-piece/situation code read elsewhere in the engine (7/9 = one kind of restart, 5 =
' another, otherwise open play). g_player_int19 is a signed multiplier applied to
' GetShootingDirection() in two of the branches (penalty-style restart and the "ball is
' inside the cross zone" case); g_player_int17/g_player_int18 are pitch-geometry constants
' also used elsewhere (TPlayer.GetDistanceToByLine, TPlayer.UpdateMovement).
'
' NOTES ON FORM (load-bearing for the byte count):
'  * The Abs(x) > g_player_int18 + 35 / GetDistanceToByLine(1) < 45.0 test is a two-step
'    Bool accumulator (`ok = cond1 ; If ok Then ok = cond2`), not a short-circuit `And`
'    expression -- same shape as TBall.CheckAfterTouch's cascaded bVar locals. The compare
'    operand order (Abs(x) on the left) also matters: `Abs(x) > x` vs `x < Abs(x)` emit
'    different bytes (guide section 10.1).
'  * The two Rand()-only branches assign Self.kickpower directly from Rand(); the top-level
'    default (distancetogoal_opp / 5.0) uses no explicit Int() conversion -- storing a Float
'    expression into the Float field needs none.
	Method ShootAI:Int()
		'!Global g_player_int01:Int
		'!Global g_player_int17:Int
		'!Global g_player_int18:Int
		'!Global g_player_int19:Int
		' g_player_double06/07/08/09 original data-section values 28.0/-28.0/5.0/
		' -5.0 (0x00C79798/A0/A8/B0), read directly from NSS5.exe. g_player_double05
		' (0x00C79788) already reads -15.0 correctly (stored elsewhere in this body).
		' See codegen-patterns 21.1/21.3.
		'!Global g_player_double05:Double
		'!Global g_player_double06:Double = 28.0
		'!Global g_player_double07:Double = -28.0
		'!Global g_player_double08:Double = 5.0
		'!Global g_player_double09:Double = -5.0

		joy.direction = directiontogoal_opp + Rnd(-15.0, 15.0)
		kickpower = distancetogoal_opp / 5.0

		If g_player_int01 = 7 Or g_player_int01 = 9 Then
			joy.direction = directiontogoal_opp + Rnd(g_player_double07, g_player_double06)
			kickpower = Rand(15, 35)
		Else If g_player_int01 = 5 Then
			joy.direction = AngleTo(x, y, 0, g_player_int19 * GetShootingDirection()) + Rnd(g_player_double09, g_player_double08)
			kickpower = Rand(55, 70)
		Else
			If TPitch.InsideCrossZone(Int(x), Int(y), GetShootingDirection()) <> 0 Then
				joy.direction = AngleTo(x, y, 0, g_player_int19 * GetShootingDirection())
				kickpower = Rand(45, 50)
			Else If g_player_int01 = 1 Then
				Local ok:Int = Abs(x) > g_player_int18 + 35
				If ok Then ok = GetDistanceToByLine(1) < 45.0
				If ok Then
					joy.direction = AngleTo(x, y, 0, (g_player_int17 - 65) * GetShootingDirection())
				Else
					If distancetogoal_opp < TPitch.YardsToPixels(16.0) Then
						kickpower = Rand(15, 40)
					EndIf
					If distancetogoal_opp < TPitch.YardsToPixels(6.0) Then
						joy.direction = directiontogoal_opp
					EndIf
				EndIf
			EndIf
		EndIf

		kickdirection = joy.direction
		joy.kickbuttonhits = 1
		joy.kickbuttondown = 0
		Return 0
	End Method
