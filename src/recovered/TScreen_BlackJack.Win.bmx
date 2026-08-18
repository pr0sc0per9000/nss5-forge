' TScreen_BlackJack.Win
' VA 0x00576b03   79 bytes   vtable slot 0x44   sig ()i
' byte-identical vs NSS5.exe (79/79, original length from Ghidra's inventory, mode=reloc)
' Globals: 0x00C6F0D4 g_snd_win:TSound, 0x00C6F090 g_chan:TChannel,
'          0x00C6F028 g_profile:TProfile, 0x00C6B85C g_bet:Int.
' 0x0059B25E = _brl_audio_PlaySound. TProfile slot 0xFC = UpdateBank, 0x150 = CheckAchievement.
	Function Win:Int()
		'!Global g_snd_win:TSound
		'!Global g_chan:TChannel
		'!Global g_profile:TProfile
		' g_bet is another alias for the same 0x00C6B85C address (see
		' TScreen_BlackJack.ButtonPlay.bmx's g_screen_blackjack_int01 = 50).
		'!Global g_bet:Int = 50
		PlaySound(g_snd_win, g_chan)
		g_profile.UpdateBank(g_bet * 2)
		g_profile.CheckAchievement(75)
	End Function
