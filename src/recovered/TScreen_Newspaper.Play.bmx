' TScreen_Newspaper.Play
' VA 0x00558fed   131 bytes   vtable slot 0x38   sig ()i
' byte-identical vs NSS5.exe (131/131, original length from Ghidra's inventory)
' assumptions: module Global at 0x00c68244 declared as g_newsobj:Object
'              module Global at 0x00c6f028 declared as g_profile:TProfile
' NOTE: Ghidra renders the "" literal's refcount bump (mov ebx,0xc5d284 / inc [ebx+4]) as
'       a bogus "DAT_00c5d288 = DAT_00c5d288 + 1"; there is no such statement.
	Function Play:Int()
		'!Global g_newsobj:Object
		'!Global g_profile:TProfile
		g_newsobj=Null
		g_profile.newsheadline=""
		g_profile.newsmotm=0
		g_profile.newsrating=0
		TScreen_GameMenu.SetUpScreen()
		g_profile.NextPlayButton()
	End Function
