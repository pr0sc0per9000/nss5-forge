' TEngine.GetWinningClub
' VA 0x004d7b33   118 bytes   vtable slot 0xf8   sig ():TTeam
' byte-identical vs NSS5.exe (118/118, original length from Ghidra's inventory)
' global 0x00c5b22c is TFixture, not TPlayer as globals_named.tsv guesses: +0x2c/+0x30/+0x34/+0x38 are score1/score2/penscore1/penscore2 and the slots it is called through (0x58,0x68,0x70,0x74) all exist on TFixture too.
' Parameter names are not recoverable from the binary; a0/a1/... as emitted by the harness.
	Function GetWinningClub:TTeam()
		'!Global g_team1:TTeam
		'!Global g_team2:TTeam
		'!Global g_fixture:TFixture
		If g_fixture.score1 > g_fixture.score2 Then Return g_team1
		If g_fixture.score1 < g_fixture.score2 Then Return g_team2
		If g_fixture.penscore1 > g_fixture.penscore2 Then Return g_team1
		If g_fixture.penscore1 < g_fixture.penscore2 Then Return g_team2
		Return Null
	End Function
