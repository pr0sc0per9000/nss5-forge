' TPlayer.DoAnimCommiserate
' VA 0x004FE16F   246 bytes
' byte-identical vs NSS5.exe (246/246, original length from Ghidra's inventory, mode=reloc)
' Verified through the oracle from scratch, with helper_map.record stubbed.
' Body-only format: statements only; parameters are a0, a1, ...
'!Global g_anim_comm_a:Int[]
'!Global g_anim_comm_b:Int[]
'!Global g_anim_comm_c:Int[]
'!Global g_anim_comm_d:Int[]
Select a0
	Case 2
		Self.currentanim = g_anim_comm_a
		Self.xvel = 0
	Case 3
		Self.currentanim = g_anim_comm_b
		Self.xvel = 0
	Case 0
		Self.currentanim = g_anim_comm_c
		Self.yvel = 0
	Case 1
		Self.currentanim = g_anim_comm_d
		Self.yvel = 0
End Select
Self.frame = 0
Self.joy.Clear()
