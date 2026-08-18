' TScreen.RenderBorder
' VA 0x00511066   332 bytes
' byte-identical vs NSS5.exe (332/332, original length from Ghidra's inventory, mode=reloc)
' Verified through the oracle from scratch, with helper_map.record stubbed.
' Body-only format: statements only; parameters are a0, a1, ...
' CONSTANTS: the two "+ N.0" offsets are 600.0 (code offset +195, the g_scr_bordery band)
'   and 800.0 (code offset +267, the g_scr_borderx band). The oracle masks the .rdata
'   ADDRESS, so a MATCH does not certify them; they are read with scripts/check_floats.py
'   and confirmed by direct disassembly. MATCH 332/332.
'!Global g_scr_borderimg:TImage
'!Global g_scr_borderx:Float
'!Global g_scr_bordery:Float
'!Global g_eng_screenw:Int
If g_scr_borderx > 0 Or g_scr_bordery > 0
	If g_scr_borderimg <> Null
		DrawImage(g_scr_borderimg, g_scr_borderx, g_scr_bordery, 0)
	EndIf
	SetAlpha(0.5)
	SetColor(0, 0, 0)
	DrawRect(0, 0, Float(g_eng_screenw), g_scr_bordery)
	DrawRect(0, g_scr_bordery + 600.0, Float(g_eng_screenw), g_scr_bordery)
	DrawRect(0, g_scr_bordery, g_scr_borderx, 600.0)
	DrawRect(g_scr_borderx + 800.0, g_scr_bordery, g_scr_borderx, 600.0)
	SetColor(255, 255, 255)
	SetAlpha(1.0)
EndIf
