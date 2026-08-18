' TEngine.StartReplay
' VA 0x004D47EE   411 bytes   vtable slot 0x9c   sig ()i   KIND=Function (static)
' byte-identical vs NSS5.exe (411/411, original length from Ghidra's inventory, mode=reloc)
' Global names are ours: 0x00C5A4C0 g_balls:TList, 0x00C6CF90 g_trainingMode:Int,
' 0x00C5B1D4 and 0x00C5D23C Float, 0x00C5B2B8 / 0x00C5B2C0 / 0x00C5B2C4 / 0x00C5B2C8 /
' 0x00C5B1CC Int -- all bare dword or x87 dword traffic with no refcounting.
' UpdateReplayFrame is TEngine + 0x98 through this Type's OWN class table, hence unprefixed;
' the other two go through TPlayer's and TBall's tables and keep their prefixes.
' CODEGEN NOTE -- `If f.frametime > g_replayMax` is 411 bytes; `If g_replayMax < f.frametime`
' is 412. The original emits 39 /r (cmp mem,reg), which per section 10.1 puts the MEMORY
' operand first in source order.
' g_engineFloat (0x00C5B1D4) and g_optionsFloat (0x00C5D23C) -- two DISTINCT
' addresses, 4 bytes apart -- both read 2.0 in NSS5.exe's data section (independently
' confirmed, not a copy-paste). g_engineFloat is the same address as g_engine_float01 in
' TEngine.Render.bmx/EndReplay.bmx and g_engine_zoom in TEngine.SetUpReplay.bmx. See
' codegen-patterns 21.1/21.3.
	Function StartReplay()
		'!Global g_balls:TList
		'!Global g_trainingMode:Int
		'!Global g_engineFloat:Float = 2.0
		'!Global g_optionsFloat:Float = 2.0
		'!Global g_replayFlag:Int
		'!Global g_replayMin:Int
		'!Global g_replayMax:Int
		'!Global g_replayCur:Int
		'!Global g_engineState:Int
		If Not g_balls Then Return 0
		If g_trainingMode > 0 Then Return 0
		g_engineFloat = g_optionsFloat
		FlushAllInput()
		g_replayFlag = 0
		g_replayMin = -1
		g_replayMax = 0
		For Local b:TBall = EachIn g_balls
			For Local f:TReplayFrame = EachIn b.replayframes
				If g_replayMin = -1 Or f.frametime < g_replayMin
					g_replayMin = f.frametime
				End If
				If f.frametime > g_replayMax
					g_replayMax = f.frametime
				End If
			Next
		Next
		g_replayCur = g_replayMin
		TPlayer.UpdateReplayAll(g_replayCur)
		TBall.UpdateReplayAll(g_replayCur)
		UpdateReplayFrame(g_replayCur)
		g_engineState = 3
	End Function
