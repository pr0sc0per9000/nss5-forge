' TScreen_WebPage.ButtonFacebook
' VA 0x005613FA   48 bytes   vtable slot 0x40   sig ()i
' byte-identical vs NSS5.exe (48/48, original length from Ghidra's inventory)
' no assumptions: 0x005B4D14 = _brl_system_OpenURL, 0x004A7C20 = _bbStringConcat,
' PTR_FUN_00C689FC = TScreen_WebPage class table + 0x44 = GetSocialMessage(i)$
	Function ButtonFacebook()
		OpenURL("http://www.facebook.com/dialog/feed?app_id=176264549093321&redirect_uri=http://www.facebook.com/&message=" + TScreen_WebPage.GetSocialMessage(0))
	End Function
