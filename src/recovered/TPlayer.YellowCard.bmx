' TPlayer.YellowCard
' VA 0x004F5333   314 bytes   mode=reloc
' Verified through the oracle from scratch with helper_map.record stubbed; MATCH over
' the full Ghidra-authoritative length, every byte.
' Body-only format: statements only, parameters are a0, a1, ...
'!Global g_homeTeam:TTeam
'!Global g_homeYellows:Int
'!Global g_awayYellows:Int
'!Global g_msgFont:TBitmapFont
'!Global g_yellowCardImg:TImage
'!Global g_secondYellowImg:TImage
'!Global g_secondYellowTime:Int
LogLine("Yellows:" + Self.matchstats.yellows)
If Self.teamid = g_homeTeam.id
	g_homeYellows :+ 1
Else
	g_awayYellows :+ 1
End If
If Self.matchstats.yellows = 0
	Self.AddStat(9, 0, 0, 0, 0)
	TScreenMessage.Create(0, 0, Lower(GetText("Yellow Card!")), 2500, g_msgFont, g_yellowCardImg, 2.0, "FFFFFF")
ElseIf Self.selectionno <> 0
	Self.AddStat(10, 0, 0, 0, 0)
	Self.AddStat(9, 0, 0, 0, 0)
	TScreenMessage.Create(0, 0, Lower(GetText("Second Yellow!")), g_secondYellowTime, g_msgFont, g_secondYellowImg, 2.0, "FFFFFF")
	Self.selectionno = 50
End If
