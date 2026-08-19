' TEngine.PauseSounds
' VA 0x004d5ff6   111 bytes   vtable slot 0xc8   sig ()i
' byte-identical vs NSS5.exe (111/111, original length from Ghidra's inventory)
' assumes: six TChannel Globals; PauseChannel/ResumeChannel from brl.audio; LogLine arg is the function's own name
	Function PauseSounds:Int()
		'!Global g_snd_chan1:TChannel
		'!Global g_snd_chan2:TChannel
		'!Global g_snd_chan3:TChannel
		'!Global g_snd_chan4:TChannel
		'!Global g_snd_chan5:TChannel
		'!Global g_musicchannel:TChannel
		LogLine("PauseSounds")
		PauseChannel(g_snd_chan1)
		PauseChannel(g_snd_chan2)
		PauseChannel(g_snd_chan3)
		PauseChannel(g_snd_chan4)
		PauseChannel(g_snd_chan5)
		ResumeChannel(g_musicchannel)
	End Function
