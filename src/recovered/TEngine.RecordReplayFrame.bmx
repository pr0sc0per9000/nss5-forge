' TEngine.RecordReplayFrame
' VA 0x004D46AB   185 bytes
' byte-identical vs NSS5.exe (185/185, original length from Ghidra's inventory, mode=reloc)
' Verified through the oracle from scratch, with helper_map.record stubbed.
' Body-only format: statements only; parameters are a0, a1, ...
'!Global g_replay:TList
'!Global g_player_int01:Int
'!Global g_engine_int26:Int
'!Global g_weather_float01:Float
'!Global g_engine_int47:Int
'!Global g_engine_int165:Int
If Not g_replay Then Return 0
Local f:TReplayFrame = New TReplayFrame
f.frametime = a0
f.id = g_player_int01
f.obtype = 3
f.clubid = g_engine_int26
f.alph = g_weather_float01
g_replay.AddLast(f)
While TReplayFrame(g_replay.First()).frametime < a0 - g_engine_int47 / g_engine_int165
	g_replay.RemoveFirst()
Wend
