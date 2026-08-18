' TScreen_Formation.ChangePosition
' VA 0x0054cc77   177 bytes   vtable slot 0x48   sig ()i
' byte-identical vs NSS5.exe (177/177, original length from Ghidra's inventory)
' assumes: both Globals Int (globals_final types 0x00C677DC as TPlayer - the code increments and compares it, so Int); guard is 'If Not p Or p.matchstats.reds Then Return 0' - setne/movzx then sete/movzx is Not on an object inside an Or
	Function ChangePosition:Int()
		'!Global g_formation_selno:Int
		'!Global g_formation_newstarselno:Int
		Local p:TPlayer = TPlayer.GetHumanPlayer()
		If Not p Or p.matchstats.reds Then Return 0
		If g_formation_selno = 0 Then g_formation_selno = g_formation_newstarselno
		g_formation_selno :+ 1
		If g_formation_selno = g_formation_newstarselno Then g_formation_selno :+ 1
		If g_formation_selno > 10 Then g_formation_selno = 1
		RefreshButtons()
		LogLine("newstarselno:" + g_formation_newstarselno)
	End Function
