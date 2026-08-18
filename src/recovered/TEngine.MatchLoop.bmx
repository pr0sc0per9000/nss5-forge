' TEngine.MatchLoop
' VA 0x004CF671   432 bytes   vtable slot 0x4C   sig ()i   KIND=Function
' byte-identical vs NSS5.exe (432/432, original length from Ghidra's inventory)
' The main match frame loop: fixed-step accumulator, one Update per step, one render.
'
' ASSUMPTIONS
'  Direct calls resolved:
'    0x00505B91 LogLine (src/recovered_module/LogLine.bmx); literal at 0x00C73CA8 read out
'      of NSS5.exe with harness.read_string = "MatchLoop" (the usual entry-trace shape, 3g)
'    0x004A4860 timeGetTime -> MilliSecs()      (same call as TEngine.PauseEngine)
'    0x004BCB98 PlayTrack (src/recovered_module/PlayTrack.bmx), sig (i)i
'    0x0059F089 _brl_random_Rand -> Rand(2,1)
'    0x005B46C8 _brl_polledinput_AppTerminate -> AppTerminate()
'    0x004A4620 -> End                          (codegen-patterns 3d)
'    0x005B9690 _bbFloatToInt -> Int(...)
'  Class-table slot calls; the four TEngine ones are this Type's own table, so they are
'  written unqualified as sibling Functions (codegen-patterns 3d/8):
'    0x00C5BB18 TEngine+0xE8 ForcePositionResetAll()   0x00C5BA84 TEngine+0x54 Update()
'    0x00C5BAD4 TEngine+0xA4 UpdateReplay()            0x00C5BA80 TEngine+0x50 RenderGameEngine(f)
'    0x00C61CA4 TScreen+0x78 Update()   -- another Type, so qualified
'  Module Globals (names ours, types load-bearing):
'    0x00C6EFD4 g_matchclock   Int   0x00C6EFD8 g_pausedms      Int
'    0x00C6F030 g_pauseclock   Int   0x00C6F034 g_frameaccum    Int
'    0x00C6CF90 g_training     Int   0x00C5B1FC g_camsubmode    Int (11.2: Int, bare mov)
'    0x00C5B1CC g_gamestate    Int   0x00C5B2CC g_replayspeedup Int
'    0x00C5D234 g_matchspeed   Int   0x00C6F028 g_profile       TProfile (construction site)
'  TProfile field at +0x78 is contractwage (extracted/object_model.json).
'  Float constant at 0x00C73CC8 = 3.0.
' SHAPE NOTES (byte-observable)
'  * Rand's three-way dispatch is a SELECT with no Default -- the two compares are emitted
'    back to back followed by a jmp (codegen-patterns 10.2); so is the inner g_gamestate one.
'  * `If g_gamestate = 3 And g_replayspeedup` -- the right operand is a BARE truth test
'    (plain `mov eax,[g]` feeding the shared `cmp eax,0`), not `<> 0`.
'  * The while test is `g_frameaccum >= spd`: fild loads the accumulator FIRST, then fld spd,
'    then fxch/fucompp/setae -- so the accumulator is the left operand.
'  * `sub esp,8` = two slots: spd at [ebp-4] and the Int->Float conversion temp at [ebp-8].
'    spd is the function's only declared Local.
	Function MatchLoop:Int()
		'!Global g_matchclock:Int
		'!Global g_pausedms:Int
		'!Global g_pauseclock:Int
		'!Global g_frameaccum:Int
		'!Global g_training:Int
		'!Global g_camsubmode:Int
		'!Global g_profile:TProfile
		'!Global g_gamestate:Int
		'!Global g_replayspeedup:Int
		'!Global g_matchspeed:Int
		LogLine("MatchLoop")
		g_matchclock = MilliSecs() - g_pausedms
		g_pauseclock = g_matchclock
		If g_training > 0
			ForcePositionResetAll()
			g_camsubmode = 12
			If g_profile.contractwage = 0
				PlayTrack(3)
			Else
				Select Rand(2, 1)
				Case 1
					PlayTrack(3)
				Case 2
					PlayTrack(4)
				End Select
			EndIf
		Else
			PlayTrack(0)
		EndIf
		Repeat
			g_matchclock = MilliSecs() - g_pausedms
			g_frameaccum :+ (g_matchclock - g_pauseclock)
			g_pauseclock = g_matchclock
			Local spd:Float = g_matchspeed
			If g_gamestate = 3 And g_replayspeedup
				spd = spd * 3.0
			EndIf
			While g_frameaccum >= spd
				Select g_gamestate
				Case 1
					TScreen.Update()
				Case 2
					Update()
				Case 3
					UpdateReplay()
				End Select
				g_frameaccum = Int(g_frameaccum - spd)
			Wend
			RenderGameEngine(g_frameaccum / spd)
			If AppTerminate() Then End
		Until g_gamestate = 0
	End Function
