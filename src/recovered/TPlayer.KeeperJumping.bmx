' TPlayer.KeeperJumping
' VA 0x004FCC37   202 bytes   vtable slot 0x1c8   sig ()i
' byte-identical vs NSS5.exe (202/202, original length from Ghidra's inventory)
' mode 'reloc': absolute addresses masked, emitted code identical
' module global assumed: Global g_player_arr24:Int[]
' module global assumed: Global g_player_arr25:Int[]

	Method KeeperJumping:Int()
		'!Global g_player_arr24:Int[]
		'!Global g_player_arr25:Int[]
		For Local f:Int = EachIn g_player_arr24
			If imageframenumber = f Then Return 1
			If imageframenumber = f + 64 Then Return 1
			If imageframenumber = f + 128 Then Return 1
		Next
		For Local f:Int = EachIn g_player_arr25
			If imageframenumber = f Then Return 1
			If imageframenumber = f + 64 Then Return 1
			If imageframenumber = f + 128 Then Return 1
		Next
		Return 0
	End Method
