' TEngine.Render
' byte-identical vs NSS5.exe
' VA 0x004D0309   282 bytes   mode=reloc
' Verified through the oracle from scratch with helper_map.record stubbed; MATCH over
' the full Ghidra-authoritative length, every byte.
' Body-only format: statements only, parameters are a0, a1, ...
' g_engine_float01's original data-section value is 2.0 (0x00C5B1D4), read
' directly from NSS5.exe -- see codegen-patterns 21.1/21.3.
'!Global g_engine_float01:Float = 2.0
'!Global g_engine_float02:Float
'!Global g_engine_float03:Float
'!Global g_engine_float04:Float
'!Global g_engine_float05:Float
'!Global g_engine_float06:Float
' g_engine_oldx/oldy/oldz's original data-section values are all 1.0 (read from
' NSS5.exe at 0x00C73D5C/60/64, consecutive, in that order). Never stored to anywhere in
' the corpus -- see codegen-patterns 21.1.
'!Global g_engine_oldx:Float = 1.0
'!Global g_engine_oldy:Float = 1.0
'!Global g_engine_oldz:Float = 1.0
'!Global g_training_int03:Int
Local a:Float = g_engine_float02 * a0 + g_engine_float04 * (g_engine_oldx - a0)
Local b:Float = g_engine_float03 * a0 + g_engine_float05 * (g_engine_oldy - a0)
Local c:Float = g_engine_float01 * a0 + g_engine_float06 * (g_engine_oldz - a0)
TPitch.Render(c, a, b)
TPitchMark.Render()
TTraining.Render()
TPlayer.RenderAll(a0)
TBall.RenderAll(a0)
TDrawOb.RenderAll(c, a, b)
TWeather.Render(0)
TPlayer.RenderGUIAll(c, g_engine_float01)
If g_training_int03
	TTraining.RenderScoreboard(a0)
Else
	RenderRadar()
	RenderScoreboard()
EndIf
TParticle.RenderParticlesAll(c, a, b)
TBossMessage.DrawAll(c, a, b)
