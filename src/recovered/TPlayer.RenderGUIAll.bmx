' TPlayer.RenderGUIAll
' VA 0x004EF035   99 bytes   vtable slot 0x58   sig (f,f)i
' byte-identical vs NSS5.exe (99/99, original length from Ghidra's inventory)
' assumption: module Global at 0x00C5DE10 declared :TList (the all-players list)
	Function RenderGUIAll(a0:Float,a1:Float)
		'!Global g_players:TList
		For Local p:TPlayer = EachIn g_players
			p.RenderGUI(a0,a1)
		Next
	End Function
