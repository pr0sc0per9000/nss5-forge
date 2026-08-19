' TEngine.SkipMatchTime   (KIND=Function -- static, no Self)
' VA 0x004D6A80   2223 bytes   class-table slot 0xDC   sig ()i
' byte-identical vs NSS5.exe (2223/2223, original length from Ghidra's inventory)
' ORACLE: mode=reloc  matched=2223/2223  reloc_masked=137  STATUS=MATCH
' g_engine_int17's original data-section value is 1750 (0x00C5B1F8), read
' directly from NSS5.exe. See codegen-patterns 21.1/21.3.

' The "fast-forward the match clock" simulator: called repeatedly (or in one shot) to
' advance g_engine_clock, roll random on/off-ball events for every selected outfield
' player, resolve the next scripted substitution, and hand back to TEngine.MatchLoop
' once the current half ends or the requested skip-to minute is reached.

' ASSUMPTIONS -- module Global NAMES are ours except g_engine_fixture (already established
' by TEngine.CheckShootOutComplete.bmx); the DECLARED TYPES are load-bearing.
'   0x00C6CF90 g_training:Int          0x00C5B208 g_engine_half:Int
'   0x00C5B1FC g_matchstate:Int        0x00C5B218 g_hometeam:TTeam
'   0x00C5B21C g_awayteam:TTeam        0x00C5B22C g_engine_fixture:TFixture
'   0x00C5B210 g_engine_clock:Int      0x00C5B228 g_engine_int22:Int  (skip-to-minute target)
'   0x00C5DE10 g_players:TList         0x00C6F028 g_profile:TProfile
'   0x00C64218 g_screen_newplayer_flag:Int (set when a newstar's contractwage is 0)
'   0x00C5D634 g_player_int16:Int      (pitch metric, also used as -offset for set-piece Y)
'   0x00C5B1F8 g_engine_int17:Int      (read-only; Shl 1 into TScreenMessage.Create's 4th arg)
'   0x00C5B1C4 g_Object15:TBitmapFont  0x00C5B2F4 g_Object29:TImage  0x00C5B2F8 g_Object30:TImage
'   0x00C5B25C g_engine_float07:Float  0x00C5B260 g_engine_float08:Float  (possession-time
'     accumulators, home/away, each :+ 1.0 per tick; constants at 0xC744BC/0xC744C0 = 1.0)
'   0x00C5B264/26C/268/270 g_engine_int29/31/30/32:Int  -- home/away shot->goal funnel counters
'   0x00C5B274/278 g_engine_int33/34:Int  0x00C5B27C/280 g_engine_int35/36:Int
'   0x00C5B28C/290 g_engine_int39/40:Int  -- bare per-tick rare-event counters, no further
'     action taken in this function.
' Fields (extracted/object_model.json): TTeam.rating(0x14) controller(0x18);
'   TFixture.score1(0x2c) score2(0x30) penscore1(0x34) penscore2(0x38);
'   TProfile.contractwage(0x78); TPlayer.selectionno(0xbc) matchstats(0x188).
' Class-table slot calls, TEngine's own written unqualified (guide 3d/8):
'   0x00C5BB30 TEngine+0x100 PauseEngine()      0x00C5BB10 TEngine+0xE0 EndMatch()
'   0x00C5BB04 TEngine+0xD4 DoYourSubstitutionOff(i)  0x00C5BB00 TEngine+0xD0 DoYourSubstitutionOn()
'   0x00C5BAA0 TEngine+0x70 SetUpSetPiece(i,i,i,i)    0x00C5BB18 TEngine+0xE8 ForcePositionResetAll()
'   0x00C5BABC TEngine+0x8C DoHalfEnds()
'   Other Types, qualified: TPlayer+0x164 GetHumanPlayer():TPlayer; TPlayer+0x160
'     GetShootingDirection()i; TPlayer+0x228 AddStat(i,f,f,f,f)i; TTeam+0x9C
'     SelectRandomPlayer(i,i,i,i):TPlayer; TStats_Match+0x38 AddStat(i,i,i,i,f,i)i;
'     TScreenMessage+0x40 ClearAll(i); TScreenMessage+0x30 Create(i,i,$,i,:TBitmapFont,
'     :TImage,f,$)i; TPitch+0x6C YardsToPixels(f)f.
'   0x004C5549 is the recovered module Function GetText (see TCompetition.GetStringCompType).
'   0x0059F089 _brl_random_Rand -- Rand(a,b)i.
' Literals read out of the exe with harness.read_string: 0x00C7447C "Substitution",
'   0x00C5D680 "FFFFFF" (a hex colour, spelled as a bare literal, not a Global).
'
' SHAPE NOTES (byte-observable)
'   * The outer test is `If g_training <> 0 ... Else ... EndIf`, NOT `= 0` -- the SMALL
'     (contractwage) branch is the fall-through side and needs its OWN `Return 0`; writing
'     the branches the other way round costs a short-vs-near jump (+4 bytes) at the very top.
'   * `For Local p:TPlayer = EachIn g_players` already emits the downcast-null-skip on its
'     own (guide 10.6) -- an explicit `If p <> Null` wrapper duplicates the check (+12 bytes).
'   * The GetHumanPlayer() + GetShootingDirection() tail is `If hp2 <> Null` wrapping a
'     `Select` with no Default, followed by a single trailing `Return 0` shared by the
'     Null case, both Cases, and the no-match fallthrough -- NOT an early `If hp2 = Null
'     Then Return 0` (that materialises a second, separate return and costs +6 bytes).
'   * `hp And hp.selectionno > 0 And hp.selectionno < 11` uses the bare object truth test
'     (setne/movzx), matching TEngine.SkipTime's identical GetHumanPlayer guard.
'   * The set-piece Y/X pair is written as fully inline expressions -- no named Locals --
'     `SetUpSetPiece(4, Rand(2,1), Int(TPitch.YardsToPixels(Rand(-30,30))),
'     Int(TPitch.YardsToPixels(Rand(-25,25))))`; the frame's single stack slot (`sub esp,4`)
'     is bcc's own Int->Float conversion temp, reused four times, not a user Local.
'   * `Select Rand(4,1) / Case 1 / Case 2 (nested Select Rand(2,1)) / Default` -- the
'     outer Select's Cases 3 and 4 are not distinguished; both fall into Default.
'   * The home/away possession pick is one boolean expression, not nested Ifs:
'     `(g_hometeam.rating >= g_awayteam.rating And coin) Or
'      (g_hometeam.rating < g_awayteam.rating And Not coin)`, with `coin` a Local set by
'     `coin = 0 : If Rand(5,1) > 2 Then coin = 1` computed once, reused in both clauses.
'   * ORIGINAL BUG (VA 0x004D7147 / 0x004D71D1): the assist-lookup after an AWAY goal calls
'     `g_hometeam.SelectRandomPlayer(...)`, not `g_awayteam` -- reproduced faithfully, not
'     fixed. Verified against the raw bytes twice (mov eax,[0x00C5B218] both times).
'   * `Select g_engine_half / Case 1..4 / If g_engine_clock > {45,90,105,120} Then
'     DoHalfEnds()` -- four separate Cases, no Default.
'   * The `g_matchstate = 9` shootout coin-flip reassigns `penscore1`/`penscore2`
'     reciprocally, the same pattern as the `g_engine_half = 5` seed at function entry.

	Function SkipMatchTime:Int()
		'!Global g_training:Int
		'!Global g_engine_half:Int
		'!Global g_matchstate:Int
		'!Global g_hometeam:TTeam
		'!Global g_awayteam:TTeam
		'!Global g_engine_fixture:TFixture
		'!Global g_engine_clock:Int
		'!Global g_engine_int22:Int
		'!Global g_players:TList
		'!Global g_profile:TProfile
		'!Global g_screen_newplayer_flag:Int
		'!Global g_player_int16:Int
		'!Global g_engine_int17:Int = 1750
		'!Global g_font_match_m:TBitmapFont
		'!Global g_Object29:TImage
		'!Global g_Object30:TImage
		'!Global g_engine_float07:Float
		'!Global g_engine_float08:Float
		'!Global g_engine_int29:Int
		'!Global g_engine_int30:Int
		'!Global g_engine_int31:Int
		'!Global g_engine_int32:Int
		'!Global g_engine_int33:Int
		'!Global g_engine_int34:Int
		'!Global g_engine_int35:Int
		'!Global g_engine_int36:Int
		'!Global g_engine_int39:Int
		'!Global g_engine_int40:Int
		PauseEngine()
		If g_training <> 0
			EndMatch()
			If g_profile.contractwage = 0
				g_screen_newplayer_flag = 1
			EndIf
			Return 0
		Else
			If g_engine_half = 5
				g_matchstate = 11
				If g_hometeam.controller = 1
					g_engine_fixture.penscore1 = Rand(2,5)
					g_engine_fixture.penscore2 = g_engine_fixture.penscore1 + 1
				Else
					g_engine_fixture.penscore2 = Rand(2,5)
					g_engine_fixture.penscore1 = g_engine_fixture.penscore2 + 1
				EndIf
			Else
				Local hp:TPlayer = TPlayer.GetHumanPlayer()
				If hp And hp.selectionno > 0 And hp.selectionno < 11
					DoYourSubstitutionOff(0)
					TScreenMessage.ClearAll(0)
				EndIf
				Repeat
					g_engine_clock :+ 1
					If g_engine_int22 > 0 And g_engine_clock = g_engine_int22
						DoYourSubstitutionOn()
						Select Rand(3,1)
							Case 1
								SetUpSetPiece(4, Rand(2,1), Int(TPitch.YardsToPixels(Rand(-30,30))), Int(TPitch.YardsToPixels(Rand(-25,25))))
							Case 2
								SetUpSetPiece(3, Rand(2,1), -g_player_int16, Int(TPitch.YardsToPixels(Rand(-25,25))))
							Case 3
								SetUpSetPiece(3, Rand(2,1), g_player_int16, Int(TPitch.YardsToPixels(Rand(-25,25))))
						End Select
						ForcePositionResetAll()
						TScreenMessage.ClearAll(0)
						Local hp2:TPlayer = TPlayer.GetHumanPlayer()
						If hp2 <> Null
							Select hp2.GetShootingDirection()
								Case -1
									TScreenMessage.Create(0, 0, Lower(GetText("Substitution")), g_engine_int17 Shl 1, g_font_match_m, g_Object29, 1.0, "FFFFFF")
								Case 1
									TScreenMessage.Create(0, 0, Lower(GetText("Substitution")), g_engine_int17 Shl 1, g_font_match_m, g_Object30, 1.0, "FFFFFF")
							End Select
						EndIf
						Return 0
					Else
						For Local p:TPlayer = EachIn g_players
							If Rand(4,1) = 1 And p.selectionno > 0 And p.selectionno < 11 And p.matchstats
								Select Rand(4,1)
									Case 1
										p.matchstats.AddStat(6, g_engine_clock, 0, 0, 0.0, 0)
									Case 2
										Select Rand(2,1)
											Case 1
												p.matchstats.AddStat(7, g_engine_clock, 0, 0, 0.0, 0)
											Case 2
												p.matchstats.AddStat(8, g_engine_clock, 0, 0, 0.0, 0)
										End Select
									Default
										p.matchstats.AddStat(3, g_engine_clock, 0, 0, 0.0, 0)
								End Select
							EndIf
						Next
						Local coin:Int = 0
						If Rand(5,1) > 2 Then coin = 1
						If (g_hometeam.rating >= g_awayteam.rating And coin) Or (g_hometeam.rating < g_awayteam.rating And Not coin)
							g_engine_float07 :+ 1.0
							If Rand(4,1) = 1
								g_engine_int29 :+ 1
								Local scorer:TPlayer = g_hometeam.SelectRandomPlayer(0,0,1,1)
								scorer.AddStat(2,0,0,0,0)
								If Rand(3,1) = 1
									g_engine_int31 :+ 1
									If Rand(3,1) = 1
										g_engine_fixture.score1 :+ 1
										scorer.AddStat(5,0,0,0,0)
										Local assister1:TPlayer = g_hometeam.SelectRandomPlayer(0,0,1,1)
										If assister1 <> scorer
											assister1.AddStat(4,0,0,0,0)
										EndIf
									EndIf
								EndIf
							EndIf
						Else
							g_engine_float08 :+ 1.0
							If Rand(4,1) = 1
								g_engine_int30 :+ 1
								Local scorer2:TPlayer = g_awayteam.SelectRandomPlayer(0,0,1,1)
								scorer2.AddStat(2,0,0,0,0)
								If Rand(3,1) = 1
									g_engine_int32 :+ 1
									If Rand(3,1) = 1
										g_engine_fixture.score2 :+ 1
										scorer2.AddStat(5,0,0,0,0)
										' ORIGINAL BUG (VA 0x004D7147): uses g_hometeam here too, not g_awayteam.
										Local assister2:TPlayer = g_hometeam.SelectRandomPlayer(0,0,1,1)
										If assister2 <> scorer2
											assister2.AddStat(4,0,0,0,0)
										EndIf
									EndIf
								EndIf
							EndIf
						EndIf
						Select Rand(30,1)
							Case 1
								g_engine_int33 :+ 1
								g_awayteam.SelectRandomPlayer(0,1,1,1).AddStat(11,0,0,0,0)
							Case 2
								g_engine_int34 :+ 2
								g_hometeam.SelectRandomPlayer(0,1,1,1).AddStat(11,0,0,0,0)
						End Select
						Select Rand(45,1)
							Case 1
								g_engine_int35 :+ 1
							Case 2
								g_engine_int36 :+ 2
						End Select
						Select Rand(45,1)
							Case 1
								g_engine_int39 :+ 1
							Case 2
								g_engine_int40 :+ 2
						End Select
						Select g_engine_half
							Case 1
								If g_engine_clock > 45 Then DoHalfEnds()
							Case 2
								If g_engine_clock > 90 Then DoHalfEnds()
							Case 3
								If g_engine_clock > 105 Then DoHalfEnds()
							Case 4
								If g_engine_clock > 120 Then DoHalfEnds()
						End Select
						If g_matchstate = 9
							g_matchstate = 11
							If Rand(2,1) = 1
								g_engine_fixture.penscore2 = g_engine_fixture.penscore1 + 1
							Else
								g_engine_fixture.penscore1 = g_engine_fixture.penscore2 + 1
							EndIf
						EndIf
						TScreenMessage.ClearAll(0)
					EndIf
				Until g_matchstate = 11
			EndIf
			EndMatch()
		EndIf
		Return 0
	End Function
