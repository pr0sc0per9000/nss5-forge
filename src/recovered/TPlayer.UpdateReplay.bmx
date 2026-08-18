' TPlayer.UpdateReplay
' VA 0x004FE59E   320 bytes   mode=reloc
' Verified through the oracle from scratch with helper_map.record stubbed; MATCH over
' the full Ghidra-authoritative length, every byte.
' Body-only format: statements only, parameters are a0, a1, ...
'!Global g_player_int16:Int
Self.oldx = Self.x
Self.oldy = Self.y
Self.oldz = Self.z
For Local rf:TReplayFrame = EachIn Self.replayframes
	If rf.frametime = a0
		Self.x = rf.x
		Self.y = rf.y
		Self.z = rf.z
		Self.xvel = rf.xvel
		Self.yvel = rf.yvel
		Self.zvel = rf.zvel
		Self.facing = rf.facing
		Self.spriterotation = rf.rotation
		Self.imageframenumber = rf.frame
		Self.obtext = rf.obtext
		Return 0
	ElseIf rf.frametime > a0
		Self.oldx = -g_player_int16 - 20
		Self.oldy = 0
		Self.x = -g_player_int16 - 20
		Self.y = 0
		Self.facing = 1
		Self.imageframenumber = 0
		Return 0
	End If
Next
Return 0
