' TPlayer.KeeperJump
' VA 0x004F4470   88 bytes   vtable slot 0xC8   sig ()i
' byte-identical vs NSS5.exe (88/88, original length from Ghidra's inventory, mode=reloc)
' Assumptions:
'   LogLine is the recovered module-level entry tracer; its literal is this function's name.
'   module Global at 0x00C5DF08 declared Int[] -- it is assigned into TPlayer.currentanim,
'   which object_model gives as `currentanim:Int[]` at +0x130, and the assignment carries
'   the inlined BBRETAIN/BBRELEASE pair (inc [ebx+4] / dec [eax+4] / bbGCFree).
'   CORRECTED: zvel (+0x6C, Float) was set from a literal placeholder 1.5. 0x00C5DE5C
'   is g_player_float08 -- already named in globals_final.tsv, and the sibling
'   TPlayer.KeeperDive.bmx already reads the identical Global for the identical purpose
'   ("Self.zvel = g_player_float08"). Not a numeric constant; fixed to read the Global.
'   Re-verified MATCH 88/88.

	Method KeeperJump:Int()
		'!Global g_player_anim_keeperjump:Int[]
		'!Global g_player_float08:Float
		LogLine("KeeperJump")
		currentanim = g_player_anim_keeperjump
		frame = 0
		zvel = g_player_float08
	End Method
