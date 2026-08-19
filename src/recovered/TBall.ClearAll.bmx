' TBall.ClearAll
' VA 0x004C7736   394 bytes   mode=reloc
' byte-identical vs NSS5.exe
' Verified through the oracle from scratch with helper_map.record stubbed; MATCH over
' the full Ghidra-authoritative length, every byte.
' Body-only format: statements only, parameters are a0, a1, ...
'!Global g_activeball:TBall
'!Global g_balls:TList
g_activeball = Null
If g_balls <> Null
	For Local b:TBall = EachIn g_balls
		b.controlledby = Null
		b.lastkickedby = Null
		b.lasttouchedby = Null
		b.assistedby = Null
		b.setpiecetaker = Null
		b.setpiecebuddy = Null
		If b.replayframes <> Null
			b.replayframes.Clear()
		EndIf
	Next
	g_balls.Clear()
EndIf
