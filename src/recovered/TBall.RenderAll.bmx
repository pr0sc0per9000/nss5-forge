' TBall.RenderAll
' VA 0x004c8211   124 bytes   vtable slot 0x50   sig (f)i
' byte-identical vs NSS5.exe (124/124, original length from Ghidra's inventory)
' assumes module global:  Global g_balls:TList  (0x00c5a4c0)
' `If Not g_balls Then Return 0` is load-bearing; wrapping the loop in
' `If g_balls <> Null ... EndIf` is 16 bytes short

	Function RenderAll:Int(a0:Float)
		'!Global g_balls:TList
		If Not g_balls Then Return 0
		For Local b:TBall = EachIn g_balls
			b.Render(a0)
		Next
	End Function
