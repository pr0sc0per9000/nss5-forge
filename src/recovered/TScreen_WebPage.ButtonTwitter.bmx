' TScreen_WebPage.ButtonTwitter
' VA 0x005613ca   48 bytes   vtable slot 0x3c   sig ()i
' byte-identical vs NSS5.exe (48/48, original length from Ghidra's inventory)
' string literal read directly out of NSS5.exe's data section; OpenURL = BRL _brl_system_OpenURL
	Function ButtonTwitter:Int()
		OpenURL("http://twitter.com/?status="+TScreen_WebPage.GetSocialMessage(1))
	End Function
