' TPlayer.DoAnimDive
' VA 0x004FCFC4   133 bytes
' byte-identical vs NSS5.exe (133/133, original length from Ghidra's inventory, mode=reloc)
' Verified through the oracle from scratch, with helper_map.record stubbed.
' Body-only format: statements only; parameters are a0, a1, ...
'!Global g_player_anim_dive:Int[]      ' 0x00C5DEC0
'!Global g_player_f07:Float            ' 0x00C5DE58
'!Global g_player_f08:Float            ' 0x00C5DE5C
LogLine("DoAnimDive")
Self.currentanim = g_player_anim_dive
Self.frame = 0
Self.joy.Clear()
Self.xvel = Self.xvel * g_player_f07
Self.yvel = Self.yvel * g_player_f07
Self.zvel = g_player_f08 * 0.75
