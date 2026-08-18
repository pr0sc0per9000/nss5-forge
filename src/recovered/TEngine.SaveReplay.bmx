' TEngine.SaveReplay
' VA 0x004D5BC6   248 bytes
' byte-identical vs NSS5.exe (248/248, original length from Ghidra's inventory, mode=reloc)
' Verified through the oracle from scratch, with helper_map.record stubbed.
' Body-only format: statements only; parameters are a0, a1, ...
'!Global g_eng_replaysaved:Int
'!Global g_eng_hometeam:TTeam
'!Global g_eng_awayteam:TTeam
'!Global g_eng_fixture:TFixture
'!Global g_eng_msgint:Int
'!Global g_eng_font:TBitmapFont
'!Global g_pitch_int06:Int
'!Global g_pitch_int07:Int
'!Global g_weather_int02:Int
'!Global g_weather_int01:Int
If g_eng_replaysaved <> 0
	TScreenMessage.Create(0, 0, GetText("replay_Saved"), g_eng_msgint, g_eng_font, Null, 1.0, "FFFFFF")
Else
	g_eng_replaysaved = 1
	Local rep:String = TReplay.CreateReplay(g_eng_hometeam, g_eng_awayteam, g_eng_fixture.score1, g_eng_fixture.score2, g_pitch_int06, g_pitch_int07, g_weather_int02, g_weather_int01, g_eng_fixture.level)
	TScreenMessage.Create(0, 0, Lower(GetText("replay_Saved")) + ": " + rep, g_eng_msgint, g_eng_font, Null, 1.0, "FFFFFF")
EndIf
