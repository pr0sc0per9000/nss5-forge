' TTeam.GetMatchOverPositions
' VA 0x004e09db   135 bytes   vtable slot 0x7c   sig ()i
' byte-identical vs NSS5.exe (135/135, original length from Ghidra's inventory)
' Field [0x62]=+0x188 matchstats:TStats_Match, its +0x10 = reds; [0x2f]=+0xbc selectionno.
' The `74 02 EB 0C` shape is `Then Continue`, not a cascade-down If (which is 2 bytes shorter).
	Method GetMatchOverPositions:Int()
		For Local p:TPlayer = EachIn squad
			If p.matchstats.reds Or p.selectionno > 10 Then Continue
			p.GetMatchOverPosition()
		Next
	End Method
