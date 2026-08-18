' TPlayer.Update
' VA 0x004EE11B   453 bytes   mode=reloc
' Verified through the oracle from scratch with helper_map.record stubbed; MATCH over
' the full Ghidra-authoritative length, every byte.
' Body-only format: statements only, parameters are a0, a1, ...
'!Global g_player_chan01:TChannel
'!Global g_player_chan02:TChannel
'!Global g_player_float01:Float
'!Global g_newspaper_img:TImage
'!Global g_player_int01:Int
' g_engine_float01's original data-section value is 2.0 (0x00C5B1D4), read
' directly from NSS5.exe -- see codegen-patterns 21.1/21.3.
'!Global g_engine_float01:Float = 2.0
'!Global g_engine_float02:Float
'!Global g_engine_float03:Float
g_player_chan01.SetVolume(g_player_float01)
g_player_chan02.SetVolume(g_player_float01)
Self.UpdateFundamentals()
Self.UpdateJoy()
Self.UpdateTeamMateId()
Self.UpdateCalling()
Self.CheckKick()
Self.UpdateMovement()
Self.CheckBallContact()
Self.UpdateOffside()
Self.UpdateAnimation()
If Self.newstar And g_newspaper_img = Null And g_player_int01 = 8 And Self.PlayerCelebrating() And TScreenMessage.Count() = 0 And TParticle.Count() = 0
	If Self.currentanim And Self.frame >= Self.currentanim.Length / 2
		Local px:Int = Int(Self.x * g_engine_float01 - g_engine_float02)
		Local py:Int = Int((Self.y - 10.0) * g_engine_float01 - g_engine_float03)
		g_newspaper_img = LoadImage(GrabPixmap(px - 80, py - 55, 160, 110))
	EndIf
EndIf
