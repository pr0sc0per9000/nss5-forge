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
		'!Global g_snd_whistle:TSound
		'!Global g_chan_whistle:TChannel
		If TEngine.CheckShootOutComplete()
			PlaySound(g_snd_whistle, g_chan_whistle)
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
