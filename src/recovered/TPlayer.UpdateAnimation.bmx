' TPlayer.UpdateAnimation
' VA 0x004fbd8d   929 bytes   vtable slot 0x190   sig ()i
' byte-identical vs NSS5.exe (929/929, original length from Ghidra's inventory, mode=reloc)
' Assumptions (globals declared for the harness, names from globals_named.tsv):
'   Global g_player_int01:Int      ' 0xc5b1fc -- game-mode selector (1 = match, 3 = set piece)
'   Global g_player_int36:Int      ' 0xc5dea8 -- animation frame interval in ms
'   Global g_player_int50:Int      ' 0xc6efd4 -- current match clock in ms
'   Global g_player_float11:Float  ' 0xc5de68
'   Global g_player_tplayer02:TBall' 0xc5dea4 -- globals_named.tsv infers "TPlayer";
'                                    that is WRONG, +0x48/+0x4c/+0x80 are
'                                    TBall.setpiecex/setpiecey/setpiecetaker.
'   Global g_player_arr01/02/08/09/19:Int[]  ' 0xc5deac / 0xc5deb0 / 0xc5dec8 /
'                                    0xc5decc / 0xc5def4 -- animation frame tables
'                                    (globals_named.tsv types them Object[]).
' 0.5 and the frame-table length read (currentanim.length, array header +0x14)
' were both confirmed by the byte compare.
' Matched in 'reloc' mode (global/vtable-constant addresses masked).
'
' Verified from scratch with the ten '!Global pragmas below -> MATCH
' 929/929, reloc_masked=28. A BUILD_FAIL without them is a harness limitation
' (it cannot bind a Global from prose alone), not a body defect.
	Method UpdateAnimation:Int()
		'!Global g_player_int01:Int
		'!Global g_player_int36:Int
		'!Global g_player_int50:Int
		'!Global g_player_float11:Float
		'!Global g_player_tplayer02:TBall
		'!Global g_player_arr01:Int[]
		'!Global g_player_arr02:Int[]
		'!Global g_player_arr08:Int[]
		'!Global g_player_arr09:Int[]
		'!Global g_player_arr19:Int[]
		facing = GetFacingDirection(direction)
		Local oldanim:Int[] = currentanim
		If z = 0.0 And (GetAnimFrame(0) = -1 Or PlayerOnFeet())
			If PlayerSliding()
				If g_player_int50 < slide_start + slide_delay Then Return 0
			EndIf
			If speed < 0.5
				currentanim = g_player_arr01
				If selectionno = 0 And g_player_int01 = 1
					currentanim = g_player_arr19
				EndIf
			Else
				currentanim = g_player_arr02
			EndIf
		Else
			If z > 0.0 And GetAnimFrame(0) = -1
				frame = frame - 1
			EndIf
		EndIf
		If g_player_int01 = 3 And g_player_tplayer02 <> Null And g_player_tplayer02.setpiecetaker <> Null And g_player_tplayer02.setpiecetaker = Self
			If distancetoball < g_player_float11 And PlayerOnFeet()
				currentanim = g_player_arr08
				xvel = 0
				yvel = 0
				x = g_player_tplayer02.setpiecex
				y = g_player_tplayer02.setpiecey
				If x > 0.0
					facing = 0
				Else
					facing = 1
				EndIf
			EndIf
		ElseIf currentanim = g_player_arr09
			If x > 0.0
				facing = 0
			Else
				facing = 1
			EndIf
		EndIf
		If g_player_int01 = 1 And selectionno = 0 And g_player_tplayer02 <> Null
			ValidateKeeperAnim()
		EndIf
		ValidateAnimDirection()
		If oldanim <> currentanim
			lastframetime = g_player_int50
			frame = 0
		EndIf
		If g_player_int50 > lastframetime + g_player_int36
			lastframetime = g_player_int50
			frame = frame + 1
			If frame = currentanim.length Then frame = 0
		EndIf
	End Method
