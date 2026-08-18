' TBall.CanSeePlayer  -- Method, slot 0xc4, sig (:TPlayer)i
' VA 0x004CC489   345 bytes
' Flagged blocked on module Function
' 0x005061DD (called PointNearSegment here) by three earlier passes.
'
' UNBLOCKED: that Function is IsPointNearLine (src/recovered_module/IsPointNearLine.bmx),
' now byte-identical (218/218, verified NSS5_NO_LEARN=1). Rewrote this body against it and
' against the score report's first-difference offset (byte 32 -- the FF 35/FF 15/A1 global
' and call addresses immediately after the `If Self.controlledby = a0` guard), which was
' the earlier draft calling the unverified PointNearSegment stub and using the wrong
' Global name/shape for the loop guard and the two occlusion checks. Score was 314/345
' (91.0%) before this pass.
'
' CHANGES FROM THE PRIOR DRAFT:
'   * PointNearSegment -> IsPointNearLine (the real, now-verified module Function).
'   * DAT_00c5a4dc named g_seeRadius (uncertain) -> g_ball_float05, the CERTAIN name
'     confirmed by explain_global.py (TBall.SetUp.bmx: passcheckradius setting).
'   * `If p = a0 Or Self.controlledby = p Then Continue` (early-exit form) -> a single
'     compound `If p <> a0 And controlledby <> p` wrapping the loop body. Per codegen
'     notes on this construct elsewhere in the corpus, the compound And is a genuine
'     flags-based short-circuit (one combined branch); splitting it into an Or/Continue
'     costs extra branch bytes and is what pushed the two calls after it to the wrong
'     addresses (every following global/call reference shifts once a branch is added or
'     removed upstream of it).
'   * Dropped the explicit `Self.` qualifiers on controlledby/x/y -- matches the
'     unqualified field-access idiom used throughout the rest of this corpus (TBall's own
'     fields are unqualified everywhere else in src/recovered/TBall.*.bmx).
'   * `PointNearSegment(...) Then Return 0` (uniform truthy test on both calls) -> the
'     first IsPointNearLine call compares `= 1`, the second `<> 0` against the same
'     Int-returning function -- asymmetric on purpose, reproduced as found (project law:
'     don't normalise divergent-looking but equivalent original code to one style).
'   * Local r -> Local viewdist (name only; no byte effect, but matches the
'     already-verified idiom for this exact quantity elsewhere).
'
' Ghidra decompile of 0x004CC489, every offset resolved:
'   param_1 = Self (TBall), param_2 = a0:TPlayer (the argument)
'   Self.controlledby = TBall+0x70 (:TPlayer)
'   Self.x/y = TBall+0x18/+0x1c
'   TPlayer.x/y = +0x4c/+0x50, TPlayer.metax/metay = +0x84/+0x88 (object_model.json)
'   PTR_DAT_00c5de10 = g_players:TList (CERTAIN, explain_global.py; 28 bodies unanimous)
'   PTR_FUN_00c5d998 = TPitch classtable+0x6C = TPitch.YardsToPixels(f):f (confirmed in
'     src/recovered/TDummy.CheckHit.bmx)
'   DAT_00c5a4dc = g_ball_float05:Float (CERTAIN, explain_global.py) = passcheckradius
'   FUN_00505da2 = Dist2D (src/recovered_module/Dist2D.bmx)
'   FUN_004a8f60 = _bbObjectDowncast (downcast NextObject()'s result to TPlayer)
'   &DAT_005c9c80 = Null
'   FUN_005061dd = IsPointNearLine (src/recovered_module/IsPointNearLine.bmx)
'   _DAT_00c72aa0 = 0.5 (float constant read from the exe .data)
'
' i.e. "can this ball see player a0" -- true unless some OTHER player (not a0, not the
' ball's current controller, and further than 2 yards from the ball) is standing close
' enough to the ball-to-a0 sightline (using either their normal position or their
' smoothed "meta" position at half radius) to block it.
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
