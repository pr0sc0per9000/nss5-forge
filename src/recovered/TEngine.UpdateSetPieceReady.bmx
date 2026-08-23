' TEngine.UpdateSetPieceReady
' VA 0x004D373C   604 bytes  mode=reloc  byte-identical vs NSS5.exe (604/604)
' KIND=Function, SIG ()i, slot 0x7C
' ASSUMPTIONS
'   0x00C5B204 g_setpiecepower:Int, 0x00C5B1FC g_matchstate:Int (both bare dword stores,
'     no refcount traffic), 0x00C6EFD4 g_player_int50:Int, 0x00C6CF90 g_training_int03:Int.
' g_engine_int17 (0x00C5B1F8) original data-section value is 1750, read directly
' from NSS5.exe. See codegen-patterns 21.1/21.3.
'   0x00C5DE10 g_players:TList -- the EachIn downcasts to ClassTable_TPlayer.
'   0x00C5B1C8 :TBitmapFont and 0x00C5B1F8 :Int are arguments 5 and 4 of
'     TScreenMessage.Create (i,i,$,i,:TBitmapFont,:TImage,f,$)i, which fixes both.
'   0x00C5B34C :TSound / 0x00C5B33C :TChannel from the PlaySound signature.
'   The first guard is a short-circuit Or: `SetPiece() = 0` produces sete/movzx and its
'     jne skips the load of g_training_int03 entirely.
'   `p.PlayerReady() = 0` is a nested If, not a third And operand -- an And operand would
'     have to materialise 0/1 with a setcc, and this one compares eax directly.
' CASE DIRECTION CORRECTED 2026-08-22: 1 call site -> .ToUpper().
' extracted/runtime_helpers.tsv named 0x004A7410 `_brl_retro_Lower` and 0x004A74E0
' `_brl_retro_Upper`. Both were wrong and neither address is a brl.retro wrapper:
' 0x004A7410 is `_bbStringToUpper` and 0x004A74E0 is `_bbStringToLower`. NSS5.exe's
' own 21-byte retro wrappers at 0x0059C8FD (Lower) and 0x0059C912 (Upper) CALL those
' two addresses, and a wrapper cannot be the function it calls. The wrong row masked
' by name, so this body certified with the case conversion running backwards. Full
' derivation and the discriminating 3x4 matrix: docs/reference/codegen-patterns.md
' 15.6. Re-verified under NSS5_NO_LEARN=1 on worker trees 380 and 380b.
	Function UpdateSetPieceReady:Int()
		'!Global g_setpiecepower:Int
		'!Global g_matchstate:Int
		'!Global g_players:TList
		'!Global g_training_int03:Int
		'!Global g_player_int50:Int
		'!Global g_engine_int17:Int = 1750
		'!Global g_engine_font:TBitmapFont
		'!Global g_snd_whistle:TSound
		'!Global g_chan_whistle:TChannel
		Local was:Int = g_setpiecepower
		If SetPiece() = 0 Or g_training_int03
			g_setpiecepower = 1
			Return 0
		End If
		If WaitForSetpiece()
			If TPlayer.AllPlayersReady() = 0
				g_setpiecepower = 0
				Return 0
			End If
		Else
			Local p:TPlayer = TPlayer.GetHumanPlayer()
			If p <> Null And p.selectionno > 10
				If p.PlayerReady() = 0
					g_setpiecepower = 0
					Return 0
				End If
			End If
			Local b:TBall = TBall.GetActiveBall()
			If b <> Null
				If b.controlledby <> b.setpiecetaker
					g_setpiecepower = 0
					Return 0
				End If
				If g_matchstate <> 3
					For Local pl:TPlayer = EachIn g_players
						If pl.teamid <> b.controlledby.teamid And pl.distancetoball < TPitch.YardsToPixels(8.0)
							g_setpiecepower = 0
							Return 0
						End If
					Next
				End If
			End If
		End If
		If was = 0
			g_setpiecepower = g_player_int50
			If g_matchstate = 2 Or g_matchstate = 4 Or g_matchstate = 7
				If g_matchstate = 2
					TScreenMessage.Create(0, 0, GetText("Kick Off").ToUpper(), g_engine_int17, g_engine_font, Null, 1.0, "FFFFFF")
				End If
				PlaySound(g_snd_whistle, g_chan_whistle)
			End If
		End If
	End Function
