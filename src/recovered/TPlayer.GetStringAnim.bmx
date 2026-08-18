' TPlayer.GetStringAnim
' VA 0x004FB39B   562 bytes   vtable slot 0x180   sig ([]i)$
' byte-identical vs NSS5.exe (562/562, original length from Ghidra's inventory)
' globals: g_player_arr01..07, arr10..29 :Int[] (0x00C5DEAC..0x00C5DF1C) - the anim frame lists
' Must be a Select with the fallback AFTER End Select: a 'Default' clause puts the
' 'No Anim!' body between the compare chain and the case bodies and is 5 bytes short.
' module globals this body declares:
'   Global g_player_arr01:Int[]
'   Global g_player_arr02:Int[]
'   Global g_player_arr03:Int[]
'   Global g_player_arr04:Int[]
'   Global g_player_arr05:Int[]
'   Global g_player_arr06:Int[]
'   Global g_player_arr07:Int[]
'   Global g_player_arr10:Int[]
'   Global g_player_arr11:Int[]
'   Global g_player_arr12:Int[]
'   Global g_player_arr13:Int[]
'   Global g_player_arr14:Int[]
'   Global g_player_arr15:Int[]
'   Global g_player_arr16:Int[]
'   Global g_player_arr17:Int[]
'   Global g_player_arr18:Int[]
'   Global g_player_arr19:Int[]
'   Global g_player_arr20:Int[]
'   Global g_player_arr21:Int[]
'   Global g_player_arr22:Int[]
'   Global g_player_arr23:Int[]
'   Global g_player_arr24:Int[]
'   Global g_player_arr25:Int[]
'   Global g_player_arr26:Int[]
'   Global g_player_arr27:Int[]
'   Global g_player_arr28:Int[]
'   Global g_player_arr29:Int[]
	Method GetStringAnim:String(a0:Int[])
		'!Global g_player_arr01:Int[]
		'!Global g_player_arr02:Int[]
		'!Global g_player_arr03:Int[]
		'!Global g_player_arr04:Int[]
		'!Global g_player_arr05:Int[]
		'!Global g_player_arr06:Int[]
		'!Global g_player_arr07:Int[]
		'!Global g_player_arr19:Int[]
		'!Global g_player_arr20:Int[]
		'!Global g_player_arr21:Int[]
		'!Global g_player_arr22:Int[]
		'!Global g_player_arr23:Int[]
		'!Global g_player_arr24:Int[]
		'!Global g_player_arr25:Int[]
		'!Global g_player_arr26:Int[]
		'!Global g_player_arr27:Int[]
		'!Global g_player_arr28:Int[]
		'!Global g_player_arr29:Int[]
		'!Global g_player_arr10:Int[]
		'!Global g_player_arr11:Int[]
		'!Global g_player_arr12:Int[]
		'!Global g_player_arr13:Int[]
		'!Global g_player_arr14:Int[]
		'!Global g_player_arr15:Int[]
		'!Global g_player_arr16:Int[]
		'!Global g_player_arr17:Int[]
		'!Global g_player_arr18:Int[]
		Select a0
			Case g_player_arr01
				Return "Stand"
			Case g_player_arr02
				Return "Run"
			Case g_player_arr03
				Return "Kick"
			Case g_player_arr04
				Return "Header"
			Case g_player_arr05
				Return "Slide"
			Case g_player_arr06
				Return "Dive"
			Case g_player_arr07
				Return "Fall"
			Case g_player_arr19
				Return "StandGK"
			Case g_player_arr20
				Return "StandWithBallGK"
			Case g_player_arr21
				Return "WalkWithBallGK"
			Case g_player_arr22
				Return "DiveGK"
			Case g_player_arr23
				Return "DiveFallGK"
			Case g_player_arr24
				Return "JumpGK"
			Case g_player_arr25
				Return "JumpWithBallGK"
			Case g_player_arr26
				Return "CatchGK"
			Case g_player_arr27
				Return "CatchWithBallGK"
			Case g_player_arr28
				Return "CatchLowGK"
			Case g_player_arr29
				Return "CatchLowWithBallGK"
			Case g_player_arr10
				Return "Celebrate1"
			Case g_player_arr11
				Return "Celebrate2"
			Case g_player_arr12
				Return "Celebrate3"
			Case g_player_arr13
				Return "Celebrate4"
			Case g_player_arr14
				Return "Celebrate5"
			Case g_player_arr15
				Return "Commiserate1:ScratchHead"
			Case g_player_arr16
				Return "Commiserate1:FallOnFace"
			Case g_player_arr17
				Return "Commiserate1:FallOnKnees"
			Case g_player_arr18
				Return "Commiserate1:HoldHead"
		End Select
		Return "No Anim!"
	End Method
