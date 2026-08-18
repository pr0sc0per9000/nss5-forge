' TBall.Compare
' VA 0x004cd25b   96 bytes   vtable slot 0x1c   sig (:Object)i
' byte-identical vs NSS5.exe (96/96, original length from Ghidra's inventory)
' the guard must be a one-case Select, not an If: an If emits 'cmp [mem],1' where the original loads the global into a register first. Global at 0x00c5a4c4 assumed Int
	Method Compare:Int(a0:Object)
		'!Global g_ball_sortmode:Int
		Select g_ball_sortmode
			Case 1
				If id < TBall(a0).id Then Return -1
				If id > TBall(a0).id Then Return 1
		End Select
		Return 0
	End Method
