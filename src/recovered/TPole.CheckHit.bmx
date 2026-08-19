' TPole.CheckHit
' VA 0x00583A50   349 bytes   mode=reloc
' byte-identical vs NSS5.exe
' Verified through the oracle from scratch with helper_map.record stubbed; MATCH over
' the full Ghidra-authoritative length, every byte.
' Body-only format: statements only, parameters are a0, a1, ...
' g_pole_maxz's original data-section value is 100.0 (read from NSS5.exe at
' 0x00C92BFC, the address bcc's `fld dword ptr` here resolves to). Never stored to
' anywhere in the corpus, so a bare pragma defaulted the assembled build to 0 -- see
' codegen-patterns 21.1.
'!Global g_pole_maxz:Float = 100.0
'!Global g_pole_sound:TSound
'!Global g_pole_chan:TChannel
If Self.colour = "FF0000" Then Return 0
Local hit:Int = 0
Local b:TBall = TBall.GetActiveBall()
If b And Dist2D(Self.x, Self.y, b.x, b.y) < TPitch.YardsToPixels(0.6) And b.z < g_pole_maxz
	hit = 1
EndIf
If Self.colour <> "0000FF"
	Local h:TPlayer = TPlayer.GetHumanPlayer()
	If h And Dist2D(Self.x, Self.y, h.x, h.y) < TPitch.YardsToPixels(0.75)
		hit = 1
	EndIf
EndIf
If hit
	Self.alive = 0
	Self.wobbling = 1
	Self.colour = "FF0000"
	PlaySound(g_pole_sound, g_pole_chan)
EndIf
