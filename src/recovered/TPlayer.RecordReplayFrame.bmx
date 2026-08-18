' TPlayer.RecordReplayFrame
' VA 0x004FE3BD   373 bytes   mode=reloc
' Verified through the oracle from scratch with helper_map.record stubbed; MATCH over
' the full Ghidra-authoritative length, every byte.
' Body-only format: statements only, parameters are a0, a1, ...
'!Global g_player_int01:Int         ' 0x00C5B1FC (verified row)
'!Global g_player_selected:TPlayer  ' 0x00C5B248
'!Global g_replay_len:Int           ' 0x00C5B2B4
'!Global g_replay_div:Int           ' 0x00C6F02C
If Not Self.replayframes Then Return 0
Local f:TReplayFrame = New TReplayFrame
f.frametime = a0
f.id = Self.id
f.selno = Self.selectionno
f.obtext = Self.initials
f.obtype = 2
f.clubid = Self.teamid
f.skincol = Self.skincol
f.haircol = Self.haircol
f.bootcol = Self.bootcolint
f.glovecol = Self.glovecolint
f.x = Self.x
f.y = Self.y
f.z = Self.z
f.xvel = Self.xvel
f.yvel = Self.yvel
f.zvel = Self.zvel
f.frame = Self.imageframenumber
f.facing = Self.facing
f.rotation = Self.spriterotation
f.alph = 1.0
f.active = 0
If g_player_int01 = 8 And g_player_selected = Self
	f.active = 1
End If
Self.replayframes.AddLast(f)
While TReplayFrame(Self.replayframes.First()).frametime < a0 - g_replay_len / g_replay_div
	Self.replayframes.RemoveFirst()
Wend
