' TPromotionPlace.GetStringPlace
' VA 0x005262eb   134 bytes   vtable slot 0x48   sig ()$
' byte-identical vs NSS5.exe (134/134, original length from Ghidra's inventory)
' Default clause is INSIDE the Select here: its body is emitted inline right after the dispatch chain.
' Parameter names are not recoverable from the binary; a0/a1/... as emitted by the harness.
	Method GetStringPlace:String()
		Select place
			Case 100
				Return "100:AllTeams"
			Case 101
				Return "101:TeamsNotInCnt"
			Case 102
				Return "102:HighestNotInCnt"
			Case 103
				Return "103:AllWinningTeams"
			Case 104
				Return "104:AllLosingTeams"
			Case 105
				Return "105:WinTeamElseLosing"
			Case 106
				Return "106:WinTeamElseLeague"
			Case 107
				Return "107:TeamsInContinental"
			Case 108
				Return "108:LoseTeamElseLeague"
			Default
				Return String(place)
		End Select
	End Method
