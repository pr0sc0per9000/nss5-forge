' TPlayer.UpdatePassPotential
' VA 0x004EFB83   2277 bytes   KIND=Method, SIG ()i, class-table slot 0x7c
' byte-identical vs NSS5.exe (2277/2277, original length from Ghidra's inventory, mode=reloc)
'
' ASSUMPTIONS (module Global names are ours; the originals are unrecoverable; codegen
' depends only on the declared TYPE, never the name):
'   g_training_int03         0x00C6CF90 : Int      -- 4 = practice/training mode
'   g_ball                   0x00C5DEA4 : TBall    -- globals_final type_source=verified
'   g_player_int01           0x00C5B1FC : Int      -- match-state code
'   g_player_int50           0x00C6EFD4 : Int      -- the millisecond clock
'   g_player_int33           0x00C5DE70 : Int      -- ball/player height unit
'   g_player_int16           0x00C5D634 : Int      -- pitch x half-extent
'   g_player_int17           0x00C5D638 : Int      -- pitch y half-extent
'   g_engine_int104          0x00C5D65C : Int
'   g_contractoffer_tplayer  0x00C6F028 : TProfile (globals_corrections: TProfile, not TPlayer)
'
' Float constants read from .rdata via disassembly (a MATCH does not certify literal
' content): 5.0 40.0 15.0 8.0 30.0 20.0 40.0 60.0 16.0 1.0 10.0 6.0 5.0 30.0 55.0
' 5.0 30.0 35.0 12.5 10.0 25.0.
'
' CODEGEN NOTES (each cost an iteration; this body is the clean worked example)
'   * TPlayer.GetPlayerById(a0:Int) is called with Self.opponentid (+0x100), NOT
'     Self.teammateid (+0xF0) -- easy to confuse, only the disassembly (`push [ebx+0x100]`)
'     disambiguates them.
'   * A single strict RELATIONAL comparison (<, >, <=, >=) used as the SOLE condition of an
'     `If ... Then ... Else ...` whose two branches hold genuinely different code gets
'     compiled by bcc as the LOGICAL NEGATION of the written comparison, with the Then/Else
'     CONTENT swapped -- e.g. to reproduce the original's `setae` (>=) test with branches
'     {T, F}, the source must read `If x < y Then F Else T`. This is NOT needed when: the
'     comparison is an If-ONLY (no Else -- the innermost rung of every cascade here is
'     unnegated), the condition is a compound And/Or (every Or/And term here, including the
'     ones built from the very same relational operators, compiles direct), or the operator
'     is `=`/`<>` on an Int -- except `Self.goalside = 0` surprisingly DOES negate (it has
'     real code on both sides), so this is a shape rule, not an operator or equality rule.
'     Measured 9 separate call sites in this one body; all 9 needed it.
'   * `distanceball < 40.0 Then (distanceopponent > 15.0 Then Rand-add)` is not two nested
'     Ifs -- it is ONE compound `And`. The tell: the inner test's own skip-jump lands
'     exactly on the outer test's own `movzx`-merge point, i.e. the classic short-circuit
'     accumulator (guide 3f/10.3), not a second independent branch.
'   * The `g_training_int03 = 4` (practice) branch ends with an explicit `Return 0` even
'     though it is the last thing the Then-arm does -- omitting it merges its tail with the
'     "else" (match-logic) arm's own final return and costs 5 bytes.
'   * `myteam:TTeam = Self.GetMyTeam()` is a real Local: the virtual call happens exactly
'     once but `.rating` is read three times (75-check, 60-check, the /15 division).
'   * `heavy = (rating>75 And mod4000<1000) Or (rating>60 And mod6000<1000)` is written
'     inline, not through a Local -- the eax accumulator is reused as a CPU register, not a
'     BlitzMax variable (guide 17.1: 850 verified bodies with zero declared Locals still
'     save registers).
	Method UpdatePassPotential:Int()
		'!Global g_training_int03:Int
		'!Global g_ball:TBall
		'!Global g_player_int01:Int
		'!Global g_player_int50:Int
		'!Global g_player_int33:Int
		'!Global g_player_int16:Int
		'!Global g_player_int17:Int
		'!Global g_engine_int104:Int
		'!Global g_profile:TProfile
		If Self.matchstats.reds Or Self.selectionno < 1 Or Self.selectionno > 10
			Self.passpotential = 0
			Return 0
		EndIf
		Self.passpotential = 1
		If g_training_int03 = 4
			If g_ball <> Null And g_ball.controlledby = Self
				If Self.distancetoopponent < TPitch.YardsToPixels(5.0)
					Self.passpotential = Rand(70, 1)
				Else
					Self.passpotential = Rand(70, 90)
				EndIf
			Else
				If Self.passison = 0 Or Self.distancetoopponent < TPitch.YardsToPixels(5.0)
					Self.passpotential = 0
				Else
					Self.passpotential = Rand(90, 1)
				EndIf
			EndIf
			Return 0
		Else
			If g_ball <> Null
				If TEngine.SetPiece()
					If g_ball.setpiecetaker = Self
						Self.passpotential = 0
						Return 0
					EndIf
					If g_player_int01 = 2 And g_ball.setpiecebuddy = Self
						Self.passpotential = 10
						Return 0
					EndIf
				EndIf
				If g_ball.lastkickmatchstate = 2
					If g_ball.lastkickedby = Self Or g_ball.controlledby = Self
						Self.passpotential = 0
					Else
						If Self.distancetoball < TPitch.YardsToPixels(40.0) And Self.distancetoopponent > TPitch.YardsToPixels(15.0)
							Self.passpotential :+ Rand(3, 1)
						EndIf
					EndIf
				EndIf
			EndIf
			If Self.distancetoopponent > TPitch.YardsToPixels(8.0)
				Self.passpotential :+ 1
			Else
				If Self.distancetogoal_opp < TPitch.YardsToPixels(30.0)
					Local tm:TPlayer = TPlayer.GetPlayerById(Self.opponentid)
					If tm <> Null And tm.distancetogoal_own > Self.distancetogoal_opp
						Self.passpotential :+ 1
					EndIf
				EndIf
			EndIf
			If g_training_int03 = 0
				If Self.distancetogoal_opp < TPitch.YardsToPixels(20.0)
					Self.passpotential :+ 3
				Else
					If Self.distancetogoal_opp < TPitch.YardsToPixels(40.0)
						Self.passpotential :+ 2
					Else
						If Self.distancetogoal_opp < TPitch.YardsToPixels(60.0)
							Self.passpotential :+ 1
						EndIf
					EndIf
				EndIf
			EndIf
			If g_ball <> Null
				If g_ball.controlledby = Self
					If g_training_int03 = 0
						Self.passpotential :+ 1
					EndIf
					If Self.CleanThrough()
						Self.passpotential :+ 1
					EndIf
					If Self.distancetogoal_opp < TPitch.YardsToPixels(16.0)
						Self.passpotential :+ 1
					Else
						Local myteam:TTeam = Self.GetMyTeam()
						If (myteam.rating > 75 And (g_player_int50 * Self.teamid) Mod 4000 < 1000) Or (myteam.rating > 60 And (g_player_int50 * Self.teamid) Mod 6000 < 1000)
							Local clampf:Float = Float(myteam.rating / 15)
							ClampFloat(Varptr clampf, 1.0, 10.0)
							If Self.distancetoopponent < TPitch.YardsToPixels(clampf)
								Self.passpotential :- 1
							EndIf
						Else
							If Self.distancetoopponent > TPitch.YardsToPixels(6.0)
								Self.passpotential :+ 1
							EndIf
						EndIf
						If Abs(Self.x) > g_player_int16 - 15
							Self.passpotential :- 1
						EndIf
						If Abs(Self.y) > g_player_int17 - 15 And Abs(Self.x) > g_engine_int104
							Self.passpotential :- 2
						EndIf
					EndIf
					Return 0
				Else
					If g_ball.lastkickedby = Self And g_ball.kicktime < g_player_int50 + 1000
						Self.passpotential :- 1
					EndIf
					If g_ball.z > g_player_int33
						If Self.distancetoball < TPitch.YardsToPixels(5.0)
							Self.passpotential :- 2
						Else
							If Self.distancetoball < TPitch.YardsToPixels(30.0)
								Self.passpotential :+ 1
							Else
								If Self.distancetoball > TPitch.YardsToPixels(35.0)
									Self.passpotential = 0
								EndIf
							EndIf
						EndIf
					Else
						If Self.distancetoball < TPitch.YardsToPixels(5.0)
							Self.passpotential :- 2
						Else
							If Self.distancetoball < TPitch.YardsToPixels(30.0)
								Self.passpotential :+ 1
							Else
								If Self.distancetoball > TPitch.YardsToPixels(55.0)
									Self.passpotential :- 1
								EndIf
							EndIf
						EndIf
					EndIf
				EndIf
			EndIf
			If Self.goalside <> 0
				If Self.distancetogoal_own < Self.distancetogoal_opp Or Self.distancetoopponent < TPitch.YardsToPixels(12.5)
					Self.passpotential :- 1
				EndIf
			Else
				If TEngine.SetPiece()
					Self.passpotential :+ 1
				EndIf
			EndIf
			If Self.offside <> 0
				Self.passpotential :- 1
				If g_player_int01 <> 1
					Self.passpotential = 0
				EndIf
			EndIf
			If Self.passison = 0
				Self.passpotential :- 1
			EndIf
			If Self.newstar And Self.calling
				If g_profile.relationteam > 60
					Self.passpotential :+ 2
				Else
					If g_profile.relationteam > 30
						Self.passpotential :+ 1
					EndIf
				EndIf
			EndIf
			If g_player_int01 = 5
				If Self.distancetoball > TPitch.YardsToPixels(10.0) And Self.distancetogoal_opp > TPitch.YardsToPixels(25.0)
					Self.passpotential :- 3
				EndIf
			EndIf
		EndIf
	End Method
