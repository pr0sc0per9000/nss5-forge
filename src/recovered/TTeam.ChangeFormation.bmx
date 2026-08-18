' TTeam.ChangeFormation
' VA 0x004DDF60   82 bytes   vtable slot 0x5c   sig (i,i)i
' byte-identical vs NSS5.exe (82/82, original length from Ghidra's inventory)
' 0x00c5bff0 = TFormation+0x34 (Create(i):TFormation); slot 0x74 = TTeam.GetTunnelPositions
	Method ChangeFormation:Int(a0:Int, a1:Int)
		formation = TFormation.Create(a0)
		If a1 Then GetTunnelPositions(1)
	End Method
