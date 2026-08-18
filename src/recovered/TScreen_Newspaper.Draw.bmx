' TScreen_Newspaper.Draw
' VA 0x00559070   480 bytes   class-table slot 0x3C   sig ()i   KIND=Function (static)
' byte-identical vs NSS5.exe (480/480, original length from Ghidra's inventory, mode=reloc,
' reloc_masked=35)
'
' ASSUMPTIONS
'  Module Globals -- NAMES ARE OURS, declared TYPES are load-bearing:
'    0x00C68244 TImage    g_np_photo  (globals_final Object/low; used as arg1 of DrawImageRect)
'    0x00C68230 TImage    g_np_bg1    (arg1 of DrawImage)
'    0x00C68234 TImage    g_np_bg2    (arg1 of DrawImage)
'    0x00C68240 TImage[]  g_np_heads  (globals_final Object[]/medium; indexed then passed
'                                      to DrawImage, so the element type is TImage)
'    0x00C6F028 TProfile  g_profile   (globals_final construction/high)
'    0x00C6EFDC Int       g_screen_x
'    0x00C68248 TImage    g_np_star
'  Fields: TProfile +0x24 playercols(:TPlayerColours), +0x44 newsheadline($),
'          +0x48 newsrating(i), +0x4C newsmotm(i);  TPlayerColours +0x08 skin(i).
'  Slots resolved:
'    [0x00C5BB34] = TEngine class table + 0x104 = TEngine.DrawMyText($,f,f,i,i,f,f,$,i)i
'  Module Functions (src/recovered_module/): 0x00506456 = SetDrawStateHex,
'    0x0050640C = FormatDecimals, 0x004C5549 = GetText (ONE arg).
'  BRL: 0x005AD711 DrawImage, 0x005AD7C8 DrawImageRect, 0x004A7410 _brl_retro_Lower.
'  Literals: 0x00C5D680 "FFFFFF", 0x00C8B9E0 "Your Rating", 0x00C8BA08 "Star Man!";
'    0x00C8BA04 is the Float constant 10.0.
'  MEASURED CORRECTION: the x for the "Your Rating" line is 545.0 (0x44084000), not 546.0
'  -- it was the only byte wrong on the first attempt (first_diff 257).
	'!Global g_np_photo:TImage
	'!Global g_np_bg1:TImage
	'!Global g_np_bg2:TImage
	'!Global g_np_heads:TImage[]
	'!Global g_profile:TProfile
	'!Global g_screen_x:Int
	'!Global g_np_star:TImage
	Function Draw:Int()
		SetDrawStateHex("FFFFFF", 1.0, 1.0, 0, 3)
		If g_np_photo <> Null
			DrawImageRect(g_np_photo, 92.0, 250.0, 320.0, 220.0, 0)
			DrawImage(g_np_bg2, 0, 0, 0)
		Else
			DrawImage(g_np_bg1, 0, 0, 0)
		EndIf
		DrawImage(g_np_heads[g_profile.playercols.skin - 1], 0, 0, 0)
		TEngine.DrawMyText(g_profile.newsheadline, g_screen_x / 2, 200.0, 1, 0, 1.0, 1.0, "FFFFFF", 0)
		TEngine.DrawMyText(Lower(GetText("Your Rating")), 545.0, 260.0, 1, 0, 1.0, 1.0, "FFFFFF", 0)
		TEngine.DrawMyText(FormatDecimals(g_profile.newsrating / 10.0, 1), 550.0, 300.0, 1, 0, 1.0, 1.0, "FFFFFF", 0)
		If g_profile.newsmotm <> 0
			DrawImage(g_np_star, 560.0, 420.0, 0)
			TEngine.DrawMyText(Lower(GetText("Star Man!")), 560.0, 420.0, 1, 1, 1.0, 1.0, "FFFFFF", 0)
		EndIf
	End Function
