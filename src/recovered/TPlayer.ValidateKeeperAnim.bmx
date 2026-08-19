' TPlayer.ValidateKeeperAnim
' VA 0x004fc5af   651 bytes   vtable slot 0x19c   sig ()i
' byte-identical vs NSS5.exe (651/651, original length from Ghidra's inventory, mode=reloc)
' Assumptions (globals declared for the harness, names from globals_named.tsv):
'   Global g_player_tplayer02:TBall     ' 0xc5dea4 -- globals_named.tsv infers
'       "TPlayer"; that is WRONG.  It is dereferenced here at +0x70 and +0x88,
'       which are TBall.controlledby:TPlayer and TBall.backpass:Int.
'   Global g_player_arr01/02/19/20/21/24..29:Int[]   ' the keeper animation
'       frame tables at 0xc5deac / 0xc5deb0 / 0xc5def4 / 0xc5def8 / 0xc5defc /
'       0xc5df08 / 0xc5df0c / 0xc5df10 / 0xc5df14 / 0xc5df18 / 0xc5df1c.
'       globals_named.tsv types them Object[]; TPlayer.currentanim is []i, and
'       Int[] is what reproduces the bytes.
' Matched in 'reloc' mode (global addresses masked).
'
' Verified from scratch with the twelve '!Global pragmas below ->
' MATCH 651/651, reloc_masked=36. A BUILD_FAIL without them is a harness
' limitation (it cannot bind a Global from prose alone), not a body defect.
	Method ValidateKeeperAnim:Int()
		'!Global g_ball:TBall
		'!Global g_player_arr01:Int[]
		'!Global g_player_arr02:Int[]
		'!Global g_player_arr19:Int[]
		'!Global g_player_arr20:Int[]
		'!Global g_player_arr21:Int[]
		'!Global g_player_arr24:Int[]
		'!Global g_player_arr25:Int[]
		'!Global g_player_arr26:Int[]
		'!Global g_player_arr27:Int[]
		'!Global g_player_arr28:Int[]
		'!Global g_player_arr29:Int[]
		If g_ball.controlledby = Self And g_ball.backpass = 0
			If currentanim = g_player_arr01
				currentanim = g_player_arr20
			ElseIf currentanim = g_player_arr19
				currentanim = g_player_arr20
			ElseIf currentanim = g_player_arr02
				currentanim = g_player_arr21
			ElseIf currentanim = g_player_arr24
				currentanim = g_player_arr25
			ElseIf currentanim = g_player_arr26
				currentanim = g_player_arr27
			ElseIf currentanim = g_player_arr28
				currentanim = g_player_arr29
			EndIf
		ElseIf g_ball.controlledby <> Self
			If currentanim = g_player_arr20
				currentanim = g_player_arr01
			ElseIf currentanim = g_player_arr21
				currentanim = g_player_arr02
			ElseIf currentanim = g_player_arr25
				currentanim = g_player_arr24
			ElseIf currentanim = g_player_arr27
				currentanim = g_player_arr26
			ElseIf currentanim = g_player_arr29
				currentanim = g_player_arr28
			EndIf
		EndIf
	End Method
