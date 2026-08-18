' TTarget.Create
' VA 0x005844B7   217 bytes   mode=reloc
' Driven through the oracle from scratch with helper_map.record stubbed; MATCH over the
' full Ghidra-authoritative length, every byte.
' Body-only format: statements only, parameters are a0, a1, ...
'!Global g_targetimg:TImage
'!Global g_targetsnd:TSound
If Not g_targetimg
	g_targetimg = LoadImageChecked("EngineMedia/Match/Pitch/Target.png", -1)
	MidHandleImage(g_targetimg)
	g_targetsnd = LoadSoundChecked("EngineMedia/Match/Sounds/PoleBoing.ogg", 0)
End If
Local t:TTarget = New TTarget
t.img = g_targetimg
t.x = a0
t.y = a1
