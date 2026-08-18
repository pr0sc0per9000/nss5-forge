' TPlayer.KeeperDiving
' VA 0x004fcbb8   127 bytes   vtable slot 0x1c4   sig ()i
' byte-identical vs NSS5.exe (127/127, original length from Ghidra's inventory)
' global 0x00c5df00 assumed Int[]; the guard is an early return, not an enclosing If block.
' Parameter names are not recoverable from the binary; a0/a1/... as emitted by the harness.
	Method KeeperDiving:Int()
		'!Global g_player_arr22:Int[]
		If selectionno > 0 Then Return 0
		For Local a:Int = EachIn g_player_arr22
			If imageframenumber = a Then Return 1
			If imageframenumber = a + 64 Then Return 1
			If imageframenumber = a + 128 Then Return 1
		Next
	End Method
