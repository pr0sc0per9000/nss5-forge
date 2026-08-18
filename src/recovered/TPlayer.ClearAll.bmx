' TPlayer.ClearAll
' VA 0x004ed44e   319 bytes   vtable slot 0x34   sig ()i   KIND=Function
' byte-identical vs NSS5.exe (319/319, original length from Ghidra's inventory)
'
' GLOBAL NAMES ARE OURS; the DECLARED TYPES are load-bearing (they pick the vtable slot).
' The guard is the 12-byte `cmp dword [g], bbNullObject / je` form, i.e. `<> Null`, not `If Not`.
'!Global g_ball:TBall
'!Global g_allplayers:TList
	Function ClearAll:Int()
		g_ball = Null
		If g_allplayers <> Null
			For Local p:TPlayer = EachIn g_allplayers
				p.imgPlayer = Null
				p.joy = Null
				p.matchstats.Clear()
				p.matchstats = Null
				If p.replayframes <> Null Then p.replayframes.Clear()
			Next
			g_allplayers.Clear()
		EndIf
	End Function
