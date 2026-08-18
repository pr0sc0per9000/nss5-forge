' TPlayer.DoAnimKick
' VA 0x004FD231   169 bytes   vtable slot 0x1E4   sig (i)i
' byte-identical vs NSS5.exe (169/169, original length from Ghidra's inventory, mode=reloc)
'
' LogLine is the recovered module trace logger; its literal is this function's own name.
' 0x00C5B1FC is an Int Global (compared against 3); globals_final types it TPlayer from a single
' construction site -- wrong for this use.
' 0x00C5DECC and 0x00C5DEB4 are Int[] Globals (animation frame tables).
' TPlayer: currentanim +0x130 ([]i), frame +0x134, lastframetime +0x138, direction +0x78 (f),
' directiontoball +0xCC (i). 0x00C6EFD4 is the millisecond clock Global (Int).
' Module Globals declared by this body (names are ours; the TYPES are load-bearing):
'   Global g_matchstate:Int
'   Global g_anim_kick2:Int[]
'   Global g_anim_kick1:Int[]
'   Global g_millis:Int
	Method DoAnimKick:Int(a0:Int)
		'!Global g_matchstate:Int
		'!Global g_anim_kick2:Int[]
		'!Global g_anim_kick1:Int[]
		'!Global g_millis:Int
		LogLine("DoAnimKick")
		If g_matchstate = 3 Then
			Self.currentanim = g_anim_kick2
		Else
			If a0 < 20 Then Return 0
			Self.currentanim = g_anim_kick1
		End If
		Self.frame = 0
		Self.lastframetime = g_millis
		Self.direction = Self.directiontoball
	End Method
