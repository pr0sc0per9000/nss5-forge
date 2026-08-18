' TScreen_Newspaper.SetUpScreen
' VA 0x00558EBA   307 bytes   vtable slot 0x34
' byte-identical vs NSS5.exe (307/307, original length from Ghidra's inventory, mode=reloc)
'
' g_snd_news:TSound (0x00C6824C) and g_chan_news:TChannel (0x00C6F090) are untyped Objects
' in globals_final; PlaySound's signature fixes them.
' TProfile.helppages is Int[]; [eax+0x40] is element 10 (data at +0x18).
	Function SetUpScreen:Int()
		'!Global g_profile:TProfile
		'!Global g_snd_news:TSound
		'!Global g_chan_news:TChannel
		TScreen.SetActive("newspaper", "btn_play")
		PlaySound(g_snd_news, g_chan_news)
		If g_profile.newsmotm <> 0
			g_profile.CheckAchievement(14)
			Local n:Int = Int(g_profile.GetStat(15,3,0,0))
			n = Int(n + g_profile.GetStat(15,4,0,0))
			If n > 9 Then g_profile.CheckAchievement(15)
			If n > 24 Then g_profile.CheckAchievement(16)
			If n > 49 Then g_profile.CheckAchievement(17)
		EndIf
		If g_profile.helppages[10] = 0
			TScreen.Tutorial()
			g_profile.helppages[10] = 1
		EndIf
	End Function
