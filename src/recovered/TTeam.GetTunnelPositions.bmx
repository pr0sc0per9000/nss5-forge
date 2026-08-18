' TTeam.GetTunnelPositions
' VA 0x004E08E8   108 bytes   vtable slot 0x74   sig (i)i
' byte-identical vs NSS5.exe (108/108, original length from Ghidra's inventory)
' no assumptions: field squad:TList at +0x1c, TPlayer.GetTunnelPosition is slot 0x144
	Method GetTunnelPositions(a0:Int)
		For Local p:TPlayer = EachIn squad
			p.GetTunnelPosition(a0)
		Next
	End Method
