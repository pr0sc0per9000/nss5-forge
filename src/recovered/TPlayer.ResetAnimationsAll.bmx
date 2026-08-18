' TPlayer.ResetAnimationsAll
' VA 0x004fe265   160 bytes   vtable slot 0x1f8   sig ()i
' byte-identical vs NSS5.exe (160/160, original length from Ghidra's inventory)
' assumptions / Globals declared:
'   0x00c5de10 TList  (globals_final g_Object79:Object, untyped; slot 0x8c = ObjectEnumerator)
'   0x00c5deac Int[]  (globals_final g_player_arr01:Object[] init=bbEmptyArray; the field it
'                      is assigned to is TPlayer.currentanim:[]i, so Int[])
' FUN_00505b91 = the recovered module Function LogLine, literal = this function's own name.
' EachIn class table 0x00c5f94c = TPlayer.
' puVar5[0x4c] = +0x130 = TPlayer.currentanim; puVar5[0x4d] = +0x134 = TPlayer.frame.
' The inlined BBRETAIN/BBRELEASE around the array store is compiler-emitted, not source.
	Function ResetAnimationsAll:Int()
		'!Global g_players:TList
		'!Global g_defaultanim:Int[]
		LogLine("ResetAnimationsAll")
		For Local p:TPlayer = EachIn g_players
			p.currentanim = g_defaultanim
			p.frame = 0
		Next
	End Function
