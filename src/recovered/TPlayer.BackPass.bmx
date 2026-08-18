' TPlayer.BackPass
' VA 0x004f44c8   194 bytes   vtable slot 0xcc   sig ()i
' byte-identical vs NSS5.exe (194/194, original length from Ghidra's inventory, mode=reloc)
' Global: 0x00C5DEA4 g_ball:TBall. globals_final.tsv types this one TPlayer from vtable slots
' 0x68/0x84/0x88/0x90, but TBall has all four too and the FIELD accesses decide it:
' +0x88 is TBall.backpass and +0x74 is TBall.lastkickedby:TPlayer (whose +0x14 is teamid).
' PTR_FUN_00C5D988 is TPitch's class table + 0x5c = TPitch.InsidePenaltyBox(i,i,i).
' The Null test is the 21-byte `If Not` form (guide 10.3); `= Null` gives 185.
	Method BackPass:Int()
		'!Global g_ball:TBall
		If Not g_ball Then Return 0
		If g_ball.backpass And g_ball.lastkickedby <> Null And g_ball.lastkickedby.teamid = teamid Then Return 1
		If TPitch.InsidePenaltyBox(Int(x), Int(y), -GetShootingDirection()) = 0 Then Return 1
		Return 0
	End Method
