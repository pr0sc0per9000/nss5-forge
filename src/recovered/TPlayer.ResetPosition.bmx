' TPlayer.ResetPosition
' VA 0x004fad47   132 bytes   vtable slot 0x15c   sig ()i
' byte-identical vs NSS5.exe (132/132, original length from Ghidra's inventory)
' slot 0x84 is TPlayer.ForceControlCPU per vtable_map.tsv; global 0x00c5deac assumed Int[].
' Parameter names are not recoverable from the binary; a0/a1/... as emitted by the harness.
	Method ResetPosition:Int()
		'!Global g_player_arr01:Int[]
		If Not ForceControlCPU() Then Return 0
		x = desx
		y = desy
		z = 0
		oldx = x
		oldy = y
		xvel = 0
		yvel = 0
		currentanim = g_player_arr01
		frame = 0
	End Method
