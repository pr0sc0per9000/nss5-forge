' TPlayer.GetMyTeam
' VA 0x004fb22e   117 bytes   vtable slot 0x174   sig ():TTeam
' byte-identical vs NSS5.exe (117/117, original length from Ghidra's inventory)
' globals 0x00c5b218 / 0x00c5b21c typed TTeam; +8 id and +0x18 controller confirm the layout.
' Parameter names are not recoverable from the binary; a0/a1/... as emitted by the harness.
	Method GetMyTeam:TTeam()
		'!Global g_team1:TTeam
		'!Global g_team2:TTeam
		If g_team1 <> Null And g_team1.id = teamid Then Return g_team1
		If g_team2 <> Null And g_team2.id = teamid Then Return g_team2
		Return Null
	End Method
