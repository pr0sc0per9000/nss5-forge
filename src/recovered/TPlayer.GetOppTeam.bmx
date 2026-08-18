' TPlayer.GetOppTeam
' VA 0x004fb2a3   117 bytes   vtable slot 0x178   sig ():TTeam
' byte-identical vs NSS5.exe (117/117, original length from Ghidra's inventory)
' same two TTeam globals as GetMyTeam, returned crossed over.
' Parameter names are not recoverable from the binary; a0/a1/... as emitted by the harness.
	Method GetOppTeam:TTeam()
		'!Global g_team1:TTeam
		'!Global g_team2:TTeam
		If g_team1 <> Null And g_team1.id = teamid Then Return g_team2
		If g_team2 <> Null And g_team2.id = teamid Then Return g_team1
		Return Null
	End Method
