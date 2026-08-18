' TScreen_Leagues.ButtonFixturesLast
' VA 0x005463b9   117 bytes   vtable slot 0x64   sig ()i
' byte-identical vs NSS5.exe (117/117, original length from Ghidra's inventory)
' same TCompetition global; 9999999 = 0x0098967F.
' Parameter names are not recoverable from the binary; a0/a1/... as emitted by the harness.
	Function ButtonFixturesLast:Int()
		'!Global g_leagues_comp:TCompetition
		If g_leagues_comp <> Null
			Select g_leagues_comp.comptype
				Case 1
					g_leagues_comp = g_leagues_comp.GetCupLastRound()
					SetUpLeagueFixtures(1)
				Default
					SetUpLeagueFixtures(9999999)
			End Select
		EndIf
	End Function
