' TScreen_MainMenu.ButtonTwitter
' VA 0x0051d9e9   28 bytes   vtable slot 0x74   sig ()i
' byte-identical vs NSS5.exe (28/28, original length from Ghidra's inventory)
' Assumes one module Global g_twitterurl:String (0x00c6ec34); the constant it points at
' in NSS5.exe is "http://twitter.com/newstargames". Passing the literal directly is one
' byte shorter (push imm32 vs push [mem]), so the original really does read a Global.
' OpenURL is BRL.System (0x005B4D14).
	Function ButtonTwitter:Int()
		'!Global g_twitterurl:String
		OpenURL(g_twitterurl)
	End Function
