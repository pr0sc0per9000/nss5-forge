' TPlayer.GetHumanNumber
' VA 0x004fb318   131 bytes   vtable slot 0x17c   sig ()i
' byte-identical vs NSS5.exe (131/131, original length from Ghidra's inventory)
' same TTeam globals as GetMyTeam.
' Parameter names are not recoverable from the binary; a0/a1/... as emitted by the harness.
	Method GetHumanNumber:Int()
		'!Global g_team1:TTeam
		'!Global g_team2:TTeam
		If g_team1 <> Null And g_team2 <> Null
			If g_team1.controller = 1 And g_team2.controller = 1
				If g_team1.id = teamid Then Return 0
				Return 1
			EndIf
		EndIf
	End Method
