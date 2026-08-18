' TTraining.UpdateTackling1
' VA 0x00580AE3   236 bytes   mode=reloc
' Driven through the oracle from scratch with helper_map.record stubbed; MATCH over the
' full Ghidra-authoritative length, every byte.
' Body-only format: statements only, parameters are a0, a1, ...
'!Global g_engine_team:TTeam
Local b:TBall = TBall.GetActiveBall()
If Not b
	Local p:TPlayer = Null
	For Local q:TPlayer = EachIn g_engine_team.squad
		If q.selectionno > 0
			p = q
			Exit
		EndIf
	Next
	b = TBall.CreateBall(Int(p.x), Int(p.y), 0)
EndIf
Local h:TPlayer = TPlayer.GetHumanPlayer()
If b.controlledby = h Or b.lasttouchedby = h
	Success()
EndIf
