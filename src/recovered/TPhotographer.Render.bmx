' TPhotographer.Render
' VA 0x004EB13B   330 bytes   mode=reloc
' Verified through the oracle from scratch with helper_map.record stubbed; MATCH over
' the full Ghidra-authoritative length, every byte.
' Body-only format: statements only, parameters are a0, a1, ...
'!Global g_photographer_imgs:TImage[]
'!Global g_engine_int13:Int
'!Global g_player_int01:Int
'!Global g_engine_int52:Int
'!Global g_player_int50:Int
Local ang:Float = 0.25
Local img:TImage = Null
Select Self.facing
	Case 3
		img = g_photographer_imgs[0]
		ang = -ang
	Case 4
		img = g_photographer_imgs[0]
	Case 2
		img = g_photographer_imgs[1]
	Case 1
		img = g_photographer_imgs[2]
End Select
Local fl:Int = 0
If g_engine_int13 <> 1 And g_player_int01 = 8
	If g_engine_int13 = 3
		If g_engine_int52 Mod Self.flashmod = 1 Then fl = 3
	Else
		If g_player_int50 Mod Self.flashmod = 1 Then fl = 3
	EndIf
EndIf
TDrawOb.AddDrawOb(img, Self.x, Self.y, 0, Self.pose + fl, 3, 1.0, 0, "FFFFFF", ang, 0.25, 3, 0, "", 0, 0)
TDrawOb.AddDrawOb(img, Self.x, Self.y, 0, Self.pose, 2, 0.3, 20, "000000", ang * 1.0, 0.2, 3, 0, "", 0, 0)
