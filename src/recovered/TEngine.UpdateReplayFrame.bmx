' TEngine.UpdateReplayFrame
' VA 0x004D4764   138 bytes   vtable slot 0x98   sig (i)i
' byte-identical vs NSS5.exe (138/138, original length from Ghidra's inventory)
' ASSUMPTIONS: module Globals 0x00C5B2B0 :TList, 0x00C5B1FC :Int, 0x00C5B24C :Int.
' TWeather.UpdateReplay resolved to TWeather+0x40 on both sides.
' harness mode=reloc.

	Function UpdateReplayFrame:Int(a0:Int)
		'!Global g_replayframes:TList
		'!Global g_replay_id:Int
		'!Global g_replay_clubid:Int
		For Local f:TReplayFrame = EachIn g_replayframes
			If f.frametime = a0 Then
				g_replay_id = f.id
				g_replay_clubid = f.clubid
				TWeather.UpdateReplay(f.alph, a0)
				Return 0
			EndIf
		Next
	End Function
