' TScreen_Leagues.ButtonFixturesLeft
' VA 0x0054625b   121 bytes   vtable slot 0x58   sig ()i
' byte-identical vs NSS5.exe (121/121, original length from Ghidra's inventory)
' global 0x00c66f44 assumed Int (the current fixture page/round).
' Parameter names are not recoverable from the binary; a0/a1/... as emitted by the harness.
	Function ButtonFixturesLeft:Int()
		'!Global g_leagues_comp:TCompetition
		'!Global g_leagues_page:Int
		If g_leagues_comp <> Null
			Select g_leagues_comp.comptype
				Case 1
					g_leagues_comp = g_leagues_comp.GetCupPreviousRound()
					SetUpLeagueFixtures(1)
				Default
					SetUpLeagueFixtures(g_leagues_page - 1)
			End Select
		EndIf
	End Function
