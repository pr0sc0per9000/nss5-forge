' TWeather.SetWeatherTimes
' VA 0x00505012   234 bytes
' byte-identical vs NSS5.exe (234/234, original length from Ghidra's inventory, mode=reloc)
' Driven through the oracle from scratch, with helper_map.record stubbed.
' Body-only format: statements only; parameters are a0, a1, ...
'!Global g_weather_start:Int
'!Global g_weather_finish:Int
'!Global g_weather_type:Int
'!Global g_weather_i1:Int
'!Global g_weather_i2:Int
'!Global g_weather_i3:Int
'!Global g_weather_f1:Float
'!Global g_weather_f2:Float
LogLine("SetWeatherTimes s=" + String(a0) + "  f=" + String(a1))
g_weather_start = a0
g_weather_finish = a1
If g_weather_finish < g_weather_start
	g_weather_finish = g_weather_start + 15
EndIf
g_weather_type = a2
g_weather_i1 = 0
g_weather_i2 = 0
g_weather_i3 = 0
g_weather_f2 = 0
g_weather_f1 = 0
TSnowFlake.ResetAll()
If a0 <= 0 And a1 > 0
	g_weather_f2 = 1.0
	g_weather_f1 = 1.0
EndIf
