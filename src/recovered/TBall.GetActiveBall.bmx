' TBall.GetActiveBall
' VA 0x004c80c5   120 bytes   vtable slot 0x44   sig ():TBall
' byte-identical vs NSS5.exe (120/120, original length from Ghidra's inventory)
' assumes module global:  Global g_balls:TList  (0x00c5a4c0)
' `If Not g_balls` (not `= Null`) is load-bearing -- see TContinent.SelectById

	Function GetActiveBall:TBall()
		'!Global g_balls:TList
		If Not g_balls Then Return Null
		For Local b:TBall = EachIn g_balls
			If b.active Then Return b
		Next
		Return Null
	End Function
