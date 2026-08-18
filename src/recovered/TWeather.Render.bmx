' TWeather.Render
' VA 0x0050538D   135 bytes   vtable slot 0x48   sig (i)i
' byte-identical vs NSS5.exe (135/135, original length from Ghidra's inventory), harness mode=reloc
' Assumptions (module Globals -- names ours, declared types load-bearing):
'   * 0x00C600E4 : Float (globals_final, x87 dword access, high)
'   * 0x00C600C4 : Int   (globals_final, medium)
'   * 0x00C600C8 : TImage -- globals_final says `Object` (low); it is the image argument of
'     0x005AD918 = _brl_max2d_TileImage.
'   * 0x00C600DC : Int, 0x00C600E0 : Int
'   * 0x00C60418 -> class table TSnowFlake + 0x44 = TSnowFlake.RenderAll()i
'   * SetAlpha  = 0x005ADC28 (alias set; SetAlpha is the member that fits a Float argument).
' SHAPE (measured):
'   * the two-way test is a Select with no Default (`cmp/je body0; cmp/je body1; jmp end`),
'     not If/ElseIf. The subject is loaded once into EAX.
'   * the y argument must be spelled `0 - (scroll Mod 128)`, not `-(scroll Mod 128)`:
'     the original evaluates the zero first (`mov ebx,0` before `idiv`) and the unary form
'     comes out 5 bytes short (130/135).
	'!Global g_weather_alpha:Float
	'!Global g_weather_type:Int
	'!Global g_weather_img:TImage
	'!Global g_weather_scroll:Int
	'!Global g_weather_frame:Int
	Function Render:Int(a0:Int)
		SetAlpha(g_weather_alpha)
		Select g_weather_type
			Case 0
				TileImage(g_weather_img, 0, 0 - (g_weather_scroll Mod 128), g_weather_frame)
			Case 1
				If a0 = 0 Then TSnowFlake.RenderAll()
		End Select
		SetAlpha(1.0)
	End Function
