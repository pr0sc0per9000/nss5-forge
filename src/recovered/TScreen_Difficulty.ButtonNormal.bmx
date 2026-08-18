' TScreen_Difficulty.ButtonNormal
' VA 0x00525D72   50 bytes   vtable slot 0x3c   sig ()i
' byte-identical vs NSS5.exe (50/50, original length from Ghidra's inventory)
' ASSUMPTIONS: module Global 0x00C5D228 :Int, 0x00C64504 :String. The second is load-bearing: the original LOADS a pointer from 0x00C64504 (a String Global), it does not take its address the way a literal would.
' TOptions.SaveOptions and TScreen.SetActive resolved to TOptions+0x48 and TScreen+0x5C on both sides. harness mode=reloc.

	Function ButtonNormal:Int()
		'!Global g_difficulty:Int
		'!Global g_nextscreen:String
		g_difficulty = 2
		TOptions.SaveOptions()
		TScreen.SetActive(g_nextscreen, "")
	End Function
