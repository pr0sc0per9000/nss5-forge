' TEngine.UpdateSounds  -- KIND=Function, sig ()i, slot 0xC0
' VA 0x004D5CBE   810 bytes
' byte-identical vs NSS5.exe (810/810, original length from Ghidra's inventory, mode=reloc,
' reloc_masked=76)
'
' ASSUMPTIONS
'   Globals (names ours; addresses are the load-bearing fact):
'     g_engine_int13:Int              0x00C5B1CC  (gamestate; also called g_gamestate elsewhere)
'     g_opt_soundfx:Float             0x00C5D220  (matches TOptions.LoadOptions/SaveOptions)
'     g_player_float01:Float          0x00C5B338
'     g_ball_channel:brl.audio.TChannel  0x00C5A510  (matches TBall.CheckAdHoardings)
'     g_training_int03:Int            0x00C6CF90  (matches many other files)
'     g_chn_extra:brl.audio.TChannel  0x00C6F08C
'     g_chn1..g_chn4:brl.audio.TChannel  0x00C5B33C / 0x00C5B340 / 0x00C5B344 / 0x00C5B348
'         (same addresses TEngine.StopChannels names g_chn1..g_chn4; g_chn3 is the crowd/
'         atmosphere channel that also plays a random chant sound here)
'     g_pitch_int21:Int               0x00C5D69C  (pitch/stadium size, matches TCameraMan etc.)
'     g_player_int01:Int              0x00C5B1FC  (match-state code, matches TBall.Kick etc.)
'     g_engine_float17:Float          0x00C7435C
'     g_engine_double01:Double        0x00C74368  (Rnd's second/high argument).
'         original data-section value is 0.75, not 0 -- read directly out of NSS5.exe and
'         carried on the pragma (codegen-patterns 21.1/21.3).
'     g_engine_double02:Double        0x00C74370  (Rnd's first/low argument).
'         original data-section value is -0.75, not 0 -- same fix.
'     g_snd_chants:brl.audio.TSound[] 0x00C5B360  (matches TEngine.SetUp's g_snd_chants, 8
'         elements, indexed here by Rand(0,7))
'   Qualified brl.audio.TChannel/brl.audio.TSound: the harness's game-Type stub TChannel
'   (present in class_tables.tsv) collides with BRL.Audio's own TChannel, so the module type
'   must be named explicitly (same trick as TEngine.ResumeSounds.bmx).
'   Float constants read directly out of NSS5.exe's data section (never stored to, so
'   constants not Globals, per guide 21.2): 100.0, 0.5, 0.05, 0.1, 0.75, 0.85, 0.75, 0.05 (x4),
'   0.5, 0.75, 0.1.
'
' CODEGEN NOTES
'   The `g_training_int03 <> 0` guard is the solo-relational branch-swap (guide 21):
'   the ORIGINAL tests `g_training_int03 = 0 / je <big body>`, which is the compiled form of
'   `If g_training_int03 <> 0 Then TTraining.UpdateSounds() ; Return 0 Else <big body> EndIf`
'   -- negate the written comparison, swap Then/Else. The explicit `Return 0` inside the Then
'   arm is load-bearing: without it the arm falls into the function's trailing `Return 0` and
'   is 5 bytes short (no separate `mov eax,0` for that path).
'   Both `Select g_pitch_int21` blocks and the `Select g_player_int01` block are genuine
'   Selects, not If/ElseIf: every case's `je` target lands past the last compare (guide 10.2's
'   tell). The `g_player_int01` Select's Default arm is emitted FIRST in memory (right after
'   the last compare, before the Case 7/9/10/8/11 bodies), which matches Default being written
'   before the numbered Cases syntactically compiling to the fallthrough-no-match position.
'   Inside that Default arm, `g_chn3.Playing()` is read directly from the Global, but once not
'   playing a fresh `Local chn:brl.audio.TChannel = g_chn3` is taken and reused (register-
'   cached) for the `.SetPan()` call only -- the PlaySound channel argument re-reads the
'   Global `g_chn3` directly (`push dword ptr [g_chn3]`), not the Local. Mixed reuse within one
'   block; do not "clean up" by using the Local for both.
'!Global g_engine_int13:Int
'!Global g_opt_soundfx:Float
'!Global g_player_float01:Float
'!Global g_ball_channel:brl.audio.TChannel
'!Global g_training_int03:Int
'!Global g_chn_extra:brl.audio.TChannel
'!Global g_chn1:brl.audio.TChannel
'!Global g_pitch_int21:Int
'!Global g_chn2:brl.audio.TChannel
'!Global g_chn4:brl.audio.TChannel
'!Global g_player_int01:Int
'!Global g_engine_float17:Float
'!Global g_chn3:brl.audio.TChannel
'!Global g_engine_double01:Double = 0.75
'!Global g_engine_double02:Double = -0.75
'!Global g_snd_chants:brl.audio.TSound[]
	Function UpdateSounds:Int()
		If g_engine_int13 = 0 Then Return 0
		Local fVar1:Float = (g_opt_soundfx / 100.0) * 0.5
		If g_player_float01 < fVar1 Then g_player_float01 :+ 0.05
		If g_engine_int13 = 3 And g_player_float01 > 0.0 Then g_player_float01 :- 0.1
		ClampFloat(Varptr g_player_float01, 0.0, fVar1)
		g_ball_channel.SetVolume(g_player_float01)
		If g_training_int03 <> 0
			TTraining.UpdateSounds()
			Return 0
		Else
			g_chn_extra.SetVolume(0)
			g_chn1.SetVolume(g_player_float01)
			Select g_pitch_int21
			Case 0
				g_player_float01 = g_player_float01 * 0.75
			Case 1
				g_player_float01 = g_player_float01 * 0.85
			End Select
			g_chn2.SetVolume(g_player_float01 * 0.75)
			g_chn4.SetVolume(g_player_float01)
			Select g_player_int01
			Case 7
				g_engine_float17 :- 0.05
			Case 9
				g_engine_float17 :- 0.05
			Case 10
				g_engine_float17 :- 0.05
			Case 8
				g_engine_float17 :- 0.05
			Case 11
			Default
				If g_engine_float17 < fVar1 Then g_engine_float17 :+ 0.05
				If Not g_chn3.Playing()
					Local chn:brl.audio.TChannel = g_chn3
					Local fVar4:Float = Rnd(g_engine_double02, g_engine_double01)
					chn.SetPan(fVar4)
					PlaySound(g_snd_chants[Rand(0,7)], g_chn3)
				EndIf
			End Select
			Select g_pitch_int21
			Case 0
				g_engine_float17 = 0.0
			Case 1
				g_engine_float17 = g_engine_float17 * 0.5
			Case 2
				g_engine_float17 = g_engine_float17 * 0.75
			Case 3
			End Select
			If g_engine_int13 = 3 Then g_engine_float17 :- 0.1
			ClampFloat(Varptr g_engine_float17, 0.0, fVar1)
			g_chn3.SetVolume(g_engine_float17)
		EndIf
		Return 0
	End Function
