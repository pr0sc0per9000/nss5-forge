' TEngine.UpdateReplay
' VA 0x004D4A25   121 bytes   vtable slot 0xa4   sig ()i
' byte-identical vs NSS5.exe (121/121, original length from Ghidra's inventory)
' class-table slots: 0x00c5baf0=TEngine+0xc0 UpdateSounds, 0x00c5badc=TEngine+0xac UpdateOffsetReplay(f), 0x00c5bac8=TEngine+0x98 UpdateReplayFrame(i), 0x00c5fb54=TPlayer+0x208 UpdateReplayAll(i), 0x00c5af48=TBall+0xb0 UpdateReplayAll(i), 0x00c5d96c=TPitch+0x40 Update, 0x00c5bad8=TEngine+0xa8 CheckReplayInput
' ASSUMPTION: Globals 0x00c5b2c8 and 0x00c5b2c4 declared :Int; 0x3dcccccd is the Float literal 0.1
	Function UpdateReplay:Int()
		'!Global g_replayframe:Int
		'!Global g_replaymaxframe:Int
		TEngine.UpdateSounds()
		TEngine.UpdateOffsetReplay(0.1)
		TEngine.UpdateReplayFrame(g_replayframe)
		TPlayer.UpdateReplayAll(g_replayframe)
		TBall.UpdateReplayAll(g_replayframe)
		TPitch.Update()
		g_replayframe = g_replayframe + 1
		If g_replayframe > g_replaymaxframe Then g_replayframe = g_replaymaxframe
		TEngine.CheckReplayInput()
	End Function
