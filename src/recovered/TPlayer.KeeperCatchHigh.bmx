' TPlayer.KeeperCatchHigh
' VA 0x004f4421   79 bytes   vtable slot 0xc4   sig ()i
' byte-identical vs NSS5.exe (79/79, original length from Ghidra's inventory)
' 0x00C5DF10 : Int[] -- assigned to TPlayer.currentanim ([]i at +0x130); refcount pair is the array BBRETAIN/BBRELEASE
' Global: Global g_anim_keepercatchhigh:Int[]
	Method KeeperCatchHigh:Int()
		'!Global g_anim_keepercatchhigh:Int[]
		LogLine("KeeperCatchHigh")
		currentanim = g_anim_keepercatchhigh
		frame = 0
	End Method
