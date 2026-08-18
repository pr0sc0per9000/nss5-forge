' TPlayer.GetShootingDirection
' VA 0x004FADCB   216 bytes   vtable slot 0x160   sig ()i
' byte-identical vs NSS5.exe (216/216, original length from Ghidra's inventory)
' mode 'reloc': absolute addresses masked, emitted code identical
' module global assumed: Global g_hometeam:TTeam
' module global assumed: Global g_awayteam:TTeam
' module global assumed: Global g_engine_int18:Int

	Method GetShootingDirection:Int()
		'!Global g_hometeam:TTeam
		'!Global g_awayteam:TTeam
		'!Global g_engine_int18:Int
		Local h:Int = 0
		Local aw:Int = 0
		If g_hometeam <> Null Then h = g_hometeam.id
		If g_awayteam <> Null Then aw = g_awayteam.id
		Select teamid
			Case h
				Select g_engine_int18
					Case 1
						Return -1
					Case 2
						Return 1
					Case 3
						Return -1
					Case 4
						Return 1
				End Select
			Case aw
				Select g_engine_int18
					Case 1
						Return 1
					Case 2
						Return -1
					Case 3
						Return 1
					Case 4
						Return -1
				End Select
		End Select
		If selectionno = 0 Then Return 1
		Return -1
	End Method
