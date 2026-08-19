' TPlayer.PlayerReady
' VA 0x004FABE3   356 bytes   mode=reloc
' byte-identical vs NSS5.exe
' Verified through the oracle from scratch with helper_map.record stubbed; MATCH over
' the full Ghidra-authoritative length, every byte.
' Body-only format: statements only, parameters are a0, a1, ...
'!Global g_player_int16:Int
'!Global g_player_int01:Int
'!Global g_ball:TBall
If Self.selectionno > 10
	If Self.x < -g_player_int16
		Return 1
	End If
Else
	If Self.ForceControlCPU() = 0
		If g_player_int01 = 5 Or g_player_int01 = 4
			If g_ball <> Null And g_ball.teaminpossession <> Self.teamid And Dist2D(Self.x, Self.y, g_ball.setpiecex, g_ball.setpiecey) < TPitch.YardsToPixels(10.0)
				Return 0
			End If
		End If
		Return 1
	End If
	If Dist2D(Self.x, Self.y, Self.desx, Self.desy) < TPitch.YardsToPixels(2.5)
		Return 1
	End If
End If
Return 0
