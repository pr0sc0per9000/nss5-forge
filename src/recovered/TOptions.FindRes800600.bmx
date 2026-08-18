' TOptions.FindRes800600
' VA 0x004e47d9   145 bytes   vtable slot 0x50   sig ()i
' byte-identical vs NSS5.exe (145/145, original length from Ghidra's inventory)
' Globals: g_gfxmodes:TList (0x00c60500; ObjectEnumerator at slot 0x8c confirms TList)
	Function FindRes800600:Int()
		'!Global g_gfxmodes:TList
		Local n:Int = 0
		For Local m:TMyGfxModes = EachIn g_gfxmodes
			If m.w = 800 And m.h = 600 Then Return n
			n = n + 1
		Next
		Return 0
	End Function
