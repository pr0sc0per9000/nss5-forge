' TPlayer.DoAnimFall
' VA 0x004FD16F   194 bytes   vtable slot 0x1e0   sig ()i
' byte-identical vs NSS5.exe (194/194, original length from Ghidra's inventory)
' assumptions: Global 0x00C5DEC4 declared Int[] (TPlayer.currentanim is []i, and the
' store carries retain/release traffic), 0x00C5DF38 TSound, 0x00C5DF30 TChannel,
' 0x00C5DEA4 TBall -- globals_final says TPlayer, but the field written at +0x70 is an
' object compared against Self, and TBall.controlledby:TPlayer is the only +0x70 object
' field in the model; TBall also carries slots 0x68/0x84/0x88/0x90 that typed the row.
	Method DoAnimFall:Int()
		'!Global g_animfall:Int[]
		'!Global g_sndfall:TSound
		'!Global g_chanfall:TChannel
		'!Global g_ball:TBall
		LogLine("DoAnimFall")
		PlaySound(g_sndfall, g_chanfall)
		Self.currentanim = g_animfall
		Self.frame = 0
		Self.joy.Clear()
		If g_ball <> Null And g_ball.controlledby = Self
			g_ball.controlledby = Null
		EndIf
	End Method
