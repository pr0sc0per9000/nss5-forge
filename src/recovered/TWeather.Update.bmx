' TWeather.Update
' VA 0x005050fc   166 bytes   vtable slot 0x38   sig (i)i
' byte-identical vs NSS5.exe (166/166, original length from Ghidra's inventory)
' assumptions / Globals declared (all typed from globals_final):
'   0x00c600c4 Int   g_weather_int01   (mode selector)
'   0x00c600d8 Int   g_weather_int02
'   0x00c600e4 Float g_weather_float01
'   0x00c600ec Int   g_weather_int05
'   0x00c600f0 Int   g_weather_int06
' 0x00c60208 = TWeather classtable+0x3c -> TWeather.UpdateRain()
' 0x00c6040c = TSnowFlake classtable+0x38 -> TSnowFlake.UpdateAll(i)i
' FUN_00505f90 = the recovered module Function ClampFloat; _DAT_00c7baa4 = 0.0005.
' Ghidra's `DAT_00c600d8 = (uint)(DAT_00c600ec < param_1)` is a collapsed store-0 /
'   conditional store-1 pair, not a materialised comparison -- the sete form is 143 bytes.
' Both conditionals are Select blocks (the subject is loaded once into eax and compared
'   twice), and the inner one really does carry an empty `Case 0`.
	Function Update:Int(a0:Int)
		'!Global g_weather_int02:Int
		'!Global g_weather_int05:Int
		'!Global g_weather_int06:Int
		'!Global g_weather_int01:Int
		'!Global g_weather_float01:Float
		g_weather_int02 = 0
		If a0 > g_weather_int05 Then g_weather_int02 = 1
		If a0 > g_weather_int06 Then g_weather_int02 = 0
		Select g_weather_int01
			Case 0
				TWeather.UpdateRain()
			Case 1
				Select g_weather_int02
					Case 1
						g_weather_float01 = g_weather_float01 + 0.0005
					Case 0
				End Select
				ClampFloat(Varptr g_weather_float01, 0, 1.0)
				TSnowFlake.UpdateAll(g_weather_int02)
		End Select
	End Function
