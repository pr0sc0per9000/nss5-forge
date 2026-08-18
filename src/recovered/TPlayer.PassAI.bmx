' TPlayer.PassAI
' VA 0x004f2c2b   126 bytes   vtable slot 0xa0   sig ()i
' byte-identical vs NSS5.exe (126/126, original length from Ghidra's inventory)
' the call must be TYPE-QUALIFIED (TPlayer.GetPlayerById) so bcc emits "call [classtable+0x168]"; unqualified inside a Method it becomes a Self-vtable call and misses. Object locals are not ref-counted by this bcc.
' Parameter names are not recoverable from the binary; a0/a1/... as emitted by the harness.
	Method PassAI:Int()
		Local p:TPlayer = TPlayer.GetPlayerById(teammateid)
		If p <> Null
			If p.passpotential > passpotential
				kickpower = 1.0
				joy.kickbuttonhits = 1
				joy.kickbuttondown = 0
				If p.newstar
					If p.calling
						p.icalledforball = 1
					Else
						p.icalledforball = 0
					EndIf
				EndIf
			EndIf
		EndIf
	End Method
