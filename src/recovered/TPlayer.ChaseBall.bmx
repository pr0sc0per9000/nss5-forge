' TPlayer.ChaseBall
' VA 0x004f94b9   488 bytes   vtable slot 0x128   sig (f,f,:TPlayer)i
' byte-identical vs NSS5.exe (488/488, original length from Ghidra's inventory, mode=reloc)
'
' Chases the ball toward a point (tx,ty) offset from the ball by the player's shooting
' direction. tx is always 0; ty = g_player_int17 * -GetShootingDirection(). Newstars (or
' when a2 is Null/slow) get a flat 1.0 speed multiplier; otherwise the multiplier tightens
' (1.08 down to 1.0) the more the player is already facing the target, via AngleDiff between
' the bearing to (tx,ty) and the player's own facing direction.
'
' NOTES ON FORM (all load-bearing for the byte count):
'  * tx is a genuine Local (not a literal 0) -- bcc converts it via the same Int->Float
'    staging dance at all four use sites, matching how a literal 0 would NOT compile.
'  * `newstar Or Not a2 Or a2.speed < 1.0` -- "Not a2" (not "a2 = Null") reproduces the
'    original's double-negation emission for the null test (guide 10.3).
'  * The second AngleTo() result needs its OWN Local (d2); inlining it into the AngleDiff()
'    call moves the literal `1` argument to the wrong place in the push sequence.
'  * desx/desy are `tx + Cos(bearing) * (dist / mult)`, in exactly that operand order --
'    both the addition order (tx first) and the multiplication order (Cos(bearing) first,
'    then dist/mult) are required to reproduce the original's evaluation order on the x87
'    stack; any other arrangement changes the byte count.
'!Global g_player_int17:Int
	Method ChaseBall:Int(a0:Float, a1:Float, a2:TPlayer)
		Local tx:Int = 0
		Local ty:Int = g_player_int17 * -GetShootingDirection()
		Local dist:Float = Dist2D(a0, a1, tx, ty)
		Local bearing:Float = ATan2(a1 - ty, a0 - tx)
		Local mult:Float
		If newstar Or Not a2 Or a2.speed < 1.0
			mult = 1.0
		Else
			mult = 1.08
			Local d1:Float = AngleTo(a0, a1, tx, ty)
			Local d2:Float = AngleTo(a0, a1, x, y)
			Local diff:Int = Int(AngleDiff(d1, d2, 1))
			If diff < 45 Then mult = 1.06
			If diff < 35 Then mult = 1.04
			If diff < 25 Then mult = 1.02
			If diff < 15 Then mult = 1.0
		EndIf
		desx = tx + Cos(bearing) * (dist / mult)
		desy = ty + Sin(bearing) * (dist / mult)
		Return 0
	End Method
