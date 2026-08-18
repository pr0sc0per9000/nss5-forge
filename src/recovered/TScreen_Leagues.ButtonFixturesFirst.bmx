' TScreen_Leagues.ButtonFixturesFirst
' VA 0x005461e9   114 bytes   vtable slot 0x54   sig ()i
' byte-identical vs NSS5.exe (114/114, original length from Ghidra's inventory)
' global 0x00c66f5c is TCompetition (globals_named.tsv guessed TPlayer). "call [0x00c671a4]" is TScreen_Leagues.SetUpLeagueFixtures at class-table slot 0x50.
' Parameter names are not recoverable from the binary; a0/a1/... as emitted by the harness.
	Function ButtonFixturesFirst:Int()
		'!Global g_leagues_comp:TCompetition
		If g_leagues_comp <> Null
			Select g_leagues_comp.comptype
				Case 1
					g_leagues_comp = g_leagues_comp.GetCupFirstRound()
					SetUpLeagueFixtures(1)
				Default
					SetUpLeagueFixtures(1)
			End Select
		EndIf
	End Function
