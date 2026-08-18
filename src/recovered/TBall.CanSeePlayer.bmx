' TBall.CanSeePlayer
' VA 0x004cc489   345 bytes   vtable slot 0xc4   sig (:TPlayer)i
' byte-identical vs NSS5.exe (345/345, original length from Ghidra's inventory), verified
' with NSS5_NO_LEARN=1.
'
' Occlusion test: can the ball "see" TPlayer a0, or is some other player standing in the
' way? Walks g_players (the all-players TList, 0x00c5de10, same EachIn/downcast idiom as
' TPlayer.RenderAll), skipping a0 itself and Self.controlledby, and for every remaining
' candidate p further than 2 yards from the ball tests whether p (or p's predicted
' position, .metax/.metay, at half the radius) lies within `passcheckradius` yards of the
' ball-to-a0 line segment. Relies on two already-recovered module Functions:
' `Dist2D` (src/recovered_module/Dist2D.bmx) and `IsPointNearLine`
' (src/recovered_module/IsPointNearLine.bmx).
'
' ASSUMPTIONS
'   0x00c5de10 : TList  -- g_players, the all-players list (established elsewhere in the
'     corpus, e.g. TPlayer.RenderAll/UpdateAll).
'   0x00c5a4dc : Float  -- g_ball_float05, confirmed by TBall.SetUp.bmx to be
'     `passcheckradius` (ReadSettingFloat("incbin::Inc/Engine.ini","passcheckradius",0,10.0)).
'   `TPitch.YardsToPixels(f)f` (already in the corpus, VA 0x004e9fdb) reached here as a
'     class-table static call, `call dword ptr [0xc5d998]` in the original -- that address
'     IS TPitch's class table + slot 0x6c, not a separate function-pointer Global.
'   TBall.controlledby/x/y (0x70/0x18/0x1c) and TPlayer.x/y/metax/metay
'     (0x4c/0x50/0x84/0x88) from object_model.json.
'
' CODEGEN NOTES
'   * `p <> a0 And controlledby <> p` is a genuine compound And (flags-based short-circuit,
'     ONE combined `je` to the loop's Continue point) -- writing it as two separate
'     `If ... Then Continue` statements costs 14 extra bytes (two `jne/jmp` pairs vs one
'     shared `setne/movzx/cmp/je` chain).
'   * `If Dist2D(...) <= TPitch.YardsToPixels(2.0) Then Continue` -- the solo-relational
'     swap rule (codegen-patterns \167 21) applies even though this If has no Else in the
'     surface reading: written the "natural" way (`If Dist2D(...) > ... Then <body>`, no
'     Else) it compiles 2 bytes long with the wrong setcc (`setbe` instead of `seta`).
'     Negating to an early `Continue` matches exactly.
'   * The two IsPointNearLine guards are asymmetric on purpose: first compares `= 1`,
'     second compares `<> 0` against the same Int-returning function -- reproduced exactly
'     as found, not normalised to one style (law 3).
	Method CanSeePlayer:Int(a0:TPlayer)
		'!Global g_players:TList
		'!Global g_ball_float05:Float
		If controlledby = a0 Then Return 1
		Local viewdist:Float = TPitch.YardsToPixels(g_ball_float05)
		For Local p:TPlayer = EachIn g_players
			If p <> a0 And controlledby <> p
				If Dist2D(x, y, p.x, p.y) <= TPitch.YardsToPixels(2.0) Then Continue
				If IsPointNearLine(x, y, a0.x, a0.y, p.x, p.y, viewdist) = 1
					Return 0
				EndIf
				If IsPointNearLine(x, y, a0.x, a0.y, p.metax, p.metay, viewdist * 0.5) <> 0
					Return 0
				EndIf
			EndIf
		Next
		Return 1
	End Method
