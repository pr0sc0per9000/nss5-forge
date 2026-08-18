' TBall.RenderReplayAll
' VA 0x004cc28d   127 bytes   vtable slot 0xb8   sig (f)i
' byte-identical vs NSS5.exe (127/127, original length from Ghidra's inventory, mode=reloc)
' Global: 0x00C5A4C0 g_balls:TList.
' The 21-byte setne/movzx Null test (guide 10.3) with the branch skipping a `Return 0`,
' i.e. `If Not g_balls Then Return 0` -- the If-block form is 111 bytes.
	Function RenderReplayAll:Int(a0:Float)
		'!Global g_balls:TList
		If Not g_balls Then Return 0
		For Local b:TBall = EachIn g_balls
			b.RenderReplay(a0)
		Next
	End Function
