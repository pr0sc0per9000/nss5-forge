' TPlayer.ImageJumping
' VA 0x004fc8e1   111 bytes   vtable slot 0x1a4   sig ()i
' byte-identical vs NSS5.exe (111/111, original length from Ghidra's inventory)
' global 0x00c5df20 assumed Int[]; EachIn over an array is the pointer-walk form.
' Parameter names are not recoverable from the binary; a0/a1/... as emitted by the harness.
	Method ImageJumping:Int()
		'!Global g_player_arr30:Int[]
		For Local a:Int = EachIn g_player_arr30
			If imageframenumber = a Then Return 1
			If imageframenumber = a + 64 Then Return 1
			If imageframenumber = a + 128 Then Return 1
		Next
	End Method
