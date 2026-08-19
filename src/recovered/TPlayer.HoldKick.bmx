' TPlayer.HoldKick   (KIND=Method, SIG=()i, SLOT=0x104)
' VA 0x004F8159   814 bytes   (Ghidra-authoritative)
' byte-identical vs NSS5.exe (814/814, original length from Ghidra's inventory)
' ORACLE: mode=reloc  matched=814/814  reloc_masked=31  STATUS=MATCH
'
' ASSUMPTIONS / RESOLUTIONS
'   0x00C5B1FC g_player_int01:Int  -- the match-state / set-piece code (already
'     corrected to Int in globals_corrections; refcount-free dword compares here agree).
'   0x00C5D1AC g_player_int14:Int, 0x00C5D228 g_player_int15:Int -- both compared
'     against small immediates with no refcount traffic.
'   0x00C5DEA4 g_player_tplayer02:TBall  -- slot 0x68 = TBall.Kick(:TPlayer,f,f,i,i);
'     see codegen-patterns 11.2 (globals_final says TPlayer, it is TBall).
'   TPitch.YardsToPixels reached through the class-table slot at 0x00C5D998 (TPitch+0x6c).
'   Float constants read out of .rdata: 0x00C79E3C=2.0, 0x00C79E40=1.0, 0x00C79E44=0.75.
'     The Case 2 arm really does multiply by 1.0 -- quirk reproduced, not tidied.
'   Each Select arm declares its OWN Float local (four distinct frame slots
'     [ebp-4]/[ebp-8]/[ebp-0xC]/[ebp-0x10] in `sub esp,0x18`); one shared local would be
'     one colouring node and one slot.
'   `Rand(2)` emits `push 1; push 2` -- maxValue defaults to 1 in brl.random.
'   Final test is `> ... Then Kick(3) Else Kick(2)`: bcc emits the INVERTED setcc
'     (`setbe`) plus `jne <else>`, so the `<=` spelling with the arms swapped is a
'     different byte at offset 728.

'!Global g_player_int01:Int
'!Global g_player_int14:Int
'!Global g_player_int15:Int
'!Global g_ball:TBall

	Method HoldKick()
		If Self.newstar And g_player_int14 = 1
			Self.HoldKickAdvanced()
			Return 0
		End If
		LogLine("HoldKick")
		Self.DoAnimKick(Int(Self.kickpower))
		If g_player_int01 <> 7 And g_player_int01 <> 9
			If Self.controller = 0
				Select g_player_int15
					Case 1
						Local d1:Float = Self.kickdirection
						d1 :+ Rand(Int(-Self.shooting), Int(Self.shooting)) * 2.0
						Self.kickdirection = d1
					Case 2
						Local d2:Float = Self.kickdirection
						d2 :+ Rand(Int(-Self.shooting), Int(Self.shooting)) * 1.0
						Self.kickdirection = d2
					Case 3
						Local d3:Float = Self.kickdirection
						d3 :+ Rand(Int(-Self.shooting), Int(Self.shooting)) * 0.75
						Self.kickdirection = d3
				End Select
			ElseIf g_player_int01 <> 5 And g_player_int01 <> 3
				Local d4:Float = Self.kickdirection
				d4 :+ Rand(Int(-Self.shooting), Int(Self.shooting))
				Self.kickdirection = d4
			End If
		End If
		If g_player_int01 = 5
			Select Rand(2)
				Case 1
					g_ball.Kick(Self, Self.kickdirection, Self.kickpower, 3, 0)
				Case 2
					g_ball.Kick(Self, Self.kickdirection, Self.kickpower, 2, 0)
			End Select
		Else
			If Self.distancetogoal_opp > TPitch.YardsToPixels(30.0)
				g_ball.Kick(Self, Self.kickdirection, Self.kickpower, 3, 0)
			Else
				g_ball.Kick(Self, Self.kickdirection, Self.kickpower, 2, 0)
			End If
		End If
	End Method
