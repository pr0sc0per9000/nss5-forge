' TEngine.DoShootOut
' VA 0x004d7768   164 bytes   vtable slot 0xec   sig ()i
' byte-identical vs NSS5.exe (164/164, original length from Ghidra's inventory)
' Globals (all Int except the two sound handles): 0x00C5B238 kick counter, 0x00C5B1FC
' match state, 0x00C5B254 and 0x00C6EFD4 are Ints (plain dword copy, no refcount
' traffic -- globals_final.tsv types them as objects and is wrong here), 0x00C5B364
' :TSound and 0x00C5B348 :TChannel. TEngine.CheckShootOutComplete = TEngine+0xF0,
' TEngine.SetUpSetPiece = TEngine+0x70, TPlayer.RecordPlayerStats = TPlayer+0x230.
' The If is an early-return guard and the 0/1 dispatch is a Select with no Default.
	Function DoShootOut:Int()
		'!Global g_shootoutkicks:Int
		'!Global g_matchstate:Int
		'!Global g_engine_int27:Int
		'!Global g_player_int50:Int
		' The shoot-out plays the CROWD GOAL sample on the crowd channel, not the whistle:
' 0x004D7777 `ff3548b3c500 push dword ptr [0xc5b348]` (channel) and 0x004D777D
' `ff3564b3c500 push dword ptr [0xc5b364]` (sound). TEngine.SetUp loads 0x00C5B364 from
' the literal "EngineMedia/Match/Sounds/CrowdGoal.ogg" at 0x004CE0D1 and stores it at
' 0x004CE0F6. g_snd_whistle and g_chan_whistle are TEngine.SetUp's, DoHalfEnds',
' SetUpSetPiece's and UpdateSetPieceReady's names for 0x00C5B34C and 0x00C5B33C, so
' finishing a shoot-out blew the referee's whistle instead of the crowd's roar.
		'!Global g_snd_crowd:TSound
		'!Global g_chan_crowd:TChannel
		If TEngine.CheckShootOutComplete()
			PlaySound(g_snd_crowd, g_chan_crowd)
			g_engine_int27 = g_player_int50
			g_matchstate = 11
			g_shootoutkicks :+ 1
			TPlayer.RecordPlayerStats()
			Return 0
		EndIf
		g_shootoutkicks :+ 1
		Local side:Int = 0
		Select g_shootoutkicks Mod 2
			Case 0
				side = 2
			Case 1
				side = 1
		End Select
		g_matchstate = 9
		TEngine.SetUpSetPiece(9, side, 0, 0)
	End Function
