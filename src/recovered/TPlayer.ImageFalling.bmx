' TPlayer.ImageFalling
' VA 0x004fc950   111 bytes   vtable slot 0x1a8   sig ()i
' byte-identical vs NSS5.exe (111/111, original length from Ghidra's inventory)
' global 0x00c5df24 assumed Int[].
' Parameter names are not recoverable from the binary; a0/a1/... as emitted by the harness.
	Method ImageFalling:Int()
		'!Global g_player_arr31:Int[]
		For Local a:Int = EachIn g_player_arr31
			If imageframenumber = a Then Return 1
			If imageframenumber = a + 64 Then Return 1
			If imageframenumber = a + 128 Then Return 1
		Next
	End Method
