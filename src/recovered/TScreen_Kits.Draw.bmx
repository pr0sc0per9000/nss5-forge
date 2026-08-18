' TScreen_Kits.Draw
' VA 0x0054a708   152 bytes   vtable slot 0x48   sig ()i
' byte-identical vs NSS5.exe (152/152, original length from Ghidra's inventory)
' harness mode=reloc.
' FUN_005ad7c8 = _brl_max2d_DrawImageRect(image, x#, y#, w#, h#, frame).
' The Int Global is passed straight through to the Float w parameter; the implicit
'   widening is what Ghidra renders as `(float)DAT_00c6efdc`.
' float immediates from the image: 0x43340000=180.0, 0x438c0000=280.0,
'   0x43320000=178.0, 0x43e50000=458.0, 0x40800000=4.0.
' module Globals assumed by this body (names ours, types load-bearing):
'   Global g_kits_img1:TImage    ' 0x00c6f34c
'   Global g_kits_img2:TImage    ' 0x00c6f3b0
'   Global g_screen_int21:Int    ' 0x00c6efdc
	Function Draw:Int()
		'!Global g_kits_img1:TImage
		'!Global g_screen_int21:Int
		'!Global g_kits_img2:TImage
		DrawImageRect(g_kits_img1, 0, 180.0, g_screen_int21, 280.0, 0)
		DrawImageRect(g_kits_img2, 0, 178.0, g_screen_int21, 4.0, 0)
		DrawImageRect(g_kits_img2, 0, 458.0, g_screen_int21, 4.0, 0)
	End Function
