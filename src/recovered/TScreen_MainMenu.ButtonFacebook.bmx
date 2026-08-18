' TScreen_MainMenu.ButtonFacebook
' VA 0x0051d9cd   28 bytes   vtable slot 0x70   sig ()i
' byte-identical vs NSS5.exe (28/28, original length from Ghidra's inventory)
' assumes module global:  Global g_url_facebook:String   (0x00c6ebe4)
'   -- the original pushes [0xc6ebe4], i.e. a String Global, NOT an inline literal
'      (a literal would emit `push imm32` and is one byte shorter)
' relies on BRL name _brl_system_OpenURL at 0x005b4d14

	Function ButtonFacebook:Int()
		'!Global g_url_facebook:String
		OpenURL(g_url_facebook)
	End Function
