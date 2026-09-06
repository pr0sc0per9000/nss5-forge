' TEngine.UpdateMatchTime
' VA 0x004D4087   685 bytes   vtable slot 0x88   sig ()i
' byte-identical vs NSS5.exe (685/685, original length from Ghidra's inventory, mode=reloc)
'
' 0x00C5AEDC = TBall + 0x44 = GetActiveBall(); 0x00C5BB14 = TEngine + 0xE4 = SkipTime();
' 0x00C5BB1C = TEngine + 0xEC = DoShootOut(); 0x00C5BABC = TEngine + 0x8C = DoHalfEnds();
' 0x00C5FB78 = TPlayer + 0x22C = UpdateMatchRatingAll(); 0x00C5D998 = TPitch + 0x6C =
' YardsToPixels(f)f. 0x00505DA2 = module Dist2D. 0x004A7FE0 is the Double Abs helper.
' TBall slot 0x88 = KeeperHolding(); TPlayer slot 0xE4 = CleanThrough().
' 0x00C5B248 + 0x8 is TPlayer.newstar (globals_final's TPlayer typing is right here).
' 0x00C5B218 + 0x8 is an Int id, so that Global is a TTeam, not the TKit the table says.
' Float constants read from the exe: 0x00C7422C = 30.0, 0x00C74230 = 0x00C74234 = 0.01
' (two distinct addresses, i.e. two separate source literals).
'
' Two forms were forced by the byte count, both -2/+4 offenders on the way in:
'   * `Local tick:Int = (...) / 90` then `g_lastminutetick + tick`. Inlining the division
'     emits `add eax,[g]` (6 bytes) instead of the original's `mov edx,[g] / add edx,eax`
'     (8); putting the Global on the left of an inlined sum makes bcc hold it in esi across
'     the idiv, which costs a whole extra push/pop pair.
'   * the four-arm `Select` (codegen-patterns 10.2): every Case compare is emitted back to
'     back ahead of the bodies, which is what the original does.
' Module Globals declared by this body (names are ours; the TYPES are load-bearing):
'   g_intraining 0x00C6CF90   g_matchstate 0x00C5B1FC   g_myprofile:TPlayer 0x00C5B248
'   g_statestarted 0x00C5B254 g_matchtimer 0x00C6EFD4   g_shootoutstarted 0x00C5B244
'   g_homeTeam:TTeam 0x00C5B218  g_possessionhome 0x00C5B25C  g_possessionaway 0x00C5B260
'   g_half 0x00C5B208  g_minutes 0x00C5B210  g_lastminutetick 0x00C5B214
'   g_halflength 0x00C5B20C  g_opt_matchlength 0x00C5D230
	Function UpdateMatchTime:Int()
		'!Global g_intraining:Int
		'!Global g_matchstate:Int
		'!Global g_myprofile:TPlayer
		'!Global g_statestarted:Int
		'!Global g_matchtimer:Int
		'!Global g_shootoutstarted:Int
		'!Global g_homeTeam:TTeam
		'!Global g_possessionhome:Float
		'!Global g_possessionaway:Float
		'!Global g_half:Int
		'!Global g_minutes:Int
		'!Global g_lastminutetick:Int
		'!Global g_halflength:Int
		' 0x00C5D230, the match-LENGTH option, measured at 0x004D41F6
' `0faf0530d2c500 imul eax, dword ptr [0xc5d230]`. g_matchspeed is TEngine.MatchLoop's
' name for the neighbouring 0x00C5D234, the match-SPEED option, so the two options were
' one emitted variable and the tick length below was computed from speed (30) instead of
' length (3): ten times too long, so the match clock crawled and never reached half time.
		'!Global g_opt_matchlength:Int
		If g_intraining <> 0 Then Return 0
		Local b:TBall = TBall.GetActiveBall()
		If g_matchstate = 8 Then
			Local skip:Int = 6000
			If g_myprofile.newstar <> 0 Then skip = 8000
			If g_matchtimer > g_statestarted + skip Or (b <> Null And Dist2D(0, 0, b.x, b.y) < 30.0) Then
				TEngine.SkipTime()
				Return 0
			End If
		End If
		If g_matchstate = 10 Then
			If g_matchtimer > g_shootoutstarted + 2500 Then TEngine.DoShootOut()
			Return 0
		End If
		If g_matchstate <> 1 Then Return 0
		If b <> Null And b.KeeperHolding() Then Return 0
		TPlayer.UpdateMatchRatingAll()
		If b <> Null And b.teaminpossession = g_homeTeam.id Then
			g_possessionhome = g_possessionhome + 0.01
		Else
			g_possessionaway = g_possessionaway + 0.01
		End If
		Local tick:Int = (g_halflength * 60 * g_opt_matchlength) / 90
		If g_matchtimer > g_lastminutetick + tick Then
			g_lastminutetick = g_matchtimer
			g_minutes :+ 1
			If b <> Null And Abs(b.y) < TPitch.YardsToPixels(30.0) And (b.lastkickmatchstate = 1 Or g_matchtimer > b.kicktime + 1500) Then
				If b.controlledby <> Null And b.controlledby.CleanThrough() Then Return 0
				Select g_half
					Case 1
						If g_minutes > 45 Then TEngine.DoHalfEnds()
					Case 2
						If g_minutes > 90 Then TEngine.DoHalfEnds()
					Case 3
						If g_minutes > 105 Then TEngine.DoHalfEnds()
					Case 4
						If g_minutes > 120 Then TEngine.DoHalfEnds()
				End Select
			End If
		End If
	End Function
