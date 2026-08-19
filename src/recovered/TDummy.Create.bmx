' TDummy.Create
' VA 0x0058338F   242 bytes   mode=reloc
' byte-identical vs NSS5.exe
' Verified through the oracle from scratch with helper_map.record stubbed; MATCH over
' the full Ghidra-authoritative length, every byte.
' Body-only format: statements only, parameters are a0, a1, ...
'!Global g_dummy_img:TImage
'!Global g_dummy_snd:TSound
If Not g_dummy_img
	g_dummy_img = LoadAnimImageChecked("EngineMedia/Match/Pitch/Dummies.png", 32, 82, 0, 3, -1)
	SetImageHandle(g_dummy_img, 16.0, 81.0)
	g_dummy_snd = LoadSoundChecked("EngineMedia/Match/Sounds/ConeHit.ogg", 0)
End If
Local d:TDummy = New TDummy
d.img = g_dummy_img
d.frame = 0
d.x = a0
d.y = a1
Return 0
