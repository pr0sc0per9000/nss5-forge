' TPlayer.DoHeadingAI
' VA 0x004F20E2   500 bytes   vtable slot 0x94   sig ()i
' byte-identical vs NSS5.exe (500/500, original length from Ghidra's inventory, mode=reloc)
'
' 0x00C5D998 = TPitch + 0x6C = YardsToPixels(f)f. 0x00506049 = module AngleDiff(f,f,i)f.
' 0x00C5DEA4 is the ball (globals_final.tsv's TPlayer row for it is wrong -- see
' codegen-patterns 11.2); +0x78 = lasttouchedby, +0x20 = z.
' TJoy + 0x1C = kickbuttondown, +0x20 = kickbuttonhits; TPlayer + 0x158 = joy.
'
' `Double(30.0)` is load-bearing and NOT cosmetic. A bare `30.0` compared against
' AngleDiff's Float result is narrowed to a Float constant by bcc and emits
' `D9 05 <addr>` (fld dword); the original emits `DD 05 <addr>` (fld qword), i.e. the
' literal stayed Double. The two differ at byte 178 and nowhere else.
' The 1.1 multiplier one block later IS a Float (`fmul dword`), so the two spellings
' genuinely coexist in one function.
' Module Globals declared by this body (names are ours; the TYPES are load-bearing):
'   Global g_ball:TBall            (0x00C5DEA4)
'   Global g_ballspeedlimit:Int    (0x00C5DE70)
'   Global g_kickbuttonhits:Int    (0x00C6EFD4)
	Method DoHeadingAI:Int()
		'!Global g_ball:TBall
		'!Global g_ballspeedlimit:Int
		'!Global g_kickbuttonhits:Int
		If g_ball <> Null And g_ball.lasttouchedby = Self Then Return 0
		If g_ball.z < g_ballspeedlimit And Self.distancetogoal_own < TPitch.YardsToPixels(40.0) And AngleDiff(Self.direction, Self.directiontogoal_own, 1) < Double(30.0) Then
			Self.joy.kickbuttondown = 0
			Self.joy.kickbuttonhits = 0
			Return 0
		End If
		If Self.distancetoopponent < TPitch.YardsToPixels(4.0) Or Self.distancetogoal_opp < TPitch.YardsToPixels(18.0) Or Self.distancetogoal_own < TPitch.YardsToPixels(30.0) Or (Self.distancetoball < TPitch.YardsToPixels(2.0) And g_ball.z > g_ballspeedlimit * 1.1) Then
			Self.joy.kickbuttonhits = g_kickbuttonhits
			Self.joy.kickbuttondown = 1
		End If
	End Method
