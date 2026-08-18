' TEngine.CreateReplayFrames
' VA 0x004D460F   156 bytes   vtable slot 0x90   sig (:TReplay)i
' byte-identical vs NSS5.exe (156/156, original length from Ghidra's inventory)
' Parameter names are not recoverable from the binary and do not affect codegen;
' they are emitted as a0, a1, ... exactly as the harness compiles them.
' ASSUMPTION: module Global at 0x00c5b2b0 declared TList.
' 'If Not g' is load-bearing -- 'If g = Null' folds to a direct memory compare and is 9 bytes short.
' FUN_005b40bf = _brl_linkedlist_CreateList.

	Function CreateReplayFrames:Int(a0:TReplay)
		'!Global g_replayframes:TList
		If Not g_replayframes Then g_replayframes = CreateList()
		For Local f:TReplayFrame = EachIn a0.matchstateframes
			g_replayframes.AddLast(f)
		Next
	End Function
