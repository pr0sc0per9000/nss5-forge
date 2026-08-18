' TEngine.Update
' VA 0x004CFA6C   201 bytes   vtable slot 0x54   sig ()i
' byte-identical vs NSS5.exe (201/201, original length from Ghidra's inventory)
' assumptions: Globals 0x00C5B218 / 0x00C5B21C declared TTeam (slot 0x64 = TTeam.Update;
' globals_final flags 0x00C5B218 as a TKit/TTeam construction conflict -- TKit's 0x64 is a
' static Function so the instance call settles it as TTeam), 0x00C5B2BC and 0x00C5B210 Int.
' Sibling TEngine Functions are called unprefixed; cross-Type ones keep the Type prefix.
	Function Update:Int()
		'!Global g_hometeam:TTeam
		'!Global g_awayteam:TTeam
		'!Global g_matchframe:Int
		'!Global g_weathertime:Int
		UpdateSounds()
		UpdateOffset(0.1)
		g_matchframe = g_matchframe + 1
		RecordReplayFrame(g_matchframe)
		TPlayer.RecordReplayFramesAll(g_matchframe)
		TBall.RecordReplayFramesAll(g_matchframe)
		UpdateSetPieceReady()
		TTraining.Update()
		If g_hometeam <> Null Then g_hometeam.Update()
		If g_awayteam <> Null Then g_awayteam.Update()
		TPlayer.UpdateAll()
		TBall.UpdateAll()
		TPitch.Update()
		UpdateMatchTime()
		TWeather.Update(g_weathertime)
		TParticle.UpdateParticlesAll()
		CheckInput()
	End Function
