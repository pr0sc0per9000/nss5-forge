' TPlayer.DoAnimSlide
' VA 0x004FD049   294 bytes
' byte-identical vs NSS5.exe (294/294, original length from Ghidra's inventory, mode=reloc)
' Verified through the oracle from scratch, with helper_map.record stubbed.
' Body-only format: statements only; parameters are a0, a1, ...
'!Global g_ball:TBall                  ' 0x00C5DEA4 (verified row)
'!Global g_snd_slide:TSound            ' 0x00C5DF34
'!Global g_chan_slide:TChannel         ' 0x00C5DF2C
'!Global g_player_anim_slide:Int[]     ' 0x00C5DEBC
'!Global g_player_f07:Float
'!Global g_match_time:Int              ' 0x00C6EFD4
LogLine("DoAnimSlide")
If g_ball And g_ball.KeeperHolding() Then Return 0
PlaySound(g_snd_slide, g_chan_slide)
Self.currentanim = g_player_anim_slide
Self.frame = 0
Self.joy.Clear()
Self.xvel = Self.xvel * Self.tackling
Self.yvel = Self.yvel * Self.tackling
Self.slide_start = g_match_time
TPitchMark.AddPitchMark(Int(Self.x + Self.xvel * g_player_f07), Int(Self.y + Self.yvel * g_player_f07), Int(Self.direction), 1, 0.5)
