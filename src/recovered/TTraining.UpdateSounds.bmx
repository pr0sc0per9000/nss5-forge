' TTraining.UpdateSounds
' VA 0x00580001   200 bytes   vtable slot 0x5c   sig ()i
' byte-identical vs NSS5.exe (200/200, original length from Ghidra's inventory)
' Globals: g_options_float01:Float (0x00c5d220), g_ch1/g_ch2/g_ch3:TChannel
'          (0x00c5b340/44/48), g_weather_int02:Int (0x00c600d8), g_training_arr:TSound[]
'          (0x00c6cf70). 0x00c92908 = 100.0 and 0x00c9290c = 0.5 are .rdata Float constants.
' The condition must be TWO NESTED Ifs: bcc emits a bare comparison as the If condition
' with cmp/jne directly, but materialises an `And` expression with sete/movzx.  Folding
' all three tests into one If costs 9 extra bytes.
	Function UpdateSounds:Int()
		'!Global g_options_float01:Float = 100.0
		'!Global g_ch1:TChannel
		'!Global g_ch2:TChannel
		'!Global g_ch3:TChannel
		'!Global g_weather_int02:Int
		'!Global g_training_arr:TSound[]
		Local v:Float = g_options_float01 / 100.0
		g_ch1.SetVolume(v * 0.5)
		g_ch2.SetVolume(v)
		g_ch3.SetVolume(v)
		If ChannelPlaying(g_ch1) = 0
			If Rand(500) = 1 And g_weather_int02 = 0
				PlaySound(g_training_arr[Rand(0,3)],g_ch1)
			EndIf
		EndIf
	End Function
