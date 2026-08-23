' TScreen_Formation.ButtonPlay
' VA 0x0054D192   784 bytes   mode=reloc   byte-identical vs NSS5.exe
' KIND=Function, SIG ()i, slot 0x58   (static -- no implicit Self)
' ASSUMPTIONS
'  * Globals (names ours; declared types are load-bearing):
'      0x00C677DC g_screen_formation_int06:Int   0x00C677D8 g_screen_formation_int05:Int
'      0x00C5B210 g_engine_int20:Int             0x00C6F028 g_profile:TProfile
'      0x00C5B22C g_engine_fixture:TFixture      0x00C677B0 g_formation_team:TTeam
'      0x00C5B218 g_hometeam:TTeam             0x00C5B21C g_opponentteam:TTeam
'      0x00C5B364 g_engine_snd:TSound            0x00C5B348 g_engine_chan:TChannel
'    0x00C5B22C is TPlayer(guess) in globals_final.tsv; TFixture is what other bodies
'    established (TEngine.EndMatch / DrawScores / CheckShootOutComplete all use it), and
'    +0x3C = TFixture.level is the club-vs-nation switch read here.
'    0x00C5B218 is TKit(conflict) in the table; TTeam is what TBall.CheckSideLines uses
'    and is forced here by the assignment g_formation_team = g_opponentteam.
'    0x00C677DC is TPlayer(construction) in the table but the store is a bare
'    `mov dword [g],0` with no refcount traffic, so it is an Int (guide 11.2).
'  * TProfile slot 0x150 is CheckAchievement(i)i; 0x59 = 89.
'  * TBase_Team +0x54 `formation` is the tactic id written through myclub / mynation.
'  * TWO early returns, both measured: the g_screen_formation_int05 guard, and the
'    "opponent takes over" branch (mov eax,0 / jmp end after the store). Written as
'    an If/ElseIf chain the tail comes out 5 bytes short.
	'!Global g_screen_formation_int06:Int
	'!Global g_screen_formation_int05:Int
	'!Global g_engine_int20:Int
	'!Global g_profile:TProfile
	'!Global g_engine_fixture:TFixture
	'!Global g_formation_team:TTeam
	'!Global g_hometeam:TTeam
	'!Global g_opponentteam:TTeam
	'!Global g_engine_snd:TSound
	'!Global g_engine_chan:TChannel
	g_screen_formation_int06 = 0
	If g_screen_formation_int05 <> 0
		SetUpScreen(0)
		Return 0
	EndIf
	If g_engine_int20 = 0
		If g_profile.transferlisted = 0 And g_profile.captain = 0 And g_profile.selectedformatch = 1 And g_engine_fixture.level = 0 And g_profile.relationboss > 90 And g_profile.relationfans > 90 And g_profile.relationteam > 90
			g_profile.captain = 1
			g_profile.CheckAchievement(89)
			TScreen.DoMessage(GetText("CMESSAGE_CAPTAINCYWON"), 0, 0)
		ElseIf g_profile.captain <> 0
			If g_profile.relationboss < 60 Or g_profile.transferlisted > 0
				TScreen.DoMessage(GetText("CMESSAGE_CAPTAINCYLOSTBOSS"), 0, 0)
				g_profile.captain = 0
			ElseIf g_profile.relationfans < 60
				TScreen.DoMessage(GetText("CMESSAGE_CAPTAINCYLOSTFANS"), 0, 0)
				g_profile.captain = 0
			ElseIf g_profile.relationteam < 60
				TScreen.DoMessage(GetText("CMESSAGE_CAPTAINCYLOSTTEAM"), 0, 0)
				g_profile.captain = 0
			EndIf
		EndIf
	EndIf
	If g_engine_fixture.level = 0
		If g_profile.myclub <> Null
			g_profile.myclub.formation = TFormation.GetTacticIdByName(g_formation_team.formation.name)
		EndIf
	ElseIf g_profile.mynation <> Null
		g_profile.mynation.formation = TFormation.GetTacticIdByName(g_formation_team.formation.name)
	EndIf
	If g_formation_team = g_hometeam And g_opponentteam.controller = 1
		g_formation_team = g_opponentteam
		Return 0
	EndIf
	If g_engine_int20 > 0
		TScreen_MatchPaused.SetUpScreen(Null)
	Else
		TEngine.PauseEngine()
		PlaySound(g_engine_snd, g_engine_chan)
	EndIf
