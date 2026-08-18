' TEngine.RenderReplay
' VA 0x004d5349   199 bytes   vtable slot 0xb0   sig (f)i
' byte-identical vs NSS5.exe (199/199, original length from Ghidra's inventory)
' assumes: six Float Globals; operand order cam*t first then old*(1-t) - swapping costs 6 bytes
' g_camz (0x00C5B1D4) original data-section value is 2.0, read directly from
' NSS5.exe -- confirmed by per-refs instruction-offset walk, same address as
' g_engine_float01 in TEngine.Render/EndReplay.bmx and g_engine_zoom in
' TEngine.SetUpReplay.bmx. g_camx/g_camy/g_oldcamx/g_oldcamy/g_oldcamz (0x00C5B1D8/DC/E0/
' E4/E8) all read genuinely 0.0 in the original -- not the same defect. See
' codegen-patterns 21.1/21.3.
	Function RenderReplay:Int(a0:Float)
		'!Global g_camx:Float
		'!Global g_camy:Float
		'!Global g_camz:Float = 2.0
		'!Global g_oldcamx:Float
		'!Global g_oldcamy:Float
		'!Global g_oldcamz:Float
		Local x:Float = g_camx * a0 + g_oldcamx * (1.0 - a0)
		Local y:Float = g_camy * a0 + g_oldcamy * (1.0 - a0)
		Local z:Float = g_camz * a0 + g_oldcamz * (1.0 - a0)
		TPitch.Render(z, x, y)
		TPitchMark.RenderReplay()
		TPlayer.RenderReplayAll(a0)
		TBall.RenderReplayAll(a0)
		TDrawOb.RenderAll(z, x, y)
		TWeather.Render(1)
		RenderReplayGUI()
		RenderReplayRadar()
	End Function
