' TBall.UpdateReplayAll
' VA 0x004cc02e   136 bytes   vtable slot 0xb0   sig (i)i
' byte-identical vs NSS5.exe (136/136, original length from Ghidra's inventory)
' 0x00C5A4C0 : TList of TBall
' TBall slot 0xB4 = UpdateReplay(i)
' Global: Global g_balls:TList
	Function UpdateReplayAll:Int(a0:Int)
		'!Global g_balls:TList
		If Not g_balls Then Return 0
		For Local b:TBall = EachIn g_balls
			b.UpdateReplay(a0)
		Next
	End Function
