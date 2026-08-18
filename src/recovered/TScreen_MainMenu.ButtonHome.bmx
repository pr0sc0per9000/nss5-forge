' TScreen_MainMenu.ButtonHome
' VA 0x0051d9b1   28 bytes   vtable slot 0x6c   sig ()i
' byte-identical vs NSS5.exe (28/28, original length from Ghidra's inventory)
' ASSUMPTION: module Global at 0x00c6ea98 declared String (the home-page URL).
' It is a Global, not a literal: the original pushes [0xc6ea98], not its address.
	Function ButtonHome:Int()
		'!Global g_homeurl:String
		OpenURL(g_homeurl)
	End Function
