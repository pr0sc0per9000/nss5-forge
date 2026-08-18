' TEngine.ResumeSounds
' VA 0x004D6065   146 bytes   vtable slot 0xCC   sig ()i
' byte-identical vs NSS5.exe (146/146, original length from Ghidra's inventory, mode=reloc)
' Assumptions: FUN_00505B91 = LogLine; 0x00C5BAF0 = TEngine class table + 0xC0 =
' UpdateSounds (sibling Function, unqualified); FUN_0059B37E = _brl_audio_ResumeChannel,
' FUN_0059B25E = _brl_audio_PlaySound. Global 0x00C6CF90:Int. The six channel Globals
' (0x00C5B340, 0x00C5B344, 0x00C5B348, 0x00C5B33C, 0x00C600D4, 0x00C6F08C) and the sound
' Global 0x00C5B354 are untyped in globals_final.tsv; they are typed here from their
' position in the ResumeChannel/PlaySound argument lists.
'
' NOTE the qualified type names. The harness emits a game-Type stub called TChannel
' (it is in class_tables.tsv), which collides with BRL.Audio's own TChannel and makes bcc
' report "Unable to convert from 'TChannel' to 'TChannel'". Writing the Global's type as
' brl.audio.TChannel selects the module type and the body builds. Same trick works for
' TImage/TSound/TPixmap.
	Function ResumeSounds:Int()
		'!Global g_training_int03:Int
		'!Global g_eng_ch1:brl.audio.TChannel
		'!Global g_eng_snd1:brl.audio.TSound
		'!Global g_eng_ch2:brl.audio.TChannel
		'!Global g_eng_ch3:brl.audio.TChannel
		'!Global g_eng_ch4:brl.audio.TChannel
		'!Global g_eng_ch5:brl.audio.TChannel
		'!Global g_eng_ch6:brl.audio.TChannel
		LogLine("ResumeSounds")
		UpdateSounds()
		If g_training_int03 = 0
			ResumeChannel(g_eng_ch1)
			PlaySound(g_eng_snd1, g_eng_ch1)
			ResumeChannel(g_eng_ch2)
			ResumeChannel(g_eng_ch3)
		EndIf
		ResumeChannel(g_eng_ch4)
		ResumeChannel(g_eng_ch5)
		ResumeChannel(g_eng_ch6)
	End Function
