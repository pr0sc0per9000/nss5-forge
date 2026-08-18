' TPlayer.UpdateTeamMateId
' VA 0x004ef516   259 bytes   vtable slot 0x68   sig ()i
' byte-identical vs NSS5.exe (259/259, original length from Ghidra's inventory)
' assumes: 0x00C5B1FC is Int (globals_final says TPlayer; it is compared to 2). 0x00C5DEA4 is TBall, NOT TPlayer as globals_final claims - field +0x84 is dereferenced at +0x10, which is TBall.setpiecebuddy:TPlayer then TPlayer.id. AngleTo/Dist2D are the recovered module Functions.
	Method UpdateTeamMateId:Int()
		'!Global g_matchstate:Int
		'!Global g_ball:TBall
		If g_matchstate = 2
			If g_ball And g_ball.setpiecebuddy
				Self.teammateid = g_ball.setpiecebuddy.id
			EndIf
		ElseIf Self.controller = 1
			Self.UpdateTeamMateId_Human()
		Else
			Self.UpdateTeamMateId_CPU()
		EndIf
		Self.directiontoteammate = Int(Self.joy.direction)
		If Self.teammateid > 0
			Local p:TPlayer = TPlayer.GetPlayerById(Self.teammateid)
			Self.directiontoteammate = Int(AngleTo(Self.x, Self.y, p.metax, p.metay))
			Self.distancetoteammate = Dist2D(Self.x, Self.y, p.metax, p.metay)
		EndIf
	End Method
