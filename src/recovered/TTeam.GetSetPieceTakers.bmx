' TTeam.GetSetPieceTakers
' VA 0x004E0C0C   3336 bytes   mode=reloc   byte-identical vs NSS5.exe
' KIND=Method, SIG (i,:TBall)i, class-table slot 0x88
' ASSUMPTIONS -- the module Globals this body touches, declared below as '!Global pragmas:
'   g_training_int03:Int           0x00C6CF90  training-mode flag (bare Int store/load, no refcount traffic)
'   g_team_int03:Int               0x00C5DE14  set to 9 in cases 2 and 9 (bare Int store)
'   g_player_int17:Int             0x00C5D638  goal-line Y, multiplied by the shooting direction
'   g_options_int15:Int            0x00C5D278  free-kick-taker option (-1 / 0 / 1)
'   g_options_int16:Int            0x00C5D27C  corner-taker option (-1 / 0 / 1)
'   g_contractoffer_tplayer:TProfile 0x00C6F028 the human profile (captain/freekicks/corners/penalties/myclub)
'   g_engine_int20:Int             0x00C5B210  a counter; only Mod 2 / Mod 4 of it is read here
'   g_engine_int25:Int             0x00C5B238  squad-size counter, halved to pick the queue index
'   g_Object18:TTeam               0x00C5B21C  compared for identity against Self only. No call goes
'                                              through it, so the declared Type is NOT load-bearing
'                                              for these bytes; TTeam is what globals_final.tsv types
'                                              it as from its construction site.
'   TTeam   +0x08 id:Int, +0x1C squad:TList, +0x3C newstarselno:Int
'   TBall   +0x48 setpiecex:Int, +0x4C setpiecey:Int, +0x80 setpiecetaker:TPlayer, +0x84 setpiecebuddy:TPlayer
'   TPlayer +0x08 newstar:Int, +0x14 teamid:Int, +0xBC selectionno:Int,
'           +0x170 passing:Float, +0x178 shooting:Float, +0x188 matchstats:TStats_Match
'   TStats_Match +0x10 reds:Int ; TProfile +0xC8 freekicks, +0xCC corners, +0xE8 penalties,
'           +0x120 captain, +0x1D0 myclub:TClub ; TClub(TBase_Team) +0x24 strength:Int
'   downcast class table 0x00C5F94C = TPlayer ; 0x00C5FAB0 = TPlayer+0x164 GetHumanPlayer():TPlayer
'   0x00C5D988 = TPitch+0x5C InsidePenaltyBox(i,i,i)i
'   String literal 0x00C75CF8 read out of the exe with harness.read_string -> "GetSetPieceTakers"
'   Float constants 0x00C75D28=45.0, 0x00C75D2C/30/34=100.0 (all stored as 4-byte Float)
'
' NOTES ON SHAPE (each one is byte-observable, so each one is a claim):
'   * The dispatch is a Select, not an If/ElseIf chain: every `cmp ebx,<n> / je` sits back to
'     back ahead of all the bodies, and the no-match path is a trailing jmp (codegen-patterns
'     10.2). Case 0 and Case 1 are present in the source with EMPTY bodies -- each emits its
'     own 5-byte `jmp` to the end of the Select, which is why they cost 10 bytes.
'   * `If g_training_int03 And Self.newstarselno` is a short-circuit And that leaves the raw
'     second operand in eax; the guard then early-returns, it is not an If/Else.
'   * `Then Continue` (`74 02 EB xx`) vs a plain If-block is chosen per site to match the
'     original: cases 2/4/5/7/9 use Continue for the red-card/selection filters and a plain
'     If-block for the final assignment test.
'   * Case 9's outer `Repeat ... Forever` really is unbounded in the original -- the only way
'     out is the `Return 0` once the index matches.
'!Global g_training_int03:Int
'!Global g_team_int03:Int
'!Global g_player_int17:Int
'!Global g_options_int15:Int
'!Global g_options_int16:Int
'!Global g_contractoffer_tplayer:TProfile
'!Global g_engine_int20:Int
'!Global g_engine_int25:Int
'!Global g_Object18:TTeam
	Method GetSetPieceTakers:Int(a0:Int, a1:TBall)
		LogLine("GetSetPieceTakers")
		If g_training_int03 And Self.newstarselno
			a1.setpiecetaker = TPlayer.GetHumanPlayer()
			Return 0
		EndIf
		Local dir:Int = Self.GetShootingDirection()
		Select a0
		Case 0
		Case 1
		Case 2
			g_team_int03 = 9
			Self.squad.Sort(0)
			For Local p:TPlayer = EachIn Self.squad
				If p.matchstats.reds Or p.selectionno > 10 Then Continue
				If p.selectionno < 11
					a1.setpiecetaker = p
					Exit
				EndIf
			Next
			For Local p:TPlayer = EachIn Self.squad
				If p.matchstats.reds Or p.selectionno > 10 Then Continue
				If p.selectionno < 11 And a1.setpiecetaker <> p
					a1.setpiecebuddy = p
					Return 0
				EndIf
			Next
		Case 3
			a1.setpiecetaker = Self.GetPlayerNearestToXY(a1.setpiecex, a1.setpiecey, 0, Null, 0)
			a1.setpiecebuddy = Self.GetPlayerNearestToXY(a1.setpiecex, a1.setpiecey, 0, a1.setpiecetaker, 0)
			Return 0
		Case 4
			If TPitch.InsidePenaltyBox(a1.setpiecex, a1.setpiecey, -dir)
				For Local p:TPlayer = EachIn Self.squad
					If p.selectionno = 0
						a1.setpiecetaker = p
						Return 0
					EndIf
				Next
			EndIf
			If Dist2D(a1.setpiecex, a1.setpiecey, 0, g_player_int17 * dir) > 45.0 Or Rand(2, 1) = 1
				a1.setpiecetaker = Self.GetPlayerNearestToXY(a1.setpiecex, a1.setpiecey, 0, Null, 0)
			Else
				Local best:Float = 100.0
				For Local p:TPlayer = EachIn Self.squad
					If p.matchstats.reds Or p.selectionno = 0 Or p.selectionno > 10 Then Continue
					If p.newstar
						If g_options_int15 = -1 Then Continue
						If g_options_int15 = 0 And Rand(2, 1) = 1 Then Continue
					EndIf
					If p.shooting < best
						best = p.shooting
						a1.setpiecetaker = p
					EndIf
				Next
				Local hum:TPlayer = TPlayer.GetHumanPlayer()
				If hum <> Null And hum.teamid = Self.id And hum.selectionno < 11 And a1.setpiecetaker <> hum
					If g_options_int15 = 1 And (Rand(4, 1) = 1 Or g_contractoffer_tplayer.captain Or g_contractoffer_tplayer.freekicks > g_contractoffer_tplayer.myclub.strength)
						a1.setpiecetaker = hum
					ElseIf g_options_int15 = 0 And Rand(5, 1) = 1
						a1.setpiecetaker = hum
					EndIf
				EndIf
				If g_engine_int20 Mod 2 = 1
					a1.setpiecebuddy = Self.GetPlayerNearestToXY(a1.setpiecex, a1.setpiecey, 0, a1.setpiecetaker, 0)
				EndIf
			EndIf
		Case 5
			Local best:Float = 100.0
			For Local p:TPlayer = EachIn Self.squad
				If p.matchstats.reds Or p.selectionno = 0 Or p.selectionno > 10 Then Continue
				If p.newstar
					If g_options_int16 = -1 Then Continue
					If g_options_int16 = 0 And Rand(2, 1) = 1 Then Continue
				EndIf
				If p.passing < best
					best = p.passing
					a1.setpiecetaker = p
				EndIf
			Next
			Local hum:TPlayer = TPlayer.GetHumanPlayer()
			If hum <> Null And hum.teamid = Self.id And hum.selectionno < 11 And a1.setpiecetaker <> hum
				If g_options_int16 = 1 And (Rand(4, 1) = 1 Or g_contractoffer_tplayer.captain Or g_contractoffer_tplayer.corners > g_contractoffer_tplayer.myclub.strength)
					a1.setpiecetaker = hum
				ElseIf g_options_int16 = 0 And Rand(5, 1) = 1
					a1.setpiecetaker = hum
				EndIf
			EndIf
			If g_engine_int20 Mod 4 = 1
				a1.setpiecebuddy = Self.GetPlayerNearestToXY(a1.setpiecex, a1.setpiecey, 0, a1.setpiecetaker, 0)
			EndIf
			Return 0
		Case 6
			For Local p:TPlayer = EachIn Self.squad
				If p.selectionno = 0
					a1.setpiecetaker = p
					Return 0
				EndIf
			Next
		Case 7
			Local best:Float = 100.0
			For Local p:TPlayer = EachIn Self.squad
				If p.matchstats.reds Or p.selectionno = 0 Or p.selectionno > 10 Then Continue
				If p.shooting < best
					best = p.shooting
					a1.setpiecetaker = p
				EndIf
			Next
			Local hum:TPlayer = TPlayer.GetHumanPlayer()
			If hum <> Null And hum.teamid = Self.id And hum.selectionno < 11 And a1.setpiecetaker <> hum
				If g_contractoffer_tplayer.penalties > g_contractoffer_tplayer.myclub.strength
					a1.setpiecetaker = hum
				EndIf
			EndIf
		Case 9
			g_team_int03 = 9
			Self.squad.Sort(0)
			Local num:Int = g_engine_int25 / 2
			If g_Object18 = Self Then num :- 1
			Local i:Int = 0
			Repeat
				For Local p:TPlayer = EachIn Self.squad
					If p.matchstats.reds Or p.selectionno > 10 Then Continue
					If p.selectionno > 0 And p.selectionno < 11
						If i = num
							a1.setpiecetaker = p
							Return 0
						EndIf
						i :+ 1
					EndIf
				Next
			Forever
		End Select
	End Method
