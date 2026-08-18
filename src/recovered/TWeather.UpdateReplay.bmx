' TWeather.UpdateReplay
' VA 0x005052c8   59 bytes   vtable slot 0x40   sig (f,i)i
' byte-identical vs NSS5.exe (59/59, original length from Ghidra's inventory)
' assumes module global:  Global g_weather_int01:Int
' global 0x00c600c4; empty Case 1 is real; UpdateReplayRain is TWeather slot 0x44

	Function UpdateReplay:Int(a0:Float, a1:Int)
		'!Global g_weather_int01:Int
		Select g_weather_int01
			Case 0
				UpdateReplayRain(a0, a1)
			Case 1
		End Select
	End Function
