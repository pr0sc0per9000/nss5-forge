' TBall.RecordReplayFramesAll
' VA 0x004cbeb4   136 bytes   vtable slot 0xa8   sig (i)i
' byte-identical vs NSS5.exe (136/136, original length from Ghidra's inventory, mode=reloc)
' assumes module Global (name ours, type load-bearing): Global g_balls:TList (0x00C5A4C0)
' the EachIn downcast class table is TBall (0x00C5AE98); slot 0xAC = RecordReplayFrame(i)
'!Global g_balls:TList

	Function RecordReplayFramesAll:Int(a0:Int)
		If Not g_balls Then Return 0
		For Local b:TBall = EachIn g_balls
			b.RecordReplayFrame(a0)
		Next
	End Function
