' TEngine.EndReplay
' VA 0x004D4989   156 bytes   mode=reloc
' Verified through the oracle from scratch with helper_map.record stubbed; MATCH over
' the full Ghidra-authoritative length, every byte.
' Body-only format: statements only, parameters are a0, a1, ...
' g_engine_float01/float09 original data-section values 2.0/1.0 (0x00C5B1D4,
' 0x00C5D238), read directly from NSS5.exe -- see codegen-patterns 21.1/21.3. Same
' addresses as TEngine.SetUpReplay.bmx's g_engine_zoom/g_engine_zoomdefault.
'!Global g_engine_float01:Float = 2.0
'!Global g_engine_float09:Float = 1.0
'!Global g_engine_int51:Int
'!Global g_engine_int52:Int
'!Global g_engine_int13:Int
'!Global g_engine_tplayer:TPlayer
g_engine_float01 = g_engine_float09
g_engine_int52 = g_engine_int51
UpdateReplayFrame(g_engine_int52)
TPlayer.UpdateReplayAll(g_engine_int52)
TBall.UpdateReplayAll(g_engine_int52)
g_engine_int13 = 2
FlushAllInput()
If Not g_engine_tplayer
	EndMatch()
	Return 0
End If
Local p:TPlayer = TPlayer.GetHumanPlayer()
If p <> Null Then p.joy.kickenabled = 0
Return 0
