' TPlayer.KeeperHoldingBall
' VA 0x004FCAB6   258 bytes   vtable slot 0x1c0   sig ()i
' byte-identical vs NSS5.exe (258/258, original length from Ghidra's inventory)
' mode 'reloc': absolute addresses masked, emitted code identical
' module global assumed: Global g_ball:TBall
' module global assumed: Global g_player_arr20:Int[]
' module global assumed: Global g_player_arr21:Int[]
' module global assumed: Global g_player_arr22:Int[]
' module global assumed: Global g_player_arr23:Int[]
' module global assumed: Global g_player_arr25:Int[]
' module global assumed: Global g_player_arr27:Int[]
' module global assumed: Global g_player_arr29:Int[]

	Method KeeperHoldingBall:Int()
		'!Global g_player_arr20:Int[]
		'!Global g_player_arr21:Int[]
		'!Global g_player_arr22:Int[]
		'!Global g_ball:TBall
		'!Global g_player_arr23:Int[]
		'!Global g_player_arr25:Int[]
		'!Global g_player_arr27:Int[]
		'!Global g_player_arr29:Int[]
		If selectionno > 0 Then Return 0
		Select currentanim
			Case g_player_arr20
				Return 1
			Case g_player_arr21
				Return 1
			Case g_player_arr22
				If g_ball <> Null And g_ball.controlledby = Self Then Return 1
			Case g_player_arr23
				If g_ball <> Null And g_ball.controlledby = Self Then Return 1
			Case g_player_arr25
				Return 1
			Case g_player_arr27
				Return 1
			Case g_player_arr29
				Return 1
		End Select
		Return 0
	End Method
