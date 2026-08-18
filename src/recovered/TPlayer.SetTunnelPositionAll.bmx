' TPlayer.SetTunnelPositionAll
' VA 0x004F9E7C   111 bytes   vtable slot 0x140   sig ()i
' byte-identical vs NSS5.exe (111/111, original length from Ghidra's inventory)
' assumptions: module Global at 0x00C5DE10 declared :TList (the all-players list);
' 0x00505B91 is the already-recovered module Function LogLine($) (src/recovered_module/LogLine.bmx)
	Function SetTunnelPositionAll()
		'!Global g_players:TList
		LogLine("SetTunnelPositionAll")
		For Local p:TPlayer = EachIn g_players
			p.GetTunnelPosition(1)
		Next
	End Function
