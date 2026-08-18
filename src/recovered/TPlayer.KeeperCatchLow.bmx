' TPlayer.KeeperCatchLow
' VA 0x004F43D2   79 bytes   vtable slot 0xC0   sig ()i
' byte-identical vs NSS5.exe (79/79, original length from Ghidra's inventory)
' Assumption: module Global 0x00c5df18 declared Int[] (it is assigned to
' TPlayer.currentanim, whose reflected type is []i, so the type is forced).
' FUN_00505B91 is the recovered module Function LogLine; its literal is the caller's name.
	Method KeeperCatchLow()
		'!Global g_player_anim_keepercatchlow:Int[]
		LogLine("KeeperCatchLow")
		currentanim = g_player_anim_keepercatchlow
		frame = 0
	End Method
