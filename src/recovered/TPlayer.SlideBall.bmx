' TPlayer.SlideBall
' VA 0x004F86D6   456 bytes   vtable slot 0x10C   sig ()i   KIND=Method
' byte-identical vs NSS5.exe (456/456, original length from Ghidra's inventory)
' ORACLE: mode=reloc  matched=456/456  STATUS=MATCH
' Original length from Ghidra's inventory. NSS5_NO_LEARN=1.
'
' ASSUMPTIONS -- module Global NAMES are ours; the DECLARED TYPES are load-bearing.
'   0x00C5DEA4 g_ball:TBall  (globals_final says TPlayer; codegen-patterns 11.2 corrects it
'                             to TBall -- slots 0x68 Kick, 0x84 NewController, 0x88
'                             KeeperHolding all resolve on TBall in vtable_map.tsv)
' Class-table static calls resolved:
'   0x00C5D998 = TPitch+0x6C    -> YardsToPixels(f)f
'   0x00C6AFC0 = TParticle+0x38 -> StarShower(i,i,$,$)i
' Self slots: 0xD8 = CheckFoul(:TPlayer)i, 0x228 = AddStat(i,f,f,f,f)i.
' Module Functions: LogLine (0x00505B91), GetText (0x004C5549), AngleDiff (0x00506049),
'   ClampFloat (0x00505F90, sig (*f,f,f) -- Var, hence Varptr at the call site).
' `Lower` is brl.retro's, named at 0x004A7410 by brl_functions.tsv.
' Float constants read out of the exe: 0x40400000 = 3.0 yards, 0x00C79EBC = 15.0 kickpower,
'   0xC1F00000/-30.0 and 0x41F00000/30.0 for the ClampFloat bounds.
' Literals read with harness.read_string: "SlideBall", "Tackle", "FF0099".
'
' NOTE  The first Or operand emits setne THEN sete (a doubled negation) -- that is the
'       spelling `Not g_ball.controlledby`, not `g_ball.controlledby = Null`, which would
'       emit a single sete (pattern 10.3 applied inside a boolean operand).
' NOTE  The second operand short-circuits on its own: cmp/setne/je before the teamid test.
' NOTE  StarShower's argument order comes from the pushes, right-to-left: "FF0099" is pushed
'       first, so it is the LAST parameter (guide 10, "Ghidra's argument list is not evidence").

'!Global g_ball:TBall

LogLine("SlideBall")
If g_ball.KeeperHolding() And Self.CheckFoul(g_ball.controlledby) Then Return 0
If Not g_ball.controlledby Or (g_ball.controlledby And g_ball.controlledby.teamid <> Self.teamid)
	If g_ball.lastkickedby <> Self And Self.distancetoopponent < TPitch.YardsToPixels(3.0)
		Self.AddStat(7,0,0,0,0)
		If Self.newstar
			TParticle.StarShower(Int(Self.x), Int(Self.y), Lower(GetText("Tackle")), "FF0099")
		EndIf
	EndIf
EndIf
g_ball.NewController(Self)
Self.kickpower = 15.0
Local a:Float = AngleDiff(Self.direction, Self.joy.direction, 0)
ClampFloat(Varptr a, -30.0, 30.0)
g_ball.Kick(Self, Self.direction + a, Self.kickpower, 1, -1)
