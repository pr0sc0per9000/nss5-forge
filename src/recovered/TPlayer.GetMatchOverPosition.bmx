' TPlayer.GetMatchOverPosition
' VA 0x004FA470   1799 bytes   vtable slot 0x150   sig ()i
' byte-identical vs NSS5.exe (1799/1799, original length from Ghidra's inventory, mode=reloc)
'
' Picks the player's post-match "walking off" destination (desx/desy), used once the match
' has finished (or is about to be judged over). Bails out via GetTunnelPosition() -- the
' normal off-pitch spot -- when the match isn't really decided yet: newstar with time left,
' or a genuine draw (TEngine.GetWinningClub() = Null, or g_fixture.matchtype = 1). Otherwise
' it recomputes the winner and, if this player's own team lost, just calls GetTunnelPosition
' again (conditionally); if this player's team WON, it walks them out toward the centre circle
' on a schedule keyed off walktime = (g_player_int50-g_engine_int27) Mod 40000, split into a
' handful of time bands with mirrored X/Y offsets depending on which physical goal end
' (g_pitch_int05) and which of the two winning-team slots (home vs away, via GetMyTeam()
' compared against g_team1) the player belongs to. The away/near-goal-end/late-band case
' instead walks the player onto a circle via Cos/Sin(selectionno*36) * YardsToPixels(6.0).
' In every branch, currentanim is reset to g_player_arr01 (frame 0) iff desx/desy actually
' changed from their values on entry -- three copies of the identical idiom, one per return
' point (bcc has no CSE / no shared-block factoring, so all three are separately emitted).
'
' NOTES ON FORM (all load-bearing for the byte count):
'  * `g_player_int50 > g_engine_int27 + 30000` / `... + 5000` -- g_player_int50 is the LEFT
'    operand (loaded first into its own register) in both places; writing the mathematically
'    equivalent `g_engine_int27 + N < g_player_int50` loads the sum first and is 2 bytes
'    shorter (guide 10.1 -- comparison operand order is byte-observable, Ghidra normalises it
'    away).
'  * `If teamid <> TEngine.GetWinningClub().id Then [[tunnel-branch]] Else [[cascade]]` --
'    the ORIGINAL emits a `je` straight to the cascade with the tunnel-branch inline
'    (fallthrough on not-equal). That is the solo-relational branch-swap rule (guide section
'    21): the written comparison must be the NEGATION of what the bytes test, with
'    Then/Else swapped, to reproduce it.
'  * Both `g_pitch_int05` tests are the same swap: source reads `<> 0` with the two
'    branches' CONTENT swapped relative to the natural `= 0` reading -- confirmed
'    independently at both occurrences (own-team and other-team halves).
'  * `xoff` is computed via `Int(g_player_int16 + TPitch.YardsToPixels(1.0))`, immediately
'    followed by a byte-for-byte IDENTICAL second statement (`yoff`) whose result is used
'    NOWHERE else in the function -- an original dead computation, reproduced faithfully
'    (project law 3). It costs zero extra bytes because the dead Local's one live value
'    naturally colours to eax, the same register the call already returns it in, so no
'    store instruction is needed for it at all.
'  * `desx`/`desy` assignments consistently negate at the INT level first when the sign
'    flips (`-xoff`, `-g_player_int19`), matching `neg eax` appearing before the `fild`
'    Int->Float conversion in every such case.
'  * The `desx = desx - TPitch.YardsToPixels(selectionno)` cases use a genuine SUBTRACT
'    (original desx value read before the call, YardsToPixels called, then subtracted) --
'    written as ordinary `desx = desx - TPitch.YardsToPixels(selectionno)`, left-to-right.
'  * The Cos/Sin branch is `Cos(selectionno * 36) * TPitch.YardsToPixels(6.0)` -- Int
'    multiply first (imul, matching Ghidra's `* 0x24`), Cos/Sin called BEFORE
'    YardsToPixels(6.0) in each product (matches the call order in the disassembly).
'!Global g_player_int01:Int
'!Global g_engine_int27:Int
'!Global g_player_int50:Int
'!Global g_fixture:TFixture
'!Global g_team1:TTeam
'!Global g_pitch_int05:Int
'!Global g_player_int16:Int
'!Global g_player_int17:Int
'!Global g_pitch_int11:Int
'!Global g_player_int19:Int
'!Global g_player_arr01:Int[]
	Method GetMatchOverPosition:Int()
		Local oldx:Float = desx
		Local oldy:Float = desy
		If (g_player_int01 = 11 And g_player_int50 > g_engine_int27 + 30000) Or (TEngine.GetWinningClub() = Null) Or (g_fixture.matchtype = 1)
			GetTunnelPosition(0)
			If oldx <> desx Or oldy <> desy
				currentanim = g_player_arr01
				frame = 0
			End If
			Return 0
		Else
			If teamid <> TEngine.GetWinningClub().id
				If g_player_int50 > g_engine_int27 + 5000
					GetTunnelPosition(0)
				End If
				If oldx <> desx Or oldy <> desy
					currentanim = g_player_arr01
					frame = 0
				End If
				Return 0
			Else
				Local walktime:Int = (g_player_int50 - g_engine_int27) Mod 40000
				Local xoff:Int = Int(g_player_int16 + TPitch.YardsToPixels(1.0))
				Local yoff:Int = Int(g_player_int16 + TPitch.YardsToPixels(1.0))
				If GetMyTeam() = g_team1
					If g_pitch_int05 <> 0
						If walktime < 10000
							desx = -xoff
							desy = -g_player_int19
							desy = desy + TPitch.YardsToPixels(selectionno)
						Else If walktime < 20000
							desx = xoff
							desy = -g_player_int19
							desy = desy + TPitch.YardsToPixels(selectionno)
						Else
							desx = -xoff
							desy = g_player_int17 * 0.5
							desx = desx + TPitch.YardsToPixels(selectionno)
						End If
					Else
						If walktime < 7500
							desx = -xoff
							desy = -g_player_int19
							desy = desy + TPitch.YardsToPixels(selectionno)
						Else If walktime < 15000
							desx = xoff
							desy = -g_player_int19
							desy = desy + TPitch.YardsToPixels(selectionno)
						Else If walktime < 22500
							desx = xoff
							desy = g_pitch_int11
							desx = desx - TPitch.YardsToPixels(selectionno)
						Else
							desx = -xoff
							desy = g_player_int19
							desy = desy + TPitch.YardsToPixels(selectionno)
						End If
					End If
				Else
					If g_pitch_int05 <> 0
						If walktime < 10000
							desx = xoff
							desy = -g_player_int19
							desy = desy + TPitch.YardsToPixels(selectionno)
						Else If walktime < 20000
							desx = xoff
							desy = g_player_int19
							desx = desx - TPitch.YardsToPixels(selectionno)
						Else
							desx = -xoff
							desy = g_player_int19
							desy = desy + TPitch.YardsToPixels(selectionno)
						End If
					Else
						If walktime < 15000
							desx = -xoff
							desy = g_player_int19
							desy = desy + TPitch.YardsToPixels(selectionno)
						Else
							desx = Cos(selectionno * 36) * TPitch.YardsToPixels(6.0)
							desy = Sin(selectionno * 36) * TPitch.YardsToPixels(6.0)
						End If
					End If
				End If
				If oldx <> desx Or oldy <> desy
					currentanim = g_player_arr01
					frame = 0
				End If
				Return 0
			End If
		End If
	End Method
